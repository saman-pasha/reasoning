# mvccs_acid diagnostic, 2026-11-17

- Code commit: `15a13e7` (`reasoning 1.8.10`, with `--keep`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Cell: `mvccs_acid/plain`, trial 1, seed `20261117`
- Budget: 3 child calls; 5000 ms per case
- Result: `fail_repair` after 3 attempts, 23 517 tokens, 53.9 s
- JSONL: `mvccs-diag-20261117.jsonl`
- Kept attempts: `/tmp/v2-mvccs-diag/mvccs_acid/plain/trial-1/` at run time

## The failure

Every attempt failed only repair case 3, the snapshot-visibility case:

```text
b T1
i T1 1
c T1          commit 1
b T2          T2's snapshot is commit 1
b T3
i T3 2
c T3          commit 2
r T2 1        expected yes
r T2 2        expected no   <-- actual yes
c T2
b T4
r T4 1
r T4 2
v             3
```

The model's program reads the latest committed version from inside a
transaction instead of the version at the transaction's snapshot. It
passes every other command of the case, so this is not formatting, a
timeout, a compiler error or a verifier defect.

## The attempts

| attempt | prompt | completion | total | code sha256 (first 12) | result |
|---|---|---|---|---|---|
| 1 | 495 | 4 357 | 4 852 | `085514a44474` | case 3 |
| 2 | 4 981 | 4 357 | 9 338 | `085514a44474` | case 3 |
| 3 | 4 981 | 4 346 | 9 327 | `fcd92713fcf3` | case 3 |

Attempts 1 and 2 are byte-identical. Attempt 3 differs only in brace and
line layout; its snapshot semantics are the same. Attempts 2 and 3 were
given the exact expected/actual difference for case 3 in the repair
prompt and still reproduced it.

## Decision

A larger call budget is not supported by this evidence. Four calls would
buy another rewrite of the same semantics, at roughly 8-9 thousand tokens
each. `mvccs_acid` is removed from the Phase 1 trio and kept for a later
hard-task or reasoning-effort suite, where the cost of a deliberate
attempt is the object of study.

`calculator` replaces it: operator precedence, left-associative
subtraction and parentheses, with a clean stdin/stdout contract and two
held-out cases. The next paid run is a fresh three-trial pilot of the new
trio and needs its spend approved.
