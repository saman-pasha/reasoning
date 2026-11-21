# The controlled note in guided cocolog, taken apart

The run `controlled-mvccs-20261121/` found guided cocolog's first
program right 2 times in 20 with the controlled restatement after the
requirement, against 15 in 20 with the requirement alone. This run asks
which part of the note does it. Each arm is the requirement and one note,
in the cocolog lane with its guide, all arms shuffled together:

| arm | the note after the requirement |
|---|---|
| `plain` | none |
| `controlled` | the controlled restatement, as in `controlled-mvccs-20261121/` (byte for byte) |
| `alt1` | the requirement itself, said again word for word under a header like the controlled note's: a second statement in plain English, of about the same length |
| `alt2` | the controlled restatement with its four quoted words unquoted (`reads as yes`, `gets no`): the guide says double-quoted text is a list of codes |
| `alt3` | the controlled restatement without its four sentences on input (`Mvccs reads a line.`, `Every line holds a command.`, `Every line that is blank is ignored.`, `Every transaction_name is a word.`) |

The notes were made by hand from `mvccs_acid-cocolog.controlled` and the
lane's requirement; `alt1`'s text is the requirement as the runner gives
it.

## The result

50 cells, 85 calls, $9.03, reasoning 1.17.2 (`f4e61ea`).

| arm | first | final | calls | tokens | first programs that print nothing for `v` | that match a part as codes (`[[0'b], T]`) |
|---|---|---|---|---|---|---|
| `plain` | 6/10 | 10/10 | 14 | 502 833 | 4 | 4 |
| `controlled` | **0/10** | 9/10 | 21 | 786 943 | 8 | 8 |
| `alt1`, the requirement again | 5/10 | 10/10 | 15 | 590 420 | 3 | 4 |
| `alt2`, no quotes | 1/10 | 10/10 | 20 | 766 479 | 5 | 7 |
| `alt3`, no input sentences | **6/10** | 10/10 | 15 | 576 036 | 2 | 1 |

- **The note does it again**: 0/10 against 6/10 (Fisher p = 0.011,
  two-sided), after 2/20 against 15/20 in `controlled-mvccs-20261121/`.
- **The four sentences on input are the cause.** Without them (`alt3`)
  the note gives 6/10, as no note does (p = 0.011 against `controlled`),
  and 1 of 10 first programs matches the parts of a line as codes,
  against 8 of 10 with them.
- **The quotes are not.** Unquoted, the note still gives 1/10 (`alt2`).
- **A second statement as such is not.** The requirement said again in
  plain English gives 5/10 (`alt1`).

The failing programs go wrong exactly where those sentences speak: how a
line is cut into words. They read the line with `read_line_to_codes/2`,
cut it with `split_string/4`, which gives strings, and dispatch on each
part as a list of codes, `mv_cmd([[0'b], T])`, so no command matches
and the program prints nothing. The run does not show which of the four
sentences does it, or why; `Every line holds a command.` and `Every
transaction_name is a word.` are the ones that speak of a line's parts.

These comparisons were not chosen before the run (this README named
the arms, not a test), ten trials an arm: read them as a description.
Four comparisons against `controlled` at p < 0.05 / 4 = 0.0125 would
keep the two at p = 0.011.
