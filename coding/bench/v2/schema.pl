%% coding/bench/v2/schema.pl -- the v2 task declaration.
%%
%% A v2 task carries the legacy requirement and cases, split into cases a
%% repair attempt may be told about and held-out cases never shown in a
%% prompt or a diagnostic. The prompt contains no cases; the repair loop
%% reveals only the failing repair cases.

:- use_module('coding/bench/tasks.pl').

v2_task_name(lcs).
v2_task_name(stable_sort).
v2_task_name(mvccs_acid).

v2_task(Task, c, Spec, Repair, Heldout, Policy,
        budget(MaxCalls, TimeoutMs, MaxTokens)) :-
    v2_task_name(Task),
    bench_task(Task, Spec, Cases0),
    v2_cases(Task, Cases0, Cases),
    v2_split_cases(Task, Cases, Repair, Heldout),
    v2_output_policy(Task, Policy),
    v2_budget(Task, budget(MaxCalls, TimeoutMs, MaxTokens)).

%% The legacy stable_sort case 1 says `5' and gives four records. That is
%% a defective case, not a property of the task: a program that reads the
%% stated five lines reads a fifth that is not there. v2 corrects the
%% count in its own copy and leaves the legacy file untouched, so the old
%% numbers stay reproducible.
v2_cases(stable_sort, Cases0, Cases) :-
    !,
    v2_fix_stable_sort_case(Cases0, Cases).
v2_cases(_, Cases, Cases).

v2_fix_stable_sort_case(
    [case('5\nbob 10\nalice 10\ncarol 5\ndave 20\n', Expected)|Rest],
    [case('4\nbob 10\nalice 10\ncarol 5\ndave 20\n', Expected)|Rest]) :-
    !.
v2_fix_stable_sort_case(Cases, Cases).

v2_output_policy(lcs, exact).
v2_output_policy(stable_sort, exact).
v2_output_policy(mvccs_acid, exact).

v2_budget(lcs, budget(3, 3000, 0)).
v2_budget(stable_sort, budget(3, 3000, 0)).
v2_budget(mvccs_acid, budget(3, 5000, 0)).

%% One-based indices into the legacy case list. The held-out cases are
%% chosen for the narrow reading each task exists to catch, not as a tail:
%% the greedy-killer and empty LCS, the tie-heavy stable sorts, and the
%% error and last-committer-wins MVCC cases.
v2_heldout_indices(lcs, [4, 6]).
v2_heldout_indices(stable_sort, [5, 7]).
v2_heldout_indices(mvccs_acid, [8, 9]).

v2_split_cases(Task, Cases, Repair, Heldout) :-
    v2_heldout_indices(Task, Indices),
    v2_split_cases(Cases, 1, Indices, Repair, Heldout).

v2_split_cases([], _, _, [], []).
v2_split_cases([Case|Cases], Index, Indices, Repair, Heldout) :-
    (   memberchk(Index, Indices)
    ->  Repair = RestRepair,
        Heldout = [Case|RestHeldout]
    ;   Repair = [Case|RestRepair],
        Heldout = RestHeldout
    ),
    Next is Index + 1,
    v2_split_cases(Cases, Next, Indices, RestRepair, RestHeldout).

%% Validation used by the test and the runner.
v2_task_check :-
    forall(v2_task_name(Task),
           (   v2_task(Task, c, _, Repair, Heldout, _, _),
               Repair \== [],
               Heldout \== []
           )).

v2_task_language(Task, Lang) :-
    v2_task(Task, Lang, _, _, _, _, _).
