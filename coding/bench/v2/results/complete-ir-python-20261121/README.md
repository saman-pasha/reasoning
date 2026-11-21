# The complete IR in Python

Written and committed BEFORE the run, so the test below was chosen
before any result of it was seen. Its companion run, with the same note
in guided cocolog and SWI-Prolog, is `../complete-ir-prolog-20261121/`.

## Why

The endpoint's IR note of `mvccs_acid` read 5 of the requirement's 14
sentences, never the command table, and in Python it did not help (2/10
against 3/10, and 3/20 against 7/20). `controlled/mvccs_acid.ir`
(reasoning 1.17.3) is the IR of every sentence of the controlled
restatement: 64 sentences, 68 IR terms, 20 039 characters. This run asks
whether the complete IR helps Python where the partial one did not.

## The run

- Lane: Python alone. Task: `mvccs_acid`, the clear text of reasoning
  1.14.1.
- Arms: `plain` (the requirement alone) and `ir` (the requirement, then
  `mvccs_acid-python.ir`, a copy of `controlled/mvccs_acid.ir`, byte for
  byte).
- 60 trials an arm, 120 cells, the two arms shuffled together, seed
  `20261122`, up to 3 generator calls a cell.
- Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000; reasoning
  1.17.3.

## The test

- **Hypothesis:** the complete IR makes the first program right more
  often than the requirement alone.
- **Test:** Fisher's exact test, ONE-SIDED (ir greater), on first-attempt
  passes. Significant if p < 0.05. This and the two tests of the
  companion run are three tests; the report also says whether each
  passes p < 0.05 / 3 = 0.0167.

Everything else is described and not tested: the final pass, calls and
tokens, the error case's failures, how many first programs print
`error`. A refused cell counts as it comes; the report says how many.
