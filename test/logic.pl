%% library(reasoning/logic) -- level 2 of the translator: the logic form made
%% from the typology IR (TRANSLATOR-PLAN.md).
%%
%%     cocolog -s test/logic.pl        from this repository's root

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

main :-
    forall(member(L, [english, spanish, italian]), typology_load(L)),
    forall(member(S, [milestone, constants, generic, joined, diagnostics, languages,
                      code_write, code_read, code_round_trip,
                      code_english, code_general, round_trips, measure, tenses,
                      adjuncts]), once(S)),
    checks_done.

%% The seven sentences of the first milestone, each its logic forms in order.
milestone :-
    section('the milestone: seven sentences into the logic form'),
    X = var(1),
    forall(member(T-Want, [
               'Socrates is human.'-[utterance(assertion, [fact(pred(human, [const(socrates)]))])],
               'Every human is mortal.'-[utterance(assertion, [rule(pred(mortal, [X]), pred(human, [X]))])],
               'Something is mortal if it is human.'-[utterance(assertion, [rule(pred(mortal, [X]), pred(human, [X]))])],
               'Who is human?'-[utterance(question, [query(pred(human, [X]))])],
               'Is Socrates human?'-[utterance(question, [query(pred(human, [const(socrates)]))])],
               'A person likes music.'-[utterance(assertion, [rule(pred(like, [X, const(music)]), pred(person, [X]))]),
                                        utterance(assertion, [fact(pred(person, [const(a_person)])),
                                                              fact(pred(like, [const(a_person), const(music)]))])],
               'A person is happy if they are healthy and safe.'-
                   [utterance(assertion, [rule(pred(happy, [X]), and([pred(person, [X]), pred(healthy, [X]), pred(safe, [X])]))])] ]),
           ( logic_readings(english, T, Us),
             atomic_list_concat(['English: ', T], Label),
             check(Label, Us, Want) )).

%% A name, a definite noun phrase and a bare noun are constants; a statement
%% of constants is its facts.
constants :-
    section('constants and facts'),
    forall(member(T-Want, [
               'John sees the dog.'-[fact(pred(see, [const(john), const(the_dog)]))],
               'John Smith sleeps.'-[fact(pred(sleep, [const(john_smith)]))],
               'The small dog sleeps.'-[fact(pred(sleep, [const(the_small_dog)]))],
               'Socrates is a wise man.'-[fact(pred(man, [const(socrates)])), fact(pred(wise, [const(socrates)]))],
               'Helium is monatomic.'-[fact(pred(monatomic, [const(helium)]))],
               'Socrates is happy if Plato is happy.'-[rule(pred(happy, [const(socrates)]), pred(happy, [const(plato)]))] ]),
           ( logic_readings(english, T, Us),
             atomic_list_concat(['English: ', T], Label),
             check(Label, Us, [utterance(assertion, Want)]) )).

%% Every, each and all make a rule; something is one individual; everything
%% a fact of a variable.
generic :-
    section('rules and individuals'),
    X = var(1),
    forall(member(T-Want, [
               'All dogs sleep.'-[utterance(assertion, [rule(pred(sleep, [X]), pred(dog, [X]))])],
               'Each small dog sleeps.'-[utterance(assertion, [rule(pred(sleep, [X]), and([pred(dog, [X]), pred(small, [X])]))])],
               'Something is mortal.'-[utterance(assertion, [fact(pred(mortal, [const(something)]))])],
               'Everything is mortal.'-[utterance(assertion, [fact(pred(mortal, [X]))])],
               'Every human is mortal and wise.'-[utterance(assertion, [rule(pred(mortal, [X]), pred(human, [X])),
                                                                         rule(pred(wise, [X]), pred(human, [X]))])] ]),
           ( logic_readings(english, T, Us),
             atomic_list_concat(['English: ', T], Label),
             check(Label, Us, Want) )).

%% A joined subject or object is a clause of each item; two clauses are the
%% items of each; the second one's same subject is the first's.
joined :-
    section('joined phrases and clauses'),
    forall(member(T-Want, [
               'John and Mary sleep.'-[fact(pred(sleep, [const(john)])), fact(pred(sleep, [const(mary)]))],
               'John sees the dog and the cat.'-[fact(pred(see, [const(john), const(the_dog)])), fact(pred(see, [const(john), const(the_cat)]))],
               'The boy sleeps and the girl sleeps.'-[fact(pred(sleep, [const(the_boy)])), fact(pred(sleep, [const(the_girl)]))],
               'The boy sleeps and sees the dog.'-[fact(pred(sleep, [const(the_boy)])), fact(pred(see, [const(the_boy), const(the_dog)]))] ]),
           ( logic_readings(english, T, Us),
             atomic_list_concat(['English: ', T], Label),
             check(Label, Us, [utterance(assertion, Want)]) )).

%% What has no logic form yet says why.
diagnostics :-
    section('what has no logic form yet'),
    forall(member(T-Want, [
               'The boy would see the dog.'-tense(conditional),
               'The boy does not sleep.'-negation,
               'Every boy sees a dog.'-object(generic),
               'The boy sleeps because the dog sleeps.'-subordinate(because),
               'He sleeps.'-pronoun,
               'No dog sleeps.'-determiner(no),
               'The boy sleeps with dogs.'-adjunct(generic) ]),
           ( once(typology_read(english, T, IR)),
             ( logic_from_ir(IR, _) -> W = read ; logic_why(IR, W) ),
             atomic_list_concat(['English: ', T], Label),
             check(Label, W, Want) )).

%% The logic form is the same for every language: the rules ask the
%% typology IR alone.
languages :-
    section('every language its logic form'),
    X = var(1),
    forall(member(L-T-Want, [
               spanish-'Cada perro duerme.'-utterance(assertion, [rule(pred(sleep, [X]), pred(dog, [X]))]),
               italian-'Tutti i cani dormono.'-utterance(assertion, [rule(pred(sleep, [X]), pred(dog, [X]))]),
               spanish-'Juan ve al perro.'-utterance(assertion, [fact(pred(see, [const(juan), const(the_dog)]))]) ]),
           ( logic_readings(L, T, [U|_]),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, U, Want) )).

%% 1.67.0: the Cocolog template. The logic form written as Cocolog source,
%% and read back to the same form.
code_write :-
    section('English into Cocolog'),
    forall(member(T-Want, [
               'Socrates is human.'-'human(socrates).\n',
               'Every human is mortal.'-'mortal(A) :-\n    human(A).\n',
               'Who is human?'-'?- human(A).\n',
               'Is Socrates human?'-'?- human(socrates).\n',
               'A person is happy if they are healthy and safe.'-'happy(A) :-\n    person(A),\n    healthy(A),\n    safe(A).\n',
               'John and Mary sleep.'-'is_sleep(john).\nis_sleep(mary).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['English into Cocolog: ', T], Label),
             check(Label, C, Want) )).

code_read :-
    section('Cocolog into the logic form'),
    X = var(1),
    forall(member(C-Want, [
               'mortal(X) :- human(X).'-utterance(assertion, [rule(pred(mortal, [X]), pred(human, [X]))]),
               'human(socrates).\nmortal(Y) :- human(Y), wise(Y).'-
                   utterance(assertion, [fact(pred(human, [const(socrates)])),
                                         rule(pred(mortal, [X]), and([pred(human, [X]), pred(wise, [X])]))]),
               '?- mortal(Who).'-utterance(question, [query(pred(mortal, [X]))]),
               '% a comment.\nis_sleep(john).'-utterance(assertion, [fact(pred(sleep, [const(john)]))]),
               'size(\'a.b\', 3). is_happy(john).'-utterance(assertion, [fact(pred(size, [const('a.b'), num(3)])),
                                                                         fact(pred(is_happy, [const(john)]))]) ]),
           ( ( cocolog_read(C, U) -> true ; U = none ),
             one_line(['Cocolog: ', C], Label),
             check(Label, U, Want) )),
    ( catch(cocolog_read('human(socrates', _), E, true) -> true ; E = failed ),
    check('a text that is no clause says so', E, lg_no(syntax('human(socrates'))).

%% Cocolog into the logic form and back is the same source; a program made
%% from English runs.
code_round_trip :-
    section('the round trips, and a program that runs'),
    forall(member(C, ['human(socrates).\n', 'mortal(A) :-\n    human(A).\n', '?- human(A).\n',
                      'like(A, music) :-\n    person(A).\n', 'is_sleep(john).\n']),
           ( ( cocolog_read(C, U), cocolog_write(U, C2) -> true ; C2 = none ),
             one_line(['Cocolog, read and written: ', C], Label),
             check(Label, C2, C) )),
    forall(member(T, ['Every human is mortal.', 'A person is happy if they are healthy and safe.', 'Who is human?']),
           ( logic_readings(english, T, [U3|_]),
             ( cocolog_write(U3, C3), cocolog_read(C3, U4) -> true ; U4 = none ),
             atomic_list_concat(['English, Cocolog and back: ', T], Label3),
             ( U4 =@= U3 -> R3 = same ; R3 = U4 ),
             check(Label3, R3, same) )),
    findall(C5, ( member(T5, ['Socrates is human.', 'Every human is mortal.']),
                  logic_translate(english, cocolog, T5, C5) ), C5s),
    atomic_list_concat(C5s, Program),
    cocolog_read(Program, utterance(_, Items)),
    cocolog_write(utterance(assertion, Items), Text6),
    logic_test_assert(Text6),
    logic_translate(english, cocolog, 'Is Socrates mortal?', Q7),
    sub_atom(Q7, 3, _, 2, G7), term_string(Goal7, G7),
    ( call(Goal7) -> R7 = proved ; R7 = failed ),
    check('the program from English proves Is Socrates mortal?', R7, proved).

%% The clauses of a Cocolog text asserted (a test's own predicates, mortal/1
%% and human/1, which nothing else here defines).
logic_test_assert(Text) :-
    atomic_list_concat(Parts, '.\n', Text),
    forall(( member(P, Parts), P \== '' ), ( term_string(T, P), assertz(T) )).

%% A label on one line: each newline of the text written as a space.
one_line(Parts, Label) :-
    atomic_list_concat(Parts, Text),
    atomic_list_concat(Lines, '\n', Text),
    atomic_list_concat(Lines, ' ', Label).

%% 1.68.0: Cocolog into English. The logic form through level 1 to a
%% sentence that reads back to it, else a general sentence.
code_english :-
    section('Cocolog into English'),
    forall(member(C-Want, [
               'human(socrates).'-'Socrates is human.',
               'mortal(X) :- human(X).'-'Every human is mortal.',
               '?- human(X).'-'Who is human?',
               '?- human(socrates).'-'Is Socrates human?',
               'happy(X) :- person(X), healthy(X), safe(X).'-'A person is happy if they are healthy and safe.',
               'like(X, music) :- person(X).'-'Every person likes music.',
               'see(john, the_dog).'-'John sees the dog.',
               'like(mary, john).'-'Mary likes John.',
               'is_sleep(john).'-'John sleeps.',
               'man(socrates).'-'Socrates is a man.',
               'is_sleep(X) :- dog(X).'-'Every dog sleeps.',
               'is_sleep(the_big_dog).'-'The big dog sleeps.',
               'mortal(something).'-'Something is mortal.',
               'mortal(X).'-'Everything is mortal.',
               '?- see(X, the_dog).'-'Who sees the dog?',
               'human(socrates). mortal(X) :- human(X).'-'Socrates is human. Every human is mortal.' ]),
           ( ( logic_translate(cocolog, english, C, T) -> true ; T = none ),
             atomic_list_concat(['Cocolog into English: ', C], Label),
             check(Label, T, Want) )),
    ( logic_translate(cocolog, spanish, 'mortal(X) :- human(X).', T2) -> true ; T2 = none ),
    check('Cocolog into Spanish: mortal(X) :- human(X).', T2, 'Cada humano es mortal.'),
    ( logic_write(english, utterance(assertion, [fact(pred(person, [const(a_person)])),
                                                 fact(pred(like, [const(a_person), const(music)]))]), T3) -> true ; T3 = none ),
    check('one individual\'s facts are one sentence', T3, 'A person likes music.').

%% What no level-1 IR says is a general sentence: a predicate that is no
%% word, a body that is no adjective, a query of two variables or atoms.
code_general :-
    section('the general sentence'),
    forall(member(C-Want, [
               'append(a, b, c).'-'Append holds for a, b and c.',
               'size(the_box, 3).'-'Size holds for the_box and 3.',
               'happy(X) :- dog(X), fed(X).'-'Happy holds for X if dog holds for X and fed holds for X.',
               '?- like(X, Y).'-'For which X and Y does it hold that like holds for X and Y?',
               '?- human(socrates), mortal(socrates).'-'Does it hold that human holds for socrates and mortal holds for socrates?',
               'name(t, "Ann").'-'Name holds for t and [65, 110, 110].',
               'size([a, b], 2).'-'Size holds for [a, b] and 2.' ]),
           ( ( logic_translate(cocolog, english, C, T) -> true ; T = none ),
             atomic_list_concat(['a general sentence: ', C], Label),
             check(Label, T, Want) )),
    assertz(logic:lg_code_class(cocolog, mortal/1, noun)),
    ( logic_translate(cocolog, english, 'mortal(socrates).', T4) -> true ; T4 = none ),
    retractall(logic:lg_code_class(cocolog, mortal/1, _)),
    check('a template row gives the word class', T4, 'Socrates is a mortal.').

%% THE ROUND TRIPS keep the logic form: English, Cocolog and English again
%% reads to the same form; Cocolog, English and Cocolog again is the same
%% source.
round_trips :-
    section('the round trips through English'),
    forall(member(T, ['Socrates is human.', 'Every human is mortal.', 'Who is human?', 'Is Socrates human?',
                      'Something is mortal if it is human.', 'A person is happy if they are healthy and safe.',
                      'A person likes music.', 'John sees the dog.', 'John sleeps.', 'Dogs sleep.']),
           ( logic_readings(english, T, [U|_]),
             ( cocolog_write(U, C), cocolog_read(C, U2), logic_write(english, U2, T2),
               logic_readings(english, T2, Us), memberchk(U, Us) -> R = kept ; R = lost ),
             atomic_list_concat(['English, Cocolog, English: ', T], Label),
             check(Label, R, kept) )),
    forall(member(C, ['human(socrates).\n', 'mortal(A) :-\n    human(A).\n', '?- human(A).\n',
                      'is_sleep(john).\n', 'see(mary, the_dog).\n', 'like(A, music) :-\n    person(A).\n']),
           ( ( logic_translate(cocolog, english, C, E), logic_translate(english, cocolog, E, C2) -> true ; C2 = none ),
             one_line(['Cocolog, English, Cocolog: ', C], Label),
             check(Label, C2, C) )).

%% 1.69.0: THE SECOND MEASURE holds its counts: lexicon/logic.txt's
%% sentences, how many give the Cocolog written beside them, and how many
%% of those Cocolog texts come back as English that reads to them.
measure :-
    section('the second measure'),
    logic_measure(english, ['Socrates is human.'-'human(socrates).',
                            'Tweety is a bird.'-'bird(tweety).',
                            'Who is human?'-'?- human(Who).'],
                  measure(N1, R1, A1, K1, G1, Ms1, Us1)),
    check('a measure of three: its counts', c(N1, R1, A1, K1, G1), c(3, 2, 0, 2, 1)),
    check('a measure of three: the miss', Ms1, [miss('Tweety is a bird.', unread)]),
    check('a measure of three: the Cocolog not kept', Us1, [unkept('bird(tweety).', 'Bird holds for tweety.')]),
    absolute_file_name(library(reasoning/'lexicon/logic.txt'), F, [access(read)]),
    logic_measure_cases(F, Cases),
    logic_measure(english, Cases, measure(N, R, _, K, _, _, _)),
    check('the second measure: its sentences', N, 132),
    ( R >= 116 -> VR = ok ; VR = R ),
    check('the second measure: English into Cocolog, at least 116 right', VR, ok),
    ( K >= 124 -> VK = ok ; VK = K ),
    check('the second measure: Cocolog into English and back, at least 124 kept', VK, ok).

%% 1.70.0: A TENSE other than the present is said of each atom its clause
%% says, at(Tense, Atom), never of a subject's noun, and Cocolog writes it
%% Tense(Atom).
tenses :-
    section('the tenses'),
    forall(member(T-Want, [
               'John slept.'-'past(is_sleep(john)).\n',
               'Every man was happy.'-'past(happy(A)) :-\n    man(A).\n',
               'Who saw the dog?'-'?- past(see(A, the_dog)).\n',
               'John will sleep.'-'future(is_sleep(john)).\n',
               'Mary has seen the dog.'-'perfect(see(mary, the_dog)).\n',
               'The boy had seen the dog.'-'pluperfect(see(the_boy, the_dog)).\n',
               'A dog barked.'-'dog(a_dog).\npast(bark(a_dog)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a tense into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    logic_readings(english, 'A person was happy if they were safe.', [U1]),
    check('a tense in an if clause', U1,
          utterance(assertion, [rule(at(past, pred(happy, [var(1)])),
                                     and([pred(person, [var(1)]), at(past, pred(safe, [var(1)]))]))])),
    logic_readings(english, 'A dog barked.', Us2),
    length(Us2, N2),
    ( Us2 = [utterance(_, [fact(_)|_])|_] -> F2 = facts ; F2 = rules ),
    check('an indefinite subject in a tense: one individual first', N2-F2, 2-facts),
    forall(member(C3-Want3, ['past(is_sleep(john)).'-'John slept.',
                             'past(happy(X)) :- man(X).'-'Every man was happy.',
                             '?- past(see(john, the_dog)).'-'Did John see the dog?',
                             'future(is_sleep(john)).'-'John will sleep.',
                             'past(bark(X)) :- dog(X).'-'Every dog barked.']),
           ( ( logic_translate(cocolog, english, C3, E3) -> true ; E3 = none ),
             atomic_list_concat(['a tense into English: ', C3], L3),
             check(L3, E3, Want3) )),
    ( logic_translate(cocolog, spanish, 'past(is_sleep(john)).', S4) -> true ; S4 = none ),
    check('a tense into Spanish', S4, 'John durmió.'),
    ( logic_translate(cocolog, english, 'past(append(a, b, c)).', E5) -> true ; E5 = none ),
    check('a tense in a general sentence', E5, 'Append holds for a, b and c in the past.'),
    ( cocolog_read('past(the_war).', U6) -> true ; U6 = none ),
    check('a tense\'s name before no compound term is a predicate', U6,
          utterance(assertion, [fact(pred(past, [const(the_war)]))])),
    once(typology_read(english, 'John would sleep.', IR7)),
    logic_why(IR7, W7),
    check('the conditional has no logic form yet', W7, tense(conditional)).

%% 1.71.0: AN ADJUNCT is said of each atom its clause says, inside the
%% tense, the first adjunct the innermost; an adposition phrase as a
%% copula's predicate is a predicate of two.
adjuncts :-
    section('the adjuncts'),
    forall(member(T-Want, [
               'John sleeps in the garden.'-'in(is_sleep(john), the_garden).\n',
               'Mary runs quickly.'-'quickly(run(mary)).\n',
               'John walked to the house.'-'past(to(walk(john), the_house)).\n',
               'The dog ran quickly to the house.'-'past(to(quickly(run(the_dog)), the_house)).\n',
               'Every dog sleeps in the house.'-'in(is_sleep(A), the_house) :-\n    dog(A).\n',
               'Who sleeps in the garden?'-'?- in(is_sleep(A), the_garden).\n',
               'The book is on the table.'-'on(the_book, the_table).\n',
               'John is with Mary.'-'with(john, mary).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['an adjunct into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    logic_readings(english, 'The dog ran quickly to the house.', [U1|_]),
    check('the adjuncts inside the tense, the first the innermost', U1,
          utterance(assertion, [fact(at(past, modified(pp(to, const(the_house)),
                                                     modified(adv(quickly), pred(run, [const(the_dog)])))))])),
    forall(member(C2-Want2, ['in(is_sleep(john), the_garden).'-'John sleeps in the garden.',
                             'past(to(quickly(run(the_dog)), the_house)).'-'The dog ran quickly to the house.',
                             'quietly(slowly(sing(mary))).'-'Mary sings slowly and quietly.',
                             'on(the_book, the_table).'-'The book is on the table.',
                             '?- in(is_sleep(X), the_garden).'-'Who sleeps in the garden?']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['an adjunct into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'in(live(john), paris).', S3) -> true ; S3 = none ),
    check('an adjunct into Spanish', S3, 'John vive en Paris.'),
    ( logic_translate(cocolog, english, 'in(append(a, b, c), the_box).', E4) -> true ; E4 = none ),
    check('an adjunct in a general sentence', E4, 'Append holds for a, b and c in the_box.'),
    ( cocolog_read('size([a, b], 2).', U5) -> true ; U5 = none ),
    check('a list is no adjunct\'s atom', U5,
          utterance(assertion, [fact(pred(size, [list([const(a), const(b)]), num(2)]))])),
    once(typology_read(english, 'John sleeps with dogs.', IR6)),
    logic_why(IR6, W6),
    check('an adjunct\'s noun phrase that is no constant', W6, adjunct(generic)).
