# Controlled English, gzip-compressed, in Python codegen, 2026-11-21

- Model: `claude-sonnet-5-5`, provider `anthropic`, effort `low`,
  `max_tokens` 16 000, no temperature
- Task: `mvccs_acid` on the clear text of reasoning 1.14.1, repair cases
  1-5, 7, 9, 10, held-out cases 6 and 8, exact output, 10 s a case
- Lane: Python alone. Arms, shuffled together: `plain` (the requirement
  alone), `controlled` (the requirement, then the controlled restatement
  as plain text, 2 590 characters) and the gzip arm, `alt1` (the
  requirement, then the same 64 sentences as `gzip -9 | base64`, under a
  header that says so, 1 145 characters)
- 60 trials an arm, seed `20261123`, up to 3 generator calls per cell;
  reasoning 1.17.3
- 180 cells, 272 generator calls, 1 274 497 tokens, 53 min of cell time:
  **$6.83**

## The tests, and their answers

Written down and committed before the run (`7590ab2`,
`controlled-gzip-python-20261121/README.md`): Fisher's exact test,
one-sided, on first-attempt passes, each significant at p < 0.05, and
reported against 0.025 for the two.

| test | first attempt | p, one-sided | the hypothesis |
|---|---|---|---|
| 1. gzip arm greater than the requirement alone | 31/60 against 30/60 | 0.50 | not supported |
| 2. controlled arm greater than the requirement alone | 34/60 against 30/60 | 0.29 | not supported |

**The gzipped note does nothing.** The gzip arm and the controlled arm
do not differ either (31/60 against 34/60, two-sided p = 0.71,
described).

## The model does not read the gzip

The gzip arm behaves as the requirement alone does in every measure:

| arm | first | failing first programs at the error case | first programs with the text `"error"` | final | calls | tokens |
|---|---|---|---|---|---|---|
| requirement alone | 30/60 | 30 of 30 | 36/60 | 60/60 | 90 | 379 054 |
| controlled, plain text | 34/60 | 26 of 26 | 34/60 | 57/60 | 89 | 442 644 |
| gzip | 31/60 | 27 of 29 | 34/60 | 60/60 | 93 | 452 799 |

No first program of any arm decodes the note in code (none names gzip,
base64 or zlib). The restatement's own names appear in 7 controlled
programs (`commit_id`, a word of the restatement) and in 1 gzip program
(`commit_id` again, which the requirement's "commit id" suggests by
itself), against 0 with the requirement alone: no sign that the model
unpacked the note.

## Compression does not save tokens

A first call of each arm sent, on average:

| arm | the note | prompt tokens a first call | the note's tokens |
|---|---|---|---|
| requirement alone | none | 1 257 | 0 |
| controlled | 2 590 characters of English | 2 160 | 903 (2.9 characters a token) |
| gzip | 1 145 characters of base64 | 2 216 | **959** (1.2 characters a token) |

gzip halves the characters, but base64 is about 1.2 characters a token
against English's 2.9, so the compressed note costs more tokens than the
text it holds, and carries nothing the model can use.

## The controlled note, asked again

The first test of the controlled note (`controlled-english-python-20261121/`)
found 37/60 against 25/60 (one-sided p = 0.022). Asked again here, in a
run of its own and with a new seed, it found 34/60 against 30/60
(p = 0.29): **the result did not repeat**. With the requirement alone
the first programs did better here than there (30/60 against 25/60; the
text `"error"` in 36/60 against 27/60), and the controlled note's gain
was 4 cells where it was 12. Taken together, not as a test chosen before
either run: 71/120 against 55/120. The note may help less than the first
test showed, or not at all; a third run, or the two counted as one test
chosen now, would say which. The third run (`controlled-english-python-3-20261121.md`)
found 33/60 against 24/60, and the three together 104/180 against
79/180, Cochran-Mantel-Haenszel one-sided p = 0.0058.

## Limits

- One task, one model, one language; 60 trials an arm.
- A model other than this one, or one given a tool to run code, could
  unpack the note; this run says nothing of that.
- One refused cell would count as it came; there were none.

## Files

`controlled-gzip-python-20261121/`: `README.md` (the tests, written
before the run, and their result), `bench.jsonl`,
`mvccs_acid-python.controlled` and `mvccs_acid-python.alt1` (the gzip
note). The same report as a page: `controlled-gzip-python-20261121.html`.
