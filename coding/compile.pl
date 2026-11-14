%% coding/compile.pl -- compile a C source atom, for any generator.
%%
%%     c_compile_check(+Code, -Verdict)
%%         ok, or fail(Diagnostic). The source is written to a fresh
%%         temporary directory and compiled with
%%         `clang -std=c17 -Wall -Wextra -O0'; stderr is merged into the
%%         diagnostic. A compiler that cannot be run is a failure with its
%%         error, not an exception.
%%
%% The checker compiles only. Running the binary on cases belongs to the
%% caller, which knows what the program should print.

:- use_module(library(process)).

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
        c_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ).

c_limit(Max, Atom, Limited) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Limited = Atom
    ;   sub_atom(Atom, 0, Max, _, Limited)
    ).
