# v2 language comparison, mvccs_acid: what the reasoning library adds to a coding prompt, 2026-11-20 to 21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature (the model refuses one)
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output
- Lanes: C, Python, cocolog with its guide, cocolog without its guide
  (`cocolog_noguide`, a short prompt), SWI-Prolog (a short prompt)
- Arms: `plain` (the prompt forwarded), `reasoning` (the endpoint's
  reasoning pre-pass: its checks and its "What the request is about"
  note), `reasoning_ir` (those and the translator's IR note), `ir` (the IR
  note alone, reasoning 1.14's arm)
- Trials: 10 per lane and arm, seed `20261117`; up to 3 generator calls
  per cell; a case has 5 s in C and 10 s in the other languages
- 324 cells in six runs, 634 generator calls, 6 009 849 tokens and 2 h 59 min of cell time: $25.46 at list prices, $25.81 with the translation phase and two requests sent again by hand.

"Reasoning" here is what the coding endpoint adds to the prompt's
context, not the model's own thinking. The model runs at effort `low` in
every arm. The notes are the endpoint's text, written before the runs by
`ir_prep.pl` and read from files: the benchmark calls no translator and
no model for them, and no translation token is in its figures.

## What the runs show

- **The pre-pass's checks alone change nothing measurable here.** For this requirement the pre-pass adds two input and output checks (341 characters; 404 for Python) and no "What the request is about" note, because the reasoner parsed no terms of the text. Run A, which ran the two reasoning arms together, gives 13/50 first-attempt passes for *+ reasoning* and 14/50 for *+ reasoning + IR* (p = 1.0). In the SWI-Prolog rerun, which ran all four arms together, *prompt forwarded* and *+ reasoning* both pass 0/10 at the first attempt. In cocolog without its guide, also run as one, they pass 7/10 and 5/10.
- **The IR note helps the two Prolog lanes at the first attempt, and not C or Python.** In the clear-text run, IR only against the prompt forwarded: cocolog 9/10 against 3/10 (p = 0.020), SWI-Prolog 5/10 against 0/10 (p = 0.033), all four lanes 21/40 against 10/40 (p = 0.021). C and Python do not move. The SWI-Prolog rerun points the same way, 3/10 against 0/10 (p = 0.21). With fewer repair rounds the IR arm also spent fewer tokens and seconds in those lanes. cocolog without its guide, on its two-line prompt, does not show it: 6/10 against 7/10. These tests were not chosen before the run: read them as a description.
- **Checks in front of the IR do not add to it.** In the SWI-Prolog rerun the IR alone passed 3/10 at the first attempt and *+ reasoning + IR* 1/10, with 75 % more tokens. In cocolog without its guide, whose four arms also ran as one run, both passed 6/10 with about the same tokens. In C, Python and guided cocolog the two IR arms ran an hour apart, so they are not compared here.
- **The final pass hides the differences.** Almost every cell of C, Python, both cocolog lanes and SWI-Prolog passes within its three calls (final 38/40 to 40/40 a lane). What the arms change is how often the first program is right, and so the calls, tokens and seconds a correct program costs.
- **Two lines do the cocolog guide's work on this task.** With the two lines in its short prompt, cocolog without its guide passed 24/40 at the first attempt and 40/40 in the end. The guided lane passed 23/40 and 39/40, and spent 2 264 582 tokens where the lane without the guide spent 338 045, 6.7 times fewer (62 calls against 56). The rows come from runs on the same text but on different days, so read this as a description, not a paired test. Without both lines the same lane passed none of its 60 first attempts: 20 with neither line, 40 with the stream import alone.
- **SWI-Prolog's low first-attempt rate is partly its prompt's.** Its user message is the requirement alone. Every cocolog lane's begins "Write a complete cocolog program for this requirement." In the SWI-Prolog rerun, 22 of the 40 first replies began with English design notes before the code and did not load; no first reply of either cocolog lane did. So the gap at the first attempt between SWI-Prolog and cocolog without its guide, 4/40 against 24/40, is not only a gap between the two languages.

## The results, lane by lane

First attempt: the first program passed the eight repair cases and the
two held-out cases. Final: a program passed within three calls. The run
column names where a row comes from; only rows of one run were shuffled
together.

| arm | first attempt | final | calls / cell | prompt tokens | completion tokens | s / cell | run |
|---|---|---|---|---|---|---|---|
| **C** | | | | | | | |
| prompt forwarded | 4/10 | 10/10 | 1.90 | 54 506 | 75 053 | 37.5 | 1.14.1 run |
| + reasoning | 4/10 | 9/10 | 2.00 | 56 602 | 72 494 | 38.4 | run A (1.15.0) |
| + reasoning + IR | 1/10 | 10/10 | 2.10 | 95 877 | 85 507 | 46.1 | run A (1.15.0) |
| + IR only | 5/10 | 9/10 | 1.50 | 55 898 | 60 169 | 29.9 | 1.14.1 run |
| **Python** | | | | | | | |
| prompt forwarded | 3/10 | 10/10 | 1.70 | 38 340 | 32 890 | 18.4 | 1.14.1 run |
| + reasoning | 4/10 | 10/10 | 1.60 | 36 547 | 36 017 | 20.9 | run A (1.15.0) |
| + reasoning + IR | 4/10 | 10/10 | 1.60 | 59 575 | 44 095 | 27.9 | run A (1.15.0) |
| + IR only | 2/10 | 10/10 | 1.90 | 73 350 | 38 300 | 21.3 | 1.14.1 run |
| **cocolog, with its guide** | | | | | | | |
| prompt forwarded | 3/10 | 9/10 | 2.00 | 670 794 | 63 519 | 45.2 | 1.14.1 run |
| + reasoning | 5/10 | 10/10 | 1.50 | 492 476 | 37 134 | 25.5 | run A (1.15.0) |
| + reasoning + IR | 6/10 | 10/10 | 1.60 | 557 812 | 38 553 | 28.4 | run A (1.15.0) |
| + IR only | 9/10 | 10/10 | 1.10 | 375 647 | 28 647 | 21.0 | 1.14.1 run |
| **cocolog, no guide** | | | | | | | |
| prompt forwarded | 7/10 | 10/10 | 1.30 | 23 065 | 34 885 | 21.0 | no-guide rerun (1.15.3) |
| + reasoning | 5/10 | 10/10 | 1.50 | 35 640 | 35 233 | 21.7 | no-guide rerun (1.15.3) |
| + reasoning + IR | 6/10 | 10/10 | 1.40 | 60 370 | 44 158 | 27.0 | no-guide rerun (1.15.3) |
| + IR only | 6/10 | 10/10 | 1.40 | 61 993 | 42 701 | 24.9 | no-guide rerun (1.15.3) |
| **SWI-Prolog** | | | | | | | |
| prompt forwarded | 0/10 | 8/10 | 2.40 | 79 483 | 64 123 | 43.8 | SWI rerun (1.15.1) |
| + reasoning | 0/10 | 10/10 | 2.30 | 76 584 | 65 746 | 44.2 | SWI rerun (1.15.1) |
| + reasoning + IR | 1/10 | 10/10 | 2.10 | 98 868 | 69 021 | 46.4 | SWI rerun (1.15.1) |
| + IR only | 3/10 | 10/10 | 1.70 | 66 612 | 29 414 | 18.8 | SWI rerun (1.15.1) |


## Why cocolog with the IR failed every cell in the first run

The first run (reasoning 1.14.0, `ir-mvccs-20261120.md`) failed held-out
case 8 five times, three of them in all three cocolog IR cells. The text
said "a deletion of an absent key is ignored" and did not say absent from
what. Case 8 run on every kept attempt showed that the view reading came
only from the Prolog lanes: 0 of 19 C and Python attempts, 5 of 15
Prolog attempts. The Prolog programs kept each view as a sorted set and
either ignored the deletion when it was staged or computed the commit as
view minus snapshot. All four IR notes held only the rule that leads
there; the sentence that the last committer wins was among those the
translator did not read. Since 1.14.1 the text says that a transaction
keeps one staged change per key and that the commit applies each one to
the latest version. On that text no attempt of any lane read the view
again.

## Two lines a model not trained on cocolog needs

cocolog is this project's own Prolog, and no model was trained on it.
Without the guide, `claude-sonnet-5-5` writes the dialect it knows best,
SWI-Prolog 7, and said as much in a repair reply: "I can't see which
Prolog dialect cocolog is." cocolog runs nearly all of that code. Two of
its defaults are not SWI-Prolog 7's. Without the lines that change them,
no first attempt passed even the first case:

```prolog
:- set_prolog_flag(double_quotes, string).
:- use_module(library(stream)).
```

| line | what the model writes | what cocolog does without the line |
|---|---|---|
| `double_quotes` | clause heads such as `cmd(["v"])`, matched against the strings `split_string/4` returns | reads `"v"` as the list of codes `[118]`, its default; no head matches, and the program prints nothing or its error line |
| `library(stream)` | `read_line_to_string/2`, `get_char/1`, `get_code/1` | does not load its stream predicates by default; each call is an unknown procedure |

The cocolog guide teaches both, which is why the guided lane never met
them. The no-guide prompt was given one line at a time:

| short prompt | arms | cells | first attempt | final | calls / cell | tokens |
|---|---|---|---|---|---|---|
| 1.15.0: neither line | + reasoning, + reasoning + IR | 20 | 0/20 | 0/20 | 3 | 436 084 |
| 1.15.2: the stream import | all four | 40 | 0/40 | 18/40 | 2.7 | 564 678 |
| 1.15.3: both lines | all four | 40 | 24/40 | 40/40 | 1.4 | 338 045 |


Of the 16 first attempts that failed on the 1.15.3 prompt, 10 printed the expected output and failed only because stderr held load warnings (singleton variables 9, clauses not together 1): the benchmark passes a case only when stderr is empty, in every lane, and SWI-Prolog prints the same warnings. 3 printed the expected output with a load error: SWI-Prolog's `arithmetic_function/1`, which cocolog does not have, a syntax error, and a clause for `(>=)/2`. 3 printed a wrong answer. Each of the 16 cells passed at its second attempt.

The first no-guide prompt (1.15.0) said only that the program is cocolog. In run A its 20 cells failed all 60 attempts: 46 programs stopped at an unknown stream predicate (`read_line_to_string/2`, `get_char/1`, `get_code/1`, `read_line_to_codes/2`), 9 printed nothing, 4 ended with main/0 failing, and 1 reply was empty. 1.15.2 added the stream import, and no program stopped at a stream predicate again. But every first attempt still failed case 1, whose input is the one command `v`: 26 printed nothing and 14 printed `error`, because no clause head written with `"v"` matched the string that was read. In the end 18 of 40 cells passed, none at the first attempt. Run offline on 12 of those first attempts, the double_quotes flag alone made 9 of them pass all ten cases. 1.15.3 added that flag as the second line.

## Fixes made on the way

- 1.14.0: the IR check shows the logical form, and asks for each word's
  role.
- 1.14.1: the task's text states which deletion a commit applies. No
  expected output changed; runs before and after are not comparable.
- 1.15.1: a reply with no text is sent again, once, and counted. The
  model's safety classifier refused three repair attempts of the some 400
  calls made by then, category `reasoning_extraction`; two came back as a thinking
  block and no text. The same requests sent again were answered. The
  SWI-Prolog lane was run again under this fix and met no empty reply:

| arm | before the fix: first · final | 1.15.1 rerun: first · final |
|---|---|---|
| prompt forwarded | 0/10 · 8/10 | 0/10 · 8/10 |
| + reasoning | 0/10 · 9/10 | 0/10 · 10/10 |
| + reasoning + IR | 3/10 · 10/10 | 1/10 · 10/10 |
| + IR only | 5/10 · 9/10 | 3/10 · 10/10 |


- 1.15.2 and 1.15.3: the no-guide prompt names the two lines above.

## What it cost

At $2 and $10 per million input and output tokens, every prompt token at
the full price (an upper bound: some were cache reads). The translation
phase is listed apart and is in no benchmark figure.

| run | cells or calls | prompt tokens | completion tokens | cost |
|---|---|---|---|---|
| **the benchmark** | | | | |
| first run, 1.14.0 (old text) | 24 | 353 139 | 100 423 | $1.71 |
| clear-text run, 1.14.1 | 80 | 1 399 904 | 390 788 | $6.71 |
| run A, 1.15.0 (reasoning arms) | 100 | 1 712 365 | 600 656 | $9.43 |
| SWI-Prolog rerun, 1.15.1 | 40 | 321 547 | 228 304 | $2.93 |
| no-guide rerun, 1.15.2 (the stream import) | 40 | 362 666 | 202 012 | $2.75 |
| no-guide rerun, 1.15.3 (both lines) | 40 | 181 068 | 156 977 | $1.93 |
| **not in the benchmark** | | | | |
| translation, 1.14.0 (first batch, discarded) | 11 calls | 14 394 | 2 563 | $0.05 |
| translation, 1.14.0 | 9 calls | 17 035 | 1 310 | $0.05 |
| translation, 1.14.1 (the notes used) | 6 calls | 22 114 | 3 747 | $0.08 |
| translation, 1.15.0 (notes not used) | 6 calls | 16 124 | 3 393 | $0.07 |
| two SWI requests sent again by hand | 2 calls | 13 623 | 6 778 | $0.10 |


## Limits of these runs

- Ten trials a cell. A difference of two or three cells in ten is inside
  the noise; only the clear-text run's pooled IR effect passes p < 0.05.
- The arms of C, Python and guided cocolog come from two runs an hour
  apart (`plain` and `ir` in one, the two reasoning arms in the other).
  SWI-Prolog and cocolog without its guide ran all four arms in one run
  each.
- One task. The reasoning pre-pass reads controlled English; this
  requirement is not, so its checks are generic (two I/O checks, 341
  characters; 404 for Python) and its about note is empty.
- The notes sit in the user prompt, not in the system prompt as the
  endpoint puts them.
- The lanes' prompts differ in more than the language: the SWI-Prolog
  lane's user message is the requirement alone, and every cocolog lane's
  begins with an instruction to write the program.
- The translator read 4 to 6 of the 14 sentences. The IR note never held
  the command table, which holds most of the rules.
- No case checks that the program uses a B-tree.
- The model takes no temperature; trials are samples of a generator that
  is not deterministic.

## Files

`ir-mvccs-clear-20261120/`: `bench.jsonl` (the clear-text run, `plain`
and `ir`), `bench-reasoning.jsonl` (run A, the two reasoning arms),
`bench-swipl-1.15.1.jsonl`, `bench-noguide-1.15.2.jsonl`,
`bench-noguide-1.15.3.jsonl`, the notes (`*.ir`, `*.reasoning`), and the
translation phase's rows (`ir-prep.jsonl`; `ir-prep-rerun-1.15.0.jsonl`,
whose notes were not used). Commits `4816a72` (1.14.0), `3475b3f` (1.14.1), `7beae66` (1.15.0), `2f014be` (1.15.1), `7ff352a` (1.15.2), `b918c99` (1.15.3) and the commit that adds this report.
