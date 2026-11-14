%% coding/c/check.pl -- compile a C file, and run its cases, with no model.
%%
%%     cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS]
%%
%% Without --tests the file is compiled with
%% `clang -std=c17 -Wall -Wextra -O0'. With --tests it is built with
%% AddressSanitizer and UndefinedBehaviorSanitizer and every case is run.
%% It prints OK and exits 0, or the compiler/test report and exits 1.
%% --timeout is the milliseconds one case may run (default 3000). The
%% cases file formats and the sanitizer policy are `coding/compile.pl''s.

:- use_module('coding/compile.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   check_args(Args, check(none, none, 3000),
                   check(File, Tests, Timeout))
    ->  catch(check_main(File, Tests, Timeout),
              error(codegen_error(Kind, Detail), _),
              ( format("check: ~w~n~s~n", [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS]~n", []),
        halt(1)
    ).

check_args([], check(File, Tests, Timeout), check(File, Tests, Timeout)) :-
    File \== none.
check_args(['--tests', File|Rest], check(Source, none, Timeout), A) :-
    check_args(Rest, check(Source, File, Timeout), A).
check_args(['--timeout', Ms|Rest], check(Source, Tests, 3000), A) :-
    atom_number(Ms, Ms0),
    integer(Ms0),
    Ms0 > 0,
    check_args(Rest, check(Source, Tests, Ms0), A).
check_args([Arg|Rest], check(none, Tests, Timeout), A) :-
    \+ check_flag(Arg),
    check_args(Rest, check(Arg, Tests, Timeout), A).

check_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').

check_main(File, Tests, Timeout) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(file, Msg), check_main/3))
    ),
    atom_codes(Code, Codes),
    (   Tests == none
    ->  c_compile_check(Code, Verdict),
        report_compile(File, Verdict)
    ;   c_read_cases(Tests, Cases),
        length(Cases, Count),
        c_test_check(Code, Cases, Timeout, Verdict),
        report_tests(File, Count, Verdict)
    ).

report_compile(File, ok) :-
    !,
    format("OK: ~s compiles~n", [File]).
report_compile(_File, fail(Diag)) :-
    format("COMPILE FAILED~n~s~n", [Diag]),
    halt(1).

report_tests(File, Count, ok) :-
    !,
    format("OK: ~s compiles and ~w case(s) pass~n", [File, Count]).
report_tests(_File, _Count, fail(compile, Diag)) :-
    format("COMPILE FAILED~n~s~n", [Diag]),
    halt(1).
report_tests(_File, _Count, fail(test, Diag)) :-
    format("TESTS FAILED~n~s~n", [Diag]),
    halt(1).
