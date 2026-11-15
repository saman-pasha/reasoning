%% coding/c/run.pl -- the C generator's command-line entry.
%%
%%     cocolog -s coding/c/run.pl -- SPEC.txt [flags] [OUT.c]
%%
%% `codegen.pl' defines the predicates and `c_cli/0'; this file owns
%% `main/0', so the C, cocolog and Python generator modules can be loaded
%% in one process without any of them claiming the same entry.

:- use_module('coding/c/codegen.pl').

main :-
    c_cli.
