# coding/cocolog/bench

A benchmark for `coding/cocolog/codegen.pl`: seven cocolog tasks, three modes.

| task | what it asks |
|---|---|
| `html_template` | load `page.html` with `library(template)` and render it twice, with escaping, an `if` and a `for` |
| `json` | parse a JSON document and take a field; write a JSON object |
| `dcg` | parse two comma-separated integer lists with a DCG |
| `store` | assert, collect and sort city facts; retract one and collect again |
| `file` | read a file with `read_file_to_codes/2`, split it into lines at code 10 and print them |
| `codes` | treat `"hello"` as codes, not an atom, and compare it with `'hello'` |
| `namespace` | define a `member/2` that accepts only `special`, against the library's `member/2` |

Every task's `main/0` prints all of its results in one run; one expected file
per task holds the exact output. The codegen's `--expect` check compares the
run with that file, so a program that loads but prints the wrong text is a
failure and its report goes back for repair.

## Modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `high` | one call with SKILL.md in the system prompt; no repair |
| `checked` | up to three | `none` | each failed run sends the output mismatch and the previous program back |
| `no_skill` | one | `high` | the `high` control with the guide omitted; a short generic cocolog prompt |

The `no_skill` mode is the control for SKILL.md: same task and effort, no
guide. The system prompt is only a sentence naming cocolog and `main/0`.

The system prompt is cocolog's whole `SKILL.md` (about 19 000 tokens, mostly
served from cache after the first call).

## Run

```sh
export REASONING_API_KEY=...
coding/cocolog/bench/run.sh              # all seven tasks, three modes
coding/cocolog/bench/run.sh -- json      # one task
```

## A sample run

2026-11-14, `deepseek-flash`:

```
task           mode    pass calls prompt completion reasoning total  cache  seconds
html_template  high    pass 1     19281  1679       1565      20960  19072  11.05
html_template  checked pass 1     19256  105        0         19361  19072  2.89
html_template  no_skill pass 1    229    5460       5342      5689   0      31.45
json           high    pass 1     19309  1013       910       20322  19072  7.83
json           checked pass 1     19284  89         0         19373  19072  2.92
json           no_skill fail 1    257    5323       5208      5580   123    28.62
dcg            high    pass 1     19262  4795       4561      24057  19072  27.00
dcg            checked fail 3     58273  596        0         58869  57728  9.24
dcg            no_skill pass 1    210    4001       3869      4211   0      22.33
store          high    pass 1     19294  964        785       20258  19072  6.62
store          checked pass 1     19269  175        0         19444  19072  2.59
store          no_skill pass 1    242    1472       1289      1714   0      7.70
codes          high    pass 1     19249  489        430       19738  18944  4.14
codes          checked pass 1     19224  64         0         19288  19072  2.50
codes          no_skill pass 1    197    771        712       968    0      5.26
file           high    pass 1     19251  2215       2035      21466  18944  13.96
file           checked pass 1     19226  197        0         19423  19072  2.59
file           no_skill pass 1    199    6021       5745      6220   0      32.53
namespace      high    pass 1     19248  8112       8040      27360  18944  49.26
namespace      checked fail 3     57929  179        0         58108  57472  7.10
namespace      no_skill fail 1    196    1827       1769      2023   0      10.69
high                   7 7   7     134894 19267      18326     154161 133120 119.86
checked                7 5   11    212461 1405       0         213866 210560 29.83
no_skill               7 5   7     1530   24875      23934     26405  123    138.58
overall                21 17 25    348885 45547      42260     394432 343803 288.27
```

`high` passed all seven first try. `no_skill` passed five: it failed `json`
and `namespace`, the two tasks that name a cocolog trap in the guide — the
JSON term and the one namespace. `checked` also passed five: it failed
`namespace` and `dcg` (which `high` and `no_skill` both passed; the model is
not deterministic). The control used 26 405 tokens against `high`'s 154 161:
SKILL.md bought two tasks for about six times the tokens in this run. The
tasks and expected outputs are fixed and were checked against hand-written
references.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner and the totals |
| `tasks.pl` | the seven tasks, each spec read from its directory |
| `gen.pl` | one codegen run in a child, so `codegen.pl`'s `main/0` is never called here |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `<task>/spec.txt` | the requirement |
| `<task>/expected.txt` | the exact standard output |
| `html_template/page.html` | the template the first task loads |
