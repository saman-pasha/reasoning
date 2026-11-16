%% coding/bench/v2/run.pl -- the v2 runner's entry point.
%%
%%     cocolog -s coding/bench/v2/run.pl -- --plan
%%     cocolog -s coding/bench/v2/run.pl -- --run --trials 3
%%
%% The runner keeps no main/0 of its own, so the test can load it without
%% starting a run.

:- use_module('coding/bench/v2/runner.pl').

main :-
    v2_cli_main.
