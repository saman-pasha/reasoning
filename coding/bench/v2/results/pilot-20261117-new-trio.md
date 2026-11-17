# v2 pilot, new trio, 2026-11-17

- Commit: `5076d6a` (`reasoning 1.8.11`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Tasks: `lcs`, `stable_sort`, `calculator`
- Modes: `plain`, `derive`
- Trials: 3 per task and mode, seed `20261117`
- Budget: 3 child calls per cell; 3000 ms per case
- JSONL: `pilot-20261117-new-trio.jsonl`
- Total: 18 cells, 10 974 tokens (all cells one attempt),
  117.9 s of cell time

## Results

| task | mode | pass@1 | final | mean attempts | tokens | mean seconds |
|---|---|---|---|---|---|---|
| `calculator` | plain | 3/3 | 3/3 | 1.00 | 1 595 | 6.2 |
| `calculator` | derive | 3/3 | 3/3 | 1.00 | 2 170 | 6.5 |
| `lcs` | plain | 0/3 | 0/3 | 1.00 | 981 | 5.8 |
| `lcs` | derive | 3/3 | 3/3 | 1.00 | 1 650 | 6.3 |
| `stable_sort` | plain | 3/3 | 3/3 | 1.00 | 1 330 | 6.6 |
| `stable_sort` | derive | 3/3 | 3/3 | 1.00 | 3 248 | 8.0 |
| all | | 15/18 | 15/18 | 1.00 | 10 974 | 117.9 total |

Outcomes: 15 `pass`, 3 `fail_heldout`; no `fail_repair`, compile,
generator or verifier failure.

## Bootstrap report

`./coding/bench/v2/report.sh
coding/bench/v2/results/pilot-20261117-new-trio.jsonl --samples 5000`:

```text
aggregate (cluster bootstrap over tasks)
plain:  9 cells, pass@1 6/9 66.7% [0.0, 100.0], final 6/9 66.7% [0.0, 100.0], attempts 1.00, 3,906 tokens, 6.2 s
derive: 9 cells, pass@1 9/9 100.0% [100.0, 100.0], final 9/9 100.0% [100.0, 100.0], attempts 1.00, 7,068 tokens, 6.9 s

paired derive minus plain (3 task(s))
pass@1 +33.3 pp [+0.0, +100.0]
final  +33.3 pp [+0.0, +100.0]
```

The task-cluster interval is wide by construction with three tasks; the
derive interval is [100, 100] only because every task's three trials
passed, not because three tasks establish a population rate.

## What the pilot says

- **`lcs` is the whole result.** `plain` failed the held-out set in all
  three trials; `derive` passed all three at pass@1. The repair cases do
  not separate a subsequence from a substring; the held-out case does.
  This is now two pilots in a row with the same direction (the old trio's
  `lcs/plain` passed 1/3, `lcs/derive` 3/3).
- **No repair loop ran.** Every cell passed or failed on its first
  attempt, so pass@1 equals final pass everywhere. The old pilot's
  `stable_sort/derive` repair did not reproduce. At N=3 this trio
  measures the prompt and the held-out set, not the value of repair; a
  harder task or more trials would be needed for that.
- **`calculator` replaces `mvccs_acid` cleanly.** It passed 3/3 in both
  modes for about 3 800 tokens in six cells. The old pilot's `mvccs_acid`
  spent 140 704 tokens for zero passes.
- **Derive costs more and is not uniformly better.** It is the difference
  on `lcs`, no better on `stable_sort` or `calculator`, and costs
  7 068 versus 3 906 tokens over the nine cells. The paired interval
  reaches zero because two of the three tasks have no difference.
- **Total cost fell sharply:** 10 974 tokens against the old trio's
  152 497, with the same number of cells.

These are N=3 observations. The next matrix should keep this trio, add
the `extract`, `contract` and `full` modes, and decide separately whether
a harder task is needed to exercise repair.
