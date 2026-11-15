%% coding/cocolog/run.pl -- the cocolog generator's command-line entry.
%%
%% The generator itself keeps no main/0, so the C and cocolog generators can
%% be loaded in one process without merging their CLI clauses.

:- use_module('coding/cocolog/codegen.pl').

main :-
    cocolog_cli.
