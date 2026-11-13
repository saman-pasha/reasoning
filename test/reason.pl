%% library(reasoning/reason) -- a paragraph in, predicates out: every sentence shape
%% the header promises, pinned; the four decisions, pinned; and the one
%% claim that matters, that what comes out ASSERTS and then PROVES.
%%
%%     cocolog -s test/reason.pl        from this repository's root
%%
%% One process for the lot. Nothing here needs a server or a build flag:
%% the library is clauses over a DCG, so this case runs everywhere.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).

main :-
    tokens, facts, copula, negation, rules, relative, mentions, lexicon, naming,
    round_trip, refusals, places, state, questions, quantities, explains, topics, prose, declares, refused, truth, errors,
    version,
    checks_done.

%% ---- the tokeniser -----------------------------------------------------

tokens :-
    section('tokens'),
    reason_tokens('Hello, World. Alice_1 x9!', T1),
    check('word(Lower, Case), comma, stop; digits and _ stay in a word', T1,
          [word(hello, upper), ',', word(world, upper), '.', word(alice_1, upper), word(x9, lower), '.']),
    reason_tokens('a? b! c.', T2),
    check('? and ! are stops too', T2, [word(a, lower), '.', word(b, lower), '.', word(c, lower), '.']),
    reason_tokens("codes work", T3),
    check('a code list is text', T3, [word(codes, lower), word(work, lower)]),
    reason_tokens('(semi;colons) -- dashes', T4),
    check('other punctuation is dropped', T4, [word(semi, lower), word(colons, lower), word(dashes, lower)]),
    reason_tokens('', T5),
    check('empty text, no tokens', T5, []),
    reason_tokens('Nadia pays 500 euros.', T6),
    check('digits are a num token', T6, [word(nadia, upper), word(pays, lower), num(500), word(euros, lower), '.']),
    reason_tokens('5.5% of 1,000', T7),
    check('a decimal kept, a percent sign the word, a thousands comma passed over', T7,
          [num(5.5), word(percent, lower), word(of, lower), num(1000)]),
    reason_tokens('Él come. ÁNGEL', T8),
    check('a capital in the Latin-1 block is a capital, and goes lower like any other', T8,
          [word('él', upper), word(come, lower), '.', word('ángel', upper)]).

%% ---- a proper subject and a verb ----------------------------------------

facts :-
    section('facts'),
    reason_sentence('Alice owns a red car.', F1),
    check('indefinite object: an individual, its noun, its adjective', F1,
          [car(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice owns a big red car.', F2),
    check('every word before the noun is an adjective', F2,
          [car(car_1), big(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice likes Bob.', F3),
    check('a proper object is its constant', F3, [like(alice, bob)]),
    reason_sentence('Alice sleeps.', F4),
    check('no object: a unary claim', F4, [sleep(alice)]),
    reason_sentence('Alice may access the server.', F5),
    check('a modal joins its verb; `the N'' is the class atom', F5, [may_access(alice, server)]),
    reason_sentence('Alice has a badge.', F6),
    check('`has'' is have, irregular', F6, [badge(badge_1), have(alice, badge_1)]),
    reason_sentence('Alice watches Bob.', F7),
    check('-es comes off after ch', F7, [watch(alice, bob)]),
    reason_sentence('Alice passes Bob.', F8),
    check('-es comes off after ss', F8, [pass(alice, bob)]),
    reason_sentence('Alice uses Bob.', F8b),
    check('but `uses'' is use+s, not us+es', F8b, [use(alice, bob)]),
    reason_sentence('Alice closes Bob.', F8c),
    F8cw =.. [close, alice, bob],                      % built, not written: cocolint's X2 reads `close(' as the stream builtin
    check('and `closes'' is close', F8c, [F8cw]),
    reason_sentence('Alice bathes Bob.', F8d),
    check('and `bathes'' is bathe: a single h is not sh or ch', F8d, [bathe(alice, bob)]),
    reason_sentence('Alice fixes Bob.', F8e),
    check('-es comes off after x', F8e, [fix(alice, bob)]),
    findall(T, reason_sentence('Alice owns a red car.', T), Rs),
    length(Rs, NR),
    check('the grammar is deterministic: one reading', NR, 1).

%% ---- the copula ---------------------------------------------------------

copula :-
    section('copula'),
    reason_sentence('Alice is happy.', C1),        check('is ADJ',        C1, [happy(alice)]),
    reason_sentence('Alice is a person.', C2),     check('is a NOUN',     C2, [person(alice)]),
    reason_sentence('Alice is an employee.', C3),  check('is an NOUN',    C3, [employee(alice)]),
    reason_sentence('Alice is not happy.', C4),    check('is not ADJ',    C4, [neg(happy(alice))]),
    reason_sentence('Alice is not a robot.', C5),  check('is not a NOUN', C5, [neg(robot(alice))]).

%% ---- negation: neg/1, and the class atom ----------------------------------

negation :-
    section('negation'),
    reason_sentence('Bob does not own a car.', N1),
    check('does not V a N: neg/1 over the CLASS, no car_1', N1, [neg(own(bob, car))]),
    reason_sentence('Bob does not sleep.', N2),
    check('does not V: unary', N2, [neg(sleep(bob))]),
    reason_sentence('Bob does not like Alice.', N3),
    check('does not V Proper', N3, [neg(like(bob, alice))]),
    reason_sentence('Bob does not have a badge.', N4),
    check('the negative names the SAME predicate as the positive', N4, [neg(have(bob, badge))]).

%% ---- every: a rule --------------------------------------------------------

rules :-
    section('rules'),
    reason_sentence('Every employee is a person.', [R1]),
    R1 = (H1 :- B1), H1 = person(X1), B1 = employee(Y1),
    yes_no(X1 == Y1, Same1),
    check('one variable through head and body', Same1, yes),
    yes_no(var(X1), Var1),
    check('and it is a VARIABLE, not employee_1', Var1, yes),
    reason_sentence('Every employee has a badge.', [R2]),
    R2 = (have(X2, O2) :- employee(Y2)),
    yes_no(X2 == Y2, Same2), check('rule over a verb', Same2, yes),
    check('an indefinite object in a rule is the class atom', O2, badge),
    reason_sentence('Every employee may access the server.', [R3]),
    R3 = (may_access(X3, O3) :- employee(Y3)),
    yes_no(X3 == Y3, Same3), check('modal in a rule', Same3, yes),
    check('the server', O3, server),
    reason_sentence('All employees are people.', [R4]),
    R4 = (H4 :- B4), functor(H4, HN4, 1), functor(B4, BN4, 1),
    check('`all'' and `are''; nouns are taken as written, plural included', HN4-BN4, people-employees),
    reason_sentence('Every employee is happy.', [R5]),
    R5 = (happy(X5) :- employee(Y5)),
    yes_no(X5 == Y5, Same5), check('rule over an adjective', Same5, yes).

%% ---- that is [not] ADJ: a condition ----------------------------------------

relative :-
    section('relative clause'),
    reason_sentence('Every employee that is authorized may access the server.', [L1]),
    L1 = (may_access(X1, server) :- employee(Y1), authorized(Z1)),
    yes_no((X1 == Y1, Y1 == Z1), S1),
    check('`that is ADJ'' is a second body goal on the same variable', S1, yes),
    reason_sentence('Every employee that is not suspended may access the server.', [L2]),
    L2 = (may_access(X2, server) :- employee(Y2), \+ suspended(Z2)),
    yes_no((X2 == Y2, Y2 == Z2), S2),
    check('`that is not ADJ'' is \\+ in the body, same variable', S2, yes),
    reason_sentence('Every person that is happy sleeps.', [L3]),
    L3 = (sleep(X3) :- person(Y3), happy(Z3)),
    yes_no((X3 == Y3, Y3 == Z3), S3),
    check('a relative clause before an intransitive verb', S3, yes).

%% ---- a word in quotation marks is mentioned ------------------------------------

mentions :-
    section('mentioned words'),
    reason_tokens('The noun "casa" means "house".', T1),
    check('a word between quotation marks is quoted(Word)', T1,
          [word(the, upper), word(noun, lower), quoted(casa), word(means, lower), quoted(house), '.']),
    reason_tokens('“pequeño” es', T2),
    check('the typographic pair opens and closes one; a UTF-8 word is one word', T2, [quoted('pequeño'), word(es, lower)]),
    reason_sentence('"casa" means "house".', M1),
    check('a quoted subject and a quoted object stand for themselves', M1, [mean(casa, house)]),
    reason_sentence('The noun "casa" means "house".', M2),
    check('`the noun "casa"'': the class is a fact about the word, first', M2, [noun(casa), mean(casa, house)]),
    reason_sentence('The feminine article "la" means "the".', M3),
    check('and its adjectives; `"the"'' is a word, not the determiner', M3, [article(la), feminine(la), mean(la, the)]),
    reason_sentence('"casa" ends in "a".', M4),
    check('a preposition and a quoted word after a bare verb join the verb', M4, [end_in(casa, a)]),
    yes_no(reason_sentence('Alice sleeps in Rome.', _), M5),
    check('a PLACE after a bare verb is still refused', M5, no),
    reason_sentence('Every noun that ends in "a" is feminine.', [R6]),
    R6 = (feminine(X6) :- noun(Y6), end_in(Z6, a)),
    yes_no((X6 == Y6, Y6 == Z6), S6),
    check('a verb in the relative clause: one condition, same variable', S6, yes),
    reason_sentence('Every noun that does not end in "a" is masculine.', [R7]),
    R7 = (masculine(X7) :- noun(Y7), \+ end_in(Z7, a)),
    yes_no((X7 == Y7, Y7 == Z7), S7),
    check('`that does not VERB'' is \\+ in the body', S7, yes),
    reason_sentence('Every employee that owns a car may park.', [R8]),
    R8 = (may_park(X8) :- employee(Y8), own(Z8, car)),
    yes_no((X8 == Y8, Y8 == Z8), S8),
    check('an object in the relative clause is the class atom', S8, yes),
    reason_sentence('Every person that is a baker sells the bread.', [R9]),
    R9 = (sell(X9, bread) :- person(Y9), baker(Z9)),
    yes_no((X9 == Y9, Y9 == Z9), S9),
    check('`that is a NOUN'' is a condition too', S9, yes),
    reason_question('Is "mesa" feminine?', Q10),
    check('a quoted word in a question', Q10, question(feminine(mesa))),
    reason_question('What does "perro" mean?', Q11),
    Q11 = question(V11, mean(perro, W11)),
    yes_no(V11 == W11, S11),
    check('what does it mean: the variable is the meaning', S11, yes),
    yes_no(( end_in(casa, a), \+ end_in(casa, o), end_with(casa, sa), begin_with(casa, ca), start_with(casa, casa) ), H12),
    check('the four helpers a rule over words may use', H12, yes),
    reason_refused('"casa" and "mesa".', F13),
    check('a refused sentence keeps its quotation marks', F13, '"casa" and "mesa"'),
    reason_learn('The noun "mesa" means "table". The noun "perro" means "dog". Every noun that ends in "a" is feminine. Every noun that does not end in "a" is masculine.'),
    reason_explanation(feminine(mesa), X14),
    check('the explanation writes the word in its quotation marks and the helper as it is', X14,
          '"mesa" is feminine because "mesa" is a noun and "mesa" ends in "a".'),
    reason_explanation(masculine(perro), X15),
    check('a helper that fails is `does not'', not `nothing shows''', X15,
          '"perro" is masculine because "perro" is a noun and "perro" does not end in "a".'),
    reason_sentence('"casa" ends in a vowel.', M16),
    check('a determined noun after a bare verb''s preposition is its class atom', M16, [end_in(casa, vowel)]),
    reason_sentence('Omar keeps the tractor in the barn.', M17),
    check('a definite phrase after an object is a place', M17, [keep_in(omar, tractor, barn)]),
    yes_no(reason_sentence('Omar keeps the tractor in the big barn.', _), M18),
    check('with an adjective it is refused, not read with the adjective dropped', M18, no),
    reason_sentence('"los" is the plural of "el".', M19),
    check('`is the NOUN of X'' is the relation the noun names', M19, [plural_of(los, el)]),
    reason_sentence('Alice is the mother of Bob.', M20),
    check('with a proper noun after `of''', M20, [mother_of(alice, bob)]),
    reason_sentence('"como" is the first person of "come".', M91),
    check('an adjective before that noun is a fact about the subject, before the claim', M91, [first(como), person_of(como, come)]),
    reason_question('What is the first person of "come"?', Q92),
    yes_no(( Q92 = question(X92, (person_of(Y92, come), first(Z92))), X92 == Y92, Y92 == Z92 ), S92),
    check('and asked for: the relation, then the adjective as a condition on what is asked', S92, yes),
    reason_sentence('"al" is the contraction of "a el".', M93),
    check('a mention may hold a space: the text between the marks, whatever it is', M93, [contraction_of(al, 'a el')]),
    reason_sentence('"casa" is a feminine noun.', M94),
    check('`is a ADJ NOUN'': the adjective is a fact about the subject, before the class', M94, [feminine(casa), noun(casa)]),
    reason_sentence('Alice is a good baker.', M95),
    check('of a proper noun too', M95, [good(alice), baker(alice)]),
    reason_sentence('Every tenant that is a good baker is happy.', [R96]),
    R96 = (happy(X96) :- tenant(Y96), baker(Z96), good(W96)),
    yes_no((X96 == Y96, Y96 == Z96, Z96 == W96), S96),
    check('and in a relative clause, the class first and the adjective after it', S96, yes),
    yes_no(reason_sentence('"casa" means "house" in Spanish.', _), M97),
    check('a sentence that mentions a word names no PLACE: the language after it is refused, not mean_in/3', M97, no),
    yes_no(reason_sentence('The word "no" precedes the verb in Spanish.', _), M98),
    check('after a class atom too', M98, no),
    reason_sentence('Every adjective follows the noun in Spanish.', [R99]),
    yes_no(( R99 = (follow_in(_, noun, spanish) :- adjective(_)) ), S99),
    check('where a sentence with no mention still reads it as a place', S99, yes),
    reason_sentence('Every noun that ends in a vowel takes "s" in the plural.', [R21]),
    R21 = (take_in(X21, s, plural) :- noun(Y21), end_in(Z21, vowel)),
    yes_no((X21 == Y21, Y21 == Z21), S21),
    check('a rule over a letter class, with a definite phrase after the object', S21, yes),
    reason_question('What is the plural of "el"?', Q22),
    Q22 = question(V22, plural_of(W22, el)),
    yes_no(V22 == W22, S22),
    check('`what is the NOUN of X'' asks for the relation''s first argument', S22, yes),
    reason_question('Is "los" the plural of "el"?', Q23),
    check('and as a yes-or-no question', Q23, question(plural_of(los, el))),
    yes_no(( end_in(casa, vowel), end_in(pan, consonant), \+ end_in(casa, consonant), \+ end_in(pan, vowel),
             end_in('sofá', vowel), begin_with(oso, vowel), begin_with(pan, consonant), \+ end_in(x9, consonant) ), H24),
    check('the letter classes: the five vowels and their accented forms; a digit is neither', H24, yes),
    yes_no(( reason_base(houses, house), reason_base(boxes, box), reason_base(cities, city), reason_base(has, have) ), H25),
    check('reason_base/2 is the stemmer, and takes a plural noun back', H25, yes),
    reason_learn('The noun "pan" means "loaf". Every noun that ends in a consonant takes "es" in the plural. "los" is the plural of "el".'),
    reason_explanation(take_in(pan, es, plural), X26),
    check('a letter class is said with its article', X26, '"pan" takes "es" in the plural because "pan" is a noun and "pan" ends in a consonant.'),
    reason_explanation(plural_of(los, el), X27),
    check('a relation a noun names is said with the noun', X27, '"los" is the plural of "el", as said.'),
    reason_tokens('¿Qué come? ¡Hola! — sí', T28),
    check('the Spanish marks and a typographic dash are punctuation, not letters', T28,
          [word('qué', upper), word(come, lower), '.', word(hola, upper), '.', word('sí', lower)]).

%% ---- the lexicon overrides position ------------------------------------------

lexicon :-
    section('lexicon'),
    assertz(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', X1),
    check('reason_verb/2 keeps a surface form', X1, [car(car_1), owns(carol, car_1)]),
    retract(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', X2),
    check('and retracting it restores the base form', X2, [car(car_1), own(carol, car_1)]),
    assertz(reason_proper(acme, acme_corp)),
    reason_sentence('Acme employs Dave.', X3),
    check('reason_proper/2 names the constant', X3, [employ(acme_corp, dave)]),
    reason_sentence('Dave joins acme.', X4),
    check('and a lexicon proper noun needs no capital', X4, [join(dave, acme_corp)]),
    retract(reason_proper(acme, acme_corp)),
    yes_no(reason_sentence('Dave joins acme.', _), X5),
    check('without it a lowercase word is no object', X5, no).

%% ---- naming the individuals ----------------------------------------------------

naming :-
    section('naming'),
    reason_text('Alice owns a red car. Bob owns a car. Carol owns a dog.', M1),
    check('numbered per noun, in order, across the paragraph', M1,
          [car(car_1), red(car_1), own(alice, car_1),
           car(car_2), own(bob, car_2),
           dog(dog_1), own(carol, dog_1)]),
    reason_text('Alice owns a car.', [variables(true)], M2),
    M2 = [car(V2), own(alice, W2)],
    yes_no((var(V2), V2 == W2), K2),
    check('variables(true) keeps the individual a shared variable', K2, yes),
    reason_name([car(V3), own(a, V3), (p(Q3) :- q(Q3))], M3),
    M3 = [car(N3), own(a, N3b), (p(Q3b) :- q(Q3c))],
    check('reason_name/2 names a fact''s variable', N3-N3b, car_1-car_1),
    yes_no((var(Q3b), Q3b == Q3c), K3),
    check('and leaves a rule''s alone', K3, yes),
    reason_name([g(_, a)], M4),
    check('a variable no unary term introduces is a thing', M4, [g(thing_1, a)]),
    reason_text('', M5),
    check('empty text, no terms', M5, []).

%% ---- the claim: what comes out asserts, and then proves --------------------------

round_trip :-
    section('round trip'),
    reason_text('Alice is an employee. Alice is authorized. Bob is an employee. Bob is suspended. Every employee that is authorized may access the server. Every employee that is not suspended may access the server. Bob does not own a car.', Ts),
    length(Ts, N), check('seven sentences, seven terms', N, 7),
    forall(member(T, Ts), assertz(T)),
    findall(W, may_access(W, server), Ws), sort(Ws, Who),
    check('the rules the text wrote prove Alice and not Bob', Who, [alice]),
    yes_no(may_access(bob, server), Bob),
    check('Bob: not authorized, and suspended', Bob, no),
    yes_no(neg(own(bob, car)), Neg),
    check('and the negative sentence is a fact to query', Neg, yes).

%% ---- what it refuses, by failing -----------------------------------------------------

refusals :-
    section('refusals'),
    yes_no(reason_sentence('She uses it.', _), F1),
    check('a pronoun object', F1, no),
    yes_no(reason_text('Alice owns a car. She uses it.', _), F2),
    check('a paragraph half understood is refused whole', F2, no),
    yes_no(reason_sentence('If an employee is authorized then it may access the server.', _), F3),
    check('if-then', F3, no),
    yes_no(reason_sentence('owns a car.', _), F4),
    check('no subject', F4, no),
    yes_no(reason_sentence('Alice owns.', _), F5),
    check('a transitive frame with nothing after the verb is... a unary claim: own(alice)', F5, yes),
    yes_no(reason_sentence('Alice a car.', _), F6),
    check('no verb', F6, no),
    reason_sentence('Alice owns a house near the river.', F7),
    check('a definite phrase after an object is a place, its class atom -- never river(river_1), which `in Rome'' once gave as rome(rome_1)', F7,
          [house(house_1), own_near(alice, house_1, river)]),
    yes_no(reason_sentence('Alice owns a house near a river.', _), F7i),
    check('an indefinite one after an object is not a place: REFUSED', F7i, no),
    reason_refused('Alice owns a house near a river.', F7r),
    check('  -- and reason_refused/2 names it', F7r, 'alice owns a house near a river'),
    reason_sentence('Alice sleeps at the house.', F8),
    check('a preposition and a determined noun after an intransitive verb join it, the noun its class atom', F8, [sleep_at(alice, house)]),
    yes_no(reason_sentence('Alice is in.', _), F9),
    check('a preposition is not an adjective', F9, no),
    yes_no(reason_sentence('Every tenant that is not exempt must pay the rent to nobody.', _), F10),
    check('a preposition after a rule''s object with no place behind it', F10, no),
    yes_no(reason_sentence('Alice and Bob.', _), F11),
    check('a conjunction: REFUSED, where it once parsed as and(alice, bob)', F11, no),
    yes_no(reason_sentence('Alice or Bob.', _), F12),
    check('or: refused, was or(alice, bob)', F12, no),
    yes_no(reason_sentence('Alice but Bob.', _), F13),
    check('but: refused, was but(alice, bob)', F13, no),
    yes_no(reason_sentence('Alice and Bob signed the contract.', _), F14),
    check('a conjoined subject: refused by rule now, not by its tail', F14, no).

%% ---- a place after an object -----------------------------------------------------------------
%% `rents a flat in Bristol': the preposition joins the relation and the
%% place is its last argument, exactly as a preposition written joined to a
%% bare verb does -- and the verb inside a joined relation stems, so a fact
%% and its denial name ONE predicate. After a bare verb the two words are
%% one relation and are written as one; `sleeps in Rome' stays refused.

places :-
    section('a place after an object'),
    reason_sentence('Dana rents a flat in Bristol.', P1),
    check('a fact: the individual, and rent_in/3 with the place last', P1, [flat(flat_1), rent_in(dana, flat_1, bristol)]),
    reason_sentence('Dana rents a small flat in Bristol.', P2),
    check('with an adjective', P2, [flat(flat_1), small(flat_1), rent_in(dana, flat_1, bristol)]),
    reason_sentence('Dana keeps the key at Bristol.', P3),
    check('a definite object: the class atom, and the preposition as written', P3, [keep_at(dana, key, bristol)]),
    reason_sentence('Dana meets Ravi in Bristol.', P4),
    check('a proper object', P4, [meet_in(dana, ravi, bristol)]),
    reason_sentence('Every tenant rents a flat in Bristol.', [(H5 :- B5)]),
    yes_no(( H5 = rent_in(X5, flat, bristol), B5 == tenant(X5) ), Rule5),
    check('a rule: the class atom as object, the place a constant, one variable through', Rule5, yes),
    reason_sentence('Dana does not rent a flat in Bristol.', P6),
    check('a denial names the same predicate', P6, [neg(rent_in(dana, flat, bristol))]),
    reason_sentence('Every tenant that is not exempt must pay the rent to Alice.', [(H7 :- _)]),
    yes_no(H7 = must_pay_to(_, rent, alice), Rule7),
    check('a modal, a definite object and a place: must_pay_to/3', Rule7, yes),
    reason_sentence('Ola lives_in Lagos.', P8),
    check('a joined relation stems its verb: lives_in is live_in', P8, [live_in(ola, lagos)]),
    reason_sentence('Kai does not live_in Lagos.', P9),
    check('so the fact and its denial name one predicate', P9, [neg(live_in(kai, lagos))]),
    reason_sentence('Alice may_use the server.', P10),
    check('but a modal joined to its verb is left as written', P10, [may_use(alice, server)]),
    yes_no(reason_sentence('Dana lives in Bristol.', _), P11),
    check('after a bare verb the two words are written as one: `lives in Bristol'' is refused', P11, no),
    yes_no(reason_sentence('Alice owns a house in rome.', _), P12),
    check('and a lower-case word after the preposition is no place', P12, no).

%% ---- state between sentences: a subject pronoun ------------------------------------------
%% The subject of the last fact is carried from sentence to sentence, and
%% `she', `he' or `they' as a subject stands for it. One sentence alone has
%% no state; `it' is left alone; an object pronoun is still refused.

state :-
    section('state between sentences'),
    reason_text('Priya is a baker. She is licensed.', S1),
    check('`she'' is the last fact''s subject', S1, [baker(priya), licensed(priya)]),
    reason_text('Marco is a tenant. He does not pay the rent. He sleeps.', S2),
    check('`he'', through two sentences', S2, [tenant(marco), neg(pay(marco, rent)), sleep(marco)]),
    reason_text('Priya is a baker. Every baker may sell the bread. She is licensed.', S3),
    yes_no(S3 = [baker(priya), (may_sell(X3, bread) :- baker(X3)), licensed(priya)], Rule3),
    check('a rule between keeps the state', Rule3, yes),
    reason_text('Priya is a baker. Marco is a tenant. She is licensed.', S4),
    check('the LAST fact''s subject, so this `she'' is Marco -- the reader has one pronoun', S4, [baker(priya), tenant(marco), licensed(marco)]),
    reason_text('Priya is a baker. They are licensed.', S5),
    check('`they'' too, with `are''', S5, [baker(priya), licensed(priya)]),
    reason_text('Priya rents a flat in Bristol. She keeps the keys in Bristol.', S6),
    check('with a place after the object', S6, [flat(flat_1), rent_in(priya, flat_1, bristol), keep_in(priya, keys, bristol)]),
    yes_no(reason_sentence('She is licensed.', _), S7),
    check('one sentence alone has no state: refused', S7, no),
    yes_no(reason_text('She is licensed.', _), S8),
    check('and a paragraph that opens with a pronoun is refused', S8, no),
    yes_no(reason_text('Priya is a baker. It rains.', _), S9),
    check('`it'' is not a subject pronoun here: still refused', S9, no),
    yes_no(reason_text('Priya is a baker. She likes him.', _), S10),
    check('an object pronoun is still refused', S10, no),
    reason_refused('Priya is a baker. She is licensed. She uses it.', R11),
    check('reason_refused/2 carries the state too, and names the third sentence', R11, 'she uses it').

%% ---- questions: a goal, and the reason with the answer -----------------------------------

questions :-
    section('questions'),
    reason_question('Does Priya sell the bread?', Q1),
    check('does S V the N: the goal a statement would assert', Q1, question(sell(priya, bread))),
    reason_question('Is Priya licensed?', Q2),   check('is S ADJ', Q2, question(licensed(priya))),
    reason_question('Is Marco a tenant?', Q3),   check('is S a N', Q3, question(tenant(marco))),
    reason_question('May Priya sell the bread?', Q4), check('a modal joins its verb', Q4, question(may_sell(priya, bread))),
    reason_question('Does Priya rent a flat in Bristol?', Q5),
    yes_no(( Q5 = question((flat(F5), rent_in(priya, F5b, bristol))), F5 == F5b, var(F5) ), V5),
    check('an indefinite object: an existential, the flat a variable', V5, yes),
    reason_question('Who rents a flat in Bristol?', Q6),
    yes_no(( Q6 = question(X6, (flat(F6), rent_in(X6b, F6b, bristol))), X6 == X6b, F6 == F6b, var(X6), X6 \== F6 ), V6),
    check('who: the subject is the variable asked for', V6, yes),
    reason_question('Who is licensed?', Q7),
    yes_no(( Q7 = question(X7, licensed(X7b)), X7 == X7b ), V7), check('who is ADJ', V7, yes),
    reason_question('Who is a baker?', Q8),
    yes_no(( Q8 = question(X8, baker(X8b)), X8 == X8b ), V8), check('who is a N', V8, yes),
    reason_question('What does Priya sell?', Q9),
    yes_no(( Q9 = question(X9, sell(priya, X9b)), X9 == X9b ), V9), check('what: the object is the variable', V9, yes),
    reason_question('Where does Marco sleep?', Q10),
    yes_no(( Q10 = question(X10, sleep_in(marco, X10b)), X10 == X10b ), V10), check('where: the place, `in'' assumed', V10, yes),
    reason_question('What does Priya keep in Leeds?', Q10c),
    yes_no(( Q10c = question(X10c, keep_in(priya, X10d, leeds)), X10c == X10d ), V10c), check('what, with a place', V10c, yes),
    reason_question('What does Priya keep_in Leeds?', Q10e),
    yes_no(( Q10e = question(X10e, keep_in(priya, X10f, leeds)), X10e == X10f ), V10e),
    check('and with the place joined to the verb, as the assembler writes it', V10e, yes),
    reason_text('Priya is a baker.', _),
    reason_question('Does she sell the bread?', Q11),
    check('a pronoun subject, from the state the last text left', Q11, question(sell(priya, bread))),
    yes_no(reason_question('Priya sells the bread.', _), Q12), check('a statement is not a question', Q12, no),
    reason_text('Who owns a car. Priya sleeps.', T13),
    yes_no(( T13 = [question(_, _), sleep(priya)] ), V13),
    check('in a paragraph a question is a question/2 term among the facts, its variable kept', V13, yes),
    reason_text('Priya is a baker. Priya is licensed. Every baker that is licensed may sell the bread. Marco does not pay the rent. Priya rents a flat in Bristol. Marco sleeps_in Lisbon.', KB),
    forall(member(T, KB), assertz(T)),
    reason_ask('Is Priya a baker?', A1), check('asked: a fact -- yes, and the reason is the fact', A1, [yes(fact)]),
    reason_ask('May Priya sell the bread?', [A2]),
    yes_no(A2 = yes(rule((may_sell(priya, bread) :- baker(priya), licensed(priya)))), V2),
    check('asked: by a rule -- yes, and the reason is the rule with the body that proved', V2, yes),
    reason_ask('Does Marco pay the rent?', A3), check('asked: denied -- no, and the reason is the denial', A3, [no(denied(neg(pay(marco, rent))))]),
    reason_ask('Is Marco licensed?', A4), check('asked: never said -- unknown', A4, [unknown]),
    reason_ask('Does Priya rent a flat in Bristol?', A5), check('asked with an existential: some flat -- yes', A5, [yes(fact)]),
    reason_ask('Does Marco rent a flat in Bristol?', A6), check('and nobody said Marco does: unknown', A6, [unknown]),
    reason_ask('Who rents a flat in Bristol?', A7), check('who: the bindings, each with its reason', A7, [[priya-fact]]),
    reason_ask('Who may sell the bread?', [[Who8-Why8]]),
    yes_no(( Who8 == priya, Why8 = rule(_) ), V8b), check('who, by a rule', V8b, yes),
    reason_ask('Who is a tenant?', A9), check('who, when nobody: an empty list', A9, [[]]),
    reason_ask('Where does Marco sleep?', A10), check('where', A10, [[lisbon-fact]]),
    reason_ask('What does Priya rent in Bristol?', A11), check('what, with a place', A11, [[flat_1-fact]]),
    reason_ask('Priya is a baker. Is she licensed?', A12), check('a statement read for its state, not asserted; the pronoun asks about Priya', A12, [yes(fact)]),
    reason_ask('Is Priya a baker? Does Marco pay the rent?', A13), check('two questions, two answers, in order', A13, [yes(fact), no(denied(neg(pay(marco, rent))))]),
    reason_why(may_sell(priya, bread), W14),
    check('reason_why/2 on its own', W14, rule((may_sell(priya, bread) :- baker(priya), licensed(priya)))),
    yes_no(reason_why(licensed(marco), _), W15), check('and fails for what nothing holds up', W15, no).

%% ---- amounts and quantities: a value, never an individual ------------------

quantities :-
    section('quantities'),
    reason_sentence('Nadia pays 500 euros.', Q1),
    check('a number and its noun: quantity(N, Noun), the noun as written', Q1, [pay(nadia, quantity(500, euros))]),
    reason_sentence('Tariq owns three vineyards.', Q2), check('a number word', Q2, [own(tariq, quantity(3, vineyards))]),
    reason_sentence('Tariq owns twenty five vineyards.', Q3), check('tens and units', Q3, [own(tariq, quantity(25, vineyards))]),
    reason_sentence('Nadia pays two hundred fifty euros.', Q4), check('hundreds', Q4, [pay(nadia, quantity(250, euros))]),
    reason_sentence('Nadia pays a hundred euros.', Q5), check('`a hundred''', Q5, [pay(nadia, quantity(100, euros))]),
    reason_sentence('Nadia pays three thousand euros.', Q6), check('thousands', Q6, [pay(nadia, quantity(3000, euros))]),
    reason_sentence('Nadia pays 5.5 percent.', Q7), check('a decimal', Q7, [pay(nadia, quantity(5.5, percent))]),
    reason_sentence('Nadia buys two litres of milk.', Q8), check('N UNIT of NOUN: quantity/3', Q8, [buy(nadia, quantity(2, litres, milk))]),
    reason_sentence('Nadia buys a litre of milk.', Q9), check('`a UNIT of'' is one', Q9, [buy(nadia, quantity(1, litre, milk))]),
    reason_sentence('Nadia pays 500 euros to Tariq.', Q10),
    check('a proper noun after the quantity joins the relation, as a place does', Q10, [pay_to(nadia, quantity(500, euros), tariq)]),
    reason_sentence('The rent is 500 euros.', Q11), check('the amount sentence: the one definite subject', Q11, [amount(rent, quantity(500, euros))]),
    reason_sentence('The rent is not 500 euros.', Q12), check('and its denial', Q12, [neg(amount(rent, quantity(500, euros)))]),
    reason_sentence('The price is 500.', Q13), check('a bare number is the number', Q13, [amount(price, 500)]),
    reason_sentence('Every tenant must pay 500 euros.', [Q14]),
    yes_no(( Q14 = (must_pay(X14, quantity(500, euros)) :- tenant(Y14)), X14 == Y14 ), V14),
    check('a rule: the quantity in the head', V14, yes),
    reason_sentence('Nadia does not pay 500 euros.', Q15), check('a denial keeps the quantity', Q15, [neg(pay(nadia, quantity(500, euros)))]),
    yes_no(reason_sentence('Nadia owns three red cars.', _), R16), check('an adjective inside a quantity is refused, not dropped', R16, no),
    yes_no(reason_sentence('Five is a number.', _), R17), check('a number word is closed: never a name', R17, no),
    reason_sentence('Alice owns one car.', Q18), check('`one car'' is a quantity of one, not an individual', Q18, [own(alice, quantity(1, car))]),
    reason_question('Does Nadia pay 500 euros?', Q19), check('does S V N UNIT', Q19, question(pay(nadia, quantity(500, euros)))),
    reason_question('Is the rent 500 euros?', Q20), check('is the N N UNIT', Q20, question(amount(rent, quantity(500, euros)))),
    reason_question('How much does Nadia pay?', Q21),
    yes_no(( Q21 = question(A21, (pay(nadia, O21), reason_amount(O21b, A21b))), A21 == A21b, O21 == O21b, var(A21) ), V21),
    check('how much: the object, through reason_amount/2', V21, yes),
    reason_question('How much must Nadia pay?', Q22),
    yes_no(( Q22 = question(A22, (must_pay(nadia, O22), reason_amount(O22b, A22b))), A22 == A22b, O22 == O22b ), V22),
    check('how much, with a modal', V22, yes),
    reason_question('How many vineyards does Tariq own?', Q23),
    yes_no(( Q23 = question(N23, (own(tariq, O23), reason_count(O23b, vineyards, N23b))), N23 == N23b, O23 == O23b ), V23),
    check('how many NOUN: the count, through reason_count/3', V23, yes),
    reason_question('How much is the rent?', Q24),
    yes_no(( Q24 = question(A24, amount(rent, A24b)), A24 == A24b ), V24), check('how much is the N', V24, yes),
    reason_text('Nadia pays 500 euros. Tariq owns three vineyards. Omar pays the rent. The rent is 600 euros. Every grower must pay 500 euros. Omar is a grower. Nadia does not pay 700 euros. Nadia buys two litres of milk.', KBQ),
    forall(member(T, KBQ), assertz(T)),
    reason_ask('Does Nadia pay 500 euros?', A1), check('asked: yes, a fact', A1, [yes(fact)]),
    reason_ask('Does Nadia pay 700 euros?', A2), check('asked: denied', A2, [no(denied(neg(pay(nadia, quantity(700, euros)))))]),
    reason_ask('Does Nadia pay 900 euros?', A3), check('asked: never said', A3, [unknown]),
    reason_ask('How much does Nadia pay?', A4), check('how much: the quantity, and the fact', A4, [[quantity(500, euros)-fact]]),
    reason_ask('How much does Omar pay?', A5),
    check('how much, through the amount of a definite object: 600 euros, not `rent''', A5, [[quantity(600, euros)-fact]]),
    reason_ask('How much must Omar pay?', [[Q6a-W6]]),
    yes_no(( Q6a == quantity(500, euros), W6 = rule(_) ), V6), check('how much, by a rule', V6, yes),
    reason_ask('How many vineyards does Tariq own?', A7), check('how many', A7, [[3-fact]]),
    reason_ask('How many litres does Nadia buy?', A8), check('how many, over a quantity with an `of'' part', A8, [[2-fact]]),
    reason_ask('How much is the rent?', A9), check('how much is', A9, [[quantity(600, euros)-fact]]),
    reason_ask('How much does Tariq pay?', A10), check('how much, when nobody said: nothing', A10, [[]]),
    reason_ask('Is the rent 600 euros?', A11), check('is the N N UNIT: yes', A11, [yes(fact)]),
    reason_ask('Who pays 500 euros?', A12), check('who, with a quantity', A12, [[nadia-fact]]),
    truth(pay(nadia, quantity(500, euros)), V13), check('truth/2 over a quantity', V13, true),
    reason_amount(quantity(2, litres, milk), AM1), check('reason_amount/2: a quantity is its own amount', AM1, quantity(2, litres, milk)),
    reason_amount(rent, AM2), check('and a definite object answers the amount the text gave it', AM2, quantity(600, euros)),
    reason_count(quantity(2, litres, milk), litres, C1), check('reason_count/3 over quantity/3', C1, 2).

%% ---- the explanation: the whole proof, in sentences ----------------------------
%% A chess position: the black king on h8 behind its own pawns on g7 and
%% h7, a white rook arrived on e8. Check and mate are three rules of the
%% controlled English; what it cannot say -- a rule over two variables, a
%% universal -- is four Prolog clauses beside it, and the explanation walks
%% both alike. The Priya and Omar facts are the ones the sections above
%% asserted.

explains :-
    section('explanation'),
    reason_text('Kh8 is a king. Kh8 is black. Kh8 occupies H8. Re8 is a rook. Re8 is white. Re8 occupies E8. Re8 attacks F8. Re8 attacks G8. Re8 attacks H8. Pg7 is a pawn. Pg7 is black. Pg7 occupies G7. Pg7 attacks F6. Pg7 attacks H6. Ph7 is a pawn. Ph7 is black. Ph7 occupies H7. Ph7 attacks G6. G8 is a square. G7 is a square. H7 is a square. Kh8 may move_to G8. Kh8 may move_to G7. Kh8 may move_to H7. Every square that is attacked is unsafe. Every square that is occupied is unsafe. Every king that is attacked is a target. Every target that is immobile is a captive. Every captive that is not defended is checkmated.', Chess),
    length(Chess, NC), check('the position and the definitions: twenty-nine terms', NC, 29),
    forall(member(T, Chess), assertz(T)),
    assertz(( attacked(X) :- attack(_, X) )),
    assertz(( attacked(P) :- occupy(P, S), attack(_, S) )),
    assertz(( occupied(S) :- occupy(_, S) )),
    assertz(( immobile(K) :- king(K), \+ ( may_move_to(K, S), \+ unsafe(S) ) )),
    assertz(( defended(K) :- occupy(K, S), attack(A, S), occupy(A, T), attack(D, T), black(D) )),
    reason_explain(unsafe(g8), W1),
    check('a rule, and the facts and the rule under it', W1, rule(unsafe(g8), [fact(square(g8)), rule(attacked(g8), [fact(attack(re8, g8))])])),
    reason_explain(immobile(kh8), W2),
    yes_no(( W2 = rule(immobile(kh8), [fact(king(kh8)), forall(may_move_to(kh8, S2), unsafe(S2b), Insts2)]), S2 == S2b,
             Insts2 = [may_move_to(kh8, g8)-rule(unsafe(g8), _), may_move_to(kh8, g7)-rule(unsafe(g7), _), may_move_to(kh8, h7)-rule(unsafe(h7), _)] ), V2),
    check('a universal, \\+ (A, \\+ B): every instance of A with the why of B', V2, yes),
    reason_explain(checkmated(kh8), W3),
    yes_no(W3 = rule(checkmated(kh8), [rule(captive(kh8), [rule(target(kh8), [fact(king(kh8)), rule(attacked(kh8), [fact(occupy(kh8, h8)), fact(attack(re8, h8))])]),
                                                             rule(immobile(kh8), _)]),
                                          absent(defended(kh8))]), V3),
    check('the whole proof of the mate, absent(defended) for the negation nothing proves', V3, yes),
    reason_explanation(checkmated(kh8), E3),
    check('and in sentences, every level of it, depth first', E3,
          'Kh8 is checkmated because Kh8 is a captive and nothing shows that Kh8 is defended. Kh8 is a captive because Kh8 is a target and Kh8 is immobile. Kh8 is a target because Kh8 is a king and Kh8 is attacked. Kh8 is attacked because Kh8 occupies H8 and Re8 attacks H8. Kh8 is immobile because Kh8 is a king and whenever Kh8 may move to X, X is unsafe (X: G8, G7 and H7). G8 is unsafe because G8 is a square and G8 is attacked. G8 is attacked because Re8 attacks G8. G7 is unsafe because G7 is a square and G7 is occupied. G7 is occupied because Pg7 occupies G7. H7 is unsafe because H7 is a square and H7 is occupied. H7 is occupied because Ph7 occupies H7.'),
    reason_question('Why is Kh8 checkmated?', Q4), check('why: the question is question(why(Goal))', Q4, question(why(checkmated(kh8)))),
    reason_ask('Why is Kh8 checkmated?', [because(E4)]), check('asked: because(Text), the same sentences', E4, E3),
    reason_ask('Why is Kh8 checkmated?', A5, X5), check('reason_ask/3: the answer', A5, [because(E3)]), check('and the explanation beside it', X5, [E3]),
    reason_ask('Is Kh8 checkmated?', A6, X6),
    yes_no(A6 = [yes(rule(_))], V6), check('a yes carries its one-level reason', V6, yes), check('and reason_ask/3 the whole proof', X6, [E3]),
    reason_ask('Why is G7 unsafe?', [because(E7)]), check('why, two levels', E7, 'G7 is unsafe because G7 is a square and G7 is occupied. G7 is occupied because Pg7 occupies G7.'),
    reason_ask('Why is Re8 white?', [because(E8)]), check('why, a fact: as said', E8, 'Re8 is white, as said.'),
    reason_ask('Why does Re8 attack H8?', [because(E9)]), check('a binary fact, the verb in the third person, the names capitalised', E9, 'Re8 attacks H8, as said.'),
    reason_ask('Why is Kh8 happy?', A10, X10), check('why, when nothing shows it: unknown', A10, [unknown]), check('and the explanation says so', X10, ['Nothing shows that Kh8 is happy.']),
    reason_ask('Is Kh8 defended?', A11, X11), check('a yes-or-no nothing shows: unknown', A11, [unknown]), check('with the same sentence', X11, ['Nothing shows that Kh8 is defended.']),
    reason_ask('Who is a captive?', A12, X12),
    atom_concat('Kh8 is checkmated because Kh8 is a captive and nothing shows that Kh8 is defended. ', Rest12, E3),
    yes_no(( A12 = [[kh8-rule(_)]], X12 == [[kh8-Rest12]] ), V12), check('who: each value with its whole proof', V12, yes),
    reason_ask('Why may Priya sell the bread?', [because(E13)]), check('why, by a rule with two facts', E13, 'Priya may sell the bread because Priya is a baker and Priya is licensed.'),
    reason_ask('Does Priya rent a flat in Bristol?', _, X14), check('a yes over an existential: the fact, the individual as `the flat''', X14, ['Priya rents the flat in Bristol, as said.']),
    reason_ask('Does Marco pay the rent?', _, X15), check('a no: the denial, as said', X15, ['Marco does not pay the rent, as said.']),
    reason_ask('Does Marco rent a flat in Bristol?', _, X16), check('unknown over an existential: `a flat''', X16, ['Nothing shows that Marco rents a flat in Bristol.']),
    reason_ask('How much does Omar pay?', _, X17), check('how much: the fact and the amount it went through', X17, [[quantity(600, euros)-'Omar pays the rent, as said. The rent is 600 euros, as said.']]),
    reason_ask('Why must Omar pay 500 euros?', [because(E18)]), check('why, a rule with a quantity in its head', E18, 'Omar must pay 500 euros because Omar is a grower.'),
    reason_ask('Why does Marco pay the rent?', [because(E19)]), check('why, when the text denied it: the denial', E19, 'Marco does not pay the rent, as said.'),
    reason_explanation(neg(pay(marco, rent)), E20), check('reason_explanation/2 over a denial', E20, 'Marco does not pay the rent, as said.'),
    yes_no(reason_explanation(happy(marco), _), V21), check('and fails for what nothing holds up', V21, no),
    yes_no(catch(reason_explain(_, _), error(instantiation_error, _), fail), V22), check('reason_explain/2 wants a goal', V22, no),
    assertz(size(box, 5)), assertz(( big(X) :- size(X, N), N > 3 )), assertz(( heavy(X) :- big(X) ; size(X, 9) )),
    reason_explanation(big(box), E27), check('a builtin comparison in a body, said in words', E27, 'The box is big because the box sizes 5 and 5 is more than 3.'),
    reason_explanation(heavy(box), E28), check('a disjunction in a body: the branch that proved', E28, 'The box is heavy because the box is big. The box is big because the box sizes 5 and 5 is more than 3.'),
    reason_third(attack, T23), check('reason_third/2, the inflector: attack -> attacks', T23, attacks),
    reason_third(occupy, T24), check('occupy -> occupies', T24, occupies),
    reason_third(watch, T25), check('watch -> watches', T25, watches),
    reason_third(have, T26), check('have -> has', T26, has).

%% ---- concepts and topics: what a text is about ------------------------------------

topics :-
    section('topics'),
    Chess = 'Kh8 is a king. Kh8 is black. Kh8 occupies H8. Re8 is a rook. Re8 is white. Re8 occupies E8. Re8 attacks F8. Re8 attacks G8. Re8 attacks H8. Pg7 is a pawn. Pg7 is black. Pg7 occupies G7. Pg7 attacks F6. Pg7 attacks H6. Ph7 is a pawn. Ph7 is black. Ph7 occupies H7. Ph7 attacks G6. G8 is a square. G7 is a square. H7 is a square. Kh8 may move_to G8. Kh8 may move_to G7. Kh8 may move_to H7. Every square that is attacked is unsafe. Every square that is occupied is unsafe. Every king that is attacked is a target. Every target that is immobile is a captive. Every captive that is not defended is checkmated.',
    reason_text(Chess, Terms),
    reason_concepts(Terms, Cs),
    yes_no(Cs = [concept(kh8, name, 6), concept(re8, name, 6), concept(attack, relation, 6)|_], V1),
    check('concepts, the most mentioned first, ties in order of first mention: Kh8, Re8, attack', V1, yes),
    yes_no(memberchk(concept(square, class, 5), Cs), V2), check('a class: three facts and two rule guards', V2, yes),
    yes_no(memberchk(concept(unsafe, property, 2), Cs), V3), check('a property: two rule heads', V3, yes),
    yes_no(memberchk(concept(may_move_to, relation, 3), Cs), V4), check('a relation', V4, yes),
    yes_no(memberchk(concept(h8, name, 2), Cs), V5), check('a name mentioned as an object', V5, yes),
    length(Cs, NC), check('thirty concepts in all', NC, 30),
    reason_topics(Terms, Ts),
    Ts = [T1|_],
    check('the first topic is what the text is most about, with its sub-topics in order of first mention', T1,
          topic(kh8, name, [class-[king], property-[black], relation(occupy)-[[h8]], relation(may_move_to)-[[g8], [g7], [h7]]])),
    yes_no(memberchk(topic(re8, name, [class-[rook], property-[white], relation(occupy)-[[e8]], relation(attack)-[[f8], [g8], [h8]]]), Ts), V6),
    check('a relation groups its objects', V6, yes),
    yes_no(( memberchk(topic(square, class, [members-[g8, g7, h7], rules-[R1, R2]]), Ts),
             R1 = (unsafe(X1) :- square(X1b), attacked(X1c)), X1 == X1b, X1b == X1c, R2 = (unsafe(_) :- square(_), occupied(_)) ), V7),
    check('a class: its members, and the rules over it', V7, yes),
    yes_no(memberchk(topic(unsafe, property, [definition-[_, _]]), Ts), V8), check('a property a rule defines: its definitions', V8, yes),
    yes_no(memberchk(topic(target, class, [definition-[_], rules-[_]]), Ts), V9), check('a class defined and quantified over', V9, yes),
    yes_no(memberchk(topic(h8, name, [by(occupy)-[occupy(kh8, h8)], by(attack)-[attack(re8, h8)]]), Ts), V10),
    check('an object: what is said of it from the other side', V10, yes),
    yes_no(memberchk(topic(g8, name, [by(attack)-[attack(re8, g8)], class-[square], by(may_move_to)-[may_move_to(kh8, g8)]]), Ts), V11),
    check('a square: attacked, a square, a move', V11, yes),
    length(Ts, NT), check('twenty-one topics', NT, 21),
    reason_outline(Chess, Lines),
    Lines = [L1, L2|_],
    check('the outline as lines: the king', L1, 'Kh8, a king: black; occupies H8; may move to G8, G7 and H7.'),
    check('the rook', L2, 'Re8, a rook: white; occupies E8; attacks F8, G8 and H8.'),
    yes_no(memberchk('Square (G8, G7 and H7): every square that is attacked is unsafe; every square that is occupied is unsafe.', Lines), V12),
    check('a class with its members and its rules', V12, yes),
    yes_no(memberchk('Unsafe: a square that is attacked; a square that is occupied.', Lines), V13), check('a property by its definitions', V13, yes),
    yes_no(memberchk('Captive: a target that is immobile; every captive that is not defended is checkmated.', Lines), V14),
    check('a class defined and quantified over', V14, yes),
    yes_no(memberchk('H8: Kh8 occupies it; Re8 attacks it.', Lines), V15), check('an object, from the other side', V15, yes),
    yes_no(memberchk('G8, a square: Re8 attacks it; Kh8 may move to it.', Lines), V16), check('a square', V16, yes),
    reason_outline('Priya is a baker. Priya is licensed. Every baker that is licensed may sell the bread. Priya rents a flat in Bristol. Marco does not pay the rent. The rent is 600 euros. Nadia pays 500 euros to Omar. Every employee is a person. Every tenant that is not exempt must pay the rent.', L2s),
    check('and a paragraph of the earlier kind', L2s,
          ['Priya, a baker: licensed; rents the flat in Bristol.', 'Baker (Priya): every baker that is licensed may sell the bread.',
           'The flat: Priya rents it in Bristol.', 'Marco: does not pay the rent.', 'The rent: 600 euros.', 'Nadia: pays 500 euros to Omar.',
           'Person: an employee.', 'Employee: every employee is a person.', 'Tenant: every tenant that is not exempt must pay the rent.']),
    reason_topics([], T0), check('nothing in, nothing out', T0, []),
    reason_concepts([question(happy(x))], C0), check('a question mentions nothing', C0, []).

%% ---- prose, through the shipped tagger: optional --------------------------------------------
%% reason_prose/2 loads library(reasoning/tagger) and the model shipped
%% beside the library on first use; where either is missing it raises, and
%% this section says so rather than failing.

%% THE OBJECT IS A CAR AND NOT A TRUCK, and the reason is measured rather
%% than tidy: an adjective inside an object with a comma filler after it is
%% the shape test/tagger.pl keeps a grid for, and the grid splits by the
%% NOUN. On the model this ships with, `car' -- which the lexicon knows
%% only as a noun -- keeps the adjective in 192 of 192, where `house' and
%% `truck', which are verbs too, keep it in 189 and 186 and `flat', which
%% is also an adjective, in 96. It was a truck here until 1.2.43 and it
%% passed on a model that read trucks in 75 of 192: a coin toss that came
%% up heads, and a pin that would have said nothing had it come up tails.
%% This case is about reason_prose/2 reading typed prose end to end, so it
%% pins the sentence the tagger is CERTAIN of and test/tagger.pl's grid
%% pins the shape -- which is the division to keep whatever the numbers
%% are on the next training.
prose :-
    section('prose'),
    %% WITHOUT TORCH THE PROMISE IS THE ERROR: reason_prose/2 raises
    %% existence_error(tagger, pretrained), which the header names and the
    %% branch below catches -- not torch's own existence_error for a tensor
    %% predicate, which it raised through 1.8.55 and which took this case and
    %% lesson 43 red on every box without torch. Asked of the module itself,
    %% which may be beside the binary, on the path or compiled in.
    (   catch(use_module(library(torch)), _, fail)
    ->  true
    ;   catch(( reason_prose('Rex owns a car.', _), E0 = none ), E0, true),
        ( E0 = error(existence_error(tagger, pretrained), _) -> R0 = promised ; R0 = E0 ),
        check('without library(torch), reason_prose/2 raises existence_error(tagger, pretrained)', R0, promised)
    ),
    (   catch(reason_prose('Well, Rex really owns a red car, obviously. Kim rents a flat in Oslo and is insured.', T1),
              error(existence_error(tagger, pretrained), _), fail)
    ->  check('typed prose, read through the shipped tagger', T1,
              [car(car_1), red(car_1), own(rex, car_1), flat(flat_1), rent_in(kim, flat_1, oslo), insured(kim)]),
        forall(member(T, T1), assertz(T)),
        reason_ask_prose('Honestly, who rents a flat in Oslo?', A2), check('and a typed question, answered', A2, [[kim-fact]]),
        reason_ask_prose('Is she insured?', A3), check('a pronoun in the question: the subject the prose left', A3, [yes(fact)])
    ;   format("     (skipped: no shipped tagger here -- library(torch) and model.rows)~n", [])
    ).

%% ---- a rule declares what its body names ------------------------------------------------

declares :-
    section('declares'),
    reason_text('Every member that is not banned may post the message. Zed is a member.', D1),
    forall(member(T, D1), assertz(T)),
    catch(( may_post(zed, message) -> R1 = proves ; R1 = fails ), E1, R1 = threw(E1)),
    check('`that is not banned'' with nobody banned: the rule PROVES, no existence_error', R1, proves),
    reason_text('Every widget that is blue is nice.', D2),
    forall(member(T, D2), assertz(T)),
    catch(( nice(w9) -> R2 = proves ; R2 = fails ), E2, R2 = threw(E2)),
    check('a body predicate nothing asserted: the rule FAILS, no existence_error', R2, fails),
    yes_no(reason_refused('Every gadget that is not broken works. She fixes it.', _), R3),
    check('reason_refused/2 declares nothing (still a pure check)', R3, yes),
    catch(( broken(g1) -> R4 = proves ; R4 = fails ), E4, R4 = threw(E4)),
    R4 = threw(error(existence_error(procedure, PI4), _)),
    check('  -- so broken/1 is still absent afterwards', PI4, broken/1).

%% ---- reason_refused/2 names the sentence ----------------------------------------------

refused :-
    section('refused'),
    reason_refused('Alice owns a car. Every tenant must_pay rent. Bob is a tenant.', R1),
    check('the first refused sentence, as its words', R1, 'every tenant must_pay rent'),
    findall(R, reason_refused('Alice owns a car. She uses it. Bob sleeps. It rains.', R), Rs2),
    check('every refused sentence on backtracking, in order', Rs2, ['she uses it', 'it rains']),
    yes_no(reason_refused('Alice owns a car. Bob sleeps.', _), R3),
    check('fails when the whole text parses', R3, no),
    yes_no(reason_refused('', _), R4),
    check('and on empty text', R4, no),
    reason_refused('Hello, World, again!', R5),
    check('punctuation is not in the words', R5, 'hello world again').

%% ---- truth/2: four answers ---------------------------------------------------------------

truth :-
    section('truth'),
    reason_text('Alice is happy. Bob is not happy. Carol is a tenant. Every tenant that is not exempt must pay the rent. Dave is a tenant. Dave is exempt.', Ts),
    forall(member(T, Ts), assertz(T)),
    truth(happy(alice), T1),          check('said: true', T1, true),
    truth(happy(bob), T2),            check('denied: false', T2, false),
    truth(happy(carol), T3),          check('never mentioned: unknown', T3, unknown),
    truth(sad(alice), T4),            check('a predicate that does not exist: unknown, not an error', T4, unknown),
    truth(must_pay(carol, rent), T5), check('proved through a rule: true', T5, true),
    truth(must_pay(dave, rent), T6),  check('the rule does not fire and nothing denies it: unknown', T6, unknown),
    assertz(reason_closed(must_pay/2)),
    truth(must_pay(dave, rent), T7),  check('the same goal once the predicate is closed: false', T7, false),
    truth(must_pay(carol, rent), T7b), check('closing changes nothing that proves', T7b, true),
    retract(reason_closed(must_pay/2)),
    assertz(neg(happy(alice))),
    truth(happy(alice), T8),          check('said AND denied: conflict', T8, conflict),
    retract(neg(happy(alice))),
    truth(neg(happy(bob)), T9),       check('a neg/1 goal is a goal like any other', T9, true),
    catch(( truth(happy(_), _), E10 = none ), error(E10, _), true),
    check('a variable is not a question with a truth value', E10, instantiation_error),
    catch(( truth(f(a), _), E11 = none ), error(E11, _), true),
    check('an absent predicate does not throw', E11, none).

%% ---- errors --------------------------------------------------------------------------

errors :-
    section('errors'),
    catch(( reason_tokens(42, _), E1 = none ), error(E1, _), true),
    check('not text: type_error', E1, type_error(text, 42)),
    catch(( reason_text(f(x), _), E2 = none ), error(E2, _), true),
    check('a compound is not text either', E2, type_error(text, f(x))).

%% ---- the library's own version ----------------------------------------------------------
%%
%% What is pinned is the SHAPE, as test/argv.pl pins cocolog's: three integers, the atom
%% they make, one answer each. Never the number -- a commit that changes this library
%% moves it, and this case must not need to move with it.

version :-
    section('version'),
    reason_version(Ma, Mi, Pa),
    (   integer(Ma), integer(Mi), integer(Pa), Ma >= 0, Mi >= 0, Pa >= 0
    ->  check('three integers, none negative', yes, yes)
    ;   check('three integers, none negative', [Ma, Mi, Pa], 'integers >= 0')
    ),
    reason_version(V),
    (   atom(V)
    ->  check('the version is an atom', yes, yes)
    ;   check('the version is an atom', V, 'an atom')
    ),
    atomic_list_concat([Ma, Mi, Pa], '.', Joined),
    check('and it is the three integers joined by dots', V, Joined),
    (   atomic_list_concat(Parts, '.', V), length(Parts, 3), forall(member(P, Parts), atom_number(P, _))
    ->  check('three dotted numbers, and nothing else', yes, yes)
    ;   check('three dotted numbers, and nothing else', V, 'X.Y.Z')
    ),
    findall(V1, reason_version(V1), Vs),
    check('reason_version/1 answers once', Vs, [V]),
    findall(M, reason_version(M, _, _), Ms),
    check('reason_version/3 answers once', Ms, [Ma]),
    (   reason_version(not_a_version) -> R1 = yes ; R1 = no ),
    check('an atom that is not the version does not unify', R1, no).
