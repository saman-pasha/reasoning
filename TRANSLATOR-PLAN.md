# The translator: English and Cocolog through one IR

Written 2026-11-24, at reasoning 1.61.0, from the owner's plan
("Cocolog ↔ English Translator") and the review of it.

## The two goals

1. **The first goal** (STATUS.md): English as one complete template, so
   that the IR of any English text can be got from it.
2. **The second goal** (this file): a translator between English and
   Cocolog, in the two directions, through a shared IR. Later, other
   natural languages and other programming languages are added as
   templates, never as new code.

The two goals are one line of work. Each item of the first goal that the
translator needs comes first, and each such item also adds sentences to
the first goal's measure.

## The decisions (2026-11-24)

1. **Two levels of IR.**
   - Level 1 is the typology IR (`typology.pl`, `templates/`). It keeps
     the meaning of a sentence: its roles, its tense, its aspect, its
     definiteness and its words of meaning. All English goes into it, and
     it is the same for the six languages.
   - Level 2 is a logic form. Rules make it from level 1, and the rules
     are the same for every language, because level 1 is. So a Spanish
     sentence gets its Cocolog through the same rules as an English one.
   - The Cocolog template connects to level 2 only. A level-1 IR that has
     no level-2 form gets a diagnostic, not a guess.
2. **reason.pl stays as it is** until level 2 reads all of its
   sentences. This is the rule that STATUS.md gives for `translate.pl`:
   a use moves only when the new reader reads as much as the old one.
3. **The order of the work:** names, then the determiners and the
   quantifiers, then the bare noun, then the `if` clause, then level 2
   and the Cocolog template.

## Level 2: the logic form

One shape for each construct:

    utterance(Intent, Content)      Intent assertion, question or
                                    instruction
    fact(Atom)                      a statement with no condition
    rule(Atom, Body)                a conclusion and its conditions
    query(Body)                     a question
    pred(Name, Args)                an atom of the logic: Name an atom,
                                    Args a list of terms
    and(Bodies), or(Bodies), not(Body)
    compare(Op, Term, Term)         Op one of < =< > >= =:= =\=
    const(Name)                     a constant: a name, a thing; since
                                    1.76.0 a term where the noun phrase
                                    has a determiner: the(dog),
                                    the(pl(rebel)), a(dog), of(dog, john);
                                    since 1.77.0 an individual keeps its
                                    adjectives and number, a(big(dog)),
                                    a(pl(book)), a(of(book, a(pl(stamp))))
    var(N)                          a variable, numbered by its first
                                    use from 1; no Prolog variable
    num(N), str(Text), list(Terms), fun(Name, Args)
    at(Tense, Atom)                 an atom in a tense other than the
                                    present (since 1.70.0): past,
                                    future, perfect, pluperfect,
                                    imperfect; Cocolog past(Atom)
    modified(Adjunct, Atom)         an atom with an adjunct (since
                                    1.71.0): pp(Prep, Term) or
                                    adv(Meaning); Cocolog in(Atom,
                                    Term), quickly(Atom), inside the
                                    tense; when(Atom2), a when clause's
                                    atom, outside both tenses (since
                                    1.79.0): Cocolog when(Atom, Atom2)

A noun phrase alone (since 1.81.0, level 1's `phrase(NP)`) is the facts
its noun and its adjectives say of its term: `A heavy coat.` is
`fact(pred(coat, [const(a(heavy(coat)))]))` and
`fact(pred(heavy, [const(a(heavy(coat)))]))`. A command (since 1.82.0) is
its atoms in the tense imperative, its subject you: `Mince the garlic.` is
`fact(at(imperative, pred(mince, [const(you), const(the(garlic))])))`.
A noun phrase with an adposition phrase after its noun (since 1.83.0,
level 1's `np_pp(NP, pp(Prep, X))`) is one constant, the head's term with
the adposition's inside it, as `of/2` is a possessor's: `The man with the
hat sleeps.` is `fact(pred(sleep, [const(the(with(man, the(hat))))]))`.
A clause with no subject (since 1.86.0, level 1's subject `pron(3, sg,
zero)`) says its atoms of the constant someone: `Took the joke well.` is
`fact(at(past, modified(adv(well), pred(take, [const(someone),
const(the(joke))]))))`. A noun before a noun (since 1.87.0, level 1's
item `n(M)` among a noun phrase's adjectives) is the predicate
`nn(Modifier, Thing)`, and inside a term `nn(M, X)`: `A treasure
hunter.` is `fact(pred(hunter, [T]))` and `fact(pred(nn, [const(treasure),
T]))`, T the constant `a(nn(treasure, hunter))`. An adjective with an
adposition phrase (since 1.88.0, level 1's item `ap(A, pp(Prep, NP))`
among a copula's predicate's adjectives) is the adjective's atom inside
the phrase, as a clause's adjunct is: `The dog is big in the house.` is
`fact(modified(pp(in, const(the(house))), pred(big,
[const(the(dog))])))`. An adverb that grades an adjective (since 1.90.0,
level 1's item `adv(M, A)`) is the adjective's atom inside the adverb:
`She was incurably optimistic.` is `fact(at(past, modified(adv(incurably),
pred(optimistic, [const(she)]))))`. An adjective with an adposition phrase
in a noun phrase (since 1.91.0, level 1's item `ap(A, pp(Prep, NP))` among
a noun phrase's adjectives) is in the noun phrase's term, A(T, Prep, X),
and said of the term as a copula's phrase is: `A calyx adnate to the
ovary.` is the individual `a(adnate(calyx, to, the(ovary)))` and
`fact(modified(pp(to, const(the(ovary))), pred(adnate, [const(a(...))])))`.

A variable's name in a source is a source detail and is to be kept apart
(`read_term/3`'s `variable_names`; not yet: the reader numbers a variable
by its first use, below). Two IRs are the same when they are
variants (`=@=/2`).

What level 2 makes from level 1, for the first milestone:

| English | level 1 | level 2 |
|---|---|---|
| Socrates is human. | `copula(present, pos, name('Socrates'), adj([human]))` | `fact(pred(human, [const(socrates)]))` |
| Every human is mortal. | a subject of `every` | `rule(pred(mortal, [var(1)]), pred(human, [var(1)]))` |
| Who is human? | `question(copula(present, pos, wh(who), adj([human])))` | `query(pred(human, [var(1)]))` |
| Is Socrates human? | `question(copula(present, pos, name('Socrates'), adj([human])))` | `query(pred(human, [const(socrates)]))` |
| Something is mortal if it is human. | a clause with `if` | `rule(pred(mortal, [var(1)]), pred(human, [var(1)]))` |
| A person is happy if they are healthy and safe. | a clause with `if`, `they` referring to `a person` | `rule(pred(happy, [var(1)]), and([pred(person, [var(1)]), pred(healthy, [var(1)]), pred(safe, [var(1)])]))` |
| A person likes music. | an indefinite subject, a bare object | two readings, a rule (in general) and a fact (one person), in that order |

**Not in level 2 at first, with a diagnostic:** a tense other than the
present (since 1.70.0 at(Tense, Atom), but the conditional), an adjunct
(since 1.71.0 modified(Adjunct, Atom), but one whose noun phrase is no
constant), a pronoun (since 1.72.0: in a text the noun phrase it refers
to, alone a constant of its own, its word), a possessor (since 1.73.0:
one constant with its possessed, of(dog, john)), an indefinite object
(since 1.74.0: an individual in a statement, a variable in a question
or a condition, but none in a rule's conclusion), a plural definite noun
phrase (since 1.75.0: a constant of the group, the(pl(rebel))), a negation, a question with `where`, `when` or `why`, an
instruction about code ("Define a fact stating that ..."), a relative
clause in a condition. Each comes later as its own item.

**Ordered readings, no confidence.** The grammar gives its readings in a
fixed order. A confidence is added only where something gives one (the
tagger, a model).

## The Cocolog template

`templates/cocolog.pl`, facts as every template is:

- **The predicate lexicon.** One fact for each predicate: its word class
  and its argument roles (`human/1` an adjective, `man/1` a noun,
  `likes/2` a verb with an object). Where no fact is given, the name is
  looked up in the English word tables. A predicate that is no word
  (`append/3`) gets a general sentence: "append holds for X, Y and Z".
- **The reserved names.** A predicate made from a word can be a Cocolog
  builtin: `Seven is a number.` gives `number(seven)`, and Cocolog
  refuses a clause of an ISO builtin in a program file; a clause of a
  builtin that is not ISO takes it over. The template keeps a list of
  the reserved names and gives each a name of its own (`is_number/1`),
  or the writer refuses it with a diagnostic.
- **The reader** is Cocolog's own reading of a term, and no new
  tokenizer: the text cut into clauses at a full stop before layout,
  outside a quoted atom or string and a comment, each clause read by
  `term_string/2` (logic.pl's `cocolog_read/2`). Not yet done (the 2026-11
  review's Priority 4): `read_term/3` with `variable_names`,
  `term_position` and `subterm_positions`, so that a variable keeps its
  source name and a diagnostic names the clause's line. Until then a
  variable is numbered by its first use and a refusal names the clause's
  text.
- **The writer** makes a term from level 2 and writes it with
  `portray_clause/1`, which puts the operators and the brackets.

## The steps

Each step is one version or more, with its tests, its lesson section and
its benchmark, as every typology version has.

1. **Names** (level 1, done: 1.62.0): `name(Meaning)` where a noun phrase
   stands; a word written with a capital that no table has, and the names
   of `lexicon/proper.txt`, `lexicon/place.txt` and Apertium's
   dictionaries, the meaning the English name. `Socrates is human.` and
   `Is Socrates human?` read.
2. **The determiners and the quantifiers** (level 1, done: 1.63.0):
   `every`, `each`, `all`, `some`, `no`, `any`, `this`, `these`, and the
   pronouns `something`, `someone`, `everything`, `everyone`, `nothing`.
   `Every human is mortal.` reads as np(human, sg, every, []).
3. **The bare noun** (level 1, done: 1.64.0): a mass noun or a plural
   with no article (`likes music`, `Dogs sleep.`). The plural read so
   already (indef); the singular is np(music, sg, mass, []).
4. **The `if` clause** (level 1, done: 1.65.0): a condition before or
   after its clause, `sub(if, Main, Clause)`, with `when` and `because`.
   A pronoun in it that refers to a noun phrase of its clause is level
   2's to bind. The seven sentences of the milestone all read at level 1.
5. **Level 2** (done: 1.66.0, `logic.pl`): the logic form from level 1,
   for the table above, with its diagnostics (`logic_why/2`); the seven
   sentences of the milestone give the table's forms (test/logic.pl,
   lesson 07). A joined subject or object is a clause of each item.
6. **The Cocolog template** (done: 1.67.0, `templates/cocolog.pl`): the
   writer (`cocolog_write/2`), the reader (`cocolog_read/2`), the reserved
   names (a prefix, `is_sleep/1`, where predicate_property/2 says the
   system defines the name), and the round trip Cocolog to level 2 to
   Cocolog. The reader reads each clause with term_string/2 and keeps no
   source place yet. The predicate lexicon is step 7's: English needs it,
   Cocolog does not.
7. **Cocolog to English** (done: 1.68.0, `logic_write/3`): level 2 to
   level 1 to English (`typology_write/3`), each sentence kept only where
   it reads back to its items, else a general sentence; and the two
   round trips. The predicate lexicon is the template's rows
   (`lg_code_class/3`, none yet) over the language's tables
   (`typology_meaning/3`) and an order of the classes from WordNet's
   lists in `lexicon/` (a common adjective first; a verb that takes no
   object before a noun for a person or an animal).
8. **The second measure** (done: 1.69.0, `lexicon/logic.txt`,
   `tools/logic/measure.pl`): 104 sentences with their Cocolog (349 since
   1.98.0), written
   by hand, counted as the first measure is (STATUS.md keeps the counts).
   At 1.69.0, 86 give their Cocolog and 94 Cocolog texts come back as
   English that reads to them; the misses are the next work: a relative
   clause in a rule (`Every man who is wise is happy.`), an object that is
   no constant (`Cats eat fish.`, `What does John like?`), a pronoun of a
   clause before its main clause (`If a person is a student, they
   study.`), `which`, an adposition phrase (`John lives in Paris.`), a
   verb of three, a comparative, a possessor, and a name no row has that
   the reader takes for no name (`Tweety`).

## The first milestone

The milestone is complete when:

1. The seven English sentences above read into level 1 and level 2.
2. Cocolog's facts, rules and queries of the same meanings read into
   level 2.
3. The writer makes valid Cocolog from level 2, and Cocolog reads it
   back into the same level 2 (`=@=/2`).
4. The writer explains each level 2 in English.
5. The two round trips keep the logic form.
6. An input with no level-2 form gets a diagnostic.
7. The templates load through `typology_load/1`.

**Since 1.68.0 the milestone is complete**: test/logic.pl holds each of
the seven points (the levels, Cocolog's own clauses, the writer and its
read-back, the English, the two round trips, the diagnostics, the
templates through `typology_load/1` and `templates/cocolog.pl`).

## What was there before (2026-11-24)

Of the seven sentences, `reason.pl` (`reason_text/2`, controlled
English) read four: `Socrates is human.`, `Every human is mortal.`,
`Who is human?` and `Is Socrates human?`. Typology read one, `Who is
human?`. It reads `The man is human.`, `Is the man human?` and `The man
is happy and safe.`, and stops at a name, at `every` and `something`, at
a clause with `if` and at a bare noun object (`music`).
