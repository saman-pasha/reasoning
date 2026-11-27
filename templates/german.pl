%% templates/german.pl -- the template of German, for
%% library(reasoning/typology). Facts only; typology_load(german) reads it.
%% A hand template: corpus/vocabulary has no German, so there is no
%% templates/german-words.pl.

%% The orders: subject, verb, object, the verb second; in a relative clause
%% the verb last (ty_verb_last/2: `der Hund, den der Junge sieht'). The
%% article, the adjectives, the noun.
ty_order(german, clause, [s, v, o]).
ty_order(german, np, [d, a, n]).
ty_verb_last(german, rel).

%% The nouns, each written with its capital: Meaning, Gender (m, f or n),
%% Animacy, Singular, Plural. `Mädchen' is neuter.
ty_capital_nouns(german).
ty_noun(german, dog, m, animate, 'Hund', 'Hunde').
ty_noun(german, cat, f, animate, 'Katze', 'Katzen').
ty_noun(german, boy, m, person, 'Junge', 'Jungen').
ty_noun(german, girl, n, person, 'Mädchen', 'Mädchen').
ty_noun(german, man, m, person, 'Mann', 'Männer').
ty_noun(german, book, n, inanimate, 'Buch', 'Bücher').
ty_noun(german, mouse, f, animate, 'Maus', 'Mäuse').
ty_noun(german, house, n, inanimate, 'Haus', 'Häuser').
ty_noun(german, animal, n, animate, 'Tier', 'Tiere').

%% THE CASES. ty_case(L, Role, Case): the subject and a copula's predicate
%% are nominative, the object accusative, a possessor genitive;
%% ty_case_after(L, Words, Case): the noun phrase after an adposition, in
%% the case the adposition takes (`mit dem Hund', `an das Mädchen').
ty_case(german, s, nom).
ty_case(german, o, acc).
ty_case(german, p, nom).
ty_case(german, g, gen).
ty_case_after(german, [in], dat).
ty_case_after(german, [auf], dat).
ty_case_after(german, [mit], dat).
ty_case_after(german, [zu], dat).
ty_case_after(german, [von], dat).
ty_case_after(german, [an], acc).

%% A noun's form in a case where it is not the nominative's: -n in the
%% dative plural, -s or -es in the genitive singular of a masculine or a
%% neuter noun, and `Junge' with -n in every case but the nominative.
ty_noun_case(german, dog, dat, pl, 'Hunden').
ty_noun_case(german, dog, gen, sg, 'Hundes').
ty_noun_case(german, boy, acc, sg, 'Jungen').
ty_noun_case(german, boy, dat, sg, 'Jungen').
ty_noun_case(german, boy, gen, sg, 'Jungen').
ty_noun_case(german, girl, gen, sg, 'Mädchens').
ty_noun_case(german, man, dat, pl, 'Männern').
ty_noun_case(german, man, gen, sg, 'Mannes').
ty_noun_case(german, book, dat, pl, 'Büchern').
ty_noun_case(german, book, gen, sg, 'Buches').
ty_noun_case(german, mouse, dat, pl, 'Mäusen').
ty_noun_case(german, house, dat, pl, 'Häusern').
ty_noun_case(german, house, gen, sg, 'Hauses').
ty_noun_case(german, animal, dat, pl, 'Tieren').
ty_noun_case(german, animal, gen, sg, 'Tieres').

%% The articles agree with the noun in gender, number and case; a plural
%% indefinite has none (`Der Junge sieht Hunde.').
ty_article_case(german, def, m, sg, nom, der).
ty_article_case(german, def, m, sg, acc, den).
ty_article_case(german, def, m, sg, dat, dem).
ty_article_case(german, def, m, sg, gen, des).
ty_article_case(german, def, f, sg, nom, die).
ty_article_case(german, def, f, sg, acc, die).
ty_article_case(german, def, f, sg, dat, der).
ty_article_case(german, def, f, sg, gen, der).
ty_article_case(german, def, n, sg, nom, das).
ty_article_case(german, def, n, sg, acc, das).
ty_article_case(german, def, n, sg, dat, dem).
ty_article_case(german, def, n, sg, gen, des).
ty_article_case(german, def, any, pl, nom, die).
ty_article_case(german, def, any, pl, acc, die).
ty_article_case(german, def, any, pl, dat, den).
ty_article_case(german, def, any, pl, gen, der).
ty_article_case(german, indef, m, sg, nom, ein).
ty_article_case(german, indef, m, sg, acc, einen).
ty_article_case(german, indef, m, sg, dat, einem).
ty_article_case(german, indef, m, sg, gen, eines).
ty_article_case(german, indef, f, sg, nom, eine).
ty_article_case(german, indef, f, sg, acc, eine).
ty_article_case(german, indef, f, sg, dat, einer).
ty_article_case(german, indef, f, sg, gen, einer).
ty_article_case(german, indef, n, sg, nom, ein).
ty_article_case(german, indef, n, sg, acc, ein).
ty_article_case(german, indef, n, sg, dat, einem).
ty_article_case(german, indef, n, sg, gen, eines).
%% The article of a question (`Welchen Hund sieht der Junge?').
ty_article_case(german, which, m, sg, nom, welcher).
ty_article_case(german, which, m, sg, acc, welchen).
ty_article_case(german, which, m, sg, dat, welchem).
ty_article_case(german, which, m, sg, gen, welches).
ty_article_case(german, which, f, sg, nom, welche).
ty_article_case(german, which, f, sg, acc, welche).
ty_article_case(german, which, f, sg, dat, welcher).
ty_article_case(german, which, f, sg, gen, welcher).
ty_article_case(german, which, n, sg, nom, welches).
ty_article_case(german, which, n, sg, acc, welches).
ty_article_case(german, which, n, sg, dat, welchem).
ty_article_case(german, which, n, sg, gen, welches).
ty_article_case(german, which, any, pl, nom, welche).
ty_article_case(german, which, any, pl, acc, welche).
ty_article_case(german, which, any, pl, dat, welchen).
ty_article_case(german, which, any, pl, gen, welcher).

%% The adjectives: the word a predicate takes (`Der Hund ist klein.'), to
%% which an adjective before a noun adds an ending of its declension, its
%% case, gender and number (`der kleine Hund', `ein kleiner Hund',
%% `kleine Hunde', `mit dem kleinen Hund'): weak after the definite article
%% and `welch-', mixed after `ein', strong with no article.
ty_adjective(german, big, any, any, 'groß').
ty_adjective(german, small, any, any, klein).
ty_adjective(german, black, any, any, schwarz).
ty_adjective(german, red, any, any, rot).
ty_declension(german, def, weak).
ty_declension(german, which, weak).
ty_declension(german, indef, mixed).
ty_declension(german, none, strong).
%% THE DETERMINERS AND THE QUANTIFIERS (since 1.63.0): each a definiteness
%% of its own with its article's words, and the quantifier pronouns, a
%% quantifier and a kind (qp(Quantifier, Kind) in the IR), singular.
%% `jeder', `alle' and `dieser' decline as `der', the adjective after them
%% weak; after `einige' it is strong. `kein' stays the negation's.
ty_declension(german, every, weak).
ty_declension(german, each, weak).
ty_declension(german, all, weak).
ty_declension(german, this, weak).
ty_declension(german, some, strong).
ty_article_case(german, every, m, sg, nom, jeder).
ty_article_case(german, every, m, sg, acc, jeden).
ty_article_case(german, every, m, sg, dat, jedem).
ty_article_case(german, every, m, sg, gen, jedes).
ty_article_case(german, every, f, sg, nom, jede).
ty_article_case(german, every, f, sg, acc, jede).
ty_article_case(german, every, f, sg, dat, jeder).
ty_article_case(german, every, f, sg, gen, jeder).
ty_article_case(german, every, n, sg, nom, jedes).
ty_article_case(german, every, n, sg, acc, jedes).
ty_article_case(german, every, n, sg, dat, jedem).
ty_article_case(german, every, n, sg, gen, jedes).
ty_article_case(german, each, m, sg, nom, jeder).
ty_article_case(german, each, m, sg, acc, jeden).
ty_article_case(german, each, m, sg, dat, jedem).
ty_article_case(german, each, m, sg, gen, jedes).
ty_article_case(german, each, f, sg, nom, jede).
ty_article_case(german, each, f, sg, acc, jede).
ty_article_case(german, each, f, sg, dat, jeder).
ty_article_case(german, each, f, sg, gen, jeder).
ty_article_case(german, each, n, sg, nom, jedes).
ty_article_case(german, each, n, sg, acc, jedes).
ty_article_case(german, each, n, sg, dat, jedem).
ty_article_case(german, each, n, sg, gen, jedes).
ty_article_case(german, this, m, sg, nom, dieser).
ty_article_case(german, this, m, sg, acc, diesen).
ty_article_case(german, this, m, sg, dat, diesem).
ty_article_case(german, this, m, sg, gen, dieses).
ty_article_case(german, this, f, sg, nom, diese).
ty_article_case(german, this, f, sg, acc, diese).
ty_article_case(german, this, f, sg, dat, dieser).
ty_article_case(german, this, f, sg, gen, dieser).
ty_article_case(german, this, n, sg, nom, dieses).
ty_article_case(german, this, n, sg, acc, dieses).
ty_article_case(german, this, n, sg, dat, diesem).
ty_article_case(german, this, n, sg, gen, dieses).
ty_article_case(german, this, any, pl, nom, diese).
ty_article_case(german, this, any, pl, acc, diese).
ty_article_case(german, this, any, pl, dat, diesen).
ty_article_case(german, this, any, pl, gen, dieser).
ty_article_case(german, all, any, pl, nom, alle).
ty_article_case(german, all, any, pl, acc, alle).
ty_article_case(german, all, any, pl, dat, allen).
ty_article_case(german, all, any, pl, gen, aller).
ty_article_case(german, some, any, pl, nom, einige).
ty_article_case(german, some, any, pl, acc, einige).
ty_article_case(german, some, any, pl, dat, einigen).
ty_article_case(german, some, any, pl, gen, einiger).
ty_quantifier_pronoun(german, some, thing, [etwas]).
ty_quantifier_pronoun(german, some, person, [jemand]).
ty_quantifier_pronoun(german, every, thing, [alles]).
ty_quantifier_pronoun(german, every, person, [jeder]).
ty_quantifier_pronoun(german, no, thing, [nichts]).
ty_quantifier_pronoun(german, no, person, [niemand]).
ty_quantifier_pronoun(german, this, thing, [dies]).
ty_quantifier_pronoun(german, that, thing, [das]).
%% SUBORDINATE CLAUSES (since 1.65.0): the words of each kind, and where
%% the clause may stand.
%% The clause after its main clause alone (a clause first moves the main
%% clause's verb before its subject: not yet), a comma before it, its verb
%% last (ty_verb_last(german, rel)). `wenn' is if and when.
ty_subordinator(german, if, [wenn]).
ty_subordinator(german, when, [wenn]).
ty_subordinator(german, because, [weil]).
ty_subordinate_comma(german).
ty_adjective_ending(german, weak, nom, any, sg, e).
ty_adjective_ending(german, weak, acc, m, sg, en).
ty_adjective_ending(german, weak, acc, f, sg, e).
ty_adjective_ending(german, weak, acc, n, sg, e).
ty_adjective_ending(german, weak, dat, any, sg, en).
ty_adjective_ending(german, weak, gen, any, sg, en).
ty_adjective_ending(german, weak, any, any, pl, en).
ty_adjective_ending(german, mixed, nom, m, sg, er).
ty_adjective_ending(german, mixed, nom, f, sg, e).
ty_adjective_ending(german, mixed, nom, n, sg, es).
ty_adjective_ending(german, mixed, acc, m, sg, en).
ty_adjective_ending(german, mixed, acc, f, sg, e).
ty_adjective_ending(german, mixed, acc, n, sg, es).
ty_adjective_ending(german, mixed, dat, any, sg, en).
ty_adjective_ending(german, mixed, gen, any, sg, en).
ty_adjective_ending(german, mixed, any, any, pl, en).
ty_adjective_ending(german, strong, nom, m, sg, er).
ty_adjective_ending(german, strong, nom, f, sg, e).
ty_adjective_ending(german, strong, nom, n, sg, es).
ty_adjective_ending(german, strong, acc, m, sg, en).
ty_adjective_ending(german, strong, acc, f, sg, e).
ty_adjective_ending(german, strong, acc, n, sg, es).
ty_adjective_ending(german, strong, dat, m, sg, em).
ty_adjective_ending(german, strong, dat, f, sg, er).
ty_adjective_ending(german, strong, dat, n, sg, em).
ty_adjective_ending(german, strong, gen, m, sg, en).
ty_adjective_ending(german, strong, gen, f, sg, er).
ty_adjective_ending(german, strong, gen, n, sg, en).
ty_adjective_ending(german, strong, nom, any, pl, e).
ty_adjective_ending(german, strong, acc, any, pl, e).
ty_adjective_ending(german, strong, dat, any, pl, en).
ty_adjective_ending(german, strong, gen, any, pl, er).

%% The verbs: the positive forms of every person.
ty_verb(german, see, present, sg, pos, [sieht]).
ty_verb(german, see, present, pl, pos, [sehen]).
ty_verb(german, see, present, sg(1), pos, [sehe]).
ty_verb(german, see, present, sg(2), pos, [siehst]).
ty_verb(german, see, present, pl(1), pos, [sehen]).
ty_verb(german, see, present, pl(2), pos, [seht]).
ty_verb(german, see, past, sg, pos, [sah]).
ty_verb(german, see, past, pl, pos, [sahen]).
ty_verb(german, see, past, sg(1), pos, [sah]).
ty_verb(german, see, past, sg(2), pos, [sahst]).
ty_verb(german, see, past, pl(1), pos, [sahen]).
ty_verb(german, see, past, pl(2), pos, [saht]).
ty_verb(german, sleep, present, sg, pos, ['schläft']).
ty_verb(german, sleep, present, pl, pos, [schlafen]).
ty_verb(german, sleep, present, sg(1), pos, [schlafe]).
ty_verb(german, sleep, present, sg(2), pos, ['schläfst']).
ty_verb(german, sleep, present, pl(1), pos, [schlafen]).
ty_verb(german, sleep, present, pl(2), pos, [schlaft]).
ty_verb(german, sleep, past, sg, pos, [schlief]).
ty_verb(german, sleep, past, pl, pos, [schliefen]).
ty_verb(german, sleep, past, sg(1), pos, [schlief]).
ty_verb(german, sleep, past, sg(2), pos, [schliefst]).
ty_verb(german, sleep, past, pl(1), pos, [schliefen]).
ty_verb(german, sleep, past, pl(2), pos, [schlieft]).
ty_verb(german, think, present, sg, pos, [denkt]).
ty_verb(german, think, present, pl, pos, [denken]).
ty_verb(german, think, present, sg(1), pos, [denke]).
ty_verb(german, think, present, sg(2), pos, [denkst]).
ty_verb(german, think, present, pl(1), pos, [denken]).
ty_verb(german, think, present, pl(2), pos, [denkt]).
ty_verb(german, think, past, sg, pos, [dachte]).
ty_verb(german, think, past, pl, pos, [dachten]).
ty_verb(german, think, past, sg(1), pos, [dachte]).
ty_verb(german, think, past, sg(2), pos, [dachtest]).
ty_verb(german, think, past, pl(1), pos, [dachten]).
ty_verb(german, think, past, pl(2), pos, [dachtet]).
%% `versuchen' (since 1.97.0), whose object may be an infinitive.
ty_verb(german, try, present, sg, pos, [versucht]).
ty_verb(german, try, present, pl, pos, [versuchen]).
ty_verb(german, try, present, sg(1), pos, [versuche]).
ty_verb(german, try, present, sg(2), pos, [versuchst]).
ty_verb(german, try, present, pl(1), pos, [versuchen]).
ty_verb(german, try, present, pl(2), pos, [versucht]).
ty_verb(german, try, past, sg, pos, [versuchte]).
ty_verb(german, try, past, pl, pos, [versuchten]).
ty_verb(german, try, past, sg(1), pos, [versuchte]).
ty_verb(german, try, past, sg(2), pos, [versuchtest]).
ty_verb(german, try, past, pl(1), pos, [versuchten]).
ty_verb(german, try, past, pl(2), pos, [versuchtet]).
%% THE INFINITIVE (since 1.97.0): `zu' and the form of the present plural,
%% the verb last as in a subordinate clause (`Der Junge versucht den Hund
%% zu sehen.'); the verbs whose object it may be are English's (WordNet's
%% frame, lexicon/vinf.txt, and the list); one of purpose is `um' and it
%% (`Der Junge schläft um den Hund zu sehen.'). Not `wollen', whose
%% infinitive takes no `zu'.
ty_tense_form(german, infinitive, any, pos, [zu, form(present, pl)]).
ty_verb_list(german, infinitive, vinf).
ty_verb_list(german, infinitive, [have, hope, need, prefer, decide, hate, remember, deserve]).
ty_purpose_mark(german, [um]).
ty_verb(german, look, present, sg, pos, [betrachtet]).
ty_verb(german, look, present, pl, pos, [betrachten]).
ty_verb(german, look, present, sg(1), pos, [betrachte]).
ty_verb(german, look, present, sg(2), pos, [betrachtest]).
ty_verb(german, look, present, pl(1), pos, [betrachten]).
ty_verb(german, look, present, pl(2), pos, [betrachtet]).
ty_verb(german, look, past, sg, pos, [betrachtete]).
ty_verb(german, look, past, pl, pos, [betrachteten]).
ty_verb(german, look, past, sg(1), pos, [betrachtete]).
ty_verb(german, look, past, sg(2), pos, [betrachtetest]).
ty_verb(german, look, past, pl(1), pos, [betrachteten]).
ty_verb(german, look, past, pl(2), pos, [betrachtetet]).

%% The negation is `nicht' at the end of the clause, before the verb's
%% last part (`Der Junge sieht den Hund nicht.', `Der Junge hat den Hund
%% nicht gesehen.', `der Hund, den der Junge nicht sieht'); in a copula
%% clause it stands before the predicate (`Der Hund ist nicht klein.').
ty_negation_place(german, [nicht], end).
ty_copula_negation(german, [nicht], before(p)).
%% The negative article, `kein': a negative clause's indefinite object, or a
%% negative copula clause's indefinite predicate, takes it, and the clause
%% no `nicht' (`Der Junge sieht keinen Hund.', `Der Junge sieht keine
%% Hunde.', `Der Hund ist kein Tier.').
ty_negative_article(german, m, sg, nom, kein).
ty_negative_article(german, m, sg, acc, keinen).
ty_negative_article(german, m, sg, dat, keinem).
ty_negative_article(german, m, sg, gen, keines).
ty_negative_article(german, f, sg, nom, keine).
ty_negative_article(german, f, sg, acc, keine).
ty_negative_article(german, f, sg, dat, keiner).
ty_negative_article(german, f, sg, gen, keiner).
ty_negative_article(german, n, sg, nom, kein).
ty_negative_article(german, n, sg, acc, kein).
ty_negative_article(german, n, sg, dat, keinem).
ty_negative_article(german, n, sg, gen, keines).
ty_negative_article(german, any, pl, nom, keine).
ty_negative_article(german, any, pl, acc, keine).
ty_negative_article(german, any, pl, dat, keinen).
ty_negative_article(german, any, pl, gen, keiner).

%% The future, `werden' and the infinitive (the form of the present
%% plural); the perfect, `haben' and the participle. Their second word is
%% the verb's last part, at the end of the clause (ty_split_place/2: `Der
%% Junge wird den Hund sehen.', `Hat der Junge den Hund gesehen?'), and
%% before the first in a relative clause (`der Hund, den der Junge gesehen
%% hat').
ty_split_place(german, end).
ty_tense_form(german, future, sg, pos, [wird, form(present, pl)]).
ty_tense_form(german, future, pl, pos, [werden, form(present, pl)]).
ty_tense_form(german, future, sg(1), pos, [werde, form(present, pl)]).
ty_tense_form(german, future, sg(2), pos, [wirst, form(present, pl)]).
ty_tense_form(german, future, pl(1), pos, [werden, form(present, pl)]).
ty_tense_form(german, future, pl(2), pos, [werdet, form(present, pl)]).
ty_tense_form(german, perfect, sg, pos, [hat, participle]).
ty_tense_form(german, perfect, pl, pos, [haben, participle]).
ty_tense_form(german, perfect, sg(1), pos, [habe, participle]).
ty_tense_form(german, perfect, sg(2), pos, [hast, participle]).
ty_tense_form(german, perfect, pl(1), pos, [haben, participle]).
ty_tense_form(german, perfect, pl(2), pos, [habt, participle]).
ty_participle(german, see, gesehen).
ty_participle(german, sleep, geschlafen).
ty_participle(german, think, gedacht).
ty_participle(german, look, betrachtet).
ty_participle(german, try, versucht).
%% `gehen', whose perfect takes `sein' (`Der Junge ist gegangen.').
ty_verb(german, go, present, sg, pos, [geht]).
ty_verb(german, go, present, pl, pos, [gehen]).
ty_verb(german, go, present, sg(1), pos, [gehe]).
ty_verb(german, go, present, sg(2), pos, [gehst]).
ty_verb(german, go, present, pl(1), pos, [gehen]).
ty_verb(german, go, present, pl(2), pos, [geht]).
ty_verb(german, go, past, sg, pos, [ging]).
ty_verb(german, go, past, pl, pos, [gingen]).
ty_verb(german, go, past, sg(1), pos, [ging]).
ty_verb(german, go, past, sg(2), pos, [gingst]).
ty_verb(german, go, past, pl(1), pos, [gingen]).
ty_verb(german, go, past, pl(2), pos, [gingt]).
ty_participle(german, go, gegangen).
ty_verb_class(german, go, sein).
ty_class_tense_form(german, sein, perfect, sg, pos, [ist, participle]).
ty_class_tense_form(german, sein, perfect, pl, pos, [sind, participle]).
ty_class_tense_form(german, sein, perfect, sg(1), pos, [bin, participle]).
ty_class_tense_form(german, sein, perfect, sg(2), pos, [bist, participle]).
ty_class_tense_form(german, sein, perfect, pl(1), pos, [sind, participle]).
ty_class_tense_form(german, sein, perfect, pl(2), pos, [seid, participle]).

%% `in dem' is `im', `zu dem' `zum', `zu der' `zur', `von dem' `vom'.
ty_contraction(german, [in, dem], im).
ty_contraction(german, [zu, dem], zum).
ty_contraction(german, [zu, der], zur).
ty_contraction(german, [von, dem], vom).

%% The copula clause: subject, copula, predicate, the copula second (and
%% last in a relative clause: `der Hund, der klein ist').
ty_order(german, copula, [s, c, p]).
ty_copula(german, any, present, sg, pos, [ist]).
ty_copula(german, any, present, pl, pos, [sind]).
ty_copula(german, any, present, sg(1), pos, [bin]).
ty_copula(german, any, present, sg(2), pos, [bist]).
ty_copula(german, any, present, pl(1), pos, [sind]).
ty_copula(german, any, present, pl(2), pos, [seid]).
ty_copula(german, any, past, sg, pos, [war]).
ty_copula(german, any, past, pl, pos, [waren]).
ty_copula(german, any, past, sg(1), pos, [war]).
ty_copula(german, any, past, sg(2), pos, [warst]).
ty_copula(german, any, past, pl(1), pos, [waren]).
ty_copula(german, any, past, pl(2), pos, [wart]).

%% Prepositions; the adjuncts at the clause's end, before the negation.
ty_order(german, pp, [p, x]).
ty_adjunct(german, end).
%% A noun phrase's adposition phrase stands after it (since 1.83.0).
ty_noun_adposition(german, after).
%% A noun before a noun (since 1.87.0): one word, `schwarze Lederjacken'.
ty_noun_modifier(german, compound).
%% An adjective's adposition phrase before it (since 1.88.0): `Der Hund ist
%% im Haus groß.'
ty_adjective_complement(german, before).
%% An adverb that grades an adjective stands before it (since 1.90.0):
%% `sehr groß'; `very' is one.
ty_adjective_adverb(german, before).
%% A noun phrase's adjective with an adposition phrase stands where its
%% adjectives do, the last of them (since 1.91.0): `Ein am Fruchtknoten angewachsener Kelch.'
ty_adjective_phrase_noun(german, with).
ty_adposition(german, of, [von]).
ty_adposition(german, in, [in]).
ty_adposition(german, on, [auf]).
ty_adposition(german, with, [mit]).
ty_adposition(german, to, [zu]).
ty_adposition(german, from, [von]).
%% The passive's agent (since 1.101.0), after of and from: a passive's
%% adjunct of von is its agent (ty_passive//2).
ty_adposition(german, by, [von]).
ty_adverb(german, quickly, schnell).
ty_adverb(german, slowly, langsam).
ty_adverb(german, today, heute).
ty_adverb(german, here, hier).
ty_adverb(german, very, sehr).

%% Questions: the verb before the subject, its last part at the end
%% (`Sieht der Junge den Hund?', `Hat der Junge den Hund gesehen?'); a
%% question word at the front, the verb second (`Wen sieht der Junge?',
%% `Wo schläft der Hund?'). `who' takes its case (ty_wh_case/4: wer, wen,
%% wem).
ty_question(german, yes_no, clause, front(all)).
ty_question(german, yes_no, copula, front(all)).
ty_question(german, wh, clause, front(all)).
ty_question(german, wh, copula, front(all)).
ty_wh(german, front).
ty_wh_word(german, who, [wer]).
ty_wh_word(german, what, [was]).
ty_wh_word(german, where, [wo]).
ty_wh_word(german, when, [wann]).
ty_wh_case(german, who, nom, [wer]).
ty_wh_case(german, who, acc, [wen]).
ty_wh_case(german, who, dat, [wem]).

%% Relative clauses: the head, a comma, the marker, the clause, a comma
%% where the sentence goes on (ty_relative_comma/1: `Der Hund, der schläft,
%% ist klein.'); the marker agrees with the head in gender and number and
%% takes the case of its gap (`der Hund, der schläft', `der Hund, den der
%% Junge sieht').
ty_order(german, rel, [h, m, c]).
ty_relative_comma(german).
ty_relative(german, s, [der], [[m, sg]]).
ty_relative(german, s, [die], [[f, sg], [pl]]).
ty_relative(german, s, [das], [[n, sg]]).
ty_relative(german, o, [den], [[m, sg]]).
ty_relative(german, o, [die], [[f, sg], [pl]]).
ty_relative(german, o, [das], [[n, sg]]).

%% A verb's complement (`Der Junge denkt an das Mädchen.'), its adposition
%% moving with its question word (`An wen denkt der Junge?').
ty_complement(german, think, [an]).
ty_complement_wh(german, moves).

%% A relative clause's gap in an adposition phrase: the adposition moves
%% into the marker with the marker in the adposition's case (`das Haus, in
%% dem der Hund schläft', `das Mädchen, an das der Junge denkt').
ty_gap(german, pp, moves).
ty_relative_pronoun(german, [dem], [[m, sg, dat], [n, sg, dat]]).
ty_relative_pronoun(german, [der], [[f, sg, dat]]).
ty_relative_pronoun(german, [denen], [[pl, dat]]).
ty_relative_pronoun(german, [den], [[m, sg, acc]]).
ty_relative_pronoun(german, [die], [[f, sg, acc], [pl, acc]]).
ty_relative_pronoun(german, [das], [[n, sg, acc]]).

%% The possessor as the gap: the possessive relative pronoun agrees with
%% the head, and the possessed after it takes no article, its adjectives
%% strong (`der Junge, dessen Hund schläft', `die Katze, deren kleinen
%% Hund der Junge sieht', `das Mädchen, in dessen Haus der Hund schläft').
ty_gap(german, poss, moves).
ty_relative_possessive(german, [dessen], [head([m, sg]), head([n, sg])]).
ty_relative_possessive(german, [deren], [head([f, sg]), head([pl])]).

%% The answer to a yes or no question; `doch' contradicts a negative one.
ty_answer(german, yes, [ja]).
ty_answer(german, no, [nein]).
ty_answer(german, contradict, [doch]).

%% A possessor (`der Hund des Jungen'): the possessed, the possessor in
%% the genitive.
ty_possessive(german, [h, p, g], [], keep).

%% Personal pronouns: a subject's (nominative), an object's (accusative)
%% and an adposition's (dative; after an adposition of the accusative the
%% object's: `an ihn'); the polite `Sie', with the third plural's form,
%% always written with its capital.
ty_pronoun(german, s, [ich], [[1, sg]]).
ty_pronoun(german, s, [du], [[2, sg]]).
ty_pronoun(german, s, [er], [[3, sg, m]]).
ty_pronoun(german, s, [sie], [[3, sg, f], [3, pl]]).
ty_pronoun(german, s, [es], [[3, sg, n]]).
ty_pronoun(german, s, [wir], [[1, pl]]).
ty_pronoun(german, s, [ihr], [[2, pl]]).
ty_pronoun(german, s, ['Sie'], [[polite]]).
ty_pronoun(german, o, [mich], [[1, sg]]).
ty_pronoun(german, o, [dich], [[2, sg]]).
ty_pronoun(german, o, [ihn], [[3, sg, m]]).
ty_pronoun(german, o, [sie], [[3, sg, f], [3, pl]]).
ty_pronoun(german, o, [es], [[3, sg, n]]).
ty_pronoun(german, o, [uns], [[1, pl]]).
ty_pronoun(german, o, [euch], [[2, pl]]).
ty_pronoun(german, o, ['Sie'], [[polite]]).
ty_pronoun(german, j, [mir], [[1, sg]]).
ty_pronoun(german, j, [dir], [[2, sg]]).
ty_pronoun(german, j, [ihm], [[3, sg, m], [3, sg, n]]).
ty_pronoun(german, j, [ihr], [[3, sg, f]]).
ty_pronoun(german, j, [uns], [[1, pl]]).
ty_pronoun(german, j, [euch], [[2, pl]]).
ty_pronoun(german, j, [ihnen], [[3, pl]]).
ty_pronoun(german, j, ['Ihnen'], [[polite]]).
ty_polite(german, sg, pl).
ty_polite(german, pl, pl).

%% A pronoun of the text takes the gender of the noun it stands for (a
%% girl is `es', a cat `sie').
ty_pronoun_gender(german, grammatical).

%% The copula's future and perfect, its second word at the end as a
%% verb's (`Der Hund wird klein sein.', `der klein gewesen ist').
ty_copula(german, any, future, sg, pos, [wird, sein]).
ty_copula(german, any, future, pl, pos, [werden, sein]).
ty_copula(german, any, future, sg(1), pos, [werde, sein]).
ty_copula(german, any, future, sg(2), pos, [wirst, sein]).
ty_copula(german, any, future, pl(1), pos, [werden, sein]).
ty_copula(german, any, future, pl(2), pos, [werdet, sein]).
ty_copula(german, any, perfect, sg, pos, [ist, gewesen]).
ty_copula(german, any, perfect, pl, pos, [sind, gewesen]).
ty_copula(german, any, perfect, sg(1), pos, [bin, gewesen]).
ty_copula(german, any, perfect, sg(2), pos, [bist, gewesen]).
ty_copula(german, any, perfect, pl(1), pos, [sind, gewesen]).
ty_copula(german, any, perfect, pl(2), pos, [seid, gewesen]).

%% The imperfect has no form of its own: it is written as the past (`sah',
%% `war'). The conditional, `würde' and the infinitive; the pluperfect,
%% `haben' in the past and the participle, or for the class `sein' `sein'
%% and the participle (`war gegangen'). Their second word is at the end,
%% as the future's and the perfect's.
ty_tense_like(german, any, imperfect, past).
ty_tense_form(german, conditional, sg, pos, ['würde', form(present, pl)]).
ty_tense_form(german, conditional, pl, pos, ['würden', form(present, pl)]).
ty_tense_form(german, conditional, sg(1), pos, ['würde', form(present, pl)]).
ty_tense_form(german, conditional, sg(2), pos, ['würdest', form(present, pl)]).
ty_tense_form(german, conditional, pl(1), pos, ['würden', form(present, pl)]).
ty_tense_form(german, conditional, pl(2), pos, ['würdet', form(present, pl)]).
ty_tense_form(german, pluperfect, sg, pos, [hatte, participle]).
ty_tense_form(german, pluperfect, pl, pos, [hatten, participle]).
ty_tense_form(german, pluperfect, sg(1), pos, [hatte, participle]).
ty_tense_form(german, pluperfect, sg(2), pos, [hattest, participle]).
ty_tense_form(german, pluperfect, pl(1), pos, [hatten, participle]).
ty_tense_form(german, pluperfect, pl(2), pos, [hattet, participle]).
%% THE PASSIVE (since 1.101.0): werden and the participle, which goes to
%% the clause's end as the perfect's does (`Der Hund wurde von dem Jungen
%% gesehen.').
ty_tense_form(german, pass(present), sg, pos, [wird, participle]).
ty_tense_form(german, pass(present), pl, pos, [werden, participle]).
ty_tense_form(german, pass(past), sg, pos, [wurde, participle]).
ty_tense_form(german, pass(past), pl, pos, [wurden, participle]).
%% The perfect passive (since 1.106.0): sein, the participle and `worden',
%% the two last at the clause's end (`Das Mädchen ist vom Jungen gesehen
%% worden.', `das Mädchen, das gesehen worden ist').
ty_tense_form(german, pass(perfect), sg, pos, [ist, participle, worden]).
ty_tense_form(german, pass(perfect), pl, pos, [sind, participle, worden]).
ty_class_tense_form(german, sein, pluperfect, sg, pos, [war, participle]).
ty_class_tense_form(german, sein, pluperfect, pl, pos, [waren, participle]).
ty_class_tense_form(german, sein, pluperfect, sg(1), pos, [war, participle]).
ty_class_tense_form(german, sein, pluperfect, sg(2), pos, [warst, participle]).
ty_class_tense_form(german, sein, pluperfect, pl(1), pos, [waren, participle]).
ty_class_tense_form(german, sein, pluperfect, pl(2), pos, [wart, participle]).
ty_copula(german, any, conditional, sg, pos, ['würde', sein]).
ty_copula(german, any, conditional, pl, pos, ['würden', sein]).
ty_copula(german, any, conditional, sg(1), pos, ['würde', sein]).
ty_copula(german, any, conditional, sg(2), pos, ['würdest', sein]).
ty_copula(german, any, conditional, pl(1), pos, ['würden', sein]).
ty_copula(german, any, conditional, pl(2), pos, ['würdet', sein]).
ty_copula(german, any, pluperfect, sg, pos, [war, gewesen]).
ty_copula(german, any, pluperfect, pl, pos, [waren, gewesen]).
ty_copula(german, any, pluperfect, sg(1), pos, [war, gewesen]).
ty_copula(german, any, pluperfect, sg(2), pos, [warst, gewesen]).
ty_copula(german, any, pluperfect, pl(1), pos, [waren, gewesen]).
ty_copula(german, any, pluperfect, pl(2), pos, [wart, gewesen]).

%% The negative article for a subject too (`Kein Hund schläft.', `Kein
%% Hund ist klein.'): the subject's before the object's (`Kein Junge sieht
%% einen Hund.').
ty_negative_article_roles(german, [s, o, p]).

%% The word before the last item of a list: a predicate's adjectives
%% (`small and black'), noun phrases (`the boy and the girl'), clauses.
ty_and(german, [und]).
%% The other conjunctions (since 1.59.0): `or', `but'.
ty_conjunction(german, or, [oder]).
ty_conjunction(german, but, [aber]).
%% A comma before `aber' between two clauses.
ty_clause_comma(german, but).

%% March, the month, keeps its article (`im März').
ty_noun(german, march_month, m, unknown, 'März', 'Märze').

%% The possessive pronouns: a stem of the possessor's person and number
%% and the ending of the possessed noun's gender, number and case, as
%% `kein' takes them (`mein Hund', `meinen Hund', `mit meinem Hund', `die
%% Katze meines Jungen'); `euer' is `eur' before an ending, and the polite
%% `Ihr' keeps its capital. An adjective after one takes the mixed
%% declension, as after `ein' (`mein kleiner Hund', `mit meinem kleinen
%% Hund').
ty_possessive_pronoun(german, [mein], [[1, sg]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [meine], [[1, sg]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [meinen], [[1, sg]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [meinem], [[1, sg]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [meiner], [[1, sg]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [meines], [[1, sg]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, [dein], [[2, sg]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [deine], [[2, sg]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [deinen], [[2, sg]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [deinem], [[2, sg]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [deiner], [[2, sg]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [deines], [[2, sg]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, [sein], [[3, sg, m], [3, sg, n]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [seine], [[3, sg, m], [3, sg, n]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [seinen], [[3, sg, m], [3, sg, n]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [seinem], [[3, sg, m], [3, sg, n]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [seiner], [[3, sg, m], [3, sg, n]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [seines], [[3, sg, m], [3, sg, n]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, [ihr], [[3, sg, f], [3, pl]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [ihre], [[3, sg, f], [3, pl]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [ihren], [[3, sg, f], [3, pl]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [ihrem], [[3, sg, f], [3, pl]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [ihrer], [[3, sg, f], [3, pl]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [ihres], [[3, sg, f], [3, pl]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, [unser], [[1, pl]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [unsere], [[1, pl]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [unseren], [[1, pl]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [unserem], [[1, pl]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [unserer], [[1, pl]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [unseres], [[1, pl]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, [euer], [[2, pl]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, [eure], [[2, pl]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, [euren], [[2, pl]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, [eurem], [[2, pl]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, [eurer], [[2, pl]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, [eures], [[2, pl]], [[m, sg, gen], [n, sg, gen]]).
ty_possessive_pronoun(german, ['Ihr'], [[polite]], [[m, sg, nom], [n, sg, nom], [n, sg, acc]]).
ty_possessive_pronoun(german, ['Ihre'], [[polite]], [[f, sg, nom], [f, sg, acc], [pl, nom], [pl, acc]]).
ty_possessive_pronoun(german, ['Ihren'], [[polite]], [[m, sg, acc], [pl, dat]]).
ty_possessive_pronoun(german, ['Ihrem'], [[polite]], [[m, sg, dat], [n, sg, dat]]).
ty_possessive_pronoun(german, ['Ihrer'], [[polite]], [[f, sg, dat], [f, sg, gen], [pl, gen]]).
ty_possessive_pronoun(german, ['Ihres'], [[polite]], [[m, sg, gen], [n, sg, gen]]).
ty_contraction(german, [an, das], ans).

%% A statement is read with an adjunct first and the verb before the
%% subject too (`Heute schläft der Hund.'); the adjunct is written at the
%% end (`Der Hund schläft heute.').
ty_adjunct_front(german, v2).

%% A statement is read with its object first too, where its first word
%% cannot begin a subject (`Den Hund sieht der Junge.', `Keinen Hund sieht
%% der Junge.', `Ihn sieht das Mädchen.'); `Die Katze sieht das Mädchen.'
%% is the cat that sees. The object is written after the verb.
ty_object_front(german, v2).
