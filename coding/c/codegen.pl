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
%%     --contract FILE  take the checklist from controlled-English FILE
%%     --keep DIR       write every attempt's prompt, code and diagnostic
%%     --attempts N     try at most N times (default 3)
%%     --timeout MS     let one case run MS milliseconds (default 3000)
%%     --cflags FLAGS   extra clang arguments (default none)
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
%%
%%     codegen_c_tested(+Spec, +Cases, -Code)
%%     codegen_c_tested(+Spec, +Cases, +Overrides, -Code)
%%         the compiled path, and then each case(Input, Expected) is run
%%         against a binary built with AddressSanitizer and
%%         UndefinedBehaviorSanitizer. A wrong case, or a sanitizer report,
%%         goes back like a failed compile; the third failure throws
%%         error(codegen_error(test_failed, Diagnostic), _). Cases and
%%         the cases file are described in `coding/compile.pl'.
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
    codegen_options(Overrides, Options),
    codegen_key_env(Overrides, KeyVar),
    llm_opt(Options, provider, Provider),
    codegen_base_url(Overrides, Provider, BaseUrl),
    codegen_use_endpoint(Provider, BaseUrl, KeyVar),
    llm_chat([msg(system,
                  'You are a C17 programmer. Output only C source code, no Markdown fences, no explanation.'),
              msg(user, Prompt)],
             Options, Reply),
    codegen_report_add,
    codegen_strip_fence(Reply, Code).

%% ---- the run report ----------------------------------------------------

codegen_report_reset :-
    nb_setval('$codegen_calls', 0),
    nb_setval('$codegen_prompt', 0),
    nb_setval('$codegen_completion', 0),
    nb_setval('$codegen_reasoning', 0),
    nb_setval('$codegen_cache', 0),
    nb_setval('$codegen_total', 0),
    nb_setval('$codegen_seconds', 0.0).

codegen_report_finish(Start) :-
    get_time(End),
    Seconds is End - Start,
    nb_setval('$codegen_seconds', Seconds).

codegen_report_add :-
    nb_getval('$codegen_calls', Calls0),
    Calls is Calls0 + 1,
    nb_setval('$codegen_calls', Calls),
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  codegen_usage_number(Pairs, prompt_tokens, Prompt),
        codegen_usage_number(Pairs, completion_tokens, Completion),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R0, Details),
            integer(R0)
        ->  Reasoning = R0
        ;   Reasoning = 0
        ),
        codegen_usage_number(Pairs, prompt_cache_hit_tokens, CacheHit),
        (   codegen_usage_number(Pairs, total_tokens, Total0),
            Total0 > 0
        ->  Total = Total0
        ;   Total is Prompt + Completion
        ),
        codegen_bump('$codegen_prompt', Prompt),
        codegen_bump('$codegen_completion', Completion),
        codegen_bump('$codegen_reasoning', Reasoning),
        codegen_bump('$codegen_cache', CacheHit),
        codegen_bump('$codegen_total', Total)
    ;   true
    ).

codegen_usage_number(Pairs, Key, Number) :-
    (   memberchk(Key-Value, Pairs),
        integer(Value)
    ->  Number = Value
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
    codegen_report(report(Calls, Prompt, Completion, Reasoning, CacheHit, Total, Seconds)),
    format(user_error,
           'codegen: ~w call(s), ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [Calls, Prompt, Completion, Total, Reasoning, CacheHit, Seconds]).

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
%% `cflags(Flags)' (default '') and `keep(Dir)'; with a keep directory,
%% every attempt's prompt, code and diagnostic is written there as
%% attempt-N.prompt.txt, attempt-N.c and attempt-N.diag.txt.
codegen_c_from(Spec, Obligations, Cases, Overrides, Code) :-
    codegen_c_from(Spec, Obligations, Cases, Overrides, [], Code).

codegen_c_from(Spec, Obligations, Cases, Overrides, RunOptions, Code) :-
    codegen_run_prepare(RunOptions, Max, Timeout, CFlags),
    codegen_run_option(RunOptions, keep, none, Keep),
    codegen_report_reset,
    get_time(Start),
    catch(codegen_attempt(1, Max, Spec, Obligations, Cases, Overrides,
                          Keep, check(Timeout, CFlags), none, Code), Ball,
          ( codegen_report_finish(Start), throw(Ball) )),
    codegen_report_finish(Start).

codegen_run_prepare(RunOptions, Max, Timeout, CFlags) :-
    codegen_run_option(RunOptions, attempts, 3, Max0),
    codegen_run_check(attempts, Max0),
    Max = Max0,
    codegen_run_option(RunOptions, case_timeout, 3000, Timeout0),
    codegen_run_check(case_timeout, Timeout0),
    Timeout = Timeout0,
    codegen_run_option(RunOptions, cflags, '', Flags0),
    codegen_run_cflags(Flags0, CFlags),
    codegen_run_option(RunOptions, keep, none, Keep),
    codegen_keep_prepare(Keep).

codegen_run_cflags(Flags, Flags) :-
    (   atom(Flags)
    ->  true
    ;   format(atom(Msg), 'cflags must be an atom, not ~w', [Flags]),
        throw(error(codegen_error(run_option, Msg), codegen_run_prepare/4))
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
        throw(error(codegen_error(run_option, Msg), codegen_run_prepare/4))
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

codegen_attempt(Attempt, Max, Spec, Obligations, Cases, Overrides, Keep,
                check(Timeout, CFlags), Prev, Code) :-
    codegen_guided_prompt(Spec, Obligations, Prev, Prompt),
    codegen_keep_attempt(Keep, Attempt, 'prompt.txt', Prompt),
    codegen_call(Prompt, Overrides, Code0),
    codegen_keep_attempt(Keep, Attempt, 'c', Code0),
    codegen_verdict(Code0, Cases, check(Timeout, CFlags), Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Kind, Diag),
        codegen_keep_attempt(Keep, Attempt, 'diag.txt', Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(Kind, Diag), codegen_c_compiled/3))
        ;   Next is Attempt + 1,
            codegen_attempt(Next, Max, Spec, Obligations, Cases, Overrides,
                            Keep, check(Timeout, CFlags), prev(Code0, Diag), Code)
        )
    ).

codegen_verdict(Code, [], check(_, CFlags), Verdict) :-
    c_compile_check(Code, CFlags, Check),
    (   Check == ok
    ->  Verdict = ok
    ;   Check = fail(Diag),
        Verdict = fail(compile_failed, Diag)
    ).
codegen_verdict(Code, Cases, check(Timeout, CFlags), Verdict) :-
    Cases \== [],
    c_test_check(Code, Cases, Timeout, CFlags, Check),
    (   Check == ok
    ->  Verdict = ok
    ;   Check = fail(compile, Diag)
    ->  Verdict = fail(compile_failed, Diag)
    ;   Check = fail(test, Diag),
        Verdict = fail(test_failed, Diag)
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
    ;   format("usage: cocolog -s coding/c/codegen.pl -- SPEC.txt [--tests CASES.txt] [--contract CONTRACT.txt] [--keep DIR] [--attempts N] [--timeout MS] [--cflags FLAGS] [--dry-run] [--key-env NAME] [--temperature T] [--max-tokens N] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.c]~n", []),
        halt(1)
    ).

codegen_main(SpecFile, TestsFile, ContractFile, OutFile, Report, DryRun,
             RunOptions, Overrides) :-
    read_file_to_codes(SpecFile, Codes),
    atom_codes(Spec, Codes),
    (   DryRun == yes
    ->  codegen_prompt_for(Spec, ContractFile, Prompt),
        format("~s~n", [Prompt]),
        codegen_report_reset,
        codegen_report_print(Report)
    ;   codegen_obligations_for(Spec, ContractFile, Obligations),
        (   TestsFile == none
        ->  Cases = []
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
codegen_args(['--tests', File|Rest], args(S, none, C, O, R, D, Run, Os), A) :-
    codegen_args(Rest, args(S, File, C, O, R, D, Run, Os), A).
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
codegen_args(['--cflags', Flags|Rest], args(S, T, C, O, R, D, Run, Os), A) :-
    codegen_run_set(cflags(Flags), Run, Run1),
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
