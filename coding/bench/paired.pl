%% coding/bench/paired.pl -- the paired repair comparison.
%%
%%     REASONING_API_KEY=... \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         cocolog query "use_module('coding/bench/paired.pl'), run"
%%
%% Each task's first attempt is generated ONCE with the plain requirement
%% at reasoning_effort(none). If it passes, both policies end there. If it
%% fails, the same first program and diagnostic branch into:
%%
%%     pair_plain    up to two repairs with the plain requirement
%%     pair_obliged  up to two repairs with the keyword-derived obligations
%%
%% The first attempt's tokens are shared and counted in both totals, so
%% the comparison isolates the repair policy instead of first-attempt luck.

:- use_module('coding/bench/bench.pl').

:- dynamic pair_result/9.

run :-
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
    retractall(pair_result(_, _, _, _, _, _, _, _, _)),
    format("~n===== paired run =====~n", []),
    format("task first plain_total obliged_total plain_pass obliged_pass~n", []),
    forall(member(Task, Tasks), pair_task(Task, Dir)),
    findall(pair_result(Task, First, U1, PS, PA, PU, OS, OA, OU),
            pair_result(Task, First, U1, PS, PA, PU, OS, OA, OU),
            Results),
    pair_report(Results, Dir).

pair_task(Task, Dir) :-
    format("--- ~w ---~n", [Task]),
    bench_task(Task, Spec, _),
    bench_paths(Task, pair_first, Dir, 1, SpecFile, CodeFile, DiagFile),
    bench_codegen(pair_first, Spec, SpecFile, CodeFile, none, _Code, U1, E1),
    (   E1 == none
    ->  bench_verify(Task, pair_first, Dir, 1, V1, D1)
    ;   V1 = fail,
        D1 = E1
    ),
    (   V1 == ok
    ->  pair_assert(Task, yes, U1,
                    yes, 1, usage(0, 0, 0, 0, 0),
                    yes, 1, usage(0, 0, 0, 0, 0))
    ;   bench_write_atom(DiagFile, D1),
        (   exists_file(CodeFile)
        ->  Prev = prev(CodeFile, DiagFile),
            pair_branch(Task, pair_plain, Spec, Dir, Prev, PS, PA, PU),
            pair_branch(Task, pair_obliged, Spec, Dir, Prev, OS, OA, OU)
        ;   PS = no, PA = 1, PU = usage(0, 0, 0, 0, 0),
            OS = no, OA = 1, OU = usage(0, 0, 0, 0, 0)
        ),
        pair_assert(Task, no, U1, PS, PA, PU, OS, OA, OU)
    ).

pair_branch(Task, Mode, Spec, Dir, Prev, Success, Attempts, Usage) :-
    bench_attempts(2, 3, Task, Mode, Spec, Dir, usage(0, 0, 0, 0, 0), Prev,
                   Success, Attempts, Usage, _LastDiag).

pair_assert(Task, First, U1, PS, PA, PU, OS, OA, OU) :-
    assertz(pair_result(Task, First, U1, PS, PA, PU, OS, OA, OU)),
    pair_total(U1, PU, PlainTotal),
    pair_total(U1, OU, ObligedTotal),
    pair_pass(PS, PlainPass),
    pair_pass(OS, ObligedPass),
    format("~w ~w ~w ~w ~w ~w~n",
           [Task, First, PlainTotal, ObligedTotal, PlainPass, ObligedPass]).

pair_total(U1, UR, Total) :-
    bench_add_usage(U1, UR, usage(_, _, Total, _, _)).

pair_pass(yes, pass) :- !.
pair_pass(_, fail).

pair_report(Results, Dir) :-
    findall(U1, member(pair_result(_, _, U1, _, _, _, _, _, _), Results), Firsts),
    findall(PU, member(pair_result(_, _, _, _, _, PU, _, _, _), Results), Plains),
    findall(OU, member(pair_result(_, _, _, _, _, _, _, _, OU), Results), Obligeds),
    bench_sum_usage_list(Firsts, usage(_, _, FirstTotal, _, _)),
    bench_sum_usage_list(Plains, usage(_, _, PlainRepair, _, _)),
    bench_sum_usage_list(Obligeds, usage(_, _, ObligedRepair, _, _)),
    PlainTotal is FirstTotal + PlainRepair,
    ObligedTotal is FirstTotal + ObligedRepair,
    findall(_, member(pair_result(_, _, _, yes, _, _, _, _, _), Results), PlainWins),
    findall(_, member(pair_result(_, _, _, _, _, _, yes, _, _), Results), ObligedWins),
    length(Results, N),
    length(PlainWins, NP),
    length(ObligedWins, NO),
    format("~n===== paired totals =====~n", []),
    format("tasks passed first_tokens plain_repair obliged_repair plain_total obliged_total~n", []),
    format("~w ~w ~w ~w ~w ~w ~w~n",
           [N, NP, FirstTotal, PlainRepair, ObligedRepair,
            PlainTotal, ObligedTotal]),
    format("plain passed ~w; obliged passed ~w~n", [NP, NO]),
    pair_failed(Results),
    format("~nbenchmark files: ~s~n", [Dir]).

pair_failed(Results) :-
    findall(pair_result(Task, no, U1, PS, PA, PU, OS, OA, OU),
            member(pair_result(Task, no, U1, PS, PA, PU, OS, OA, OU), Results),
            Failed),
    (   Failed == []
    ->  format("~nevery first attempt passed~n", [])
    ;   format("~n===== first attempt failed =====~n", []),
        format("task first_tokens plain_repair obliged_repair plain_attempts obliged_attempts plain_pass obliged_pass~n", []),
        forall(member(pair_result(Task, no, U1, PS, PA, PU, OS, OA, OU), Failed),
               (   U1 = usage(_, _, FT, _, _),
                   PU = usage(_, _, PR, _, _),
                   OU = usage(_, _, OR, _, _),
                   pair_pass(PS, PPass),
                   pair_pass(OS, OPass),
                   format("~w ~w ~w ~w ~w ~w ~w ~w~n",
                          [Task, FT, PR, OR, PA, OA, PPass, OPass])
               ))
    ).
