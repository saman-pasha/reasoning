%% coding/c/codegen.pl -- C code from a written requirement.
%%
%%     cocolog -s coding/c/codegen.pl -- SPEC.txt [--tests CASES.txt] [OUT.c]
%%
%% A requirement goes to a language model as a CONTRACT: C17, one complete
%% program, no Markdown fences, no prose. The reply is compiled, and a
%% failed compile is repaired with the compiler's own diagnostic. With
%% `--tests', the program is also run on each case and a wrong answer is
%% repaired the same way. The model is used with the effort defaults in
%% `coding/options.pl' -- both `none' -- so the thinking this repository
%% does is not paid for twice.
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
%%     main/0
%%         the program: SPEC.txt, an optional `--tests CASES.txt', then an
%%         optional OUT.c; stdout otherwise. It uses codegen_c_tested/2
%%         when tests are given and exits 1 if no reply passes.

:- use_module(library(llm)).
:- use_module('coding/options.pl').
:- use_module('coding/obligations.pl').
:- use_module('coding/compile.pl').

codegen_c(Spec, Code) :-
    codegen_c(Spec, [], Code).

codegen_c(Spec, Overrides, Code) :-
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
    codegen_strip_fence(Reply, Code).

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
    codegen_attempt(1, 3, Spec, Obligations, [], Overrides, none, Code).

%% codegen_c_tested(+Spec, +Cases, -Code)
%% codegen_c_tested(+Spec, +Cases, +Overrides, -Code)
%%
%% The same loop, and a compiling reply is run on each case. A case that
%% answers wrong is repaired like a compile failure.
codegen_c_tested(Spec, Cases, Code) :-
    codegen_c_tested(Spec, Cases, [], Code).

codegen_c_tested(Spec, Cases, Overrides, Code) :-
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
    (   codegen_args(Args, SpecFile, TestsFile, OutFile)
    ->  catch(codegen_main(SpecFile, TestsFile, OutFile),
              error(codegen_error(Kind, Detail), _),
              ( format("codegen: ~w~n~s~n", [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/c/codegen.pl -- SPEC.txt [--tests CASES.txt] [OUT.c]~n", [])
    ).

codegen_main(SpecFile, TestsFile, OutFile) :-
    read_file_to_codes(SpecFile, Codes),
    atom_codes(Spec, Codes),
    (   TestsFile == none
    ->  codegen_c_compiled(Spec, Code)
    ;   c_read_cases(TestsFile, Cases),
        codegen_c_tested(Spec, Cases, Code)
    ),
    (   OutFile == none
    ->  format("~s~n", [Code])
    ;   atom_concat(Code, '\n', Text),
        atom_codes(Text, OutCodes),
        write_file_from_codes(OutFile, OutCodes)
    ).

%% SPEC.txt [--tests CASES.txt] [OUT.c], the flag anywhere after the
%% binary. A second positional is OUT.c; a third is a usage error.
codegen_args(Args, SpecFile, TestsFile, OutFile) :-
    codegen_args(Args, none, none, none, SpecFile, TestsFile, OutFile).

codegen_args([], Spec, Tests, Out, Spec, Tests, Out) :-
    Spec \== none.
codegen_args(['--tests', File|Rest], Spec, none, Out, S, T, O) :-
    codegen_args(Rest, Spec, File, Out, S, T, O).
codegen_args([Arg|Rest], none, Tests, Out, S, T, O) :-
    codegen_args(Rest, Arg, Tests, Out, S, T, O).
codegen_args([Arg|Rest], Spec, Tests, none, S, T, O) :-
    Spec \== none,
    codegen_args(Rest, Spec, Tests, Arg, S, T, O).
