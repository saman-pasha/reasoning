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
(`tools/logic/prose.pl`, the tables below). At 1.108.0: 4 640 of the 8 000
read into the IR (58.0 %), 4 389 of those 4 640 into Cocolog (94.6 %);
at 1.107.0 4 580 and 4 360, at 1.105.0 and 1.106.0 4 479 and 4 275, at 1.104.0 4 456 and 4 256, at 1.103.0 4 405 and 4 209, at 1.102.0 4 405 and 4 206, at 1.100.0 and 1.101.0 4 377 and 4 179, at 1.99.0 4 358 and 4 165, at 1.98.0 4 325 and 4 141, at 1.96.0 and 1.97.0 4 295 and 4 111, at 1.95.0 4 243 and 4 063, at 1.94.0 4 218 and 4 040, at 1.93.0 4 167 and 3 990, at 1.92.0 4 129 and 3 954, at 1.91.0 4 108 and 3 933, at 1.90.0 4 055 and 3 884, at 1.88.0 and 1.89.0 3 952 and 3 789, at 1.87.0 3 849 and 3 704, at 1.86.0 3 644 and 3 508, at 1.84.0 and 1.85.0 3 550 and 3 415, at 1.83.0 3 268 and 3 155, at 1.82.0 3 118 and 3 015, at 1.81.0 2 813 and 2 723, at 1.80.0 678 and 609. The two goals below are its two halves: the first
the IR, the second Cocolog.

**What blocks the rest** (measured at 1.96.0, `typology_coverage/4`'s
words and probes that change each sentence a known way): of the 3 705
sentences not read, 2 312 have a word no table has (at 1.86.0 the
commonest were `as` 126, `there` 69, `up` 68, `than` 53, `could` 48,
`more` 47, `very` 46, `one` 45, `two` 44, `many` 43; `very` is a word of
every template since 1.90.0, `up` a particle since 1.94.0), and the other
1 393 have every word in a table and a structure level 1 does not read.
Of those 1 393, 612 read with one word taken out, and the word says what
blocks. THE LARGEST SHAPE IS STILL A WORD THAT IS AN ADJECTIVE'S: taken
out it reads 81, and 24 more with a word that is an adjective's or a
noun's (102 at 1.95.0), of four shapes in the 102 of 1.95.0, counted by
their words, and since 1.96.0 an adjective phrase alone too (`Liable to
diabetes.`, `Glad to help.`, `Unwilling to face facts.`, 9 of the 19
that read with `to` taken out):
an adjective that completes an object (15: `They considered colonialism
immoral.`, `She made her wishes explicit.`), a copula verb other than
`be` (15: `The situation became ugly.`, `He remained faithful to his
wife.`; 25 of all the sentences not read at 1.94.0 are read with the verb
made `was` or `is`), an adjective with a capital letter that WordNet has
in small letters too, or that is a name (13: `A gorgeous Victorian
gown.`), and `still`, `only` or `just` (11: `The building is still
unfinished.`; 40 of all the sentences not read at 1.94.0 are read with
one of twelve such adverbs taken out). The adverb reads 36, and 8 more
with a word that is an adverb's or an adjective's: 16 of the 44 between
the subject and a verb that ends in -ed or -s (`The detective carefully
lifted some fingerprints from the table.`), the rest after the verb (`She
was crying quietly.`) or before an adposition phrase (`She was madly in
love.`); 36 and 9 at 1.96.0. A word that is a verb's reads 11 (27 at
1.95.0, the infinitive's verb most of them), a noun's or a verb's 6 (27),
a noun's 24. The other words of grammar (398): `the` 50, `all` 25, `of`
20 (`His declaration of innocence.`), `to` 19 (24 at 1.95.0: an
adjective phrase alone, `Glad to help.`, or a stranded `to`, `Several
matters to attend to.`), the passive's words (56 with `is`, `are`, `was`,
`were` or `be` taken out), and the particles left, `up` 8 and `out` 7: a verb with no row of it (`The music surged up.`), a particle
after the object (`They moved the meeting date up.`) or a passive
(`Knocked out by doped wine.`). Through 1.80.0 the largest gap was the noun phrase alone,
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
of which 1.88.0 reads the copula's (103); then an adverb before an
adjective, 103 read with an adverb's word taken out (`She was incurably
optimistic.`), which 1.90.0 reads (103); then an adjective after its
noun with an adposition phrase, 46 read with an adjective's word taken
out (`A calyx adnate to the ovary.`), which 1.91.0 reads (53); then an
adjective with a capital letter, 31 read with the word lowered (`The
Guyanese capital.`), which 1.92.0 reads (21); then `of` before a noun
with no article, 45 read with `of` taken out (`The incarnation of
evil.`), which 1.93.0 reads (38); then a verb with a particle, 59 read
with the particle taken out (`The mayor threw out the first ball.`, `Set
up an experiment.`), which 1.94.0 reads (51); then the infinitive, 167
read with `to`, its verb and the words after them taken out, some 75 of
them a verb's object (`He tried to catch her eye.`), which 1.95.0 reads
(25: the rest have another block inside the infinitive); then the
infinitive after a noun, an adjective and an object, and of purpose
(`A knowing attempt to defraud.`, `He is glad to help.`, `Pressure causes
plantar warts to develop a painful callus.`, `He used pressure to stop
the bleeding.`), which 1.96.0 reads (52); then the passive (`The pass
was fumbled.`, `The game was interrupted by a brief shower.`), which
1.98.0 reads (30: of the 40 read with the passive made the active's past,
the rest have an object complement, `His landscapes were deemed the acme
of beauty.`, an adverb inside the verb's words, `The area is well
populated.`, or the passive in a relative clause); then an adverb
inside or before the verb's words and the passive in a relative clause,
with no subject and in an infinitive (`He promptly forgot the address.`,
`The area is well populated.`, `Was easily confused.`, `The washing
machine needs to be serviced.`), which 1.99.0 reads (33); then an
object's complement, active and passive (`They considered colonialism
immoral.`, `His landscapes were deemed the acme of beauty.`), which
1.100.0 reads (19: 8 more begin with an adjunct before the subject, `In
England they call a fender a wing.`, which level 1 does not read yet);
then the progressive (`Pigs were wallowing in the mud.`, 25 read when
made simple), which 1.102.0 reads (28); then an adposition phrase alone
(`In direct sunlight.`, 47 read after `The dog sleeps`, of 156 unread
sentences that begin with an adposition), which 1.104.0 reads (51), and
an adposition phrase before the subject (`In England they call a fender
a wing.`, 15 read with the phrase put at the end, and 10 more with an
adverb first, `Suddenly she felt a sharp pain in her side.`), which
1.105.0 reads (23).

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

**Meaning before coverage** (1.89.0, after the review of 2026-11: "make
the pipeline semantically trustworthy"): a count translated is not a
count right, so a step may correct meanings and add no sentence. 1.89.0
does: a text's individuals are each its own (`Something is red.
Something is blue.` is red(something), blue(something_2); `John sees a
dog. Mary sees a dog.` two dogs, a(dog) and a(dog, 2); `A dog sees a
dog.` see(a(dog), a(dog, 2)); through 1.88.0 one thing, one dog, and a
dog that sees itself), and a pronoun after a generic sentence is generic
too (`A dog barks. It sleeps.` two rules of every dog; through 1.88.0 a
rule and a fact of one dog). No sentence of the 8 000 changed (none says
one indefinite name twice); test/logic.pl's `meanings_apart` holds twelve
texts that look alike and mean apart. The review's quantifier example is
right as it stands: `Something is mortal.` is a fact of one thing,
mortal(something), and `Something is mortal if it is human.` a rule, as
the controlled reading (Attempto's) makes `something ... it` in an if
clause any thing. Still open: negation, `no` and `this` at level 2 (8,
10 and 19 sentences of the reasons below), and the Cocolog reader keeps
no variable names or places yet (TRANSLATOR-PLAN.md).

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
   `because`), the infinitive, the gerund, the passive (done: 1.98.0, 30
   more; 1.99.0, 14 more with an adverb, in a relative clause, with no
   subject or in an infinitive), the object complement (done: 1.100.0, 19
   more), the progressive (done: 1.102.0, 28 more; the progressive
   passive, `is being built`, 1.103.0, none among the 8 000), the imperative;
   the noun phrase alone (done: 1.81.0, `phrase(NP)`: 2 135 sentences more),
   the adposition phrase alone (done: 1.104.0, `phrase(pp(Prep, NP))`: 51 more),
   the adjunct before the subject (done: 1.105.0, 23 more);
   the words of grammar as rows (done: 1.107.0, 101 more: the closed
   adverbs, the numbers and the quantifiers);
   the modals and the short forms of not (done: 1.108.0, 60 more: `can`,
   `must`, `ought to`, `doesn't`, `couldn't`);
   the imperative (done: 1.82.0, the tense `imperative`: 305 more).

The other five languages take the class design after English. Since
1.97.0 an infinitive as a verb's object and one of purpose are read and
written in Spanish, Italian, French and German too (`El niño quiere ver
al perro.`, `El niño empieza a ver al perro.`, `Il ragazzo tenta di
vedere il cane.`, `Der Junge versucht den Hund zu sehen.`, `Le garçon dort
pour voir le chien.`), and English's infinitive goes into them (`The boy
wants to see the dog.` is `El niño quiere ver al perro.`). Not yet: the
infinitive after a noun, an adjective or an object in those four,
German's bare infinitive after `wollen` (`Der Junge will den Hund
sehen.`, no wollen row yet), and Persian, which says the subjunctive
where English says an infinitive (`پسر می‌خواهد سگ را ببیند.`). Since
1.101.0 the passive is read and written in Spanish, Italian, French and
German (`La niña fue vista.`, `La ragazza fu vista dal ragazzo.`, `Les
filles ont été vues.`, `Das Mädchen wurde vom Jungen gesehen.`): rows of
pass(T), the participle agreeing with the subject in the three that say
participle(subject), German's at the clause's end; and a passive of any
of them is its active at level 2 (`El perro fue visto por el niño.` is
past(see(the(boy), the(dog))), in German `Der Junge sah den Hund.`). Not
yet: Persian's passive (no participle row), and a Spanish
or Italian participle that is a noun too reads first as the noun (`La
niña fue vista por el niño.` is the girl going to a sight, its passive a
later reading). Since 1.106.0 the Italian and German perfect passive
too (`La ragazza è stata vista dal ragazzo.`, `Das Mädchen ist vom
Jungen gesehen worden.`, `das Mädchen, das gesehen worden ist`), the
active's perfect at level 2. Since 1.104.0 an adposition phrase alone is read and
written in all six (`En la casa grande.`, `Nella casa grande.`, `Im
großen Haus.`).

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
| 1.90.0 | 265 | of 279: 95.0 % | 271 | an adverb that grades an adjective: 10 sentences of lexicon/prose.txt more, all right and kept -- the adverb round the adjective's atom, and round its wrap inside a term (`The product is commercially available.` is commercially(available(the(product))); `A dimly lit room.` room(a(dimly(lit(room)))), dimly(lit(a(dimly(lit(room))))); `They envied her naturally curly hair.` past(envy(they, of(naturally(curly(hair)), she)))); 14 misses, 1.80.0's |
| 1.91.0 | 275 | of 289: 95.2 % | 281 | an adjective with an adposition phrase in a noun phrase: 10 sentences of lexicon/prose.txt more, all right and kept -- the adjective with its phrase in the term, A(T, Prep, X), and said of the term as a copula's phrase is (`A calyx adnate to the ovary.` is calyx(a(adnate(calyx, to, the(ovary)))), to(adnate(a(adnate(calyx, to, the(ovary)))), the(ovary)); `A house aglow with lights.` adds the lights' individual, light(a(pl(light)))); 14 misses, 1.80.0's |
| 1.92.0 | 285 | of 299: 95.3 % | 291 | an adjective with a capital letter: 10 sentences of lexicon/prose.txt more, all right and kept -- the adjective's atom the small word, as any adjective's (`The Guyanese capital.` is capital(the(guyanese(capital))), guyanese(the(guyanese(capital)))), and the English template puts its capital back (`He left an indelible mark on the American theater.`); 14 misses, 1.80.0's |
| 1.93.0 | 295 | of 309: 95.5 % | 301 | a bare noun after `of` whose word is an adjective's too: 10 sentences of lexicon/prose.txt more, all right and kept -- the noun a constant of its own inside the possessed's term, as any bare noun is (`The incarnation of evil.` is incarnation(of(incarnation, evil)); `He felt a stream of air.` stream(a(of(stream, air))), past(feel(he, a(of(stream, air))))); 14 misses, 1.80.0's |
| 1.94.0 | 305 | of 319: 95.6 % | 311 | a verb with a particle: 10 sentences of lexicon/prose.txt more, all right and kept -- the verb one predicate, named by its meaning (`The mayor threw out the first ball.` is past(throw_out(the(mayor), the(first(ball)))); `An opportunity opened up.` opportunity(a(opportunity)), past(open_up(a(opportunity)))); 14 misses, 1.80.0's |
| 1.95.0 | 315 | of 329: 95.7 % | 321 | an infinitive as a verb's object: 10 sentences of lexicon/prose.txt more, all right and kept -- the infinitive a term to(Atom), its atom said of the clause's own subject (`He tried to catch her eye.` is past(try(he, to(catch(he, of(eye, she))))); `The company tried to project an altruistic image.` past(try(the(company), to(project(the(company), a(altruistic(image)))))), the image a term and no fact); 14 misses, 1.80.0's |
| 1.96.0 | 325 | of 339: 95.9 % | 331 | the infinitive after a noun, an adjective and an object, and of purpose: 10 sentences of lexicon/prose.txt more, all right and kept -- an adjective's and an object's infinitive the second argument to(Atom) (`She is liable to forget.` is liable(she, to(forget(she))); `A flaw caused the crystal to shatter.` flaw(a(flaw)), past(cause(a(flaw), to(shatter(the(crystal)))))), a noun's a constant to(Noun, Atom), its atom said of someone (`A foursquare refusal to yield.` refusal(a(to(foursquare(refusal), yield(someone))))), one of purpose to(Atom, Atom2) (`They dug a pit to bury the body.` past(to(dig(they, a(pit)), bury(they, the(body))))); the line of `He tried to find out by indirection.` now past(try(he, to(by(find_out(he), indirection)))), the adjunct the infinitive's; 14 misses, 1.80.0's |
| 1.97.0 | 325 | of 339: 95.9 % | 331 | the infinitive in the other languages: no line of the measure changes, as no English reading does |
| 1.98.0 | 335 | of 349: 96.0 % | 341 | the passive: 10 sentences of lexicon/prose.txt more, all right and kept -- its active's atom, the agent `by NP' its subject, else someone (`The pass was fumbled.' is past(fumble(someone, the(pass))); `The game was interrupted by a brief shower.' shower(a(brief(shower))), past(interrupt(a(brief(shower)), the(game))); `He had been trained rigorously by the monks.' pluperfect(rigorously(train(the(pl(monk)), he)))), an object's infinitive the patient's (`He was licensed to carry a weapon.' past(license(someone, to(carry(he, a(weapon)))))); back into English each is the active (`Someone fumbled the pass.') |
| 1.99.0 | 345 | of 359: 96.1 % | 351 | an adverb inside or before the verb's words, and a passive infinitive: 10 sentences of lexicon/prose.txt more, all right and kept -- the adverb the clause's first adjunct, said of its atom as any adverb is (`He promptly forgot the address.' is past(promptly(forget(he, the(address)))); `His name has long been forgotten.' perfect(long(forget(someone, of(name, he))))), a passive infinitive's patient the clause's subject (`The washing machine needs to be serviced.' need(the(nn(washing, machine)), to(service(someone, the(nn(washing, machine)))))); back into English the adverb after the object (`He forgot the address promptly.') |
| 1.100.0 | 355 | of 369: 96.2 % | 361 | an object's complement: 10 sentences of lexicon/prose.txt more, all right and kept -- the complement the verb's third argument, the atom a copula would make of the object (`They considered colonialism immoral.' is past(consider(they, colonialism, immoral(colonialism))); `The accident left her badly shaken.' past(leave(the(accident), she, badly(shaken(she))))), a passive's its active's (`His landscapes were deemed the acme of beauty.' past(deem(someone, of(pl(landscape), he), acme(of(pl(landscape), he), beauty)))); back into English the complement after the object |
| 1.101.0 | 355 | of 369: 96.2 % | 361 | the passive in four more languages: no line of the measure changes, as no English reading does |
| 1.102.0 | 365 | of 379: 96.3 % | 371 | the progressive: 10 sentences of lexicon/prose.txt more, all right and kept -- a tense of its own, its name the Cocolog template's (`The engine is idling.' is progressive(idle(the(engine))); `Pigs were wallowing in the mud.' pig(a(pl(pig))), past_progressive(in(wallow(a(pl(pig))), the(mud)))); back into English the same sentence |
| 1.103.0 | 368 | of 382: 96.3 % | 374 | an object's complement of several atoms: 3 sentences of lexicon/prose.txt more, all right and kept -- the noun phrase's term the verb's third argument, an indefinite one a(Shape) and no fact (`A manned earth satellite was considered a necessary research step.' is satellite(a(manned(nn(earth, satellite)))), manned(...), nn(earth, ...), past(consider(someone, a(manned(nn(earth, satellite))), a(necessary(nn(research, step))))); `They painted it a light shade of bluish green.' past(paint(they, it, a(of(light(shade), bluish(green)))))), a definite one its constant (`He was rightly considered the greatest singer of his time.' past(rightly(consider(someone, he, of(greatest(singer), of(time, he)))))); back into English the complement after the object; 14 misses, 1.80.0's |
| 1.104.0 | 378 | of 392: 96.4 % | 384 | an adposition phrase alone: 10 sentences of lexicon/prose.txt more, all right and kept -- the phrase said of something, as a copula's adposition phrase is said of its subject (`In direct sunlight.' is in(something, direct(sunlight)); `In a nasty mood.' mood(a(nasty(mood))), nasty(a(nasty(mood))), in(something, a(nasty(mood))); `At the height of her career.' at(something, of(height, of(career, she)))); back into English the copula of something; 14 misses, 1.80.0's |
| 1.105.0 | 388 | of 402: 96.5 % | 394 | an adjunct before the subject: 10 sentences of lexicon/prose.txt more, all right and kept -- the clause's adjunct as any is, the last, round the atom (`At the last minute the government changed the rules.' is past(at(change(the(government), the(pl(rule))), the(last(minute)))); `Suddenly she felt a sharp pain in her side.' pain(a(sharp(pain))), sharp(...), past(suddenly(in(feel(she, a(sharp(pain))), of(side, she))))); back into English the adjunct at the end; 14 misses, 1.80.0's |
| 1.106.0 | 388 | of 402: 96.5 % | 394 | the perfect passive in Italian and German: no line of the measure changes, as no English reading does |
| 1.107.0 | 398 | of 412: 96.6 % | 404 | the words of grammar as rows: 10 sentences of lexicon/prose.txt more, all right and kept -- an adverb of grammar round its atom as any adverb (`They rehearsed the scene again.' is past(again(rehearse(they, the(scene)))); `It was rather cold.' past(rather(cold(it)))), a number or a quantifier an indefinite noun phrase with the word its first modifier (`The board has seven members.' member(a(pl(seven(member)))), seven(...), have(the(board), a(pl(seven(member))))); back into English the same sentence; 14 misses, 1.80.0's |
| 1.108.0 | 408 | of 422: 96.7 % | 414 | the modals: 10 sentences of lexicon/prose.txt more, all right and kept -- a modal its own name round its atom, as a tense is (`He can hear the snap of a twig.' is twig(a(twig)), can(hear(he, of(snap, a(twig)))); `In bridge you must follow suit.' must(in(follow(you, suit), bridge)); `The punishment ought to be proportional to the crime.' ought(to(proportional(the(punishment)), the(crime)))), the passive's active in it (`Our ideas must be substantiated into actions.' must(into(substantiate(someone, ...), ...))) |

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
| 1.89.0 | 3 952 | 3 952 (3 602) | 3 789 (47.4 %) |
| 1.90.0 | 4 055 | 4 055 (3 695) | 3 884 (48.6 %) |
| 1.91.0 | 4 108 | 4 108 (3 745) | 3 933 (49.2 %) |
| 1.92.0 | 4 129 | 4 129 (3 764) | 3 954 (49.4 %) |
| 1.93.0 | 4 167 | 4 167 (3 802) | 3 990 (49.9 %) |
| 1.94.0 | 4 218 | 4 218 (3 850) | 4 040 (50.5 %) |
| 1.95.0 | 4 243 | 4 243 (3 873) | 4 063 (50.8 %) |
| 1.96.0 | 4 295 | 4 295 (3 918) | 4 111 (51.4 %) |
| 1.97.0 | 4 295 | 4 295 (3 918) | 4 111 (51.4 %) |
| 1.98.0 | 4 325 | 4 325 (3 943) | 4 141 (51.8 %) |
| 1.99.0 | 4 358 | 4 357 (3 948) | 4 165 (52.1 %) |
| 1.100.0 | 4 377 | 4 376 (3 964) | 4 179 (52.2 %) |
| 1.101.0 | 4 377 | 4 376 (3 964) | 4 179 (52.2 %) |
| 1.102.0 | 4 405 | 4 403 (3 989) | 4 206 (52.6 %) |
| 1.103.0 | 4 405 | 4 403 (3 989) | 4 209 (52.6 %) |
| 1.104.0 | 4 456 | 4 454 (4 030) | 4 256 (53.2 %) |
| 1.105.0 | 4 479 | 4 477 (4 030) | 4 275 (53.4 %) |
| 1.106.0 | 4 479 | 4 477 (4 030) | 4 275 (53.4 %) |
| 1.107.0 | 4 580 | 4 577 (4 106) | 4 360 (54.5 %) |
| 1.108.0 | 4 640 | 4 637 (4 133) | 4 389 (54.9 %) |

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
| 1.90.0 | 3 884 | 48.6 % | an IR shape with no rule 42, `this` 21, a noun of relation with an adjective 14, a phrase with a relative clause 13, a predicate with no rule 12, `no` 10, `that` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 103 sentences more, every one with an adverb that grades an adjective (`She was incurably optimistic.`: adj([adv(incurably, optimistic)]), where each template has `ty_adjective_adverb(L, before)`), and 95 of them go into Cocolog, the adverb round the adjective's atom (past(incurably(optimistic(she)))) and round its wrap inside a term (a(perfectly(natural(explanation)))); the other 8 are `this`, a relative clause or a coordination where a constant stands. No sentence lost or changed: an adverb is read before an adjective only where the text has an adverb-only word right before an adjective's (`'$ty_av'`). The adverb's word is no adjective's and no verb's, so `small red` stays two adjectives and `see red` a verb and its object; that loses the adverbs that are a verb's word too (`well known`, 5 sentences). Every template writes it (`Der sehr große Hund schläft.`, `El perro muy grande duerme.`, `Le chien très grand dort.`, `سگ خیلی بزرگ می‌خوابد.`), `very` a row of each. Of 40 new readings looked at, 1 is wrong (`A merely verbal writer who sacrifices content to sound.`: `content` the relative clause's verb and `sacrifices` its subject), and a passive is read as an adjective where its participle has an adjective's row, as before (`Any variation in his routine was immediately reported.`). Cost: the round trips 0.27 % (Spanish) to 0.60 % (French) more inferences, English 0.52 % (the first cut, an `append/3` walk over the adverb rows, 1.2 %) |
| 1.91.0 | 3 933 | 49.2 % | an IR shape with no rule 42, `this` 21, a predicate with no rule 15, a phrase with a relative clause 14, a noun of relation with an adjective 14, `no` 10, `that` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 53 sentences more, every one with an adjective with an adposition phrase in a noun phrase (`A calyx adnate to the ovary.`: np(calyx, sg, indef, [ap(adnate, pp(to, np(ovary, sg, def, [])))]), the English template's `ty_adjective_phrase_noun(english, after)` putting it after the noun, the other five's `with` where their adjectives stand: `El perro grande en la casa duerme.`, `Der im Haus große Hund schläft.`), and 49 of them go into Cocolog, the adjective with its phrase in the noun phrase's term, A(T, Prep, X), and said of the term as a copula's phrase is (calyx(a(adnate(calyx, to, the(ovary)))), to(adnate(a(adnate(calyx, to, the(ovary)))), the(ovary))); the other 4 a relative clause, a passive or `according to`. The item is read in a pass of its own, after the plain reading and before the nouns before a noun (ty_nn_passes/3): with it in the first pass, a word that is a noun and an adjective was read as the noun and the next noun as an adjective with a phrase, and 8 right readings went wrong (`A special kind of paint.` the noun special and kind of paint). So 5 readings of 1.90.0 change, each a noun before a noun read before: 4 are right now (`A diet high in protein.`, `An issue open to question.`, `A herald chosen for his sonorous voice.`, `He had the gem set in a ring for his wife.`) and 1 is wrong (`He enjoyed the evening light across the lake.`, light an adjective). Of the 53, about 6 are wrong: `Please move clockwise in a circle.` (move a noun), `being` a noun twice, `A solvent unsuitable for use on wood surfaces.` a rule of surfaces. Where the words have a plain reading the item is not read: Spanish, Italian and French read `el perro grande en la casa` as the adjective and the noun's own phrase, and English `John sees a dog big in the house.` takes big for an adverb. Cost: the round trips 1.1 % (Persian) to 1.6 % (English, Spanish) more inferences, some three calls in each noun phrase tried (the first cut, a part after the noun in every noun phrase and the switch set by a walk of the IR, 2 % to 8 %) |
| 1.92.0 | 3 954 | 49.4 % | an IR shape with no rule 42, `this` 21, a predicate with no rule 15, a phrase with a relative clause 14, a noun of relation with an adjective 14, `no` 10, `that` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 21 sentences more, each with an adjective written with a capital (`The Guyanese capital.`, `A Gallic shrug.`, `The Hindu faith.`), and all 21 go into Cocolog. The capitals are data, not grammar: lexicon/capital.txt holds WordNet's one-word adjectives written ONLY with a capital (629: no lemma of any part of speech has the word in small letters, so `Polish`, a verb's `polish`, and `Victorian`, an adjective's `victorian` too, are not there), from WordNet 3.1's data files (the `wordnet-db` package of npm, `lexicon/build.pl -- --capitals`), and the English import makes each a `ty_capital/3` row, the row `I` and the months had: read from the capital wherever it stands and written with it. Not a word that is a name too (15: `Julian`, `Norman`, `Burundi`) or the vocabularies' own meaning (`Neapolitan`, `Corsican`, whose Italian and Spanish words are of that meaning): 612 rows. A row lowers the word wherever it stands, so where the words read nothing so, they are read again with such a word as written (`ty_surface_kept/2`): the first cut lost 4 readings of a language as a name (`He speaks French after a fashion.`, `A working knowledge of Spanish.`), which this keeps. No sentence lost or changed. The other 10 of the 31: an adjective WordNet has in small letters too (`A gorgeous Victorian gown.`, `Bohemian`, `Allied`, `Confederate`, `Eastern`), a name (`German`), or a word no table has (`Pyrrhic`). The meaning is the small word, so Spanish writes `La capital guyanesa.`. Cost: the round trips 0.01 % to 0.03 % more inferences |
| 1.93.0 | 3 990 | 49.9 % | an IR shape with no rule 42, `this` 22, a phrase with a relative clause 15, a predicate with no rule 15, a noun of relation with an adjective 14, `no` 10, `that` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 38 sentences more, each with a bare noun after `of` whose word is an adjective's too (`The incarnation of evil.`, `A man of quality.`, `A pocket of air.`), and 36 of them go into Cocolog. A bare singular noun stays refused where its word is an adjective's (1.64.0's rule, so `The big dog is red.` keeps its adjective), but not after a possessor's word (`of`, `de`, `di`), where no adjective stands alone: `'$ty_mass_adj'`, set around the possessor alone (`ty_poss_part//10`, `ty_mass_ok/2`). It has a pass of its own, after the plain one and before the others (`'$ty_massp'`, where the text has a possessor's word; `ty_nn_passes/3`): in the plain pass `A room of smiling faces.` was a clause, smiling a noun and faces its verb, and 5 right readings changed so. 2 readings of 1.92.0 change, each a language after `of`, now its noun where it was a name (`A working knowledge of Spanish.`: np(spanish, sg, mass, []) for name('Spanish')), the Cocolog the same. Of the 38 about 3 are wrong (`His theory is the antithesis of mine.`, mine a noun; two coordinations: `A woman of breeding and refinement.`). Measured and left out: the same for an adposition's object (`dressed in red`) reads 26 sentences more, 20 into Cocolog, but `to meet` and `to spread` become a noun after `to`, `while` a noun, and 2 adjective phrases of 1.91.0 become clauses, the pass coming before theirs. And a bare constant that is a name too reads back as the name (`An unbloody transfer of power.` is said back `... of Power.`, a name row's: 1.76.0's order). Cost: the round trips 0.02 % to 0.12 % more inferences |
| 1.94.0 | 4 040 | 50.5 % | an IR shape with no rule 42, `this` 22, a phrase with a relative clause 15, a predicate with no rule 15, a noun of relation with an adjective 14, `that` 11, `no` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 51 sentences more, each with a verb and a particle (`The mayor threw out the first ball.`, `Set up an experiment.`, `An opportunity opened up.`, `The plane touched down at noon.`), and 50 of them go into Cocolog, the verb one predicate named by its meaning (past(throw_out(the(mayor), the(first(ball))))). The meanings are WordNet's: `lexicon/build.pl --phrasal` writes lexicon/phrasal.txt from data.verb, 1 725 lemmas of a verb and a particle with what object their frames take (849 one, 454 none, 422 either), and the English import makes a ty_phrasal/5 row of each whose verb it has, 1 398. The particle is read after the verb's words, before the object, in the verb group's last clause (`ty_verb_group//8`), so the plain verb is read first and a preposition after a verb stays one (`The dog sat on the mat.`): no reading of 1.93.0 changes, and no particle is read where a relative clause's gap moved the same adposition to its front (`The boy sees the house in which the dog sleeps in.` stays refused, not sleep_in). Of the 51 about 3 are wrong: `Came up the lightless stairs.` (come_up with an object, where `up` is the stairs' preposition; WordNet lets come_up take one), `It worked up to right now.`, and `The culprit started to run and the cop took off in pursuit.`, whose `to run` an older rule reads as a noun. Not read: the particle after the object (`He threw it out.`, `threw the ball out`), and so a pronoun object, which the writer refuses after the particle; a question; and a phrasal verb in the other languages, which have no row. Cost: as the verb's own read, the particle asked of every verb, the round trips cost 0.5 % to 2.4 % more inferences, a language with no row the most (read with the meaning unbound where the IR gave it, English 129 %); as the verb group's last clause, in a language with rows (`'$ty_phrasal_made'/1`) and a sentence with a particle's word (`'$ty_pparticle'`), English 0.48 % and the others 0.08 % to 0.13 % |
| 1.95.0 | 4 063 | 50.8 % | an IR shape with no rule 44, `this` 22, a phrase with a relative clause 15, a predicate with no rule 15, a noun of relation with an adjective 14, `that` 11, `no` 10, a negation 8, a generic object 6, an object of `some` 5. Level 1 reads 25 sentences more, each with an infinitive as a verb's object (`He tried to catch her eye.`, `He wants to reconstruct the original text.`, `You have to face the music.`, `He seems to have ample ready money.`), and 23 of them go into Cocolog. The IR is inf(Verb, Object[, Adjuncts]) where a verb's object stands (clause(try, past, pos, pron(3, sg, m), inf(catch, of(pron(3, sg, f), np(eye, sg, def, []))))), read as a clause in a new tense, `infinitive` (English ty_tense_form/5 [to, form(present, pl)]), whose subject no words say (`'$ty_command'` holds i(Clause) as it holds a command's), and only after a verb that may take one: ty_verb_list(L, infinitive, Base), English WordNet's frame `Somebody ----s to INFINITIVE` (lexicon/vinf.txt, `lexicon/build.pl --infinitive`, 159 verbs) and a list in the hand template of what the frames leave out (`have`, `hope`, `need`, `decide` ...; ty_verb_list/3's Base may be a list since 1.95.0). At level 2 the infinitive is a term, to(Atom), its atom said of the clause's own subject (past(try(he, to(catch(he, of(eye, she)))))), and `Demographers try to predict social fluidity.` a rule, try(A, to(predict(A, social(fluidity)))) :- demographer(A); an indefinite noun phrase in it is a term a(Shape) and no fact, the thing tried for need not be. No reading of 1.94.0 changes. Of the 25 about 2 are wrong: `The Canadian government scrapped plans to tax ...` reads `plans` as the verb, and `Attempts to explain the origin of evil in the world.` a clause with no subject, where it is a noun phrase. Not read: an infinitive after a noun (`an attempt to defraud`, `in order to`), an adjective (`Glad to help.`) or as a purpose (`He used pressure to stop the bleeding.`), one after an object (`He hired someone to answer his fan mail.`), and the other languages' infinitives, which have no row. Cost: the round trips 0.00 % to 0.23 % more inferences, English the most: a verb read tries one more tense pattern |
| 1.96.0 | 4 111 | 51.4 % | an IR shape with no rule 44, `this` 22, a predicate with no rule 16, a phrase with a relative clause 15, a noun of relation with an adjective 14, `that` 11, `no` 10, a negation 9, a generic object 6, an object of `some` 6. Level 1 reads 52 sentences more, each with an infinitive after a noun (`A knowing attempt to defraud.`, `He made a bid to gain attention.`), an adjective (`She is liable to forget.`, `We were unable to get satisfaction from the local store.`), an object (`A flaw caused the crystal to shatter.`, `He wanted a special stone to mark the site.`) or of purpose (`He used pressure to stop the bleeding.`, `They dug a pit to bury the body.`, `The mechanic removed the cowling in order to repair the plane's engine.`), and 47 of them go into Cocolog. The IR: a noun's infinitive the noun phrase's tail, np_pp(NP, inf(...)); an adjective's ap(A, inf(...)), after an adjective ty_adjective_list(L, infinitive, Base) names; after the object of a verb of WordNet's `Somebody ----s somebody to INFINITIVE` (lexicon/vtinf.txt, 163 verbs, less the template's `object_purpose` list of 43: use, take, make, give, have ...) the infinitive's clause, clause(V, infinitive, pos, Object, ...); else, after the object or after `in order` (ty_purpose_mark/2), an inf(...) of purpose among the clause's adjuncts, but never after a noun of ty_noun_list(L, infinitive, Base), a new header row (bid, attempt, plan, right ...), where it is the noun's. An infinitive's clause takes the adjuncts after it (`He had to sell his car at a considerable sacrifice.`, ty_infinitive_end//1), and after a verb, an adjective or a noun an infinitive may follow `to` and a bare noun that is a verb too is the infinitive (`The culprit started to run.`, `He is sure to win.`, ty_to_verb_noun/3; not after the template's `to_noun` verbs, `The ball came to rest.`). At level 2 a noun's infinitive is a constant to(Noun, Atom) of an individual, its atom said of someone; an adjective's and an object's the second argument to(Atom), said of the subject or of the object; one of purpose the term to(Atom, Atom2), Atom2 said of the subject; read back, a term inside to(...) is an atom (by(find_out(he), indirection) has a noun phrase's shape). Of the 1.95.0 readings 16 change, each now right or the same in another form (`Attempts to explain the origin of evil in the world.` a noun phrase, `The Canadian government scrapped plans to tax ...` plans a noun with its infinitive). Of the 52 about 6 are wrong: `Her compulsion to wash her hands repeatedly.` reads `hands` as the verb, `It takes several people to work the farm.` the farm worked by `it`, `He gave an inaccurate account of the plot to kill the president.` the killing his purpose, `Used devious means to achieve success.` a noun phrase with `used` an adjective, and two passives read as verbs with no subject (`Instructions altered to suit ...`). Not read: an infinitive alone (`Glad to help.`), a gap inside an infinitive (`The house that he wanted to live in.`), `someone` as an object at level 2 (`He hired someone to answer his fan mail.`), and the other languages' infinitives. Cost: the round trips 0.18 % to 0.40 % more inferences, English the most; asked of every object, adjunct and clause of every language, the first cut cost 0.34 % to 1.19 % |
| 1.97.0 | 4 111 | 51.4 % | as 1.96.0: no English reading changes (the 8 000's IR, dumped before and after, is the same). Spanish, Italian, French and German read and write an infinitive as a verb's object and one of purpose, written as their templates say: a ty_verb row of the tense infinitive where a language has no word before it (Spanish `ver`, Italian `vedere`, French `voir`), the import making a row of each verb of the words' tables whose infinitive they give (Spanish 2 626 rows, Italian 2 033), and German's ty_tense_form/5 [zu, form(present, pl)] at the clause's end (`Der Junge versucht den Hund zu sehen.`); the words a verb says before it, ty_infinitive_after(L, Meaning, Words), a new header row (Spanish `tener que`, `empezar a`; Italian `tentare di`, `iniziare a`; French `essayer de`); the mark of purpose ty_purpose_mark/2 (`para`, `per`, `pour`, `um`), and in English alone the purpose with no mark after a clause, ty_purpose_bare(L), a new choice. The readings with no mark ask a word of the text that is an infinitive (`'$ty_vinf'/2`, made at load). English's infinitive goes into the four, the same Cocolog from each (`El niño quiere ver al perro.` is want(the(boy), to(see(the(boy), the(dog))))). Not yet: their infinitive after a noun, an adjective or an object, German `wollen` (a bare infinitive), and Persian, which says the subjunctive. Cost: the round trips English 0.14 % more inferences, Spanish 0.49 %, Italian 0.50 %, French 0.39 %, German 0.48 %, Persian 0.10 %; of Spanish's, the scan of the text's words for an infinitive is a third |
| 1.98.0 | 4 141 | 51.8 % | an IR shape with no rule 44, `this` 23, a predicate with no rule 16, a phrase with a relative clause 15, a noun of relation with an adjective 14, `that` 11, `no` 10, a negation 9, a generic object 6, an object of `some` 6. Level 1 reads 30 sentences more, each a passive (`The pass was fumbled.`, `Their appeal was denied in the superior court.`, `The thief's identification was followed quickly by his arrest.`, `A program is needed to create new jobs.`), and 28 of them go into Cocolog; 5 more, read as the copula and an adjective with a `by` phrase, are now the passive (`She was afflicted by the death of her parents.`: past(afflict(of(death, of(pl(parent), she)), she)), where 1.97.0 said past(by(afflicted(she), ...))). The IR is a clause in a tense pass(T), its subject the verb's patient and its object none, its words a ty_tense_form/5 row of pass(T) (English pass(past) [was, participle], pass(perfect) [has, been, participle], 22 rows); an agent is an adjunct pp(by, NP), and after a verb whose object may take an infinitive (ty_object_infinitive/2) the infinitive is the object (clause(require, pass(past), pos, np(auditor, ...), inf(produce, ...))). The passive is read after every other reading (ty_passive//2, the last clause of ty_sentence//2 and of ty_statement//2): its patterns are tried only while `$ty_pass' is on (ty_imperative_ok/1, and the first words `is', `was' are a tense's first words only then), so no reading of 1.97.0 changes but the 5 copulas, which a passive's adjective with an agent no longer reads (ty_passive_ap/2); `He was killed.' stays killed(he). A passive takes an infinitive of purpose with no object (`A program is needed to create new jobs.'), which an active clause of a verb with its own infinitive does not. At level 2 the passive is its active (lg_active/2): the agent the NP of the first pp(by, NP) wherever it stands, else pron(3, sg, zero), the constant someone; an infinitive object clause(V2, infinitive, pos, Patient, ...). Of the 30 about 5 are wrong: `He was resigned to a life of dishonor.` (an adjective with `to`), `The strike was scheduled to begin at dawn.` and `A detail was sent to remove the fallen trees.` (the infinitive said of someone, not of the patient), `We are set to go at any time.`, and `It was created with the conscious aim of answering immediate needs.`, `answering` an adjective. Not read: an object complement after a passive (`His landscapes were deemed the acme of beauty.`), an adverb inside the verb's words (`The area is well populated.`), a passive in a relative clause, with no subject (`Is wrapped up in his family.`), with an object (`He was given a book.`) or in an infinitive (`to be loved`), and the other languages' passive, which have no row. Cost: English's round trips 0.21 % more inferences, the others 0.01 % to 0.03 %; the first cut 1.58 %, every tense pattern tried for a verb's first word walking the 22 passive rows too (`The boys do not see the dogs.` read 1 303 inferences dearer), now an active table where no passive is read (`$ty_tact'/6) |
| 1.99.0 | 4 165 | 52.1 % | an IR shape with no rule 44, `this` 25, a phrase with a relative clause 18, a predicate with no rule 16, a noun of relation with an adjective 14, `that` 13, `no` 10, a negation 9, a generic object 6, `any` 5, an object of `some` 5. Level 1 reads 33 sentences more, and 21 of them go into Cocolog; 3 read before go now too, someone an object's constant (`He hired someone to answer his fan mail.`, `Keep someone at arm's length.`, `Spray water on someone.`). 25 have an adverb before the verb or inside its words, the clause's first adjunct (ty_adverb_inside/1, a new header row: `He promptly forgot the address.`, `We had long anticipated his cadaverous end.`, `The area is well populated.`, `His name has long been forgotten.`), written back after the object (`He forgot the address promptly.`); 2 a passive in a relative clause, after a marker of one word or more (`The difficulties in which the question is involved.`, `A man whose name is permanently stamped on our maps.`); 5 a passive with no subject, its patient someone the text does not name (`Was easily confused.`), which level 2 refuses where no agent is said (passive(unsaid), 4); and 1 a passive infinitive as a verb's object, clause(V, pass(infinitive), pos, pron(3, sg, zero), none), its patient the clause's subject at level 2 (`The washing machine needs to be serviced.` need(the(nn(washing, machine)), to(service(someone, the(nn(washing, machine)))))). The adverb is tried only in a text with an adverb's word (`$ty_padv'), where the verb's words go on past it, inside them only after a tense pattern's first word (`$ty_tfirst'/2), and not in an infinitive's words, before a command's verb nor before a past verb of a clause with no subject (`Chemically related.' stays a participle). The relative passive tried after every noun too, whose object takes a marker of no words, made `A key pressure point in the controversy was the building permit.' cost 3 972 064 inferences to read, past typology_coverage/4's 2 000 000; after a marker alone, 1 272 452. About 2 of the 33 are wrong: `Seeds precisely adapted to the area.' (a participle read as a past verb) and `Was concerned about the future.' (an adjective). Not read: an object complement, active and passive (`His landscapes were deemed the acme of beauty.`), and the other languages' passive and adverb. Cost: English's round trips 0.94 % more inferences, the others 0.12 % to 0.15 %; the first cut 3.9 %, the adverb tried at every verb read |
| 1.100.0 | 4 179 | 52.2 % | an IR shape with no rule 44, `this` 25, a phrase with a relative clause 19, a noun of relation with an adjective 16, a predicate with no rule 16, `that` 13, a negation 10, `no` 10, a generic object 6, `any` 5, an object of `some` 5. Level 1 reads 19 sentences more, each with an object's complement (`They considered colonialism immoral.`, `The monsoon left the whole place awash.`, `Set the house afire.`) or a passive's (`His landscapes were deemed the acme of beauty.`, `The siamese twins were not considered separable.`), and 13 of them go into Cocolog; 1 read before goes now too, a later reading of it the first that has a logic form (`He used his computer to make a collage of pictures superimposed on a map.`). The IR is oc(Object, Predicate) where the object stands, after a verb of the template's new ty_verb_list(L, complement, Base) row (WordNet's `Something ----s something Adjective/Noun' and the verbs of naming and choosing), the predicate an adjective's or a noun phrase's as a copula's is, never an adposition phrase; a passive's is oc(Predicate), tried only where a complement verb's participle is among the words ('$ty_ocpw'/2). After an object that is no pronoun, a complement of one word that is a noun's too is one of the common adjectives (lexicon/adj.txt: `They painted the house red.'), else the compound noun a later pass reads stays (`He kept the title to his car in the glove compartment.', `She made a copy of the designer dress.', which the first cut read as complements; `Loss of livestock left the rancher bankrupt.' keeps 1.99.0's compound). At level 2 the complement is the verb's third argument, the copula's atom of the object (past(consider(they, colonialism, immoral(colonialism)))), and a passive's its active's; one of several atoms has no form yet (complement(Pred), 1: `A manned earth satellite was considered a necessary research step.'). Read back from Cocolog, a verb's third argument whose first argument is the second is an atom, not a constant's term. About 2 of the 19 are wrong: `She keeps her time well occupied.' (`time well' a noun phrase, as 1.99.0 reads `Her time well.') and `Found it galling to have to ask permission.' (an infinitive of purpose). Not read: a complement after an adjunct first (`In England they call a fender a wing.', 8), `not' before an adjective (`found him not guilty'), `too' and `more' before one, two objects (`made her many enemies' reads as a complement), and the other languages' complement. Cost: the round trips 0.02 % to 0.04 % more inferences; the first cut's passive tried its clause a third time for oc(_) in every passive, and two gates of ty_verb_of/3 at every object, the long passives a fifth more, `The steady state theory has been abandoned in favor of the big bang theory.' past typology_coverage/4's 2 000 000 |
| 1.101.0 | 4 179 | 52.2 % | as 1.100.0: no English reading changes (the 8 000's IR, dumped before and after, is the same). Spanish, Italian, French and German read and write the passive: ty_tense_form/5 rows of pass(present) and pass(past) in each, of pass(perfect) in Spanish and French, the auxiliary and the participle (ser, essere, être, werden); the participle agrees with the subject where the row says participle(subject) (Spanish's endings are new rows, ty_participle_ending/5), and a by row is each language's agent (por, da, par, von). Italian da and German von mean from (and of) first, so a passive's adjunct whose words an agent's are too is read as the agent (ty_agent_first/3). Two faults the four found: the passive's '$ty_pword'/2, the words a participle follows, took only `participle' and no `participle(subject)', so no Romance passive was tried; and a split verb's ty_tense_participle/2 bound pass(_)'s tense to the first passive row's, so German `wurde gesehen' (pass(past)) never read, only `wird gesehen'. A negation rule of any tense fits a passive's (ty_tense_fit/2: `no fue visto'). Cost: the round trips of Spanish 0.18 %, Italian 0.12 %, French 0.07 %, German 0.28 % more inferences, English and Persian none |
| 1.102.0 | 4 206 | 52.6 % | an IR shape with no rule 45, `this` 25, a phrase with a relative clause 19, a noun of relation with an adjective 16, a predicate with no rule 16, `that` 13, a negation 10, `no` 10, a generic object 6, `any` 5, an object of `some` 5. Level 1 reads 28 sentences more, each a progressive (`Pigs were wallowing in the mud.`, `The engine is idling.`, `They were trying to find a peaceful solution.`, `Troops are building up on the Iraqi border.`), and 27 of them go into Cocolog; 2 read before as a copula with a compound noun are now the progressive they are (`The children were playing house.`, `They were playing better at the close of the season.`). The IR is a clause in a tense prog(T), its words a ty_tense_form/5 row of prog(T) (English [was, ing], 20 rows of five tenses), ing a new pattern word, the verb's form in -ing, made from its base by English's spelling rules (ty_ing_word/3: `die' dying, `make' making, `run' running, and the verbs of a new ty_verb_list kind ing_double, `begin' beginning) and read back to the base whose own form it is first (`staring' is stare's, not star's). As the passive, it is read after every other reading, with '$ty_prog' on, and only where a word in -ing stands right after a row's word before ing (`is', `was', `been', `be') or after one more word, `not' or an adverb ('$ty_ingw'/2): any word in -ing ahead, `washing' and `building' among them, cost the long sentences a third more. So a word in -ing that is an adjective too reads as the copula first (`The boy is walking.' is walking(the(boy))). At level 2 prog(T) is a tense, the Cocolog template's name round the atom (progressive, past_progressive, future_progressive, perfect_progressive, pluperfect_progressive). Not read: a progressive passive (`is being built`), a progressive in a relative clause or a question, and the other languages' progressive. Cost: English's round trips 0.26 % more inferences, the others 0.01 %; the longest sentence of the three watched, `The steady state theory has been abandoned in favor of the big bang theory.', 1 828 345 inferences, 3.6 % more, under typology_coverage/4's 2 000 000 |
| 1.103.0 | 4 209 | 52.6 % | an IR shape with no rule 45, `this` 25, a phrase with a relative clause 19, a predicate with no rule 16, a noun of relation with an adjective 14, `that` 13, a negation 10, `no` 10, a generic object 6, `any` 5, an object of `some` 5. Level 1 reads no sentence more (the 8 000's IR, dumped before and after, is the same), and 3 of its sentences go into Cocolog, each an object's complement that is a noun phrase of several atoms: the noun phrase's term is the verb's third argument, an indefinite one a(Shape) and no fact, as an infinitive's object is (`A manned earth satellite was considered a necessary research step.` is past(consider(someone, a(manned(nn(earth, satellite))), a(necessary(nn(research, step))))), the satellite's facts beside it; `They painted it a light shade of bluish green.` past(paint(they, it, a(of(light(shade), bluish(green))))); `He was rightly considered the greatest singer of his time.` past(rightly(consider(someone, he, of(greatest(singer), of(time, he)))))). A complement of one atom stays 1.100.0's atom of the object. Read back, the third argument of a verb of the complement list that is a noun phrase's term is that noun phrase after the object (`They considered him a good man.`). Level 1 also reads the progressive passive, a tense pass(prog(T)) of 12 new rows (English pass(prog(present)) [is, being, participle], pass(prog(past)) [was, being, participle], each with `not` too), at level 2 its active's progressive (`The house is being built.` is progressive(build(someone, the(house)))); no sentence of the 8 000 has one. A passive tries those rows only where a word that only they have is ahead (English `being`: '$ty_pprw'/2, '$ty_pprog'): tried in every passive, the rows cost the longest sentence watched 3.6 % more. Not yet: a complement of several atoms that is no noun phrase (`rich and famous`), and the progressive passive's future and perfect (`will be being built`). Cost: English's round trips 0.06 % more inferences, Spanish's and Italian's 0.01 %, the others' none; the longest sentence of the three watched, `The steady state theory has been abandoned in favor of the big bang theory.`, 1 831 270 inferences, 0.16 % more |
| 1.104.0 | 4 256 | 53.2 % | an IR shape with no rule 47, `this` 25, a phrase with a relative clause 19, a predicate with no rule 16, a noun of relation with an adjective 14, `that` 13, `no` 11, a negation 10, `any` 6, a generic object 6, an object of `some` 5. Level 1 reads 51 sentences more, each an adposition phrase alone, phrase(pp(Prep, NP)) (`In direct sunlight.`, `With dry eyes.`, `At the height of her career.`, `Under cover of darkness.`), and 47 of them go into Cocolog: the phrase said of something, the copula of qp(some, thing) with the phrase as its predicate (in(something, direct(sunlight)); an indefinite noun phrase in it its individual and its facts, `With dry eyes.` eye(a(pl(dry(eye)))), dry(...), with(something, a(pl(dry(eye))))). The 4 not: a coordination of noun phrases in it (`With open arms and an ingratiating smile.`, `In the twilight zone between humor and vulgarity.`), `any` and `no` (`Beyond any stretch of his understanding.`, `By no stretch of the imagination.`). Level 1 reads it after the noun phrase alone, only where the first word may begin an adposition phrase (an adposition's first word or a contraction: ty_pp_first/2), in every language (`Im großen Haus.`). Back into English it is the copula, `Something is in direct sunlight.`, which reads to the same Cocolog. Not read: `of` alone (`Of noble birth.`, 6 sentences: `of` is a possessor's, no adjunct's), and an adposition phrase before the subject (1.105.0). Cost: the round trips' inferences the same but Spanish's, 0.004 % more; the longest sentence watched 33 inferences more |
| 1.105.0 | 4 275 | 53.4 % | an IR shape with no rule 47, `this` 26, a phrase with a relative clause 19, a predicate with no rule 16, a noun of relation with an adjective 14, `that` 13, a negation 12, `no` 12, `any` 6, a generic object 6, an object of `some` 5. Level 1 reads 23 sentences more, each with an adjunct before its subject, and 19 of them go into Cocolog: a new row ty_adjunct_front(english, first), one adposition phrase or adverb first (jf(F)), a comma after it or none, the order otherwise the template's, the others at the template's place (jl(F)); the first one is the last of the clause's adjuncts, so the writer puts it at the end (`After the game the children brought friends home for supper.` is clause(bring, ..., [adv(home), pp(for, ...), pp(after, np(game, ...))]), past(after(for(home(bring(the(pl(child)), a(pl(friend)))), supper), the(game))), back `The children brought friends home for supper after the game.`). The 4 not: a negation (`Happily he was not injured.`, `Meanwhile I will not think about the problem.`), `this` and `no`. It is tried only in the clause that begins the sentence (its words are the parse's own, '$ty_words'), and not in a command or a clause with no subject: asked of every clause whose first word is an adposition's, `to` among them, an infinitive's clause read its own infinitive as its first adjunct for ever, and the round trips cost 5 % more; and before an unsaid subject 7 of the 8 000 read false (`Chemically related.`, `Before a woman gives birth her waters break.`). German keeps v2 ('$ty_jfirst'/3 has the kind, so no language asks a table more). The blank template offers ty_adjunct_front as a choice of v2 or first. One reading is wrong and not new: `In England they call life insurance life assurance.` takes `insurance` as an adjective, as the complement reader of 1.100.0 does without the adjunct. Cost: the round trips 0.01 % more inferences at most in each language (the words kept for the parse); the longest sentence watched 115 inferences more |
| 1.106.0 | 4 275 | 53.4 % | as 1.105.0: no English reading changes (the 8 000's IR and Cocolog, dumped before and after, are the same). Italian and German read and write the perfect passive. Italian's rows are essere, `stato' and the participle, each agreeing with the subject (['è', agree(stato), participle(subject)]): a new pattern word agree(Word) is a fixed word that agrees as a participle does (`Le ragazze sono state viste.`). German's are sein, the participle and `worden' ([ist, participle, worden]), the two last words at the clause's end (`Das Mädchen ist vom Jungen gesehen worden.`) or before the auxiliary where the verb is last (`das Mädchen, das gesehen worden ist`): the verb's split puts every word after the first of a verb of three at the end (ty_split_parts/4), and reading takes a last part of two words where the second is a row's last word ('$ty_rest2'/2: `worden`), held to the writer's shape (no `ist gesehen' and `worden': each reading came twice). The passive's gate word of a row with a word after its participle is that word (ty_pword_of/2: `worden`, as `ist` is no passive's word alone). At level 2 both are the active's perfect (perfect(see(the(boy), the(girl)))). Not yet: German `wollen` with a bare infinitive (no `want` row, and no infinitive without its mark), the infinitive after a noun, an adjective or an object in Spanish, Italian, French and German, Persian's subjunctive and passive. Cost: German's round trips 0.08 % more inferences, English's 0.07 % and French's 0.02 % (the split's second branch, tried where a split's last part fails), the others' none |
| 1.107.0 | 4 360 | 54.5 % | an IR shape with no rule 53, `this` 28, a phrase with a relative clause 20, a predicate with no rule 16, `that` 15, a noun of relation with an adjective 15, a negation 14, `no` 12, a generic object 7, `any` 6, an object of `some` 6. THE MEASURE FIRST (the owner's goal of 2026-11-27, every sentence into the IR): of the 3 521 unread sentences, 1 792 have one word no table has and 1 225 none; the commonest such words are words of grammar that ty_closed/2 keeps from the import (`as` 111 sentences, `there` 69, `than` 53, `could` 48, `one` 44, `more` 44, `two` 43, `many` 43, `so` 37, `can` 36, `most` 30, `too` 29, `must` 29). This step makes two groups of them rows of the hand template. The adverbs never, always, often, ever, again, already, almost, quite, rather, even, still, just, also, perhaps, too, so, then, only and yet (ty_adverb/3) read where any adverb stands: 36 sentences more (`They always raise the audio for commercials.`, `It was rather cold.`, `Then he left.`). The numbers one to twelve, twenty to fifty by tens, hundred and thousand, and the quantifiers many, much, few, most and both, are determiners (ty_article/5 rows, new values of ty_values(definiteness, _)): 65 more (`The board has seven members.` is np(member, pl, seven, []), `Most people like eggs.`); `several` stays the adjective it was, whose sentences had their Cocolog. At level 2 a number or a quantifier is an indefinite noun phrase with the word its first modifier, as `several` is (lg_active/2: member(a(pl(seven(member)))), seven(...)), and back from Cocolog the first modifier is the determiner again (lg_count_back/2). No earlier reading of the 8 000 changes. Wrong and new: `Much given to apothegmatic instruction.` (much a determiner of the noun `given`), `One last worried check of the sleeping children.`. Cost: the round trips the same in every language; the longest sentence watched 1 841 210 inferences, 0.5 % more |
| 1.108.0 | 4 389 | 54.9 % | an IR shape with no rule 55, a negation 34, `this` 31, a phrase with a relative clause 21, a predicate with no rule 16, `no` 15, `that` 15, a noun of relation with an adjective 15, a generic object 7, `any` 6, an object of `some` 6. THE MODALS (the owner's goal of 2026-11-27, every sentence into the IR; 190 unread sentences of 1.107.0 hold a modal): each a tense, modal(M) of ty_values(tense, _), words before the base as `will` is -- can, could, may, might, must, shall and should ([can, form(present, pl)], [cannot, ...], [could, not, ...]), ought ([ought, to, form(present, pl)]), each with its copula's ([must, be]) and its passive's ([can, be, participle]) -- and the short forms of not, each a row after its long form's, read and never written: doesn't, don't, didn't (ty_negation/5), isn't, aren't, wasn't, weren't, won't, wouldn't, hasn't, haven't, hadn't, can't, couldn't, mustn't, shouldn't. 60 sentences more, 50 of them a modal's (`He can hear the snap of a twig.' is clause(hear, modal(can), pos, ...), `Cluster bombs cannot be targeted precisely.' clause(target, pass(modal(can)), neg, ...), `Guards must be good blockers.' copula(modal(must), ...)) and 10 a short form's (`She doesn't like sad movies.', `I couldn't control it.'). At level 2 the conditional and each modal are tenses of their own Cocolog names (conditional(Atom), can(Atom)): 29 more into Cocolog, the rest of the new readings negations, which level 2 has no form of yet (14 at 1.107.0, 34 now). No earlier reading of the 8 000 changes. THE TENSE PATTERNS BY THEIR FIRST WORD: the reader tried each pattern of a tense for each agreement before it looked at its words, so the 40 rows of the first cut cost the longest sentence watched 36 % more and the English round trips 6 %; ty_tense_pattern_at/7 takes the patterns whose first word is the words' first, and those that begin with a form, in their order (the dump of the 8 000 the same, test/typology.pl's `modals` holding the order), and ty_tense_fit/2 tests a bound tense with memberchk/2 (a member/2 walked the 8 new tense values for each negation: Spanish 0.3 % more). Cost: the English round trips 1.6 % fewer inferences (18 707 730), Spanish 0.2 % and Italian 0.1 % fewer, the others the same; the longest sentence watched 1 559 733 inferences, 15.3 % fewer. The completeness check asks a verb's form only in the tenses a verb can lack ('$ty_tcheck'/2: not a tense whose every pattern is of any agreement and made of words and a core form or the participle, as the modals' are): the six languages' checks 18 % fewer inferences than 1.107.0's (English 9 800 075, 36 % fewer; Spanish and Italian 2 % more, the 8 new tense values). A question's moved verb read leniently (typology_repair/5) is words of a known count whose words are not known yet: a person's form made from the plural's (`I' from `see') takes as many words (ty_person_form/5), and a pattern no more items than words (ty_tense_pattern_at/7); made of no words, every verb's form was made for each negation row and each modal's pattern, and the first cut's repair of `What the boy sees?' took 740 million inferences, three times 1.107.0's 252 million -- 45 million now, of `Sees the boy the dog?' 15.6 million (1.107.0: 84 million); test/typology.pl ran in 136 s (194 s at 1.107.0) and lesson 06 in 23 s (49 s). A modal's and the conditional's general sentence (`can(append(a, b, c))') is `It can be that append holds for a, b and c.' (lg_holds_tense/3), where any tense but the future said `in the past'. Wrong and new: `Clear the water before it can be drunk.' (clear an adverb before the subject `the water before it'), `She doesn't feel first-rate today.' (`first-rate today' a noun phrase) |

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
