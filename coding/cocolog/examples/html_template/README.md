# HTML template loader

A benchmark for `coding/cocolog/codegen.pl`: load `page.html` with
`library(template)`, render it in HTML format with the context in `spec.txt`,
and print the result exactly. `expected.html` is the oracle.

Run from this repository's root:

```sh
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/cocolog/codegen.pl -- \
    coding/cocolog/examples/html_template/spec.txt \
    --expect coding/cocolog/examples/html_template/expected.html \
    --provider openai --model deepseek-flash \
    --base-url https://api.deepseek.com/v1/chat/completions \
    --effort none --report /tmp/page.pl
```

The result on 2026-11-14 was one call: 19 353 prompt tokens (19 072 served
from cache), 76 completion, 2.41 s, and the output matched. The generated
program is `generated.pl` (a copy of that run), which also passes:

```sh
../cocolog/cocolog run coding/cocolog/examples/html_template/generated.pl \
    | diff - coding/cocolog/examples/html_template/expected.html
```

A first spec that did not name `template_file/4` produced
`template_text/4`—a predicate the library does not have—in all three
attempts. The spec now names the call, and the model uses it. This is the
value of the `--expect` check: a program that loads and prints the wrong
page is refused.
