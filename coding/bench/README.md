# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front, a deterministic verification loop, a loop whose prompt carries
obligations from a hand-written controlled-English contract, a loop whose
obligations are extracted from the plain requirement by the model, and a
loop whose obligations are derived from its keywords without a model.

## The five modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |
| `contract` | up to three | `reasoning_effort(none)` | the loop, with an obligation checklist added to the prompt. The checklist is derived by `contract.pl` from the task's hand-written sentences in the controlled English `library(reasoning/reason)` reads |
| `extract` | one + up to three | `reasoning_effort(none)` | one call rewrites the plain requirement into allowed controlled-English sentences; `reason.pl` accepts the lines it can read, and the obligations derived from them go into the loop's prompt. The prompt names the task's read and print nouns and only the shapes that task can use |
| `derive` | up to three | `reasoning_effort(none)` | the loop, with obligations derived deterministically from the plain requirement's keywords and the task's noun list. No model call |

The loop is the reasoning this repository already trusts -- a compiler and
tests -- not a second model. The contract mode adds the other half: rules
over the parsed requirement produce obligations such as "read whole lines,
not whitespace-separated words; a line may be empty" without spending a
model reasoning token. The extract mode asks a model to write that
contract; its prompt names the task's read and print nouns, closes the noun
list, and offers only the shapes the task can use. The derive mode writes
the same kind of contract from keywords the plain requirement already has
(`subsequence`, `command`, `expression`, `lexicographic`) and the task's
noun list, so it pays no model call at all. A line the controlled-English
reader refuses is dropped, and a failed extraction leaves the plain
requirement. A failed codegen attempt costs another prompt with the
previous code and diagnostics, so any loop can lose to `high` when the
first attempt fails.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English contracts, derives the obligations, writes the extractor's prompt and line parser, and holds the keyword-to-contract rules |
| `tasks.pl` | seven requirements, their hand-written contracts, extractor noun lists and stdin/stdout cases |
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
high     7     7      7        943    8385       5532      9328  0         59.90
loop     7     7      7        768    2613       0         3381  0         34.25
contract 7     7      7        1398   3251       0         4649  0         36.46
extract  7     7      14       3266   3542       0         6808  512       36.17
derive   7     7      7        1423   3321       0         4744  0         36.07
```

All five modes solved every task, and every codegen call passed on its
first attempt. `loop` won because the obligations bought nothing when no
repair was needed: `contract` is 4 649 against `loop`'s 3 381, and `derive`
is 4 744 -- 40 % more. The deterministic derivation is the useful result:
it matched the hand-written contract almost exactly (4 744 against 4 649,
2 % more) with no hand-written requirement and no extraction call. It beat
`extract` by 30 % (4 744 against 6 808) and `high` by 49 % (9 328).

`extract` made seven extraction calls, and its 14 attempts are 7 extraction
calls plus 7 codegen calls, all first try. Its own rewrite still costs more
than it saves. Tightening the prompt had helped -- 8 553 to 6 924, 15
attempts to 14 -- but the deterministic keywords remove the call entirely
and land at the same price as the hand contract.

The ranking is not fixed. In an earlier three-mode run the loop needed
repairs on calculator and LCS -- the LCS attempt used `scanf("%100s")`,
which cannot read an empty line -- and the hand-written contract won,
4 595 against 6 235. The benchmark exists to show both sides: obligations
pay when a repair is likely, the plain loop pays when it is not, and
`derive` is the version that needs no human contract and no extraction
call. Choosing when to add obligations, rather than always adding them, is
the next lever.

`high` burned 5 532 reasoning tokens; every no-reasoning mode burned none.

## Adding a task

Add a `bench_task(Name, Spec, Cases)` clause, a
`bench_requirement(Name, Sentences)` clause, and a
`bench_extract_nouns(Name, ReadNoun, PrintNoun, Nouns)` clause to
`tasks.pl`. `Cases` is a list of `case(Input, Expected)`, both atoms;
`Input` keeps its newlines, and `Expected` is compared after trailing
whitespace and final newlines are trimmed. `Sentences` is the same
requirement in the controlled English `library(reasoning/reason)` reads;
`contract.pl` derives the contract mode's checklist from it. The extract
mode reads `Spec`, names `ReadNoun` and `PrintNoun` in the required lines,
and lets optional lines use `Nouns`; `bench_extract_extra_lines/2` adds a
line the required set cannot say (`sum_even`'s `Every sum is even.`). The
derive mode uses the same `ReadNoun`, `PrintNoun` and `Nouns`, plus the
keyword rules in `contract.pl`; a new concept in `Spec` needs a keyword
rule there. `high` and `loop` use `Spec` alone; `extract` writes its own
sentences; `derive` writes them from keywords. No Python is involved.
