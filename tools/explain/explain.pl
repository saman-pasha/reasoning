%% tools/explain/explain.pl -- a Cocolog program said in English
%% (library(reasoning/explain), since 1.80.0): each clause, its source and
%% its English, then the measure.
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/explain/explain.pl -- FILE [OUT]
%%
%% OUT, where named, takes the clauses and their English; the counts go to
%% the standard output: the clauses, those the translator says as English
%% that reads back, those whose every goal is explained or the text's own,
%% and the names with no row, the commonest first.

:- use_module(library(reasoning/explain)).

main :-
    current_prolog_flag(argv, [_, F|Rest]),
    explain_file(english, F, Es),
    (   Rest = [Out|_]
    ->  open(Out, write, O),
        forall(member(explained(C, E, _), Es), format(O, "~w~n=> ~w~n~n", [C, E])),
        close(O)
    ;   forall(member(explained(C, E, _), Es), format("~w~n=> ~w~n~n", [C, E]))
    ),
    explain_measure(english, F, measure(N, ByLogic, Full, Us)),
    format("~w clauses (~w)~n", [N, F]),
    format("  said by the translator, as English that reads back: ~w~n", [ByLogic]),
    format("  every goal explained or the text's own: ~w~n", [Full]),
    format("names with no row, said as terms:~n"),
    forall(member(PI-C, Us), format("  ~w ~q~n", [C, PI])).
