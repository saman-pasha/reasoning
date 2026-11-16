%% coding/bench/v2/verify.pl -- one verifier for v2 tasks.
%%
%% C is compiled with the sanitizers, run on the repair cases first and on
%% the held-out cases only for the final verdict. Output is compared under
%% the task's declared policy; the legacy per-line normalisation is not the
%% default. A held-out failure is a failure, but its case is not put in a
%% diagnostic the model can see.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module('coding/shell.pl').
:- use_module('coding/compile.pl').
:- use_module('coding/bench/v2/schema.pl').

v2_verify(Task, Code, Verdict) :-
    v2_task(Task, c, _, Repair, Heldout, Policy, budget(_, TimeoutMs, _)),
    c_compile(Code, sanitized, '', c17, Exe, Compile),
    call_cleanup(
        v2_judge(Exe, Compile, Repair, Heldout, Policy, TimeoutMs, Verdict),
        v2_clean_exe(Exe)).

v2_judge(_, fail(Diag), _, _, _, _, verdict(fail(compile(Diag)), not_run)) :-
    !.
v2_judge(Exe, ok, Repair, Heldout, Policy, TimeoutMs, Verdict) :-
    v2_run_cases(Repair, Exe, Policy, TimeoutMs, RepairVerdict),
    (   RepairVerdict == ok
    ->  v2_run_cases(Heldout, Exe, Policy, TimeoutMs, HeldoutVerdict0),
        (   HeldoutVerdict0 == ok
        ->  HeldoutVerdict = ok
        ;   HeldoutVerdict = fail(heldout)
        ),
        Verdict = verdict(ok, HeldoutVerdict)
    ;   Verdict = verdict(RepairVerdict, not_run)
    ).

v2_clean_exe(Exe) :-
    (   file_directory_name(Exe, Dir)
    ->  catch(c_clean_dir(Dir), _, true)
    ;   true
    ).

v2_run_cases(Cases, Exe, Policy, TimeoutMs, Verdict) :-
    v2_case_failures(Cases, Exe, Policy, TimeoutMs, 1, Failures),
    (   Failures == []
    ->  Verdict = ok
    ;   Verdict = fail(cases(Failures))
    ).

v2_case_failures([], _, _, _, _, []).
v2_case_failures([Case|Cases], Exe, Policy, TimeoutMs, Index, Failures) :-
    v2_case_parts(Case, Input, Expected, ExpectedExit),
    tmp_file(v2_case, InFile),
    tmp_file(v2_case_out, OutFile),
    tmp_file(v2_case_err, ErrFile),
    atom_codes(Input, InCodes),
    write_file_from_codes(InFile, InCodes),
    codegen_shell_quote(Exe, QExe),
    codegen_shell_quote(InFile, QIn),
    codegen_shell_quote(OutFile, QOut),
    codegen_shell_quote(ErrFile, QErr),
    format(atom(Cmd),
           'ASAN_OPTIONS=detect_leaks=0 ~w < ~w > ~w 2> ~w',
           [QExe, QIn, QOut, QErr]),
    catch(proc_run(Cmd, TimeoutMs, _OutCodes, Exit0),
          Ball,
          ( Exit0 = -1,
            v2_error_text(Ball, RunError)
          )),
    (   var(RunError) -> RunError = none ; true ),
    v2_read_codes(OutFile, OutCodes0),
    v2_read_codes(ErrFile, ErrCodes0),
    atom_codes(Actual0, OutCodes0),
    atom_codes(Stderr0, ErrCodes0),
    v2_match(Policy, Actual0, Expected, Match),
    (   RunError == none,
        Exit0 =:= ExpectedExit,
        Match == yes,
        Stderr0 == ''
    ->  Here = []
    ;   v2_case_failure(Index, Input, Expected, ExpectedExit, Exit0,
                        Actual0, Match, Stderr0, RunError, Failure),
        Here = [Failure]
    ),
    v2_remove_files([InFile, OutFile, ErrFile]),
    Next is Index + 1,
    v2_case_failures(Cases, Exe, Policy, TimeoutMs, Next, Rest),
    append(Here, Rest, Failures).

v2_case_parts(case(Input, Expected), Input, Expected, 0).
v2_case_parts(case(Input, Expected, Exit), Input, Expected, Exit).

v2_read_codes(File, Codes) :-
    (   exists_file(File)
    ->  catch(read_file_to_codes(File, Codes), _, Codes = [])
    ;   Codes = []
    ).

v2_remove_files([]).
v2_remove_files([File|Files]) :-
    catch(delete_file(File), _, true),
    v2_remove_files(Files).

v2_case_failure(Index, Input, Expected, ExpectedExit, Exit, Actual, Match,
                Stderr, RunError, Failure) :-
    (   RunError == none,
        Exit =:= ExpectedExit,
        Match == yes
    ->  format(atom(Failure),
               'CASE ~w WROTE TO STDERR~ninput: ~w~nexpected: ~w~nstderr: ~w',
               [Index, Input, Expected, Stderr])
    ;   v2_case_failure0(Index, Input, Expected, ExpectedExit, Exit, Actual,
                         RunError, Base),
        (   Stderr == ''
        ->  Failure = Base
        ;   format(atom(Failure), '~w~nstderr: ~w', [Base, Stderr])
        )
    ).

v2_case_failure0(Index, Input, Expected, ExpectedExit, Exit, Actual, RunError,
                 Failure) :-
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

v2_match(Policy, Actual, Expected, Match) :-
    (   v2_norm(Policy, Actual, A),
        v2_norm(Policy, Expected, E),
        A == E
    ->  Match = yes
    ;   Match = no
    ).

%% exact: byte-for-byte except that one final newline is optional.
%% edge_trim: the legacy per-line trim and dropped empty lines.
%% token_normalized: runs of whitespace are one space.
v2_norm(exact, Text, Norm) :-
    atom_codes(Text, Codes),
    v2_strip_one_newline(Codes, Kept),
    atom_codes(Norm, Kept).
v2_norm(edge_trim, Text, Norm) :-
    split_string(Text, "\n", " \t\r", Lines0),
    exclude(v2_empty_string, Lines0, Lines),
    findall(A, (member(Line, Lines), atom_string(A, Line)), Atoms),
    atomic_list_concat(Atoms, '\n', Norm).
v2_norm(token_normalized, Text, Norm) :-
    split_string(Text, "\n", " \t\r", Lines0),
    findall(Joined,
            (   member(Line, Lines0),
                split_string(Line, " \t\r", " \t\r", Words0),
                exclude(v2_empty_string, Words0, Words),
                atomic_list_concat(Words, ' ', Joined)
            ),
            Lines),
    atomic_list_concat(Lines, '\n', Norm).

v2_strip_one_newline(Codes, Kept) :-
    (   append(Kept, [13, 10], Codes)
    ->  true
    ;   append(Kept, [10], Codes)
    ->  true
    ;   Kept = Codes
    ).

v2_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

v2_error_text(Ball, Text) :-
    (   Ball = error(Formal, _)
    ->  format(atom(Text), '~w', [Formal])
    ;   format(atom(Text), '~w', [Ball])
    ).
