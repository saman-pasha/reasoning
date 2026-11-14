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
%%     --provider P     provider(P) in the call
%%     --model M        model(M) in the call
%%     --base-url U     base_url(U) in the call
%%     --effort E       effort(E) in the call
%%     --report         print calls and token usage to stderr
%%
%% The three of provider, model and base URL are one setting: a provider
%% chosen alone keeps library(llm)'s model and endpoint for that provider.
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
%%     c_compile_check(+Code, -Verdict)
%%     c_test_check(+Code, +Cases, -Verdict)
%%         from `coding/compile.pl'; the checks the repair loop uses.
%%
%%     codegen_report(-Report)
%%         report(Calls, Prompt, Completion, Reasoning, Total), the last
%%         top-level generation's calls and tokens. `--report' prints it.
%%
%%     main/0
%%         the program: SPEC.txt, the flags, then an optional OUT.c;
%%         stdout otherwise. It uses codegen_c_tested/4 when tests are
%%         given and exits 1 if no reply passes.

:- use_module(library(llm)).
:- use_module('coding/options.pl').
:- use_module('coding/obligations.pl').
:- use_module('coding/compile.pl').

codegen_c(Spec, Code) :-
    codegen_c(Spec, [], Code).

codegen_c(Spec, Overrides, Code) :-
    codegen_report_reset,
    codegen_prompt(Spec, Prompt),
    codegen_call(Prompt, Overrides, Code).

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
    nb_setval('$codegen_total', 0).

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
        (   codegen_usage_number(Pairs, total_tokens, Total0),
            Total0 > 0
        ->  Total = Total0
        ;   Total is Prompt + Completion
        ),
        codegen_bump('$codegen_prompt', Prompt),
        codegen_bump('$codegen_completion', Completion),
        codegen_bump('$codegen_reasoning', Reasoning),
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

codegen_report(report(Calls, Prompt, Completion, Reasoning, Total)) :-
    nb_getval('$codegen_calls', Calls),
    nb_getval('$codegen_prompt', Prompt),
    nb_getval('$codegen_completion', Completion),
    nb_getval('$codegen_reasoning', Reasoning),
    nb_getval('$codegen_total', Total).

codegen_report_print(no) :-
    !.
codegen_report_print(yes) :-
    codegen_report(report(Calls, Prompt, Completion, Reasoning, Total)),
    format(user_error,
           'codegen: ~w call(s), ~w prompt + ~w completion = ~w tokens (~w reasoning)~n',
           [Calls, Prompt, Completion, Total, Reasoning]).

%% codegen_c_compiled(+Spec, -Code)
%% codegen_c_compiled(+Spec, +Overrides, -Code)
%%
%% The reply is compiled with clang after every call. A compile failure
%% goes back with the compiler's diagnostic and the previous program, up
%% to three attempts. The obligation checklist is in every attempt.
codegen_c_compiled(Spec, Code) :-
    codegen_c_compiled(Spec, [], Code).

codegen_c_compiled(Spec, Overrides, Code) :-
    codegen_report_reset,
    codegen_obligations(Spec, Obligations),
    codegen_attempt(1, 3, Spec, Obligations, [], Overrides, none, Code).

%% codegen_c_tested(+Spec, +Cases, -Code)
%% codegen_c_tested(+Spec, +Cases, +Overrides, -Code)
%%
%% The same loop, and a compiling reply is run on each case. A case that
%% answers wrong is repaired like a compile failure.
codegen_c_tested(Spec, Cases, Code) :-
    codegen_c_tested(Spec, Cases, [], Code).

codegen_c_tested(Spec, Cases, Overrides, Code) :-
    codegen_report_reset,
    codegen_obligations(Spec, Obligations),
    codegen_attempt(1, 3, Spec, Obligations, Cases, Overrides, none, Code).

codegen_attempt(Attempt, Max, Spec, Obligations, Cases, Overrides, Prev, Code) :-
    codegen_guided_prompt(Spec, Obligations, Prev, Prompt),
    codegen_call(Prompt, Overrides, Code0),
    codegen_verdict(Code0, Cases, Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Kind, Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(Kind, Diag), codegen_c_compiled/3))
        ;   Next is Attempt + 1,
            codegen_attempt(Next, Max, Spec, Obligations, Cases, Overrides,
                            prev(Code0, Diag), Code)
        )
    ).

codegen_verdict(Code, [], Verdict) :-
    c_compile_check(Code, Check),
    (   Check == ok
    ->  Verdict = ok
    ;   Check = fail(Diag),
        Verdict = fail(compile_failed, Diag)
    ).
codegen_verdict(Code, Cases, Verdict) :-
    Cases \== [],
    c_test_check(Code, Cases, Check),
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
    (   codegen_args(Args, SpecFile, TestsFile, OutFile, Report, Overrides)
    ->  catch(codegen_main(SpecFile, TestsFile, OutFile, Report, Overrides),
              error(codegen_error(Kind, Detail), _),
              ( codegen_report_print(Report),
                format(user_error, 'codegen: ~w~n~s~n', [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/c/codegen.pl -- SPEC.txt [--tests CASES.txt] [--provider P] [--model M] [--base-url U] [--effort E] [--report] [OUT.c]~n", [])
    ).

codegen_main(SpecFile, TestsFile, OutFile, Report, Overrides) :-
    read_file_to_codes(SpecFile, Codes),
    atom_codes(Spec, Codes),
    (   TestsFile == none
    ->  codegen_c_compiled(Spec, Overrides, Code)
    ;   c_read_cases(TestsFile, Cases),
        codegen_c_tested(Spec, Cases, Overrides, Code)
    ),
    (   OutFile == none
    ->  format("~s~n", [Code])
    ;   atom_concat(Code, '\n', Text),
        atom_codes(Text, OutCodes),
        write_file_from_codes(OutFile, OutCodes)
    ),
    codegen_report_print(Report).

%% SPEC.txt [flags] [OUT.c], the flags anywhere after the binary. A
%% second positional is OUT.c; a third is a usage error. Overrides are
%% prepended, so a flag said again keeps its last value.
codegen_args(Args, SpecFile, TestsFile, OutFile, Report, Overrides) :-
    codegen_args(Args, none, none, none, no, [],
                 SpecFile, TestsFile, OutFile, Report, Overrides).

codegen_args([], Spec, Tests, Out, Report, Os, Spec, Tests, Out, Report, Os) :-
    Spec \== none.
codegen_args(['--tests', File|Rest], Spec, none, Out, Report, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, File, Out, Report, Os, S, T, O, R, Os2).
codegen_args(['--provider', P|Rest], Spec, Tests, Out, Report, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, Tests, Out, Report, [provider(P)|Os], S, T, O, R, Os2).
codegen_args(['--model', M|Rest], Spec, Tests, Out, Report, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, Tests, Out, Report, [model(M)|Os], S, T, O, R, Os2).
codegen_args(['--base-url', U|Rest], Spec, Tests, Out, Report, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, Tests, Out, Report, [base_url(U)|Os], S, T, O, R, Os2).
codegen_args(['--effort', E|Rest], Spec, Tests, Out, Report, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, Tests, Out, Report, [effort(E)|Os], S, T, O, R, Os2).
codegen_args(['--report'|Rest], Spec, Tests, Out, _, Os, S, T, O, R, Os2) :-
    codegen_args(Rest, Spec, Tests, Out, yes, Os, S, T, O, R, Os2).
codegen_args([Arg|Rest], none, Tests, Out, Report, Os, S, T, O, R, Os2) :-
    \+ codegen_flag(Arg),
    codegen_args(Rest, Arg, Tests, Out, Report, Os, S, T, O, R, Os2).
codegen_args([Arg|Rest], Spec, Tests, none, Report, Os, S, T, O, R, Os2) :-
    Spec \== none,
    \+ codegen_flag(Arg),
    codegen_args(Rest, Spec, Tests, Arg, Report, Os, S, T, O, R, Os2).

codegen_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').
