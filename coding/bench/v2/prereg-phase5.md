# Phase 5 pre-registration: declarative vs imperative

- Date: 2026-11-17
- Status: registered before the first paid run
- Model: `deepseek-flash`, temperature 0, seed `20261117`, 3 trials
- Forms: imperative Python 3 (`codegen_python`) and declarative cocolog
  (`codegen_cocolog`, guide `coding/cocolog/SKILL.md`)
- Budget: 3 generator calls per form and task; 10 s per case; the same
  repair cases, held-out cases and output policy for both forms

## Hypothesis

On the reasoning tasks below, the declarative cocolog form has a higher
final-pass rate than the imperative Python form at the same budget, and
uses no more tokens or program lines. The hypothesis is directional; no
single combined score is computed. The result is reported per task and
form, with the paired difference `declarative - imperative`.

This is a hypothesis about this pipeline, not a claim that one language
is better: Python is the model's strongest language, cocolog has the
repository guide, and the two forms use different generators.

## Tasks (pre-registered)

| task | what | output policy |
|---|---|---|
| `reach` | transitive closure over a directed graph | exact |
| `topo` | a topological order of a DAG; any valid order | property: a permutation with every edge ordered |
| `parses` | number of parse trees of `S -> S S \| a \| b`, modulo 1 000 000 007 | exact |

The cases are in `coding/bench/v2/reasoning_schema.pl`: four repair and
two held-out cases per task. Held-out cases are never shown in a prompt
or a repair diagnostic. The topological property checker is
`v2_topo_check/3`, and both forms use it.

## Analysis

- Per task and form: pass@1, final pass, attempts, tokens, seconds, code
  lines and bytes.
- Paired per task: declarative minus imperative on pass@1, final pass,
  mean tokens and mean lines.
- No aggregate over tasks and no combined language score; this result
  is reported separately from the Phase 4 language comparison.
- A held-out failure is final and is not described to the model.

## Run gate

This registration is committed before the first paid run. The default
grid is 3 tasks x 2 forms x 3 trials = 18 cells. The run starts only
after the code and this file are green and committed.

## Post-run record

The first run is in `results/form-20261117.md`. One `reach` case was
malformed (header `3 3` with two edge lines); it was corrected to `3 2`
and the `reach` lane was rerun. The hypothesis was not supported on the
corrected data: imperative Python passed 9/9 at attempt 1, declarative
cocolog 1/9 at attempt 1 and 5/9 final, at about 116 times the tokens.
The hypothesis and analysis above are unchanged.
