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
%% The article of a question (`Which dog does the boy see?').
ty_article(english, which, any, any, which).

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

%% `a' is `an' before a vowel sound: spelled with a vowel, but not `uni',
%% `use', `eu', `one'; and before the silent h of `hour' and `honest'.
ty_letters(english, vowel, [a, e, i, o, u]).
ty_before(english, a, [[vowel]], an, space).
ty_before(english, a, [[u, n, i], [u, s, e], [u, s, u], [e, u], [o, n, e]], a, space).
ty_before(english, a, [[h, o, u, r], [h, o, n, e, s, t], [h, o, n, o, u, r], [h, e, i, r]], an, space).

%% The copula clause: subject, copula, predicate; the copula agrees with the
%% subject's number, for every kind of predicate.
ty_order(english, copula, [s, c, p]).
ty_copula(english, any, present, sg, pos, [is]).
ty_copula(english, any, present, pl, pos, [are]).
ty_copula(english, any, present, sg, neg, [is, not]).
ty_copula(english, any, present, pl, neg, [are, not]).
ty_copula(english, any, past, sg, pos, [was]).
ty_copula(english, any, past, pl, pos, [were]).
ty_copula(english, any, past, sg, neg, [was, not]).
ty_copula(english, any, past, pl, neg, [were, not]).

%% Prepositions before their noun phrase; the adjuncts at the clause's end.
ty_order(english, pp, [p, x]).
ty_adjunct(english, end).
ty_adposition(english, in, [in]).
ty_adposition(english, on, [on]).
ty_adposition(english, with, [with]).
ty_adposition(english, to, [to]).
ty_adposition(english, from, [from]).
ty_adverb(english, quickly, quickly).
ty_adverb(english, slowly, slowly).
ty_adverb(english, today, today).
ty_adverb(english, here, here).

%% Questions: the verb's first word before the subject, a positive verb in
%% its question form (`does' before the base: `Does the boy see the dog?',
%% `Is the dog not big?'); a question word at the front, the subject's
%% with no change (`Who sees the dog?').
ty_question(english, yes_no, clause, front(first)).
ty_question(english, yes_no, copula, front(first)).
ty_question(english, wh, clause, front(first)).
ty_question(english, wh, copula, front(first)).
ty_question_form(english, present, sg, [does], form(present, pl)).
ty_question_form(english, present, pl, [do], form(present, pl)).
ty_question_form(english, past, any, [did], form(present, pl)).
ty_wh(english, front).
ty_wh_word(english, who, [who]).
ty_wh_word(english, what, [what]).
ty_wh_word(english, where, [where]).
ty_wh_word(english, when, [when]).

%% Relative clauses: the head, the marker, the clause (`the dog that the
%% boy sees'). The first marker that fits is written; `who' (a person or
%% an animal) and `which' are read too, and no marker where the gap is the
%% object (`the dog the boy sees').
ty_order(english, rel, [h, m, c]).
ty_relative(english, any, [that], [[]]).
ty_relative(english, any, [who], [[animate]]).
ty_relative(english, any, [which], [[]]).
ty_relative(english, o, [], [[]]).

%% A verb's complement: its object is an adposition phrase (`The boy
%% thinks about the girl.'), and the adposition stays where its question
%% word or a relative clause's gap moves (`What does the boy think
%% about?', `the girl that the boy thinks about').
ty_complement(english, think, [about]).
ty_complement(english, look, [at]).
ty_complement(english, wait, [for]).
ty_complement(english, listen, [to]).
ty_complement(english, depend, [on]).
ty_complement(english, dream, [of]).
ty_complement_wh(english, stays).

%% The answer to a yes or no question (`Yes.', `No, the boy does not see
%% the dog.'): `yes' for a positive answer, after a negative question too.
ty_answer(english, yes, [yes]).
ty_answer(english, no, [no]).
