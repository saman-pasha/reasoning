%% tools/logic/measure.pl -- the second measure (TRANSLATOR-PLAN.md): how
%% many sentences of lexicon/logic.txt give the Cocolog written beside them
%% (library(reasoning/logic)'s logic_measure/3).
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/logic/measure.pl [-- FILE]
%%
%% FILE is lexicon/logic.txt unless named: a sentence and its Cocolog a
%% line, apart by a tab, a line beginning # a comment. Prints the counts,
%% the reasons of the misses, the commonest first, and each miss. STATUS.md
%% records the counts of each version.

:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [F|_] -> true ; F = 'lexicon/logic.txt' ),
    typology_load(english),
    logic_measure_cases(F, Cases),
    logic_measure(english, Cases, measure(N, R, A, K, G, Ms, Uk)),
    PR is 100 * R / N, PK is 100 * K / N,
    format("the second measure: ~w sentences and their Cocolog (~w)~n", [N, F]),
    format("English into Cocolog: ~w right (~1f %), ~w more in a later reading~n", [R, PR, A]),
    format("Cocolog into English and back: ~w kept (~1f %), ~w said as a general sentence~n", [K, PK, G]),
    findall(W, ( member(miss(_, W0), Ms), measure_kind(W0, W) ), Ws),
    msort(Ws, Ws1), clumped(Ws1, Cs),
    sort(2, @>=, Cs, Cs1),
    format("why not right:~n", []),
    forall(member(W-C, Cs1), format("  ~w ~w~n", [C, W])),
    format("the misses:~n", []),
    forall(member(miss(S, W), Ms), format("  ~w  ~q~n", [S, W])),
    format("the Cocolog not kept:~n", []),
    forall(member(unkept(C, T), Uk), format("  ~w  =>  ~w~n", [C, T])).

measure_kind(got(_), got) :- !.
measure_kind(why(W), W) :- !.
measure_kind(W, W).
