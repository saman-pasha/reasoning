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
%% THE DETERMINERS AND THE QUANTIFIERS (since 1.63.0): each a definiteness
%% of its own with its article's words, and the quantifier pronouns, a
%% quantifier and a kind (qp(Quantifier, Kind) in the IR), singular.
%% `ce', `cette' and `ces' are this and that both.
ty_article(french, every, any, sg, chaque).
ty_article(french, each, any, sg, chaque).
ty_article(french, all, m, pl, 'tous les').
ty_article(french, all, f, pl, 'toutes les').
ty_article(french, some, any, pl, quelques).
ty_article(french, this, m, sg, ce).
ty_article(french, this, f, sg, cette).
ty_article(french, this, any, pl, ces).
ty_article(french, that, m, sg, ce).
ty_article(french, that, f, sg, cette).
ty_article(french, that, any, pl, ces).
ty_before(french, ce, [[vowel], [h]], cet, space).
ty_quantifier_pronoun(french, some, thing, [quelque, chose]).
ty_quantifier_pronoun(french, some, person, ['quelqu\'un']).
ty_quantifier_pronoun(french, every, thing, [tout]).
ty_quantifier_pronoun(french, every, person, [tout, le, monde]).
ty_quantifier_pronoun(french, this, thing, [ceci]).
ty_quantifier_pronoun(french, that, thing, [cela]).
%% SUBORDINATE CLAUSES (since 1.65.0): the words of each kind, and where
%% the clause may stand.
%% `si' is `s\'' before `il' and `ils'.
ty_subordinator(french, if, [si]).
ty_subordinator(french, when, [quand]).
ty_subordinator(french, because, [parce, que]).
ty_subordinate_first(french).
ty_before(french, si, [[i, l]], 's\'', joined).

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
%% A noun phrase's adposition phrase stands after it (since 1.83.0).
ty_noun_adposition(french, after).
%% A noun before a noun (since 1.87.0): `vestes noires de cuir'.
ty_noun_modifier(french, after([de])).
%% An adjective's adposition phrase after it (since 1.88.0): `Le chien est
%% grand dans la maison.'
ty_adjective_complement(french, after).
%% An adverb that grades an adjective stands before it (since 1.90.0):
%% `très grand'; `very' is one.
ty_adjective_adverb(french, before).
ty_adposition(french, of, [de]).
ty_adposition(french, in, [dans]).
ty_adposition(french, on, [sur]).
ty_adposition(french, with, [avec]).
ty_adposition(french, to, ['à']).
ty_adposition(french, from, [de]).
ty_adverb(french, quickly, vite).
ty_adverb(french, slowly, lentement).
ty_adverb(french, today, 'aujourd\'hui').
ty_adverb(french, here, ici).
ty_adverb(french, very, 'très').

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

%% The copula's future and perfect (`sera', `a été', `n'a pas été').
ty_copula(french, any, future, sg, pos, [sera]).
ty_copula(french, any, future, pl, pos, [seront]).
ty_copula(french, any, future, sg(1), pos, [serai]).
ty_copula(french, any, future, sg(2), pos, [seras]).
ty_copula(french, any, future, pl(1), pos, [serons]).
ty_copula(french, any, future, pl(2), pos, [serez]).
ty_copula(french, any, future, sg, neg, [ne, sera, pas]).
ty_copula(french, any, future, pl, neg, [ne, seront, pas]).
ty_copula(french, any, future, sg(1), neg, [ne, serai, pas]).
ty_copula(french, any, future, sg(2), neg, [ne, seras, pas]).
ty_copula(french, any, future, pl(1), neg, [ne, serons, pas]).
ty_copula(french, any, future, pl(2), neg, [ne, serez, pas]).
ty_copula(french, any, perfect, sg, pos, [a, 'été']).
ty_copula(french, any, perfect, pl, pos, [ont, 'été']).
ty_copula(french, any, perfect, sg(1), pos, [ai, 'été']).
ty_copula(french, any, perfect, sg(2), pos, [as, 'été']).
ty_copula(french, any, perfect, pl(1), pos, [avons, 'été']).
ty_copula(french, any, perfect, pl(2), pos, [avez, 'été']).
ty_copula(french, any, perfect, sg, neg, [ne, a, pas, 'été']).
ty_copula(french, any, perfect, pl, neg, [ne, ont, pas, 'été']).
ty_copula(french, any, perfect, sg(1), neg, [ne, ai, pas, 'été']).
ty_copula(french, any, perfect, sg(2), neg, [ne, as, pas, 'été']).
ty_copula(french, any, perfect, pl(1), neg, [ne, avons, pas, 'été']).
ty_copula(french, any, perfect, pl(2), neg, [ne, avez, pas, 'été']).

%% The imperfect and the conditional of each verb (`voyait', `verrait');
%% the pluperfect, `avoir' in the imperfect and the participle, or for the
%% class `être' `être' and the participle that agrees with the subject
%% (`était allée'). The copula's past is its imperfect already (`était'),
%% so its imperfect is written as its past.
ty_verb(french, see, imperfect, sg, pos, [voyait]).
ty_verb(french, see, imperfect, pl, pos, [voyaient]).
ty_verb(french, see, imperfect, sg(1), pos, [voyais]).
ty_verb(french, see, imperfect, sg(2), pos, [voyais]).
ty_verb(french, see, imperfect, pl(1), pos, [voyions]).
ty_verb(french, see, imperfect, pl(2), pos, [voyiez]).
ty_verb(french, sleep, imperfect, sg, pos, [dormait]).
ty_verb(french, sleep, imperfect, pl, pos, [dormaient]).
ty_verb(french, sleep, imperfect, sg(1), pos, [dormais]).
ty_verb(french, sleep, imperfect, sg(2), pos, [dormais]).
ty_verb(french, sleep, imperfect, pl(1), pos, [dormions]).
ty_verb(french, sleep, imperfect, pl(2), pos, [dormiez]).
ty_verb(french, think, imperfect, sg, pos, [pensait]).
ty_verb(french, think, imperfect, pl, pos, [pensaient]).
ty_verb(french, think, imperfect, sg(1), pos, [pensais]).
ty_verb(french, think, imperfect, sg(2), pos, [pensais]).
ty_verb(french, think, imperfect, pl(1), pos, [pensions]).
ty_verb(french, think, imperfect, pl(2), pos, [pensiez]).
ty_verb(french, look, imperfect, sg, pos, [regardait]).
ty_verb(french, look, imperfect, pl, pos, [regardaient]).
ty_verb(french, look, imperfect, sg(1), pos, [regardais]).
ty_verb(french, look, imperfect, sg(2), pos, [regardais]).
ty_verb(french, look, imperfect, pl(1), pos, [regardions]).
ty_verb(french, look, imperfect, pl(2), pos, [regardiez]).
ty_verb(french, go, imperfect, sg, pos, [allait]).
ty_verb(french, go, imperfect, pl, pos, [allaient]).
ty_verb(french, go, imperfect, sg(1), pos, [allais]).
ty_verb(french, go, imperfect, sg(2), pos, [allais]).
ty_verb(french, go, imperfect, pl(1), pos, [allions]).
ty_verb(french, go, imperfect, pl(2), pos, [alliez]).
ty_verb(french, see, conditional, sg, pos, [verrait]).
ty_verb(french, see, conditional, pl, pos, [verraient]).
ty_verb(french, see, conditional, sg(1), pos, [verrais]).
ty_verb(french, see, conditional, sg(2), pos, [verrais]).
ty_verb(french, see, conditional, pl(1), pos, [verrions]).
ty_verb(french, see, conditional, pl(2), pos, [verriez]).
ty_verb(french, sleep, conditional, sg, pos, [dormirait]).
ty_verb(french, sleep, conditional, pl, pos, [dormiraient]).
ty_verb(french, sleep, conditional, sg(1), pos, [dormirais]).
ty_verb(french, sleep, conditional, sg(2), pos, [dormirais]).
ty_verb(french, sleep, conditional, pl(1), pos, [dormirions]).
ty_verb(french, sleep, conditional, pl(2), pos, [dormiriez]).
ty_verb(french, think, conditional, sg, pos, [penserait]).
ty_verb(french, think, conditional, pl, pos, [penseraient]).
ty_verb(french, think, conditional, sg(1), pos, [penserais]).
ty_verb(french, think, conditional, sg(2), pos, [penserais]).
ty_verb(french, think, conditional, pl(1), pos, [penserions]).
ty_verb(french, think, conditional, pl(2), pos, [penseriez]).
ty_verb(french, look, conditional, sg, pos, [regarderait]).
ty_verb(french, look, conditional, pl, pos, [regarderaient]).
ty_verb(french, look, conditional, sg(1), pos, [regarderais]).
ty_verb(french, look, conditional, sg(2), pos, [regarderais]).
ty_verb(french, look, conditional, pl(1), pos, [regarderions]).
ty_verb(french, look, conditional, pl(2), pos, [regarderiez]).
ty_verb(french, go, conditional, sg, pos, [irait]).
ty_verb(french, go, conditional, pl, pos, [iraient]).
ty_verb(french, go, conditional, sg(1), pos, [irais]).
ty_verb(french, go, conditional, sg(2), pos, [irais]).
ty_verb(french, go, conditional, pl(1), pos, [irions]).
ty_verb(french, go, conditional, pl(2), pos, [iriez]).
ty_tense_form(french, pluperfect, sg, pos, [avait, participle]).
ty_tense_form(french, pluperfect, pl, pos, [avaient, participle]).
ty_tense_form(french, pluperfect, sg(1), pos, [avais, participle]).
ty_tense_form(french, pluperfect, sg(2), pos, [avais, participle]).
ty_tense_form(french, pluperfect, pl(1), pos, [avions, participle]).
ty_tense_form(french, pluperfect, pl(2), pos, [aviez, participle]).
ty_class_tense_form(french, 'être', pluperfect, sg, pos, ['était', participle(subject)]).
ty_class_tense_form(french, 'être', pluperfect, pl, pos, ['étaient', participle(subject)]).
ty_class_tense_form(french, 'être', pluperfect, sg(1), pos, ['étais', participle(subject)]).
ty_class_tense_form(french, 'être', pluperfect, sg(2), pos, ['étais', participle(subject)]).
ty_class_tense_form(french, 'être', pluperfect, pl(1), pos, ['étions', participle(subject)]).
ty_class_tense_form(french, 'être', pluperfect, pl(2), pos, ['étiez', participle(subject)]).
ty_tense_like(french, copula, imperfect, past).
ty_copula(french, any, conditional, sg, pos, [serait]).
ty_copula(french, any, conditional, pl, pos, [seraient]).
ty_copula(french, any, conditional, sg(1), pos, [serais]).
ty_copula(french, any, conditional, sg(2), pos, [serais]).
ty_copula(french, any, conditional, pl(1), pos, [serions]).
ty_copula(french, any, conditional, pl(2), pos, [seriez]).
ty_copula(french, any, conditional, sg, neg, [ne, serait, pas]).
ty_copula(french, any, conditional, pl, neg, [ne, seraient, pas]).
ty_copula(french, any, conditional, sg(1), neg, [ne, serais, pas]).
ty_copula(french, any, conditional, sg(2), neg, [ne, serais, pas]).
ty_copula(french, any, conditional, pl(1), neg, [ne, serions, pas]).
ty_copula(french, any, conditional, pl(2), neg, [ne, seriez, pas]).
ty_copula(french, any, pluperfect, sg, pos, [avait, 'été']).
ty_copula(french, any, pluperfect, pl, pos, [avaient, 'été']).
ty_copula(french, any, pluperfect, sg(1), pos, [avais, 'été']).
ty_copula(french, any, pluperfect, sg(2), pos, [avais, 'été']).
ty_copula(french, any, pluperfect, pl(1), pos, [avions, 'été']).
ty_copula(french, any, pluperfect, pl(2), pos, [aviez, 'été']).
ty_copula(french, any, pluperfect, sg, neg, [ne, avait, pas, 'été']).
ty_copula(french, any, pluperfect, pl, neg, [ne, avaient, pas, 'été']).
ty_copula(french, any, pluperfect, sg(1), neg, [ne, avais, pas, 'été']).
ty_copula(french, any, pluperfect, sg(2), neg, [ne, avais, pas, 'été']).
ty_copula(french, any, pluperfect, pl(1), neg, [ne, avions, pas, 'été']).
ty_copula(french, any, pluperfect, pl(2), neg, [ne, aviez, pas, 'été']).

%% `pas de': a negative clause's indefinite object takes `de' (`d'' before
%% a vowel) for its article, and the clause keeps `ne ... pas' (`Le garçon
%% ne voit pas de chien.', `Je ne vois pas d'animaux.'); a predicate keeps
%% its article (`Ce n'est pas un chien.').
ty_negative_article(french, any, any, any, de).
ty_negative_article_roles(french, [o]).
ty_negative_article_keeps(french).

%% The word before the last item of a list: a predicate's adjectives
%% (`small and black'), noun phrases (`the boy and the girl'), clauses.
ty_and(french, [et]).
%% The other conjunctions (since 1.59.0): `or', `but'.
ty_conjunction(french, or, [ou]).
ty_conjunction(french, but, [mais]).

%% March, the month (templates/topics.pl), takes no definite article and
%% `en' for `in' (`en mars').
ty_noun(french, march_month, m, unknown, mars, mars).
ty_bare_topic(french, month).
ty_adposition_topic(french, in, month, [en]).
