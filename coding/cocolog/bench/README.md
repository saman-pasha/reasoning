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
coding/cocolog/bench/run.sh              # all four tasks, both modes
coding/cocolog/bench/run.sh -- json      # one task
```

## A sample run

2026-11-14, `deepseek-flash`:

```
task           mode    pass calls prompt completion reasoning total  cache  seconds
html_template  high    pass 1     19281  1841       1739      21122  19072  11.55
html_template  checked pass 1     19256  105        0         19361  19072  2.37
html_template  no_skill pass 1    229    2357       2250      2586   0      13.23
json           high    pass 1     19309  1826       1728      21135  19072  11.40
json           checked pass 1     19284  89         0         19373  19072  2.40
json           no_skill pass 1    257    4187       4091      4444   0      23.38
dcg            high    fail 1     19262  7668       7534      26930  19072  42.62
dcg            checked fail 3     58279  605        0         58884  57600  9.29
dcg            no_skill pass 1    210    2508       2297      2718   0      14.36
store          high    pass 1     19294  784        602       20078  19072  5.97
store          checked pass 1     19269  175        0         19444  19072  2.80
store          no_skill pass 1    242    2288       2108      2530   0      12.54
high                   4 3   4     77146  12119      11603     89265  76288  71.54
checked                4 3   6     116088 974        0         117062 114816 16.86
no_skill               4 4   4     938    11340      10746     12278  0      63.51
overall                12 10 14    194172 24433      22349     218605 191104 151.91
```

`high` and `checked` both failed only `dcg` in this run; `no_skill` passed all
four first try. The model is not deterministic (`dcg` has passed in other
runs), but the control's cost is unambiguous: about 200 prompt tokens per
task against 19 000 with SKILL.md, and 12 278 total tokens against 89 265 for
`high`. For these four tasks the guide was not necessary; the suite is a
control, not evidence that a guide never helps.

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
