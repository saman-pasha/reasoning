# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front against paying for a deterministic verification loop.

## The two modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |

The loop is the reasoning this repository already trusts -- a compiler and
tests -- not a second model. A failed attempt costs another prompt that
contains the previous code and the diagnostics, so the loop can lose to
`high` when the first attempt fails. The task set includes one such case.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, efforts and loop cap both scripts use |
| `tasks.pl` | seven requirements and their stdin/stdout cases |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |

## Run

```sh
export REASONING_API_KEY=...
coding/bench/run.sh              # all tasks
coding/bench/run.sh -- lcs       # one task
```

`REASONING_API_KEY` is read by the child `gen.pl` through `coding/options.pl`;
no other provider variable is needed. `run.sh` builds `COCOLOG_LIBRARY` as a
colon-separated list, like `PATH`: the repository's parent, the cocolog
checkout's `library/`, and any value the variable already had.

The provider, model and endpoint are `coding/bench/config.pl`'s facts:
DeepSeek's OpenAI-compatible endpoint, `deepseek-flash`, `high` for the one
mode and `none` for the loop. `loop_attempts` is the cap (three).

Each run prints the temporary directory holding every attempt's `.spec.txt`,
`.c`, `.out` and `.diag.txt`, then a line per task/mode and the totals.

## What is measured

The provider's own usage, read from `library(llm)`'s `llm_last_usage/1`:

| column | meaning |
|---|---|
| `prompt` | input tokens |
| `completion` | output tokens, including reasoning |
| `reasoning` | the part of `completion` spent reasoning |
| `total` | prompt + completion |
| `cache_hit` | prompt tokens DeepSeek reports as cache hits |
| `seconds` | wall time for the mode's calls, compiles and tests |

`attempts` counts generator calls; a task passes when every case matches
after trimming trailing whitespace and final newlines.

## A sample run

2026-11-14, `deepseek-flash`, `REASONING_API_KEY`, all seven tasks:

```
mode tasks passed attempts prompt completion reasoning total cache_hit seconds
high 7     7      7        943    7050       4413      7993  0         56.75
loop 7     7      8        1145   2988       0         4133  0         39.03
```

The loop used 48 % fewer tokens (4 133 against 7 993) and about 31 % less
wall time. Its `high` counterpart burned 4 413 reasoning tokens; the loop
burned none. Six tasks passed on the loop's first attempt. The seventh,
LCS, did not: the first `none` attempt read the two strings with
`scanf("%100s")`, which returns no second string on an empty line, so case
6 (`abc` then an empty line) printed nothing. The repair call read with
`fgets` and passed. That raised the loop's LCS total to 1 036 against
`high`'s 800, with two calls instead of one -- the repair prompt carries
the previous program and the report, and can cost more than thinking
first. The other six tasks are the loop's easy case.

## Adding a task

Add a `bench_task(Name, Spec, Cases)` clause to `tasks.pl`. `Cases` is a
list of `case(Input, Expected)`, both atoms; `Input` keeps its newlines,
and `Expected` is compared after trailing whitespace and final newlines
are trimmed. No Python is involved.
