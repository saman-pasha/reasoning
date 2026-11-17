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
                v2_match/4
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
    v2_match(Policy, Actual, Expected, Match),
    (   RunError == none,
        Exit0 =:= ExpectedExit,
        Match == yes,
        Stderr == ''
    ->  Here = []
    ;   v2_lang_case_failure(Index, Input, Expected, ExpectedExit, Exit0,
                             Actual, Stderr, RunError, Failure),
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
                     Stderr, RunError, Failure) :-
    v2_lang_case_failure0(Index, Input, Expected, ExpectedExit, Exit, Actual,
                          RunError, Base),
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
