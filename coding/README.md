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

`coding/options.pl` holds the defaults. The two effort names are per
provider, because `library(llm)` treats `effort(L)` and
`reasoning_effort(L)` as the same level and refuses two different ones:

| provider | default | field sent |
|---|---|---|
| Anthropic | `low` | `output_config: {effort: "low"}` |
| OpenAI | `none` | `reasoning_effort: "none"` |

A caller may override either name. Further defaults are one more
`codegen_default/2` fact; the generator fills them in unless the caller
names the same key.

## Run

From this repository's root, with its parent and the cocolog library on
the path:

```sh
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/c/codegen.pl -- spec.txt out.c
```

The key comes from the environment (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`,
or whatever `llm_provider/3` names), never from this repository. A
provider pointed at another endpoint -- DeepSeek, for example -- is
registered with the same dynamic facts `library(llm)` documents.

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
