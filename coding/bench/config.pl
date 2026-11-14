%% coding/bench/config.pl -- the provider and modes the benchmark uses.
%%
%% Both bench.pl (the runner) and gen.pl (the child generator) load this
%% file, so a change here moves both modes. These are the benchmark's own
%% facts, not coding/options.pl's defaults: the benchmark is DeepSeek, and
%% the two modes differ only in reasoning effort.

bench_config(provider, openai).
bench_config(model, 'deepseek-flash').
bench_config(base_url, 'https://api.deepseek.com/v1/chat/completions').
bench_config(temperature, 0).
bench_config(high_effort, high).
bench_config(loop_effort, none).
bench_config(loop_attempts, 3).

%% The C edition every task is compiled and run as. It is a bench_config
%% fact so a run can name it beside the model -- `assertz(bench_config(std,
%% c23))' in a caller's own file, before main/0 -- and bench.pl asks for it
%% alone: the tasks' requirements say `a complete C program', and the
%% standard is this setting, not a word repeated in twelve specs. c17 is
%% the default because every table recorded before this fact was recorded
%% under it.
bench_config(std, c17).
