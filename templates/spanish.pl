%% templates/spanish.pl -- the template of Spanish, for
%% library(reasoning/typology). Facts only; typology_load(spanish) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(spanish, clause, [s, v, o]).
ty_order(spanish, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy, Singular, Plural.
ty_noun(spanish, dog, m, animate, perro, perros).
ty_noun(spanish, cat, m, animate, gato, gatos).
ty_noun(spanish, boy, m, animate, niño, niños).
ty_noun(spanish, girl, f, animate, niña, niñas).
ty_noun(spanish, book, m, inanimate, libro, libros).
ty_noun(spanish, mouse, m, animate, ratón, ratones).

%% The adjectives agree with the noun in gender and number.
ty_adjective(spanish, big, any, sg, grande).
ty_adjective(spanish, big, any, pl, grandes).
ty_adjective(spanish, small, m, sg, pequeño).
ty_adjective(spanish, small, f, sg, pequeña).
ty_adjective(spanish, small, m, pl, pequeños).
ty_adjective(spanish, small, f, pl, pequeñas).
ty_adjective(spanish, black, m, sg, negro).
ty_adjective(spanish, black, f, sg, negra).
ty_adjective(spanish, black, m, pl, negros).
ty_adjective(spanish, black, f, pl, negras).
ty_adjective(spanish, red, m, sg, rojo).
ty_adjective(spanish, red, f, sg, roja).
ty_adjective(spanish, red, m, pl, rojos).
ty_adjective(spanish, red, f, pl, rojas).

%% The verbs. The negative is `no' before the verb.
ty_verb(spanish, see, present, sg, pos, [ve]).
ty_verb(spanish, see, present, pl, pos, [ven]).
ty_verb(spanish, see, present, sg, neg, [no, ve]).
ty_verb(spanish, see, present, pl, neg, [no, ven]).
ty_verb(spanish, see, past, sg, pos, [vio]).
ty_verb(spanish, see, past, pl, pos, [vieron]).
ty_verb(spanish, see, past, sg, neg, [no, vio]).
ty_verb(spanish, see, past, pl, neg, [no, vieron]).
ty_verb(spanish, sleep, present, sg, pos, [duerme]).
ty_verb(spanish, sleep, present, pl, pos, [duermen]).
ty_verb(spanish, sleep, present, sg, neg, [no, duerme]).
ty_verb(spanish, sleep, present, pl, neg, [no, duermen]).
ty_verb(spanish, sleep, past, sg, pos, [durmió]).
ty_verb(spanish, sleep, past, pl, pos, [durmieron]).
ty_verb(spanish, sleep, past, sg, neg, [no, durmió]).
ty_verb(spanish, sleep, past, pl, neg, [no, durmieron]).

%% The articles agree with the noun. A plural indefinite has none.
ty_article(spanish, def, m, sg, el).
ty_article(spanish, def, f, sg, la).
ty_article(spanish, def, m, pl, los).
ty_article(spanish, def, f, pl, las).
ty_article(spanish, indef, m, sg, un).
ty_article(spanish, indef, f, sg, una).

%% The personal `a': before an animate object that is definite or
%% singular (`ve al perro', `ve a una niña'; `ve perros', `ve un libro').
ty_mark(spanish, o, before, a, [[animate, def], [animate, sg]]).

%% `a el' is written `al'.
ty_contraction(spanish, [a, el], al).
