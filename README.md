# library/reasoning

Everything of the reasoning task lives here, and it is loaded with the
directory in the name:

    :- use_module(library(reasoning/reason)).
    :- use_module(library(reasoning/normalise)).
    :- use_module(library(reasoning/tagger)).

| file | what |
|---|---|
| `reason.pl` | a paragraph of controlled English in, predicates out -- and, optionally, typed prose in through the shipped tagger (`reason_prose/2`, `reason_ask_prose/2`, loaded on first use): facts, `neg/1` facts, rules, a quantity as a VALUE (`500 euros` is `quantity(500, euros)`, `The rent is 500 euros` an `amount/2`), and a question as a GOAL with a variable where `who`, `what`, `where` or `how much` stood; `truth/2`, four-valued; `reason_ask/2`, a question answered with the fact, the rule or the denial it rests on, and `reason_ask/3` with the EXPLANATION beside it -- `reason_explanation/2`, the whole proof in sentences, every level of it, which a `Why ...?` question answers as `because(Text)`; `reason_concepts/2`, what a text mentions, ranked, and `reason_topics/2` and `reason_outline/2`, what it is ABOUT as an outline by topic with the sub-topics under each -- `Kh8, a king: black; occupies H8; may move to G8, G7 and H7.`; `reason_refused/2`, which sentence would not parse; a word in quotation marks is MENTIONED (`"casa" means "house"` is `mean(casa, house)`, `the noun "casa"` says what it is), a relative clause takes a verb, `is the NOUN of X` is the relation the noun names, `end_in/2` is the library's so that a rule over letters runs (`ends in a vowel` included), and `reason_learn/1` reads and asserts |
| `translate.pl` | a language lesson as a knowledge base and a translation as a proof over it: `reason_translate/2,3` takes a simple sentence -- a subject, a verb and what follows it; singular or plural, in any person, denied or not, present, past, future or perfect, with a pronoun, a possessive, a number, a prepositional phrase, an adverb or two phrases joined; a statement or a question (yes or no, what, who, whom, where, when, which) -- between English and the language a lesson teaches, asking the knowledge base what a word means, what it is, its gender, its plural, its past, its future, its participle and its persons (stated, or by an ending rule), the word for `not`, whether an adjective follows its noun, whether a pronoun precedes the verb, the word that stands before a person as the object (`The word "a" precedes the person`) and the contractions it states (`"al" is the contraction of "a el"`) -- and naming no word of the language's vocabulary itself (the few closed-class words the code does name are listed under What a translation promises, below); `reason_learn/3` learns a lesson under its own name so that several languages sit in one knowledge base -- a FACT under the language's own namespace (`'spanish:mean'(casa, house)`) so the first-argument index keys on the word as a plain lesson's does, a rule in `lesson/2` where the body must still be proved through the lesson, with `reason_lesson/2` to read one and `reason_unlearn/1` to forget one -- and `reason_untranslated/2` names the words a lesson left out. AND EVERY LANGUAGE HAS TWO HALVES AND NO PAIR HAS ANY: `reason_ir/2,3` reads a text INTO an intermediate representation -- `ir(s(Asked, Subject, g(Lexeme, Tense, Aspect, Denied), Complements), Stop)`, the reader's own shape with English words in it -- and `reason_ir_text/3` writes one back out into any language, so `reason_translate/4` takes Italian into Spanish with no English sentence written and none read, three languages are three lessons rather than six paths, and a fourth is a fourth lesson. The SHAPE travels exactly; the vocabulary travels through English, because a lesson says what a word means only as `mean(Word, EnglishWord)`. `reason_languages/1` names them. AND WHAT NEWSPAPER PROSE IS MADE OF, which twelve verbatim Italian sentences named as eleven structures and every one of which turned out to be a SHAPE rather than a vocabulary: several clauses joined by a comma or a connecting word, a passive with its `da` agent, a reflexive that belongs to the verb, a reduced relative (a participle after a noun), an infinitive of purpose, an object complement (`definire illegale la decisione`, which the lesson's language writes before its object and English after), an adjective in the comparative or the superlative (one word in the lesson's language, and the ARTICLE decides which), a subject after its verb where an adjunct is fronted and the lesson calls the verb intransitive, a headline with the copula left out (a passive, never a fragment), a gerund clause with a `that` clause inside it, an IMPERATIVE (no subject, and only a form the lesson calls one -- `"come" is the imperative of "come"' -- so `Come el pan.' is read where `Comia el pan.' keeps its refusal; its denial is a different form in every language that has both, Spanish's subjunctive against Italian's infinitive, and the translator asks the lesson for it by name), and an article before a NAME (`la Tate Gallery`, which Italian writes far more often than English does) -- an ordinary phrase with the name where the noun goes, where the ARTICLE says what a name cannot: its number, and its gender, which travels so the other language agrees with it. Each asks the lesson for what it needs and no more -- `The word "per" begins the purpose`, `The word "più" begins the comparative`, `"domina" is intransitive`, `The conjunction "che" means "that"`, `"ha" is the auxiliary of "es"` -- and the costs are stated: the fronting is not written back, a headline comes out as the sentence it leaves the copula out of, and a subjunctive is written back as one only after a word the lesson says takes it (below) |
| `normalise.pl` | the training data for the network: the grammar's fifty-five shapes as a generator with gold tags, thirteen noise transforms that carry the tags, and the assembler the round trip holds them to -- over the lexicon files in `lexicon/` and the lessons in `corpus/`, read as needed and never written into the code. Ten of the shapes are a LESSON's, about mentioned words (`The noun "casa" means "house"`, `Every noun that ends in "a" is feminine`), and their tag M is the one the assembler writes something for: the quotation marks, so that `The noun casa means house` typed bare comes back as the lesson's own line (`normalise_bare/2` is the typing) |
| `lexicon/` | the words, one class a file: 2500 census first names and some seventeen thousand WordNet words ranked by use for the generator (`unit.txt` the four hundred a number counts, WordNet's units of measurement and of time; `language.txt` a hundred and fifty languages, for `Spanish is a language` and the `in Spanish` the normaliser drops), and in `known_*.txt` every SemCor-counted noun, verb, adjective and adverb for the tagger's judge; `SOURCES.md` says where each came from, and `lexicon/build.pl` writes every file but the names from a WordNet 3.0 `dict` directory; `prose.txt` is eight thousand of WordNet's own example sentences, which nothing trains on and `tagger_refused/4` measures against |
| `generated/` | the training data, as DATA: `training.txt`, the 32768 pairs the shipped model was fitted to, and `evaluation.txt`, the 300 it is measured on -- one `pair(...)` term a line, written by `generate.pl` and read back by `normalise_load/2`; committed, because a seed is not data once a shape or a lexicon line moves under it |
| `generate.pl` | the program that writes `generated/`: `cocolog -s library/reasoning/generate.pl`, which `tools/tagger/train.sh` runs first |
| `train.pl` | the program that trains the shipped tagger on `generated/training.txt` into the knowledge base and measures it -- unseen pairs, real prose refused, the lessons typed bare -- which `tools/tagger/train.sh` runs over a scratch store and exports from |
| `corpus/` | the lessons, as DATA: `spanish.txt` and `italian.txt`, the two lessons `test/translate.pl` learns, one sentence a line in the controlled English. The lesson shapes' words -- the mentioned words, the classes said of them, the adjectives, the forms, the relations and the class atoms -- are read out of these lines by pattern, so that no word of a lesson lives in the code, and `tagger_lessons/4` measures the shipped tagger on the lines typed bare. Its README says what to add and where |
| `corpus/vocabulary/` | the vocabulary of each lesson, WRITTEN by `corpus/build.pl` out of Apertium's dictionaries and committed: `spanish.txt`, some eighty thousand lesson lines, and `italian.txt`, some sixty thousand -- every noun with its gender and plural, every adjective in its forms, every verb in sixteen, the persons, an English past -ed cannot make -- in the shapes the hand-written lessons use, so the same reader and the same translator serve. `tools/corpus/fetch.sh` fetches the raw dictionaries (not committed) and `test/translate.pl` rebuilds the Spanish file from them byte for byte |
| `teach.pl` | the program that learns a language's lessons -- the grammar, then the vocabulary, in chunks -- into the knowledge base: `cocolog --embed KB -s library/reasoning/teach.pl -- spanish`, four minutes once, and every later process over the store starts taught. A SECOND ARGUMENT NAMES THE LESSON (`-- spanish spanish`), which is how two languages share one store: learned under names they share nothing, and the IR then translates between them |
| `page.pl` | the program that translates a file sentence by sentence over a taught store, marking what it refuses with the words no lesson knows: `cocolog --embed KB -s library/reasoning/page.pl -- page.txt [INTO [FROM]]`; naming both takes the page from one language to the other through the IR, with no English sentence written |
| `model.rows` | the SHIPPED tagger: the model's rows as `tagger_export/2` writes them, eight thousand lines, which `tagger_pretrained/1` consults as a module when the knowledge base a program proves against holds no model named `tagger` of its own -- so a `--local` program reads prose with no training and no store; `sh tools/tagger/train.sh` writes it (`generate.pl`, then `train.pl`), three minutes with libtorch |
| `tagger.pl` | the network: a tagger over library(tensor_expr) -- two embeddings, a GRU each way, a linear head -- trained on `normalise.pl`'s pairs and saved into the knowledge base; `tagger_normalise/4` takes prose to `reason.pl`'s terms, `tagger_ask/3` answers a typed question (`tagger_ask/4` with the explanation beside it), `tagger_pretrained/1` loads the model the knowledge base keeps or the shipped one, `tagger_evaluate/4` measures it on sentences training never saw, `tagger_refused/4` on sentences it must not read and `tagger_lessons/4` on the corpus's lessons typed bare; a tagging the lexicon contradicts (`tagger_sane/2`, eleven rules -- a quoted word is M and nothing else, and a sentence about a word is related only by a verb some lesson uses) comes back X, outside, which the assembler refuses. Needs library(torch) to train or tag; its pure half loads anywhere |

The suite case for each is `test/reason.pl`, `test/normalise.pl`,
`test/tagger.pl` and `test/translate.pl`, and the lesson `tutorials/library/43-reason.pl`,
`44-normalise.pl`, `45-tagger.pl` and `46-translate.pl`. They
stay where the runners look -- `test/run.pl` takes `test/*.pl` and
`test/tutorials.pl` takes `tutorials/*/*.pl` -- because a case under
`library/` is a case nobody runs.

The library has a version of its own, which is not cocolog's:
`reason_version/1` answers it as an atom (`X.Y.Z`) and `reason_version/3` as
the three integers a program compares, from one fact at the top of
`reason.pl`. A change to anything in this directory -- the code, `corpus/`,
`lexicon/`, `generated/`, `model.rows` -- moves that number in the same
commit, and `cocolog --version` stays unless the binary or another library
changed too. CLAUDE.md, under The version, has the rules.

**What a translation promises, and what it does not.** Each of these was
checked against the code and a lesson (2026-10-17, reasoning 1.0.8; the second and third bullets changed in 1.0.9):

* **One text, and no alternatives.** A translation is one sentence out;
  backtracking offers no other. A word a lesson gives two meanings is
  settled by the sentence's shape where a shape decides -- `qué` before a
  noun is `which` -- and otherwise by the order the lesson states the
  meanings in: the Spanish lesson says `lo` means `him` before it says
  `it`, so `Maria lo come.` is `Maria eats him.`. Nothing marks such a
  choice in the result.
* **Which phrase is asked for, and who does it.** `qué`, `quale` and the
  like before a noun ask for a phrase that is the subject or the object,
  and the word order says no more than the verb and the phrase after it:
  `¿Qué libro lee el gato?` and `¿Qué gato lee el libro?` read alike. The
  reader settles it so (`fo_which_object/3`). A verb that cannot agree
  with the phrase asked for says it is the object (`¿Qué libros lee el
  gato?`, `¿Qué medidas tomará el Gobierno?`). Where the number decides
  nothing, the phrase after the verb is the doer when it is animate and
  the one asked for is not: a name, a pronoun, a noun the lesson calls a
  person (`"amigo" is a person.`, which the vocabularies state from
  WordNet's `noun.person`) or animate (`"gato" is animate.`, which they
  state of about a hundred animals); two doers, or none, are read as
  before, the phrase asked for the subject (`¿Qué perro come el pan?`).
  An institution is no doer unless the lesson says so (`¿Qué medida tomó
  el Gobierno?` is `Which measure took the Government?`), and a name of
  several words after the verb is not read this way (`¿Qué libro lee
  Maria Lopez?` still swaps the two).
* **A stated gender beats an ending rule, and a denial beats a rule.**
  `tr_gender/2` asks `feminine/1` first, and a rule holds of a word unless
  the lesson denies it of that word (`tr_holds/1`). A feminine the lesson
  states (`"leche" is feminine.`) wins over `Every noun that does not end
  in "a" is masculine.` and writes `la leche`; a masculine it states
  (`"mapa" is masculine.`) wins over `Every noun that ends in "a" is
  feminine.` and writes `el mapa` -- unless it states the feminine too
  (`"mar"`: `el mar` and `la mar`), when the feminine is asked first, as
  it always was. A denial (`"tema" is not feminine.`) wins over a rule
  as well. The reasoner, reading the same lesson, has no order and holds
  both genders true (`truth(masculine(leche), true)`). The vocabularies'
  builder writes the denial after every masculine noun in `a` of the
  dictionaries (`corpus/build.pl`); a line of `corpus/extra/` is copied as
  it stands, and four Italian ones lacked it (`caposquadra`, `centro
  destra`, `centro sinistra`, `microtrauma`: written feminine, until
  reasoning 1.0.9) -- `test/translate.pl` scans both vocabularies for a
  masculine noun in `a` without it.
* **The mood does not cross.** The IR has no mood, as English marks none:
  a subjunctive is read as its verb, and written as a subjunctive only
  after a word that the lesson of the language being written says takes
  one (`"chiede" takes the subjunctive.`, twenty-five to thirty a
  language) -- the indicative elsewhere, after `cuando` or `si`, in a
  relative clause. A fronted adjunct is written where English puts it (`En
  la casa el perro come el pan.` is `The dog eats the bread in the
  house.`), and a headline as the sentence it leaves the copula out of.
* **An article's count is coverage, not correctness.** `37 of 38` (a
  sample's count, in its commit and in CLAUDE.md) is the sentences
  translated rather than refused. Each sample's texts are read by hand and
  what is wrong in them is listed beside the count, under The reasoning
  library and the translator in CLAUDE.md. `test/translate.pl` holds the
  shapes, not the articles: a small sentence for each, its expected text
  written by hand, and, when the shape was added, a copy of the library
  with its rule taken out on which that check went red. The controls --
  every earlier article and four hundred short Tatoeba-style sentences,
  this translator against the last -- find the texts that CHANGED, which
  is how a regression is caught and not a measure of quality. There are no
  reference translations and no measure of whether a meaning survived.
* **Of Spanish and Italian the code names only closed classes**, each the
  guard of a shape: surname particles and the articles a name holds (`de`,
  `di`, `da`, `del`, `d'`; `de la`, `de los`), clitic and article forms
  (`lo`, `la`, `li`, `le`, `ne`, `los`, `las`; `mi`, `ti`, `ci`, `vi`, `si`
  and their forms before another clitic), the Italian demonstratives with
  their copula (`questo è`, `questi sono`), the numeral one (`uno`, `un`,
  `una`), ten Italian adverbs that may stand inside a verb of two words
  (`risente invece di`, `tr_plain_adverb_word/1`) and the `di` that ends
  such a verb, a list of abbreviations (`pag.`, `dott.`, `núm.`), and the
  gerund endings `-ando` and `-endo`, which pick the words of a sentence
  the lesson is asked about as gerunds (`tr_gerunds_of/2`: a lesson's
  gerund that ends otherwise is not among them). Every word's meaning,
  class, gender and forms, and every rule of the language, is asked of the
  lesson; English, the IR's language, is the code's own.

The loop is closed: `tagger.pl` trains in about two minutes on four
cores, over 300 sentences training never saw (seeds past the corpus)
0.988 of the tags and 0.93 to 0.96 of the sentences are right, a training
apart (0.9997 and 0.997 before the lesson shapes joined), of eighty-two hand-written sentences
whose names, nouns, adjectives and verbs are outside the lexicon
seventy-eight or more give their terms, and 0.88 of the corpus's own
lesson lines typed bare -- `The noun casa means house.` -- read back to
their terms; `test/tagger.pl` holds all three, and puts a paragraph of
such prose, a place after an object included, to `truth/2`.

The other half is what it refuses. Shown 875 sentences of real government
prose the first tagger "read" a tenth of them -- `Boston, Mass.` as
mass(boston) -- because every sentence it had ever seen had a reading.
Three ways of teaching the network to refuse (an outside tag on every
token of real prose, a sentence head over the shared states, a second
network) each cost a tenth of the hand-written sentences it should read.
What stayed is deterministic: lexicon rules, six then and eleven now
(`tagger_sane/2`), put to every tagging before the assembler sees it, and a twelfth tag X for one
they contradict, which the assembler refuses. Measured, 0.93 to 0.94 of
WordNet's example sentences refused where the network alone refused 0.85,
0.96 of the government prose where it was 0.87, and the forty-three read
as before.

The corpus is the capability. Trained on 2048 pairs from the first
lexicon (ten names, twelve nouns, eleven shapes) the same network read its
own kind of sentence at 0.99 and lost `a small blue lamp` (no object had
carried two adjectives) and `lives in Lagos` (the only place it had seen
after a verb was an adjunct to drop). Each miss was a shape the generator
did not make, never the network, and each was fixed in `normalise.pl`:
fifty-five shapes and thirteen transforms now -- four shapes a
place after an object, `rents a flat in Bristol', which a noise transform
had taught the network to DROP until the grammar learned to read it as
rent_in/3; a filler after a conjunction, `and, as far as I know,', a
position typed prose uses and the generator never had; and a second fact
about the same subject, `Priya is a baker and is licensed' or `and she is
licensed'. That last one is STATE carried from sentence to sentence: the
assembler supplies the subject a break left out, and the grammar resolves
`she', `he' or `they' to the subject of the last fact -- `Priya is a
baker. She is licensed.' is two facts about Priya, in `reason.pl` itself.
And six shapes are QUESTIONS: `Does Priya sell the bread?' is the goal
`sell(priya, bread)`, `Who rents a flat in Bristol?' the goal with a
variable where `who' stood, and `reason_ask/2` answers either against the
knowledge base with the REASON beside the answer -- the fact that was
said, the rule and the body that proved it, or the denial -- so
`tagger_ask/3` takes a typed question to an answer with its why; and
`Why is Kh8 checkmated?` answers the WHOLE proof in sentences, every
level of it down to what was said, a universal in a body as `whenever Kh8
may move to X, X is unsafe (X: G8, G7 and H7)` with every instance
explained -- `reason_explanation/2`, over a back-rank mate written in the
controlled English, in `test/reason.pl` and lesson 43. Eight
shapes are QUANTITIES: `Nadia pays 500 euros' is pay(nadia, quantity(500,
euros)), a value and never an individual, the number a determiner to the
tagger and copied by the assembler; `The rent is 500 euros' is amount/2,
the one definite subject the grammar reads; and `How much does Nadia
pay?' asks for the object through `reason_amount/2`, so that `Nadia pays
the rent' beside the amount answers the 500 euros. And the
judge that refuses a tagging the words contradict reads `known_*.txt`,
every counted word of WordNet, since the generator's nouns are things to
own and `Death put a period' had walked past a judge that never heard of
death: the same model went from 28 of 300 real sentences read to 11. The
words were the other half:
a lexicon written by hand is a lexicon nobody grows, so it is files now,
`lexicon/`, census names and WordNet, and over those the corpus is the
lever twice over -- 8192 pairs read 0.96 of the sentences training never
saw whatever the step count, which is memorising; 16384 read 0.987 and
32768 read 0.993 before the lesson shapes joined, and with them 16384
read 0.963 of the sentences, which is why the defaults are 32768 pairs
and 500 steps now. What it still cannot know is a shape the grammar does
not read -- a definite subject, a passive -- and that is refused, never
quietly rewritten; the lesson's last section shows both.
