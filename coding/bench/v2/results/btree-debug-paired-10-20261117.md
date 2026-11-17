# btree_debug paired experiment, 10 trials, 2026-11-17

- Run commit: `08198c6` (`reasoning 1.8.17`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree_debug`
- Design: one shared first attempt per trial, then `once` and `plain`
  arms over the same code and diagnostic
- Trials: 10, seed `20261117`
- JSONL: `btree-debug-paired-10-20261117.jsonl`
- Total: 10 pairs, 86 867 tokens under `plain`, 46 791 under `once`
  (the shared calls); 40 076 of the plain total is repair usage

The printed per-task summary in the run log counted `once` passes with
the plain arm's field; the JSONL is correct and this report uses it. The
counting is fixed in `reasoning 1.8.18`.

## Pairs

| trial | first | once | plain | shared | plain repair | plain total |
|---|---|---|---|---|---|---|
| 1 | fail | fail | fail | 4 677 | 16 067 | 20 744 |
| 2 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 3 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 4 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 5 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 6 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 7 | fail | fail | fail | 4 677 | 15 957 | 20 634 |
| 8 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 9 | fail | fail | pass | 4 677 | 8 052 | 12 729 |
| 10 | pass | pass | pass | 4 680 | 0 | 4 680 |
| all | 7 pass / 3 fail | 7 pass | 8 pass | 46 791 | 40 076 | 86 867 |

- `once`: 7/10. `plain`: 8/10. `plain_only` wins: 1; `once_only`: 0.
- Paired difference: `+10.0 pp`, bootstrap over pairs `[0.0, +30.0]` at
  95% (20 000 resamples, seed `20261117`).
- Of the three failing first attempts, one was repaired (trial 9, one
  extra call), and two were not (trials 1 and 7, two extra calls each).
- `plain` costs 1.86 times `once` for the extra pass: 40 076 repair
  tokens, or 40 076 tokens per extra solved pair in this sample.
- The `Abort trap: 6` lines in the log are the injected-defect program
  crashing in the repair cases, as expected.

## What it says

- **Feedback can help, and the paired design shows it.** Trial 9 is a
  genuine paired win: the same failing first program was repaired to a
  pass in one extra call. The earlier unpaired 0/3 result was
  first-attempt luck.
- **One win in three failing branches is not an estimate.** The paired
  interval reaches zero; N=10 gives only three repair opportunities.
  A success rate of 1/3 is compatible with a low true rate.
- **The cost is high when repair fails.** Trials 1 and 7 paid two extra
  calls each and stayed failing; those two repairs are 32 024 of the
  40 076 repair tokens.
- **The next N is larger, not a new design.** Thirty pairs would give
  roughly 9 failing first attempts at the observed rate, enough to
  separate a low repair rate from zero. The shared cost is about 4.7k
  tokens per pair plus 8-16k per failing branch.
