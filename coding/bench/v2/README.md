# coding/bench/v2

The second coding benchmark. It is separate from the legacy
`coding/bench/bench.pl`, `paired.pl` and `tool.pl`; those keep their
behaviour. v2 answers a narrower set of questions with one verifier,
repeated trials and held-out cases.

Phase 1 and the Phase 4 language layer are implemented here; the first
pilot, the paired feedback runs and the first language comparison have
run, and the statistics are implemented.

- C only, five legacy tasks: `lcs`, `stable_sort`, `calculator`,
  `btree`, `btree_debug`.
- Six modes: `once`, `plain`, `derive`, `contract`, `extract`, `full`.
- Exact output policy for every task.
- Repair cases a failing attempt may be told about, and held-out cases
  that are never put in a prompt or a diagnostic.
- A JSONL row for every task, mode and trial, a sorted summary, and a
  separate report with task-cluster bootstrap intervals.
- `--keep DIR` for a diagnostic run's per-attempt code and verdict.
- Four languages (C, Python, cocolog and SWI-Prolog) on three
  language-neutral tasks, with one runner and one verifier policy.

`once` is the no-feedback arm: one call, no repair. `extract` spends one
extra model call; `full` is the hand contract plus the keyword derivation
and spends none. The declarative experiment is implemented (Phase 5);
per-attempt JSONL rows are not implemented yet.

`mvccs_acid` was the third task in the first pilot. The diagnostic run of
2026-11-17 failed only its snapshot-visibility case in all three attempts;
two attempts produced byte-identical code and the third changed only
formatting. A larger budget is not supported by that evidence, so
`calculator` is the Phase 1 third task and `mvccs_acid` is left for a
later hard-task or reasoning-effort suite. Since reasoning 1.14.0 it is a
hard task of the language runner, with the translator's IR as an arm
("The translator's IR", below). The pilot's numbers remain the
record for the old trio.

## Modes

| mode | calls | prompt |
|---|---|---|
| `once` | 1 | the requirement alone, no repair |
| `plain` | up to 3 | the repair loop with the requirement alone |
| `derive` | up to 3 | plus obligations derived from its keywords |
| `contract` | up to 3 | plus the task's hand controlled-English contract |
| `extract` | up to 3 + 1 | one call writes the controlled-English contract, then its obligations |
| `full` | up to 3 | the hand contract and the keyword derivation together |

`once` measures the value of feedback itself; `plain` is the feedback arm
with no obligations. `full` does not call the extractor: the plan's third
factor is the guide, and the C codegen's system prompt is the guide in
every mode.

## The cases

`schema.pl` takes each task's legacy cases and splits them. The split is
declared by one-based indices:

| task | repair / held-out | why these |
|---|---|---|
| `lcs` | 4 / 2 | the greedy killer (`aggtab/gxtxayb`) and the empty second line |
| `stable_sort` | 5 / 2 | the two tie-heavy orders |
| `calculator` | 4 / 2 | operator precedence and left-associative subtraction |
| `btree` | 4 / 2 | all-equal keys and a deeper 2-3-4 split |
| `btree_debug` | 11 / 2 | a source-repair task; n=256 is repair, n=50 and n=1000 are held out |

`btree_debug` is the repair-loop candidate: its source has three injected
defects, its repair cases include `n=256` where the buggy program
crashes, and the model must return the corrected complete program.

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

## Languages (Phase 4)

`lang.sh` runs the language comparison on the three language-neutral
tasks (`lcs`, `stable_sort`, `calculator`) in C, Python, cocolog and
SWI-Prolog. It is a separate runner: no C result or mode matrix changes.

```sh
./coding/bench/v2/lang.sh --plan
./coding/bench/v2/lang.sh --doctor
./coding/bench/v2/lang.sh --run --tasks lcs --langs python,c --trials 1
```

`--plan` prints the grid and no model call; `--doctor` prints each
language's toolchain and no model call. A run needs
`CODING_ENDPOINT_KEY_ENV` and spends tokens. The default grid is
3 tasks x 4 languages x 3 trials = 36 cells, all in `plain` mode.

What is held identical:

- the task's requirement after its first sentence (which names the
  language and entry point);
- the repair and held-out cases, their order, and the exact output
  policy;
- the task's call budget and the parent repair loop.

What differs, and is a stated confound:

- **The generator is each language's normal one.** C uses
  `codegen_c`, Python `codegen_python`, and cocolog
  `codegen_cocolog`, each with its own guide and obligations. SWI has no
  generator in this tree: its child makes one direct `llm_chat` call
  with a short SWI-Prolog system prompt. The comparison therefore
  measures language *plus its normal guide*, not language alone.
- **The case timeout.** C keeps its 3 s; every other language gets at
  least 10 s, because the pyenv `python3` shim alone takes about 3 s to
  start. This is a timing allowance, not a policy change for C.

Each cell runs one complete program through the same exact matcher and
the same stdout/stderr separation as `verify.pl`. A nonempty stderr is
a failure. The source is written to a temporary directory and run as:

```sh
python3 -I program.py          < in > out 2> err
cocolog run program.pl         < in > out 2> err
swipl -q -f program.pl -g main -t halt < in > out 2> err
```

C compiles with the sanitizer build as before. `PYTHON3` and `SWIPL`
override the two interpreted runtimes. A failed case's diagnostic
includes the offending source line and a caret under the column when the
compiler did not quote the line itself; a cocolog entry goal that exits
nonzero with empty stderr is rerun once under `--trace` and the first
case's report gets the tracer's last failing chain. For cocolog the
generator reads this repository's `coding/cocolog/SKILL.md`, a copy of
the language guide with an added "Codes, parsers and tables" section:
`char_code/2` and the `0'` token, the safe code-parser shape, the
`digits/3` collision with `library(stream)`, and a row-table rule with a
worked LCS program, plus a "Transpiling Python to cocolog" section (a
construct map and a worked BFS). `COCOLOG_SKILL` still overrides the
path. This is a stated, cocolog-only scaffold; the lane rerun with it is
`results/lang-cocolog-skill-20261117.md` (4/9 pass@1, 8/9 final,
362 886 tokens, against 2/9 and 5/9 in the 36-cell run). There is **no
combined score**: the JSONL rows and the per-task/language summary are
the result, and languages are not ranked by one number. The first
comparison ran on 2026-11-17: 36 cells, 22/36 pass@1, 26/36 final,
403 944 tokens; `results/lang-20261117.md` is the record. Treat it as a
pilot: one model, one generator per language and three tasks.

## The translator's IR (an arm of the language runner)

The coding endpoint sends the coding model the translator's reading of the
request, "The request in the translator's IR" (`coding/endpoint/ir_repair.pl`).
The `ir` arm measures what that note does: it is `plain` with the note
after the requirement, and nothing else differs.

```sh
# 1. the translation phase, counted apart: run it until a run makes no call
CODING_ENDPOINT_IR_API=anthropic CODING_ENDPOINT_IR_KEY=... CODING_ENDPOINT_IR_MODEL=... \
    ../cocolog/cocolog --embed coding/endpoint/store -s coding/bench/v2/ir_prep.pl -- \
    --tasks mvccs_acid --langs c,python,cocolog,swipl --out DIR
# 2. the benchmark, which reads the notes and calls no translator
CODING_ENDPOINT_KEY_ENV=... CODING_BENCH_PROVIDER=anthropic CODING_BENCH_MODEL=... \
CODING_BENCH_BASE_URL=https://api.anthropic.com/v1/messages \
    ./coding/bench/v2/lang.sh --run --tasks mvccs_acid --arms plain,ir --ir-notes DIR
```

- **The translation is done first, and none of it is in the benchmark's
  figures.** `ir_prep.pl` reads each language's requirement as the endpoint
  reads a request -- every sentence, where the endpoint reads six -- with
  the model's check and repair, keeps what it learned in the endpoint's
  store, and writes the note to `DIR/TASK-LANG.ir` and its own calls,
  tokens and seconds to `DIR/ir-prep.jsonl`. Run it until a run makes no
  call: the four requirements share every sentence after the first, so a
  later language's request can judge a shared reading an earlier one used
  (the first run's C note changed at the second). The benchmark reads the
  notes from their files; an arm whose note is missing is refused before
  the first call.
- **What the `ir` arm costs is in it**: the note is prompt tokens of every
  call it is in, and the summary gives prompt and completion tokens apart.
- **Within a trial the cells of both arms are shuffled together**, so
  neither arm runs at another hour of the provider's day.
- The note goes after the requirement in the user prompt, where every
  language's generator puts the requirement; the endpoint puts it in the
  system prompt, after the guide. A stated difference.
- `mvccs_acid` is a hard task (`v2_hard_task/1`): the language runner runs
  it when named, its default tasks stay the three, and the C matrix's grid
  does not change. Its budget is the pilot's, three calls and 5000 ms a
  case; cases 6 and 8 are held out, and case 3, the snapshot visibility
  every pilot attempt failed, stays a repair case.
- **A run's provider** is `v2_setting/2`: `CODING_BENCH_PROVIDER`,
  `_MODEL`, `_BASE_URL`, `_EFFORT` and `_MAX_TOKENS` override the facts of
  `config.pl`, which stay the pilots' record. An `anthropic` run sends no
  temperature (`claude-sonnet-5-5` refuses one), effort `low` unless set,
  and 16000 tokens a reply: the model thinks by default, and the thinking
  counts against the limit. Its usage is Anthropic's `input_tokens`,
  `output_tokens` and cache fields.
- **A reply with no text is sent again, once, and counted** (1.15.1,
  `v2_lang_code_replied/6`). `claude-sonnet-5-5`'s safety classifier
  refused three repair attempts of some 400 calls, category
  `reasoning_extraction` (a repair prompt sends the model its own
  previous program): an empty content, or a thinking block and no text.
  Through 1.15.0 each was a generator failure whose tokens were not
  counted. The same requests sent again were answered, and server-side
  fallback does not retry that category on this model. Now the child
  sends it again (with twice the token limit when it stopped at
  `max_tokens`), its tokens go into USAGE, a failed child's USAGE is read
  too, and each row names its `empty_replies` and their `empty_reasons`
  (stop reason, category, blocks).
- **The first run** is `results/ir-mvccs-20261120.md`: 24 cells on
  `claude-sonnet-5-5`, the translation phase's 9 calls apart. Every
  held-out failure there is case 8, whose expected output reads "a
  deletion of an absent key is ignored" against the latest committed
  version and not against the transaction's view. That was an ambiguity
  of the task's text, which said neither. **Since reasoning 1.14.1 the
  text says the rule**: a transaction keeps one staged change per key,
  even one that does not change its view, and the commit applies each to
  the latest committed version. No case's expected output changed (each
  of the ten agrees with the rule), but a run before 1.14.1 read another
  text and is not comparable with a run after it. The run on the clear
  text is `results/ir-mvccs-clear-20261120.md`.
- **The reader notes in Python** are `results/reason-python-20261121.md`
  (reasoning 1.17.1): the requirement said again in controlled English
  (`controlled/`) and what `reason_text/2`, `reason_concepts/2` and
  `reason_topics/2` make of it, each an arm (`reason_prep.pl` writes
  them). The restatement itself did best, 12/20 first programs against
  7/20 with no note (p = 0.21); no reader's note did better than none.
  A second run put the restatement in C and both cocolog lanes
  (`results/controlled-mvccs-20261121/`): no change in C or in cocolog
  without its guide, and 2/20 against 15/20 in cocolog with its guide
  (p = 0.00007).
  `results/controlled-ablation-20261121/` took the note apart there: the
  cause is its four sentences on input (without them 6/10, with them
  0/10); the first programs then match the parts of a line as codes.
- **Controlled English effect on Python codegen** is
  `results/controlled-english-python-20261121.md`: the test written before
  the run, 60 trials an arm. The restatement makes Python's first program
  right 37/60 against 25/60 (Fisher, one-sided, p = 0.022), with 18 %
  fewer calls and 9 % fewer tokens.
  Asked again in `results/controlled-gzip-python-20261121.md`, it did not
  repeat (34/60 against 30/60, p = 0.29); the same note gzipped and sent
  as base64 did nothing (31/60) and cost more tokens than the text.
- **A complete IR** of the restatement (reasoning 1.17.3) is
  `controlled/mvccs_acid.ir`, written by `ir_complete.pl` with no model
  from `controlled/mvccs_acid.translator.txt`: all 64 sentences, 68 IR
  terms, where the endpoint's IR note of the requirement read 5 of 14.
  Tested in `results/complete-ir-20261121.md`, each test written before
  its run: it makes the first program right more often in no lane, and
  in Python far less often (3/60 against 32/60), at 4.4 times the
  tokens.

### The reasoning arms and the cocolog lane without its guide (1.15.0)

Every reasoning coding benchmark here measures one thing: what this
repository's reasoning adds to a coding prompt. The language runner's
three main arms are the endpoint's three settings, at the same model
effort (`low` for `claude-sonnet-5-5`, whose lowest effort that is):

| arm | what follows the requirement | the endpoint's setting |
|---|---|---|
| `plain` | nothing: the prompt forwarded as it is | `-r0`, plain mode |
| `reasoning` | the pre-pass's checks and its "What the request is about" note | the pre-pass without the IR note |
| `reasoning_ir` | those, then "The request in the translator's IR" | the full pre-pass, the endpoint's default |

`ir` (the IR note alone, reasoning 1.14) stays an arm.

- **The notes are the endpoint's own text**, made before the run by
  `ir_prep.pl`: the checks and the about note by `ep_reasoning_notes/7`
  (httpd_core.pl, the code `ep_reasoning/9` sends; the default two
  checks) to `DIR/TASK-LANG.reasoning`, with no model call, and the IR
  note to `DIR/TASK-LANG.ir`. The runner reads them from the files, and an
  arm whose note is missing is refused before the first call. Each row
  gives both notes' lengths (`ir_note_chars`, `reasoning_note_chars`).
- **The default sends two checks of those the readers find** (the
  endpoint's `CODING_ENDPOINT_REASONING_MIN` and `_MAX`, 2 each): 2 of the
  13 in mvccs_acid's C requirement and of the 12 in each other lane's.
  Since 1.15.4 `ir_prep.pl --checks all` writes the note with every check
  the readers find (the endpoint's `count(N)`), `--checks N` with N, and
  `--only reasoning` writes the `.reasoning` notes alone, with no
  translation and no model call. `reason_text/2` reads no term of
  mvccs_acid's requirement, so its "What the request is about" note, which
  `reason_concepts/2` and `reason_topics/2` write, is empty in every lane.
- **The endpoint reads a C, cocolog or Python request.** `cocolog_noguide`
  is read as cocolog, and `swipl`, which has no endpoint model, as cocolog
  too, whose checks are C's (the same keyword reader and contract).
- The notes go after the requirement in the user prompt, where the
  endpoint puts them in the system prompt after the guide: the stated
  difference of the `ir` arm, now of all three.
- **`cocolog_noguide` is cocolog without its guide**: the cocolog
  generator's short `--no-skill` system prompt in place of the guide's
  19 000 tokens, and the `cocolog` lane's requirement, user prompt,
  runtime and verifier (`v2_language_runtime/2`). `cocolog` against
  `cocolog_noguide` is what the guide is worth. `cocolog_noguide` against
  `swipl` is not only the runtime and the language's name: the `swipl`
  generator's user message is the requirement alone, where the cocolog
  generator's begins "Write a complete cocolog program for this
  requirement.", and in the 1.15.1 run 22 of SWI-Prolog's 40 first
  replies began with English notes before the code and did not load. Its notes are the `cocolog` lane's, as the requirement
  is (`ir_prep.pl --langs cocolog_noguide` makes no call). The default
  languages stay the four. **Since 1.15.2 the short prompt names one fact
  of cocolog**: begin with `:- use_module(library(stream)).`, which loads
  the stream predicates. Under 1.15.0's prompt every program of the
  lane's two reasoning arms (20 cells, 60 attempts) called SWI-Prolog's
  `read_line_to_string/2`, `get_char/1` or `get_code/1` without it and
  stopped at the first case, or answered a repair with prose before the
  code; none passed. **Since 1.15.3 it names a second**: begin with
  `:- set_prolog_flag(double_quotes, string).` too. With the import
  alone (1.15.2, 40 cells) no first program passed and 18 cells passed
  by the end: the programs matched `split_string/4`'s strings against
  `"v"` in their clause heads, which cocolog reads as a list of codes by
  default, and printed nothing or `error`. Both are where cocolog is not
  SWI-Prolog 7, the dialect a model that was never trained on cocolog
  writes. With both lines (1.15.3, 40 cells) 24 first programs passed and
  all 40 cells by the end, at 338 045 tokens against the guided lane's
  2 264 582 for its 40 (`results/ir-mvccs-clear-20261120.md`).

## Declarative vs imperative (Phase 5)

`form.sh` runs the paired experiment: for each reasoning task, an
imperative Python 3 program and a cocolog program of facts, relations
and rules. Both forms get the same requirement after its first sentence,
the same repair and held-out cases, the same output policy and the same
budget. The result is a separate question from the language comparison;
there is no combined score.

```sh
./coding/bench/v2/form.sh --plan
./coding/bench/v2/form.sh --doctor
./coding/bench/v2/form.sh --run --trials 3
```

Tasks (`reasoning_schema.pl`):

| task | what | policy |
|---|---|---|
| `reach` | transitive closure over a directed graph | exact |
| `topo` | a topological order of a DAG; any valid order | property |
| `parses` | number of parse trees of `S -> S S \| a \| b` | exact |

`topo` uses a property checker (`v2_topo_check/3`): the output must be a
permutation of the nodes with every edge in order. The same checker is
used by both forms, and its reason reaches the repair diagnostic.

The hypothesis, tasks, cases, budget and analysis are pre-registered in
`prereg-phase5.md` before the first paid run. The stated confounds:
Python is the model's strongest language, cocolog has the repository
guide, and the two forms use different generators. The default grid is
3 tasks x 2 forms x 3 trials = 18 cells.

The first run is `results/form-20261117.md`: the hypothesis was **not
supported**. Imperative Python passed 9/9 at attempt 1; declarative
cocolog passed 1/9 at attempt 1 and 5/9 final, at about 116 times the
tokens and 2.4 times the lines. One `reach` case was malformed in that
run; it was corrected and the `reach` lane rerun, both recorded there.

A Python-to-cocolog **transpiling section** was then added to the
cocolog skill and measured (`results/form-20261117-transpile.md`). It
improves `reach` (declarative 0/3 to 2/3 at attempt 1, 1/3 to 3/3 final,
54 % fewer tokens) but regresses `topo` (3/3 to 0/3 final) and `parses`
(1/3 to 0/3); the net over the three tasks is negative. The section
stays as a general guide for the endpoint, not as a proven improvement
for this lane.

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
--modes A,B     once, plain, derive, contract, extract, full
                (default: config.pl's list, all six)
--trials N      trials per task and mode (default: 3)
--seed N        order seed (default: config.pl's)
--out FILE      JSONL output (default: results/<run id>.jsonl)
--keep DIR      write each cell's spec and each attempt's code, usage and
                verdict under DIR/task/mode/trial-N
--paired        pair once and plain over one shared first attempt
```

`--paired` ignores `--modes`: its arms are fixed as `once` and `plain`.
It writes one `pair` row per task and trial instead of two independent
cells.

`./run.sh` is the same command with `COCOLOG_LIBRARY` set from the
repository's parent.

## Pair once and plain

The separate mode cells are independent samples. For a feedback
comparison, `--paired` makes ONE first call per task and trial, then
branches the same code and diagnostic into:

- `once` -- stop after the first attempt;
- `plain` -- repair with the requirement alone, up to the task's budget.

If the first attempt passes its repair cases, both arms are that result.
The shared first attempt's usage is counted in both arms' totals, as the
legacy `paired.pl` does; the pair row also records it once under
`shared_usage`. A pair row is:

```text
type-pair, task, trial, order_position, seed
first, pair_verdict
shared_usage {prompt, completion, total, reasoning, cache_hit}
once  {outcome, pass_at_1, final_pass, attempts, repair_usage, total_usage}
plain {outcome, pass_at_1, final_pass, attempts, repair_usage, total_usage}
seconds
```

`pair_verdict` is `both_pass`, `plain_pass` or `both_fail`.

## Report a saved run

```sh
./report.sh coding/bench/v2/results/pilot-20261117.jsonl --samples 5000
```

The report always prints the per-task table. Its aggregate is a **cluster
bootstrap over tasks**, not over cells: trials of one task are not
independent samples of the task population. With three tasks the interval
is necessarily wide, so the table is the evidence and the interval is a
warning against reading the aggregate as an estimate. It also prints the
ablation pairs present: `plain` minus `once`, `derive` minus `plain`,
`extract` minus `derive`, `contract` minus `extract` and `full` minus
`contract`, for pass@1 and final pass, with the same bootstrap.

`--seed` defaults to the run's own seed, so a report is reproducible.

## Legacy baseline

The legacy benchmark is frozen and run unchanged by Phase 0's selector:

```sh
./legacy.sh -- [task ...]
```

It sets `COCOLOG_LIBRARY`, runs `coding/bench/bench.pl` and spends model
tokens. `results/baseline.md` records the legacy commit, config and the
existing sample table; no legacy file is edited to make v2 pass.

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
paired arms and their shared usage, the statistics and JSONL reader, the
kept attempt files, and one complete JSONL run with no provider. It also
pins the five task splits, including the corrected `stable_sort` case.
For Phase 4 it checks the language table and spec transformation, runs a
correct LCS through the Python, cocolog and SWI verifiers when the
toolchain is present, strips Markdown fences from model replies, and
writes one Python language-run JSONL through a fixture seam. For Phase 5
it checks the reasoning task declarations and shared form requirements,
the topological property checker and its verifier path, and one paired
form-run JSONL.

## Budget

`config.pl` holds the provider, model, temperature, three-trial pilot and
the seed. Per task, `schema.pl` allows three child calls and a case
timeout; `once` reduces that to one. The default pilot is 5 tasks x 6
modes x 3 trials = 90 cells: at most 240 generator calls plus 15
extraction calls. The pilot is the budget gate: do not start a larger run
until its per-task variance and token cost are known and the spend is
approved.

The legacy benchmark is not edited to make v2 pass. A disagreement
between v2 and a legacy result is recorded before changing either.

## Files

```text
config.pl    provider, model, temperature, trials, seed, results dir;
             v2_setting/2, a run's own provider from CODING_BENCH_*
schema.pl    task declaration, case split, output policy, budget
verify.pl    sanitized compile, repair and held-out runs, output policy
runner.pl    attempts, paired arms, repair diagnostics, seeded order,
             JSONL, summary
gen.pl       one child generator call
run.pl       the runner's main/0
run.sh       the shell entry point
stats.pl     JSONL reader, cluster bootstrap, paired differences
report.pl    the report's main/0
report.sh    the report's shell entry point
langs.pl     Phase 4 language table, spec transformation, verifiers
lang_runner.pl  language cells, attempts and summary
lang_gen.pl  one language generator call (child)
lang_run.pl  the language runner's main/0
lang.sh      the language runner's shell entry point
ir_prep.pl   the translation phase of an IR run: each language's note
reasoning_schema.pl  Phase 5 tasks, cases and property checker
form_runner.pl  Phase 5 paired forms, cells, pairs and summary
form_run.pl  the form runner's main/0
form.sh      the form runner's shell entry point
prereg-phase5.md  the pre-registered hypothesis and tasks
test.pl      no-model checks
legacy.sh    Phase 0 selector for the unchanged legacy benchmark
results/     baseline.md and frozen runs, each with its JSONL and report
```
