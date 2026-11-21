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
  note alone, reasoning 1.14's arm); and, in a run of its own,
  `reasoning` with every check the keyword reader found (1.15.4)
- Trials: 10 per lane and arm, seed `20261117`; up to 3 generator calls
  per cell; a case has 5 s in C and 10 s in the other languages
- 424 cells in seven runs, 811 generator calls, 8 119 201 tokens and 3 h 52 min of cell time: $33.88 at list prices, $34.23 with the translation phase and two requests sent again by hand.

"Reasoning" here is what the coding endpoint adds to the prompt's
context, not the model's own thinking. The model runs at effort `low` in
every arm. The notes are the endpoint's text, written before the runs by
`ir_prep.pl` and read from files: the benchmark calls no translator and
no model for them, and no translation token is in its figures.

## What the runs show

- **The pre-pass's checks change nothing measurable here, two of them or all of them.** For this requirement the pre-pass adds input and output checks and no "What the request is about" note, because the reasoner parsed no terms of the text. The keyword reader found 13 checks in the C requirement and 12 in each other lane's, and the endpoint's default sends only the first two, the generic input and output checks (341 characters; 404 for Python). In C and the three Prolog lanes the checks after them name the task: the 2-3-4 tree's split, versions, snapshots and the atomic commit. Python's do not. Run A, which ran the two reasoning arms together, gives 13/50 first-attempt passes for *+ reasoning* and 14/50 for *+ reasoning + IR* (p = 1.0). In the SWI-Prolog rerun, which ran all four arms together, *prompt forwarded* and *+ reasoning* both pass 0/10 at the first attempt. In cocolog without its guide, also run as one, they pass 7/10 and 5/10. **With every check, in a run of its own with the prompt forwarded, the arm passed 19/50 at the first attempt and the prompt forwarded 20/50 (p = 1.0).** In C it made 8 of 10 first programs fail to compile, against 1 of 10 (p = 0.005): they called `strdup`, which C17 does not declare.
- **The IR note helps the two Prolog lanes at the first attempt, and not C or Python.** In the clear-text run, IR only against the prompt forwarded: cocolog 9/10 against 3/10 (p = 0.020), SWI-Prolog 5/10 against 0/10 (p = 0.033), all four lanes 21/40 against 10/40 (p = 0.021). C and Python do not move. The SWI-Prolog rerun points the same way, 3/10 against 0/10 (p = 0.21). With fewer repair rounds the IR arm also spent fewer tokens and seconds in those lanes. cocolog without its guide, on its two-line prompt, does not show it: 6/10 against 7/10. These tests were not chosen before the run: read them as a description.
- **Checks in front of the IR do not add to it.** In the SWI-Prolog rerun the IR alone passed 3/10 at the first attempt and *+ reasoning + IR* 1/10, with 75 % more tokens. In cocolog without its guide, whose four arms also ran as one run, both passed 6/10 with about the same tokens. In C, Python and guided cocolog the two IR arms ran an hour apart, so they are not compared here.
- **The final pass hides the differences.** Almost every cell of C, Python, both cocolog lanes and SWI-Prolog passes within its three calls (final 38/40 to 40/40 a lane). What the arms change is how often the first program is right, and so the calls, tokens and seconds a correct program costs.
- **Two lines do the cocolog guide's work on this task.** With the two lines in its short prompt, cocolog without its guide passed 24/40 at the first attempt and 40/40 in the end. The guided lane passed 23/40 and 39/40, and spent 2 264 582 tokens where the lane without the guide spent 338 045, 6.7 times fewer (62 calls against 56). The rows come from runs on the same text but on different days, so read this as a description, not a paired test. Without both lines the same lane passed none of its 60 first attempts: 20 with neither line, 40 with the stream import alone.
- **cocolog without its guide spent fewer tokens than Python.** **Over its four arms it spent 338 045 tokens where Python spent 359 114, 6 % fewer, and fewer in three of the four arms** (all but *+ reasoning + IR*, 104 528 against 103 670). Its first program was right 24 times in 40 and Python's 13 times, so it needed 56 calls where Python needed 68. Python's rows come from runs on another day, so read this as a description.
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


## Why the IR note saves tokens in C and costs tokens in Python

The first run's report (`ir-mvccs-20261120.md`) showed fewer tokens for
the IR arm in C. The clear-text run shows the same in C, and more tokens
in Python, as the first run also did. The direction is the same in both
runs; only the size changed. Each total is its calls times its tokens a
call:

| lane and run | calls | tokens a call | tokens | change |
|---|---|---|---|---|
| **C, prompt forwarded → + IR only** | | | | |
| first run (3 cells an arm) | 6 → 4 | 6 677 → 7 162 | 40 062 → 28 647 | −28 % |
| clear-text run (10 cells an arm) | 19 → 15 | 6 819 → 7 738 | 129 559 → 116 067 | −10 % |
| **Python, prompt forwarded → + IR only** | | | | |
| first run (3 cells an arm) | 6 → 5 | 4 069 → 5 446 | 24 414 → 27 232 | +12 % |
| clear-text run (10 cells an arm) | 17 → 19 | 4 190 → 5 876 | 71 230 → 111 650 | +57 % |
| **all four arms, Python → cocolog without its guide** | | | | |
| clear-text runs (40 cells a lane) | 68 → 56 | 5 281 → 6 037 | 359 114 → 338 045 | −6 % |

The note makes every call dearer: it adds 1 435 prompt tokens to a call,
in C and in Python (measured on the cells of one call). It makes a cell
cheaper only by saving repair calls, and a repair call is expensive: it
sends the requirement, the note, the previous program and the failure
report, and the model writes a whole new program. In the clear-text run
a C cell of one call spent about 5 750 tokens and a cell of two calls
about 15 800; in Python about 3 800 and 10 200.

- **C:** the note made the first program right 5 times in 10 against 4,
  and the arm made 5 repair calls against 9. Its calls fell by 21 %, its
  tokens a call rose by 13 %, and its tokens fell by 10 %.
- **Python:** the first program was right 2 times in 10 against 3, and
  the arm made 9 repair calls against 7. Its calls rose by 12 %, its
  tokens a call by 40 %, and its tokens by 57 %.
- **The first run:** C saved two calls of six, which paid for the note;
  Python saved one, which did not. At three cells an arm one repair call
  more or less moves an arm's tokens by about 30 %, and the first run
  read the old text: its report says no difference in it is significant.

On this task the note does not make C's or Python's first program right
more often, and without that it only adds tokens. **The same rule makes
cocolog without its guide spend fewer tokens than Python: its first
program was right 24 times in 40 and Python's 13, so it made 56 calls
where Python made 68, and spent 6 % fewer tokens though each of its calls
spent 14 % more.**

## Every check against two

The endpoint's default sends the first two checks the keyword reader
finds. On this requirement those are the generic input and output
checks. Reasoning 1.15.4 lets `ir_prep.pl` write the note with every
check (`--checks all`): 13 in C and 12 in each other lane, 1 244 to
1 597 characters. The prompt forwarded and this arm ran together, ten
trials a lane and arm, 100 cells
(`ir-mvccs-checks-20261121/bench.jsonl`).

| lane | prompt forwarded: first · final | calls | tokens | + reasoning, every check: first · final | calls | tokens | p, first | + reasoning, two checks, earlier run: first |
|---|---|---|---|---|---|---|---|---|
| C | 5/10 · 9/10 | 14 | 85 567 | 2/10 · 10/10 | 22 | 169 342 | 0.350 | 4/10 (run A) |
| Python | 4/10 · 10/10 | 17 | 72 416 | 6/10 · 10/10 | 15 | 69 809 | 0.656 | 4/10 (run A) |
| cocolog | 3/10 · 10/10 | 19 | 700 836 | 4/10 · 10/10 | 16 | 595 015 | 1.000 | 5/10 (run A) |
| cocolog without its guide | 8/10 · 9/10 | 13 | 54 161 | 7/10 · 10/10 | 13 | 56 063 | 1.000 | 5/10 (1.15.3 rerun) |
| SWI-Prolog | 0/10 · 10/10 | 22 | 139 000 | 0/10 · 8/10 | 26 | 167 143 | 1.000 | 0/10 (1.15.1 rerun) |
| all five lanes | 20/50 · 48/50 | 85 | 1 051 980 | 19/50 · 48/50 | 92 | 1 057 372 | 1.000 | 18/50 |


p is Fisher's exact test, two-sided, on the first attempts of the two
arms of this run. The last column is the two-check arm of an earlier
run. It is there for comparison only, because its cells were not
shuffled with these.

- **No lane moves.** All five lanes pass 19/50 at the first attempt with
  every check and 20/50 with no note (p = 1.0). With two checks, the
  earlier runs gave 18/50. Both arms pass 48/50 within three calls.
- **C and the three Prolog lanes got the task's own checks, and did not
  gain.** Their notes name the 2-3-4 tree's split, versions, snapshots
  and the atomic commit. C fell from 5/10 to 2/10 at the first attempt
  (p = 0.35) and spent twice the tokens, 169 342 against 85 567. The
  three Prolog lanes moved by one cell or none.
- **In C, every check made the first program fail to compile.** 8 of its
  10 first programs did not compile, against 1 of 10 with no note
  (p = 0.005). Seven of the eight called `strdup` or `strtok_r`, which
  POSIX declares and the endpoint's `clang -std=c17` does not; the prompt
  asks for a C17 program. With every check, 7 of 10 first programs called
  `strdup`; with no note, 1 of 10. The run does not show which check made
  the model copy its strings that way.
- **Python got none of them.** Its twelve checks are Python's own
  phrasings of generic checks: integers, `max` and `min`, recursion
  depth, sort order, word splitting, and "An error the task names is
  raised with `raise ValueError("...")`". The cases expect the program
  to print the word `error`; the requirement does not say what an error
  prints. Python rose from 4/10 to 6/10 (p = 0.66), with 4 % fewer
  tokens. Its first programs failed the error case 6 times in 10 with no
  note and 3 times with every check, and another case once.
- **Checks that do not apply are sent too.** Every lane's note has
  checks for words and recursion, which this task does not have, and the
  Prolog lanes' note tells the program to check every allocation for
  NULL.

The compile errors, the calls of `strdup` and the failed cases come from
the first programs the run kept. These comparisons were not chosen before
the run: read them as a description.

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
| every-check run, 1.15.4 | 100 | 1 583 180 | 526 172 | $8.43 |
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
  requirement is not, so its about note is empty, and the default sent 2
  of the 12 checks the keyword reader found (13 for C): the two generic
  I/O checks, 341 characters (404 for Python). Every check, sent in a
  run of its own, changed nothing either.
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
whose notes were not used). `ir-mvccs-checks-20261121/`: `bench.jsonl`
(the every-check run), its notes (`*.reasoning`) and `ir-prep.jsonl`.
Commits `4816a72` (1.14.0), `3475b3f` (1.14.1), `7beae66` (1.15.0), `2f014be` (1.15.1), `7ff352a` (1.15.2), `b918c99` (1.15.3) and `8119689` (1.15.4); the report came in `426fbbc`, its page in `526d165` and its token section in `225ba6c`. The same report as a page, with its tables drawn: `ir-mvccs-clear-20261120.html`.
