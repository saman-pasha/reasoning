%% templates/cocolog.pl -- Cocolog as a template of the translator's level 2
%% (TRANSLATOR-PLAN.md, since reasoning 1.67.0): what library(reasoning/logic)
%% needs to write the logic form as Cocolog source and to read it back. A
%% programming language connects to level 2 alone; its rows are facts, as a
%% natural language's are.
%%
%% THE SLOTS:
%%
%%     lg_code(L)                      L is a programming language's template
%%     lg_code_reserved_prefix(L, P)   a predicate the system already
%%                                     defines (a builtin, a library's:
%%                                     predicate_property/2 says
%%                                     imported_from/1) is written with the
%%                                     prefix P, and read back without it:
%%                                     `John sleeps.' is is_sleep(john), as
%%                                     sleep/1 is Cocolog's
%%     lg_code_name(L, Meaning/Arity, Name)
%%                                     a predicate written by another name
%%                                     than its meaning; none: a predicate's
%%                                     name is its meaning (the English word)
%%     lg_code_query_mark(L, Mark)     the mark before a query
%%     lg_code_class(L, Meaning/Arity, Class)
%%                                     the word class a predicate is said
%%                                     as in a natural language (adjective,
%%                                     noun, verb), where WordNet's lists
%%                                     cannot give it (since 1.70.0)
%%     lg_code_tense(L, Tense, Name)   an atom in a tense other than the
%%                                     present is Name(Atom): `John
%%                                     slept.' is past(sleep(john)) (since
%%                                     1.70.0); read back, Name of one
%%                                     compound term is that tense

lg_code(cocolog).
lg_code_reserved_prefix(cocolog, is_).
lg_code_query_mark(cocolog, '?-').
lg_code_tense(cocolog, past, past).
lg_code_tense(cocolog, future, future).
lg_code_tense(cocolog, perfect, perfect).
lg_code_tense(cocolog, pluperfect, pluperfect).
lg_code_tense(cocolog, imperfect, imperfect).
%% A command (since 1.82.0): `Construct a proof.' is
%% imperative(construct(you, a(proof))).
lg_code_tense(cocolog, imperative, imperative).
%% The progressive (since 1.102.0): `The baby is sleeping.' is
%% progressive(sleep(the(baby))).
lg_code_tense(cocolog, prog(present), progressive).
lg_code_tense(cocolog, prog(past), past_progressive).
lg_code_tense(cocolog, prog(future), future_progressive).
lg_code_tense(cocolog, prog(perfect), perfect_progressive).
lg_code_tense(cocolog, prog(pluperfect), pluperfect_progressive).
%% The conditional and the modals (since 1.108.0): `The dog would sleep.'
%% is conditional(sleep(the(dog))), `He can hear the snap of a twig.'
%% can(hear(he, of(the(snap), a(twig)))).
lg_code_tense(cocolog, conditional, conditional).
lg_code_tense(cocolog, modal(can), can).
lg_code_tense(cocolog, modal(could), could).
lg_code_tense(cocolog, modal(may), may).
lg_code_tense(cocolog, modal(might), might).
lg_code_tense(cocolog, modal(must), must).
lg_code_tense(cocolog, modal(ought), ought).
lg_code_tense(cocolog, modal(shall), shall).
lg_code_tense(cocolog, modal(should), should).

%% The verbs of an animal's sound: each a noun too (the bark of a tree, a
%% roar), and no list of lexicon/ says which a dog's bark is.
lg_code_class(cocolog, bark/1, verb).
lg_code_class(cocolog, moo/1, verb).
lg_code_class(cocolog, quack/1, verb).
lg_code_class(cocolog, roar/1, verb).
lg_code_class(cocolog, howl/1, verb).
lg_code_class(cocolog, growl/1, verb).
lg_code_class(cocolog, bleat/1, verb).
