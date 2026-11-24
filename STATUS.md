# Status: parking translate.pl

Written 2026-11-23, at reasoning 1.53.0; the first goal added at 1.55.0.

**The decision** (the owner, 2026-11-23): park `translate.pl`. Every use of it
moves to the typology template system (`typology.pl` and `templates/`).

This file gives the current state, the desired state, the gaps between
them, and the steps. Change it as the work moves.

## The first goal: English, all of it

**The goal** (the owner, 2026-11-23): English as one complete template,
so that the IR of any English text can be got from it.

**The measure** is `lexicon/prose.txt`, WordNet's 8 000 example sentences
(real English of 2 to 20 words). `tools/typology/coverage.pl` reads them
all (`typology_coverage/4`) and prints the count read into an IR and the
commonest words no table has. test/typology.pl's `english_coverage` holds
the count to the last one below.

| version | read | of 8 000 | what moved it |
|---|---|---|---|
| 1.55.0 | 215 | 2.7 % | the start: 5 285 sentences have a word no table has, and 2 500 have no unknown word but a structure the grammar has not |
| 1.56.0 | 250 | 3.1 % | the English nouns in the class design: 20 078 nouns, from the vocabularies and `lexicon/` |
| 1.57.0 | 278 | 3.5 % | the English verbs in the class design: 3 835 regular verbs, 217 irregular ones (`do` stays a word of grammar) |
| 1.58.0 | 428 | 5.4 % | the English adjectives and adverbs, one fact each: 17 703 adjectives, 1 081 adverbs, from `lexicon/` and the vocabularies |
| 1.59.0 | 436 | 5.5 % | coordination, first part: noun phrases and two clauses joined by `and`, `or`, `but` |
| 1.60.0 | 438 | 5.5 % | coordination, second part: the verbs of one subject (`same`) |
| 1.61.0 | 442 | 5.5 % | coordination, third part: adjectives and adverbs joined inside a phrase |
| 1.63.0 | 498 | 6.2 % | the determiners (every, each, all, some, no, any, this, that) and the quantifier pronouns (`something`, `everyone`, `nothing`, `this` alone) |
| 1.62.0 | 456 | 5.7 % | names: a word with a capital that no table has, and 10 568 English names of rows (the census, WordNet's places, Apertium); a first word is a name only by a row |

At 1.55.0 the commonest words no table has are words of grammar, not
nouns: `and` 451 times, `by` 154, `as` 126, `out` 95, `this` 95, `all` 92,
`into` 79, `there` 69, `up` 68, `but` 67, `than` 53, `some` 50, `could` 48,
`more` 47, `very` 46, `one` 45, `two` 44, `many` 43, `every` 36, `or` 36,
`must` 29.

At 1.58.0, with the four kinds of words in, 2 255 words no table has, and
the commonest are still words of grammar (`and` 451, `by` 154, `as` 126):
step 3 is next.

**The design of a template: the classes first, then the items** (the
owner, 2026-11-23). In each part of a language the template defines the
classes and their rules first, then each item is put in a class, and
only an irregular item is defined one by one. The fewest facts: one fact
a class, one fact a regular item, and one fact an irregular item, which
gives all its irregular parts (its past, its participle, its future, ...)
and takes the rest from its class.

    ty_noun_class(english, regular, [''-s, s-ses, x-xes, ch-ches, sh-shes, y-ies, ay-ays, ...]).
    ty_noun_in(english, house, none, inanimate, house, regular).        % a regular noun
    ty_noun(english, child, none, person, child, children).             % an irregular noun
    ty_conjugation(english, regular, [present(sg)-[''-s, ...], past(sg)-[''-ed, e-ed, y-ied, ...], ...]).
    ty_verb_in(english, walk, walk, regular).                           % a regular verb
    ty_irregular_verb(english, see, see, regular, [past(sg)-saw, participle-seen]).

The regular items are in a file of their kind beside the template
(`templates/english-nouns.pl`, `-verbs.pl`, `-adjectives.pl`,
`-adverbs.pl`), the classes and the irregular items in the template
itself, and `typology_load/1` makes the forms from the rules. For
English a word's meaning is the word: no translation table.

**The steps:**

1. The measure (1.55.0).
2. The English words in the class design, from `lexicon/` (8 915 nouns,
   3 616 verbs, 16 706 adjectives, 1 149 adverbs) and the vocabularies'
   English meanings: the nouns, then the verbs, then the adjectives and
   the adverbs, one version each (done: 1.56.0 to 1.58.0).
3. The words of grammar, each with its grammar and its IR shape, the
   commonest first by the measure: coordination (`and`, `or`, `but`), the
   other adpositions, the determiners and quantifiers, the numbers, the
   modal verbs, `there is`, the particles (`out`, `up`), the adverbs of
   degree (`very`), comparison (`than`, `more`), and the verbs' objects
   (whether a verb takes one: `lexicon/`'s `vt` and `vi`), with `do` as a
   main verb: until then `do` is a word of grammar only, or `Yes, he
   does.` reads as the verb `do` with no object too.
   Coordination is three versions: 1.59.0 the noun phrases and two
   clauses (done); 1.60.0 the verbs of one subject (done: `The boy sleeps
   and sees the dog.`; `They stood on high and observed the countryside.`
   waits for `on high`); 1.61.0 the adjectives and the adverbs inside a
   phrase (done: `vexed and troubled times`, `slowly and quietly`). Nouns
   under one article (`the corn and tomatoes`) are not done: they change
   the noun's own slot of the IR. Of the 215 sentences of the measure that
   only a conjunction stopped at 1.58.0, 14 read at 1.61.0; most of the
   others need a structure that is no coordination: a phrase with no verb
   (`An animated and expressive face.`), an imperative, a bare singular
   noun (`Helium is monatomic.` is not read either).
   Since 2026-11-24 the rest of step 3 takes its items in the order the
   translator needs them (the second goal, below): names (done: 1.62.0),
   then the determiners and the quantifiers (done: 1.63.0), then the bare
   noun; then the
   `if` clause of step 4. The determiners and the quantifiers read 42 more,
   about four of them false (`He is no better today.`, `All mammals except
   monotremes ...` with `except` a verb). Names read 14 more sentences of the measure;
   with every unknown first word a name they read 45, 31 of them false.
   Of the 14, four are still false: a row's name that is a common word
   too, at the start (`Snow blanketed the fields.`, `Rusty deposits.`,
   `Vital signs.`, `Faith is his anchor.`); the word is the first reading
   where the grammar reads it, so the bare noun and the phrase with no
   verb will read these.
4. The structures: the subordinate clause (`that`, `if`, `when`,
   `because`), the infinitive, the gerund, the passive, the imperative.

The other five languages take the class design after English.

## The second goal: English and Cocolog

**The goal** (the owner, 2026-11-24): a translator between English and
Cocolog in the two directions, through a shared IR, with other languages
added later as templates. `TRANSLATOR-PLAN.md` is its plan: two levels of
IR (the typology IR, and a logic form that rules make from it), the
Cocolog template, the steps and the first milestone.

The two goals are one line of work. The translator needs names, the
determiners and the quantifiers, the bare noun and the `if` clause, and
the measure needs them too: `all` is in it 92 times, `some` 50, `every`
36. `reason.pl` stays as it is until the logic form reads all of its
sentences.

## What "parked" means

A parked file stays in the repository. Nothing else loads it, and
`sh run-tests.sh` (all the cases) does not run its case. `sh run-tests.sh
translate` still runs it by name, so it can come back. The files that
are parked:

- `translate.pl`
- `test/translate.pl`
- `tutorials/04-translate.pl`
- `teach.pl`
- `corpus/spanish.txt` and `corpus/italian.txt`, the lessons `teach.pl`
  teaches

`corpus/vocabulary/` and `lexicon/` are not parked: the typology import
and the endpoint use them.

## The current state (1.53.0)

### The two translators

| | `translate.pl` | `typology.pl` |
|---|---|---|
| code | 30 332 lines | 5 780 lines |
| a language is | a lesson in controlled English (`reason_learn/3`) | a template, facts in `templates/<name>.pl`, and the word tables the import writes from `corpus/vocabulary/` |
| languages | English (the pivot) and each lesson: Spanish and Italian | English, Spanish, Italian, Persian, French, German |
| the IR | `ir(s(Asked, Subject, g(Lexeme, Tense, Aspect, Denied), Complements), Stop)`, its words English | `clause/5,6`, `copula/4`, `question/1`, `answer/2,3`, its words meanings |
| one grammar for each direction | no: a reader and a writer for each side | yes: one DCG reads and writes every language |
| the test | `test/translate.pl`, 19 313 lines, 3 678 checks, about 30 sections of newspaper text | `test/typology.pl`, 2 177 lines, 275 checks (many inside loops over sentences) |
| the lesson | `tutorials/04-translate.pl`, 12 793 lines | `tutorials/06-typology.pl`, 721 lines |
| load | a lesson is learned (`teach.pl` keeps one in a store, as it takes minutes) | `typology_load/1`, the six languages in 1.03 s of CPU |

### Every use of translate.pl

| file | what it calls | what for |
|---|---|---|
| `page.pl` | `reason_translate_page/2,4` | a page, each sentence its translation or `?` and the words no lesson knows |
| `teach.pl` | `reason_learn/3` | `corpus/<language>.txt` and `corpus/vocabulary/<language>.txt` into a knowledge base |
| `live.pl` | `reason_ir/3`, `reason_ir_text/3`, `reason_untranslated/2` | the live mode's `ir(From)` kind: the model judges a reading, and teaches a word the lesson lacks as a lesson line (`reason_live_lesson/2`) |
| `coding/endpoint/english_lesson.pl` | asserts a lesson's facts (`mean/2`, `noun/1`, `verb/1`, ...) | some 47 000 English words of `lexicon/`, taught as a lesson, so the translator reads English |
| `coding/endpoint/reasoning_core.pl` | `reason_ir/2` | `endpoint_ir/2`, the IR note of a request |
| `coding/endpoint/ir_repair.pl` | `reason_ir/2`, `reason_ir_text/3`, `reason_untranslated/2`, `tr_pieces/2`, `tr_trim/2`, `tr_stop_text/3` | the model checks and repairs the reading of each sentence; the reading said back in English, and its logical form (`ep_ir_logical_form/2`) |
| `coding/endpoint/httpd.pl`, `httpd_core.pl`, `live_ir.pl` | `ep_english_lesson/0`, `ep_ir_readings/2` | the server and the live run, through the two files above |
| `corpus/build.pl` | `tr_english_ing/2` | the gerund rule that a vocabulary line must not repeat |
| `test/live.pl` | `reason_ir/3`, `reason_learn/2` | section `translator` |
| `coding/endpoint/test.pl` | `endpoint_ir/2`, `ep_ir_readings/2` | the endpoint's IR sections |
| `test/typology.pl` | `reason_ir/3`, `reason_ir_text/3`, `reason_learn/3` | section `bridge` (1.53.0) |
| `run-tests.sh` | the `translate` case | one of the eight cases of `all` |
| `reason.pl` | nothing | comments only: `reason_learn/1,2` is `reason.pl`'s own |
| `CLAUDE.md`, `README.md`, `tutorials/README.md`, `TYPOLOGY-PLAN.md` | | they describe it |

### What typology reads of those uses today

- **Spanish into Italian.** `test/translate.pl` translates 37 Spanish
  sentences into Italian with `reason_translate/4`. Typology translates
  12 of them. For one of the 12 it chooses another reading (`de sus
  padres` as `from`). The newspaper sections were not tried.
- **The endpoint's English.** Of 10 sentences of the endpoint's tests
  and of a benchmark task, `translate.pl` (with the endpoint's lesson)
  reads 6 and typology reads 3.
- **The bridge** (`typology_reason_ir/2`, 1.53.0). Over 22 shared English
  sentences, `translate.pl`'s reading is typology's own reading, and the
  two write the same Spanish.

## The desired state

Nothing loads `translate.pl`. Each use calls typology:

| use | desired |
|---|---|
| `page.pl` | a new `typology_translate_page/4`: the page split into sentences, each sentence its translation or `?` and its unknown words |
| `teach.pl` | parked: `typology_load/1` reads the templates in about one second, so no store is needed |
| `live.pl` | the kind `typology(L)`: the model judges a reading of `typology_read/3`, and gives a word the tables lack as a template row (`ty_noun/6`, `ty_verb/6`, ...), held to the round trip and the reference sentences (Phase 8 of TYPOLOGY-PLAN.md) |
| `coding/endpoint/english_lesson.pl` | not needed: `typology_load(english)`, with the words of `lexicon/` in the English word tables |
| `coding/endpoint/reasoning_core.pl` | `endpoint_ir/2` gives typology readings of the request |
| `coding/endpoint/ir_repair.pl` | the reading said back by `typology_write(english, ...)`; the logical form made from the typology IR; the unknown words from typology |
| `corpus/build.pl` | the gerund from the English template's ending rules (`ty_ending/4`), or a rule of its own |
| `test/live.pl`, `coding/endpoint/test.pl` | their sections hold the typology readings |
| `test/typology.pl` | section `bridge` stays while the work runs (it is the measure), and is parked with `translate.pl` at the end |
| `tutorials/04-translate.pl` | parked; lesson 06 is the translator's lesson |
| `run-tests.sh` | `all` runs seven cases, without `translate` |
| the documentation | `CLAUDE.md`, `README.md`, `tutorials/README.md` and `TYPOLOGY-PLAN.md` name typology as the translator and `translate.pl` as parked |

**A language is facts, and only facts** (the owner, 2026-11-23). A
template and its word tables are facts in `templates/`. No lesson in
controlled English gives a language or a word, in place of the facts or
beside them. So `translate.pl`'s way to learn a language (`reason_learn/3`)
is not carried over, and the live mode gives a word the tables lack as a
fact row. This is about how a language is given to the translator: the
controlled English of `reason.pl` (the reasoner, the endpoint's contract)
is a different matter and does not change.

## The gaps

Typology must read what the uses read. These are the gaps that the 25
Spanish sentences and the endpoint's sentences show:

1. **Clauses.** Coordination of phrases and of clauses (`el pan o el
   caldo`, `pan, caldo y sopa`, two clauses with `y`); subordinate clauses
   (`if`, `until`, a clause after `that`); the imperative, positive and
   negative (`Write a complete C program.`, `No comas el pan.`); an
   infinitive after a verb (`tiene que comer`, `al acusar`); the gerund
   (`comiendo`); modal verbs; the passive (`ha sido arrojada`); the
   reflexive and the impersonal `se`; `there is` (`hay`).
2. **Noun phrases.** Quantifiers and determiners (`every`, `each`, `no`,
   `this`, `these`); numbers; names and a name in apposition (`el
   ministro, Jean-Pierre Chevènement,`); a phrase with no noun (`el más
   débil`, `el de los chicos`); an adverb before an adjective (`tan
   pacífica`); an adjective before the noun where the template puts it
   after (`la sacrosanta institución`); a noun phrase of two nouns
   (`standard input`, `C program`).
3. **Sentences.** An adverb first (`Después, el perro come el pan.`);
   text with no verb (`¡El pan del perro!`); a clause after a semicolon
   that leaves out its verb (`el gato, la sopa`); quotes; `how`, `where`
   and `when`; the first person with an adjective (`Estamos cansados.`).
4. **Pages.** A text split into sentences, each with its stop; the words
   no table knows, named.
5. **Words.** `lexicon/` has 6 000 nouns, 2 500 transitive verbs and
   3 000 adjectives; the endpoint's lesson teaches some 47 000 words. The
   English word tables have 25 440 rows, from the vocabularies.
6. **A word in live mode.** `translate.pl`'s live mode teaches a word the
   lesson lacks. Typology's live mode gives topics only: it must give a
   word as a fact row (`ty_noun/6`, `ty_verb/6`, ...), held to the round
   trip and the reference sentences.

## The steps

1. **The measure.** A script counts what typology reads and writes the
   same way as `translate.pl`, section by section of `test/translate.pl`,
   and over the endpoint's sentences. Each version records its count.
2. **Typology grows,** the largest gaps first by the measure, one feature
   a version, each with its tests, its lesson section and its benchmark.
3. **The uses move,** the smallest first: `corpus/build.pl`, `live.pl`,
   `page.pl`, then the endpoint.
4. **The park.** No file loads `translate.pl`; `run-tests.sh`, the
   section `bridge` and the documentation change as above.

## Open questions for the owner

1. Park in place (the paths stay the same), or move the parked files
   into a directory of their own? Recommended: in place.
2. Can a use move while typology reads fewer of its sentences than
   `translate.pl` does? The endpoint would read fewer requests until the
   gaps close. Recommended: no, for the endpoint; yes, for `page.pl` and
   `live.pl`, whose tests are small.
3. The words of `lexicon/`: import them into the English word tables?

Answered:

- A language from controlled English, in place of facts: no (the owner,
  2026-11-23). A template is facts.
