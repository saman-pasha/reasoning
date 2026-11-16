# coding/bench

This file describes the legacy suite. The repeated-trial suite with one
verifier, exact output policies and held-out cases is in `v2/` (see
`v2/README.md`); the legacy files stay runnable and unchanged.

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
| `loop` | up to three | `reasoning_effort(none)` | after each call the code is compiled with `clang -std=<EDITION> -Wall -Wextra -O0` (`c17` unless `bench_config(std, ...)` names another) and run on the task's cases; the compiler/test report and the previous program go back with the next call |
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
| `gen.pl` | one generator call, run as a child `cocolog` so the tool's CLI is never called here |
| `config.pl` | the provider, model, endpoint, temperature, efforts and loop cap both scripts use |
| `contract.pl` | parses the controlled-English contracts with the shared `coding/contract.pl` reader and vocabulary, writes the extractor's prompt and line parser, and holds the keyword-to-contract rules |
| `tasks.pl` | twelve requirements, their hand-written contracts, extractor noun lists and stdin/stdout cases |
| `debug/btree_c_buggy.c` | the cicilang `btree_c.c` adapted to stdin, with three injected defects |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `paired.pl` | the paired repair comparison: one shared first attempt, then plain and obliged branches |
| `paired.sh` | sets `COCOLOG_LIBRARY` and runs `paired.pl` |
| `tool.pl` | the shipped C tool over the same tasks, with its own report |
| `tool_gen.pl` | one real-tool run in a child process, printing usage and result |
| `tool.sh` | sets `COCOLOG_LIBRARY` and runs `tool.pl` |

## Run

```sh
export CODING_ENDPOINT_KEY_ENV=...
coding/bench/run.sh              # all tasks, seven modes
coding/bench/run.sh -- lcs       # one task
coding/bench/paired.sh           # paired first attempt and two repair policies
coding/bench/paired.sh -- lcs
coding/bench/tool.sh             # the shipped tool, all tasks
coding/bench/tool.sh -- lcs
```

`CODING_ENDPOINT_KEY_ENV` is read by the child `gen.pl` through `coding/options.pl`;
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

2026-11-14, `deepseek-flash`, `CODING_ENDPOINT_KEY_ENV`, the ten tasks before
`btree_debug`:

```
mode      tasks passed attempts prompt completion reasoning total cache_hit seconds
high      10    9      10       1607   36956      29534     38563 256       205.33
loop      10    8      15       8139   11445      0         19584 2048      92.33
contract  10    10     10       2382   7888       0         10270 384       62.29
extract   10    10     20       5370   8582       0         13952 1535      61.35
derive    10    10     10       2429   7575       0         10004 384       61.34
escalate  10    9      13       8174   11646      0         19820 1664      84.33
escalate2 10    9      15       9070   13372      0         22442 2048      95.62
```

`stable_sort` is still the hard task: the model must sort by score and
keep equal scores in input order. `high` failed it (2 899 tokens, 2 072
of them reasoning) and `loop` failed it in three plain attempts (2 210).
`contract`, `derive` and `extract` solved it on their first codegen
attempt (1 126, 1 114 and 1 389, the last including its extraction call);
`escalate` passed it on its second attempt (1 823) and `escalate2` on its
third (2 810), which is when its third-stage obligations fired.

`mvccs`, the MVCC B-tree, is one task: one writer, any number of
readers, a snapshot per reader, and a 2-3-4 tree at each snapshot. The
newer `mvccs_acid` adds named transactions, staged inserts and deletes,
atomic commit and abort, snapshot isolation, last-committer-wins and error
handling; its ten cases are in `tasks.pl`. It is not in this older sample.
`high`
passed it first try at 17 197 tokens (14 005 reasoning), and `derive`
passed it first try at 2 902, the cheapest of the modes. `contract`
passed at 2 998 and `extract` at 4 037 (including extraction). `loop`,
`escalate` and `escalate2` failed it after three attempts (11 923, 13 166
and 14 082). The generated programs define B-tree node structs with a
version chain or copy-on-write, so the task measures the MVCC B-tree, not
a flat map. The model is not deterministic: run alone before this suite,
`mvccs` had `contract` and `escalate2` pass first try (3 061 and 2 615)
and `derive` fail; here `derive` passes and `escalate2` fails.

`derive` is the cheapest 10/10 mode at 10 004, then `contract` at 10 270
and `extract` at 13 952; per task solved that is 1 000, 1 027 and 1 395.
`high` is 9/10 and burned 29 534 reasoning tokens, 3 963 per task it
solved (35 664 for the 9). `loop` is 8/10 at 19 584 and `escalate` and
`escalate2` 9/10 at 19 820 and 22 442; the failed tasks account for much
of those totals.

`btree` passed on the first attempt in every mode: `high` spent 6 249
tokens (5 090 reasoning) where `loop`, `derive`, `escalate` and
`escalate2` spent 1 134-1 136, `contract` 1 326 and `extract` 1 647.

### The mvccs_acid run

2026-11-15, `deepseek-flash`, `CODING_ENDPOINT_KEY_ENV`, `mvccs_acid` alone:

```
mode      tasks passed attempts prompt completion reasoning total cache_hit seconds
high      1     0      1        520    36711      31140     37231 0         175.89
loop      1     0      3        10695  13360      0         24055 1024      50.43
contract  1     1      2        7245   11378      0         18623 640       44.78
extract   1     0      4        13934  16187      0         30121 3712      53.64
derive    1     0      3        13203  14833      0         28036 4224      52.83
escalate  1     0      3        12533  14972      0         27505 1536      51.60
escalate2 1     0      3        10779  13317      0         24096 1280      48.34
opencode-c-r0#high 1     1      39       1660899 42270      26492     1703169 1638272   557.95
opencode-c-r2#high 1     1      12       364250  33931      24856     398181  355712    319.88
opencode-c-r8#high 1     1      10       297881  30504      20579     328385  290432    198.87
codex-c-r0#high    1     1      15       873893  39422      27428     913315  830592    315.55
codex-c-r2#high    1     1      13       421904  19987      12762     441891  399103    223.53
codex-c-r8#high    1     1      33       2378233 49075      31407     2427308 2324992   580.39
```

The OpenCode rows are not benchmark modes: they are the same task
through OpenCode, in a fresh directory holding only `spec.txt` and
`cases/`, with the model's `#high` variant. `attempts` counts endpoint
calls and `seconds` is the session's wall time; the token columns are the
sums of the backend's reported usage over those calls. The call times
were 349.3 s for `c-r0`, 228.9 s for `c-r2` and 169.4 s for `c-r8`.
`c-r0#high` traces `mode=plain`, `reasoning=0` and `terms=0` on every
call, so its 26,492 reasoning tokens are DeepSeek's own `#high` effort,
not endpoint checks. Each generated program was independently rebuilt
with `clang -std=c17 -Wall -Wextra -O0`, passed all ten cases, passed
ASan/UBSan, and matched an independent specification model on 1,000
random command streams.

The three `codex-...#high` rows are the same task through Codex 0.169,
with the same prompt and the same two files, under
`codex -p reasoning -m c-rN -c model_reasoning_effort=high exec -s
workspace-write --skip-git-repo-check`. `attempts` is again the endpoint
calls and `seconds` the session's wall time; the endpoint's call time was
230.9 s for `c-r0`, 118.4 s for `c-r2` and 384.4 s for `c-r8`, the rest
being the agent's own builds, case runs and fuzzing. Each program was
rebuilt independently, passed the ten cases and ASan/UBSan, and matched
the independent model on 500 random streams (200 more under the
sanitizers). Codex's `c-r8` session spent most of its wall time on its
own stress tests: 33 calls and 2.43 million prompt tokens against
OpenCode's 10 calls and 328 thousand.

`contract` is the only passing benchmark mode, and it needed two attempts: the
first timed out on cases 2 and 6, the second passed all ten. `high`, one
call with no repair, failed only case 8, the last-committer-wins delete
after another transaction inserted the key. `loop`, `derive`, `escalate`,
`escalate2` and `extract` all failed case 3, a read that should not see a
key committed after its snapshot but did. The task is much heavier than
the `mvccs` result above: `high` spent 31 140 reasoning tokens and still
missed the edge case, while the passing `contract` run cost 18 623 tokens
in total.

### The btree_debug task

`btree_debug` is the cicilang benchmark's `btree_c.c`, adapted to read `n`
from standard input and print three deterministic counts, with three
defects injected. The requirement carries the buggy source, the correct
output `((n+1)/2) (n/2) 0`, and the symptoms at `n=30` and `n=256`. Run
alone on 2026-11-14:

```
mode      tasks passed attempts prompt completion reasoning total cache_hit seconds
high      1     1      1        2758   24055      21749     26813 0         123.11
loop      1     1      1        2733   1948       0         4681  2560      10.05
contract  1     1      1        2802   1962       0         4764  0         10.27
extract   1     0      4        15412  5915       0         21327 8064      30.91
derive    1     1      1        2801   1949       0         4750  2560      9.97
escalate  1     1      1        2733   1948       0         4681  2560      9.61
escalate2 1     1      1        2733   1949       0         4682  2560      10.02
```

Six modes fixed it on the first call; `extract` failed after four
attempts. The bug report in the requirement is what made the task
solvable: in a first run without it, every mode failed and `high` timed
out after 600 s, and the models repaired the insertion branch but left the
merge's last child and the right rotation's child index. The shipped tool
fixes it on the first call too (4 844 tokens, 11.94 s).

### History: the eight tasks before `btree`

The same day, before `btree` was added:

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

Here `high` and `loop` failed `stable_sort` and were 7/8; the other five
modes were 8/8, `extract` costliest at 7 953, and `derive` cheapest among
them at 5 991.

## Paired run

The seven mode rows above call the model independently, so first-attempt
luck can decide the total. `paired.pl` removes that: one plain first
attempt per task; if it fails, the same program and diagnostic are the
input to two branches:

- `pair_plain`: up to two repairs with the plain requirement;
- `pair_obliged`: up to two repairs with the keyword-derived obligations.

The first attempt's tokens are counted in both totals, so the difference
is the repair policy alone.

A sample from the same eight tasks, before `btree` was added:

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

## The shipped tool

`coding/bench/tool.sh` runs the real `coding/c/codegen.pl` policy over the
same tasks: the keyword obligations on every attempt, compile repair, and
the task's cases under the sanitizers. Its tokens come from
`codegen_report/1`, and a task passes only when the tool accepts it. It is
the `derive` policy plus the tool's own keyword reader and the sanitizers,
so its token count is the one to compare with the tool's future.

A run on the ten tasks before `btree_debug`, on 2026-11-14:

```
task        pass calls prompt completion reasoning total cache_hit seconds
sum_even    pass 1     219    73         0         292   0         5.47
max_subarray pass 1    228    169        0         397   0         5.15
balanced    pass 1     211    320        0         531   0         5.08
word_count  pass 1     237    835        0         1072  0         5.94
phonebook   pass 1     286    830        0         1116  128       6.70
calculator  pass 1     244    488        0         732   0         5.89
lcs         pass 1     202    249        0         451   0         5.37
stable_sort pass 1     241    533        0         774   0         6.51
btree       pass 1     218    940        0         1158  0         7.32
mvccs       pass 1     666    2457       0         3123  512       13.31
overall     10 10      10     2752       6894      0     9646  640       66.74
```

All ten passed on the first call, including `stable_sort`, `btree` and
`mvccs`;
the keyword checklist carried the stable-order line without a repair. The
seconds are longer than the `derive` row's because every case runs under
the sanitizers.

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
