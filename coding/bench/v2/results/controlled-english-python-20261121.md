# Controlled English effect on Python codegen, 2026-11-21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature (the model refuses one)
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output, 10 s a case
- Lane: Python alone. Arms: `plain` (the requirement alone) and
  `controlled` (the requirement, then the controlled restatement of
  `reason-python-20261121/`, byte for byte)
- Trials: 60 per arm in one run, the arms shuffled together, seed
  `20261121`, up to 3 generator calls per cell; reasoning 1.17.2
- 120 cells, 186 generator calls, 849 900 tokens (476 698 prompt,
  373 202 completion), 35 min of cell time: **$4.69** at $2 and $10 per
  million input and output tokens

## The test, and its answer

The test was written down and committed before the first cell ran
(`controlled-english-python-20261121/README.md`, commit `cbb2150`):
first-attempt passes, `controlled` against `plain`, Fisher's exact test,
one-sided (controlled greater), significant at p < 0.05.

**The controlled restatement makes Python's first program right more
often: 37/60 against 25/60, p = 0.022.** The effect is significant by the
test chosen before the run. (Two-sided, p = 0.044.)

| arm | first | final | calls | tokens | cell time |
|---|---|---|---|---|---|
| `plain` | 25/60 (42 %) | 59/60 | 102 | 443 950 | 19 min 20 s |
| `controlled` | **37/60 (62 %)** | 59/60 | **84** | **405 950** | 15 min 34 s |

At 95 % confidence the first-attempt rate is 30 % to 54 % with the
requirement alone and 49 % to 73 % with the note (Wilson intervals).
The earlier run of the same two arms, `reason-python-20261121/`, gave
12/20 against 7/20 (p = 0.21 two-sided): the same direction, and about
the same size.

## What it does to calls and tokens

These are described, not tested. With more first programs right, the
note saves repair calls: 84 calls against 102 (−18 %). A repair call is
dear (it sends the requirement, the note, the last program and the
failure, and the model writes the program again), so the note pays for
its own 2 590 characters in every call and the arm still spends **9 %
fewer tokens** and 20 % less cell time.

## Why

As in every Python run before it, the first programs fail almost only
at the error case (case 9: commands to a transaction that has not begun,
and a second begin, each expecting the word `error`). The requirement
says "error if T is not active" and never what an error prints.

| arm | first programs that failed | of them, at the error case | first programs with the text `"error"` |
|---|---|---|---|
| `plain` | 35 | 35 | 27/60 |
| `controlled` | 23 | 22 | 39/60 |

The restatement says "causes an error" in two sentences of their own
(`Every repeated_begin causes an error.`, `Every transaction that is not
active causes an error.`), and more of its programs print the word. It
adds no fact the requirement does not have: it says the same rule as a
sentence by itself, where the requirement says it as the tail of each
line of a command table.

## Limits

- **One task, one model, one language.** The effect goes through one word
  the cases expect and the requirement does not name. A requirement that
  names its outputs would likely not show it (not tested).
- **The same note harms guided cocolog**: 2/20 against 15/20, and 0/10
  against 6/10 in the ablation, through its sentences on input
  (`controlled-ablation-20261121/README.md`). The note is no general aid.
- **The restatement was written by hand**, by the assistant that ran the
  benchmark, from the requirement alone. Its cost is not counted, and
  another writer would make another text.
- **One `plain` cell met the safety classifier**: both repair calls of
  trial 11 were refused (`reasoning_extraction`), and the request sent
  again was refused again. Its first program had failed already, so the
  test does not change; it is the arm's one final failure.
- The note sits in the user prompt, not in the system prompt as the
  coding endpoint puts its notes.
- The model takes no temperature; trials are samples of a generator that
  is not deterministic, and the same prompt passes at different rates in
  different runs (`reason-python-20261121.md`), so only arms of one run
  are compared.

## Files

`controlled-english-python-20261121/`: `README.md` (the test, written
before the run, and its result), `bench.jsonl` (the run) and
`mvccs_acid-python.controlled` (the note). The same report as a page:
`controlled-english-python-20261121.html`.
