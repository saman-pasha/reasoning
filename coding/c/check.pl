%% coding/c/check.pl -- compile a C file, and run its cases, with no model.
%%
%%     cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS] [--cflags FLAGS] [--analyze]
%%
%% Without --tests the file is compiled with
%% `clang -std=c17 -Wall -Wextra -O0 CFlags'. With --tests it is built with
%% AddressSanitizer and UndefinedBehaviorSanitizer and every case is run.
%% With --analyze it is put through `clang --analyze' first; a finding is
%% printed and exits 1.
%% It prints OK and exits 0, or the compiler/test report and exits 1.
%% --timeout is the milliseconds one case may run (default 3000); --cflags
%% are extra compiler arguments (default none). The cases file formats and
%% the sanitizer policy are `coding/compile.pl''s.

:- use_module('coding/compile.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   check_args(Args, check(none, none, 3000, '', no),
                   check(File, Tests, Timeout, CFlags, Analyze))
    ->  catch(check_main(File, Tests, Timeout, CFlags, Analyze),
              error(codegen_error(Kind, Detail), _),
              ( format("check: ~w~n~s~n", [Kind, Detail]),
                halt(1)
              ))
    ;   format("usage: cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS] [--cflags FLAGS] [--analyze]~n", []),
        halt(1)
    ).

check_args([], check(File, Tests, Timeout, CFlags, Analyze),
           check(File, Tests, Timeout, CFlags, Analyze)) :-
    File \== none.
check_args(['--tests', File|Rest],
           check(Source, none, Timeout, CFlags, Analyze), A) :-
    check_args(Rest, check(Source, File, Timeout, CFlags, Analyze), A).
check_args(['--timeout', Ms|Rest],
           check(Source, Tests, 3000, CFlags, Analyze), A) :-
    atom_number(Ms, Ms0),
    integer(Ms0),
    Ms0 > 0,
    check_args(Rest, check(Source, Tests, Ms0, CFlags, Analyze), A).
check_args(['--cflags', CFlags|Rest],
           check(Source, Tests, Timeout, '', Analyze), A) :-
    check_args(Rest, check(Source, Tests, Timeout, CFlags, Analyze), A).
check_args(['--analyze'|Rest],
           check(Source, Tests, Timeout, CFlags, _), A) :-
    check_args(Rest, check(Source, Tests, Timeout, CFlags, yes), A).
check_args([Arg|Rest], check(none, Tests, Timeout, CFlags, Analyze), A) :-
    \+ check_flag(Arg),
    check_args(Rest, check(Arg, Tests, Timeout, CFlags, Analyze), A).

check_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').

check_main(File, Tests, Timeout, CFlags, Analyze) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(file, Msg), check_main/5))
    ),
    atom_codes(Code, Codes),
    (   Analyze == yes
    ->  c_analyze_check(Code, CFlags, AnalyzeVerdict),
        report_analyze(AnalyzeVerdict)
    ;   true
    ),
    (   Tests == none
    ->  (   Analyze == yes
        ->  format("OK: ~s passes the analyzer~n", [File])
        ;   c_compile_check(Code, CFlags, Verdict),
            report_compile(File, Verdict)
        )
    ;   c_read_cases(Tests, Cases),
        length(Cases, Count),
        c_test_check(Code, Cases, Timeout, CFlags, Verdict),
        report_tests(File, Count, Verdict)
    ).

report_analyze(ok) :-
    !.
report_analyze(fail(Diag)) :-
    format("~s~n", [Diag]),
    halt(1).

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
