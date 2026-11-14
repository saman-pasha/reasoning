# coding/cocolog/bench

A benchmark for `coding/cocolog/codegen.pl`: eight cocolog tasks, three modes.

| task | what it asks |
|---|---|
| `html_template` | load `page.html` with `library(template)` and render it twice, with escaping, an `if` and a `for` |
| `json` | parse a JSON document and take a field; write a JSON object |
| `dcg` | parse two comma-separated integer lists with a DCG |
| `store` | assert, collect and sort city facts; retract one and collect again |
| `file` | read a file with `read_file_to_codes/2`, split it into lines at code 10 and print them |
| `stream` | the same lines through `library(stream)`: `stream_open/3`, `stream_read_line/2`, `stream_close/1` |
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
coding/cocolog/bench/run.sh              # all eight tasks, three modes
coding/cocolog/bench/run.sh -- json      # one task
```

## A sample run

2026-11-14, `deepseek-flash`:

```
task           mode    pass calls prompt completion reasoning total  cache  seconds
html_template  high    pass 1     19281  2452       2342      21733  19072  15.55
html_template  checked pass 1     19256  105        0         19361  19072  3.20
html_template  no_skill pass 1    229    1915       1805      2144   0      11.50
json           high    pass 1     19309  1223       1120      20532  19072  8.11
json           checked pass 1     19284  102        0         19386  19072  2.59
json           no_skill pass 1    257    704        614       961    123    5.04
dcg            high    pass 1     19262  5004       4789      24266  19072  31.03
dcg            checked pass 3     58273  601        0         58874  57728  8.99
dcg            no_skill pass 1    210    7518       7272      7728   0      39.70
store          high    pass 1     19294  1015       832       20309  19072  6.36
store          checked pass 1     19269  175        0         19444  19072  2.39
store          no_skill pass 1    242    2638       2451      2880   0      15.51
codes          high    pass 1     19249  441        378       19690  19072  3.91
codes          checked pass 1     19224  64         0         19288  19072  3.73
codes          no_skill pass 1    197    926        867       1123   0      5.94
file           high    pass 1     19251  2446       2283      21697  19072  15.15
file           checked pass 1     19226  187        0         19413  19072  2.94
file           no_skill pass 1    199    4065       3909      4264   0      22.95
stream         high    pass 1     19257  1270       1134      20527  18944  7.91
stream         checked pass 1     19232  130        0         19362  18944  2.58
stream         no_skill pass 1    205    1705       1583      1910   0      10.08
namespace      high    fail 1     19248  5559       5501      24807  19072  34.72
  ERROR cocolog_failed
namespace      checked pass 3     57953  215        0         58168  57472  6.97
namespace      no_skill fail 1    196    424        366       620    0      3.60
  ERROR cocolog_failed
high                   8 7   8     154151 19410      18379     173561 152448 122.74
checked                8 8   12    231717 1579       0         233296 229504 33.39
no_skill               8 7   8     1735   19895      18867     21630  123    114.32
overall                24 22 28    387603 40884      37246     428487 382075 270.45
```

`checked` passed all eight, repairing `dcg`, `namespace` and `stream` on its
third call. `high` and `no_skill` each passed seven: both failed `namespace`,
the one-namespace trap the guide names. `high` used 173 561 tokens against
the control's 21 630, about eight times as many, and the guide's one-shot
advantage over the control is not visible in this run; with repairs, the
guided `checked` mode passed every task in 12 calls and 233 296 tokens.
`namespace` is still the task a one-shot call gets wrong most often: the
model defines `member/2` and the library's own still answers. The tasks and
expected outputs are fixed and were checked against hand-written references.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner and the totals |
| `tasks.pl` | the eight tasks, each spec read from its directory |
| `gen.pl` | one codegen run in a child, so `codegen.pl`'s `main/0` is never called here |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `<task>/spec.txt` | the requirement |
| `<task>/expected.txt` | the exact standard output |
| `html_template/page.html` | the template the first task loads |
