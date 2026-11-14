# coding/cocolog/bench

A benchmark for `coding/cocolog/codegen.pl`: four cocolog tasks, two modes.

| task | what it asks |
|---|---|
| `html_template` | load `page.html` with `library(template)` and render it twice, with escaping, an `if` and a `for` |
| `json` | parse a JSON document and take a field; write a JSON object |
| `dcg` | parse two comma-separated integer lists with a DCG |
| `store` | assert, collect and sort city facts; retract one and collect again |

Every task's `main/0` prints all of its results in one run; one expected file
per task holds the exact output. The codegen's `--expect` check compares the
run with that file, so a program that loads but prints the wrong text is a
failure and its report goes back for repair.

## Modes

| mode | calls | effort | what happens |
|---|---|---|---|
| `high` | one | `high` | one call; no repair |
| `checked` | up to three | `none` | each failed run sends the output mismatch and the previous program back |

The system prompt is cocolog's whole `SKILL.md` (about 19 000 tokens, mostly
served from cache after the first call).

## Run

```sh
export REASONING_API_KEY=...
coding/cocolog/bench/run.sh              # all four tasks, both modes
coding/cocolog/bench/run.sh -- json      # one task
```

## A sample run

2026-11-14, `deepseek-flash`:

```
task           mode    pass calls prompt completion reasoning total  cache  seconds
html_template  high    pass 1     19281  2914       2812      22195  19072  16.90
html_template  checked pass 1     19256  105        0         19361  19072  2.23
json           high    pass 1     19309  10346      10250     29655  18944  53.33
json           checked pass 1     19284  89         0         19373  19072  2.97
dcg            high    pass 1     19262  4209       3983      23471  19072  25.65
dcg            checked fail 3     58261  576        0         58837  57600  9.96
store          high    pass 1     19294  455        279       19749  19072  5.34
store          checked pass 1     19269  175        0         19444  19072  2.62
high                   4 4   4     77146  17924      17324     95070  76160  101.22
checked                4 3   6     116070 945        0         117015 114816 17.78
overall                8 7   10    193216 18869      17324     212085 190976 119.00
```

`high` passed all four first try. `checked` passed three; `dcg` failed after
three attempts in this run, though an earlier run of the same task passed it
on the second. The model is not deterministic; the task and its expected
output are fixed and were checked against a hand-written reference.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner and the totals |
| `tasks.pl` | the four tasks, each spec read from its directory |
| `gen.pl` | one codegen run in a child, so `codegen.pl`'s `main/0` is never called here |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `<task>/spec.txt` | the requirement |
| `<task>/expected.txt` | the exact standard output |
| `html_template/page.html` | the template the first task loads |
