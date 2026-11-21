%% templates/english.pl -- the template of English, for
%% library(reasoning/typology). Facts only; typology_load(english) reads it.

%% The orders: subject, verb, object; the article, the adjectives, the noun.
ty_order(english, clause, [s, v, o]).
ty_order(english, np, [d, a, n]).

%% The nouns: Meaning, Gender (English has none), Animacy, Singular, Plural.
ty_noun(english, dog, none, animate, dog, dogs).
ty_noun(english, cat, none, animate, cat, cats).
ty_noun(english, boy, none, animate, boy, boys).
ty_noun(english, girl, none, animate, girl, girls).
ty_noun(english, book, none, inanimate, book, books).
ty_noun(english, mouse, none, animate, mouse, mice).

%% The adjectives do not change.
ty_adjective(english, big, any, any, big).
ty_adjective(english, small, any, any, small).
ty_adjective(english, black, any, any, black).
ty_adjective(english, red, any, any, red).

%% The verbs: every tense, number and polarity. A negative is three words.
ty_verb(english, see, present, sg, pos, [sees]).
ty_verb(english, see, present, pl, pos, [see]).
ty_verb(english, see, present, sg, neg, [does, not, see]).
ty_verb(english, see, present, pl, neg, [do, not, see]).
ty_verb(english, see, past, sg, pos, [saw]).
ty_verb(english, see, past, pl, pos, [saw]).
ty_verb(english, see, past, sg, neg, [did, not, see]).
ty_verb(english, see, past, pl, neg, [did, not, see]).
ty_verb(english, sleep, present, sg, pos, [sleeps]).
ty_verb(english, sleep, present, pl, pos, [sleep]).
ty_verb(english, sleep, present, sg, neg, [does, not, sleep]).
ty_verb(english, sleep, present, pl, neg, [do, not, sleep]).
ty_verb(english, sleep, past, sg, pos, [slept]).
ty_verb(english, sleep, past, pl, pos, [slept]).
ty_verb(english, sleep, past, sg, neg, [did, not, sleep]).
ty_verb(english, sleep, past, pl, neg, [did, not, sleep]).

%% The articles. A plural indefinite has none: `dogs'.
ty_article(english, def, any, any, the).
ty_article(english, indef, any, sg, a).
