%% tools/typology/coverage.pl -- how much of a text the English template
%% reads (library(reasoning/typology)'s typology_coverage/4).
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/typology/coverage.pl [-- LANGUAGE [FILE]]
%%
%% LANGUAGE is english unless named, FILE lexicon/prose.txt (WordNet's
%% 8 000 example sentences, one a line) unless named. Prints the count of
%% the sentences read into an IR, and the 40 words no table has that are
%% the commonest. STATUS.md records the count of each version.

:- use_module(library(reasoning/typology)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [L0|More] -> atom_string(L, L0) ; L = english, More = [] ),
    ( More = [F|_] -> true ; F = 'lexicon/prose.txt' ),
    typology_load(L),
    read_file_to_codes(F, Codes), atom_codes(Text, Codes),
    atomic_list_concat(Lines0, '\n', Text),
    exclude(==(''), Lines0, Lines),
    length(Lines, N),
    typology_coverage(L, Lines, Read, Unknown),
    length(Read, K), length(Unknown, U),
    P is 100 * K / N,
    format("~w: ~w of ~w sentences read (~2f %)~n", [L, K, N, P]),
    format("~w words no table has; the commonest:~n", [U]),
    forall(( nth1(I, Unknown, W-C), I =< 40 ), format("  ~w ~w~n", [W, C])).
