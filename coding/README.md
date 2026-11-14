# coding

Code generation for the reasoning library, one language a directory:

```
coding/
  options.pl          defaults shared by every generator
  obligations.pl      the checks a requirement's words imply
  contract.pl         obligations from controlled-English sentences
  compile.pl          the compile, analyzer and case checks
  test.pl             the coding helpers' checks
  c/
    codegen.pl        C17 code from a written requirement
    check.pl          compile and test an existing C file, no model
  cocolog/
    codegen.pl        cocolog source, taught by cocolog's SKILL.md
```

A new language is a new directory and a `codegen.pl` beside this one; it
loads `coding/options.pl` and hands its options to `llm_chat/3`.

## Defaults

`coding/options.pl` holds the defaults:

| key | default |
|---|---|
| `provider` | `anthropic` |
| `model` | `claude-sonnet-4-5` |
| `base_url` | `https://api.anthropic.com/v1/messages` |
| `effort` (Anthropic) | `none` |
| `reasoning_effort` (OpenAI) | `none` |
| `key_env` | `REASONING_API_KEY` |

The provider, model and base URL are one setting; change the three facts
together. For DeepSeek over its OpenAI-compatible endpoint:

```prolog
codegen_default(provider, openai).
codegen_default(model, 'deepseek-flash').
codegen_default(base_url, 'https://api.deepseek.com/v1/chat/completions').
```

A local OpenAI-compatible server uses the same shape with
`http://127.0.0.1:8000/v1/chat/completions`. The URL is the full request
endpoint, not only the host or the `/v1` root.

`provider(P)`, `model(M)` and `base_url(U)` in a call override the facts.
A provider chosen only in the call keeps `library(llm)`'s endpoint and
default model unless `model(M)` or `base_url(U)` is given too. The two
effort names are per provider, because `library(llm)` treats `effort(L)`
and `reasoning_effort(L)` as the same level and refuses two different
ones; both default to `none`, so a caller asks for reasoning explicitly.
The key variable is `REASONING_API_KEY` unless `key_env(NAME)` names
another. Further defaults are one more `codegen_default/2` fact; the
generator fills them in unless the caller names the same key.

## Run

From this repository's root, with its parent and the cocolog library on
the path:

```sh
export REASONING_API_KEY=...
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/c/codegen.pl -- spec.txt out.c

COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/c/codegen.pl -- spec.txt --tests cases.pl out.c

COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/c/check.pl -- out.c --tests cases.txt
```

The key comes from the environment -- `REASONING_API_KEY` by default, or
the variable named by `key_env(NAME)` -- never from this repository. The
endpoint and model come from `coding/options.pl`, or from the command
line, so a one-off DeepSeek run needs no edit:

```sh
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/c/codegen.pl -- spec.txt \
    --provider openai --model deepseek-flash \
    --base-url https://api.deepseek.com/v1/chat/completions \
    --effort none --report out.c
```

| flag | effect |
|---|---|
| `--tests FILE` | run the cases in FILE after compiling |
| `--auto-tests` | ask the model for test cases, then run them |
| `--cases-effort L` | reasoning effort for the auto case and reference calls (default `high`) |
| `--verify-provider P` | provider for the reference check (default: the code call's) |
| `--verify-model M` | model for the reference check (default: a second model of the same provider where the pair is known) |
| `--verify-base-url U` | endpoint for the verification provider |
| `--verify-key-env NAME` | key variable for the verification provider |
| `--contract FILE` | take the checklist from controlled-English FILE |
| `--keep DIR` | write every attempt's prompt, code and diagnostic |
| `--attempts N` | try at most N times (default 3) |
| `--timeout MS` | let one case run MS milliseconds (default 3000) |
| `--budget N` | stop before a repair once N tokens are spent |
| `--cflags FLAGS` | extra clang arguments (default none) |
| `--analyze` | run `clang --analyze` before accepting a reply |
| `--dry-run` | print the first prompt and exit, no model call |
| `--key-env NAME` | read the API key from NAME |
| `--temperature T` | `temperature(T)` in the call |
| `--max-tokens N` | `max_tokens(N)` in the call |
| `--provider P` | `provider(P)` in the call |
| `--model M` | `model(M)` in the call |
| `--base-url U` | `base_url(U)` in the call |
| `--effort E` | `effort(E)` in the call |
| `--report` | print calls and token usage to stderr |

The provider, model and base URL are one setting: a provider chosen alone
keeps `library(llm)`'s model and endpoint for that provider, so pass all
three when changing provider. A flag said again keeps its last value.
`--key-env NAME` only picks the variable; the key is still read from the
environment, never from the repository. The same overrides are available
to a Prolog caller:

```prolog
codegen_c(Spec,
          [provider(openai),
           model('deepseek-flash'),
           base_url('https://api.deepseek.com/v1/chat/completions')],
          Code).
```

`codegen_report/1` answers
`report(Calls, Prompt, Completion, Reasoning, CacheHit, Total, Seconds)`
for the last top-level generation: the tokens the provider reported, the
prompt tokens it served from cache, and the loop's wall time.
`codegen_report_calls/1` answers one
`call(Seconds, Prompt, Completion, Reasoning, CacheHit, Total)` per
provider call, in order. `--report` prints a line for each call and then
the totals line, all to stderr, leaving stdout for the program.

`--keep DIR` creates the directory if needed and writes each attempt as
`attempt-N.prompt.txt`, `attempt-N.c` and, when it failed,
`attempt-N.diag.txt`. The files are written before a failure is thrown, so
the last candidate survives a refused run. `codegen_c_from/6` takes a run
options list -- `keep(dir(Dir))`, `attempts(N)`, `case_timeout(Ms)`,
`cflags(Flags)`, `budget(N)`, `analyze(yes)` -- and `codegen_c_from/5`
uses the defaults. `attempts` counts the first call; `case_timeout` is one
case's run time, after compilation; `cflags` are extra clang arguments
such as `-lm` or `-DNDEBUG`; `budget` stops before a repair once the
provider's total tokens reach N. It does not abort a call in flight and
does not fail a program that already passed; `analyze` puts the reply
through `clang --analyze` after the other checks.

`--dry-run` prints the first prompt -- the requirement and its checklist --
and exits 0 without calling the model or writing OUT.c. `--contract` is
honored, so a bad contract still fails; `--tests` is not read.

## Compile and repair

`main/0` does not return the first reply. It compiles the reply with
`clang -std=c17 -Wall -Wextra -O0`, and on a failure sends the compiler's
diagnostic and the previous program back to the model, up to three
attempts. If no reply compiles it prints the last diagnostic and exits 1.
`--analyze` also puts every reply through `clang --analyze`; a finding is
repaired like a failed compile and ends a refused run as
`analyze_failed`. The same policy is available to a Prolog caller:

```prolog
codegen_c_compiled(Spec, Code).
codegen_c_compiled(Spec, Overrides, Code).
```

`codegen_c_compiled/2,3` throws
`error(codegen_error(compile_failed, Diagnostic), _)` when the third reply
still fails, and `c_compile_check(Code, Verdict)` is the checker on its
own (`ok`, or `fail(Diagnostic)`); it lives in `coding/compile.pl` so a
caller can use it without the generator. `codegen_c/2,3` remains the
one-shot call that returns a reply without compiling it. `clang` must be
on `PATH`.

## Tests

A compiling program can still be wrong, so `--tests CASES.txt` runs it.
The cases binary is built with AddressSanitizer and
UndefinedBehaviorSanitizer (`-fsanitize=address,undefined
-fno-sanitize-recover=all`), so an out-of-bounds read or a signed overflow
fails a case even when the printed answer happens to match. Leak detection
is off: a one-shot program's leak is no answer's business. The file is
text blocks:

```text
# input
1 2 3
# expected
6
# input
4 5
# expected
9
```

`# input` starts a case and `# expected` starts its expected output; the
next `# input` starts the following case. `# input` immediately followed
by `# expected` is no input at all; a blank line between them is an empty
line (one newline). An empty expected is `# expected` with nothing before
the next block. Any other line is content, even one beginning `#`.
An expected exit status is optional: `# exit N` after the expected block,
before the next `# input`. A timeout never passes, even when `N` is 124.

The Prolog term form is accepted too:

```prolog
cases([case('1 2 3\n', '6'),
       case('4 5\n', '9', 2)]).
```

Each case is `case(Input, Expected)` or `case(Input, Expected, Exit)`,
the atoms and an exit status that defaults to 0; `Input` keeps its
newlines, and both sides are compared after trailing whitespace and final
newlines are trimmed, as the benchmark does. One case may run for 3000 ms
unless `--timeout` says otherwise. A wrong answer goes back to
the model with the case report and the previous program, just as a failed
compile does. A bad cases file is refused before any model call.

`--auto-tests` asks the model for 6 to 10 cases in exactly this format
before the first code call, with `high` reasoning unless
`--cases-effort` names another level. It then asks a second model for an
independent reference program from the same requirement, compiles it with
the sanitizers, and drops every case whose expected output the reference
does not reproduce. The second model defaults to `deepseek-reasoner` for
`deepseek-flash` and `claude-opus-5-5` for `claude-sonnet-4-5`;
`--verify-model` names another model. The provider, endpoint and key are
the code call's unless `--verify-provider`, `--verify-base-url` and
`--verify-key-env` name others; with a provider named, `--verify-model`
defaults to that provider's model (`claude-opus-5-5` or
`deepseek-reasoner`). `--keep DIR` writes the verified cases to
`auto-cases.txt`, the dropped ones to `auto-cases-rejected.txt`, and the
reference program to `reference.c`. The report prints
`reference model M via P`. `codegen_cases/2,3,4` exposes the raw case
call on its own.

```prolog
codegen_c_tested(Spec, Cases, Code).
codegen_c_tested(Spec, Cases, Overrides, Code).
```

`codegen_c_tested/3,4` also carries the obligation checklist. It throws
`error(codegen_error(test_failed, Diagnostic), _)` when the third reply
still answers a case wrong or reports undefined behaviour (a compile
failure keeps `compile_failed`). `c_test_check(Code, Cases, Verdict)` is
the combined check on its own (`ok`, `fail(compile, Diagnostic)` or
`fail(test, Diagnostic)`), and `c_read_cases(File, Cases)` reads and
validates the cases file; both are in `coding/compile.pl`.

## Check

`coding/c/check.pl` is the verifier without the generator. It compiles an
existing C file, and with `--tests` builds it with the sanitizers and runs
every case. No model is called. It prints `OK` and exits 0, or the
compiler/test report and exits 1; `--timeout MS` is one case's run time,
and `--cflags FLAGS` are extra compiler arguments. Without `--tests` it is
the plain compile check. `--analyze` runs `clang --analyze` first; a
finding is printed and exits 1, and with `--tests` the cases run after a
clean analysis.

```sh
cocolog -s coding/c/check.pl -- out.c --tests cases.txt
cocolog -s coding/c/check.pl -- out.c --analyze
```

## Obligations

Before the first call, `codegen_c_compiled/2,3` and `codegen_c_tested/3,4`
read the requirement's own words with `coding/obligations.pl` and add a
checklist to every attempt. The reading is deterministic and costs no
model call: a `line` the program reads is read whole, a `word` is a run of
ASCII letters, a `subsequence` is not a substring, a `subarray` is
contiguous and non-empty, a `sort` with `descending` is descending, and
equal keys under `stable` keep their input order. Beyond those it also
reads a file, a string, floating point and decimal places, a matrix, an
allocation, recursion, a separator and an uppercase conversion. A word
must match whole, so `assortment` is not `sort` and `deadline` is not
`line`, and a line the program *prints* is told from one it *reads* by
where the words stand relative to the input and output verbs. `codegen_c/2,3` keeps its plain
prompt; the checklist belongs to the verified paths. A `--contract` file
replaces this keyword reading with the reasoner's own, below.

`coding/test.pl` holds the checks: the word boundaries, the lines each
benchmark task's requirement implies, the contract reader, the guided
prompt, the compile checker, the case runner and the cases file. Run it
with `sh run-tests.sh coding` from this repository's root; the case skips
itself when `clang` is not on the path.

## Contracts

`--contract CONTRACT.txt` replaces the keyword reading with sentences in
the controlled English `library(reasoning/reason)` parses. The rules in
`coding/contract.pl` turn what the reader parses into obligations:

```text
Every program has an input.
Every program has an output.
Balanced reads the line.
Every line has a bracket.
Every line has a length.
```

The accepted shapes are listed at the top of `coding/contract.pl`:
`Every X has a Y.`, `NAME reads the Y.`, `NAME prints the Y.`,
`NAME sorts the Y.`, `NAME has a Y.`, `Every sum is even.`, and the
subarray/subsequence bodies. The vocabulary now also covers the general C
checks the keyword reader knows: file, string/character, float/decimal,
precision, matrix, allocation, recursion, separator and uppercase. A line
the reasoner refuses is dropped; a sentence it reads but the rules do not
know adds no line. A contract the reasoner reads as no obligation at all
is an error (`contract_empty`), not a silent fallback. The same
obligations are available to a caller as
`codegen_contract_obligations(Text, Obligations)`, and
`codegen_c_from/5` runs the loop with a checklist the caller supplies.
The benchmark's contract, extract and derive modes use the same
`coding/contract.pl` reader and vocabulary, so the tool and the benchmark
cannot drift.

## cocolog

`coding/cocolog/codegen.pl` writes cocolog source instead of C. Its system
prompt carries the cocolog checkout's `SKILL.md` whole—the dialect, the
libraries and the differences from SWI-Prolog—so the model writes the
language the guide describes. A reply must define `main/0` (or the goal
`--goal` names); the tool writes it to a temporary file and runs
`cocolog run` before accepting it, repairing a warning, a failed goal or an
error like the C loop; `--expect FILE` also compares its standard output.
The guide is `$COCOLOG_SKILL`, else `../cocolog/SKILL.md`, or `--skill
FILE`. See `coding/cocolog/README.md` for the flags, the API and the checks,
and `coding/cocolog/bench/` for the seven-task benchmark suite and its
`no_skill` control.

## Benchmark

`coding/bench/` measures DeepSeek's high reasoning against six
no-reasoning verification loops on eleven small C tasks: the requirement
alone, the requirement with obligations derived from a hand-written
controlled-English contract, obligations extracted from it by a model,
obligations derived from its keywords without a model, obligations added
after one failed attempt, and obligations added only after two.
`coding/bench/run.sh` sets the colon-separated `COCOLOG_LIBRARY` and runs
the seven modes; `coding/bench/paired.sh` runs the paired comparison, where
one first attempt branches into a plain repair and an obligation repair;
`coding/bench/tool.sh` runs the shipped tool itself over the same tasks.
See its README for the modes, the token columns and sample runs.

## Shape of a generator

1. Read the requirement.
2. Derive the checks: its words by keyword, or a controlled-English
   contract through the reasoner; no model call.
3. Build a contract prompt: the language, one complete program, code only,
   and the checklist.
4. Call `llm_chat/3` with `codegen_options/2` and the language's system
   prompt.
5. Strip a Markdown fence, if the model added one.
6. Compile the reply; on failure, return the diagnostic and the previous
   program to the model and try again.
7. If cases are given, run them under the sanitizers and repair a wrong
   answer or a report the same way.
8. Return or write the code.

The C generator is `coding/c/codegen.pl`; it is deliberately small. The
benchmark in `coding/bench/` is where the prompt policy is measured.
`--auto-tests` removes the hand-written cases file: the model writes the
cases, and a second model—optionally through a second provider—writes a
reference program that drops the cases it contradicts. The remaining
limit is an error both models share; a second model family would close it.
