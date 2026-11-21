%% templates/persian.pl -- the template of Persian, for
%% library(reasoning/typology). Facts only; typology_load(persian) reads it.

%% The orders: subject, object, verb; the article, the noun, the
%% adjectives. The ezafe between a noun and its adjective is not written
%% after a consonant, and every noun here ends in one.
ty_order(persian, clause, [s, o, v]).
ty_order(persian, np, [d, n, a]).

%% The nouns: Meaning, Gender (Persian has none), Animacy, Singular, Plural.
ty_noun(persian, dog, none, animate, 'سگ', 'سگ‌ها').
ty_noun(persian, mouse, none, animate, 'موش', 'موش‌ها').
%% No cat yet: `گربه' ends in a vowel, and its ezafe is written.
ty_noun(persian, boy, none, animate, 'پسر', 'پسرها').
ty_noun(persian, girl, none, animate, 'دختر', 'دخترها').
ty_noun(persian, book, none, inanimate, 'کتاب', 'کتاب‌ها').

%% The adjectives do not change.
ty_adjective(persian, big, any, any, 'بزرگ').
ty_adjective(persian, small, any, any, 'کوچک').
ty_adjective(persian, black, any, any, 'سیاه').
ty_adjective(persian, red, any, any, 'قرمز').

%% The verbs agree with the subject in number. The negative is a prefix,
%% so each form is one word.
ty_verb(persian, see, present, sg, pos, ['می‌بیند']).
ty_verb(persian, see, present, pl, pos, ['می‌بینند']).
ty_verb(persian, see, present, sg, neg, ['نمی‌بیند']).
ty_verb(persian, see, present, pl, neg, ['نمی‌بینند']).
ty_verb(persian, see, past, sg, pos, ['دید']).
ty_verb(persian, see, past, pl, pos, ['دیدند']).
ty_verb(persian, see, past, sg, neg, ['ندید']).
ty_verb(persian, see, past, pl, neg, ['ندیدند']).
ty_verb(persian, sleep, present, sg, pos, ['می‌خوابد']).
ty_verb(persian, sleep, present, pl, pos, ['می‌خوابند']).
ty_verb(persian, sleep, present, sg, neg, ['نمی‌خوابد']).
ty_verb(persian, sleep, present, pl, neg, ['نمی‌خوابند']).
ty_verb(persian, sleep, past, sg, pos, ['خوابید']).
ty_verb(persian, sleep, past, pl, pos, ['خوابیدند']).
ty_verb(persian, sleep, past, sg, neg, ['نخوابید']).
ty_verb(persian, sleep, past, pl, neg, ['نخوابیدند']).

%% No definite article; `یک' before a singular indefinite noun.
ty_article(persian, indef, any, sg, 'یک').

%% `را' after a definite object.
ty_mark(persian, o, after, 'را', [[def]]).
