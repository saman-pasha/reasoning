# library(reasoning/typology): the plan

**The goal.** A language is a filled template. One grammar reads every
language into the IR and writes the IR into every language. A new language
is a new file in `templates/`, never new code.

## The rules every phase keeps

- The grammar knows levels, roles and slots. It never names a word or an
  order of a language.
- A feature the grammar needs from a language is a new SLOT: a fact shape
  in the template, filled per language, and a part of the grammar that asks
  it. A language never gets a clause of its own.
- A slot whose values are a closed set lists them all (`typology_choices/2`
  for the orders), so a template is filled by choosing, not by writing
  sentences.
- A row written by hand wins over a row a tool generated.
- Each phase is held by three things: `typology_check/2` is `[]` for every
  template; reference sentences, written out, for each new slot (the output
  is right); a round trip over a sample of IRs (the reader and the writer
  agree). Each phase adds a section to lesson 06.

## Phase 1: done (reasoning 1.19.0)

- Two levels: the clause (`s v o`) and the noun phrase (`d a n`), six orders
  each, all listed.
- Slots: `ty_order/3`, `ty_noun/6`, `ty_adjective/5`, `ty_verb/6`,
  `ty_article/5`, `ty_mark/5`, `ty_contraction/3`.
- Four templates: English, Spanish, Italian, Persian.
- `typology_read/3`, `typology_write/3`, `typology_translate/4`,
  `typology_check/2`, `typology_template/1`; `test/typology.pl`; lesson 06.

## Phase 2: the word tables from corpus/vocabulary (done, reasoning 1.20.0)

Done as planned: 36 035 Spanish rows, 25 918 Italian and 25 440 English;
`typology_check/2` is `[]` for all three with them; a sentence over the
full tables reads in under a thousand inferences; the import run again
reproduces the committed files byte for byte. Left out and counted by the
import: nouns with no gender (653 Spanish, 1 424 Italian) or no plural,
adjective meanings with a form missing, verbs with a form missing, and
entries of more than one word.

The vocabulary files hold, for Spanish and Italian, each noun with its
gender and plural, each adjective with its gender forms and plurals, and
each verb with its plural, its past and the past's plural; animacy where a
line says `is animate` or `is a person`.

1. **Two new slots**, so a form a language makes by a rule is not listed
   word by word:
   - `ty_negation(L, Tense, Number, Words, Form)`: the negative is `Words`
     before a positive form. `Form` is `same` (Spanish `no ve`, Italian
     `non vede`) or `form(T, N)`, another form of the verb (English
     `does not` before the present plural, which is the base: `does not
     see`).
   - `ty_ending(L, Feature, From, To)`: a word that ends in `From` takes
     `To` in its place; the longest `From` that fits wins. English plurals
     (`-s`, `-es`, `-ies`) and pasts (`-ed`, `-d`, `-ied`).
2. **`typology_import/1`** writes `templates/<lang>-words.pl` from
   `corpus/vocabulary/<lang>.txt`:
   - nouns: gender (stated, or `is feminine` / `is not feminine`), the
     plural, animacy (`animate` where stated, else `unknown`);
   - adjectives: each gender's singular and plural, or one form for both
     genders;
   - verbs: present and past, singular and plural (the Spanish pretérito,
     the Italian passato remoto: the vocabulary's past). The meaning is the
     English base (`sees` is `see`, by the reason library's
     `reason_base/2`).
   - English: a row for every meaning the other languages have. The
     third person singular is the vocabulary's own meaning, the base comes
     from `reason_base/2`, and the past is a stated one
     (`"saw" is the past of "sees"`) or `ty_ending/4`'s; plurals come from
     `ty_ending/4`, and irregular ones are hand rows.
   - Only complete entries are written: a noun with its gender and
     plural, an adjective with every form, a verb with all four forms.
     Entries with a space in the word or the meaning are left out. The
     tool reports each count.
   - A row the hand template already has (the same meaning and word) is
     not written again.
3. **`typology_load/1`** reads `templates/<lang>.pl`, then
   `templates/<lang>-words.pl` when it exists.
4. **Reading stays fast** with tens of thousands of rows: a noun is looked
   up by the word read, and a verb by the words read. They are not looked
   up by meaning.
5. **The Italian hand template's past becomes the passato remoto**, the
   vocabulary's past, so every Italian verb has one past. The passato
   prossimo needs the participle to agree with the subject (Phase 5).
6. **Tests**: the counts the import writes; `typology_check/2` on the full
   tables; reference translations with imported words; the import run again
   reproduces the committed files byte for byte; a time limit on loading
   and reading.

## Phase 3: forms chosen by sound (done, reasoning 1.21.0)

Done with two slots, not one: `ty_before/5` (a form chosen by how the next
word begins, patterns of letters, `ty_letters/3` classes and `end`, the
longest pattern winning) for English `a`/`an`, the Italian articles and
Spanish `el agua`; and `ty_linked/5` (a form chosen by the word's own
ending when a word of a class follows it) for the written Persian ezafe.
The reader keeps a reading only where the writer writes the very words
read. Apocope (`gran`) waits for an adjective before its noun (Phase 4).

One slot, a form chosen by how the next word begins: English `a`/`an`,
Italian `il`/`lo`/`l'`/`gli`/`i`, the written Persian ezafe (`گربه‌ی`),
Spanish and Italian apocope (`gran`). Then `cat` goes into Persian, and
Italian nouns that start with `s` and a consonant, `z` or a vowel are
right.

## Phase 4: more levels (in part done, reasoning 1.22.0 to 1.32.0)

Done:

1. **The copula clause** (`s c p`, six orders): `copula(T, P, S, Pred)`,
   the predicate an adjective that agrees with the subject, a noun phrase
   or an adposition phrase. `ty_copula/6` chooses the copula by the
   predicate's kind (Spanish `es` for a quality, `está` for a place); a
   copula of no words is dropped, though no template drops one yet.
2. **The adposition phrase** (`p x`, two orders: a preposition or a
   postposition) as an adjunct of the clause, where `ty_adjunct/2` puts
   the adjuncts (start, end, before or after a part), with its
   contractions (`del`, `al`, `nel`, `nell'acqua`, `sull'albero`).
3. **Adverbs** as adjuncts (`ty_adverb/3`).
6. **A word with several meanings in one place** (not in the first plan;
   the owner's, 2026-11-22). Spanish `a` became both the object's mark and
   `to`, and `ve al perro` read as `sees, to the dog` too. Two things now
   choose the meaning, the first that decides:
   - the words around the word, a lookback and a lookahead:
     `ty_sense(L, Word, Sense, Back, Ahead)`, its patterns words, classes
     (`class(verb)`, `class(noun, animate)`), `opt(Item)` and any word;
   - the topics of the context: `templates/topics.pl`, one table of
     `ty_topic(Meaning, Topic)` for every language, a meaning its own
     topic too; the context is the topics given (the sentences before:
     `typology_read/4`, `typology_read_text/3`,
     `typology_translate_text/4`) and the other words of the sentence with
     one meaning in their class. `hoja` beside `libro` is a sheet, beside
     `árbol` a leaf, after a sentence about a knife a blade.
   The writer writes the first way whose words, read in their context,
   give the IR back: a blade beside a book is `cuchilla`, not `hoja`.
4. **Questions** (1.23.0): `question(Clause)`, with no question word (yes
   or no) or one, `wh(M)`, where a subject, an object, the one adjunct or
   a copula's predicate stands. `ty_question(L, Kind, Level, Rule)` says
   how the order changes, a choice among five: unchanged, a particle at
   the start or the end (Persian `آیا`), the verb before the subject
   (front(all): `¿Ve el niño al perro?`) or its first word only
   (front(first), with `ty_question_form/5`'s `does`: `Does the boy see the
   dog?`, `Is the dog not big?`). `ty_wh/2` puts a question word at the
   front (the rule then on the rest, unless it is the subject: `Who sees
   the dog?`) or in place (Persian); `ty_wh_word/3` and
   `ty_question_mark/3` (`¿ ?`, `؟`) give the words and the marks. A
   question word stands only where the kind put it, so a statement has
   none.
   **Which noun is the subject** (1.24.0, the owner's): of several
   readings of the same meanings the reader keeps the one whose order is
   closest to the statement's (a question's cost: the pairs of parts it
   puts the other way round), so `Chi vede il ragazzo?` is who sees the
   boy; and a role is what its verb takes (`templates/roles.pl`,
   `ty_role_animacy/3`: the subject of `see` is animate), so `Cosa vede il
   ragazzo?` is what the boy sees, and `El libro ve al perro.` is not
   read. The writer writes what a reader would read back first: whom the
   girl saw is `La ragazza chi vide?` (`ty_wh(italian, after(s))`).
7. **Repair** (1.24.0, the owner's): `typology_repair/5` reads a sentence
   the template does not allow. Each check of the template -- an order, an
   agreement, a mark, a copula's kind, a form the next word chooses, a
   question's order, form or marks, the mood -- has a second road, taken
   only where the first fails, that notes a fault; one fault is allowed,
   then two, then three. The fewest faults win, weighed (a clause's order
   and a mood count two), then the question's cost, then the most words
   kept; the writer writes the IR as the template has it. `Los perro ven
   al gato.` is `Los perros ven al gato.` (one fault, the noun), `What the
   boy sees?` is `What does the boy see?`, `El niño ve qué.` is `¿Qué ve
   el niño?`. A word no table has is not repaired.
5. **Relative clauses** (1.25.0): `rel(NP, Clause)` where a noun phrase
   stands -- a subject, an object, an adposition's noun phrase, a
   copula's predicate. It is a level of its own, `rel`: the head (h, the
   noun phrase between its role's marks), the marker (m, `ty_relative/4`)
   and the clause (c), six orders like the others. The clause is a verb
   clause or a copula clause in the language's own order, with `gap`
   where the head stands in it (its subject or its object), and the gap
   is the head to every check: the verb agrees with it (`Las niñas
   pequeñas que vieron a un gato`), its role asks its animacy (`The book
   that sees the dog sleeps.` is not read), a predicate adjective agrees
   with it (`la niña que es pequeña`). The marker is the first row that
   fits the gap's role and the head's features: English `that`, and
   `who`, `which` and none (the object's gap: `the dog the boy sees`)
   read; Spanish `que`, Italian `che`, Persian `که`, after which the
   head's last word takes `ی` (`ty_linked(persian, n, r, ...)`: `سگی که`,
   `خانه‌ای که`, `دخترهای کوچکی که`) and a mark stays with the head
   (`سگ سیاهی را که می‌خوابد`). A clause nests in a clause, and an
   adjunct after a relative clause is read as the main clause's and as
   the relative clause's. A template whose clause stands before its head
   (`c m h`, `c h`) reads too: no relative clause starts again where one
   is open that has read no word yet, which in such an order would start
   one there for ever.
8. **A verb's complement** (1.26.0): `ty_complement(L, Verb, Words)` makes
   the verb's object an adposition phrase with the adposition Words, in
   the pp level's order and with no role marks -- English `think about`,
   `look at`, `wait for`, `listen to`, `depend on`, `dream of`; Spanish
   `pensar en`, `depender de`, `soñar con`; Italian `pensare a`, `dipendere
   da`; Persian `به ... فکر کردن`, `به ... نگاه کردن` (two verbs of two
   words, new). The IR keeps the plain object, so `The boy looks at the
   dog.` is `El niño mira al perro.` and back. `ty_complement_wh(L, Rule)`,
   a new choice, says whether the adposition moves with its question word
   (`¿En qué piensa el niño?`, `A cosa pensa il ragazzo?`) or stays (`What
   does the boy think about?`); where it stays, a relative clause's gap
   leaves it behind too (`The girl that the boy thinks about sleeps.`).
   With no object, the verb's own adposition is its complement and never
   an adjunct (`El niño piensa en la casa.` is about the house). A repair
   puts a missing complement in (`The boy looks the dog.`) and moves a
   stranded one back (`About what does the boy think?`).
9. **The place of the negation** (1.27.0): `ty_negation_place(L, Words,
   Place)` puts a negative verb clause's negation as a part of its order,
   `n(Words)`, at Place -- start, end, before(X) or after(X), X one of s,
   v, o -- and the verb takes its positive form; several rows are a
   negation of several parts. One row at the end is German `nicht` (`The
   boy sees the dog not.`, `Sees the boy the dog not?`), two around the
   verb French `ne ... pas` (`The boy ne sees pas the dog.`), and a
   question that moves the verb's first word puts them around that word
   (`Ne sees pas the boy the dog?`, as `Ne voit-il pas le chien ?`). The
   four templates have no row: their negation stays a part of the verb's
   form, and they read and write as before. The test makes the two
   languages of the English rows; a repair moves a negation to its place.
10. **Asking and answering** (1.28.0). Several question words in one
   question: the subject's moves, else the object's, else the adjunct's,
   and the others stay in place (`Who sees what?`, `¿Quién ve a quién?`,
   `چه کسی چه چیزی می‌بیند؟`); `What does who see?` is refused. A question
   word inside a noun phrase is its article, `which`, a third
   definiteness (np(dog, sg, which, []), `ty_article(L, which, ...)`:
   `which`, `qué`, `quale`/`quali`, `کدام`), definite to the marks
   (`¿A qué perro ve el niño?`, `کدام سگ را`), and an adposition phrase
   of one moves whole (`In which house does the dog sleep?`). The answer
   to a yes or no question is `answer(Polarity, Asked)`, or
   `answer(Polarity, Asked, Clause)` with its clause (`No, el niño no ve
   al perro.`, the clause of the answer's polarity); `ty_answer/3` gives
   the words, and `ty_answer_system/2` how they are chosen -- polarity
   (yes for a positive answer; Persian contradicts a negative question
   with `چرا`, as French `si`, German `doch`) or agreement (yes where the
   answer agrees with the question, as Japanese `hai`). `typology_answer/4`
   writes the short answer to a question.

11. **The topics the vocabularies give** (1.29.0). `typology_import(topics)`
   writes `templates/topics-words.pl` from the class lines of both
   vocabularies (`"sábado" is a time.`), which `typology_load/1` reads
   after the hand table: 62 rows, a class's topics by
   `ty_class_topics/2` (a month is about the month and the time, a
   street's word about the street and a place; person, group and name
   say how a word is used, and give none). A word that is also a name
   gives nothing (`mosca`, Moscow, whose noun is a fly; every city,
   country, region and continent of the vocabularies is a name now); a
   word of several noun meanings gives the first that another word of its
   class gives too (`volta`, a time and a vault, the time `vez` gives),
   and none where no other word does (`metro`, a metre and a subway).
   So `madrugada` after an hour is the morning, alone the dawn, and
   Italian `via` after a square the road. A meaning is an English word,
   and one word is several things: `march` (the month) is about time in
   `marcha` too.

12. **The gap in an adposition phrase, the pronoun, the clause after the
   verb** (1.30.0). A relative clause's gap may be the noun phrase of an
   adposition phrase, an adjunct (`clause(sleep, present, pos, np(dog,
   ...), none, [pp(in, gap)])`) or a verb's complement, and
   `ty_gap(L, Place, Rule)` says how it is written: the adposition stays
   (English `the house that the dog sleeps in`, written; `in which` read),
   moves into the marker with a relative pronoun of the head's features
   (`ty_relative_pronoun/3`: Spanish `la casa en la que el perro duerme`,
   `las casas en las que`; Italian `la casa in cui il cane dorme`, `la
   ragazza a cui il ragazzo pensa`), or stays with a pronoun
   (`ty_resumptive/3`: Persian `خانه‌ای که سگ در آن می‌خوابد`, `دختری که
   پسر به او فکر می‌کند`); an object's gap is no word, or read as a
   pronoun with its mark (`سگی که پسر آن را می‌بیند`). Inside the clause
   the gap is `gap(Head, Features, r(Place, Rule))`, so each part writes
   what its rule says, and the marker reads the moved adposition before
   the clause. `ty_relative_after(L, Part)` puts the relative clause of
   an object or a copula's predicate at its clause's end, the head
   staying in place (Persian `دختر سگ سیاهی را می‌بیند که می‌خوابد`, `سگ
   حیوانی است که می‌خوابد`, `پسر به دختری فکر می‌کند که می‌خوابد`), and
   the clause in place is read too; `ty_relative_bare(persian, indef)`
   drops `یک` before it, read with `یک` too, so a Persian head with `ی`
   reads definite and indefinite. Reading, a gap is tried only where its
   words are among the words left: the round trips cost 1 to 3 % more
   inferences in Spanish, Italian and Persian and 11 % more in English
   (whose object's marker of no words tries a relative clause after each
   noun phrase), the clock the same in all four.

13. **More of the gap, and the person** (1.31.0). An adjunct's gap stands
   beside other adjuncts (`la casa en la que el perro duerme hoy`): the
   clause's adjuncts are `gapped(Prep, Gap, Js)` inside the clause, the
   IR's list with `pp(Prep, gap)` in it once, and a gap that writes
   nothing stands first, so a sentence is one reading. A subject's
   relative clause after the verb is read: `ty_relative_after(L, Part,
   Rank)` takes a rank, `first` (written, the clause in place read too)
   or `second` (the clause in place written, this one read), and Persian
   reads `سگی می‌خوابد که پسر می‌بیند` (rank second). Animacy has a value
   `person`, a kind of animate to every row and role that asks animate
   (Spanish `a`, the roles of `see`), and a row may ask it: Persian `او`
   is a person's pronoun, `آن` an animal's or a thing's (`سگی که پسر به آن
   فکر می‌کند`, `دختری که پسر به او فکر می‌کند`). The import writes
   `person` for `"niño" is a person.` (921 Spanish rows, 833 Italian, 826
   English), and the hand templates' people are persons. The round trips
   cost 0.5 to 2 % more inferences than 1.30.0.

14. **The possessor, and `whose`** (1.32.0). `of(Possessor, NP)` stands
   where a noun phrase stands, a level of its own, `poss` (h p g, six
   orders): the possessed, the possessive word (`ty_possessive(L, Words,
   Article)`) and the possessor. English `the boy's dog` (g p h, the
   possessor's last word linked to the head, `'s` or `'` after s, and the
   head bare: Article `drop`, `Next` `bare(N)` in the noun phrase);
   Spanish `el perro del niño`, Italian `il cane del ragazzo` (`di` with
   seven contractions); Persian `سگ پسر`, `خانه‌ی سیاه پسرها` (the ezafe as
   before an adjective, `ty_linked(persian, n, g, ...)`). Its features are
   the possessed's: the verb agrees with it, and a mark asks it (`al
   perro del niño`, `سگ پسر را`). A relative clause's gap may be the
   possessor of its subject or object, `ty_gap(L, poss, Rule)`: moves, the
   possessed going into the marker with a pronoun that agrees with it
   (`ty_relative_possessive/3`: `the boy whose dog sleeps`, `the girl whose
   house the dog sees`, `el niño cuyo perro duerme`, `a cuyos perros`,
   `il ragazzo il cui cane dorme`, `i cui cani`), or resumptive, the
   possessed staying with a clitic for the head's number (Persian `سگش`,
   `خانه‌اش`, `سگ‌هایش`, `سگشان`, `clitic(N)` links). Reading, a possessor
   is tried only in a sentence with a possessive word (`'$ty_poss'`, set
   where the parse starts) and a possessor's gap only with a possessive
   relative word or a clitic rule (`'$ty_whose'`). The round trips cost 3
   to 7 % more inferences in English, Spanish and Italian, the clock the
   same; Persian 32 % more and its time with it, because its ezafe is not
   written after a consonant and any two nouns side by side may be a
   possessor (`پسر سگ می‌بیند` is the dog's boy who sees).

Not yet:

3. A German or a French template:
   the place of the negation is there for them, and German's `nicht`
   before a predicate (`ist nicht groß`) and its verb second are not.
4. Every question word at the front (Bulgarian, Russian), a slot of its
   own; an answer that repeats the verb (Portuguese `Vejo.`, Irish) and
   English `Yes, he does.`, which wait for pronouns.
5. A possessor's possessor (`the boy's dog's house`), a possessor with a
   relative clause, a possessor's gap in an adposition phrase (`the boy in
   whose house the dog sleeps`), and a possessive pronoun (`his dog`,
   Phase 5's pronouns).
6. The topics the class lines do not give: the hand table's thirty rows,
   and every other meaning, are Phase 8's (a model fills a slot in live
   mode, with the reference sentences as its check). A meaning of its
   own for each sense of an English word (`march`, the month and the
   walk) waits for the bridge to translate.pl (Phase 6).

## Phase 5: more features

Persons 1 and 2 and the pronouns, with a subject that may be dropped; more
tenses and aspects (the future; the perfect, and the passato prossimo with
its participle agreement); the polite and the plural `you`.

## Phase 6: the bridge to translate.pl

A mapping between the typology IR and `translate.pl`'s `ir(s(...))` for the
shapes both have. A shared set of sentences then holds the two translators
to the same outputs.

## Phase 7: languages far from these

- Persian complete: the ezafe, and `را` with a specific indefinite object.
- Japanese: a script with no spaces (a reader that splits by the lexicon),
  and particles as marks.
- One verb-first or agglutinating language (Arabic or Turkish).

Each one is a new file. The code changes only by the slots of phases 3 to 5.

## Phase 8: filling a template

- `typology_template/1`'s blank template filled by choosing.
- A model fills a slot in live mode, with the round trip and the
  reference sentences as its check.
- Controlled English rows as an alternative to facts.
