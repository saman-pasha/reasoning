# Legacy benchmark baseline

Frozen legacy code and evidence, for historical comparison only. v2 does
not call this suite and no legacy file was edited to make v2 pass.

- Repository commit: `ac94cd3` (`reasoning 1.8.18`)
- Cocolog: 3.62.4
- Provider: `openai` (`https://api.deepseek.com/v1/chat/completions`)
- Model: `deepseek-flash`, temperature 0
- Reasoning effort: `high` for the legacy `high` mode, `none` for the
  loops
- Loop attempts: 3
- C edition: `c17`
- Verification: `clang -std=c17 -Wall -Wextra -O0`, then each case run
  and compared after trailing whitespace is trimmed (`bench_norm/2`)
- Tasks: the legacy `tasks.pl`'s ten tasks plus `btree_debug`; no v2 task
  is added to the legacy set

## Selector

```sh
./coding/bench/v2/legacy.sh -- [task ...]
```

With no task names it runs every legacy task and mode; it spends model
tokens. The script sets `COCOLOG_LIBRARY` and runs the unchanged
`coding/bench/bench.pl`, whose report is the legacy mode table. The
command is the one that produced the sample below; it was not rerun to
write this file.

## Existing sample result

From `coding/bench/README.md`, 2026-11-14, `deepseek-flash`, the ten
tasks before `btree_debug`:

```text
mode      tasks passed attempts prompt completion reasoning total cache_hit seconds
high      10    9      10       1607   36956      29534     38563 256       205.33
loop      10    8      15       8139   11445      0         19584 2048      92.33
contract  10    10     10       2382   7888       0         10270 384       62.29
extract   10    10     20       5370   8582       0         13952 1535      61.35
derive    10    10     10       2429   7575       0         10004 384       61.34
escalate  10    9      13       8174   11646      0         19820 1664      84.33
escalate2 10    9      15       9070   13372      0         22442 2048      95.62
```

The README has later single-task and `btree_debug` samples as well. They
are legacy-verifier results and are not comparable with v2's exact-output,
held-out, repeated-trial rows.

## Relationship to v2

- Legacy files are untouched: `bench.pl`, `paired.pl`, `tool.pl`,
  `tasks.pl` and their shell wrappers. v2's only correction of a legacy
  task (the `stable_sort` case that announced five records and gave four)
  lives in `v2/schema.pl`.
- Legacy uses one output policy for every task; v2 declares one per task.
- Legacy cases are all visible to repair; v2 withholds a held-out set.
- The legacy evidence above is a single sample, not repeated trials.
