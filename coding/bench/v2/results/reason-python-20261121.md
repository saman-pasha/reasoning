# v2 language comparison, mvccs_acid in Python: which reason_* note helps the first program, 2026-11-21

With a second run: the controlled text in C and in cocolog with and
without its guide (below).

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature (the model refuses one)
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output, 10 s a case
- Lane: Python alone
- Arms: `plain` (the prompt forwarded) and five notes after the
  requirement, in the user prompt: `controlled`, `terms`, `concepts`,
  `outline` and `ir` (below)
- Trials: 20 per arm, seed `20261117`, up to 3 generator calls per cell;
  reasoning 1.17.1 (commit `c2380ac`)
- 120 cells, 213 generator calls, 1 159 412 tokens (730 308 prompt,
  429 104 completion), 39 min of cell time: **$5.75** at $2 and $10 per
  million input and output tokens, every prompt token at the full price

## The question and the answer

Which of the reasoner's readers gives a note that makes Python's first
program right more often?

**None of the readers' notes does.** The note that did best is the
readers' INPUT, the requirement said again in controlled English: 12/20
first programs right, against 7/20 with no note (p = 0.21, Fisher's
exact test, two-sided). What the readers made of that text did not help:
`reason_text/2`'s terms 7/20, the outline of `reason_topics/2` 5/20,
`reason_concepts/2`'s list 3/20, and the translator's IR 3/20. No arm
differs from `plain` at p < 0.05.

## The notes

The readers read controlled English, and the requirement is not:
`reason_text/2` reads 0 of its 14 sentences, with the grammar, with the
tagger, and (one, wrongly) in live mode, so a note made from the
requirement as it is would be empty. So the notes come from a
**controlled restatement**, `coding/bench/v2/controlled/mvccs_acid.txt`:
64 sentences the grammar reads, written by hand from the requirement's
text alone, sentence by sentence, never from the cases or their expected
output. It says what the requirement says and nothing more: the
requirement says "error if T is not active" and never what an error
prints, so the restatement says `Every transaction that is not active
causes an error.` and not that the program prints `error`. What the
grammar cannot say is left out (one command's output on its own line).
`controlled/README.md` lists each requirement and its sentences.

`coding/bench/v2/reason_prep.pl` reads the restatement with the grammar
alone (no tagger, no saved rewrite, no model) and writes the notes; no
model is called for them, and no token of theirs is in any figure here.

| arm | what follows the requirement | characters |
|---|---|---|
| `plain` | nothing | 0 |
| `controlled` | the restatement itself, one sentence a line | 2 590 |
| `terms` | `reason_text/2`'s 66 terms, one a line: `may_stage(A, insertion) :- transaction(A), active(A)` | 2 387 |
| `concepts` | `reason_concepts/2`'s 94 concepts, each with its kind and its mentions: `transaction: class, mentioned 11 times` | 3 823 |
| `outline` | `reason_topics/2` and `reason_topic_lines/2`, a line a subject, 53 subjects | 3 836 |
| `ir` | the translator's IR note of the clear-text run, `ir-mvccs-clear-20261120/mvccs_acid-python.ir` | 3 307 |

The notes are the readers' output as it is: where a reading is the
grammar's and not the sentence's meaning, it stays (`Every transaction
that is active may commit.` is `may_commit/1`, and the outline says "is
may_commit").

## The results

All six arms ran in one run, shuffled together.

| arm | first | final | calls | tokens | tokens a call | p, first, against `plain` |
|---|---|---|---|---|---|---|
| `plain` | 7/20 | 20/20 | 34 | 138 268 | 4 067 | |
| **`controlled`** | **12/20** | 20/20 | **29** | 142 252 | 4 905 | 0.21 |
| `terms` | 7/20 | 20/20 | 34 | 201 427 | 5 924 | 1.0 |
| `outline` | 5/20 | 20/20 | 36 | 196 770 | 5 466 | 0.73 |
| `concepts` | 3/20 | 18/20 | 42 | 261 988 | 6 238 | 0.27 |
| `ir` | 3/20 | 20/20 | 38 | 218 707 | 5 755 | 0.27 |

First: the first program passed the eight repair cases and the two
held-out cases. Final: a program passed within three calls.

- **The restatement is the cheapest note.** With the most first
  programs right it made the fewest calls, 29, and spent 3 % more tokens
  than `plain` though each of its calls carried 2 590 characters more.
  Every other note spent 42 % to 89 % more than `plain`.
- **The readers' outputs do worse than the text they read.** Against
  `controlled`, `concepts` and `ir` pass 3/20 to its 12/20 (p = 0.008
  each) and `outline` 5/20 (p = 0.054). These comparisons were not chosen
  before the run, and fifteen pairs were there to choose from: with a
  correction for fifteen, none passes p < 0.05. Read them as a
  description.
- **Two `concepts` cells failed for the safety classifier, not for a
  program.** Both repair calls of each were refused, category
  `reasoning_extraction` (a repair prompt sends the model its own
  previous program), and the call sent again was refused again. Those
  are the run's 4 empty replies, and the reason `concepts` passes 18/20
  where every other arm passes 20/20.

## Why Python's first programs fail

Almost only at the error case (case 9: `r`, `i`, `c` and `a` of a
transaction that has not begun, and a second `b`; it expects `error`
five times). The cases expect the program to print the word `error`,
and the requirement does not say what an error prints.

| arm | first programs that failed | of them, at the error case | first programs with the text `"error"` |
|---|---|---|---|
| `plain` | 13 | 13 | 8/20 |
| `controlled` | 8 | 7 | 14/20 |
| `terms` | 13 | 13 | 7/20 |
| `outline` | 15 | 15 | 5/20 |
| `concepts` | 17 | 17 | 3/20 |
| `ir` | 17 | 16 | 4/20 |

Run on that case's input, 11 of `plain`'s 13 failing first programs
print nothing at all and 2 stop with a traceback; of the 7 `controlled`
first programs that failed the case, 6 print nothing and 1 prints `error`
once. So on this task a note
helps the first program when it makes the model print a word the
requirement never names. The restatement says "causes an error" in two
sentences of their own (`Every repeated_begin causes an error.`, `Every
transaction that is not active causes an error.`), and 14 of its 20
first programs print `error`. The terms say it as two rules among 66
(`cause(A,error):-transaction(A),\+active(A)`), and the concepts and the
outline put it among 94 and 53 lines.

This is the same failure the clear-text run found in Python (24 of its
27 failed first programs failed only the error case), so the other runs'
Python rows agree with `plain` here: 3/10 in the clear-text run, 4/10 in
the every-check run, 7/20 now.

## The controlled text in C and cocolog

A second run (`controlled-mvccs-20261121/`) put the same controlled
text after the requirement in C, in cocolog with its guide and in
cocolog without its guide, beside the requirement alone, 20 trials a
lane and arm: 120 cells, 171 calls, 3 076 591 tokens, 58 min of cell
time, $10.72. The note is the same file, byte for byte; it names no
language.

| lane | requirement alone: first | + controlled English: first | p | final | calls | tokens |
|---|---|---|---|---|---|---|
| C | 14/20 | 15/20 | 1.0 | 20/20 · 20/20 | 27 · 25 | 152 363 · 164 971 |
| cocolog, with its guide | 15/20 | **2/20** | **0.00007** | 20/20 · 19/20 | 25 · 42 | 903 162 · 1 580 274 |
| cocolog, without its guide | 14/20 | 15/20 | 1.0 | 20/20 · 20/20 | 27 · 25 | 122 062 · 153 759 |

(Final, calls and tokens: the requirement alone · with the controlled
text.)

- **C and cocolog without its guide do not move.** One cell in twenty
  each way, with 8 % and 26 % more tokens. No C program called `strdup`
  in either arm, and one in each did not compile: the compile errors of
  the every-check run came from its checks, not from a note as such.
- **In cocolog with its guide the controlled text made the first program
  much worse**: 2/20 against 15/20, with 42 calls against 25 and 75 %
  more tokens. 12 of its 18 failing first programs split each line with
  `split_string/4`, which gives strings, and then match each command as
  a list of codes (`mv_cmd([[0'b], N])`), so no command matches and the
  program prints nothing; with the requirement alone, 3 of 20 programs
  did that. Most of the passing programs (12 of 17 in the two arms) turn
  the parts into atoms and match `[b, T]`. 5 more failed the error case and printed nothing there;
  with the requirement alone, none did. The note says nothing of strings,
  codes or how to read a line, and the run does not show why it moves
  the model away from what the guide teaches.
- **The same prompt passed more often in this run than in the earlier
  ones.** With the requirement alone, cocolog with its guide passed 15/20
  here and 3/10 in each of the two runs before it (p = 0.010 against the
  two together), and C 14/20 against 4/10 and 5/10. The prompts are the
  same text byte for byte (the kept `spec.txt` of both runs, and the
  runner's `plain` arm did not change). Rows of different runs do not
  compare; only arms shuffled together in one run do.

### Why it breaks cocolog with its guide

A third run, `controlled-ablation-20261121/` (50 cells, $9.03, its
README has the table), took the note apart in guided cocolog, ten
trials an arm: the requirement alone 6/10 at the first attempt, the
controlled note **0/10** (p = 0.011), the requirement said again in plain
English 5/10, the note with its quoted words unquoted 1/10, and **the note
without its four sentences on input 6/10** (p = 0.011 against the whole
note). So the cause is those four sentences: `Mvccs reads a line.`,
`Every line holds a command.`, `Every line that is blank is ignored.`,
`Every transaction_name is a word.` With them, 8 of 10 first programs
match the parts of a line as codes; without them, 1 of 10. Neither the
quotes nor a second statement as such do it. The run does not show which
of the four sentences does it, or why. These comparisons were not chosen
before the run: read them as a description.

A test of `controlled` against `plain` alone, written before its run,
with 60 trials an arm, is `controlled-english-python-20261121.md`: 37/60
against 25/60, Fisher one-sided p = 0.022, significant.

So the controlled text helps where the first program's failure is the
unnamed `error` (Python, not significantly), changes nothing in C and in
cocolog without its guide, and harms cocolog with its 19 000-token
guide.

## Limits of this run


- One task. In Python the notes help or hurt through one word the cases
  expect; a task whose failures are not one unnamed output would test
  the readers in another way. Only the controlled text ran in the other
  lanes.
- Twenty trials an arm. A difference of five cells in twenty is inside
  the noise (p = 0.21).
- The restatement was written by hand, by the assistant that ran the
  benchmark, before the run and from the requirement alone. Its cost is
  not counted, and another writer would make another text. It is a
  test of what a controlled text gives the model, not of a reader.
- The `ir` note is the translator's reading of the requirement as it is
  (4 to 6 of its 14 sentences), not of the restatement.
- The notes sit in the user prompt, not in the system prompt as the
  coding endpoint puts its notes.
- The model takes no temperature; trials are samples of a generator that
  is not deterministic.

## Files

`reason-python-20261121/`: `bench.jsonl` (the run), the five notes
(`mvccs_acid-python.controlled`, `.terms`, `.concepts`, `.outline`, and
the `.ir` copied from `ir-mvccs-clear-20261120/`) and `reason-prep.jsonl`
(the notes' sizes and the reasoning version that wrote them). The second
run is `controlled-mvccs-20261121/`: `bench.jsonl`, the notes it wrote
(only `.controlled` ran) and `reason-prep.jsonl`. The
restatement is `coding/bench/v2/controlled/mvccs_acid.txt`; the code is
1.17.1's (`5da3c6e`). The same report as a page, with its tables drawn:
`reason-python-20261121.html`.
