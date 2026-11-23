%% cocolog -- library(reasoning/typology): a language as a filled template,
%% and one grammar that reads every language into the IR and writes the IR
%% into every language.
%%
%%     :- use_module(library(reasoning/typology)).
%%
%%     ?- typology_load(spanish), typology_load(persian),
%%        typology_read(spanish, 'El niño ve al perro negro.', IR),
%%        typology_write(persian, IR, P).
%%     IR = clause(see, present, pos, np(boy, sg, def, []),
%%                 np(dog, sg, def, [black])),
%%     P = 'پسر سگ سیاه را می‌بیند.'
%%
%% A LANGUAGE IS A CHOICE AMONG ALL THE ORDERS, NOT A LIST OF SENTENCES. The
%% grammar here knows ROLES and LEVELS and no word and no order of any
%% language. A level is a head and the parts around it, and its parts can
%% stand in a fixed number of orders, all of them listed:
%%
%%     clause   s the subject, v the verb, o the object     6 orders
%%     np       d the article, a the adjectives, n the noun  6 orders
%%     copula   s the subject, c the copula, p the predicate  6 orders
%%     pp       p the adposition, x its noun phrase          2 orders
%%     rel      h the head, m the marker, c the clause       6 orders
%%              (a noun phrase with a relative clause)
%%
%% A language keeps the orders it uses (typology_choices/2 lists all of
%% them; templates/template.pl, which typology_template/1 writes, is the
%% blank template: every slot and every choice), and the reader takes any order the language keeps; the writer
%% writes the first. Two levels, not one flat order of every word: an
%% adjective belongs to its noun and not to the verb, two nouns are told
%% apart by their ROLE and not by their class, and the count of choices
%% ADDS across levels (6 + 6) where one flat order would multiply them.
%%
%% THE TEMPLATE. A language file is facts, the language's name first in
%% each, one file a language in templates/ beside this file
%% (templates/english.pl, templates/persian.pl, ...; typology_load/1 reads
%% one):
%%
%%     ty_order(L, Level, Order)       an order of a level's parts the
%%                                     language uses; the first is written
%%     ty_noun(L, Meaning, Gender, Animacy, Singular, Plural)
%%                                     Gender: the language's own (m, f,
%%                                     ...), or none; Animacy: person,
%%                                     animate, inanimate, or unknown (an
%%                                     imported noun the vocabulary says
%%                                     nothing of: no mark asks for it); a
%%                                     person is animate to every row and
%%                                     role that asks animate (Spanish `a'),
%%                                     and a row may ask person (Persian
%%                                     `او')
%%     ty_noun_class(L, Class, Endings) a class of nouns and its plural:
%%                                     Endings are From-To, the longest
%%                                     From that ends the singular giving
%%                                     the plural (English regular [''-s,
%%                                     y-ies, ay-ays, ...]); the first class
%%                                     is the one the import puts a noun in
%%     ty_noun_in(L, Meaning, Gender, Animacy, Singular, Class)
%%                                     a noun of a class, its plural the
%%                                     class's (typology_load/1 makes its
%%                                     ty_noun/6 row); an irregular noun is
%%                                     a ty_noun/6 fact of its own
%%     ty_closed(L, Words)             the words of grammar the import never
%%                                     takes as a noun, a verb, an adjective
%%                                     or an adverb (English `and', `this')
%%     ty_adjective(L, Meaning, Gender, Number, Word)
%%                                     a form for a gender and a number;
%%                                     any for a form that does not change
%%     ty_adjective_before(L, Meaning) the adjective stands before the noun
%%                                     where the others stand after it
%%                                     (French `le petit chien noir')
%%     ty_verb(L, Meaning, Tense, Number, Polarity, Words)
%%                                     Tense present, past, future or
%%                                     perfect (every verb has the first
%%                                     two), Number the subject's person and
%%                                     number (sg and pl the third person;
%%                                     sg(1), sg(2), pl(1), pl(2) the first
%%                                     and second),
%%                                     Polarity pos or neg; Words a LIST, so
%%                                     `does not see', `no ve' and
%%                                     `نمی‌بیند' are all forms
%%     ty_conjugation(L, Class, Parts) a class of verbs and its forms: each
%%                                     part (present(sg), past(sg), ...,
%%                                     participle) and its rule: base, the
%%                                     endings From-To on the base, or
%%                                     another part (English regular
%%                                     past(sg)-[''-ed, e-ed, y-ied, ...])
%%     ty_class_when(L, Kind, Class, Pattern)
%%                                     the import puts an item of Kind (noun
%%                                     or verb) whose word fits Pattern, a
%%                                     list of ty_letters/3 classes and
%%                                     star(C), in Class (English verb
%%                                     double: [star(consonant), vowel,
%%                                     doubling], `stop')
%%     ty_verb_in(L, Meaning, Base, Class)
%%                                     a verb of a class (typology_load/1
%%                                     makes its ty_verb/6 and its
%%                                     ty_participle/3 rows)
%%     ty_irregular_verb(L, Meaning, Base, Class, Parts)
%%                                     an irregular verb, one fact: the
%%                                     parts its class does not make
%%                                     (English see [past(sg)-saw,
%%                                     participle-seen])
%%     ty_tense_form(L, Tense, Number, Polarity, Pattern)
%%                                     a verb in Tense with no row of its
%%                                     own is Pattern: words, and form(T, N)
%%                                     (the verb's own positive form) or
%%                                     participle: English future [will,
%%                                     form(present, pl)], perfect [has,
%%                                     participle], Spanish [ha, participle]
%%     ty_tense_like(L, Level, Tense, As)
%%                                     the language has no form of Tense
%%                                     at Level (clause, copula or any):
%%                                     its writer writes Tense as the
%%                                     tense As, its reader never reads
%%                                     Tense (English imperfect past:
%%                                     Spanish `veía' is `saw')
%%     ty_participle(L, Meaning, Word) a verb's participle (`seen', `visto')
%%     ty_participle_like(L, Tense, Number)
%%                                     a verb with no participle row has
%%                                     that form as its participle (English
%%                                     past, sg: `walked')
%%     ty_participle_ending(L, Gender, Number, From, To)
%%                                     a participle that agrees takes this
%%                                     ending (Italian f, sg, o, a: `vista')
%%     ty_participle_agrees(L, clitic) a participle agrees with an object
%%                                     clitic of the third person before it
%%                                     (`l'ha vista', `il l'a vue')
%%     ty_verb_class(L, Meaning, Class) a verb of a class whose tenses have
%%                                     patterns of their own (Italian go
%%                                     essere, French go `être')
%%     ty_class_tense_form(L, Class, Tense, Number, Polarity, Pattern)
%%                                     such a pattern, its item
%%                                     participle(subject) a participle that
%%                                     agrees with the subject (`è andata',
%%                                     `sont allées')
%%     ty_article(L, Definiteness, Gender, Number, Word)
%%                                     def or indef, or which (the article
%%                                     of a question: `which dog'); a
%%                                     combination with no
%%                                     row has NO article (an English plural
%%                                     indefinite: `dogs')
%%     ty_mark(L, Role, Place, Word, Conditions)
%%                                     a word before or after a role's
%%                                     phrase, written when the phrase has
%%                                     every feature of one of the
%%                                     Conditions (a list of lists of def,
%%                                     indef, sg, pl, animate, inanimate):
%%                                     Persian `را' after a definite object,
%%                                     Spanish `a' before an animate one
%%     ty_contraction(L, Words, Word)  two words written as one (`a el' is
%%                                     `al'), and read back as two
%%     ty_negation(L, Tense, Number, Words, Form)
%%                                     a negative the template does not list
%%                                     is Words before a positive form: the
%%                                     same one (Form `same': `no ve') or
%%                                     another (`form(T, N)': English `does
%%                                     not' before the present plural, `see');
%%                                     Tense and Number may be any
%%     ty_letters(L, Class, Letters)   a class of letters a pattern names
%%                                     (vowel, consonant)
%%     ty_before(L, Word, Patterns, Form, Join)
%%                                     Word is written Form before a word
%%                                     that begins with a pattern, the
%%                                     longest pattern winning: English `an'
%%                                     before a vowel and `a' before `uni',
%%                                     Italian `lo', `gli', `uno', and `l''
%%                                     and `un'' written joined to the noun
%%                                     (Join `joined', else `space'),
%%                                     Spanish `el' before `agua'. A pattern
%%                                     is a list of letters, classes and
%%                                     `end' (the word ends there)
%%     ty_linked(L, Class, NextClass, From, To)
%%                                     a word of Class right before a word of
%%                                     NextClass in its phrase ends in To in
%%                                     place of From, the longest From
%%                                     winning: the written Persian ezafe
%%                                     (`گربه' before an adjective is
%%                                     `گربه‌ی'); NextClass r is a relative
%%                                     clause after the phrase, and the
%%                                     phrase's last word takes the form
%%                                     (Persian `سگی که'); a word no row
%%                                     fits is unchanged
%%     ty_ending(L, Feature, From, To) a form a rule makes: a word ending in
%%                                     From takes To in its place, the
%%                                     longest From that fits winning
%%                                     (English plural: `y' to `ies', `ay' to
%%                                     `ays', `' to `s'); the import uses it
%%                                     where the vocabulary states no form
%%     ty_copula(L, Kind, Tense, Number, Polarity, Words)
%%                                     the copula for a predicate of Kind
%%                                     (adj, np, pp, or any: Spanish `es'
%%                                     and `está'); Words [] drops it;
%%                                     Number a person's key, as ty_verb/6's
%%     ty_adposition(L, Meaning, Words)
%%                                     a preposition or a postposition, by
%%                                     the pp level's order
%%     ty_adverb(L, Meaning, Word)     an adverb, an adjunct of the clause
%%     ty_adjunct(L, Place)            where a clause's adjuncts stand:
%%                                     start, end, before(v), after(s)
%%     ty_question(L, Kind, Level, Rule)
%%                                     how a question of Kind (yes_no, or
%%                                     wh: with a question word) changes a
%%                                     Level's order (clause, copula): Rule
%%                                     unchanged, particle(Word, start|end)
%%                                     (Word a word or a list: French
%%                                     `est-ce que'),
%%                                     front(all) (the verb before the
%%                                     subject: `¿Ve el niño al perro?') or
%%                                     front(first) (its first word only:
%%                                     `Is the dog not big?') or
%%                                     invert(pronoun) (a pronoun of the
%%                                     subject after the verb, joined to it,
%%                                     the subject in its place: French `Le
%%                                     garçon voit-il le chien?'; a pronoun
%%                                     subject itself: `Voit-il le
%%                                     chien?'); the first row is written,
%%                                     every row read
%%     ty_inversion(L, Join, VowelJoin)
%%                                     a subject pronoun right after the
%%                                     verb is written joined to it by Join,
%%                                     by VowelJoin between two vowels
%%                                     (French `voit-il', `pense-t-il')
%%     ty_question_form(L, Tense, Number, Words, Form)
%%                                     a verb a question's rule moves is, if
%%                                     positive, Words before its form Form
%%                                     (English `does' before the base:
%%                                     `Does the boy see the dog?')
%%     ty_wh(L, Place)                 a question word stands at the front,
%%                                     in place (in_place: Persian), or
%%                                     right after the subject (after(s):
%%                                     Italian `La ragazza chi vide?'), or
%%                                     every one at the front (all_front:
%%                                     Bulgarian `Кой какво вижда?')
%%     ty_wh_word(L, Meaning, Words)   who, what, where, when
%%     ty_wh_tonic(L, Meaning, Words)  a question word's form where it does
%%                                     not open the clause: after an
%%                                     adposition, and in place (French
%%                                     `quoi', where `que' opens it)
%%     ty_question_mark(L, Open, Close)
%%                                     the marks of a question (Spanish `¿'
%%                                     and `?'); with no row, `' and `?'
%%     ty_sense(L, Word, Sense, Back, Ahead)
%%                                     Word has Sense where the words before
%%                                     it fit the pattern Back and the words
%%                                     after it fit Ahead (below: a word
%%                                     with several meanings)
%%     ty_relative(L, Role, Words, Conditions)
%%                                     a relative clause's marker where the
%%                                     gap is Role (s, o, or any), written
%%                                     when the head has every feature of
%%                                     one of the Conditions (as a mark's);
%%                                     the first that fits is written, and
%%                                     Words [] is no marker (English `the
%%                                     dog the boy sees')
%%     ty_gap(L, Place, Rule)          how a relative clause's gap is
%%                                     written at Place o (an object: gap,
%%                                     the default, or resumptive) or pp (in
%%                                     an adposition phrase: stays, moves or
%%                                     resumptive) or poss (a possessor:
%%                                     moves, resumptive, or stays: French
%%                                     `dont'); the first row written,
%%                                     every row read (below: the gap)
%%     ty_relative_pronoun(L, Words, Conditions)
%%                                     the pronoun after a moved adposition
%%                                     in the marker (Spanish `en la que',
%%                                     Italian `in cui'), as a marker's
%%                                     Conditions
%%     ty_resumptive(L, Words, Conditions)
%%                                     the pronoun where a resumptive gap
%%                                     stands (Persian `آن', `او')
%%     ty_relative_after(L, Part, Rank) the relative clause of a subject (s),
%%                                     an object (o) or a copula's predicate
%%                                     (p) stands after the verb, at the
%%                                     clause's end (Persian); Rank first:
%%                                     written, and in place read too;
%%                                     second: in place written, this read
%%     ty_relative_bare(L, Definiteness)
%%                                     a head of this definiteness takes no
%%                                     article before its relative clause
%%                                     (Persian `حیوانی که', not `یک حیوانی
%%                                     که')
%%     ty_possessive(L, Order, Words, Article)
%%                                     a possessor's construction: its order
%%                                     of h p g, its word (p: Spanish `de',
%%                                     English `of', none), and whether the
%%                                     possessed keeps its article (keep) or
%%                                     loses it to the possessor (drop:
%%                                     English `the boy's dog'); the first
%%                                     row written, every row read
%%     ty_possessive_pronoun(L, Words, Possessor, Possessed)
%%                                     a possessive pronoun's words before
%%                                     the bare possessed, where the pronoun
%%                                     fits a Possessor condition and the
%%                                     possessed a Possessed one (`his',
%%                                     `sus', `la sua')
%%     ty_possessive_clitic(L)         the pronoun is a clitic on the
%%                                     possessed (Persian `سگش')
%%     ty_pronoun(L, Role, Words, Conditions)
%%                                     a personal pronoun's words in Role s
%%                                     (a subject), o (an object) or j
%%                                     (after an adposition), where the
%%                                     pronoun fits one of the Conditions,
%%                                     each its person, number and kind
%%                                     (`he' [[3, sg, m]]); a role with no
%%                                     row takes o's (j) or s's rows
%%     ty_polite(L, Number, Key)       the agreement key a polite `you' of
%%                                     Number takes (Spanish sg, sg: `usted
%%                                     ve'; French sg, pl(2): `vous voyez')
%%     ty_pro_drop(L, Persons)         a subject pronoun may be no word (the
%%                                     verb's form tells it): written so of
%%                                     the Persons listed, read so of every
%%                                     person (Spanish `Veo al perro.')
%%     ty_clitic(L, o)                 an object pronoun is a clitic in the
%%                                     verb's words, after the negation's
%%                                     (Spanish `no lo ve')
%%     ty_verb_person(L, Tense, Key, Base, From, To)
%%                                     a verb or copula of the person and
%%                                     number Key no row gives is Base's,
%%                                     its last word's ending From made To
%%                                     (English: every key but sg is pl's;
%%                                     Persian ند made م: `می‌بینم')
%%     ty_capital(L, Word, Written)    a word always written with its
%%                                     capital (English `I')
%%     ty_pronoun_gender(L, System)    a third person's pronoun of the text
%%                                     takes the noun's gender (grammatical:
%%                                     Spanish `la' for `la casa') or the
%%                                     meaning's kind (natural, the default:
%%                                     English `it')
%%     ty_relative_possessive(L, Words, Conditions)
%%                                     the pronoun of a moved possessor gap
%%                                     (`whose', `cuyo', `il cui'), its
%%                                     Conditions the possessed's features,
%%                                     or head(Features) the head's (German
%%                                     `dessen' after a masculine or a neuter
%%                                     head, `deren' after a feminine or a
%%                                     plural one)
%%     ty_complement(L, Verb, Words)   the object of Verb is an adposition
%%                                     phrase with the adposition Words, in
%%                                     the pp level's order and with no role
%%                                     marks (English `think about', Spanish
%%                                     `pensar en'); the IR keeps the plain
%%                                     object
%%     ty_complement_wh(L, Rule)       whether a complement's adposition
%%                                     moves to the front with its question
%%                                     word (`¿En qué piensa el niño?') or
%%                                     stays (`What does the boy think
%%                                     about?'); moves where no row says
%%     ty_negation_place(L, Words, Place)
%%                                     a negative verb clause has Words as a
%%                                     part of its order at Place (start,
%%                                     end, before(X), after(X), X one of s,
%%                                     v, o), the verb positive: German
%%                                     `nicht' at the end, French `ne' and
%%                                     `pas' around the verb; with no row the
%%                                     negation is the verb's form
%%     ty_answer(L, Kind, Words)       the words of an answer: yes, no, and
%%                                     contradict (a positive answer to a
%%                                     negative question: Persian `چرا')
%%     ty_answer_system(L, System)     polarity (the default: yes for a
%%                                     positive answer) or agreement (yes
%%                                     where the answer agrees with the
%%                                     question, as Japanese)
%%     ty_answer_mark(L, Mark)         the comma after an answer's word
%%                                     before its clause (`,' with no row)
%%     ty_answer_echo(L, Rule, Word)   the answer that repeats its clause
%%                                     short: Rule aux (the subject and the
%%                                     auxiliary: `Yes, he does.') or verb
%%                                     (the clause with no object: Persian
%%                                     `بله، می‌بینم.'), Word keep or drop
%%                                     the yes or no word before it
%%     ty_case(L, Role, Case)          the case of a role's noun phrase (s,
%%                                     o, p a copula's predicate, g a
%%                                     possessor): German s nom, o acc;
%%                                     a language with these rows has cases
%%     ty_case_after(L, Words, Case)   the case of the noun phrase after the
%%                                     adposition Words (German [mit] dat,
%%                                     [an] acc)
%%     ty_article_case(L, Definiteness, Gender, Number, Case, Word)
%%                                     an article of a case (German `den':
%%                                     def, m, sg, acc); each is a
%%                                     ty_article/5 row too
%%     ty_noun_case(L, Meaning, Case, Number, Word)
%%                                     a noun's form in a case where it is
%%                                     not the nominative's (`Hunden', dat,
%%                                     pl)
%%     ty_declension(L, Definiteness, Declension)
%%                                     the declension of the adjectives
%%                                     after an article of Definiteness
%%                                     (none: no article)
%%     ty_adjective_ending(L, Declension, Case, Gender, Number, Ending)
%%                                     an adjective before a noun is its
%%                                     row's word and Ending (German
%%                                     `kleinen': weak, acc, m, sg, en)
%%     ty_wh_case(L, Meaning, Case, Words)
%%                                     a question word of a case (German
%%                                     who acc [wen])
%%     ty_comma(L, Mark)               the language's comma (Persian `،'),
%%                                     `,' where it names none
%%     ty_adjunct_front(L, v2)         a statement read with an adjunct first
%%                                     and the verb before the subject
%%                                     (German `Heute schläft der Hund.')
%%     ty_object_front(L, v2)          a statement read with its object first
%%                                     and the verb before the subject, where
%%                                     the first word cannot begin a subject
%%                                     (German `Den Hund sieht der Junge.')
%%     ty_adposition_topic(L, Meaning, Topic, Words)
%%                                     the adposition's words before a noun
%%                                     of the topic (French `en mars')
%%     ty_bare_topic(L, Topic)         a noun of the topic takes no definite
%%                                     article (the months: `in March')
%%     ty_and(L, Words)                the words that join the last of a
%%                                     predicate's adjectives (`and', `y',
%%                                     `und', `و')
%%     ty_negative_article_roles(L, Roles)
%%                                     the roles (s, o, p) whose indefinite
%%                                     phrase takes the negative article
%%                                     in a negative clause (German
%%                                     [s, o, p]; [o, p] where no row says)
%%     ty_negative_article_keeps(L)    the clause keeps its own negation
%%                                     beside the negative article (French
%%                                     `ne ... pas de')
%%     ty_negative_article(L, Gender, Number, Case, Word)
%%                                     the article that says a negation
%%                                     (German `kein'): a negative clause's
%%                                     indefinite object, or a negative
%%                                     copula's indefinite predicate, takes
%%                                     it and the clause no other negation
%%     ty_split_place(L, end)          the last part of a verb of two (an
%%                                     auxiliary and a participle or an
%%                                     infinitive) stands at the clause's
%%                                     end (German `Der Junge hat den Hund
%%                                     nicht gesehen.')
%%     ty_verb_last(L, rel)            a relative clause's verb stands after
%%                                     its other parts (German `der Hund,
%%                                     den der Junge sieht')
%%     ty_copula_negation(L, Words, Place)
%%                                     ty_negation_place/3 for a copula
%%                                     clause, X one of s, c, p (German
%%                                     [nicht] before(p))
%%     ty_relative_comma(L)            a comma before a relative clause's
%%                                     marker and after the clause where
%%                                     the sentence goes on (German)
%%     ty_capital_nouns(L)             the nouns keep their capital, so a
%%                                     sentence's first word is read as
%%                                     written too (German `Hunde schlafen.')
%%
%% THE WORD TABLES. templates/<name>-words.pl holds the rows
%% typology_import/1 writes from corpus/vocabulary/<name>.txt (and, for
%% English, from every vocabulary's English meanings); typology_load/1 reads
%% it after the hand template, whose rows come first and win. Edit the hand
%% template, never the words file, and import again.
%%
%% THE IR is the meaning with English words in it, the same for every
%% language:
%%
%%     clause(Predicate, Tense, Polarity, Subject, Object)  Object none
%%                                     for a clause with no object
%%     clause(Predicate, Tense, Polarity, Subject, Object, Adjuncts)
%%                                     Adjuncts a list of pp(Meaning, NP)
%%                                     and adv(Meaning)
%%     copula(Tense, Polarity, Subject, Predicate)  Predicate adj(As),
%%                                     an np/4 or a pp/2
%%     question(Clause)                a question: Clause a clause or a
%%                                     copula clause, with no wh(M) (yes or
%%                                     no) or one, where a subject, an
%%                                     object, the one adjunct or a copula's
%%                                     predicate stands (wh(who), wh(what),
%%                                     wh(where), wh(when)), or a
%%                                     noun phrase of `which'; of several, the
%%                                     subject's moves, then the object's
%%     answer(Polarity, Asked)         the answer to a yes or no question of
%%                                     the polarity Asked (pos, neg)
%%     answer(Polarity, Asked, Clause) with its clause, of that polarity
%%     answer(Polarity, Asked, echo(Clause))
%%                                     the answer that repeats its clause
%%                                     short: Clause with no object (none)
%%                                     and no adjuncts, its verb unbound
%%                                     where the words say none
%%     np(Noun, Number, Definiteness, Adjectives)
%%     rel(NP, Clause)                 a noun phrase with a relative clause,
%%                                     where a noun phrase stands: Clause a
%%                                     clause or a copula clause with `gap'
%%                                     where the head stands in it (its
%%                                     subject or object, or the noun
%%                                     phrase of an adposition phrase:
%%                                     pp(in, gap))
%%     of(Possessor, NP)               a noun phrase of a possessor, where a
%%                                     noun phrase stands (`the boy's dog'):
%%                                     NP an np/4, Possessor an np/4, an
%%                                     of/2, a rel/2, a pronoun pron/3, or
%%                                     in a relative clause `gap' (`whose
%%                                     dog')
%%     pron(Person, Number, Kind)      a personal pronoun where a noun
%%                                     phrase stands: Person 1, 2, 3 or
%%                                     polite (the polite `you'), Number
%%                                     sg, pl, Kind m, f, n (a thing); a
%%                                     reading leaves unbound what its words
%%                                     do not tell (`you' is pron(2, _, _));
%%                                     Kind ref(Meaning) in a text's IR, the
%%                                     noun the pronoun stands for
%%
%% WHAT IS PUBLIC:
%%
%%     typology_load(+Name)            consult templates/Name.pl, then
%%                                     templates/Name-words.pl if it exists,
%%                                     and templates/topics.pl (with
%%                                     topics-words.pl) and
%%                                     templates/roles.pl once
%%     typology_import(+Name)          write templates/Name-words.pl;
%%                                     topics writes topics-words.pl
%%     typology_import(+Name, +File)   or File, and report the counts
%%     typology_languages(-Names)      the languages loaded
%%     typology_choices(+Level, -Orders)  every order of a level's parts
%%     typology_template(+Name)        a blank template on the output:
%%                                     every order, and the shape of each
%%                                     row
%%     typology_check(+Name, -Missing) what the template lacks: a level
%%                                     with no order, an order that is no
%%                                     order of its parts, a verb form or
%%                                     an adjective form the grammar may
%%                                     need, a row with a value no slot
%%                                     takes. [] is a complete template
%%     typology_read(+Name, +Text, -IR)   a sentence into the IR; each
%%                                     reading on backtracking
%%     typology_read(+Name, +Text, -IR, +Topics)
%%                                     and Topics the context's topics
%%                                     (the sentences before)
%%     typology_write(+Name, +IR, -Text)  the IR into a sentence
%%     typology_write(+Name, +IR, -Text, +Topics)
%%     typology_translate(+From, +To, +Text, -Text2)
%%     typology_topics(+IR, -Topics)   the topics of an IR's meanings
%%     typology_read_text(+Name, +Texts, -IRs)
%%                                     sentences in order, each read with
%%                                     the topics of the sentences before it
%%                                     and each pronoun of the third person
%%                                     given the noun before it that it
%%                                     stands for, pron(3, N, ref(Meaning))
%%     typology_translate_text(+From, +To, +Texts, -Texts2)
%%     typology_repair(+Name, +Text, -IR, -Faults, -Fixed)
%%                                     a sentence the template does not
%%                                     allow, read with the fewest faults
%%                                     (an order, an agreement, a mark, a
%%                                     form, a question's order or marks),
%%                                     and written as the template has it;
%%                                     Faults [] for one it allows
%%     typology_answer(+Name, +Question, +Polarity, -Text)
%%                                     the short answer to a yes or no
%%                                     question, its word chosen by the
%%                                     question's polarity
%%     typology_answer(+Name, +Question, +Polarity, +Form, -Text)
%%                                     the answer in Form word, clause or
%%                                     echo (`Yes, he does.': the subject
%%                                     as the one who answers says it, a
%%                                     noun its pronoun by templates/
%%                                     roles.pl's ty_kind/2)
%%
%% A WORD WITH SEVERAL MEANINGS IN ONE PLACE of the grammar -- Spanish `a',
%% the object's mark and `to', both after a verb and before a noun phrase;
%% `hoja', a leaf, a sheet and a blade -- takes the meaning two things
%% give, the first that decides:
%%
%%   1. THE WORDS AROUND IT, a lookback and a lookahead: the first
%%      ty_sense/5 row of the word whose Back fits the words before it
%%      (read backwards, the nearest first) and whose Ahead fits the words
%%      after it gives the meaning. A pattern is a list of items: a word;
%%      class(C), a word of class C (noun, adjective, verb, article, mark,
%%      adposition, adverb, copula); class(noun, F), a noun of gender or
%%      animacy F; opt(Item), the item or no word; a variable, any word.
%%      [] fits anything.
%%   2. THE TOPICS OF THE CONTEXT: ty_topic(Meaning, Topic) in
%%      templates/topics.pl, one table for every language (a meaning is
%%      the IR's), and a meaning is its own topic too. The vocabularies'
%%      class lines give more (templates/topics-words.pl, written by
%%      typology_import(topics)): `"sábado" is a time.' makes saturday
%%      about time, a month about the month and the time, a street's
%%      word about the street and a place. The context's
%%      topics are those given (the sentences before) and those of the
%%      sentence's words that have one meaning. Of a word's meanings in
%%      the class the grammar takes there, the ones whose topics the
%%      context has the most of are kept; where the context has none of
%%      any, every meaning is kept.
%%      In live mode a model gives a meaning the tables give no topic its
%%      topics, once (reason_live_topics/2; ty_live_topics/3 below).
%%
%% OF SEVERAL READINGS OF A QUESTION THE READER KEEPS THE LEAST COSTLY of
%% the same meanings: a question's cost is the pairs of the statement's
%% parts its order puts the other way round, so the noun after an SVO verb
%% is its object (`Chi vede il ragazzo?' is who sees the boy); a tie keeps
%% every one. And a role is what its verb takes (templates/roles.pl:
%% `Cosa vede il ragazzo?' is what the boy sees, as a thing does not see).
%%
%% A Sense is noun(M), adjective(M), verb(M), adverb(M), adposition(M),
%% mark(Role) or copula(Kind). The writer writes the first way whose
%% words, read in their context, give the IR back: `blade' in a sentence
%% about a book is `cuchilla', not `hoja' (the book makes it a sheet).
%%
%% THE GRAMMAR IS ONE DCG THAT RUNS BOTH WAYS. Each slot offers what may
%% stand there, and a check at the end of its level keeps what the
%% template allows -- agreement of the adjectives and the article with the
%% noun, the article a combination has or lacks, the marks a role's
%% phrase needs -- so the same clauses read (the words given) and write
%% (the IR given), and no order is written into them.
%%
%% TYPOLOGY-PLAN.md says what comes next. NOT YET (each is a slot to add,
%% not a change to the grammar): persons other than the third, more
%% tenses, a relative clause moved after its verb (Persian `حیوانی است که
%% می‌خوابد'); a language written without spaces.

:- module(typology, [ typology_load/1, typology_languages/1, typology_choices/2,
                      typology_template/1, typology_check/2, typology_read/3,
                      typology_read/4, typology_write/3, typology_write/4,
                      typology_translate/4, typology_topics/2,
                      typology_read_text/3, typology_translate_text/4, typology_repair/5,
                      typology_answer/4, typology_answer/5,
                      typology_import/1, typology_import/2,
                      typology_references/2, typology_reason_ir/2,
                      typology_coverage/4 ]).

:- use_module(library(reasoning/reason), [ reason_base/2 ]).

:- dynamic ty_order/3, ty_noun/6, ty_noun_class/3, ty_noun_in/6, ty_closed/2,
           ty_conjugation/3, ty_class_when/4, ty_verb_in/4, ty_irregular_verb/5,
           ty_adjective/5, ty_verb/6, ty_article/5,
           ty_mark/5, ty_contraction/3, ty_negation/5, ty_ending/4,
           ty_letters/3, ty_before/5, ty_linked/5, ty_copula/6, ty_adposition/3,
           ty_adverb/3, ty_adjunct/2, ty_sense/5, ty_topic/2, ty_question/4,
           ty_question_form/5, ty_wh/2, ty_wh_word/3, ty_question_mark/3,
           ty_role_animacy/3, ty_relative/4, ty_complement/3, ty_complement_wh/2, ty_negation_place/3,
           ty_answer/3, ty_answer_system/2, ty_answer_mark/2, ty_gap/3,
           ty_relative_pronoun/3, ty_resumptive/3, ty_relative_after/3,
           ty_relative_bare/2, ty_possessive/4, ty_relative_possessive/3,
           ty_possessive_pronoun/4, ty_possessive_clitic/1, ty_pronoun/4,
           ty_pro_drop/2, ty_clitic/2, ty_verb_person/6, ty_capital/3,
           ty_answer_echo/3, ty_kind/2, ty_adjective_before/2, ty_pronoun_gender/2,
           ty_inversion/3, ty_wh_tonic/3,
           ty_tense_form/5, ty_participle/3, ty_participle_like/3,
           ty_participle_ending/5, ty_participle_agrees/2,
           ty_verb_class/3, ty_class_tense_form/6, ty_polite/3,
           ty_case/3, ty_case_after/3, ty_article_case/6, ty_noun_case/5,
           ty_declension/3, ty_adjective_ending/6, ty_wh_case/4,
           ty_verb_last/2, ty_split_place/2, ty_copula_negation/3,
           ty_relative_comma/1, ty_negative_article/5, ty_negative_article_roles/2,
           ty_negative_article_keeps/1, ty_and/2, ty_comma/2, ty_bare_topic/2, ty_adposition_topic/4, ty_adjunct_front/2, ty_object_front/2, ty_capital_nouns/1,
           ty_reference/4, ty_meaning_sense/2, ty_tense_like/4.
:- discontiguous ty_order/3, ty_noun/6, ty_noun_class/3, ty_noun_in/6, ty_closed/2,
                 ty_conjugation/3, ty_class_when/4, ty_verb_in/4, ty_irregular_verb/5,
                 ty_adjective/5, ty_verb/6,
                 ty_article/5, ty_mark/5, ty_contraction/3, ty_negation/5,
                 ty_ending/4, ty_letters/3, ty_before/5, ty_linked/5, ty_copula/6,
                 ty_adposition/3, ty_adverb/3, ty_adjunct/2, ty_sense/5,
                 ty_question/4, ty_question_form/5, ty_wh/2, ty_wh_word/3,
                 ty_question_mark/3, ty_relative/4, ty_complement/3,
                 ty_complement_wh/2, ty_negation_place/3, ty_answer/3,
                 ty_answer_system/2, ty_answer_mark/2, ty_gap/3,
                 ty_relative_pronoun/3, ty_resumptive/3, ty_relative_after/3,
                 ty_relative_bare/2, ty_possessive/4, ty_relative_possessive/3,
                 ty_possessive_pronoun/4, ty_possessive_clitic/1, ty_pronoun/4,
                 ty_pro_drop/2, ty_clitic/2, ty_verb_person/6, ty_capital/3,
                 ty_answer_echo/3, ty_adjective_before/2, ty_pronoun_gender/2,
                 ty_inversion/3, ty_wh_tonic/3,
                 ty_tense_form/5, ty_participle/3, ty_participle_like/3,
                 ty_participle_ending/5, ty_participle_agrees/2,
                 ty_verb_class/3, ty_class_tense_form/6, ty_polite/3,
                 ty_case/3, ty_case_after/3, ty_article_case/6, ty_noun_case/5,
                 ty_declension/3, ty_adjective_ending/6, ty_wh_case/4,
                 ty_verb_last/2, ty_split_place/2, ty_copula_negation/3,
                 ty_relative_comma/1, ty_negative_article/5, ty_negative_article_roles/2,
                 ty_negative_article_keeps/1, ty_and/2, ty_comma/2, ty_bare_topic/2, ty_adposition_topic/4, ty_adjunct_front/2, ty_object_front/2, ty_capital_nouns/1,
                 ty_tense_like/4.

%% The next token, read and left (unbound writing).
ty_peek(W, S, S) :- ( nonvar(S), S = [W0|_] -> W = W0 ; true ).

%% ---- the levels and the values a slot takes -----------------------------------

ty_level(clause, [s, v, o]).
ty_level(np, [d, a, n]).
ty_level(copula, [s, c, p]).
ty_level(pp, [p, x]).
ty_level(rel, [h, m, c]).
ty_level(poss, [h, p, g]).

ty_values(tense, [present, past, future, perfect, imperfect, conditional, pluperfect]).
%% The tenses every verb and every copula has; a template gives the others
%% where it has them, or writes one as another (ty_tense_like/4);
%% typology_check/2 asks the whole of a tense where a verb or the copula
%% has one form of it.
ty_values(core_tense, [present, past]).
ty_values(number, [sg, pl]).
ty_values(agreement, [sg, pl, sg(1), sg(2), pl(1), pl(2)]).
ty_values(pronoun_role, [s, o, j]).
ty_values(person, [1, 2, 3]).
ty_values(polarity, [pos, neg]).
ty_values(definiteness, [def, indef, which]).
ty_values(animacy, [person, animate, inanimate, unknown]).
ty_values(place, [before, after]).
ty_values(role, [s, o]).
ty_values(adjunct_place, [start, end, before(v), after(s)]).
ty_values(predicate, [adj, np, pp]).
ty_values(question_kind, [yes_no, wh]).
ty_values(question_level, [clause, copula]).
ty_values(wh_place, [front, in_place, after(s), all_front]).
ty_values(wh, [who, what, where, when]).
ty_values(relative_role, [s, o, any]).
ty_values(complement_wh, [moves, stays]).
ty_values(gap_place, [o, pp, poss]).
ty_values(gap, [gap, stays, moves, resumptive]).
ty_values(relative_after, [s, o, p]).
ty_values(answer, [yes, no, contradict]).
ty_values(answer_system, [polarity, agreement]).
ty_values(negation_place, [start, end, before(s), after(s), before(v), after(v),
                          before(o), after(o)]).

%% ---- loading --------------------------------------------------------------------

typology_load(Name) :-
    must_be(atom, Name),
    ty_unexpand(Name),
    consult(library(reasoning/templates/Name)),
    forall(( member(Kind, ['-words', '-nouns', '-verbs', '-adjectives', '-adverbs']), atom_concat(Name, Kind, Base), ty_file(Base, File) ),
           consult(File)),
    ty_expand(Name),
    (   \+ ty_topic(_, _), ty_file(topics, Topics)
    ->  consult(Topics),
        (   ty_file('topics-words', TopicWords) -> consult(TopicWords) ; true )
    ;   true
    ),
    (   \+ ty_role_animacy(_, _, _), ty_file(roles, Roles)
    ->  consult(Roles)
    ;   true
    ),
    (   \+ ty_reference(_, _, _, _), ty_file(references, Refs)
    ->  consult(Refs)
    ;   true
    ),
    ty_vfirst_make(Name),
    ty_feats_make(Name).

%% templates/Base.pl, found on the library path.
ty_file(Base, File) :-
    atomic_list_concat(['templates/', Base, '.pl'], Rel),
    catch(absolute_file_name(library(reasoning/Rel), File, [access(read)]), _, fail).

%% THE CLASSES MAKE THE FORMS. typology_load/1 makes the ty_noun/6 row of
%% each ty_noun_in/6 row, its plural the class's (ty_expand/1), and before
%% it reads the files again it takes back the rows it made, by the rows
%% that made them (ty_unexpand/1). A noun its class makes no plural of is
%% typology_check/2's noun_form(Meaning).
ty_expand(L) :-
    forall(( ty_noun_in(L, M, G, A, Sg, C), ty_noun_class(L, C, Es), ty_class_form(Es, Sg, Pl) ),
           assertz(ty_noun(L, M, G, A, Sg, Pl))),
    forall(ty_class_verb(L, M, B, C, Over), ty_expand_verb(L, M, B, C, Over)).

ty_unexpand(L) :-
    forall(ty_noun_in(L, M, G, A, Sg, _), retractall(ty_noun(L, M, G, A, Sg, _))),
    forall(ty_class_verb(L, M, _, _, _),
           ( retractall(ty_verb(L, M, _, _, pos, _)), retractall(ty_participle(L, M, _)) )).


%% A verb's forms (ty_expand/1): each part of its class, the form its rule
%% makes from the base, or the irregular verb's own form of the part; a
%% present or a past part is a ty_verb/6 row, the participle a
%% ty_participle/3 row. A part's rule that names another part is followed
%% at most five deep.
ty_expand_verb(L, M, B, C, Over) :-
    (   ty_conjugation(L, C, Parts)
    ->  forall(( member(Part-_, Parts), ty_verb_part(Part, Parts, Over, B, F, 0) ),
               ty_verb_row(L, M, Part, F))
    ;   true
    ).

ty_verb_part(Part, Parts, Over, B, F, D) :-
    D < 6,
    (   memberchk(Part-F0, Over)
    ->  F = F0
    ;   memberchk(Part-Rule, Parts),
        (   Rule == base -> F = B
        ;   is_list(Rule) -> ty_class_form(Rule, B, F)
        ;   D1 is D + 1, ty_verb_part(Rule, Parts, Over, B, F, D1)
        )
    ).

ty_verb_row(L, M, participle, F) :- !, assertz(ty_participle(L, M, F)).
ty_verb_row(L, M, Part, F) :-
    Part =.. [T, N],
    assertz(ty_verb(L, M, T, N, pos, [F])).

%% An irregular verb, and a verb of a class: the irregular verbs' rows
%% first, so a form two verbs share is read as the irregular verb's first
%% (`found': find before found, `saw': see before saw).
ty_class_verb(L, M, B, C, Over) :- ty_irregular_verb(L, M, B, C, Over).
ty_class_verb(L, M, B, C, []) :- ty_verb_in(L, M, B, C).

%% A class's form of Word: the longest From of its endings that ends Word,
%% its To in From's place.
ty_class_form(Endings, Word, Form) :-
    findall(Len-(From-To), ( member(From-To, Endings), atom_concat(_, From, Word),
                             atom_length(From, Len) ), Fits),
    Fits \== [],
    keysort(Fits, Sorted),
    last(Sorted, _-(From-To)),
    atom_concat(Stem, From, Word),
    atom_concat(Stem, To, Form).

typology_languages(Names) :-
    (   setof(L, O^ty_order(L, clause, O), Names) -> true ; Names = [] ).

%% ---- the choices and the blank template -------------------------------------------

typology_choices(Level, Orders) :-
    ty_level(Level, Parts),
    findall(O, permutation(Parts, O), Orders).

%% THE BLANK TEMPLATE (typology_template/1): every slot, in groups
%% (ty_template_group/2), each with its description from this file's
%% header (THE TEMPLATE, read at the call: one text, in one place) and
%% then its rows. A slot of a closed set of choices (ty_template_choice/4)
%% is every choice as a row of code, which a language keeps or deletes; any
%% other slot is its shape in a comment, with an example, the first row of
%% the slot in the hand templates of english, spanish, italian, french,
%% german and persian. templates/template.pl is the template of `xx',
%% written by typology_import(template).
typology_template(Name) :-
    must_be(atom, Name),
    ty_template_docs(Docs),
    findall(R, ( member(L, [english, spanish, italian, french, german, persian]),
                 catch(ty_hand_rows(L, Rs), _, Rs = []),
                 member(R, Rs) ), Hand),
    ty_template_head(Name),
    forall(ty_template_group(Title, Slots),
           ( format("~n%% ==== ~w ====~n", [Title]),
             forall(member(Slot, Slots), ty_template_slot(Name, Docs, Hand, Slot)) )).

ty_template_head(Name) :-
    format("%% The blank template of the language `~w': every slot of~n", [Name]),
    format("%% library(reasoning/typology), and every choice. typology_template/1~n", []),
    format("%% writes it from typology.pl; templates/template.pl is the one of `xx',~n", []),
    format("%% written by typology_import(template). Do not edit that file: change~n", []),
    format("%% typology.pl and import again.~n%%~n", []),
    format("%% TO MAKE A LANGUAGE: copy it to templates/<name>.pl, with the name for~n", []),
    format("%% each `xx' (or ask typology_template(<name>) for the same text in the~n", []),
    format("%% name). Then, slot by slot:~n%%~n", []),
    format("%%   - a row of code is a choice: keep it where the language uses it,~n", []),
    format("%%     delete it where the language does not;~n", []),
    format("%%   - a row in a comment is a shape: write a row of it for each word or~n", []),
    format("%%     form the language has, as the example after it (another~n", []),
    format("%%     language's row) shows. A slot the language does not need gets~n", []),
    format("%%     no row.~n%%~n", []),
    format("%% typology_import(<name>) writes the word tables from~n", []),
    format("%% corpus/vocabulary/<name>.txt, typology_load(<name>) reads the~n", []),
    format("%% template, and typology_check(<name>, Missing) names what is still~n", []),
    format("%% missing.~n", []).

ty_template_slot(Name, Docs, Hand, Slot) :-
    nl,
    ( memberchk(Slot-Lines, Docs) -> forall(member(Line, Lines), format("~w~n", [Line])) ; true ),
    (   ty_template_choice(Slot, Name, Note, Rows)
    ->  format("%%   (~w)~n", [Note]),
        forall(member(R, Rows), ty_template_row(R))
    ;   atom_length(Slot, SL), ty_row_shape(Shape),
        sub_atom(Shape, 0, SL, _, Slot), sub_atom(Shape, SL, 2, _, '(L'),
        Start is SL + 2, sub_atom(Shape, Start, _, 0, Tail)
    ->  format("%% ~w(~q~w~n", [Slot, Name, Tail]),
        (   ty_template_example(Slot, Hand, Ex)
        ->  with_output_to(string(ExS), write_term(Ex, [quoted(true), spacing(next_argument)])),
            format("%%   e.g. ~s.~n", [ExS])
        ;   true
        )
    ;   true
    ).

ty_template_row(row(T)) :- write_term(T, [quoted(true), spacing(next_argument)]), format(".~n", []).
ty_template_row(text(Fmt, Args)) :- format("%% ", []), format(Fmt, Args), nl.

ty_template_example(Slot, Hand, Ex) :-
    member(Ex0, Hand), compound(Ex0), functor(Ex0, Slot, _), !,
    ty_template_short(Ex0, Ex).

%% An example's list of more than eight is its first eight and `...'.
ty_template_short(T, S) :-
    (   is_list(T)
    ->  (   length(T, N), N > 8
        ->  length(F, 8), append(F, _, T), maplist(ty_template_short, F, F1), append(F1, ['...'], S)
        ;   maplist(ty_template_short, T, S)
        )
    ;   compound(T), T \= [_|_]
    ->  T =.. [Fn|As], maplist(ty_template_short, As, As1), S =.. [Fn|As1]
    ;   S = T
    ).

%% The description of each slot in this file's header: an entry starts at
%% a line `%%     ty_...' and goes on over the lines indented more, as
%% Name-Lines.
ty_template_docs(Docs) :-
    ty_dir(Dir),
    atom_concat(Dir, '/typology.pl', File),
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    atomic_list_concat(Lines, '\n', Text),
    append(_, ['%% THE TEMPLATE. A language file is facts, the language\'s name first in'|Rest], Lines), !,
    ty_tdoc_entries(Rest, Docs).

ty_tdoc_entries([], []).
ty_tdoc_entries([L|Ls], Docs) :-
    (   sub_atom(L, 0, _, _, '%%     ty_')
    ->  sub_atom(L, 7, _, _, After), sub_atom(After, BP, _, _, '('), !,
        sub_atom(After, 0, BP, _, Name),
        ty_tdoc_more(Ls, More, Ls1),
        Docs = [Name-[L|More]|Docs1],
        ty_tdoc_entries(Ls1, Docs1)
    ;   L == '%% THE WORD TABLES. templates/<name>-words.pl holds the rows'
    ->  Docs = []
    ;   ty_tdoc_entries(Ls, Docs)
    ).

ty_tdoc_more([L|Ls], [L|More], Rest) :-
    sub_atom(L, 0, _, _, '%%      '), !,
    ty_tdoc_more(Ls, More, Rest).
ty_tdoc_more(Ls, [], Ls).

%% The groups of the blank template, every slot once (test/typology.pl's
%% section blank_template holds them to the header's slots).
ty_template_group('the orders of the levels', [ty_order]).
ty_template_group('words', [ty_noun_class, ty_class_when, ty_noun_in, ty_noun, ty_adjective, ty_adjective_before, ty_article, ty_adposition,
                            ty_adverb, ty_capital, ty_capital_nouns, ty_and, ty_comma, ty_sense, ty_closed]).
ty_template_group('verbs and tenses', [ty_conjugation, ty_verb_in, ty_irregular_verb, ty_verb, ty_tense_form, ty_tense_like, ty_participle,
                                       ty_participle_like, ty_participle_ending, ty_participle_agrees,
                                       ty_verb_class, ty_class_tense_form, ty_verb_person, ty_copula,
                                       ty_split_place, ty_verb_last]).
ty_template_group('the negation', [ty_negation, ty_negation_place, ty_copula_negation,
                                   ty_negative_article, ty_negative_article_roles,
                                   ty_negative_article_keeps]).
ty_template_group('forms chosen by sound, and contractions', [ty_ending, ty_letters, ty_before,
                                                               ty_linked, ty_contraction]).
ty_template_group('roles, marks and cases', [ty_mark, ty_case, ty_case_after, ty_article_case,
                                             ty_noun_case, ty_declension, ty_adjective_ending]).
ty_template_group('adjuncts and complements', [ty_adjunct, ty_adjunct_front, ty_object_front,
                                               ty_bare_topic, ty_adposition_topic, ty_complement]).
ty_template_group('questions and answers', [ty_question, ty_inversion, ty_question_form,
                                            ty_question_mark, ty_wh, ty_wh_word, ty_wh_tonic, ty_wh_case,
                                            ty_complement_wh, ty_answer, ty_answer_system,
                                            ty_answer_mark, ty_answer_echo]).
ty_template_group('relative clauses', [ty_relative, ty_relative_comma, ty_gap, ty_relative_pronoun,
                                       ty_resumptive, ty_relative_after, ty_relative_bare,
                                       ty_relative_possessive]).
ty_template_group('possessors and pronouns', [ty_possessive, ty_possessive_pronoun,
                                              ty_possessive_clitic, ty_pronoun, ty_pronoun_gender,
                                              ty_polite, ty_pro_drop, ty_clitic]).

%% A slot of a closed set of choices: a note, and every choice as a row of
%% code (row(Term)), or as a comment where it needs words or other rows
%% first (text(Format, Args)).
ty_template_choice(ty_order, Name, 'keep the orders it uses; the first kept is the one written', Rows) :-
    findall(R, ( ty_level(Level, Parts), Level \== poss,
                 (   atomic_list_concat(Parts, ', ', PT), R = text("~w: ~w", [Level, PT])
                 ;   typology_choices(Level, Os), member(O, Os), R = row(ty_order(Name, Level, O))
                 ) ), Rows).
ty_template_choice(ty_possessive, Name, 'keep the ones it uses, with their words, and keep or drop', Rows) :-
    typology_choices(poss, Os),
    findall(text("ty_possessive(~q, [~w], Words, keep_or_drop).", [Name, OT]),
            ( member(O, Os), atomic_list_concat(O, ', ', OT) ), Rows).
ty_template_choice(ty_adjunct, Name, 'keep one', Rows) :-
    ty_values(adjunct_place, Ps), findall(row(ty_adjunct(Name, P)), member(P, Ps), Rows).
ty_template_choice(ty_question, Name, 'one row or more a kind and level; a particle needs its words', Rows) :-
    findall(R, ( ty_values(question_kind, Ks), member(K, Ks),
                 ty_values(question_level, Ls), member(Lv, Ls),
                 (   member(Rule, [unchanged, front(all), front(first), invert(pronoun)]),
                     R = row(ty_question(Name, K, Lv, Rule))
                 ;   member(P, [start, end]),
                     R = text("ty_question(~q, ~q, ~q, particle(Words, ~q)).", [Name, K, Lv, P])
                 ) ), Rows).
ty_template_choice(ty_wh, Name, 'keep one', Rows) :-
    ty_values(wh_place, Ps), findall(row(ty_wh(Name, P)), member(P, Ps), Rows).
ty_template_choice(ty_complement_wh, Name, 'keep one', Rows) :-
    ty_values(complement_wh, Rs), findall(row(ty_complement_wh(Name, R)), member(R, Rs), Rows).
ty_template_choice(ty_answer_system, Name, 'keep one', Rows) :-
    ty_values(answer_system, Ss), findall(row(ty_answer_system(Name, S)), member(S, Ss), Rows).
ty_template_choice(ty_gap, Name, 'keep the rules it uses, one or more a place', Rows) :-
    findall(row(ty_gap(Name, Pl, R)),
            ( ty_values(gap_place, Ps), member(Pl, Ps), ty_values(gap, Rs), member(R, Rs),
              ( Pl == o -> memberchk(R, [gap, resumptive]) ; R \== gap ) ), Rows).
ty_template_choice(ty_relative_after, Name, 'keep the ones the language uses, or none', Rows) :-
    findall(row(ty_relative_after(Name, P, R)),
            ( ty_values(relative_after, Ps), member(P, Ps), member(R, [first, second]) ), Rows).
ty_template_choice(ty_relative_bare, Name, 'keep the ones the language uses, or none', Rows) :-
    findall(row(ty_relative_bare(Name, D)), member(D, [def, indef]), Rows).
ty_template_choice(ty_pronoun_gender, Name, 'keep one, or none: natural is the default', Rows) :-
    findall(row(ty_pronoun_gender(Name, S)), member(S, [grammatical, natural]), Rows).
ty_template_choice(ty_pro_drop, Name, 'keep the persons whose subject may be no word, or delete it', [row(ty_pro_drop(Name, [1, 2, 3]))]).
ty_template_choice(ty_negative_article_roles, Name, 'only with ty_negative_article/5 rows; keep the roles that take it', [text("ty_negative_article_roles(~q, [s, o, p]).", [Name])]).
ty_template_choice(ty_negative_article_keeps, Name, 'only with ty_negative_article/5 rows', [text("ty_negative_article_keeps(~q).", [Name])]).
ty_template_choice(Slot, Name, 'keep it where the language does this, else delete it', [row(T)]) :-
    ty_template_flag(Slot, Name, T).

ty_template_flag(ty_possessive_clitic, Name, ty_possessive_clitic(Name)).
ty_template_flag(ty_clitic, Name, ty_clitic(Name, o)).
ty_template_flag(ty_participle_agrees, Name, ty_participle_agrees(Name, clitic)).
ty_template_flag(ty_split_place, Name, ty_split_place(Name, end)).
ty_template_flag(ty_verb_last, Name, ty_verb_last(Name, rel)).
ty_template_flag(ty_relative_comma, Name, ty_relative_comma(Name)).
ty_template_flag(ty_capital_nouns, Name, ty_capital_nouns(Name)).
ty_template_flag(ty_adjunct_front, Name, ty_adjunct_front(Name, v2)).
ty_template_flag(ty_object_front, Name, ty_object_front(Name, v2)).

ty_row_shape('ty_noun(L, Meaning, Gender, Animacy, Singular, Plural).').
ty_row_shape('ty_noun_class(L, Class, Endings).').
ty_row_shape('ty_noun_in(L, Meaning, Gender, Animacy, Singular, Class).').
ty_row_shape('ty_closed(L, Words).').
ty_row_shape('ty_adjective(L, Meaning, Gender, Number, Word).').
ty_row_shape('ty_verb(L, Meaning, Tense, Number, Polarity, Words).').
ty_row_shape('ty_conjugation(L, Class, Parts).').
ty_row_shape('ty_class_when(L, Kind, Class, Pattern).').
ty_row_shape('ty_verb_in(L, Meaning, Base, Class).').
ty_row_shape('ty_irregular_verb(L, Meaning, Base, Class, Parts).').
ty_row_shape('ty_article(L, Definiteness, Gender, Number, Word).').
ty_row_shape('ty_mark(L, Role, Place, Word, Conditions).').
ty_row_shape('ty_contraction(L, Words, Word).').
ty_row_shape('ty_negation(L, Tense, Number, Words, Form).').
ty_row_shape('ty_ending(L, Feature, From, To).').
ty_row_shape('ty_letters(L, Class, Letters).').
ty_row_shape('ty_before(L, Word, Patterns, Form, Join).').
ty_row_shape('ty_linked(L, Class, NextClass, From, To).').
ty_row_shape('ty_copula(L, Kind, Tense, Number, Polarity, Words).').
ty_row_shape('ty_adposition(L, Meaning, Words).').
ty_row_shape('ty_adverb(L, Meaning, Word).').
ty_row_shape('ty_sense(L, Word, Sense, Back, Ahead).').
ty_row_shape('ty_question_form(L, Tense, Number, Words, Form).').
ty_row_shape('ty_wh_word(L, Meaning, Words).').
ty_row_shape('ty_question_mark(L, Open, Close).').
ty_row_shape('ty_relative(L, Role, Words, Conditions).').
ty_row_shape('ty_complement(L, Verb, Words).').
ty_row_shape('ty_negation_place(L, Words, Place).').
ty_row_shape('ty_answer(L, Kind, Words).').
ty_row_shape('ty_answer_mark(L, Mark).').
ty_row_shape('ty_gap(L, Place, Rule).').
ty_row_shape('ty_relative_pronoun(L, Words, Conditions).').
ty_row_shape('ty_resumptive(L, Words, Conditions).').
ty_row_shape('ty_relative_after(L, Part, Rank).').
ty_row_shape('ty_relative_bare(L, Definiteness).').
ty_row_shape('ty_possessive(L, Order, Words, Article).').
ty_row_shape('ty_relative_possessive(L, Words, Conditions).').
ty_row_shape('ty_possessive_pronoun(L, Words, Possessor, Possessed).').
ty_row_shape('ty_possessive_clitic(L).').
ty_row_shape('ty_pronoun(L, Role, Words, Conditions).').
ty_row_shape('ty_pro_drop(L, Persons).').
ty_row_shape('ty_clitic(L, Role).').
ty_row_shape('ty_verb_person(L, Tense, Person, Base, From, To).').
ty_row_shape('ty_capital(L, Word, Written).').
ty_row_shape('ty_answer_echo(L, Rule, Word).').
ty_row_shape('ty_adjective_before(L, Meaning).').
ty_row_shape('ty_pronoun_gender(L, System).').
ty_row_shape('ty_inversion(L, Join, VowelJoin).').
ty_row_shape('ty_wh_tonic(L, Meaning, Words).').
ty_row_shape('ty_tense_form(L, Tense, Number, Polarity, Pattern).').
ty_row_shape('ty_tense_like(L, Level, Tense, As).').
ty_row_shape('ty_participle(L, Meaning, Word).').
ty_row_shape('ty_participle_like(L, Tense, Number).').
ty_row_shape('ty_participle_ending(L, Gender, Number, From, To).').
ty_row_shape('ty_participle_agrees(L, With).').
ty_row_shape('ty_verb_class(L, Meaning, Class).').
ty_row_shape('ty_class_tense_form(L, Class, Tense, Number, Polarity, Pattern).').
ty_row_shape('ty_polite(L, Number, Key).').
ty_row_shape('ty_case(L, Role, Case).').
ty_row_shape('ty_case_after(L, Words, Case).').
ty_row_shape('ty_article_case(L, Definiteness, Gender, Number, Case, Word).').
ty_row_shape('ty_noun_case(L, Meaning, Case, Number, Word).').
ty_row_shape('ty_declension(L, Definiteness, Declension).').
ty_row_shape('ty_adjective_ending(L, Declension, Case, Gender, Number, Ending).').
ty_row_shape('ty_wh_case(L, Meaning, Case, Words).').
ty_row_shape('ty_negative_article(L, Gender, Number, Case, Word).').
ty_row_shape('ty_negative_article_roles(L, Roles).').
ty_row_shape('ty_negative_article_keeps(L).').
ty_row_shape('ty_and(L, Words).').
ty_row_shape('ty_bare_topic(L, Topic).').
ty_row_shape('ty_adjunct_front(L, Kind).').
ty_row_shape('ty_object_front(L, Kind).').
ty_row_shape('ty_adposition_topic(L, Meaning, Topic, Words).').
ty_row_shape('ty_comma(L, Mark).').
ty_row_shape('ty_split_place(L, end).').
ty_row_shape('ty_verb_last(L, rel).').
ty_row_shape('ty_copula_negation(L, Words, Place).').
ty_row_shape('ty_relative_comma(L).').
ty_row_shape('ty_capital_nouns(L).').

%% ---- the check ----------------------------------------------------------------------

typology_check(L, Missing) :-
    must_be(atom, L),
    findall(M, ty_missing(L, M), Missing0),
    sort(Missing0, Missing).

%% THE REFERENCE SENTENCES (templates/references.pl): the rows of L whose
%% text, read with their topics, has not their IR among its readings, as
%% Text-Topics. Live mode holds a model's topics to them.
typology_references(L, Failed) :-
    must_be(atom, L),
    findall(Text-Topics, ( ty_reference(L, Text, Topics, IR),
                           \+ ty_reference_holds(L, Text, Topics, IR) ), Failed).

ty_reference_holds(L, Text, Topics, IR) :-
    \+ \+ ( typology_read(L, Text, R, Topics), R =@= IR ).

%% ---- the bridge to translate.pl (Phase 6) -----------------------------------------
%%
%% typology_reason_ir(?IR, ?Sentence): IR, the typology's term, and
%% Sentence, translate.pl's ir(S, Stop) (reason_ir/3 reads it,
%% reason_ir_text/3 writes it), for the shapes the two have alike: a
%% clause with its subject, its object or none and its adjuncts (an
%% adposition phrase, an adverb), in the present, the past, the future,
%% the conditional, the perfect or the pluperfect, denied or not; a copula
%% clause with its adjectives or a noun phrase; a yes or no question, and
%% a question whose subject or object is `who' or `what'; a noun phrase
%% with `the' or `a', its adjectives and its number; and a relative clause
%% whose gap is its subject or its object. Either side may be given, and
%% the answer is the first. The words are the English template's
%% (typology_load(english) first): a meaning is its English word, a verb
%% its present third person (`sees'), the copula `is', and a noun's word
%% may be its plural, as translate.pl's English reader leaves it (`dogs').
%% Any other shape fails: a pronoun, a possessor, the imperfect, a
%% question word in an adjunct.
typology_reason_ir(IR, ir(S, Stop)) :-
    once(ty_br_top(IR, S, Stop)).

ty_br_top(question(C), S, 63) :- ty_br_ask(C, S).
ty_br_top(C, S, 46) :- ty_br_s(C, S).

ty_br_s(copula(T, P, S, Pred), s(none, RS, G, [C])) :-
    ty_br_np(S, RS), ty_br_copula(T, P, G), ty_br_pred(Pred, C).
ty_br_s(clause(V, T, P, S, O), s(none, RS, G, Cs)) :-
    ty_br_np(S, RS), ty_br_group(V, T, P, G), ty_br_object(O, Cs, []).
ty_br_s(clause(V, T, P, S, O, Js), s(none, RS, G, Cs)) :-
    ty_br_np(S, RS), ty_br_group(V, T, P, G), ty_br_object(O, Cs, Cs1),
    ty_br_adjuncts(Js, Cs1), Js \== [].

%% A question word: the subject's (s(subject(Q), asked(Q), ...)) or the
%% object's (s(object(Q), Subject, ...)); else a yes or no question, its
%% statement.
ty_br_ask(clause(V, T, P, wh(Q), O), s(subject(w(Q, lower)), asked(w(Q, lower)), G, Cs)) :-
    ty_br_wh(Q), ty_br_group(V, T, P, G), ty_br_object(O, Cs, []).
ty_br_ask(copula(T, P, wh(Q), Pred), s(subject(w(Q, lower)), asked(w(Q, lower)), G, [C])) :-
    ty_br_wh(Q), ty_br_copula(T, P, G), ty_br_pred(Pred, C).
ty_br_ask(clause(V, T, P, S, wh(Q)), s(object(w(Q, lower)), RS, G, [])) :-
    ty_br_wh(Q), ty_br_np(S, RS), ty_br_group(V, T, P, G).
ty_br_ask(C, S) :- ty_br_s(C, S).

ty_br_wh(who).
ty_br_wh(what).

%% The verb group: the verb's present third person, the tense as a tense
%% and an aspect, and the denial.
ty_br_group(V, T, P, g(Lex, Tn, Asp, Den)) :-
    ty_br_tense(T, Tn, Asp), ty_br_polarity(P, Den),
    ty_verb(english, V, present, sg, pos, [Lex]).
ty_br_copula(T, P, g(is, Tn, Asp, Den)) :-
    ty_br_tense(T, Tn, Asp), ty_br_polarity(P, Den).

ty_br_tense(present, present, simple).
ty_br_tense(past, past, simple).
ty_br_tense(future, future, simple).
ty_br_tense(conditional, conditional, simple).
ty_br_tense(perfect, present, perfect).
ty_br_tense(pluperfect, past, perfect).

ty_br_polarity(pos, no).
ty_br_polarity(neg, yes).

ty_br_object(none, Cs, Cs).
ty_br_object(NP, [obj(R)|Cs], Cs) :- NP \== none, ty_br_np(NP, R).

ty_br_pred(adj(As), adj(Ws)) :- ty_br_adjs(As, Ws).
ty_br_pred(NP, obj(R)) :- NP = np(_, _, _, _), ty_br_np(NP, R).

ty_br_adjuncts([], []).
ty_br_adjuncts([J|Js], [C|Cs]) :- ty_br_adjunct(J, C), ty_br_adjuncts(Js, Cs).

ty_br_adjunct(pp(M, NP), pp(w(W, lower), R)) :-
    ty_adposition(english, M, [W]), ty_br_np(NP, R).
ty_br_adjunct(adv(M), adv(w(W, lower))) :- ty_adverb(english, M, W).

%% A noun phrase: the article, the adjectives, the noun and its number; a
%% relative clause, its gap the subject (gap(third, Number), the head's
%% number) or the object (no object among the complements).
ty_br_np(np(M, N, Def, As), np(Det, none, Ws, w(W, lower), RN)) :-
    ty_br_det(Def, Det), ty_br_number(N, RN),
    ty_br_noun(M, W), ty_br_adjs(As, Ws).
ty_br_np(rel(NP, C), rc(R, Role, S)) :- ty_br_rel(NP, C, R, Role, S).

ty_br_rel(NP, clause(V, T, P, gap, O), R, subject, s(none, gap(third, RN), G, Cs)) :-
    ty_br_np(NP, R), NP = np(_, N, _, _), ty_br_number(N, RN),
    ty_br_group(V, T, P, G), ty_br_object(O, Cs, []).
ty_br_rel(NP, copula(T, P, gap, Pred), R, subject, s(none, gap(third, RN), G, [C])) :-
    ty_br_np(NP, R), NP = np(_, N, _, _), ty_br_number(N, RN),
    ty_br_copula(T, P, G), ty_br_pred(Pred, C).
ty_br_rel(NP, clause(V, T, P, S, gap), R, object, s(none, RS, G, [])) :-
    ty_br_np(NP, R), ty_br_np(S, RS), ty_br_group(V, T, P, G).

%% `the' and `a' (read, translate.pl's word may be `an').
ty_br_det(Def, det(article, A, W)) :-
    ty_br_def(Def, A),
    ( var(W) -> W = w(A, lower) ; true ).

ty_br_def(def, the).
ty_br_def(indef, a).

ty_br_number(sg, singular).
ty_br_number(pl, plural).

%% A noun's meaning and its English word, the singular written and either
%% form read.
ty_br_noun(M, W) :-
    (   atom(W)
    ->  ( ty_noun(english, M, _, _, W, _) ; ty_noun(english, M, _, _, _, W) )
    ;   ty_noun(english, M, _, _, W, _)
    ).

ty_br_adjs([], []).
ty_br_adjs([A|As], [w(W, lower)|Ws]) :-
    ty_adjective(english, A, _, _, W), ty_br_adjs(As, Ws).

%% ---- the measure: how much of a text the template reads ----------------------------
%%
%% typology_coverage(+L, +Sentences, -Read, -Unknown): of Sentences (atoms),
%% Read are the ones typology_read/3 reads into an IR, and Unknown the
%% words of all of them no table of L has, as Word-Count, the commonest
%% first (the words the reader's own split gives, ty_surface/5, its commas
%% off). A
%% sentence is given 2 000 000 inferences. tools/typology/coverage.pl
%% prints it over lexicon/prose.txt, WordNet's 8 000 example sentences.
typology_coverage(L, Sentences, Read, Unknown) :-
    must_be(atom, L),
    must_be(list, Sentences),
    findall(S, ( member(S, Sentences),
                 catch(call_with_inference_limit(once(typology_read(L, S, _)), 2000000, R), _, fail),
                 R \== inference_limit_exceeded ), Read),
    findall(W, ( member(S, Sentences),
                 catch(( ty_surface(S, _, _, _, Ws), ty_uncomma(L, Ws, Ws2) ), _, fail),
                 member(W, Ws2), W \== ',', \+ ty_known_token(L, W) ), Ws0),
    msort(Ws0, Ws1),
    ty_count_runs(Ws1, Counts),
    findall(N-W, member(W-N, Counts), NWs),
    keysort(NWs, Up), reverse(Up, Down),
    findall(W-N, member(N-W, Down), Unknown).

ty_count_runs([], []).
ty_count_runs([X|Xs], [X-N|Rest]) :-
    ty_count_same(X, Xs, 1, N, Xs1),
    ty_count_runs(Xs1, Rest).

ty_count_same(X, [Y|Ys], N0, N, Rest) :- X == Y, !, N1 is N0 + 1, ty_count_same(X, Ys, N1, N, Rest).
ty_count_same(_, Rest, N, N, Rest).

ty_missing(L, order(Level)) :-
    ty_level(Level, _),
    ty_level_used(L, Level),
    \+ ty_order(L, Level, _).
ty_missing(L, copula_form(K, T, N, P)) :-
    ty_copula(L, _, _, _, _, _),
    ty_values(predicate, Ks), member(K, Ks),
    ty_values(tense, Ts), member(T, Ts),
    ( ty_values(core_tense, Cs), memberchk(T, Cs) -> true ; once(ty_copula(L, _, T, _, _, _)) ),
    ty_values(number, Ns), member(N, Ns),
    ty_values(polarity, Ps), member(P, Ps),
    \+ ( P == neg, once(ty_copula_negation(L, _, _)) ),
    \+ ( ty_copula_n(L, K1, T, P, N, _), ty_fits(K1, K) ).
ty_missing(L, adjunct_place) :-
    once(( ty_adposition(L, _, _) ; ty_adverb(L, _, _) )),
    \+ ty_adjunct(L, _).
ty_missing(L, bad(ty_adjunct(L, P))) :-
    ty_adjunct(L, P),
    \+ ( ty_values(adjunct_place, Ps), memberchk(P, Ps) ).
ty_missing(L, not_an_order(Level, Order)) :-
    ty_order(L, Level, Order),
    \+ ( ty_level(Level, Parts), permutation(Parts, Order) ).
ty_missing(L, verb_form(V, T, N, P)) :-
    ty_verb_meaning(L, V),
    ty_values(tense, Ts), member(T, Ts),
    ty_tense_asked(L, V, T),
    ty_values(number, Ns), member(N, Ns),
    ty_values(polarity, Ps), member(P, Ps),
    \+ ( P == neg, ty_neg_placed(L) ),
    \+ ty_verb_form(L, V, T, N, P, _).
%% The genders once (ty_gender/2 walks every noun): asked for each
%% adjective, the check of English's 17 703 made 358 million inferences
%% (1.58.0's first cut).
ty_missing(L, adjective_form(A, G, N)) :-
    findall(G0, ty_gender(L, G0), Gs),
    ty_adjective_meaning(L, A),
    member(G, Gs),
    ty_values(number, Ns), member(N, Ns),
    \+ ( ty_adjective(L, A, RG, RN, _), ty_fits(RG, G), ty_fits(RN, N) ).
ty_missing(L, bad(ty_verb(L, V, T, N, P, Ws))) :-
    ty_verb(L, V, T, N, P, Ws),
    \+ ( ty_values(tense, Ts), memberchk(T, Ts),
         ty_values(agreement, Ns), memberchk(N, Ns),
         ty_values(polarity, Ps), memberchk(P, Ps),
         is_list(Ws), Ws \== [] ).
ty_missing(L, bad(ty_noun(L, M, G, A, S, P))) :-
    ty_noun(L, M, G, A, S, P),
    \+ ( ty_values(animacy, As), memberchk(A, As) ).
ty_missing(L, bad(ty_noun_class(L, C, Es))) :-
    ty_noun_class(L, C, Es),
    \+ ( atom(C), is_list(Es), Es \== [],
         forall(member(E, Es), ( nonvar(E), E = F-T, atom(F), atom(T) )) ).
ty_missing(L, bad(ty_noun_in(L, M, G, A, S, C))) :-
    ty_noun_in(L, M, G, A, S, C),
    \+ ( atom(M), atom(S), atom(C), ty_values(animacy, As), memberchk(A, As) ).
ty_missing(L, bad(ty_closed(L, Ws))) :-
    ty_closed(L, Ws),
    \+ ( is_list(Ws), forall(member(W, Ws), atom(W)) ).
ty_missing(L, bad(ty_conjugation(L, C, Ps))) :-
    ty_conjugation(L, C, Ps),
    \+ ( atom(C), is_list(Ps), Ps \== [],
         forall(member(P, Ps), ( nonvar(P), P = Part-R, ty_part_ok(Part), ty_rule_ok(R, Ps) )) ).
ty_missing(L, bad(ty_class_when(L, K, C, Pat))) :-
    ty_class_when(L, K, C, Pat),
    \+ ( memberchk(K, [noun, verb]), atom(C), is_list(Pat),
         forall(member(I, Pat), ( atom(I) ; nonvar(I), I = star(A), atom(A) )) ).
ty_missing(L, bad(ty_verb_in(L, M, B, C))) :-
    ty_verb_in(L, M, B, C),
    \+ ( atom(M), atom(B), atom(C) ).
ty_missing(L, bad(ty_irregular_verb(L, M, B, C, Ps))) :-
    ty_irregular_verb(L, M, B, C, Ps),
    \+ ( atom(M), atom(B), atom(C), is_list(Ps),
         forall(member(P, Ps), ( nonvar(P), P = Part-W, ty_part_ok(Part), atom(W) )) ).
ty_missing(L, conjugation(C)) :-
    ty_class_verb(L, _, _, C, _),
    \+ ty_conjugation(L, C, _).
ty_missing(L, verb_part(M, Part)) :-
    ty_class_verb(L, M, B, C, Over),
    ty_conjugation(L, C, Ps),
    member(Part-_, Ps),
    \+ ty_verb_part(Part, Ps, Over, B, _, 0).
ty_missing(L, noun_class(C)) :-
    ty_noun_in(L, _, _, _, _, C),
    \+ ty_noun_class(L, C, _).
ty_missing(L, noun_form(M)) :-
    ty_noun_in(L, M, _, _, Sg, C),
    ty_noun_class(L, C, Es),
    \+ ty_class_form(Es, Sg, _).

%% A part of a conjugation: participle, or Tense(Number); a rule: base, a
%% list of endings, or a part the class has.
ty_part_ok(participle) :- !.
ty_part_ok(P) :-
    compound(P), P =.. [T, N],
    ty_values(tense, Ts), memberchk(T, Ts),
    ty_values(agreement, As), memberchk(N, As).

ty_rule_ok(base, _) :- !.
ty_rule_ok(Es, _) :- is_list(Es), !, forall(member(E, Es), ( nonvar(E), E = F-T, atom(F), atom(T) )).
ty_rule_ok(P, Ps) :- compound(P), memberchk(P-_, Ps).
ty_missing(L, bad(ty_before(L, W, Ps, F, J))) :-
    ty_before(L, W, Ps, F, J),
    \+ ( memberchk(J, [space, joined]), is_list(Ps),
         forall(( member(P, Ps), member(E, P) ),
                ( E == end ; atom_length(E, 1) ; ty_letters(L, E, _) )) ).
ty_missing(L, question(Kind, Level)) :-
    once(ty_question(L, _, _, _)),
    ty_values(question_kind, Ks), member(Kind, Ks),
    ty_values(question_level, Ls), member(Level, Ls),
    ( Level == copula -> ty_level_used(L, copula) ; true ),
    \+ ty_question(L, Kind, Level, _).
ty_missing(L, wh_place) :-
    once(ty_question(L, wh, _, _)),
    \+ ty_wh(L, _).
ty_missing(L, wh_word(M)) :-
    once(ty_question(L, wh, _, _)),
    ty_values(wh, Ms), member(M, Ms),
    \+ ty_wh_word(L, M, _).
ty_missing(L, bad(ty_question(L, K, Lv, R))) :-
    ty_question(L, K, Lv, R),
    \+ ( ty_values(question_kind, Ks), memberchk(K, Ks),
         ty_values(question_level, Ls), memberchk(Lv, Ls),
         ty_question_rule(R) ).
ty_missing(L, bad(ty_wh(L, P))) :-
    ty_wh(L, P),
    \+ ( ty_values(wh_place, Ps), memberchk(P, Ps) ).
ty_missing(L, bad(ty_sense(L, W, S, B, A))) :-
    ty_sense(L, W, S, B, A),
    \+ ( ty_has_sense(L, W, S),
         ty_pattern_items(B), ty_pattern_items(A) ).
ty_missing(L, bad(ty_complement(L, V, Ws))) :-
    ty_complement(L, V, Ws),
    \+ ( is_list(Ws), Ws \== [], ty_verb_meaning(L, V) ).
ty_missing(L, answer(K)) :-
    once(ty_answer(L, _, _)),
    member(K, [yes, no]),
    \+ ty_answer(L, K, _).
ty_missing(L, bad(ty_answer(L, K, Ws))) :-
    ty_answer(L, K, Ws),
    \+ ( ty_values(answer, Ks), memberchk(K, Ks), is_list(Ws), Ws \== [] ).
ty_missing(L, bad(ty_answer_system(L, S))) :-
    ty_answer_system(L, S),
    \+ ( ty_values(answer_system, Ss), memberchk(S, Ss) ).
ty_missing(L, bad(ty_negation_place(L, Ws, Pl))) :-
    ty_negation_place(L, Ws, Pl),
    \+ ( is_list(Ws), Ws \== [], ty_values(negation_place, Ps), memberchk(Pl, Ps) ).
ty_missing(L, bad(ty_complement_wh(L, R))) :-
    ty_complement_wh(L, R),
    \+ ( ty_values(complement_wh, Rs), memberchk(R, Rs) ).
ty_missing(L, relative_marker) :-
    once(ty_order(L, rel, _)),
    \+ ty_relative(L, _, _, _).
ty_missing(L, bad(ty_relative(L, R, Ws, Cs))) :-
    ty_relative(L, R, Ws, Cs),
    \+ ( ty_values(relative_role, Rs), memberchk(R, Rs),
         is_list(Ws), is_list(Cs) ).
ty_missing(L, bad(ty_gap(L, Pl, R))) :-
    ty_gap(L, Pl, R),
    \+ ( ty_values(gap_place, Ps), memberchk(Pl, Ps),
         ty_values(gap, Rs), memberchk(R, Rs),
         ( Pl == o -> memberchk(R, [gap, resumptive]) ; R \== gap ) ).
ty_missing(L, bad(ty_relative_pronoun(L, Ws, Cs))) :-
    ty_relative_pronoun(L, Ws, Cs),
    \+ ( is_list(Ws), Ws \== [], is_list(Cs) ).
ty_missing(L, bad(ty_resumptive(L, Ws, Cs))) :-
    ty_resumptive(L, Ws, Cs),
    \+ ( is_list(Ws), Ws \== [], is_list(Cs) ).
ty_missing(L, bad(ty_relative_after(L, P, R))) :-
    ty_relative_after(L, P, R),
    \+ ( ty_values(relative_after, Ps), memberchk(P, Ps), memberchk(R, [first, second]) ).
ty_missing(L, bad(ty_possessive(L, O, Ws, A))) :-
    ty_possessive(L, O, Ws, A),
    \+ ( typology_choices(poss, Os), memberchk(O, Os), is_list(Ws), memberchk(A, [keep, drop]) ).
ty_missing(L, bad(ty_relative_possessive(L, Ws, Cs))) :-
    ty_relative_possessive(L, Ws, Cs),
    \+ ( is_list(Ws), Ws \== [], is_list(Cs),
         forall(member(C, Cs), ( is_list(C) ; nonvar(C), C = head(H), is_list(H) )) ).
ty_missing(L, bad(ty_possessive_pronoun(L, Ws, A, B))) :-
    ty_possessive_pronoun(L, Ws, A, B),
    \+ ( is_list(Ws), Ws \== [], is_list(A), is_list(B) ).
ty_missing(L, bad(ty_pronoun(L, R, Ws, Cs))) :-
    ty_pronoun(L, R, Ws, Cs),
    \+ ( ty_values(pronoun_role, Rs), memberchk(R, Rs), is_list(Ws), Ws \== [],
         is_list(Cs), forall(member(C, Cs), ty_pron_condition(C)) ).
ty_missing(L, bad(ty_possessive_pronoun(L, Ws, A, B))) :-
    ty_possessive_pronoun(L, Ws, A, B),
    is_list(A), \+ forall(member(C, A), ty_pron_condition(C)).
ty_missing(L, bad(ty_pro_drop(L, Ps))) :-
    ty_pro_drop(L, Ps),
    \+ ( is_list(Ps), ty_values(person, Ks), forall(member(P, Ps), memberchk(P, Ks)) ).
ty_missing(L, bad(ty_clitic(L, R))) :-
    ty_clitic(L, R),
    R \== o.
ty_missing(L, bad(ty_verb_person(L, T, K, B, F, To))) :-
    ty_verb_person(L, T, K, B, F, To),
    \+ ( ( T == any ; ty_values(tense, Ts), memberchk(T, Ts) ),
         ty_values(agreement, As), memberchk(K, As), memberchk(B, As),
         atom(F), atom(To) ).
ty_missing(L, bad(ty_capital(L, W, C))) :-
    ty_capital(L, W, C),
    \+ ( atom(W), atom(C), downcase_atom(C, W) ).
ty_missing(L, bad(ty_answer_echo(L, R, W))) :-
    ty_answer_echo(L, R, W),
    \+ ( memberchk(R, [aux, verb]), memberchk(W, [keep, drop]) ).
ty_missing(L, bad(ty_adjective_before(L, A))) :-
    ty_adjective_before(L, A),
    \+ ty_adjective(L, A, _, _, _).
ty_missing(L, bad(ty_pronoun_gender(L, S))) :-
    ty_pronoun_gender(L, S),
    \+ memberchk(S, [grammatical, natural]).
ty_missing(L, bad(ty_inversion(L, J, JV))) :-
    ty_inversion(L, J, JV),
    \+ ( atom(J), atom(JV) ).
ty_missing(L, inversion) :-
    ty_question(L, _, _, invert(pronoun)),
    \+ ty_inversion(L, _, _).
ty_missing(L, bad(ty_wh_tonic(L, M, Ws))) :-
    ty_wh_tonic(L, M, Ws),
    \+ ( is_list(Ws), Ws \== [], ty_wh_word(L, M, _) ).
ty_missing(L, bad(ty_tense_form(L, T, N, P, Ws))) :-
    ty_tense_form(L, T, N, P, Ws),
    \+ ( ty_values(tense, Ts), memberchk(T, Ts),
         ( N == any ; ty_values(agreement, As), memberchk(N, As) ),
         memberchk(P, [pos, neg]), is_list(Ws), Ws \== [] ).
ty_missing(L, bad(ty_negative_article_roles(L, Rs))) :-
    ty_negative_article_roles(L, Rs),
    \+ ( is_list(Rs), Rs \== [], forall(member(R, Rs), memberchk(R, [s, o, p])),
         once(ty_negative_article(L, _, _, _, _)) ).
ty_missing(L, bad(ty_adjunct_front(L, K))) :-
    ty_adjunct_front(L, K), K \== v2.
ty_missing(L, bad(ty_object_front(L, K))) :-
    ty_object_front(L, K), K \== v2.
ty_missing(L, bad(ty_and(L, Ws))) :-
    ty_and(L, Ws),
    \+ ( is_list(Ws), Ws \== [], forall(member(W, Ws), atom(W)) ).
ty_missing(L, bad(ty_negative_article_keeps(L))) :-
    ty_negative_article_keeps(L),
    \+ once(ty_negative_article(L, _, _, _, _)).
ty_missing(L, bad(ty_tense_like(L, Lv, T, T1))) :-
    ty_tense_like(L, Lv, T, T1),
    \+ ( memberchk(Lv, [clause, copula, any]),
         ty_values(tense, Ts), memberchk(T, Ts), memberchk(T1, Ts), T \== T1,
         \+ ( ty_tense_like(L, Lv2, T1, _), ( Lv2 == any ; Lv == any ; Lv2 == Lv ) ) ).
ty_missing(L, bad(ty_participle_ending(L, G, N, F, T))) :-
    ty_participle_ending(L, G, N, F, T),
    \+ ( atom(F), atom(T), memberchk(N, [sg, pl]) ).
ty_missing(L, bad(ty_participle_agrees(L, W))) :-
    ty_participle_agrees(L, W),
    W \== clitic.
ty_missing(L, bad(ty_class_tense_form(L, C, T, N, P, Ws))) :-
    ty_class_tense_form(L, C, T, N, P, Ws),
    \+ ( atom(C), ty_values(tense, Ts), memberchk(T, Ts),
         ( N == any ; ty_values(agreement, As), memberchk(N, As) ),
         memberchk(P, [pos, neg]), is_list(Ws), Ws \== [] ).
ty_missing(L, bad(ty_polite(L, N, K))) :-
    ty_polite(L, N, K),
    \+ ( memberchk(N, [sg, pl]),
         memberchk(K, [sg, pl, sg(1), sg(2), pl(1), pl(2)]) ).
ty_missing(L, bad(ty_split_place(L, P))) :-
    ty_split_place(L, P), P \== end.
ty_missing(L, bad(ty_verb_last(L, P))) :-
    ty_verb_last(L, P), P \== rel.
ty_missing(L, bad(ty_copula_negation(L, Ws, Pl))) :-
    ty_copula_negation(L, Ws, Pl),
    \+ ( is_list(Ws), Ws \== [],
         ( memberchk(Pl, [start, end]) ; Pl = before(X), memberchk(X, [s, c, p])
         ; Pl = after(X), memberchk(X, [s, c, p]) ) ).
ty_missing(L, bad(ty_case_after(L, Ws, C))) :-
    ty_case_after(L, Ws, C),
    \+ ( is_list(Ws), Ws \== [], atom(C), ty_adposition_words(L, Ws) ).
ty_missing(L, bad(ty_article_case(L, D, G, N, C, W))) :-
    ty_article_case(L, D, G, N, C, W),
    \+ ( ty_values(definiteness, Ds), memberchk(D, Ds), memberchk(N, [sg, pl, any]),
         ty_case_known(L, C), atom(W) ).
ty_missing(L, bad(ty_noun_case(L, M, C, N, W))) :-
    ty_noun_case(L, M, C, N, W),
    \+ ( ty_noun(L, M, _, _, _, _), memberchk(N, [sg, pl]), ty_case_known(L, C), atom(W) ).
ty_missing(L, bad(ty_adjective_ending(L, D, C, G, N, E))) :-
    ty_adjective_ending(L, D, C, G, N, E),
    \+ ( ty_declension(L, _, D), ( C == any ; ty_case_known(L, C) ),
         memberchk(N, [sg, pl, any]), atom(E) ).
ty_missing(L, declension(Def)) :-
    once(ty_adjective_ending(L, _, _, _, _, _)),
    member(Def, [def, indef, which, none]),
    ( Def == which -> once(ty_article(L, which, _, _, _)) ; true ),
    \+ ty_declension(L, Def, _).
ty_missing(L, case_article(Def, C)) :-
    once(ty_case(L, _, _)),
    member(Def, [def, indef]),
    once(ty_article_case(L, Def, _, _, _, _)),
    ty_case(L, _, C),
    \+ ty_article_case(L, Def, _, _, C, _).

%% A case some row of the language names.
ty_case_known(L, C) :- ( ty_case(L, _, C) ; ty_case_after(L, _, C) ), !.

ty_adposition_words(L, Ws) :- ( ty_adposition(L, _, Ws) ; ty_complement(L, _, Ws) ), !.

%% A sense of its own (ty_meaning_sense/2) English has a row to write.
ty_missing(english, sense_word(S)) :-
    ty_meaning_sense(S, _),
    \+ ty_noun(english, S, _, _, _, _).
ty_missing(L, polite(N)) :-
    once(( ty_pronoun(L, _, _, Cs), member(C, Cs), memberchk(polite, C) )),
    member(N, [sg, pl]),
    \+ ty_polite(L, N, _).
ty_missing(L, verb_class(V, C)) :-
    ty_verb_class(L, V, C),
    \+ ty_class_tense_form(L, C, _, _, _, _).
ty_missing(L, clitic_pronoun) :-
    ty_clitic(L, o),
    \+ ty_pronoun(L, o, _, _).
ty_missing(L, relative_possessive) :-
    ty_gap(L, poss, moves),
    \+ ty_relative_possessive(L, _, _).
ty_missing(L, relative_pronoun) :-
    ty_gap(L, pp, moves),
    \+ ty_relative_pronoun(L, _, _).
ty_missing(L, resumptive_pronoun) :-
    ty_gap(L, _, resumptive),
    \+ ty_resumptive(L, _, _).
ty_missing(L, bad(ty_mark(L, R, Pl, W, Cs))) :-
    ty_mark(L, R, Pl, W, Cs),
    \+ ( ty_values(role, Rs), memberchk(R, Rs),
         ty_values(place, Ps), memberchk(Pl, Ps),
         is_list(Cs) ).

%% A core tense of every verb; a further one of a verb that has a form of it.
ty_tense_asked(L, V, T) :-
    (   ty_values(core_tense, Cs), memberchk(T, Cs) -> true
    ;   once(ty_verb_form(L, V, T, _, pos, _))
    ).

%% A pronoun's condition: a list of its person, number and kind.
ty_pron_condition(C) :-
    is_list(C),
    forall(member(X, C), memberchk(X, [1, 2, 3, polite, sg, pl, m, f, n])).

ty_question_rule(R) :- memberchk(R, [unchanged, front(all), front(first), invert(pronoun)]), !.
ty_question_rule(particle(W, P)) :- ( atom(W) ; is_list(W), W \== [] ), memberchk(P, [start, end]).

%% The clause and the noun phrase are every language's; the copula clause
%% and the adposition phrase only a language that has their words.
ty_level_used(_, clause).
ty_level_used(_, np).
ty_level_used(L, copula) :- once(ty_copula(L, _, _, _, _, _)).
ty_level_used(L, pp) :- once(ty_adposition(L, _, _)).
ty_level_used(L, rel) :- once(ty_relative(L, _, _, _)).

ty_verb_meaning(L, V) :- setof(V0, T^N^P^W^ty_verb(L, V0, T, N, P, W), Vs), member(V, Vs).
ty_adjective_meaning(L, A) :- setof(A0, G^N^W^ty_adjective(L, A0, G, N, W), As), member(A, As).
ty_gender(L, G) :- setof(G0, M^A^S^P^ty_noun(L, M, G0, A, S, P), Gs), member(G, Gs).

%% ---- reading and writing -------------------------------------------------------------

%% Reading undoes the writer's steps, each word back to the words it may
%% stand for -- a joined word split (`nell'acqua'), a contraction opened
%% (`nell'' is `in l''), a form taken back to its word (`l'' is `il' or
%% `la') -- parses those, and keeps a reading only where the writer writes
%% the very words read: `il avvocato', `a apple' and `in la casa' are not
%% read.
typology_read(L, Text, IR) :-
    typology_read(L, Text, IR, []).

typology_read(L, Text, IR, Topics) :-
    must_be(atom, L),
    must_be(list, Topics),
    ty_surface(Text, Mood, Open, Close, Surface0),
    ty_first_written(L, Text, Surface0, Surface),
    ty_marks_fit(L, Mood, Open, Close),
    ty_live_topics(L, Text, Surface),
    (   Mood == question
    ->  findall(C-IR0, ty_read_bases(L, Surface, Topics, Mood, IR0, C), All),
        ty_least(All, IRs),
        member(IR1, IRs)
    ;   ty_read_bases(L, Surface, Topics, Mood, IR1, _)
    ),
    ty_ir_out(IR1, IR).

%% The words as the tables have them, parsed in their context; C is the
%% reading's cost, how far its order is from the statement's (0 for a
%% statement).
ty_read_bases(L, Surface, Topics, Mood, IR0, C) :-
    ty_uncomma(L, Surface, T0),
    ty_unjoin(L, T0, T1),
    ty_uncontract(L, T1, T2),
    ty_unsound(L, T2, Bases),
    ty_sound_ok(L, Bases, Surface),
    ty_new_context(Bases, Topics, Context),
    b_setval('$ty_context', Context),
    b_setval('$ty_rel_open', f([])),
    ty_poss_flag(L, Bases),
    ty_parse_reset(L),
    ty_mood(Mood, L, IR0, C, Goal),
    phrase(Goal, Bases).

%% The writer writes the very words read; in a repair, a fault.
ty_sound_ok(L, Bases, Surface) :-
    ty_write_tokens(L, Bases, Again),
    (   Again == Surface -> true ; ty_fault(sound(Again)) ).

%% Of the readings Cost-IR, each that no reading of the same meanings
%% (`ty_ir_senses/2': `vede' as see and as view are two) is under, once.
ty_least(Pairs, Xs) :-
    Pairs \== [],
    findall(X, ( member(C-X, Pairs),
                 ty_ir_senses(X, Ms),
                 \+ ( member(C2-X2, Pairs), C2 < C, ty_ir_senses(X2, Ms) ) ), Xs0),
    list_to_set(Xs0, Xs).

ty_ir_senses(IR, Ms) :-
    findall(M, ty_ir_meaning(IR, M), Ms0),
    msort(Ms0, Ms).

typology_write(L, IR, Text) :-
    typology_write(L, IR, Text, []).

%% The first way to write the IR whose words, read in their context, give
%% the IR back.
typology_write(L, IR, Text, Topics) :-
    must_be(atom, L),
    must_be(list, Topics),
    ty_ir_in(IR, IR00),
    ty_ir_tenses(L, IR00, IR0),
    ( IR0 = question(_) -> Mood = question ; Mood = statement ),
    ty_mood(Mood, L, IR0, _, Goal),
    b_setval('$ty_context', none),
    ty_parse_reset(L),
    phrase(Goal, Tokens0),
    ty_reads_as(Mood, L, IR0, Tokens0, Topics), !,
    ty_write_tokens(L, Tokens0, Tokens),
    ty_text(L, Mood, Tokens, Text).

%% A TENSE WRITTEN AS ANOTHER (ty_tense_like/4): each clause's and each
%% copula's tense the language has no form of becomes the tense it is
%% written as (English imperfect past: Spanish `El niño veía al perro.' is
%% `The boy saw the dog.'), a clause's by its clause row, a copula's by its
%% copula row, else by its any row.
ty_ir_tenses(L, IR0, IR) :-
    (   '$ty_tlikes'(L) -> ty_ir_tw(IR0, L, IR) ; IR = IR0 ).

ty_ir_tw(X, L, Y) :- ( var(X) -> Y = X ; ty_ir_tw_(X, L, Y) ).

ty_ir_tw_(clause(V, T, P, S, O, Js), L, clause(V, T1, P, S1, O1, Js1)) :- !,
    ty_tense_as(L, clause, T, T1),
    ty_ir_tw(S, L, S1), ty_ir_tw(O, L, O1), ty_ir_tw_list(Js, L, Js1).
ty_ir_tw_(copula(T, P, S, Pr), L, copula(T1, P, S1, Pr1)) :- !,
    ty_tense_as(L, copula, T, T1),
    ty_ir_tw(S, L, S1), ty_ir_tw(Pr, L, Pr1).
ty_ir_tw_(question(C), L, question(C1)) :- !, ty_ir_tw(C, L, C1).
ty_ir_tw_(rel(NP, C), L, rel(NP1, C1)) :- !, ty_ir_tw(NP, L, NP1), ty_ir_tw(C, L, C1).
ty_ir_tw_(of(G, NP), L, of(G1, NP1)) :- !, ty_ir_tw(G, L, G1), ty_ir_tw(NP, L, NP1).
ty_ir_tw_(pp(M, NP), L, pp(M, NP1)) :- !, ty_ir_tw(NP, L, NP1).
ty_ir_tw_(answer(P, A, C), L, answer(P, A, C1)) :- !, ty_ir_tw(C, L, C1).
ty_ir_tw_(echo(C), L, echo(C1)) :- !, ty_ir_tw(C, L, C1).
ty_ir_tw_(X, _, X).

ty_ir_tw_list(Js, L, Js1) :-
    (   var(Js) -> Js1 = Js
    ;   Js = [J|Js0] -> Js1 = [J1|Js2], ty_ir_tw(J, L, J1), ty_ir_tw_list(Js0, L, Js2)
    ;   Js1 = Js
    ).

%% The tense a clause's or a copula's tense is written as: the rows
%% typology_load/1 keeps (`$ty_tlike'/4: a level's own row, else the any
%% row).
ty_tense_as(L, Level, T, T1) :-
    (   atom(T), '$ty_tlike'(L, Level, T, T2) -> T1 = T2 ; T1 = T ).

%% The words give the IR back, at a cost no other reading of them is under
%% (`Chi vide la ragazza?' is who saw the girl, so whom the girl saw is
%% written another way).
ty_reads_as(Mood, L, IR0, Tokens, Topics) :-
    ty_new_context(Tokens, Topics, Context),
    \+ \+ ( b_setval('$ty_context', Context),
           ty_parse_reset(L),
           b_setval('$ty_rel_open', f([])),
           ty_poss_flag(L, Tokens),
           aggregate_all(min(C), ( ty_mood(Mood, L, IR0, C, G), phrase(G, Tokens) ), C1),
           \+ ( C1 > 0,
                ty_ir_senses(IR0, Ms),
                ty_mood(Mood, L, IR2, C2, G2), phrase(G2, Tokens), C2 < C1,
                ty_ir_senses(IR2, Ms) ) ).

%% A statement is ty_sentence//2, at cost 0; a question ty_ask//3.
ty_mood(statement, L, IR, 0, ty_sentence(L, IR)).
ty_mood(question, L, IR, C, ty_ask(L, IR, C)).

%% A question's marks are the language's (ty_question_mark/3), a
%% statement has none at its front.
ty_marks_fit(L, question, Open, Close) :-
    ty_question_marks(L, Open, Close).
ty_marks_fit(_, statement, '', _).

ty_question_marks(L, Open, Close) :-
    (   ty_question_mark(L, O, C) -> Open = O, Close = C ; Open = '', Close = '?' ).

%% The writer's steps after the grammar: the forms the next word chooses
%% (a joined one marked j(Form)), the contractions (`in' and a joined `l''
%% are a joined `nell''), then each joined form written as one word with
%% the word after it.
ty_write_tokens(L, Tokens0, Tokens) :-
    ty_sound(L, Tokens0, T1),
    ty_contract(L, T1, T2),
    ty_join(T2, T3),
    (   ty_inversion(L, _, _) -> ty_join_inverted(T3, T4) ; T4 = T3 ),
    (   ( ty_relative_comma(L) ; memberchk(',', T4) )
    ->  ty_comma_mark(L, M), ty_comma_join(T4, M, Tokens)
    ;   Tokens = T4
    ).

%% A comma is written joined to the word before it, once; one at the end
%% is dropped (the full stop stands there).
ty_comma_join([], _, []).
ty_comma_join([','|Ws], M, Out) :- !, ty_comma_join(Ws, M, Out).
ty_comma_join([W, ','|Ws], M, Out) :- !,
    ty_commas_off(Ws, Ws1),
    (   Ws1 == [] -> Out = [W] ; atom_concat(W, M, WC), Out = [WC|Rest], ty_comma_join(Ws1, M, Rest) ).
ty_comma_join([W|Ws], M, [W|Rest]) :- ty_comma_join(Ws, M, Rest).

%% The language's comma (ty_comma/2: Persian `،'), `,' where it names none.
ty_comma_mark(L, M) :- ( ty_comma(L, M0) -> M = M0 ; M = ',' ).

ty_commas_off([','|Ws], Rest) :- !, ty_commas_off(Ws, Rest).
ty_commas_off(Ws, Ws).

%% Reading, a comma after a word is a word of its own, where the language
%% puts commas round a relative clause or the text has one and the
%% language joins adjectives (ty_and/2); an answer's word keeps its own
%% (`Ja, der Hund schläft.').
ty_uncomma(L, Ws, Out) :-
    (   ty_relative_comma(L) -> ty_comma_mark(L, M), ty_uncomma_words(L, M, Ws, Out)
    ;   ty_and(L, _), ty_comma_mark(L, M), ty_comma_in(Ws, M) -> ty_uncomma_words(L, M, Ws, Out)
    ;   Out = Ws
    ).

%% A word of the text ends in the comma M.
ty_comma_in(Ws, M) :- member(W, Ws), atom(W), W \== M, atom_concat(_, M, W), !.

ty_uncomma_words(_, _, [], []).
ty_uncomma_words(L, M, [W|Ws], Out) :-
    (   atom(W), atom_concat(W0, M, W), W0 \== '',
        \+ ( ty_answer(L, _, AWs), last(AWs, W0) )
    ->  Out = [W0, ','|Rest]
    ;   Out = [W|Rest]
    ),
    ty_uncomma_words(L, M, Ws, Rest).

%% clause/5 is a clause with no adjuncts: the grammar's clause/6 with [],
%% at every depth (a relative clause is a clause inside a noun phrase).
ty_ir_in(IR, IR1) :- ty_ir_map(in, IR, IR1).

ty_ir_out(IR, IR1) :- ty_ir_map(out, IR, IR1).

ty_ir_map(_, X, Y) :- var(X), !, Y = X.
ty_ir_map(in, clause(V, T, P, S, O), clause(V, T, P, S1, O1, [])) :- !,
    ty_ir_map(in, S, S1), ty_ir_map(in, O, O1).
ty_ir_map(out, clause(V, T, P, S, O, []), clause(V, T, P, S1, O1)) :- !,
    ty_ir_map(out, S, S1), ty_ir_map(out, O, O1).
ty_ir_map(D, clause(V, T, P, S, O, Js), clause(V, T, P, S1, O1, Js1)) :- !,
    ty_ir_map(D, S, S1), ty_ir_map(D, O, O1),
    maplist(ty_ir_map(D), Js, Js1).
ty_ir_map(D, question(C), question(C1)) :- !, ty_ir_map(D, C, C1).
ty_ir_map(D, copula(T, P, S, Pred), copula(T, P, S1, Pred1)) :- !,
    ty_ir_map(D, S, S1), ty_ir_map(D, Pred, Pred1).
ty_ir_map(D, rel(NP, C), rel(NP1, C1)) :- !,
    ty_ir_map(D, NP, NP1), ty_ir_map(D, C, C1).
ty_ir_map(D, of(G, NP), of(G1, NP1)) :- !, ty_ir_map(D, G, G1), ty_ir_map(D, NP, NP1).
ty_ir_map(D, pp(M, NP), pp(M, NP1)) :- !, ty_ir_map(D, NP, NP1).
ty_ir_map(D, answer(P, A, C), answer(P, A, C1)) :- !, ty_ir_map(D, C, C1).
ty_ir_map(D, echo(C), echo(C1)) :- !, ty_ir_map(D, C, C1).
ty_ir_map(_, X, X).

typology_translate(From, To, Text, Text2) :-
    once(typology_read(From, Text, IR)),
    typology_write(To, IR, Text2).

%% A text: each sentence read, and written, with the topics of the
%% sentences before it.
typology_read_text(L, Texts, IRs) :-
    must_be(list, Texts),
    ty_read_text(Texts, L, [], [], IRs).

ty_read_text([], _, _, _, []).
ty_read_text([T|Ts], L, Topics0, Prev, [IR|IRs]) :-
    once(findnsols(8, IR0, typology_read(L, T, IR0, Topics0), IRs0)),
    IRs0 = [_|_],
    ty_refer_best(IRs0, L, Prev, IR),
    ty_add_topics(IR, Topics0, Topics),
    ty_read_text(Ts, L, Topics, [IR|Prev], IRs).

%% THE NOUN A PRONOUN STANDS FOR. Of a sentence's first eight readings,
%% the one whose pronouns of the third person find the most nouns before
%% them (Persian `او' is he and she, two readings: the one the text's
%% girl fits), the first of a tie; each pronoun found takes the kind
%% ref(Meaning). A noun fits where its number is the pronoun's and the
%% kind the language's pronouns give it (ty_ref_kind/3) the pronoun's:
%% Spanish `la' is a feminine noun's, a house's too; English `it' a
%% thing's or an animal's. A pronoun looks in the sentences before it, the
%% latest first, the noun of its own role first (the subject's for a
%% subject); a possessive pronoun in its own sentence first (`El niño ve
%% a su perro.', his dog). A pronoun of the text stands for its noun to
%% the pronouns after it.
ty_refer_best(IRs0, L, Prev, IR) :-
    findall(C-I-R, ( nth1(I, IRs0, R0), ty_refer(L, R0, Prev, R, C) ), Scored),
    findall(K-R, ( member(C-I-R, Scored), K is -C * 100 + I ), Keyed),
    keysort(Keyed, [_-IR|_]).

ty_refer(L, IR0, Prev, IR, Count) :-
    nb_setval('$ty_refs', 0),
    ty_rf(IR0, x, L, IR0, Prev, IR),
    nb_getval('$ty_refs', Count).

ty_rf(X, _, _, _, _, X) :- var(X), !.
ty_rf(pron(3, N, K), Role, L, Whole, Prev, Out) :- !,
    (   \+ ( nonvar(K), K = ref(_) ),
        ty_antecedent(L, Role, N, K, Whole, Prev, M, N1)
    ->  Out = pron(3, N1, ref(M)),
        nb_getval('$ty_refs', C0), C1 is C0 + 1, nb_setval('$ty_refs', C1)
    ;   Out = pron(3, N, K)
    ).
ty_rf(clause(V, T, P, S, O), _, L, W, Pv, clause(V, T, P, S1, O1)) :- !,
    ty_rf(S, s, L, W, Pv, S1), ty_rf(O, o, L, W, Pv, O1).
ty_rf(clause(V, T, P, S, O, Js), _, L, W, Pv, clause(V, T, P, S1, O1, Js1)) :- !,
    ty_rf(S, s, L, W, Pv, S1), ty_rf(O, o, L, W, Pv, O1),
    maplist([J, J1]>>ty_rf(J, x, L, W, Pv, J1), Js, Js1).
ty_rf(copula(T, P, S, Pr), _, L, W, Pv, copula(T, P, S1, Pr1)) :- !,
    ty_rf(S, s, L, W, Pv, S1), ty_rf(Pr, x, L, W, Pv, Pr1).
ty_rf(of(G, NP), Role, L, W, Pv, of(G1, NP1)) :- !,
    ty_rf(G, poss(Role), L, W, Pv, G1), ty_rf(NP, Role, L, W, Pv, NP1).
ty_rf(X, _, L, W, Pv, X1) :-
    compound(X), !,
    X =.. [F|As],
    maplist([A, A1]>>ty_rf(A, x, L, W, Pv, A1), As, As1),
    X1 =.. [F|As1].
ty_rf(X, _, _, _, _, X).

ty_antecedent(L, Role, N, K, Whole, Prev, M, N1) :-
    ty_candidates(Role, Whole, Prev, Lists),
    member(Ms, Lists),
    member(_-M-N1, Ms),
    ( var(N) -> true ; N == N1 ),
    ( var(K) -> true ; ty_ref_kind(L, M, K0), K0 == K ), !.

%% The nouns a pronoun may stand for, a list a sentence: a possessive
%% pronoun's own sentence first, but for the phrase it stands in (`its
%% house' is no house's), the subject's first; then the sentences before,
%% the latest first, each with the noun of the pronoun's role first.
ty_candidates(poss(R0), Whole, Prev, [Here|Before]) :- !,
    findall(R-M-N, ( ty_mention(Whole, R, M, N), R \== R0 ), Here0),
    ty_role_first(Here0, s, Here),
    ty_candidates(s, Whole, Prev, Before).
ty_candidates(Role, _, Prev, Lists) :-
    findall(Ms, ( member(S, Prev),
                  findall(R-M-N, ty_mention(S, R, M, N), Ms0),
                  ty_role_first(Ms0, Role, Ms) ), Lists).

%% The nouns a sentence says, with their roles: the subject's, the
%% object's, then the others (x); a phrase's head before the nouns inside
%% it, and a pronoun of the text its noun.
ty_mention(clause(V, T, P, S, O), R, M, N) :- !, ty_mention(clause(V, T, P, S, O, []), R, M, N).
ty_mention(clause(_, _, _, S, O, Js), R, M, N) :- !,
    (   R = s, ty_np_mention(S, M, N)
    ;   R = o, ty_np_mention(O, M, N)
    ;   R = x, nonvar(Js), member(J, Js), ty_np_mention(J, M, N)
    ).
ty_mention(copula(_, _, S, Pr), R, M, N) :- !,
    (   R = s, ty_np_mention(S, M, N)
    ;   R = x, ty_np_mention(Pr, M, N)
    ).
ty_mention(question(C), R, M, N) :- !, ty_mention(C, R, M, N).
ty_mention(answer(_, _, C), R, M, N) :- !, ty_mention(C, R, M, N).

ty_np_mention(X, _, _) :- var(X), !, fail.
ty_np_mention(np(M, N, _, _), M, N).
ty_np_mention(pron(3, N, K), M, N) :- nonvar(K), K = ref(M).
ty_np_mention(rel(NP, C), M, N) :- ( ty_np_mention(NP, M, N) ; ty_mention(C, _, M, N) ).
ty_np_mention(of(G, NP), M, N) :- ( ty_np_mention(NP, M, N) ; ty_np_mention(G, M, N) ).
ty_np_mention(pp(_, NP), M, N) :- ty_np_mention(NP, M, N).

%% The mentions of Role first, the others after, each in its order.
ty_role_first(Ms, Role, Ordered) :-
    findall(X, ( member(X, Ms), X = Role-_-_ ), Same),
    findall(X, ( member(X, Ms), X \= Role-_-_ ), Others),
    append(Same, Others, Ordered).

typology_translate_text(From, To, Texts, Texts2) :-
    typology_read_text(From, Texts, IRs),
    ty_write_text(IRs, To, [], Texts2).

ty_write_text([], _, _, []).
ty_write_text([IR|IRs], L, Topics0, [T|Ts]) :-
    typology_write(L, IR, T, Topics0),
    ty_add_topics(IR, Topics0, Topics),
    ty_write_text(IRs, L, Topics, Ts).

ty_add_topics(IR, Topics0, Topics) :-
    typology_topics(IR, Ts),
    append(Topics0, Ts, Topics1),
    sort(Topics1, Topics).

%% The topics of the meanings in an IR: each noun, adjective, verb and
%% adverb, and the topics ty_topic/2 gives each.
typology_topics(IR, Topics) :-
    findall(T, ( ty_ir_meaning(IR, M), ty_meaning_topic(M, T) ), Ts),
    sort(Ts, Topics).

ty_ir_meaning(question(C), M) :- ty_ir_meaning(C, M).
ty_ir_meaning(answer(_, _, C), M) :- ty_ir_meaning(C, M).
ty_ir_meaning(echo(C), M) :- ty_ir_meaning(C, M).
ty_ir_meaning(clause(V, T, P, S, O), M) :-
    ty_ir_meaning(clause(V, T, P, S, O, []), M).
ty_ir_meaning(clause(V, _, _, S, O, Js), M) :-
    (   atom(V), M = V
    ;   ty_ir_meaning(S, M)
    ;   ty_ir_meaning(O, M)
    ;   member(J, Js), ty_ir_meaning(J, M)
    ).
ty_ir_meaning(copula(_, _, S, Pred), M) :-
    (   ty_ir_meaning(S, M)
    ;   ty_ir_meaning(Pred, M)
    ).
ty_ir_meaning(np(N, _, _, As), M) :-
    (   M = N
    ;   member(M, As)
    ).
ty_ir_meaning(adj(As), M) :- member(M, As).
ty_ir_meaning(pp(_, NP), M) :- ty_ir_meaning(NP, M).
ty_ir_meaning(rel(NP, C), M) :-
    (   ty_ir_meaning(NP, M)
    ;   ty_ir_meaning(C, M)
    ).
ty_ir_meaning(of(G, NP), M) :-
    (   ty_ir_meaning(G, M)
    ;   ty_ir_meaning(NP, M)
    ).
ty_ir_meaning(adv(M), M).

ty_meaning_topic(M, M).
ty_meaning_topic(M, T) :- ty_topic(M, T).
ty_meaning_topic(M, T) :- reason_live_topics(M, Ts), member(T, Ts).

%% LIVE MODE GIVES A MEANING THE TABLES GIVE NO TOPIC ITS TOPICS (reason.pl's
%% mode, library(reasoning/live)'s reason_live_topics/4): where a word of
%% the sentence has several meanings in one class, each meaning of the
%% sentence's words that has no topic and was never asked goes to the
%% model in ONE call, and the answer is kept as reason_live_topics(Meaning,
%% Topics), which a meaning's topics then include. Static mode, and live
%% mode's own reads, ask nothing.
ty_live_topics(L, Text, Surface) :-
    (   rv_live([]),
        ty_open_meanings(L, Surface, Ms),
        Ms \== [],
        setof(T, M^ty_topic(M, T), Known)
    ->  use_module(library(reasoning/live)),
        text_to_string(Text, S),
        reason_live_topics(L, S, Ms, Known)
    ;   true
    ).

%% Of the sentence's words, the meanings with no topic and never asked
%% (forty at most), where one of the words has several in one class; else
%% none.
ty_open_meanings(L, Surface, Ms) :-
    findall(W, ( ty_unjoin(L, Surface, T1), ty_uncontract(L, T1, T2),
                 ty_unsound(L, T2, Bases), member(W, Bases) ),
            Ws0),
    sort(Ws0, Ws),
    findall(Cs, ( member(W, Ws), member(C, [noun, adjective, verb, adverb]),
                  setof(M, ty_class_meaning(L, C, W, M), Cs) ),
            Groups),
    (   memberchk([_, _|_], Groups)
    ->  findall(M, ( member(Cs, Groups), member(M, Cs),
                     \+ ty_topic(M, _), \+ reason_live_topics(M, _) ),
                Ms0),
        sort(Ms0, Ms1),
        (   length(Ms1, N), N > 40 -> length(Ms, 40), append(Ms, _, Ms1) ; Ms = Ms1 )
    ;   Ms = []
    ).

%% The words of a sentence as written: the full stop off, the first word
%% lowered (a script with no capitals is unchanged).
ty_surface(Text, Mood, Open, Close, Words) :-
    ty_surface_written(Text, Mood, Open, Close, [FirstA|Rest1]),
    downcase_atom(FirstA, First),
    maplist(ty_lower_capital, Rest1, Rest),
    Words = [First|Rest].

%% The words as written, the marks off.
ty_surface_written(Text, Mood, Open, Close, Words) :-
    atom_string(A0, Text),
    ty_end_mark(A0, A1, Mood, Close),
    ty_open_mark(A1, A, Open),
    split_string(A, " ", " ", Parts0),
    exclude(==(""), Parts0, Parts),
    maplist([P, W]>>atom_string(W, P), Parts, Words).

%% THE FIRST WORD AS WRITTEN is read too, in a language whose nouns keep
%% their capital (ty_capital_nouns/1), where its tables hold it so: a noun
%% German writes with its capital (`Hunde schlafen.'), the
%% polite `Sie' (`Sie sehen den Hund.' is you or they).
ty_first_written(L, Text, [First|Rest], Words) :-
    (   ty_capital_nouns(L),
        ty_surface_written(Text, _, _, _, [FirstA|_]),
        FirstA \== First,
        ty_table_word(L, FirstA)
    ->  ( Words = [FirstA|Rest] ; Words = [First|Rest] )
    ;   Words = [First|Rest]
    ).

ty_table_word(L, W) :-
    once(( ty_noun(L, _, _, _, W, _) ; ty_noun(L, _, _, _, _, W)
         ; ty_noun_case(L, _, _, _, W)
         ; ty_pronoun(L, _, Ws, _), memberchk(W, Ws) )).

%% A word a template always writes with its capital (ty_capital/3: English
%% `I') is its table's word, read and written.
ty_lower_capital(W, W0) :- ( ty_capital(_, W1, W) -> W0 = W1 ; W0 = W ).

ty_capital_word(L, W, C) :- ( atom(W), ty_capital(L, W, C0) -> C = C0 ; C = W ).

%% The mark at the end: a full stop (or none) a statement, `?' or `؟' a
%% question; and the mark a question may open with (Spanish `¿').
ty_end_mark(A0, A, Mood, Close) :-
    (   sub_atom(A0, B, 1, 0, C), ty_end_mood(C, Mood0)
    ->  sub_atom(A0, 0, B, _, A), Mood = Mood0, Close = C
    ;   A = A0, Mood = statement, Close = ''
    ).

ty_end_mood('.', statement).
ty_end_mood('?', question).
ty_end_mood('؟', question).

ty_open_mark(A0, A, Open) :-
    (   sub_atom(A0, 0, 1, _, '¿') -> sub_atom(A0, 1, _, 0, A), Open = '¿' ; A = A0, Open = '' ).

%% ---- forms chosen by the next word's sound -----------------------------------
%%
%% ty_before(L, Word, Patterns, Form, Join): Word is written Form when the
%% next word begins with one of Patterns, the longest pattern of all the
%% word's rows winning (so `a uni...' keeps `a' where `a' + a vowel is
%% `an'). A pattern is a list of letters, ty_letters/3 classes and `end'
%% (the word ends there: `agua' and not `aguacate'). Join `joined' writes
%% the form and the next word as one (`l'avvocato').

ty_sound(_, [], []).
ty_sound(L, [W, N|Ws], [Out|Rest]) :-
    atom(W), atom(N),
    ty_sound_form(L, W, N, F, J), !,
    ( J == joined -> Out = j(F) ; Out = F ),
    ty_sound(L, [N|Ws], Rest).
ty_sound(L, [W|Ws], [W|Rest]) :-
    ty_sound(L, Ws, Rest).

ty_sound_form(L, W, Next, Form, Join) :-
    atom_chars(Next, Cs),
    findall(Len-(F-J), ( ty_before(L, W, Patterns, F, J),
                         member(P, Patterns),
                         ty_pattern(L, P, Cs),
                         length(P, Len) ), Fits),
    Fits \== [],
    keysort(Fits, Sorted),
    last(Sorted, _-(Form-Join)),
    Form \== W.

ty_pattern(_, [], _).
ty_pattern(_, [end], []) :- !.
ty_pattern(L, [E|Es], [C|Cs]) :-
    E \== end,
    (   atom_length(E, 1) -> E == C ; ty_letters(L, E, Ls), memberchk(C, Ls) ),
    ty_pattern(L, Es, Cs).

%% Each word as the word of the table it may stand for: itself, or the
%% word whose form it is.
ty_unsound(_, [], []).
ty_unsound(L, [T|Ts], [B|Bs]) :-
    (   B = T
    ;   setof(B0, P^J^ty_before(L, B0, P, T, J), B0s),
        member(B, B0s), B \== T
    ),
    ty_unsound(L, Ts, Bs).

%% A written word split where it begins with a joined form, or a contraction
%% of one (`nell'acqua': `nell'' and `acqua'), and a verb from the
%% pronoun joined after it (`n'a-t-il': `n'', `a' and `-t-il').
ty_unjoin(_, [], []).
ty_unjoin(L, [T|Ts], Out) :-
    (   Out = [T|Rest]
    ;   ty_joinable(L, F), atom_concat(F, W, T), W \== '',
        (   Out = [F, W|Rest]
        ;   ty_inverted_split(L, W, V, P),
            Out = [F, V, P|Rest]
        )
    ;   ty_inverted_split(L, T, V, P),
        Out = [V, P|Rest]
    ),
    ty_unjoin(L, Ts, Rest).

%% A verb and the subject pronoun joined to it (`voit-il': `voit' and
%% `-il'; `pense-t-il': `pense' and `-t-il'), in a language with
%% ty_inversion/3.
ty_inverted_split(L, T, V, P) :-
    ty_inversion(L, J, JV),
    sub_atom(T, B, 1, _, '-'), B > 0,
    sub_atom(T, 0, B, _, V),
    sub_atom(T, B, _, 0, P),
    ( atom_concat(J, W, P) ; atom_concat(JV, W, P) ),
    ty_pronoun(L, s, [W], _).

ty_joinable(L, F) :-
    setof(F0, ty_joinable0(L, F0), Fs),
    member(F, Fs).

ty_joinable0(L, F) :- ty_before(L, _, _, F, joined).
ty_joinable0(L, C) :-
    ty_contraction(L, Parts, C),
    last(Parts, P),
    ty_before(L, _, _, P, joined).

%% A contraction opened, or the word as it is.
ty_uncontract(_, [], []).
ty_uncontract(L, [T|Ts], Out) :-
    (   Out = [T|Rest]
    ;   ty_contraction(L, Parts, T), append(Parts, Rest, Out)
    ),
    ty_uncontract(L, Ts, Rest).

%% Two words written as one; a joined second word makes a joined one.
ty_contract(_, [], []).
%% A comma that opens a relative clause stops a contraction after it
%% (German `das Haus, in dem', where `in dem Haus' is `im Haus').
ty_contract(L, [',', A|Ws], [',', A|Rest]) :-
    ty_relative_comma(L), !,
    ty_contract(L, Ws, Rest).
ty_contract(L, [A, B|Ws], [C|Rest]) :-
    atom(A),
    ( B = j(B0) -> Joined = yes ; B0 = B, Joined = no ),
    atom(B0),
    ty_contraction(L, [A, B0], C0), !,
    ( Joined == yes -> C = j(C0) ; C = C0 ),
    ty_contract(L, Ws, Rest).
ty_contract(L, [W|Ws], [W|Rest]) :-
    ty_contract(L, Ws, Rest).

ty_join([], []).
ty_join([j(F), N|Ws], [FN|Rest]) :- !,
    atom_concat(F, N, FN),
    ty_join(Ws, Rest).
ty_join([j(F)], [F]) :- !.
ty_join([W|Ws], [W|Rest]) :-
    ty_join(Ws, Rest).

%% A token that begins with a hyphen (a subject pronoun after the verb,
%% `-il') is written joined to the word before it.
ty_join_inverted([], []).
ty_join_inverted([W, H|Ws], Out) :-
    ty_inverted_token(H), !,
    atom_concat(W, H, WH),
    ty_join_inverted([WH|Ws], Out).
ty_join_inverted([W|Ws], [W|Out]) :-
    ty_join_inverted(Ws, Out).

ty_inverted_token(H) :-
    atom(H), sub_atom(H, 0, 1, _, '-'), atom_length(H, N), N > 1.

ty_text(L, Mood, Tokens, Text) :-
    maplist(ty_capital_word(L), Tokens, Tokens1),
    atomic_list_concat(Tokens1, ' ', Body),
    sub_atom(Body, 0, 1, _, F),
    sub_atom(Body, 1, _, 0, R),
    upcase_atom(F, U),
    (   Mood == question
    ->  ty_question_marks(L, Open, Close)
    ;   Open = '', Close = '.'
    ),
    atomic_list_concat([Open, U, R, Close], Text).

%% ---- the meaning of a word with several -----------------------------------------
%%
%% The context of a read, ctx(Id, Words, Given): the words read and the
%% topics given. A writer's first parse has none, and its check the words
%% it wrote; ty_meant//3 asks it after each word the grammar takes. What a
%% check works out for a word is kept under the context's Id (ty_memo/4,
%% in a global, not the knowledge base), so a parse that takes the same
%% word many times as it backtracks works it out once.

ty_new_context(Words, Given, ctx(Id, Words, Given)) :-
    (   nb_current('$ty_context_n', N0) -> true ; N0 = 0 ),
    Id is N0 + 1,
    nb_setval('$ty_context_n', Id).

ty_memo(ctx(Id, _, _), Key, Value, Goal) :-
    (   nb_current('$ty_memo', memo(Id, A0)) -> true ; empty_assoc(A0) ),
    (   get_assoc(Key, A0, V0)
    ->  Value = V0
    ;   once(Goal),
        put_assoc(Key, A0, Value, A1),
        nb_setval('$ty_memo', memo(Id, A1))
    ).

%% The meanings of a word in one class, looked up by the word (a linked
%% Persian form by the word it is a form of: before an adjective, or as
%% the last word of a relative clause's head).
ty_class_meaning(L, noun, W, M) :-
    ty_base_word(L, n, W, W0),
    ( ty_noun(L, M, _, _, W0, _) ; ty_noun(L, M, _, _, _, W0) ; ty_noun_case(L, M, _, _, W0) ).
ty_class_meaning(L, adjective, W, M) :-
    ty_base_word(L, a, W, W0),
    ty_adjective(L, M, _, _, W0).
ty_class_meaning(L, adjective, W, M) :-
    ty_adjective_ending(L, _, _, _, _, E), E \== '',
    atom_concat(W0, E, W),
    ty_adjective(L, M, _, _, W0).
ty_class_meaning(L, verb, W, M) :-
    (   atom(W), '$ty_vfirst_made'(L) -> '$ty_vfirst'(W, L, M) ; ty_verb(L, M, _, _, _, [W|_]) ).
ty_class_meaning(L, adverb, W, M) :- ty_adverb(L, M, W).
ty_class_meaning(L, adposition, W, M) :- ty_adposition(L, M, Ws), memberchk(W, Ws).

%% Ws, just taken (the words S follow), in the meaning Sense.
ty_meant(L, Sense, Ws, S, S) :-
    (   nb_current('$ty_context', Ctx), Ctx = ctx(_, Full, _)
    ->  length(Full, NF), length(Ws, NW), length(S, NS),
        NP is NF - NW - NS,
        length(Prefix, NP), append(Prefix, _, Full),
        reverse(Prefix, Back),
        ty_meant_each(Ws, Back, S, L, Sense, Ctx)
    ;   true
    ).

ty_meant_each([], _, _, _, _, _).
ty_meant_each([W|Ws], Back, S, L, Sense, Ctx) :-
    append(Ws, S, Ahead),
    ty_meaning_here(L, W, Sense, Back, Ahead, Ctx),
    ty_meant_each(Ws, [W|Back], S, L, Sense, Ctx).

%% The first row of the word that fits the words around it decides; with
%% none, the topics.
ty_meaning_here(L, W, Sense, Back, Ahead, Ctx) :-
    length(Back, Pos),
    ty_memo(Ctx, p(Pos, W), Fit, ty_sense_fit(L, W, Back, Ahead, Fit)),
    (   Fit = sense(Sense1)
    ->  Sense1 = Sense
    ;   Sense =.. [C, M],
        ty_memo(Ctx, t(W, C), Best, ty_topic_best(L, W, C, Ctx, Best)),
        ( Best == all -> true ; memberchk(M, Best) )
    ).

ty_sense_fit(L, W, Back, Ahead, Fit) :-
    (   ty_sense(L, W, Sense, B, A),
        ty_pattern_fits(L, B, Back),
        ty_pattern_fits(L, A, Ahead)
    ->  Fit = sense(Sense)
    ;   Fit = none
    ).

ty_pattern_fits(_, [], _).
ty_pattern_fits(L, [I|Is], Ws) :-
    (   nonvar(I), I = opt(I1)
    ->  (   Ws = [W|Ws1], ty_item_fits(L, I1, W), ty_pattern_fits(L, Is, Ws1)
        ;   ty_pattern_fits(L, Is, Ws)
        )
    ;   Ws = [W|Ws1],
        ty_item_fits(L, I, W),
        ty_pattern_fits(L, Is, Ws1)
    ).

ty_item_fits(_, I, _) :- var(I), !.
ty_item_fits(_, I, W) :- atom(I), !, I == W.
ty_item_fits(L, class(C), W) :- !, ty_word_class(L, C, W).
ty_item_fits(L, class(noun, F), W) :-
    ( ty_noun(L, _, G, A, W, _) ; ty_noun(L, _, G, A, _, W) ),
    ( F == G ; F == A ; F == animate, A == person ), !.

ty_word_class(L, noun, W) :- ty_class_meaning(L, noun, W, _), !.
ty_word_class(L, adjective, W) :- ty_class_meaning(L, adjective, W, _), !.
ty_word_class(L, verb, W) :-
    (   ty_class_meaning(L, verb, W, _)
    ;   ty_negation(L, _, _, Ws, _), memberchk(W, Ws)
    ), !.
ty_word_class(L, article, W) :- ty_article(L, _, _, _, W), !.
ty_word_class(L, mark, W) :- ty_mark(L, _, _, W, _), !.
ty_word_class(L, adposition, W) :- ty_class_meaning(L, adposition, W, _), !.
ty_word_class(L, adverb, W) :- ty_adverb(L, _, W), !.
ty_word_class(L, copula, W) :- '$ty_cword'(L, W, _), !.
ty_word_class(L, relative, W) :- ty_relative(L, _, Ws, _), memberchk(W, Ws), !.
ty_word_class(L, possessive, W) :- ty_possessive_pronoun(L, Ws, _, _), memberchk(W, Ws), !.

%% Of the word's meanings in class C, the ones whose topics the context
%% has the most of; all when the context has none of any.
ty_topic_best(L, W, C, Ctx, Best) :-
    (   setof(M1, ty_class_meaning(L, C, W, M1), Ms),
        Ms = [_, _|_],
        findall(N-M1, ( member(M1, Ms), ty_topic_count(L, W, M1, Ctx, N) ), Pairs),
        max_member(Max-_, Pairs),
        Max > 0
    ->  findall(M1, member(Max-M1, Pairs), Best)
    ;   Best = all
    ).

ty_topic_count(L, W, M, Ctx, N) :-
    findall(T, ( ty_meaning_topic(M, T), ty_context_has(L, W, T, Ctx) ), Ts),
    length(Ts, N).

%% The context has a topic when it was given, or when another word of the
%% sentence, with one meaning in its class, has it (`saw' is no context of
%% its own: the noun, a tool, would choose the verb `to saw'). The words
%% are found from the topic, by meaning, and not each word of the sentence
%% by its form: a table of thousands of verbs is not walked for every word
%% read.
ty_context_has(_, _, T, ctx(_, _, Given)) :- memberchk(T, Given), !.
ty_context_has(L, W, T, ctx(_, Words, _)) :-
    ty_topic_meaning(T, M),
    ty_meaning_word(L, M, C, W1),
    W1 \== W,
    memberchk(W1, Words),
    setof(M1, ty_class_meaning(L, C, W1, M1), [M]), !.

ty_topic_meaning(T, T).
ty_topic_meaning(T, M) :- ty_topic(M, T).
ty_topic_meaning(T, M) :- reason_live_topics(M, Ts), memberchk(T, Ts).

ty_meaning_word(L, M, noun, W) :- ty_noun(L, M, _, _, S, P), ( W = S ; W = P ).
ty_meaning_word(L, M, adjective, W) :- ty_adjective(L, M, _, _, W).
ty_meaning_word(L, M, verb, W) :- ty_verb(L, M, _, _, _, [W|_]).
ty_meaning_word(L, M, adverb, W) :- ty_adverb(L, M, W).

%% The check's view of a ty_sense/5 row: the word has the sense, and each
%% pattern is a list of items.
ty_has_sense(L, W, mark(R)) :- !, ty_mark(L, R, _, W, _), !.
ty_has_sense(L, W, copula(K)) :- !, '$ty_cword'(L, W, K), !.
ty_has_sense(L, W, S) :-
    compound(S), S =.. [C, M],
    memberchk(C, [noun, adjective, verb, adverb, adposition]),
    ty_class_meaning(L, C, W, M), !.

ty_pattern_items(P) :-
    is_list(P),
    forall(member(I, P), ty_pattern_item(I)).

ty_pattern_item(I) :- var(I), !.
ty_pattern_item(I) :- atom(I), !.
ty_pattern_item(opt(I)) :- !, ty_pattern_item(I).
ty_pattern_item(class(C)) :- !,
    memberchk(C, [noun, adjective, verb, article, mark, adposition, adverb, copula,
                  relative, possessive]).
ty_pattern_item(class(noun, F)) :- atom(F).

%% ---- the grammar ---------------------------------------------------------------------

%% ---- repair: a sentence the template does not allow --------------------------------
%%
%% The template's checks are where the reader refuses a sentence: an
%% order, an agreement, a mark, a form the next word chooses, a question's
%% order or its marks. In a repair each of them has a second road, taken
%% only where the first fails, that reads on and notes a FAULT; the reader
%% allows one fault, then two, then three (`$ty_fault_max'), keeps the
%% readings with the fewest (and of those the least costly), and the
%% writer writes each IR as the template has it:
%%
%%     ?- typology_repair(spanish, 'Los perro ven al gato.', IR, Fs, T).
%%     Fs = [agreement(noun, perro)], T = 'Los perros ven al gato.'
%%
%% One fault rather than two (the article and the verb, `El perro ve al
%% gato.') is the repair that changes the least. A word no table has is
%% not repaired: the repair fails at once.

typology_repair(L, Text, IR, Repairs, Fixed) :-
    must_be(atom, L),
    (   typology_read(L, Text, _)
    ->  typology_read(L, Text, IR), Repairs = [], Fixed = Text
    ;   ty_surface(Text, _, _, _, Surface),
        ty_known_words(L, Surface),
        ty_repairs(L, Text, Surface, Best),
        member(Fixed-(IR-Repairs), Best)
    ).

%% The readings of the fewest faults, written, and ranked: the faults
%% weighed (a clause's order and a mood are 2: `What the boy sees?' is
%% `What does the boy see?', a question's order, not `What sees the boy?',
%% the clause's), then the question's cost, then the most words of the
%% sentence kept (`La niña pequeña duerme.', not `El niño pequeño
%% duerme.', where `niña' is a child); one repair a text.
ty_repairs(L, Text, Surface, Best) :-
    ty_surface(Text, Mood0, Open, Close, _),
    between(1, 3, Max),
    findall(C-(IR-Fs), ty_lenient_read(L, Surface, Mood0, Open, Close, Max, IR, Fs, _, C), All),
    All \== [], !,
    findall(k(W, C, NK)-(Fixed-(IR-Fs)),
            ( member(C-(IR-Fs), All),
              typology_write(L, IR, Fixed),
              ty_faults_weight(Fs, W),
              ty_surface(Fixed, _, _, _, FixedWords),
              ty_kept(FixedWords, Surface, 0, K), NK is -K ), Keyed),
    keysort(Keyed, [Key-_|_]),
    findall(X, member(Key-X, Keyed), Xs),
    ty_one_a_text(Xs, [], Best).

ty_faults_weight(Fs, W) :-
    foldl([F, W0, W1]>>( ty_fault_weight(F, X), W1 is W0 + X ), Fs, 0, W).

ty_fault_weight(order(clause, _), 2) :- !.
ty_fault_weight(mood(_), 2) :- !.
ty_fault_weight(_, 1).

%% The words of Fixed that the sentence has (each once).
ty_kept([], _, K, K).
ty_kept([W|Ws], Have, K0, K) :-
    (   selectchk(W, Have, Rest) -> K1 is K0 + 1 ; Rest = Have, K1 = K0 ),
    ty_kept(Ws, Rest, K1, K).

ty_one_a_text([], _, []).
ty_one_a_text([F-X|Xs], Seen, Best) :-
    (   memberchk(F, Seen)
    ->  Best = Rest
    ;   Best = [F-X|Rest]
    ),
    ty_one_a_text(Xs, [F|Seen], Rest).

%% Every word is one the tables have, as some reading of it takes it apart
%% (`nell'acqua' is `in', `l'' and `acqua'): a word no table has is no
%% repair to search for.
ty_known_words(L, Surface) :-
    forall(member(W, Surface), ty_known_token(L, W)).

ty_known_token(L, W) :-
    ty_unjoin(L, [W], T1),
    ty_uncontract(L, T1, T2),
    ty_unsound(L, T2, Bs),
    forall(member(B, Bs), ty_known_base(L, B)), !.

ty_known_base(L, B) :-
    (   member(C, [noun, adjective, verb, article, mark, adposition, adverb, copula]),
        ty_word_class(L, C, B)
    ;   ty_wh_word(L, _, Ws), memberchk(B, Ws)
    ;   ty_question_form(L, _, _, Ws, _), memberchk(B, Ws)
    ;   ty_question(L, _, _, particle(B, _))
    ;   ty_question(L, _, _, particle(Ws, _)), is_list(Ws), memberchk(B, Ws)
    ;   ty_wh_tonic(L, _, Ws), memberchk(B, Ws)
    ;   ty_inversion(L, J, JV), ( atom_concat(J, W, B) ; atom_concat(JV, W, B) ),
        ty_pronoun(L, s, [W], _)
    ;   ty_relative(L, _, Ws, _), memberchk(B, Ws)
    ;   ty_relative_pronoun(L, Ws, _), memberchk(B, Ws)
    ;   ty_resumptive(L, Ws, _), memberchk(B, Ws)
    ;   ty_possessive(L, _, Ws, _), memberchk(B, Ws)
    ;   ty_relative_possessive(L, Ws, _), memberchk(B, Ws)
    ;   ty_possessive_pronoun(L, Ws, _, _), memberchk(B, Ws)
    ;   ty_pronoun(L, _, Ws, _), memberchk(B, Ws)
    ;   ty_complement(L, _, Ws), memberchk(B, Ws)
    ;   ty_negation_place(L, Ws, _), memberchk(B, Ws)
    ;   ty_answer(L, _, Ws), ( memberchk(B, Ws) ; last(Ws, W), ty_answer_comma(L, M), atom_concat(W, M, B) )
    ;   ty_verb(L, _, _, _, _, Ws), memberchk(B, Ws)
    ), !.

ty_lenient_read(L, Surface, Mood0, Open, Close, Max, IR, Fs, N, C) :-
    b_setval('$ty_lenient', yes),
    b_setval('$ty_fault_max', Max),
    b_setval('$ty_faults', f([])),
    ty_lenient_mood(L, Mood0, Open, Close, Mood),
    ty_read_bases(L, Surface, [], Mood, IR0, C),
    b_getval('$ty_faults', f(Fs0)),
    reverse(Fs0, Fs),
    length(Fs, N),
    ty_ir_out(IR0, IR).

%% The mood the marks say, its marks a fault where they are not the
%% language's (`El niño ve al perro?'); or the other mood, a fault
%% (`El niño ve qué.', `Does the boy see the dog.').
ty_lenient_mood(L, Mood0, Open, Close, Mood) :-
    (   Mood = Mood0,
        (   ty_marks_fit(L, Mood, Open, Close) -> true ; ty_fault(marks(Mood)) )
    ;   ty_other_mood(Mood0, Mood),
        ty_fault(mood(Mood))
    ).

ty_other_mood(statement, question).
ty_other_mood(question, statement).

ty_lenient :- nb_current('$ty_lenient', yes).

%% A fault noted, while the budget lasts. The list is kept inside f/1:
%% cocolog 3.72.0's b_getval/2 of an atomic value (`[]') hands back the
%% global's own cell, and a b_setval/2 of [F|Fs] over it made a cycle.
ty_fault(F) :-
    ty_lenient,
    b_getval('$ty_faults', f(Fs)),
    b_getval('$ty_fault_max', Max),
    length(Fs, K), K < Max,
    b_setval('$ty_faults', f([F|Fs])).

%% An order the template keeps, or in a repair any other, a fault.
ty_order_at(L, Level, Order) :-
    (   ty_order(L, Level, Order)
    ;   ty_lenient,
        typology_choices(Level, Os), member(Order, Os),
        \+ ty_order(L, Level, Order),
        ty_fault(order(Level, Order))
    ).

ty_question_at(L, Kind, Level, Rule) :-
    (   ty_question(L, Kind, Level, Rule)
    ;   ty_lenient,
        member(Rule, [unchanged, front(all), front(first)]),
        \+ ty_question(L, Kind, Level, Rule),
        ty_fault(question(Kind, Level, Rule))
    ).

ty_wh_at(L, Place) :-
    (   ty_wh(L, Place)
    ;   ty_lenient,
        ty_values(wh_place, Ps), member(Place, Ps),
        Place \== all_front,
        \+ ty_wh(L, Place),
        ty_fault(wh_place(Place))
    ).

%% ---- questions ---------------------------------------------------------------------
%%
%% A question is a clause or a copula clause in an order its kind's rule
%% makes from the statement's (ty_question/4): a yes or no question as the
%% rule says; a question word moved to the front (ty_wh/2) and the rule on
%% the rest, unless it is the subject (`Who sees the dog?'). The parts are
%% the statement's, and f (front(first): the verb's first word) and q (a
%% particle). The kind and the place of the question word are chosen
%% first, and the IR is checked last: a yes or no question has no question
%% word, a question with one has one.

ty_ask(L, question(C), Cost) --> ty_ask_clause(L, C, Cost).
ty_ask(L, question(C), Cost) --> ty_ask_copula(L, C, Cost).

ty_ask_clause(L, C, Cost) -->
    { C = clause(_, _, _, _, O, Js),
      b_setval('$ty_front', f(none)),
      ty_order_at(L, clause, Order0),
      ty_valency(Order0, O, Order1),
      ty_adjunct_order(L, Order1, Js, Order2),
      ty_ask_kind(C, Kind, Part),
      Q = q(_, _, _, _, _),
      ty_ask_order(L, Kind, Part, clause, Order2, Order, Q),
      ty_order_cost(Order, Order2, Cost),
      C = clause(_, _, P, _, _, _),
      ty_neg_clause(L, C, Order, Order3a),
      Q = q(QRule, _, _, _, _),
      ty_verb_split(L, C, QRule, Order3a, Order3) },
    ty_extraposed(L, o, O, Order3, Order4),
    { C = clause(_, _, _, S, _, _) },
    ty_extraposed(L, s, S, Order4, Order5),
    { ty_lead(Order5) },
    ty_ask_parts(Order5, L, C, Q, How),
    { ty_wh_count(C, Kind),
      ty_wh_first(C, Part),
      ty_roles_ok(L, C),
      ty_object_ok(L, C, How),
      ty_comp_wh_ok(L, Order, C, How),
      ty_front_ok(C),
      ty_split_kept(L, C, QRule, Order5),
      ty_kein_ok(L) }.

ty_ask_copula(L, C, Cost) -->
    { C = copula(_, _, _, Pred),
      b_setval('$ty_front', f(none)),
      ty_order_at(L, copula, Order0),
      ty_ask_kind(C, Kind, Part),
      Q = q(_, _, _, Features, Rows),
      ty_ask_order(L, Kind, Part, copula, Order0, OrderA, Q),
      ty_order_cost(OrderA, Order0, Cost),
      C = copula(_, P, _, _),
      ty_copula_neg_order(L, C, OrderA, OrderB0),
      ty_copula_split(L, C, OrderB0, OrderB) },
    ty_extraposed(L, p, Pred, OrderB, Order1),
    { C = copula(_, _, S, _) },
    ty_extraposed(L, s, S, Order1, Order2),
    { ty_lead(Order2) },
    ty_ask_parts(Order2, L, C, Q, _),
    { Features = [_, N, _, G],
      ty_predicate_ok(Pred, Rows, G, N),
      ty_wh_count(C, Kind),
      ty_wh_first(C, Part),
      ty_front_ok(C),
      ty_kein_ok(L) }.

%% A question's cost: the pairs of the statement's parts it puts the other
%% way round. Of several readings the reader keeps the least costly, so
%% the part after an SVO verb is its object (`Chi vede il ragazzo?' is who
%% sees the boy, at 0, not whom the boy sees, at 3); a tie keeps both.
ty_order_cost(Order, Base, Cost) :-
    ty_shared_parts(Order, Base, Shared),
    ty_inversions(Shared, Base, 0, Cost).

ty_shared_parts([], _, []).
ty_shared_parts([P|Ps], Base, Shared) :-
    (   memberchk(P, Base) -> Shared = [P|Rest] ; Shared = Rest ),
    ty_shared_parts(Ps, Base, Rest).

ty_inversions([], _, C, C).
ty_inversions([P|Ps], Base, C0, C) :-
    nth0(I, Base, P), !,
    findall(x, ( member(Q, Ps), nth0(J, Base, Q), J < I ), Xs),
    length(Xs, K),
    C1 is C0 + K,
    ty_inversions(Ps, Base, C1, C).

%% The kind, and the part whose question word moves. A question word is
%% wh(M); a noun phrase whose article is `which' (np(dog, sg, which, []):
%% `Which dog does the boy see?'); or the one adjunct, a wh(M) or an
%% adposition phrase of such a noun phrase (`In which house does the dog
%% sleep?'). Of several, the subject's moves, else the object's, else the
%% adjunct's, and the others stay in place (`Who sees what?'); reading,
%% an object or an adjunct after the one that moves may be a question word
%% too, and ty_wh_first/2 holds the order at the end.
ty_ask_kind(clause(_, _, _, S, O, Js), Kind, Part) :-
    (   Kind = yes_no, Part = none
    ;   Kind = wh, Part = s, ty_asked(S), ty_maybe_wh(O), ty_maybe_wh_js(Js)
    ;   Kind = wh, Part = o, ty_asked(O), ty_maybe_wh_js(Js)
    ;   Kind = wh, Part = j, ty_asked_js(Js)
    ).
ty_ask_kind(copula(_, _, S, P), Kind, Part) :-
    (   Kind = yes_no, Part = none
    ;   Kind = wh, Part = s, ty_asked(S), ty_maybe_wh(P)
    ;   Kind = wh, Part = p, P = wh(_)
    ).

ty_asked(X) :- ( X = wh(_) ; X = np(_, _, which, _) ).

ty_asked_js([J]) :- ( J = wh(_) ; J = pp(_, np(_, _, which, _)) ).

%% Reading, a question word in place is bound before it is read; a noun
%% phrase of `which' needs nothing (its article says it).
ty_maybe_wh(X) :- ( var(X) -> ( X = wh(_) ; true ) ; true ).

ty_maybe_wh_js(Js) :- ( var(Js) -> ( Js = [wh(_)] ; true ) ; true ).

ty_wh_count(C, Kind) :-
    findall(x, ty_wh_in(C), Xs),
    length(Xs, N),
    ( Kind == yes_no -> N =:= 0 ; N >= 1 ).

ty_wh_in(clause(_, _, _, S, O, Js)) :-
    ( ty_is_asked(S) ; ty_is_asked(O) ; member(J, Js), ty_is_asked_j(J) ).
ty_wh_in(copula(_, _, S, P)) :- ( ty_is_asked(S) ; ty_is_asked(P) ).

ty_is_asked(X) :- nonvar(X), ( X = wh(_) ; X = np(_, _, D, _), D == which ).

ty_is_asked_j(J) :- nonvar(J), ( J = wh(_) ; J = pp(_, NP), ty_is_asked(NP) ).

%% The question word that moved is the first of the subject, the object
%% and the adjunct that holds one.
ty_wh_first(clause(_, _, _, S, O, _), Part) :-
    (   Part == o -> \+ ty_is_asked(S)
    ;   Part == j -> \+ ty_is_asked(S), \+ ty_is_asked(O)
    ;   true
    ).
ty_wh_first(copula(_, _, S, _), Part) :-
    (   Part == p -> \+ ty_is_asked(S) ; true ).

%% The order of a question; Q = q(Rule, Moved, VerbWords, Features, Rows),
%% Moved yes where the rule moved the verb.
%% EVERY QUESTION WORD AT THE FRONT (ty_wh(L, all_front): Bulgarian `Кой
%% какво вижда?', who what sees): the first part holding one, then each
%% part after it in the order s, o, j (s, p of a copula) that holds one, and
%% the rule on the rest (none where the subject is asked). Reading, any of
%% the later parts may stand there; the parts at the front are kept
%% (`$ty_front') and held to the IR at the end (ty_front_ok/1).
ty_ask_order(L, wh, Part, Level, Order0, Order, q(Rule, Moved, _, _, _)) :-
    ty_wh(L, all_front), !,
    ty_later_parts(Part, Level, Order0, Later),
    ty_some(Later, More),
    Front = [Part|More],
    b_setval('$ty_front', f(Front)),
    subtract(Order0, Front, Rest),
    (   Part == s
    ->  Rule = unchanged, Moved = no, Rest1 = Rest
    ;   ty_question_at(L, wh, Level, Rule),
        ty_ask_rule(Rule, Level, Rest, Rest1, Moved)
    ),
    append(Front, Rest1, Order).
ty_ask_order(L, wh, s, _, Order0, Order, q(unchanged, no, _, _, _)) :- !,
    (   ty_wh(L, front) -> ty_put_first(s, Order0, Order) ; Order = Order0 ).
%% A question word that is a complement's noun phrase goes to the front
%% without its adposition where the adposition stays (ty_complement_wh/2):
%% the front takes ow, the object's place keeps op (`What does the boy
%% think about?'). It is tried first, and op reads only a complement.
ty_ask_order(L, wh, o, clause, Order0, Order, q(Rule, Moved, _, _, _)) :-
    ty_strand_at(L),
    ty_wh_at(L, front),
    once(append(A, [o|B], Order0)),
    append(A, [ow, op|B], Order1),
    ty_wh_order(front, L, ow, clause, Order1, Order, Rule, Moved).
ty_ask_order(L, wh, Part, Level, Order0, Order, q(Rule, Moved, _, _, _)) :- !,
    ty_wh_at(L, Place),
    ty_wh_order(Place, L, Part, Level, Order0, Order, Rule, Moved).
ty_ask_order(L, yes_no, _, Level, Order0, Order, q(Rule, Moved, _, _, _)) :-
    ty_question_at(L, yes_no, Level, Rule),
    ty_ask_rule(Rule, Level, Order0, Order, Moved).

%% The adposition stays where the template says so; in a repair, where it
%% says it moves, a fault.
ty_strand_at(L) :-
    (   ty_comp_rule(L, stays)
    ->  true
    ;   ty_lenient, ty_fault(complement_wh(stays))
    ).

%% A complement moved to the front with its question word (`¿En qué piensa
%% el niño?') is the template's only where its adposition moves; in a
%% repair, a fault (`About what does the boy think?' is `What does the boy
%% think about?').
ty_comp_wh_ok(L, Order, clause(_, _, _, _, O, _), How) :-
    (   nonvar(How), How = comp(_), nonvar(O), O = wh(_), Order = [o|_],
        \+ ty_comp_rule(L, moves)
    ->  ty_lenient, ty_fault(complement_wh(moves))
    ;   true
    ).

%% Where a question word stands: at the front, the rule on the rest; in
%% place, the statement's order kept (French `La fille vit qui ?', Persian;
%% 1.36.0: through 1.35.0 the rule moved the verb there too); or right after the subject, nothing else moved (Italian `La
%% ragazza chi vide?', whom the girl saw, where `Chi vide la ragazza?'
%% would be who saw her).
ty_wh_order(front, L, Part, Level, Order0, [Part|Rest1], Rule, Moved) :-
    ty_question_at(L, wh, Level, Rule),
    once(select(Part, Order0, Rest)),
    ty_ask_rule(Rule, Level, Rest, Rest1, Moved).
ty_wh_order(in_place, _, _, _, Order, Order, unchanged, no).
ty_wh_order(after(s), _, Part, _, Order0, Order, unchanged, no) :-
    once(select(Part, Order0, Rest)),
    once(append(A, [s|B], Rest)),
    append(A, [s, Part|B], Order).

ty_put_first(P, Order0, [P|Rest]) :- select(P, Order0, Rest), !.

%% The parts after Part that a question word may stand in, of those the
%% order has.
ty_later_parts(Part, Level, Order0, Later) :-
    ( Level == clause -> All = [s, o, j] ; All = [s, p] ),
    append(_, [Part|After], All), !,
    include([P]>>memberchk(P, Order0), After, Later).

ty_some([], []).
ty_some([X|Xs], [X|Ys]) :- ty_some(Xs, Ys).
ty_some([_|Xs], Ys) :- ty_some(Xs, Ys).

%% The parts at the front are the parts that hold a question word.
ty_front_ok(C) :-
    b_getval('$ty_front', f(Front)),
    (   Front == none
    ->  true
    ;   forall(ty_wh_part(C, P, Asked), ( memberchk(P, Front) -> Asked == yes ; Asked == no ))
    ).

ty_wh_part(clause(_, _, _, S, O, Js), P, A) :-
    (   P = s, ty_yes(ty_is_asked(S), A)
    ;   P = o, ty_yes(ty_is_asked(O), A)
    ;   P = j, ty_yes(( nonvar(Js), member(J, Js), ty_is_asked_j(J) ), A)
    ).
ty_wh_part(copula(_, _, S, Pr), P, A) :-
    (   P = s, ty_yes(ty_is_asked(S), A)
    ;   P = p, ty_yes(ty_is_asked(Pr), A)
    ).

ty_yes(G, A) :- ( call(G) -> A = yes ; A = no ).

ty_ask_rule(unchanged, _, O, O, no).
ty_ask_rule(particle(_, start), _, O, [q|O], no).
ty_ask_rule(particle(_, end), _, O, O1, no) :- append(O, [q], O1).
ty_ask_rule(front(all), Level, O, O1, yes) :-
    ty_head(Level, H),
    select(H, O, O2), !,
    ty_before_subject(H, O2, O1).
ty_ask_rule(front(first), _, O, O1, yes) :-
    ty_before_subject(f, O, O1).
ty_ask_rule(invert(pronoun), _, O, O, no).

ty_head(clause, v).
ty_head(copula, c).

ty_before_subject(X, O, O1) :-
    append(A, [s|B], O), !,
    append(A, [X, s|B], O1).

ty_ask_parts([], _, _, _, _) --> [].
ty_ask_parts([P|Ps], L, C, Q, How) --> ty_ask_part(P, L, C, Q, How), ty_ask_parts(Ps, L, C, Q, How).

ty_ask_part(s, L, clause(_, _, _, S, _, _), q(R, _, _, _, _), _) -->
    { ty_inv_on(L, R) }, !,
    ty_inv_subject(R, L, S, _).
ty_ask_part(s, L, copula(_, _, S, _), q(R, _, _, F, _), _) -->
    { ty_inv_on(L, R) }, !,
    ty_inv_subject(R, L, S, F).
ty_ask_part(s, L, clause(_, _, _, S, _, _), _, _) --> ty_role(L, s, S).
ty_ask_part(s, L, copula(_, _, S, _), q(_, _, _, F, _), _) --> ty_role(L, s, S, F).
ty_ask_part(o, L, clause(V, _, _, _, O, _), _, How) --> ty_object(L, V, O, How).
%% A question word moved without its complement's adposition (ow), and the
%% adposition left in the object's place (op): `What does the boy think
%% about?'.
ty_ask_part(ow, L, clause(_, _, _, _, O, _), _, _) --> { nonvar(O), O = wh(M) }, ty_wh_words(L, M, clitic).
ty_ask_part(op, L, clause(V, _, _, _, _, _), _, comp(Ws)) -->
    { ty_complement_words(L, V, Ws) },
    ty_tokens(Ws).
ty_ask_part(j, L, clause(_, _, _, _, _, Js), _, _) --> ty_adjuncts(L, Js).
ty_ask_part(p, L, copula(_, _, _, Pred), q(_, _, _, _, R), _) --> ty_predicate(L, Pred, R).
ty_ask_part(v, L, C, Q, _) --> ty_ask_verb(L, C, Q), { Q = q(_, _, VW, _, _) }, ty_ask_inv(L, C, Q, VW).
ty_ask_part(c, L, C, Q, _) --> ty_ask_verb(L, C, Q), { Q = q(_, _, VW, _, _) }, ty_ask_inv(L, C, Q, VW).
ty_ask_part(vf(R), L, C, Q, _) --> ty_split_first(R, L, C, Q).
ty_ask_part(vr(R), L, C, Q, _) --> ty_split_rest(R, L, C, Q).
ty_ask_part(f, L, C, Q, _) --> ty_ask_first(L, C, Q).
ty_ask_part(q, _, _, q(particle(W, _), _, _, _, _), _) --> { atom(W) -> Ws = [W] ; Ws = W }, ty_tokens(Ws).
ty_ask_part(n(Ws), _, _, _, _) --> ty_tokens(Ws).
ty_ask_part(oh(X), L, clause(V, _, _, _, O, _), _, How) --> ty_object_head(L, V, O, How, X).
ty_ask_part(ot(X), L, _, _, _) --> ty_rel_tail(L, X).
ty_ask_part(ph(X), L, copula(_, _, _, Pred), q(_, _, _, _, []), _) --> ty_predicate_head(L, Pred, X).
ty_ask_part(pt(X), L, _, _, _) --> ty_rel_tail(L, X).
ty_ask_part(sh(X), L, clause(_, _, _, S, _, _), _, _) --> ty_subject_head(L, S, X).
ty_ask_part(sh(X), L, copula(_, _, S, _), q(_, _, _, F, _), _) -->
    { X = x(_, F, _) }, ty_subject_head(L, S, X).
ty_ask_part(st(X), L, _, _, _) --> ty_rel_tail(L, X).

%% The verb (or the copula). Under front(first) part f, before the
%% subject, is its first word and this part the rest: writing, f looks the
%% words up; reading, this part does, once it has the rest.
ty_ask_verb(L, C, q(Rule, Moved, VW, _, _), S0, S) :-
    ty_ask_subject(C, Subj),
    b_setval('$ty_csubj', Subj),
    (   Rule == front(first)
    ->  (   var(S0)
        ->  VW = [_|Rest], append(Rest, S, S0)
        ;   between(0, 3, K), length(Rest, K), append(Rest, S, S0),
            VW = [_|Rest],
            ty_ask_words(L, C, Moved, VW)
        )
    ;   (   var(S0)
        ->  ty_ask_words(L, C, Moved, Ws), append(Ws, S, S0)
        ;   ty_ask_min(C, Min), between(Min, 4, K), length(Ws, K), append(Ws, S, S0),
            ty_ask_words(L, C, Moved, Ws)
        ),
        VW = Ws,
        ty_ask_meant(L, C, Ws, S)
    ).

ty_ask_first(L, C, q(_, Moved, VW, _, _), S0, S) :-
    (   var(S0)
    ->  ty_ask_words(L, C, Moved, VW), VW = [W1|_], S0 = [W1|S]
    ;   S0 = [W1|S], VW = [W1|_]
    ).

ty_ask_min(clause(_, _, _, _, _, _), 1).
ty_ask_min(copula(_, _, _, _), 0).

ty_ask_meant(L, clause(V, _, _, _, _, _), Ws, S) :- !, ty_meant(L, verb(V), Ws, S, S).
ty_ask_meant(_, _, _, _).

%% INVERSION (ty_inversion/3: French). Under the rule invert(pronoun) a
%% pronoun of the subject follows the verb, joined to it: a copy of a noun
%% phrase subject, which keeps its place (`Le garçon voit-il le chien?'),
%% or a pronoun subject itself, which then stands nowhere else (`Voit-il
%% le chien?'). Under front(all), the verb before the subject, a pronoun
%% subject is so joined (`Que voit-il?'), a noun phrase is not (`Que voit
%% le garçon?'). The pronoun is part of the verb's part, so the negation
%% stands round both (`Ne voit-il pas le chien?') and an object clitic
%% before them (`Le garçon le voit-il?').
ty_inv_on(L, R) :- ( R == invert(pronoun) ; R == front(all) ), ty_inversion(L, _, _), !.

%% The subject's part: nothing for a pronoun the verb took; else a noun
%% phrase. Reading under invert(pronoun) the part may be empty, and the
%% pronoun after the verb is then the subject.
ty_inv_subject(_, _, S, _) --> { ty_is_pron(S) }, !.
ty_inv_subject(R, _, S, _) --> { R == invert(pronoun), var(S), S = pron(_, _, _) }.
ty_inv_subject(_, L, S, F) --> ty_role(L, s, S, F), { \+ ty_is_pron(S) }.

ty_is_pron(S) :- nonvar(S), S = pron(_, _, _).

%% After the verb's words, the joined pronoun the rule asks for; a copula
%% whose subject is that pronoun takes the pronoun's features.
ty_ask_inv(L, C, q(R, _, _, F, _), VW) -->
    (   { ty_inv_on(L, R) }
    ->  { ty_ask_subject(C, S) },
        ty_inv_tail(R, L, S, VW),
        { (   C = copula(_, _, _, _), ty_is_pron(S)
          ->  ty_pron_np_features(L, S, F)
          ;   true
          ) }
    ;   []
    ).

ty_ask_subject(clause(_, _, _, S, _, _), S).
ty_ask_subject(copula(_, _, S, _), S).

ty_inv_tail(invert(pronoun), L, S, VW) --> ty_inv_token(L, S, VW).
ty_inv_tail(front(all), L, S, VW) -->
    (   { var(S) } -> ( ty_inv_token(L, S, VW) ; [] )
    ;   { ty_is_pron(S) } -> ty_inv_token(L, S, VW)
    ;   []
    ).

ty_inv_token(L, S, VW) --> [T], { ty_inv_word(L, S, VW, T) }.

%% The token: the join (ty_inv_join/6) and the subject pronoun's word, for
%% a pronoun subject its own, for a noun phrase the one of its number and
%% the kind the language's pronouns give its noun (`la maison' is `elle').
ty_inv_word(L, S, VW, T) :-
    ty_inversion(L, J, JV),
    (   atom(T)
    ->  atom_concat(J0, W, T), memberchk(J0, [J, JV]),
        ty_inv_pron(L, S, W),
        ty_inv_join(L, J, JV, VW, W, J1), J1 == J0
    ;   ty_inv_pron(L, S, W),
        ty_inv_join(L, J, JV, VW, W, J0),
        atom_concat(J0, W, T)
    ).

ty_inv_pron(L, S, W) :-
    (   var(S) -> S = pron(_, _, _) ; true ),
    (   S = pron(_, _, _)
    ->  ty_pron_words(L, s, S, [W])
    ;   ty_head_np(S, np(M, N, _, _)),
        ty_ref_kind(L, M, K),
        ty_pron_words(L, s, pron(3, N, K), [W])
    ).

ty_head_np(NP, NP) :- NP = np(_, _, _, _).
ty_head_np(rel(NP, _), H) :- ty_head_np(NP, H).
ty_head_np(of(_, NP), H) :- ty_head_np(NP, H).

%% VowelJoin where the verb's last word ends in a vowel and the pronoun
%% begins with one (`pense-t-il'), else Join (`voit-il', `pense-je').
ty_inv_join(L, J, JV, VW, W, J0) :-
    (   is_list(VW), last(VW, V), atom(V),
        ty_letters(L, vowel, Vs),
        sub_atom(V, _, 1, 0, E), memberchk(E, Vs),
        sub_atom(W, 0, 1, _, B), memberchk(B, Vs)
    ->  J0 = JV
    ;   J0 = J
    ).

ty_ask_words(L, clause(V, T, P, Subj, O, _), Moved, Ws) :-
    ty_subject_number(Subj, N),
    ty_verb_polarity(L, P, VP),
    (   \+ ty_clitic_pron(L, V, O),
        ty_ask_verb_form(L, V, T, N, VP, Moved, Ws)
    ;   ty_clitic_slot(L, O),
        ty_clitic_verb(L, V, T, N, VP, O, _, Ws, [])
    ).
ty_ask_words(L, copula(T, P, Subj, Pred), _, Ws) :-
    ty_subject_number(Subj, N),
    ty_predicate_kind(Pred, K),
    ty_copula_polarity(L, P, CP),
    ty_copula_lookup(L, K, _, T, N, CP, Ws).

%% The key a verb agrees with: a noun phrase's number, a question word's
%% (sg), a relative clause's head's, a gap's head's, a pronoun's person and
%% number (ty_agreement/3). A gap and a question word are only where
%% something put them.
ty_subject_number(np(_, N, _, _), N).
ty_subject_number(W, sg) :- nonvar(W), W = wh(_).
ty_subject_number(G, N) :- nonvar(G), G = gap(H, _, _), ty_subject_number(H, N).
ty_subject_number(rel(np(_, N, _, _), _), N).
ty_subject_number(of(_, np(_, N, _, _)), N).
ty_subject_number(pron(P, N0, _), N) :- ty_agreement(P, N0, N).

%% A verb the rule moved, in a language with question forms, is the
%% question form if positive (`does see') and its negative if negative
%% (`does not see', of which f takes `does'); a tense made of words is its
%% own form, whose first word moves (`Will the boy see the dog?').
ty_ask_verb_form(L, V, T, N, P, Moved, Ws) :-
    (   ty_ask_verb_strict(L, V, T, N, P, Moved, Ws)
    *-> true
    ;   ty_lenient,
        (   nonvar(N), ty_other_number(N, N1),
            ty_ask_verb_strict(L, V, T, N1, P, Moved, Ws),
            ty_fault(agreement(verb, Ws))
        ;   Moved == yes, once(ty_question_form(L, _, _, _, _)),
            P = pos, ty_verb_form(L, V, T, N, pos, Ws),
            ty_fault(question_form(Ws))
        )
    ).

ty_ask_verb_strict(L, V, T, N, P, Moved, Ws) :-
    (   Moved == yes, once(ty_question_form(L, _, _, _, _))
    ->  (   P = pos, ty_question_verb(L, V, T, N, Ws)
        ;   P = neg, ty_verb_form(L, V, T, N, neg, Ws), \+ ty_tense_made(L, T)
        ;   ty_verb_form(L, V, T, N, P, Ws), ty_tense_made(L, T)
        )
    ;   ty_verb_form(L, V, T, N, P, Ws)
    ).

ty_question_verb(L, V, T, N, Words) :-
    ty_person_form(L, T, N, ty_question_verb_n(L, V, T), Words).

ty_question_verb_n(L, V, T, N, Words) :-
    ty_question_form(L, T0, N0, Aux, form(T1, N1)),
    append(Aux, Pos, Words),
    ty_verb_row(L, V, T1, N1, pos, Pos),
    ty_tense_fit(T0, T),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N).

%% A question word's words, and the features its marks ask for.
ty_wh_words(L, M) --> ty_wh_words(L, M, clitic).

%% Form clitic: the question word as it opens the clause (French `que');
%% tonic: after an adposition and in place, the language's ty_wh_tonic/3
%% form where it has one (`quoi').
ty_wh_words(L, M, Form) --> ty_words(1, 3, Ws, ty_wh_form(L, M, Form, Ws)).

%% In a language with cases a question word of ty_wh_case/4 rows takes the
%% phrase's case (German `wer', `wen', `wem').
ty_wh_form(L, M, Form, Ws) :-
    (   '$ty_cased'(L)
    ->  ty_case_now(L, C),
        (   ty_wh_case(L, M, C1, Ws), ty_case_fits(C1, C)
        ;   ty_wh_plain(L, M, Form, Ws), \+ ty_wh_case(L, M, _, _)
        )
    ;   ty_wh_plain(L, M, Form, Ws)
    ).

ty_wh_plain(L, M, clitic, Ws) :- ty_wh_word(L, M, Ws).
ty_wh_plain(L, M, tonic, Ws) :-
    (   ty_wh_tonic(L, M, Ws)
    ;   ty_wh_word(L, M, Ws), \+ ty_wh_tonic(L, M, _)
    ).

%% The part a question opens with (`$ty_lead'): a question word in the
%% role that opens it takes the clitic form, elsewhere the tonic.
ty_lead(Order) :- ( Order = [P|_] -> b_setval('$ty_lead', P) ; b_setval('$ty_lead', none) ).

ty_wh_role_form(Role, Form) :-
    (   nb_current('$ty_lead', P), P == Role -> Form = clitic ; Form = tonic ).


ty_wh_features(who, [def, sg, person]).
ty_wh_features(what, [indef, sg, inanimate]).

%% ---- statements ---------------------------------------------------------------------

%% A statement has no question word.
ty_sentence(L, IR) --> ty_clause(L, IR), { ty_wh_count(IR, yes_no) }.
ty_sentence(L, IR) --> ty_copula_clause(L, IR), { ty_wh_count(IR, yes_no) }.
ty_sentence(L, IR) --> ty_answer(L, IR).

%% ---- the answer to a yes or no question -----------------------------------------
%%
%% answer(Polarity, Asked): the answer `yes' (pos) or `no' (neg) to a
%% question of the polarity Asked; answer(Polarity, Asked, Clause) is the
%% answer with its clause after it, the clause of that polarity (`Yes, the
%% boy sees the dog.', `No, the boy does not see the dog.'). Its word is a
%% ty_answer/3 row chosen by the language's system (ty_answer_system/2):
%%   polarity (the default) -- `yes' for pos, `no' for neg; after a
%%     negative question a positive answer takes the `contradict' row
%%     where there is one (Persian `چرا', as French `si', German `doch');
%%   agreement -- `yes' where the answer agrees with the question, `no'
%%     where it does not (Japanese `hai' to `Doesn't he see the dog?' is
%%     he does not).
%% The word before a clause takes the language's comma (ty_answer_mark/2;
%% `,' where no row says).
ty_answer(L, answer(Pol, Asked)) -->
    { ty_answer_words(L, Pol, Asked, Ws) },
    ty_tokens(Ws).
ty_answer(L, answer(Pol, Asked, C)) -->
    { ty_answer_words(L, Pol, Asked, Ws0),
      append(Ws1, [W], Ws0),
      ty_answer_comma(L, M), atom_concat(W, M, WM),
      append(Ws1, [WM], Ws) },
    ty_tokens(Ws),
    ty_answer_clause(L, Pol, C).

%% THE ECHO: answer(Polarity, Asked, echo(Clause)) repeats the question's
%% clause short, as ty_answer_echo(L, Rule, Word) says: Rule aux, the
%% subject and the auxiliary of the clause's tense and person or the
%% copula (English `Yes, he does.', `No, I am not.'), or verb, the clause
%% with no object and no adjunct (Persian `بله، می‌بینم.', Portuguese
%% `Vejo.'); Word keep, the yes or no word before it, or drop. A copula
%% clause's echo is its subject and its copula by either rule (`Yes, she
%% is.', `بله، هستم.'). The echo's
%% object is none and its adjuncts []; reading an aux echo leaves its verb
%% unbound (`Yes, he does.' says no verb).
ty_answer(L, answer(Pol, Asked, echo(C))) -->
    { ty_answer_echo(L, Rule, Word),
      ty_answer_words(L, Pol, Asked, Ws0) },
    ty_echo_word(Word, L, Ws0),
    ty_echo(Rule, L, Pol, C).

ty_echo_word(drop, _, _) --> [].
ty_echo_word(keep, L, Ws0) -->
    { append(Ws1, [W], Ws0),
      ty_answer_comma(L, M), atom_concat(W, M, WM),
      append(Ws1, [WM], Ws) },
    ty_tokens(Ws).

ty_echo(aux, L, Pol, clause(_, T, Pol, S, none, [])) -->
    ty_role(L, s, S),
    { ty_subject_number(S, N) },
    ty_words(1, 3, Ws, ty_echo_aux(L, T, N, Pol, Ws)).
ty_echo(Rule, L, Pol, copula(T, Pol, S, Pred)) -->
    ty_role(L, s, S, _),
    { ty_subject_number(S, N),
      ( nonvar(Pred) -> ty_predicate_kind(Pred, K) ; true ) },
    ty_words(1, 4, Ws, ty_echo_copula(Rule, L, K, T, N, Pol, Ws)).

%% By the rule aux a copula of two words is its words but the last (`Yes, it
%% will.', `No, it has not.'); else the whole copula.
ty_echo_copula(Rule, L, K, T, N, P, Ws) :-
    ty_copula_lookup(L, K, _, T, N, P, Full),
    (   Rule == aux, ty_copula_two(L, T)
    ->  append(Ws, [_], Full), Ws \== []
    ;   Ws = Full
    ).
ty_echo(verb, L, Pol, C) -->
    { C = clause(_, _, Pol, _, none, []) },
    ty_clause(L, C).

%% The auxiliary of a tense and a person: the question form's words if
%% positive (`does'), the negation's if negative (`does not'); of a tense
%% made of words, the words before its verb (`will', `has not').
ty_echo_aux(L, T, N, P, Ws) :-
    ty_person_form(L, T, N, ty_echo_aux_n(L, T, P), Ws).

ty_echo_aux_n(L, T, pos, N, Ws) :-
    ty_question_form(L, T0, N0, Ws, _),
    ty_tense_fit(T0, T),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N).
ty_echo_aux_n(L, T, neg, N, Ws) :-
    ty_negation(L, T0, N0, Ws, form(_, _)),
    ty_tense_fit(T0, T),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N).
ty_echo_aux_n(L, T, P, N, Ws) :-
    ty_tense_form(L, T, N0, P, Pattern),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N),
    once(( append(Ws, [I|_], Pattern), ( I = form(_, _) ; I == participle ) )),
    Ws \== [].

ty_answer_clause(L, Pol, C) -->
    { C = clause(_, _, Pol, _, _, _) }, ty_clause(L, C), { ty_wh_count(C, yes_no) }.
ty_answer_clause(L, Pol, C) -->
    { C = copula(_, Pol, _, _) }, ty_copula_clause(L, C), { ty_wh_count(C, yes_no) }.

ty_answer_words(L, Pol, Asked, Ws) :-
    ty_values(polarity, Ps),
    member(Pol, Ps), member(Asked, Ps),
    ty_answer_kind(L, Pol, Asked, Kind),
    ty_answer(L, Kind, Ws).

ty_answer_kind(L, Pol, Asked, Kind) :-
    (   ty_answer_system(L, agreement)
    ->  ( Pol == Asked -> Kind = yes ; Kind = no )
    ;   Pol == neg
    ->  Kind = no
    ;   Asked == neg, once(ty_answer(L, contradict, _))
    ->  Kind = contradict
    ;   Kind = yes
    ).

ty_answer_comma(L, M) :-
    (   ty_answer_mark(L, M0) -> M = M0 ; M = ',' ).

%% The short answer to a yes or no question, in its polarity.
typology_answer(L, Question, Pol, Text) :-
    must_be(atom, L),
    ty_ir_in(Question, question(C)),
    ( C = clause(_, _, Asked, _, _, _) -> true ; C = copula(_, Asked, _, _) ),
    ty_wh_count(C, yes_no),
    typology_write(L, answer(Pol, Asked), Text).

%% The answer in a Form: word (`Yes.'), clause (`Yes, the boy sees the
%% dog.') or echo (`Yes, he does.': the clause short, its subject as the
%% one who answers says it).
typology_answer(L, Question, Pol, Form, Text) :-
    must_be(atom, L),
    ty_ir_in(Question, question(C)),
    ( C = clause(_, _, Asked, _, _, _) -> true ; C = copula(_, Asked, _, _) ),
    ty_wh_count(C, yes_no),
    ty_values(polarity, Ps), memberchk(Pol, Ps),
    ty_answer_ir(Form, Pol, Asked, C, IR),
    typology_write(L, IR, Text).

ty_answer_ir(word, Pol, Asked, _, answer(Pol, Asked)).
ty_answer_ir(clause, Pol, Asked, C, answer(Pol, Asked, C1)) :- ty_with_polarity(C, Pol, C1).
ty_answer_ir(echo, Pol, Asked, C, answer(Pol, Asked, echo(E))) :- ty_echo_of(C, Pol, E).

ty_with_polarity(clause(V, T, _, S, O, Js), P, clause(V, T, P, S, O, Js)).
ty_with_polarity(copula(T, _, S, Pr), P, copula(T, P, S, Pr)).

ty_echo_of(clause(V, T, _, S, _, _), P, clause(V, T, P, S1, none, [])) :- ty_answerer(S, S1).
ty_echo_of(copula(T, _, S, Pr), P, copula(T, P, S1, Pr)) :- ty_answerer(S, S1).

%% The subject as the one who answers says it: you is I, I is you, a noun
%% phrase its pronoun, of the kind its meaning has (ty_meaning_kind/2).
ty_answerer(pron(1, N, K), pron(2, N, K)) :- !.
ty_answerer(pron(2, N, K), pron(1, N, K)) :- !.
ty_answerer(pron(polite, N, K), pron(1, N, K)) :- !.
ty_answerer(pron(3, N, K), pron(3, N, K)) :- !.
ty_answerer(X, pron(3, N, K)) :-
    ty_np_head(X, M, N),
    ty_meaning_kind(M, K).

%% The noun phrase that heads a phrase: itself, a relative clause's head,
%% the possessed.
ty_np_head(np(M, N, _, _), M, N).
ty_np_head(rel(NP, _), M, N) :- ty_np_head(NP, M, N).
ty_np_head(of(_, NP), M, N) :- ty_np_head(NP, M, N).

%% THE KIND OF A MEANING, a pronoun's that stands for it: templates/roles.pl's
%% ty_kind/2 (`girl' f, `boy' m); a person of no row m, any other n (`it').
ty_meaning_kind(M, K) :-
    (   ty_kind(M, K0) -> K = K0
    ;   once(ty_noun(_, M, _, person, _, _)) -> K = m
    ;   K = n
    ).

%% A verb clause: its order of s, v and o, with the adjuncts (j) put where
%% the template says (ty_adjunct/2); a language with no such row has none.
ty_clause(L, C) -->
    ty_peek(First),
    { C = clause(_, _, P, S, O, Js),
      ty_order_at(L, clause, Order0),
      ty_valency(Order0, O, Order1),
      ty_clause_adjuncts(L, First, Order1, Js, Order2),
      ty_clause_object_front(L, First, Order2, Order2o),
      ty_neg_clause(L, C, Order2o, Order3a),
      ty_verb_final(L, v, Order3a, Order3b),
      ty_verb_split(L, C, none, Order3b, Order3) },
    ty_extraposed(L, o, O, Order3, Order4),
    ty_extraposed(L, s, S, Order4, Order),
    ty_clause_parts(Order, L, C, How),
    { ty_roles_ok(L, C),
      ty_object_ok(L, C, How),
      ty_split_kept(L, C, none, Order),
      ty_kein_ok(L) }.

%% ---- the place of the negation ------------------------------------------------------
%%
%% ty_negation_place(L, Words, Place): in a negative verb clause the
%% negation's Words stand as a part of the order, n(Words), at Place --
%% start, end, before(X) or after(X), X one of s, v, o (end where X is not
%% in the clause) -- and the verb takes its positive form. Several rows are
%% a negation of several parts (French `ne ... pas': [ne] before(v), [pas]
%% after(v)); one at the end is German `Der Junge sieht den Hund nicht'. A
%% language with no row keeps the negation in the verb's form
%% (ty_negation/5, or a negative ty_verb/6 row): English, Spanish, Italian
%% and Persian. Reading, a clause with the parts is negative and one
%% without positive. In a repair, a negation whose parts stand elsewhere
%% is a fault.
%% A question that moves the verb's first word (f) puts the parts placed
%% by the verb around that word: `Ne sees pas the boy the dog?', as French
%% `Ne voit-il pas le chien?'.
ty_negation_order(L, P, Order0, Order) :-
    (   ty_neg_placed(L)
    ->  ( memberchk(f, Order0) -> VA = f ; VA = v ),
        findall(Ws-Pl, ( ty_negation_place(L, Ws, Pl0), ty_verb_anchor(Pl0, VA, Pl) ), Rows),
        (   P = pos, Order = Order0
        ;   P = neg, foldl(ty_place_n, Rows, Order0, Order)
        ;   P = neg, ty_lenient,
            ty_values(negation_place, Places),
            ty_other_places(Rows, Places, Rows2),
            ty_fault(negation_place(Rows2)),
            foldl(ty_place_n, Rows2, Order0, Order)
        )
    ;   Order = Order0
    ).

%% The rows with their places chosen again, one place at least another.
ty_other_places(Rows, Places, Rows2) :-
    maplist([Ws-_, Ws-Pl]>>member(Pl, Places), Rows, Rows2),
    Rows2 \== Rows.

ty_verb_anchor(before(v), VA, before(VA)) :- !.
ty_verb_anchor(after(v), VA, after(VA)) :- !.
ty_verb_anchor(Pl, _, Pl).

ty_place_n(Ws-Place, O0, O) :- ty_place_part(Place, n(Ws), O0, O).

ty_place_part(start, X, O, [X|O]).
ty_place_part(end, X, O, Os) :- append(O, [X], Os).
ty_place_part(before(P), X, O, Os) :-
    (   append(A, [P|B], O) -> append(A, [X, P|B], Os) ; append(O, [X], Os) ).
ty_place_part(after(P), X, O, Os) :-
    (   append(A, [P|B], O) -> append(A, [P, X|B], Os) ; append(O, [X], Os) ).

ty_neg_placed(L) :- once(ty_negation_place(L, _, _)).

%% THE NEGATIVE ARTICLE (ty_negative_article(L, Gender, Number, Case, Word):
%% German `kein'): a negative clause whose subject or object, or a negative
%% copula clause whose subject or predicate, is an indefinite noun phrase
%% says its negation in that phrase's article and nowhere else (`Der Junge
%% sieht keinen Hund.', `Kein Hund schläft.', `Der Hund ist kein Tier.');
%% it is tried first, the subject before the object. `$ty_kein' names the role whose phrase takes it,
%% `$ty_kein_np' says the phrase being read is it, and ty_kein_ok holds a
%% clause read so to a phrase that took one (`$ty_kein_used').
ty_neg_clause(L, C, O0, O) :-
    C = clause(_, _, P, Subj, Obj, _),
    (   '$ty_kein_lang'(L)
    ->  b_setval('$ty_kein', none),
        (   ty_negative_article_keeps(L)
        ->  ty_negation_order(L, P, O0, O),
            (   P == neg, ty_kein_role(L, s), ty_kein_phrase(Subj) -> ty_kein_here(L, s, Subj)
            ;   P == neg, ty_kein_role(L, o), ty_kein_phrase(Obj) -> ty_kein_here(L, o, Obj)
            ;   true
            )
        ;   P = neg, ty_kein_role(L, s), ty_kein_here(L, s, Subj), O = O0
        ;   P = neg, ty_kein_role(L, o), ty_kein_here(L, o, Obj), O = O0
        ;   ty_negation_order(L, P, O0, O)
        )
    ;   ty_negation_order(L, P, O0, O)
    ).

%% The roles whose phrase takes the negative article
%% (ty_negative_article_roles/2; the object and the predicate where the
%% template names none), and the clause's own negation, which the article
%% replaces (German `Der Junge sieht keinen Hund.') or, where the template
%% says ty_negative_article_keeps/1, keeps (French `Le garçon ne voit pas
%% de chien.'): there the role is the clause's
%% once its negation is placed, and its phrase's article the negative one
%% where the phrase is indefinite, else its own (`ne voit pas le chien').
ty_kein_role(L, R) :-
    (   ty_negative_article_roles(L, Rs) -> memberchk(R, Rs) ; memberchk(R, [o, p]) ).



ty_kein_here(L, Role, X) :-
    '$ty_kein_lang'(L),
    ty_kein_phrase(X),
    b_setval('$ty_kein', Role),
    b_setval('$ty_kein_used', no).

ty_kein_phrase(X) :- var(X), !.
ty_kein_phrase(np(_, _, D, _)) :- ( var(D) -> true ; D == indef ).
ty_kein_phrase(rel(NP, _)) :- ty_kein_phrase(NP).

ty_kein_ok(L) :-
    (   '$ty_kein_lang'(L), \+ ty_negative_article_keeps(L), nb_current('$ty_kein', K), K \== none
    ->  nb_current('$ty_kein_used', yes)
    ;   true
    ).

ty_kein_np :- nb_current('$ty_kein_np', yes).

%% THE VERB SPLIT AT ITS AUXILIARY. Where a tense is an auxiliary and a
%% participle (ty_tense_form/5) and the negation has places round the verb,
%% or a pronoun is joined after it (the inversion), the verb's part is two:
%% vf(R), the words up to the auxiliary (an object clitic, the auxiliary,
%% and the pronoun an inversion joins to it), and vr(R), the participle,
%% after the negation's words that follow the verb: French `Le garçon n'a
%% pas vu le chien.', `A-t-il vu le chien?', `Ne l'a-t-il pas vue?'.
%% Reading, both orders are tried, and the whole one is kept only for a
%% tense with no auxiliary (ty_split_kept/4).
ty_verb_split(L, C, Rule, O0, O) :-
    (   C = clause(_, T, P, _, _, _),
        ty_split_wanted(L, P, Rule),
        once(append(A, [v|B], O0))
    ->  (   nonvar(T)
        ->  ( ty_tense_participle(L, T) -> ty_split_at(L, A, B, O) ; O = O0 )
        ;   ( O = O0 ; ty_split_at(L, A, B, O) )
        )
    ;   O = O0
    ).

%% Where the template puts the verb's last part at the end
%% (ty_split_place(L, end): German `Der Junge hat den Hund nicht
%% gesehen.'), it goes after every part, and before the first part where
%% the verb is last (`der Hund, den der Junge gesehen hat').
ty_split_at(L, A, B, O) :-
    (   ty_split_place(L, end)
    ->  (   B == []
        ->  append(A, [vr(R), vf(R)], O)
        ;   append(A, [vf(R)|B], O1), append(O1, [vr(R)], O)
        )
    ;   ty_n_parts(B, Ns, B1),
        append(Ns, [vr(R)|B1], B2),
        append(A, [vf(R)|B2], O)
    ).

ty_split_wanted(L, P, Rule) :-
    (   ty_split_place(L, end) -> true
    ;   P == neg, ty_neg_placed(L) -> true
    ;   ty_inv_on(L, Rule)
    ),
    once(ty_tense_participle(L, _)).

ty_n_parts([N|Ps], [N|Ns], Rest) :- nonvar(N), N = n(_), !, ty_n_parts(Ps, Ns, Rest).
ty_n_parts(Ps, [], Ps).

ty_split_kept(L, C, Rule, Order) :-
    (   memberchk(vf(_), Order)
    ->  true
    ;   C = clause(_, T, P, _, _, _), ty_split_wanted(L, P, Rule)
    ->  \+ ty_tense_participle(L, T)
    ;   true
    ).

%% The two parts share R = sp(First, Rest). Writing, the first finds the
%% whole verb and writes all but its last word; reading, it takes up to
%% three words, and the second, its one word, holds the two to a verb
%% (ty_split_verb/4: the statement's verb group, or the question's verb).
ty_split_first(sp(First, Rest), L, C, Q) -->
    ty_split_take(First, Rest, L, C, Q),
    (   { Q == none } -> [] ; ty_ask_inv(L, C, Q, First) ).

ty_split_take(First, Rest, L, C, Q, S0, S) :-
    (   var(S0)
    ->  ty_split_verb(L, C, Q, Full),
        append(First, Rest, Full), Rest = [_],
        append(First, S, S0)
    ;   between(1, 3, K), length(First, K), append(First, S, S0),
        (   nonvar(Rest)
        ->  append(First, Rest, Full), ty_split_verb(L, C, Q, Full)
        ;   true
        )
    ).

%% The second part may come first (the verb last): reading, the part read
%% second holds the two to a verb.
ty_split_rest(sp(First, Rest), L, C, Q, S0, S) :-
    (   var(S0)
    ->  Rest = [_], append(Rest, S, S0)
    ;   S0 = [W|S], Rest = [W],
        (   var(First)
        ->  true
        ;   append(First, Rest, Full),
            ty_split_verb(L, C, Q, Full)
        )
    ).

ty_split_verb(L, copula(T, P, Subj, Pred), Q, Full) :- !,
    b_setval('$ty_csubj', Subj),
    (   Q == none
    ->  ty_subject_number(Subj, N),
        ty_predicate_kind(Pred, K),
        ty_copula_polarity(L, P, CP),
        ty_copula_lookup(L, K, _, T, N, CP, Full)
    ;   phrase(ty_ask_verb(L, copula(T, P, Subj, Pred), Q), Full)
    ),
    Full = [_, _|_].
ty_split_verb(L, C, Q, Full) :-
    C = clause(V, T, P, Subj, O, _),
    b_setval('$ty_csubj', Subj),
    (   Q == none
    ->  ty_subject_number(Subj, N),
        ty_verb_polarity(L, P, VP),
        phrase(ty_verb_group(L, V, T, N, VP, O, _), Full)
    ;   phrase(ty_ask_verb(L, C, Q), Full)
    ),
    ty_tense_participle(L, T).

%% THE COPULA SPLIT, where the template puts a verb's last part at the end
%% (ty_split_place(L, end)): a copula of two words is two parts as a verb
%% of two is (German `Der Hund wird klein sein.', `Ist der Hund klein
%% gewesen?', `der Hund, der klein gewesen ist'); reading, both orders.
ty_copula_split(L, C, O0, O) :-
    (   ty_split_place(L, end),
        C = copula(T, _, _, _),
        once(append(A, [c|B], O0))
    ->  (   nonvar(T)
        ->  ( ty_copula_two(L, T) -> ty_split_at(L, A, B, O) ; O = O0 )
        ;   ( O = O0 ; ty_split_at(L, A, B, O) )
        )
    ;   O = O0
    ).

ty_copula_two(L, T) :- once(ty_copula(L, _, T, _, pos, [_, _|_])).

%% The polarity of the verb's own form: positive where the negation has a
%% place of its own.
ty_verb_polarity(L, P, VP) :-
    (   ty_neg_placed(L) -> VP = pos ; VP = P ).

%% The subject is what its verb takes (templates/roles.pl: the subject of
%% `see' is animate), and a verb whose object is none takes none (`sleep':
%% Spanish `Duerme el perro.' is no sleeping of a dog), asked of the IR
%% once the clause is read.
ty_roles_ok(L, clause(V, _, _, S, O, _)) :-
    (   ty_role_animacy(V, s, A) -> ty_np_animacy(L, S, A) ; true ),
    (   ty_role_animacy(V, o, none) -> O == none ; true ).

ty_np_animacy(L, np(M, _, _, _), A) :-
    once(( ty_noun(L, M, _, A1, _, _), ty_animacy_fits(A, A1) )).
ty_np_animacy(_, wh(M), A) :-
    ty_wh_features(M, [_, _, A1]),
    ty_animacy_fits(A, A1).
ty_np_animacy(L, rel(NP, _), A) :- NP = np(_, _, _, _), ty_np_animacy(L, NP, A).
ty_np_animacy(L, gap(NP, _, _), A) :- ty_np_animacy(L, NP, A).
ty_np_animacy(L, of(_, NP), A) :- NP = np(_, _, _, _), ty_np_animacy(L, NP, A).
ty_np_animacy(L, pron(_, _, K), A) :-
    nonvar(K), K = ref(M), !,
    ty_np_animacy(L, np(M, _, _, _), A).
ty_np_animacy(_, pron(P, _, K), A) :-
    ty_pron_animacy(P, K, A1),
    ( var(A1) -> true ; ty_animacy_fits(A, A1) ).

%% A role asks an animacy, and a noun of it fits, or one the vocabulary
%% says nothing of; a person is animate.
ty_animacy_fits(A, A1) :- A1 == A, !.
ty_animacy_fits(animate, A1) :- A1 == person, !.
ty_animacy_fits(_, unknown).

ty_adjunct_order(L, Order0, Js, Order) :-
    (   ty_adjunct(L, Place)
    ->  (   ty_place_j(Place, Order0, Order)
        ;   ty_lenient,
            ty_values(adjunct_place, Ps), member(P2, Ps), P2 \== Place,
            ty_place_j(P2, Order0, Order),
            ty_fault(adjunct_place(P2))
        )
    ;   Js = [], Order = Order0
    ).

%% A STATEMENT'S ADJUNCT FIRST, THE VERB SECOND (ty_adjunct_front(L, v2):
%% German `Heute schläft der Hund.', `Im Haus schläft der Hund.'): read
%% beside the template's own place, which the writer keeps (`Der Hund
%% schläft heute.'), in a main clause only, and where the clause's first word may
%% begin an adjunct (`$ty_jfirst'/2, made at load: an adverb, an
%% adposition's first word, a contraction).
ty_clause_adjuncts(L, _, O1, Js, O2) :- ty_adjunct_order(L, O1, Js, O2).
ty_clause_adjuncts(L, First, O1, Js, O2) :-
    atom(First), '$ty_jfirst'(L, First),
    \+ nb_current('$ty_sub', yes),
    var(Js), Js = [_|_],
    selectchk(v, O1, R),
    O2 = [j, v|R].

%% A STATEMENT'S OBJECT FIRST, THE VERB SECOND (ty_object_front(L, v2):
%% German `Den Hund sieht der Junge.'), in a main clause only, where the
%% clause's first word may begin an object and not a subject (`$ty_ofirst'/2,
%% made at load: `den', `einen', `keinen', `meinen', `ihn'). A first word
%% that may begin either (`die', `das') keeps the template's order, so
%% `Die Katze sieht das Mädchen.' has one reading, the cat that sees. The
%% writer keeps the template's order.
ty_clause_object_front(L, First, O1, O2) :-
    (   atom(First), '$ty_ofirst'(L, First),
        \+ nb_current('$ty_sub', yes),
        selectchk(o, O1, R1), selectchk(v, R1, R2)
    ->  O2 = [o, v|R2]
    ;   O2 = O1
    ).

%% A word that may begin a noun phrase of case C: an article's (not a
%% question's `welchen'), a negative
%% article's or a possessive pronoun's of C (a possessive pronoun's
%% condition that names no case is of any), or a pronoun of the role
%% (o for acc, s for nom).
ty_front_word(L, W, C) :- ty_article_case(L, Def, _, _, C1, W), Def \== which, ty_fits(C1, C).
ty_front_word(L, W, C) :- ty_negative_article(L, _, _, C1, W), ty_fits(C1, C).
ty_front_word(L, W, C) :-
    ty_possessive_pronoun(L, [W], _, Pd), member(Fs, Pd),
    (   member(C1, Fs), ty_case_known(L, C1) -> C1 == C ; true ).
ty_front_word(L, W, acc) :- ty_pronoun(L, o, [W], _).
ty_front_word(L, W, nom) :- ty_pronoun(L, s, [W], _).

ty_place_j(start, O, [j|O]).
ty_place_j(end, O, Os) :- append(O, [j], Os).
ty_place_j(before(P), O, Os) :- append(A, [P|B], O), !, append(A, [j, P|B], Os).
ty_place_j(after(P), O, Os) :- append(A, [P|B], O), !, append(A, [P, j|B], Os).

%% A clause with no object leaves o out of the order; it is tried first.
ty_valency(Order0, none, Order) :- exclude(==(o), Order0, Order).
ty_valency(Order, O, Order) :- O \== none.

%% How: how the object was read (ty_object//4).
ty_clause_parts([], _, _, _) --> [].
ty_clause_parts([P|Ps], L, C, How) --> ty_clause_part(P, L, C, How), ty_clause_parts(Ps, L, C, How).

ty_clause_part(s, L, clause(_, _, _, S, _, _), _) --> ty_role(L, s, S).
ty_clause_part(o, L, clause(V, _, _, _, O, _), How) --> ty_object(L, V, O, How).
ty_clause_part(v, L, clause(V, T, P, S, O, _), _) -->
    { ty_subject_number(S, N),
      b_setval('$ty_csubj', S),
      ty_verb_polarity(L, P, VP) },
    ty_verb_group(L, V, T, N, VP, O, Ws),
    ty_meant(L, verb(V), Ws).
ty_clause_part(j, L, clause(_, _, _, _, _, Js), _) --> ty_adjuncts(L, Js).
ty_clause_part(n(Ws), _, _, _) --> ty_tokens(Ws).
ty_clause_part(vf(R), L, C, _) --> ty_split_first(R, L, C, none).
ty_clause_part(vr(R), L, C, _) --> ty_split_rest(R, L, C, none).
ty_clause_part(oh(X), L, clause(V, _, _, _, O, _), How) --> ty_object_head(L, V, O, How, X).
ty_clause_part(ot(X), L, _, _) --> ty_rel_tail(L, X).
ty_clause_part(sh(X), L, clause(_, _, _, S, _, _), _) --> ty_subject_head(L, S, X).
ty_clause_part(st(X), L, _, _) --> ty_rel_tail(L, X).

%% ---- a verb's complement --------------------------------------------------------
%%
%% ty_complement(L, Verb, Words): the object of Verb is an adposition
%% phrase whose adposition is Words, in the pp level's order (English
%% `think about', `look at'; Spanish `pensar en'; Italian `pensare a';
%% Persian `به ... فکر کردن'), and it takes no role marks (Spanish `piensa
%% en la niña', not `a la niña'; Persian `به دختر', no `را'). The IR is the
%% plain object, clause(think, present, pos, np(boy, ...), np(girl, ...)),
%% so `The boy looks at the dog.' is `El niño mira al perro.'.
%%
%% How the object was read is How: plain (a role with its marks) or
%% comp(Words), checked against the verb once the clause is read
%% (ty_object_ok/3): a verb with a complement row takes no plain object,
%% and one with none no complement. Reading, a verb read before its object
%% decides at once; after it (Persian), at the clause's end.
ty_object(L, V, O, plain) -->
    { \+ ( nonvar(V), ty_complement(L, V, _), \+ ty_lenient ) },
    ty_role(L, o, O).
ty_object(L, V, O, comp(Ws)) -->
    { ty_complement_words(L, V, Ws) },
    ty_comp_phrase(L, Ws, O).

%% The head of an object whose relative clause stands after the verb
%% (ty_extraposed//5): its noun phrase in the linked form a relative clause
%% asks for, with its marks or in its complement. X carries the head and
%% its features to the clause's tail.
ty_object_head(L, V, rel(NP, Cl), plain, x(NP, F, Cl)) -->
    { \+ ( nonvar(V), ty_complement(L, V, _), \+ ty_lenient ) },
    ty_marked_np(L, o, NP, F, r).
ty_object_head(L, V, rel(NP, Cl), comp(Ws), x(NP, F, Cl)) -->
    { ty_complement_words(L, V, Ws) },
    ty_comp_phrase(L, Ws, head(NP, F)).

ty_complement_words(L, V, Ws) :-
    (   nonvar(V)
    ->  ty_complement(L, V, Ws)
    ;   setof(Ws0, V0^ty_complement(L, V0, Ws0), Wss),
        member(Ws, Wss)
    ).

%% The complement: its adposition and its noun phrase in the pp level's
%% order. A question word stands for the noun phrase; so does a relative
%% clause's gap, as ty_gap/3 says (ty_gap_words//3): the adposition stays
%% behind (English `the girl that the boy thinks about'), moves into the
%% marker (Spanish `la niña en la que el niño piensa'), or stays with a
%% pronoun (Persian `دختری که پسر به او فکر می‌کند').
ty_comp_phrase(L, Ws, O) -->
    { ty_order_at(L, pp, Order) },
    ty_comp_parts(Order, L, Ws, O).

ty_comp_parts([], _, _, _) --> [].
ty_comp_parts([P|Ps], L, Ws, O) --> ty_comp_part(P, L, Ws, O), ty_comp_parts(Ps, L, Ws, O).

ty_comp_part(p, L, Ws, O) -->
    (   { ty_gap_moved_from(O, AWs) }
    ->  { AWs = Ws }
    ;   ty_tokens(Ws)
    ),
    { ty_case_after_words(L, Ws) }.
ty_comp_part(x, L, _, O) --> ty_comp_np(L, O).

ty_comp_np(L, W) --> { nonvar(W), W = wh(M) }, ty_wh_words(L, M, tonic).
ty_comp_np(L, G) --> { nonvar(G), G = gap(_, F, R), R = r(c(_), _) }, ty_gap_words(L, F, R).
ty_comp_np(L, H) --> { nonvar(H), H = head(NP, F) }, ty_np(L, NP, F, r).
ty_comp_np(L, NP) --> ty_np_phrase(L, NP, _).

ty_tokens([]) --> [].
ty_tokens([W|Ws]) --> [W], ty_tokens(Ws).

%% Whether a complement's adposition moves with a question word to the
%% front (`¿En qué piensa el niño?') or stays (`What does the boy think
%% about?'); moves where the template says nothing.
ty_comp_rule(L, Rule) :-
    (   ty_complement_wh(L, R) -> Rule = R ; Rule = moves ).

%% The object as read, against the verb; in a repair, a plain object
%% where the verb takes a complement is a fault (`The boy looks the dog.'
%% is `The boy looks at the dog.'). With no object, an adjunct with the
%% verb's own adposition is the complement and not an adjunct: `El niño
%% piensa en la casa.' is about the house.
ty_object_ok(L, clause(V, _, _, _, O, Js), How) :-
    (   var(How)
    ->  \+ ( O == none, ty_complement(L, V, Ws),
             ty_js_items(Js, Items), member(pp(M, _), Items), ty_adposition(L, M, Ws) )
    ;   How = comp(Ws)
    ->  ty_complement(L, V, Ws)
    ;   ty_complement(L, V, Ws)
    ->  ty_lenient, ty_fault(complement(missing, Ws))
    ;   true
    ).

%% The adjuncts: adposition phrases and adverbs, in the IR's order.
ty_adjuncts(_, []) --> [].
ty_adjuncts(L, [J|Js]) --> ty_adjunct_item(L, J), ty_adjuncts(L, Js).
ty_adjuncts(L, Gapped) -->
    { nonvar(Gapped), Gapped = gapped(Prep, X, G, Js) },
    ty_adjuncts_gapped(L, Prep, X, G, Js, no).

%% The IR's adjuncts of a clause's list, gapped or not.
ty_js_items(Js, Items) :- ( nonvar(Js), Js = gapped(_, _, _, Items) -> true ; Items = Js ).

%% The adjuncts with a relative clause's gap in one of them, once. A gap
%% that writes nothing (its adposition moved into the marker) stands first,
%% so a sentence is one reading: `la casa en la que el perro duerme hoy' is
%% [pp(in, gap), adv(today)].
ty_adjuncts_gapped(_, _, _, _, [], yes) --> [].
ty_adjuncts_gapped(L, Prep, X, G, [pp(Prep, X)|Js], no) -->
    ty_pp(L, Prep, G),
    ty_adjuncts_gapped(L, Prep, X, G, Js, yes).
ty_adjuncts_gapped(L, Prep, X, G, [J|Js], Taken) -->
    { \+ ( Taken == no, ty_gap_moved_from(G, _) ) },
    ty_adjunct_item(L, J),
    ty_adjuncts_gapped(L, Prep, X, G, Js, Taken).

ty_adjunct_item(L, pp(Prep, NP)) --> ty_pp(L, Prep, NP).
ty_adjunct_item(L, W) --> { nonvar(W), W = wh(M), ty_wh_adjunct(M) }, ty_wh_words(L, M).
ty_adjunct_item(L, adv(M)) --> [W], { ty_adverb(L, M, W) }, ty_meant(L, adverb(M), [W]).

%% The question words that stand as an adjunct.
ty_wh_adjunct(where).
ty_wh_adjunct(when).

%% An adposition phrase: the adposition (p) and its noun phrase (x) in the
%% order the template keeps, a preposition or a postposition.
ty_pp(L, Prep, NP) -->
    { ty_order_at(L, pp, Order) },
    ty_pp_parts(Order, L, Prep, NP),
    { ty_pp_topic_ok(L, Prep, NP) }.

%% AN ADPOSITION BY ITS NOUN'S TOPIC (ty_adposition_topic/4: French `en' for
%% `in' before a month, `en mars', where it is `dans' else): writing, the
%% words of the noun's topic; reading, either, held to the noun read after
%% them (`$ty_pwords').
ty_pp_words(L, Prep, NP, Ws) :-
    (   '$ty_ptopic'(L)
    ->  (   ty_pp_head(NP, M), nonvar(M)
        ->  ( ty_adposition_topic(L, Prep, T, Ws0), ty_topic(M, T) -> Ws = Ws0 ; ty_adposition(L, Prep, Ws) )
        ;   ( ty_adposition(L, Prep, Ws) ; ty_adposition_topic(L, Prep, _, Ws) )
        ),
        b_setval('$ty_pwords', Ws)
    ;   ty_adposition(L, Prep, Ws)
    ).

ty_pp_topic_ok(L, Prep, NP) :-
    (   '$ty_ptopic'(L), nb_current('$ty_pwords', Ws), Ws \== none
    ->  b_setval('$ty_pwords', none),
        (   ty_pp_head(NP, M), nonvar(M), ty_adposition_topic(L, Prep, T, TWs), ty_topic(M, T)
        ->  Ws == TWs
        ;   ty_adposition(L, Prep, Ws)
        )
    ;   true
    ).

ty_pp_head(NP, M) :-
    (   var(NP) -> true
    ;   NP = np(M, _, _, _) -> true
    ;   NP = rel(H, _) -> ty_pp_head(H, M)
    ;   NP = of(_, H) -> ty_pp_head(H, M)
    ;   true
    ).

ty_pp_parts([], _, _, _) --> [].
ty_pp_parts([P|Ps], L, Prep, NP) --> ty_pp_part(P, L, Prep, NP), ty_pp_parts(Ps, L, Prep, NP).

ty_pp_part(p, L, Prep, NP) -->
    (   { ty_gap_moved_from(NP, AWs) }
    ->  { ty_adposition(L, Prep, AWs) }
    ;   ty_words(1, 3, Ws, ty_pp_words(L, Prep, NP, Ws)),
        ty_meant(L, adposition(Prep), Ws),
        { ty_case_after_words(L, Ws) }
    ).
ty_pp_part(x, L, _, G) --> { nonvar(G), G = gap(_, F, R), R = r(j(_), _) }, ty_gap_words(L, F, R).
ty_pp_part(x, L, _, NP) --> ty_np_phrase(L, NP, _).

%% A noun phrase where no role's marks stand (an adposition's, a copula's
%% predicate): a noun phrase, or a noun phrase with a relative clause.
ty_np_phrase(L, NP, F) --> { ty_np_slot(NP) }, ty_np(L, NP, F).
ty_np_phrase(L, R, F) --> { ty_rel_slot(R) }, ty_rel(L, none, R, F).
ty_np_phrase(L, P, F) --> { ty_poss_slot(P) }, ty_poss(L, P, F).
ty_np_phrase(L, Pr, F) -->
    { ty_ppron_slot(Pr) },
    ty_flag_allows('$ty_ppron'),
    { ty_pp_pron_role(L, R) },
    ty_words(1, 2, Ws, ty_pron_words(L, R, Pr, Ws)),
    { ty_pron_np_features(L, Pr, F) }.

%% A pronoun after an adposition takes the rows of j, or of o after an
%% adposition of the accusative (German `mit ihm', `an ihn').
ty_pp_pron_role(L, R) :- ( ty_case_now(L, acc) -> R = o ; R = j ).


%% ---- the possessor ------------------------------------------------------------------
%%
%% A noun phrase of a possessor is of(Possessor, NP) where a noun phrase
%% stands, a level of its own, poss: the possessed noun phrase (h), the
%% possessive word (p) and the possessor (g). ty_possessive(L, Order,
%% Words, Article) is a construction, its order of h p g, its words and
%% whether the possessed keeps its article; the first row is written, every
%% row read. English `the boy's dog' is g p h, the possessor's last word
%% linked to the head (ty_linked(english, n, h, '', '\'s')) and the head
%% with no article (Article drop), and `the dog of the boy' h p g, the
%% one written where the 's cannot stand (a possessor with a relative
%% clause); Spanish `el perro del niño' and Italian `il cane del ragazzo' h
%% p g with `de' and `di'; Persian `سگ پسر' h g, the head's last word
%% taking the ezafe before the possessor (ty_linked(persian, n, g, ...)).
%% Its features are the possessed's, so the verb agrees with the dog and a
%% mark asks the dog. The phrase's last word links to what follows it
%% (Next), so a possessor may itself be a possessor's phrase (`the boy's
%% dog's house', `la casa del perro del niño'); a possessor may be a noun
%% phrase with a relative clause where nothing links to it (`la casa del
%% niño que duerme', `خانه‌ی پسری که می‌خوابد').
%% Reading, a possessor is tried only where its construction's word is
%% among the words left, or a word in the linked form a possessed head
%% asks, and a possessor in a possessor only to the depth of the
%% sentence's possessive marks (`$ty_poss', counted where the parse starts:
%% English's g first would else start one at its own place for ever).
ty_poss(L, P, F) --> ty_poss(L, P, F, none, 0).

ty_poss(L, P, F, _, _) -->
    { nonvar(P), P = of(G, NP), nonvar(G), G = gap(_, HF, r(poss(_, NP, F), Rule)) },
    ty_poss_gap(L, Rule, NP, F, HF).
ty_poss(L, of(Pr, NP), F, Next, _) -->
    { ty_pron_slot(Pr) },
    ty_poss_pronoun(L, Pr, NP, F, Next).
ty_poss(L, of(G, NP), F, Next, Depth) -->
    ty_ahead(Ahead),
    { ty_poss_depth_ok(Ahead, Depth),
      ty_possessive(L, Order0, PWs, Art),
      ty_poss_possible(L, PWs, Ahead),
      ( PWs == [] -> exclude(==(p), Order0, Order) ; Order = Order0 ),
      ( nb_current('$ty_case', C0) -> true ; C0 = any ) },
    ty_poss_parts(Order, L, G, NP, F, PWs, art(Art, C0), Next, Depth).

ty_poss_parts([], _, _, _, _, _, _, _, _) --> [].
ty_poss_parts([P|Ps], L, G, NP, F, PWs, Art, Next, Depth) -->
    ty_poss_part(P, Ps, L, G, NP, F, PWs, Art, Next, Depth),
    ty_poss_parts(Ps, L, G, NP, F, PWs, Art, Next, Depth).

ty_poss_part(h, Ps, L, _, NP, F, _, art(Art, C0), Outer, _) -->
    { ty_poss_next(Ps, g, Outer, N0),
      ( Art == drop -> Next = bare(N0) ; Next = N0 ),
      b_setval('$ty_case', C0) },
    ty_np(L, NP, F, Next).
ty_poss_part(p, _, _, _, _, _, PWs, _, _, _) --> ty_tokens(PWs).
ty_poss_part(g, Ps, L, G, _, _, _, _, Outer, Depth) -->
    { ty_poss_next(Ps, h, Outer, Next), ty_role_case(L, g) },
    ty_possessor(L, G, Next, Depth).

%% The class a part's last word links to: the next part's, where that part
%% is the one named; the phrase's own Next for its last part.
ty_poss_next([], _, Outer, Outer) :- !.
ty_poss_next([X|_], X, _, X) :- !.
ty_poss_next(_, _, _, none).

%% A possessor: a noun phrase, a possessor's phrase, or a noun phrase with
%% a relative clause where nothing links to its last word.
ty_possessor(L, G, Next, _) --> { ty_np_slot(G) }, ty_np(L, G, _, Next).
ty_possessor(L, G, Next, Depth) -->
    { ty_poss_slot(G), Depth1 is Depth + 1 },
    ty_poss(L, G, _, Next, Depth1).
ty_possessor(L, G, Next, _) --> { Next == none, ty_rel_slot(G) }, ty_rel(L, none, G, _).

ty_poss_depth_ok(Ahead, Depth) :-
    (   var(Ahead) -> true
    ;   nb_current('$ty_poss', f(Count)) -> Depth < Count
    ;   true
    ).

%% A POSSESSIVE PRONOUN is a pronoun as a possessor: of(pron(Person,
%% Number, Kind), NP) (the pronoun's section below).
%% ty_possessive_pronoun(L, Words, Possessor, Possessed) gives its words
%% before the possessed, which takes no article of its own, where the
%% pronoun fits one of the Possessor conditions (a pronoun's, as
%% ty_pronoun/4's) and the possessed one of the Possessed ones (a noun
%% phrase's features): English `my', `your', `his', `their'; Spanish `mi',
%% `su', `sus' (the possessed's number), `nuestra'; Italian `il mio', `la
%% sua', `i loro'. ty_possessive_clitic(L) puts it on the possessed's last
%% word as the clitic of its person and number, clitic(Key) (Persian
%% `سگم', `سگش', `سگشان'). Reading, the pronoun is what its words tell, the
%% rest unbound (Spanish `su perro' is pron(3, _, _): his, her, its or
%% their dog).
ty_poss_pronoun(L, Pr, NP, F, Next) -->
    { \+ ty_possessive_clitic(L) },
    ty_words(1, 2, Ws, ty_possessive_pronoun(L, Ws, _, _)),
    { b_setval('$ty_bare_decl', indef) },
    ty_np(L, NP, F, bare(Next)),
    { b_setval('$ty_bare_decl', none),
      ty_possessive_pronoun(L, Ws, PrC, PdC),
      Pr = pron(_, _, _),
      ty_pron_here(L, Pr, Pr1),
      member(N1, PrC), ty_pron_fits(N1, Pr1),
      once(( member(N2, PdC), ty_poss_features(L, N2, F) )) }.

%% The possessed's features, and in a language with cases the phrase's
%% case where the condition names one (German `meinen' [m, sg, acc]).
ty_poss_features(L, N2, F) :-
    (   '$ty_cased'(L), member(C, N2), ty_case_known(L, C)
    ->  ty_case_now(L, C0), ty_case_fits(C, C0),
        exclude(==(C), N2, N3),
        ty_features_have(N3, F)
    ;   ty_features_have(N2, F)
    ).
ty_poss_pronoun(L, Pr, NP, F, none) -->
    { ty_possessive_clitic(L),
      Pr = pron(P, N, _),
      ( nonvar(P) -> ty_agreement(P, N, Key0), ty_key_here(L, Key0, Key) ; true ) },
    ty_np(L, NP, F, clitic(Key)),
    { ty_agreement(P, N, Key0), ty_key_here(L, Key0, Key) }.

%% An agreement key as the language's rows have it: a polite one the key
%% ty_polite/3 maps it to.
ty_key_here(L, Key0, Key) :-
    (   nonvar(Key0), Key0 = polite(N0) -> ty_polite(L, N0, Key) ; Key = Key0 ).

%% A slot that may hold a possessive pronoun: writing, a pron/3; reading,
%% one is tried where the sentence has a pronoun's word or a clitic form
%% (`$ty_pron').
ty_pron_slot(Pr) :-
    (   var(Pr) -> \+ nb_current('$ty_pron', f(no))
    ;   Pr = pron(_, _, _)
    ).

%% ---- the personal pronoun -----------------------------------------------------------
%%
%% A PERSONAL PRONOUN is pron(Person, Number, Kind) where a noun phrase
%% stands (a subject, an object, an adposition's noun phrase, a possessor):
%% Person 1, 2 or 3, or polite (the polite `you': usted, Lei, vous, شما,
%% whose verb ty_polite/3 gives), Number sg or pl, Kind m, f or n (a thing, or a living
%% thing whose sex is not said). A reading binds what its words tell and
%% leaves the rest unbound (`I' is pron(1, sg, _), `you' pron(2, _, _),
%% Spanish `su' pron(3, _, _)); the writer writes the first form that fits.
%% ty_pronoun(L, Role, Words, Conditions) gives its words in Role s (a
%% subject), o (an object) or j (after an adposition), where the pronoun
%% fits one of the Conditions, each a list of a person, a number and a
%% kind (`he' [[3, sg, m]], `you' [[2]]); a role with no row takes o's
%% rows (j, where an object is no clitic) or s's (Persian `او', `او را').
%% To a mark or an agreement a pronoun is a definite noun phrase of its
%% number, a person (the first and the second persons, he and she) or not
%% known (it), its kind its gender (a thing agrees as the language's first
%% gender does: Spanish `Es pequeño.').
%% ty_pro_drop(L, Persons): a subject pronoun may be no word, the verb's
%% form telling its person (Spanish `Veo al perro.', I see the dog), written
%% so for the Persons listed and read so of every person (`Duerme.', he or
%% she sleeps), never a polite one (usted, Lei, vous, شما are
%% always said). Reading, a pronoun's words are tried where the sentence
%% has one (`$ty_ppron').
ty_ppron_slot(Pr) :- var(Pr), !, Pr = pron(_, _, _).
ty_ppron_slot(pron(_, _, _)).

ty_ppron_role(L, s, Pr, F) -->
    { ty_dropped_first(L, Pr), ty_pron_np_features(L, Pr, F) }.
ty_ppron_role(L, Role, Pr, F) -->
    { \+ ( Role == o, ty_clitic(L, o) ) },
    ty_flag_allows('$ty_ppron'),
    ty_mark_slot(L, Role, before, Before),
    ty_words(1, 2, Ws, ty_pron_words(L, Role, Pr, Ws)),
    ty_mark_slot(L, Role, after, After),
    { ty_pron_np_features(L, Pr, F),
      ty_marks_ok(L, Role, before, F, Before),
      ty_marks_ok(L, Role, after, F, After) }.
ty_ppron_role(L, s, Pr, F) -->
    { ty_pro_drop(L, _), \+ ty_dropped_first(L, Pr),
      Pr = pron(P, _, _), ( var(P) -> member(P, [1, 2, 3]) ; P \== polite ),
      ty_pron_np_features(L, Pr, F) }.

%% Writing, a subject of a person the language drops, or of the third
%% person whose kind the IR does not say (Spanish `Duerme.' is Italian
%% `Dorme.', not `Lui dorme.'). A pronoun of the text (its kind ref(Meaning)) is dropped
%% so too: its noun was said.
ty_dropped_first(L, pron(P, _, K)) :-
    nonvar(P), ty_pro_drop(L, Persons),
    ( memberchk(P, Persons) -> true ; P == 3, ( var(K) -> true ; K = ref(_) ) ).

ty_flag_allows(Flag, S0, S0) :- ( var(S0) -> true ; \+ nb_current(Flag, f(no)) ).

%% The words of a pronoun in a role, by the role's rows or the rows it
%% takes.
ty_pron_words(L, Role, Pr, Ws) :-
    ty_pron_rows(L, Role, R),
    Pr = pron(_, _, _),
    ty_pron_here(L, Pr, Pr1),
    ty_pronoun(L, R, Ws, Conditions),
    member(C, Conditions),
    ty_pron_fits(C, Pr1).

ty_pron_rows(L, Role, R) :-
    (   once(ty_pronoun(L, Role, _, _)) -> R = Role
    ;   Role == j, \+ ty_clitic(L, o), once(ty_pronoun(L, o, _, _)) -> R = o
    ;   R = s
    ).

%% A condition's person, number and kind, each the pronoun's.
ty_pron_fits([], _).
ty_pron_fits([X|Xs], Pr) :- ty_pron_feature(X, Pr), ty_pron_fits(Xs, Pr).

ty_pron_feature(X, pron(P, _, _)) :- ( integer(X) ; X == polite ), !, P = X.
ty_pron_feature(X, pron(_, N, _)) :- ( X == sg ; X == pl ), !, N = X.
ty_pron_feature(X, pron(_, _, X)).

ty_pron_np_features(L, Pr0, [def, N, A, G]) :-
    ty_pron_here(L, Pr0, pron(P, N, K)),
    ( K == n -> true ; G = K ),
    (   Pr0 = pron(_, _, K0), nonvar(K0), K0 = ref(M), once(ty_noun(_, M, _, A0, _, _))
    ->  A = A0
    ;   ty_pron_animacy(P, K, A)
    ).

ty_pron_animacy(P, K, A) :-
    (   var(P) -> true
    ;   P \== 3 -> A = person
    ;   ( K == m ; K == f ) -> A = person
    ;   A = unknown
    ).

%% A PRONOUN OF THE TEXT, pron(3, Number, ref(Meaning)), stands for a noun
%% of Meaning said before it (typology_read_text/3 finds it). Each language
%% takes the kind its own pronouns give that noun: the noun's gender where
%% the pronouns follow it (ty_pronoun_gender(L, grammatical): Spanish `la'
%% for `la casa'), else the meaning's kind (ty_meaning_kind/2: English
%% `it' for the house, `she' for the girl).
ty_pron_here(L, pron(P, N, K), pron(P, N, K1)) :-
    (   nonvar(K), K = ref(M) -> ty_ref_kind(L, M, K1) ; K1 = K ).

ty_ref_kind(L, M, K) :-
    (   ty_pronoun_gender(L, grammatical),
        once(ty_noun(L, M, G, _, _, _)), memberchk(G, [m, f])
    ->  K = G
    ;   ty_meaning_kind(M, K)
    ).

%% Whether a construction can stand where the words are: its word among
%% them, or a word in the linked form the possessed asks.
ty_poss_possible(L, PWs, Ahead) :-
    (   var(Ahead) -> true
    ;   ty_poss_words_in(L, PWs, Ahead)
    ).

ty_poss_words_in(L, PWs, Words) :-
    (   PWs \== [] -> ty_all_ahead(PWs, Words)
    ;   '$ty_cased'(L), ty_case(L, g, Gen)
    ->  once(( member(W, Words), atom(W), '$ty_art_words'(L, _, Gen, W) ))
    ;   ty_linked(L, _, h, _, _)
    ->  once(( ty_linked(L, _, h, _, To), To \== '', member(W, Words),
               atom(W), atom_concat(_, To, W) ))
    ;   true
    ).

%% The sentence's possessive marks, counted once where its parse starts:
%% each construction's words, or the words in a linked form a possessed
%% asks; a construction with neither (Persian, whose ezafe is not written
%% after a consonant) counts the nouns less one, two nouns to a possessor. And whether a possessor's gap may
%% stand (`$ty_whose'), and whether a personal pronoun's word is among the
%% words (`$ty_ppron').
ty_poss_flag(L, Words) :-
    (   nb_current('$ty_poss_memo', memo(L0, Words0, Count, W, P, PP)), L0 == L, Words0 == Words
    ->  true
    ;   ty_poss_counts(L, Words, Count, W, P),
        ( ty_ppron_in(L, Words) -> PP = yes ; PP = no ),
        nb_setval('$ty_poss_memo', memo(L, Words, Count, W, P, PP))
    ),
    b_setval('$ty_poss', f(Count)),
    b_setval('$ty_whose', f(W)),
    b_setval('$ty_pron', f(P)),
    b_setval('$ty_ppron', f(PP)).

ty_ppron_in(L, Words) :-
    once(( ty_pronoun(L, _, Ws, _), ty_all_ahead(Ws, Words) )).

%% The last sentence's counts are kept (`$ty_poss_memo'): the writer reads
%% each sentence it writes back, the same words again.
ty_poss_counts(L, Words, Count, W, P) :-
    findall(N, ( ty_possessive(L, _, PWs, _), ty_poss_marks(L, PWs, Words, N) ), Ns),
    sum_list(Ns, Count0),
    (   ty_pron_in(L, Words) -> P = yes, Count is Count0 + 1 ; P = no, Count = Count0 ),
    (   ty_gap(L, poss, resumptive) -> W = yes
    ;   ty_relative_possessive(L, Ws, _), ty_all_ahead(Ws, Words) -> W = yes
    ;   W = no
    ).

%% A clitic form counts where the word without it is a noun or an
%% adjective (Persian `موش', a mouse, ends in ش and is no one's `مو'); a
%% possessive pronoun's words are asked by their first word (`$ty_ppw'/3,
%% made at load).
ty_pron_in(L, Words) :-
    (   ty_possessive_clitic(L)
    ->  once(( member(W, Words), atom(W), ty_unlinked(L, C1, clitic(_), W, W0), W0 \== W,
               (   C1 == n -> once(ty_noun_form(L, _, _, _, _, W0))
               ;   C1 == a, once(ty_adjective(L, _, _, _, W0))
               ) ))
    ;   once(( member(W, Words), atom(W), '$ty_ppw'(L, W, Ws), ty_all_ahead(Ws, Words) ))
    ).
ty_poss_marks(L, PWs, Words, N) :-
    (   PWs = [W0|_]
    ->  aggregate_all(count, ( member(W, Words), W == W0 ), N)
    ;   '$ty_cased'(L), ty_case(L, g, Gen)
    ->  aggregate_all(count, ( member(W, Words), atom(W), once('$ty_art_words'(L, _, Gen, W)) ), N)
    ;   ty_linked(L, _, h, _, _)
    ->  aggregate_all(count, ( member(W, Words), atom(W),
                              once(( ty_linked(L, _, h, _, To), To \== '', atom_concat(_, To, W) )) ), N)
    ;   aggregate_all(count, ( member(W, Words), atom(W), ty_base_word(L, n, W, W0),
                              once(( ty_noun_form(L, _, _, _, _, W0) ; ty_noun_case(L, _, _, _, W0) )) ), Nouns),
        N is max(0, Nouns - 1)
    ).

%% A possessor that is a relative clause's gap (`whose'): the rule
%% ty_gap(L, poss, Rule) says. Moved, the possessed went into the marker
%% with a possessive relative pronoun (ty_relative_possessive/3: English
%% `whose dog', Spanish `cuyo perro', Italian `il cui cane') and nothing is
%% written here; resumptive, the possessed stays and its last word takes the
%% possessor's clitic (Persian `سگش', clitic(Number)).
ty_poss_gap(_, moves, _, _, _) --> [].
ty_poss_gap(L, resumptive, NP, F, [_, N, _, _]) --> ty_np(L, NP, F, clitic(N)).
ty_poss_gap(L, stays, NP, F, _) --> ty_np(L, NP, F).

%% Reading (the slot unbound), a possessor is tried only in a sentence
%% with a possessive word (`$ty_poss'), and a possessor's gap only in one
%% with a possessive relative word or a clitic rule (`$ty_whose').
ty_poss_slot(X) :- var(X), !, \+ nb_current('$ty_poss', f(0)), X = of(_, _).
ty_poss_slot(of(_, _)).

%% A possessed phrase that moved into its relative clause's marker.
ty_poss_moved(P) :-
    nonvar(P), P = of(G, _), nonvar(G), G = gap(_, _, r(poss(_, _, _), Rule)), Rule == moves.

%% Words a table gives: reading, Min to Max words are taken and then
%% looked up (Lookup names Ws), so a table is asked by the words read;
%% writing, the lookup makes them.
ty_words(Min, Max, Ws, Lookup, S0, S) :-
    (   nonvar(S0)
    ->  between(Min, Max, K), length(Ws, K), append(Ws, S, S0), call(Lookup)
    ;   call(Lookup), append(Ws, S, S0)
    ).

%% A copula clause: s, the copula (c) and the predicate (p) in the order
%% the template keeps. The copula agrees with the subject's number and is
%% chosen by the predicate's kind (Spanish `estar' for a place); a copula
%% of no words is dropped. A predicate adjective agrees with the subject.
ty_copula_clause(L, C) -->
    { C = copula(_, P, S, Pred),
      ty_order_at(L, copula, Order0a),
      ty_copula_neg_order(L, C, Order0a, Order0b),
      ty_verb_final(L, c, Order0b, Order0c),
      ty_copula_split(L, C, Order0c, Order0) },
    ty_extraposed(L, p, Pred, Order0, Order1),
    ty_extraposed(L, s, S, Order1, Order),
    ty_copula_parts(Order, L, C, Features, Rows),
    { Features = [_, N, _, G],
      ty_predicate_ok(Pred, Rows, G, N),
      ty_kein_ok(L) }.

ty_copula_parts([], _, _, _, _) --> [].
ty_copula_parts([P|Ps], L, C, F, R) --> ty_copula_part(P, L, C, F, R), ty_copula_parts(Ps, L, C, F, R).

ty_copula_part(s, L, copula(_, _, S, _), Features, _) --> ty_role(L, s, S, Features).
ty_copula_part(c, L, copula(T, P, S, Pred), _, _) -->
    { ty_subject_number(S, N),
      b_setval('$ty_csubj', S),
      ty_predicate_kind(Pred, K),
      ty_copula_polarity(L, P, CP) },
    ty_copula_words(L, K, T, N, CP).
ty_copula_part(n(Ws), _, _, _, _) --> ty_tokens(Ws).
ty_copula_part(vf(R), L, C, _, _) --> ty_split_first(R, L, C, none).
ty_copula_part(vr(R), L, C, _, _) --> ty_split_rest(R, L, C, none).
ty_copula_part(p, L, copula(_, _, _, Pred), _, Rows) --> ty_predicate(L, Pred, Rows).
ty_copula_part(ph(X), L, copula(_, _, _, Pred), _, []) --> ty_predicate_head(L, Pred, X).
ty_copula_part(pt(X), L, _, _, _) --> ty_rel_tail(L, X).
ty_copula_part(sh(X), L, copula(_, _, S, _), Features, _) -->
    { X = x(_, Features, _) }, ty_subject_head(L, S, X).
ty_copula_part(st(X), L, _, _, _) --> ty_rel_tail(L, X).

%% THE COPULA'S NEGATION AT A PLACE: ty_copula_negation(L, Words, Place), as
%% ty_negation_place/3 is for a verb clause, puts the negation's Words in
%% a negative copula clause at Place (X one of s, c, p), and the copula
%% takes its positive form (German `Der Hund ist nicht klein.', `der Hund,
%% der nicht klein ist').
ty_copula_neg_order(L, C, O0, O) :-
    C = copula(_, P, Subj, Pred),
    (   once(ty_copula_negation(L, _, _))
    ->  b_setval('$ty_kein', none),
        findall(Ws-Pl, ty_copula_negation(L, Ws, Pl), Rows),
        (   P = pos, O = O0
        ;   P = neg, ty_kein_role(L, s), ty_kein_here(L, s, Subj), O = O0
        ;   P = neg, ty_kein_role(L, p), ty_kein_here(L, p, Pred), O = O0
        ;   P = neg, foldl(ty_place_n, Rows, O0, O)
        )
    ;   O = O0
    ).

ty_copula_polarity(L, P, CP) :-
    (   once(ty_copula_negation(L, _, _)) -> CP = pos ; CP = P ).

%% The head of a predicate whose relative clause stands after the copula.
ty_predicate_head(L, rel(NP, Cl), x(NP, F, Cl)) --> ty_np(L, NP, F, r).

ty_predicate_kind(adj(_), adj).
ty_predicate_kind(np(_, _, _, _), np).
ty_predicate_kind(rel(_, _), np).
ty_predicate_kind(of(_, _), np).
ty_predicate_kind(pp(_, _), pp).
ty_predicate_kind(W, K) :- nonvar(W), W = wh(M), ty_wh_kind(M, K).

%% A question word as a copula's predicate stands for a noun phrase or a
%% place (`Where is the dog?': Spanish `está').
ty_wh_kind(who, np).
ty_wh_kind(what, np).
ty_wh_kind(where, pp).

ty_copula_words(L, K, T, N, P) -->
    { '$ty_cmax'(L, Max) },
    ty_words(0, Max, Ws, ty_copula_lookup(L, K, K1, T, N, P, Ws)),
    ty_meant(L, copula(K1), Ws).

%% The copula of the predicate's kind and the subject's number; in a
%% repair, the other number's or another kind's (Spanish `es' for a place)
%% is a fault.
ty_copula_lookup(L, K, K1, T, N, P, Ws) :-
    (   ty_copula_form(L, K1, T, N, P, Ws), ty_fits(K1, K)
    *-> true
    ;   ty_lenient,
        (   nonvar(N), ty_other_number(N, N1),
            ty_copula_form(L, K1, T, N1, P, Ws), ty_fits(K1, K),
            ty_fault(agreement(copula, Ws))
        ;   ty_copula_form(L, K1, T, N, P, Ws), \+ ty_fits(K1, K),
            ty_fault(copula(Ws))
        )
    ).

%% A copula the template lists, or of a person by the person's rule; a
%% negative no row lists is the positive after the negation's words, where
%% the negation leaves the form as it is (Spanish `no soy').
ty_copula_form(L, K1, T, N, P, Ws) :-
    ty_person_form(L, T, N, ty_copula_n(L, K1, T, P), Ws).

%% A row's word agree(W) is the participle W agreeing with the subject
%% (Italian `è stato', `è stata', `sono stati'). typology_load/1 keeps a
%% template's copula rows in two tables: `$ty_crow'/6 the rows of plain
%% words, `$ty_cagree'/6 the rows with such a word.
ty_copula_n(L, K1, T, P, N, Ws) :- '$ty_crow'(L, K1, T, N, P, Ws).
ty_copula_n(L, K1, T, P, N, Ws) :-
    '$ty_cagree'(L, K1, T, N, P, Ws0), ty_copula_agreed(L, Ws0, Ws).
ty_copula_n(L, K1, T, neg, N, Ws) :-
    ty_negation(L, _, _, Neg, same),
    append(Neg, Pos, Ws),
    ty_copula_row(L, K1, T, N, pos, Pos),
    \+ ty_copula(L, K1, T, N, neg, _).

ty_copula_row(L, K1, T, N, P, Ws) :- '$ty_crow'(L, K1, T, N, P, Ws).
ty_copula_row(L, K1, T, N, P, Ws) :-
    '$ty_cagree'(L, K1, T, N, P, Ws0), ty_copula_agreed(L, Ws0, Ws).

ty_copula_agreed(_, [], []).
ty_copula_agreed(L, [X|Xs], [W|Ws]) :-
    (   compound(X), X = agree(W0)
    ->  ( atom(W) -> ty_part_base(L, W, W0) ; true ),
        ty_subject_part(L, W0, W)
    ;   W = X
    ),
    ty_copula_agreed(L, Xs, Ws).

%% A predicate takes the case ty_case(L, p, Case) gives it.
ty_predicate(L, P, Rows) --> { ty_role_case(L, p) }, ty_predicate_in(L, P, Rows).

ty_predicate_in(L, adj(As), Rows) -->
    { As = [_|_] },
    (   { ty_and(L, _) } -> ty_pred_adjs(L, As, Rows) ; ty_adjs(L, As, Rows) ).

%% THE PREDICATE'S ADJECTIVES joined (ty_and/2): the last after the
%% language's `and', each before it after a comma (`The dog is small and
%% black.', `El perro es pequeño, negro y grande.', Persian `سگ کوچک و
%% سیاه است.'); a noun phrase's adjectives stay as they are (`the small
%% black dog').
ty_pred_adjs(L, [A|As], [R|Rs]) --> ty_adjs(L, [A], [R]), ty_pred_more(L, As, Rs).

ty_pred_more(_, [], []) --> [].
ty_pred_more(L, [A], [R]) --> ty_and_words(L), ty_adjs(L, [A], [R]).
ty_pred_more(L, [A, B|As], [R|Rs]) --> [','], ty_adjs(L, [A], [R]), ty_pred_more(L, [B|As], Rs).

ty_and_words(L, S0, S) :- ty_and(L, Ws), append(Ws, S, S0).
ty_predicate_in(L, np(M, N, D, A), []) --> ty_np(L, np(M, N, D, A), _).
ty_predicate_in(L, R, []) --> { ty_rel_slot(R) }, ty_rel(L, none, R, _).
ty_predicate_in(L, P, []) --> { ty_poss_slot(P) }, ty_poss(L, P, _).
ty_predicate_in(L, pp(Prep, NP), []) --> ty_pp(L, Prep, NP).
ty_predicate_in(L, W, []) --> { nonvar(W), W = wh(M) }, ty_wh_words(L, M).

ty_predicate_ok(adj(_), Rows, G, N) :- !,
    (   ty_rows_fit(Rows, G, N)
    ->  true
    ;   ty_lenient,
        ty_fault(agreement(adjective))
    ).
ty_predicate_ok(_, _, _, _).

%% Each adjective's gender and number the subject's; a subject whose
%% gender is not known yet (a pronoun: `Soy pequeña.') takes the
%% adjective's.
ty_rows_fit([], _, _).
ty_rows_fit([adj(RG, RN)|Rows], G, N) :-
    ty_fits(RG, G), ty_fits(RN, N),
    ty_rows_fit(Rows, G, N).

%% ---- the clitic ---------------------------------------------------------------------
%%
%% ty_clitic(L, o): an object pronoun is a CLITIC, written in the verb's
%% words, after the negation's words and before the verb's form (Spanish
%% `la niña lo ve', `no lo ve'; Italian `lo vede'), and nothing where the
%% object stands; its words are the ty_pronoun(L, o, ...) rows. A verb with
%% a complement keeps its adposition, and the pronoun stands after it
%% (`piensa en él'). Ws, for the verb's meaning, are the form's own words
%% (the last ones before the rest of the sentence).
ty_verb_group(L, V, T, N, P, O, Ws) -->
    { \+ ty_clitic_pron(L, V, O) },
    ty_verb_words(L, V, T, N, P, Ws).
ty_verb_group(L, V, T, N, P, O, Ws) -->
    { ty_clitic_slot(L, O) },
    ty_clitic_verb(L, V, T, N, P, O, Ws).

%% Writing, an object pronoun of a verb with no complement, in a clitic
%% language.
ty_clitic_pron(L, V, O) :-
    nonvar(O), O = pron(_, _, _),
    ty_clitic(L, o),
    \+ ( nonvar(V), ty_complement(L, V, _) ).

%% Reading, a clitic is tried where the sentence has a pronoun's word
%% (`$ty_ppron').
ty_clitic_slot(L, O) :-
    ty_clitic(L, o),
    (   var(O) -> \+ nb_current('$ty_ppron', f(no)) ; O = pron(_, _, _) ).

ty_clitic_verb(L, V, T, N, P, O, Pos, S0, S) :-
    (   var(S0)
    ->  ty_verb_form(L, V, T, N, P, VWs0),
        ty_part_agree(L, T, O, VWs0, VWs),
        ty_neg_split(L, VWs, Neg, Pos),
        ty_pron_words(L, o, O, Cl),
        append([Neg, Cl, Pos, S], S0)
    ;   ty_neg_split(L, S0, Neg, S1),
        between(1, 2, KC), length(Cl, KC), append(Cl, S2, S1),
        once(ty_pron_words(L, o, _, Cl)),
        between(1, 4, KV), length(Pos, KV), append(Pos, S, S2),
        append(Neg, Pos, VWsA),
        ty_neg_split(L, VWsA, Neg1, _), Neg1 == Neg,
        ty_part_unagree(L, VWsA, VWs),
        ty_verb_agree(L, V, T, N, P, VWs),
        ty_pron_words(L, o, O, Cl),
        ty_part_agree(L, T, O, VWs, VWsA1), VWsA1 == VWsA
    ),
    \+ ty_complement(L, V, _).

%% A PARTICIPLE AGREES WITH AN OBJECT CLITIC before it where the template
%% says so (ty_participle_agrees(L, clitic): Italian `l'ha vista', `li ha
%% visti', French `il l'a vue'): the last word of the form, the
%% participle, takes the ending ty_participle_ending/5 gives the clitic's
%% gender and number; a masculine singular has none. Reading, the words
%% read are taken back to the form (ty_part_unagree/3, each ending a
%% candidate) and written again to be held to what was read.
ty_part_agree(L, T, O, D, A) :-
    (   ty_participle_agrees(L, clitic),
        ty_tense_participle(L, T),
        ty_part_features(L, O, G, N)
    ->  append(Front, [DW], D),
        (   ty_participle_ending(L, G, N, From, To),
            atom_concat(Stem, From, DW), atom_concat(Stem, To, AW)
        ;   \+ ty_participle_ending(L, G, N, _, _), AW = DW
        ),
        append(Front, [AW], A)
    ;   A = D
    ).

ty_part_unagree(_, A, A).
ty_part_unagree(L, A, D) :-
    ty_participle_agrees(L, clitic),
    append(Front, [AW], A),
    ty_participle_ending(L, _, _, From, To), To \== From,
    atom_concat(Stem, To, AW), atom_concat(Stem, From, DW),
    append(Front, [DW], D).

%% A third person's gender (a neuter is masculine) and number.
ty_part_features(L, O, G, N) :-
    nonvar(O), O = pron(3, _, _),
    ty_pron_here(L, O, pron(3, N, K)),
    (   K == f -> G = f ; var(K) -> G = K ; G = m ).

%% The negation's words at the start of a verb's words, and the rest.
ty_neg_split(L, Ws, Neg, Rest) :-
    (   ty_negation(L, _, _, Neg, _), Neg = [_|_], append(Neg, Rest, Ws)
    ->  true
    ;   Neg = [], Rest = Ws
    ).

%% Reading, the words are taken first and looked up (one to four of them),
%% so a table of thousands of verbs is asked by the words read; writing,
%% the form is looked up by its meaning and its words written.
ty_verb_words(L, V, T, N, P, Words, S0, S) :-
    (   nonvar(S0)
    ->  between(1, 4, K), length(Words, K), append(Words, S, S0),
        ty_verb_agree(L, V, T, N, P, Words)
    ;   ty_verb_form(L, V, T, N, P, Words),
        append(Words, S, S0)
    ).

%% A verb read agrees with its subject's number; in a repair, one that
%% does not is a fault.
ty_verb_agree(L, V, T, N, P, Words) :-
    (   ty_verb_form(L, V, T, N, P, Words)
    *-> true
    ;   ty_lenient, nonvar(N),
        ty_other_number(N, N1),
        ty_verb_form(L, V, T, N1, P, Words),
        ty_fault(agreement(verb, Words))
    ).

ty_other_number(sg, pl).
ty_other_number(pl, sg).

%% A form the template lists, or a negative its negation rule makes from a
%% positive form it lists; of a person, by the person's rule where no row
%% gives it (ty_person_form/5).
ty_verb_form(L, V, T, N, P, Words) :-
    ty_person_form(L, T, N, ty_verb_form_n(L, V, T, P), Words).

ty_verb_form_n(L, V, T, P, N, Words) :-
    ty_verb_plain(L, V, T, P, N, Words).
ty_verb_form_n(L, V, T, neg, N, Words) :-
    ty_negation(L, T0, N0, Neg, Form),
    append(Neg, Pos, Words),
    ( Form == same -> T1 = T, N1 = N ; Form = form(T1, N1) ),
    ty_verb_plain(L, V, T1, pos, N1, Pos),
    ty_tense_fit(T0, T),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N),
    \+ ty_verb(L, V, T, N, neg, _),
    \+ ty_tense_form(L, T, _, neg, _).

%% A form of the table, or one a ty_tense_form/5 row makes of words and
%% another form (English `will see', `has seen', Spanish `ha visto'); the
%% table's own row wins.
ty_verb_plain(L, V, T, P, N, Words) :-
    ty_verb_row(L, V, T, N, P, Words).
ty_verb_plain(L, V, T, P, N, Words) :-
    ty_tense_may(L, Words),
    ty_tense_pattern(L, T, N0, P, Pattern, C),
    ty_values(agreement, Ns), member(N, Ns), ty_fits(N0, N),
    ty_tense_words(Pattern, L, V, Words),
    ty_class_ok(L, V, C),
    \+ ty_verb(L, V, T, N, P, _).

%% A tense's pattern, of every verb (C none) or of a class of verbs
%% (ty_class_tense_form/6: Italian `essere', `è andato').
%% Reading, a pattern is tried only where the words begin with one's first
%% word (`$ty_tfirst'/2, made with the verb tables), and never for no
%% words: no pattern is empty.
ty_tense_may(L, Words) :-
    (   '$ty_vfirst_made'(L), nonvar(Words), Words = [W|_], atom(W)
    ->  ( '$ty_tfirst'(W, L) -> true ; '$ty_tfirst'('$any', L) )
    ;   Words \== []
    ).

ty_tense_pattern(L, T, N0, P, Pattern, none) :- ty_tense_form(L, T, N0, P, Pattern).
ty_tense_pattern(L, T, N0, P, Pattern, C) :- ty_class_tense_form(L, C, T, N0, P, Pattern).

ty_class_ok(L, V, C) :-
    (   C == none -> \+ ( ty_verb_class(L, V, C1), ty_class_tense_form(L, C1, _, _, _, _) )
    ;   ty_verb_class(L, V, C)
    ).

%% A pattern's words: a word as it is; form(T, N) the verb's own positive
%% form (looked up by its words where they are given); participle the
%% verb's participle.
ty_tense_words([], _, _, []).
ty_tense_words([I|Is], L, V, Words) :-
    (   I = form(T, N)
    ->  (   is_list(Words)
        ->  append(Ws, Rest, Words), Ws = [_|_], ty_verb_row(L, V, T, N, pos, Ws)
        ;   ty_verb_row(L, V, T, N, pos, Ws), append(Ws, Rest, Words)
        )
    ;   I == participle
    ->  Words = [W|Rest], ty_participle_word(L, V, W)
    ;   I == participle(subject)
    ->  Words = [W|Rest],
        (   atom(W)
        ->  ty_part_base(L, W, W0), ty_participle_word(L, V, W0), ty_subject_part(L, W0, W)
        ;   ty_participle_word(L, V, W0), ty_subject_part(L, W0, W)
        )
    ;   Words = [I|Rest]
    ),
    ty_tense_words(Is, L, V, Rest).

%% A verb's participle: its ty_participle/3 row, else the form
%% ty_participle_like/3 names (English `walked' for `walk').
ty_participle_word(L, V, W) :-
    (   ty_participle(L, V, W)
    ;   ty_participle_like(L, T, N),
        ty_verb_row(L, V, T, N, pos, [W]),
        \+ ty_participle(L, V, _)
    ).

%% A tense made of words and a participle; one made so at all.
ty_tense_participle(L, T) :-
    ty_tense_pattern(L, T, _, _, Pattern, _),
    (   memberchk(participle, Pattern) ; memberchk(participle(_), Pattern)
    ;   ty_split_place(L, end), Pattern = [_, _|_]
    ), !.

ty_tense_made(L, T) :- ty_tense_pattern(L, T, _, _, _, _), !.

%% A PARTICIPLE THAT AGREES WITH THE SUBJECT (a pattern's participle(subject):
%% Italian `La ragazza è andata', French `Les filles sont allées'): the
%% verb's part sets `$ty_csubj' to its clause's subject just before it;
%% writing, the subject's gender and number choose the ending
%% (ty_participle_ending/5); reading, the ending read binds what the
%% subject leaves open (`Sono andata': pron(1, sg, f)), and a subject not
%% read yet (it follows the verb) is not held to it.
ty_subject_part(L, W0, W) :-
    (   nb_current('$ty_csubj', S), ty_subject_gn(L, S, G, N)
    ->  (   var(W), var(G) -> G1 = m ; G1 = G ),
        ty_part_form(L, G1, N, W0, W)
    ;   atom(W) -> ty_part_form(L, _, _, W0, W)
    ;   W = W0
    ).

ty_subject_gn(L, S, G, N) :-
    nonvar(S),
    (   S = np(M, N, _, _) -> ( once(ty_noun(L, M, G0, _, _, _)), memberchk(G0, [m, f]) -> G = G0 ; G = m )
    ;   S = pron(_, N, K) -> ( K == f -> G = f ; var(K) -> G = K ; G = m )
    ;   S = rel(H, _) -> ty_subject_gn(L, H, G, N)
    ;   S = of(_, H) -> ty_subject_gn(L, H, G, N)
    ;   S = gap(H, _, _) -> ty_subject_gn(L, H, G, N)
    ).

ty_part_form(L, G, N, W0, W) :-
    (   ty_participle_ending(L, G, N, From, To),
        atom_concat(Stem, From, W0), atom_concat(Stem, To, W)
    ;   ( var(G) -> G = m ; true ),
        \+ ty_participle_ending(L, G, N, _, _), W = W0
    ).

%% The participle's plain form of a form read: itself, or with an ending
%% put back.
ty_part_base(_, W, W).
ty_part_base(L, W, W0) :-
    ty_participle_ending(L, _, _, From, To), To \== From,
    atom_concat(Stem, To, W), atom_concat(Stem, From, W0).

%% A verb's row. Reading (its last word given), the rows are asked by the
%% words alone, through `$ty_vrow'/6 (the words joined, an atom, its first
%% argument): the table's own index on a list of words finds the first row
%% at once, but its every other answer walked the rows -- 2.6 milliseconds
%% for all the rows of Spanish `ve' with 76 000 rows loaded (1.40.0; 1.8 ms
%% with 57 000 through 1.39.0), the reader's greatest cost -- and a miss
%% walked them too.
ty_verb_row(L, V, T, N, P, Words) :-
    (   ty_last_given(Words)
    ->  (   ground(Words), '$ty_vfirst_made'(L)
        ->  atomic_list_concat(Words, ' ', Key),
            '$ty_vrow'(Key, L, V, T1, N1, P1)
        ;   ty_verb(L, V, T1, N1, P1, Words)
        ),
        T1 = T, N1 = N, P1 = P
    ;   ty_verb(L, V, T, N, P, Words)
    ).

%% Every verb row by its words joined (`$ty_vrow'/6: Key, L, Meaning,
%% Tense, Number, Polarity) and every meaning by a form's first word
%% (`$ty_vfirst'/3), in the table's order and each once, of a language
%% typology_load/1 loaded, made as it loads (`$ty_vfirst_made'/1); a
%% language whose rows were asserted (a test's) has none, and its table is
%% asked as it is.
:- dynamic('$ty_vfirst'/3).
:- dynamic('$ty_vrow'/6).
:- dynamic('$ty_vfirst_made'/1).
:- dynamic('$ty_tfirst'/2).

%% Whether a verb's form may begin with W (the words around a word with
%% several meanings).
ty_verb_begins(L, W) :-
    (   atom(W), '$ty_vfirst_made'(L) -> once('$ty_vfirst'(W, L, _)) ; true ).

%% The rows of L go by a walk of retract/1, not by retractall/1: with the
%% first argument unbound, cocolog 3.73.2's retractall/1 took 70 s to take
%% 20 000 rows that stand after 100 000 others (4.7 s where they stand
%% first), and English's rows, at the end after a reload, 180 s at a third
%% load (1.57.0). The walk takes them in 0.01 s.
ty_vfirst_make(L) :-
    forall(retract('$ty_vfirst'(_, L, _)), true),
    forall(retract('$ty_vrow'(_, L, _, _, _, _)), true),
    retractall('$ty_tfirst'(_, L)),
    retractall('$ty_vfirst_made'(L)),
    forall(ty_verb(L, M, T, N, P, Fs),
           (   Fs = [W|_],
               atomic_list_concat(Fs, ' ', K),
               (   '$ty_vrow'(K, L, M, T, N, P) -> true ; assertz('$ty_vrow'(K, L, M, T, N, P)) ),
               (   '$ty_vfirst'(W, L, M) -> true ; assertz('$ty_vfirst'(W, L, M)) )
           )),
    findall(F, ( ty_tense_pattern(L, _, _, _, [I|_], _),
                 ( atom(I) -> F = I ; F = '$any' ) ), Fs0),
    sort(Fs0, Fs1),
    forall(member(F, Fs1), assertz('$ty_tfirst'(F, L))),
    assertz('$ty_vfirst_made'(L)).

%% ---- the person -------------------------------------------------------------------
%%
%% A verb agrees with its subject's PERSON AND NUMBER, a key: sg and pl are
%% the third person (every row written before 1.34.0), sg(1), sg(2), pl(1)
%% and pl(2) the first and the second (ty_agreement/3). The Number of a
%% ty_verb/6, ty_copula/6, ty_negation/5 and ty_question_form/5 row is a
%% key. A key no row gives is made by the language's rule,
%% ty_verb_person(L, Tense, Key, Base, From, To): the form of the key Base,
%% its last word's ending From made To. English: every key but sg is pl's
%% form (`I see', `you do not see', `do we see'); Persian: the plural's
%% ending ند made م, ی, یم, ید (`می‌بینم', `دیدی', `نیستیم').
ty_agreement(3, sg, sg).
ty_agreement(3, pl, pl).
ty_agreement(1, sg, sg(1)).
ty_agreement(2, sg, sg(2)).
ty_agreement(1, pl, pl(1)).
ty_agreement(2, pl, pl(2)).
%% The polite `you' (pron(polite, N, K)): its own key, which a template maps
%% to the form it takes (ty_polite/3: Spanish `usted ve', French `vous
%% voyez').
ty_agreement(polite, sg, polite(sg)).
ty_agreement(polite, pl, polite(pl)).

%% The form of key N, Form called with a key and the words: the rows' own,
%% else the rule's over its base's form. Reading, the rule takes the
%% ending back first, so the table is asked by the base's words.
ty_person_form(L, T, N, Form, Words) :-
    (   nonvar(N), N = polite(N0)
    ->  ty_polite(L, N0, Key),
        ty_person_form(L, T, Key, Form, Words)
    ;   nonvar(N), N \== sg, N \== pl
    ->  (   call(Form, N, Words)
        *-> true
        ;   ty_verb_person(L, T0, N, Base, From, To),
            ty_fits(T0, T),
            (   ty_last_given(Words)
            ->  ty_person_ending(Ws0, From, To, Words), call(Form, Base, Ws0)
            ;   call(Form, Base, Ws0), ty_person_ending(Ws0, From, To, Words)
            )
        )
    ;   call(Form, N, Words)
    ).

%% Reading, the last word is given: the rule's ending is taken back from
%% it.
ty_last_given(Ws) :- is_list(Ws), last(Ws, W), atom(W).

ty_person_ending(Ws0, From, To, Ws) :-
    (   ty_last_given(Ws)
    ->  append(Front, [W], Ws),
        atom_concat(Stem, To, W), atom_concat(Stem, From, W0),
        append(Front, [W0], Ws0)
    ;   append(Front, [W0], Ws0),
        atom_concat(Stem, From, W0), atom_concat(Stem, To, W),
        append(Front, [W], Ws)
    ).

%% A role's phrase, with the marks the template puts before or after it.
ty_role(L, Role, NP) --> ty_role(L, Role, NP, _).

%% A question word in a role, with the marks its features ask for (Spanish
%% `a quién', Persian `چه کسی را'). It stands only where ty_ask_kind/3 put
%% it: a statement has none.
ty_role(L, Role, W, [Def, N, Anim, _]) -->
    { nonvar(W), W = wh(M), ty_wh_features(M, [Def, N, Anim]),
      ty_role_case(L, Role) },
    ty_mark_slot(L, Role, before, Before),
    { ty_wh_role_form(Role, Form) },
    ty_wh_words(L, M, Form),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_ok(L, Role, before, [Def, N, Anim], Before),
      ty_marks_ok(L, Role, after, [Def, N, Anim], After) }.

ty_role(L, Role, NP, Features) -->
    { ty_np_slot(NP) },
    ty_marked_np(L, Role, NP, Features, none).

%% A personal pronoun in its role; an object clitic's words stood in the
%% verb's (ty_verb_group//7), which bound it before the object's place.
ty_role(L, o, Pr, F) -->
    { nonvar(Pr), Pr = pron(_, _, _), ty_clitic(L, o), ty_pron_np_features(L, Pr, F) }.
ty_role(L, Role, Pr, F) --> { ty_ppron_slot(Pr) }, ty_ppron_role(L, Role, Pr, F).

%% A relative clause's gap: its head's, with no words, or a pronoun
%% between the role's marks (Persian `سگی که پسر آن را می‌بیند').
ty_role(_, _, G, Features) --> { nonvar(G), G = gap(_, Features, r(Pl, gap)), ty_role_gap(Pl) }.
ty_role(L, Role, G, [_, N, A, Gen]) -->
    { nonvar(G), G = gap(_, [_, N, A, Gen], r(Pl, resumptive)), ty_role_gap(Pl),
      F = [def, N, A, Gen] },
    ty_mark_slot(L, Role, before, Before),
    ty_resumptive_words(L, F),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_ok(L, Role, before, F, Before),
      ty_marks_ok(L, Role, after, F, After) }.

%% A noun phrase with a relative clause.
ty_role(L, Role, R, Features) --> { ty_rel_slot(R) }, ty_rel(L, Role, R, Features).

%% A noun phrase of a possessor between its role's marks; moved into a
%% relative clause's marker (`whose dog'), nothing.
ty_role(L, Role, P, Features) -->
    { ty_poss_slot(P), \+ ty_poss_moved(P),
      ty_role_case(L, Role) },
    ty_mark_slot(L, Role, before, Before),
    ty_poss(L, P, Features),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_ok(L, Role, before, Features, Before),
      ty_marks_ok(L, Role, after, Features, After) }.
ty_role(_, _, P, Features) -->
    { ty_poss_moved(P), P = of(gap(_, _, r(poss(_, _, Features), _)), _) }.

%% A noun phrase between the marks its role asks for. Next is r when a
%% relative clause follows it (its last word may take a linked form).
ty_marked_np(L, Role, NP, Features, Next) -->
    { ty_role_case(L, Role) },
    ty_mark_slot(L, Role, before, Before),
    ty_np(L, NP, Features, Next),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_ok(L, Role, before, Features, Before),
      ty_marks_ok(L, Role, after, Features, After) }.

%% What a slot may hold, reading (unbound) or writing.
ty_np_slot(X) :- var(X), !.
ty_np_slot(np(_, _, _, _)).

ty_rel_slot(X) :- var(X), !, X = rel(_, _).
ty_rel_slot(rel(_, _)).

%% ---- relative clauses ---------------------------------------------------------------
%%
%% A noun phrase with a relative clause is a level of its own, rel: the
%% head (h: the noun phrase, between its role's marks), the marker (m,
%% ty_relative/4: `that', `que', `che', `که') and the clause (c), in an
%% order the template keeps (English `the dog that the boy sees' is h m c).
%% The clause is a verb clause or a copula clause in the language's own
%% order, with a GAP where the head stands in it:
%%
%%     rel(np(dog, sg, def, []),
%%         clause(see, present, pos, np(boy, sg, def, []), gap))
%%
%% A gap (most often no words: the section on the gap below) is its head
%% to every check: the verb agrees
%% with it (`the boys that see the dog'), its role asks its animacy (`the
%% book that sees' is not read), a predicate adjective agrees with it (`la
%% niña que es pequeña'). The marker is the first ty_relative/4 row that
%% fits the gap's role and the head's features; a marker of no words is
%% written nothing (English `the dog the boy sees'). In Persian the head's
%% last word takes a linked form before the clause (ty_linked(persian, n,
%% r, From, To): `سگی که پسر می‌بیند', the dog that the boy sees).
%% The relative clause of an object or a predicate may stand after the
%% verb (ty_relative_after/3, below).

ty_rel(L, Role, rel(NP, C), Features) -->
    ty_rel_open(L),
    ty_ahead(Ahead),
    { ty_order_at(L, rel, Order),
      ty_gap_place(L, NP, Features, R, C, C1),
      ty_gap_possible(L, R, Ahead) },
    ty_rel_parts(Order, L, Role, NP, Features, C1, m(Ws, R)),
    { ty_rel_marker_ok(L, R, Features, Ws) }.

%% A relative clause after its verb (ty_extraposed//5): the marker and the
%% clause, in the rel level's order less the head, which was read where
%% its role stands. X is x(Head, Features, Clause).
ty_rel_tail(L, x(NP, Features, C)) -->
    ty_ahead(Ahead),
    { ty_order_at(L, rel, [h|Order]),
      ty_gap_place(L, NP, Features, R, C, C1),
      ty_gap_possible(L, R, Ahead) },
    ty_rel_parts(Order, L, none, NP, Features, C1, m(Ws, R)),
    { ty_rel_marker_ok(L, R, Features, Ws) }.

%% THE RELATIVE CLAUSE AFTER THE VERB: ty_relative_after(L, Part, Rank),
%% Part s (a subject), o (a verb clause's object) or p (a copula clause's
%% predicate), moves the clause to the end of its clause, the head staying
%% where its part stands (Persian `دختر سگ سیاهی را می‌بیند که می‌خوابد',
%% `سگ حیوانی است که می‌خوابد', `سگی می‌خوابد که پسر می‌بیند'). The part
%% becomes the head (sh(X), oh(X), ph(X)), and the tail (st(X), ot(X),
%% pt(X)) goes last. Rank first: it is written, and the clause in place is
%% read too; second: the clause in place is written, and this one read
%% (Persian's subject). Reading, it is tried only where a marker word is
%% among the words left; the rel order must begin with the head.
ty_extraposed(L, Part, X, Order0, Order, S0, S0) :-
    (   ty_relative_after(L, Part, Rank),
        ty_order_at(L, rel, [h|_]),
        (   nonvar(X) -> X = rel(_, _)
        ;   nonvar(S0) -> ty_marker_ahead(L, S0)
        ;   true
        ),
        ty_head_tail(Part, Head, Tail),
        append(Before, [Part|After], Order0)
    ->  append(Before, [Head|After], Order1),
        append(Order1, [Tail], Moved),
        (   Rank == first
        ->  ( Order = Moved ; Order = Order0 )
        ;   ( Order = Order0 ; Order = Moved )
        )
    ;   Order = Order0
    ).

ty_head_tail(s, sh(X), st(X)).
ty_head_tail(o, oh(X), ot(X)).
ty_head_tail(p, ph(X), pt(X)).

%% The head of a subject whose relative clause stands after the verb.
ty_subject_head(L, rel(NP, Cl), x(NP, F, Cl)) --> ty_marked_np(L, s, NP, F, r).

%% Reading, a relative clause starts only where it may:
%%   - not where one is open that has read no word yet: in an order with
%%     the clause first (c h), the clause's first role would start a
%%     relative clause there again, for ever. The places are the counts of
%%     the words left (`$ty_rel_open', set to f([]) where a parse starts;
%%     inside f/1 for the reason ty_fault/1 gives);
%%   - in a language whose every marker is a word, only where a marker
%%     word (a relative pronoun's too) is among the words left: every noun
%%     phrase read would else try a relative clause after it.
ty_rel_open(L, S0, S0) :-
    (   var(S0)
    ->  true
    ;   length(S0, N),
        ( nb_current('$ty_rel_open', f(Open)) -> true ; Open = [] ),
        \+ memberchk(N, Open),
        (   ty_relative(L, _, [], _)
        ->  true
        ;   ty_marker_ahead(L, S0)
        ->  true
        ),
        b_setval('$ty_rel_open', f([N|Open]))
    ).

%% A language that puts a comma before the marker has one ahead too.
ty_marker_ahead(L, S0) :-
    ( ty_relative_comma(L) -> memberchk(',', S0) ; true ),
    (   ty_relative(L, _, [W|_], _), memberchk(W, S0)
    ;   ty_relative_pronoun(L, Ws, _), ty_all_ahead(Ws, S0)
    ;   ty_relative_possessive(L, Ws, _), ty_all_ahead(Ws, S0)
    ), !.

ty_all_ahead(Ws, S0) :- forall(member(W, Ws), memberchk(W, S0)).

%% ---- the gap ------------------------------------------------------------------------
%%
%% THE GAP is where the head stands in its relative clause: the subject or
%% the object of a verb clause, the noun phrase of an adposition phrase
%% (an adjunct, `the house in which the dog sleeps', or a verb's
%% complement, `the girl that the boy thinks about'), or the subject of a
%% copula clause. Writing, the IR says which; reading, each is tried. Inside
%% the clause the gap is gap(Head, Features, r(Place, Rule)): Place s, o,
%% c(Verb) (a complement) or j(Adposition) (an adjunct), and Rule how it is
%% written, as ty_gap(L, Place, Rule) says, the first row written and every
%% row read:
%%
%%     gap          nothing (o: the default with no row)
%%     resumptive   a pronoun of the head's features (ty_resumptive/3): an
%%                  object with its marks (Persian `که پسر آن را
%%                  می‌بیند'), after the adposition (`که سگ در آن
%%                  می‌خوابد')
%%     stays        (pp) the adposition alone (`the house that the dog
%%                  sleeps in')
%%     moves        (pp) nothing: the adposition moves into the marker, with
%%                  a relative pronoun of the head's features
%%                  (ty_relative_pronoun/3: `la casa en la que el perro
%%                  duerme', `la casa in cui il cane dorme', `the house in
%%                  which the dog sleeps')
%%
%% A gap in an adposition phrase needs a pp row: a language with none has
%% no such relative clause. Reading, an adjunct's gap is the clause's only
%% adjunct.
ty_gap_place(_, NP, F, r(s, gap), clause(V, T, P, gap, O, Js),
             clause(V, T, P, gap(NP, F, r(s, gap)), O, Js)).
ty_gap_place(L, NP, F, R, clause(V, T, P, S, gap, Js), clause(V, T, P, S, gap(NP, F, R), Js)) :-
    (   ty_gap_rule(L, o, Rule), R = r(o, Rule)
    ;   ty_gap_rule(L, pp, Rule), R = r(c(V), Rule)
    ).
ty_gap_place(L, NP, F, R, clause(V, T, P, S, O, Js0), clause(V, T, P, S, O, Js)) :-
    ty_gap_rule(L, pp, Rule),
    R = r(j(Prep), Rule),
    ty_gap_adjunct(Js0, Prep, gap, gap(NP, F, R), Js).
ty_gap_place(_, NP, F, r(s, gap), copula(T, P, gap, Pred), copula(T, P, gap(NP, F, r(s, gap)), Pred)).
ty_gap_place(L, NP, F, R, C0, C) :-
    (   var(C0) -> \+ nb_current('$ty_whose', f(no)) ; true ),
    ty_poss_gap_place(L, NP, F, R, C0, C).

ty_poss_gap_place(L, NP, F, R, clause(V, T, P, S0, O, Js), clause(V, T, P, S, O, Js)) :-
    ty_poss_gap_in(L, s, NP, F, R, S0, S).
ty_poss_gap_place(L, NP, F, R, clause(V, T, P, S, O0, Js), clause(V, T, P, S, O, Js)) :-
    ty_poss_gap_in(L, o, NP, F, R, O0, O).
ty_poss_gap_place(L, NP, F, R, copula(T, P, S0, Pred), copula(T, P, S, Pred)) :-
    ty_poss_gap_in(L, s, NP, F, R, S0, S).
ty_poss_gap_place(L, NP, F, R, clause(V, T, P, S, O, Js0), clause(V, T, P, S, O, Js)) :-
    (   var(Js0) -> \+ nb_current('$ty_whose', f(no)) ; true ),
    ty_gap(L, poss, Rule),
    Rule \== stays,
    R = r(poss(j(Prep, _), NP2, _), Rule),
    ty_gap_adjunct(Js0, Prep, of(gap, NP2), of(gap(NP, F, R), NP2), Js).

%% The possessor of a subject or an object as the gap (`the boy whose dog
%% sleeps'): of(gap, Possessed) in the IR, the rule ty_gap(L, poss, Rule)'s;
%% r(poss(Role, Possessed, Features), Rule) carries the possessed and its
%% features from the marker to its place.
ty_poss_gap_in(L, Role, NP, F, R, X0, of(gap(NP, F, R), NP2)) :-
    (   var(X0) -> \+ nb_current('$ty_whose', f(no)) ; true ),
    X0 = of(gap, NP2),
    ty_gap(L, poss, Rule),
    R = r(poss(Role, NP2, _), Rule).

%% Reading, a gap is tried only where the words it needs are among the
%% words left: a pronoun's, a moved adposition's pronoun, an adposition
%% that stays (every noun phrase of English, whose object takes a marker
%% of no words, would else try each). Writing, every gap is possible.
ty_ahead(S0, S0, S0).

ty_gap_possible(L, r(Pl, Rule), Ahead) :-
    (   var(Ahead) -> true
    ;   Rule == gap -> true
    ;   Pl = poss(_, _, _) -> ( ( Rule == moves ; Rule == stays ) -> once(( ty_relative_possessive(L, Ws, _), ty_all_ahead(Ws, Ahead) )) ; true )
    ;   Rule = moves(_) -> once(( ty_relative_pronoun(L, Ws, _), ty_all_ahead(Ws, Ahead) ))
    ;   Rule == resumptive -> once(( ty_resumptive(L, Ws, _), ty_all_ahead(Ws, Ahead) ))
    ;   Pl = c(_) -> once(( ty_complement(L, _, Ws), ty_all_ahead(Ws, Ahead) ))
    ;   once(( ty_adposition(L, _, Ws), ty_all_ahead(Ws, Ahead) ))
    ).

%% How a gap is written at Place: the rows, the first written; an object
%% with no row is a gap. A moved adposition is moves(Words).
ty_gap_rule(L, o, Rule) :-
    (   ty_gap(L, o, _) -> ty_gap(L, o, Rule) ; Rule = gap ).
ty_gap_rule(L, pp, Rule) :-
    ty_gap(L, pp, Rule0),
    ( Rule0 == moves -> Rule = moves(_) ; Rule = Rule0 ).

%% An adjunct's gap: the clause's adjuncts are gapped(Prep, X, Gap, Js), Js
%% the IR's list with pp(Prep, X) in it once (X gap, or of(gap, NP): `in
%% whose house'), the clause's own adjunct pp(Prep, Gap), which ty_adjuncts//2 reads
%% or writes beside the other adjuncts (`la casa en la que el perro duerme
%% hoy').
ty_gap_adjunct(Js0, Prep, X, G, gapped(Prep, X, G, Js0)) :-
    (   var(Js0) -> true ; once(member(pp(Prep, X), Js0)) ).

%% A role's gap is a subject's or a plain object's.
ty_role_gap(s).
ty_role_gap(o).

%% A gap whose adposition moved into the marker: its words.
ty_gap_moved_from(X, Ws) :-
    nonvar(X),
    (   X = gap(_, _, r(_, moves(Ws))) -> true
    ;   X = of(G, _), nonvar(G), G = gap(_, _, r(poss(j(_, Ws), _, _), Rule)), Rule == moves
    ).

%% What a gap writes where no role's marks stand (in an adposition phrase).
ty_gap_words(_, _, r(_, Rule)) --> { Rule \== resumptive }.
ty_gap_words(L, [_, N, A, G], r(_, resumptive)) --> ty_resumptive_words(L, [def, N, A, G]).

%% A pronoun that fits the head's features, the first ty_resumptive/3 row
%% written (Persian `او' for a living thing, `آن' for a thing, `آنها' for
%% several; `آن' is read of an animal too). Features not known yet (a head
%% after its clause) fit none.
ty_resumptive_words(L, F) -->
    ty_words(1, 2, Ws, ty_fitting(ty_resumptive(L), F, Ws)).

ty_fitting(Table, F, Ws) :-
    call(Table, Ws, Alternatives),
    once(( member(Need, Alternatives), ty_known_subset(Need, F) )).

ty_known_subset(Need, F) :-
    forall(member(X, Need), ( member(Y, F), ty_feature_is(X, Y) )).

%% A row's condition: every feature of Need among the Features (a person
%% is animate too).
ty_features_have([], _).
ty_features_have([X|Xs], F) :-
    (   memberchk(X, F) -> true
    ;   X == animate, memberchk(person, F)
    ),
    ty_features_have(Xs, F).

ty_feature_is(X, Y) :- ( Y == X -> true ; X == animate, Y == person ).

ty_rel_parts([], _, _, _, _, _, _) --> [].
ty_rel_parts([P|Ps], L, Role, NP, F, C, M) -->
    ty_rel_part(P, L, Role, NP, F, C, M),
    ty_rel_parts(Ps, L, Role, NP, F, C, M).

%% M is m(Words, r(Place, Rule)): the marker is looked up for the gap where
%% it is read, so a clause after a marker no row gives that gap is not
%% read at all (English: no marker is no subject's). A moved adposition's
%% marker is its words and a relative pronoun (`en la que', `in cui').
ty_rel_part(h, L, Role, NP, F, _, _) --> ty_marked_np(L, Role, NP, F, r).
ty_rel_part(m, L, _, _, _, _, m(Ws, R)) -->
    { R = r(poss(Pl, NP2, F2), Rule), Rule == moves }, !,
    ty_rel_comma(L),
    ty_poss_marker(Pl, L, NP2, F2, Ws).

ty_rel_part(m, L, _, _, _, _, m(Ws, R)) -->
    { ty_marker_span(R, Min, Max) },
    ty_rel_comma(L),
    ty_words(Min, Max, Ws, ty_marker_words(L, R, Ws)).
ty_rel_part(c, L, _, _, _, C, _) --> ty_rel_clause(L, C), ty_rel_close(L).

%% THE COMMAS OF A RELATIVE CLAUSE (ty_relative_comma(L): German `Der Hund,
%% der schläft, ist klein.'): a comma before the marker, and one after the
%% clause, which the writer drops where the sentence ends (ty_comma_join/2);
%% reading, the clause's comma is there, or the sentence ends.
ty_rel_comma(L) --> ( { ty_relative_comma(L) } -> [','] ; [] ).

ty_rel_close(L, S0, S) :-
    (   ty_relative_comma(L)
    ->  (   var(S0) -> S0 = [','|S]
        ;   S0 = [','|S1] -> S = S1
        ;   S0 == [], S = []
        )
    ;   S = S0
    ).

%% A moved possessor's marker: the possessive relative pronoun and the
%% possessed, between a role's marks (`a cuyos perros'), or after the
%% adjunct's adposition (`in whose house', `en cuya casa', `nella cui
%% casa'); Ws is the pronoun's words. The possessed takes the case of its role, or of the
%% adposition (German `dessen kleinen Hund', `in dessen kleinem Haus').
ty_poss_marker(j(Prep, AWs), L, NP2, F2, Ws) --> !,
    ty_words(1, 3, AWs, ty_adposition(L, Prep, AWs)),
    ty_words(1, 2, Ws, ty_relative_possessive(L, Ws, _)),
    { ty_case_after_words(L, AWs) },
    ty_np(L, NP2, F2, bare(none)).
ty_poss_marker(Role, L, NP2, F2, Ws) -->
    ty_mark_slot(L, Role, before, Before),
    ty_words(1, 2, Ws, ty_relative_possessive(L, Ws, _)),
    { ( ty_case(L, Role, C) -> b_setval('$ty_case', C) ; true ) },
    ty_np(L, NP2, F2, bare(none)),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_ok(L, Role, before, F2, Before),
      ty_marks_ok(L, Role, after, F2, After) }.

ty_marker_span(r(_, Rule), 2, 5) :- nonvar(Rule), Rule = moves(_), !.
ty_marker_span(_, 0, 2).

ty_marker_words(L, r(Pl, Rule), Ws) :-
    (   Rule = moves(AWs)
    ->  ty_moved_words(L, Pl, AWs),
        ty_relative_pronoun(L, PWs, _),
        append(AWs, PWs, Ws)
    ;   Rule == stays, Pl = poss(_, _, _)
    ->  ty_relative_possessive(L, Ws, _)
    ;   ty_gap_marker_role(Pl, Role),
        ty_relative(L, R, Ws, _),
        ty_fits(R, Role)
    ).

%% The adposition that moved: a complement's, of its verb (any verb's, the
%% verb not read yet), or an adjunct's.
ty_moved_words(L, c(V), Ws) :- ty_complement_words(L, V, Ws).
ty_moved_words(L, j(Prep), Ws) :- ty_adposition(L, Prep, Ws).

%% A gap in an adposition phrase takes the object's markers.
ty_gap_marker_role(s, s).
ty_gap_marker_role(o, o).
ty_gap_marker_role(c(_), o).
ty_gap_marker_role(j(_), o).
ty_gap_marker_role(poss(_, _, _), o).

%% A relative clause is a subordinate one (`$ty_sub'), whose verb
%% ty_verb_last/2 may put last.
ty_rel_clause(L, C) -->
    { C = clause(_, _, _, _, _, _) },
    (   { '$ty_sub_used'(L) } -> ty_sub(ty_clause(L, C)) ; ty_clause(L, C) ).
ty_rel_clause(L, C) -->
    { C = copula(_, _, _, _) },
    (   { '$ty_sub_used'(L) } -> ty_sub(ty_copula_clause(L, C)) ; ty_copula_clause(L, C) ).

ty_sub(G, S0, S) :-
    (   nb_current('$ty_sub', Old) -> true ; Old = no ),
    (   nb_current('$ty_kein', K) -> true ; K = none ),
    (   nb_current('$ty_kein_used', U) -> true ; U = no ),
    b_setval('$ty_sub', yes),
    phrase(G, S0, S),
    b_setval('$ty_sub', Old),
    b_setval('$ty_kein', K),
    b_setval('$ty_kein_used', U).

%% THE VERB LAST: ty_verb_last(L, rel) puts the verb (V, v or c) of a
%% relative clause after its other parts, the negation's too (German `der
%% Hund, den der Junge nicht sieht', `der Hund, der klein ist').
ty_verb_final(L, V, O0, O) :-
    (   nb_current('$ty_sub', yes), ty_verb_last(L, rel),
        selectchk(V, O0, O1)
    ->  append(O1, [V], O)
    ;   O = O0
    ).

%% The marker read is one a row gives for the gap and the head's features
%% (English `who' for an animate head, `which' for a thing; Spanish `en la
%% que' for a feminine one); a possessive relative pronoun's
%% row names the possessed's features, or the head's (German `dessen').
ty_rel_marker_ok(L, r(Pl, Rule), Features, Ws) :-
    Pl = poss(_, _, F2), ( Rule == moves ; Rule == stays ), !,
    ty_relative_possessive(L, Ws, Alternatives),
    member(Need, Alternatives),
    (   nonvar(Need), Need = head(H)
    ->  ty_features_have(H, Features)
    ;   ty_features_have(Need, F2)
    ), !.
%% A moved adposition's relative pronoun takes the adposition's case,
%% where the language has cases (German `in dem', `an das').
ty_rel_marker_ok(L, r(Pl, Rule), Features, Ws) :-
    (   Rule = moves(AWs)
    ->  append(AWs, PWs, Ws),
        ty_relative_pronoun(L, PWs, Alternatives),
        ( ty_case_after(L, AWs, C) -> F1 = [C|Features] ; F1 = Features )
    ;   ty_gap_marker_role(Pl, Role),
        ty_relative(L, R, Ws, Alternatives),
        ty_fits(R, Role),
        F1 = Features
    ),
    member(Need, Alternatives),
    ty_features_have(Need, F1), !.

%% The marks read are the ones the features need; in a repair, a mark
%% missing or too many is a fault.
ty_marks_ok(L, Role, Place, Features, Marks) :-
    ty_marks_needed(L, Role, Place, Features, Needed),
    (   Needed = Marks
    ->  true
    ;   ty_lenient,
        ty_fault(mark(Role, Marks, Needed))
    ).

ty_mark_slot(L, Role, Place, [W]) -->
    [W], { ty_mark(L, Role, Place, W, _) },
    ty_meant(L, mark(Role), [W]).
ty_mark_slot(_, _, _, []) --> [].

ty_marks_needed(L, Role, Place, Features, Marks) :-
    findall(W, ( ty_mark(L, Role, Place, W, Alternatives),
                 member(Need, Alternatives),
                 ty_features_have(Need, Features) ), Marks0),
    sort(Marks0, Marks).

%% ---- the cases ------------------------------------------------------------------
%%
%% A LANGUAGE WITH CASES (one with ty_case/3 rows: German) writes a noun
%% phrase in the case its place gives it: a role's (ty_case(L, Role,
%% Case), Role s, o, p or g) or an adposition's (ty_case_after(L, Words,
%% Case)). The case is kept for the phrase (`$ty_case') where the role or
%% the adposition stands, and the article (ty_article_case/6), the noun
%% (ty_noun_case/5, a form that is not the nominative's), an adjective's
%% ending and a question word (ty_wh_case/4) take it; a phrase where
%% nothing set one takes any.
ty_cased(L) :- '$ty_cased'(L).

%% Where a parse starts, the globals of a language with cases are set back.
ty_parse_reset(L) :-
    (   '$ty_cased'(L)
    ->  b_setval('$ty_case', any), b_setval('$ty_sub', no),
        b_setval('$ty_kein', none), b_setval('$ty_kein_np', no)
    ;   '$ty_kein_lang'(L)
    ->  b_setval('$ty_kein', none), b_setval('$ty_kein_np', no)
    ;   true
    ).

%% THE LANGUAGE'S FEATURES the hot paths ask, as facts typology_load/1
%% makes: a call of one is a step, where asking the rows was a once/1 that
%% failed. And a language with cases has each article of a case as a
%% ty_article/5 row of its definiteness, gender and number too.
ty_feats_make(L) :-
    retractall('$ty_cased'(L)), retractall('$ty_declines'(L)),
    retractall('$ty_kein_lang'(L)), retractall('$ty_sub_used'(L)),
    ( once(ty_case(L, _, _)) -> assertz('$ty_cased'(L)) ; true ),
    ( once(ty_adjective_ending(L, _, _, _, _, _)) -> assertz('$ty_declines'(L)) ; true ),
    ( once(ty_negative_article(L, _, _, _, _)) -> assertz('$ty_kein_lang'(L)) ; true ),
    (   ( once(ty_verb_last(L, _)) ; '$ty_kein_lang'(L) )
    ->  assertz('$ty_sub_used'(L))
    ;   true
    ),
    retractall('$ty_art_words'(L, _, _, _)),
    retractall('$ty_ending'(L, _, _, _, _, _)),
    forall(ty_article_case(L, Def, G, N, _, W),
           ( ty_article(L, Def, G, N, W) -> true ; assertz(ty_article(L, Def, G, N, W)) )),
    retractall('$ty_crow'(L, _, _, _, _, _)),
    retractall('$ty_cagree'(L, _, _, _, _, _)),
    forall(ty_copula(L, K, T, N, P, Ws),
           (   member(X, Ws), compound(X), X = agree(_)
           ->  ( '$ty_cagree'(L, K, T, N, P, Ws) -> true ; assertz('$ty_cagree'(L, K, T, N, P, Ws)) )
           ;   ( '$ty_crow'(L, K, T, N, P, Ws) -> true ; assertz('$ty_crow'(L, K, T, N, P, Ws)) ) )),
    retractall('$ty_cword'(L, _, _)),
    forall(( ty_copula(L, K, _, _, _, Ws), member(W, Ws), atom(W) ),
           ( '$ty_cword'(L, W, K) -> true ; assertz('$ty_cword'(L, W, K)) )),
    retractall('$ty_tlike'(L, _, _, _)), retractall('$ty_tlikes'(L)),
    forall(( member(Lv, [clause, copula]), ty_values(tense, Ts), member(T, Ts),
             ( ty_tense_like(L, Lv, T, As) -> true ; ty_tense_like(L, any, T, As) ) ),
           assertz('$ty_tlike'(L, Lv, T, As))),
    ( once('$ty_tlike'(L, _, _, _)) -> assertz('$ty_tlikes'(L)) ; true ),
    retractall('$ty_ptopic'(L)),
    ( once(ty_adposition_topic(L, _, _, _)) -> assertz('$ty_ptopic'(L)) ; true ),
    retractall('$ty_ppw'(L, _, _)),
    forall(( ty_possessive_pronoun(L, Ws1, _, _), Ws1 = [W1|_] ),
           ( '$ty_ppw'(L, W1, Ws1) -> true ; assertz('$ty_ppw'(L, W1, Ws1)) )),
    retractall('$ty_jfirst'(L, _)),
    (   ty_adjunct_front(L, v2)
    ->  forall(( ty_adverb(L, _, W2) ; ty_adposition(L, _, [W2|_]) ; ty_contraction(L, _, W2) ),
               ( '$ty_jfirst'(L, W2) -> true ; assertz('$ty_jfirst'(L, W2)) ))
    ;   true
    ),
    retractall('$ty_ofirst'(L, _)),
    (   ty_object_front(L, v2)
    ->  forall(( ty_front_word(L, W3, acc), \+ ty_front_word(L, W3, nom) ),
               ( '$ty_ofirst'(L, W3) -> true ; assertz('$ty_ofirst'(L, W3)) ))
    ;   true
    ),
    retractall('$ty_bare'(L, _)),
    forall(( ty_bare_topic(L, T), ty_topic(M, T), once(ty_noun(L, M, _, _, _, _)) ),
           ( '$ty_bare'(L, M) -> true ; assertz('$ty_bare'(L, M)) )),
    retractall('$ty_cmax'(L, _)),
    (   aggregate_all(max(Len), ( ty_copula_form(L, _, _, _, _, Ws0), length(Ws0, Len) ), Max)
    ->  assertz('$ty_cmax'(L, Max))
    ;   assertz('$ty_cmax'(L, 0))
    ),
    forall(ty_article_case(L, Def, _, _, C, W),
           ( '$ty_art_words'(L, Def, C, W) -> true ; assertz('$ty_art_words'(L, Def, C, W)) )),
    forall(ty_negative_article(L, _, _, C, W),
           ( '$ty_art_words'(L, kein, C, W) -> true ; assertz('$ty_art_words'(L, kein, C, W)) )),
    findall(C, ( ty_case(L, _, C) ; ty_case_after(L, _, C) ), Cs0),
    sort(Cs0, Cs),
    forall(( ty_adjective_ending(L, D, AC, G, N, E),
             ( AC == any -> member(C, Cs) ; C = AC ) ),
           ( '$ty_ending'(L, D, C, G, N, E) -> true ; assertz('$ty_ending'(L, D, C, G, N, E)) )).

:- dynamic('$ty_cased'/1).
:- dynamic('$ty_declines'/1).
:- dynamic('$ty_kein_lang'/1).
:- dynamic('$ty_sub_used'/1).
:- dynamic('$ty_art_words'/4).
:- dynamic('$ty_ending'/6).
:- dynamic('$ty_cagree'/6).
:- dynamic('$ty_cmax'/2).
:- dynamic('$ty_crow'/6).
:- dynamic('$ty_cword'/3).
:- dynamic('$ty_bare'/2).
:- dynamic('$ty_jfirst'/2).
:- dynamic('$ty_ofirst'/2).
:- dynamic('$ty_ppw'/3).
:- dynamic('$ty_ptopic'/1).
:- dynamic('$ty_tlike'/4).
:- dynamic('$ty_tlikes'/1).

ty_role_case(L, Role) :-
    (   ty_case(L, Role, C)
    ->  b_setval('$ty_case', C),
        ty_kein_mark(Role)
    ;   '$ty_kein_lang'(L)
    ->  ty_kein_mark(Role)
    ;   true
    ).

ty_kein_mark(Role) :-
    (   nb_current('$ty_kein', K), K \== none, K == Role
    ->  b_setval('$ty_kein_np', yes)
    ;   b_setval('$ty_kein_np', no)
    ).

ty_case_after_words(L, Ws) :-
    (   ty_case_after(L, Ws, C)
    ->  b_setval('$ty_case', C), b_setval('$ty_kein_np', no)
    ;   true
    ).

ty_case_now(L, C) :-
    (   '$ty_cased'(L), nb_current('$ty_case', C0) -> C = C0 ; C = any ).

ty_case_fits(AC, C) :- ( AC == any -> true ; C == any -> true ; AC == C ).

%% The article W fits the definiteness, the noun's gender and number, and
%% the phrase's case where the language has cases.
ty_article_fits(L, Def, G, N, W) :-
    (   '$ty_cased'(L)
    ->  ty_case_now(L, C),
        (   ty_kein_np
        ->  Def == indef,
            ty_negative_article(L, AG, AN, AC, W),
            ty_fits(AG, G), ty_fits(AN, N), ty_case_fits(AC, C),
            b_setval('$ty_kein_used', yes)
        ;   ty_article_case(L, Def, AG, AN, AC, W),
            ty_fits(AG, G), ty_fits(AN, N), ty_case_fits(AC, C)
        )
    ;   '$ty_kein_lang'(L), ty_kein_np, ( ty_negative_article_keeps(L) -> Def == indef ; true )
    ->  Def == indef,
        ty_negative_article(L, AG, AN, _, W),
        ty_fits(AG, G), ty_fits(AN, N),
        b_setval('$ty_kein_used', yes)
    ;   ty_article(L, Def, AG, AN, W), ty_fits(AG, G), ty_fits(AN, N)
    ).

%% A noun's word in the phrase's case: its case form where it has one,
%% else its form of the number.
ty_noun_here(L, M, G, A, N, W) :-
    (   '$ty_cased'(L)
    ->  ty_case_now(L, C),
        (   C == any
        ->  (   ty_noun_form(L, M, G, A, N, W)
            ;   ty_noun_case(L, M, _, N, W), ty_noun(L, M, G, A, _, _)
            )
        ;   ty_noun_case(L, M, C, N, W), ty_noun(L, M, G, A, _, _)
        ;   ty_noun_form(L, M, G, A, N, W), \+ ty_noun_case(L, M, C, N, _)
        )
    ;   ty_noun_form(L, M, G, A, N, W)
    ).

%% A noun phrase: its parts in an order the template keeps, then the check
%% that the article and the adjectives agree with the noun.
%% Its features: definiteness, number, animacy (which the marks ask) and
%% gender (which a predicate adjective agrees with).
ty_np(L, NP, Features) --> ty_np(L, NP, Features, none).

%% A noun phrase of `which' is definite to its marks (Spanish `a qué
%% perro', Persian `کدام سگ را'). Writing in a language with cases, the noun's
%% gender is known before its article and adjectives are chosen.
ty_np(L, NP, [FDef, N, Anim, G], Next) -->
    { NP = np(M, N, Def, As),
      ty_order_at(L, np, Order0),
      ty_np_split(L, Order0, Order, As, Bs, As2),
      (   nonvar(M), '$ty_cased'(L), once(ty_noun(L, M, G0, _, _, _))
      ->  Noun = noun(G0, _)
      ;   true
      ) },
    ty_np_parts(Order, L, np(M, N, Def, As2), got(Det, Noun, ARows, b(Bs, BRows)), Next),
    { Noun = noun(G, _),
      ( var(As) -> append(Bs, As2, As) ; true ),
      ( var(BRows) -> Adjs = ARows ; append(BRows, ARows, Adjs) ),
      ty_np_ok(L, NP, Det, Noun, Adjs, Anim, Next),
      ( Def == which -> FDef = def ; FDef = Def ) }.

%% ty_adjective_before(L, Meaning): the adjective stands before the noun
%% (French `le petit chien noir'): where the order has the adjectives after
%% the noun, a part b before it holds those of the IR's first adjectives
%% that are so, the longest run written first; reading, either place takes
%% one (`le chien petit' is read), and the IR's list is b's and then a's.
ty_np_split(L, Order0, Order, As, Bs, As2) :-
    (   once(ty_adjective_before(L, _)),
        append(X, [n|Y], Order0), memberchk(a, Y)
    ->  append(X, [b, n|Y], Order),
        ( var(As) -> true ; ty_before_run(L, As, Bs, As2) )
    ;   Order = Order0, Bs = [], As2 = As
    ).

ty_before_run(L, [A|As], [A|Bs], Rest) :- ty_adjective_before(L, A), ty_before_run(L, As, Bs, Rest).
ty_before_run(_, As, [], As).

ty_np_parts([], _, _, _, _) --> [].
ty_np_parts([P|Ps], L, NP, Got, Next) -->
    ty_np_part(P, Ps, L, NP, Got, Next),
    ty_np_parts(Ps, L, NP, Got, Next).

%% Each part knows the parts after it: a noun right before the adjectives
%% takes its linked form (the Persian ezafe), and so does each adjective
%% before another; the phrase's last word takes the form a relative
%% clause after it asks for (Next r).
%% Before a relative clause a head of a definiteness ty_relative_bare/2
%% names takes no article (Persian `حیوانی که', not `یک حیوانی که'): written
%% so, and read with the article too.
%% A noun phrase whose Next is bare(Next1) takes no article (English
%% `the boy's dog': the possessor stands for it).
ty_np_part(d, _, L, np(M, N, Def, _), got(Det, Noun, _, _), Next) -->
    (   { ty_no_article(Next, L, Def) ; Def == def, nonvar(M), '$ty_bare'(L, M) }
    ->  { Det = none }
    ;   ty_det(L, Def, Noun-N, Det)
    ).

%% Indexed by Next, so a phrase with nothing after it (none) asks nothing.
ty_no_article(bare(_), _, _).
ty_no_article(r, L, Def) :- nonvar(Def), ty_relative_bare(L, Def).
ty_np_part(n, Ps, L, np(M, N, _, As), got(_, noun(G, A), _, _), Next) -->
    [W],
    { ty_linked_here(Ps, As, Next, C2, Linked),
      ty_linked_word(L, n, C2, Linked, W0, W, ty_noun_lookup(L, M, G, A, N, W0)) },
    ty_meant(L, noun(M), [W]).
ty_np_part(a, Ps, L, np(_, N, _, As), got(Det, Noun, Rows, _), Next) -->
    { ( Ps == [] -> End = Next ; End = none ),
      (   '$ty_declines'(L)
      ->  ty_declined(L, Det, Next, D0), D = decl(D0, Noun-N)
      ;   D = plain
      ) },
    ty_adjs(L, As, Rows, End, D).
ty_np_part(b, _, L, np(_, N, _, _), got(Det, Noun, _, b(Bs, Rows)), Next) -->
    {   '$ty_declines'(L)
    ->  ty_declined(L, Det, Next, D0), D = decl(D0, Noun-N)
    ;   D = plain
    },
    ty_adjs(L, Bs, Rows, none, D),
    { forall(member(A, Bs), ty_adjective_before(L, A)) }.

%% Reading, the adjectives are not known yet when the noun is: each case is
%% a branch.
ty_linked_here([a|Ps], As, Next, C2, Linked) :- !,
    (   As = [_|_], C2 = a, Linked = yes
    ;   As = [], ty_linked_end(Ps, Next, C2, Linked)
    ).
ty_linked_here(Ps, _, Next, C2, Linked) :- ty_linked_end(Ps, Next, C2, Linked).

%% The phrase's last word takes the form of what follows it: r a relative
%% clause, g a possessor (the Persian ezafe), h the possessed (English
%% `'s'), clitic(N) a possessor's clitic (Persian `ش').
ty_linked_end([], Next, C2, Linked) :- !, ty_end_link(Next, C2, Linked).
ty_linked_end(_, _, a, no).

ty_end_link(none, a, no) :- !.
ty_end_link(bare(N), C2, Linked) :- !, ty_end_link(N, C2, Linked).
ty_end_link(C, C, yes).

ty_next_link(Next, C) :- ( nonvar(Next), Next = bare(C0) -> C = C0 ; C = Next ).
ty_next_bare(Next) :- nonvar(Next), Next = bare(_).

%% Reading the word is bound and the table is asked by it; writing, by the
%% meaning.
%% In a repair a noun may stand for its other number too, a fault: `Los
%% perro ven' is `Los perros ven', one fault, not `El perro ve', two.
ty_noun_lookup(L, M, G, A, N, W) :-
    (   '$ty_cased'(L)
    ->  ty_noun_here(L, M, G, A, N, W)
    ;   ty_noun_form(L, M, G, A, N, W)
    ;   ty_lenient,
        ty_noun_here(L, M, G, A, N1, W),
        ty_other_number(N1, N),
        ty_fault(agreement(noun, W))
    ).

ty_noun_form(L, M, G, A, sg, W) :- ty_noun(L, M, G, A, W, _).
ty_noun_form(L, M, G, A, pl, W) :- ty_noun(L, M, G, A, _, W).

%% The article: reading, the word's own; writing, the words of the
%% definiteness the IR asks, of the phrase's case where the language has
%% cases, each word once.
ty_det(L, Def, GN, art(W)) -->
    [W],
    {   '$ty_cased'(L) -> ty_det_word(L, Def, GN, W)
    ;   '$ty_kein_lang'(L), ty_kein_np -> ty_det_word(L, Def, GN, W)
    ;   ty_article(L, _, _, _, W)
    }.
ty_det(_, _, _, none) --> [].

ty_det_word(L, Def, GN, W) :-
    (   nonvar(W)
    ->  (   ty_kein_np
        ->  (   ty_negative_article_keeps(L)
            ->  once(( ty_negative_article(L, _, _, _, W) ; ty_article(L, _, _, _, W) ))
            ;   once(ty_negative_article(L, _, _, _, W))
            )
        ;   once(ty_article(L, _, _, _, W))
        )
    ;   ty_kein_np, ( ty_negative_article_keeps(L) -> Def == indef ; true )
    ->  Def == indef,
        ty_case_now(L, C),
        ty_case_words(L, kein, C, Ws),
        member(W, Ws),
        ty_det_fits(L, kein, GN, C, W)
    ;   nonvar(Def), '$ty_cased'(L)
    ->  ty_case_now(L, C),
        ty_case_words(L, Def, C, Ws),
        member(W, Ws),
        ty_det_fits(L, Def, GN, C, W)
    ;   ty_article(L, _, _, _, W)
    ).

%% Writing, an article word fits the noun the IR names.
ty_det_fits(L, Def, GN, C, W) :-
    (   nonvar(GN), GN = noun(G, _)-N, nonvar(G)
    ->  (   Def == kein
        ->  once(( ty_negative_article(L, AG, AN, AC, W), ty_fits(AG, G), ty_fits(AN, N), ty_case_fits(AC, C) ))
        ;   once(( ty_article_case(L, Def, AG, AN, AC, W), ty_fits(AG, G), ty_fits(AN, N), ty_case_fits(AC, C) ))
        )
    ;   true
    ).

%% The article words of a definiteness (or kein) and a case, each once, as
%% typology_load/1 keeps them (`$ty_art_words'/4); of every case where
%% the case is not known.
ty_case_words(L, Def, C, Ws) :-
    (   C == any
    ->  findall(W, '$ty_art_words'(L, Def, _, W), Ws0), list_to_set(Ws0, Ws)
    ;   findall(W, '$ty_art_words'(L, Def, C, W), Ws)
    ).

ty_adjs(L, As, Rows) --> ty_adjs(L, As, Rows, none, plain).

%% End r: the last adjective is the phrase's last word before a relative
%% clause. D is plain, or decl(Declension) where the language puts an
%% ending on an adjective before a noun (ty_declined/4).
ty_adjs(_, [], [], _, _) --> [].
ty_adjs(L, [A|As], [adj(G, N)|Rows], End, plain) -->
    [W],
    { (   As = [_|_], C2 = a, Linked = yes
      ;   As = [], ty_linked_end([], End, C2, Linked)
      ),
      ty_linked_word(L, a, C2, Linked, W0, W, ty_adjective(L, A, G, N, W0)) },
    ty_meant(L, adjective(A), [W]),
    ty_adjs(L, As, Rows, End, plain).
ty_adjs(L, [A|As], [adj(G, N)|Rows], End, decl(D, GN)) -->
    [W],
    { (   As = [_|_], C2 = a, Linked = yes
      ;   As = [], ty_linked_end([], End, C2, Linked)
      ),
      ty_linked_word(L, a, C2, Linked, W0, W, ty_adjective_in(decl(D, GN), L, A, G, N, W0)) },
    ty_meant(L, adjective(A), [W]),
    ty_adjs(L, As, Rows, End, decl(D, GN)).

%% An adjective's word: its row's; or, declined, the row's word (the
%% predicate's, `klein') and an ending of the declension and the phrase's
%% case, the gender and the number the ending is for (`kleine', `kleinen').
ty_adjective_in(plain, L, A, G, N, W) :- ty_adjective(L, A, G, N, W).
%% The endings are asked of `$ty_ending'/6, the rows by case that
%% typology_load/1 makes (a row of any case one a case).
ty_adjective_in(decl(D, GN), L, A, G, N, W) :-
    ty_case_now(L, C0),
    ( C0 == any -> true ; C = C0 ),
    (   nonvar(W)
    ->  '$ty_ending'(L, D, C, G, N, E),
        atom_concat(S, E, W), ty_adjective(L, A, _, _, S)
    ;   ty_adjective(L, A, _, _, S),
        '$ty_ending'(L, D, C, G, N, E),
        ty_ending_fits(GN, G, N),
        atom_concat(S, E, W)
    ).

%% Writing, an ending fits the noun the IR names.
ty_ending_fits(GN, G, N) :-
    (   nonvar(GN), GN = noun(G1, _)-N1, nonvar(G1) -> ty_fits(G, G1), ty_fits(N, N1) ; true ).

%% THE DECLENSION of a noun phrase's adjectives, where the language puts
%% endings on them (ty_adjective_ending/6 rows): ty_declension(L, Def, D)
%% by the article's definiteness, `none' for a phrase with no article
%% (German weak after `der', mixed after `ein', strong with none), mixed after
%% a possessive pronoun (`$ty_bare_decl': `mein kleiner Hund', `mit meinem
%% kleinen Hund'); an
%% article read before them tells it; a language with no endings
%% (no `$ty_declines' fact) has plain ones.
ty_declined(L, Det, _, D0) :-
    (   nonvar(Det), Det = art(W)
    ->  (   ty_article_case(L, Def, _, _, _, W) -> true
        ;   ty_negative_article(L, _, _, _, W) -> Def = indef
        ;   Def = def
        ),
        ty_declension(L, Def, D0)
    ;   nb_current('$ty_bare_decl', BD), BD \== none
    ->  ty_declension(L, BD, D0)
    ;   ty_declension(L, none, D0)
    ).

%% The word W0 of the table, written W: itself, or its linked form when a
%% word of class C2 follows it. Lookup finds W0; reading it runs after W0 is
%% taken back from W, writing before W is made from it.
ty_linked_word(_, _, _, no, W, W, Lookup) :- !, call(Lookup).
ty_linked_word(L, C1, C2, yes, W0, W, Lookup) :-
    (   nonvar(W)
    ->  ty_unlinked(L, C1, C2, W, W0), call(Lookup), ty_link_form(L, C1, C2, W0, W1), W1 == W
    ;   call(Lookup), ty_link_form(L, C1, C2, W0, W)
    ).

%% The linked form: the longest ending a ty_linked/5 row names, replaced;
%% a word no row fits is unchanged (the ezafe is not written after a
%% consonant).
ty_link_form(L, C1, C2, W0, W) :-
    findall(Len-(From-To), ( ty_linked(L, C1, C2, From, To),
                             atom_concat(_, From, W0),
                             atom_length(From, Len) ), Fits),
    (   Fits == []
    ->  W = W0
    ;   keysort(Fits, Sorted), last(Sorted, _-(From-To)),
        atom_concat(Stem, From, W0), atom_concat(Stem, To, W)
    ).

ty_unlinked(_, _, _, W, W).
ty_unlinked(L, C1, C2, W, W0) :-
    ty_linked(L, C1, C2, From, To),
    atom_concat(Stem, To, W),
    atom_concat(Stem, From, W0),
    W0 \== W.

%% The word W of class C1 stands for: itself, or a word any linked form
%% of which it is (before an adjective, before a relative clause).
ty_base_word(_, _, W, W).
ty_base_word(L, C1, W, W0) :-
    member(C2, [a, r]),
    ty_unlinked(L, C1, C2, W, W0),
    W0 \== W.

ty_np_ok(L, NP, Det, Noun, Rows, Anim, Next) :-
    (   ty_np_agrees(L, NP, Det, Noun, Rows, Anim, Next)
    *-> true
    ;   ty_lenient,
        ty_np_faults(L, NP, Det, Noun, Rows, Anim, Next)
    ).

ty_np_agrees(L, np(M, N, Def, _), Det, noun(G, Anim), Rows, Anim, Next) :-
    ty_values(definiteness, Defs), member(Def, Defs),
    forall(member(adj(RG, RN), Rows), ( ty_fits(RG, G), ty_fits(RN, N) )),
    (   Det = art(W)
    ->  (   '$ty_cased'(L)
        ->  once(ty_article_fits(L, Def, G, N, W))
        ;   '$ty_kein_lang'(L), ty_kein_np
        ->  once(ty_article_fits(L, Def, G, N, W))
        ;   ty_article(L, Def, AG, AN, W), ty_fits(AG, G), ty_fits(AN, N)
        )
    ;   Def \== which,
        (   Next == none
        ->  (   Def == def, nonvar(M), '$ty_bare'(L, M) -> true ; \+ ty_article_fits(L, Def, G, N, _) )
        ;   Next = bare(_)
        ->  Def == def
        ;   Next == r, ty_relative_bare(L, Def)
        ->  true
        ;   \+ ty_article_fits(L, Def, G, N, _)
        )
    ).

%% A NOUN OF A TOPIC THE LANGUAGE WRITES WITH NO ARTICLE (ty_bare_topic/2:
%% the months in English, Spanish, Italian and French): a definite phrase
%% of it has none (`in March', `en marzo', `a marzo'), where German keeps
%% its article (`im März'). `$ty_bare'/2 holds the meanings, made at load.

%% In a repair: an adjective or an article that does not agree, and a noun
%% phrase with no article where it needs one, are each a fault; the
%% article keeps its own definiteness.
ty_np_faults(L, np(_, N, Def, _), Det, noun(G, Anim), Rows, Anim, Next) :-
    ty_values(definiteness, Defs), member(Def, Defs),
    (   forall(member(adj(RG, RN), Rows), ( ty_fits(RG, G), ty_fits(RN, N) ))
    ->  true
    ;   ty_fault(agreement(adjective))
    ),
    (   Det = art(W)
    ->  once(ty_article(L, Def, _, _, W)),
        (   ty_article_fits(L, Def, G, N, W)
        ->  true
        ;   ty_fault(agreement(article, W))
        )
    ;   Def \== which,
        (   (   ty_next_bare(Next), Def == def
            ;   Next == r, ty_relative_bare(L, Def)
            ;   \+ ty_article_fits(L, Def, G, N, _)
            )
        ->  true
        ;   ty_fault(article(missing))
        )
    ).

ty_fits(any, _) :- !.
ty_fits(X, X).

%% A tense a row's tense fits: any of the tenses where the row says any.
ty_tense_fit(T0, T) :-
    (   T0 == any -> ty_values(tense, Ts), member(T, Ts) ; T = T0 ).

%% ---- the word tables from corpus/vocabulary ---------------------------------------
%%
%% A vocabulary file is lesson lines of a few fixed shapes, read here by
%% their shape and not by the grammar, so 160 000 lines take seconds:
%%
%%     The masculine noun "perro" means "dog".      (feminine, or no gender)
%%     The feminine adjective "negra" means "black".
%%     The verb "ve" means "sees".                  (the third person)
%%     "perros" is the plural of "perro".           (a verb's too: "ven")
%%     "vio" is the past of "ve".                   ("vieron" of "ven")
%%     "perro" is animate.   "niño" is a person.   "casa" is feminine.
%%
%% Only complete entries are written, and only single words; a row the hand
%% template has already (its meaning and its word) is not written again.
%%
%% A FORM BELONGS TO THE CLASS OF THE ENTRY ITS LINE FOLLOWS. The file puts
%% each entry's forms right after it, and one spelling can be two words:
%% `fría' is an adjective whose plural is `frías', and a form of `freír'
%% whose plural is `frían'. So a form line is kept with the class of the
%% last entry line (tyi_form(Kind, Form, Of, Class)), and a noun's plural is
%% asked of the nouns' blocks alone. A name's line starts no block: the English
%% pasts stand alone, some after a name (`"broadcast" is the past of
%% "broadcasts"' after `copenaghen'), and the block they fall in is
%% the verbs' one the English import asks.

:- dynamic tyi_entry/4, tyi_form/4, tyi_lex/3, tyi_animate/1, tyi_gender/2, tyi_count/2,
           tyi_hand/1, tyi_class/2, tyi_name/1, tyi_class_word/4, tyi_person/1,
           tyi_sense/2, tyi_sense_word/4, tyi_vbase/2.

typology_import(Name) :-
    must_be(atom, Name),
    ty_dir(Dir),
    (   Name == template
    ->  atomic_list_concat([Dir, '/templates/template.pl'], File)
    ;   atomic_list_concat([Dir, '/templates/', Name, '-words.pl'], File)
    ),
    typology_import(Name, File).

%% The hand template's rows are READ from its file, not asked of the
%% knowledge base, so what is loaded (a words file, an earlier import)
%% changes nothing in what is written.
%% The name template is the blank template, written as typology_template(xx)
%% writes it.
typology_import(template, File) :- !,
    with_output_to(codes(Codes), typology_template(xx)),
    write_file_from_codes(File, Codes),
    format("template: the blank template into ~w~n", [File]).
typology_import(Name, File) :-
    must_be(atom, Name),
    ty_import_reset,
    ty_hand_rows(Name, Hand),
    forall(member(H, Hand), assertz(tyi_hand(H))),
    ty_import_senses,
    (   Name == english
    ->  findall(V, ( member(Src, [spanish, italian]), ty_vocabulary_file(Src, V) ), Vs),
        Vs \== [],
        forall(member(V, Vs), ty_read_vocabulary(V)),
        ty_read_lexicon(english),
        findall(R, ty_english_row(R), Rows0)
    ;   Name == topics
    ->  findall(Src-V, ( member(Src, [spanish, italian]), ty_vocabulary_file(Src, V) ), Vs),
        Vs \== [],
        forall(member(Src-V, Vs),
               ( ty_sense_words(Src), ty_read_vocabulary(V), ty_keep_class_words(Src),
                 ty_import_reset_words )),
        findall(R, ty_topic_row(R), Rows0)
    ;   ty_vocabulary_file(Name, V),
        ty_read_vocabulary(V),
        findall(R, ty_import_row(Name, R), Rows0)
    ),
    ty_dedupe(Rows0, Rows1),
    ty_kind_split(Rows1, Kinds, Rows),
    (   Rows == []
    ->  ( exists_file(File) -> delete_file(File) ; true ),
        format("~w: no rows left for ~w, which is not written~n", [Name, File])
    ;   length(Rows, NRows),
        with_output_to(codes(Codes), ty_write_rows(Name, Rows)),
        write_file_from_codes(File, Codes),
        format("~w: ~w rows into ~w~n", [Name, NRows, File])
    ),
    forall(member(Kind-KRows, Kinds),
           ( ty_kind_file(File, Kind, KFile),
             with_output_to(codes(KCodes), ty_write_kind_rows(Name, Kind, KRows)),
             write_file_from_codes(KFile, KCodes),
             length(KRows, NK),
             format("~w: ~w rows into ~w~n", [Name, NK, KFile]) )),
    forall(tyi_count(What, N), format("  ~w: ~w~n", [What, N])),
    ty_import_reset.

%% The rows once each, in the vocabulary's order: a word's first meaning
%% there is the first it is read as.
ty_dedupe(Rows0, Rows) :-
    findall(R-I, nth1(I, Rows0, R), Pairs0),
    msort(Pairs0, Pairs1),
    ty_first_of_each(Pairs1, Firsts),
    findall(I-R, member(R-I, Firsts), ByPlace0),
    keysort(ByPlace0, ByPlace),
    findall(R, member(_-R, ByPlace), Rows).

ty_first_of_each([], []).
ty_first_of_each([R-I|Ps], [R-I|Fs]) :-
    ty_skip_same(R, Ps, Rest),
    ty_first_of_each(Rest, Fs).

ty_skip_same(R, [R1-_|Ps], Rest) :- R1 == R, !, ty_skip_same(R, Ps, Rest).
ty_skip_same(_, Ps, Ps).

ty_dir(Dir) :-
    absolute_file_name(library(reasoning/typology), F, [file_type(prolog), access(read)]),
    file_directory_name(F, Dir).

ty_vocabulary_file(Name, File) :-
    atomic_list_concat(['corpus/vocabulary/', Name, '.txt'], Rel),
    catch(absolute_file_name(library(reasoning/Rel), File, [access(read)]), _, fail).

ty_hand_rows(Name, Rows) :-
    ty_file(Name, File),
    use_module(library(stream)),
    setup_call_cleanup(open(File, read, S), ty_read_terms(S, Rows), close(S)).

ty_read_terms(S, Ts) :-
    read_term(S, T, []),
    (   T == end_of_file -> Ts = [] ; Ts = [T|Ts1], ty_read_terms(S, Ts1) ).

ty_import_reset :-
    ty_import_reset_words,
    retractall(tyi_lex(_, _, _)),
    retractall(tyi_class_word(_, _, _, _)),
    retractall(tyi_count(_, _)), retractall(tyi_hand(_)),
    retractall(tyi_sense(_, _)), retractall(tyi_sense_word(_, _, _, _)).

%% What one vocabulary's lines say: the topic import reads each vocabulary
%% in turn and keeps only its class words between them.
ty_import_reset_words :-
    retractall(tyi_entry(_, _, _, _)), retractall(tyi_form(_, _, _, _)),
    retractall(tyi_animate(_)), retractall(tyi_gender(_, _)),
    retractall(tyi_class(_, _)), retractall(tyi_name(_)), retractall(tyi_person(_)),
    retractall(tyi_vbase(_, _)).

ty_count(What) :-
    (   retract(tyi_count(What, N0)) -> N is N0 + 1 ; N = 1 ),
    assertz(tyi_count(What, N)).

ty_read_vocabulary(File) :-
    read_file_to_codes(File, Codes),
    split_string(Codes, "\n", "", Lines),
    nb_setval('$ty_block', none),
    forall(member(S, Lines), ( atom_string(Line, S), ty_vocabulary_line(Line) )).

ty_vocabulary_line(Line) :-
    atomic_list_concat(Parts, '"', Line),
    (   Parts = [Head, W, ' means ', M, '.'], ty_entry_head(Head, Class, G)
    ->  assertz(tyi_entry(Class, G, W, M)),
        nb_setval('$ty_block', Class)
    ;   Parts = ['', A, Rel, B, '.'], ty_form_relation(Rel, Kind)
    ->  nb_getval('$ty_block', Class),
        assertz(tyi_form(Kind, A, B, Class))
    ;   Parts = ['The name ', W, ' means ', _, '.']
    ->  assertz(tyi_name(W))
    ;   Parts = ['', W, Says], ty_says(Says, Fact, W)
    ->  assertz(Fact)
    ;   Parts = ['', W, Says], ty_class_says(Says, C)
    ->  assertz(tyi_class(W, C))
    ;   true
    ).

ty_entry_head('The masculine noun ', noun, m).
ty_entry_head('The feminine noun ', noun, f).
ty_entry_head('The noun ', noun, none).
ty_entry_head('The masculine adjective ', adjective, m).
ty_entry_head('The feminine adjective ', adjective, f).
ty_entry_head('The adjective ', adjective, none).
ty_entry_head('The verb ', verb, none).

ty_form_relation(' is the plural of ', plural).
ty_form_relation(' is the past of ', past).
ty_form_relation(' is the first person of ', first).
ty_form_relation(' is the second person of ', second).
ty_form_relation(' is the participle of ', participle).
ty_form_relation(' is the infinitive of ', infinitive).
ty_form_relation(' is the future of ', future).
ty_form_relation(' is the imperfect of ', imperfect).
ty_form_relation(' is the conditional of ', conditional).

ty_says(' is animate.', tyi_animate(W), W).
ty_says(' is a person.', tyi_person(W), W).
ty_says(' is feminine.', tyi_gender(W, f), W).
ty_says(' is not feminine.', tyi_gender(W, m), W).

%% `"sábado" is a time.': the word's class.
ty_class_says(Says, C) :-
    (   atom_concat(' is a ', Rest, Says) -> true ; atom_concat(' is an ', Rest, Says) ),
    atom_concat(C, '.', Rest),
    ty_single(C).

%% The senses of their own (templates/topics.pl's ty_meaning_sense/2,
%% read from the file as the hand rows are), and the words of a
%% vocabulary's hand template that have one.
ty_import_senses :-
    (   catch(ty_hand_rows(topics, Rows), _, Rows = [])
    ->  forall(member(ty_meaning_sense(S, M), Rows), assertz(tyi_sense(S, M)))
    ;   true
    ).

ty_sense_words(Src) :-
    (   catch(ty_hand_rows(Src, Rows), _, Rows = [])
    ->  forall(( member(ty_noun(Src, S, _, _, W, _), Rows), tyi_sense(S, M) ),
               assertz(tyi_sense_word(Src, W, M, S)))
    ;   true
    ).

%% THE TOPICS A CLASS GIVES its words' meanings: the class, and a wider
%% topic. A class not here (person, group, name) says how a word is used,
%% not what it is about.
ty_class_topics(time, [time]).
ty_class_topics(month, [month, time]).
ty_class_topics(measure, [measure]).
ty_class_topics(institution, [institution]).
ty_class_topics(street, [street, place]).
ty_class_topics(city, [city, place]).
ty_class_topics(country, [country, place]).
ty_class_topics(region, [region, place]).
ty_class_topics(continent, [continent, place]).

%% A class word of one vocabulary, with its noun meanings in the
%% vocabulary's order (tyi_class_word(Vocabulary, Word, Class, Meanings)).
%% A meaning a hand template gives the word a sense of its own for is that
%% sense (tyi_sense_word/4: `marzo' is march_month).
%% A word that is also a name is the name's (`mosca' is a city as Moscow,
%% and its noun is a fly), and a name is no meaning of the IR.
ty_keep_class_words(Src) :-
    forall(( tyi_class(W, C), ty_class_topics(C, _) ),
           (   tyi_name(W) -> ty_count(class_word_that_is_a_name)
           ;   findall(M, ( tyi_entry(noun, _, W, M0), ty_single(M0),
                            ( tyi_sense_word(Src, W, M0, S) -> M = S ; M = M0 ) ), Ms0),
               ty_first_each(Ms0, Ms),
               (   Ms == [] -> ty_count(class_word_with_no_noun)
               ;   assertz(tyi_class_word(Src, W, C, Ms))
               )
           )).

ty_first_each([], []).
ty_first_each([X|Xs], [X|Ys]) :-
    exclude(==(X), Xs, Xs1),
    ty_first_each(Xs1, Ys).

%% A word of one noun meaning gives the meaning its class's topics. A word
%% of several gives the first that another word of the class gives too, in
%% either vocabulary (`volta', a time and a vault, gives the time `vez'
%% gives), and none where no other word gives one (`metro', a metre and a
%% subway). A meaning is its own topic already, so `month' is no
%% row of the month's.
ty_topic_row(ty_topic(M, T)) :-
    tyi_class_word(Src, W, C, Ms),
    (   Ms = [M] -> true
    ;   member(M, Ms), ty_class_shared(Src-W, C, M) -> true
    ;   ty_count(class_word_of_several_meanings), fail
    ),
    ty_class_topics(C, Ts),
    member(T, Ts),
    T \== M,
    (   tyi_hand(ty_topic(M, T)) -> ty_count(topic_in_the_hand_table), fail ; true ).

ty_class_shared(Src-W, C, M) :-
    tyi_class_word(Src1, W1, C, Ms1),
    Src1-W1 \== Src-W,
    memberchk(M, Ms1), !.

ty_single(W) :- \+ sub_atom(W, _, _, _, ' ').

%% A word's animacy as the vocabulary says it: a person (`"niño" is a
%% person.'), animate (`"perro" is animate.'), or unknown.
ty_word_animacy(W, Anim) :-
    (   tyi_person(W) -> Anim = person
    ;   tyi_animate(W) -> Anim = animate
    ;   Anim = unknown
    ).

ty_once_form(Kind, Class, Of, Form) :- once(( tyi_form(Kind, Form, Of, Class), ty_single(Form) )).

%% The rows of a language that has a vocabulary.
ty_import_row(L, ty_noun(L, M, G, Anim, W, P)) :-
    tyi_entry(noun, G0, W, M),
    (   ty_single(W), ty_single(M) -> true ; ty_count(noun_not_a_single_word), fail ),
    (   tyi_hand(ty_noun(L, S, _, _, W, _)), tyi_sense(S, M)
    ->  ty_count(noun_with_a_sense_of_its_own), fail
    ;   true
    ),
    (   G0 \== none -> G = G0
    ;   once(tyi_gender(W, G)) -> true
    ;   ty_count(noun_with_no_gender), fail
    ),
    (   ty_once_form(plural, noun, W, P) -> true ; ty_count(noun_with_no_plural), fail ),
    ty_word_animacy(W, Anim),
    (   tyi_hand(ty_noun(L, M, _, _, W, _)) -> ty_count(noun_in_the_hand_template), fail ; true ).
ty_import_row(L, ty_adjective(L, M, G, N, W)) :-
    setof(M0, G0^W0^tyi_entry(adjective, G0, W0, M0), Ms),
    member(M, Ms),
    ty_single(M),
    findall(R, ty_adjective_form(M, R), Forms),
    (   ty_adjective_complete(Forms) -> true ; ty_count(adjective_meaning_incomplete), fail ),
    member(form(G, N, W), Forms),
    \+ tyi_hand(ty_adjective(L, M, _, _, W)).
ty_import_row(L, ty_verb(L, B, T, N, pos, [W])) :-
    tyi_entry(verb, _, W3, M3),
    (   ty_single(W3), ty_single(M3) -> true ; ty_count(verb_not_a_single_word), fail ),
    (   ty_once_form(plural, verb, W3, W3p), ty_once_form(past, verb, W3, Wp),
        ty_once_form(past, verb, W3p, Wpp)
    ->  true
    ;   ty_count(verb_with_a_form_missing), fail
    ),
    reason_base(M3, B),
    (   tyi_hand(ty_verb(L, B, present, sg, pos, [W3])) -> ty_count(verb_in_the_hand_template), fail ; true ),
    (   ty_copula_word(L, W3) -> ty_count(verb_that_is_a_copula_word), fail ; true ),
    member(T-N0-W0, [present-sg-W3, present-pl-W3p, past-sg-Wp, past-pl-Wpp]),
    ty_person_rows(N0, W0, N, W).

%% A verb's participle, as the vocabulary states it (`"visto" is the
%% participle of "ve"').
ty_import_row(L, ty_participle(L, B, P)) :-
    ty_import_verb(L, W3, _, B),
    \+ tyi_hand(ty_participle(L, B, _)),
    (   ty_once_form(participle, verb, W3, P) -> true ; ty_count(verb_with_no_participle), fail ).
%% A verb's future: the singular and the plural the vocabulary states
%% (`"nacerá" is the future of "nace"'), the other persons on the stem of
%% the singular (the template's ending future(sg) taken off); else on the
%% stem the template's ending future_stem makes of the infinitive (Spanish
%% `ver', `tener' `tendr'; Italian `parlare' `parler'), each person's
%% ending future(N) after it.
ty_import_row(L, ty_verb(L, B, future, N, pos, [F])) :-
    ty_import_verb(L, W3, W3p, B),
    \+ tyi_hand(ty_verb(L, B, future, _, _, _)),
    (   ty_future_stem(L, W3, Stem) -> true ; ty_count(verb_with_no_future), fail ),
    member(N, [sg, pl, sg(1), sg(2), pl(1), pl(2)]),
    (   N == sg, ty_once_form(future, verb, W3, F0) -> F = F0
    ;   N == pl, ty_once_form(future, verb, W3p, F0) -> F = F0
    ;   ty_apply_ending(L, future(N), Stem, F)
    ).

%% A verb's imperfect and conditional, where the template gives endings
%% for them: the singular and the plural the vocabulary states (`"veía" is
%% the imperfect of "ve"'), else the imperfect's singular made of the
%% infinitive by the template's ending imperfect (Spanish `ar' `aba',
%% Italian `are' `ava') and its plural of the singular, the conditional's
%% on the future's stem; a first or second person the vocabulary states of
%% the third (`"ibas" is the second person of "iba"'), else the template's
%% ending of the person, on the singular (the imperfect: Italian `vedeva'
%% `vedevo') or on the stem (the conditional: `vedr' `vedrei').
ty_import_row(L, ty_verb(L, B, imperfect, N, pos, [F])) :-
    once(tyi_hand(ty_ending(L, imperfect, _, _))),
    ty_import_verb(L, W3, W3p, B),
    \+ tyi_hand(ty_verb(L, B, imperfect, _, _, _)),
    (   ty_imperfect_sg(L, W3, I3) -> true ; ty_count(verb_with_no_imperfect), fail ),
    (   ty_once_form(imperfect, verb, W3p, I3p0) -> I3p = I3p0
    ;   ty_apply_ending(L, imperfect(pl), I3, I3p)
    ),
    member(N, [sg, pl, sg(1), sg(2), pl(1), pl(2)]),
    ty_tense_person(L, imperfect, N, I3, I3p, I3, F).
ty_import_row(L, ty_verb(L, B, conditional, N, pos, [F])) :-
    once(tyi_hand(ty_ending(L, conditional(_), _, _))),
    ty_import_verb(L, W3, W3p, B),
    \+ tyi_hand(ty_verb(L, B, conditional, _, _, _)),
    (   ty_future_stem(L, W3, Stem) -> true ; ty_count(verb_with_no_conditional), fail ),
    (   ty_once_form(conditional, verb, W3, C30) -> C3 = C30
    ;   ty_apply_ending(L, conditional(sg), Stem, C3)
    ),
    (   ty_once_form(conditional, verb, W3p, C3p0) -> C3p = C3p0
    ;   ty_apply_ending(L, conditional(pl), Stem, C3p)
    ),
    member(N, [sg, pl, sg(1), sg(2), pl(1), pl(2)]),
    ty_tense_person(L, conditional, N, C3, C3p, Stem, F).

ty_imperfect_sg(L, W3, I3) :-
    (   ty_once_form(imperfect, verb, W3, I0) -> I3 = I0
    ;   ty_once_form(infinitive, verb, W3, Inf),
        ty_apply_ending(L, imperfect, Inf, I3)
    ).

%% A person's form of a tense: the third persons as given; a first or a
%% second the vocabulary states of the third (sg(P) of the singular, pl(P)
%% of the plural), else the ending Tense(N) on Base.
ty_tense_person(_, _, sg, F3, _, _, F3).
ty_tense_person(_, _, pl, _, F3p, _, F3p).
ty_tense_person(L, T, N, F3, F3p, Base, F) :-
    N =.. [N0, P], integer(P),
    ( P =:= 1 -> Kind = first ; Kind = second ),
    ( N0 == sg -> W = F3 ; W = F3p ),
    (   ty_once_form(Kind, verb, W, F0) -> F = F0
    ;   Feature =.. [T, N], ty_apply_ending(L, Feature, Base, F)
    ).

%% A verb the import writes the rows of (the conditions of its ty_verb/6
%% rows, above, with nothing counted).
ty_import_verb(L, W3, W3p, B) :-
    tyi_entry(verb, _, W3, M3),
    ty_single(W3), ty_single(M3),
    ty_once_form(plural, verb, W3, W3p),
    ty_once_form(past, verb, W3, _),
    ty_once_form(past, verb, W3p, _),
    reason_base(M3, B),
    \+ tyi_hand(ty_verb(L, B, present, sg, pos, [W3])),
    \+ ty_copula_word(L, W3).

ty_future_stem(L, W3, Stem) :-
    (   ty_once_form(future, verb, W3, F3),
        tyi_hand(ty_ending(L, future(sg), '', E)),
        atom_concat(Stem, E, F3)
    ->  true
    ;   ty_once_form(infinitive, verb, W3, Inf),
        once(tyi_hand(ty_ending(L, future_stem, _, _))),
        ty_apply_ending(L, future_stem, Inf, Stem)
    ).

%% A third person's form and the first and second persons the vocabulary
%% gives of it (`"veo" is the first person of "ve"'): sg(1) and sg(2) of a
%% singular, pl(1) and pl(2) of a plural.
ty_person_rows(N, W, N, W).
ty_person_rows(N0, W0, N, W) :-
    member(Kind-P, [first-1, second-2]),
    ty_once_form(Kind, verb, W0, W),
    N =.. [N0, P].
%% A copula's word is the copula, never a verb: the vocabularies list `es'
%% (`is'), `está' and `è' as verbs, and as verbs they read `el perro es en
%% la casa', where the copula's own rows choose `está'. A row of one
%% positive word is the copula; the words of a row of several (English
%% `has been') are not (English `have' is a verb).
ty_copula_word(L, W) :-
    tyi_hand(ty_copula(L, _, _, _, pos, [W])), !.

%% An adjective's forms: a word with no gender stands for both, and each
%% word needs its plural.
ty_adjective_form(M, form(G, N, W)) :-
    tyi_entry(adjective, G0, W0, M),
    ty_single(W0),
    ty_once_form(plural, adjective, W0, P),
    ( G0 == none -> G = any ; G = G0 ),
    member(N-W, [sg-W0, pl-P]).

ty_adjective_complete(Forms) :-
    forall(( member(G, [m, f]), member(N, [sg, pl]) ),
           ( member(form(G1, N, _), Forms), ( G1 == any ; G1 == G ) )).

%% English: a row for every meaning the vocabularies give, its forms by the
%% reason library (the base of a third person) and by the English
%% template's endings, and a past the vocabulary states where it states one
%% (`"saw" is the past of "sees"').
%% An English noun is put in the template's first class (ty_noun_class/3),
%% unless the hand template has it (a noun of a class, or an irregular one).
ty_english_row(ty_noun_in(english, M, none, Anim, M, C)) :-
    once(tyi_hand(ty_noun_class(english, _, _))),
    ty_english_nouns(Ms),
    member(M, Ms),
    ty_single(M),
    \+ tyi_hand(ty_noun(english, M, _, _, _, _)),
    \+ tyi_hand(ty_noun_in(english, M, _, _, _, _)),
    ty_english_animacy(M, Anim),
    ty_class_pick(english, noun, M, C).
%% An English adjective is one fact, its word its meaning (an English
%% adjective has one form): the vocabularies' meanings and lexicon/'s
%% (since 1.58.0), unless the hand template has it.
ty_english_row(ty_adjective(english, M, any, any, M)) :-
    setof(M0, G^W^A^( tyi_entry(adjective, G, W, M0) ; tyi_lex(adjective, M0, A) ), Ms),
    member(M, Ms),
    ty_single(M),
    \+ tyi_hand(ty_adjective(english, M, _, _, _)).
%% An English adverb is one fact, its word its meaning: lexicon/'s (the
%% vocabularies state none), unless the hand template has it (since 1.58.0).
ty_english_row(ty_adverb(english, M, M)) :-
    setof(M0, A^tyi_lex(adverb, M0, A), Ms),
    member(M, Ms),
    ty_single(M),
    \+ tyi_hand(ty_adverb(english, M, _)),
    \+ tyi_hand(ty_adverb(english, _, M)).
%% An English verb is put in its class (ty_class_pick/4), unless the hand
%% template has it; a past a vocabulary states that its class does not make
%% is counted (an irregular verb the hand template lacks).
ty_english_row(ty_verb_in(english, B, B, C)) :-
    once(tyi_hand(ty_conjugation(english, _, _))),
    ty_verb_bases,
    ty_english_verbs(Bs),
    member(B, Bs),
    ty_single(B),
    B \== be,
    \+ tyi_hand(ty_verb_in(english, B, _, _)),
    \+ tyi_hand(ty_irregular_verb(english, B, _, _, _)),
    \+ ( tyi_vbase(B, M3), ty_copula_word(english, M3) ),
    ty_class_pick(english, verb, B, C),
    (   tyi_vbase(B, M3), tyi_form(past, P0, M3, verb),
        \+ tyi_entry(verb, _, M3, _),
        tyi_hand(ty_conjugation(english, C, Ps)), ty_verb_part(past(sg), Ps, [], B, P, 0), P \== P0
    ->  ty_count(english_past_unlike_its_class)
    ;   true
    ).

%% THE WORDS OF lexicon/ (the English import): each word of the files a
%% kind reads, of letters a to z alone, as tyi_lex(Kind, Word, Animacy),
%% once, the first file's; a word of grammar the template names
%% (ty_closed/2) is none. class.txt is the persons; the verbs are known_verb,
%% vt, vi and vpp; the adjectives known_adj and adj, the adverbs
%% known_adverb and adverb (since 1.58.0).
ty_read_lexicon(L) :-
    ( tyi_hand(ty_closed(L, Closed)) -> true ; Closed = [] ),
    forall(member(Kind-Base-Anim, [noun-class-person, noun-known_noun-unknown, noun-noun-unknown,
                                   noun-unit-unknown, verb-known_verb-unknown,
                                   verb-vt-unknown, verb-vi-unknown, verb-vpp-unknown,
                                   adjective-known_adj-unknown, adjective-adj-unknown,
                                   adverb-known_adverb-unknown, adverb-adverb-unknown]),
           ( ty_lexicon_file(Base, File)
           ->  read_file_to_codes(File, Codes), atom_codes(Text, Codes),
               atomic_list_concat(Lines, '\n', Text),
               forall(( member(W, Lines), W \== '', ty_az_word(W), \+ memberchk(W, Closed),
                        \+ tyi_lex(Kind, W, _) ),
                      assertz(tyi_lex(Kind, W, Anim)))
           ;   true
           )).

ty_lexicon_file(Base, File) :-
    atomic_list_concat(['lexicon/', Base, '.txt'], Rel),
    catch(absolute_file_name(library(reasoning/Rel), File, [access(read)]), _, fail).

ty_az_word(W) :-
    atom_codes(W, Cs),
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z )).


%% The class the import puts an item of Kind in: the first ty_class_when/4
%% class whose pattern its word fits, else the kind's first class.
ty_class_pick(L, Kind, Word, Class) :-
    atom_chars(Word, Cs),
    (   tyi_hand(ty_class_when(L, Kind, C, Pat)), ty_letters_fit(L, Pat, Cs)
    ->  Class = C
    ;   ty_kind_first_class(L, Kind, Class)
    ).

ty_kind_first_class(L, noun, C) :- once(tyi_hand(ty_noun_class(L, C, _))).
ty_kind_first_class(L, verb, C) :- once(tyi_hand(ty_conjugation(L, C, _))).

%% A pattern of letter classes (ty_letters/3) and star(Class), zero or more
%% of the class, over the whole word.
ty_letters_fit(_, [], []).
ty_letters_fit(L, [star(K)|Ps], Cs) :- !,
    (   ty_letters_fit(L, Ps, Cs)
    ;   Cs = [C|Cs1], ty_letter_in(L, K, C), ty_letters_fit(L, [star(K)|Ps], Cs1)
    ).
ty_letters_fit(L, [K|Ps], [C|Cs]) :-
    ty_letter_in(L, K, C),
    ty_letters_fit(L, Ps, Cs).

ty_letter_in(L, K, C) :- tyi_hand(ty_letters(L, K, Ls)), memberchk(C, Ls).

%% The base of each verb meaning of the vocabularies, made once as
%% tyi_vbase(Base, Meaning) (`sees' is `see'), so that a verb's row asks it
%% by its base: asked of every meaning for each verb, the English import
%% made 2 450 million inferences where it makes ten million.
ty_verb_bases :-
    (   tyi_vbase(_, _) -> true
    ;   forall(( tyi_entry(verb, _, _, M), \+ tyi_vbase(_, M), once(reason_base(M, B)) ),
               assertz(tyi_vbase(B, M)))
    ).

%% The English verbs: the vocabularies' (their base) and lexicon/'s, each
%% once.
ty_english_verbs(Bs) :-
    (   setof(B, G^W3^M3^A^( ( tyi_entry(verb, G, W3, M3), ty_single(M3), reason_base(M3, B) )
                           ; tyi_lex(verb, B, A) ), Bs0)
    ->  Bs = Bs0
    ;   Bs = []
    ).

%% The English nouns: the vocabularies' meanings and lexicon/'s, each once.
ty_english_nouns(Ms) :-
    (   setof(M, G^W^A^( tyi_entry(noun, G, W, M) ; tyi_lex(noun, M, A) ), Ms0) -> Ms = Ms0 ; Ms = [] ).

%% An English noun's animacy: the vocabularies' (a person, animate), else
%% lexicon/'s.
ty_english_animacy(M, Anim) :-
    (   tyi_entry(noun, _, W, M), tyi_person(W) -> Anim = person
    ;   tyi_entry(noun, _, W, M), tyi_animate(W) -> Anim = animate
    ;   tyi_lex(noun, M, A) -> Anim = A
    ;   Anim = unknown
    ).

%% The form the hand template's ending rule makes: the longest From that
%% fits.
ty_apply_ending(L, Feature, Word, Form) :-
    findall(Len-(From-To), ( tyi_hand(ty_ending(L, Feature, From, To)),
                             atom_concat(_, From, Word),
                             atom_length(From, Len) ), Fits),
    keysort(Fits, Sorted),
    last(Sorted, _-(From-To)),
    atom_concat(Stem, From, Word),
    atom_concat(Stem, To, Form).

%% The rows of a kind with a file of its own: a noun of a class
%% (templates/<name>-nouns.pl), a verb of a class (-verbs.pl), and since
%% 1.58.0 an English adjective (-adjectives.pl) and adverb (-adverbs.pl);
%% the rest stay in the words file.
ty_kind_split(Rows, Kinds, Rest) :-
    partition([R]>>( R = ty_noun_in(_, _, _, _, _, _) ), Rows, Nouns, Rest1),
    partition([R]>>( R = ty_verb_in(_, _, _, _) ), Rest1, Verbs, Rest2),
    partition([R]>>( R = ty_adjective(english, _, _, _, _) ), Rest2, Adjectives, Rest3),
    partition([R]>>( R = ty_adverb(english, _, _) ), Rest3, Adverbs, Rest),
    findall(K-Rs, ( member(K-Rs, [nouns-Nouns, verbs-Verbs, adjectives-Adjectives, adverbs-Adverbs]),
                    Rs \== [] ), Kinds).

ty_kind_file(File, Kind, KFile) :-
    atom_concat(Base, '-words.pl', File),
    atomic_list_concat([Base, '-', Kind, '.pl'], KFile).

ty_write_kind_rows(L, Kind, Rows) :-
    format("%% templates/~w-~w.pl -- GENERATED by typology_import(~w) from~n", [L, Kind, L]),
    format("%% corpus/vocabulary/ and lexicon/: one fact a regular item. Do not~n", []),
    format("%% edit: a class and an irregular item are templates/~w.pl's; import again.~n~n", [L]),
    forall(member(R, Rows), portray_clause(R)).

ty_write_rows(L, Rows) :-
    format("%% templates/~w-words.pl -- GENERATED by typology_import(~w) from~n", [L, L]),
    format("%% corpus/vocabulary/. Do not edit: edit templates/~w.pl, whose rows~n", [L]),
    format("%% win, and import again.~n~n", []),
    forall(member(R, Rows), portray_clause(R)).
