%% templates/spanish.pl -- the template of Spanish, for
%% library(reasoning/typology). Facts only; typology_load(spanish) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(spanish, clause, [s, v, o]).
ty_order(spanish, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy (person, animate, inanimate; a person is animate too), Singular, Plural.
ty_noun(spanish, dog, m, animate, perro, perros).
ty_noun(spanish, cat, m, animate, gato, gatos).
ty_noun(spanish, boy, m, person, niño, niños).
ty_noun(spanish, girl, f, person, niña, niñas).
ty_noun(spanish, book, m, inanimate, libro, libros).
ty_noun(spanish, mouse, m, animate, ratón, ratones).
ty_noun(spanish, house, f, inanimate, casa, casas).

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

%% The verbs: the positive forms. The pretérito is the past.
ty_verb(spanish, see, present, sg, pos, [ve]).
ty_verb(spanish, see, present, pl, pos, [ven]).
ty_verb(spanish, see, past, sg, pos, [vio]).
ty_verb(spanish, see, past, pl, pos, [vieron]).
ty_verb(spanish, sleep, present, sg, pos, [duerme]).
ty_verb(spanish, sleep, present, pl, pos, [duermen]).
ty_verb(spanish, sleep, past, sg, pos, [durmió]).
ty_verb(spanish, sleep, past, pl, pos, [durmieron]).

%% The negative: `no' before the verb.
ty_negation(spanish, any, any, [no], same).

%% The articles agree with the noun. A plural indefinite has none.
ty_article(spanish, def, m, sg, el).
ty_article(spanish, def, f, sg, la).
ty_article(spanish, def, m, pl, los).
ty_article(spanish, def, f, pl, las).
ty_article(spanish, indef, m, sg, un).
ty_article(spanish, indef, f, sg, una).
%% The article of a question (`¿Qué perro ve el niño?').
ty_article(spanish, which, any, any, 'qué').

%% The personal `a': before an animate object that is definite or
%% singular (`ve al perro', `ve a una niña'; `ve perros', `ve un libro').
ty_mark(spanish, o, before, a, [[animate, def], [animate, sg]]).

%% `a el' is written `al'.
ty_contraction(spanish, [a, el], al).

%% A feminine noun that begins with a stressed `a' takes `el' and `un' in
%% the singular (`el agua', `un arma'; `las aguas', `la amiga'). Stress is
%% not in the spelling, so the words are named, each to its end.
ty_before(spanish, la, [[a, g, u, a, end], [á, g, u, i, l, a, end], [h, a, m, b, r, e, end],
                        [a, l, m, a, end], [a, r, m, a, end], [a, u, l, a, end],
                        [h, a, c, h, a, end], [á, r, e, a, end], [h, a, b, l, a, end]], el, space).
ty_before(spanish, una, [[a, g, u, a, end], [á, g, u, i, l, a, end], [h, a, m, b, r, e, end],
                         [a, l, m, a, end], [a, r, m, a, end], [a, u, l, a, end],
                         [h, a, c, h, a, end], [á, r, e, a, end], [h, a, b, l, a, end]], un, space).

%% The copula clause: subject, copula, predicate. `ser' for a quality and
%% a noun (`el perro es grande'), `estar' for a place (`el perro está en la
%% casa'); the past is the imperfect, the past of a state.
ty_order(spanish, copula, [s, c, p]).
ty_copula(spanish, adj, present, sg, pos, [es]).
ty_copula(spanish, adj, present, pl, pos, [son]).
ty_copula(spanish, adj, past, sg, pos, [era]).
ty_copula(spanish, adj, past, pl, pos, [eran]).
ty_copula(spanish, np, present, sg, pos, [es]).
ty_copula(spanish, np, present, pl, pos, [son]).
ty_copula(spanish, np, past, sg, pos, [era]).
ty_copula(spanish, np, past, pl, pos, [eran]).
ty_copula(spanish, pp, present, sg, pos, [está]).
ty_copula(spanish, pp, present, pl, pos, [están]).
ty_copula(spanish, pp, past, sg, pos, [estaba]).
ty_copula(spanish, pp, past, pl, pos, [estaban]).
ty_copula(spanish, adj, present, sg, neg, [no, es]).
ty_copula(spanish, adj, present, pl, neg, [no, son]).
ty_copula(spanish, adj, past, sg, neg, [no, era]).
ty_copula(spanish, adj, past, pl, neg, [no, eran]).
ty_copula(spanish, np, present, sg, neg, [no, es]).
ty_copula(spanish, np, present, pl, neg, [no, son]).
ty_copula(spanish, np, past, sg, neg, [no, era]).
ty_copula(spanish, np, past, pl, neg, [no, eran]).
ty_copula(spanish, pp, present, sg, neg, [no, está]).
ty_copula(spanish, pp, present, pl, neg, [no, están]).
ty_copula(spanish, pp, past, sg, neg, [no, estaba]).
ty_copula(spanish, pp, past, pl, neg, [no, estaban]).

%% Prepositions; the adjuncts at the clause's end; `de el' is `del'.
ty_order(spanish, pp, [p, x]).
ty_adjunct(spanish, end).
ty_adposition(spanish, in, [en]).
ty_adposition(spanish, on, [sobre]).
ty_adposition(spanish, with, [con]).
ty_adposition(spanish, to, [a]).
ty_adposition(spanish, from, [de]).
ty_contraction(spanish, [de, el], del).
ty_adverb(spanish, quickly, rápidamente).
ty_adverb(spanish, slowly, lentamente).
ty_adverb(spanish, today, hoy).
ty_adverb(spanish, here, aquí).

%% A word with several meanings in one place: `a' after a verb and before an
%% animate noun is the object's mark (`ve al perro'); anywhere else it is
%% `to' (`ve a un libro': sees, to a book). The lookback may pass over the
%% subject of a question (`¿Ve el niño al perro?'), and before `quién' it is
%% the mark with no verb before it (`¿A quién ve el niño?').
ty_sense(spanish, a, mark(o), [class(verb)], [opt(class(article)), class(noun, animate)]).
ty_sense(spanish, a, mark(o), [class(noun), opt(class(article)), class(verb)],
         [opt(class(article)), class(noun, animate)]).
ty_sense(spanish, a, mark(o), [], ['quién']).
ty_sense(spanish, a, mark(o), [], ['qué', class(noun, animate)]).
%% Before `cuyo' and an animate noun it is the mark too (`el niño a cuyo
%% perro ve la niña').
ty_sense(spanish, a, mark(o), [], [cuyo, class(noun, animate)]).
ty_sense(spanish, a, mark(o), [], [cuya, class(noun, animate)]).
ty_sense(spanish, a, mark(o), [], [cuyos, class(noun, animate)]).
ty_sense(spanish, a, mark(o), [], [cuyas, class(noun, animate)]).
ty_sense(spanish, a, adposition(to), [], []).

%% Questions: `¿' and `?'; a yes or no question in the statement's order,
%% or with the verb before the subject (`¿Ve el niño al perro?'); a
%% question word at the front, the verb before the subject after it.
ty_question_mark(spanish, '¿', '?').
ty_question(spanish, yes_no, clause, unchanged).
ty_question(spanish, yes_no, clause, front(all)).
ty_question(spanish, yes_no, copula, unchanged).
ty_question(spanish, yes_no, copula, front(all)).
ty_question(spanish, wh, clause, front(all)).
ty_question(spanish, wh, copula, front(all)).
ty_wh(spanish, front).
ty_wh_word(spanish, who, ['quién']).
ty_wh_word(spanish, what, ['qué']).
ty_wh_word(spanish, where, ['dónde']).
ty_wh_word(spanish, when, ['cuándo']).

%% Relative clauses: the head, the marker, the clause (`el perro que el
%% niño ve').
ty_order(spanish, rel, [h, m, c]).
ty_relative(spanish, any, [que], [[]]).

%% A verb's complement (`El niño piensa en la niña.'); the adposition moves
%% with its question word (`¿En qué piensa el niño?'). `mirar', `esperar'
%% and `escuchar' take a plain object (`El niño mira al perro.').
ty_complement(spanish, think, [en]).
ty_complement(spanish, depend, [de]).
ty_complement(spanish, dream, [con]).
ty_complement_wh(spanish, moves).

%% A relative clause's gap in an adposition phrase: the adposition moves
%% into the marker with the article of the head and `que' (`la casa en la
%% que el perro duerme', `la niña en la que el niño piensa'); `en que' is
%% read.
ty_gap(spanish, pp, moves).
ty_relative_pronoun(spanish, [el, que], [[m, sg]]).
ty_relative_pronoun(spanish, [la, que], [[f, sg]]).
ty_relative_pronoun(spanish, [los, que], [[m, pl]]).
ty_relative_pronoun(spanish, [las, que], [[f, pl]]).
ty_relative_pronoun(spanish, [que], [[]]).

%% The answer to a yes or no question (`Sí, el niño ve al perro.').
ty_answer(spanish, yes, ['sí']).
ty_answer(spanish, no, [no]).

%% A possessor (`el perro del niño'): the possessed, `de', the possessor.
%% `cuyo' moves with the possessed into the marker and agrees with it (`el
%% niño cuyo perro duerme', `el niño cuyas niñas duermen').
ty_possessive(spanish, [h, p, g], [de], keep).
ty_gap(spanish, poss, moves).
ty_relative_possessive(spanish, [cuyo], [[m, sg]]).
ty_relative_possessive(spanish, [cuya], [[f, sg]]).
ty_relative_possessive(spanish, [cuyos], [[m, pl]]).
ty_relative_possessive(spanish, [cuyas], [[f, pl]]).

%% A possessive pronoun (`su perro', `sus perros'): by the possessed's
%% number, whoever the possessor is.
ty_possessive_pronoun(spanish, [su], [[]], [[sg]]).
ty_possessive_pronoun(spanish, [sus], [[]], [[pl]]).
