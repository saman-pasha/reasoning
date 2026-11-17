%% coding/bench/v2/stats.pl -- read a v2 JSONL run and estimate rates.
%%
%% The per-task table is always printed. The aggregate is a cluster
%% bootstrap over TASKS, not cells: trials of one task are not independent
%% samples of the task population, and a three-task pilot's interval is
%% wide by construction. No aggregate is printed without the table.
%%
%%     v2_stats_read_run(+File, -Header, -Cells)
%%     v2_stats_summary(+Cells, -stats(N, Pass1, Final, MeanAttempts,
%%                                     Tokens, MeanSeconds))
%%     v2_stats_bootstrap_rate(+Cells, +Key, +Samples, +Seed,
%%                             -point(Rate), -ci(Lo, Hi))
%%     v2_stats_paired_diffs(+Cells, +ModeA, +ModeB, -Diffs)
%%     v2_stats_bootstrap_diff(+Diffs, +Key, +Samples, +Seed,
%%                             -point(Diff), -ci(Lo, Hi))
%%     v2_stats_report(+File, +Samples, +SeedOrDefault)
%%
%% Key is `pass1` or `final`. A cell is
%% cell(Task, Mode, Trial, Pass1, Final, Attempts, Usage, Seconds,
%%      Outcome, Repair, Heldout).

:- use_module(library(json)).
:- use_module(library(os)).

%% ---- reading -----------------------------------------------------------

v2_stats_read_run(File, Header, Cells) :-
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    split_string(Text, "\n", " \t\r", Lines0),
    exclude(v2_stats_empty_string, Lines0, Lines),
    Lines \== [],
    maplist(v2_stats_line, Lines, Terms),
    Terms = [Header|Rows],
    Header = json(HeaderPairs),
    memberchk(type-header, HeaderPairs),
    findall(Cell, (member(Row, Rows), v2_stats_cell(Row, Cell)), Cells),
    length(Rows, NRows),
    length(Cells, NCells),
    NRows =:= NCells.

v2_stats_line(Line, Term) :-
    atom_string(Atom, Line),
    json_parse(Atom, Term).

v2_stats_cell(json(Pairs),
              cell(Task, Mode, Trial, Pass1, Final, Attempts,
                   usage(P, C, T, R, H), Seconds, Outcome, Repair, Heldout)) :-
    memberchk(type-cell, Pairs),
    v2_stats_get(task, Pairs, Task),
    v2_stats_get(mode, Pairs, Mode),
    v2_stats_get(trial, Pairs, Trial),
    v2_stats_get(pass_at_1, Pairs, Pass1Json),
    v2_stats_bool(Pass1Json, Pass1),
    v2_stats_get(final_pass, Pairs, FinalJson),
    v2_stats_bool(FinalJson, Final),
    v2_stats_get(attempts, Pairs, Attempts),
    v2_stats_get(usage, Pairs, UsageJson),
    UsageJson = json(UsagePairs),
    v2_stats_get(prompt, UsagePairs, P),
    v2_stats_get(completion, UsagePairs, C),
    v2_stats_get(total, UsagePairs, T),
    v2_stats_get(reasoning, UsagePairs, R),
    v2_stats_get(cache_hit, UsagePairs, H),
    v2_stats_get(seconds, Pairs, Seconds),
    v2_stats_get(outcome, Pairs, Outcome),
    v2_stats_get(repair, Pairs, Repair),
    v2_stats_get(heldout, Pairs, Heldout).

v2_stats_bool('@'(true), yes) :- !.
v2_stats_bool('@'(false), no) :- !.
v2_stats_bool(V, V).

v2_stats_get(Key, Pairs, Value) :-
    memberchk(Key-Value, Pairs),
    !.
v2_stats_get(Key, _, _) :-
    throw(error(missing_json_key(Key), v2_stats_get/3)).

v2_stats_header(Header, Key, Value) :-
    Header = json(Pairs),
    v2_stats_get(Key, Pairs, Value).

v2_stats_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

%% ---- summaries ---------------------------------------------------------

v2_stats_summary(Cells, stats(N, Pass1, Final, MeanAttempts, Tokens,
                              MeanSeconds)) :-
    length(Cells, N),
    N > 0,
    findall(P, member(cell(_, _, _, P, _, _, _, _, _, _, _), Cells), Ps),
    v2_stats_yes(Ps, Pass1),
    findall(F, member(cell(_, _, _, _, F, _, _, _, _, _, _), Cells), Fs),
    v2_stats_yes(Fs, Final),
    findall(A, member(cell(_, _, _, _, _, A, _, _, _, _, _), Cells), As),
    v2_stats_sum(As, 0, AttemptsSum),
    findall(T,
            member(cell(_, _, _, _, _, _, usage(_, _, T, _, _), _, _, _, _),
                   Cells),
            Ts),
    v2_stats_sum(Ts, 0, Tokens),
    findall(S, member(cell(_, _, _, _, _, _, _, S, _, _, _), Cells), Ss),
    v2_stats_sum(Ss, 0.0, SecondsSum),
    MeanAttempts is AttemptsSum / N,
    MeanSeconds is SecondsSum / N.

v2_stats_yes(Values, Count) :-
    findall(x, (member(V, Values), V == yes), Yes),
    length(Yes, Count).

v2_stats_sum([], Acc, Acc).
v2_stats_sum([X|Xs], Acc0, Acc) :-
    Acc1 is Acc0 + X,
    v2_stats_sum(Xs, Acc1, Acc).

v2_stats_rate(Key, Cells, Rate) :-
    findall(Y, (member(Cell, Cells), v2_stats_key(Cell, Key, Y)), Ys),
    length(Ys, N),
    N > 0,
    v2_stats_yes(Ys, Yes),
    Rate is Yes / N.

v2_stats_key(cell(_, _, _, P, _, _, _, _, _, _, _), pass1, P).
v2_stats_key(cell(_, _, _, _, F, _, _, _, _, _, _), final, F).

v2_stats_tasks(Cells, Tasks) :-
    findall(T, member(cell(T, _, _, _, _, _, _, _, _, _, _), Cells), Ts0),
    sort(Ts0, Tasks).

v2_stats_modes(Cells, Modes) :-
    findall(M, member(cell(_, M, _, _, _, _, _, _, _, _, _), Cells), Ms0),
    v2_stats_unique(Ms0, Modes0),
    v2_stats_preferred_modes(Modes0, Modes).

v2_stats_unique([], []).
v2_stats_unique([X|Xs], [X|Ys]) :-
    \+ memberchk(X, Xs),
    v2_stats_unique(Xs, Ys).
v2_stats_unique([X|Xs], Ys) :-
    memberchk(X, Xs),
    v2_stats_unique(Xs, Ys).

v2_stats_preferred_modes(Modes, Ordered) :-
    findall(M,
            (   member(M, [plain, derive, contract, extract, full]),
                memberchk(M, Modes)
            ),
            First),
    findall(M,
            (   member(M, Modes),
                \+ memberchk(M, [plain, derive, contract, extract, full])
            ),
            Rest),
    append(First, Rest, Ordered).

%% ---- cluster bootstrap over tasks -------------------------------------

v2_stats_bootstrap_rate(Cells, Key, Samples, Seed,
                        point(Point), ci(Lo, Hi)) :-
    v2_stats_rate(Key, Cells, Point),
    v2_stats_tasks(Cells, Tasks),
    Tasks \== [],
    v2_stats_bootstrap_rates(Samples, Cells, Tasks, Key, Seed, _,
                             Rates),
    Rates \== [],
    msort(Rates, Sorted),
    v2_stats_percentile(Sorted, 0.025, Lo),
    v2_stats_percentile(Sorted, 0.975, Hi).

v2_stats_bootstrap_rates(0, _, _, _, Seed, Seed, []) :-
    !.
v2_stats_bootstrap_rates(K, Cells, Tasks, Key, Seed0, Seed,
                         [Rate|Rates]) :-
    K > 0,
    length(Tasks, N),
    v2_stats_draw(N, Tasks, Seed0, Drawn, Seed1),
    findall(Cell,
            (   member(Task, Drawn),
                member(Cell, Cells),
                Cell = cell(Task, _, _, _, _, _, _, _, _, _, _)
            ),
            Sample),
    v2_stats_rate(Key, Sample, Rate),
    K1 is K - 1,
    v2_stats_bootstrap_rates(K1, Cells, Tasks, Key, Seed1, Seed, Rates).

%% ---- paired difference between two modes -------------------------------

v2_stats_paired_diffs(Cells, ModeA, ModeB, Diffs) :-
    v2_stats_tasks(Cells, Tasks),
    findall(diff(Task, Pass1Diff, FinalDiff),
            (   member(Task, Tasks),
                v2_stats_task_mode_cells(Cells, Task, ModeA, CA),
                v2_stats_task_mode_cells(Cells, Task, ModeB, CB),
                v2_stats_rate(pass1, CA, RateA1),
                v2_stats_rate(pass1, CB, RateB1),
                Pass1Diff is RateB1 - RateA1,
                v2_stats_rate(final, CA, RateA2),
                v2_stats_rate(final, CB, RateB2),
                FinalDiff is RateB2 - RateA2
            ),
            Diffs).

v2_stats_task_mode_cells(Cells, Task, Mode, ModeCells) :-
    findall(Cell,
            (   member(Cell, Cells),
                Cell = cell(Task, Mode, _, _, _, _, _, _, _, _, _)
            ),
            ModeCells),
    ModeCells \== [].

v2_stats_bootstrap_diff(Diffs, Key, Samples, Seed,
                        point(Point), ci(Lo, Hi)) :-
    v2_stats_diff_values(Diffs, Key, Values),
    Values \== [],
    v2_stats_mean(Values, Point),
    v2_stats_bootstrap_means(Samples, Diffs, Key, Seed, _,
                             Means),
    Means \== [],
    msort(Means, Sorted),
    v2_stats_percentile(Sorted, 0.025, Lo),
    v2_stats_percentile(Sorted, 0.975, Hi).

v2_stats_bootstrap_means(0, _, _, Seed, Seed, []) :-
    !.
v2_stats_bootstrap_means(K, Diffs, Key, Seed0, Seed, [Mean|Means]) :-
    K > 0,
    length(Diffs, N),
    v2_stats_draw(N, Diffs, Seed0, Drawn, Seed1),
    v2_stats_diff_values(Drawn, Key, Values),
    v2_stats_mean(Values, Mean),
    K1 is K - 1,
    v2_stats_bootstrap_means(K1, Diffs, Key, Seed1, Seed, Means).

v2_stats_diff_values([], _, []).
v2_stats_diff_values([diff(_, P1, _)|Ds], pass1, [P1|Vs]) :-
    !,
    v2_stats_diff_values(Ds, pass1, Vs).
v2_stats_diff_values([diff(_, _, F)|Ds], final, [F|Vs]) :-
    !,
    v2_stats_diff_values(Ds, final, Vs).

v2_stats_mean(Values, Mean) :-
    Values \== [],
    length(Values, N),
    v2_stats_sum(Values, 0.0, Sum),
    Mean is Sum / N.

v2_stats_percentile(Sorted, P, Value) :-
    length(Sorted, N),
    N > 0,
    Index is 1 + floor(P * (N - 1)),
    nth1(Index, Sorted, Value).

%% ---- deterministic draws ----------------------------------------------

v2_stats_draw(0, _, Seed, [], Seed).
v2_stats_draw(K, Items, Seed0, [Item|ItemsOut], Seed) :-
    K > 0,
    length(Items, N),
    N > 0,
    v2_stats_rand(Seed0, Seed1),
    Index is Seed1 mod N,
    nth0(Index, Items, Item),
    K1 is K - 1,
    v2_stats_draw(K1, Items, Seed1, ItemsOut, Seed).

v2_stats_rand(S0, S) :-
    S is (S0 * 1103515245 + 12345) mod 2147483648.

%% ---- report ------------------------------------------------------------

v2_stats_report(File, Samples, Seed0) :-
    v2_stats_read_run(File, Header, Cells),
    v2_stats_effective_seed(Seed0, Header, Seed),
    v2_stats_header(Header, run_id, RunId),
    v2_stats_header(Header, commit, Commit),
    v2_stats_header(Header, model, Model),
    v2_stats_header(Header, trials, Trials),
    v2_stats_modes(Cells, Modes),
    v2_stats_tasks(Cells, Tasks),
    length(Tasks, NTasks),
    length(Modes, NModes),
    length(Cells, NCells),
    format("v2 report ~w~n", [File]),
    format("run ~w, commit ~w, model ~w, trials ~w~n",
           [RunId, Commit, Model, Trials]),
    format("~w task(s), ~w mode(s), ~w cell(s), bootstrap ~w samples, seed ~w~n~n",
           [NTasks, NModes, NCells, Samples, Seed]),
    format("task mode trials pass@1 final attempts tokens seconds~n", []),
    forall(member(Task, Tasks),
           forall(member(Mode, Modes),
                  v2_stats_task_row(Cells, Task, Mode))),
    format("~naggregate (cluster bootstrap over tasks)~n", []),
    forall(member(Mode, Modes),
           v2_stats_mode_block(Cells, Mode, Samples, Seed)),
    v2_stats_pair_block(Cells, Modes, Samples, Seed).

v2_stats_effective_seed(default, Header, Seed) :-
    !,
    (   catch(v2_stats_header(Header, seed, HeaderSeed), _, fail)
    ->  Seed = HeaderSeed
    ;   Seed = 20261117
    ).
v2_stats_effective_seed(Seed, _, Seed).

v2_stats_task_row(Cells, Task, Mode) :-
    v2_stats_task_mode_cells(Cells, Task, Mode, ModeCells),
    !,
    v2_stats_summary(ModeCells,
                     stats(N, Pass1, Final, MeanAttempts, Tokens,
                           MeanSeconds)),
    format("~w ~w ~w ~w/~w ~w/~w ~2f ~w ~1f~n",
           [Task, Mode, N, Pass1, N, Final, N, MeanAttempts, Tokens,
            MeanSeconds]).
v2_stats_task_row(_, _, _).

v2_stats_mode_block(Cells, Mode, Samples, Seed) :-
    v2_stats_task_mode_cells_any(Cells, Mode, ModeCells),
    v2_stats_summary(ModeCells,
                     stats(N, Pass1, Final, MeanAttempts, Tokens,
                           MeanSeconds)),
    v2_stats_bootstrap_rate(ModeCells, pass1, Samples, Seed,
                            point(Rate1), ci(Lo1, Hi1)),
    v2_stats_bootstrap_rate(ModeCells, final, Samples, Seed,
                            point(Rate2), ci(Lo2, Hi2)),
    P1 is 100 * Rate1,
    P1Lo is 100 * Lo1,
    P1Hi is 100 * Hi1,
    P2 is 100 * Rate2,
    P2Lo is 100 * Lo2,
    P2Hi is 100 * Hi2,
    format("~w: ~w cells, pass@1 ~w/~w ~1f% [~1f, ~1f], final ~w/~w ~1f% [~1f, ~1f], attempts ~2f, ~w tokens, ~1f s~n",
           [Mode, N, Pass1, N, P1, P1Lo, P1Hi, Final, N, P2, P2Lo, P2Hi,
            MeanAttempts, Tokens, MeanSeconds]).

v2_stats_task_mode_cells_any(Cells, Mode, ModeCells) :-
    findall(Cell,
            (   member(Cell, Cells),
                Cell = cell(_, Mode, _, _, _, _, _, _, _, _, _)
            ),
            ModeCells),
    ModeCells \== [].

v2_stats_pair_block(Cells, Modes, Samples, Seed) :-
    v2_stats_pairs(Modes, Pairs),
    (   Pairs == []
    ->  format("~nno pair of modes to compare~n", [])
    ;   forall(member(ModeA-ModeB, Pairs),
               v2_stats_one_pair(Cells, ModeA, ModeB, Samples, Seed))
    ).

v2_stats_pairs(Modes, Pairs) :-
    findall(ModeA-ModeB,
            (   member(ModeA-ModeB,
                       [plain-derive,
                        derive-extract,
                        extract-contract,
                        contract-full]),
                memberchk(ModeA, Modes),
                memberchk(ModeB, Modes)
            ),
            Pairs).

v2_stats_one_pair(Cells, ModeA, ModeB, Samples, Seed) :-
    v2_stats_paired_diffs(Cells, ModeA, ModeB, Diffs),
    Diffs \== [],
    length(Diffs, NTasks),
    v2_stats_bootstrap_diff(Diffs, pass1, Samples, Seed,
                            point(P1), ci(P1Lo, P1Hi)),
    v2_stats_bootstrap_diff(Diffs, final, Samples, Seed,
                            point(P2), ci(P2Lo, P2Hi)),
    S1 is 100 * P1,
    S1Lo is 100 * P1Lo,
    S1Hi is 100 * P1Hi,
    S2 is 100 * P2,
    S2Lo is 100 * P2Lo,
    S2Hi is 100 * P2Hi,
    v2_stats_signed(S1, T1),
    v2_stats_signed(S1Lo, T1Lo),
    v2_stats_signed(S1Hi, T1Hi),
    v2_stats_signed(S2, T2),
    v2_stats_signed(S2Lo, T2Lo),
    v2_stats_signed(S2Hi, T2Hi),
    format("~npaired ~w minus ~w (~w task(s))~n",
           [ModeB, ModeA, NTasks]),
    format("pass@1 ~w pp [~w, ~w]~n", [T1, T1Lo, T1Hi]),
    format("final  ~w pp [~w, ~w]~n", [T2, T2Lo, T2Hi]).

v2_stats_signed(Value, Text) :-
    (   Value >= 0
    ->  format(atom(Text), '+~1f', [Value])
    ;   format(atom(Text), '~1f', [Value])
    ).

%% ---- command line ------------------------------------------------------

v2_stats_main(Args) :-
    (   v2_stats_args(Args, File, Samples, Seed)
    ->  true
    ;   v2_stats_usage,
        halt(2)
    ),
    (   catch(v2_stats_report(File, Samples, Seed), Ball,
              ( v2_stats_error_text(Ball, Text),
                format("v2 report error: ~w~n", [Text]),
                halt(1)
              ))
    ->  true
    ;   halt(1)
    ).

v2_stats_args([File|Rest], File, Samples, Seed) :-
    v2_stats_opts(Rest, 2000, default, Samples, Seed).

v2_stats_opts([], Samples, Seed, Samples, Seed).
v2_stats_opts(['--samples', Value|Rest], _, Seed, Samples, SeedOut) :-
    atom_number(Value, N),
    integer(N),
    N > 0,
    v2_stats_opts(Rest, N, Seed, Samples, SeedOut).
v2_stats_opts(['--seed', Value|Rest], Samples, _, Samples, SeedOut) :-
    atom_number(Value, N),
    integer(N),
    v2_stats_opts(Rest, Samples, N, Samples, SeedOut).

v2_stats_usage :-
    format("usage: cocolog -s coding/bench/v2/report.pl -- FILE.jsonl [--samples N] [--seed N]~n", []).

v2_stats_error_text(Ball, Text) :-
    (   Ball = error(Formal, _)
    ->  format(atom(Text), '~w', [Formal])
    ;   format(atom(Text), '~w', [Ball])
    ).
