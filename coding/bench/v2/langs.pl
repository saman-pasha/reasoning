%% coding/bench/v2/langs.pl -- the Phase 4 language layer.
%%
%% C keeps the v2 verifier. Python, cocolog and SWI-Prolog each get a
%% toolchain runner with the same stdin/stdout cases and the same exact
%% policy. The spec is the C task's requirement with only its first
%% sentence replaced by the language and its entry point; cases, held-out
%% split and budget are identical.
%%
%% The generators are each language's normal one (C's plain prompt,
%% Python's checked prompt, cocolog's guide), so a comparison measures
%% language plus normal guide, a confound the report must state. SWI has
%% no generator in this tree: its path is a direct call with a short
%% SWI-Prolog system prompt.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module('coding/shell.pl').
:- use_module('coding/bench/v2/config.pl').
:- use_module('coding/bench/v2/schema.pl').
:- use_module('coding/bench/v2/verify.pl',
              [ v2_verify/3,
                v2_case_parts/4,
                v2_match_case/6
              ]).

:- dynamic v2_language_generate_hook/6.

v2_language_supported(c).
v2_language_supported(python).
v2_language_supported(cocolog).
v2_language_supported(swipl).

v2_language_task(lcs).
v2_language_task(stable_sort).
v2_language_task(calculator).

v2_language_extension(c, c).
v2_language_extension(python, py).
v2_language_extension(cocolog, pl).
v2_language_extension(swipl, pl).

v2_language_spec(c, Task, Spec) :-
    v2_task(Task, c, Spec, _, _, _, _).
v2_language_spec(Lang, Task, Spec) :-
    v2_language_supported(Lang),
    Lang \== c,
    v2_task(Task, c, SpecC, _, _, _, _),
    atom_concat('Write a complete C program.', Rest, SpecC),
    v2_language_head(Lang, Head),
    atom_concat(Head, Rest, Spec).

v2_language_head(python,
                 'Write a complete Python 3 program.').
v2_language_head(cocolog,
                 'Write a complete cocolog program whose main/0 reads standard input and writes standard output.').
v2_language_head(swipl,
                 'Write a complete SWI-Prolog program whose main/0 reads standard input and writes standard output.').

%% ---- generation --------------------------------------------------------

v2_language_generate(Lang, Spec, Prev, Code, Usage, Error) :-
    (   v2_language_generate_hook(Lang, Spec, Prev, Code, Usage, Error)
    ->  !
    ;   v2_language_generate_child(Lang, Spec, Prev, Code, Usage, Error)
    ).

%% v2_language_generate_hook/6 is a test seam: the runner asserts none,
%% and test.pl proves the language path without a provider.
v2_language_generate_child(Lang, Spec, Prev, Code, Usage, Error) :-
    tmp_file(v2_lang_spec, SpecFile),
    tmp_file(v2_lang_code, CodeFile),
    v2_lang_write_atom(SpecFile, Spec),
    v2_language_prev_files(Prev, PrevFile, DiagFile),
    current_prolog_flag(executable, Cocolog),
    codegen_shell_quote(Cocolog, QCocolog),
    codegen_shell_quote(SpecFile, QSpec),
    codegen_shell_quote(CodeFile, QCode),
    codegen_shell_quote(PrevFile, QPrev),
    codegen_shell_quote(DiagFile, QDiag),
    v2_language_effort(Lang, Effort),
    format(atom(Cmd),
           '~w query "use_module(''coding/bench/v2/lang_gen.pl''), run" -- --lang ~w --spec ~w --out ~w --effort ~w --prev ~w --diag ~w 2>&1',
           [QCocolog, Lang, QSpec, QCode, Effort, QPrev, QDiag]),
    v2_config(child_timeout_ms, Timeout),
    catch(proc_run(Cmd, Timeout, OutCodes0, Exit0),
          Ball,
          ( OutCodes0 = [],
            Exit0 = -1,
            v2_lang_error(Ball, RunError)
          )),
    (   var(RunError) -> RunError = none ; true ),
    atom_codes(OutText, OutCodes0),
    (   RunError == none,
        Exit0 == 0,
        exists_file(CodeFile)
    ->  read_file_to_codes(CodeFile, CodeCodes),
        atom_codes(Code, CodeCodes),
        (   Code == ''
        ->  Usage = usage(0, 0, 0, 0, 0),
            Error = 'child wrote empty code'
        ;   catch(v2_lang_parse_usage(OutText, Usage), _,
                  Usage = usage(0, 0, 0, 0, 0)),
            Error = none
        )
    ;   Code = '',
        Usage = usage(0, 0, 0, 0, 0),
        v2_lang_limit(OutText, OutTail),
        (   RunError == none
        ->  format(atom(Error0), 'language child failed (exit ~w)~n~s',
                   [Exit0, OutTail]),
            Error = Error0
        ;   Error = RunError
        )
    ),
    v2_lang_remove_files([SpecFile, CodeFile, PrevFile, DiagFile]).

v2_language_effort(_, none).

v2_language_prev_files(none, '-', '-') :- !.
v2_language_prev_files(prev(Code, Diag), PrevFile, DiagFile) :-
    tmp_file(v2_lang_prev, PrevFile),
    tmp_file(v2_lang_diag, DiagFile),
    v2_lang_write_atom(PrevFile, Code),
    v2_lang_write_atom(DiagFile, Diag).

v2_lang_parse_usage(Text, Usage) :-
    (   v2_lang_usage_line(Text, Line)
    ->  v2_lang_usage_parts(Line, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

v2_lang_usage_line(Text, LineAtom) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    sub_atom(LineAtom, 0, 6, _, 'USAGE '),
    !.

v2_lang_usage_parts(Line, usage(P, C, T, R, H)) :-
    split_string(Line, " ", " ", Parts),
    Parts = [_, P0, C0, T0, R0, H0],
    v2_lang_number(P0, P),
    v2_lang_number(C0, C),
    v2_lang_number(T0, T),
    v2_lang_number(R0, R),
    v2_lang_number(H0, H).

v2_lang_number(String, N) :-
    atom_string(A, String),
    atom_number(A, N).

%% ---- verification ------------------------------------------------------

v2_language_verify(c, Task, Code, Verdict) :-
    !,
    v2_verify(Task, Code, Verdict).
v2_language_verify(Lang, Task, Code, Verdict) :-
    v2_language_supported(Lang),
    v2_task(Task, c, _, Repair, Heldout, Policy, budget(_, TaskTimeout, _)),
    v2_lang_case_timeout(Lang, TaskTimeout, Timeout),
    v2_lang_verify(Lang, Code, Repair, Heldout, Policy, Timeout, Verdict).

%% Interpreted runtimes need their startup time; the model-call budget is
%% still the task's. C keeps the task's 3 s case timeout so no C result
%% moves, and every other language gets at least 10 s. This is a stated
%% confound of the comparison, not a policy change for C.
v2_lang_case_timeout(c, Timeout, Timeout) :- !.
v2_lang_case_timeout(_, TaskTimeout, 10000) :-
    TaskTimeout =< 10000,
    !.
v2_lang_case_timeout(_, TaskTimeout, TaskTimeout).

v2_lang_verify(Lang, Code, Repair, Heldout, Policy, Timeout, Verdict) :-
    (   Code == ''
    ->  Verdict = verdict(fail(compile('the reply is empty')), not_run)
    ;   v2_lang_temp_dir(Dir),
        v2_lang_source_name(Lang, Name),
        format(atom(Source), '~s/~w', [Dir, Name]),
        atom_codes(Code, Codes0),
        append(Codes0, [10], Codes),
        write_file_from_codes(Source, Codes),
        call_cleanup(
            v2_lang_judge(Lang, Source, Repair, Heldout, Policy, Timeout,
                          Verdict),
            v2_lang_clean_dir(Dir))
    ).

v2_lang_source_name(python, 'program.py').
v2_lang_source_name(cocolog, 'program.pl').
v2_lang_source_name(swipl, 'program.pl').

v2_lang_judge(Lang, Source, Repair, Heldout, Policy, Timeout, Verdict) :-
    v2_lang_run_cases(Lang, Source, Repair, Policy, Timeout, 1, RepairFailures),
    (   RepairFailures == []
    ->  v2_lang_run_cases(Lang, Source, Heldout, Policy, Timeout, 1,
                          HeldoutFailures),
        (   HeldoutFailures == []
        ->  HeldoutVerdict = ok
        ;   HeldoutVerdict = fail(heldout)
        ),
        Verdict = verdict(ok, HeldoutVerdict)
    ;   Verdict = verdict(fail(cases(RepairFailures)), not_run)
    ).

v2_lang_run_cases(_, _, [], _, _, _, []).
v2_lang_run_cases(Lang, Source, [Case|Cases], Policy, Timeout, Index,
                  Failures) :-
    v2_case_parts(Case, Input, Expected, ExpectedExit),
    tmp_file(v2_lang_in, InFile),
    tmp_file(v2_lang_out, OutFile),
    tmp_file(v2_lang_err, ErrFile),
    atom_codes(Input, InCodes),
    write_file_from_codes(InFile, InCodes),
    v2_lang_command(Lang, Source, InFile, OutFile, ErrFile, Cmd),
    catch(proc_run(Cmd, Timeout, _Codes, Exit0),
          Ball,
          ( Exit0 = -1,
            v2_lang_error(Ball, RunError)
          )),
    (   var(RunError) -> RunError = none ; true ),
    v2_lang_read_codes(OutFile, OutCodes),
    v2_lang_read_codes(ErrFile, ErrCodes),
    atom_codes(Actual, OutCodes),
    atom_codes(Stderr, ErrCodes),
    v2_match_case(Policy, Input, Actual, Expected, Match, Reason),
    (   RunError == none,
        Exit0 =:= ExpectedExit,
        Match == yes,
        Stderr == ''
    ->  Here = []
    ;   v2_lang_case_failure(Index, Input, Expected, ExpectedExit, Exit0,
                             Actual, Reason, Stderr, RunError, Failure0),
        v2_lang_source_context(Source, Stderr, Failure0, Failure1),
        v2_lang_trace_context(Lang, Index, Source, InFile, Stderr, Exit0,
                              ExpectedExit, Timeout, Failure1, Failure),
        Here = [Failure]
    ),
    v2_lang_remove_files([InFile, OutFile, ErrFile]),
    Next is Index + 1,
    v2_lang_run_cases(Lang, Source, Cases, Policy, Timeout, Next, Rest),
    append(Here, Rest, Failures).

v2_lang_command(python, Source, In, Out, Err, Cmd) :-
    v2_lang_python(Python),
    codegen_shell_quote(Python, QPython),
    codegen_shell_quote(Source, QSource),
    codegen_shell_quote(In, QIn),
    codegen_shell_quote(Out, QOut),
    codegen_shell_quote(Err, QErr),
    format(atom(Cmd), '~w -I ~w < ~w > ~w 2> ~w',
           [QPython, QSource, QIn, QOut, QErr]).
v2_lang_command(cocolog, Source, In, Out, Err, Cmd) :-
    current_prolog_flag(executable, Exe),
    codegen_shell_quote(Exe, QExe),
    codegen_shell_quote(Source, QSource),
    codegen_shell_quote(In, QIn),
    codegen_shell_quote(Out, QOut),
    codegen_shell_quote(Err, QErr),
    format(atom(Cmd), '~w run ~w < ~w > ~w 2> ~w',
           [QExe, QSource, QIn, QOut, QErr]).
v2_lang_command(swipl, Source, In, Out, Err, Cmd) :-
    v2_lang_swipl(Swipl),
    codegen_shell_quote(Swipl, QSwipl),
    codegen_shell_quote(Source, QSource),
    codegen_shell_quote(In, QIn),
    codegen_shell_quote(Out, QOut),
    codegen_shell_quote(Err, QErr),
    format(atom(Cmd), '~w -q -f ~w -g main -t halt < ~w > ~w 2> ~w',
           [QSwipl, QSource, QIn, QOut, QErr]).

v2_lang_python(Python) :-
    (   getenv('PYTHON3', Python0),
        Python0 \== ''
    ->  atom_string(Python, Python0)
    ;   Python = python3
    ).

v2_lang_swipl(Swipl) :-
    (   getenv('SWIPL', Swipl0),
        Swipl0 \== ''
    ->  atom_string(Swipl, Swipl0)
    ;   Swipl = swipl
    ).

v2_lang_case_failure(Index, Input, Expected, ExpectedExit, Exit, Actual,
                     Reason, Stderr, RunError, Failure) :-
    v2_lang_case_failure0(Index, Input, Expected, ExpectedExit, Exit, Actual,
                          RunError, Base0),
    (   Reason == none
    ->  Base = Base0
    ;   format(atom(Base), '~w~nreason: ~w', [Base0, Reason])
    ),
    (   Stderr == ''
    ->  Failure = Base
    ;   format(atom(Failure), '~w~nstderr: ~w', [Base, Stderr])
    ).

v2_lang_case_failure0(Index, Input, Expected, ExpectedExit, Exit, Actual,
                      RunError, Failure) :-
    (   RunError \== none
    ->  format(atom(Failure),
               'CASE ~w COULD NOT RUN (expected exit ~w)~ninput: ~w~nexpected: ~w~nerror: ~w',
               [Index, ExpectedExit, Input, Expected, RunError])
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

%% ---- the failing source line -------------------------------------------
%%
%% A diagnostic that gives only file:line:column leaves a repair call
%% guessing which token the parser refused. GCC and Python already quote
%% the source line; cocolog does not. When the line is absent, append it
%% and a caret under the column, at most once per case.

v2_lang_source_context(Source, Stderr, Failure, WithContext) :-
    (   Stderr \== '',
        v2_lang_error_position(Stderr, Line, Col),
        v2_lang_source_line(Source, Line, Text),
        Text \== '',
        \+ sub_atom(Stderr, _, _, _, Text)
    ->  v2_lang_caret(Col, Caret),
        format(atom(WithContext),
               '~w~nThe source line ~w, column ~w:~n~w~n~w',
               [Failure, Line, Col, Text, Caret])
    ;   WithContext = Failure
    ).

v2_lang_error_position(Stderr, Line, Col) :-
    split_string(Stderr, "\n", " \t\r", Lines),
    member(Text, Lines),
    split_string(Text, ":", " \t\r", Parts),
    v2_lang_position_parts(Parts, Line, Col),
    !.

v2_lang_position_parts([File, LineText, ColText, Message|_], Line, Col) :-
    sub_atom(File, _, _, _, '.'),
    v2_lang_position_number(LineText, Line),
    v2_lang_position_number(ColText, Col),
    \+ v2_lang_text_empty(Message).
v2_lang_position_parts([_|Parts], Line, Col) :-
    v2_lang_position_parts(Parts, Line, Col).

v2_lang_text_empty(Text) :-
    (   string(Text)
    ->  string_length(Text, 0)
    ;   Text == ''
    ).

v2_lang_position_number(Text, N) :-
    atom_string(A, Text),
    atom_number(A, N),
    integer(N),
    N > 0.

v2_lang_source_line(Source, N, Text) :-
    catch(read_file_to_codes(Source, Codes), _, fail),
    atom_codes(SourceText, Codes),
    v2_lang_line_at(SourceText, N, Text).

v2_lang_line_at(Text, N, Line) :-
    N > 0,
    (   sub_atom(Text, P, 1, _, '\n')
    ->  sub_atom(Text, 0, P, _, First),
        (   N =:= 1
        ->  Line = First
        ;   Start is P + 1,
            sub_atom(Text, Start, _, 0, Rest),
            Next is N - 1,
            v2_lang_line_at(Rest, Next, Line)
        )
    ;   N =:= 1,
        Line = Text
    ).

v2_lang_caret(Col, Caret) :-
    N is Col - 1,
    length(Spaces, N),
    maplist(=( ' ' ), Spaces),
    append(Spaces, ['^'], Parts),
    atomic_list_concat(Parts, Caret).

%% A cocolog run exits 1 with empty stderr when its entry goal simply
%% failed. The four-port tracer names the goals that failed, which is the
%% only clue a repair call gets; run it once, for the first case, and keep
%% the last failures only.
v2_lang_trace_context(cocolog, 1, Source, In, Stderr, Exit, ExpectedExit,
                      Timeout, Failure, WithTrace) :-
    !,
    (   Stderr == '',
        Exit =\= ExpectedExit,
        Exit =\= 124,
        v2_lang_trace_lines(Source, In, Timeout, Lines)
    ->  atomic_list_concat(Lines, '\n', Trace),
        format(atom(WithTrace),
               '~w~nThe entry goal failed with no stderr; the trace of its last failures:~n~w',
               [Failure, Trace])
    ;   WithTrace = Failure
    ).
v2_lang_trace_context(_, _, _, _, _, _, _, _, Failure, Failure).

v2_lang_trace_lines(Source, In, Timeout, Lines) :-
    tmp_file(v2_lang_trace, TraceFile),
    v2_lang_trace_command(Source, In, TraceFile, Cmd),
    catch(proc_run(Cmd, Timeout, _, _), _, true),
    v2_lang_read_codes(TraceFile, Codes),
    v2_lang_remove_files([TraceFile]),
    atom_codes(Text, Codes),
    split_string(Text, "\n", " \t\r", Parts),
    v2_lang_fail_lines(Parts, Fails),
    reverse(Fails, Rev),
    v2_lang_depth_first(Rev, [], ChainRev),
    reverse(ChainRev, Chain),
    v2_lang_take_last(20, Chain, Lines),
    Lines \== [].

v2_lang_take_last(N, List, Last) :-
    length(List, L),
    (   L > N
    ->  Skip is L - N,
        length(Prefix, Skip),
        append(Prefix, Last, List)
    ;   Last = List
    ).

%% One line per depth, taken from the end, is the final failing chain:
%% the deepest repeated goal (a loop of digit/1 tests) no longer crowds
%% the caller's goal out of the report.
v2_lang_depth_first([], _, []).
v2_lang_depth_first([Line|Lines], Seen, Kept) :-
    (   v2_lang_fail_depth(Line, Depth),
        \+ memberchk(Depth, Seen)
    ->  Kept = [Line|Rest],
        Seen1 = [Depth|Seen]
    ;   Kept = Rest,
        Seen1 = Seen
    ),
    v2_lang_depth_first(Lines, Seen1, Rest).

v2_lang_fail_depth(Line, Depth) :-
    sub_atom(Line, B, 7, _, 'Fail: ('),
    Start is B + 7,
    sub_atom(Line, Start, _, 0, Rest),
    sub_atom(Rest, End, 1, _, ')'),
    sub_atom(Rest, 0, End, _, Digits),
    atom_string(Text, Digits),
    atom_number(Text, Depth),
    integer(Depth).

v2_lang_trace_command(Source, In, TraceFile, Cmd) :-
    current_prolog_flag(executable, Exe),
    codegen_shell_quote(Exe, QExe),
    codegen_shell_quote(Source, QSource),
    codegen_shell_quote(In, QIn),
    codegen_shell_quote(TraceFile, QTrace),
    format(atom(Cmd), '~w --trace run ~w < ~w > /dev/null 2> ~w',
           [QExe, QSource, QIn, QTrace]).

v2_lang_fail_lines([], []).
v2_lang_fail_lines([Text|Texts], Kept) :-
    atom_string(Line, Text),
    (   sub_atom(Line, _, _, _, 'Fail:')
    ->  Kept = [Line|Rest]
    ;   Kept = Rest
    ),
    v2_lang_fail_lines(Texts, Rest).

%% ---- small helpers -----------------------------------------------------

v2_lang_temp_dir(Dir) :-
    tmp_file(v2_lang, Try),
    (   exists_directory(Try)
    ->  v2_lang_temp_dir(Dir)
    ;   catch(make_directory(Try), _, fail)
    ->  Dir = Try
    ;   throw(error(v2_lang_temp_dir(Try), v2_lang_temp_dir/1))
    ).

v2_lang_clean_dir(Dir) :-
    catch(c_clean_dir(Dir), _, true).

v2_lang_read_codes(File, Codes) :-
    (   exists_file(File)
    ->  catch(read_file_to_codes(File, Codes), _, Codes = [])
    ;   Codes = []
    ).

v2_lang_write_atom(File, Atom) :-
    atom_codes(Atom, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

v2_lang_remove_files([]).
v2_lang_remove_files([File|Files]) :-
    (   File == '-'
    ->  true
    ;   catch(delete_file(File), _, true)
    ),
    v2_lang_remove_files(Files).

v2_lang_limit(Text, Limited) :-
    v2_config(max_diagnostic, Max),
    atom_length(Text, Len),
    (   Len =< Max
    ->  Limited = Text
    ;   sub_atom(Text, 0, Max, _, Limited)
    ).

v2_lang_error(Ball, Text) :-
    (   Ball = error(Formal, _)
    ->  format(atom(Text), '~w', [Formal])
    ;   format(atom(Text), '~w', [Ball])
    ).
