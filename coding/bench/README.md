# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front, a deterministic verification loop, a loop whose prompt carries
obligations from a hand-written controlled-English contract, a loop whose
obligations are extracted from the plain requirement by the model, a loop
whose obligations are derived from its keywords without a model, a loop
that adds those obligations after one failed attempt, and one that adds
them only after two.

## The seven modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |
| `contract` | up to three | `reasoning_effort(none)` | the loop, with an obligation checklist added to the prompt. The checklist is derived by `contract.pl` from the task's hand-written sentences in the controlled English `library(reasoning/reason)` reads |
| `extract` | one + up to three | `reasoning_effort(none)` | one call rewrites the plain requirement into allowed controlled-English sentences; `reason.pl` accepts the lines it can read, and the obligations derived from them go into the loop's prompt. The prompt names the task's read and print nouns and only the shapes that task can use |
| `derive` | up to three | `reasoning_effort(none)` | the loop, with obligations derived deterministically from the plain requirement's keywords and the task's noun list. No model call |
| `escalate` | up to three | `reasoning_effort(none)` | the first attempt is the plain loop; only a repair attempt adds the keyword-derived obligations |
| `escalate2` | up to three | `reasoning_effort(none)` | the first two attempts are the plain loop; only the third adds the keyword-derived obligations |

The loop is the reasoning this repository already trusts -- a compiler and
tests -- not a second model. The contract mode adds the other half: rules
over the parsed requirement produce obligations such as "read whole lines,
not whitespace-separated words; a line may be empty" without spending a
model reasoning token. The extract mode asks a model to write that
contract; its prompt names the task's read and print nouns, closes the noun
list, and offers only the shapes the task can use. The derive mode writes
the same kind of contract from keywords the plain requirement already has
(`subsequence`, `command`, `expression`, `lexicographic`) and the task's
noun list, so it pays no model call at all. The escalate mode withholds
those obligations until a first attempt fails; escalate2 withholds them
until a second attempt fails, so a plain repair gets its chance first. A
line the controlled-English reader refuses is dropped, and a failed
extraction leaves the plain requirement. A failed codegen attempt costs
another prompt with the previous code and diagnostics, so any loop can lose
to `high` when the first attempt fails.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, temperature, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English contracts, derives the obligations, writes the extractor's prompt and line parser, and holds the keyword-to-contract rules |
| `tasks.pl` | eight requirements, their hand-written contracts, extractor noun lists and stdin/stdout cases |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `paired.pl` | the paired repair comparison: one shared first attempt, then plain and obliged branches |
| `paired.sh` | sets `COCOLOG_LIBRARY` and runs `paired.pl` |

## Run

```sh
export REASONING_API_KEY=...
coding/bench/run.sh              # all tasks, seven modes
coding/bench/run.sh -- lcs       # one task
coding/bench/paired.sh           # paired first attempt and two repair policies
coding/bench/paired.sh -- lcs
```

`REASONING_API_KEY` is read by the child `gen.pl` through `coding/options.pl`;
no other provider variable is needed. `run.sh` and `paired.sh` build
`COCOLOG_LIBRARY` as a colon-separated list, like `PATH`: the repository's
parent, the cocolog checkout's `library/`, and any value the variable
already had.

The provider, model, endpoint and efforts are `coding/bench/config.pl`'s
facts: DeepSeek's OpenAI-compatible endpoint, `deepseek-flash`, `high` for
the `high` mode and `none` for the others. `temperature` is 0, to make
runs as repeatable as the provider allows; `loop_attempts` is the cap
(three).

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

2026-11-14, `deepseek-flash`, `REASONING_API_KEY`, all eight tasks:

```
mode      tasks passed attempts prompt completion reasoning total cache_hit seconds
high      8     7      8        1077   16762      12670     17839 0         102.95
loop      8     7      10       1955   3908       0         5863  768       51.64
contract  8     8      8        1615   4419       0         6034  0         45.41
extract   8     8      16       3772   4181       0         7953  640       40.67
derive    8     8      8        1693   4298       0         5991  0         40.35
escalate  8     8      10       2024   4439       0         6463  768       50.98
escalate2 8     8      11       2465   4618       0         7083  1024      55.23
```

`stable_sort` is the hard task: the model must sort by score and keep
equal scores in input order. `high` and `loop` both failed it; loop tried
three plain attempts and spent 2 210 tokens on the task. `contract`,
`derive` and `extract` solved it on their first codegen attempt (1 118,
1 130 and 1 321, the last including its extraction call), so they are 8/8
without a repair. `escalate` passed it on its second attempt (1 930);
`escalate2` passed it on its third (2 773), which is the first time its
third-stage obligations fired.

That is the expected tradeoff: `escalate2` withholds the obligations until
a second repair is needed, so it pays two failed attempts before they
help. `contract`/`derive` pay obligations on every task and solve the hard
one first time; on the earlier easy tasks that cost more than a plain
loop, but here it also buys the missing task. `extract` is 8/8 but the
costliest no-reasoning mode at 7 953. `high` failed `stable_sort` and
burned 12 670 reasoning tokens.

## Paired run

The seven mode rows above call the model independently, so first-attempt
luck can decide the total. `paired.pl` removes that: one plain first
attempt per task; if it fails, the same program and diagnostic are the
input to two branches:

- `pair_plain`: up to two repairs with the plain requirement;
- `pair_obliged`: up to two repairs with the keyword-derived obligations.

The first attempt's tokens are counted in both totals, so the difference
is the repair policy alone.

A sample from the same eight tasks:

```
task        first plain_total obliged_total plain_pass obliged_pass
sum_even    yes   200   200   pass pass
max_subarray yes  278   278   pass pass
balanced    yes   419   419   pass pass
word_count  yes   1047  1047  pass pass
phonebook   yes   839   839   pass pass
calculator  yes   546   546   pass pass
lcs         no    984   1144  pass pass
stable_sort no    2210  1930  fail pass
```

The two first attempts that failed:

```
task        first_tokens plain_repair obliged_repair plain_attempts obliged_attempts plain_pass obliged_pass
lcs         328          656          816            2              2                pass       pass
stable_sort 450          1760         1480           3              2                fail       pass
```

Totals:

```
tasks passed first_tokens plain_repair obliged_repair plain_total obliged_total
8     7      4107         2416          2296           6523        6403
```

Six first attempts passed, so both policies were identical there. LCS
failed and both policies fixed it on the first repair; the obligations cost
160 more tokens (816 against 656), so the plain repair wins that one.
`stable_sort` is the other side: the plain branch failed after both repairs
(1 760 repair tokens), while the obliged branch passed on its second repair
(1 480), because the third attempt carried the stable-order obligation. The
obliged policy therefore solved one more task and spent 120 fewer tokens
overall.

This is the clean comparison the six-mode rows cannot make: on a task whose
plain repairs fail, obligations on the second repair pay. On a task where a
plain repair succeeds, they are 160 tokens of overhead.

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
rule there. Escalate uses the same rules on the first repair; escalate2
uses them only on the second. `high` and `loop` use `Spec` alone;
`extract` writes its own sentences; `derive` writes them from keywords.
No Python is involved.
