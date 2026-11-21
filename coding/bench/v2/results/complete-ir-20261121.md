# The complete IR in Python, guided cocolog and SWI-Prolog, 2026-11-21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output
- Arms: `plain` (the requirement alone) and `ir` (the requirement, then
  `controlled/mvccs_acid.ir`, the complete IR, byte for byte)
- Two runs, seed `20261122`, reasoning 1.17.3:
  `complete-ir-python-20261121/` (Python, 60 trials an arm) and
  `complete-ir-prolog-20261121/` (cocolog with its guide and SWI-Prolog,
  20 trials a lane and arm), each arm shuffled with its lane's other
- 200 cells, 376 generator calls, 5 427 770 tokens, 1 h 40 min of cell
  time: **$18.37** at $2 and $10 per million input and output tokens

## The complete IR

The coding endpoint's IR note of `mvccs_acid` read 5 of the
requirement's 14 sentences and never the command table.
`controlled/mvccs_acid.ir` is the IR of every sentence of the controlled
restatement: 64 sentences, 68 IR terms, 20 039 characters (about 5 000
tokens), written by `ir_complete.pl` with no model from a form of the
restatement the translator reads right (`controlled/README.md`: 15
sentences as they stand, 33 of the model's rewrites, 16 by hand, every
reading read back by hand).

## The tests, and their answers

The tests were written down and committed before the runs (`cbc3c82`,
each run's README): in each lane, the complete IR makes the first program
right more often than the requirement alone; Fisher's exact test,
one-sided (ir greater), on first-attempt passes, each significant at
p < 0.05, and the report to say whether each passes 0.05 / 3 = 0.0167.

| lane | requirement alone: first | + complete IR: first | p, one-sided | the hypothesis |
|---|---|---|---|---|
| Python | 32/60 | **3/60** | 1.0 | not supported |
| cocolog, with its guide | 14/20 | 13/20 | 0.75 | not supported |
| SWI-Prolog | 0/20 | 0/20 | 1.0 | not supported |

**No test passes. The complete IR does not make the first program right
more often in any lane.** In Python it does the opposite, and by far:
3/60 against 32/60 (two-sided p = 3 × 10⁻⁹; a direction the test did not
ask about, so this is a description).

## Calls, tokens and the final pass

Described, not tested.

| lane | arm | final | calls | tokens |
|---|---|---|---|---|
| Python | requirement alone | 60/60 | 92 | 390 376 |
| Python | + complete IR | 59/60 | 127 | 1 721 122 (4.4 ×) |
| cocolog | requirement alone | 20/20 | 27 | 972 013 |
| cocolog | + complete IR | 20/20 | 27 | 1 223 870 (+26 %) |
| SWI-Prolog | requirement alone | 17/20 | 46 | 276 129 |
| SWI-Prolog | + complete IR | **10/20** | 57 | 844 260 (3.1 ×) |

The note adds about 5 000 tokens to every call and, with no first
program saved, pays for none of them. In SWI-Prolog fewer programs pass
at all within three calls: 10/20 against 17/20 (two-sided p = 0.041).

## How the first programs failed

- **Python, at the error case.** 53 of the 57 failing first programs
  with the complete IR failed the error case (case 9, which expects the
  word `error`), against 22 of 28 with the requirement alone; run on that
  case's input, 56 of the 57 print nothing (27 of 28). Only 5 of 60 first programs with the complete
  IR have the text `"error"`, against 33 of 60 with the requirement
  alone. The note holds the rule (`If a transaction is not active, it
  causes an error.` and its IR), as the controlled-English note does,
  and the controlled note raised that count to 39 of 60
  (`controlled-english-python-20261121.md`). Here the rule is three
  entries among 64, each under a long logical form. Every long or
  structured note so far has lowered the count below the requirement
  alone's: the terms 7/20, the outline 5/20, the concepts 3/20 and the old
  IR note 4/20, against 8/20 in the same run. The translator form also
  holds one sentence the controlled text does not, the model's rewrite
  `The program writes only the answers.`, and an error line may not read
  as an answer. Which of the two does it, the runs do not show.
- **Cocolog, at the first case, as always.** 6 of 7 failing first
  programs printed nothing for `v` (4 of 6 with the requirement alone),
  and 5 of 20 first programs matched a line's parts as codes (4 of 20). The four sentences on input
  that broke guided cocolog in the controlled-English note are in the
  complete IR too, and here they did not: 13/20 against 14/20.
- **SWI-Prolog, before the first case.** No first program passed in
  either arm: 12 and 15 did not load or run, and most of the rest
  printed the right output with an error on stderr. The lane's user message is the
  requirement alone, and its first replies often begin with prose before
  the code (`ir-mvccs-clear-20261120.md`); that, not the note, decides
  the first attempt here.

## What this says about the IR

The old IR note, read from 5 of 14 sentences, helped the two Prolog
lanes in one run (cocolog 9/10 against 3/10, SWI-Prolog 5/10 against
0/10) and did not help Python. The complete IR, read from all 64
sentences of the restatement, helps no lane and harms Python. Being
complete did not make the IR a better note: on this task the model does
better with the rule said once in plain or controlled English than with
every rule said as a logical form.

## Limits

- One task, one model. Python 60 trials an arm; the Prolog lanes 20.
- The translator form is the assistant's and the model's work over the
  restatement, which is the assistant's: another writer would make
  another text.
- Each run's arms were shuffled together; rows of different runs do not
  compare (the same prompt passes at different rates in different runs).
- One cell an arm met the safety classifier (Python `ir` trial 4,
  SWI-Prolog `plain` trial 17), each after its first program had failed:
  no test changes.

## Files

`complete-ir-python-20261121/` and `complete-ir-prolog-20261121/`: each
`README.md` (the test, written before the run, and its result),
`bench.jsonl` and the note. The note and its sources are in
`controlled/`. The same report as a page: `complete-ir-20261121.html`.
