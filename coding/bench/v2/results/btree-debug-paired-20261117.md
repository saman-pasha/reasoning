# btree_debug paired feedback experiment, 2026-11-17

- Commit: `2546c0d` (`reasoning 1.8.17`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree_debug`
- Design: one shared first attempt per trial, then `once` and `plain`
  arms over the same code and diagnostic
- Trials: 3, seed `20261117`
- JSONL: `btree-debug-paired-20261117.jsonl`
- Total: 3 pairs, 29 976 tokens under the plain policy, 14 036 under
  once (the shared calls), 64.0 s of pair time

## Pairs

| trial | first | once | plain | once tokens | plain repair | plain total |
|---|---|---|---|---|---|---|
| 1 | pass | pass | pass | 4 680 | 0 | 4 680 |
| 2 | fail | fail_repair | fail_repair | 4 677 | 15 940 | 20 617 |
| 3 | pass | pass | pass | 4 679 | 0 | 4 679 |
| all | | 2 pass | 2 pass | 14 036 | 15 940 | 29 976 |

`plain_only` wins: 0. The shared first attempt passed in trials 1 and 3,
so neither arm had a repair opportunity there. Trial 2 is the only
paired repair: both arms failed, and `plain` spent two extra calls
(15 940 tokens) without changing the verdict.

The aggregate `plain` total is 2.14 times `once`'s for the same two
passes. The `Abort trap: 6` lines in the run log are the injected-defect
program crashing in a repair case, as expected.

## What it says

- **The paired design works.** It removed the unpaired pilot's
  first-attempt luck: the earlier `plain` 0/3 and `once` 2/3 came from
  different first attempts; here the arms share them and both pass 2/3.
- **No feedback gain in this sample.** The one failing first attempt was
  repaired twice and stayed failing. The repair calls cost 15 940 tokens,
  more than the shared calls themselves.
- **The sample is small and conditional.** Only one of three pairs had a
  failing first attempt, so the experiment measures a single repair
  branch. It cannot estimate how often a repair succeeds.
- **Next is N, not design.** A 10-trial paired run would give more
  failing branches at roughly 4.7k shared tokens per pair plus 5-20k per
  failed branch. The task or model setting could also be chosen to fail
  first more often. No further paid run has been made.
