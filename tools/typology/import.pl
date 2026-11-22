%% tools/typology/import.pl -- write the word tables of the templates from
%% corpus/vocabulary (library(reasoning/typology)'s typology_import/1).
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/typology/import.pl
%%
%% Spanish and Italian first, then English, whose rows are the meanings of
%% both vocabularies, then the topics their class lines give. Writes
%% templates/spanish-words.pl, templates/italian-words.pl,
%% templates/english-words.pl and templates/topics-words.pl.

:- use_module(library(reasoning/typology)).

main :-
    forall(member(L, [spanish, italian, english, topics]), typology_import(L)).
