# v2 no-feedback vs feedback, 2026-11-17

- Commit: `8a64959` (`reasoning 1.8.14`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Tasks: `lcs`, `stable_sort`, `calculator`
- Modes: `once` (one call, no repair), `plain` (repair loop, no obligations)
- Trials: 3 per task and mode, seed `20261117`
- JSONL: `once-plain-20261117.jsonl`
- Total: 18 cells, 7 945 tokens, 116.6 s of cell time

## Results

| task | mode | pass@1 | final | attempts | tokens |
|---|---|---|---|---|---|
| `lcs` | once | 0/3 | 0/3 | 1.00 | 981 |
| `lcs` | plain | 1/3 | 1/3 | 1.00 | 1 017 |
| `stable_sort` | once | 3/3 | 3/3 | 1.00 | 1 322 |
| `stable_sort` | plain | 3/3 | 3/3 | 1.00 | 1 325 |
| `calculator` | once | 3/3 | 3/3 | 1.00 | 1 642 |
| `calculator` | plain | 3/3 | 3/3 | 1.00 | 1 658 |
| all | | 13/18 | 13/18 | 1.00 | 7 945 |

Aggregate: `once` 6/9, `plain` 7/9; paired `plain - once` is
`+11.1 pp [0.0, +33.3]` for pass@1 and final. The task-cluster interval
is wide with three tasks.

## What it says

- **No repair loop ran.** Every one of the 18 cells finished on its first
  attempt. `plain` and `once` are the same policy until a repair case
  fails; the only difference between them here is model variance on
  `lcs`, where `plain` passed one trial and `once` none.
- **The +11.1 pp is one trial, not feedback.** It is `lcs/plain` trial 3;
  the earlier five-mode matrix had `lcs/plain` at 0/3. The paired interval
  reaches zero and the aggregate interval is mostly between-task
  variation.
- **The no-feedback arm is now in place.** It costs about the same as
  `plain` on these tasks (7 945 tokens in all: 3 945 `once`, 4 000
  `plain`, since no repair call is made) and is ready for a task that
  actually fails repair.
- **The task-selection blocker is unchanged.** No current task makes the
  first attempt fail a repair case, so the trio cannot measure the value
  of feedback. The next paid run needs such a task, not another N.

The next design step is to add a task whose first attempt is likely to
fail a repair case but whose diagnostic is actionable — `phonebook`,
`btree` or a small parser with a stated edge — then repeat `once` vs
`plain` and only after that re-run the obligation modes.
