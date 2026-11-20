%% coding/bench/v2/config.pl -- v2 provider, trials and budgets.
%%
%% The parent runner and the child generator both load this file, so a
%% change here moves both. These are the benchmark's own facts, not
%% coding/options.pl's defaults.

v2_config(provider, openai).
v2_config(model, 'deepseek-flash').
v2_config(base_url, 'https://api.deepseek.com/v1/chat/completions').
v2_config(temperature, 0).

v2_config(high_effort, high).
v2_config(loop_effort, none).

%% A pilot is three trials per task and mode. Increase only after the
%% pilot's variance and cost are known; the runner takes --trials N.
v2_config(trials, 3).
v2_config(seed, 20261117).

v2_config(modes, [once, plain, derive, contract, extract, full]).

v2_config(max_diagnostic, 4000).
v2_config(child_timeout_ms, 600000).

v2_config(results_dir, 'coding/bench/v2/results').

%% ---- a run's own provider -------------------------------------------------
%%
%% v2_setting(Key, Value) is the value a run uses: the environment's when
%% it names one, else the facts above. So a run can go to another provider
%% without a change to this file, and the facts stay the pilots' record.
%%
%%     CODING_BENCH_PROVIDER    provider: openai or anthropic
%%     CODING_BENCH_MODEL       model
%%     CODING_BENCH_BASE_URL    the complete URL
%%     CODING_BENCH_EFFORT      the generator's effort level
%%     CODING_BENCH_MAX_TOKENS  a reply's limit, thinking included
%%
%% ANTHROPIC'S CURRENT MODELS TAKE NO TEMPERATURE AND NO EFFORT `none'.
%% claude-sonnet-5-5 refuses a temperature other than its default (HTTP
%% 400, "`temperature` is deprecated for this model."), thinks by default,
%% and counts the thinking against max_tokens, so an anthropic run sends no
%% temperature, effort `low' unless CODING_BENCH_EFFORT names another
%% level, and a limit of 16000 tokens: library(llm)'s own 4096 is below
%% what the pilot's mvccs_acid attempts spent before any thinking.
v2_setting(provider, P) :-
    v2_setting_env('CODING_BENCH_PROVIDER', provider, P).
v2_setting(model, M) :-
    v2_setting_env('CODING_BENCH_MODEL', model, M).
v2_setting(base_url, U) :-
    v2_setting_env('CODING_BENCH_BASE_URL', base_url, U).
v2_setting(temperature, T) :-
    (   v2_setting(provider, anthropic)
    ->  T = none
    ;   v2_config(temperature, T)
    ).
v2_setting(effort, E) :-
    (   getenv('CODING_BENCH_EFFORT', E0), E0 \== ''
    ->  E = E0
    ;   v2_setting(provider, anthropic)
    ->  E = low
    ;   v2_config(loop_effort, E)
    ).
v2_setting(max_tokens, N) :-
    (   getenv('CODING_BENCH_MAX_TOKENS', V), V \== '',
        atom_number(V, N0), integer(N0)
    ->  N = N0
    ;   v2_setting(provider, anthropic)
    ->  N = 16000
    ;   N = none
    ).

v2_setting_env(Var, Key, Value) :-
    (   getenv(Var, V), V \== ''
    ->  Value = V
    ;   v2_config(Key, Value)
    ).
