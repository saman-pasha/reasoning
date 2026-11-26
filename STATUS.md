# Status: parking translate.pl

Written 2026-11-23, at reasoning 1.53.0; the first goal added at 1.55.0.

**The decision** (the owner, 2026-11-23): park `translate.pl`. Every use of it
moves to the typology template system (`typology.pl` and `templates/`).

This file gives the current state, the desired state, the gaps between
them, and the steps. Change it as the work moves.

## THE GOAL (the owner, 2026-11-24)

**The reasoning library translates all 8 000 sentences of
`lexicon/prose.txt` from English into the IR, and all of that IR into
Cocolog.** Every step is measured against it, both counts
(`tools/logic/prose.pl`, the tables below). At 1.88.0: 3 952 of the 8 000
read into the IR (49.4 %), 3 789 of those 3 952 into Cocolog (95.9 %);
at 1.87.0 3 849 and 3 704, at 1.86.0 3 644 and 3 508, at 1.84.0 and 1.85.0 3 550 and 3 415, at 1.83.0 3 268 and 3 155, at 1.82.0 3 118 and 3 015, at 1.81.0 2 813 and 2 723, at 1.80.0 678 and 609. The two goals below are its two halves: the first
the IR, the second Cocolog.

**What blocks the rest** (measured at 1.88.0, `typology_coverage/4`'s
words and probes that change each sentence a known way): of the 4 048
sentences not read, 2 421 have a word no table has (at 1.86.0 the
commonest were `as` 126, `there` 69, `up` 68, `than` 53, `could` 48,
`more` 47, `very` 46, `one` 45, `two` 44, `many` 43), and the other 1 627
have every word in a table and a structure level 1 does not read. Of
those 1 627, 758 read with one word taken out, and the word says what
blocks. A word that is an adjective's still reads the most (125, and 36
more with a word that is an adjective's or a noun's; 197 at 1.87.0), but
of four shapes: an adjective after its noun with an adposition phrase
(43 by a probe that cuts the phrase: `A calyx adnate to the ovary.`), an
adjective with a capital letter (40 read lowered: `The Guyanese
capital.`, `A Gallic shrug.`), an adjective that completes an object
(about 50: `They considered colonialism immoral.`), a copula verb other
than `be` (13 read with `is` or `was` in its place: `He remained
faithful to his wife.`). THE LARGEST GAP OF ONE SHAPE IS NOW AN ADVERB
BEFORE AN ADJECTIVE: 103 read with an adverb's word taken out and 6 more
with a word that is an adverb's or an adjective's, most of them before
an adjective or a participle (`She was incurably optimistic.`, `A
perfectly natural explanation.`, `Her voice is superbly disciplined.`),
the rest between the subject and the verb (`The detective carefully
lifted some fingerprints from the table.`). Then `of` before a bare
singular noun (43: `The incarnation of evil.`), `to` before an infinitive
(26: `Glad to help.`, `Strawberries are hardy and easy to grow.`), `out`
(26), `all` (21), the passive's words (39 with `is`, `are`, `was`,
`were` or `be` taken out; 86 at 1.87.0). `the` taken out reads 46, most
of them a command whose verb no table has as a verb (`Tar the roads.`)
and `the` before a name (19: `the Great Salt Lake`). Through 1.80.0 the largest gap was the noun phrase alone,
2 130 sentences of the 4 451 with every word known (`A heavy coat.`),
which 1.81.0 reads; then the commands, 397 read with `You` before them
(`Construct a proof.`), which 1.82.0 reads; then the noun phrase with an
adposition phrase after its noun, at least 170 read with `He sees` before
them (`An award for bravery.` with `for`; 150 with the adpositions level
1 has), which 1.83.0 reads; then the prepositions, 346 read with each
one no row had changed to `in` (`for` 106 of them, `at` 32, `into` 30),
which 1.84.0 reads (282); then a verb with no subject, 107 read with `He`
before them (`Took the joke well.`), which 1.86.0 reads (94); then a noun
before a noun, 138 read with a noun taken out and 79 more with a word
that is a noun's or a verb's (`Black leather jackets.`), which 1.87.0
reads (205); then an adjective with an adposition phrase, 159 read with
an adjective's word taken out (`The movie is unsuitable for children.`),
of which 1.88.0 reads the copula's (103).

Cocolog into English goes two ways: the translator's round trip for the
logic form (`logic_write/3`), and since 1.80.0 the explainer for a
program (`explain.pl`, lesson 08): cocolog's `library(tensor_expr)`, 217
clauses, every goal of 177 explained or the text's own, the other 40
naming `library(torch)`'s predicates as terms. Since 1.85.0 it says the
role of each argument of a predicate before its first clause -- a goal
it calls, an input, an output, either, a term (`area/3 takes three
arguments: W, an input; H, an input; and A, an output.`) -- from a
meta_predicate declaration, a mode comment or the clauses; the 41
arguments `library(tensor_expr)`'s 17 mode comments name are all
inferred as the comments say, with the comments unread. 1.85.0 adds no
sentence to either count of the goal.

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
| 1.65.0 | 673 | 8.4 % | the subordinate clause of if, when and because, before or after its main clause |
| 1.64.0 | 661 | 8.3 % | the bare singular noun (`likes music`, `Helium is monatomic.`): no person, no animal, no adjective's word |
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
   noun (done: 1.64.0); then the
   `if` clause of step 4 (done: 1.65.0, with `when` and `because`). The determiners and the quantifiers read 42 more,
   about four of them false (`He is no better today.`, `All mammals except
   monotremes ...` with `except` a verb). Names read 14 more sentences of the measure;
   with every unknown first word a name they read 45, 31 of them false.
   Of the 14, four are still false: a row's name that is a common word
   too, at the start (`Snow blanketed the fields.`, `Rusty deposits.`,
   `Vital signs.`, `Faith is his anchor.`); the word is the first reading
   where the grammar reads it, so the bare noun and the phrase with no
   verb will read these.
4. The structures: the subordinate clause (`that`, `if`, `when`,
   `because`), the infinitive, the gerund, the passive, the imperative;
   the noun phrase alone (done: 1.81.0, `phrase(NP)`: 2 135 sentences more);
   the imperative (done: 1.82.0, the tense `imperative`: 305 more).

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

**Where it stands:** names (1.62.0), the determiners and the quantifiers
(1.63.0), the bare noun (1.64.0) and the `if` clause (1.65.0) at level 1,
and level 2, the logic form (1.66.0, `logic.pl`): the seven sentences of
the milestone read into the plan's logic forms. The Cocolog template
(1.67.0, `templates/cocolog.pl`) writes each form as Cocolog and reads it
back to the same form, and the program written from English runs. Cocolog
is said in English again (1.68.0, `logic_write/3`), so the first
milestone is complete: the two round trips keep the logic form.

**The second measure** (1.69.0) is `lexicon/logic.txt`: 179 English
sentences, each with the Cocolog it says, written by hand.
`tools/logic/measure.pl` counts how many give that Cocolog (their first
logic form, compared as items) and how many of the Cocolog texts are
said in English that reads back to them (`logic_write/3`, a sentence a
group); test/logic.pl's `measure` holds the counts to the last row.

| version | right | of all | kept | what moved it |
|---|---|---|---|---|
| 1.69.0 | 86 | of 104: 82.7 % | 94 | the start. The 18 misses: 7 unread (a verb of three, a comparative, a possessor, `Tweety`, `Whom`, `fed`), 3 relative clauses in a rule, 2 objects that are no constant, 2 pronouns of a clause first, 1 adjunct, 1 adposition phrase, 1 `which`, 1 question word as the object. The 10 not kept are the general sentence's: a predicate of no word or of three, a query of two atoms or of an object |
| 1.70.0 | 102 | of 120: 85.0 % | 110 | the tenses: 16 sentences more (the past, the future, the perfect, the pluperfect), all right and kept; the 18 misses as before |
| 1.71.0 | 116 | of 132: 87.9 % | 124 | the adjuncts and an adposition phrase as a predicate: 12 sentences more, all right and kept, and `John lives in Paris.` (its Cocolog now in(live(john), paris), the form 1.71.0 chose) and `The book is on the table.` right; 16 misses |
| 1.72.0 | 127 | of 143: 88.8 % | 135 | the pronouns: 11 sentences more, all right and kept -- alone a pronoun is a constant of its own (`He sleeps.` is sleep(he)), in a text of several sentences the noun phrase it refers to (`John sleeps. He dreams.` is sleep(john), dream(john)); 16 misses |
| 1.73.0 | 137 | of 153: 89.5 % | 145 | the possessors: 10 sentences more, all right and kept -- the possessed and its possessor one constant (`His dog sleeps.` is sleep(dog_of_he), `the edge of the bed` and `the bed's edge` edge_of_the_bed); 16 misses |
| 1.74.0 | 145 | of 161: 90.1 % | 153 | the indefinite objects: 8 sentences more, all right and kept -- in a statement an individual (`He received a letter.` is letter(a_letter), receive(he, a_letter)), in a question or a condition a variable (`Who sees a dog?` is see(X, Y), dog(Y)); `The cat eats fish.` and `Cats eat fish.` now read an individual of the bare plural object, where the hand-written Cocolog says the kind (fish): 16 misses |
| 1.75.0 | 153 | of 169: 90.5 % | 161 | the plural definite noun phrases: 8 sentences more, all right and kept -- a constant of the group, the English plural word (`The rebels salted the fields.` is salt(the_rebels, the_fields), `His hands are cold.` cold(hands_of_he)); 16 misses |
| 1.76.0 | 153 | of 169: 90.5 % | 161 | the constants are terms (the(dog), the(pl(rebel)), a(dog), of(dog, john)): the hand-written Cocolog of the measure took the new form, and every count is 1.75.0's |
| 1.77.0 | 163 | of 179: 91.1 % | 171 | the indefinite noun phrases: 10 sentences more, all right and kept -- an individual wherever a statement says it (an adjunct's, a possessor, a possessed), its term a(T) with its adjectives and number (`Some dogs bark.` is dog(a(pl(dog))), `John sees a big dog.` dog(a(big(dog))): those two lines of the measure took the new form); 16 misses |
| 1.78.0 | 175 | of 189: 92.6 % | 181 | the nouns of relation: 10 sentences more, all right and kept, and `John is Mary's father.` and `Mary is the mother of John.` right (father(john, mary), mother(mary, john): level 1 reads a name as a possessor since 1.78.0); 14 misses |
| 1.79.0 | 183 | of 197: 92.9 % | 189 | `when`: 8 sentences more, all right and kept -- in the present a rule (`John sleeps when Mary sings.` is sleep(john) :- sing(mary)), in a tense a link of the two atoms (`John slept when Mary sang.` is when(past(sleep(john)), past(sing(mary)))); 14 misses |
| 1.81.0 | 194 | of 208: 93.3 % | 200 | a noun phrase alone: 11 sentences of lexicon/prose.txt more, all right and kept -- its noun and its adjectives said of its term (`A heavy coat.` is coat(a(heavy(coat))), heavy(a(heavy(coat)))), and said back as the phrase; the Cocolog reader takes no adverb on a copula's atom (good(good(taste)) is `Good taste.`); 14 misses, 1.80.0's |
| 1.82.0 | 203 | of 217: 93.5 % | 209 | the commands: 9 sentences of lexicon/prose.txt more, all right and kept -- the imperative a tense of the atoms, the subject you (`Mince the garlic.` is imperative(mince(you, the(garlic)))); 14 misses, 1.80.0's |
| 1.83.0 | 214 | of 228: 93.9 % | 220 | a noun phrase with an adposition phrase after its noun: 11 sentences more, 10 of them lexicon/prose.txt's, all right and kept -- one constant, the adposition's term inside the(...) or a(...) (`The house on the hill is old.` is old(the(on(house, the(hill))))); 14 misses, 1.80.0's |
| 1.84.0 | 225 | of 239: 94.1 % | 231 | the other prepositions: 11 sentences more, all right and kept -- a predicate of two as in/2 is, round the atom (`He slept during the storm.` is past(during(is_sleep(he), the(storm)))), after `is` (`The book is at the station.` at(the(book), the(station))) or inside a constant (a(for(large(turnout), the(meeting)))); 14 misses, 1.80.0's |
| 1.86.0 | 235 | of 249: 94.4 % | 241 | a clause with no subject: 10 sentences of lexicon/prose.txt more, all right and kept -- its subject the constant someone (`Took the joke well.` is past(well(take(someone, the(joke))))), said back as `Someone took the joke well.`; 14 misses, 1.80.0's |
| 1.87.0 | 245 | of 259: 94.6 % | 251 | a noun before a noun: 10 sentences of lexicon/prose.txt more, all right and kept -- the predicate nn(Modifier, Thing) of the thing's term, and nn(M, X) inside a term (`A treasure hunter.` is hunter(a(nn(treasure, hunter))), nn(treasure, a(nn(treasure, hunter))); `The patient is on life support.` on(the(patient), nn(life, support))), said back as the compound; 14 misses, 1.80.0's |
| 1.88.0 | 255 | of 269: 94.8 % | 261 | an adjective with an adposition phrase: 10 sentences of lexicon/prose.txt more, all right and kept -- the adjective's atom inside the phrase, as a clause's adjunct is round its verb's (`The book was full of errors.` is error(a(pl(error))), past(of(full(the(book)), a(pl(error)))); `All men are equal before the law.` before(equal(X), the(law)) :- man(X)); 14 misses, 1.80.0's |

**The 8 000 sentences of the first measure into Cocolog**
(`tools/logic/prose.pl`): read into level 1, then a logic form, then
Cocolog; and since 1.76.0 (the owner's rule: both counts after each step)
read into level 1 and written back into English, and the same sentence
again. A count translated is not a count right: the Cocolog is not
checked, and a sentence level 1 reads wrong (a fragment, `A dead shot.`)
is translated wrong. A sentence written back other than it was says its
meaning in another form (`the bed's edge` for `the edge of the bed`).

| version | into the IR | IR, then English (the same) | IR, then Cocolog |
|---|---|---|---|
| 1.76.0 | 673 | 673 (584) | 476 (6.0 %) |
| 1.77.0 | 673 | 673 (584) | 574 (7.2 %) |
| 1.78.0 | 678 | 678 (587) | 599 (7.5 %) |
| 1.79.0 | 678 | 678 (587) | 609 (7.6 %) |
| 1.80.0 | 678 | 678 (587) | 609 (7.6 %) |
| 1.81.0 | 2 813 | 2 813 (2 559) | 2 723 (34.0 %) |
| 1.82.0 | 3 118 | 3 118 (2 847) | 3 015 (37.7 %) |
| 1.83.0 | 3 268 | 3 268 (2 986) | 3 155 (39.4 %) |
| 1.84.0 | 3 550 | 3 550 (3 234) | 3 415 (42.7 %) |
| 1.86.0 | 3 644 | 3 644 (3 327) | 3 508 (43.9 %) |
| 1.87.0 | 3 849 | 3 849 (3 518) | 3 704 (46.3 %) |
| 1.88.0 | 3 952 | 3 952 (3 602) | 3 789 (47.4 %) |

| version | translated | of 8 000 | the first reasons of the others read into level 1 |
|---|---|---|---|
| 1.69.0 | 59 | 0.7 % | the past tense 451, an adjunct 41, an IR shape with no rule 36, a pronoun 27 |
| 1.70.0 | 111 | 1.4 % | an adjunct 248, a pronoun 112, an IR shape with no rule 110, a predicate with no rule 28, an object that is no constant 24 |
| 1.71.0 | 142 | 1.8 % | a pronoun 271, an IR shape with no rule 145, an object that is no constant 33, a plural definite noun phrase 23, a predicate with no rule 23. Of the 31 new ones about 8 are wrong because level 1 reads them wrong: a fragment with a passive participle (`Yogurt made with skim milk.`), an adjective read as an adverb (`Prices remained flat.`), `last night` joined to a noun |
| 1.72.0 | 231 | 2.9 % | an IR shape with no rule 233 (a possessor, a relative clause), an object that is no constant 91, a predicate with no rule 37, a plural definite noun phrase 29, an adjunct's noun phrase that is no constant 19. Of the 89 new ones about 4 are wrong: two level 1 reads wrong (`She was near tears.`), and a pronoun that refers to a noun of its own sentence is its own constant (`held them`: they, not the_receipts) |
| 1.73.0 | 329 | 4.1 % | an object that is no constant 97, a plural definite noun phrase 68, a possessor that is no constant 40, a predicate with no rule 39, an indefinite possessed 29. Of the 98 new ones about 6 are wrong because level 1 reads them wrong: a fragment (`My best wishes.`), an infinitive, an imperative, `like` and `now` in other classes, a noun compound |
| 1.74.0 | 417 | 5.2 % | a plural definite noun phrase 69, a possessor that is no constant 40, a predicate with no rule 39, an indefinite possessed 29, an adjunct's noun phrase that is no constant 26. Of the 88 new ones about 5 are wrong: `several` read as an adjective (three), a noun compound (`a wage floor`), and a generic plural subject with an object is read as individuals only (`Dictionaries list words in alphabetical order.`) |
| 1.75.0 | 476 | 6.0 % | a possessor that is no constant 40, a predicate with no rule 40, an indefinite possessed 32, an adjunct's noun phrase that is no constant 29, an IR shape with no rule 13. Of the 59 new ones about 7 are wrong: fragments, an infinitive and `like` that level 1 reads wrong (`The problems involved.`), and a possessive pronoun of its own sentence's subject (`Each industry has its own trade publications.`: its is the constant it, not the rule's variable) |
| 1.77.0 | 574 | 7.2 % | a predicate with no rule 40 (a copula's noun phrase with a possessor: `Sculpture is a form of art.`), an IR shape with no rule 13, `when` 11, `no` 7, `this` 7. No sentence lost; 92 of the 476 keep their facts with a fuller individual (a(pl(book)), a(big(dog))). Of the 98 new ones about 18 are wrong: level 1 joins an adposition phrase to the verb (6: `an abrupt end to a promising career`), a generic statement is read as individuals (5: `Children need a lot of love.`), a fragment is read as a clause (4: `Bonnets smothered with flowers.`), `several` read as an adjective (3), `hands` not made its noun |
| 1.78.0 | 599 | 7.5 % | an IR shape with no rule 14, a noun of relation with an adjective 13 (`She was his main squeeze.`), `when` 11, `no` 7, `this` 7, a copula's definite noun phrase with no possessor 6. Level 1 reads 5 sentences more (a name as a possessor: `They clambered to the tip of Monadnock.`), and all 678 go back into English. No sentence lost or changed. Of the 25 new ones about 4 are wrong: `several` read as an adjective, `other` made a condition (`All other sets are subsets of the universal set.`), and a bare plural possessor read as a group, not the kind (2: `the dean of foreign correspondents`) |
| 1.79.0 | 609 | 7.6 % | an IR shape with no rule 15, a noun of relation with an adjective 13, `no` 7, `this` 7, a copula's definite noun phrase with no possessor 6, a negation 4. No sentence lost or changed. Of the 10 new ones (all but one of the 11 `when` sentences: the last level 1 reads wrong) about 3 are imperfect: a pronoun of its own sentence is its own constant (2: `The house was a wreck when they bought it.`: it, not the house), and `turned on the juice` read as an adjunct |
| 1.81.0 | 2 723 | 34.0 % | an IR shape with no rule 15, a noun of relation with an adjective 13, `this` 9, a phrase with a relative clause 9 (`Roads that lead therefrom.`), a predicate with no rule 8, `no` 7. Level 1 reads 2 135 sentences more, every one a noun phrase alone (`phrase(NP)`), and 2 114 of them go into Cocolog: its noun and its adjectives said of its term. One old reading changed, for the better (`Vital signs.`: the phrase, where it was the verb `sign` of a name `Vital`); no other sentence lost or changed. In two samples of 60 of the new ones about 6 are imperfect: a noun before a noun read as an adjective (`An oil baron.`: oil(a(oil(baron)))), a bare plural possessor read as individuals, not the kind (`The formation of sentences.`). A relative clause in a phrase alone has its marker: with none the first cut read 6 clauses as phrases (`The ice cream melted.`, the ice that cream melted) and keeps 3 true ones unread (`A sudden recognition of the problem he faced.`) |
| 1.82.0 | 3 015 | 37.7 % | an IR shape with no rule 19, `this` 16, a noun of relation with an adjective 13, a phrase with a relative clause 9, a predicate with no rule 8, `no` 7, `that` 5. Level 1 reads 305 sentences more, every one a command (the tense `imperative`, the subject you said by no words: `Construct a proof.`), and 292 of them go into Cocolog as imperative(Atom); the others are `this` (7: `Park your bag in this locker.`) and a negation (`Do not ...`). No sentence lost or changed. A command with no object takes no verb that is an adjective's word: the first cut read 7 adjectives with their complement as commands (`Close to noon.`, `Secure from harm.`). In a sample of 60 of the new ones 1 is wrong, and of the 46 whose object is a bare noun about 5: a noun before a noun read as a command (`Travel allowance.`, `String beans.`) |
| 1.83.0 | 3 155 | 39.4 % | an IR shape with no rule 23 (a coordination where a constant stands 16: `A church with a shuttered belfry and spire.`, `Drive a car or bus.`; a relative clause in a role 7), `this` 16, a noun of relation with an adjective 14, a phrase with a relative clause 9, a predicate with no rule 9, `no` 8, `that` 6. Level 1 reads 150 sentences more, every one with a noun phrase that has an adposition phrase after its noun (`np_pp(NP, pp(Prep, X))`: `A dip in prices.`, `The man with the hat sleeps.`), and 140 of them go into Cocolog, the phrase one constant (the(with(man, the(hat)))). One old reading changed, for the better (`People in high places.`: the phrase, where it was a command); no sentence lost. A phrase whose head has no article is a command where its words read as one: the 8 such sentences stay 1.82.0's commands (`Knock on the door.`; `Murder in the second degree.`, a phrase, among them). In a sample of 38 of the new ones 4 are wrong -- a verb with no subject read as a noun phrase (2: `Spoke with unmoderated harshness.`), `Hands in the starting position.` with `position` the verb, `Work in the butter and ...` -- and 2 put on the noun a phrase that is the clause's (`The common people in those days suffered greatly.`) |
| 1.84.0 | 3 415 | 42.7 % | an IR shape with no rule 34 (a coordination where a constant stands 25, a relative clause in a role 9), `this` 17, a noun of relation with an adjective 14, a predicate with no rule 10, `no` 9, a phrase with a relative clause 9, `that` 6, a negation 5. Level 1 reads 282 sentences more, every one with an English preposition that had no row (38 rows more: `for` 104 of the sentences, `at` 32, `into` 30, `by` 21, `over` and `against` 11, `onto`, `between` and `about` 9; `towards` a second word of `toward`; `out of` and `instead of` two words), and 260 of them go into Cocolog, each preposition a predicate of two as in/2 is. One old reading changed, for the better (`All mammals except monotremes and marsupials are placental mammals.`: except a preposition, where it was a verb); no sentence lost. No row for `up`, `down` and `off`: with them 19 sentences more read, and most made a verb's particle a preposition and the verb's object its noun phrase (`Fold up the newspaper.`); nor for `past`, a tense's name in Cocolog. 43 rows made the gap check of an adposition phrase walk them all, English 10 % more inferences: it asks the text's adpositions now (`ty_adp_ahead/2`), and English is 0.6 % cheaper than at 1.83.0. In a sample of 40 of the new ones 5 are wrong, every one by an older class: a noun before a noun (`They played at home last night.`), an infinitive (`The end managed to hold onto the pass.`), a participle read as a verb (`A flight destined for New York.`) |
| 1.86.0 | 3 508 | 43.9 % | an IR shape with no rule 34, `this` 17, a noun of relation with an adjective 14, a predicate with no rule 10, `no` 9, a phrase with a relative clause 9, `that` 6, a negation 5, a generic object 5. Level 1 reads 94 sentences more, every one a clause with no subject (`Took the joke well.`: its subject pron(3, sg, zero), someone the text does not name, where the English template has `ty_subject_unsaid(english, 3)`), and 93 of them go into Cocolog, the subject the constant someone. No sentence lost or changed. Tried after the command; refused where the words read as a clause with a subject (`Dogs sleep.` is no clause of someone who dogs sleep) and, with no object, where the past verb's word is an adjective's and the verb takes an object in every sense (`Interested in sports.`, a passive: the first cut read 23 of them, and refused 9 active verbs with it, `Fell into a profound sleep.`, until WordNet's verbs that may take no object, lexicon/vi.txt, a new row `ty_verb_list(english, no_object, vi)`, kept them). Spanish, Italian and Persian write it with the subject dropped (`Durmió.`). In a sample of 47 of the new ones about 5 are wrong: a passive whose verb may take no object (4: `Caught by a couple of alert cops.`, `Worried by the worsening storm.`), a noun read as a verb (`Experiences new to him.`) |
| 1.87.0 | 3 704 | 46.3 % | an IR shape with no rule 35, `this` 17, a noun of relation with an adjective 14, a predicate with no rule 12, a phrase with a relative clause 10, `no` 9, `that` 7, a generic object 6, a negation 5. Level 1 reads 205 sentences more, every one with a noun before a noun (`Black leather jackets.`: np(jacket, pl, indef, [black, n(leather)]), where the English template has `ty_noun_modifier(english, before)`), and 196 of them go into Cocolog, the predicate nn(Modifier, Thing) and, inside a term, nn(M, X) (`a(pl(black(nn(leather, jacket))))`). No sentence lost or changed: level 1 reads a sentence again with the modifier only where it reads nothing without it and two nouns stand in a row (one pass changed 40 readings of 1.86.0). Refused: a modifier whose word is an adjective's (`black leather` is no two nouns), and a bare noun after `to`, an infinitive (`to raise money`, `ty_infinitive_mark(english, [to])`: the first cut read 6 of them as an adposition phrase). Spanish and French write it after the noun with `de` (`Chaquetas negras de pellejo.`), Italian with `di`, German as one word (`Ein großes Hundhaus.`, with no linking letter yet, and not read), Persian with the ezafe (read back as a possessor). Two modifiers do not say their bracketing (nn(day, nn(care, program))). In a sample of 40 of the new ones about 8 are wrong, most for another shape of the sentence that the compound lets level 1 read wrong: a verb read as a noun (`Ream oranges.`, `Pole climbing plants like beans.`), a gerund subject (`Drinking alcohol is a health hazard.`, `Mixing sounds.`), `have` with a participle (`He had the gem set.`) |
| 1.88.0 | 3 789 | 47.4 % | an IR shape with no rule 39, `this` 19, a noun of relation with an adjective 14, a phrase with a relative clause 12, a predicate with no rule 12, `no` 10, `that` 10, a negation 8, a generic object 6. Level 1 reads 103 sentences more, every one a copula's adjective with an adposition phrase (`He was aware of the danger.`: adj([ap(aware, pp(of, np(danger, sg, def, [])))]), where the English template has `ty_adjective_complement(english, after)`), and 85 of them go into Cocolog, the adjective's atom inside the phrase (past(of(aware(he), the(danger)))). No sentence lost or changed: the phrase is read only where the plain predicate is not. `of` begins such a phrase and no other: an adposition row in each language (`de`, `di`, `von`, `از`) that a possessor never takes. Spanish, Italian and French write the phrase after the adjective (`Él era consciente del peligro.`), German and Persian before (`Der Hund ist im Haus groß.`). 60 of the 103 are a passive or a progressive whose participle has an adjective's row (`They were driven from the marketplace.`, `He was suffering from museum fatigue.`), as level 1 read such a participle without a phrase before; 3 read an infinitive after `to` as a phrase (`He is sure to win.`), which the words do not tell from `He is superior to fear.`. Back from Cocolog a name that is a noun too is read as a possessed in a tense (`John was proud of Mary.` is said back `Mary's proud john is past.`), and a word that is a verb which may take no object is the verb first inside a phrase (`in(live(john), paris)` is `John lives in Paris.`: the first cut said `John es vivo en Paris.`). An adjective after its noun (`A calyx adnate to the ovary.`) is not read yet. Cost: English's round trips 0.17 % more inferences, French's 0.49 % (the first cut, a switch set in every noun phrase, 1.30 %) |

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
| `run-tests.sh` | `all` runs eight cases, without `translate` |
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
