# btree feedback pilot, 2026-11-17

- Commit: `16a4e1d` (`reasoning 1.8.15`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Task: `btree`
- Modes: `once`, `plain`
- Trials: 3 each, seed `20261117`
- JSONL: `btree-once-plain-20261117.jsonl`
- Total: 6 cells, 6 560 tokens, 47.4 s

## Results

| mode | pass@1 | final | attempts | tokens |
|---|---|---|---|---|
| `once` | 3/3 | 3/3 | 1.00 | 3 310 |
| `plain` | 3/3 | 3/3 | 1.00 | 3 250 |

Every cell passed on its first attempt. The paired `plain - once` is
`+0.0 pp [0.0, +0.0]`.

## What it says

`btree` does not exercise repair either. The model implemented the 2-3-4
tree, the duplicate rule and the split cases on the first attempt in all
three trials, so `once` and `plain` were the same policy.

The next candidate is `btree_debug`, which is a repair task by design:
its source has three injected defects, its repair cases include `n=256`
where the buggy program crashes, and its held-out cases are `n=50` and
`n=1000`. A first attempt that fails any of those repair cases is the
precondition for measuring the feedback loop. No paid `btree_debug` run
has been made.
