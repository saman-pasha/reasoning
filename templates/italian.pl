%% templates/italian.pl -- the template of Italian, for
%% library(reasoning/typology). Facts only; typology_load(italian) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(italian, clause, [s, v, o]).
ty_order(italian, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy, Singular, Plural. Each masculine
%% noun here takes `il': lo and gli (before s and a consonant, z, a
%% vowel) are not in the template yet.
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

%% The verbs. The past is the passato prossimo; the negative is `non'.
ty_verb(italian, see, present, sg, pos, [vede]).
ty_verb(italian, see, present, pl, pos, [vedono]).
ty_verb(italian, see, present, sg, neg, [non, vede]).
ty_verb(italian, see, present, pl, neg, [non, vedono]).
ty_verb(italian, see, past, sg, pos, [ha, visto]).
ty_verb(italian, see, past, pl, pos, [hanno, visto]).
ty_verb(italian, see, past, sg, neg, [non, ha, visto]).
ty_verb(italian, see, past, pl, neg, [non, hanno, visto]).
ty_verb(italian, sleep, present, sg, pos, [dorme]).
ty_verb(italian, sleep, present, pl, pos, [dormono]).
ty_verb(italian, sleep, present, sg, neg, [non, dorme]).
ty_verb(italian, sleep, present, pl, neg, [non, dormono]).
ty_verb(italian, sleep, past, sg, pos, [ha, dormito]).
ty_verb(italian, sleep, past, pl, pos, [hanno, dormito]).
ty_verb(italian, sleep, past, sg, neg, [non, ha, dormito]).
ty_verb(italian, sleep, past, pl, neg, [non, hanno, dormito]).

%% The articles agree with the noun. A plural indefinite has none.
ty_article(italian, def, m, sg, il).
ty_article(italian, def, f, sg, la).
ty_article(italian, def, m, pl, i).
ty_article(italian, def, f, pl, le).
ty_article(italian, indef, m, sg, un).
ty_article(italian, indef, f, sg, una).
