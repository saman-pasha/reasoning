# coding

Code generation for the reasoning library, one language a directory:

```
coding/
  options.pl          defaults shared by every generator
  obligations.pl      the checks a requirement's words imply
  compile.pl          the compile checker and case runner
  test.pl             the coding helpers' checks
  c/
    codegen.pl        C17 code from a written requirement
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
| `--provider P` | `provider(P)` in the call |
| `--model M` | `model(M)` in the call |
| `--base-url U` | `base_url(U)` in the call |
| `--effort E` | `effort(E)` in the call |
| `--report` | print calls and token usage to stderr |

The provider, model and base URL are one setting: a provider chosen alone
keeps `library(llm)`'s model and endpoint for that provider, so pass all
three when changing provider. A flag said again keeps its last value. The
same overrides are available to a Prolog caller:

```prolog
codegen_c(Spec,
          [provider(openai),
           model('deepseek-flash'),
           base_url('https://api.deepseek.com/v1/chat/completions')],
          Code).
```

`codegen_report/1` answers
`report(Calls, Prompt, Completion, Reasoning, Total)` for the last
top-level generation; `--report` prints the same line to stderr, leaving
stdout for the program.

## Compile and repair

`main/0` does not return the first reply. It compiles the reply with
`clang -std=c17 -Wall -Wextra -O0`, and on a failure sends the compiler's
diagnostic and the previous program back to the model, up to three
attempts. If no reply compiles it prints the last diagnostic and exits 1.
The same policy is available to a Prolog caller:

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
is off: a one-shot program's leak is no answer's business. The file is one
Prolog term:

```prolog
cases([case('1 2 3\n', '6'),
       case('4 5\n', '9')]).
```

Each case is `case(Input, Expected)`, both atoms; `Input` keeps its
newlines, and both sides are compared after trailing whitespace and final
newlines are trimmed, as the benchmark does. A wrong answer goes back to
the model with the case report and the previous program, just as a failed
compile does. A bad cases file is refused before any model call.

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

## Obligations

Before the first call, `codegen_c_compiled/2,3` and `codegen_c_tested/3,4`
read the requirement's own words with `coding/obligations.pl` and add a
checklist to every attempt. The reading is deterministic and costs no
model call: a `line` the program reads is read whole, a `word` is a run of
ASCII letters, a `subsequence` is not a substring, a `subarray` is
contiguous and non-empty, a `sort` with `descending` is descending, and
equal keys under `stable` keep their input order. A word must match whole,
so `assortment` is not `sort` and `deadline` is not `line`, and a line the
program *prints* is told from one it *reads* by where the words stand
relative to the input and output verbs. `codegen_c/2,3` keeps its plain
prompt; the checklist belongs to the verified paths.

`coding/test.pl` holds the checks: the word boundaries, the lines each
benchmark task's requirement implies, the guided prompt, the compile
checker, the case runner and the cases file. Run it from this repository's
root with the cocolog library on the path.

## Benchmark

`coding/bench/` measures DeepSeek's high reasoning against six
no-reasoning verification loops on eight small C tasks: the requirement
alone, the requirement with obligations derived from a hand-written
controlled-English contract, obligations extracted from it by a model,
obligations derived from its keywords without a model, obligations added
after one failed attempt, and obligations added only after two.
`coding/bench/run.sh` sets the colon-separated `COCOLOG_LIBRARY` and runs
the seven modes; `coding/bench/paired.sh` runs the paired comparison, where
one first attempt branches into a plain repair and an obligation repair.
See its README for the modes, the token columns and sample runs.

## Shape of a generator

1. Read the requirement.
2. Derive the checks its words imply; no model call.
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
benchmark in `coding/bench/` is where the prompt policy is measured. The
next step is deriving cases from the requirement, so the tool can test
without a hand-written cases file.
