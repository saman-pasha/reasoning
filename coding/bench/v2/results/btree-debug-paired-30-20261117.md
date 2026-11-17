# btree_debug paired experiment, 30 trials, 2026-11-17

- Run commit: `a53dce8` (`reasoning 1.8.18`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree_debug`
- Design: one shared first attempt per trial, then `once` and `plain`
  arms over the same code and diagnostic
- Trials: 30, seed `20261117`
- JSONL: `btree-debug-paired-30-20261117.jsonl`
- Total: 30 pairs, 284 220 tokens under `plain`, 140 369 under `once`
  (the shared calls); 143 851 of the plain total is repair usage

The run log's `Abort trap: 6` lines are the injected-defect program
crashing in repair cases; `sh` job-control text sometimes interleaves
with the runner's output. The JSONL is intact and is the source for
this report.

## Pairs

| outcome | pairs |
|---|---|
| first attempt passed | 20 |
| first attempt failed | 10 |
| `once` final pass | 20/30 |
| `plain` final pass | 22/30 |
| `plain_only` wins | 2 |
| `once_only` wins | 0 |

The two wins are trials 1 and 12, each one repair call (8 036 and 8 048
tokens). The eight failed repairs each used two calls, about 15.9k
tokens apiece.

## Totals

| arm | pass | tokens | mean tokens per pair |
|---|---|---|---|
| `once` | 20/30 | 140 369 | 4 679 |
| `plain` | 22/30 | 284 220 | 9 474 |

- Paired difference: `+6.7 pp`, bootstrap over pairs `[0.0, +16.7]` at
  95% (20 000 resamples, seed `20261117`).
- Repair success: 2 of 10 failing first attempts (20%).
- `plain` costs 2.02 times `once` for two extra passes: 143 851 repair
  tokens, or about 71 925 tokens per extra solved pair in this sample.
- The 10-pair run's 1/3 repair success is consistent with 2/10; neither
  is an estimate.

## What it says

- **Feedback has a small positive signal.** Two of ten failing first
  attempts were repaired, and the paired interval reaches zero rather
  than crossing it.
- **The price is high and mostly wasted.** Eight of ten repairs paid two
  calls and stayed failing; 127 000 of the 143 851 repair tokens are
  those failures.
- **The sample is still small.** Two wins in ten branches leave a wide
  uncertainty. A larger N is the next step if the effect is to be
  stated as a rate; the design itself no longer changes.
