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
    const(Name)                     a constant: a name, a thing
    var(N)                          a variable, numbered by its first
                                    use from 1; no Prolog variable
    num(N), str(Text), list(Terms), fun(Name, Args)

A variable's name in a source is a source detail and is kept apart
(`read_term/3`'s `variable_names`). Two IRs are the same when they are
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
present, a negation, a question with `where`, `when` or `why`, an
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
- **The reader** is Cocolog's own: `read_term/3` with `variable_names`,
  `term_position` and `subterm_positions`, so the source places come with
  each clause. No new tokenizer.
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
6. **The Cocolog template**: the reader, the writer, the predicate
   lexicon and the reserved names; the round trip Cocolog to level 2 to
   Cocolog.
7. **Cocolog to English**: level 2 to level 1 to English
   (`typology_write/3`), and the round trip English to Cocolog to
   English.
8. **The second measure**: a set of sentences with their Cocolog,
   counted as the first measure is.

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

## What was there before (2026-11-24)

Of the seven sentences, `reason.pl` (`reason_text/2`, controlled
English) read four: `Socrates is human.`, `Every human is mortal.`,
`Who is human?` and `Is Socrates human?`. Typology read one, `Who is
human?`. It reads `The man is human.`, `Is the man human?` and `The man
is happy and safe.`, and stops at a name, at `every` and `something`, at
a clause with `if` and at a bare noun object (`music`).
