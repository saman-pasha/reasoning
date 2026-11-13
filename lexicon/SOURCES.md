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
| `prose.txt` | real sentences, the grammar's opposite | WordNet 3.0's example sentences, quoted in its glosses: 8000 of two to twenty words, capitalised and stopped, in a fixed hash order -- the negatives a tagger learns to refuse (`normalise_negatives/3`) |
| `known_noun.txt`, `known_verb.txt`, `known_adverb.txt` | every word the judge knows | every SemCor-counted lemma of that part of speech, whatever its sense, commonest first, each once: not the generator's words but the tagger's -- `tagger_sane/2` refuses a tagging they contradict, and `death` as a subject slipped through while only the generator's concrete nouns were known |
| `known_adj.txt` | every adjective the dictionary knows | the counted ones first, exactly as above, then every other lemma `index.adj` names, in hash order -- because a count says how OFTEN a corpus used a word and this table's question is whether WordNet knows it as an adjective at all. `registered` has three adjective senses and no count, and the tagger read it as no adjective until it was here |

The WordNet files are ranked by the tag counts of SemCor, the sense-tagged
corpus WordNet ships as `cntlist.rev`, so a cap keeps the words English
uses and leaves the obscure ones out. The MENTIONED words the lesson
shapes generate from are not here: they are read out of the lessons in
`../corpus/`, which is data of its own kind (see its README). `build.pl` beside these files, a cocolog
program, writes every file but `proper.txt` from a WordNet 3.0 `dict`
directory (`apt install wordnet-base`; `sh tools/lexicon/build.sh`), and
`proper.txt` is the census list as it is.

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
