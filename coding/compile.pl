%% coding/compile.pl -- compile and run a C source atom.
%%
%%     c_compile_check(+Code, -Verdict)
%%     c_compile_check(+Code, +CFlags, -Verdict)
%%         ok, or fail(Diagnostic). The source is written to a fresh
%%         temporary directory and compiled with
%%         `clang -std=c17 -Wall -Wextra -O0 CFlags'; stderr is merged into
%%         the diagnostic. A compiler that cannot be run is a failure with
%%         its error, not an exception.
%%
%%     c_test_check(+Code, +Cases, -Verdict)
%%     c_test_check(+Code, +Cases, +Timeout, -Verdict)
%%     c_test_check(+Code, +Cases, +Timeout, +CFlags, -Verdict)
%%         compile with AddressSanitizer and UndefinedBehaviorSanitizer,
%%         then run the binary on each case. ok, or
%%         fail(compile, Diagnostic) or fail(test, Diagnostic). A case is
%%         case(Input, Expected) or case(Input, Expected, Exit), the atoms
%%         and an exit status that defaults to 0; Input keeps its newlines,
%%         and both sides are compared after trailing whitespace and final
%%         newlines are trimmed. A sanitizer report is a failed case, even
%%         when the printed answer happens to match; leak detection is off
%%         (a one-shot program's leak is no answer's business). Timeout is
%%         the milliseconds one case may run, 3000 unless a caller says;
%%         CFlags are extra compiler arguments, '' unless a caller says.
%%
%%     c_analyze_check(+Code, -Verdict)
%%     c_analyze_check(+Code, +CFlags, -Verdict)
%%         `clang --analyze' over the source. ok when it prints no
%%         `warning:'; fail(Diagnostic) with its output otherwise. This is
%%         the deeper check when no cases are given; it is slower than a
%%         compile and finds paths the compiler itself does not.
%%
%%     c_run_cases(+Exe, +Cases, -Failures)
%%     c_run_cases(+Exe, +Cases, +Timeout, -Failures)
%%         the runner on its own: [] when every case matches.
%%
%%     c_read_cases(+File, -Cases)
%%         read one Prolog term, cases([case(Input, Expected), ...]), or
%%         text blocks (`# input', the input, `# expected', the expected
%%         output). A bad file throws
%%         error(codegen_error(cases_file, Message), _). The formats and
%%         their empty-block rules are described below.
%%
%%     c_parse_text_cases(+Text, -Cases)
%%         the text-block format from an atom, with no file. The same
%%         errors as c_read_cases/2.

:- use_module(library(process)).

%% ---- compile -----------------------------------------------------------

c_compile_check(Code, Verdict) :-
    c_compile_check(Code, '', Verdict).

c_compile_check(Code, CFlags, Verdict) :-
    c_compile(Code, plain, CFlags, _Exe, Verdict).

c_compile(Code, Mode, CFlags, Exe, Verdict) :-
    tmp_file(codegen_check, Dir),
    make_directory(Dir),
    atom_concat(Dir, '/check.c', CFile),
    atom_concat(Dir, '/check.out', Exe),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(CFile, Codes),
    c_compile_command(Mode, CFlags, Exe, CFile, Cmd),
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

c_compile_command(plain, CFlags, Exe, CFile, Cmd) :-
    format(atom(Cmd), 'clang -std=c17 -Wall -Wextra -O0 ~s -o ~s ~s 2>&1',
           [CFlags, Exe, CFile]).
c_compile_command(sanitized, CFlags, Exe, CFile, Cmd) :-
    format(atom(Cmd),
           'clang -std=c17 -Wall -Wextra -O0 -g ~s -fsanitize=address,undefined -fno-sanitize-recover=all -o ~s ~s 2>&1',
           [CFlags, Exe, CFile]).

%% ---- static analysis ---------------------------------------------------

c_analyze_check(Code, Verdict) :-
    c_analyze_check(Code, '', Verdict).

c_analyze_check(Code, CFlags, Verdict) :-
    tmp_file(codegen_analyze, Dir),
    make_directory(Dir),
    atom_concat(Dir, '/analyze.c', CFile),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(CFile, Codes),
    format(atom(Cmd),
           'clang --analyze -Xanalyzer -analyzer-output=text -std=c17 -Wall -Wextra -O0 ~s ~s 2>&1',
           [CFlags, CFile]),
    c_run_command(Cmd, 120000, OutCodes, Exit, Error),
    atom_codes(Output, OutCodes),
    (   Error == none,
        Exit == 0,
        \+ sub_atom(Output, _, _, _, 'warning:')
    ->  Verdict = ok
    ;   (   Error \== none
        ->  format(atom(Diag0), 'analyzer could not run: ~w~n~s', [Error, Output])
        ;   Exit \== 0
        ->  format(atom(Diag0), 'ANALYZER FAILED (exit ~w)~n~s', [Exit, Output])
        ;   format(atom(Diag0), 'ANALYZER FINDINGS~n~s', [Output])
        ),
        c_limit(4000, Diag0, Diag),
        Verdict = fail(Diag)
    ).

%% ---- compile and run the cases ----------------------------------------

c_test_check(Code, Cases, Verdict) :-
    c_test_check(Code, Cases, 3000, Verdict).

c_test_check(Code, Cases, Timeout, Verdict) :-
    c_test_check(Code, Cases, Timeout, '', Verdict).

c_test_check(Code, Cases, Timeout, CFlags, Verdict) :-
    c_compile(Code, sanitized, CFlags, Exe, CompileVerdict),
    (   CompileVerdict == ok
    ->  c_run_cases(Exe, Cases, Timeout, Failures),
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
    c_run_cases(Exe, Cases, 3000, Failures).

c_run_cases(Exe, Cases, Timeout, Failures) :-
    c_run_cases(Cases, Exe, Timeout, 1, Failures).

c_run_cases([], _, _, _, []).
c_run_cases([Case|Rest], Exe, Timeout, Index, Failures) :-
    c_case_parts(Case, Input, Expected, ExpectedExit),
    tmp_file(codegen_case, InFile),
    atom_codes(Input, InCodes),
    write_file_from_codes(InFile, InCodes),
    format(atom(Cmd), 'ASAN_OPTIONS=detect_leaks=0 ~s < ~s 2>&1', [Exe, InFile]),
    c_run_command(Cmd, Timeout, OutCodes, Exit, Error),
    atom_codes(Actual0, OutCodes),
    c_norm(Actual0, Actual),
    c_norm(Expected, ExpNorm),
    (   Error == none,
        Exit \== 124,
        Exit =:= ExpectedExit,
        Actual == ExpNorm
    ->  Here = []
    ;   c_case_failure(Index, Input, Expected, ExpectedExit, Exit, Actual,
                       Error, Failure),
        Here = [Failure]
    ),
    Next is Index + 1,
    c_run_cases(Rest, Exe, Timeout, Next, Tail),
    append(Here, Tail, Failures).

c_case_parts(case(Input, Expected), Input, Expected, 0).
c_case_parts(case(Input, Expected, Exit), Input, Expected, Exit).

c_case_failure(Index, Input, Expected, ExpectedExit, Exit, Actual, Error, Failure) :-
    (   Error \== none
    ->  format(atom(Failure),
               'CASE ~w COULD NOT RUN (expected exit ~w)~ninput: ~w~nexpected: ~w~nerror: ~w',
               [Index, ExpectedExit, Input, Expected, Error])
    ;   Exit == 124
    ->  format(atom(Failure),
               'CASE ~w TIMEOUT~ninput: ~w~nexpected: ~w',
               [Index, Input, Expected])
    ;   Exit =\= ExpectedExit
    ->  format(atom(Failure),
               'CASE ~w EXIT ~w (expected ~w)~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Exit, ExpectedExit, Input, Expected, Actual])
    ;   format(atom(Failure),
               'CASE ~w WRONG~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Input, Expected, Actual])
    ).

%% ---- reading a cases file ---------------------------------------------
%%
%% Two formats: one Prolog term,
%%
%%     cases([case('1 2 3\n', '6'), case('4 5\n', '9', 2)]).
%%
%% or text blocks, which need no escaping:
%%
%%     # input
%%     1 2 3
%%     # expected
%%     6
%%     # input
%%     4 5
%%     # expected
%%     9
%%     # exit 2
%%
%% An exit status is optional and 0 unless said: the third argument in the
%% term, `# exit N' after the expected block in the text. An empty input
%% is `# input' immediately followed by `# expected'; a blank line between
%% the two is an empty line (one newline), not no input. An empty expected
%% is `# expected' followed by the next `# input' or the end. A line is a
%% marker only when it is exactly one of the three (or `# exit N'); any
%% other line is content. An input block ends with a newline, as a file's
%% line does; expected output is trimmed by the runner.
c_read_cases(File, Cases) :-
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  true
    ;   format(atom(Msg), 'cannot read ~s', [File]),
        throw(error(codegen_error(cases_file, Msg), c_read_cases/2))
    ),
    atom_codes(Text, Codes),
    (   catch(read_term_from_atom(Text, Term, []), _, fail),
        Term = cases(Cases0),
        c_valid_cases(Cases0)
    ->  Cases = Cases0
    ;   c_read_text_cases(Text, Cases)
    ).

c_read_text_cases(Text, Cases) :-
    c_parse_text_cases(Text, Cases).

%% The same text blocks from an atom, so a caller that already holds the
%% text (a model's reply) needs no file. Errors are the cases_file errors
%% c_read_cases/2 raises.
c_parse_text_cases(Text, Cases) :-
    split_string(Text, "\n", "", Lines0),
    c_drop_final_empty(Lines0, Lines1),
    findall(Line,
            (   member(Raw, Lines1),
                atom_string(Atom0, Raw),
                c_strip_cr(Atom0, Line)
            ),
            Lines),
    c_text_cases(Lines, 1, none, [], [], [], CasesRev),
    reverse(CasesRev, Cases).

%% A file's final newline ends its last line; it is not an empty line of
%% content. One empty part is dropped, so an input block can still end on
%% a blank line of its own.
c_drop_final_empty(Lines, Init) :-
    (   append(Init0, [Last], Lines),
        c_empty_string(Last)
    ->  Init = Init0
    ;   Init = Lines
    ).

c_strip_cr(Atom0, Atom) :-
    (   sub_atom(Atom0, _, 1, 0, '\r')
    ->  sub_atom(Atom0, 0, _, 1, Atom)
    ;   Atom = Atom0
    ).

c_text_cases([], _, none, _, _, [], _) :-
    c_cases_error('the cases file has no "# input" block').
c_text_cases([], _, none, _, _, Cases, Cases) :-
    Cases \== [].
c_text_cases([], _, input, _, _, _, _) :-
    c_cases_error('the cases file ends inside an input block').
c_text_cases([], _, expected, In, Ex, Cases, Closed) :-
    c_close_case(In, Ex, 0, Cases, Closed).
c_text_cases([], _, after(Exit), In, Ex, Cases, Closed) :-
    c_close_case(In, Ex, Exit, Cases, Closed).

c_text_cases([Line|Rest], N, none, _, _, Cases, Closed) :-
    (   Line == '# input'
    ->  N1 is N + 1,
        c_text_cases(Rest, N1, input, [], [], Cases, Closed)
    ;   Line == ''
    ->  N1 is N + 1,
        c_text_cases(Rest, N1, none, [], [], Cases, Closed)
    ;   c_cases_error_at(N, 'text before the first # input')
    ).
c_text_cases([Line|Rest], N, input, In, Ex, Cases, Closed) :-
    (   Line == '# expected'
    ->  N1 is N + 1,
        c_text_cases(Rest, N1, expected, In, [], Cases, Closed)
    ;   Line == '# input'
    ->  c_cases_error_at(N, 'a new # input before # expected')
    ;   N1 is N + 1,
        c_text_cases(Rest, N1, input, [Line|In], Ex, Cases, Closed)
    ).
c_text_cases([Line|Rest], N, expected, In, Ex, Cases, Closed) :-
    (   Line == '# input'
    ->  c_close_case(In, Ex, 0, Cases, Cases1),
        N1 is N + 1,
        c_text_cases(Rest, N1, input, [], [], Cases1, Closed)
    ;   Line == '# expected'
    ->  c_cases_error_at(N, 'a second # expected')
    ;   c_exit_marker(Line, Exit)
    ->  N1 is N + 1,
        c_text_cases(Rest, N1, after(Exit), In, Ex, Cases, Closed)
    ;   c_exit_prefix(Line)
    ->  c_cases_error_at(N, '# exit needs a non-negative number')
    ;   N1 is N + 1,
        c_text_cases(Rest, N1, expected, In, [Line|Ex], Cases, Closed)
    ).
c_text_cases([Line|Rest], N, after(Exit), In, Ex, Cases, Closed) :-
    (   Line == '# input'
    ->  c_close_case(In, Ex, Exit, Cases, Cases1),
        N1 is N + 1,
        c_text_cases(Rest, N1, input, [], [], Cases1, Closed)
    ;   Line == ''
    ->  N1 is N + 1,
        c_text_cases(Rest, N1, after(Exit), In, Ex, Cases, Closed)
    ;   c_cases_error_at(N, 'content after # exit')
    ).

c_exit_prefix(Line) :-
    sub_atom(Line, 0, 6, _, '# exit').

c_exit_marker(Line, Exit) :-
    sub_atom(Line, 0, 6, _, '# exit'),
    sub_atom(Line, 7, _, 0, Number),
    atom_number(Number, Exit0),
    integer(Exit0),
    Exit0 >= 0,
    Exit = Exit0.

c_close_case(InRev, ExRev, 0, Cases, [case(Input, Expected)|Cases]) :-
    !,
    c_input_atom(InRev, Input),
    c_expected_atom(ExRev, Expected).
c_close_case(InRev, ExRev, Exit, Cases,
             [case(Input, Expected, Exit)|Cases]) :-
    c_input_atom(InRev, Input),
    c_expected_atom(ExRev, Expected).

c_input_atom([], '').
c_input_atom(Rev, Atom) :-
    Rev \== [],
    reverse(Rev, Lines),
    atomic_list_concat(Lines, '\n', Body),
    atom_concat(Body, '\n', Atom).

c_expected_atom([], '').
c_expected_atom(Rev, Atom) :-
    Rev \== [],
    reverse(Rev, Lines),
    atomic_list_concat(Lines, '\n', Atom).

c_cases_error_at(N, Msg) :-
    format(atom(Full), 'line ~w: ~s', [N, Msg]),
    c_cases_error(Full).

c_cases_error(Msg) :-
    throw(error(codegen_error(cases_file, Msg), c_read_cases/2)).

c_valid_cases([]).
c_valid_cases([case(Input, Expected)|Rest]) :-
    atom(Input),
    atom(Expected),
    c_valid_cases(Rest).
c_valid_cases([case(Input, Expected, Exit)|Rest]) :-
    atom(Input),
    atom(Expected),
    integer(Exit),
    Exit >= 0,
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
