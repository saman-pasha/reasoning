# Controlled English effect on Python codegen: the third run, and the three together, 2026-11-21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output, 10 s a case
- Lane: Python alone. Arms: `plain` (the requirement alone) and
  `controlled` (the requirement, then the controlled restatement,
  2 590 characters, the same note in all three runs, byte for byte)
- This run: 60 trials an arm, the arms shuffled together, seed
  `20261124`, reasoning 1.17.3; 120 cells, 191 generator calls, 898 638
  tokens, 36 min of cell time: **$4.90**

## The tests, and their answers

Written down and committed before the run (`0c4526f`,
`controlled-english-python-3-20261121/README.md`).

| test | controlled | requirement alone | p, one-sided | answer |
|---|---|---|---|---|
| 1. this run alone, Fisher's exact test | 33/60 | 24/60 | 0.072 | not significant |
| 2. the three runs together, Cochran-Mantel-Haenszel | 104/180 | 79/180 | **0.0058** | **significant** |

The second test takes each run as a stratum: it compares the two arms
within each run, so the drift between runs (the requirement alone passed
25/60, 30/60 and 24/60) does not confuse it. It was chosen when the first
two runs' results were known and this run's was not: z = 2.52, the
observed count 104 against the 91.5 expected with no effect, variance
22.6, the continuity correction applied.

**Over the three runs the controlled restatement makes Python's first
program right more often: 58 % against 44 %, a common odds ratio of
1.75.** The single runs vary around that, as twenty-odd cells of sixty
do:

| run | seed | controlled | requirement alone | p, one-sided, the run alone |
|---|---|---|---|---|
| `controlled-english-python-20261121/` | 20261121 | 37/60 | 25/60 | 0.022 |
| `controlled-gzip-python-20261121/` | 20261123 | 34/60 | 30/60 | 0.29 |
| this run | 20261124 | 33/60 | 24/60 | 0.072 |
| the three | | **104/180** | **79/180** | **0.0058** (CMH) |

Every run points the same way; the first overstated the gain (+12
cells), the second understated it (+4), and the third is near the
three's mean (+9).

## Calls and tokens

Described, not tested.

| | controlled | requirement alone | change |
|---|---|---|---|
| this run: calls | 93 | 98 | −5 % |
| this run: tokens | 469 912 | 428 726 | +10 % |
| the three runs: calls | 266 | 290 | −8 % |
| the three runs: tokens | 1 318 506 | 1 251 730 | +5 % |

The note saves repair calls, about one in twelve, and costs about 900
prompt tokens on every call; over the three runs the two nearly cancel,
and the arm spends 5 % more tokens for 14 points more first programs
right.

## How the first programs failed

As in every Python run, almost only at the error case (case 9, which
expects the word `error`, which the requirement never names): 35 of 36
failing first programs with the requirement alone, 26 of 27 with the
note. The text `"error"` is in 34 of 60 first programs with the note and
30 of 60 without. Over the three runs that count was 39, 34 and 34 with
the note, and 27, 36 and 30 without: the note's gain goes through the
error case, but the counts move from run to run as much as the passes
do.

## Limits

- One task, one model, one language.
- The pooled test was chosen after two of its three runs were known;
  this run alone did not pass its own test.
- The restatement was written by hand, by the assistant that ran the
  benchmark, from the requirement alone; another writer would make
  another text.
- The same note harms guided cocolog (`controlled-ablation-20261121/`)
  and does nothing in C and in cocolog without its guide
  (`reason-python-20261121.md`).
- No cell met the safety classifier in this run.

## Files

`controlled-english-python-3-20261121/`: `README.md` (the tests, written
before the run, and their result), `bench.jsonl` and the note. The same
report as a page: `controlled-english-python-3-20261121.html`.
