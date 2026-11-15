%% coding/python/codegen.pl -- Python 3 source from a written requirement.
%%
%%     cocolog -s coding/python/run.pl -- SPEC.txt [flags] [OUT.py]
%%
%% A requirement goes to a language model as a CONTRACT: one complete
%% program or module, no Markdown fences, no prose. The reply is read
%% back with `python3 -m py_compile' and REPAIRED with the interpreter's
%% own diagnostic until it parses. What passes is not yet believed: see
%% `guarded' below, which is what makes a reply that shows tests run
%% them.
%%
%% The effort defaults are `coding/options.pl''s -- both `none'. The
%% keyword reading is `coding/python/obligations.pl''s; the general
%% checks are `coding/languages.pl''s.
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/python/run.pl -- SPEC.txt out.py
%%
%%     --goal G         the unit a reply is expected to define: main
%%                      (default) for a program, or the function or class
%%                      name the task asks for
%%     --python PATH    the interpreter (default PYTHON3, else python3)
%%     --modes          print the modes, one a line, and exit
%%     --tests CMD      run CMD in the reply's directory before accepting
%%     --verified M     plain (default): the check is the parse; guarded:
%%                      also name the goal and, when the request names
%%                      tests and the reply shows one, run them; tested:
%%                      also run --tests
%%     --keep DIR       write every attempt's prompt, .py and diagnostic
%%     --attempts N     try at most N times (default 3)
%%     --timeout MS     let one run take MS milliseconds (default 10000)
%%     --budget N       stop before a repair once N tokens are spent
%%     --expect FILE    compare the program's standard output with FILE
%%     --dry-run        print the first prompt and exit, no model call
%%     --key-env, --temperature, --max-tokens, --provider, --model,
%%     --base-url, --effort, --report as in the C generator
%%
%%     codegen_python(+Spec, -Code)
%%     codegen_python(+Spec, +Overrides, -Code)
%%         one model call, not read by Python.
%%
%%     codegen_python_checked(+Spec, -Code)
%%     codegen_python_checked(+Spec, +Overrides, -Code)
%%         the call and the parse, with repair.
%%
%%     codegen_python_from(+Spec, +Overrides, +RunOptions, -Code)
%%         the loop with the run options named.
%%
%%     python_parse_check(+Code, +RunOptions, -Verdict)
%%         ok, or fail(Kind, Diagnostic) for a file Python refuses to
%%         parse (Kind `syntax'), a reply with no `--goal' definition
%%         (`goal'), unbound names (`names'), one the modes judge and
%%         guard it (`tests'), or one whose tests or `--tests' command
%%         fail (`run').
%%
%% WHY THERE ARE MODES. `python3 -m py_compile' proves a file parses and
%% nothing else, so `plain' is exactly the C tool's `it compiled': cheap,
%% and silent about a name that is never defined. `guarded' adds what a
%% parse cannot see and a person reads a Python answer for: the name the
%% task asked for is there, and a reply that shows a test has run one.
%% `tested' adds the caller's own command. The endpoint's Python model is
%% the `guarded' mode; the tool defaults to `plain', as the C tool does,
%% and a run names the other.

:- use_module(library(llm)).
:- use_module(library(process)).
:- use_module(library(os)).
:- use_module('coding/options.pl').
:- use_module('coding/languages.pl').
:- use_module('coding/python/obligations.pl').
:- use_module('coding/report.pl').

%% ---- the reading -------------------------------------------------------

%% The keyword reading, the general checks, and the two sanity checks the
%% Python tool always adds: the checks a reply is refused for, whether or
%% not its words named them.
codegen_python_reading(Spec, Obligations) :-
    codegen_python_obligations(Spec, Keyword),
    codegen_python_sanity_checks(Sanity),
    append(Keyword, Sanity, All),
    codegen_unique_texts(All, Obligations).

codegen_unique_texts([], []).
codegen_unique_texts([Text|Rest], [Text|Texts]) :-
    exclude(codegen_same_atom(Text), Rest, Rest1),
    codegen_unique_texts(Rest1, Texts).

codegen_same_atom(Text, Other) :-
    Text == Other.

%% ---- the prompt --------------------------------------------------------

codegen_python_prompt(Spec, Obligations, Prev, Prompt) :-
    (   Obligations == []
    ->  format(atom(Base),
               'Write a complete Python 3 program for this requirement. Output only the source, with no Markdown fences and no explanation.~n~nRequirement:~n~s',
               [Spec])
    ;   atomic_list_concat(Obligations, '\n', Checklist),
        format(atom(Base),
               'Write a complete Python 3 program. Output only the source, with no Markdown fences and no explanation.~n~nThe requirement implies these checks. The program must satisfy every one:~n~s~n~nRequirement:~n~s',
               [Checklist, Spec])
    ),
    (   Prev == none
    ->  Prompt = Base
    ;   Prev = prev(Previous, Diag),
        format(atom(Prompt),
               '~s~n~nYour previous program was refused. The report said:~n~s~nThe previous program was:~n~s~nWrite a corrected complete Python 3 program. Output only the source.',
               [Base, Diag, Previous])
    ).

%% ---- one call and the loop ---------------------------------------------

codegen_python(Spec, Code) :-
    codegen_python(Spec, [], Code).

codegen_python(Spec, Overrides, Code) :-
    codegen_python_reading(Spec, Obligations),
    codegen_python_prompt(Spec, Obligations, none, Prompt),
    codegen_report_reset,
    get_time(Start),
    catch(( python_llm(Prompt, Overrides, Reply),
            codegen_python_strip_fence(Reply, Code)
          ), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

codegen_python_checked(Spec, Code) :-
    codegen_python_checked(Spec, [], Code).

codegen_python_checked(Spec, Overrides, Code) :-
    codegen_python_from(Spec, Overrides, [], Code).

codegen_python_from(Spec, Overrides, RunOptions, Code) :-
    python_reading_and_guard(Spec, RunOptions, Reading),
    python_run_loop(Spec, Reading, Overrides, RunOptions, Code).

%% The reading and the guard a run of RunOptions gets: built together so
%% that a `tested' run with no --tests refuses before the first call, and
%% a caller of the loop sees the same refusal the tool does.
python_reading_and_guard(Spec, RunOptions, reading(Obligations, Guard)) :-
    python_run_prepare(RunOptions, _, _, _, _, _, Verified, TestsCommand, _),
    codegen_python_reading(Spec, Obligations),
    python_guard(Spec, Verified, TestsCommand, Guard).

python_run_loop(Spec, reading(Obligations, Guard), Overrides, RunOptions, Code) :-
    python_run_prepare(RunOptions, Max, Timeout, Keep, Python, Goal, _, _, Budget),
    codegen_report_reset,
    get_time(Start),
    catch(python_attempt(1, Max, Spec, Obligations, Guard, Goal, Overrides,
                         Keep, check(Python, Timeout, Budget), none, Code),
          Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

python_run_prepare(RunOptions, Max, Timeout, Keep, Python, Goal, Verified,
                   TestsCommand, Budget) :-
    python_run_option(RunOptions, attempts, 3, Max0),
    python_positive(attempts, Max0),
    Max = Max0,
    python_run_option(RunOptions, timeout, 10000, Timeout0),
    python_positive(timeout, Timeout0),
    Timeout = Timeout0,
    python_run_option(RunOptions, budget, none, Budget0),
    (   Budget0 == none
    ->  Budget = none
    ;   python_positive(budget, Budget0),
        Budget = Budget0
    ),
    python_run_option(RunOptions, keep, none, Keep),
    python_run_option(RunOptions, python, none, Python),
    python_run_option(RunOptions, goal, main, Goal),
    python_run_option(RunOptions, verified, plain, Verified0),
    python_verified(Verified0, Verified),
    python_run_option(RunOptions, tests, none, TestsCommand).

python_verified(plain, plain).
python_verified(guarded, guarded).
python_verified(tested, tested).
python_verified(Value, _) :-
    \+(memberchk(Value, [plain, guarded, tested])),
    format(atom(Msg), 'verified is plain, guarded or tested, not ~w', [Value]),
    throw(error(codegen_error(run_option, Msg), python_run_prepare/9)).

python_positive(Key, Value) :-
    (   integer(Value),
        Value > 0
    ->  true
    ;   format(atom(Msg), '~w must be a positive integer, not ~w', [Key, Value]),
        throw(error(codegen_error(run_option, Msg), python_run_prepare/9))
    ).

python_run_option(Options, Key, Default, Value) :-
    (   member(Option, Options),
        functor(Option, Key, 1),
        arg(1, Option, Found)
    ->  Value = Found
    ;   Value = Default
    ).

%% The guard is on where the mode is `guarded' or `tested'; `plain' has
%% none, and a `tested' run without --tests is an error before a model
%% call rather than a mode that silently checks less.
python_guard(_Spec, plain, _TestsCommand, guard(none, none, none)) :-
    !.
python_guard(Spec, guarded, _TestsCommand, Guard) :-
    !,
    codegen_python_sanity_checks(Sanity),
    codegen_request_tests_cue(Spec, Tests),
    Guard = guard(tests(Tests), sanity(Sanity), none).
python_guard(Spec, tested, CommandText0, guard(tests(Tests), sanity(Sanity), command(CommandText))) :-
    codegen_python_sanity_checks(Sanity),
    codegen_request_tests_cue(Spec, Tests),
    (   CommandText0 == none
    ->  throw(error(codegen_error(run_option,
                                  'verified tested needs --tests CMD'),
                    python_guard/4))
    ;   CommandText = CommandText0
    ).

codegen_request_tests_cue(Spec, yes) :-
    codegen_spec_atom(Spec, Atom),
    codegen_request_tests_cue(Atom),
    !.
codegen_request_tests_cue(_, no).

python_attempt(Attempt, Max, Spec, Obligations, Guard, Goal, Overrides, Keep,
               check(Python, Timeout, Budget), Prev, Code) :-
    codegen_python_prompt(Spec, Obligations, Prev, Prompt),
    python_keep_attempt(Keep, Attempt, 'prompt.txt', Prompt),
    python_llm(Prompt, Overrides, Reply),
    codegen_python_strip_fence(Reply, Code0),
    python_keep_attempt(Keep, Attempt, 'py', Code0),
    python_verdict(Code0, Guard, Goal, check(Python, Timeout), Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Kind, Diag),
        python_keep_attempt(Keep, Attempt, 'diag.txt', Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(Kind, Diag), codegen_python_from/4))
        ;   python_budget_exhausted(Budget)
        ->  python_budget_error(Budget)
        ;   Next is Attempt + 1,
            python_attempt(Next, Max, Spec, Obligations, Guard, Goal, Overrides,
                           Keep, check(Python, Timeout, Budget),
                           prev(Code0, Diag), Code)
        )
    ).

%% ---- the checks --------------------------------------------------------

%% The one verdict a reply gets: it parses or it does not; then the guard
%% names its own failure.
python_verdict(Code, Guard, Goal, check(Python, Timeout), Verdict) :-
    python_write(Code, Dir, File),
    python_parse(Python, File, Verdict0),
    (   Verdict0 == ok
    ->  python_guard_verdict(Guard, Goal, Code, check(Python, Timeout), Dir,
                             Verdict)
    ;   Verdict = Verdict0
    ).

%% The parse: the file Python reads, refused with its own message.
python_parse(Python, File, Verdict) :-
    python_interpreter(Python, Exe),
    format(atom(Command), '"~s" -m py_compile "~s" 2>&1', [Exe, File]),
    python_proc_run(Command, 60000, OutCodes, Exit),
    (   Exit == 0
    ->  Verdict = ok
    ;   atom_codes(Out, OutCodes),
        python_limit(4000, Out, Diag),
        Verdict = fail(syntax, Diag)
    ).

python_guard_verdict(guard(none, _, none), _, _, _, _, ok) :-
    !.
python_guard_verdict(guard(Tests, Sanity, Command), Goal, Code,
                     check(Python, Timeout), Dir, Verdict) :-
    (   python_goal_missing(Goal, Code)
    ->  format(atom(Diag),
               'the reply does not define ~w, which the task named~n~w',
               [Goal, Sanity]),
        Verdict = fail(goal, Diag)
    ;   Tests == yes,
        python_test_shown(Code, Needle),
        \+ sub_atom(Code, _, _, _, Needle)
    ->  format(atom(Diag1),
               'the reply shows a test and never runs one: a test that was not run is not a test that passed~n~w',
               [Sanity]),
        Verdict = fail(tests, Diag1)
    ;   Command == none
    ->  Verdict = ok
    ;   Command = command(CommandText),
        python_command_check(CommandText, Dir, check(Python, Timeout), Verdict)
    ).

python_command_check(CommandText, Dir, check(_Python, Timeout), Verdict) :-
    format(atom(Command), 'cd "~s" && ~s 2>&1', [Dir, CommandText]),
    python_proc_run(Command, Timeout, OutCodes, Exit),
    (   Exit == 0
    ->  Verdict = ok
    ;   atom_codes(Out, OutCodes),
        python_limit(4000, Out, Diag),
        (   Exit == 124
        ->  format(atom(Report), 'the command timed out: ~s~n~s',
                   [CommandText, Diag])
        ;   format(atom(Report), 'the command failed with exit ~w: ~s~n~s',
                   [Exit, CommandText, Diag])
        ),
        Verdict = fail(run, Report)
    ).

%% A name the task asked for is a `def NAME' or `class NAME', at any
%% indentation. `main' is on every program's list already: a reply that
%% is a module and defines no main is refused here, which is what
%% `guarded' means by a program.
python_goal_missing(main, Code) :-
    !,
    \+ sub_atom(Code, _, _, _, 'def main('),
    \+ sub_atom(Code, _, _, _, 'if __name__').
python_goal_missing(Goal, Code) :-
    atom(Goal),
    atom_concat('def ', Goal, DefHead),
    atom_concat(DefHead, '(', Def),
    \+ sub_atom(Code, _, _, _, Def),
    atom_concat('class ', Goal, Cls),
    \+ sub_atom(Code, _, _, _, Cls).

%% What a reply SHOWS a test by, and the command that must have run it.
%% The first key the reply holds decides, so the narrow `def test_` is
%% tried before the broad `assert '.
python_test_shown(Code, Needle) :-
    codegen_language_check_key(python, Shown, Needle),
    sub_atom(Code, _, _, _, Shown),
    !.

%% ---- the interpreter ---------------------------------------------------

%% ` --python PATH' wins, then $PYTHON3, then python3. A missing
%% interpreter is an error naming the three, never a silent `plain' that
%% accepted the first reply.
python_interpreter(none, Exe) :-
    !,
    (   getenv('PYTHON3', Found),
        Found \== ''
    ->  Exe = Found
    ;   Exe = python3
    ).
python_interpreter(Exe, Exe).

%% A run writes a directory of its own: the reply, and whatever test
%% command the guard runs finds nothing but the reply beside it.
python_write(Code, Dir, File) :-
    tmp_file(codegen_python, Dir),
    (   catch(exists_directory(Dir), _, fail)
    ->  true
    ;   catch(make_directory(Dir), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot make ~s', [Dir]),
        throw(error(codegen_error(keep_dir, Msg), python_write/3))
    ),
    atom_concat(Dir, '/program.py', File),
    atom_codes(Code, Codes),
    write_file_from_codes(File, Codes).

python_proc_run(Command, Timeout, Codes, Exit) :-
    catch(proc_run(Command, Timeout, Codes, Exit), _, ( Codes = [], Exit = 124 )).

python_limit(Max, Text, Limited) :-
    (   atom_length(Text, Length),
        Length > Max
    ->  sub_atom(Text, 0, Max, _, Limited)
    ;   Limited = Text
    ).

%% ---- the model call ----------------------------------------------------

python_llm(Prompt, Overrides, Reply) :-
    codegen_options(Overrides, Options),
    codegen_key_env(Overrides, KeyVar),
    llm_opt(Options, provider, Provider),
    codegen_base_url(Overrides, Provider, BaseUrl),
    format(atom(System),
           'You are a Python 3 programmer. Output only Python source, no Markdown fences, no explanation.',
           []),
    python_use_endpoint(Provider, BaseUrl, KeyVar),
    get_time(Start),
    llm_chat([msg(system, System), msg(user, Prompt)], Options, Reply),
    get_time(End),
    Seconds is End - Start,
    codegen_report_add(Seconds).

python_use_endpoint(Provider, BaseUrl, KeyVar) :-
    (   memberchk(Provider, [anthropic, openai])
    ->  retractall(llm_provider(Provider, _, _)),
        assertz(llm_provider(Provider, BaseUrl, KeyVar))
    ;   throw(error(llm_error(unknown_provider, Provider), python_llm/3))
    ).

codegen_python_strip_fence(Text, Code) :-
    (   sub_atom(Text, _, _, _, '```')
    ->  split_string(Text, "\n", "", Lines0),
        exclude(codegen_python_fence_line, Lines0, Lines),
        findall(A, ( member(L, Lines), atom_string(A, L) ), Atoms),
        atomic_list_concat(Atoms, '\n', Code)
    ;   Code = Text
    ).

codegen_python_fence_line(Line) :-
    sub_string(Line, 0, 3, _, '```').

%% ---- keep and budget ---------------------------------------------------

python_keep_attempt(none, _, _, _) :-
    !.
python_keep_attempt(dir(Dir), Attempt, Kind, Text) :-
    crypto_keep_file(Dir, Attempt, Kind, Text).

crypto_keep_file(Dir, Attempt, Kind, Text) :-
    python_keep_prepare(Dir),
    format(atom(Name), 'attempt-~w.~w', [Attempt, Kind]),
    atom_concat(Dir, '/', Prefix),
    atom_concat(Prefix, Name, File),
    atom_concat(Text, '\n', Terminated),
    atom_codes(Terminated, Codes),
    (   catch(write_file_from_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot write ~s', [File]),
        throw(error(codegen_error(keep_dir, Msg), python_keep_attempt/4))
    ).

python_keep_prepare(Dir) :-
    (   catch(exists_directory(Dir), _, fail)
    ->  true
    ;   catch(make_directory(Dir), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot make the keep directory ~s', [Dir]),
        throw(error(codegen_error(keep_dir, Msg), python_keep_attempt/4))
    ).

python_budget_exhausted(none) :-
    !,
    fail.
python_budget_exhausted(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    Total >= Budget.

python_budget_error(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    format(atom(Msg), 'the run reached ~w tokens, its budget of ~w',
           [Total, Budget]),
    throw(error(codegen_error(budget_exceeded, Msg), codegen_python_from/4)).

%% ---- the command line --------------------------------------------------

python_cli :-
    current_prolog_flag(argv, [_|Args]),
    (   python_args(Args, args(_, _, _, _, Modes, _, _)),
        Modes == yes
    ->  python_modes_printed
    ;   python_args(Args, args(SpecFile, OutFile, Report, DryRun, _,
                               RunOptions, Overrides))
    ->  catch(python_main(SpecFile, OutFile, Report, DryRun, RunOptions,
                         Overrides),
              error(codegen_error(Kind, Detail), _),
              ( codegen_report_print(Report),
                format(user_error, 'codegen: ~w~n~s~n', [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/python/run.pl -- SPEC.txt [--goal G] [--python PATH] [--verified plain|guarded|tested] [--tests CMD] [--keep DIR] [--attempts N] [--timeout MS] [--budget N] [--expect FILE] [--dry-run] [--modes] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.py]~n", []),
        halt(1)
    ).

%% --expect belongs to a program run: a reply the loop above accepted is
%% written alone in a directory of its own and run as `python3
%% program.py', and its standard output must match the file byte for
%% byte. The comparison is after acceptance, so a mismatch refuses the
%% run with no repair: what was run is what the output came from.
python_main(SpecFile, OutFile, Report, DryRun, RunOptions, Overrides) :-
    (   catch(read_file_to_codes(SpecFile, Codes), _, fail)
    ->  atom_codes(Spec, Codes)
    ;   format(atom(Msg), 'cannot read the requirement ~s', [SpecFile]),
        throw(error(codegen_error(spec_file, Msg), python_main/6))
    ),
    (   DryRun == yes
    ->  codegen_python_reading(Spec, Obligations),
        codegen_python_prompt(Spec, Obligations, none, Prompt),
        format("~s~n", [Prompt]),
        codegen_report_reset,
        codegen_report_print(Report)
    ;   codegen_python_from(Spec, Overrides, RunOptions, Code),
        python_run_option(RunOptions, expect, none, Expect),
        (   Expect == none
        ->  true
        ;   python_expect(Expect, Code, RunOptions)
        ),
        python_write_output(OutFile, Code),
        codegen_report_print(Report)
    ).

python_expect(Expect, Code, RunOptions) :-
    (   catch(read_file_to_codes(Expect, WantCodes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read the expected output ~s', [Expect]),
        throw(error(codegen_error(expect_file, Msg), python_expect/3))
    ),
    python_run_option(RunOptions, python, none, Python),
    python_write(Code, Dir, _File),
    python_interpreter(Python, Exe),
    format(atom(Command), 'cd "~s" && "~s" program.py 2>&1', [Dir, Exe]),
    python_proc_run(Command, 10000, GotCodes, _Exit),
    atom_codes(Want, WantCodes),
    atom_codes(Got, GotCodes),
    (   Got == Want
    ->  true
    ;   format(atom(Diag),
               'the output does not match ~s~nexpected:~n~s~nactual:~n~s',
               [Expect, Want, Got]),
        throw(error(codegen_error(expect_failed, Diag), python_expect/3))
    ).

python_write_output(none, Code) :-
    !,
    format("~s~n", [Code]).
python_write_output(OutFile, Code) :-
    atom_concat(Code, '\n', Text),
    atom_codes(Text, TextCodes),
    write_file_from_codes(OutFile, TextCodes).

python_modes_printed :-
    forall(member(Mode, [plain, guarded, tested]),
           format("~w~n", [Mode])).

%% args(Spec, Out, Report, DryRun, Modes, RunOptions, Overrides)
python_args(Args, Term) :-
    python_args(Args, args(none, none, no, no, no, [], []), Term).

python_args([], State, State) :-
    State = args(_, _, _, _, yes, _, _),
    !.
python_args([], State, State) :-
    State = args(Spec, _, _, _, _, _, _),
    Spec \== none,
    !.
python_args(['--goal', Goal|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(goal(Goal), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--python', P|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(python(P), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--verified', V|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(verified(V), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--tests', C|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(tests(C), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--keep', Dir|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(keep(dir(Dir)), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--attempts', N|Rest], args(S, O, R, D, M, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    python_run_set(attempts(V), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--timeout', N|Rest], args(S, O, R, D, M, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    python_run_set(timeout(V), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--budget', N|Rest], args(S, O, R, D, M, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    python_run_set(budget(V), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--expect', File|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_run_set(expect(File), Run, Run1),
    python_args(Rest, args(S, O, R, D, M, Run1, Os), A).
python_args(['--dry-run'|Rest], args(S, O, R, _, M, Run, Os), A) :-
    python_args(Rest, args(S, O, R, yes, M, Run, Os), A).
python_args(['--modes'|Rest], args(S, O, R, D, _, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, yes, Run, Os), A).
python_args(['--report'|Rest], args(S, O, _, D, M, Run, Os), A) :-
    python_args(Rest, args(S, O, yes, D, M, Run, Os), A).
python_args(['--provider', P|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, M, Run, [provider(P)|Os]), A).
python_args(['--model', M|Rest], args(S, O, R, D, Modes, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, Modes, Run, [model(M)|Os]), A).
python_args(['--base-url', U|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, M, Run, [base_url(U)|Os]), A).
python_args(['--effort', E|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, M, Run, [effort(E)|Os]), A).
python_args(['--key-env', K|Rest], args(S, O, R, D, M, Run, Os), A) :-
    python_args(Rest, args(S, O, R, D, M, Run, [key_env(K)|Os]), A).
python_args(['--temperature', T|Rest], args(S, O, R, D, M, Run, Os), A) :-
    atom_number(T, V), number(V), V >= 0, !,
    python_args(Rest, args(S, O, R, D, M, Run, [temperature(V)|Os]), A).
python_args(['--max-tokens', N|Rest], args(S, O, R, D, M, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    python_args(Rest, args(S, O, R, D, M, Run, [max_tokens(V)|Os]), A).
python_args([Arg|Rest], args(none, O, R, D, M, Run, Os), A) :-
    \+ python_flag(Arg),
    python_args(Rest, args(Arg, O, R, D, M, Run, Os), A).
python_args([Arg|Rest], args(S, none, R, D, M, Run, Os), A) :-
    S \== none,
    \+ python_flag(Arg),
    python_args(Rest, args(S, Arg, R, D, M, Run, Os), A).

python_run_set(Option, Options, [Option|Rest]) :-
    functor(Option, Key, _),
    exclude(python_run_key(Key), Options, Rest).

python_run_key(Key, Option) :-
    functor(Option, Key, _).

python_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').
