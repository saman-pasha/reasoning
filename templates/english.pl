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

%% Plurals the ending rules below would get wrong.
ty_noun(english, man, none, animate, man, men).
ty_noun(english, woman, none, animate, woman, women).
ty_noun(english, child, none, animate, child, children).
ty_noun(english, person, none, animate, person, people).
ty_noun(english, foot, none, inanimate, foot, feet).
ty_noun(english, tooth, none, inanimate, tooth, teeth).
ty_noun(english, goose, none, animate, goose, geese).
ty_noun(english, wife, none, animate, wife, wives).
ty_noun(english, knife, none, inanimate, knife, knives).
ty_noun(english, life, none, inanimate, life, lives).
ty_noun(english, leaf, none, inanimate, leaf, leaves).
ty_noun(english, wolf, none, animate, wolf, wolves).
ty_noun(english, sheep, none, animate, sheep, sheep).
ty_noun(english, fish, none, animate, fish, fish).

%% The adjectives do not change.
ty_adjective(english, big, any, any, big).
ty_adjective(english, small, any, any, small).
ty_adjective(english, black, any, any, black).
ty_adjective(english, red, any, any, red).

%% The verbs: the positive forms; the negatives are the rule below.
ty_verb(english, see, present, sg, pos, [sees]).
ty_verb(english, see, present, pl, pos, [see]).
ty_verb(english, see, past, sg, pos, [saw]).
ty_verb(english, see, past, pl, pos, [saw]).
ty_verb(english, sleep, present, sg, pos, [sleeps]).
ty_verb(english, sleep, present, pl, pos, [sleep]).
ty_verb(english, sleep, past, sg, pos, [slept]).
ty_verb(english, sleep, past, pl, pos, [slept]).

%% The articles. A plural indefinite has none: `dogs'.
ty_article(english, def, any, any, the).
ty_article(english, indef, any, sg, a).

%% The negative: `does not', `do not', `did not' before the base, which is
%% the present plural.
ty_negation(english, present, sg, [does, not], form(present, pl)).
ty_negation(english, present, pl, [do, not], form(present, pl)).
ty_negation(english, past, any, [did, not], form(present, pl)).

%% The endings typology_import(english) makes the forms the vocabularies do
%% not state with: the longest ending that fits wins.
ty_ending(english, plural, '', s).
ty_ending(english, plural, s, ses).
ty_ending(english, plural, x, xes).
ty_ending(english, plural, z, zes).
ty_ending(english, plural, ch, ches).
ty_ending(english, plural, sh, shes).
ty_ending(english, plural, y, ies).
ty_ending(english, plural, ay, ays).
ty_ending(english, plural, ey, eys).
ty_ending(english, plural, oy, oys).
ty_ending(english, plural, uy, uys).
ty_ending(english, past, '', ed).
ty_ending(english, past, e, ed).
ty_ending(english, past, y, ied).
ty_ending(english, past, ay, ayed).
ty_ending(english, past, ey, eyed).
ty_ending(english, past, oy, oyed).
ty_ending(english, past, uy, uyed).
