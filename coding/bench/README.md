# coding/bench

A DeepSeek code-generation benchmark: paying for the model's reasoning up
front, a deterministic verification loop, a loop whose prompt carries
obligations from a hand-written controlled-English contract, a loop whose
obligations are extracted from the plain requirement by the model, a loop
whose obligations are derived from its keywords without a model, and a
loop that adds those obligations only after a failed first attempt.

## The six modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `reasoning_effort(high)` | the model gets the requirement and must return working C |
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=c17 -Wall -Wextra -O0` and run on the task's cases; the compiler/test report and the previous program go back with the next call |
| `contract` | up to three | `reasoning_effort(none)` | the loop, with an obligation checklist added to the prompt. The checklist is derived by `contract.pl` from the task's hand-written sentences in the controlled English `library(reasoning/reason)` reads |
| `extract` | one + up to three | `reasoning_effort(none)` | one call rewrites the plain requirement into allowed controlled-English sentences; `reason.pl` accepts the lines it can read, and the obligations derived from them go into the loop's prompt. The prompt names the task's read and print nouns and only the shapes that task can use |
| `derive` | up to three | `reasoning_effort(none)` | the loop, with obligations derived deterministically from the plain requirement's keywords and the task's noun list. No model call |
| `escalate` | up to three | `reasoning_effort(none)` | the first attempt is the plain loop; only a repair attempt adds the keyword-derived obligations |

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
those obligations until a first attempt fails, so a task that passes pays
only the plain loop's prompt. A line the controlled-English reader refuses
is dropped, and a failed extraction leaves the plain requirement. A failed
codegen attempt costs another prompt with the previous code and
diagnostics, so any loop can lose to `high` when the first attempt fails.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner, the task modes and the report |
| `gen.pl` | one generator call, run as a child `cocolog` so codegen's `main/0` is never called here |
| `config.pl` | the provider, model, endpoint, temperature, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English contracts, derives the obligations, writes the extractor's prompt and line parser, and holds the keyword-to-contract rules |
| `tasks.pl` | seven requirements, their hand-written contracts, extractor noun lists and stdin/stdout cases |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `paired.pl` | the paired repair comparison: one shared first attempt, then plain and obliged branches |
| `paired.sh` | sets `COCOLOG_LIBRARY` and runs `paired.pl` |

## Run

```sh
export REASONING_API_KEY=...
coding/bench/run.sh              # all tasks, six modes
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

2026-11-14, `deepseek-flash`, `REASONING_API_KEY`, all seven tasks:

```
mode     tasks passed attempts prompt completion reasoning total cache_hit seconds
high     7     7      7        943    11344      7985      12287 0         69.08
loop     7     7      8        1145   3167       0         4312  128       38.42
contract 7     7      7        1398   3317       0         4715  0         36.07
extract  7     7      14       3280   3471       0         6751  512       35.25
derive   7     7      7        1423   3401       0         4824  0         32.74
escalate 7     7      7        768    3002       0         3770  0         33.56
```

All six modes solved every task. `escalate` had the lowest total: it paid
the plain first-attempt prompt and never needed a repair. `loop` is close
but its LCS first attempt failed and its repair cost 984; `escalate`'s LCS
first attempt passed at 364. On the six tasks where both passed first try,
the two are nearly identical (sum_even 200 against 200, max_subarray 278
against 278, balanced 418 against 418); the differences are
completion-token variance, not the mode.

That is also the limitation of this comparison: each mode makes its own
model calls, so the first-attempt luck differs. The LCS outcome does not
show that escalation repairs better; it shows that escalation's first
attempt happened to pass. Temperature 0 is set to reduce this, and the
provider still varies. A paired run that generates the first attempt once
and branches into the two repair policies is the next methodological step.

The other results hold: `contract` and `derive` solved LCS first try (527
and 526) but their obligations add prompt tokens on every task, so they
cost 4 715 and 4 824 against `loop`'s 4 312. `extract` is the costliest
no-reasoning mode at 6 751. `high` burned 7 985 reasoning tokens.

## Paired run

The six mode rows above call the model independently, so first-attempt
luck can decide the total. `paired.pl` removes that: one plain first
attempt per task; if it fails, the same program and diagnostic are the
input to two branches:

- `pair_plain`: up to two repairs with the plain requirement;
- `pair_obliged`: up to two repairs with the keyword-derived obligations.

The first attempt's tokens are counted in both totals, so the difference
is the repair policy alone.

A sample from the same seven tasks:

```
task first plain_total obliged_total plain_pass obliged_pass
sum_even   yes  173 173 pass pass
max_subarray yes 278 278 pass pass
balanced   yes  418 418 pass pass
word_count yes 1047 1047 pass pass
phonebook  yes  898 898 pass pass
calculator yes  587 587 pass pass
lcs        no   984 1144 pass pass
```

The one first attempt that failed:

```
task first_tokens plain_repair obliged_repair plain_attempts obliged_attempts plain_pass obliged_pass
lcs  328          656          816            2              2                pass       pass
```

Totals:

```
tasks passed first_tokens plain_repair obliged_repair plain_total obliged_total
7     7      3729         656          816            4385        4545
```

Six first attempts passed, so both policies were identical there. LCS
failed, and both policies fixed it on the first repair; the obligations
did not save an attempt and cost 160 more tokens (816 against 656). The
plain repair wins on this failure. Obligations on repair would pay only
if a plain repair failed and the obliged repair passed, which this task
set did not show; a harder task or more trials is the next measurement.

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
rule there. Escalate uses the same rules, but only on a repair attempt.
`high` and `loop` use `Spec` alone; `extract` writes its own sentences;
`derive` writes them from keywords. No Python is involved.
