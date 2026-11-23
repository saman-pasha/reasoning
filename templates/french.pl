%% templates/french.pl -- the template of French, for
%% library(reasoning/typology). Facts only; typology_load(french) reads it.
%% A hand template: corpus/vocabulary has no French, so there is no
%% templates/french-words.pl.

%% The orders: subject, verb, object; the article, the noun, the
%% adjectives. A few adjectives stand before the noun (`un petit chien
%% noir'): ty_adjective_before/2, below.
ty_order(french, clause, [s, v, o]).
ty_order(french, np, [d, n, a]).

%% The nouns: Meaning, Gender, Animacy (person, animate, inanimate; a
%% person is animate too), Singular, Plural.
ty_noun(french, dog, m, animate, chien, chiens).
ty_noun(french, cat, m, animate, chat, chats).
ty_noun(french, boy, m, person, 'garçon', 'garçons').
ty_noun(french, girl, f, person, fille, filles).
ty_noun(french, man, m, person, homme, hommes).
ty_noun(french, book, m, inanimate, livre, livres).
ty_noun(french, mouse, f, animate, souris, souris).
ty_noun(french, house, f, inanimate, maison, maisons).
ty_noun(french, animal, m, animate, animal, animaux).

%% The adjectives agree with the noun in gender and number.
ty_adjective(french, big, m, sg, grand).
ty_adjective(french, big, f, sg, grande).
ty_adjective(french, big, m, pl, grands).
ty_adjective(french, big, f, pl, grandes).
ty_adjective(french, small, m, sg, petit).
ty_adjective(french, small, f, sg, petite).
ty_adjective(french, small, m, pl, petits).
ty_adjective(french, small, f, pl, petites).
ty_adjective(french, black, m, sg, noir).
ty_adjective(french, black, f, sg, noire).
ty_adjective(french, black, m, pl, noirs).
ty_adjective(french, black, f, pl, noires).
ty_adjective(french, red, any, sg, rouge).
ty_adjective(french, red, any, pl, rouges).
ty_adjective_before(french, big).
ty_adjective_before(french, small).

%% The verbs: the positive forms of every person. The past is the passé
%% simple, one word (Italian's template takes the passato remoto so too).
ty_verb(french, see, present, sg, pos, [voit]).
ty_verb(french, see, present, pl, pos, [voient]).
ty_verb(french, see, present, sg(1), pos, [vois]).
ty_verb(french, see, present, sg(2), pos, [vois]).
ty_verb(french, see, present, pl(1), pos, [voyons]).
ty_verb(french, see, present, pl(2), pos, [voyez]).
ty_verb(french, see, past, sg, pos, [vit]).
ty_verb(french, see, past, pl, pos, [virent]).
ty_verb(french, see, past, sg(1), pos, [vis]).
ty_verb(french, see, past, sg(2), pos, [vis]).
ty_verb(french, see, past, pl(1), pos, ['vîmes']).
ty_verb(french, see, past, pl(2), pos, ['vîtes']).
ty_verb(french, sleep, present, sg, pos, [dort]).
ty_verb(french, sleep, present, pl, pos, [dorment]).
ty_verb(french, sleep, present, sg(1), pos, [dors]).
ty_verb(french, sleep, present, sg(2), pos, [dors]).
ty_verb(french, sleep, present, pl(1), pos, [dormons]).
ty_verb(french, sleep, present, pl(2), pos, [dormez]).
ty_verb(french, sleep, past, sg, pos, [dormit]).
ty_verb(french, sleep, past, pl, pos, [dormirent]).
ty_verb(french, sleep, past, sg(1), pos, [dormis]).
ty_verb(french, sleep, past, sg(2), pos, [dormis]).
ty_verb(french, sleep, past, pl(1), pos, ['dormîmes']).
ty_verb(french, sleep, past, pl(2), pos, ['dormîtes']).
ty_verb(french, think, present, sg, pos, [pense]).
ty_verb(french, think, present, pl, pos, [pensent]).
ty_verb(french, think, present, sg(1), pos, [pense]).
ty_verb(french, think, present, sg(2), pos, [penses]).
ty_verb(french, think, present, pl(1), pos, [pensons]).
ty_verb(french, think, present, pl(2), pos, [pensez]).
ty_verb(french, think, past, sg, pos, [pensa]).
ty_verb(french, think, past, pl, pos, ['pensèrent']).
ty_verb(french, think, past, sg(1), pos, [pensai]).
ty_verb(french, think, past, sg(2), pos, [pensas]).
ty_verb(french, think, past, pl(1), pos, ['pensâmes']).
ty_verb(french, think, past, pl(2), pos, ['pensâtes']).
ty_verb(french, look, present, sg, pos, [regarde]).
ty_verb(french, look, present, pl, pos, [regardent]).
ty_verb(french, look, present, sg(1), pos, [regarde]).
ty_verb(french, look, present, sg(2), pos, [regardes]).
ty_verb(french, look, present, pl(1), pos, [regardons]).
ty_verb(french, look, present, pl(2), pos, [regardez]).
ty_verb(french, look, past, sg, pos, [regarda]).
ty_verb(french, look, past, pl, pos, ['regardèrent']).
ty_verb(french, look, past, sg(1), pos, [regardai]).
ty_verb(french, look, past, sg(2), pos, [regardas]).
ty_verb(french, look, past, pl(1), pos, ['regardâmes']).
ty_verb(french, look, past, pl(2), pos, ['regardâtes']).

%% The negation is two words around the verb, which stays positive (`Le
%% garçon ne voit pas le chien.'); an object clitic stands inside them
%% (`ne le voit pas').
ty_negation_place(french, [ne], before(v)).
ty_negation_place(french, [pas], after(v)).

%% The future, a word of its own; the passé composé, `avoir' and the
%% participle (`a vu', `n'a pas vu'), which agrees with an object clitic
%% of the third person before it (`il l'a vue', `il les a vus'). The
%% negation and an inverted pronoun stand after the auxiliary (`A-t-il vu
%% le chien?').
ty_verb(french, see, future, sg, pos, [verra]).
ty_verb(french, see, future, pl, pos, [verront]).
ty_verb(french, see, future, sg(1), pos, [verrai]).
ty_verb(french, see, future, sg(2), pos, [verras]).
ty_verb(french, see, future, pl(1), pos, [verrons]).
ty_verb(french, see, future, pl(2), pos, [verrez]).
ty_verb(french, sleep, future, sg, pos, [dormira]).
ty_verb(french, sleep, future, pl, pos, [dormiront]).
ty_verb(french, sleep, future, sg(1), pos, [dormirai]).
ty_verb(french, sleep, future, sg(2), pos, [dormiras]).
ty_verb(french, sleep, future, pl(1), pos, [dormirons]).
ty_verb(french, sleep, future, pl(2), pos, [dormirez]).
ty_verb(french, think, future, sg, pos, [pensera]).
ty_verb(french, think, future, pl, pos, [penseront]).
ty_verb(french, think, future, sg(1), pos, [penserai]).
ty_verb(french, think, future, sg(2), pos, [penseras]).
ty_verb(french, think, future, pl(1), pos, [penserons]).
ty_verb(french, think, future, pl(2), pos, [penserez]).
ty_verb(french, look, future, sg, pos, [regardera]).
ty_verb(french, look, future, pl, pos, [regarderont]).
ty_verb(french, look, future, sg(1), pos, [regarderai]).
ty_verb(french, look, future, sg(2), pos, [regarderas]).
ty_verb(french, look, future, pl(1), pos, [regarderons]).
ty_verb(french, look, future, pl(2), pos, [regarderez]).
ty_tense_form(french, perfect, sg, pos, ['a', participle]).
ty_tense_form(french, perfect, pl, pos, ['ont', participle]).
ty_tense_form(french, perfect, sg(1), pos, ['ai', participle]).
ty_tense_form(french, perfect, sg(2), pos, ['as', participle]).
ty_tense_form(french, perfect, pl(1), pos, ['avons', participle]).
ty_tense_form(french, perfect, pl(2), pos, ['avez', participle]).
ty_participle(french, see, vu).
ty_participle(french, sleep, dormi).
ty_participle(french, think, 'pensé').
ty_participle(french, look, 'regardé').
ty_participle_ending(french, f, sg, '', e).
ty_participle_ending(french, m, pl, '', s).
ty_participle_ending(french, f, pl, '', es).
ty_participle_agrees(french, clitic).
%% `aller', whose passé composé takes `être', the participle agreeing with
%% the subject (`La fille est allée', `Les filles sont allées').
ty_verb(french, go, present, sg, pos, [va]).
ty_verb(french, go, present, pl, pos, [vont]).
ty_verb(french, go, present, sg(1), pos, [vais]).
ty_verb(french, go, present, sg(2), pos, [vas]).
ty_verb(french, go, present, pl(1), pos, [allons]).
ty_verb(french, go, present, pl(2), pos, [allez]).
ty_verb(french, go, past, sg, pos, [alla]).
ty_verb(french, go, past, pl, pos, ['allèrent']).
ty_verb(french, go, past, sg(1), pos, [allai]).
ty_verb(french, go, past, sg(2), pos, [allas]).
ty_verb(french, go, past, pl(1), pos, ['allâmes']).
ty_verb(french, go, past, pl(2), pos, ['allâtes']).
ty_verb(french, go, future, sg, pos, [ira]).
ty_verb(french, go, future, pl, pos, [iront]).
ty_verb(french, go, future, sg(1), pos, [irai]).
ty_verb(french, go, future, sg(2), pos, [iras]).
ty_verb(french, go, future, pl(1), pos, [irons]).
ty_verb(french, go, future, pl(2), pos, [irez]).
ty_participle(french, go, 'allé').
ty_verb_class(french, go, 'être').
ty_class_tense_form(french, 'être', perfect, sg, pos, [est, participle(subject)]).
ty_class_tense_form(french, 'être', perfect, pl, pos, [sont, participle(subject)]).
ty_class_tense_form(french, 'être', perfect, sg(1), pos, [suis, participle(subject)]).
ty_class_tense_form(french, 'être', perfect, sg(2), pos, [es, participle(subject)]).
ty_class_tense_form(french, 'être', perfect, pl(1), pos, [sommes, participle(subject)]).
ty_class_tense_form(french, 'être', perfect, pl(2), pos, ['êtes', participle(subject)]).

%% The articles agree with the noun; a plural indefinite is `des'.
ty_article(french, def, m, sg, le).
ty_article(french, def, f, sg, la).
ty_article(french, def, any, pl, les).
ty_article(french, indef, m, sg, un).
ty_article(french, indef, f, sg, une).
ty_article(french, indef, any, pl, des).
%% The article of a question (`Quel chien le garçon voit-il ?' is not
%% written: `Quel chien voit le garçon ?').
ty_article(french, which, m, sg, quel).
ty_article(french, which, f, sg, quelle).
ty_article(french, which, m, pl, quels).
ty_article(french, which, f, pl, quelles).

%% Elision: `le', `la', `de', `ne', `que', `je', `me' and `te' lose their
%% vowel before a vowel or a mute h, written joined to the next word
%% (`l'homme', `n'est', `d'un').
ty_letters(french, vowel, [a, e, i, o, u, y, 'é', 'è', 'ê', 'à', 'â', 'î', 'ô', 'û']).
ty_letters(french, consonant, [b, c, d, f, g, h, j, k, l, m, n, p, q, r, s, t, v, w, x, z, 'ç']).
ty_before(french, le, [[vowel], [h]], 'l\'', joined).
ty_before(french, la, [[vowel], [h]], 'l\'', joined).
ty_before(french, de, [[vowel], [h]], 'd\'', joined).
ty_before(french, ne, [[vowel], [h]], 'n\'', joined).
ty_before(french, que, [[vowel], [h]], 'qu\'', joined).
ty_before(french, je, [[vowel], [h]], 'j\'', joined).
ty_before(french, me, [[vowel], [h]], 'm\'', joined).
ty_before(french, te, [[vowel], [h]], 't\'', joined).

%% `à le' and `de le' are `au' and `du', `à les' and `de les' `aux' and
%% `des' (`l'' stays: `à l'homme').
ty_contraction(french, ['à', le], au).
ty_contraction(french, ['à', les], aux).
ty_contraction(french, [de, le], du).
ty_contraction(french, [de, les], des).

%% The copula clause: subject, copula, predicate; the past is the
%% imperfect, the past of a state; the negation around the copula.
ty_order(french, copula, [s, c, p]).
ty_copula(french, any, present, sg, pos, [est]).
ty_copula(french, any, present, pl, pos, [sont]).
ty_copula(french, any, present, sg(1), pos, [suis]).
ty_copula(french, any, present, sg(2), pos, [es]).
ty_copula(french, any, present, pl(1), pos, [sommes]).
ty_copula(french, any, present, pl(2), pos, ['êtes']).
ty_copula(french, any, past, sg, pos, ['était']).
ty_copula(french, any, past, pl, pos, ['étaient']).
ty_copula(french, any, past, sg(1), pos, ['étais']).
ty_copula(french, any, past, sg(2), pos, ['étais']).
ty_copula(french, any, past, pl(1), pos, ['étions']).
ty_copula(french, any, past, pl(2), pos, ['étiez']).
ty_copula(french, any, present, sg, neg, [ne, est, pas]).
ty_copula(french, any, present, pl, neg, [ne, sont, pas]).
ty_copula(french, any, present, sg(1), neg, [ne, suis, pas]).
ty_copula(french, any, present, sg(2), neg, [ne, es, pas]).
ty_copula(french, any, present, pl(1), neg, [ne, sommes, pas]).
ty_copula(french, any, present, pl(2), neg, [ne, 'êtes', pas]).
ty_copula(french, any, past, sg, neg, [ne, 'était', pas]).
ty_copula(french, any, past, pl, neg, [ne, 'étaient', pas]).
ty_copula(french, any, past, sg(1), neg, [ne, 'étais', pas]).
ty_copula(french, any, past, sg(2), neg, [ne, 'étais', pas]).
ty_copula(french, any, past, pl(1), neg, [ne, 'étions', pas]).
ty_copula(french, any, past, pl(2), neg, [ne, 'étiez', pas]).

%% Prepositions; the adjuncts at the clause's end.
ty_order(french, pp, [p, x]).
ty_adjunct(french, end).
ty_adposition(french, in, [dans]).
ty_adposition(french, on, [sur]).
ty_adposition(french, with, [avec]).
ty_adposition(french, to, ['à']).
ty_adposition(french, from, [de]).
ty_adverb(french, quickly, vite).
ty_adverb(french, slowly, lentement).
ty_adverb(french, today, 'aujourd\'hui').
ty_adverb(french, here, ici).

%% Questions: a yes or no question with `est-ce que' first, or in the
%% statement's order; a question word at the front, the verb before a
%% subject after it (`Que voit le garçon ?'), or in place (`La fille vit
%% qui ?', whom the girl saw, where `Qui vit la fille ?' is who saw her).
%% A yes or no question may also take the inversion, a pronoun of the
%% subject joined to the verb (`Le garçon voit-il le chien?', `Voit-il le
%% chien?', `Pense-t-il à la fille?'), and a question word `est-ce que'
%% after it (`Qu'est-ce que le garçon voit?'). After a preposition and in
%% place `what' is `quoi' (`À quoi pense le garçon?', `La fille voit
%% quoi?').
%% The written question mark is `?' with no space before it.
ty_question(french, yes_no, clause, particle(['est-ce', que], start)).
ty_question(french, yes_no, clause, unchanged).
ty_question(french, yes_no, copula, particle(['est-ce', que], start)).
ty_question(french, yes_no, copula, unchanged).
ty_question(french, yes_no, clause, invert(pronoun)).
ty_question(french, yes_no, copula, invert(pronoun)).
ty_question(french, wh, clause, front(all)).
ty_question(french, wh, copula, front(all)).
ty_question(french, wh, clause, particle(['est-ce', que], start)).
ty_inversion(french, '-', '-t-').
ty_wh(french, front).
ty_wh(french, in_place).
ty_wh_word(french, who, [qui]).
ty_wh_word(french, what, [que]).
ty_wh_tonic(french, what, [quoi]).
ty_wh_word(french, where, ['où']).
ty_wh_word(french, when, [quand]).

%% Relative clauses: the head, the marker, the clause; `qui' where the
%% gap is the subject, `que' where it is the object (`le chien qui dort',
%% `le chien que le garçon voit').
ty_order(french, rel, [h, m, c]).
ty_relative(french, s, [qui], [[]]).
ty_relative(french, o, [que], [[]]).

%% A verb's complement (`Le garçon pense à la fille.'), its adposition
%% moving with its question word.
ty_complement(french, think, ['à']).
ty_complement_wh(french, moves).

%% A relative clause's gap in an adposition phrase: the adposition moves
%% into the marker with `qui' for a person and `lequel' agreeing with
%% another head (`la fille à qui le garçon pense', `la maison dans
%% laquelle le chien dort'), `à lequel' written `auquel'.
ty_gap(french, pp, moves).
ty_relative_pronoun(french, [qui], [[person]]).
ty_relative_pronoun(french, [lequel], [[m, sg]]).
ty_relative_pronoun(french, [laquelle], [[f, sg]]).
ty_relative_pronoun(french, [lesquels], [[m, pl]]).
ty_relative_pronoun(french, [lesquelles], [[f, pl]]).
ty_contraction(french, ['à', lequel], auquel).
ty_contraction(french, ['à', lesquels], auxquels).
ty_contraction(french, ['à', lesquelles], auxquelles).
ty_contraction(french, [de, lequel], duquel).
ty_contraction(french, [de, lesquels], desquels).
ty_contraction(french, [de, lesquelles], desquelles).

%% The answer to a yes or no question; `si' contradicts a negative one.
ty_answer(french, yes, [oui]).
ty_answer(french, no, [non]).
ty_answer(french, contradict, [si]).

%% A possessor (`le chien du garçon'): the possessed, `de', the possessor.
%% `dont' is the marker of a relative clause whose gap is a possessor, the
%% possessed staying where it stands with its article (`le garçon dont le
%% chien dort', the boy whose dog sleeps).
ty_possessive(french, [h, p, g], [de], keep).
ty_gap(french, poss, stays).
ty_relative_possessive(french, [dont], [[]]).

%% A possessive pronoun, by the possessor's person and number and the
%% possessed's gender and number (`mon chien', `sa maison', `leurs livres').
ty_possessive_pronoun(french, [mon], [[1, sg]], [[m, sg]]).
ty_possessive_pronoun(french, [ma], [[1, sg]], [[f, sg]]).
ty_possessive_pronoun(french, [mes], [[1, sg]], [[pl]]).
ty_possessive_pronoun(french, [ton], [[2, sg]], [[m, sg]]).
ty_possessive_pronoun(french, [ta], [[2, sg]], [[f, sg]]).
ty_possessive_pronoun(french, [tes], [[2, sg]], [[pl]]).
ty_possessive_pronoun(french, [son], [[3, sg]], [[m, sg]]).
ty_possessive_pronoun(french, [sa], [[3, sg]], [[f, sg]]).
ty_possessive_pronoun(french, [ses], [[3, sg]], [[pl]]).
ty_possessive_pronoun(french, [notre], [[1, pl]], [[sg]]).
ty_possessive_pronoun(french, [nos], [[1, pl]], [[pl]]).
ty_possessive_pronoun(french, [votre], [[2, pl], [polite]], [[sg]]).
ty_possessive_pronoun(french, [vos], [[2, pl], [polite]], [[pl]]).
ty_possessive_pronoun(french, [leur], [[3, pl]], [[sg]]).
ty_possessive_pronoun(french, [leurs], [[3, pl]], [[pl]]).

%% Personal pronouns: a subject's, always written (French drops none); an
%% object's, a clitic in the verb's words, inside the negation (`La fille
%% le voit.', `Je ne la vois pas.'); and an adposition's (`avec lui',
%% `à elle').
ty_pronoun(french, s, [je], [[1, sg]]).
ty_pronoun(french, s, [tu], [[2, sg]]).
ty_pronoun(french, s, [il], [[3, sg, m], [3, sg, n]]).
ty_pronoun(french, s, [elle], [[3, sg, f]]).
ty_pronoun(french, s, [nous], [[1, pl]]).
ty_pronoun(french, s, [vous], [[2, pl], [polite]]).
ty_pronoun(french, s, [ils], [[3, pl, m], [3, pl, n]]).
ty_pronoun(french, s, [elles], [[3, pl, f]]).
ty_pronoun(french, o, [me], [[1, sg]]).
ty_pronoun(french, o, [te], [[2, sg]]).
ty_pronoun(french, o, [le], [[3, sg, m], [3, sg, n]]).
ty_pronoun(french, o, [la], [[3, sg, f]]).
ty_pronoun(french, o, [nous], [[1, pl]]).
ty_pronoun(french, o, [vous], [[2, pl], [polite]]).
ty_pronoun(french, o, [les], [[3, pl]]).
ty_pronoun(french, j, [moi], [[1, sg]]).
ty_pronoun(french, j, [toi], [[2, sg]]).
ty_pronoun(french, j, [lui], [[3, sg, m], [3, sg, n]]).
ty_pronoun(french, j, [elle], [[3, sg, f]]).
ty_pronoun(french, j, [nous], [[1, pl]]).
ty_pronoun(french, j, [vous], [[2, pl], [polite]]).
ty_pronoun(french, j, [eux], [[3, pl, m], [3, pl, n]]).
ty_pronoun(french, j, [elles], [[3, pl, f]]).
ty_clitic(french, o).
%% The polite `you' is `vous' with the second plural's form (`Vous voyez le
%% chien.'), one person's adjectives singular (`Vous êtes petit.').
ty_polite(french, sg, pl(2)).
ty_polite(french, pl, pl(2)).

%% A pronoun of the text takes the gender of the noun it stands for (a
%% house is `la', a book `lo').
ty_pronoun_gender(french, grammatical).
