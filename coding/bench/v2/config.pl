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

v2_config(modes, [plain, derive]).

v2_config(max_diagnostic, 4000).
v2_config(child_timeout_ms, 600000).

v2_config(results_dir, 'coding/bench/v2/results').
