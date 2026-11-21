# Controlled English effect on Python codegen

Written and committed BEFORE the run, so the test below was chosen
before any result of it was seen.

## Why

In `reason-python-20261121/` the controlled restatement after the
requirement made Python's first program right 12 times in 20, against 7
in 20 with the requirement alone (Fisher p = 0.21, two-sided). That arm
was the best of five notes, and twenty trials an arm cannot tell a gap
of five cells from chance. This run asks the one question again, with
three times the trials, in a run of its own.

## The run

- Lane: Python alone. Task: `mvccs_acid`, the clear text of reasoning
  1.14.1, repair cases 1-5, 7, 9, 10, held-out cases 6 and 8.
- Arms: `plain` (the requirement alone) and `controlled` (the
  requirement, then `mvccs_acid-python.controlled`, the same note as in
  `reason-python-20261121/`, byte for byte).
- 60 trials an arm, 120 cells, the two arms shuffled together, seed
  `20261121` (a new one), up to 3 generator calls a cell.
- Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000, no
  temperature; reasoning 1.17.2.

## The test

- **Hypothesis:** the controlled note makes the first program right
  more often than the requirement alone.
- **Measure:** first-attempt passes (the first program passes the eight
  repair cases and the two held-out cases), `controlled` against
  `plain`.
- **Test:** Fisher's exact test, ONE-SIDED (controlled greater), on the
  2x2 table of first-attempt passes and failures. The effect is
  significant if p < 0.05.
- With 60 trials an arm, this test finds a true gap of 35 % against 60 %
  about four times in five.

Everything else is described and not tested: the final pass, calls and
tokens per arm, the error case's failures among the first programs, and
how many first programs print the word `error`. A cell the model
refuses (an empty reply sent again and refused again) counts as it
comes, a failure where its program fails; the report says how many.
