%% coding/cocolog/codegen.pl -- cocolog source from a written requirement.
%%
%%     cocolog -s coding/cocolog/codegen.pl -- SPEC.txt [flags] [OUT.pl]
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
%%                     ../cocolog/SKILL.md)
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
%%         one model call, not run.
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

%% ---- the language guide ------------------------------------------------

cocolog_skill_text(Text) :-
    cocolog_skill_text(none, Text).

cocolog_skill_text(none, Text) :-
    !,
    (   getenv('COCOLOG_SKILL', File),
        File \== ''
    ->  true
    ;   File = '../cocolog/SKILL.md'
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

cocolog_user_prompt(Spec, Goal, Prompt) :-
    format(atom(Prompt),
'Write a complete cocolog program for this requirement. The command run will prove ~w.
~s',
           [Goal, Spec]).

cocolog_repair_prompt(Base, none, Base) :-
    !.
cocolog_repair_prompt(Base, prev(Previous, Diag), Prompt) :-
    format(atom(Prompt),
           '~s~n~nYour previous program did not load or run. The report said:~n~s~nThe previous program was:~n~s~nWrite a corrected complete cocolog program. Output only the source.',
           [Base, Diag, Previous]).

%% ---- one call ----------------------------------------------------------

codegen_cocolog(Spec, Code) :-
    codegen_cocolog(Spec, [], Code).

codegen_cocolog(Spec, Overrides, Code) :-
    cocolog_skill_text(Skill),
    cocolog_system_prompt(Skill, System),
    cocolog_user_prompt(Spec, main, Prompt),
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
    cocolog_skill_text(SkillFile, Skill),
    cocolog_system_prompt(Skill, System),
    codegen_report_reset,
    get_time(Start),
    catch(cocolog_attempt(1, Attempts, Spec, Goal, System, Overrides, Keep,
                          Timeout, Expect, Budget, none, Code), Ball,
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
    cocolog_run_option(RunOptions, expect, none, Expect).

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

cocolog_attempt(Attempt, Max, Spec, Goal, System, Overrides, Keep, Timeout,
                Expect, Budget, Prev, Code) :-
    cocolog_user_prompt(Spec, Goal, Base),
    cocolog_repair_prompt(Base, Prev, Prompt),
    cocolog_keep_attempt(Keep, Attempt, 'prompt.txt', Prompt),
    cocolog_llm(System, Prompt, Overrides, Reply),
    cocolog_strip_fence(Reply, Code0),
    cocolog_keep_attempt(Keep, Attempt, 'pl', Code0),
    cocolog_check(Code0, Goal, Timeout, Expect, Verdict),
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
            cocolog_attempt(Next, Max, Spec, Goal, System, Overrides, Keep,
                            Timeout, Expect, Budget, prev(Code0, Diag), Code)
        )
    ).

%% ---- run the reply -----------------------------------------------------

cocolog_check(Code, Goal, Timeout, Expect, Verdict) :-
    (   Code == ''
    ->  Verdict = fail('the reply is empty')
    ;   tmp_file(cocolog_program, Dir),
        make_directory(Dir),
        atom_concat(Dir, '/program.pl', File),
        atom_codes(Code, Codes),
        write_file_from_codes(File, Codes),
        current_prolog_flag(executable, Exe),
        cocolog_run_command(Exe, File, Goal, Command),
        cocolog_proc_run(Command, Timeout, OutCodes, Exit),
        atom_codes(Output, OutCodes),
        (   Exit == 0,
            \+ cocolog_bad_output(Output)
        ->  cocolog_expect(Expect, Output, Verdict)
        ;   format(atom(Diag0), 'cocolog run exit ~w~n~s', [Exit, Output]),
            cocolog_limit(4000, Diag0, Diag),
            Verdict = fail(Diag)
        )
    ).

cocolog_expect(none, _, ok) :-
    !.
cocolog_expect(File, Output, Verdict) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(Expected, Codes),
        (   Output == Expected
        ->  Verdict = ok
        ;   format(atom(Diag0),
                   'the output does not match ~s~nexpected:~n~s~nactual:~n~s',
                   [File, Expected, Output]),
            cocolog_limit(4000, Diag0, Diag),
            Verdict = fail(Diag)
        )
    ;   format(atom(Msg), 'cannot read the expected output ~s', [File]),
        Verdict = fail(Msg)
    ).

cocolog_run_command(Exe, File, main, Command) :-
    !,
    format(atom(Command), '"~s" run "~s" 2>&1', [Exe, File]).
cocolog_run_command(Exe, File, Goal, Command) :-
    format(atom(Command), '"~s" run "~s" "~w" 2>&1', [Exe, File, Goal]).

cocolog_proc_run(Command, Timeout, Codes, Exit) :-
    catch(proc_run(Command, Timeout, Codes, Exit), _, ( Codes = [], Exit = 124 )).

cocolog_bad_output(Output) :-
    (   sub_atom(Output, _, _, _, 'ERROR:')
    ;   sub_atom(Output, _, _, _, 'Warning:')
    ).

cocolog_limit(Max, Text, Limited) :-
    (   atom_length(Text, Length),
        Length > Max
    ->  sub_atom(Text, 0, Max, _, Limited)
    ;   Limited = Text
    ).

%% ---- the model call ----------------------------------------------------

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

%% ---- the run report ----------------------------------------------------

codegen_report_reset :-
    nb_setval('$cocolog_calls', 0),
    nb_setval('$cocolog_prompt', 0),
    nb_setval('$cocolog_completion', 0),
    nb_setval('$cocolog_reasoning', 0),
    nb_setval('$cocolog_cache', 0),
    nb_setval('$cocolog_total', 0),
    nb_setval('$cocolog_seconds', 0.0),
    nb_setval('$cocolog_call_list', []).

codegen_report_finish(Start) :-
    get_time(End),
    Seconds is End - Start,
    nb_setval('$cocolog_seconds', Seconds).

codegen_report_add(CallSeconds) :-
    (   catch(nb_getval('$cocolog_calls', Calls0), _, fail)
    ->  Calls is Calls0 + 1
    ;   Calls = 1
    ),
    nb_setval('$cocolog_calls', Calls),
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  cocolog_usage_first(Pairs, prompt_tokens, input_tokens, Prompt),
        cocolog_usage_first(Pairs, completion_tokens, output_tokens,
                            Completion),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R0, Details),
            integer(R0)
        ->  Reasoning = R0
        ;   cocolog_usage_found(Pairs, reasoning_tokens, R1)
        ->  Reasoning = R1
        ;   Reasoning = 0
        ),
        cocolog_usage_first(Pairs, prompt_cache_hit_tokens,
                            cache_read_input_tokens, CacheHit),
        (   cocolog_usage_found(Pairs, total_tokens, Total0),
            Total0 > 0
        ->  Total = Total0
        ;   Total is Prompt + Completion
        ),
        cocolog_bump('$cocolog_prompt', Prompt),
        cocolog_bump('$cocolog_completion', Completion),
        cocolog_bump('$cocolog_reasoning', Reasoning),
        cocolog_bump('$cocolog_cache', CacheHit),
        cocolog_bump('$cocolog_total', Total),
        cocolog_call_record(call(CallSeconds, Prompt, Completion, Reasoning,
                                 CacheHit, Total))
    ;   cocolog_call_record(call(CallSeconds, 0, 0, 0, 0, 0))
    ).

cocolog_usage_first(Pairs, Key, Alternate, Number) :-
    (   cocolog_usage_found(Pairs, Key, Found)
    ->  Number = Found
    ;   cocolog_usage_found(Pairs, Alternate, Found)
    ->  Number = Found
    ;   Number = 0
    ).

cocolog_usage_found(Pairs, Key, Number) :-
    memberchk(Key-Value, Pairs),
    integer(Value),
    Number = Value.

cocolog_bump(Global, Number) :-
    (   catch(nb_getval(Global, Old), _, fail)
    ->  true
    ;   Old = 0
    ),
    New is Old + Number,
    nb_setval(Global, New).

cocolog_call_record(Call) :-
    (   catch(nb_getval('$cocolog_call_list', Calls), _, fail)
    ->  true
    ;   Calls = []
    ),
    nb_setval('$cocolog_call_list', [Call|Calls]).

codegen_report(report(Calls, Prompt, Completion, Reasoning, CacheHit, Total,
                      Seconds)) :-
    cocolog_global('$cocolog_calls', Calls),
    cocolog_global('$cocolog_prompt', Prompt),
    cocolog_global('$cocolog_completion', Completion),
    cocolog_global('$cocolog_reasoning', Reasoning),
    cocolog_global('$cocolog_cache', CacheHit),
    cocolog_global('$cocolog_total', Total),
    (   catch(nb_getval('$cocolog_seconds', S), _, fail), float(S)
    ->  Seconds = S
    ;   Seconds = 0.0
    ).

cocolog_global(Global, Value) :-
    (   catch(nb_getval(Global, Current), _, fail)
    ->  Value = Current
    ;   Value = 0
    ).

codegen_report_print(no) :-
    !.
codegen_report_print(yes) :-
    (   catch(nb_getval('$cocolog_call_list', Reversed), _, fail)
    ->  reverse(Reversed, Calls)
    ;   Calls = []
    ),
    cocolog_report_calls(Calls, 1),
    codegen_report(report(Calls0, Prompt, Completion, Reasoning, CacheHit,
                          Total, Seconds)),
    format(user_error,
           'codegen: ~w call(s), ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [Calls0, Prompt, Completion, Total, Reasoning, CacheHit, Seconds]).

cocolog_report_calls([], _).
cocolog_report_calls([call(S, P, C, R, H, T)|Rest], N) :-
    format(user_error,
           'codegen call ~w: ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [N, P, C, T, R, H, S]),
    N1 is N + 1,
    cocolog_report_calls(Rest, N1).

%% ---- CLI ---------------------------------------------------------------

main :-
    current_prolog_flag(argv, [_|Args]),
    (   cocolog_args(Args, args(SpecFile, Goal, OutFile, Report, DryRun,
                                RunOptions, Overrides))
    ->  catch(cocolog_main(SpecFile, Goal, OutFile, Report, DryRun,
                           RunOptions, Overrides),
              error(codegen_error(Kind, Detail), _),
              ( codegen_report_print(Report),
                format(user_error, 'codegen: ~w~n~s~n', [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/cocolog/codegen.pl -- SPEC.txt [--goal G] [--skill FILE] [--expect FILE] [--attempts N] [--timeout MS] [--budget N] [--keep DIR] [--dry-run] [--key-env NAME] [--temperature T] [--max-tokens N] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.pl]~n", []),
        halt(1)
    ).

cocolog_main(SpecFile, Goal, OutFile, Report, DryRun, RunOptions, Overrides) :-
    read_file_to_codes(SpecFile, Codes),
    atom_codes(Spec, Codes),
    (   DryRun == yes
    ->  cocolog_run_option(RunOptions, skill, none, SkillFile),
        cocolog_skill_text(SkillFile, Skill),
        cocolog_system_prompt(Skill, System),
        cocolog_user_prompt(Spec, Goal, Prompt),
        format("SYSTEM~n~s~n~nUSER~n~s~n", [System, Prompt]),
        codegen_report_reset,
        codegen_report_print(Report)
    ;   codegen_cocolog_from(Spec, Goal, Overrides, RunOptions, Code),
        (   OutFile == none
        ->  format("~s~n", [Code])
        ;   atom_concat(Code, '\n', Text),
            atom_codes(Text, TextCodes),
            write_file_from_codes(OutFile, TextCodes)
        ),
        codegen_report_print(Report)
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
