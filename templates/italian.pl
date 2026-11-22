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
