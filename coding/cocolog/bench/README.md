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

Each task now carries a `reference.pl`, run by `coding/test.pl` against the
same expected file. The `namespace` reference deliberately defines
`ns_member/2`: the task's literal `member/2` is the one-namespace trap, and
the expected output is the one the namespaced version produces.

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
export CODING_ENDPOINT_KEY_ENV=...
coding/cocolog/bench/run.sh              # all eight tasks, three modes
coding/cocolog/bench/run.sh -- json      # one task
```

## A sample run

2026-11-15, `deepseek-flash`, with the 1.6.1/1.6.2 check fixes:

```
task           mode    pass calls prompt completion reasoning total  cache  seconds
html_template  high    pass 1     19281  1312       1212      20593  19072  13.48
html_template  checked pass 1     19256  105        0         19361  19072  3.61
html_template  no_skill pass 1    229    1886       1783      2115   0      12.61
json           high    pass 1     19309  996        887       20305  19072  7.97
json           checked pass 1     19284  96         0         19380  19072  3.92
json           no_skill pass 1    257    1584       1494      1841   123    11.47
dcg            high    pass 1     19262  11928      11684     31190  19072  72.29
dcg            checked pass 2     38691  244        0         38935  38272  10.06
dcg            no_skill pass 1    210    8406       8163      8616   0      52.47
store          high    pass 1     19294  967        786       20261  19072  9.10
store          checked pass 1     19269  175        0         19444  19072  4.39
store          no_skill pass 1    242    1175       995       1417   0      7.87
codes          high    pass 1     19249  483        420       19732  19072  5.78
codes          checked pass 1     19224  64         0         19288  19072  3.42
codes          no_skill pass 1    197    1029       970       1226   0      8.04
file           high    pass 1     19251  3338       3126      22589  19072  25.12
file           checked pass 1     19226  187        0         19413  19072  4.49
file           no_skill pass 1    199    5082       4816      5281   0      31.20
stream         high    pass 1     19257  676        544       19933  19072  6.40
stream         checked pass 1     19232  125        0         19357  19072  6.11
stream         no_skill pass 1    205    1902       1776      2107   0      12.55
namespace      high    fail 1     19248  11454      11396     30702  19072  79.42
  ERROR cocolog_failed
namespace      checked pass 2     38604  134        0         38738  38272  8.02
namespace      no_skill fail 1    196    766        708       962    0      6.77
  ERROR cocolog_failed
high                   8 7   8     154151 31154      30055     185305 152576 219.56
checked                8 8   10    192786 1130       0         193916 190976 44.02
no_skill               8 7   8     1735   21830      20705     23565  123    142.98
overall                24 22 26    348672 54114      50760     402786 343675 406.56
```

`checked` passed all eight, repairing `dcg` and `namespace` on its second
call. `high` and `no_skill` each passed seven: both failed `namespace`, the
one-namespace trap the guide names. `high` used 185 305 tokens against the
control's 23 565, about eight times as many, and the guide's one-shot
advantage over the control is not visible in this run; with repairs, the
guided `checked` mode passed every task in 10 calls and 193 916 tokens.
`namespace` is still the task a one-shot call gets wrong most often: the
model defines `member/2` and the library's own still answers. The tasks and
expected outputs are fixed and were checked against hand-written references.

## Files

| file | what it is |
|---|---|
| `bench.pl` | the runner and the totals |
| `tasks.pl` | the eight tasks, each spec read from its directory |
| `gen.pl` | one codegen run in a child, so the tool's CLI is never called here |
| `run.sh` | sets `COCOLOG_LIBRARY` and runs `bench.pl` |
| `<task>/spec.txt` | the requirement |
| `<task>/expected.txt` | the exact standard output |
| `<task>/reference.pl` | a hand-written reference program for the task |
| `html_template/page.html` | the template the first task loads |
| `file/lines.txt`, `stream/lines.txt` | the two tasks' line files |
