# The model-written controlled note in Python codegen

Written and committed BEFORE the run, so the test below was chosen
before any result of it was seen.

## Why

Three runs found that the requirement said again in controlled English,
after the requirement, makes Python's first program right more often
than the requirement alone: 104/180 against 79/180 over the three
(Cochran-Mantel-Haenszel one-sided p = 0.0058,
`../controlled-english-python-3-20261121.md`). In each of them the
restatement was the same text, written by hand
(`coding/bench/v2/controlled/mvccs_acid.txt`).

Since reasoning 1.18.0 the coding endpoint makes that note itself: a
model writes the restatement (`reason_restate/3` in live mode), and the
grammar keeps each sentence it reads. This run asks whether THAT note,
with no hand-written text in it, has the same effect.

## The note

`mvccs_acid-python.controlled`, made ONCE by
`coding/bench/v2/restate_prep.pl` with the endpoint's own
`ep_controlled/6`, before this README, and used as it came: no sentence
was edited, added or taken out, and no second note was made to choose
from. It is byte for byte what the endpoint would put after this
requirement.

- Model `claude-sonnet-5-5` (the benchmark's own), through
  `REASON_LIVE_*`, effort `low`; 3 calls, 9 213 prompt and 3 411
  completion tokens, 20 s (`restate-prep.jsonl`; the rounds, prompts and
  replies in `restate-rounds.log`). This cost is the note's, made once a
  task, and is not in the benchmark's figures.
- 57 sentences, all read by the grammar alone; 2 967 characters, where
  the hand-written note had 64 sentences and 2 590.

## The run

- Lane: Python alone. Task: `mvccs_acid`, the clear text of reasoning
  1.14.1.
- Arms: `plain` (the requirement alone) and `controlled` (the
  requirement, then the model-written note).
- 60 trials an arm, 120 cells, the two arms shuffled together, seed
  `20261125` (a new one), up to 3 generator calls a cell.
- Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000; reasoning
  1.18.1 (1.18.0's endpoint and readers, with `restate_prep.pl` added; the
  note was made by that script on 1.18.0, the same code).

## The test

1. **The model-written note makes the first program right more often than
   the requirement alone.** Fisher's exact test, one-sided (controlled
   greater), on first-attempt passes; significant if p < 0.05.

Everything else is described and not tested: the final pass, calls and
tokens, the error case's failures and how many first programs print
`error`, and how this run's rates stand beside the three hand-written
runs' (across runs, which drift; not a test). A refused cell counts as it
comes; the report says how many.
