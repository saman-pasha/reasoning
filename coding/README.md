# coding

Code generation for the reasoning library, one language a directory:

```
coding/
  options.pl          defaults shared by every generator
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
```

The key comes from the environment -- `REASONING_API_KEY` by default, or
the variable named by `key_env(NAME)` -- never from this repository. The
endpoint and model come from `coding/options.pl`; edit its three facts,
or call `codegen_c/3` from a wrapper with `provider`, `model` and
`base_url` overrides:

```prolog
codegen_c(Spec,
          [provider(openai),
           model('deepseek-flash'),
           base_url('https://api.deepseek.com/v1/chat/completions')],
          Code).
```

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
own (`ok`, or `fail(Diagnostic)`). `codegen_c/2,3` remains the one-shot
call that returns a reply without compiling it. `clang` must be on `PATH`.

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
2. Build a contract prompt: the language, one complete program, code only.
3. Call `llm_chat/3` with `codegen_options/2` and the language's system
   prompt.
4. Strip a Markdown fence, if the model added one.
5. Compile the reply; on failure, return the diagnostic and the previous
   program to the model and try again.
6. Return or write the code.

The C generator is `coding/c/codegen.pl`; it is deliberately small. The
benchmark in `coding/bench/` is where the prompt policy is measured. The
next steps are the ones the architecture needs, not more prompt text:
derive the obligations and tests from the requirement with `reasoning`,
and run the tests as a second check after the compile.
