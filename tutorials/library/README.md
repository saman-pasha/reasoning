# Lessons

The four reasoning lessons, moved from cocolog's `tutorials/library/` with the
library. Run one from this repository's root, with the repository's PARENT
directory on the library path (the module names are `library(reasoning/...)`):

    COCOLOG_LIBRARY="$(dirname "$PWD")${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}" \
        ../cocolog/cocolog -s tutorials/library/43-reason.pl

(`sh run-tests.sh` does the same for the test cases.)

| file | library | what it teaches | needs |
|---|---|---|---|
| 43-reason | `reason.pl` | a paragraph of controlled English as predicates, questions as goals, an explanation as the whole proof | nothing |
| 44-normalise | `normalise.pl` | the training data for the tagger: shapes with gold tags, the noise transforms, the round trip | nothing |
| 45-tagger | `tagger.pl` | prose in, `reason.pl`'s terms out: the network, trained and measured | `sh modules/torch/build.sh` |
| 46-translate | `translate.pl` | a sentence read on one language's side and written on another's, through an IR that is English | nothing |
