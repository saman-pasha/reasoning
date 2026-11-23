%% templates/spanish.pl -- the template of Spanish, for
%% library(reasoning/typology). Facts only; typology_load(spanish) reads it.

%% The orders: subject, verb, object; the article, the noun, the adjectives.
ty_order(spanish, clause, [s, v, o]).
ty_order(spanish, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy (person, animate, inanimate; a person is animate too), Singular, Plural.
ty_noun(spanish, dog, m, animate, perro, perros).
ty_noun(spanish, cat, m, animate, gato, gatos).
%% `marzo', the month: a meaning of its own (templates/topics.pl).
ty_noun(spanish, march_month, m, unknown, marzo, marzos).
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

%% The future, a word of its own; the perfect, `haber' and the participle
%% (`ha visto', `no lo ha visto'). The import gives the vocabulary's verbs
%% their participles and futures.
ty_verb(spanish, see, future, sg, pos, ['verá']).
ty_verb(spanish, see, future, pl, pos, ['verán']).
ty_verb(spanish, see, future, sg(1), pos, ['veré']).
ty_verb(spanish, see, future, sg(2), pos, ['verás']).
ty_verb(spanish, see, future, pl(1), pos, [veremos]).
ty_verb(spanish, see, future, pl(2), pos, ['veréis']).
ty_verb(spanish, sleep, future, sg, pos, ['dormirá']).
ty_verb(spanish, sleep, future, pl, pos, ['dormirán']).
ty_verb(spanish, sleep, future, sg(1), pos, ['dormiré']).
ty_verb(spanish, sleep, future, sg(2), pos, ['dormirás']).
ty_verb(spanish, sleep, future, pl(1), pos, [dormiremos]).
ty_verb(spanish, sleep, future, pl(2), pos, ['dormiréis']).
ty_tense_form(spanish, perfect, sg, pos, [ha, participle]).
ty_tense_form(spanish, perfect, pl, pos, [han, participle]).
ty_tense_form(spanish, perfect, sg(1), pos, [he, participle]).
ty_tense_form(spanish, perfect, sg(2), pos, [has, participle]).
ty_tense_form(spanish, perfect, pl(1), pos, [hemos, participle]).
ty_tense_form(spanish, perfect, pl(2), pos, ['habéis', participle]).
ty_participle(spanish, see, visto).
ty_participle(spanish, sleep, dormido).
%% The future the import makes: a stated future's stem, else the
%% infinitive's (`ver' `verá'; `tener' `tendrá'), and each person's ending.
ty_ending(spanish, future_stem, '', '').
ty_ending(spanish, future_stem, tener, tendr).
ty_ending(spanish, future_stem, poner, pondr).
ty_ending(spanish, future_stem, venir, vendr).
ty_ending(spanish, future_stem, salir, saldr).
ty_ending(spanish, future_stem, valer, valdr).
ty_ending(spanish, future_stem, hacer, har).
ty_ending(spanish, future_stem, decir, dir).
ty_ending(spanish, future_stem, poder, podr).
ty_ending(spanish, future_stem, querer, querr).
ty_ending(spanish, future_stem, saber, sabr).
ty_ending(spanish, future_stem, caber, cabr).
ty_ending(spanish, future_stem, haber, habr).
ty_ending(spanish, future(sg), '', 'á').
ty_ending(spanish, future(pl), '', 'án').
ty_ending(spanish, future(sg(1)), '', 'é').
ty_ending(spanish, future(sg(2)), '', 'ás').
ty_ending(spanish, future(pl(1)), '', emos).
ty_ending(spanish, future(pl(2)), '', 'éis').

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
%% `to' (`ve a un libro': sees, to a book). A possessive pronoun may stand
%% between (`ve a su perro'). The lookback may pass over the
%% subject of a question (`¿Ve el niño al perro?'), and before `quién' it is
%% the mark with no verb before it (`¿A quién ve el niño?').
ty_sense(spanish, a, mark(o), [class(verb)], [opt(class(article)), opt(class(possessive)), class(noun, animate)]).
ty_sense(spanish, a, mark(o), [class(noun), opt(class(article)), class(verb)],
         [opt(class(article)), opt(class(possessive)), class(noun, animate)]).
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

%% A possessive pronoun (`mi perro', `su perro', `sus perros'): by the
%% possessor's person and number (`su' is any third person's) and the
%% possessed's number, `nuestro' and `vuestro' by its gender too.
ty_possessive_pronoun(spanish, [mi], [[1, sg]], [[sg]]).
ty_possessive_pronoun(spanish, [mis], [[1, sg]], [[pl]]).
ty_possessive_pronoun(spanish, [tu], [[2, sg]], [[sg]]).
ty_possessive_pronoun(spanish, [tus], [[2, sg]], [[pl]]).
ty_possessive_pronoun(spanish, [su], [[3], [polite]], [[sg]]).
ty_possessive_pronoun(spanish, [sus], [[3], [polite]], [[pl]]).
ty_possessive_pronoun(spanish, [nuestro], [[1, pl]], [[m, sg]]).
ty_possessive_pronoun(spanish, [nuestra], [[1, pl]], [[f, sg]]).
ty_possessive_pronoun(spanish, [nuestros], [[1, pl]], [[m, pl]]).
ty_possessive_pronoun(spanish, [nuestras], [[1, pl]], [[f, pl]]).
ty_possessive_pronoun(spanish, [vuestro], [[2, pl]], [[m, sg]]).
ty_possessive_pronoun(spanish, [vuestra], [[2, pl]], [[f, sg]]).
ty_possessive_pronoun(spanish, [vuestros], [[2, pl]], [[m, pl]]).
ty_possessive_pronoun(spanish, [vuestras], [[2, pl]], [[f, pl]]).

%% Personal pronouns: a subject's, which the verb's form makes no word for
%% the first and the second persons (`Veo al perro.', I see the dog), and
%% may make none for the third (`Duerme.'); an object's, a clitic in the
%% verb's words (`La niña lo ve.', `No la veo.'); and an adposition's (`con
%% ella', `en él'; `conmigo', `contigo').
ty_pronoun(spanish, s, [yo], [[1, sg]]).
ty_pronoun(spanish, s, [tú], [[2, sg]]).
ty_pronoun(spanish, s, [él], [[3, sg, m]]).
ty_pronoun(spanish, s, [ella], [[3, sg, f]]).
ty_pronoun(spanish, s, [nosotros], [[1, pl, m]]).
ty_pronoun(spanish, s, [nosotras], [[1, pl, f]]).
ty_pronoun(spanish, s, [vosotros], [[2, pl, m]]).
ty_pronoun(spanish, s, [vosotras], [[2, pl, f]]).
ty_pronoun(spanish, s, [usted], [[polite, sg]]).
ty_pronoun(spanish, s, [ustedes], [[polite, pl]]).
ty_pronoun(spanish, s, [ellos], [[3, pl, m], [3, pl, n]]).
ty_pronoun(spanish, s, [ellas], [[3, pl, f]]).
ty_pronoun(spanish, o, [me], [[1, sg]]).
ty_pronoun(spanish, o, [te], [[2, sg]]).
ty_pronoun(spanish, o, [lo], [[3, sg, m], [3, sg, n], [polite, sg, m]]).
ty_pronoun(spanish, o, [la], [[3, sg, f], [polite, sg, f]]).
ty_pronoun(spanish, o, [nos], [[1, pl]]).
ty_pronoun(spanish, o, [os], [[2, pl]]).
ty_pronoun(spanish, o, [los], [[3, pl, m], [3, pl, n], [polite, pl, m]]).
ty_pronoun(spanish, o, [las], [[3, pl, f], [polite, pl, f]]).
ty_pronoun(spanish, j, [mí], [[1, sg]]).
ty_pronoun(spanish, j, [ti], [[2, sg]]).
ty_pronoun(spanish, j, [él], [[3, sg, m], [3, sg, n]]).
ty_pronoun(spanish, j, [ella], [[3, sg, f]]).
ty_pronoun(spanish, j, [nosotros], [[1, pl, m]]).
ty_pronoun(spanish, j, [nosotras], [[1, pl, f]]).
ty_pronoun(spanish, j, [vosotros], [[2, pl, m]]).
ty_pronoun(spanish, j, [vosotras], [[2, pl, f]]).
ty_pronoun(spanish, j, [usted], [[polite, sg]]).
ty_pronoun(spanish, j, [ustedes], [[polite, pl]]).
ty_pronoun(spanish, j, [ellos], [[3, pl, m], [3, pl, n]]).
ty_pronoun(spanish, j, [ellas], [[3, pl, f]]).
ty_contraction(spanish, [con, mí], conmigo).
ty_contraction(spanish, [con, ti], contigo).
ty_pro_drop(spanish, [1, 2]).
%% The polite `you', `usted' and `ustedes', takes the third person's form
%% (`Usted ve al perro.'), its object clitic and its possessive the third
%% person's too (`Lo veo.', `su perro'); it is never dropped.
ty_polite(spanish, sg, sg).
ty_polite(spanish, pl, pl).
ty_clitic(spanish, o).

%% The first and the second persons of the verbs above (the import gives
%% every other verb's from the vocabulary), and of the copula; a negative
%% is `no' before the positive.
ty_verb(spanish, see, present, sg(1), pos, [veo]).
ty_verb(spanish, see, present, sg(2), pos, [ves]).
ty_verb(spanish, see, present, pl(1), pos, [vemos]).
ty_verb(spanish, see, present, pl(2), pos, [veis]).
ty_verb(spanish, see, past, sg(1), pos, [vi]).
ty_verb(spanish, see, past, sg(2), pos, [viste]).
ty_verb(spanish, see, past, pl(1), pos, [vimos]).
ty_verb(spanish, see, past, pl(2), pos, [visteis]).
ty_verb(spanish, sleep, present, sg(1), pos, [duermo]).
ty_verb(spanish, sleep, present, sg(2), pos, [duermes]).
ty_verb(spanish, sleep, present, pl(1), pos, [dormimos]).
ty_verb(spanish, sleep, present, pl(2), pos, [dormís]).
ty_verb(spanish, sleep, past, sg(1), pos, [dormí]).
ty_verb(spanish, sleep, past, sg(2), pos, [dormiste]).
ty_verb(spanish, sleep, past, pl(1), pos, [dormimos]).
ty_verb(spanish, sleep, past, pl(2), pos, [dormisteis]).
ty_copula(spanish, adj, present, sg(1), pos, [soy]).
ty_copula(spanish, adj, present, sg(2), pos, [eres]).
ty_copula(spanish, adj, present, pl(1), pos, [somos]).
ty_copula(spanish, adj, present, pl(2), pos, [sois]).
ty_copula(spanish, adj, past, sg(1), pos, [era]).
ty_copula(spanish, adj, past, sg(2), pos, [eras]).
ty_copula(spanish, adj, past, pl(1), pos, [éramos]).
ty_copula(spanish, adj, past, pl(2), pos, [erais]).
ty_copula(spanish, np, present, sg(1), pos, [soy]).
ty_copula(spanish, np, present, sg(2), pos, [eres]).
ty_copula(spanish, np, present, pl(1), pos, [somos]).
ty_copula(spanish, np, present, pl(2), pos, [sois]).
ty_copula(spanish, np, past, sg(1), pos, [era]).
ty_copula(spanish, np, past, sg(2), pos, [eras]).
ty_copula(spanish, np, past, pl(1), pos, [éramos]).
ty_copula(spanish, np, past, pl(2), pos, [erais]).
ty_copula(spanish, pp, present, sg(1), pos, [estoy]).
ty_copula(spanish, pp, present, sg(2), pos, [estás]).
ty_copula(spanish, pp, present, pl(1), pos, [estamos]).
ty_copula(spanish, pp, present, pl(2), pos, [estáis]).
ty_copula(spanish, pp, past, sg(1), pos, [estaba]).
ty_copula(spanish, pp, past, sg(2), pos, [estabas]).
ty_copula(spanish, pp, past, pl(1), pos, [estábamos]).
ty_copula(spanish, pp, past, pl(2), pos, [estabais]).

%% A pronoun of the text takes the gender of the noun it stands for (a
%% house is `la', a book `lo').
ty_pronoun_gender(spanish, grammatical).

%% The copula's future and perfect, `ser' and `estar' (`será', `ha sido',
%% `estará', `ha estado'); the negative is `no' before them.
ty_copula(spanish, adj, future, sg, pos, [será]).
ty_copula(spanish, adj, future, pl, pos, [serán]).
ty_copula(spanish, adj, future, sg(1), pos, [seré]).
ty_copula(spanish, adj, future, sg(2), pos, [serás]).
ty_copula(spanish, adj, future, pl(1), pos, [seremos]).
ty_copula(spanish, adj, future, pl(2), pos, [seréis]).
ty_copula(spanish, adj, perfect, sg, pos, [ha, sido]).
ty_copula(spanish, adj, perfect, pl, pos, [han, sido]).
ty_copula(spanish, adj, perfect, sg(1), pos, [he, sido]).
ty_copula(spanish, adj, perfect, sg(2), pos, [has, sido]).
ty_copula(spanish, adj, perfect, pl(1), pos, [hemos, sido]).
ty_copula(spanish, adj, perfect, pl(2), pos, [habéis, sido]).
ty_copula(spanish, np, future, sg, pos, [será]).
ty_copula(spanish, np, future, pl, pos, [serán]).
ty_copula(spanish, np, future, sg(1), pos, [seré]).
ty_copula(spanish, np, future, sg(2), pos, [serás]).
ty_copula(spanish, np, future, pl(1), pos, [seremos]).
ty_copula(spanish, np, future, pl(2), pos, [seréis]).
ty_copula(spanish, np, perfect, sg, pos, [ha, sido]).
ty_copula(spanish, np, perfect, pl, pos, [han, sido]).
ty_copula(spanish, np, perfect, sg(1), pos, [he, sido]).
ty_copula(spanish, np, perfect, sg(2), pos, [has, sido]).
ty_copula(spanish, np, perfect, pl(1), pos, [hemos, sido]).
ty_copula(spanish, np, perfect, pl(2), pos, [habéis, sido]).
ty_copula(spanish, pp, future, sg, pos, [estará]).
ty_copula(spanish, pp, future, pl, pos, [estarán]).
ty_copula(spanish, pp, future, sg(1), pos, [estaré]).
ty_copula(spanish, pp, future, sg(2), pos, [estarás]).
ty_copula(spanish, pp, future, pl(1), pos, [estaremos]).
ty_copula(spanish, pp, future, pl(2), pos, [estaréis]).
ty_copula(spanish, pp, perfect, sg, pos, [ha, estado]).
ty_copula(spanish, pp, perfect, pl, pos, [han, estado]).
ty_copula(spanish, pp, perfect, sg(1), pos, [he, estado]).
ty_copula(spanish, pp, perfect, sg(2), pos, [has, estado]).
ty_copula(spanish, pp, perfect, pl(1), pos, [hemos, estado]).
ty_copula(spanish, pp, perfect, pl(2), pos, [habéis, estado]).
