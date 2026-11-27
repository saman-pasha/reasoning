# library/reasoning/lexicon

The words `library(reasoning/normalise)` generates from, one class a file,
one word a line, the commonest first. The library reads them the first
time a word is asked for and drops, as it loads, whatever the grammar
would not read as an open word: a closed word (`will` is a modal before it
is a name) and a verb whose third person does not stem back to it.

| file | class | source |
|---|---|---|
| `proper.txt` | first names | the United States Census Bureau's 1990 frequency lists, public domain: the 1500 commonest female and 1000 commonest male names, capitalised |
| `noun.txt` | things | WordNet 3.0, a word whose first sense is in `noun.animal`, `noun.artifact`, `noun.food`, `noun.object`, `noun.plant` or `noun.possession` |
| `class.txt` | kinds of person | WordNet 3.0, first sense in `noun.person` |
| `place.txt` | named places | WordNet 3.0, first sense in `noun.location` and an instance (a city, a country, a river), capitalised |
| `adj.txt` | adjectives | WordNet 3.0, `adj.all` and `adj.pert` |
| `adverb.txt` | adverbs | WordNet 3.0, `adv.all` |
| `vt.txt` | verbs that take an object | WordNet 3.0, any sense with the frame "Somebody ----s something", "... somebody", "Something ----s something" or "... somebody" |
| `vi.txt` | verbs that take none | WordNet 3.0, a sense with "Something ----s" or "Somebody ----s" |
| `vpp.txt` | verbs before a phrase | WordNet 3.0, a sense with "Somebody ----s PP" or "Something is ----ing PP" |
| `unit.txt` | units | WordNet 3.0, a word whose first sense is a hyponym of `unit_of_measurement` or `time_unit` (euro under `monetary_unit`, gram under `metric_weight_unit`, hour under `time_unit`), no instance -- the nouns a number counts, which the generator pluralises: `500 euros`, `40 hours` |
| `language.txt` | languages, capitalised | WordNet 3.0, a word under `natural_language` in its first sense, or in its second when the first is a person or a group (English first; Italian, German and Japanese name the people first) -- for the lesson shapes, `Spanish is a language` and `The Spanish word "casa"`, and the noise `in Spanish` the normaliser drops |
| `capital.txt` | adjectives written only with a capital | WordNet 3.1's data files (the `wordnet-db` package 3.1.14 of npm, the same database, WordNet's licence below): a one-word adjective lemma of `data.adj` that is a capital and then small letters (`American`, `Guyanese`, `Gallic`), three to twelve letters, where no lemma of any part of speech has the word in small letters (`Polish` is a verb's `polish`, and `Victorian` an adjective's `victorian` too, so neither is here): 629 words, alphabetical. `lexicon/build.pl -- --capitals --wordnet DIR` writes it from the four `data.*` files alone; the English import makes each a `ty_capital/3` row (since reasoning 1.92.0) where a table has its word and it is no name |
| `phrasal.txt` | verbs of a verb and a particle | WordNet 3.1's `data.verb` (the `wordnet-db` package 3.1.14 of npm, as for `capital.txt`): a lemma that is a verb's word, `_` and one of seventeen particles (`throw_out`, `set_up`, `come_up`), and what object its synsets' frames take -- `object` (frames 5, 8 to 11, 14 to 21, 24, 25, 30, 31), `none` (1 to 4, 6, 7, 12, 13, 22, 23, 27) or `any` where both stand: 1 725 lemmas, alphabetical, a line each (`throw_out any`). `lexicon/build.pl -- --phrasal --wordnet DIR` writes it from `data.verb` alone; the English import makes each a `ty_phrasal/5` row (since reasoning 1.94.0) where it has the verb, 1 398 |
| `vinf.txt` | verbs whose object may be an infinitive | WordNet 3.1's `data.verb` (the `wordnet-db` package 3.1.14 of npm, as for `capital.txt`): a one-word verb lemma of three to twelve letters whose synsets have frame 28, `Somebody ----s to INFINITIVE` (`try`, `want`, `refuse`, `begin`): 159 verbs, alphabetical. `lexicon/build.pl -- --infinitive --wordnet DIR` writes it from `data.verb` alone; the English template names it with `ty_verb_list(english, infinitive, vinf)` (since reasoning 1.95.0), beside a list of what the frames leave out |
| `vtinf.txt` | verbs whose object may be followed by an infinitive whose subject it is | WordNet 3.1's `data.verb`, as `vinf.txt`: a one-word verb lemma of three to twelve letters whose synsets have frame 24, `Somebody ----s somebody to INFINITIVE` (`cause`, `ask`, `want`, `allow`): 163 verbs, alphabetical. `lexicon/build.pl -- --infinitive --wordnet DIR` writes it with `vinf.txt`; the English template names it with `ty_verb_list(english, object_infinitive, vtinf)` (since reasoning 1.96.0), less a list of those whose object's infinitive is most often one of purpose (`use`, `take`, `make`) |
| `every_noun.txt`, `every_verb.txt`, `every_adverb.txt` | every noun, verb and adverb WordNet knows, for the typology alone | WordNet 3.0's `index.noun`, `index.verb` and `index.adv`: every lemma under the files' word filter (one word, a to z, three to twelve letters), the SemCor-counted ones first in `known_*`'s order and the rest in hash order, less an uncounted lemma that is a form of another word (a plural, `fields`, `teeth`; a verb's -s, -ed or -ing form, `twitching`, `drew`; any line of the four `.exc` files) or a noun whose own plural is one (`physic`: physics, `sens`: senses, `doe`: does), and a lemma the data files write only with a capital (a name: `socrates`) -- 36 073 nouns, 8 265 verbs and 2 974 adverbs. `lexicon/build.pl -- --every --wordnet DIR` writes them with `every_vi.txt`. The English import reads them after every other file (since reasoning 1.123.0), and takes a word from them only where no other file and no vocabulary has it: a word with no class takes WordNet's, a known word no rare sense (`see` is no noun there, `small` no adverb). Not the judge's: the `known_*` files stay SemCor's, as `build.pl` says why |
| `every_vi.txt` | every verb that may take no object | WordNet 3.0's `data.verb`: every verb with the frame "Something ----s" or "Somebody ----s" (1, 2), `vi.txt`'s order and no cap, so its first 1 200 lines are `vi.txt`: 3 679 verbs. The English template names it with `ty_verb_list(english, no_object, every_vi)` since reasoning 1.123.0 (`The cancer had metastasized.`) |
| `prose.txt` | real sentences, the grammar's opposite | WordNet 3.0's example sentences, quoted in its glosses: 8000 of two to twenty words, capitalised and stopped, in a fixed hash order -- the negatives a tagger learns to refuse (`normalise_negatives/3`) |
| `logic.txt` | the translator's second measure (TRANSLATOR-PLAN.md) | written by hand, not from WordNet and not from the translator: 197 English sentences (104 at 1.69.0, the tenses' 16 since 1.70.0, the adjuncts' 12 since 1.71.0, the pronouns' 11 since 1.72.0, the possessors' 10 since 1.73.0, the objects' 8 since 1.74.0, the plurals' 8 since 1.75.0, the indefinite noun phrases' 10 since 1.77.0, the nouns of relation's 10 since 1.78.0, `when`'s 8 since 1.79.0, a line of several sentences a text), each with the Cocolog it says, apart by a tab -- facts, rules, if clauses, relative clauses, questions, the quantifier pronouns, and sentences the translator does not read yet (`John lives in Paris.`, `John gives Mary the book.`), which are its next work. `tools/logic/measure.pl` counts them (`logic_measure/3`) |
| `known_noun.txt`, `known_verb.txt`, `known_adverb.txt` | every word the judge knows | every SemCor-counted lemma of that part of speech, whatever its sense, commonest first, each once: not the generator's words but the tagger's -- `tagger_sane/2` refuses a tagging they contradict, and `death` as a subject slipped through while only the generator's concrete nouns were known |
| `known_adj.txt` | every adjective the dictionary knows | the counted ones first, exactly as above, then every other lemma `index.adj` names, in hash order -- because a count says how OFTEN a corpus used a word and this table's question is whether WordNet knows it as an adjective at all. `registered` has three adjective senses and no count, and the tagger read it as no adjective until it was here |

The WordNet files are ranked by the tag counts of SemCor, the sense-tagged
corpus WordNet ships as `cntlist.rev`, so a cap keeps the words English
uses and leaves the obscure ones out. The MENTIONED words the lesson
shapes generate from are not here: they are read out of the lessons in
`../corpus/`, which is data of its own kind (see its README). `build.pl` beside these files, a cocolog
program, writes every file but `proper.txt` and `logic.txt` from a WordNet 3.0 `dict`
directory (`apt install wordnet-base`; `sh tools/lexicon/build.sh`), and
`proper.txt` is the census list as it is; with `--capitals` it writes
`capital.txt` alone, from the `data.*` files of either version, and with
`--phrasal` `phrasal.txt` alone, from `data.verb`, and with
`--infinitive` `vinf.txt` and `vtinf.txt` alone, from `data.verb` too, and with
`--every` the four `every_*` files alone, from the `index.*` files, `data.verb`
and `cntlist.rev`.

WordNet 3.0 is Copyright 2006 by Princeton University, used under its
licence: "Permission to use, copy, modify and distribute this software and
database and its documentation for any purpose and without fee or royalty
is hereby granted, provided that you agree to comply with the following
copyright notice and statements, including the disclaimer, and that the
same appear on ALL copies of the software, database and documentation,
including modifications that you make for internal use or for
distribution. WordNet 3.0 Copyright 2006 by Princeton University. All
rights reserved. THIS SOFTWARE AND DATABASE IS PROVIDED "AS IS" AND
PRINCETON UNIVERSITY MAKES NO REPRESENTATIONS OR WARRANTIES, EXPRESS OR
IMPLIED. BY WAY OF EXAMPLE, BUT NOT LIMITATION, PRINCETON UNIVERSITY MAKES
NO REPRESENTATIONS OR WARRANTIES OF MERCHANTABILITY OR FITNESS FOR ANY
PARTICULAR PURPOSE OR THAT THE USE OF THE LICENSED SOFTWARE, DATABASE OR
DOCUMENTATION WILL NOT INFRINGE ANY THIRD PARTY PATENTS, COPYRIGHTS,
TRADEMARKS OR OTHER RIGHTS. The name of Princeton University or Princeton
may not be used in advertising or publicity pertaining to distribution of
the software and/or database. Title to copyright in this software,
database and any associated documentation shall at all times remain with
Princeton University and LICENSEE agrees to preserve same."
