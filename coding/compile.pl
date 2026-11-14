%% coding/compile.pl -- compile and run a C source atom.
%%
%%     c_compile_check(+Code, -Verdict)
%%         ok, or fail(Diagnostic). The source is written to a fresh
%%         temporary directory and compiled with
%%         `clang -std=c17 -Wall -Wextra -O0'; stderr is merged into the
%%         diagnostic. A compiler that cannot be run is a failure with its
%%         error, not an exception.
%%
%%     c_test_check(+Code, +Cases, -Verdict)
%%         compile, then run the binary on each case. ok, or
%%         fail(compile, Diagnostic) or fail(test, Diagnostic). A case is
%%         case(Input, Expected), both atoms; Input keeps its newlines,
%%         and both sides are compared after trailing whitespace and final
%%         newlines are trimmed.
%%
%%     c_run_cases(+Exe, +Cases, -Failures)
%%         the runner on its own: [] when every case matches.
%%
%%     c_read_cases(+File, -Cases)
%%         read one Prolog term, cases([case(Input, Expected), ...]), and
%%         check its shape. A bad file throws
%%         error(codegen_error(cases_file, Message), _).

:- use_module(library(process)).

%% ---- compile -----------------------------------------------------------

c_compile_check(Code, Verdict) :-
    c_compile(Code, _Exe, Verdict).

c_compile(Code, Exe, Verdict) :-
    tmp_file(codegen_check, Dir),
    make_directory(Dir),
    atom_concat(Dir, '/check.c', CFile),
    atom_concat(Dir, '/check.out', Exe),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(CFile, Codes),
    format(atom(Cmd), 'clang -std=c17 -Wall -Wextra -O0 -o ~s ~s 2>&1',
           [Exe, CFile]),
    c_run_command(Cmd, 120000, OutCodes, Exit, Error),
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

%% ---- compile and run the cases ----------------------------------------

c_test_check(Code, Cases, Verdict) :-
    c_compile(Code, Exe, CompileVerdict),
    (   CompileVerdict == ok
    ->  c_run_cases(Exe, Cases, Failures),
        (   Failures == []
        ->  Verdict = ok
        ;   atomic_list_concat(Failures, '\n\n', Diag0),
            c_limit(4000, Diag0, Diag),
            Verdict = fail(test, Diag)
        )
    ;   CompileVerdict = fail(Diag),
        Verdict = fail(compile, Diag)
    ).

c_run_cases(Exe, Cases, Failures) :-
    c_run_cases(Cases, Exe, 1, Failures).

c_run_cases([], _, _, []).
c_run_cases([case(Input, Expected)|Rest], Exe, Index, Failures) :-
    tmp_file(codegen_case, InFile),
    atom_codes(Input, InCodes),
    write_file_from_codes(InFile, InCodes),
    format(atom(Cmd), '~s < ~s 2>&1', [Exe, InFile]),
    c_run_command(Cmd, 3000, OutCodes, Exit, Error),
    atom_codes(Actual0, OutCodes),
    c_norm(Actual0, Actual),
    c_norm(Expected, ExpNorm),
    (   Error == none,
        Exit == 0,
        Actual == ExpNorm
    ->  Here = []
    ;   c_case_failure(Index, Input, Expected, Exit, Actual, Error, Failure),
        Here = [Failure]
    ),
    Next is Index + 1,
    c_run_cases(Rest, Exe, Next, Tail),
    append(Here, Tail, Failures).

c_case_failure(Index, Input, Expected, Exit, Actual, Error, Failure) :-
    (   Error \== none
    ->  format(atom(Failure),
               'CASE ~w COULD NOT RUN~ninput: ~w~nexpected: ~w~nerror: ~w',
               [Index, Input, Expected, Error])
    ;   Exit == 124
    ->  format(atom(Failure),
               'CASE ~w TIMEOUT~ninput: ~w~nexpected: ~w',
               [Index, Input, Expected])
    ;   Exit \== 0
    ->  format(atom(Failure),
               'CASE ~w EXIT ~w~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Exit, Input, Expected, Actual])
    ;   format(atom(Failure),
               'CASE ~w WRONG~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Input, Expected, Actual])
    ).

%% ---- reading a cases file ---------------------------------------------

c_read_cases(File, Cases) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(Text, Codes),
        (   catch(read_term_from_atom(Text, Term, []), _, fail)
        ->  true
        ;   c_cases_error('the cases file is not one Prolog term')
        )
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(cases_file, Msg), c_read_cases/2))
    ),
    (   Term = cases(Cases0),
        c_valid_cases(Cases0)
    ->  Cases = Cases0
    ;   c_cases_error('the cases file must be cases([case(Input, Expected), ...])')
    ).

c_cases_error(Msg) :-
    throw(error(codegen_error(cases_file, Msg), c_read_cases/2)).

c_valid_cases([]).
c_valid_cases([case(Input, Expected)|Rest]) :-
    atom(Input),
    atom(Expected),
    c_valid_cases(Rest).

%% ---- small helpers -----------------------------------------------------

c_run_command(Cmd, Timeout, OutCodes, Exit, Error) :-
    catch(( proc_run(Cmd, Timeout, OutCodes0, Exit0),
            OutCodes = OutCodes0,
            Exit = Exit0,
            Error = none
          ),
          Ball,
          ( OutCodes = [],
            Exit = -1,
            c_error_text(Ball, Error)
          )).

c_error_text(Ball, Error) :-
    (   Ball = error(Formal, _)
    ->  Error = Formal
    ;   Error = Ball
    ).

c_norm(Text, Norm) :-
    split_string(Text, "\n", " \t\r", Lines0),
    exclude(c_empty_string, Lines0, Lines),
    findall(A, (member(L, Lines), atom_string(A, L)), Atoms),
    atomic_list_concat(Atoms, '\n', Norm).

c_empty_string(S) :-
    string_length(S, 0).

c_limit(Max, Atom, Limited) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Limited = Atom
    ;   sub_atom(Atom, 0, Max, _, Limited)
    ).
