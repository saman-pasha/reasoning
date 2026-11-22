# Lessons

The reasoning lessons, moved here from cocolog's library tutorial
track with the library. Run one from this repository's root, with the
repository's PARENT directory on the library path (the module names are
`library(reasoning/...)`):

    COCOLOG_LIBRARY="$(dirname "$PWD")${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}" \
        ../cocolog/cocolog -s tutorials/01-reason.pl

(`sh run-tests.sh` does the same for the test cases.)

| file | library | what it teaches | needs |
|---|---|---|---|
| 01-reason | `reason.pl` | a paragraph of controlled English as predicates, questions as goals, an explanation as the whole proof | nothing |
| 02-normalise | `normalise.pl` | the training data for the tagger: shapes with gold tags, the noise transforms, the round trip | nothing |
| 03-tagger | `tagger.pl` | prose in, `reason.pl`'s terms out: the network, trained and measured | `sh modules/torch/build.sh` |
| 04-translate | `translate.pl` | a sentence read on one language's side and written on another's, through an IR that is English | nothing |
| 05-live | `live.pl` | a reader's two modes: static, and live, which asks a model (a stub here) about the reading, saves what it teaches and reads again with it -- and static mode reads what was saved; and `reason_restate/2,3`, a text said again in the grammar's own sentences | nothing |
| 06-typology | `typology.pl` | a language as a filled template: every order of a level, a language's choice among them, and one grammar that reads every language into the IR and writes the IR into every language, with the word tables the vocabularies fill, forms chosen by sound, a word with several meanings read by the words around it and the topics of its context, questions, and the repair of a sentence the template does not allow | nothing |
