# The model-written controlled note in Python codegen, 2026-11-21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output, 10 s a case
- Lane: Python alone. Arms, shuffled together: `plain` (the requirement
  alone) and `controlled` (the requirement, then the note the coding
  endpoint of reasoning 1.18.0 writes itself: a model's restatement, no
  hand-written text)
- 60 trials an arm, seed `20261125`, up to 3 generator calls per cell;
  reasoning 1.18.1
- 120 cells, 232 generator calls, 1 218 359 tokens, 46 min of cell time:
  **$6.35**; the note itself 3 calls, 12 624 tokens: $0.05

## The test, and its answer

Written down and committed before the run (`f2929b2`,
`model-controlled-python-20261121/README.md`): Fisher's exact test,
one-sided (the note greater), on first-attempt passes, significant at
p < 0.05.

| arm | first attempt | p, one-sided | the hypothesis |
|---|---|---|---|
| model-written note | 7/60 | 0.997 | **not supported** |
| requirement alone | 18/60 | | |

**The model-written note made Python's first program right less often,
not more.** That direction was not tested before the run: two-sided
p = 0.023, described.

## The note

`model-controlled-python-20261121/mvccs_acid-python.controlled`, made once
by `restate_prep.pl` with the endpoint's own `ep_controlled/6` and used as
it came: `claude-sonnet-5-5` said the requirement again in three calls,
and the grammar kept 57 sentences (2 967 characters). The hand-written
note of the three earlier runs had 64 (2 590 characters).

## The results

| arm | first | final | calls | tokens | cost |
|---|---|---|---|---|---|
| requirement alone | 18/60 | 60/60 | 105 | 490 755 | $2.81 |
| model-written note | 7/60 | 58/60 | 127 | 727 604 | $3.54 |

The note cost 21 % more calls and 48 % more tokens. Of the two cells
that did not pass in the end, one failed its three calls and one was
refused twice by the safety classifier (`reasoning_extraction`) after a
first program that failed.

## How the first programs failed

| arm | pass | case 7, the error case | a load error | another case |
|---|---|---|---|---|
| requirement alone | 18 | 27 | 14 | 1 |
| model-written note | 7 | **51** | 0 | 2 |

Case 7 expects the word `error` five times, a word the requirement never
names (it says "error if T is not active"). With the note, **7 first
programs of 60 contain the text `error` at all, against 27 of 60 without
it**, and every program that failed case 7 printed nothing there. The 14
load errors without the note were programs that did not compile: an
unterminated string (8), or `≥` and `→` written in the code (3 each).

The two notes say different things about output. The model's note says
which commands print and what, and of an error only "causes an error":

```text
Every r_command that names an inactive_transaction causes an error.
Every p_command that names an empty_view prints nothing.
Multiversion_Tree does not print a prompt.
Multiversion_Tree does not print a debug_output.
```

The hand-written note says "causes an error" too (`Every transaction
that is not active causes an error.`), has the same two last lines, and
also has **`Every command prints an answer.`**,
which the model's note does not have and which the requirement does not
say in those words (`b`, `i` and `d` print nothing when they succeed).
That one sentence is the plainest difference on the error case, but no
run here took it out or put it in: it is a reading of the counts, not a
tested cause.

## Beside the hand-written note's runs

Across runs, which drift, and not a test:

| run | the note | first, with it | first, without |
|---|---|---|---|
| `controlled-english-python-20261121/` | hand-written | 37/60 | 25/60 |
| `controlled-gzip-python-20261121/` | hand-written | 34/60 | 30/60 |
| `controlled-english-python-3-20261121/` | hand-written | 33/60 | 24/60 |
| this run | model-written | **7/60** | 18/60 |

The requirement alone did worse here than in any earlier run (18/60;
14 of its failures were programs that did not compile), and the
model-written note did far worse than the hand-written one ever did.

## What this means for the endpoint

Since reasoning 1.18.0 the coding endpoint sends exactly this kind of
note for C and Python by default (`CODING_ENDPOINT_CONTROLLED_LANGS`,
`c,python`). The gain measured before was the hand-written note's; on
this task the note the endpoint writes harms Python's first program.
`CODING_ENDPOINT_CONTROLLED_LANGS=none` sends none.

## Limits

- One task, one model, one language, one note: a second note the model
  wrote could read differently, and no second one was made to choose
  from.
- The cause is read from the counts; no arm took a sentence out or put
  one in.
- One refused cell counts as it came.

## Files

`model-controlled-python-20261121/`: `README.md` (the test, written
before the run, and its result), `bench.jsonl`,
`mvccs_acid-python.controlled` (the note), `restate-prep.jsonl` (its
calls and tokens) and `restate-rounds.log` (its prompts and replies).
