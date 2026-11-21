# Controlled English effect on Python codegen, the third run

Written and committed BEFORE the run, so the tests below were chosen
before any result of it was seen.

## Why

Two runs asked whether the controlled restatement after the requirement
makes Python's first program right more often than the requirement
alone, each with 60 trials an arm and a test chosen before it:

| run | controlled | requirement alone | p, one-sided |
|---|---|---|---|
| `controlled-english-python-20261121/` | 37/60 | 25/60 | 0.022 |
| `controlled-gzip-python-20261121/` | 34/60 | 30/60 | 0.29 |

The first found the effect and the second did not. This third run asks
the same question again.

## The run

- Lane: Python alone. Task: `mvccs_acid`, the clear text of reasoning
  1.14.1.
- Arms: `plain` (the requirement alone) and `controlled` (the
  requirement, then `mvccs_acid-python.controlled`, the note of both
  earlier runs, byte for byte).
- 60 trials an arm, 120 cells, the two arms shuffled together, seed
  `20261124` (a new one), up to 3 generator calls a cell.
- Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000; reasoning
  1.17.3.

## The tests

1. **This run alone (the primary test):** the controlled note makes the
   first program right more often than the requirement alone. Fisher's
   exact test, one-sided (controlled greater), on first-attempt passes;
   significant if p < 0.05.
2. **The three runs together:** the same hypothesis over the three runs,
   each run a stratum, by the Cochran-Mantel-Haenszel test, one-sided
   (controlled greater), with the continuity correction; significant if
   p < 0.05. It is chosen now, when the first two runs' results are
   known and this run's is not; the report says so beside it.

Everything else is described and not tested: the final pass, calls and
tokens, the error case's failures and how many first programs print
`error`. A refused cell counts as it comes; the report says how many.
