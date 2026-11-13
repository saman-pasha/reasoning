# library/reasoning/corpus

Controlled English that TEACHES, kept as data: one file a lesson, one
sentence a line, in the English `library(reasoning/reason)` reads -- a word
between quotation marks is MENTIONED and stands for itself, so `The noun
"casa" means "house".` is `noun(casa), mean(casa, house)`. A line beginning
`#` is a comment.

| file | what |
|---|---|
| `spanish.txt` | the Spanish lesson of `test/translate.pl` and `tutorials/library/46-translate.pl`: 183 lines, the vocabulary as facts about words, the grammar as rules over the classes -- the auxiliary of the progressive (`The auxiliary "está" means "is"`) among them, because a vocabulary cannot say which `is` it is |
| `italian.txt` | the Italian lesson learned beside it under its own name: 130 lines -- the articles, the copula and the two auxiliaries in their forms, the negation, the question words, the pronouns, the possessives, the prepositions and their contractions |
| `vocabulary/spanish.txt` | the VOCABULARY, written by `build.pl` and never by hand: some 127 000 lesson lines in the same shapes -- 22 000 words with their genders, plurals, persons and every verb's forms (the conditional, the infinitive and the gerund since 1.2.43, the participle in its four forms since 1.6.1, the subjunctive since 1.6.8, the imperative since 1.6.10), the modals, the demonstratives, the determiners and the pronouns that stand alone, the numbers, and `hay` as `there is` -- out of Apertium's dictionaries |
| `vocabulary/italian.txt` | the same for Italian, some 98 000 lines |
| `extra/` | what Apertium lacks or gets wrong, which `build.pl` writes at the HEAD of the vocabulary so it comes first: `<language>.txt` in the lessons' own sentences, `eng-<xx>.dix` as entries in the bilingual dictionary's shape, each with a comment saying why. Its README says why they are not in the two lessons above: those are the tagger's corpus |
| `build.pl` | the program that writes `vocabulary/`: `cocolog -s library/reasoning/corpus/build.pl -- spanish` |
| `raw/` | Apertium's dictionaries and pattern's English verb table, which `tools/corpus/fetch.sh` downloads (pinned to their commits) and which are NOT committed: 30 MB, and what `build.pl` writes from them is |

**THE HAND-WRITTEN FILE IS THE GRAMMAR AND THE WRITTEN ONE IS THE WORDS.**
`spanish.txt` says what the rules are -- gender by ending, the plural's
endings, where an adjective stands, the word that denies, the question
words -- and gives a few words to say them with; `vocabulary/spanish.txt`
gives twenty-two thousand more in the same sentences, `The feminine noun
"casa" means "house".`, `"comió" is the past of "come".`, `"comer" is the
infinitive of "come".`, `The modal "puede" means "can".`, `The pronoun "esto"
means "this".`, `"amigo" is a person.`, and a gender denied of the word whose
ending would mislead the rule (`"problema" is not feminine.`). A program learns the grammar first
and then the words -- `library/reasoning/teach.pl` does both, into whatever
knowledge base the process proves against, which under `--embed` is a
store every later process finds taught in a second where the learning
takes six minutes for Spanish and three for Italian -- and `library/reasoning/page.pl` translates a file
sentence by sentence over it. The vocabulary directory is NOT read by the
generator: the tagger's lesson shapes draw from the lessons beside it,
not from eighty thousand lines of dictionary.

The sources, and their licences: `apertium/apertium-eng-spa`,
`apertium-spa`, `apertium-eng-ita` and `apertium-ita` (GPL-2), the
bilingual and monolingual dictionaries; `clips/pattern`'s `en-verbs.txt`
(BSD-3), for the English pasts and participles -ed cannot make; WordNet's
noun.person by way of `lexicon/class.txt`, for which nouns are persons.

Three things read this directory, and none of them holds a word of it:

* `library(reasoning/normalise)` generates its LESSON shapes from the words
  in here -- the mentioned words, the classes said of them (`noun`,
  `article`, `pronoun`), the adjectives (`feminine`), the forms (`the plural
  of`, `the first person of`), the relations (`means`, `precedes`, `takes ...
  in the plural`) -- through `normalise_lexicon/2` with `mention`, `wclass`,
  `wadj`, `form`, `wverb`, `wobj` and `wplace`, and lists the lines
  themselves with `normalise_lessons/1`. A lesson that uses a shape or a
  word these files lack is one the tagger was never shown, and the fix is a
  line here, not a word in the code.
* `library(reasoning/tagger)`'s judge lets a sentence about a mentioned word
  be related only by a verb some lesson here uses, and
  `tagger_lessons/4` measures the shipped tagger on these lines with their
  quotation marks taken off -- `The noun casa means house.` -- read back to
  the same terms.
* `tools/tagger/train.sh` trains on the generator, so every word here is
  in the shipped model's world.

`$COCOLOG_CORPUS` names another directory; otherwise it is
`reasoning/corpus` under the first library directory that has one, as the
lexicon beside it is found. Nothing trains on data the tree does not hold:
a sentence worth teaching the tagger goes in a file here, and the file is
committed.
