# Python-to-cocolog transpiling guide, 2026-11-17

The cocolog skill now carries a "Transpiling Python to cocolog" section:
a construct map (function → predicate and output argument, loop →
recursion and accumulator, `if` → if-then-else, `==` → `=:=`, `print` →
`format`, `int` → `number_codes`, comprehensions → `findall`, and so
on), two traps (a singleton variable is a warning that fails the exact
policy; a predicate a library defines is silently ignored), and a worked
Python BFS-to-cocolog program. The hypothesis was that this would let a
model trained on Python reach the declarative form's targets.

## Runs

- Reach: `v2-form-1794924652551`, commit `bab09aa`, 6 cells,
  89 560 tokens.
- `topo` and `parses`: `v2-form-1794924736475`, commit `bab09aa`,
  12 cells, 410 304 tokens.
- Both were taken with the transpiling section uncommitted; it is
  committed with this report (`reasoning 1.8.27`).
- JSONL: `form-20261117-reach-transpile.jsonl` and
  `form-20261117-transpile-parses-topo.jsonl`.
- Model, temperature, seed, cases and budget are the Phase 5 ones; only
  the cocolog guide changed.

## Before and after

| task | form | pass@1 | final | tokens | lines |
|---|---|---|---|---|---|
| `reach` | imperative | 3/3 | 3/3 | 1 353 | 31.0 |
| `reach` | declarative before | 0/3 | 1/3 | 192 899 | 60.3 |
| `reach` | declarative after | **2/3** | **3/3** | **88 207** | **42.7** |
| `topo` | imperative | 3/3 | 3/3 | 1 257 | 29.0 |
| `topo` | declarative before | 1/3 | 3/3 | 110 583 | 78.0 |
| `topo` | declarative after | 0/3 | 0/3 | 203 467 | 57.0 |
| `parses` | imperative | 3/3 | 3/3 | 1 525 | 25.3 |
| `parses` | declarative before | 0/3 | 1/3 | 175 983 | 63.3 |
| `parses` | declarative after | 0/3 | 0/3 | 204 055 | 66.7 |

"Before" is `form-20261117.md`; "after" is the two runs above.
`tokens` are sums over three trials and `lines` are means per cell.

## What it says

- **The idea works for the task whose example the guide carries.** The
  `reach` declarative form went from 0/3 to 2/3 at attempt 1 and 1/3 to
  3/3 final, and its tokens fell 54 %. Its earlier failure was a correct
  program rejected for a singleton-variable warning; the guide's
  no-warning rule and the BFS example address exactly that.
- **It does not transfer to the other two tasks.** `topo` fell from 3/3
  final to 0/3, and `parses` from 1/3 to 0/3. Their declarative code
  changed approach and fails earlier; the BFS example appears to anchor
  the model, and the added text does not help a source-picking
  topological sort or a parse-count recurrence.
- **The net over the three tasks is negative.** Declarative final passes
  fall from 5/9 to 3/9, tokens rise from 479 465 to 495 729, and the
  line count falls (67.2 to 55.5). The pass@1 count rises from 1/9 to
  2/9. The imperative form is unchanged (9/9 at attempt 1).
- **This is a guide-following result, not an unaided language result.**
  The BFS example is task scaffolding; the cocolog guide is longer by
  about 1 000 tokens per call; the sample is three tasks and three
  trials.

## Decision

The section stays in `coding/cocolog/SKILL.md` as a general guide for
the endpoint's cocolog model, but it is **not** a proven improvement for
the Phase 5 declarative lane. The Phase 5 result in
`form-20261117.md` remains the primary record. The next refinements, if
wanted, are a worked topological-sort and parse-count example (more
scaffolding), the mapping table without the BFS example (to test whether
the example is the anchor), or a task-conditional guide.

The test suite is 221 checks GREEN and pins the new section.
