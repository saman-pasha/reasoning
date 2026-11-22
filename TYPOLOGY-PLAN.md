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

## Phase 4: more levels (in part done, reasoning 1.22.0 and 1.23.0)

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

Not yet:

3. The place of the negation as a part of the order, not only a form.
   The adposition phrase as a verb's complement (it is an adjunct now).
4. Questions of more than one question word, a question word inside a
   noun phrase (`which dog`, `whose`), and the yes or no answer.
5. Relative clauses: the marker, its place, and the gap.
6. The topic table is written by hand (some thirty rows). The
   vocabularies' class lines (`is a time`, `is a country`, `is a
   measure`, `is an institution`) can fill a part of it; the rest is
   Phase 8's (a model fills a slot in live mode, with the reference
   sentences as its check).

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
