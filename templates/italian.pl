%% templates/italian.pl -- the template of Italian, for
%% library(reasoning/typology). Facts only; typology_load(italian) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(italian, clause, [s, v, o]).
ty_order(italian, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy, Singular, Plural.
ty_noun(italian, dog, m, animate, cane, cani).
ty_noun(italian, cat, m, animate, gatto, gatti).
ty_noun(italian, boy, m, animate, ragazzo, ragazzi).
ty_noun(italian, girl, f, animate, ragazza, ragazze).
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

%% The answer to a yes or no question (`Sì, il ragazzo vede il cane.').
ty_answer(italian, yes, ['sì']).
ty_answer(italian, no, [no]).
