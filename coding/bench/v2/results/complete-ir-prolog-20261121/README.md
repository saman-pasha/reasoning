# The complete IR in guided cocolog and SWI-Prolog

Written and committed BEFORE the run, so the tests below were chosen
before any result of them was seen. Its companion run, with the same
note in Python, is `../complete-ir-python-20261121/`.

## Why

The endpoint's IR note, partial as it was (5 of 14 sentences), was the
one note that helped at the first attempt: guided cocolog 9/10 against
3/10 and SWI-Prolog 5/10 against 0/10 in the clear-text run, and
SWI-Prolog 3/10 against 0/10 in its rerun. `controlled/mvccs_acid.ir`
(reasoning 1.17.3) is the IR of every sentence of the controlled
restatement. It holds the four sentences on input that broke guided
cocolog in the controlled-English note (`controlled-ablation-20261121/`),
each as its IR beside its English.

## The run

- Lanes: `cocolog` (with its guide) and `swipl`. Task: `mvccs_acid`, the
  clear text of reasoning 1.14.1.
- Arms: `plain` (the requirement alone) and `ir` (the requirement, then
  `mvccs_acid-LANG.ir`, each a copy of `controlled/mvccs_acid.ir`, byte
  for byte).
- 20 trials a lane and arm, 80 cells, all shuffled together, seed
  `20261122`, up to 3 generator calls a cell.
- Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000; reasoning
  1.17.3.

## The tests

- **Hypotheses:** in each lane, the complete IR makes the first program
  right more often than the requirement alone.
- **Tests:** Fisher's exact test, ONE-SIDED (ir greater), on
  first-attempt passes, one test a lane. Each significant if p < 0.05.
  With the companion run's test these are three; the report also says
  whether each passes p < 0.05 / 3 = 0.0167.

Everything else is described and not tested: the final pass, calls and
tokens, how the first programs failed (in cocolog, whether they match a
line's parts as codes). A refused cell counts as it comes; the report
says how many.

## The result (written after the run)

Fisher's exact test, one-sided (ir greater), on first-attempt passes:

- cocolog with its guide: `ir` 13/20, `plain` 14/20, **p = 0.75: not
  supported**;
- SWI-Prolog: `ir` 0/20, `plain` 0/20, **p = 1.0: not supported**.

In SWI-Prolog fewer programs passed at all within three calls, 10/20
against 17/20. The report is `../complete-ir-20261121.md`.
