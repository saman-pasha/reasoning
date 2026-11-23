%% templates/italian.pl -- the template of Italian, for
%% library(reasoning/typology). Facts only; typology_load(italian) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(italian, clause, [s, v, o]).
ty_order(italian, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy (person, animate, inanimate; a person is animate too), Singular, Plural.
ty_noun(italian, dog, m, animate, cane, cani).
ty_noun(italian, cat, m, animate, gatto, gatti).
%% `marzo', the month: a meaning of its own (templates/topics.pl).
ty_noun(italian, march_month, m, unknown, marzo, marzi).
ty_noun(italian, boy, m, person, ragazzo, ragazzi).
ty_noun(italian, girl, f, person, ragazza, ragazze).
ty_noun(italian, book, m, inanimate, libro, libri).
ty_noun(italian, mouse, m, animate, topo, topi).
ty_noun(italian, house, f, inanimate, casa, case).

%% The adjectives agree with the noun in gender and number.
ty_adjective(italian, big, any, sg, grande).
ty_adjective(italian, big, any, pl, grandi).
ty_adjective(italian, small, m, sg, piccolo).
ty_adjective(italian, small, f, sg, piccola).
ty_adjective(italian, small, m, pl, piccoli).
ty_adjective(italian, small, f, pl, piccole).
ty_adjective(italian, black, m, sg, nero).
ty_adjective(italian, black, f, sg, nera).
ty_adjective(italian, black, m, pl, neri).
ty_adjective(italian, black, f, pl, nere).
ty_adjective(italian, red, m, sg, rosso).
ty_adjective(italian, red, f, sg, rossa).
ty_adjective(italian, red, m, pl, rossi).
ty_adjective(italian, red, f, pl, rosse).

%% The verbs: the positive forms. The past is the passato remoto, as
%% corpus/vocabulary/italian.txt has it; the passato prossimo needs the
%% participle to agree with the subject, which the template has no slot for
%% yet.
ty_verb(italian, see, present, sg, pos, [vede]).
ty_verb(italian, see, present, pl, pos, [vedono]).
ty_verb(italian, see, past, sg, pos, [vide]).
ty_verb(italian, see, past, pl, pos, [videro]).
ty_verb(italian, sleep, present, sg, pos, [dorme]).
ty_verb(italian, sleep, present, pl, pos, [dormono]).
ty_verb(italian, sleep, past, sg, pos, [dormì]).
ty_verb(italian, sleep, past, pl, pos, [dormirono]).

%% The negative: `non' before the verb.
ty_negation(italian, any, any, [non], same).

%% The future, a word of its own; the passato prossimo, `avere' and the
%% participle (`ha visto', `non l'ha visto'), which agrees with an object
%% clitic of the third person before it (`l'ha vista', `li ha visti').
ty_verb(italian, see, future, sg, pos, ['vedrà']).
ty_verb(italian, see, future, pl, pos, [vedranno]).
ty_verb(italian, see, future, sg(1), pos, ['vedrò']).
ty_verb(italian, see, future, sg(2), pos, [vedrai]).
ty_verb(italian, see, future, pl(1), pos, [vedremo]).
ty_verb(italian, see, future, pl(2), pos, [vedrete]).
ty_verb(italian, sleep, future, sg, pos, ['dormirà']).
ty_verb(italian, sleep, future, pl, pos, [dormiranno]).
ty_verb(italian, sleep, future, sg(1), pos, ['dormirò']).
ty_verb(italian, sleep, future, sg(2), pos, [dormirai]).
ty_verb(italian, sleep, future, pl(1), pos, [dormiremo]).
ty_verb(italian, sleep, future, pl(2), pos, [dormirete]).
ty_tense_form(italian, perfect, sg, pos, [ha, participle]).
ty_tense_form(italian, perfect, pl, pos, [hanno, participle]).
ty_tense_form(italian, perfect, sg(1), pos, [ho, participle]).
ty_tense_form(italian, perfect, sg(2), pos, [hai, participle]).
ty_tense_form(italian, perfect, pl(1), pos, [abbiamo, participle]).
ty_tense_form(italian, perfect, pl(2), pos, [avete, participle]).
ty_participle(italian, see, visto).
ty_participle(italian, sleep, dormito).
ty_participle_ending(italian, f, sg, o, a).
ty_participle_ending(italian, m, pl, o, i).
ty_participle_ending(italian, f, pl, o, e).
ty_participle_agrees(italian, clitic).
%% The verbs whose passato prossimo takes `essere', the participle agreeing
%% with the subject (`La ragazza è andata', `I ragazzi sono andati').
ty_verb_class(italian, go, essere).
ty_verb_class(italian, come, essere).
ty_verb_class(italian, arrive, essere).
ty_verb_class(italian, return, essere).
ty_verb_class(italian, fall, essere).
ty_verb_class(italian, die, essere).
ty_verb_class(italian, enter, essere).
ty_verb_class(italian, become, essere).
ty_verb_class(italian, stay, essere).
ty_verb_class(italian, remain, essere).
ty_class_tense_form(italian, essere, perfect, sg, pos, ['è', participle(subject)]).
ty_class_tense_form(italian, essere, perfect, pl, pos, [sono, participle(subject)]).
ty_class_tense_form(italian, essere, perfect, sg(1), pos, [sono, participle(subject)]).
ty_class_tense_form(italian, essere, perfect, sg(2), pos, [sei, participle(subject)]).
ty_class_tense_form(italian, essere, perfect, pl(1), pos, [siamo, participle(subject)]).
ty_class_tense_form(italian, essere, perfect, pl(2), pos, [siete, participle(subject)]).
%% The future the import makes: a stated future's stem, else the
%% infinitive's (`parlare' `parlerà', `cercare' `cercherà', `mangiare'
%% `mangerà'), and each person's ending.
ty_ending(italian, future_stem, are, er).
ty_ending(italian, future_stem, care, cher).
ty_ending(italian, future_stem, gare, gher).
ty_ending(italian, future_stem, ciare, cer).
ty_ending(italian, future_stem, giare, ger).
ty_ending(italian, future_stem, ere, er).
ty_ending(italian, future_stem, ire, ir).
ty_ending(italian, future(sg), '', 'à').
ty_ending(italian, future(pl), '', anno).
ty_ending(italian, future(sg(1)), '', 'ò').
ty_ending(italian, future(sg(2)), '', ai).
ty_ending(italian, future(pl(1)), '', emo).
ty_ending(italian, future(pl(2)), '', ete).

%% The articles agree with the noun. A plural indefinite has none.
ty_article(italian, def, m, sg, il).
ty_article(italian, def, f, sg, la).
ty_article(italian, def, m, pl, i).
ty_article(italian, def, f, pl, le).
ty_article(italian, indef, m, sg, un).
ty_article(italian, indef, f, sg, una).
%% The article of a question (`Quale cane vede il ragazzo?').
ty_article(italian, which, any, sg, quale).
ty_article(italian, which, any, pl, quali).

%% The articles by the sound of the next word: `lo', `gli' and `uno' before
%% s and a consonant, z, gn, ps, pn, x and y; `l'' and `un'' before a vowel,
%% written joined to it (`l'avvocato', `un'amica'); `gli' before a vowel.
ty_letters(italian, vowel, [a, e, i, o, u, à, è, é, ì, ò, ù]).
ty_letters(italian, consonant, [b, c, d, f, g, h, j, k, l, m, n, p, q, r, s, t, v, w, x, y, z]).
ty_before(italian, il, [[s, consonant], [z], [g, n], [p, s], [p, n], [x], [y]], lo, space).
ty_before(italian, il, [[vowel], [h]], 'l\'', joined).
ty_before(italian, la, [[vowel], [h]], 'l\'', joined).
ty_before(italian, i, [[vowel], [h], [s, consonant], [z], [g, n], [p, s], [p, n], [x], [y]], gli, space).
ty_before(italian, un, [[s, consonant], [z], [g, n], [p, s], [p, n], [x], [y]], uno, space).
ty_before(italian, una, [[vowel]], 'un\'', joined).

%% The copula clause: subject, copula, predicate; `essere' for every kind
%% of predicate, the past the imperfetto.
ty_order(italian, copula, [s, c, p]).
ty_copula(italian, any, present, sg, pos, [è]).
ty_copula(italian, any, present, pl, pos, [sono]).
ty_copula(italian, any, present, sg, neg, [non, è]).
ty_copula(italian, any, present, pl, neg, [non, sono]).
ty_copula(italian, any, past, sg, pos, [era]).
ty_copula(italian, any, past, pl, pos, [erano]).
ty_copula(italian, any, past, sg, neg, [non, era]).
ty_copula(italian, any, past, pl, neg, [non, erano]).

%% Prepositions; the adjuncts at the clause's end. A preposition and the
%% article after it are one word: `nel', `nello', `nell'' joined to its
%% noun, `negli'; the same for `su', `a' and `da'.
ty_order(italian, pp, [p, x]).
ty_adjunct(italian, end).
ty_adposition(italian, in, [in]).
ty_adposition(italian, on, [su]).
ty_adposition(italian, with, [con]).
ty_adposition(italian, to, [a]).
ty_adposition(italian, from, [da]).
ty_contraction(italian, [in, il], nel).
ty_contraction(italian, [in, lo], nello).
ty_contraction(italian, [in, 'l\''], 'nell\'').
ty_contraction(italian, [in, la], nella).
ty_contraction(italian, [in, i], nei).
ty_contraction(italian, [in, gli], negli).
ty_contraction(italian, [in, le], nelle).
ty_contraction(italian, [su, il], sul).
ty_contraction(italian, [su, lo], sullo).
ty_contraction(italian, [su, 'l\''], 'sull\'').
ty_contraction(italian, [su, la], sulla).
ty_contraction(italian, [su, i], sui).
ty_contraction(italian, [su, gli], sugli).
ty_contraction(italian, [su, le], sulle).
ty_contraction(italian, [a, il], al).
ty_contraction(italian, [a, lo], allo).
ty_contraction(italian, [a, 'l\''], 'all\'').
ty_contraction(italian, [a, la], alla).
ty_contraction(italian, [a, i], ai).
ty_contraction(italian, [a, gli], agli).
ty_contraction(italian, [a, le], alle).
ty_contraction(italian, [da, il], dal).
ty_contraction(italian, [da, lo], dallo).
ty_contraction(italian, [da, 'l\''], 'dall\'').
ty_contraction(italian, [da, la], dalla).
ty_contraction(italian, [da, i], dai).
ty_contraction(italian, [da, gli], dagli).
ty_contraction(italian, [da, le], dalle).
ty_adverb(italian, quickly, rapidamente).
ty_adverb(italian, slowly, lentamente).
ty_adverb(italian, today, oggi).
ty_adverb(italian, here, qui).

%% Questions: a yes or no question in the statement's order; a question
%% word at the front, the verb before the subject after it (`Cosa vede il
%% ragazzo?'), `dove è' written `dov'è'. `Chi vide la ragazza?' is who saw
%% the girl, so whom the girl saw has the subject first: `La ragazza chi
%% vide?'.
ty_question(italian, yes_no, clause, unchanged).
ty_question(italian, yes_no, copula, unchanged).
ty_question(italian, wh, clause, front(all)).
ty_question(italian, wh, copula, front(all)).
ty_wh(italian, front).
ty_wh(italian, after(s)).
ty_wh_word(italian, who, [chi]).
ty_wh_word(italian, what, [cosa]).
ty_wh_word(italian, where, [dove]).
ty_wh_word(italian, when, [quando]).
ty_contraction(italian, [dove, 'è'], 'dov\'è').

%% Relative clauses: the head, the marker, the clause (`il cane che il
%% ragazzo vede').
ty_order(italian, rel, [h, m, c]).
ty_relative(italian, any, [che], [[]]).

%% A verb's complement (`Il ragazzo pensa alla ragazza.'); the adposition
%% moves with its question word (`A cosa pensa il ragazzo?'). `guardare',
%% `aspettare' and `ascoltare' take a plain object.
ty_complement(italian, think, [a]).
ty_complement(italian, depend, [da]).
ty_complement_wh(italian, moves).

%% A relative clause's gap in an adposition phrase: the adposition moves
%% into the marker with `cui' (`la casa in cui il cane dorme', `la ragazza
%% a cui il ragazzo pensa').
ty_gap(italian, pp, moves).
ty_relative_pronoun(italian, [cui], [[]]).

%% The answer to a yes or no question (`Sì, il ragazzo vede il cane.').
ty_answer(italian, yes, ['sì']).
ty_answer(italian, no, [no]).

%% A possessor (`il cane del ragazzo'): the possessed, `di' with the
%% possessor's article, the possessor. `il cui' moves with the possessed
%% into the marker, its article the possessed's (`il ragazzo il cui cane
%% dorme', `la ragazza la cui casa').
ty_possessive(italian, [h, p, g], [di], keep).
ty_contraction(italian, [di, il], del).
ty_contraction(italian, [di, lo], dello).
ty_contraction(italian, [di, 'l\''], 'dell\'').
ty_contraction(italian, [di, la], della).
ty_contraction(italian, [di, i], dei).
ty_contraction(italian, [di, gli], degli).
ty_contraction(italian, [di, le], delle).
ty_gap(italian, poss, moves).
ty_relative_possessive(italian, [il, cui], [[m, sg]]).
ty_relative_possessive(italian, [la, cui], [[f, sg]]).
ty_relative_possessive(italian, [i, cui], [[m, pl]]).
ty_relative_possessive(italian, [le, cui], [[f, pl]]).

%% A possessive pronoun with the possessed's article (`il mio cane', `la sua
%% casa', `i loro cani'): `mio', `tuo', `suo' of one possessor and `nostro',
%% `vostro' of several, agreeing with the possessed; `loro' of several of
%% the third person.
ty_possessive_pronoun(italian, [il, mio], [[1, sg]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, mia], [[1, sg]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, miei], [[1, sg]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, mie], [[1, sg]], [[f, pl]]).
ty_possessive_pronoun(italian, [il, tuo], [[2, sg]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, tua], [[2, sg]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, tuoi], [[2, sg]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, tue], [[2, sg]], [[f, pl]]).
ty_possessive_pronoun(italian, [il, suo], [[3, sg], [polite, sg]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, sua], [[3, sg], [polite, sg]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, suoi], [[3, sg], [polite, sg]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, sue], [[3, sg], [polite, sg]], [[f, pl]]).
ty_possessive_pronoun(italian, [il, nostro], [[1, pl]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, nostra], [[1, pl]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, nostri], [[1, pl]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, nostre], [[1, pl]], [[f, pl]]).
ty_possessive_pronoun(italian, [il, vostro], [[2, pl], [polite, pl]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, vostra], [[2, pl], [polite, pl]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, vostri], [[2, pl], [polite, pl]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, vostre], [[2, pl], [polite, pl]], [[f, pl]]).
ty_possessive_pronoun(italian, [il, loro], [[3, pl]], [[m, sg]]).
ty_possessive_pronoun(italian, [la, loro], [[3, pl]], [[f, sg]]).
ty_possessive_pronoun(italian, [i, loro], [[3, pl]], [[m, pl]]).
ty_possessive_pronoun(italian, [le, loro], [[3, pl]], [[f, pl]]).

%% Personal pronouns: a subject's, which the verb's form makes no word for
%% the first and the second persons (`Vedo il cane.'), and may make none
%% for the third (`Dorme.'); an object's, a clitic in the verb's words (`La
%% ragazza lo vede.', `Non la vedo.'; `lo' is `l'' before a vowel, as
%% `il'); and an adposition's (`con lei', `a lui').
ty_pronoun(italian, s, [io], [[1, sg]]).
ty_pronoun(italian, s, [tu], [[2, sg]]).
ty_pronoun(italian, s, [lui], [[3, sg, m]]).
ty_pronoun(italian, s, [lei], [[3, sg, f], [polite, sg]]).
ty_pronoun(italian, s, [noi], [[1, pl]]).
ty_pronoun(italian, s, [voi], [[2, pl], [polite, pl]]).
ty_pronoun(italian, s, [loro], [[3, pl]]).
ty_pronoun(italian, o, [mi], [[1, sg]]).
ty_pronoun(italian, o, [ti], [[2, sg]]).
ty_pronoun(italian, o, [lo], [[3, sg, m], [3, sg, n]]).
ty_pronoun(italian, o, [la], [[3, sg, f], [polite, sg]]).
ty_pronoun(italian, o, [ci], [[1, pl]]).
ty_pronoun(italian, o, [vi], [[2, pl], [polite, pl]]).
ty_pronoun(italian, o, [li], [[3, pl, m], [3, pl, n]]).
ty_pronoun(italian, o, [le], [[3, pl, f]]).
ty_pronoun(italian, j, [me], [[1, sg]]).
ty_pronoun(italian, j, [te], [[2, sg]]).
ty_pronoun(italian, j, [lui], [[3, sg, m], [3, sg, n]]).
ty_pronoun(italian, j, [lei], [[3, sg, f], [polite, sg]]).
ty_pronoun(italian, j, [noi], [[1, pl]]).
ty_pronoun(italian, j, [voi], [[2, pl], [polite, pl]]).
ty_pronoun(italian, j, [loro], [[3, pl]]).
ty_before(italian, lo, [[vowel], [h]], 'l\'', joined).
ty_pro_drop(italian, [1, 2]).
%% The polite `you': one person is `Lei' with the third person's form and
%% clitic (`Lei vede il cane.', `La vedo.', `il suo cane'), several `voi' with
%% the second plural's; it is never dropped.
ty_polite(italian, sg, sg).
ty_polite(italian, pl, pl(2)).
ty_clitic(italian, o).

%% The first and the second persons of the verbs above (the import gives
%% every other verb's from the vocabulary), and of the copula; a negative
%% is `non' before the positive.
ty_verb(italian, see, present, sg(1), pos, [vedo]).
ty_verb(italian, see, present, sg(2), pos, [vedi]).
ty_verb(italian, see, present, pl(1), pos, [vediamo]).
ty_verb(italian, see, present, pl(2), pos, [vedete]).
ty_verb(italian, see, past, sg(1), pos, [vidi]).
ty_verb(italian, see, past, sg(2), pos, [vedesti]).
ty_verb(italian, see, past, pl(1), pos, [vedemmo]).
ty_verb(italian, see, past, pl(2), pos, [vedeste]).
ty_verb(italian, sleep, present, sg(1), pos, [dormo]).
ty_verb(italian, sleep, present, sg(2), pos, [dormi]).
ty_verb(italian, sleep, present, pl(1), pos, [dormiamo]).
ty_verb(italian, sleep, present, pl(2), pos, [dormite]).
ty_verb(italian, sleep, past, sg(1), pos, [dormii]).
ty_verb(italian, sleep, past, sg(2), pos, [dormisti]).
ty_verb(italian, sleep, past, pl(1), pos, [dormimmo]).
ty_verb(italian, sleep, past, pl(2), pos, [dormiste]).
ty_copula(italian, any, present, sg(1), pos, [sono]).
ty_copula(italian, any, present, sg(2), pos, [sei]).
ty_copula(italian, any, present, pl(1), pos, [siamo]).
ty_copula(italian, any, present, pl(2), pos, [siete]).
ty_copula(italian, any, past, sg(1), pos, [ero]).
ty_copula(italian, any, past, sg(2), pos, [eri]).
ty_copula(italian, any, past, pl(1), pos, [eravamo]).
ty_copula(italian, any, past, pl(2), pos, [eravate]).

%% A pronoun of the text takes the gender of the noun it stands for (a
%% house is `la', a book `lo').
ty_pronoun_gender(italian, grammatical).

%% The copula's future and perfect (`sarà', `è stato'); `stato' agrees
%% with the subject (`agree(stato)': `è stata', `sono stati'); the negative
%% is `non' before them.
ty_copula(italian, any, future, sg, pos, [sarà]).
ty_copula(italian, any, future, pl, pos, [saranno]).
ty_copula(italian, any, future, sg(1), pos, [sarò]).
ty_copula(italian, any, future, sg(2), pos, [sarai]).
ty_copula(italian, any, future, pl(1), pos, [saremo]).
ty_copula(italian, any, future, pl(2), pos, [sarete]).
ty_copula(italian, any, perfect, sg, pos, [è, agree(stato)]).
ty_copula(italian, any, perfect, pl, pos, [sono, agree(stato)]).
ty_copula(italian, any, perfect, sg(1), pos, [sono, agree(stato)]).
ty_copula(italian, any, perfect, sg(2), pos, [sei, agree(stato)]).
ty_copula(italian, any, perfect, pl(1), pos, [siamo, agree(stato)]).
ty_copula(italian, any, perfect, pl(2), pos, [siete, agree(stato)]).
