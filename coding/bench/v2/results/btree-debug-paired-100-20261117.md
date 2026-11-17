# btree_debug paired experiment, 100 trials, 2026-11-17

- Run commit: `19b6937` (`reasoning 1.8.19`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree_debug`
- Design: one shared first attempt per trial, then `once` and `plain`
  arms over the same code and diagnostic
- Trials: 100, seed `20261117`
- JSONL: `btree-debug-paired-100-20261117.jsonl`
- Total: 100 pairs, 1 091 270 tokens under `plain`, 467 869 under `once`
  (the shared calls); 623 401 of the plain total is repair usage

The `Abort trap: 6` lines in the run log are the injected-defect program
crashing in repair cases; `sh` job-control text can interleave with the
runner's output. The JSONL is intact and is the source for this report.

## Pairs

| outcome | count |
|---|---|
| first attempt passed | 57 |
| first attempt failed | 43 |
| `once` final pass | 57/100 |
| `plain` final pass | 65/100 |
| `plain_only` wins | 8 |
| `once_only` wins | 0 |

Winning trials: 3, 26, 32, 47, 49, 77, 92, 93. Each was repaired with
one extra call, about 8.0k tokens. Of the 43 failing first attempts, 8
were repaired and 35 stayed failing.

## Totals

| arm | pass | prompt | completion | total |
|---|---|---|---|---|
| `once` | 57/100 | 273 100 | 194 769 | 467 869 |
| `plain` | 65/100 | 744 689 | 346 581 | 1 091 270 |

- Paired difference: `+8.0 pp`, bootstrap over pairs `[+3.0, +14.0]` at
  95% (20 000 resamples, seed `20261117`), which no longer reaches zero.
- Repair success: 8 of 43 failing first attempts (18.6%).
- Repair cost: 64 390 tokens on the 8 successes, 559 011 on the 35
  failures. The failures are 89.7% of the repair spend.
- `plain` costs 2.33 times `once` for the eight extra passes: about
  77 925 tokens per extra solved pair in this sample.

## What it says

- **Feedback has a measurable benefit on this task.** The paired design
  gives eight wins and no losses; the paired interval excludes zero.
- **The benefit is expensive and mostly paid on failures.** About one
  failing first attempt in five is repaired, and nine of every ten
  repair tokens are spent on attempts that do not pass.
- **This is still one task and one model.** The result is a paired
  estimate for `btree_debug` with `deepseek-flash`, not a general claim
  about feedback. The other five tasks have not shown a repair-triggering
  failure in the runs so far.
- **The design is settled.** A larger N would tighten the interval, but
  the direction and the cost structure are now visible; the next
  benchmark step is the language comparison, not another feedback run.
