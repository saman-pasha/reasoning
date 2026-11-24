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
                    someone, something, somebody, everyone, everything, everybody, nothing, nobody,
                    anyone, anything, anybody,
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

%% THE VERBS: the classes of the conjugation first, then the verbs. A class
%% is one fact, ty_conjugation(english, Class, Parts): each part --
%% present(sg), present(pl), past(sg), past(pl), participle -- and its rule:
%% base (the base itself), endings From-To on the base (the longest From
%% that ends it), or another part (its form). The negatives are the rule
%% below. typology_import(english) puts a verb in the first class whose
%% ty_class_when/4 pattern its base fits, else in the first class
%% (templates/english-verbs.pl).
ty_conjugation(english, regular, [present(sg)-[''-s, s-ses, x-xes, z-zes, ch-ches, sh-shes, o-oes,
                                               y-ies, ay-ays, ey-eys, oy-oys, uy-uys],
                                  present(pl)-base,
                                  past(sg)-[''-ed, e-ed, y-ied, ay-ayed, ey-eyed, oy-oyed, uy-uyed],
                                  past(pl)-past(sg),
                                  participle-past(sg)]).
ty_conjugation(english, double, [present(sg)-[''-s],
                                 present(pl)-base,
                                 past(sg)-[b-bbed, d-dded, g-gged, l-lled, m-mmed, n-nned, p-pped,
                                           r-rred, t-tted],
                                 past(pl)-past(sg),
                                 participle-past(sg)]).
ty_conjugation(english, ck, [present(sg)-[''-s],
                             present(pl)-base,
                             past(sg)-[c-cked],
                             past(pl)-past(sg),
                             participle-past(sg)]).
%% A verb of one syllable, one vowel before a last consonant that doubles,
%% is of the class double (`stop', `plan'); one of more syllables only by
%% its row below (`admit').
ty_letters(english, consonant, [b, c, d, f, g, h, j, k, l, m, n, p, q, r, s, t, v, w, x, y, z]).
ty_letters(english, doubling, [b, d, g, l, m, n, p, r, t]).
ty_class_when(english, verb, double, [star(consonant), vowel, doubling]).

%% The verbs of a class the import cannot tell from the base.
ty_verb_in(english, admit, admit, double).
ty_verb_in(english, commit, commit, double).
ty_verb_in(english, permit, permit, double).
ty_verb_in(english, omit, omit, double).
ty_verb_in(english, submit, submit, double).
ty_verb_in(english, emit, emit, double).
ty_verb_in(english, transmit, transmit, double).
ty_verb_in(english, remit, remit, double).
ty_verb_in(english, refer, refer, double).
ty_verb_in(english, prefer, prefer, double).
ty_verb_in(english, defer, defer, double).
ty_verb_in(english, confer, confer, double).
ty_verb_in(english, infer, infer, double).
ty_verb_in(english, occur, occur, double).
ty_verb_in(english, recur, recur, double).
ty_verb_in(english, incur, incur, double).
ty_verb_in(english, deter, deter, double).
ty_verb_in(english, control, control, double).
ty_verb_in(english, patrol, patrol, double).
ty_verb_in(english, compel, compel, double).
ty_verb_in(english, expel, expel, double).
ty_verb_in(english, propel, propel, double).
ty_verb_in(english, repel, repel, double).
ty_verb_in(english, excel, excel, double).
ty_verb_in(english, rebel, rebel, double).
ty_verb_in(english, regret, regret, double).
ty_verb_in(english, abhor, abhor, double).
ty_verb_in(english, acquit, acquit, double).
ty_verb_in(english, equip, equip, double).
ty_verb_in(english, outwit, outwit, double).
ty_verb_in(english, befit, befit, double).
ty_verb_in(english, abet, abet, double).
ty_verb_in(english, allot, allot, double).
ty_verb_in(english, annul, annul, double).
ty_verb_in(english, debug, debug, double).
ty_verb_in(english, dispel, dispel, double).
ty_verb_in(english, inter, inter, double).
ty_verb_in(english, kidnap, kidnap, double).
ty_verb_in(english, overlap, overlap, double).
ty_verb_in(english, overstep, overstep, double).
ty_verb_in(english, transfer, transfer, double).
ty_verb_in(english, unplug, unplug, double).
ty_verb_in(english, unfit, unfit, double).
ty_verb_in(english, format, format, double).
ty_verb_in(english, program, program, double).
ty_verb_in(english, embed, embed, double).
ty_verb_in(english, handicap, handicap, double).
ty_verb_in(english, rebut, rebut, double).
ty_verb_in(english, recap, recap, double).
ty_verb_in(english, outfit, outfit, double).
ty_verb_in(english, outstrip, outstrip, double).
ty_verb_in(english, sidestep, sidestep, double).
ty_verb_in(english, unzip, unzip, double).
ty_verb_in(english, quip, quip, double).
ty_verb_in(english, panic, panic, ck).
ty_verb_in(english, picnic, picnic, ck).
ty_verb_in(english, mimic, mimic, ck).
ty_verb_in(english, traffic, traffic, ck).
ty_verb_in(english, frolic, frolic, ck).

%% The irregular verbs: one fact each, ty_irregular_verb(english, Meaning,
%% Base, Class, Parts), the parts its class does not make (`saw', `seen');
%% the class makes the rest (`sees'). `be' is the copula's, and `do' the
%% auxiliary's: as a main verb it waits for the verbs' objects, without
%% which `Yes, he does.' reads as `he does' with no object too. The forms
%% are American: `traveled', `burned', `learned'.
ty_irregular_verb(english, arise, arise, regular, [past(sg)-arose, participle-arisen]).
ty_irregular_verb(english, awake, awake, regular, [past(sg)-awoke, participle-awoken]).
ty_irregular_verb(english, bear, bear, regular, [past(sg)-bore, participle-borne]).
ty_irregular_verb(english, beat, beat, regular, [past(sg)-beat, participle-beaten]).
ty_irregular_verb(english, become, become, regular, [past(sg)-became, participle-become]).
ty_irregular_verb(english, befall, befall, regular, [past(sg)-befell, participle-befallen]).
ty_irregular_verb(english, beget, beget, regular, [past(sg)-begot, participle-begotten]).
ty_irregular_verb(english, begin, begin, regular, [past(sg)-began, participle-begun]).
ty_irregular_verb(english, behold, behold, regular, [past(sg)-beheld, participle-beheld]).
ty_irregular_verb(english, bend, bend, regular, [past(sg)-bent, participle-bent]).
ty_irregular_verb(english, beseech, beseech, regular, [past(sg)-besought, participle-besought]).
ty_irregular_verb(english, bet, bet, regular, [past(sg)-bet, participle-bet]).
ty_irregular_verb(english, bid, bid, regular, [past(sg)-bid, participle-bid]).
ty_irregular_verb(english, bind, bind, regular, [past(sg)-bound, participle-bound]).
ty_irregular_verb(english, bite, bite, regular, [past(sg)-bit, participle-bitten]).
ty_irregular_verb(english, bleed, bleed, regular, [past(sg)-bled, participle-bled]).
ty_irregular_verb(english, blow, blow, regular, [past(sg)-blew, participle-blown]).
ty_irregular_verb(english, break, break, regular, [past(sg)-broke, participle-broken]).
ty_irregular_verb(english, breed, breed, regular, [past(sg)-bred, participle-bred]).
ty_irregular_verb(english, bring, bring, regular, [past(sg)-brought, participle-brought]).
ty_irregular_verb(english, broadcast, broadcast, regular, [past(sg)-broadcast, participle-broadcast]).
ty_irregular_verb(english, build, build, regular, [past(sg)-built, participle-built]).
ty_irregular_verb(english, burst, burst, regular, [past(sg)-burst, participle-burst]).
ty_irregular_verb(english, buy, buy, regular, [past(sg)-bought, participle-bought]).
ty_irregular_verb(english, cast, cast, regular, [past(sg)-cast, participle-cast]).
ty_irregular_verb(english, catch, catch, regular, [past(sg)-caught, participle-caught]).
ty_irregular_verb(english, choose, choose, regular, [past(sg)-chose, participle-chosen]).
ty_irregular_verb(english, cling, cling, regular, [past(sg)-clung, participle-clung]).
ty_irregular_verb(english, come, come, regular, [past(sg)-came, participle-come]).
ty_irregular_verb(english, cost, cost, regular, [past(sg)-cost, participle-cost]).
ty_irregular_verb(english, creep, creep, regular, [past(sg)-crept, participle-crept]).
ty_irregular_verb(english, cut, cut, regular, [past(sg)-cut, participle-cut]).
ty_irregular_verb(english, deal, deal, regular, [past(sg)-dealt, participle-dealt]).
ty_irregular_verb(english, dig, dig, regular, [past(sg)-dug, participle-dug]).
ty_irregular_verb(english, draw, draw, regular, [past(sg)-drew, participle-drawn]).
ty_irregular_verb(english, drink, drink, regular, [past(sg)-drank, participle-drunk]).
ty_irregular_verb(english, drive, drive, regular, [past(sg)-drove, participle-driven]).
ty_irregular_verb(english, dwell, dwell, regular, [past(sg)-dwelt, participle-dwelt]).
ty_irregular_verb(english, eat, eat, regular, [past(sg)-ate, participle-eaten]).
ty_irregular_verb(english, fall, fall, regular, [past(sg)-fell, participle-fallen]).
ty_irregular_verb(english, feed, feed, regular, [past(sg)-fed, participle-fed]).
ty_irregular_verb(english, feel, feel, regular, [past(sg)-felt, participle-felt]).
ty_irregular_verb(english, fight, fight, regular, [past(sg)-fought, participle-fought]).
ty_irregular_verb(english, find, find, regular, [past(sg)-found, participle-found]).
ty_irregular_verb(english, flee, flee, regular, [past(sg)-fled, participle-fled]).
ty_irregular_verb(english, fling, fling, regular, [past(sg)-flung, participle-flung]).
ty_irregular_verb(english, fly, fly, regular, [past(sg)-flew, participle-flown]).
ty_irregular_verb(english, forbid, forbid, regular, [past(sg)-forbade, participle-forbidden]).
ty_irregular_verb(english, forecast, forecast, regular, [past(sg)-forecast, participle-forecast]).
ty_irregular_verb(english, forego, forego, regular, [past(sg)-forewent, participle-foregone]).
ty_irregular_verb(english, foresee, foresee, regular, [past(sg)-foresaw, participle-foreseen]).
ty_irregular_verb(english, foretell, foretell, regular, [past(sg)-foretold, participle-foretold]).
ty_irregular_verb(english, forget, forget, regular, [past(sg)-forgot, participle-forgotten]).
ty_irregular_verb(english, forgive, forgive, regular, [past(sg)-forgave, participle-forgiven]).
ty_irregular_verb(english, forgo, forgo, regular, [past(sg)-forwent, participle-forgone]).
ty_irregular_verb(english, forsake, forsake, regular, [past(sg)-forsook, participle-forsaken]).
ty_irregular_verb(english, freeze, freeze, regular, [past(sg)-froze, participle-frozen]).
ty_irregular_verb(english, get, get, regular, [past(sg)-got, participle-gotten]).
ty_irregular_verb(english, give, give, regular, [past(sg)-gave, participle-given]).
ty_irregular_verb(english, go, go, regular, [past(sg)-went, participle-gone]).
ty_irregular_verb(english, grind, grind, regular, [past(sg)-ground, participle-ground]).
ty_irregular_verb(english, grow, grow, regular, [past(sg)-grew, participle-grown]).
ty_irregular_verb(english, hang, hang, regular, [past(sg)-hung, participle-hung]).
ty_irregular_verb(english, have, have, regular, [present(sg)-has, past(sg)-had, participle-had]).
ty_irregular_verb(english, hear, hear, regular, [past(sg)-heard, participle-heard]).
ty_irregular_verb(english, hew, hew, regular, [past(sg)-hewed, participle-hewn]).
ty_irregular_verb(english, hide, hide, regular, [past(sg)-hid, participle-hidden]).
ty_irregular_verb(english, hit, hit, regular, [past(sg)-hit, participle-hit]).
ty_irregular_verb(english, hold, hold, regular, [past(sg)-held, participle-held]).
ty_irregular_verb(english, hurt, hurt, regular, [past(sg)-hurt, participle-hurt]).
ty_irregular_verb(english, input, input, regular, [past(sg)-input, participle-input]).
ty_irregular_verb(english, interweave, interweave, regular, [past(sg)-interwove, participle-interwoven]).
ty_irregular_verb(english, keep, keep, regular, [past(sg)-kept, participle-kept]).
ty_irregular_verb(english, kneel, kneel, regular, [past(sg)-knelt, participle-knelt]).
ty_irregular_verb(english, knit, knit, regular, [past(sg)-knit, participle-knit]).
ty_irregular_verb(english, know, know, regular, [past(sg)-knew, participle-known]).
ty_irregular_verb(english, lay, lay, regular, [past(sg)-laid, participle-laid]).
ty_irregular_verb(english, lead, lead, regular, [past(sg)-led, participle-led]).
ty_irregular_verb(english, leave, leave, regular, [past(sg)-left, participle-left]).
ty_irregular_verb(english, lend, lend, regular, [past(sg)-lent, participle-lent]).
ty_irregular_verb(english, let, let, regular, [past(sg)-let, participle-let]).
ty_irregular_verb(english, lie, lie, regular, [past(sg)-lay, participle-lain]).
ty_irregular_verb(english, light, light, regular, [past(sg)-lit, participle-lit]).
ty_irregular_verb(english, lose, lose, regular, [past(sg)-lost, participle-lost]).
ty_irregular_verb(english, make, make, regular, [past(sg)-made, participle-made]).
ty_irregular_verb(english, mean, mean, regular, [past(sg)-meant, participle-meant]).
ty_irregular_verb(english, meet, meet, regular, [past(sg)-met, participle-met]).
ty_irregular_verb(english, mishear, mishear, regular, [past(sg)-misheard, participle-misheard]).
ty_irregular_verb(english, mislay, mislay, regular, [past(sg)-mislaid, participle-mislaid]).
ty_irregular_verb(english, mislead, mislead, regular, [past(sg)-misled, participle-misled]).
ty_irregular_verb(english, misread, misread, regular, [past(sg)-misread, participle-misread]).
ty_irregular_verb(english, mistake, mistake, regular, [past(sg)-mistook, participle-mistaken]).
ty_irregular_verb(english, misunderstand, misunderstand, regular, [past(sg)-misunderstood, participle-misunderstood]).
ty_irregular_verb(english, mow, mow, regular, [past(sg)-mowed, participle-mown]).
ty_irregular_verb(english, offset, offset, regular, [past(sg)-offset, participle-offset]).
ty_irregular_verb(english, outbid, outbid, regular, [past(sg)-outbid, participle-outbid]).
ty_irregular_verb(english, outdo, outdo, regular, [past(sg)-outdid, participle-outdone]).
ty_irregular_verb(english, outgrow, outgrow, regular, [past(sg)-outgrew, participle-outgrown]).
ty_irregular_verb(english, output, output, regular, [past(sg)-output, participle-output]).
ty_irregular_verb(english, outrun, outrun, regular, [past(sg)-outran, participle-outrun]).
ty_irregular_verb(english, outsell, outsell, regular, [past(sg)-outsold, participle-outsold]).
ty_irregular_verb(english, overcome, overcome, regular, [past(sg)-overcame, participle-overcome]).
ty_irregular_verb(english, overdo, overdo, regular, [past(sg)-overdid, participle-overdone]).
ty_irregular_verb(english, overeat, overeat, regular, [past(sg)-overate, participle-overeaten]).
ty_irregular_verb(english, overhear, overhear, regular, [past(sg)-overheard, participle-overheard]).
ty_irregular_verb(english, overpay, overpay, regular, [past(sg)-overpaid, participle-overpaid]).
ty_irregular_verb(english, override, override, regular, [past(sg)-overrode, participle-overridden]).
ty_irregular_verb(english, overrun, overrun, regular, [past(sg)-overran, participle-overrun]).
ty_irregular_verb(english, oversee, oversee, regular, [past(sg)-oversaw, participle-overseen]).
ty_irregular_verb(english, oversleep, oversleep, regular, [past(sg)-overslept, participle-overslept]).
ty_irregular_verb(english, overtake, overtake, regular, [past(sg)-overtook, participle-overtaken]).
ty_irregular_verb(english, overthrow, overthrow, regular, [past(sg)-overthrew, participle-overthrown]).
ty_irregular_verb(english, partake, partake, regular, [past(sg)-partook, participle-partaken]).
ty_irregular_verb(english, pay, pay, regular, [past(sg)-paid, participle-paid]).
ty_irregular_verb(english, put, put, regular, [past(sg)-put, participle-put]).
ty_irregular_verb(english, quit, quit, regular, [past(sg)-quit, participle-quit]).
ty_irregular_verb(english, read, read, regular, [past(sg)-read, participle-read]).
ty_irregular_verb(english, rebuild, rebuild, regular, [past(sg)-rebuilt, participle-rebuilt]).
ty_irregular_verb(english, recast, recast, regular, [past(sg)-recast, participle-recast]).
ty_irregular_verb(english, redo, redo, regular, [past(sg)-redid, participle-redone]).
ty_irregular_verb(english, remake, remake, regular, [past(sg)-remade, participle-remade]).
ty_irregular_verb(english, repay, repay, regular, [past(sg)-repaid, participle-repaid]).
ty_irregular_verb(english, reread, reread, regular, [past(sg)-reread, participle-reread]).
ty_irregular_verb(english, rerun, rerun, regular, [past(sg)-reran, participle-rerun]).
ty_irregular_verb(english, resell, resell, regular, [past(sg)-resold, participle-resold]).
ty_irregular_verb(english, reset, reset, regular, [past(sg)-reset, participle-reset]).
ty_irregular_verb(english, retell, retell, regular, [past(sg)-retold, participle-retold]).
ty_irregular_verb(english, rethink, rethink, regular, [past(sg)-rethought, participle-rethought]).
ty_irregular_verb(english, rewind, rewind, regular, [past(sg)-rewound, participle-rewound]).
ty_irregular_verb(english, rewrite, rewrite, regular, [past(sg)-rewrote, participle-rewritten]).
ty_irregular_verb(english, rid, rid, regular, [past(sg)-rid, participle-rid]).
ty_irregular_verb(english, ride, ride, regular, [past(sg)-rode, participle-ridden]).
ty_irregular_verb(english, ring, ring, regular, [past(sg)-rang, participle-rung]).
ty_irregular_verb(english, rise, rise, regular, [past(sg)-rose, participle-risen]).
ty_irregular_verb(english, run, run, regular, [past(sg)-ran, participle-run]).
ty_irregular_verb(english, say, say, regular, [past(sg)-said, participle-said]).
ty_irregular_verb(english, see, see, regular, [past(sg)-saw, participle-seen]).
ty_irregular_verb(english, seek, seek, regular, [past(sg)-sought, participle-sought]).
ty_irregular_verb(english, sell, sell, regular, [past(sg)-sold, participle-sold]).
ty_irregular_verb(english, send, send, regular, [past(sg)-sent, participle-sent]).
ty_irregular_verb(english, set, set, regular, [past(sg)-set, participle-set]).
ty_irregular_verb(english, sew, sew, regular, [past(sg)-sewed, participle-sewn]).
ty_irregular_verb(english, shake, shake, regular, [past(sg)-shook, participle-shaken]).
ty_irregular_verb(english, shear, shear, regular, [past(sg)-sheared, participle-shorn]).
ty_irregular_verb(english, shed, shed, regular, [past(sg)-shed, participle-shed]).
ty_irregular_verb(english, shine, shine, regular, [past(sg)-shone, participle-shone]).
ty_irregular_verb(english, shoe, shoe, regular, [past(sg)-shod, participle-shod]).
ty_irregular_verb(english, shoot, shoot, regular, [past(sg)-shot, participle-shot]).
ty_irregular_verb(english, show, show, regular, [past(sg)-showed, participle-shown]).
ty_irregular_verb(english, shrink, shrink, regular, [past(sg)-shrank, participle-shrunk]).
ty_irregular_verb(english, shut, shut, regular, [past(sg)-shut, participle-shut]).
ty_irregular_verb(english, sing, sing, regular, [past(sg)-sang, participle-sung]).
ty_irregular_verb(english, sink, sink, regular, [past(sg)-sank, participle-sunk]).
ty_irregular_verb(english, sit, sit, regular, [past(sg)-sat, participle-sat]).
ty_irregular_verb(english, slay, slay, regular, [past(sg)-slew, participle-slain]).
ty_irregular_verb(english, sleep, sleep, regular, [past(sg)-slept, participle-slept]).
ty_irregular_verb(english, slide, slide, regular, [past(sg)-slid, participle-slid]).
ty_irregular_verb(english, sling, sling, regular, [past(sg)-slung, participle-slung]).
ty_irregular_verb(english, slink, slink, regular, [past(sg)-slunk, participle-slunk]).
ty_irregular_verb(english, slit, slit, regular, [past(sg)-slit, participle-slit]).
ty_irregular_verb(english, smite, smite, regular, [past(sg)-smote, participle-smitten]).
ty_irregular_verb(english, sow, sow, regular, [past(sg)-sowed, participle-sown]).
ty_irregular_verb(english, speak, speak, regular, [past(sg)-spoke, participle-spoken]).
ty_irregular_verb(english, speed, speed, regular, [past(sg)-sped, participle-sped]).
ty_irregular_verb(english, spend, spend, regular, [past(sg)-spent, participle-spent]).
ty_irregular_verb(english, spin, spin, regular, [past(sg)-spun, participle-spun]).
ty_irregular_verb(english, spit, spit, regular, [past(sg)-spat, participle-spat]).
ty_irregular_verb(english, split, split, regular, [past(sg)-split, participle-split]).
ty_irregular_verb(english, spread, spread, regular, [past(sg)-spread, participle-spread]).
ty_irregular_verb(english, spring, spring, regular, [past(sg)-sprang, participle-sprung]).
ty_irregular_verb(english, stand, stand, regular, [past(sg)-stood, participle-stood]).
ty_irregular_verb(english, steal, steal, regular, [past(sg)-stole, participle-stolen]).
ty_irregular_verb(english, stick, stick, regular, [past(sg)-stuck, participle-stuck]).
ty_irregular_verb(english, sting, sting, regular, [past(sg)-stung, participle-stung]).
ty_irregular_verb(english, stink, stink, regular, [past(sg)-stank, participle-stunk]).
ty_irregular_verb(english, strew, strew, regular, [past(sg)-strewed, participle-strewn]).
ty_irregular_verb(english, stride, stride, regular, [past(sg)-strode, participle-stridden]).
ty_irregular_verb(english, strike, strike, regular, [past(sg)-struck, participle-struck]).
ty_irregular_verb(english, string, string, regular, [past(sg)-strung, participle-strung]).
ty_irregular_verb(english, strive, strive, regular, [past(sg)-strove, participle-striven]).
ty_irregular_verb(english, swear, swear, regular, [past(sg)-swore, participle-sworn]).
ty_irregular_verb(english, sweep, sweep, regular, [past(sg)-swept, participle-swept]).
ty_irregular_verb(english, swell, swell, regular, [past(sg)-swelled, participle-swollen]).
ty_irregular_verb(english, swim, swim, regular, [past(sg)-swam, participle-swum]).
ty_irregular_verb(english, swing, swing, regular, [past(sg)-swung, participle-swung]).
ty_irregular_verb(english, take, take, regular, [past(sg)-took, participle-taken]).
ty_irregular_verb(english, teach, teach, regular, [past(sg)-taught, participle-taught]).
ty_irregular_verb(english, tear, tear, regular, [past(sg)-tore, participle-torn]).
ty_irregular_verb(english, tell, tell, regular, [past(sg)-told, participle-told]).
ty_irregular_verb(english, think, think, regular, [past(sg)-thought, participle-thought]).
ty_irregular_verb(english, throw, throw, regular, [past(sg)-threw, participle-thrown]).
ty_irregular_verb(english, thrust, thrust, regular, [past(sg)-thrust, participle-thrust]).
ty_irregular_verb(english, tread, tread, regular, [past(sg)-trod, participle-trodden]).
ty_irregular_verb(english, undercut, undercut, regular, [past(sg)-undercut, participle-undercut]).
ty_irregular_verb(english, undergo, undergo, regular, [past(sg)-underwent, participle-undergone]).
ty_irregular_verb(english, underlie, underlie, regular, [past(sg)-underlay, participle-underlain]).
ty_irregular_verb(english, underpay, underpay, regular, [past(sg)-underpaid, participle-underpaid]).
ty_irregular_verb(english, understand, understand, regular, [past(sg)-understood, participle-understood]).
ty_irregular_verb(english, undertake, undertake, regular, [past(sg)-undertook, participle-undertaken]).
ty_irregular_verb(english, underwrite, underwrite, regular, [past(sg)-underwrote, participle-underwritten]).
ty_irregular_verb(english, undo, undo, regular, [past(sg)-undid, participle-undone]).
ty_irregular_verb(english, unwind, unwind, regular, [past(sg)-unwound, participle-unwound]).
ty_irregular_verb(english, uphold, uphold, regular, [past(sg)-upheld, participle-upheld]).
ty_irregular_verb(english, upset, upset, regular, [past(sg)-upset, participle-upset]).
ty_irregular_verb(english, wake, wake, regular, [past(sg)-woke, participle-woken]).
ty_irregular_verb(english, wear, wear, regular, [past(sg)-wore, participle-worn]).
ty_irregular_verb(english, weave, weave, regular, [past(sg)-wove, participle-woven]).
ty_irregular_verb(english, wed, wed, regular, [past(sg)-wed, participle-wed]).
ty_irregular_verb(english, weep, weep, regular, [past(sg)-wept, participle-wept]).
ty_irregular_verb(english, wet, wet, regular, [past(sg)-wet, participle-wet]).
ty_irregular_verb(english, win, win, regular, [past(sg)-won, participle-won]).
ty_irregular_verb(english, wind, wind, regular, [past(sg)-wound, participle-wound]).
ty_irregular_verb(english, withdraw, withdraw, regular, [past(sg)-withdrew, participle-withdrawn]).
ty_irregular_verb(english, withhold, withhold, regular, [past(sg)-withheld, participle-withheld]).
ty_irregular_verb(english, withstand, withstand, regular, [past(sg)-withstood, participle-withstood]).
ty_irregular_verb(english, wring, wring, regular, [past(sg)-wrung, participle-wrung]).
ty_irregular_verb(english, write, write, regular, [past(sg)-wrote, participle-written]).

%% The articles. A plural indefinite has none: `dogs'.
ty_article(english, def, any, any, the).
ty_article(english, indef, any, sg, a).
%% The article of a question (`Which dog does the boy see?').
ty_article(english, which, any, any, which).
%% THE DETERMINERS AND THE QUANTIFIERS (since 1.63.0): each a definiteness
%% of its own with its article's words, and the quantifier pronouns, a
%% quantifier and a kind (qp(Quantifier, Kind) in the IR), singular.
ty_article(english, every, any, sg, every).
ty_article(english, each, any, sg, each).
ty_article(english, all, any, pl, all).
ty_article(english, some, any, any, some).
ty_article(english, no, any, any, no).
ty_article(english, any, any, any, any).
ty_article(english, this, any, sg, this).
ty_article(english, this, any, pl, these).
ty_article(english, that, any, sg, that).
ty_article(english, that, any, pl, those).
ty_quantifier_pronoun(english, some, thing, [something]).
ty_quantifier_pronoun(english, some, person, [someone]).
ty_quantifier_pronoun(english, some, person, [somebody]).
ty_quantifier_pronoun(english, every, thing, [everything]).
ty_quantifier_pronoun(english, every, person, [everyone]).
ty_quantifier_pronoun(english, every, person, [everybody]).
ty_quantifier_pronoun(english, no, thing, [nothing]).
ty_quantifier_pronoun(english, no, person, [nobody]).
ty_quantifier_pronoun(english, no, person, [no, one]).
ty_quantifier_pronoun(english, any, thing, [anything]).
ty_quantifier_pronoun(english, any, person, [anyone]).
ty_quantifier_pronoun(english, any, person, [anybody]).
ty_quantifier_pronoun(english, this, thing, [this]).
ty_quantifier_pronoun(english, that, thing, [that]).
%% SUBORDINATE CLAUSES (since 1.65.0): the words of each kind, and where
%% the clause may stand.
ty_subordinator(english, if, [if]).
ty_subordinator(english, when, [when]).
ty_subordinator(english, because, [because]).
ty_subordinate_first(english).

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
ty_participle_like(english, past, sg).

%% A command (since 1.82.0): the imperative is the present's plural form,
%% `do not' before it, with no subject (`Construct a proof.', `Do not
%% open the door.'). Of the plural, as the person rule gives `you': of any
%% number the row fits the second person's own key, and a present `you see'
%% inside a command was lost (ty_person_form/5 takes a key's own rows first).
ty_tense_form(english, imperative, pl, pos, [form(present, pl)]).
ty_tense_form(english, imperative, pl, neg, [do, not, form(present, pl)]).

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
%% A noun phrase's adposition phrase stands after it (since 1.83.0).
ty_noun_adposition(english, after).
ty_adposition(english, in, [in]).
ty_adposition(english, on, [on]).
ty_adposition(english, with, [with]).
ty_adposition(english, to, [to]).
ty_adposition(english, from, [from]).
%% The other prepositions (since 1.84.0): each its word, `towards' a second
%% word of `toward', two words for `out of' and `instead of'. No row for `up',
%% `down' and `off': in lexicon/prose.txt they are the particles of verbs
%% (`Fold up the newspaper.'), and as prepositions they made its object an
%% adjunct; nor for `past', the name of a tense in Cocolog.
ty_adposition(english, for, [for]).
ty_adposition(english, at, [at]).
ty_adposition(english, into, [into]).
ty_adposition(english, by, [by]).
ty_adposition(english, over, [over]).
ty_adposition(english, against, [against]).
ty_adposition(english, onto, [onto]).
ty_adposition(english, between, [between]).
ty_adposition(english, about, [about]).
ty_adposition(english, under, [under]).
ty_adposition(english, without, [without]).
ty_adposition(english, through, [through]).
ty_adposition(english, after, [after]).
ty_adposition(english, before, [before]).
ty_adposition(english, around, [around]).
ty_adposition(english, during, [during]).
ty_adposition(english, toward, [toward]).
ty_adposition(english, toward, [towards]).
ty_adposition(english, among, [among]).
ty_adposition(english, above, [above]).
ty_adposition(english, across, [across]).
ty_adposition(english, behind, [behind]).
ty_adposition(english, along, [along]).
ty_adposition(english, below, [below]).
ty_adposition(english, beneath, [beneath]).
ty_adposition(english, beside, [beside]).
ty_adposition(english, beyond, [beyond]).
ty_adposition(english, inside, [inside]).
ty_adposition(english, near, [near]).
ty_adposition(english, outside, [outside]).
ty_adposition(english, throughout, [throughout]).
ty_adposition(english, upon, [upon]).
ty_adposition(english, within, [within]).
ty_adposition(english, until, [until]).
ty_adposition(english, despite, [despite]).
ty_adposition(english, except, [except]).
ty_adposition(english, out_of, [out, of]).
ty_adposition(english, instead_of, [instead, of]).
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

%% The word before the last item of a list: a predicate's adjectives
%% (`small and black'), noun phrases (`the boy and the girl'), clauses.
ty_and(english, [and]).
%% The other conjunctions (since 1.59.0): `or', `but'.
ty_conjunction(english, or, [or]).
ty_conjunction(english, but, [but]).
%% A comma may stand before the last item's `and' (`red, blue, and yellow'),
%% read and not written.
ty_serial_comma(english).

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
