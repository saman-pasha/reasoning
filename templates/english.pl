%% templates/english.pl -- the template of English, for
%% library(reasoning/typology). Facts only; typology_load(english) reads it.

%% The orders: subject, verb, object; the article, the adjectives, the noun.
ty_order(english, clause, [s, v, o]).
ty_order(english, np, [d, a, n]).

%% THE NOUNS: the classes of the plural first, then the nouns. A class is
%% one fact, its endings From-To: the longest From that ends the singular
%% gives the plural. The first class is the one typology_import(english)
%% puts a noun in (templates/english-nouns.pl). A noun of a class is
%% ty_noun_in(english, Meaning, Gender, Animacy, Singular, Class): Gender
%% none (English has none), Animacy person, animate, inanimate or unknown
%% (a person is animate too). An irregular noun is one ty_noun/6 fact, its
%% plural in it.
ty_noun_class(english, regular, [''-s, s-ses, x-xes, z-zes, ch-ches, sh-shes,
                                 y-ies, ay-ays, ey-eys, oy-oys, uy-uys]).
ty_noun_class(english, ves, [f-ves, fe-ves]).
ty_noun_class(english, same, [''-'']).
ty_noun_class(english, oes, [o-oes]).
ty_noun_class(english, is_es, [is-es]).
ty_noun_class(english, us_i, [us-i]).
ty_noun_class(english, um_a, [um-a]).
ty_noun_class(english, on_a, [on-a]).
ty_noun_class(english, ices, [ix-ices, ex-ices]).

ty_noun_in(english, dog, none, animate, dog, regular).
ty_noun_in(english, cat, none, animate, cat, regular).
%% March, the month: a meaning of its own (templates/topics.pl).
ty_noun_in(english, march_month, none, unknown, 'March', regular).
ty_noun_in(english, boy, none, person, boy, regular).
ty_noun_in(english, girl, none, person, girl, regular).
ty_noun_in(english, book, none, inanimate, book, regular).
ty_noun_in(english, wife, none, person, wife, ves).
ty_noun_in(english, knife, none, inanimate, knife, ves).
ty_noun_in(english, life, none, inanimate, life, ves).
ty_noun_in(english, leaf, none, inanimate, leaf, ves).
ty_noun_in(english, wolf, none, animate, wolf, ves).
ty_noun_in(english, half, none, inanimate, half, ves).
ty_noun_in(english, shelf, none, inanimate, shelf, ves).
ty_noun_in(english, thief, none, person, thief, ves).
ty_noun_in(english, loaf, none, inanimate, loaf, ves).
ty_noun_in(english, calf, none, animate, calf, ves).
ty_noun_in(english, self, none, inanimate, self, ves).
ty_noun_in(english, sheaf, none, inanimate, sheaf, ves).
ty_noun_in(english, sheep, none, animate, sheep, same).
ty_noun_in(english, fish, none, animate, fish, same).
ty_noun_in(english, deer, none, animate, deer, same).
ty_noun_in(english, moose, none, animate, moose, same).
ty_noun_in(english, salmon, none, animate, salmon, same).
ty_noun_in(english, trout, none, animate, trout, same).
ty_noun_in(english, swine, none, animate, swine, same).
ty_noun_in(english, bison, none, animate, bison, same).
ty_noun_in(english, species, none, inanimate, species, same).
ty_noun_in(english, series, none, inanimate, series, same).
ty_noun_in(english, aircraft, none, inanimate, aircraft, same).
ty_noun_in(english, offspring, none, unknown, offspring, same).
ty_noun_in(english, potato, none, inanimate, potato, oes).
ty_noun_in(english, tomato, none, inanimate, tomato, oes).
ty_noun_in(english, hero, none, person, hero, oes).
ty_noun_in(english, echo, none, inanimate, echo, oes).
ty_noun_in(english, veto, none, inanimate, veto, oes).
ty_noun_in(english, torpedo, none, inanimate, torpedo, oes).
ty_noun_in(english, embargo, none, inanimate, embargo, oes).
ty_noun_in(english, crisis, none, inanimate, crisis, is_es).
ty_noun_in(english, thesis, none, inanimate, thesis, is_es).
ty_noun_in(english, analysis, none, inanimate, analysis, is_es).
ty_noun_in(english, basis, none, inanimate, basis, is_es).
ty_noun_in(english, hypothesis, none, inanimate, hypothesis, is_es).
ty_noun_in(english, diagnosis, none, inanimate, diagnosis, is_es).
ty_noun_in(english, axis, none, inanimate, axis, is_es).
ty_noun_in(english, synopsis, none, inanimate, synopsis, is_es).
ty_noun_in(english, parenthesis, none, inanimate, parenthesis, is_es).
ty_noun_in(english, emphasis, none, inanimate, emphasis, is_es).
ty_noun_in(english, oasis, none, inanimate, oasis, is_es).
ty_noun_in(english, ellipsis, none, inanimate, ellipsis, is_es).
ty_noun_in(english, prognosis, none, inanimate, prognosis, is_es).
ty_noun_in(english, cactus, none, inanimate, cactus, us_i).
ty_noun_in(english, fungus, none, inanimate, fungus, us_i).
ty_noun_in(english, nucleus, none, inanimate, nucleus, us_i).
ty_noun_in(english, radius, none, inanimate, radius, us_i).
ty_noun_in(english, stimulus, none, inanimate, stimulus, us_i).
ty_noun_in(english, alumnus, none, person, alumnus, us_i).
ty_noun_in(english, locus, none, inanimate, locus, us_i).
ty_noun_in(english, curriculum, none, inanimate, curriculum, um_a).
ty_noun_in(english, bacterium, none, animate, bacterium, um_a).
ty_noun_in(english, stratum, none, inanimate, stratum, um_a).
ty_noun_in(english, memorandum, none, inanimate, memorandum, um_a).
ty_noun_in(english, erratum, none, inanimate, erratum, um_a).
ty_noun_in(english, phenomenon, none, inanimate, phenomenon, on_a).
ty_noun_in(english, criterion, none, inanimate, criterion, on_a).
ty_noun_in(english, matrix, none, inanimate, matrix, ices).
ty_noun_in(english, vertex, none, inanimate, vertex, ices).
ty_noun_in(english, appendix, none, inanimate, appendix, ices).
ty_noun_in(english, vortex, none, inanimate, vortex, ices).

%% The irregular nouns: one fact each, the plural in it.
ty_noun(english, mouse, none, animate, mouse, mice).
ty_noun(english, louse, none, animate, louse, lice).
ty_noun(english, man, none, person, man, men).
ty_noun(english, woman, none, person, woman, women).
ty_noun(english, child, none, person, child, children).
ty_noun(english, person, none, person, person, people).
ty_noun(english, foot, none, inanimate, foot, feet).
ty_noun(english, tooth, none, inanimate, tooth, teeth).
ty_noun(english, goose, none, animate, goose, geese).
ty_noun(english, ox, none, animate, ox, oxen).

%% The words of grammar, which typology_import(english) never takes from
%% lexicon/ as a noun, a verb, an adjective or an adverb: each is the
%% grammar's, or waits for its grammar (TYPOLOGY-PLAN.md, STATUS.md).
ty_closed(english, [a, an, the, this, that, these, those, some, any, no, none, every, each, all, both,
                    either, neither, many, much, more, most, few, fewer, less, least, several, such,
                    own, other, another, and, or, but, nor, yet, so, if, then, than, as, because,
                    although, though, while, whereas, unless, until, till, since, when, whenever,
                    where, wherever, why, how, what, whatever, who, whoever, whom, whose, which,
                    whichever, there, here, i, me, my, mine, myself, you, your, yours, yourself,
                    yourselves, he, him, his, himself, she, her, hers, herself, it, its, itself, we,
                    us, our, ours, ourselves, they, them, their, theirs, themselves, one, two, three,
                    four, five, six, seven, eight, nine, ten, eleven, twelve, twenty, thirty, forty,
                    fifty, hundred, thousand, million, billion, not, yes, to, of, in, on, at, by,
                    for, with, from, into, onto, upon, over, under, up, down, out, off, about,
                    above, across, after, against, along, among, amongst, around, before, behind,
                    below, beneath, beside, besides, between, beyond, during, except, inside, near,
                    outside, through, throughout, toward, towards, underneath, unlike, via, within,
                    without, be, am, is, are, was, were, been, being, will, would, shall, should,
                    can, could, may, might, must, ought, do, does, did, have, has, had, very, too,
                    also, just, only, even, ever, never, always, often, still, already, again,
                    almost, quite, rather, perhaps]).

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

%% The future and the perfect: words before another form, for every verb
%% (`will see', `will not see', `has seen', `have not seen'; `I have
%% seen' by the persons' rule below). The participle is a row, else the
%% past (`walked').
ty_tense_form(english, future, any, pos, [will, form(present, pl)]).
ty_tense_form(english, future, any, neg, [will, not, form(present, pl)]).
ty_tense_form(english, perfect, sg, pos, [has, participle]).
ty_tense_form(english, perfect, pl, pos, [have, participle]).
ty_tense_form(english, perfect, sg, neg, [has, not, participle]).
ty_tense_form(english, perfect, pl, neg, [have, not, participle]).
ty_participle(english, see, seen).
ty_participle(english, sleep, slept).
ty_participle_like(english, past, sg).
%% The participles that are not the past (`spoken', `gone', `written').
ty_participle(english, begin, begun).
ty_participle(english, break, broken).
ty_participle(english, choose, chosen).
ty_participle(english, come, come).
ty_participle(english, do, done).
ty_participle(english, draw, drawn).
ty_participle(english, drink, drunk).
ty_participle(english, drive, driven).
ty_participle(english, eat, eaten).
ty_participle(english, fall, fallen).
ty_participle(english, fly, flown).
ty_participle(english, forget, forgotten).
ty_participle(english, forgive, forgiven).
ty_participle(english, freeze, frozen).
ty_participle(english, give, given).
ty_participle(english, go, gone).
ty_participle(english, grow, grown).
ty_participle(english, hide, hidden).
ty_participle(english, know, known).
ty_participle(english, ride, ridden).
ty_participle(english, ring, rung).
ty_participle(english, rise, risen).
ty_participle(english, run, run).
ty_participle(english, shake, shaken).
ty_participle(english, show, shown).
ty_participle(english, sing, sung).
ty_participle(english, sink, sunk).
ty_participle(english, speak, spoken).
ty_participle(english, steal, stolen).
ty_participle(english, swim, swum).
ty_participle(english, take, taken).
ty_participle(english, tear, torn).
ty_participle(english, throw, thrown).
ty_participle(english, wake, woken).
ty_participle(english, wear, worn).
ty_participle(english, write, written).
ty_participle(english, become, become).
ty_participle(english, bite, bitten).
ty_participle(english, blow, blown).
ty_participle(english, beat, beaten).
ty_participle(english, forbid, forbidden).
ty_participle(english, mistake, mistaken).
ty_participle(english, withdraw, withdrawn).
ty_participle(english, undertake, undertaken).
ty_participle(english, overcome, overcome).
ty_participle(english, lie, lain).

%% The endings typology_import(english) makes a verb's past with, where the
%% vocabularies state none: the longest ending that fits wins.
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

%% A relative clause's gap in an adposition phrase: the adposition stays
%% (`the house that the dog sleeps in', `the girl that the boy thinks
%% about'), written; or it moves into the marker with `whom' or `which'
%% (`the house in which the dog sleeps'), read.
ty_gap(english, pp, stays).
ty_gap(english, pp, moves).
ty_relative_pronoun(english, [whom], [[animate]]).
ty_relative_pronoun(english, [which], [[]]).

%% The answer to a yes or no question (`Yes.', `No, the boy does not see
%% the dog.'): `yes' for a positive answer, after a negative question too.
ty_answer(english, yes, [yes]).
ty_answer(english, no, [no]).

%% A possessor (`the boy's dog'): the possessor, then the possessed with no
%% article; the possessor's last word takes `'s', or `'' after s (`the
%% boys' dog'). `whose' moves with the possessed into the marker (`the boy
%% whose dog sleeps').
ty_possessive(english, [g, p, h], [], drop).
%% `of' where the 's cannot stand: a possessor with a relative clause (`the
%% dog of the boy that sleeps').
ty_possessive(english, [h, p, g], [of], keep).
ty_linked(english, n, h, '', '\'s').
ty_linked(english, n, h, 's', 's\'').
ty_gap(english, poss, moves).
ty_relative_possessive(english, [whose], [[]]).

%% A possessive pronoun (`his dog'), by the possessor's person, number and
%% kind: `my', `your' (one or several), `his' a man's, `her' a woman's,
%% `its' a thing's, `our', `their'.
ty_possessive_pronoun(english, [my], [[1, sg]], [[]]).
ty_possessive_pronoun(english, [your], [[2], [polite]], [[]]).
ty_possessive_pronoun(english, [his], [[3, sg, m]], [[]]).
ty_possessive_pronoun(english, [her], [[3, sg, f]], [[]]).
ty_possessive_pronoun(english, [its], [[3, sg, n]], [[]]).
ty_possessive_pronoun(english, [our], [[1, pl]], [[]]).
ty_possessive_pronoun(english, [their], [[3, pl]], [[]]).

%% Personal pronouns (`he sees her'): a subject's, and an object's, which an
%% adposition takes too (`with him'); `I' is written with its capital. The
%% verb of every person but the third singular is the plural's (`I see',
%% `you do not see', `do we see'); the copula of `I' is `am' and `was'.
ty_pronoun(english, s, [i], [[1, sg]]).
ty_pronoun(english, s, [you], [[2], [polite]]).
ty_pronoun(english, s, [he], [[3, sg, m]]).
ty_pronoun(english, s, [she], [[3, sg, f]]).
ty_pronoun(english, s, [it], [[3, sg, n]]).
ty_pronoun(english, s, [we], [[1, pl]]).
ty_pronoun(english, s, [they], [[3, pl]]).
ty_pronoun(english, o, [me], [[1, sg]]).
ty_pronoun(english, o, [you], [[2], [polite]]).
ty_pronoun(english, o, [him], [[3, sg, m]]).
ty_pronoun(english, o, [her], [[3, sg, f]]).
ty_pronoun(english, o, [it], [[3, sg, n]]).
ty_pronoun(english, o, [us], [[1, pl]]).
ty_pronoun(english, o, [them], [[3, pl]]).
ty_capital(english, i, 'I').
ty_verb_person(english, any, sg(1), pl, '', '').
ty_verb_person(english, any, sg(2), pl, '', '').
ty_verb_person(english, any, pl(1), pl, '', '').
ty_verb_person(english, any, pl(2), pl, '', '').
%% The polite `you' is `you', its verb the plural's (`you see').
ty_polite(english, sg, pl).
ty_polite(english, pl, pl).
ty_copula(english, any, present, sg(1), pos, [am]).
ty_copula(english, any, present, sg(1), neg, [am, not]).
ty_copula(english, any, past, sg(1), pos, [was]).
ty_copula(english, any, past, sg(1), neg, [was, not]).

%% The short answer that repeats the clause (`Yes, he does.', `No, I am
%% not.'): the yes or no word, the subject and the auxiliary of its tense
%% and person, or the copula.
ty_answer_echo(english, aux, keep).

%% The copula's future and perfect (`will be', `has been'); the first and
%% second persons take the plural's.
ty_copula(english, any, future, sg, pos, [will, be]).
ty_copula(english, any, future, sg, neg, [will, not, be]).
ty_copula(english, any, future, pl, pos, [will, be]).
ty_copula(english, any, future, pl, neg, [will, not, be]).
ty_copula(english, any, perfect, sg, pos, [has, been]).
ty_copula(english, any, perfect, pl, pos, [have, been]).
ty_copula(english, any, perfect, sg, neg, [has, not, been]).
ty_copula(english, any, perfect, pl, neg, [have, not, been]).

%% The imperfect has no form of its own: it is written as the past
%% (ty_tense_like/4: Spanish `veía' is `saw', `era' `was'). The
%% conditional and the pluperfect are words before another form, for
%% every verb and person (`would see', `had seen'), and the copula's
%% (`would be', `had been').
ty_tense_like(english, any, imperfect, past).
ty_tense_form(english, conditional, any, pos, [would, form(present, pl)]).
ty_tense_form(english, conditional, any, neg, [would, not, form(present, pl)]).
ty_tense_form(english, pluperfect, any, pos, [had, participle]).
ty_tense_form(english, pluperfect, any, neg, [had, not, participle]).
ty_copula(english, any, conditional, sg, pos, [would, be]).
ty_copula(english, any, conditional, sg, neg, [would, not, be]).
ty_copula(english, any, conditional, pl, pos, [would, be]).
ty_copula(english, any, conditional, pl, neg, [would, not, be]).
ty_copula(english, any, pluperfect, sg, pos, [had, been]).
ty_copula(english, any, pluperfect, sg, neg, [had, not, been]).
ty_copula(english, any, pluperfect, pl, pos, [had, been]).
ty_copula(english, any, pluperfect, pl, neg, [had, not, been]).

%% The word before the last of a predicate's adjectives (`small and black').
ty_and(english, [and]).

%% A month takes no definite article (`in March'), and is written with its
%% capital.
ty_bare_topic(english, month).
ty_capital(english, january, 'January').
ty_capital(english, february, 'February').
ty_capital(english, april, 'April').
ty_capital(english, may, 'May').
ty_capital(english, june, 'June').
ty_capital(english, july, 'July').
ty_capital(english, august, 'August').
ty_capital(english, september, 'September').
ty_capital(english, october, 'October').
ty_capital(english, november, 'November').
ty_capital(english, december, 'December').
