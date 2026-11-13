# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front, a deterministic verification loop, and a loop whose prompt carries
obligations derived from a controlled-English contract.

## The three modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |
| `contract` | up to three | `reasoning_effort(none)` | the loop, with an obligation checklist added to the prompt. The checklist is derived by `contract.pl` from the task's sentences in the controlled English `library(reasoning/reason)` reads |

The loop is the reasoning this repository already trusts -- a compiler and
tests -- not a second model. The contract mode adds the other half: rules
over the parsed requirement produce obligations such as "read whole lines,
not whitespace-separated words; a line may be empty" without spending a
model reasoning token. A failed attempt costs another prompt that contains
the previous code and the diagnostics, so either loop can lose to `high`
when the first attempt fails.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English requirements and derives the obligations |
| `tasks.pl` | seven requirements, their controlled-English contracts and stdin/stdout cases |
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
DeepSeek's OpenAI-compatible endpoint, `deepseek-flash`, `high` for the
`high` mode and `none` for `loop` and `contract`. `loop_attempts` is the
cap (three).

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
mode     tasks passed attempts prompt completion reasoning total cache_hit seconds
high     7     7      7        943    10571      7510      11514 0         70.33
loop     7     7      9        2274   3961       0         6235  128       61.33
contract 7     7      7        1398   3197       0         4595  0         35.54
```

The contract mode used 60 % fewer tokens than `high` (4 595 against
11 514) and 26 % fewer than `loop` (4 595 against 6 235), and about half
`high`'s wall time. All seven contract calls passed on the first attempt.
The loop did not: its calculator attempt failed once, and its LCS attempt
used `scanf("%100s")`, which returns no second string on an empty line.
Those two repairs cost 2 458 and 980 tokens; the contract mode's
first-attempt totals for the same tasks were 718 and 561. The obligations
that catch these are the line's length and the empty-line rule.

On a task the first attempt passes, `loop` is still cheaper than
`contract`: the obligations add prompt tokens (sum_even is 173 against
280) and buy nothing. The contract mode pays when a failure would cost a
repair prompt -- which is the case the benchmark exists to show.

`high` burned 7 510 reasoning tokens; both loops burned none.

## Adding a task

Add a `bench_task(Name, Spec, Cases)` clause and a
`bench_requirement(Name, Sentences)` clause to `tasks.pl`. `Cases` is a
list of `case(Input, Expected)`, both atoms; `Input` keeps its newlines,
and `Expected` is compared after trailing whitespace and final newlines
are trimmed. `Sentences` is the same requirement in the controlled English
`library(reasoning/reason)` reads; `contract.pl` derives the contract
mode's checklist from it, so a sentence the reader refuses breaks the
`contract` mode. `high` and `loop` use `Spec` alone. No Python is
involved.
