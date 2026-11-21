%% tools/typology/import.pl -- write the word tables of the templates from
%% corpus/vocabulary (library(reasoning/typology)'s typology_import/1).
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/typology/import.pl
%%
%% Spanish and Italian first, then English, whose rows are the meanings of
%% both vocabularies. Writes templates/spanish-words.pl,
%% templates/italian-words.pl and templates/english-words.pl.

:- use_module(library(reasoning/typology)).

main :-
    forall(member(L, [spanish, italian, english]), typology_import(L)).
