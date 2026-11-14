%% coding/cocolog/bench/bench.pl -- the cocolog codegen benchmark.
%%
%%     REASONING_API_KEY=... coding/cocolog/bench/run.sh [-- task ...]
%%
%% Two modes per task:
%%
%%     high      one call at reasoning_effort(high), with SKILL.md
%%     checked   up to three calls at none; each repair carries the output
%%               mismatch from the expected file
%%     no_skill  the high control with the guide omitted
%%
%% Every task's main/0 prints all its results in one run, and the codegen's
%% own --expect check compares them with the task's expected file. The
%% numbers are the provider's usage, from codegen_report/1.

:- use_module(library(process)).
:- use_module('coding/cocolog/bench/tasks.pl').

:- dynamic bench_result/10.

main :-
    (   getenv('REASONING_API_KEY', Key),
        Key \== ''
    ->  true
    ;   format("REASONING_API_KEY is not set.~n", []),
        halt(1)
    ),
    bench_selected_tasks(Tasks),
    (   Tasks == []
    ->  format("no cocolog benchmark task named.~n", []),
        halt(1)
    ;   true
    ),
    tmp_file(cocolog_bench, Dir),
    make_directory(Dir),
    format("benchmark directory: ~s~n~n", [Dir]),
    retractall(bench_result(_, _, _, _, _, _, _, _, _, _)),
    format("task mode pass calls prompt completion reasoning total cache seconds~n", []),
    forall(member(Task, Tasks), bench_task_modes(Task, Dir)),
    bench_report(Tasks).

bench_selected_tasks(Tasks) :-
    current_prolog_flag(argv, [_|Args]),
    (   Args == []
    ->  findall(Task, bench_task(Task, _, _), Tasks)
    ;   findall(Task, (member(Task, Args), bench_task(Task, _, _)), Tasks)
    ).

bench_task_modes(Task, Dir) :-
    forall(member(Mode, [high, checked, no_skill]), bench_run(Task, Mode, Dir)).

bench_run(Task, Mode, Dir) :-
    bench_task(Task, Spec, Expected),
    format(atom(SpecFile), '~s/~w.spec.txt', [Dir, Task]),
    write_text(SpecFile, Spec),
    format(atom(OutFile), '~s/~w_~w.pl', [Dir, Task, Mode]),
    current_prolog_flag(executable, Exe),
    format(atom(Cmd),
           '"~s" query "use_module(''coding/cocolog/bench/gen.pl''), run" -- "~s" "~s" "~s" ~w 2>&1',
           [Exe, SpecFile, Expected, OutFile, Mode]),
    catch(proc_run(Cmd, 600000, Codes, _Exit), _,
          ( Codes = [] )),
    atom_codes(Text, Codes),
    (   bench_field(Text, 'RESULT ', Result)
    ->  true
    ;   Result = fail
    ),
    (   Result == pass
    ->  Pass = pass
    ;   Pass = fail
    ),
    (   bench_field(Text, 'USAGE ', UsageText)
    ->  true
    ;   UsageText = '0 0 0 0 0 0 0'
    ),
    bench_usage(UsageText, Prompt, Completion, Reasoning, Cache, Total, Seconds,
                Calls),
    (   bench_field(Text, 'ERROR ', Error)
    ->  true
    ;   Error = none
    ),
    assertz(bench_result(Task, Mode, Pass, Calls, Prompt, Completion, Reasoning,
                         Total, Cache, Seconds)),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Task, Mode, Pass, Calls, Prompt, Completion, Reasoning, Total,
            Cache, Seconds]),
    (   Pass == fail
    ->  ( Error == none -> true ; format("  ERROR ~s~n", [Error]) )
    ;   true
    ).

bench_field(Text, Prefix, Value) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    atom_concat(Prefix, Value, LineAtom),
    !.

bench_usage(Text, Prompt, Completion, Reasoning, Cache, Total, Seconds, Calls) :-
    split_string(Text, " ", " \t\r", Parts),
    Parts = [Prompt0, Completion0, Total0, Reasoning0, Cache0, Seconds0, Calls0],
    atom_number(Prompt0, Prompt),
    atom_number(Completion0, Completion),
    atom_number(Total0, Total),
    atom_number(Reasoning0, Reasoning),
    atom_number(Cache0, Cache),
    atom_number(Seconds0, Seconds),
    atom_number(Calls0, Calls),
    !.
bench_usage(_, 0, 0, 0, 0, 0, 0.0, 0).

write_text(File, Text) :-
    atom_codes(Text, Codes),
    write_file_from_codes(File, Codes).

bench_report(_Tasks) :-
    mode_total(high),
    mode_total(checked),
    mode_total(no_skill),
    overall.

mode_total(Mode) :-
    findall(row(Calls, P, C, R, T, H, S, Pass),
            bench_result(_, Mode, Pass, Calls, P, C, R, T, H, S),
            Rows),
    sum_rows(Rows, acc(0, 0, 0, 0, 0, 0, 0, 0, 0.0),
             acc(N, Passed, Calls, P, C, R, T, H, S)),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Mode, N, Passed, Calls, P, C, R, T, H, S]).

overall :-
    findall(row(Calls, P, C, R, T, H, S, Pass),
            bench_result(_, _, Pass, Calls, P, C, R, T, H, S),
            Rows),
    sum_rows(Rows, acc(0, 0, 0, 0, 0, 0, 0, 0, 0.0),
             acc(N, Passed, Calls, P, C, R, T, H, S)),
    format("overall ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [N, Passed, Calls, P, C, R, T, H, S]).

sum_rows([], Acc, Acc).
sum_rows([row(Calls0, P0, C0, R0, T0, H0, S0, Pass)|Rows],
         acc(N0, Passed0, CallsA, PA, CA, RA, TA, HA, SA),
         Acc) :-
    N1 is N0 + 1,
    (   Pass == pass -> Passed1 is Passed0 + 1 ; Passed1 = Passed0 ),
    Calls1 is CallsA + Calls0,
    P1 is PA + P0,
    C1 is CA + C0,
    R1 is RA + R0,
    T1 is TA + T0,
    H1 is HA + H0,
    S1 is SA + S0,
    sum_rows(Rows, acc(N1, Passed1, Calls1, P1, C1, R1, T1, H1, S1), Acc).
