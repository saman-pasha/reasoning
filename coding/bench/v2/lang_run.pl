%% coding/bench/v2/lang_run.pl -- Phase 4 language comparison entry.
%%
%%     cocolog -s coding/bench/v2/lang_run.pl -- --plan
%%     cocolog -s coding/bench/v2/lang_run.pl -- --run

:- use_module('coding/bench/v2/lang_runner.pl').

main :-
    v2_lang_cli_main.
