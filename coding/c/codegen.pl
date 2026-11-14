%% coding/c/codegen.pl -- C code from a written requirement.
%%
%%     cocolog -s coding/c/codegen.pl -- SPEC.txt [OUT.c]
%%
%% A requirement goes to a language model as a CONTRACT: C17, one complete
%% program, no Markdown fences, no prose. The reply is compiled, and a
%% failed compile is repaired with the compiler's own diagnostic. The
%% model is used with the effort defaults in `coding/options.pl' -- both
%% `none' -- so the thinking this repository does is not paid for twice.
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
%%         `clang -std=c17 -Wall -Wextra -O0'. A failed compile goes back
%%         to the model with the compiler's diagnostic and the previous
%%         program, up to three attempts; then
%%         error(codegen_error(compile_failed, Diagnostic), _) is thrown.
%%
%%     c_compile_check(+Code, -Verdict)
%%         ok or fail(Diagnostic), the check the repair loop uses.
%%
%%     main/0
%%         the program: SPEC.txt, then an optional OUT.c; stdout otherwise.
%%         It uses codegen_c_compiled/2 and exits 1 if no reply compiles.

:- use_module(library(llm)).
:- use_module(library(process)).
:- use_module('coding/options.pl').

codegen_c(Spec, Code) :-
    codegen_c(Spec, [], Code).

codegen_c(Spec, Overrides, Code) :-
    codegen_options(Overrides, Options),
    codegen_key_env(Overrides, KeyVar),
    llm_opt(Options, provider, Provider),
    codegen_base_url(Overrides, Provider, BaseUrl),
    codegen_use_endpoint(Provider, BaseUrl, KeyVar),
    codegen_prompt(Spec, Prompt),
    llm_chat([msg(system,
                  'You are a C17 programmer. Output only C source code, no Markdown fences, no explanation.'),
              msg(user, Prompt)],
             Options, Reply),
    codegen_strip_fence(Reply, Code).

%% codegen_c_compiled(+Spec, -Code)
%% codegen_c_compiled(+Spec, +Overrides, -Code)
%%
%% The reply is compiled with clang. A compile failure goes back with the
%% compiler's diagnostic and the previous program, up to three attempts.
codegen_c_compiled(Spec, Code) :-
    codegen_c_compiled(Spec, [], Code).

codegen_c_compiled(Spec, Overrides, Code) :-
    codegen_compile_attempt(1, 3, Spec, Overrides, none, Code).

codegen_compile_attempt(Attempt, Max, Spec, Overrides, Prev, Code) :-
    codegen_c_with_feedback(Spec, Prev, Overrides, Code0),
    c_compile_check(Code0, Verdict),
    (   Verdict == ok
    ->  Code = Code0
    ;   Verdict = fail(Diag),
        (   Attempt >= Max
        ->  throw(error(codegen_error(compile_failed, Diag), codegen_c_compiled/3))
        ;   Next is Attempt + 1,
            codegen_compile_attempt(Next, Max, Spec, Overrides,
                                    prev(Code0, Diag), Code)
        )
    ).

codegen_c_with_feedback(Spec, none, Overrides, Code) :-
    !,
    codegen_c(Spec, Overrides, Code).
codegen_c_with_feedback(Spec, prev(Previous, Diag), Overrides, Code) :-
    format(atom(Full),
           '~s~n~nYour previous C program did not compile. The compiler said:~n~s~nThe previous program was:~n~s~nWrite a corrected complete C17 program. Output only the C source.',
           [Spec, Diag, Previous]),
    codegen_c(Full, Overrides, Code).

%% c_compile_check(+Code, -Verdict)
%%
%% ok, or fail(Diagnostic). The source and binary live in a fresh
%% temporary directory; clang's stderr is merged into its stdout.
c_compile_check(Code, Verdict) :-
    tmp_file(codegen_check, Dir),
    make_directory(Dir),
    atom_concat(Dir, '/check.c', CFile),
    atom_concat(Dir, '/check.out', Exe),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(CFile, Codes),
    format(atom(Cmd), 'clang -std=c17 -Wall -Wextra -O0 -o ~s ~s 2>&1',
           [Exe, CFile]),
    catch(( proc_run(Cmd, 120000, OutCodes, Exit),
            Error = none
          ),
          Ball,
          ( OutCodes = [],
            Exit = -1,
            Error = Ball
          )),
    atom_codes(Output, OutCodes),
    (   Error == none,
        Exit == 0
    ->  Verdict = ok
    ;   (   Error == none
        ->  format(atom(Diag0), 'COMPILE FAILED (exit ~w)~n~s', [Exit, Output])
        ;   format(atom(Diag0), 'compiler could not run: ~w~n~s', [Error, Output])
        ),
        codegen_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
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

codegen_limit(Max, Atom, Limited) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Limited = Atom
    ;   sub_atom(Atom, 0, Max, _, Limited)
    ).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [SpecFile|Rest]
    ->  read_file_to_codes(SpecFile, Codes),
        atom_codes(Spec, Codes),
        catch(codegen_c_compiled(Spec, Code),
              error(codegen_error(compile_failed, Diag), _),
              ( format("the program did not compile after three attempts~n~s~n", [Diag]),
                halt(1)
              )),
        (   Rest = [OutFile|_]
        ->  atom_concat(Code, '\n', Text),
            atom_codes(Text, OutCodes),
            write_file_from_codes(OutFile, OutCodes)
        ;   format("~s~n", [Code])
        )
    ;   format("usage: cocolog -s coding/c/codegen.pl -- SPEC.txt [OUT.c]~n", [])
    ).
