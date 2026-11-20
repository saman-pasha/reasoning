%% coding/cocolog/codegen.pl -- cocolog source from a written requirement.
%%
%%     cocolog -s coding/cocolog/run.pl -- SPEC.txt [flags] [OUT.pl]
%%
%% The requirement goes to a language model together with cocolog's own
%% SKILL.md, the guide the repository writes for a programmer new to the
%% dialect. The reply is a complete cocolog program with a `main/0' entry
%% point (or the goal named by --goal). A reply is written to a temporary
%% file and run with `cocolog run' before it is accepted; a load warning,
%% a failed goal or an uncaught error goes back to the model with the
%% report and the previous program, up to three attempts.
%%
%%     --goal G        the goal `cocolog run' proves (default main)
%%     --skill FILE    the language guide (default $COCOLOG_SKILL, else
%%                     coding/cocolog/SKILL.md)
%%     --no-skill      omit the guide; a short generic cocolog prompt
%%     --expect FILE   compare the program's standard output with FILE
%%     --attempts N    try at most N times (default 3)
%%     --timeout MS    let one run take MS milliseconds (default 3000)
%%     --budget N      stop before a repair once N tokens are spent
%%     --keep DIR      write every attempt's prompt, code and diagnostic
%%     --dry-run       print the system and user prompts, no model call
%%     --report        print calls and token usage to stderr
%%     --key-env NAME --temperature T --max-tokens N --provider P
%%     --model M --base-url U --effort E
%%
%%     codegen_cocolog(+Spec, -Code)
%%     codegen_cocolog(+Spec, +Overrides, -Code)
%%     codegen_cocolog(+Spec, +Goal, +Overrides, -Code)
%%         one model call, not run; the goal defaults to main.
%%
%%     codegen_cocolog_bare(+Spec, +Goal, +Overrides, -Code)
%%         the one-shot with --no-skill's short system prompt in place of
%%         the guide; the user prompt is codegen_cocolog/4's.
%%
%%     codegen_cocolog_checked(+Spec, -Code)
%%     codegen_cocolog_checked(+Spec, +Overrides, -Code)
%%         the call, then `cocolog run' on the reply, with repair.
%%
%%     codegen_cocolog_from(+Spec, +Goal, +Overrides, +RunOptions, -Code)
%%         the loop with the goal and run options named.
%%
%%     cocolog_skill_text(-Text)
%%     cocolog_skill_text(+File, -Text)
%%         the guide as an atom; File `none' uses the default.
%%
%% The provider, model, endpoint and key are `coding/options.pl''s; a
%% `cocolog` binary must be the one running this file (its executable is
%% the child that checks a reply).

:- use_module(library(llm)).
:- use_module(library(process)).
:- use_module('coding/options.pl').
:- use_module('coding/report.pl').
:- use_module('coding/shell.pl').

%% ---- the language guide ------------------------------------------------
%%
%% Three ways to find the guide, in order: --skill FILE, $COCOLOG_SKILL,
%% then this repository's coding/cocolog/SKILL.md. A guide that cannot be
%% read is an error, never a silent fall-back to the generic prompt: the
%% generic run is a different experiment (--no-skill says so on purpose),
%% and a missing file must not be quietly counted with it.

cocolog_skill_text(Text) :-
    cocolog_skill_text(none, Text).

cocolog_skill_text(none, Text) :-
    !,
    (   getenv('COCOLOG_SKILL', File),
        File \== ''
    ->  true
    ;   File = 'coding/cocolog/SKILL.md'
    ),
    cocolog_read_skill(File, Text).
cocolog_skill_text(File, Text) :-
    cocolog_read_skill(File, Text).

cocolog_read_skill(File, Text) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(Text, Codes)
    ;   format(atom(Msg), 'cannot read the cocolog guide ~s', [File]),
        throw(error(codegen_error(skill_file, Msg), cocolog_skill_text/2))
    ).

cocolog_system_prompt(Skill, Prompt) :-
    format(atom(Prompt),
'You are a cocolog programmer. The language guide follows. Read it and follow it exactly. Output only the complete cocolog source code, with no Markdown fences and no explanation. Define main/0 unless the requirement names another goal.

~s',
           [Skill]).

cocolog_no_skill_prompt(Prompt) :-
    format(atom(Prompt),
'You are a cocolog programmer. Write a complete cocolog program for the requirement. Define main/0 unless the requirement names another goal. Output only the complete source code, with no Markdown fences and no explanation.',
           []).

cocolog_user_prompt(Spec, Goal, Prompt) :-
    format(atom(Prompt),
'Write a complete cocolog program for this requirement. The command run will prove ~w.
~s',
           [Goal, Spec]).

cocolog_repair_prompt(Base, none, Base) :-
    !.
cocolog_repair_prompt(Base, prev(Previous, Diag), Prompt) :-
    format(atom(Prompt),
           '~s~n~nYour previous program did not pass verification. It may not have loaded, run, timed out, or printed the expected output. The report said:~n~s~nThe previous program was:~n~s~nWrite a corrected complete cocolog program. Output only the source.',
           [Base, Diag, Previous]).

%% ---- one call ----------------------------------------------------------
%%
%% codegen_cocolog/2,3 is the one-shot: one model call, the reply returned
%% as written, NOT run and not repaired. It is what a caller uses to see
%% what the model writes; the entry's main/0 (run.pl) is what uses the
%% checked loop.

codegen_cocolog(Spec, Code) :-
    codegen_cocolog(Spec, main, [], Code).

codegen_cocolog(Spec, Overrides, Code) :-
    codegen_cocolog(Spec, main, Overrides, Code).

codegen_cocolog(Spec, Goal, Overrides, Code) :-
    cocolog_skill_text(Skill),
    cocolog_system_prompt(Skill, System),
    cocolog_one_call(System, Spec, Goal, Overrides, Code).

%% The control: the same call with no guide, which is what the guide is
%% measured against.
codegen_cocolog_bare(Spec, Goal, Overrides, Code) :-
    cocolog_no_skill_prompt(System),
    cocolog_one_call(System, Spec, Goal, Overrides, Code).

cocolog_one_call(System, Spec, Goal, Overrides, Code) :-
    cocolog_user_prompt(Spec, Goal, Prompt),
    codegen_report_reset,
    get_time(Start),
    catch(( cocolog_llm(System, Prompt, Overrides, Reply),
            cocolog_strip_fence(Reply, Code)
          ), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

codegen_cocolog_checked(Spec, Code) :-
    codegen_cocolog_checked(Spec, [], Code).

codegen_cocolog_checked(Spec, Overrides, Code) :-
    codegen_cocolog_from(Spec, main, Overrides, [], Code).

codegen_cocolog_from(Spec, Goal, Overrides, RunOptions, Code) :-
    cocolog_run_prepare(RunOptions, Attempts, Timeout, Budget, Keep, SkillFile,
                        Expect),
    codegen_key_env(Overrides, KeyVar),
    (   SkillFile == no
    ->  cocolog_no_skill_prompt(System)
    ;   cocolog_skill_text(SkillFile, Skill),
        cocolog_system_prompt(Skill, System)
    ),
    codegen_report_reset,
    get_time(Start),
    catch(cocolog_attempt(1, Attempts, Spec, Goal, System, Overrides, KeyVar,
                          Keep, Timeout, Expect, Budget, none, Code), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

cocolog_run_prepare(RunOptions, Attempts, Timeout, Budget, Keep, SkillFile,
                    Expect) :-
    cocolog_run_option(RunOptions, attempts, 3, Attempts0),
    cocolog_positive(attempts, Attempts0),
    Attempts = Attempts0,
    cocolog_run_option(RunOptions, timeout, 3000, Timeout0),
    cocolog_positive(timeout, Timeout0),
    Timeout = Timeout0,
    cocolog_run_option(RunOptions, budget, none, Budget0),
    (   Budget0 == none
    ->  Budget = none
    ;   cocolog_positive(budget, Budget0),
        Budget = Budget0
    ),
    cocolog_run_option(RunOptions, keep, none, Keep),
    cocolog_keep_prepare(Keep),
    cocolog_run_option(RunOptions, skill, none, SkillFile),
    cocolog_run_option(RunOptions, expect, none, Expect0),
    cocolog_expect_prepare(Expect0, Expect).

%% The oracle is a configuration error, not a repair: read it before the
%% first call, so a typo costs no model tokens and cannot change between
%% attempts.
cocolog_expect_prepare(none, none) :-
    !.
cocolog_expect_prepare(File, expect(File, Expected)) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(Expected, Codes)
    ;   format(atom(Msg), 'cannot read the expected output ~s', [File]),
        throw(error(codegen_error(expect_file, Msg),
                    cocolog_expect_prepare/2))
    ).

cocolog_run_option(Options, Key, Default, Value) :-
    (   member(Option, Options),
        functor(Option, Key, 1),
        arg(1, Option, Found)
    ->  Value = Found
    ;   Value = Default
    ).

cocolog_positive(Key, Value) :-
    (   integer(Value),
        Value > 0
    ->  true
    ;   format(atom(Msg), '~w must be a positive integer, not ~w', [Key, Value]),
        throw(error(codegen_error(run_option, Msg), cocolog_run_prepare/7))
    ).

cocolog_keep_prepare(none) :-
    !.
cocolog_keep_prepare(dir(Dir)) :-
    (   catch(exists_directory(Dir), _, fail)
    ->  true
    ;   catch(make_directory(Dir), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot make the keep directory ~s', [Dir]),
        throw(error(codegen_error(keep_dir, Msg), cocolog_keep_prepare/1))
    ).

cocolog_attempt(Attempt, Max, Spec, Goal, System, Overrides, KeyVar, Keep,
                Timeout, Expect, Budget, Prev, Code) :-
    cocolog_user_prompt(Spec, Goal, Base),
    cocolog_repair_prompt(Base, Prev, Prompt),
    cocolog_keep_attempt(Keep, Attempt, 'prompt.txt', Prompt),
    cocolog_llm(System, Prompt, Overrides, Reply),
    cocolog_strip_fence(Reply, Code0),
    cocolog_keep_attempt(Keep, Attempt, 'pl', Code0),
    cocolog_check(Code0, Goal, Timeout, Expect, KeyVar, Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Diag),
        cocolog_keep_attempt(Keep, Attempt, 'diag.txt', Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(cocolog_failed, Diag),
                        codegen_cocolog_from/5))
        ;   cocolog_budget_exhausted(Budget)
        ->  cocolog_budget_error(Budget)
        ;   Next is Attempt + 1,
            cocolog_attempt(Next, Max, Spec, Goal, System, Overrides, KeyVar,
                            Keep, Timeout, Expect, Budget, prev(Code0, Diag),
                            Code)
        )
    ).

%% ---- run the reply -----------------------------------------------------
%%
%% THE REPLY IS RUN, NOT READ. A program that loads and whose main/0
%% succeeds is accepted; a program whose standard error carries a
%% line-leading `ERROR:' or `Warning:' is not, because a load warning
%% names a clause that did not land -- the program may still run, on less
%% than it wrote, which is the failure this check exists to catch. The
%% child's standard error is the stream proc_run/4 reads; its standard
%% output goes to a file of its own. A warning can therefore not be
%% mistaken for the program's own text, and the program cannot truncate
%% the stream the check reads.
%%
%% The verifier reads no store and starts no server: the reply runs under
%% plain `--local', so a generator that wrote to a knowledge base would
%% pass here and fail where it was meant to run. A task that needs one is
%% not this tool's.
%%
%% EXPECT is compared byte for byte against the standard output, not
%% trimmed: unlike the C benchmark's cases (bench_norm/2 there), here the
%% program writes its report, and a missing newline is a difference the
%% caller asked to see.

cocolog_check(Code, Goal, Timeout, Expect, KeyVar, Verdict) :-
    (   Code == ''
    ->  Verdict = fail('the reply is empty')
    ;   cocolog_temp_dir(Dir),
        atom_concat(Dir, '/program.pl', File),
        atom_concat(Dir, '/stdout.txt', OutFile),
        call_cleanup(
            cocolog_check_file(Code, Goal, Timeout, Expect, KeyVar, File,
                               OutFile, Verdict),
            cocolog_cleanup(Dir, File, OutFile))
    ).

%% proc_run/4 reads the pipe it gives the child. The command puts the
%% child's standard ERROR on that pipe and its standard OUTPUT in OutFile
%% (`2>&1 >OUT'), so a load diagnostic is on a stream the program cannot
%% truncate, and --expect compares what the program printed and nothing
%% else.
cocolog_check_file(Code, Goal, Timeout, Expect, KeyVar, File, OutFile,
                   Verdict) :-
    atom_codes(Code, Codes),
    (   catch(write_file_from_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(FileMsg), 'cannot write the check file ~s', [File]),
        throw(error(codegen_error(check_file, FileMsg),
                    cocolog_check_file/8))
    ),
    current_prolog_flag(executable, Exe),
    cocolog_run_command(Exe, File, Goal, OutFile, KeyVar, Command),
    cocolog_proc_run(Command, Timeout, ErrCodes, Exit),
    (   catch(read_file_to_codes(OutFile, OutCodes), _, fail)
    ->  true
    ;   OutCodes = []
    ),
    atom_codes(Output, OutCodes),
    atom_codes(Errors, ErrCodes),
    (   Exit == 0,
        \+ cocolog_bad_stderr(Errors)
    ->  cocolog_expect(Expect, Output, Verdict)
    ;   Exit == 0
    ->  format(atom(Diag0), 'cocolog run printed a load diagnostic~n~s',
               [Errors]),
        cocolog_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ;   Exit == 124
    ->  format(atom(Diag0), 'cocolog run timed out after ~w ms~n~s',
               [Timeout, Errors]),
        cocolog_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ;   format(atom(Diag0), 'cocolog run exit ~w~n~s', [Exit, Errors]),
        cocolog_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ).

%% tmp_file/2 only names a path. A killed run can leave a directory under a
%% name this process would be given again, so an existing name is skipped.
cocolog_temp_dir(Dir) :-
    tmp_file(cocolog_program, Try),
    (   cocolog_path_exists(Try)
    ->  cocolog_temp_dir(Dir)
    ;   (   catch(make_directory(Try), _, fail)
        ->  Dir = Try
        ;   format(atom(DirMsg), 'cannot make the check directory ~s', [Try]),
            throw(error(codegen_error(check_dir, DirMsg), cocolog_temp_dir/1))
        )
    ).

cocolog_path_exists(Path) :-
    (   exists_file(Path)
    ->  true
    ;   exists_directory(Path)
    ).

cocolog_expect(none, _, ok) :-
    !.
cocolog_expect(expect(File, Expected), Output, Verdict) :-
    (   Output == Expected
    ->  Verdict = ok
    ;   format(atom(Diag0),
               'the output does not match ~s~nexpected:~n~s~nactual:~n~s',
               [File, Expected, Output]),
        cocolog_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ).

cocolog_run_command(Exe, File, Goal, OutFile, KeyVar, Command) :-
    codegen_shell_quote(Exe, QExe),
    codegen_shell_quote(File, QFile),
    codegen_shell_quote(OutFile, QOut),
    codegen_env_prefix(KeyVar, Prefix),
    (   Goal == main
    ->  format(atom(Command), 'ulimit -f 8192; ~w~w run ~w 2>&1 >~w',
               [Prefix, QExe, QFile, QOut])
    ;   codegen_shell_quote(Goal, QGoal),
        format(atom(Command), 'ulimit -f 8192; ~w~w run ~w ~w 2>&1 >~w',
               [Prefix, QExe, QFile, QGoal, QOut])
    ).

%% The selected key and the known provider keys are removed from the
%% child's environment by codegen_env_prefix/2: a generated program has no
%% business asking a provider anything, and the key is the one secret this
%% process holds.
%%
%% `ulimit -f 8192' (4 MB in 512-byte blocks) caps the file standard output
%% goes to; a program that floods it dies on the write and fails the check
%% instead of filling the disk. The deadline bounds standard error, which
%% proc_run/4 reads through a pipe.
cocolog_proc_run(Command, Timeout, Codes, Exit) :-
    catch(proc_run(Command, Timeout, Codes, Exit), Ball,
          throw(error(codegen_error(process, Ball), cocolog_proc_run/4))).

%% Errors and warnings are line-leading in cocolog's own diagnostics, so
%% the program's standard output may contain the words without being
%% refused.
cocolog_bad_stderr(Output) :-
    atom_string(Output, String),
    split_string(String, "\n", "", Lines),
    member(Line, Lines),
    (   cocolog_line_begins(Line, 'ERROR:')
    ;   cocolog_line_begins(Line, 'Warning:')
    ).

cocolog_line_begins(Line, Word) :-
    atom_string(Word, Prefix),
    sub_string(Line, 0, _, _, Prefix).

cocolog_cleanup(Dir, File, OutFile) :-
    catch(delete_file(File), _, true),
    catch(delete_file(OutFile), _, true),
    catch(delete_directory(Dir), _, true).

cocolog_limit(Max, Text, Limited) :-
    (   atom_length(Text, Length),
        Length > Max
    ->  sub_atom(Text, 0, Max, _, Limited)
    ;   Limited = Text
    ).

%% ---- the model call ----------------------------------------------------
%%
%% The guide is the largest part of the prompt: cocolog's SKILL.md is about
%% 19 000 tokens, sent with every attempt. It is loaded once per
%% `codegen_cocolog_from/5' call, before the first attempt, and reused --
%% so an edit to SKILL.md while a `--attempts 3' run is going does not
%% change the guide between the call and its repair.
%%
%% --no-skill swaps it for a short generic prompt, which is the control:
%% the difference between a run with the guide and one without measures
%% what the guide is worth, not what the model is.

cocolog_llm(System, Prompt, Overrides, Reply) :-
    codegen_options(Overrides, Options),
    codegen_key_env(Overrides, KeyVar),
    llm_opt(Options, provider, Provider),
    codegen_base_url(Overrides, Provider, BaseUrl),
    cocolog_use_endpoint(Provider, BaseUrl, KeyVar),
    get_time(Start),
    llm_chat([msg(system, System), msg(user, Prompt)], Options, Reply),
    get_time(End),
    Seconds is End - Start,
    codegen_report_add(Seconds).

cocolog_use_endpoint(Provider, BaseUrl, KeyVar) :-
    (   memberchk(Provider, [anthropic, openai])
    ->  retractall(llm_provider(Provider, _, _)),
        assertz(llm_provider(Provider, BaseUrl, KeyVar))
    ;   throw(error(llm_error(unknown_provider, Provider), cocolog_llm/4))
    ).

cocolog_strip_fence(Text, Code) :-
    (   sub_atom(Text, _, _, _, '```')
    ->  split_string(Text, "\n", "", Lines0),
        exclude(cocolog_fence_line, Lines0, Lines),
        findall(A, ( member(L, Lines), atom_string(A, L) ), Atoms),
        atomic_list_concat(Atoms, '\n', Code)
    ;   Code = Text
    ).

cocolog_fence_line(Line) :-
    sub_string(Line, 0, 3, _, '```').

%% ---- CLI ---------------------------------------------------------------
%%
%% A bad flag list is the usage line and exit 1. A bad RUN -- an unreadable
%% spec, a guide that is not there, a run that ends refused -- is exit 1
%% with `codegen: KIND' and the diagnostic on stderr, and the report first
%% when --report was asked for, so the tokens a refused run spent are
%% still seen. OUT is written only after a run is accepted: a refused run
%% leaves no .pl behind to be mistaken for the program, and --keep dir is
%% how its last candidate is kept for a person to read.

cocolog_cli :-
    current_prolog_flag(argv, [_|Args]),
    (   cocolog_args(Args, args(SpecFile, Goal, OutFile, Report, DryRun,
                                RunOptions, Overrides))
    ->  catch(cocolog_main(SpecFile, Goal, OutFile, Report, DryRun,
                           RunOptions, Overrides),
              Ball,
              codegen_cli_failure(Report, Ball))
    ;   format("usage: cocolog -s coding/cocolog/run.pl -- SPEC.txt [--goal G] [--skill FILE] [--no-skill] [--expect FILE] [--attempts N] [--timeout MS] [--budget N] [--keep DIR] [--dry-run] [--key-env NAME] [--temperature T] [--max-tokens N] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.pl]~n", []),
        halt(1)
    ).

cocolog_main(SpecFile, Goal, OutFile, Report, DryRun, RunOptions, Overrides) :-
    (   catch(read_file_to_codes(SpecFile, Codes), _, fail)
    ->  atom_codes(Spec, Codes)
    ;   format(atom(Msg), 'cannot read the requirement ~s', [SpecFile]),
        throw(error(codegen_error(spec_file, Msg), cocolog_main/7))
    ),
    (   DryRun == yes
    ->  cocolog_run_option(RunOptions, keep, none, Keep),
        cocolog_keep_prepare(Keep),
        cocolog_run_option(RunOptions, skill, none, SkillFile),
        (   SkillFile == no
        ->  cocolog_no_skill_prompt(System)
        ;   cocolog_skill_text(SkillFile, Skill),
            cocolog_system_prompt(Skill, System)
        ),
        cocolog_user_prompt(Spec, Goal, Prompt),
        format("SYSTEM~n~s~n~nUSER~n~s~n", [System, Prompt]),
        codegen_report_reset,
        codegen_report_print(Report)
    ;   codegen_cocolog_from(Spec, Goal, Overrides, RunOptions, Code),
        cocolog_write_output(OutFile, Code),
        codegen_report_print(Report)
    ).

cocolog_write_output(none, Code) :-
    !,
    format("~s~n", [Code]).
cocolog_write_output(OutFile, Code) :-
    atom_concat(Code, '\n', Text),
    atom_codes(Text, TextCodes),
    (   catch(write_file_from_codes(OutFile, TextCodes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot write ~s', [OutFile]),
        throw(error(codegen_error(output_file, Msg), cocolog_write_output/2))
    ).

%% args(Spec, Goal, Out, Report, DryRun, RunOptions, Overrides)
cocolog_args(Args, Term) :-
    cocolog_args(Args, args(none, main, none, no, no, [], []), Term).

cocolog_args([], State, State) :-
    State = args(Spec, _, _, _, _, _, _),
    Spec \== none,
    !.
cocolog_args(['--goal', Goal|Rest], args(S, _, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, Goal, O, R, D, Run, Os), A).
cocolog_args(['--skill', File|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_run_set(skill(File), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--no-skill'|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_run_set(skill(no), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--expect', File|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_run_set(expect(File), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--attempts', N|Rest], args(S, G, O, R, D, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    cocolog_run_set(attempts(V), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--timeout', N|Rest], args(S, G, O, R, D, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    cocolog_run_set(timeout(V), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--budget', N|Rest], args(S, G, O, R, D, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    cocolog_run_set(budget(V), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--keep', Dir|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_run_set(keep(dir(Dir)), Run, Run1),
    cocolog_args(Rest, args(S, G, O, R, D, Run1, Os), A).
cocolog_args(['--dry-run'|Rest], args(S, G, O, R, _, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, yes, Run, Os), A).
cocolog_args(['--report'|Rest], args(S, G, O, _, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, yes, D, Run, Os), A).
cocolog_args(['--provider', P|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, D, Run, [provider(P)|Os]), A).
cocolog_args(['--model', M|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, D, Run, [model(M)|Os]), A).
cocolog_args(['--base-url', U|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, D, Run, [base_url(U)|Os]), A).
cocolog_args(['--effort', E|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, D, Run, [effort(E)|Os]), A).
cocolog_args(['--key-env', K|Rest], args(S, G, O, R, D, Run, Os), A) :-
    cocolog_args(Rest, args(S, G, O, R, D, Run, [key_env(K)|Os]), A).
cocolog_args(['--temperature', T|Rest], args(S, G, O, R, D, Run, Os), A) :-
    atom_number(T, V), number(V), V >= 0, !,
    cocolog_args(Rest, args(S, G, O, R, D, Run, [temperature(V)|Os]), A).
cocolog_args(['--max-tokens', N|Rest], args(S, G, O, R, D, Run, Os), A) :-
    atom_number(N, V), integer(V), V > 0, !,
    cocolog_args(Rest, args(S, G, O, R, D, Run, [max_tokens(V)|Os]), A).
cocolog_args([Arg|Rest], args(none, G, O, R, D, Run, Os), A) :-
    \+ cocolog_flag(Arg),
    cocolog_args(Rest, args(Arg, G, O, R, D, Run, Os), A).
cocolog_args([Arg|Rest], args(S, G, none, R, D, Run, Os), A) :-
    S \== none,
    \+ cocolog_flag(Arg),
    cocolog_args(Rest, args(S, G, Arg, R, D, Run, Os), A).

cocolog_run_set(Option, Options, [Option|Rest]) :-
    functor(Option, Key, _),
    exclude(cocolog_run_key(Key), Options, Rest).

cocolog_run_key(Key, Option) :-
    functor(Option, Key, _).

cocolog_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').

%% ---- helpers -----------------------------------------------------------

cocolog_keep_attempt(none, _, _, _) :-
    !.
cocolog_keep_attempt(dir(Dir), Attempt, Kind, Text) :-
    format(atom(Name), 'attempt-~w.~w', [Attempt, Kind]),
    atom_concat(Dir, '/', Prefix),
    atom_concat(Prefix, Name, File),
    atom_concat(Text, '\n', Terminated),
    atom_codes(Terminated, Codes),
    (   catch(write_file_from_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot write ~s', [File]),
        throw(error(codegen_error(keep_dir, Msg), cocolog_keep_attempt/4))
    ).

cocolog_budget_exhausted(none) :-
    !,
    fail.
cocolog_budget_exhausted(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    Total >= Budget.

cocolog_budget_error(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    format(atom(Msg), 'the run reached ~w tokens, its budget of ~w',
           [Total, Budget]),
    throw(error(codegen_error(budget_exceeded, Msg),
                codegen_cocolog_from/5)).
