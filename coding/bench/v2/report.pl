%% coding/bench/v2/report.pl -- the v2 report's entry point.
%%
%%     cocolog -s coding/bench/v2/report.pl -- FILE.jsonl [options]
%%
%%     --samples N     bootstrap samples (default 2000)
%%     --seed N        bootstrap seed (default: the run's own seed)
%%
%% The table is per task and mode; the aggregate is a cluster bootstrap
%% over tasks. No model call and no network.

:- use_module('coding/bench/v2/stats.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    v2_stats_main(Args).
