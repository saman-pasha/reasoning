# coding/bench/v2

The second coding benchmark. It is separate from the legacy
`coding/bench/bench.pl`, `paired.pl` and `tool.pl`; those keep their
behaviour. v2 answers a narrower set of questions with one verifier,
repeated trials and held-out cases.

Phase 1 is implemented here; the first pilot has run, and the statistics
are implemented:

- C only, three legacy tasks: `lcs`, `stable_sort`, `calculator`.
- Five modes: `plain`, `derive`, `contract`, `extract`, `full`.
- Exact output policy for every task.
- Repair cases a failing attempt may be told about, and held-out cases
  that are never put in a prompt or a diagnostic.
- A JSONL row for every task, mode and trial, a sorted summary, and a
  separate report with task-cluster bootstrap intervals.
- `--keep DIR` for a diagnostic run's per-attempt code and verdict.

`extract` spends one extra model call; `full` is the hand contract plus
the keyword derivation and spends none. The other languages, the
declarative experiment and per-attempt JSONL rows are not implemented yet.

`mvccs_acid` was the third task in the first pilot. The diagnostic run of
2026-11-17 failed only its snapshot-visibility case in all three attempts;
two attempts produced byte-identical code and the third changed only
formatting. A larger budget is not supported by that evidence, so
`calculator` is the Phase 1 third task and `mvccs_acid` is left for a
later hard-task or reasoning-effort suite. The pilot's numbers remain the
record for the old trio.

## Modes

| mode | extra calls | prompt |
|---|---|---|
| `plain` | 0 | the requirement alone |
| `derive` | 0 | plus obligations derived from its keywords |
| `contract` | 0 | plus the task's hand controlled-English contract |
| `extract` | 1 | one call writes the controlled-English contract, then its obligations |
| `full` | 0 | the hand contract and the keyword derivation together |

`full` does not call the extractor: the plan's third factor is the guide,
and the C codegen's system prompt is the guide in every mode.

## The cases

`schema.pl` takes each task's legacy cases and splits them. The split is
declared by one-based indices:

| task | repair / held-out | why these |
|---|---|---|
| `lcs` | 4 / 2 | the greedy killer (`aggtab/gxtxayb`) and the empty second line |
| `stable_sort` | 5 / 2 | the two tie-heavy orders |
| `calculator` | 4 / 2 | operator precedence and left-associative subtraction |

The prompt contains no case. When an attempt fails a repair case, the
repair prompt gets the verifier's diagnostic for that case. The held-out
cases are run once, after every repair case passes; a held-out failure is
a final failure and its case is never named to the model.

The legacy `stable_sort` case 1 says `5` and gives four records. A program
that follows the requirement and reads five lines reads a line that is not
there. v2 corrects the count to `4` in its own copy and leaves
`coding/bench/tasks.pl` untouched, so the legacy run stays reproducible.
The test pins both texts.

## Output policies

- `exact` -- byte for byte, except that one final newline is optional.
- `edge_trim` -- the legacy per-line trim and dropped empty lines.
- `token_normalized` -- runs of whitespace are one space.

Every current task uses `exact`, so a leading space is a failure. The
legacy `bench_norm/2` is not used. `stdout` and `stderr` are captured
separately: a nonempty `stderr` is a failure even when `stdout` is right,
so a sanitizer report cannot pass as an answer.

## Commands

Run from the repository root, with the cocolog checkout beside it:

```sh
COCOLOG_LIBRARY="$PWD/..:$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/bench/v2/run.pl -- --plan
```

`--plan` prints the selected tasks, repair/held-out counts, policy and
budget, and makes no model call. It is the default.

For a diagnostic run, `--keep DIR` writes `spec.txt` once per cell and,
for every attempt, `attempt-N-code.c` and `attempt-N-verdict.txt` with
the usage, generator error and verifier verdict. A held-out failure's
file names that failure and no held-out case. The files are for
diagnosis; the normal matrix leaves them out.

A paid run needs the provider key and `--run`:

```sh
export CODING_ENDPOINT_KEY_ENV=...       # never a file in this repository
COCOLOG_LIBRARY="$PWD/..:$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/bench/v2/run.pl -- \
    --run --tasks lcs --modes plain --trials 1 --out /tmp/v2-pilot.jsonl
```

Options:

```text
--tasks A,B     tasks (default: every v2 task)
--modes A,B     plain, derive, contract, extract, full
                (default: config.pl's list, all five)
--trials N      trials per task and mode (default: 3)
--seed N        order seed (default: config.pl's)
--out FILE      JSONL output (default: results/<run id>.jsonl)
--keep DIR      write each cell's spec and each attempt's code, usage and
                verdict under DIR/task/mode/trial-N
```

`./run.sh` is the same command with `COCOLOG_LIBRARY` set from the
repository's parent.

## Report a saved run

```sh
./report.sh coding/bench/v2/results/pilot-20261117.jsonl --samples 5000
```

The report always prints the per-task table. Its aggregate is a **cluster
bootstrap over tasks**, not over cells: trials of one task are not
independent samples of the task population. With three tasks the interval
is necessarily wide, so the table is the evidence and the interval is a
warning against reading the aggregate as an estimate. It also prints the
ablation pairs present: `derive` minus `plain`, `extract` minus `derive`,
`contract` minus `extract` and `full` minus `contract`, for pass@1 and
final pass, with the same bootstrap.

`--seed` defaults to the run's own seed, so a report is reproducible.

## What a row records

The first line is a header with the run id, git commit, model, provider,
tasks, modes, trials and seed. Each later line is one cell:

```text
task, language, mode, trial, order_position, seed
pass_at_1, final_pass, outcome, attempts
extra_calls, calls, mode_error
repair, heldout, max_calls
usage {prompt, completion, total, reasoning, cache_hit}
seconds
```

`attempts` counts the repair loop's generator calls; `extra_calls` is the
extraction call (`0` or `1`) and `calls` is their sum. `mode_error` is
`none` unless the extraction failed or returned no obligations.

`outcome` is one of `pass`, `fail_compile`, `fail_repair`,
`fail_heldout`, `fail_generator`, `fail_verifier`.

`pass@1` means the first attempt passed both case sets. `final_pass`
means any allowed attempt did. The summary prints per task and mode:
trials, pass@1, final pass, mean attempts, tokens and seconds.

Rows are appended as cells finish, so an interrupted run keeps every
completed cell.

## Tests

No model and no network:

```sh
COCOLOG_LIBRARY="$PWD/..:$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/bench/v2/test.pl
```

The test checks the schema and split, the three output policies, the
verifier on a correct LCS, a repair-case failure, a held-out-only failure
and a compile failure, the attempt loop through a fixture seam, the
statistics and JSONL reader, the kept attempt files, and one complete
JSONL run with no provider.

## Budget

`config.pl` holds the provider, model, temperature, three-trial pilot and
the seed. Per task, `schema.pl` allows three child calls and a case
timeout. The default pilot is 3 tasks x 5 modes x 3 trials = 45 cells: at
most 135 generator calls plus 15 extraction calls. The pilot is the
budget gate: do not start a larger run until its per-task variance and
token cost are known and the spend is approved.

The legacy benchmark is not edited to make v2 pass. A disagreement
between v2 and a legacy result is recorded before changing either.

## Files

```text
config.pl    provider, model, temperature, trials, seed, results dir
schema.pl    task declaration, case split, output policy, budget
verify.pl    sanitized compile, repair and held-out runs, output policy
runner.pl    attempts, repair diagnostics, seeded order, JSONL, summary
gen.pl       one child generator call
run.pl       the runner's main/0
run.sh       the shell entry point
stats.pl     JSONL reader, cluster bootstrap, paired differences
report.pl    the report's main/0
report.sh    the report's shell entry point
test.pl      no-model checks
results/     run output; a frozen pilot keeps its JSONL and report
```
