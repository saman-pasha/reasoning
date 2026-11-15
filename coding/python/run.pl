%% coding/python/run.pl -- the Python generator's command line.
%%
%%     cocolog -s coding/python/run.pl -- SPEC.txt [flags] [OUT.py]
%%
%% `codegen.pl' defines the predicates and `python_cli/0'; this file owns
%% `main/0', so the C, cocolog and Python generators can be loaded in one
%% process without two of them claiming the same entry.

:- use_module('coding/python/codegen.pl').

main :-
    python_cli.
