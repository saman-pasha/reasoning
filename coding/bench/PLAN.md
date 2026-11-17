# A second coding benchmark

This plan keeps `coding/bench/bench.pl`, `paired.pl` and `tool.pl` as the
**legacy suite** and adds a separate suite beside them. It does not turn
the existing seven modes into a language leaderboard, and it does not
combine unrelated experiments into one score.

The review that prompted this plan is broadly right. Three qualifications:

- The current README already states that the model is not deterministic
  and that one run is not an estimate. The gap is the **statistics**, not
  an undisclosed claim.
- The C benchmark never claimed that Cocolog beats Python. Its question
  is narrower: do obligations derived from a requirement improve C
  generation over plain prompting and plain compiler feedback?
- `bench_norm/2` is deliberate, but it is one policy for every task. The
  fix is a declared per-task output policy, not necessarily exact
  matching everywhere.

## The suites stay separate

| suite | question |
|---|---|
| `coding/bench` (legacy) | Do obligation-guided prompts improve C generation? |
| `coding/cocolog/bench` | Does Cocolog's language guide improve Cocolog generation? |
| `coding/bench/tool.pl` | Does the shipped C generator work under its real policy? |
| `coding/bench/v2` | The questions below, with shared verification and repeated trials |

No table adds a row from one suite to a row from another.

## What v2 must answer

1. **Obligations vs feedback vs extraction.** Is a gain from the
   obligations themselves, from compiler/test feedback, or from the model
   rewriting the requirement?
2. **Repeated, held-out, exact.** Does a result survive repeated trials,
   cases never shown in repair diagnostics and the task's declared output
   policy?
3. **Language and paradigm.** On the same problem, with the same budget
   and cases, how do C, Python, Cocolog and SWI-Prolog compare?
4. **Declarative formulation.** Does defining a problem as facts,
   relations and rules help on problems that are awkward as imperative
   code?

## Directory and shared pieces

```text
coding/bench/v2/
  README.md
  config.pl          model, temperature, trials, budgets, seeds
  schema.pl          task declarations, repair/held-out split, output policy
  verify.pl          one verification pipeline for C
  gen.pl             one child generator call
  runner.pl          modes, trials, ordering, child calls, paired arms, JSONL
  run.pl, run.sh     runner entry points
  stats.pl           pass@1, final pass, paired deltas, bootstrap CIs
  report.pl, report.sh  report entry points
  test.pl            no-model checks
  legacy.sh          Phase 0 selector for the unchanged legacy benchmark
  results/           baseline.md and frozen runs
```

The planned separate `tasks.pl`, `heldout.pl` and `modes.pl` were folded
into `schema.pl` and `runner.pl`; `langs/` is not built yet. Reuse
`coding/compile.pl` for C (sanitized build) and `coding/bench/gen.pl`'s
child-process pattern. Legacy files are not edited to make v2 pass.

## Task schema

Each task declares, not implies:

- `lang(Task, Lang)` — one implementation target.
- `spec(Task, Text)` — the requirement shown to the model.
- `repair_cases(Task, Cases)` — the cases whose failures a repair
  attempt may be told about. The prompt itself contains no cases; the
  current benchmark already works this way.
- `heldout_cases(Task, Seed, Cases)` — deterministic cases never shown in
  any prompt or repair diagnostic, run only for the final verdict.
- `output_policy(Task, exact | edge_trim | token_normalized)`.
  - `exact`: byte-for-byte stdout, only the final newline optional.
  - `edge_trim`: leading/trailing whitespace on each line may differ.
  - `token_normalized`: internal spacing is not significant; a task must
    say why.
- `acceptance(Task, functional | concurrency | constraint | property)` —
  a task may have more than one; the report names which passed.
- `budget(Task, MaxCalls, MaxSeconds, MaxTokens)`.
- `tags(Task, Tags)` — e.g. `relational`, `grammar`, `repair`,
  `data-structure`.

A task cannot be in the language comparison until every language has a
runner, a repair-case set, a held-out generator and an output policy.

## Verification

`verify.pl` is the only place a program is judged. Every mode and every
language goes through it.

- **C:** compile with the task's `-std`, `-Wall -Wextra -O0 -g`, then the
  sanitized build from `coding/compile.pl`
  (`-fsanitize=address,undefined -fno-sanitize-recover=all`), run every
  repair and held-out case under a timeout, then the static analyzer when
  the task asks for it.
- **Python:** `py_compile`, run in a fresh temporary directory with
  `-I`, compare under the output policy, timeout, and an optional
  `python3 -X dev` pass.
- **Cocolog:** consult the program in a child process, run each case as a
  query or a stream, `cocolint`, timeout.
- **SWI-Prolog:** the same case protocol under `swipl -q`, with its own
  style check.

A sanitizer report, a compiler error, a timeout, a nonzero exit, a wrong
held-out case and a failed property each have their own result; the repair
prompt gets the same diagnostic the verifier produced. The legacy
`bench_norm/2` is not used in v2.

## Trials and statistics

`config.pl`:

```prolog
v2_config(trials, 10).
v2_config(temperature, 0).
v2_config(seed, 20261117).
v2_config(models, ['deepseek-flash']).
v2_config(max_calls, 6).
v2_config(max_seconds, 600).
```

The runner records one JSON object per task/mode/trial:

- run id, git commit, suite version, model, effort, mode, language;
- repair and held-out verdicts, per acceptance criterion;
- attempts: prompt, verdict, usage, wall time, diagnostic hash;
- total tokens, estimated cost, wall time, sanitizer result;
- order position and seed.

Statistics:

- **pass@1** — the first attempt passes all repair and held-out cases.
- **final pass** — any allowed attempt passes.
- **attempts to pass** and **cost per solved task**.
- **paired task-level differences** — for two modes, per task, the same
  first attempt where the legacy `paired.pl` design allows it.
- **bootstrap confidence intervals** over tasks, and per-task rows; an
  aggregate without a per-task table is not reported.
- A pilot of 3 trials per task/mode first; increase to 10 or more only
  if the variance warrants it. The plan and the maximum spend are fixed
  before the run.

Because the provider is not deterministic even at temperature 0, the
result file records the provider's response id and any seed it accepts.
A run is reproduced by re-running, not by assuming the same samples.

## Ablation matrix

Keep the prompt, verification, cases and budget fixed; vary one thing:

| mode | feedback | obligations | source |
|---|---|---|---|
| `once` | no | none | requirement |
| `plain` | compiler/tests | none | requirement |
| `derive` | compiler/tests | keyword-derived | requirement |
| `extract` | compiler/tests | model-extracted | extra call |
| `contract` | compiler/tests | hand contract | task's controlled English |
| `full` | compiler/tests | contract + derivation + guide | both |

The implementation names the no-feedback arm `once`; `plain` is the
feedback loop with no obligations.

Comparisons:

- `plain` vs `once`: value of the loop alone.
- `derive` vs `plain`: value of deterministic obligations.
- `extract` vs `derive`: value and cost of model interpretation.
- `contract` vs `extract`: hand contract vs extraction.
- `full` vs `contract`: the guide and the extra reasoning.

The Cocolog-guide suite stays in `coding/cocolog/bench`; it is not folded
into this matrix, but its `checked` vs `no_skill` result is reported
beside it.

## Language and paradigm comparison

Add a `langs/` runner for each target. The comparison is only valid when:

- the specification, repair cases and held-out cases are the same;
- each language gets its normal guide and toolchain, and the same model,
  effort and call budget;
- the output policy is declared per task and applied to every language;
- a language's implementation is reviewed by someone other than the
  person who tuned the prompt;
- failures are reported per language, per task, with the toolchain error,
  not only as a pass count.

Targets: C, Python, Cocolog and SWI-Prolog. Cocolog vs SWI-Prolog is a
dialect comparison, not a claim about Prolog as a language. The report
names the confounds: model familiarity, library availability, compile
time, and the fact that the model is trained most on Python.

The language suite starts with tasks that have a clean I/O contract:
LCS, stable sort, a small parser, a dependency resolver, a relational
query, a constraint problem. Data-structure tasks stay in the C legacy
suite until their held-out cases are language-neutral.

## Reasoning-specific tasks

Add tasks where the declarative form is the point, not a checklist:

- transitive closure and joins over facts;
- bidirectional transformation (parse and print, both tested);
- dependency resolution and topological order;
- grammar and parser rules, with ambiguous inputs;
- constraints with multiple valid solutions, checked by a property;
- a small scheduler or state machine with invariants.

Each has repair cases a failing attempt may be told about and a
deterministic held-out generator; a held-out case that only the
imperative solution can express is a task
defect, not a model failure.

## Declarative vs imperative experiment

For a selected set, ask for two solutions to the same problem:

1. an imperative C or Python program;
2. a Cocolog program of facts, relations and rules.

Both go through the same verifier and held-out cases. Report correctness,
tokens, wall time and the size of the program. Pre-register the tasks and
the hypothesis before the run. This is the experiment that can support a
claim about reasoning, rather than about prompt checklists.

## Phases and acceptance

### Phase 0 — freeze the legacy evidence

**Done 2026-11-17.** `v2/results/baseline.md` records the frozen commit,
config and the existing sample table; `v2/legacy.sh` runs the unchanged
`coding/bench/bench.pl`. The selector was checked with a no-task
invocation (no model call); the sample table is from the legacy README,
not a new run. No legacy file was edited.

- Keep `bench.pl`, `paired.pl` and `tool.pl` behavior unchanged.
- Add `v2/results/baseline.md` recording the current commit, model,
  config and the existing sample results.
- Add a `legacy` suite selector that runs the old modes under the old
  verification, for historical comparison only.
- Acceptance: a documented command reproduces the old mode table; no old
  file is edited to make a new test pass.

### Phase 1 — one verifier, declared output

- Add `schema.pl`, `verify.pl`, per-task output policies, and the
  repair/held-out case split.
- Run the legacy tasks through v2 verification in a small pilot.
- Acceptance: every mode uses the same verifier; a task with `exact`
  fails on a wrong leading space; a sanitizer report is a failure; the
  delta against the legacy sample is reported, not hidden.

### Phase 2 — repeated trials

- Add the JSONL runner, seeds, randomized order, pass@1/final pass and
  bootstrap intervals.
- Pilot: 3 trials, 4 tasks, 3 modes; then decide the full N and budget.
- Acceptance: the report has per-task rows, paired differences and CIs;
  no aggregate is shown without them.

### Phase 3 — ablation and unseen tasks

- Implement `full` and the mode matrix; pre-register held-out tasks and
  contracts with someone blind to the results.
- Acceptance: each comparison changes one factor; unseen tasks are
  reported separately; extraction acceptance (lines read vs refused) is
  recorded.

### Phase 4 — language and paradigm comparison

- Add Python, Cocolog and SWI-Prolog runners and the first language-neutral
  tasks.
- Acceptance: identical specs/cases/budgets; per-language toolchain
  diagnostics; confounds stated; no combined score.

Implemented in `coding/bench/v2/langs.pl`, `lang_runner.pl`,
`lang_gen.pl`, `lang_run.pl` and `lang.sh`. The first comparison ran on
2026-11-17: 36 cells, 22/36 pass@1, 26/36 final, 403 944 tokens
(`v2/results/lang-20261117.md`). It is a pilot: one model, one generator
per language and three tasks, with the guide confound stated. The repair
diagnostic now shows the offending source line and a caret when the
compiler did not quote it, and a silent cocolog goal failure adds the
tracer's failing chain (`reasoning 1.8.21`).

### Phase 5 — declarative vs imperative

- Add the paired two-form experiment and the reasoning-specific task set.
- Acceptance: pre-registered tasks; held-out cases; both forms verified by
  the same pipeline; the result is reported as a separate question.

## Cost

The current sample is roughly 134 thousand tokens for 10 tasks x 7 modes.
Ten trials is therefore about 1.3 million tokens per suite before
language comparison, and the full matrix is larger. The pilot is the
budget gate: no full run starts until the pilot's per-task variance and
cost are known and the spend is approved.

## First sprint

1. Create `coding/bench/v2/` with `schema.pl`, `verify.pl`, `runner.pl`
   and a JSONL writer; no model calls yet.
2. Port three legacy tasks (`lcs`, `stable_sort`, `mvccs_acid`) with an
   output policy and one held-out case set each.
3. Implement `plain` and `derive` on those tasks and run 3 trials.
4. Produce a per-task table with pass@1, final pass, attempts and tokens;
   use it to size N and the language suite.
5. Only then add `extract`, `contract`, `full` and the other languages.

The old bench stays runnable throughout; if v2 cannot reproduce a legacy
result, that is a finding to record before changing anything else.

## Status (2026-11-17)

The implemented v2:

- Phase 0 is done: `results/baseline.md` freezes the legacy evidence and
  `legacy.sh` runs the unchanged legacy runner.
- `schema.pl` declares the five tasks, their exact output policy, budgets
  and the repair/held-out split. The split is by explicit indices into
  the legacy case list, not by a held-out generator yet. It also corrects
  one defective legacy `stable_sort` case (it said five records and gave
  four) in v2's own copy; the legacy file is untouched and the test pins
  both.
- `verify.pl` compiles with the sanitizers, runs repair cases first and
  held-out cases only for the final verdict, and separates stdout from
  stderr. A nonempty stderr is a failure.
- `config.pl` holds the provider, model, temperature, three-trial pilot,
  seed and child timeout.
- `runner.pl` implements `once`, `plain`, `derive`, `contract`, `extract`
  and `full`, the repair loop, seeded trial order, append-as-you-go JSONL
  and a per-task summary. `once` is the no-feedback arm (one call);
  `extract` makes one parent call; `full` combines the hand contract and
  the keyword derivation without one. `run.pl` is its entry point;
  `gen.pl` is the child generator.
- `stats.pl` reads a saved JSONL run and reports per-task rows, a cluster
  bootstrap over tasks for pass@1 and final pass, and the paired mode
  difference over tasks. `report.pl` is its entry point. The pilot's
  interval is necessarily wide with three tasks; the per-task table is
  the evidence.
- Phase 4's language layer is implemented and tested, but no language
  comparison has run. `langs.pl` declares C, Python, cocolog and
  SWI-Prolog and rewrites only the task requirement's first sentence;
  cases, held-out split, exact policy and call budget are the C task's.
  `lang_runner.pl` / `lang_run.pl` / `lang.sh` run the language grid
  (`--plan`, `--doctor`, `--run`) and write `suite: v2-lang` JSONL rows;
  `lang_gen.pl` is the child generator. `--doctor` prints each
  toolchain. The stated confound is that each language uses its normal
  generator (C's, Python's, cocolog's; SWI a short direct prompt), so the
  comparison is language plus guide, and non-C languages get a 10 s case
  timeout where C keeps 3 s. There is no combined score.
- `test.pl` checks all of the above with no model call, including a full
  JSONL run through a fixture seam, the statistic reader, correct LCS
  programs in Python, cocolog and SWI, and fence stripping.

Not yet implemented: the declarative experiment (Phase 5) and
per-attempt rows in the JSONL. A diagnostic run can keep each attempt's
spec, code, usage and verdict with `--keep DIR`, but the JSONL still
aggregates them per cell. The six-mode matrix has been run on the
three-task set and `btree_debug` has paired feedback runs; the full
six-mode matrix on all five tasks has not been run. The Phase 4 language
comparison ran on 2026-11-17 (`v2/results/lang-20261117.md`): Python
9/9 pass@1, C 6/9, SWI 5/9, cocolog 2/9; cocolog's guide is 95.5 % of
the run's tokens. The next gate is whether to widen the language run or
turn to Phase 5.

The old trio's pilot (`mvccs_acid` in place) spent 140 704 of 152 497
tokens on `mvccs_acid` for zero passes. The diagnostic of 2026-11-17
(commit `15a13e7`, one `plain` cell, 23 517 tokens) failed only the
snapshot-visibility case in all three attempts; attempts 1 and 2 were
byte-identical and attempt 3 changed only formatting. A larger call
budget is not supported, so `calculator` replaced `mvccs_acid` and the
latter is kept for a later hard-task or reasoning-effort suite.

The five-mode matrix pilot (2026-11-17, commit `75fdc8c`, saved in
`v2/results/matrix-20261117.md`) reads 42/45 for 35 147 tokens. Only
`lcs/plain` failed, on all three held-out runs; every obligation mode
passed it. `contract`, `extract` and `full` had exactly zero paired
difference against each other and against `derive`, and no cell needed a
repair. The trio is too easy to separate the upper modes.

The no-feedback arm (`once`) is now implemented, and its pilot against
`plain` (2026-11-17, commit `8a64959`, saved in
`v2/results/once-plain-20261117.md`) reads 13/18 for 7 945 tokens. Every
cell finished on its first attempt, so `plain` and `once` were the same
policy; the paired `plain - once` difference is one `lcs` trial,
`+11.1 pp [0.0, +33.3]`. The trio still cannot measure feedback because
no first attempt fails a repair case. `btree` is now the fourth task for that role, but its pilot
(2026-11-17, commit `16a4e1d`, saved in
`v2/results/btree-once-plain-20261117.md`) passed 6/6 on the first
attempt: it does not exercise repair either. `btree_debug` is now the
fifth task and the repair-loop candidate: its repair cases include
`n=256` where the buggy source crashes, its held-out cases are `n=50`
and `n=1000`, and the model must return the corrected complete program.
Its first pilot (2026-11-17, commit `8951c5e`, saved in
`v2/results/btree-debug-once-plain-20261117.md`) is the first task that
exercised the repair loop: `once` passed 2/3, `plain` passed 0/3 with
three calls per cell, 76 034 tokens in all against `once`'s 14 037. The
direction is negative but not a conclusion: N=3, the modes are separate
samples, and one task makes the bootstrap degenerate. A paired first
attempt is now implemented (`--paired`): one first call, then `once` and
`plain` arms over the same code, with the shared usage counted in both
arm totals. Its pilot on `btree_debug` (2026-11-17, commit `2546c0d`,
saved in `v2/results/btree-debug-paired-20261117.md`) has three pairs:
the shared first attempt passed in two, and the one failing attempt was
repaired twice and stayed failing. `once` and `plain` both passed 2/3;
`plain` cost 29 976 tokens against `once`'s 14 036 with no gain. The
design is sound but N=3 gives one repair branch.

The 100-pair run (2026-11-17, commit `19b6937`, saved in
`v2/results/btree-debug-paired-100-20261117.md`) is the final feedback
pilot. The shared first attempt passed 57 times and failed 43. `once`
passes 57/100 and `plain` 65/100: eight paired wins, no losses, a paired
difference of `+8.0 pp [+3.0, +14.0]`. Repair success is 8/43 (18.6%);
`plain` costs 1 091 270 tokens against `once`'s 467 869 (2.33 times),
and 89.7% of the repair tokens are spent on failures. The direction and
cost structure are now measured for this task and model; Phase 2's
paired comparison is complete. No further paid run has been made.
