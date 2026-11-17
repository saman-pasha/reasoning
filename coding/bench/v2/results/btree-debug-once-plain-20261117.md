# btree_debug feedback pilot, 2026-11-17

- Commit: `8951c5e` (`reasoning 1.8.16`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree_debug` (a source with three injected defects)
- Modes: `once` (one call), `plain` (repair loop, no obligations)
- Trials: 3 each, seed `20261117`
- JSONL: `btree-debug-once-plain-20261117.jsonl`
- Total: 6 cells, 76 034 tokens, 151.3 s

## Results

| mode | pass@1 | final | mean attempts | tokens | mean seconds |
|---|---|---|---|---|---|
| `once` | 2/3 | 2/3 | 1.00 | 14 037 | 12.6 |
| `plain` | 0/3 | 0/3 | 3.00 | 61 997 | 37.8 |

All three `plain` cells failed repair after three calls; `once` passed
trials 1 and 3 and failed trial 2 on the first attempt. The paired
`plain - once` is `-66.7 pp`, but with one task the bootstrap is
degenerate (it has one task to resample).

The `Abort trap: 6` lines in the run log are the injected-defect programs
crashing under the sanitizer in a repair case; they are expected and are
captured as failed cases, not harness failures.

## What it says

- **This is the first task that exercised the repair loop.** `plain` spent
  three calls per cell, 4.4 times `once`'s tokens, and solved none.
- **The direction is negative, but this is not yet a conclusion.** The
  modes are separate model samples, not a paired branch from one first
  attempt; N=3; and one task makes the bootstrap interval degenerate.
  `once` passed two of three, so the task is solvable, and the first
  attempts of `plain` may simply have been the unlucky samples.
- **The repair prompt is expensive here.** Each call carries the full
  buggy source plus the previous program and diagnostic; `plain` costs
  about 20.6k tokens per cell against 4.7k for `once`.
- **The next experiment is a paired first attempt**, as the legacy
  `paired.pl` does: one first call, then a `once` arm and a `plain` arm
  over the same code. That isolates feedback from sampling. A larger N
  without pairing would still mix the two.

No further paid run has been made.
