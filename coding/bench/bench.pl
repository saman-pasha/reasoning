%% coding/bench/bench.pl -- DeepSeek codegen, high reasoning against a
%% no-reasoning verification loop.
%%
%%     REASONING_API_KEY=... \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/bench/bench.pl [-- task ...]
%%
%% Four modes per task:
%%
%%     high      one call with reasoning_effort(high)
%%     loop      up to three calls with reasoning_effort(none); after each
%%               the code is compiled with clang and run on the task's cases,
%%               and the compiler/test report goes back with the next call
%%     contract  the loop, with the obligation checklist contract.pl derives
%%               from the task's controlled-English requirement added to
%%               the prompt
%%     extract   one extra reasoning_effort(none) call rewrites the plain
%%               requirement into controlled English; the lines the reader
%%               accepts give the obligations, then the loop runs
%%
%% The measurement is the provider's own usage: prompt, completion (which
%% includes reasoning), reasoning, total, and prompt-cache hits. The code
%% is generated in a child cocolog (coding/bench/gen.pl) so this file's
%% main/0 is the only main/0 the benchmark process sees.
%%
%% The provider, model, endpoint and efforts are coding/bench/config.pl's.
%% They are DeepSeek's OpenAI-compatible endpoint, not coding/options.pl's
%% Anthropic default, so the modes differ in reasoning effort and prompt
%% only.

:- use_module(library(llm)).
:- use_module(library(process)).
:- use_module('coding/bench/config.pl').
:- use_module('coding/bench/tasks.pl').
:- use_module('coding/bench/contract.pl').

:- dynamic bench_result/7.

%% ---- the provider under test -------------------------------------------
%%
%% bench_config/2 is coding/bench/config.pl's: DeepSeek's OpenAI-compatible
%% endpoint, one model, high effort for the high mode and none for the
%% others. The extract mode also calls it directly, so the parent points
%% library(llm) at the same endpoint the children use.

%% ---- the run -----------------------------------------------------------

main :-
    (   getenv('REASONING_API_KEY', Key),
        Key \== ''
    ->  true
    ;   format("REASONING_API_KEY is not set.~n", []),
        halt(1)
    ),
    bench_llm_setup,
    bench_selected_tasks(Tasks),
    (   Tasks == []
    ->  format("no benchmark task named.~n", []),
        halt(1)
    ;   true
    ),
    catch(bench_scratch(Dir), Ball,
          ( bench_error_text(Ball, Text),
            format("cannot make benchmark directory: ~w~n", [Text]),
            halt(1)
          )),
    format("benchmark directory: ~s~n", [Dir]),
    retractall(bench_result(_, _, _, _, _, _, _)),
    format("~n===== per task =====~n", []),
    format("task mode pass attempts prompt completion reasoning total cache_hit seconds~n", []),
    forall(member(Task, Tasks), bench_task_modes(Task, Dir)),
    findall(result(Task, Mode, Success, Attempts, Usage, Seconds, Diag),
            bench_result(Task, Mode, Success, Attempts, Usage, Seconds, Diag),
            Results),
    bench_report(Results, Tasks, Dir).

bench_selected_tasks(Tasks) :-
    current_prolog_flag(argv, [_|Args]),
    (   Args == []
    ->  findall(Task, bench_task(Task, _, _), Tasks)
    ;   findall(Task, (member(Task, Args), bench_task(Task, _, _)), Tasks)
    ).

bench_scratch(Dir) :-
    tmp_file(codegen_bench, Dir),
    make_directory(Dir).

%% The parent's own model call is the extractor; it uses the same endpoint
%% and key the child generators use.
bench_llm_setup :-
    bench_config(provider, Provider),
    bench_config(base_url, BaseUrl),
    retractall(llm_provider(Provider, _, _)),
    assertz(llm_provider(Provider, BaseUrl, 'REASONING_API_KEY')).

%% ---- one task, its modes -----------------------------------------------

bench_task_modes(Task, Dir) :-
    format("===== ~w =====~n", [Task]),
    bench_mode_order(Task, Modes),
    forall(member(Mode, Modes), bench_run_mode(Task, Mode, Dir)).

%% Alternate which mode goes first, to spread any prompt-cache effect.
bench_mode_order(Task, Modes) :-
    findall(T, bench_task(T, _, _), Tasks),
    bench_index(Tasks, Task, 1, Index),
    Cycle is Index mod 4,
    bench_mode_cycle(Cycle, Modes).

bench_mode_cycle(1, [high, loop, contract, extract]).
bench_mode_cycle(2, [loop, contract, extract, high]).
bench_mode_cycle(3, [contract, extract, high, loop]).
bench_mode_cycle(0, [extract, high, loop, contract]).

bench_index([Task|_], Task, I, I) :- !.
bench_index([_|Tasks], Task, I0, I) :-
    I1 is I0 + 1,
    bench_index(Tasks, Task, I1, I).

bench_run_mode(Task, Mode, Dir) :-
    format("--- ~w / ~w ---~n", [Task, Mode]),
    bench_max_attempts(Mode, Max),
    bench_mode_spec(Mode, Task, Spec, Usage0, ExtraAttempts),
    get_time(T0),
    bench_attempts(1, Max, Task, Mode, Spec, Dir, Usage0, none,
                   Success, Attempts0, Usage, LastDiag),
    get_time(T1),
    Seconds is T1 - T0,
    Attempts is Attempts0 + ExtraAttempts,
    assertz(bench_result(Task, Mode, Success, Attempts, Usage, Seconds, LastDiag)),
    bench_print_result(Task, Mode, Success, Attempts, Usage, Seconds).

bench_max_attempts(high, 1) :- !.
bench_max_attempts(contract, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(extract, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(loop, N) :-
    bench_config(loop_attempts, N).

%% The contract mode adds the checklist derived by contract.pl to the
%% plain requirement. high and loop get the requirement alone. extract
%% spends one no-reasoning call rewriting the requirement into controlled
%% English; its usage is returned so the loop's total carries it.
bench_mode_spec(high, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).
bench_mode_spec(loop, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).
bench_mode_spec(contract, Task, Full, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _),
    bench_obligations(Task, Obligations),
    bench_obligation_lines(Obligations, Lines),
    atomic_list_concat(Lines, '\n', ObligationsText),
    format(atom(Full),
           '~s~n~nObligations derived from a controlled-English contract:~n~s',
           [Spec, ObligationsText]).
bench_mode_spec(extract, Task, Full, Usage, 1) :-
    bench_task(Task, Spec, _),
    bench_extract_contract(Task, Spec, Obligations, Usage, Error),
    (   Error == none
    ->  true
    ;   format("extract warning: ~w~n", [Error])
    ),
    (   Obligations == []
    ->  Full = Spec
    ;   bench_obligation_lines(Obligations, Lines),
        atomic_list_concat(Lines, '\n', ObligationsText),
        format(atom(Full),
               '~s~n~nObligations extracted from the requirement:~n~s',
               [Spec, ObligationsText])
    ).

%% One extraction call. The reply is parsed by contract.pl; a line the
%% controlled-English reader refuses is dropped. A failed call leaves the
%% mode with the plain requirement and its usage at zero.
bench_extract_contract(Task, Spec, Obligations, Usage, Error) :-
    bench_extract_prompt(Task, Spec, Prompt),
    bench_config(provider, Provider),
    bench_config(model, Model),
    catch(( llm_chat([msg(system,
                          'You rewrite programming requirements into controlled English sentences. Output only sentences of the allowed shapes.'),
                     msg(user, Prompt)],
                    [provider(Provider), model(Model), reasoning_effort(none)],
                    Reply),
            bench_usage_now(Usage0),
            bench_reply_obligations(Reply, _Parsed, Obligations0),
            Usage = Usage0,
            Obligations = Obligations0,
            Error = none
          ),
          Ball,
          ( Usage = usage(0, 0, 0, 0, 0),
            Obligations = [],
            bench_error_text(Ball, Error)
          )).

bench_usage_now(Usage) :-
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  bench_usage_pairs(Pairs, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

bench_usage_pairs(Pairs, usage(P, C, T, R, H)) :-
    memberchk(prompt_tokens-P, Pairs),
    memberchk(completion_tokens-C, Pairs),
    memberchk(total_tokens-T, Pairs),
    (   memberchk(completion_tokens_details-json(Details), Pairs),
        memberchk(reasoning_tokens-R, Details)
    ->  true
    ;   R = 0
    ),
    (   memberchk(prompt_cache_hit_tokens-H, Pairs)
    ->  true
    ;   H = 0
    ).

%% ---- attempts, generation and verification -----------------------------

bench_attempts(Attempt, Max, Task, Mode, Spec, Dir, Usage0, Prev,
               Success, Attempts, Usage, LastDiag) :-
    (   Attempt > Max
    ->  Success = no,
        Attempts is Max,
        Usage = Usage0,
        LastDiag = 'attempts exhausted'
    ;   bench_paths(Task, Mode, Dir, Attempt, SpecFile, CodeFile, DiagFile),
        bench_codegen(Mode, Spec, SpecFile, CodeFile, Prev, _Code, Usage1, Error),
        bench_add_usage(Usage0, Usage1, Usage2),
        (   Error == none
        ->  bench_verify(Task, Mode, Dir, Attempt, Verdict, Diag)
        ;   Verdict = fail,
            Diag = Error
        ),
        (   Verdict == ok
        ->  Success = yes,
            Attempts = Attempt,
            Usage = Usage2,
            LastDiag = ''
        ;   bench_write_atom(DiagFile, Diag),
            Next is Attempt + 1,
            bench_attempts(Next, Max, Task, Mode, Spec, Dir, Usage2,
                           prev(CodeFile, DiagFile),
                           Success, Attempts, Usage, LastDiag)
        )
    ).

bench_paths(Task, Mode, Dir, Attempt, SpecFile, CodeFile, DiagFile) :-
    format(atom(SpecFile), '~s/~w_~w_~w.spec.txt', [Dir, Task, Mode, Attempt]),
    format(atom(CodeFile), '~s/~w_~w_~w.c', [Dir, Task, Mode, Attempt]),
    format(atom(DiagFile), '~s/~w_~w_~w.diag.txt', [Dir, Task, Mode, Attempt]).

bench_code_file(Task, Mode, Dir, Attempt, File) :-
    format(atom(File), '~s/~w_~w_~w.c', [Dir, Task, Mode, Attempt]).

bench_exe_file(Task, Mode, Dir, Attempt, File) :-
    format(atom(File), '~s/~w_~w_~w.out', [Dir, Task, Mode, Attempt]).

bench_input_file(Task, Mode, Dir, Attempt, Index, File) :-
    format(atom(File), '~s/~w_~w_~w_~w.in', [Dir, Task, Mode, Attempt, Index]).

%% One child cocolog per call. It writes CodeFile and prints its usage.
bench_codegen(Mode, Spec, SpecFile, CodeFile, Prev, Code, Usage, Error) :-
    bench_write_atom(SpecFile, Spec),
    bench_prev_files(Prev, PrevFile, DiagFile),
    bench_effort_atom(Mode, EffortAtom),
    cocolog(Cocolog),
    format(atom(Cmd),
           '"~s" query "use_module(''coding/bench/gen.pl''), run" -- ~s ~s ~w ~s ~s 2>&1',
           [Cocolog, SpecFile, CodeFile, EffortAtom, PrevFile, DiagFile]),
    bench_run_command(Cmd, 600000, OutCodes, Exit, RunError),
    atom_codes(OutText, OutCodes),
    (   Exit == 0,
        exists_file(CodeFile)
    ->  read_file_to_codes(CodeFile, CodeCodes),
        atom_codes(Code, CodeCodes),
        (   Code == ''
        ->  Usage = usage(0, 0, 0, 0, 0),
            Error = 'child wrote empty code'
        ;   bench_parse_usage(OutText, Usage),
            (   RunError == none
            ->  Error = none
            ;   Error = RunError
            )
        )
    ;   Code = '',
        Usage = usage(0, 0, 0, 0, 0),
        bench_limit(4000, OutText, OutTail),
        format(atom(Error0), 'codegen child failed (exit ~w)~n~s', [Exit, OutTail]),
        (   RunError == none
        ->  Error = Error0
        ;   Error = RunError
        )
    ).

bench_prev_files(none, '-', '-') :- !.
bench_prev_files(prev(CodeFile, DiagFile), CodeFile, DiagFile).

bench_effort_atom(high, high) :- !.
bench_effort_atom(contract, none) :- !.
bench_effort_atom(extract, none) :- !.
bench_effort_atom(loop, none).

cocolog(Cocolog) :-
    current_prolog_flag(executable, Cocolog).

%% ---- the child's usage line --------------------------------------------

bench_parse_usage(Text, Usage) :-
    (   bench_usage_line(Text, Line)
    ->  bench_usage_parts(Line, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

bench_usage_line(Text, LineAtom) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    sub_atom(LineAtom, 0, 6, _, 'USAGE '),
    !.

bench_usage_parts(Line, usage(P, C, T, R, H)) :-
    split_string(Line, " ", " ", Parts),
    Parts = [_, P0, C0, T0, R0, H0],
    bench_number(P0, P),
    bench_number(C0, C),
    bench_number(T0, T),
    bench_number(R0, R),
    bench_number(H0, H).

bench_number(String, N) :-
    atom_string(A, String),
    atom_number(A, N).

%% ---- compile and run the cases -----------------------------------------

bench_verify(Task, Mode, Dir, Attempt, Verdict, Diag) :-
    bench_code_file(Task, Mode, Dir, Attempt, CodeFile),
    bench_exe_file(Task, Mode, Dir, Attempt, Exe),
    format(atom(Cmd), 'clang -std=c17 -Wall -Wextra -O0 -o ~s ~s 2>&1',
           [Exe, CodeFile]),
    bench_run_command(Cmd, 120000, CompCodes, CompExit, CompError),
    atom_codes(CompText, CompCodes),
    (   CompError \== none
    ->  Verdict = fail,
        format(atom(Diag0), 'compiler could not run: ~w', [CompError]),
        bench_limit(4000, Diag0, Diag)
    ;   CompExit == 0
    ->  bench_task(Task, _, Cases),
        bench_run_cases(Cases, Exe, Task, Mode, Dir, Attempt, 1, Failures),
        (   Failures == []
        ->  Verdict = ok,
            Diag = ''
        ;   atomic_list_concat(Failures, '\n\n', Diag0),
            Verdict = fail,
            bench_limit(4000, Diag0, Diag)
        )
    ;   Verdict = fail,
        format(atom(Diag0), 'COMPILE FAILED (exit ~w)~n~s', [CompExit, CompText]),
        bench_limit(4000, Diag0, Diag)
    ).

bench_run_cases([], _, _, _, _, _, _, []).
bench_run_cases([case(Input, Expected)|Rest], Exe, Task, Mode, Dir, Attempt, Index,
                Failures) :-
    bench_input_file(Task, Mode, Dir, Attempt, Index, InputFile),
    bench_write_text(InputFile, Input),
    format(atom(Cmd), '~s < ~s 2>&1', [Exe, InputFile]),
    bench_run_command(Cmd, 3000, OutCodes, Exit, RunError),
    atom_codes(Actual0, OutCodes),
    bench_norm(Actual0, Actual),
    bench_norm(Expected, ExpNorm),
    (   RunError == none,
        Exit == 0,
        Actual == ExpNorm
    ->  Here = []
    ;   bench_case_failure(Index, Input, Expected, Exit, Actual, RunError, Failure),
        Here = [Failure]
    ),
    Next is Index + 1,
    bench_run_cases(Rest, Exe, Task, Mode, Dir, Attempt, Next, Tail),
    append(Here, Tail, Failures).

bench_case_failure(Index, Input, Expected, Exit, Actual, RunError, Failure) :-
    (   RunError \== none
    ->  format(atom(Failure),
               'CASE ~w COULD NOT RUN~ninput: ~w~nexpected: ~w~nerror: ~w',
               [Index, Input, Expected, RunError])
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

bench_run_command(Cmd, Timeout, OutCodes, Exit, Error) :-
    catch(( proc_run(Cmd, Timeout, OutCodes0, Exit0),
            OutCodes = OutCodes0,
            Exit = Exit0,
            Error = none
          ),
          Ball,
          ( OutCodes = [],
            Exit = -1,
            bench_error_text(Ball, Error)
          )).

%% ---- small helpers -----------------------------------------------------

bench_norm(Text, Norm) :-
    split_string(Text, "\n", " \t\r", Lines0),
    exclude(bench_empty_string, Lines0, Lines),
    findall(A, (member(L, Lines), atom_string(A, L)), Atoms),
    atomic_list_concat(Atoms, '\n', Norm).

bench_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

bench_write_atom(File, Atom) :-
    atom_codes(Atom, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

bench_write_text(File, Atom) :-
    atom_codes(Atom, Codes),
    write_file_from_codes(File, Codes).

bench_limit(Max, Atom, Limited) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Limited = Atom
    ;   sub_atom(Atom, 0, Max, _, Limited)
    ).

bench_add_usage(usage(P0, C0, T0, R0, H0), usage(P, C, T, R, H),
                usage(P1, C1, T1, R1, H1)) :-
    P1 is P0 + P,
    C1 is C0 + C,
    T1 is T0 + T,
    R1 is R0 + R,
    H1 is H0 + H.

bench_error_text(Ball, Text) :-
    catch(format(atom(Text), 'error: ~w', [Ball]), _, Text = 'error').

%% ---- the report --------------------------------------------------------

bench_print_result(Task, Mode, Success, Attempts, usage(P, C, T, R, H), Seconds) :-
    (   Success == yes
    ->  Pass = pass
    ;   Pass = fail
    ),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Task, Mode, Pass, Attempts, P, C, R, T, H, Seconds]).

bench_report(Results, Tasks, Dir) :-
    format("~n===== totals =====~n", []),
    format("mode tasks passed attempts prompt completion reasoning total cache_hit seconds~n", []),
    bench_print_mode_totals(high, Results),
    bench_print_mode_totals(loop, Results),
    bench_print_mode_totals(contract, Results),
    bench_print_mode_totals(extract, Results),
    format("~n===== all modes solved =====~n", []),
    format("task high_total loop_total contract_total extract_total high_reasoning~n", []),
    forall(member(Task, Tasks), bench_print_four(Task, Results)),
    format("~n===== per solved task =====~n", []),
    format("mode solved total tokens_per_solved~n", []),
    bench_print_per_solved(high, Results),
    bench_print_per_solved(loop, Results),
    bench_print_per_solved(contract, Results),
    bench_print_per_solved(extract, Results),
    format("~nbenchmark files: ~s~n", [Dir]).

bench_print_mode_totals(Mode, Results) :-
    findall(row(P, C, T, R, H, Secs, Attempts, Succ),
            (   member(result(_, Mode0, Success, Attempts0,
                              usage(P, C, T, R, H), Secs0, _), Results),
                Mode0 == Mode,
                Attempts = Attempts0,
                Secs = Secs0,
                (   Success == yes
                ->  Succ = 1
                ;   Succ = 0
                )
            ),
            Rows),
    bench_sum_rows(Rows,
                   acc(N, Passed, AttemptsSum, PSum, CSum,
                       TSum, RSum, HSum, SecSum)),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Mode, N, Passed, AttemptsSum, PSum, CSum, RSum, TSum, HSum, SecSum]).

bench_sum_rows([], acc(0, 0, 0, 0, 0, 0, 0, 0, 0)).
bench_sum_rows([row(P, C, T, R, H, Secs, Attempts, Succ)|Rest],
               acc(N1, Passed1, Attempts1, P1, C1, T1, R1, H1, Sec1)) :-
    bench_sum_rows(Rest,
                   acc(N0, Passed0, Attempts0, P0, C0, T0, R0, H0, Sec0)),
    N1 is N0 + 1,
    Passed1 is Passed0 + Succ,
    Attempts1 is Attempts0 + Attempts,
    P1 is P0 + P,
    C1 is C0 + C,
    T1 is T0 + T,
    R1 is R0 + R,
    H1 is H0 + H,
    Sec1 is Sec0 + Secs.

bench_print_four(Task, Results) :-
    bench_find_result(Task, high, Results,
                      result(_, _, yes, _, usage(_, _, HT, _, _), _, _)),
    bench_find_result(Task, loop, Results,
                      result(_, _, yes, _, usage(_, _, LT, _, _), _, _)),
    bench_find_result(Task, contract, Results,
                      result(_, _, yes, _, usage(_, _, CT, _, _), _, _)),
    bench_find_result(Task, extract, Results,
                      result(_, _, yes, _, usage(_, _, ET, _, _), _, _)),
    bench_find_result(Task, high, Results,
                      result(_, _, yes, _, usage(_, _, _, HR, _), _, _)),
    format("~w ~w ~w ~w ~w ~w~n", [Task, HT, LT, CT, ET, HR]).

bench_find_result(Task, Mode, Results, Result) :-
    member(Result0, Results),
    Result0 = result(Task0, Mode0, _, _, _, _, _),
    Task0 == Task,
    Mode0 == Mode,
    Result = Result0.

bench_print_per_solved(Mode, Results) :-
    findall(usage(P, C, T, R, H),
            (   member(result(_, Mode0, yes, _, U, _, _), Results),
                Mode0 == Mode,
                U = usage(P, C, T, R, H)
            ),
            Usages),
    (   Usages == []
    ->  true
    ;   length(Usages, N),
        bench_sum_usage_list(Usages, usage(_, _, Total, _, _)),
        Per is Total / N,
        format("~w ~w ~w ~2f~n", [Mode, N, Total, Per])
    ).

bench_sum_usage_list([], usage(0, 0, 0, 0, 0)).
bench_sum_usage_list([U|Us], Total) :-
    bench_sum_usage_list(Us, T),
    bench_add_usage(U, T, Total).
