%% cocolog tutorial 43 -- library(reasoning/reason): a paragraph in, predicates out.
%%
%% TIER 2: `use_module(library(reasoning/reason))', from reason.pl. Clauses only.
%%
%%     cocolog -s tutorials/library/43-reason.pl
%%
%% A KNOWLEDGE BASE IS ROWS, AND THIS IS HOW A PARAGRAPH BECOMES SOME. The
%% library reads a controlled English -- a proper noun or `every NOUN' as
%% subject, a verb or the copula, an object with `a', `an' or `the' -- and
%% hands back a list of terms: facts, neg/1 facts, and rules written
%% (Head :- Body). Every one of them is a term assertz/1 takes, and section
%% 6 below does exactly that and then PROVES through the rules the text
%% wrote. Nothing is called out to: the grammar is a DCG whose semantic
%% argument is the term, the way library(http) reads a request.
%%
%% THE LEXICON IS DATA AND POSITION IS THE DEFAULT. Nothing here declares
%% that `car' is a noun or `owns' a verb -- the last word of a noun phrase
%% is its noun, what precedes it is adjectives, the word after the subject
%% is the verb. reason_noun/1, reason_adj/1, reason_verb/2 and
%% reason_proper/2 are consulted first, and section 7 shows one saying a
%% word is not what its position suggests.
%%
%% FOUR DECISIONS YOU WILL MEET, each argued in reason.pl's header:
%% a verb comes back in its BASE form (`owns' -> own), so a positive and a
%% negative sentence name one predicate; an indefinite object is an
%% INDIVIDUAL in a fact (car_1, with car(car_1) beside it) and a CLASS atom
%% under negation or in a rule, because Prolog has no negative fact and no
%% existential in a head; `the server' is the constant `server'; and a
%% negative sentence is neg/1, a term you can store and query, never \+,
%% which is a question about provability and not a claim the text made.
%%
%% THE LIBRARY HAS A VERSION OF ITS OWN. Everything in this repository
%% -- this grammar, the translator, the tagger, the lexicon, the lessons --
%% moves a number that is not cocolog's: reason_version/1 answers it as an
%% atom and reason_version/3 as the three integers a program compares, and
%% section 18 shows both. A change to the library moves that number and
%% leaves `cocolog --version' alone.

:- use_module(library(reasoning/reason)).

main :-
    format("~n1. One sentence, one fact -- and the individual it introduces~n", []),
    reason_sentence('Alice owns a red car.', T1),
    must('Alice owns a red car', T1, [car(car_1), red(car_1), own(alice, car_1)]),
    reason_sentence('Alice likes Bob.', T1b),
    must('Alice likes Bob', T1b, [like(alice, bob)]),
    reason_sentence('Alice sleeps.', T1c),
    must('an intransitive verb', T1c, [sleep(alice)]),

    format("~n2. The copula: a property, a class, and their negations~n", []),
    reason_sentence('Alice is happy.', T2a),      must('is ADJ',      T2a, [happy(alice)]),
    reason_sentence('Alice is a person.', T2b),   must('is a NOUN',   T2b, [person(alice)]),
    reason_sentence('Alice is not happy.', T2c),  must('is not ADJ',  T2c, [neg(happy(alice))]),
    reason_sentence('Alice is not a robot.', T2d), must('is not a NOUN', T2d, [neg(robot(alice))]),

    format("~n3. A negative sentence with an indefinite object names the CLASS~n", []),
    reason_sentence('Bob does not own a car.', T3),
    must('does not own a car', T3, [neg(own(bob, car))]),
    show('   -- and not car(car_1): the sentence says no such car exists', ''),

    format("~n4. `every': a rule, and its variable stays a variable~n", []),
    reason_sentence('Every employee is a person.', [R4]),
    R4 = (H4 :- B4), H4 = person(X4), B4 = employee(Y4),
    ( X4 == Y4 -> Shared4 = yes ; Shared4 = no ),
    must('one variable through head and body', Shared4, yes),
    ( var(X4) -> Var4 = yes ; Var4 = no ),
    must('and it is still a variable, not employee_1', Var4, yes),
    reason_sentence('Every employee has a badge.', [R4b]),
    R4b = (have(_, Obj4b) :- employee(_)),
    must('an indefinite object in a rule is the class atom', Obj4b, badge),

    format("~n5. `that is [not] ADJ': a condition, and \\+ in the body~n", []),
    reason_sentence('Every employee that is authorized may access the server.', [R5a]),
    R5a = (may_access(X5a, server) :- employee(Y5a), authorized(Z5a)),
    ( X5a == Y5a, Y5a == Z5a -> S5a = yes ; S5a = no ),
    must('may access -> may_access/2, over one variable', S5a, yes),
    reason_sentence('Every employee that is not suspended may access the server.', [R5b]),
    R5b = (may_access(X5b, server) :- employee(Y5b), \+ suspended(Z5b)),
    ( X5b == Y5b, Y5b == Z5b -> S5b = yes ; S5b = no ),
    must('`that is not'' is \\+ in the body, over one variable', S5b, yes),

    format("~n6. The terms are what assertz/1 takes -- and then the rules RUN~n", []),
    reason_text('Alice is an employee. Alice is authorized. Bob is an employee. Bob is suspended. Every employee that is authorized may access the server. Every employee that is not suspended may access the server.', T6),
    length(T6, N6), must('six sentences, six terms', N6, 6),
    forall(member(T, T6), assertz(T)),
    findall(W, may_access(W, server), Ws6), sort(Ws6, Who6),
    must('who may access the server', Who6, [alice]),
    ( may_access(bob, server) -> Bob6 = yes ; Bob6 = no ),
    must('Bob is suspended and not authorized', Bob6, no),

    format("~n7. The lexicon overrides position~n", []),
    reason_sentence('Carol owns a car.', T7a),
    must('by default the verb is normalised', T7a, [car(car_1), own(carol, car_1)]),
    assertz(reason_verb(owns, owns)),
    reason_sentence('Carol owns a car.', T7b),
    must('reason_verb/2 keeps the surface form', T7b, [car(car_1), owns(carol, car_1)]),
    retract(reason_verb(owns, owns)),
    assertz(reason_proper(acme, acme_corp)),
    reason_sentence('Acme employs Dave.', T7c),
    must('reason_proper/2 names the constant', T7c, [employ(acme_corp, dave)]),
    retract(reason_proper(acme, acme_corp)),

    format("~n8. Across a paragraph the individuals are numbered in order -- and the subject is carried~n", []),
    reason_text('Priya is a baker. She is licensed.', P8s),
    must('`she'' is the subject of the last fact: the one coreference the reader does', P8s, [baker(priya), licensed(priya)]),
    reason_text('Alice owns a red car. Bob owns a car. Carol owns a dog.', T8),
    must('car_1, car_2, dog_1', T8,
         [car(car_1), red(car_1), own(alice, car_1),
          car(car_2), own(bob, car_2),
          dog(dog_1), own(carol, dog_1)]),
    reason_text('Alice owns a car.', [variables(true)], T8v),
    T8v = [car(V8), own(alice, W8)],
    ( var(V8), V8 == W8 -> Kept8 = yes ; Kept8 = no ),
    must('variables(true) keeps the individual a variable', Kept8, yes),

    format("~n9. What it refuses, and how: by failing~n", []),
    ( reason_sentence('She uses it.', _) -> P9a = parsed ; P9a = refused ),
    must('a pronoun object', P9a, refused),
    ( reason_text('Alice owns a car. She uses it.', _) -> P9b = parsed ; P9b = refused ),
    must('a paragraph half understood is refused whole', P9b, refused),
    ( reason_sentence('If an employee is authorized then it may access the server.', _)
    -> P9c = parsed ; P9c = refused ),
    must('if-then with a pronoun (write `that is'' instead)', P9c, refused),
    ( reason_sentence('Alice sleeps in Rome.', _) -> P9d = parsed ; P9d = refused ),
    must('a preposition after a bare verb -- refused: the two words are one relation, written sleeps_in', P9d, refused),
    reason_sentence('Alice owns a house near the river.', T9d2),
    must('a definite phrase after an object is a place, its class atom -- never misread as river(river_1)', T9d2,
         [house(house_1), own_near(alice, house_1, river)]),
    ( reason_sentence('Alice owns a house near a river.', _) -> P9d2i = parsed ; P9d2i = refused ),
    must('an indefinite one after an object is no place -- refused', P9d2i, refused),
    reason_sentence('Alice owns a house in Rome.', P9d3),
    must('but a PLACE after an object joins the relation: own_in/3, the place last', P9d3, [house(house_1), own_in(alice, house_1, rome)]),
    reason_sentence('Alice lives_in Rome.', P9d4),
    must('and a relation written joined stems its verb, so a fact and its denial agree', P9d4, [live_in(alice, rome)]),
    ( reason_sentence('Alice and Bob.', _) -> P9e = parsed ; P9e = refused ),
    must('a conjunction -- refused, never misread as and(alice, bob)', P9e, refused),

    format("~n10. The tokens, for a grammar of your own~n", []),
    reason_tokens('Hello, World. Alice_1!', Tk),
    must('word(Lower, Case), comma, stop', Tk,
         [word(hello, upper), ',', word(world, upper), '.', word(alice_1, upper), '.']),

    format("~n11. Which sentence was refused: reason_refused/2~n", []),
    ( reason_text('Alice owns a car. Every tenant must_pay rent.', _) -> W11 = parsed ; W11 = refused ),
    must('a bare noun object is not a shape it reads, so the text is refused', W11, refused),
    reason_refused('Alice owns a car. Every tenant must_pay rent.', R11),
    must('and this names the sentence to rewrite', R11, 'every tenant must_pay rent'),
    reason_text('Alice owns a car. Every tenant must pay the rent.', T11),
    length(T11, N11), must('written as `the rent'' it parses', N11, 3),

    format("~n12. truth/2: said, denied, never mentioned, contradicted~n", []),
    reason_text('Eve is a tenant. Eve is not exempt. Every tenant that is not exempt must pay the rent.', T12),
    forall(member(X12, T12), assertz(X12)),
    truth(must_pay(eve, rent), V12a),  must('proved through the rule', V12a, true),
    truth(exempt(eve), V12b),          must('the text denied it', V12b, false),
    truth(landlord(eve), V12c),        must('the text never said', V12c, unknown),
    truth(may_access(eve, server), V12d), must('nor did anything: no rule fires', V12d, unknown),
    assertz(reason_closed(may_access/2)),
    truth(may_access(eve, server), V12e), must('closed, the same silence is false', V12e, false),
    retract(reason_closed(may_access/2)),
    assertz(neg(tenant(eve))),
    truth(tenant(eve), V12f),          must('said and denied both: conflict', V12f, conflict),
    retract(neg(tenant(eve))),

    questions,
    quantities,
    explanation,
    topics,
    prose,
    version,
    format("~ndone~n", []).

%% section 13 is a clause of its own: a lesson's main/0 must still fit a
%% row of the knowledge base when it is consulted into one
questions :-
    format("~n13. A question is a GOAL -- a variable where `who' stood -- and the answer comes with its reason~n", []),
    reason_text('Priya is a baker. Priya is licensed. Every baker that is licensed may sell the bread. Priya rents a flat in Bristol. Marco does not pay the rent.', T13),
    forall(member(T, T13), assertz(T)),
    reason_question('Who may sell the bread?', Q13), show('the question, read', Q13),
    reason_ask('Who may sell the bread?', [A13a]), show('answered, each answer with the reason it rests on', A13a),
    reason_ask('May Priya sell the bread?', [A13b]),
    ( A13b = yes(rule(_)) -> Y13b = yes_by_a_rule ; Y13b = A13b ), must('yes, by a rule', Y13b, yes_by_a_rule),
    reason_ask('Does he pay the rent?', [A13c]),
    must('`he'' is Marco, the subject of the last fact the paragraph left; no, and the denial is the reason', A13c, no(denied(neg(pay(marco, rent))))),
    reason_ask('Is Priya licensed?', [A13d]), must('a fact: yes, and the fact is the reason', A13d, yes(fact)),
    reason_ask('Is Marco licensed?', [A13e]), must('never said: unknown', A13e, unknown),
    reason_ask('Where does Priya rent a flat?', [A13f]), must('where: the place is the answer', A13f, [bristol-fact]).

%% section 14: a quantity is a VALUE -- a number and the noun it counts,
%% quantity(N, Noun) -- never an individual, and `how much' asks for it
quantities :-
    format("~n14. Amounts and quantities: a number and its noun are one value, and `how much' asks for it~n", []),
    reason_text('Nadia pays 500 euros. Tariq owns three vineyards. Nadia buys two litres of milk. Omar pays the rent. The rent is 600 euros. Every grower must pay 500 euros. Omar is a grower.', T14),
    show('the paragraph, read', T14),
    T14 = [F14a, F14b, F14c, F14d, F14e|_],
    must('digits and a noun: quantity(N, Noun), the noun as written', F14a, pay(nadia, quantity(500, euros))),
    must('a number word: three vineyards, and no vineyard_1 -- three of them is not one', F14b, own(tariq, quantity(3, vineyards))),
    must('N UNIT of NOUN: quantity/3', F14c, buy(nadia, quantity(2, litres, milk))),
    must('`the rent'' as an object is the class atom', F14d, pay(omar, rent)),
    must('and `The rent is 600 euros'' is what that object costs: amount/2, the one definite subject the grammar reads', F14e, amount(rent, quantity(600, euros))),
    forall(member(T, T14), assertz(T)),
    reason_question('How much does Omar pay?', Q14), show('how much, read: the object through reason_amount/2', Q14),
    reason_ask('How much does Nadia pay?', [A14a]), must('how much Nadia pays: the quantity, and the fact', A14a, [quantity(500, euros)-fact]),
    reason_ask('How much does Omar pay?', [A14b]), must('how much Omar pays: 600 euros through the amount of the rent, not the word `rent''', A14b, [quantity(600, euros)-fact]),
    reason_ask('How much must Omar pay?', [[A14c-W14c]]),
    ( W14c = rule(_) -> Y14c = by_a_rule ; Y14c = W14c ), must('how much Omar must pay: by the rule over growers', A14c-Y14c, quantity(500, euros)-by_a_rule),
    reason_ask('How many vineyards does Tariq own?', [A14d]), must('how many: the number', A14d, [3-fact]),
    reason_ask('How many litres does Nadia buy?', [A14e]), must('how many, over a quantity with an `of'' part', A14e, [2-fact]),
    reason_ask('Does Nadia pay 500 euros?', [A14f]), must('a yes-or-no question over a quantity', A14f, yes(fact)),
    reason_ask('Is the rent 600 euros?', [A14g]), must('and over an amount', A14g, yes(fact)),
    ( reason_sentence('Nadia owns three red cars.', _) -> R14 = read ; R14 = refused ),
    must('an adjective inside a quantity is refused, not dropped', R14, refused).

%% section 15: an EXPLANATION is the whole proof, in sentences. A chess
%% position: the black king on h8 behind its own pawns on g7 and h7, and a
%% white rook has arrived on e8. Check and mate are three rules of the
%% controlled English; what the English cannot say -- a rule over two
%% variables, a universal (`no square the king may move to is safe') -- is
%% four Prolog clauses asserted beside it, and the explanation walks both
%% alike
explanation :-
    format("~n15. Why is the king checkmated? The explanation is the proof, every level of it, in sentences~n", []),
    reason_text('Kh8 is a king. Kh8 is black. Kh8 occupies H8. Re8 is a rook. Re8 is white. Re8 occupies E8. Re8 attacks F8. Re8 attacks G8. Re8 attacks H8. Pg7 is a pawn. Pg7 is black. Pg7 occupies G7. Pg7 attacks F6. Pg7 attacks H6. Ph7 is a pawn. Ph7 is black. Ph7 occupies H7. Ph7 attacks G6. G8 is a square. G7 is a square. H7 is a square. Kh8 may move_to G8. Kh8 may move_to G7. Kh8 may move_to H7. Every square that is attacked is unsafe. Every square that is occupied is unsafe. Every king that is attacked is a target. Every target that is immobile is a captive. Every captive that is not defended is checkmated.', T15),
    forall(member(T, T15), assertz(T)),
    assertz(( attacked(X) :- attack(_, X) )),                                          % a square somebody attacks
    assertz(( attacked(P) :- occupy(P, S), attack(_, S) )),                            % a piece on such a square
    assertz(( occupied(S) :- occupy(_, S) )),
    assertz(( immobile(K) :- king(K), \+ ( may_move_to(K, S), \+ unsafe(S) ) )),       % every square it may move to is unsafe
    assertz(( defended(K) :- occupy(K, S), attack(A, S), occupy(A, T), attack(D, T), black(D) )),   % a black piece attacks the attacker
    reason_ask('Is Kh8 checkmated?', [A15a]), show('asked, one level', A15a),
    reason_ask('Why is Kh8 checkmated?', [because(E15)]),
    format("   why = ~w~n", [E15]),
    must('every level of the proof, in sentences', E15,
         'Kh8 is checkmated because Kh8 is a captive and nothing shows that Kh8 is defended. Kh8 is a captive because Kh8 is a target and Kh8 is immobile. Kh8 is a target because Kh8 is a king and Kh8 is attacked. Kh8 is attacked because Kh8 occupies H8 and Re8 attacks H8. Kh8 is immobile because Kh8 is a king and whenever Kh8 may move to X, X is unsafe (X: G8, G7 and H7). G8 is unsafe because G8 is a square and G8 is attacked. G8 is attacked because Re8 attacks G8. G7 is unsafe because G7 is a square and G7 is occupied. G7 is occupied because Pg7 occupies G7. H7 is unsafe because H7 is a square and H7 is occupied. H7 is occupied because Ph7 occupies H7.'),
    reason_ask('Why is G7 unsafe?', [because(E15b)]), must('why, two levels down', E15b, 'G7 is unsafe because G7 is a square and G7 is occupied. G7 is occupied because Pg7 occupies G7.'),
    reason_ask('Is Kh8 defended?', [A15c], [X15c]), must('nothing shows it', A15c, unknown), must('and the explanation says so', X15c, 'Nothing shows that Kh8 is defended.'),
    reason_explain(unsafe(g8), W15), show('the proof as a term, reason_explain/2', W15),
    reason_ask('Why does Omar pay the rent?', [because(E15d)]), must('a fact: as said', E15d, 'Omar pays the rent, as said.').

%% section 16: what a text is ABOUT -- the concepts it mentions, ranked,
%% and an outline by topic with the sub-topics under each; the chess
%% position of section 15 is what the knowledge base holds now
topics :-
    format("~n16. Concepts and topics: what the text is about, and an outline of it~n", []),
    findall(T, ( member(P/A, [king/1, black/1, occupy/2, rook/1, white/1, attack/2, pawn/1, square/1, may_move_to/2]),
                 functor(T, P, A), clause(T, true) ), Facts),
    findall((H :- B), ( member(P, [unsafe, target, captive, checkmated]), functor(H, P, 1), clause(H, B), B \== true ), Rules),
    append(Facts, Rules, Terms),
    reason_concepts(Terms, Cs), Cs = [C1, C2, C3|_],
    show('the three most mentioned concepts', [C1, C2, C3]),
    must('the text is about Kh8 first: six mentions, a name', C1, concept(kh8, name, 6)),
    reason_topics(Terms, Topics), Topics = [T1|_],
    show('the first topic, with its sub-topics', T1),
    reason_topic_lines(Topics, Lines),
    forall(member(L, Lines), format("   | ~w~n", [L])),
    Lines = [L1|_],
    must('the outline begins with the king', L1, 'Kh8, a king: black; occupies H8; may move to G8, G7 and H7.'),
    ( memberchk('Unsafe: a square that is attacked; a square that is occupied.', Lines) -> D16 = yes ; D16 = no ),
    must('and a property a rule defines is a topic with its definitions', D16, yes),
    reason_outline('Nadia is a grower. Nadia owns three vineyards. Nadia pays 500 euros to Omar. Every grower that is registered may export the wine.', L16),
    show('a paragraph outlined', L16).

%% section 17: OPTIONAL -- the shipped tagger reads typed prose, where
%% library(torch) and model.rows are there
prose :-
    format("~n17. Typed prose, through the shipped tagger -- optional, and loaded on first use~n", []),
    (   catch(reason_prose('Well, Rex really owns a red truck, obviously. Kim rents a flat in Oslo and is insured.', T14),
              error(existence_error(tagger, pretrained), _), fail)
    ->  show('the prose, read', T14),
        forall(member(T, T14), assertz(T)),
        reason_ask_prose('Is she insured?', [A14]),
        must('and a typed question, `she'' being Kim', A14, yes(fact))
    ;   format("   (no shipped tagger here: library(torch) and model.rows -- the grammar above needs neither)~n", [])
    ).

%% section 18: the library's own version. The lesson pins its SHAPE -- three
%% integers and the atom they make -- and never the number: a commit that
%% changes this library moves it, and a lesson must not need to move
%% with it.
version :-
    format("~n18. The library's own version -- a number of its own, not cocolog's~n", []),
    reason_version(Ma, Mi, Pa),
    reason_version(V),
    show('the version, as the atom a person reads', V),
    show('and as the three integers a program compares', [Ma, Mi, Pa]),
    ( integer(Ma), integer(Mi), integer(Pa) -> D18a = yes ; D18a = no ),
    must('three integers', D18a, yes),
    atomic_list_concat([Ma, Mi, Pa], '.', Joined),
    must('and the atom is those three joined by dots', V, Joined),
    ( '1.10.0' @< '1.9.0' -> D18b = yes ; D18b = no ),
    must('as atoms 1.10.0 sorts BEFORE 1.9.0, so a program does not compare the atom', D18b, yes),
    ( [1, 10, 0] @> [1, 9, 0] -> D18c = yes ; D18c = no ),
    must('as lists of integers it sorts after, which is what [Major, Minor, Patch] is for', D18c, yes).

%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
