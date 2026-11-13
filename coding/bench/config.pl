%% coding/bench/config.pl -- the provider and modes the benchmark uses.
%%
%% Both bench.pl (the runner) and gen.pl (the child generator) load this
%% file, so a change here moves both modes. These are the benchmark's own
%% facts, not coding/options.pl's defaults: the benchmark is DeepSeek, and
%% the two modes differ only in reasoning effort.

bench_config(provider, openai).
bench_config(model, 'deepseek-flash').
bench_config(base_url, 'https://api.deepseek.com/v1/chat/completions').
bench_config(high_effort, high).
bench_config(loop_effort, none).
bench_config(loop_attempts, 3).
