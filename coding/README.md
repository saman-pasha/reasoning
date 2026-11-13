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
| `effort` (Anthropic) | `low` |
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
ones. The key variable is `REASONING_API_KEY` unless `key_env(NAME)` names
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

## Shape of a generator

1. Read the requirement.
2. Build a contract prompt: the language, one complete program, code only.
3. Call `llm_chat/3` with `codegen_options/2` and the language's system
   prompt.
4. Strip a Markdown fence, if the model added one.
5. Return or write the code.

The C generator is `coding/c/codegen.pl`; it is deliberately small. The
next steps are the ones the architecture needs, not more prompt text:
derive the obligations and tests from the requirement with `reasoning`,
compile the reply with `cicilang`, and repair on the diagnostic.
