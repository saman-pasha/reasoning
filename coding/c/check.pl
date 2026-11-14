%% coding/c/check.pl -- compile a C file, and run its cases, with no model.
%%
%%     cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS] [--cflags FLAGS] [--std EDITION] [--analyze]
%%
%% Without --tests the file is compiled with
%% `clang -std=<EDITION> -Wall -Wextra -O0 CFlags'. With --tests it is
%% built with AddressSanitizer and UndefinedBehaviorSanitizer and every
%% case is run. With --analyze it is put through `clang --analyze' first;
%% a finding is printed and exits 1.
%% It prints OK and exits 0, or the compiler/test report and exits 1.
%% --timeout is the milliseconds one case may run (default 3000); --cflags
%% are extra compiler arguments (default none). The cases file formats and
%% the sanitizer policy are `coding/compile.pl''s.
%%
%% --std names the C edition: c89, c99, c11, c17 (the default) or c23, and
%% c90/c18/c2x as aliases. It is `coding/options.pl''s codegen_std/1 unless
%% named here, so a checkout that asserted another default gets it from
%% this file too. Every build -- the compile, the sanitizer binary and the
%% analyzer -- uses the one edition, never two.

:- use_module('coding/compile.pl').
:- use_module('coding/options.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    codegen_std(Default),
    catch(( check_args(Args, check(none, none, 3000, '', Default, no),
                       check(File, Tests, Timeout, CFlags, Std, Analyze))
          ->  check_main(File, Tests, Timeout, CFlags, Std, Analyze)
          ;   format("usage: cocolog -s coding/c/check.pl -- FILE.c [--tests CASES.txt] [--timeout MS] [--cflags FLAGS] [--std EDITION] [--analyze]~n", []),
              halt(1)
          ),
          error(codegen_error(Kind, Detail), _),
          ( format("check: ~w~n~s~n", [Kind, Detail]),
            halt(1)
          )).

check_args([], check(File, Tests, Timeout, CFlags, Std, Analyze),
           check(File, Tests, Timeout, CFlags, Std, Analyze)) :-
    File \== none.
check_args(['--tests', File|Rest],
           check(Source, none, Timeout, CFlags, Std, Analyze), A) :-
    check_args(Rest, check(Source, File, Timeout, CFlags, Std, Analyze), A).
check_args(['--timeout', Ms|Rest],
           check(Source, Tests, 3000, CFlags, Std, Analyze), A) :-
    atom_number(Ms, Ms0),
    integer(Ms0),
    Ms0 > 0,
    check_args(Rest, check(Source, Tests, Ms0, CFlags, Std, Analyze), A).
check_args(['--cflags', CFlags|Rest],
           check(Source, Tests, Timeout, '', Std, Analyze), A) :-
    check_args(Rest, check(Source, Tests, Timeout, CFlags, Std, Analyze), A).
check_args(['--std', Std|Rest],
           check(Source, Tests, Timeout, CFlags, _, Analyze), A) :-
    (   codegen_std_value(Std, _)
    ->  check_args(Rest, check(Source, Tests, Timeout, CFlags, Std, Analyze), A)
    ;   format("check: --std takes c89, c99, c11, c17 or c23, not ~w~n", [Std]),
        halt(1)
    ).
check_args(['--analyze'|Rest],
           check(Source, Tests, Timeout, CFlags, Std, _), A) :-
    check_args(Rest, check(Source, Tests, Timeout, CFlags, Std, yes), A).
check_args([Arg|Rest], check(none, Tests, Timeout, CFlags, Std, Analyze), A) :-
    \+ check_flag(Arg),
    check_args(Rest, check(Arg, Tests, Timeout, CFlags, Std, Analyze), A).

check_flag(Arg) :-
    atom(Arg),
    sub_atom(Arg, 0, 2, _, '--').

check_main(File, Tests, Timeout, CFlags, Std, Analyze) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(file, Msg), check_main/6))
    ),
    %% --std is checked in check_args/3 and the default in main/0, but a
    %% caller of check_main/6 directly gets the same refusal, not an
    %% instantiation error from deep in codegen_std_name/2.
    (   codegen_std_value(Std, _)
    ->  true
    ;   format(atom(BadMsg),
               'the C standard is one of c89, c99, c11, c17 or c23, not ~w',
               [Std]),
        throw(error(codegen_error(std, BadMsg), check_main/6))
    ),
    atom_codes(Code, Codes),
    codegen_std_value(Std, Spelling),
    (   Analyze == yes
    ->  c_analyze_check(Code, CFlags, Std, AnalyzeVerdict),
        report_analyze(AnalyzeVerdict)
    ;   true
    ),
    (   Tests == none
    ->  (   Analyze == yes
        ->  format("OK: ~s passes the analyzer as ~w~n", [File, Spelling])
        ;   c_compile_check(Code, CFlags, Std, Verdict),
            report_compile(File, Spelling, Verdict)
        )
    ;   c_read_cases(Tests, Cases),
        length(Cases, Count),
        c_test_check(Code, Cases, Timeout, CFlags, Std, Verdict),
        report_tests(File, Spelling, Count, Verdict)
    ).

report_analyze(ok) :-
    !.
report_analyze(fail(Diag)) :-
    format("~s~n", [Diag]),
    halt(1).

report_compile(File, Spelling, ok) :-
    !,
    format("OK: ~s compiles as ~w~n", [File, Spelling]).
report_compile(_File, _Spelling, fail(Diag)) :-
    format("COMPILE FAILED~n~s~n", [Diag]),
    halt(1).

report_tests(File, Spelling, Count, ok) :-
    !,
    format("OK: ~s compiles as ~w and ~w case(s) pass~n", [File, Spelling, Count]).
report_tests(_File, _Spelling, _Count, fail(compile, Diag)) :-
    format("COMPILE FAILED~n~s~n", [Diag]),
    halt(1).
report_tests(_File, _Spelling, _Count, fail(test, Diag)) :-
    format("TESTS FAILED~n~s~n", [Diag]),
    halt(1).
