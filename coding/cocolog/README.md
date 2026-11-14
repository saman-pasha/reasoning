# coding/cocolog

`codegen.pl` writes cocolog source from a written requirement. The language
guide is the cocolog checkout's own `SKILL.md`: the whole file goes into the
model's system prompt, so the model reads the dialect, the libraries and the
differences from SWI-Prolog before it writes a line. The current guide is
about 19 000 prompt tokens.

## Run

```sh
export REASONING_API_KEY=...
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/cocolog/codegen.pl -- spec.txt out.pl
```

The default guide is `$COCOLOG_SKILL`, else `../cocolog/SKILL.md`; `--skill
FILE` names another. The provider defaults are `coding/options.pl`'s. For
DeepSeek:

```sh
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/cocolog/codegen.pl -- spec.txt \
    --provider openai --model deepseek-flash \
    --base-url https://api.deepseek.com/v1/chat/completions \
    --effort none --report out.pl
```

| flag | effect |
|---|---|
| `--goal G` | the goal `cocolog run` proves (default `main`) |
| `--skill FILE` | the language guide |
| `--no-skill` | omit the guide and use a short generic cocolog prompt |
| `--expect FILE` | compare the program's standard output with FILE |
| `--attempts N` | try at most N times (default 3) |
| `--timeout MS` | one run's timeout (default 3000) |
| `--budget N` | stop before a repair once N tokens are spent |
| `--keep DIR` | write each attempt's prompt, `.pl` and diagnostic |
| `--dry-run` | print the system and user prompts, no model call |
| `--report` | print calls and token usage to stderr |
| `--key-env`, `--temperature`, `--max-tokens`, `--provider`, `--model`, `--base-url`, `--effort` | as in the C generator |

## What is checked

A reply is a complete cocolog program. It must define `main/0` unless
`--goal` names another goal. The tool writes it to a temporary file and runs

```sh
cocolog run FILE.pl [Goal]
```

under the timeout. A load warning or error on stderr, a failed goal, a
timeout, or a nonzero exit is a failure. With `--expect FILE`, the program's
standard output must match FILE exactly as well. The report and the previous
program go back to the model for another attempt. The prompt tells the model
to output only source; a Markdown fence is stripped.

### The HTML template loader

`examples/html_template/` is a small benchmark: a spec, a page with values,
a condition and a loop, and the expected HTML. Run from this repository's
root with

```sh
../cocolog/cocolog -s coding/cocolog/codegen.pl -- \
    coding/cocolog/examples/html_template/spec.txt \
    --expect coding/cocolog/examples/html_template/expected.html \
    --provider openai --model deepseek-flash \
    --base-url https://api.deepseek.com/v1/chat/completions \
    --effort none --report /tmp/page.pl
```

On 2026-11-14 it passed on the first call: 19 353 prompt tokens (19 072
cached), 76 completion, and the output matched. A first spec without the
explicit `template_file/4` hint produced `template_text/4`, which the
library does not have, in all three attempts; naming the API fixed it.

## Benchmark suite

`coding/cocolog/bench/` runs seven tasks — the template loader, JSON, a DCG,
the program's database, file codes, double-quoted codes and the one-namespace
trap — in `high`, `checked` and `no_skill` modes, with an exact expected
output per task. `no_skill` is the control with the guide omitted. See its
README for the measured table and how to run it.

## API

```prolog
codegen_cocolog(Spec, Code).
codegen_cocolog(Spec, Overrides, Code).          % one call, not run
codegen_cocolog_checked(Spec, Code).
codegen_cocolog_checked(Spec, Overrides, Code).  % run main, repair
codegen_cocolog_from(Spec, Goal, Overrides, RunOptions, Code).
cocolog_skill_text(Text).
cocolog_skill_text(File, Text).
```

`RunOptions` are `attempts(N)`, `timeout(Ms)`, `budget(N)`, `keep(dir(Dir))`,
`skill(File)` and `expect(File)`.

## Checks

`coding/test.pl`'s `cocolog` section reads the guide, generates a mock
program, runs it, checks the repair path, the argument parser and a missing
guide. It calls no model and no network.
