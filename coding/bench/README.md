# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front, a deterministic verification loop, a loop whose prompt carries
obligations from a hand-written controlled-English contract, and a loop
whose obligations are extracted from the plain requirement by the model.

## The four modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |
| `contract` | up to three | `reasoning_effort(none)` | the loop, with an obligation checklist added to the prompt. The checklist is derived by `contract.pl` from the task's hand-written sentences in the controlled English `library(reasoning/reason)` reads |
| `extract` | one + up to three | `reasoning_effort(none)` | one call rewrites the plain requirement into allowed controlled-English sentences; `reason.pl` accepts the lines it can read, and the obligations derived from them go into the loop's prompt |

The loop is the reasoning this repository already trusts -- a compiler and
tests -- not a second model. The contract mode adds the other half: rules
over the parsed requirement produce obligations such as "read whole lines,
not whitespace-separated words; a line may be empty" without spending a
model reasoning token. The extract mode asks a model to write that
contract; a line the controlled-English reader refuses is dropped, and a
failed extraction leaves the plain requirement. A failed codegen attempt
costs another prompt with the previous code and diagnostics, so either
loop can lose to `high` when the first attempt fails.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English contracts, derives the obligations, and holds the extractor's prompt and line parser |
| `tasks.pl` | seven requirements, their hand-written contracts and stdin/stdout cases |
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
`high` mode and `none` for `loop`, `contract` and `extract`.
`loop_attempts` is the cap (three).

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
high     7     7      7        943    9672       6636      10615 0         62.51
loop     7     7      7        768    2773       0         3541  0         32.92
contract 7     7      7        1398   3344       0         4742  0         35.78
extract  7     7      15       4040   4513       0         8553  128       39.27
```

All four modes solved every task. `loop` won this run because every
codegen first attempt passed: the contract obligations added prompt tokens
and bought nothing (4 742 against 3 541), and extraction added more still.
`extract` made seven extraction calls and needed one `word_count` repair;
its 15 attempts are 7 extraction calls and 8 codegen calls. It still beat
`high` (8 553 against 10 615) but not `loop` or `contract`.

That ranking is not fixed. In an earlier three-mode run the loop needed
repairs on calculator and LCS -- the LCS attempt used `scanf("%100s")`,
which cannot read an empty line -- and the hand-written contract won,
4 595 against 6 235. The benchmark exists to show both sides: the hand
contract pays when a repair is likely, the plain loop pays when it is not,
and the extractor currently pays for its own rewrite without making the
first attempt reliable enough to earn it back. Tightening the extraction
prompt, or validating and retrying its lines, is the next lever.

`high` burned 6 636 reasoning tokens; every no-reasoning mode burned none.

## Adding a task

Add a `bench_task(Name, Spec, Cases)` clause and a
`bench_requirement(Name, Sentences)` clause to `tasks.pl`. `Cases` is a
list of `case(Input, Expected)`, both atoms; `Input` keeps its newlines,
and `Expected` is compared after trailing whitespace and final newlines
are trimmed. `Sentences` is the same requirement in the controlled English
`library(reasoning/reason)` reads; `contract.pl` derives the contract
mode's checklist from it, so a sentence the reader refuses breaks the
`contract` mode. `high`, `loop` and `extract` use `Spec` alone; `extract`
writes its own sentences from it. No Python is involved.
