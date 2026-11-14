%% coding/c/codegen.pl -- C code from a written requirement.
%%
%%     cocolog -s coding/c/codegen.pl -- SPEC.txt [flags] [OUT.c]
%%
%% A requirement goes to a language model as a CONTRACT: C17, one complete
%% program, no Markdown fences, no prose. The reply is compiled, and a
%% failed compile is repaired with the compiler's own diagnostic. With
%% `--tests', the program is also run on each case under the sanitizers
%% and a wrong answer is repaired the same way. The model is used with the
%% effort defaults in `coding/options.pl' -- both `none' -- so the
%% thinking this repository does is not paid for twice.
%%
%% The library is tier 2 and lives in the cocolog checkout beside this
%% repository, so run from the repository root with its PARENT on the
%% library path:
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/c/codegen.pl -- SPEC.txt out.c
%%
%% The provider, model and endpoint are `coding/options.pl''s
%% `codegen_default(provider, ...)', `model' and `base_url' facts; a
%% call's provider(P), model(M) or base_url(U) overrides any of them. The
%% key is read from the environment variable the options name --
%% `REASONING_API_KEY' by default, or `key_env(NAME)' in Overrides. It is
%% never written here.
%%
%%     --tests FILE     run the cases in FILE after compiling
%%     --auto-tests     ask the model for test cases, verify them with an
%%                      independent reference program, then run them
%%     --cases-effort L reasoning effort for the auto cases (default high)
%%     --verify-model M model for the reference check (default: the second
%%                      model of a known pair, otherwise the code model)
%%     --verify-provider P  provider for the reference check (default auto:
%%                      the code call's provider)
%%     --verify-base-url U  endpoint for that provider
%%     --verify-key-env NAME  key variable for that provider
%%     --contract FILE  take the checklist from controlled-English FILE
%%     --keep DIR       write every attempt's prompt, code and diagnostic
%%     --attempts N     try at most N times (default 3)
%%     --timeout MS     let one case run MS milliseconds (default 3000)
%%     --budget N       stop before a repair once N tokens are spent
%%     --cflags FLAGS   extra clang arguments (default none)
%%     --analyze        run clang --analyze before accepting a reply
%%     --dry-run        print the first prompt and exit, no model call
%%     --key-env NAME   read the API key from NAME
%%     --temperature T  temperature(T) in the call
%%     --max-tokens N   max_tokens(N) in the call
%%     --provider P     provider(P) in the call
%%     --model M        model(M) in the call
%%     --base-url U     base_url(U) in the call
%%     --effort E       effort(E) in the call
%%     --report         print calls and token usage to stderr
%%
%% The three of provider, model and base URL are one setting: a provider
%% chosen alone keeps library(llm)'s model and endpoint for that provider.
%% A contract file replaces the keyword reading of the requirement; its
%% sentences are the shapes `coding/contract.pl' lists, and one the
%% reasoner reads as no obligation is an error, not a silent fallback.
%%
%%     codegen_c(+Spec, -Code)
%%     codegen_c(+Spec, +Overrides, -Code)
%%         Code is the reply with any Markdown fence removed. One call: the
%%         reply is not compiled. Overrides are library(llm) options plus
%%         provider(P), model(M) and base_url(U); either effort name
%%         replaces the default.
%%
%%     codegen_c_compiled(+Spec, -Code)
%%     codegen_c_compiled(+Spec, +Overrides, -Code)
%%         Code is a reply that compiles with
%%         `clang -std=c17 -Wall -Wextra -O0'. The requirement's words are
%%         read by `coding/obligations.pl' for the checks they imply, and
%%         the prompt carries that checklist on every attempt. A failed
%%         compile goes back to the model with the compiler's diagnostic
%%         and the previous program, up to three attempts; then
%%         error(codegen_error(compile_failed, Diagnostic), _) is thrown.
%%         With analyze(yes), a static-analyzer finding is analyze_failed.
%%
%%     codegen_c_tested(+Spec, +Cases, -Code)
%%     codegen_c_tested(+Spec, +Cases, +Overrides, -Code)
%%         the compiled path, and then each case(Input, Expected) is run
%%         against a binary built with AddressSanitizer and
%%         UndefinedBehaviorSanitizer. A wrong case, or a sanitizer report,
%%         goes back like a failed compile; the third failure throws
%%         error(codegen_error(test_failed, Diagnostic), _). Cases and
%%         the cases file are described in `coding/compile.pl'. Cases may
%%         be `auto': the model is asked for test cases first, a second
%%         model (where the pair is known, or the provider's model when
%%         --verify-provider names one) writes an independent reference
%%         program from the same requirement, and a case whose expected
%%         answer the reference does not reproduce is dropped. With analyze(yes), a
%%         static-analyzer finding is analyze_failed.
%%
%%     codegen_cases(+Spec, -Cases)
%%     codegen_cases(+Spec, +Overrides, -Cases)
%%     codegen_cases(+Spec, +Overrides, +CasesEffort, -Cases)
%%         one model call that writes test cases for the requirement in
%%         the text-block format `# input'/`# expected'. CasesEffort
%%         defaults to `high', because a wrong expected output can mislead
%%         a repair; it is a library(llm) effort level. These are the raw
%%         cases: the `auto' path of codegen_c_from/6 verifies them with a
%%         reference program. The call is in codegen_report/1's totals.
%%
%%     codegen_c_from(+Spec, +Obligations, +Cases, +Overrides, -Code)
%%         the loop itself, the checklist already decided: keyword
%%         obligations, `codegen_contract_obligations/2' from
%%         `coding/contract.pl', or a list a caller wrote. Cases is [] for
%%         a compile-only run.
%%
%%     c_compile_check(+Code, -Verdict)
%%     c_test_check(+Code, +Cases, -Verdict)
%%         from `coding/compile.pl'; the checks the repair loop uses.
%%
%%     codegen_report(-Report)
%%         report(Calls, Prompt, Completion, Reasoning, CacheHit, Total,
%%         Seconds), the last top-level generation's calls, tokens and
%%         wall time. `--report' prints it.
%%
%%     codegen_report_calls(-Calls)
%%         call(Seconds, Prompt, Completion, Reasoning, CacheHit, Total),
%%         one per provider call in order. `--report' prints these too.
%%
%%     main/0
%%         the program: SPEC.txt, the flags, then an optional OUT.c;
%%         stdout otherwise. It uses codegen_c_tested/4 when tests are
%%         given and exits 1 if no reply passes.

:- use_module(library(llm)).
:- use_module('coding/options.pl').
:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module('coding/compile.pl').

codegen_c(Spec, Code) :-
    codegen_c(Spec, [], Code).

codegen_c(Spec, Overrides, Code) :-
    codegen_report_reset,
    get_time(Start),
    codegen_prompt(Spec, Prompt),
    catch(codegen_call(Prompt, Overrides, Code), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

codegen_call(Prompt, Overrides, Code) :-
    codegen_llm('You are a C17 programmer. Output only C source code, no Markdown fences, no explanation.',
                Prompt, Overrides, Reply),
    codegen_strip_fence(Reply, Code).

codegen_llm(System, Prompt, Overrides, Reply) :-
    codegen_options(Overrides, Options),
    codegen_key_env(Overrides, KeyVar),
    llm_opt(Options, provider, Provider),
    codegen_base_url(Overrides, Provider, BaseUrl),
    codegen_use_endpoint(Provider, BaseUrl, KeyVar),
    get_time(CallStart),
    llm_chat([msg(system, System), msg(user, Prompt)], Options, Reply),
    get_time(CallEnd),
    CallSeconds is CallEnd - CallStart,
    codegen_report_add(CallSeconds).

%% ---- the run report ----------------------------------------------------

codegen_report_reset :-
    nb_setval('$codegen_calls', 0),
    nb_setval('$codegen_prompt', 0),
    nb_setval('$codegen_completion', 0),
    nb_setval('$codegen_reasoning', 0),
    nb_setval('$codegen_cache', 0),
    nb_setval('$codegen_total', 0),
    nb_setval('$codegen_seconds', 0.0),
    nb_setval('$codegen_verify_model', none),
    nb_setval('$codegen_verify_provider', none),
    nb_setval('$codegen_call_list', []).

codegen_report_finish(Start) :-
    get_time(End),
    Seconds is End - Start,
    nb_setval('$codegen_seconds', Seconds).

codegen_report_add(CallSeconds) :-
    nb_getval('$codegen_calls', Calls0),
    Calls is Calls0 + 1,
    nb_setval('$codegen_calls', Calls),
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  codegen_usage_first(Pairs, prompt_tokens, input_tokens, Prompt),
        codegen_usage_first(Pairs, completion_tokens, output_tokens,
                            Completion),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R0, Details),
            integer(R0)
        ->  Reasoning = R0
        ;   codegen_usage_found(Pairs, reasoning_tokens, R1)
        ->  Reasoning = R1
        ;   Reasoning = 0
        ),
        codegen_usage_first(Pairs, prompt_cache_hit_tokens,
                            cache_read_input_tokens, CacheHit),
        (   codegen_usage_number(Pairs, total_tokens, Total0),
            Total0 > 0
        ->  Total = Total0
        ;   Total is Prompt + Completion
        ),
        codegen_bump('$codegen_prompt', Prompt),
        codegen_bump('$codegen_completion', Completion),
        codegen_bump('$codegen_reasoning', Reasoning),
        codegen_bump('$codegen_cache', CacheHit),
        codegen_bump('$codegen_total', Total),
        codegen_call_record(call(CallSeconds, Prompt, Completion, Reasoning,
                                 CacheHit, Total))
    ;   codegen_call_record(call(CallSeconds, 0, 0, 0, 0, 0))
    ).

codegen_call_record(Call) :-
    (   catch(nb_getval('$codegen_call_list', Calls), _, fail)
    ->  true
    ;   Calls = []
    ),
    nb_setval('$codegen_call_list', [Call|Calls]).

codegen_report_calls(Calls) :-
    (   catch(nb_getval('$codegen_call_list', Reversed), _, fail)
    ->  reverse(Reversed, Calls)
    ;   Calls = []
    ).

codegen_usage_first(Pairs, Key, Alternate, Number) :-
    (   codegen_usage_found(Pairs, Key, Found)
    ->  Number = Found
    ;   codegen_usage_found(Pairs, Alternate, Found)
    ->  Number = Found
    ;   Number = 0
    ).

codegen_usage_found(Pairs, Key, Number) :-
    memberchk(Key-Value, Pairs),
    integer(Value),
    Number = Value.

codegen_usage_number(Pairs, Key, Number) :-
    (   codegen_usage_found(Pairs, Key, Found)
    ->  Number = Found
    ;   Number = 0
    ).

codegen_bump(Global, Number) :-
    nb_getval(Global, Old),
    New is Old + Number,
    nb_setval(Global, New).

codegen_report(report(Calls, Prompt, Completion, Reasoning, CacheHit, Total, Seconds)) :-
    codegen_global('$codegen_calls', Calls),
    codegen_global('$codegen_prompt', Prompt),
    codegen_global('$codegen_completion', Completion),
    codegen_global('$codegen_reasoning', Reasoning),
    codegen_global('$codegen_cache', CacheHit),
    codegen_global('$codegen_total', Total),
    codegen_report_seconds(Seconds).

codegen_report_seconds(Seconds) :-
    (   catch(nb_getval('$codegen_seconds', Found), _, fail),
        float(Found)
    ->  Seconds = Found
    ;   Seconds = 0.0
    ).

%% A report asked before any generation (an early error, say) is zeros.
codegen_global(Global, Value) :-
    (   catch(nb_getval(Global, Current), _, fail)
    ->  Value = Current
    ;   Value = 0
    ).

codegen_report_print(no) :-
    !.
codegen_report_print(yes) :-
    codegen_report_calls(Calls),
    codegen_report_print_calls(Calls, 1),
    codegen_report_verify_model,
    codegen_report(report(Calls0, Prompt, Completion, Reasoning, CacheHit, Total,
                          Seconds)),
    format(user_error,
           'codegen: ~w call(s), ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [Calls0, Prompt, Completion, Total, Reasoning, CacheHit, Seconds]).

codegen_report_verify_model :-
    (   catch(nb_getval('$codegen_verify_model', Model), _, fail),
        Model \== none
    ->  (   catch(nb_getval('$codegen_verify_provider', Provider), _, fail),
            Provider \== none
        ->  format(user_error, 'codegen: reference model ~w via ~w~n',
                   [Model, Provider])
        ;   format(user_error, 'codegen: reference model ~w~n', [Model])
        )
    ;   true
    ).

codegen_report_print_calls([], _).
codegen_report_print_calls([call(CallSeconds, Prompt, Completion, Reasoning,
                                 CacheHit, Total)|Rest], N) :-
    format(user_error,
           'codegen call ~w: ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [N, Prompt, Completion, Total, Reasoning, CacheHit, CallSeconds]),
    N1 is N + 1,
    codegen_report_print_calls(Rest, N1).

%% codegen_c_compiled(+Spec, -Code)
%% codegen_c_compiled(+Spec, +Overrides, -Code)
%%
%% The reply is compiled with clang after every call. A compile failure
%% goes back with the compiler's diagnostic and the previous program, up
%% to three attempts. The obligation checklist is in every attempt.
codegen_c_compiled(Spec, Code) :-
    codegen_c_compiled(Spec, [], Code).

codegen_c_compiled(Spec, Overrides, Code) :-
    codegen_obligations(Spec, Obligations),
    codegen_c_from(Spec, Obligations, [], Overrides, Code).

%% codegen_c_from(+Spec, +Obligations, +Cases, +Overrides, -Code)
%% codegen_c_from(+Spec, +Obligations, +Cases, +Overrides, +RunOptions, -Code)
%%
%% The loop itself, with the checklist already decided: keyword
%% obligations, `codegen_contract_obligations/2' from
%% `coding/contract.pl', or a list a caller wrote. Cases is [] for a
%% compile-only run. RunOptions is a list of
%% `attempts(N)' (default 3), `case_timeout(Ms)' (default 3000),
%% `cflags(Flags)' (default ''), `budget(N)' (no budget unless said),
%% `analyze(yes)' (off unless said), `cases_effort(Level)' (default
%% `high'), `verify_model(M)' (default `auto': the second model of a known
%% pair, otherwise the code model), `verify_provider(P)' (default `auto':
%% the code call's provider), `verify_base_url(U)' and `verify_key_env(K)'
%% (default `none') and `keep(Dir)'; with a keep
%% directory, every attempt's prompt, code and diagnostic is written there
%% as attempt-N.prompt.txt, attempt-N.c and attempt-N.diag.txt. A
%% static-analyzer finding is the failure kind analyze_failed.
codegen_c_from(Spec, Obligations, Cases, Overrides, Code) :-
    codegen_c_from(Spec, Obligations, Cases, Overrides, [], Code).

codegen_c_from(Spec, Obligations, Cases0, Overrides, RunOptions, Code) :-
    codegen_run_prepare(RunOptions, Max, Timeout, CFlags, Budget, Analyze,
                        CasesEffort, VerifySettings0),
    codegen_run_option(RunOptions, keep, none, Keep),
    codegen_report_reset,
    get_time(Start),
    catch(( codegen_cases_ready(Cases0, Spec, Overrides, Keep,
                                case_settings(CasesEffort, VerifySettings0,
                                              Timeout, CFlags), Cases),
            codegen_attempt(1, Max, Spec, Obligations, Cases, Overrides,
                            Keep, check(Timeout, CFlags), Analyze, Budget,
                            none, Code)
          ), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

%% Cases are given, or `auto' asks the model for them before the first
%% code call. An independent reference program is generated from the same
%% requirement and run on every generated input; a case whose expected
%% answer it does not reproduce is dropped. The calls are part of the
%% run's report; `--keep' writes the verified cases, the rejected ones and
%% the reference program.
codegen_cases_ready(auto, Spec, Overrides, Keep,
                    case_settings(CasesEffort, VerifySettings, Timeout, CFlags),
                    Cases) :-
    !,
    codegen_generate_cases(Spec, Overrides, CasesEffort, Raw),
    codegen_verify_cases(Spec, Overrides, Keep, CasesEffort, VerifySettings,
                         Timeout, CFlags, Raw, Cases),
    codegen_keep_cases(Keep, Cases).
codegen_cases_ready(Cases, _, _, _, _, Cases).

codegen_run_prepare(RunOptions, Max, Timeout, CFlags, Budget, Analyze,
                    CasesEffort, VerifySettings) :-
    codegen_run_option(RunOptions, attempts, 3, Max0),
    codegen_run_check(attempts, Max0),
    Max = Max0,
    codegen_run_option(RunOptions, case_timeout, 3000, Timeout0),
    codegen_run_check(case_timeout, Timeout0),
    Timeout = Timeout0,
    codegen_run_option(RunOptions, cflags, '', Flags0),
    codegen_run_cflags(Flags0, CFlags),
    codegen_run_option(RunOptions, budget, none, Budget0),
    codegen_run_budget(Budget0, Budget),
    codegen_run_option(RunOptions, analyze, no, Analyze0),
    codegen_run_analyze(Analyze0, Analyze),
    codegen_run_option(RunOptions, cases_effort, high, CasesEffort0),
    codegen_run_cases_effort(CasesEffort0, CasesEffort),
    codegen_run_option(RunOptions, verify_provider, auto, VerifyProvider0),
    codegen_run_auto_atom(verify_provider, VerifyProvider0, VerifyProvider),
    codegen_run_option(RunOptions, verify_model, auto, VerifyModel0),
    codegen_run_auto_atom(verify_model, VerifyModel0, VerifyModel),
    codegen_run_option(RunOptions, verify_base_url, none, VerifyBaseUrl0),
    codegen_run_optional_atom(verify_base_url, VerifyBaseUrl0, VerifyBaseUrl),
    codegen_run_option(RunOptions, verify_key_env, none, VerifyKeyEnv0),
    codegen_run_optional_atom(verify_key_env, VerifyKeyEnv0, VerifyKeyEnv),
    VerifySettings = verify(VerifyProvider, VerifyModel, VerifyBaseUrl,
                            VerifyKeyEnv),
    codegen_run_option(RunOptions, keep, none, Keep),
    codegen_keep_prepare(Keep).

codegen_run_cases_effort(Level, Level) :-
    atom(Level),
    !.
codegen_run_cases_effort(Value, _) :-
    format(atom(Msg), 'cases_effort must be an atom, not ~w', [Value]),
    throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8)).

codegen_run_auto_atom(auto, auto) :-
    !.
codegen_run_auto_atom(_Key, Value, Value) :-
    atom(Value),
    !.
codegen_run_auto_atom(Key, Value, _) :-
    format(atom(Msg), '~w must be an atom or auto, not ~w', [Key, Value]),
    throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8)).

codegen_run_optional_atom(none, none) :-
    !.
codegen_run_optional_atom(_Key, Value, Value) :-
    atom(Value),
    !.
codegen_run_optional_atom(Key, Value, _) :-
    format(atom(Msg), '~w must be an atom or none, not ~w', [Key, Value]),
    throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8)).

codegen_run_analyze(yes, yes) :-
    !.
codegen_run_analyze(no, no) :-
    !.
codegen_run_analyze(Value, _) :-
    format(atom(Msg), 'analyze must be yes or no, not ~w', [Value]),
    throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8)).

codegen_run_budget(none, none) :-
    !.
codegen_run_budget(N, N) :-
    integer(N),
    N > 0,
    !.
codegen_run_budget(Value, _) :-
    format(atom(Msg), 'budget must be a positive integer, not ~w', [Value]),
    throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8)).

codegen_run_cflags(Flags, Flags) :-
    (   atom(Flags)
    ->  true
    ;   format(atom(Msg), 'cflags must be an atom, not ~w', [Flags]),
        throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8))
    ).

codegen_run_option(Options, Key, Default, Value) :-
    (   member(Option, Options),
        functor(Option, Key, 1),
        arg(1, Option, Found)
    ->  Value = Found
    ;   Value = Default
    ).

codegen_run_check(Key, Value) :-
    (   integer(Value),
        Value > 0
    ->  true
    ;   format(atom(Msg), '~w must be a positive integer, not ~w', [Key, Value]),
        throw(error(codegen_error(run_option, Msg), codegen_run_prepare/8))
    ).

codegen_keep_prepare(none) :-
    !.
codegen_keep_prepare(dir(Dir)) :-
    (   catch(exists_directory(Dir), _, fail)
    ->  true
    ;   catch(make_directory(Dir), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot make the keep directory ~s', [Dir]),
        throw(error(codegen_error(keep_dir, Msg), codegen_keep_prepare/1))
    ).

codegen_keep_attempt(none, _, _, _) :-
    !.
codegen_keep_attempt(dir(Dir), Attempt, Kind, Text) :-
    format(atom(Name), 'attempt-~w.~w', [Attempt, Kind]),
    codegen_keep_file(Dir, Name, Text).

%% The auto-generated cases, in the format c_parse_text_cases/2 reads, so
%% a run's oracle can be read after the fact.
codegen_keep_cases(none, _) :-
    !.
codegen_keep_cases(dir(Dir), Cases) :-
    codegen_cases_text(Cases, Text),
    codegen_keep_file(Dir, 'auto-cases.txt', Text).

codegen_cases_text([], '').
codegen_cases_text(Cases, Text) :-
    Cases \== [],
    findall(Block,
            (   member(Case, Cases),
                codegen_case_block(Case, Block)
            ),
            Blocks),
    atomic_list_concat(Blocks, '', Text).

codegen_case_block(case(Input, Expected), Block) :-
    codegen_terminated(Expected, Terminated),
    format(atom(Block), '# input~n~s# expected~n~s', [Input, Terminated]).
codegen_case_block(case(Input, Expected, Exit), Block) :-
    codegen_terminated(Expected, Terminated),
    format(atom(Block), '# input~n~s# expected~n~s# exit ~w~n',
           [Input, Terminated, Exit]).

codegen_terminated(Atom, Terminated) :-
    (   sub_atom(Atom, _, 1, 0, '\n')
    ->  Terminated = Atom
    ;   atom_concat(Atom, '\n', Terminated)
    ).

codegen_keep_file(Dir, Name, Text) :-
    atom_concat(Dir, '/', Prefix),
    atom_concat(Prefix, Name, File),
    atom_concat(Text, '\n', Terminated),
    atom_codes(Terminated, Codes),
    (   catch(write_file_from_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot write ~s', [File]),
        throw(error(codegen_error(keep_dir, Msg), codegen_keep_file/3))
    ).

%% codegen_c_tested(+Spec, +Cases, -Code)
%% codegen_c_tested(+Spec, +Cases, +Overrides, -Code)
%%
%% The same loop, and a compiling reply is run on each case. A case that
%% answers wrong is repaired like a compile failure.
codegen_c_tested(Spec, Cases, Code) :-
    codegen_c_tested(Spec, Cases, [], Code).

codegen_c_tested(Spec, Cases, Overrides, Code) :-
    codegen_obligations(Spec, Obligations),
    codegen_c_from(Spec, Obligations, Cases, Overrides, Code).

%% codegen_cases(+Spec, -Cases)
%% codegen_cases(+Spec, +Overrides, -Cases)
%% codegen_cases(+Spec, +Overrides, +CasesEffort, -Cases)
%%
%% One model call writes test cases in the `# input'/`# expected' format.
%% These are raw cases; the `auto' path of codegen_c_from/6 runs a
%% reference program over them and drops disagreements. The default
%% effort is `high'; a caller may name another level.
codegen_cases(Spec, Cases) :-
    codegen_cases(Spec, [], high, Cases).

codegen_cases(Spec, Overrides, Cases) :-
    codegen_cases(Spec, Overrides, high, Cases).

codegen_cases(Spec, Overrides, CasesEffort, Cases) :-
    codegen_report_reset,
    get_time(Start),
    catch(codegen_generate_cases(Spec, Overrides, CasesEffort, Cases), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

codegen_generate_cases(Spec, Overrides, CasesEffort, Cases) :-
    codegen_case_overrides(Overrides, CasesEffort, CaseOverrides),
    codegen_case_prompt(Spec, Prompt),
    codegen_llm('You write black-box test cases for C17 programs. Output only the requested test-case blocks, with no prose, numbering or Markdown fences.',
                Prompt, CaseOverrides, Reply),
    codegen_strip_fence(Reply, Text),
    codegen_case_reply(Text, Cases).

%% The case call has an effort of its own: the code call's effort is no
%% measure of how carefully an oracle should be written.
codegen_case_overrides(Overrides, CasesEffort, CaseOverrides) :-
    exclude(codegen_case_effort, Overrides, Rest),
    CaseOverrides = [effort(CasesEffort)|Rest].

codegen_case_effort(effort(_)).
codegen_case_effort(reasoning_effort(_)).

codegen_case_reply(Text, Cases) :-
    (   catch(c_parse_text_cases(Text, Cases0), _, fail)
    ->  true
    ;   codegen_case_error('the reply is not a sequence of "# input"/"# expected" blocks')
    ),
    (   Cases0 == []
    ->  codegen_case_error('the reply has no test case')
    ;   length(Cases0, Count),
        (   Count =< 20
        ->  Cases = Cases0
        ;   format(atom(Msg), 'the reply has ~w test cases; at most 20 are used',
                   [Count]),
            codegen_case_error(Msg)
        )
    ).

codegen_case_error(Msg) :-
    throw(error(codegen_error(cases_auto, Msg), codegen_generate_cases/4)).

%% The independent check: a second model, from a second provider when one
%% is named, writes a high-effort program from the same requirement and it
%% is run on each generated input. Only expectations it reproduces
%% survive. It never sees the generated cases.
codegen_verify_cases(Spec, Overrides, Keep, CasesEffort, VerifySettings0,
                     Timeout, CFlags, Raw, Cases) :-
    codegen_verify_settings(Overrides, CasesEffort, VerifySettings0,
                            RefOverrides, VerifyProvider, VerifyModel),
    nb_setval('$codegen_verify_model', VerifyModel),
    nb_setval('$codegen_verify_provider', VerifyProvider),
    codegen_reference_prompt(Spec, Prompt),
    codegen_llm('You are a C17 programmer writing an independent reference implementation for black-box testing. Output only the complete C source, with no Markdown fences and no explanation.',
                Prompt, RefOverrides, Reply),
    codegen_strip_fence(Reply, Reference),
    codegen_keep_reference(Keep, Reference),
    codegen_case_inputs(Raw, Inputs),
    c_run_outputs(Reference, Inputs, Timeout, CFlags, Outputs, Verdict),
    (   Verdict == ok
    ->  true
    ;   Verdict = fail(Diag),
        format(atom(Msg), 'the reference program did not compile: ~s',
               [Diag]),
        codegen_case_error(Msg)
    ),
    codegen_verified_cases(Raw, Outputs, Cases, Rejected),
    codegen_keep_rejected(Keep, Rejected),
    (   Cases == []
    ->  codegen_case_error('the reference program disagreed with every generated case')
    ;   true
    ).

%% verify(Provider, Model, BaseUrl, KeyEnv); `auto' keeps the code call's
%% provider and takes the second model of a known pair, `none' leaves an
%% endpoint or key variable to the provider's own resolution.
codegen_verify_settings(Overrides, CasesEffort,
                        verify(Provider0, Model0, BaseUrl0, KeyEnv0),
                        RefOverrides, VerifyProvider, VerifyModel) :-
    codegen_provider(Overrides, MainProvider),
    codegen_model(Overrides, MainProvider, MainModel),
    (   Provider0 == auto
    ->  VerifyProvider = MainProvider
    ;   VerifyProvider = Provider0
    ),
    codegen_verify_model_choice(Provider0, Model0, MainProvider, MainModel,
                                VerifyProvider, VerifyModel),
    codegen_verify_base_url(Provider0, BaseUrl0, Overrides, VerifyProvider,
                            BaseUrl),
    (   KeyEnv0 \== none
    ->  KeyEnv = KeyEnv0
    ;   codegen_key_env(Overrides, KeyEnv)
    ),
    codegen_case_overrides(Overrides, CasesEffort, Base),
    exclude(codegen_verify_endpoint_option, Base, Rest),
    (   BaseUrl == none
    ->  Endpoint = [provider(VerifyProvider), model(VerifyModel),
                    key_env(KeyEnv)]
    ;   Endpoint = [base_url(BaseUrl), provider(VerifyProvider),
                    model(VerifyModel), key_env(KeyEnv)]
    ),
    append(Endpoint, Rest, RefOverrides).

codegen_verify_model_choice(auto, auto, MainProvider, MainModel, _, Model) :-
    !,
    (   codegen_second_model(MainProvider, MainModel, Second)
    ->  Model = Second
    ;   Model = MainModel
    ).
codegen_verify_model_choice(auto, Model, _, _, _, Model) :-
    !.
codegen_verify_model_choice(_, auto, MainProvider, MainModel, VerifyProvider,
                            Model) :-
    (   VerifyProvider == MainProvider,
        codegen_second_model(MainProvider, MainModel, Second)
    ->  Model = Second
    ;   codegen_verify_default_model(VerifyProvider, Default)
    ->  Model = Default
    ;   format(atom(Msg), 'verify_model is needed for provider ~w',
               [VerifyProvider]),
        throw(error(codegen_error(run_option, Msg), codegen_verify_settings/6))
    ).
codegen_verify_model_choice(_, Model, _, _, _, Model).

codegen_verify_default_model(anthropic, 'claude-opus-5-5').
codegen_verify_default_model(openai, 'deepseek-reasoner').

codegen_verify_base_url(auto, none, Overrides, VerifyProvider, BaseUrl) :-
    !,
    (   catch(codegen_base_url(Overrides, VerifyProvider, Found), _, fail)
    ->  BaseUrl = Found
    ;   format(atom(Msg), 'verify_base_url is needed for provider ~w',
               [VerifyProvider]),
        throw(error(codegen_error(run_option, Msg), codegen_verify_settings/6))
    ).
codegen_verify_base_url(auto, BaseUrl, _, _, BaseUrl) :-
    !.
codegen_verify_base_url(_, BaseUrl, _, _, BaseUrl) :-
    BaseUrl \== none,
    !.
codegen_verify_base_url(_, none, _, VerifyProvider, _) :-
    format(atom(Msg), 'verify_base_url is needed for provider ~w',
           [VerifyProvider]),
    throw(error(codegen_error(run_option, Msg), codegen_verify_settings/6)).

codegen_second_model(openai, 'deepseek-flash', 'deepseek-reasoner').
codegen_second_model(openai, 'deepseek-reasoner', 'deepseek-chat').
codegen_second_model(anthropic, 'claude-sonnet-4-5', 'claude-opus-5-5').

codegen_verify_endpoint_option(provider(_)).
codegen_verify_endpoint_option(model(_)).
codegen_verify_endpoint_option(base_url(_)).
codegen_verify_endpoint_option(key_env(_)).

codegen_case_inputs([], []).
codegen_case_inputs([case(Input, _)|Cases], [Input|Inputs]) :-
    codegen_case_inputs(Cases, Inputs).
codegen_case_inputs([case(Input, _, _)|Cases], [Input|Inputs]) :-
    codegen_case_inputs(Cases, Inputs).

codegen_verified_cases([], [], [], []).
codegen_verified_cases([Case|Cases], [output(Actual, Exit, Error)|Outputs],
                       Kept, Rejected) :-
    codegen_verified_cases(Cases, Outputs, Kept0, Rejected0),
    (   codegen_case_holds(Case, Actual, Exit, Error)
    ->  Kept = [Case|Kept0],
        Rejected = Rejected0
    ;   Kept = Kept0,
        Rejected = [Case|Rejected0]
    ).

codegen_case_holds(case(_, Expected), Actual, Exit, Error) :-
    codegen_case_holds(case(_, Expected, 0), Actual, Exit, Error).
codegen_case_holds(case(_, Expected, ExpectedExit), Actual, Exit, Error) :-
    Error == none,
    Exit =:= ExpectedExit,
    c_norm(Expected, Norm),
    Actual == Norm.

codegen_keep_reference(none, _) :-
    !.
codegen_keep_reference(dir(Dir), Reference) :-
    codegen_keep_file(Dir, 'reference.c', Reference).

codegen_keep_rejected(none, _) :-
    !.
codegen_keep_rejected(dir(Dir), Cases) :-
    codegen_cases_text(Cases, Text),
    codegen_keep_file(Dir, 'auto-cases-rejected.txt', Text).

codegen_attempt(Attempt, Max, Spec, Obligations, Cases, Overrides, Keep,
                check(Timeout, CFlags), Analyze, Budget, Prev, Code) :-
    codegen_guided_prompt(Spec, Obligations, Prev, Prompt),
    codegen_keep_attempt(Keep, Attempt, 'prompt.txt', Prompt),
    codegen_call(Prompt, Overrides, Code0),
    codegen_keep_attempt(Keep, Attempt, 'c', Code0),
    codegen_verdict(Code0, Cases, check(Timeout, CFlags), Analyze, Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Kind, Diag),
        codegen_keep_attempt(Keep, Attempt, 'diag.txt', Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(Kind, Diag), codegen_c_compiled/3))
        ;   budget_exhausted(Budget)
        ->  codegen_budget_error(Budget)
        ;   Next is Attempt + 1,
            codegen_attempt(Next, Max, Spec, Obligations, Cases, Overrides,
                            Keep, check(Timeout, CFlags), Analyze, Budget,
                            prev(Code0, Diag), Code)
        )
    ).

budget_exhausted(none) :-
    !,
    fail.
budget_exhausted(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    Total >= Budget.

codegen_budget_error(Budget) :-
    codegen_report(report(_, _, _, _, _, Total, _)),
    format(atom(Msg), 'the run reached ~w tokens, its budget of ~w',
           [Total, Budget]),
    throw(error(codegen_error(budget_exceeded, Msg), codegen_c_compiled/3)).

codegen_verdict(Code, [], check(_, CFlags), Analyze, Verdict) :-
    c_compile_check(Code, CFlags, Check),
    (   Check == ok
    ->  codegen_analyze_verdict(Code, CFlags, Analyze, Verdict)
    ;   Check = fail(Diag),
        Verdict = fail(compile_failed, Diag)
    ).
codegen_verdict(Code, Cases, check(Timeout, CFlags), Analyze, Verdict) :-
    Cases \== [],
    c_test_check(Code, Cases, Timeout, CFlags, Check),
    (   Check == ok
    ->  codegen_analyze_verdict(Code, CFlags, Analyze, Verdict)
    ;   Check = fail(compile, Diag)
    ->  Verdict = fail(compile_failed, Diag)
    ;   Check = fail(test, Diag),
        Verdict = fail(test_failed, Diag)
    ).

codegen_analyze_verdict(_Code, _CFlags, no, ok) :-
    !.
codegen_analyze_verdict(Code, CFlags, yes, Verdict) :-
    c_analyze_check(Code, CFlags, Check),
    (   Check == ok
    ->  Verdict = ok
    ;   Check = fail(Diag),
        Verdict = fail(analyze_failed, Diag)
    ).

codegen_guided_prompt(Spec, Obligations, Prev, Prompt) :-
    codegen_obligation_lines(Obligations, Lines),
    (   Lines == []
    ->  codegen_prompt(Spec, Base)
    ;   atomic_list_concat(Lines, '\n', Checklist),
        format(atom(Base),
               'Write a complete C17 program for this requirement. Output only the C source, with no Markdown fences and no explanation.~n~nThe requirement implies these checks. The program must satisfy every one:~n~s~n~nRequirement:~n~s',
               [Checklist, Spec])
    ),
    (   Prev == none
    ->  Prompt = Base
    ;   Prev = prev(Previous, Diag),
        format(atom(Prompt),
               '~s~n~nYour previous C program did not pass verification. The report said:~n~s~nThe previous program was:~n~s~nWrite a corrected complete C17 program. Output only the C source.',
               [Base, Diag, Previous])
    ).

%% codegen_prompt_for(+Spec, +Contract, -Prompt)
%%
%% The first prompt a run would send. Contract is `none' for the keyword
%% reading, or a controlled-English file. No model call and no compile.
codegen_prompt_for(Spec, Contract, Prompt) :-
    codegen_obligations_for(Spec, Contract, Obligations),
    codegen_guided_prompt(Spec, Obligations, none, Prompt).

%% Point the selected provider at the endpoint and key variable the
%% options give. `llm_provider/3' is library(llm)'s dynamic
%% configuration; this is what makes the default REASONING_API_KEY rather
%% than OPENAI_API_KEY or ANTHROPIC_API_KEY, and what lets options.pl's
%% base_url reach the request. library(llm) knows two request bodies, so
%% a provider it does not know is refused here.
codegen_use_endpoint(Provider, BaseUrl, KeyVar) :-
    (   memberchk(Provider, [anthropic, openai])
    ->  retractall(llm_provider(Provider, _, _)),
        assertz(llm_provider(Provider, BaseUrl, KeyVar))
    ;   throw(error(llm_error(unknown_provider, Provider), codegen_c/3))
    ).

codegen_prompt(Spec, Prompt) :-
    format(atom(Prompt),
           'Write a complete C17 program for this requirement. Output only the C source, with no Markdown fences and no explanation.~n~n~s',
           [Spec]).

%% The case-generation prompt. The format is the one c_parse_text_cases/2
%% reads, so a reply with prose before the first block is refused.
codegen_case_prompt(Spec, Prompt) :-
    format(atom(Prompt),
'Write 6 to 10 black-box test cases for a C17 program that must satisfy this requirement:

~s

Output only test cases in exactly this format:

# input
<the exact input>
# expected
<the exact expected output>

Repeat those two blocks for every case. Rules:
- Use only input the requirement allows.
- Keep every input small: at most 20 lines and at most 100 numbers.
- If a line declares how many values follow, make the count match.
- Include the smallest or empty valid input, a typical input, and edge cases.
- The expected output must be exact; trailing whitespace is ignored.
- Do not write a program, an explanation, numbering, or Markdown fences.
- Do not put commentary between the blocks.',
           [Spec]).

%% The reference program sees the requirement and nothing else. Its sole
%% purpose is to reproduce or contradict the generated expectations.
codegen_reference_prompt(Spec, Prompt) :-
    format(atom(Prompt),
'Write a complete C17 reference implementation for this requirement. It will be used only to check generated test cases. Output only the C source, with no Markdown fences and no explanation.

~s',
           [Spec]).

%% Models still wrap code in ```c ... ``` even when told not to. A reply
%% with no fence is the code as it stands; one with block fences loses the
%% fence lines and keeps everything between them.
codegen_strip_fence(Text, Code) :-
    (   sub_atom(Text, _, _, _, '```')
    ->  split_string(Text, "\n", "", Lines0),
        exclude(codegen_fence_line, Lines0, Lines),
        findall(A, ( member(L, Lines), atom_string(A, L) ), Atoms),
        atomic_list_concat(Atoms, '\n', Code)
    ;   Code = Text
    ).

codegen_fence_line(Line) :-
    sub_string(Line, 0, 3, _, '```').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   codegen_args(Args, args(SpecFile, TestsFile, ContractFile, OutFile,
                                Report, DryRun, RunOptions, Overrides))
    ->  catch(codegen_main(SpecFile, TestsFile, ContractFile, OutFile,
                           Report, DryRun, RunOptions, Overrides),
              error(codegen_error(Kind, Detail), _),
              ( codegen_report_print(Report),
                format(user_error, 'codegen: ~w~n~s~n', [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/c/codegen.pl -- SPEC.txt [--tests CASES.txt] [--auto-tests] [--cases-effort L] [--verify-provider P] [--verify-model M] [--verify-base-url U] [--verify-key-env NAME] [--contract CONTRACT.txt] [--keep DIR] [--attempts N] [--timeout MS] [--budget N] [--cflags FLAGS] [--analyze] [--dry-run] [--key-env NAME] [--temperature T] [--max-tokens N] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.c]~n", []),
        halt(1)
    ).

codegen_main(SpecFile, TestsFile, ContractFile, OutFile, Report, DryRun,
             RunOptions, Overrides) :-
    read_file_to_codes(SpecFile, Codes),
    atom_codes(Spec, Codes),
    (   DryRun == yes
    ->  (   TestsFile == auto
        ->  codegen_case_prompt(Spec, Prompt)
        ;   codegen_prompt_for(Spec, ContractFile, Prompt)
        ),
        format("~s~n", [Prompt]),
        codegen_report_reset,
        codegen_report_print(Report)
    ;   codegen_obligations_for(Spec, ContractFile, Obligations),
        (   TestsFile == none
        ->  Cases = []
        ;   TestsFile == auto
        ->  Cases = auto
        ;   c_read_cases(TestsFile, Cases)
        ),
        codegen_c_from(Spec, Obligations, Cases, Overrides, RunOptions, Code),
        (   OutFile == none
        ->  format("~s~n", [Code])
        ;   atom_concat(Code, '\n', Text),
            atom_codes(Text, OutCodes),
            write_file_from_codes(OutFile, OutCodes)
        ),
        codegen_report_print(Report)
    ).

%% A contract file replaces the keyword reading; a contract the reasoner
%% reads as nothing is an error, not a silent fallback.
codegen_obligations_for(Spec, none, Obligations) :-
    !,
    codegen_obligations(Spec, Obligations).
codegen_obligations_for(_Spec, File, Obligations) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(contract_file, Msg), codegen_obligations_for/3))
    ),
    atom_codes(Contract, Codes),
    codegen_contract_obligations(Contract, Obligations),
    (   Obligations == []
    ->  format(atom(Msg2), 'the contract ~s read as no obligation', [File]),
        throw(error(codegen_error(contract_empty, Msg2), codegen_obligations_for/3))
    ;   true
    ).

%% SPEC.txt [flags] [OUT.c], the flags anywhere after the binary. A
%% second positional is OUT.c; a third is a usage error. One state term
%% carries the parsed fields: args(Spec, Tests, Contract, Out, Report,
%% DryRun, RunOptions, Overrides).
codegen_args(Args, ArgsTerm) :-
    codegen_args(Args, args(none, none, none, none, no, no, [], []), ArgsTerm).

codegen_args([], State, State) :-
    State = args(Spec, _, _, _, _, _, _, _),
    Spec \== none.
codegen_args(['--tests', File|Rest], args(S, _, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, File, C, O, R, D, Run, Os), A).
codegen_args(['--auto-tests'|Rest], args(S, _, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, auto, C, O, R, D, Run, Os), A).
codegen_args(['--cases-effort', E|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom(E),
    codegen_run_set(cases_effort(E), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--verify-model', M|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom(M),
    codegen_run_set(verify_model(M), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--verify-provider', P|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom(P),
    codegen_run_set(verify_provider(P), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--verify-base-url', U|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom(U),
    codegen_run_set(verify_base_url(U), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--verify-key-env', K|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom(K),
    codegen_run_set(verify_key_env(K), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--contract', File|Rest], args(S, T, none, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, File, O, R, D, Run, Os), A).
codegen_args(['--keep', Dir|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_run_set(keep(dir(Dir)), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--attempts', N|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom_number(N, N0),
    integer(N0),
    N0 > 0,
    codegen_run_set(attempts(N0), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--timeout', Ms|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom_number(Ms, Ms0),
    integer(Ms0),
    Ms0 > 0,
    codegen_run_set(case_timeout(Ms0), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--budget', N|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom_number(N, Value),
    integer(Value),
    Value > 0,
    codegen_run_set(budget(Value), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--cflags', Flags|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_run_set(cflags(Flags), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--analyze'|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_run_set(analyze(yes), Run, Run1),
    codegen_args(Rest, args(S, T, C, O, R, D, Run1, Os), A).
codegen_args(['--provider', P|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [provider(P)|Os]), A).
codegen_args(['--model', M|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [model(M)|Os]), A).
codegen_args(['--base-url', U|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [base_url(U)|Os]), A).
codegen_args(['--effort', E|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [effort(E)|Os]), A).
codegen_args(['--key-env', K|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [key_env(K)|Os]), A).
codegen_args(['--temperature', Temp|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom_number(Temp, Value),
    number(Value),
    Value >= 0,
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [temperature(Value)|Os]), A).
codegen_args(['--max-tokens', N|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    atom_number(N, Value),
    integer(Value),
    Value > 0,
    codegen_args(Rest, args(S, T, C, O, R, D, Run, [max_tokens(Value)|Os]), A).
codegen_args(['--dry-run'|Rest], args(S, T, C, O, R, _, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, R, yes, Run, Os), A).
codegen_args(['--report'|Rest], args(S, T, C, O, _, D, Run, Os), A) :-
    codegen_args(Rest, args(S, T, C, O, yes, D, Run, Os), A).
codegen_args([Arg|Rest], args(none, T, C, O, R, D, Run, Os), A) :-
    \+ codegen_flag(Arg),
    codegen_args(Rest, args(Arg, T, C, O, R, D, Run, Os), A).
codegen_args([Arg|Rest], args(S, T, C, none, R, D, Run, Os), A) :-
    S \== none,
    \+ codegen_flag(Arg),
    codegen_args(Rest, args(S, T, C, Arg, R, D, Run, Os), A).

codegen_run_set(Option, Options, [Option|Rest]) :-
    functor(Option, Key, _),
    exclude(codegen_run_key(Key), Options, Rest).

codegen_run_key(Key, Option) :-
    functor(Option, Key, _).

codegen_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').
