%% templates/persian.pl -- the template of Persian, for
%% library(reasoning/typology). Facts only; typology_load(persian) reads it.

%% The orders: subject, object, verb; the article, the noun, the
%% adjectives.
ty_order(persian, clause, [s, o, v]).
ty_order(persian, np, [d, n, a]).

%% The nouns: Meaning, Gender (Persian has none), Animacy, Singular, Plural.
ty_noun(persian, dog, none, animate, 'سگ', 'سگ‌ها').
ty_noun(persian, mouse, none, animate, 'موش', 'موش‌ها').
ty_noun(persian, cat, none, animate, 'گربه', 'گربه‌ها').
ty_noun(persian, house, none, inanimate, 'خانه', 'خانه‌ها').
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

%% The ezafe: a noun before its adjective, and an adjective before another,
%% is linked to it. After a consonant the link is a vowel not written;
%% after a silent `ه' it is `‌ی' (`گربه‌ی سیاه'), after `ا' and `و' it is `ی'
%% (`سگ‌های سیاه'). `سیاه' ends in a spoken h, so it is named, unchanged.
ty_linked(persian, n, a, 'ه', 'ه‌ی').
ty_linked(persian, n, a, 'ا', 'ای').
ty_linked(persian, n, a, 'و', 'وی').
ty_linked(persian, a, a, 'ه', 'ه‌ی').
ty_linked(persian, a, a, 'سیاه', 'سیاه').
ty_linked(persian, a, a, 'ا', 'ای').
ty_linked(persian, a, a, 'و', 'وی').
