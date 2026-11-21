# Controlled English, gzip-compressed, in Python codegen

Written and committed BEFORE the run, so the tests below were chosen
before any result of them was seen.

## Why

In `controlled-english-python-20261121/` the controlled restatement
after the requirement made Python's first program right 37 times in 60,
against 25 with the requirement alone (Fisher one-sided p = 0.022). This
run asks whether the same text helps when it is sent compressed: gzip,
then base64, since a prompt carries text alone. A model can read base64
only by decoding it in its head, and gzip's deflate stream is far harder
to undo that way, so the run tests whether the model reads it at all.

## The run

- Lane: Python alone. Task: `mvccs_acid`, the clear text of reasoning
  1.14.1.
- Arms, all shuffled together:
  - `plain`: the requirement alone;
  - `controlled`: the requirement, then `mvccs_acid-python.controlled`,
    the earlier run's note, byte for byte (2 590 characters);
  - `alt1`, the GZIP arm: the requirement, then
    `mvccs_acid-python.alt1` (1 145 characters): a header like the
    controlled note's, saying the text is "compressed with gzip and
    encoded in base64", then `gzip -9 -n controlled/mvccs_acid.txt |
    base64 -w 76`, the same 64 sentences (md5
    `deeac127492e3e58b799bb8dd8620455` once decoded and unpacked).
- 60 trials an arm, 180 cells, seed `20261123`, up to 3 generator calls
  a cell. Model `claude-sonnet-5-5`, effort `low`, `max_tokens` 16 000;
  reasoning 1.17.3.

## The tests

Fisher's exact test, ONE-SIDED, on first-attempt passes:

1. **The gzip arm makes the first program right more often than the
   requirement alone** (`alt1` greater than `plain`).
2. **The controlled arm does** (`controlled` greater than `plain`): the
   earlier run's result, asked again.

Each significant if p < 0.05; the report also says whether each passes
p < 0.05 / 2 = 0.025, the limit for the two together.

Everything else is described and not tested: the gzip arm against the
controlled arm, the final pass, calls and tokens, the error case's
failures and how many first programs print `error`. A refused cell
counts as it comes; the report says how many.
