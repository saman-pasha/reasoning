# v2 cocolog lane with the repository skill, 2026-11-17

- Run: `v2-lang-1794918314090`
- Commit: `bec66c4` (`reasoning 1.8.22` at HEAD); the skill-file move
  was uncommitted at run time and is committed with this report
  (`reasoning 1.8.23`)
- Model: `deepseek-flash`, provider `openai`, temperature 0
- Tasks: `lcs`, `stable_sort`, `calculator`
- Language: cocolog only
- Trials: 3 per task, seed `20261117`
- Mode: `plain` (up to 3 generator calls per cell)
- JSONL: `lang-cocolog-skill-20261117.jsonl`
- Total: 9 cells, 362 886 tokens, 102.7 s of cell time

The guide the generator reads is this repository's
`coding/cocolog/SKILL.md`, a copy of the cocolog repository's
`SKILL.md` with one added section, "Codes, parsers and tables":

- a character is not a number: `char_code/2`, or keep the codes;
- a character code is `0'` followed by the character, with no quote
  after it;
- the safe code-parser shape: three `skip_spaces` clauses, recursion on
  the parenthesis's tail, a digit base with no empty-rest guard,
  `number_codes/2`, and no `digits/3` (`library(stream)` defines it);
- a row table returns the row it just built, with a worked longest
  common subsequence program.

The generator's default skill path is now `coding/cocolog/SKILL.md`;
`COCOLOG_SKILL` still overrides it. This is a cocolog-only guide change.

## Results

| task | trial | pass@1 | final | outcome | attempts | tokens | seconds |
|---|---|---|---|---|---|---|---|
| `calculator` | 1 | no | yes | `pass` | 2 | 43 488 | 12.8 |
| `lcs` | 1 | yes | yes | `pass` | 1 | 20 495 | 5.7 |
| `stable_sort` | 1 | no | yes | `pass` | 3 | 64 080 | 18.4 |
| `lcs` | 2 | yes | yes | `pass` | 1 | 20 500 | 5.7 |
| `calculator` | 2 | no | yes | `pass` | 2 | 43 532 | 12.3 |
| `stable_sort` | 2 | no | yes | `pass` | 3 | 64 093 | 18.5 |
| `calculator` | 3 | yes | yes | `pass` | 1 | 20 827 | 6.8 |
| `lcs` | 3 | yes | yes | `pass` | 1 | 20 488 | 5.1 |
| `stable_sort` | 3 | no | no | `fail_repair` | 3 | 65 383 | 17.5 |

| task | pass@1 | final | attempts | tokens |
|---|---|---|---|---|
| `lcs` | 3/3 | 3/3 | 3 | 61 483 |
| `calculator` | 1/3 | 3/3 | 5 | 107 847 |
| `stable_sort` | 0/3 | 2/3 | 9 | 193 556 |
| all | 4/9 | 8/9 | 17 | 362 886 |

The published cocolog lane (before the guide, `lang-20261117.md`) was
2/9 pass@1, 5/9 final, 385 659 tokens. With the repository skill it is
4/9 pass@1, 8/9 final, 362 886 tokens.

## What it says

- **`lcs` is now 3/3 on the first attempt**, and its held-out cases
  pass, including the empty second line. This is a guided result: the
  skill carries a complete correct LCS program, so the lane measures
  whether the model follows the guide, not whether it can derive LCS.
- **`calculator` is 3/3 final** (one first-attempt pass, two two-attempt
  repairs), against 0/3 final before the guide. The parser rules and the
  `digits/3` collision were the blockers.
- **`stable_sort` is 2/3 final**, with trial 3 failing all three
  attempts. The added guidance does not address sorting; the model still
  has a repair failure there.
- **The guide is not a combined score and not an unaided language
  result.** It is a cocolog-only, task-specific scaffold; the C, Python
  and SWI lanes are unchanged. The 36-cell table in `lang-20261117.md`
  remains the record from before it.

The test suite pins the skill file, its added section and the full
guide's presence in the generator's default path (204 checks, GREEN).
