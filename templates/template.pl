%% The blank template of the language `xx': every slot of
%% library(reasoning/typology), and every choice. typology_template/1
%% writes it from typology.pl; templates/template.pl is the one of `xx',
%% written by typology_import(template). Do not edit that file: change
%% typology.pl and import again.
%%
%% TO MAKE A LANGUAGE: copy it to templates/<name>.pl, with the name for
%% each `xx' (or ask typology_template(<name>) for the same text in the
%% name). Then, slot by slot:
%%
%%   - a row of code is a choice: keep it where the language uses it,
%%     delete it where the language does not;
%%   - a row in a comment is a shape: write a row of it for each word or
%%     form the language has, as the example after it (another
%%     language's row) shows. A slot the language does not need gets
%%     no row.
%%
%% typology_import(<name>) writes the word tables from
%% corpus/vocabulary/<name>.txt, typology_load(<name>) reads the
%% template, and typology_check(<name>, Missing) names what is still
%% missing.

%% ==== the orders of the levels ====

%%     ty_order(L, Level, Order)       an order of a level's parts the
%%                                     language uses; the first is written
%%   (keep the orders it uses; the first kept is the one written)
%% clause: s, v, o
ty_order(xx, clause, [s, v, o]).
ty_order(xx, clause, [s, o, v]).
ty_order(xx, clause, [v, s, o]).
ty_order(xx, clause, [v, o, s]).
ty_order(xx, clause, [o, s, v]).
ty_order(xx, clause, [o, v, s]).
%% np: d, a, n
ty_order(xx, np, [d, a, n]).
ty_order(xx, np, [d, n, a]).
ty_order(xx, np, [a, d, n]).
ty_order(xx, np, [a, n, d]).
ty_order(xx, np, [n, d, a]).
ty_order(xx, np, [n, a, d]).
%% copula: s, c, p
ty_order(xx, copula, [s, c, p]).
ty_order(xx, copula, [s, p, c]).
ty_order(xx, copula, [c, s, p]).
ty_order(xx, copula, [c, p, s]).
ty_order(xx, copula, [p, s, c]).
ty_order(xx, copula, [p, c, s]).
%% pp: p, x
ty_order(xx, pp, [p, x]).
ty_order(xx, pp, [x, p]).
%% rel: h, m, c
ty_order(xx, rel, [h, m, c]).
ty_order(xx, rel, [h, c, m]).
ty_order(xx, rel, [m, h, c]).
ty_order(xx, rel, [m, c, h]).
ty_order(xx, rel, [c, h, m]).
ty_order(xx, rel, [c, m, h]).

%% ==== words ====

%%     ty_noun_class(L, Class, Endings) a class of nouns and its plural:
%%                                     Endings are From-To, the longest
%%                                     From that ends the singular giving
%%                                     the plural (English regular [''-s,
%%                                     y-ies, ay-ays, ...]); the first class
%%                                     is the one the import puts a noun in
%% ty_noun_class(xx, Class, Endings).
%%   e.g. ty_noun_class(english, regular, [''-s, s-ses, x-xes, z-zes, ch-ches, sh-shes, y-ies, ay-ays, ...]).

%%     ty_class_when(L, Kind, Class, Pattern)
%%                                     the import puts an item of Kind (noun
%%                                     or verb) whose word fits Pattern, a
%%                                     list of ty_letters/3 classes and
%%                                     star(C), in Class (English verb
%%                                     double: [star(consonant), vowel,
%%                                     doubling], `stop')
%% ty_class_when(xx, Kind, Class, Pattern).
%%   e.g. ty_class_when(english, verb, double, [star(consonant), vowel, doubling]).

%%     ty_noun_in(L, Meaning, Gender, Animacy, Singular, Class)
%%                                     a noun of a class, its plural the
%%                                     class's (typology_load/1 makes its
%%                                     ty_noun/6 row); an irregular noun is
%%                                     a ty_noun/6 fact of its own
%% ty_noun_in(xx, Meaning, Gender, Animacy, Singular, Class).
%%   e.g. ty_noun_in(english, dog, none, animate, dog, regular).

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
%% ty_noun(xx, Meaning, Gender, Animacy, Singular, Plural).
%%   e.g. ty_noun(english, mouse, none, animate, mouse, mice).

%%     ty_adjective(L, Meaning, Gender, Number, Word)
%%                                     a form for a gender and a number;
%%                                     any for a form that does not change
%% ty_adjective(xx, Meaning, Gender, Number, Word).
%%   e.g. ty_adjective(english, big, any, any, big).

%%     ty_adjective_before(L, Meaning) the adjective stands before the noun
%%                                     where the others stand after it
%%                                     (French `le petit chien noir')
%% ty_adjective_before(xx, Meaning).
%%   e.g. ty_adjective_before(french, big).

%%     ty_article(L, Definiteness, Gender, Number, Word)
%%                                     def or indef, or which (the article
%%                                     of a question: `which dog'); a
%%                                     combination with no
%%                                     row has NO article (an English plural
%%                                     indefinite: `dogs')
%% ty_article(xx, Definiteness, Gender, Number, Word).
%%   e.g. ty_article(english, def, any, any, the).

%%     ty_adposition(L, Meaning, Words)
%%                                     a preposition or a postposition, by
%%                                     the pp level's order
%% ty_adposition(xx, Meaning, Words).
%%   e.g. ty_adposition(english, in, [in]).

%%     ty_adverb(L, Meaning, Word)     an adverb, an adjunct of the clause
%% ty_adverb(xx, Meaning, Word).
%%   e.g. ty_adverb(english, quickly, quickly).

%%     ty_capital(L, Word, Written)    a word always written with its
%%                                     capital (English `I')
%% ty_capital(xx, Word, Written).
%%   e.g. ty_capital(english, i, 'I').

%%     ty_capital_nouns(L)             the nouns keep their capital, so a
%%                                     sentence's first word is read as
%%                                     written too (German `Hunde schlafen.')
%%   (keep it where the language does this, else delete it)
ty_capital_nouns(xx).

%%     ty_name(L, Meaning, Written, Gender, Animacy)
%%                                     a name: its meaning, the English
%%                                     name (Italian `Socrate' is
%%                                     `Socrates'), as written, its words
%%                                     joined by one space (`New York'),
%%                                     its gender m, f or none (not known)
%%                                     and its animacy person, animate or
%%                                     inanimate; a word written with a
%%                                     capital that no table has is a name
%%                                     with no row, its meaning as written
%%                                     (the rows are templates/<name>-
%%                                     names.pl's, from lexicon/ and
%%                                     corpus/raw/)
%% ty_name(xx, Meaning, Written, Gender, Animacy).
%%   e.g. ty_name(persian, 'Ali', علی, m, person).

%%     ty_quantifier_pronoun(L, Quantifier, Kind, Words)
%%                                     a word of a quantifier and a kind
%%                                     where a noun phrase stands (since
%%                                     1.63.0): Quantifier some, every,
%%                                     no, any, this or that, Kind thing
%%                                     or person (`someone', `nothing',
%%                                     `todo el mundo', `this' alone), one
%%                                     word or several; singular, so a
%%                                     language gives its singular form
%%                                     (Italian `ognuno', not `tutti')
%% ty_quantifier_pronoun(xx, Quantifier, Kind, Words).
%%   e.g. ty_quantifier_pronoun(english, some, thing, [something]).

%%     ty_definite_like(L, Def, As)    the language writes the definiteness
%%                                     Def as As, and never reads Def
%%                                     (since 1.64.0: Persian writes mass
%%                                     as def, which has no article either)
%% ty_definite_like(xx, Def, As).
%%   e.g. ty_definite_like(persian, mass, def).

%%     ty_and(L, Words)                the words that join the last item of
%%                                     a list: a predicate's adjectives, noun
%%                                     phrases, clauses (`and', `y', `und',
%%                                     `و')
%% ty_and(xx, Words).
%%   e.g. ty_and(english, [and]).

%%     ty_conjunction(L, Kind, Words)  the words of another conjunction,
%%                                     Kind or or but (`or', `o', `but',
%%                                     `aber')
%% ty_conjunction(xx, Kind, Words).
%%   e.g. ty_conjunction(english, or, [or]).

%%     ty_serial_comma(L)              a comma may stand before the last
%%                                     item's conjunction of a list of three
%%                                     or more (`red, blue, and yellow'):
%%                                     read, not written
%%   (keep it where the language does this, else delete it)
ty_serial_comma(xx).

%%     ty_conjunct_marks(L)            each item of a coordinated role takes
%%                                     the role's marks (Spanish `al niño y
%%                                     a la niña'); else the whole takes them
%%   (keep it where the language does this, else delete it)
ty_conjunct_marks(xx).

%%     ty_clause_comma(L, Kind)        a comma before the conjunction Kind
%%                                     that joins two clauses (German `,
%%                                     aber'); read with or without one
%% ty_clause_comma(xx, Kind).
%%   e.g. ty_clause_comma(german, but).

%%     ty_comma(L, Mark)               the language's comma (Persian `،'),
%%                                     `,' where it names none
%% ty_comma(xx, Mark).
%%   e.g. ty_comma(persian, ،).

%%     ty_sense(L, Word, Sense, Back, Ahead)
%%                                     Word has Sense where the words before
%%                                     it fit the pattern Back and the words
%%                                     after it fit Ahead (below: a word
%%                                     with several meanings)
%% ty_sense(xx, Word, Sense, Back, Ahead).
%%   e.g. ty_sense(spanish, a, mark(o), [class(verb)], [opt(class(article)), opt(class(possessive)), class(noun, animate)]).

%%     ty_closed(L, Words)             the words of grammar the import never
%%                                     takes as a noun, a verb, an adjective
%%                                     or an adverb (English `and', `this')
%% ty_closed(xx, Words).
%%   e.g. ty_closed(english, [a, an, the, this, that, these, those, some, ...]).

%% ==== verbs and tenses ====

%%     ty_conjugation(L, Class, Parts) a class of verbs and its forms: each
%%                                     part (present(sg), past(sg), ...,
%%                                     participle) and its rule: base, the
%%                                     endings From-To on the base, or
%%                                     another part (English regular
%%                                     past(sg)-[''-ed, e-ed, y-ied, ...])
%% ty_conjugation(xx, Class, Parts).
%%   e.g. ty_conjugation(english, regular, [present(sg)-[''-s, s-ses, x-xes, z-zes, ch-ches, sh-shes, o-oes, y-ies, ...], present(pl)-base, past(sg)-[''-ed, e-ed, y-ied, ay-ayed, ey-eyed, oy-oyed, uy-uyed], past(pl)-past(sg), participle-past(sg)]).

%%     ty_verb_in(L, Meaning, Base, Class)
%%                                     a verb of a class (typology_load/1
%%                                     makes its ty_verb/6 and its
%%                                     ty_participle/3 rows)
%% ty_verb_in(xx, Meaning, Base, Class).
%%   e.g. ty_verb_in(english, admit, admit, double).

%%     ty_irregular_verb(L, Meaning, Base, Class, Parts)
%%                                     an irregular verb, one fact: the
%%                                     parts its class does not make
%%                                     (English see [past(sg)-saw,
%%                                     participle-seen])
%% ty_irregular_verb(xx, Meaning, Base, Class, Parts).
%%   e.g. ty_irregular_verb(english, arise, arise, regular, [past(sg)-arose, participle-arisen]).

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
%% ty_verb(xx, Meaning, Tense, Number, Polarity, Words).
%%   e.g. ty_verb(spanish, see, present, sg, pos, [ve]).

%%     ty_tense_form(L, Tense, Number, Polarity, Pattern)
%%                                     a verb in Tense with no row of its
%%                                     own is Pattern: words, and form(T, N)
%%                                     (the verb's own positive form) or
%%                                     participle: English future [will,
%%                                     form(present, pl)], perfect [has,
%%                                     participle], Spanish [ha, participle]
%% ty_tense_form(xx, Tense, Number, Polarity, Pattern).
%%   e.g. ty_tense_form(english, future, any, pos, [will, form(present, pl)]).

%%     ty_tense_like(L, Level, Tense, As)
%%                                     the language has no form of Tense
%%                                     at Level (clause, copula or any):
%%                                     its writer writes Tense as the
%%                                     tense As, its reader never reads
%%                                     Tense (English imperfect past:
%%                                     Spanish `veía' is `saw')
%% ty_tense_like(xx, Level, Tense, As).
%%   e.g. ty_tense_like(english, any, imperfect, past).

%%     ty_participle(L, Meaning, Word) a verb's participle (`seen', `visto')
%% ty_participle(xx, Meaning, Word).
%%   e.g. ty_participle(spanish, see, visto).

%%     ty_participle_like(L, Tense, Number)
%%                                     a verb with no participle row has
%%                                     that form as its participle (English
%%                                     past, sg: `walked')
%% ty_participle_like(xx, Tense, Number).
%%   e.g. ty_participle_like(english, past, sg).

%%     ty_participle_ending(L, Gender, Number, From, To)
%%                                     a participle that agrees takes this
%%                                     ending (Italian f, sg, o, a: `vista')
%% ty_participle_ending(xx, Gender, Number, From, To).
%%   e.g. ty_participle_ending(italian, f, sg, o, a).

%%     ty_participle_agrees(L, clitic) a participle agrees with an object
%%                                     clitic of the third person before it
%%                                     (`l'ha vista', `il l'a vue')
%%   (keep it where the language does this, else delete it)
ty_participle_agrees(xx, clitic).

%%     ty_verb_class(L, Meaning, Class) a verb of a class whose tenses have
%%                                     patterns of their own (Italian go
%%                                     essere, French go `être')
%% ty_verb_class(xx, Meaning, Class).
%%   e.g. ty_verb_class(italian, go, essere).

%%     ty_class_tense_form(L, Class, Tense, Number, Polarity, Pattern)
%%                                     such a pattern, its item
%%                                     participle(subject) a participle that
%%                                     agrees with the subject (`è andata',
%%                                     `sont allées')
%% ty_class_tense_form(xx, Class, Tense, Number, Polarity, Pattern).
%%   e.g. ty_class_tense_form(italian, essere, perfect, sg, pos, [è, participle(subject)]).

%%     ty_verb_person(L, Tense, Key, Base, From, To)
%%                                     a verb or copula of the person and
%%                                     number Key no row gives is Base's,
%%                                     its last word's ending From made To
%%                                     (English: every key but sg is pl's;
%%                                     Persian ند made م: `می‌بینم')
%% ty_verb_person(xx, Tense, Person, Base, From, To).
%%   e.g. ty_verb_person(english, any, sg(1), pl, '', '').

%%     ty_copula(L, Kind, Tense, Number, Polarity, Words)
%%                                     the copula for a predicate of Kind
%%                                     (adj, np, pp, or any: Spanish `es'
%%                                     and `está'); Words [] drops it;
%%                                     Number a person's key, as ty_verb/6's
%% ty_copula(xx, Kind, Tense, Number, Polarity, Words).
%%   e.g. ty_copula(english, any, present, sg, pos, [is]).

%%     ty_split_place(L, end)          the last part of a verb of two (an
%%                                     auxiliary and a participle or an
%%                                     infinitive) stands at the clause's
%%                                     end (German `Der Junge hat den Hund
%%                                     nicht gesehen.')
%%   (keep it where the language does this, else delete it)
ty_split_place(xx, end).

%%     ty_verb_last(L, rel)            a relative clause's verb stands after
%%                                     its other parts (German `der Hund,
%%                                     den der Junge sieht')
%%   (keep it where the language does this, else delete it)
ty_verb_last(xx, rel).

%% ==== the negation ====

%%     ty_negation(L, Tense, Number, Words, Form)
%%                                     a negative the template does not list
%%                                     is Words before a positive form: the
%%                                     same one (Form `same': `no ve') or
%%                                     another (`form(T, N)': English `does
%%                                     not' before the present plural, `see');
%%                                     Tense and Number may be any
%% ty_negation(xx, Tense, Number, Words, Form).
%%   e.g. ty_negation(english, present, sg, [does, not], form(present, pl)).

%%     ty_negation_place(L, Words, Place)
%%                                     a negative verb clause has Words as a
%%                                     part of its order at Place (start,
%%                                     end, before(X), after(X), X one of s,
%%                                     v, o), the verb positive: German
%%                                     `nicht' at the end, French `ne' and
%%                                     `pas' around the verb; with no row the
%%                                     negation is the verb's form
%% ty_negation_place(xx, Words, Place).
%%   e.g. ty_negation_place(french, [ne], before(v)).

%%     ty_copula_negation(L, Words, Place)
%%                                     ty_negation_place/3 for a copula
%%                                     clause, X one of s, c, p (German
%%                                     [nicht] before(p))
%% ty_copula_negation(xx, Words, Place).
%%   e.g. ty_copula_negation(german, [nicht], before(p)).

%%     ty_negative_article(L, Gender, Number, Case, Word)
%%                                     the article that says a negation
%%                                     (German `kein'): a negative clause's
%%                                     indefinite object, or a negative
%%                                     copula's indefinite predicate, takes
%%                                     it and the clause no other negation
%% ty_negative_article(xx, Gender, Number, Case, Word).
%%   e.g. ty_negative_article(french, any, any, any, de).

%%     ty_negative_article_roles(L, Roles)
%%                                     the roles (s, o, p) whose indefinite
%%                                     phrase takes the negative article
%%                                     in a negative clause (German
%%                                     [s, o, p]; [o, p] where no row says)
%%   (only with ty_negative_article/5 rows; keep the roles that take it)
%% ty_negative_article_roles(xx, [s, o, p]).

%%     ty_negative_article_keeps(L)    the clause keeps its own negation
%%                                     beside the negative article (French
%%                                     `ne ... pas de')
%%   (only with ty_negative_article/5 rows)
%% ty_negative_article_keeps(xx).

%% ==== forms chosen by sound, and contractions ====

%%     ty_ending(L, Feature, From, To) a form a rule makes: a word ending in
%%                                     From takes To in its place, the
%%                                     longest From that fits winning
%%                                     (English plural: `y' to `ies', `ay' to
%%                                     `ays', `' to `s'); the import uses it
%%                                     where the vocabulary states no form
%% ty_ending(xx, Feature, From, To).
%%   e.g. ty_ending(spanish, future_stem, '', '').

%%     ty_letters(L, Class, Letters)   a class of letters a pattern names
%%                                     (vowel, consonant)
%% ty_letters(xx, Class, Letters).
%%   e.g. ty_letters(english, consonant, [b, c, d, f, g, h, j, k, ...]).

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
%% ty_before(xx, Word, Patterns, Form, Join).
%%   e.g. ty_before(english, a, [[vowel]], an, space).

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
%% ty_linked(xx, Class, NextClass, From, To).
%%   e.g. ty_linked(english, n, h, '', '\'s').

%%     ty_contraction(L, Words, Word)  two words written as one (`a el' is
%%                                     `al'), and read back as two
%% ty_contraction(xx, Words, Word).
%%   e.g. ty_contraction(spanish, [a, el], al).

%% ==== roles, marks and cases ====

%%     ty_mark(L, Role, Place, Word, Conditions)
%%                                     a word before or after a role's
%%                                     phrase, written when the phrase has
%%                                     every feature of one of the
%%                                     Conditions (a list of lists of def,
%%                                     indef, sg, pl, animate, inanimate):
%%                                     Persian `را' after a definite object,
%%                                     Spanish `a' before an animate one
%% ty_mark(xx, Role, Place, Word, Conditions).
%%   e.g. ty_mark(spanish, o, before, a, [[animate, def], [animate, sg]]).

%%     ty_case(L, Role, Case)          the case of a role's noun phrase (s,
%%                                     o, p a copula's predicate, g a
%%                                     possessor): German s nom, o acc;
%%                                     a language with these rows has cases
%% ty_case(xx, Role, Case).
%%   e.g. ty_case(german, s, nom).

%%     ty_case_after(L, Words, Case)   the case of the noun phrase after the
%%                                     adposition Words (German [mit] dat,
%%                                     [an] acc)
%% ty_case_after(xx, Words, Case).
%%   e.g. ty_case_after(german, [in], dat).

%%     ty_article_case(L, Definiteness, Gender, Number, Case, Word)
%%                                     an article of a case (German `den':
%%                                     def, m, sg, acc); each is a
%%                                     ty_article/5 row too
%% ty_article_case(xx, Definiteness, Gender, Number, Case, Word).
%%   e.g. ty_article_case(german, def, m, sg, nom, der).

%%     ty_noun_case(L, Meaning, Case, Number, Word)
%%                                     a noun's form in a case where it is
%%                                     not the nominative's (`Hunden', dat,
%%                                     pl)
%% ty_noun_case(xx, Meaning, Case, Number, Word).
%%   e.g. ty_noun_case(german, dog, dat, pl, 'Hunden').

%%     ty_declension(L, Definiteness, Declension)
%%                                     the declension of the adjectives
%%                                     after an article of Definiteness
%%                                     (none: no article)
%% ty_declension(xx, Definiteness, Declension).
%%   e.g. ty_declension(german, def, weak).

%%     ty_adjective_ending(L, Declension, Case, Gender, Number, Ending)
%%                                     an adjective before a noun is its
%%                                     row's word and Ending (German
%%                                     `kleinen': weak, acc, m, sg, en)
%% ty_adjective_ending(xx, Declension, Case, Gender, Number, Ending).
%%   e.g. ty_adjective_ending(german, weak, nom, any, sg, e).

%% ==== adjuncts and complements ====

%%     ty_adjunct(L, Place)            where a clause's adjuncts stand:
%%                                     start, end, before(v), after(s)
%%   (keep one)
ty_adjunct(xx, start).
ty_adjunct(xx, end).
ty_adjunct(xx, before(v)).
ty_adjunct(xx, after(s)).

%%     ty_adjunct_front(L, v2)         a statement read with an adjunct first
%%                                     and the verb before the subject
%%                                     (German `Heute schläft der Hund.')
%%   (keep it where the language does this, else delete it)
ty_adjunct_front(xx, v2).

%%     ty_object_front(L, v2)          a statement read with its object first
%%                                     and the verb before the subject, where
%%                                     the first word cannot begin a subject
%%                                     (German `Den Hund sieht der Junge.')
%%   (keep it where the language does this, else delete it)
ty_object_front(xx, v2).

%%     ty_bare_topic(L, Topic)         a noun of the topic takes no definite
%%                                     article (the months: `in March')
%% ty_bare_topic(xx, Topic).
%%   e.g. ty_bare_topic(english, month).

%%     ty_adposition_topic(L, Meaning, Topic, Words)
%%                                     the adposition's words before a noun
%%                                     of the topic (French `en mars')
%% ty_adposition_topic(xx, Meaning, Topic, Words).
%%   e.g. ty_adposition_topic(french, in, month, [en]).

%%     ty_complement(L, Verb, Words)   the object of Verb is an adposition
%%                                     phrase with the adposition Words, in
%%                                     the pp level's order and with no role
%%                                     marks (English `think about', Spanish
%%                                     `pensar en'); the IR keeps the plain
%%                                     object
%% ty_complement(xx, Verb, Words).
%%   e.g. ty_complement(english, think, [about]).

%% ==== questions and answers ====

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
%%   (one row or more a kind and level; a particle needs its words)
ty_question(xx, yes_no, clause, unchanged).
ty_question(xx, yes_no, clause, front(all)).
ty_question(xx, yes_no, clause, front(first)).
ty_question(xx, yes_no, clause, invert(pronoun)).
%% ty_question(xx, yes_no, clause, particle(Words, start)).
%% ty_question(xx, yes_no, clause, particle(Words, end)).
ty_question(xx, yes_no, copula, unchanged).
ty_question(xx, yes_no, copula, front(all)).
ty_question(xx, yes_no, copula, front(first)).
ty_question(xx, yes_no, copula, invert(pronoun)).
%% ty_question(xx, yes_no, copula, particle(Words, start)).
%% ty_question(xx, yes_no, copula, particle(Words, end)).
ty_question(xx, wh, clause, unchanged).
ty_question(xx, wh, clause, front(all)).
ty_question(xx, wh, clause, front(first)).
ty_question(xx, wh, clause, invert(pronoun)).
%% ty_question(xx, wh, clause, particle(Words, start)).
%% ty_question(xx, wh, clause, particle(Words, end)).
ty_question(xx, wh, copula, unchanged).
ty_question(xx, wh, copula, front(all)).
ty_question(xx, wh, copula, front(first)).
ty_question(xx, wh, copula, invert(pronoun)).
%% ty_question(xx, wh, copula, particle(Words, start)).
%% ty_question(xx, wh, copula, particle(Words, end)).

%%     ty_inversion(L, Join, VowelJoin)
%%                                     a subject pronoun right after the
%%                                     verb is written joined to it by Join,
%%                                     by VowelJoin between two vowels
%%                                     (French `voit-il', `pense-t-il')
%% ty_inversion(xx, Join, VowelJoin).
%%   e.g. ty_inversion(french, -, '-t-').

%%     ty_question_form(L, Tense, Number, Words, Form)
%%                                     a verb a question's rule moves is, if
%%                                     positive, Words before its form Form
%%                                     (English `does' before the base:
%%                                     `Does the boy see the dog?')
%% ty_question_form(xx, Tense, Number, Words, Form).
%%   e.g. ty_question_form(english, present, sg, [does], form(present, pl)).

%%     ty_question_mark(L, Open, Close)
%%                                     the marks of a question (Spanish `¿'
%%                                     and `?'); with no row, `' and `?'
%% ty_question_mark(xx, Open, Close).
%%   e.g. ty_question_mark(spanish, ¿, ?).

%%     ty_wh(L, Place)                 a question word stands at the front,
%%                                     in place (in_place: Persian), or
%%                                     right after the subject (after(s):
%%                                     Italian `La ragazza chi vide?'), or
%%                                     every one at the front (all_front:
%%                                     Bulgarian `Кой какво вижда?')
%%   (keep one)
ty_wh(xx, front).
ty_wh(xx, in_place).
ty_wh(xx, after(s)).
ty_wh(xx, all_front).

%%     ty_wh_word(L, Meaning, Words)   who, what, where, when
%% ty_wh_word(xx, Meaning, Words).
%%   e.g. ty_wh_word(english, who, [who]).

%%     ty_wh_tonic(L, Meaning, Words)  a question word's form where it does
%%                                     not open the clause: after an
%%                                     adposition, and in place (French
%%                                     `quoi', where `que' opens it)
%% ty_wh_tonic(xx, Meaning, Words).
%%   e.g. ty_wh_tonic(french, what, [quoi]).

%%     ty_wh_case(L, Meaning, Case, Words)
%%                                     a question word of a case (German
%%                                     who acc [wen])
%% ty_wh_case(xx, Meaning, Case, Words).
%%   e.g. ty_wh_case(german, who, nom, [wer]).

%%     ty_complement_wh(L, Rule)       whether a complement's adposition
%%                                     moves to the front with its question
%%                                     word (`¿En qué piensa el niño?') or
%%                                     stays (`What does the boy think
%%                                     about?'); moves where no row says
%%   (keep one)
ty_complement_wh(xx, moves).
ty_complement_wh(xx, stays).

%%     ty_answer(L, Kind, Words)       the words of an answer: yes, no, and
%%                                     contradict (a positive answer to a
%%                                     negative question: Persian `چرا')
%% ty_answer(xx, Kind, Words).
%%   e.g. ty_answer(english, yes, [yes]).

%%     ty_answer_system(L, System)     polarity (the default: yes for a
%%                                     positive answer) or agreement (yes
%%                                     where the answer agrees with the
%%                                     question, as Japanese)
%%   (keep one)
ty_answer_system(xx, polarity).
ty_answer_system(xx, agreement).

%%     ty_answer_mark(L, Mark)         the comma after an answer's word
%%                                     before its clause (`,' with no row)
%% ty_answer_mark(xx, Mark).
%%   e.g. ty_answer_mark(persian, ،).

%%     ty_answer_echo(L, Rule, Word)   the answer that repeats its clause
%%                                     short: Rule aux (the subject and the
%%                                     auxiliary: `Yes, he does.') or verb
%%                                     (the clause with no object: Persian
%%                                     `بله، می‌بینم.'), Word keep or drop
%%                                     the yes or no word before it
%% ty_answer_echo(xx, Rule, Word).
%%   e.g. ty_answer_echo(english, aux, keep).

%% ==== relative clauses ====

%%     ty_relative(L, Role, Words, Conditions)
%%                                     a relative clause's marker where the
%%                                     gap is Role (s, o, or any), written
%%                                     when the head has every feature of
%%                                     one of the Conditions (as a mark's);
%%                                     the first that fits is written, and
%%                                     Words [] is no marker (English `the
%%                                     dog the boy sees')
%% ty_relative(xx, Role, Words, Conditions).
%%   e.g. ty_relative(english, any, [that], [[]]).

%%     ty_relative_comma(L)            a comma before a relative clause's
%%                                     marker and after the clause where
%%                                     the sentence goes on (German)
%%   (keep it where the language does this, else delete it)
ty_relative_comma(xx).

%%     ty_gap(L, Place, Rule)          how a relative clause's gap is
%%                                     written at Place o (an object: gap,
%%                                     the default, or resumptive) or pp (in
%%                                     an adposition phrase: stays, moves or
%%                                     resumptive) or poss (a possessor:
%%                                     moves, resumptive, or stays: French
%%                                     `dont'); the first row written,
%%                                     every row read (below: the gap)
%%   (keep the rules it uses, one or more a place)
ty_gap(xx, o, gap).
ty_gap(xx, o, resumptive).
ty_gap(xx, pp, stays).
ty_gap(xx, pp, moves).
ty_gap(xx, pp, resumptive).
ty_gap(xx, poss, stays).
ty_gap(xx, poss, moves).
ty_gap(xx, poss, resumptive).

%%     ty_relative_pronoun(L, Words, Conditions)
%%                                     the pronoun after a moved adposition
%%                                     in the marker (Spanish `en la que',
%%                                     Italian `in cui'), as a marker's
%%                                     Conditions
%% ty_relative_pronoun(xx, Words, Conditions).
%%   e.g. ty_relative_pronoun(english, [whom], [[animate]]).

%%     ty_resumptive(L, Words, Conditions)
%%                                     the pronoun where a resumptive gap
%%                                     stands (Persian `آن', `او')
%% ty_resumptive(xx, Words, Conditions).
%%   e.g. ty_resumptive(persian, [او], [[person, sg]]).

%%     ty_relative_after(L, Part, Rank) the relative clause of a subject (s),
%%                                     an object (o) or a copula's predicate
%%                                     (p) stands after the verb, at the
%%                                     clause's end (Persian); Rank first:
%%                                     written, and in place read too;
%%                                     second: in place written, this read
%%   (keep the ones the language uses, or none)
ty_relative_after(xx, s, first).
ty_relative_after(xx, s, second).
ty_relative_after(xx, o, first).
ty_relative_after(xx, o, second).
ty_relative_after(xx, p, first).
ty_relative_after(xx, p, second).

%%     ty_relative_bare(L, Definiteness)
%%                                     a head of this definiteness takes no
%%                                     article before its relative clause
%%                                     (Persian `حیوانی که', not `یک حیوانی
%%                                     که')
%%   (keep the ones the language uses, or none)
ty_relative_bare(xx, def).
ty_relative_bare(xx, indef).

%%     ty_relative_possessive(L, Words, Conditions)
%%                                     the pronoun of a moved possessor gap
%%                                     (`whose', `cuyo', `il cui'), its
%%                                     Conditions the possessed's features,
%%                                     or head(Features) the head's (German
%%                                     `dessen' after a masculine or a neuter
%%                                     head, `deren' after a feminine or a
%%                                     plural one)
%% ty_relative_possessive(xx, Words, Conditions).
%%   e.g. ty_relative_possessive(english, [whose], [[]]).

%% ==== possessors and pronouns ====

%%     ty_possessive(L, Order, Words, Article)
%%                                     a possessor's construction: its order
%%                                     of h p g, its word (p: Spanish `de',
%%                                     English `of', none), and whether the
%%                                     possessed keeps its article (keep) or
%%                                     loses it to the possessor (drop:
%%                                     English `the boy's dog'); the first
%%                                     row written, every row read
%%   (keep the ones it uses, with their words, and keep or drop)
%% ty_possessive(xx, [h, p, g], Words, keep_or_drop).
%% ty_possessive(xx, [h, g, p], Words, keep_or_drop).
%% ty_possessive(xx, [p, h, g], Words, keep_or_drop).
%% ty_possessive(xx, [p, g, h], Words, keep_or_drop).
%% ty_possessive(xx, [g, h, p], Words, keep_or_drop).
%% ty_possessive(xx, [g, p, h], Words, keep_or_drop).

%%     ty_possessive_pronoun(L, Words, Possessor, Possessed)
%%                                     a possessive pronoun's words before
%%                                     the bare possessed, where the pronoun
%%                                     fits a Possessor condition and the
%%                                     possessed a Possessed one (`his',
%%                                     `sus', `la sua')
%% ty_possessive_pronoun(xx, Words, Possessor, Possessed).
%%   e.g. ty_possessive_pronoun(english, [my], [[1, sg]], [[]]).

%%     ty_possessive_clitic(L)         the pronoun is a clitic on the
%%                                     possessed (Persian `سگش')
%%   (keep it where the language does this, else delete it)
ty_possessive_clitic(xx).

%%     ty_pronoun(L, Role, Words, Conditions)
%%                                     a personal pronoun's words in Role s
%%                                     (a subject), o (an object) or j
%%                                     (after an adposition), where the
%%                                     pronoun fits one of the Conditions,
%%                                     each its person, number and kind
%%                                     (`he' [[3, sg, m]]); a role with no
%%                                     row takes o's (j) or s's rows
%% ty_pronoun(xx, Role, Words, Conditions).
%%   e.g. ty_pronoun(english, s, [i], [[1, sg]]).

%%     ty_pronoun_gender(L, System)    a third person's pronoun of the text
%%                                     takes the noun's gender (grammatical:
%%                                     Spanish `la' for `la casa') or the
%%                                     meaning's kind (natural, the default:
%%                                     English `it')
%%   (keep one, or none: natural is the default)
ty_pronoun_gender(xx, grammatical).
ty_pronoun_gender(xx, natural).

%%     ty_polite(L, Number, Key)       the agreement key a polite `you' of
%%                                     Number takes (Spanish sg, sg: `usted
%%                                     ve'; French sg, pl(2): `vous voyez')
%% ty_polite(xx, Number, Key).
%%   e.g. ty_polite(english, sg, pl).

%%     ty_pro_drop(L, Persons)         a subject pronoun may be no word (the
%%                                     verb's form tells it): written so of
%%                                     the Persons listed, read so of every
%%                                     person (Spanish `Veo al perro.')
%%   (keep the persons whose subject may be no word, or delete it)
ty_pro_drop(xx, [1, 2, 3]).

%%     ty_clitic(L, o)                 an object pronoun is a clitic in the
%%                                     verb's words, after the negation's
%%                                     (Spanish `no lo ve')
%%   (keep it where the language does this, else delete it)
ty_clitic(xx, o).
