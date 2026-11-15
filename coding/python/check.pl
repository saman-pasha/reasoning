%% coding/python/check.pl -- read a Python file, and run its tests, with no model.
%%
%%     cocolog -s coding/python/check.pl -- FILE.py [--tests CMD] [--timeout MS] [--python PATH] [--strict]
%%
%% The file is read the way codegen's `plain' mode reads a reply:
%% `python3 -m py_compile'. With --tests the command is run in the file's
%% own directory. With --strict it is read the way `guarded' does, and a
%% name the source uses and never defines is a finding.
%% It prints OK and exits 0, or every finding and exits 1.
%%
%% --timeout is the milliseconds one command may run (default 10000).
%% --python is the interpreter: $PYTHON3, else python3.
%%
%% THE NAME CHECK IS A READING, NOT AN IMPORT. A file is not executed: an
%% import runs its top level, which a checker has no right to do to a file
%% a model wrote. The names are found in the source, and the finding is
%% the narrow one a person would give by reading: a word followed by `('
%% or by an operator, that no `def', `class', `import', `for', `with ... as',
%% parameter or assignment in the file defines. An attribute (`x.foo()') is
%% not a name for this reading, an f-string is not read, and a name bound
%% only inside a function is not taken as bound outside it. `possibly' says
%% the reading cannot tell; a finding is never called an error.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module('coding/python/names.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   python_check_args(Args, check(File, Tests, Timeout, Python, Strict)),
        File \== none
    ->  catch(python_check_main(File, Tests, Timeout, Python, Strict), Error,
              ( format(user_msg, '~q~n', [Error]), halt(2) ))
    ;   format("usage: cocolog -s coding/python/check.pl -- FILE.py [--tests CMD] [--timeout MS] [--python PATH] [--strict]~n", []),
        halt(1)
    ).

python_check_args(Args, Result) :-
    python_check_args(Args, check(none, none, 10000, none, no), Result).

python_check_args([], State, State).
python_check_args(['--tests', C|Rest], check(F, _, T, P, S), R) :-
    python_check_args(Rest, check(F, C, T, P, S), R).
python_check_args(['--timeout', Ms|Rest], check(F, C, _, P, S), R) :-
    atom_number(Ms, N), integer(N), N > 0, !,
    python_check_args(Rest, check(F, C, N, P, S), R).
python_check_args(['--python', P0|Rest], check(F, C, T, _, S), R) :-
    python_check_args(Rest, check(F, C, T, P0, S), R).
python_check_args(['--strict'|Rest], check(F, C, T, P, _), R) :-
    python_check_args(Rest, check(F, C, T, P, yes), R).
python_check_args([Arg|Rest], check(none, C, T, P, S), R) :-
    \+(sub_atom(Arg, 0, 2, _, '--')),
    python_check_args(Rest, check(Arg, C, T, P, S), R).

python_check_main(File, Tests, Timeout, Python, Strict) :-
    (   catch(exists_file(File), _, fail)
    ->  true
    ;   format(user_error, 'cannot read ~s~n', [File]),
        halt(1)
    ),
    python_check_dir(File, Dir),
    python_check_parse(File, Python, Parse),
    (   Strict == yes
    ->  python_check_names(File, Names)
    ;   Names = []
    ),
    (   Tests == none
    ->  TestHit = none
    ;   python_check_tests(Tests, Dir, Timeout, TestOutput, TestHit)
    ),
    (   TestHit == none
    ->  TestFindings = []
    ;   TestHit = hit(TestFinding),
        TestFindings = [TestFinding]
    ),
    append(Parse, Names, Syntax),
    append(Syntax, TestFindings, Findings),
    (   Findings == []
    ->  python_check_say(TestOutput),
        format("OK: ~s~n", [File])
    ;   forall(member(Finding, Findings), format("~s~n", [Finding])),
        halt(1)
    ).

python_check_say(none).
python_check_say(Output) :-
    format("~s", [Output]).

python_check_dir(File, Dir) :-
    (   file_directory_name(File, D),
        D \== ''
    ->  Dir = D
    ;   Dir = '.'
    ).

python_check_parse(File, Python, Findings) :-
    python_check_interpreter(Python, Exe),
    format(atom(Command), '"~s" -m py_compile "~s" 2>&1', [Exe, File]),
    python_check_proc_run(Command, 60000, Codes, Exit),
    (   Exit == 0
    ->  Findings = []
    ;   atom_codes(Out, Codes),
        format(atom(Finding), 'SYNTAX~n~s', [Out]),
        Findings = [Finding]
    ).

python_check_tests(Tests, Dir, Timeout, Output, Hit) :-
    format(atom(Command), 'cd "~s" && ~s 2>&1', [Dir, Tests]),
    python_check_proc_run(Command, Timeout, Codes, Exit),
    atom_codes(Out, Codes),
    Output = Out,
    (   Exit == 0
    ->  Hit = none
    ;   format(atom(Finding), 'TESTS exit ~w: ~s~n~s', [Exit, Tests, Out]),
        Hit = hit(Finding)
    ).

%% ---- the name reading --------------------------------------------------

%% The file is read by `names.pl', the same reader codegen's `guarded'
%% mode uses, so the checker and the generator cannot drift. A finding is
%% the narrow one a person would give by reading: a name that is read and
%% that no definition in the file binds.
python_check_names(File, Findings) :-
    catch(read_file_to_codes(File, Codes), _, fail),
    !,
    atom_codes(Text, Codes),
    python_names_findings(Text, Findings).
python_check_names(_, []).

%% ---- helpers -----------------------------------------------------------

python_check_interpreter(none, Exe) :-
    !,
    (   getenv('PYTHON3', Found),
        Found \== ''
    ->  Exe = Found
    ;   Exe = python3
    ).
python_check_interpreter(Exe, Exe).

python_check_proc_run(Command, Timeout, Codes, Exit) :-
    catch(proc_run(Command, Timeout, Codes, Exit), _, ( Codes = [], Exit = 124 )).
