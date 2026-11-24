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
                      adjuncts, pronouns, possessors, objects, plurals, terms, individuals]), once(S)),
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
                                        utterance(assertion, [fact(pred(person, [const(a(person))])),
                                                              fact(pred(like, [const(a(person)), const(music)]))])],
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
               'John sees the dog.'-[fact(pred(see, [const(john), const(the(dog))]))],
               'John Smith sleeps.'-[fact(pred(sleep, [const(john_smith)]))],
               'The small dog sleeps.'-[fact(pred(sleep, [const(the(small(dog)))]))],
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
               'John sees the dog and the cat.'-[fact(pred(see, [const(john), const(the(dog))])), fact(pred(see, [const(john), const(the(cat))]))],
               'The boy sleeps and the girl sleeps.'-[fact(pred(sleep, [const(the(boy))])), fact(pred(sleep, [const(the(girl))]))],
               'The boy sleeps and sees the dog.'-[fact(pred(sleep, [const(the(boy))])), fact(pred(see, [const(the(boy)), const(the(dog))]))] ]),
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
               'He received this letter.'-determiner(this),
               'No dog sleeps.'-determiner(no),
               'The boy sleeps with every dog.'-adjunct(every),
               'Lilies of the valley are racemose.'-possessor(generic) ]),
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
               spanish-'Juan ve al perro.'-utterance(assertion, [fact(pred(see, [const(juan), const(the(dog))]))]) ]),
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
               'see(john, the(dog)).'-'John sees the dog.',
               'like(mary, john).'-'Mary likes John.',
               'is_sleep(john).'-'John sleeps.',
               'man(socrates).'-'Socrates is a man.',
               'is_sleep(X) :- dog(X).'-'Every dog sleeps.',
               'is_sleep(the(big(dog))).'-'The big dog sleeps.',
               'mortal(something).'-'Something is mortal.',
               'mortal(X).'-'Everything is mortal.',
               '?- see(X, the(dog)).'-'Who sees the dog?',
               'human(socrates). mortal(X) :- human(X).'-'Socrates is human. Every human is mortal.' ]),
           ( ( logic_translate(cocolog, english, C, T) -> true ; T = none ),
             atomic_list_concat(['Cocolog into English: ', C], Label),
             check(Label, T, Want) )),
    ( logic_translate(cocolog, spanish, 'mortal(X) :- human(X).', T2) -> true ; T2 = none ),
    check('Cocolog into Spanish: mortal(X) :- human(X).', T2, 'Cada humano es mortal.'),
    ( logic_write(english, utterance(assertion, [fact(pred(person, [const(a(person))])),
                                                 fact(pred(like, [const(a(person)), const(music)]))]), T3) -> true ; T3 = none ),
    check('one individual\'s facts are one sentence', T3, 'A person likes music.').

%% What no level-1 IR says is a general sentence: a predicate that is no
%% word, a body that is no adjective, a query of two variables or atoms.
code_general :-
    section('the general sentence'),
    forall(member(C-Want, [
               'append(a, b, c).'-'Append holds for a, b and c.',
               'size(the(box), 3).'-'Size holds for the(box) and 3.',
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
                      'is_sleep(john).\n', 'see(mary, the(dog)).\n', 'like(A, music) :-\n    person(A).\n']),
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
    check('the second measure: its sentences', N, 179),
    ( R >= 163 -> VR = ok ; VR = R ),
    check('the second measure: English into Cocolog, at least 163 right', VR, ok),
    ( K >= 171 -> VK = ok ; VK = K ),
    check('the second measure: Cocolog into English and back, at least 171 kept', VK, ok).

%% 1.70.0: A TENSE other than the present is said of each atom its clause
%% says, at(Tense, Atom), never of a subject's noun, and Cocolog writes it
%% Tense(Atom).
tenses :-
    section('the tenses'),
    forall(member(T-Want, [
               'John slept.'-'past(is_sleep(john)).\n',
               'Every man was happy.'-'past(happy(A)) :-\n    man(A).\n',
               'Who saw the dog?'-'?- past(see(A, the(dog))).\n',
               'John will sleep.'-'future(is_sleep(john)).\n',
               'Mary has seen the dog.'-'perfect(see(mary, the(dog))).\n',
               'The boy had seen the dog.'-'pluperfect(see(the(boy), the(dog))).\n',
               'A dog barked.'-'dog(a(dog)).\npast(bark(a(dog))).\n' ]),
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
                             '?- past(see(john, the(dog))).'-'Did John see the dog?',
                             'future(is_sleep(john)).'-'John will sleep.',
                             'past(bark(X)) :- dog(X).'-'Every dog barked.']),
           ( ( logic_translate(cocolog, english, C3, E3) -> true ; E3 = none ),
             atomic_list_concat(['a tense into English: ', C3], L3),
             check(L3, E3, Want3) )),
    ( logic_translate(cocolog, spanish, 'past(is_sleep(john)).', S4) -> true ; S4 = none ),
    check('a tense into Spanish', S4, 'John durmió.'),
    ( logic_translate(cocolog, english, 'past(append(a, b, c)).', E5) -> true ; E5 = none ),
    check('a tense in a general sentence', E5, 'Append holds for a, b and c in the past.'),
    ( cocolog_read('past(the(war)).', U6) -> true ; U6 = none ),
    check('a tense\'s name before no compound term is a predicate', U6,
          utterance(assertion, [fact(pred(past, [const(the(war))]))])),
    once(typology_read(english, 'John would sleep.', IR7)),
    logic_why(IR7, W7),
    check('the conditional has no logic form yet', W7, tense(conditional)).

%% 1.71.0: AN ADJUNCT is said of each atom its clause says, inside the
%% tense, the first adjunct the innermost; an adposition phrase as a
%% copula's predicate is a predicate of two.
adjuncts :-
    section('the adjuncts'),
    forall(member(T-Want, [
               'John sleeps in the garden.'-'in(is_sleep(john), the(garden)).\n',
               'Mary runs quickly.'-'quickly(run(mary)).\n',
               'John walked to the house.'-'past(to(walk(john), the(house))).\n',
               'The dog ran quickly to the house.'-'past(to(quickly(run(the(dog))), the(house))).\n',
               'Every dog sleeps in the house.'-'in(is_sleep(A), the(house)) :-\n    dog(A).\n',
               'Who sleeps in the garden?'-'?- in(is_sleep(A), the(garden)).\n',
               'The book is on the table.'-'on(the(book), the(table)).\n',
               'John is with Mary.'-'with(john, mary).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['an adjunct into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    logic_readings(english, 'The dog ran quickly to the house.', [U1|_]),
    check('the adjuncts inside the tense, the first the innermost', U1,
          utterance(assertion, [fact(at(past, modified(pp(to, const(the(house))),
                                                     modified(adv(quickly), pred(run, [const(the(dog))])))))])),
    forall(member(C2-Want2, ['in(is_sleep(john), the(garden)).'-'John sleeps in the garden.',
                             'past(to(quickly(run(the(dog))), the(house))).'-'The dog ran quickly to the house.',
                             'quietly(slowly(sing(mary))).'-'Mary sings slowly and quietly.',
                             'on(the(book), the(table)).'-'The book is on the table.',
                             '?- in(is_sleep(X), the(garden)).'-'Who sleeps in the garden?']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['an adjunct into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'in(live(john), paris).', S3) -> true ; S3 = none ),
    check('an adjunct into Spanish', S3, 'John vive en Paris.'),
    ( logic_translate(cocolog, english, 'in(append(a, b, c), the(box)).', E4) -> true ; E4 = none ),
    check('an adjunct in a general sentence', E4, 'Append holds for a, b and c in the(box).'),
    ( cocolog_read('size([a, b], 2).', U5) -> true ; U5 = none ),
    check('a list is no adjunct\'s atom', U5,
          utterance(assertion, [fact(pred(size, [list([const(a), const(b)]), num(2)]))])),
    once(typology_read(english, 'John sleeps with every dog.', IR6)),
    logic_why(IR6, W6),
    check('an adjunct\'s noun phrase of every', W6, adjunct(every)).

%% 1.72.0: A PRONOUN with no referent is a constant of its own, its word;
%% in a text, the noun phrase it refers to.
pronouns :-
    section('the pronouns'),
    forall(member(T-Want, [
               'He sleeps.'-'is_sleep(he).\n',
               'She sees him.'-'see(she, he).\n',
               'I see you.'-'see(i, you).\n',
               'They like music.'-'like(they, music).\n',
               'He stood on the rock.'-'past(on(stand(he), the(rock))).\n',
               'He is happy if he is safe.'-'happy(he) :-\n    safe(he).\n',
               'The boy sees the house. He sees it.'-'see(the(boy), the(house)).\nsee(the(boy), the(house)).\n',
               'John sleeps. He dreams.'-'is_sleep(john).\ndream(john).\n',
               'A dog barked. It was hungry.'-'dog(a(dog)).\npast(bark(a(dog))).\npast(hungry(a(dog))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a pronoun into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['see(she, he).'-'She sees him.',
                             'happy(we).'-'We are happy.',
                             'see(i, you).'-'I see you.',
                             'dog(a(dog)). past(bark(a(dog))). past(hungry(a(dog))).'-'A dog barked. It was hungry.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['a pronoun into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'see(she, he).', S3) -> true ; S3 = none ),
    check('a pronoun into Spanish', S3, 'Ella lo ve.'),
    logic_readings(english, 'Who is human? Is Socrates human?', [U4|_]),
    check('a text of two questions is a question', U4,
          utterance(question, [query(pred(human, [var(1)])), query(pred(human, [const(socrates)]))])),
    logic_readings(english, 'Every dog sleeps. It dreams.', Us5),
    check('a pronoun whose referent no earlier sentence has', Us5, []).

%% 1.73.0: A POSSESSOR and its possessed are one constant, of(Possessed,
%% Possessor) since 1.76.0.
possessors :-
    section('the possessors'),
    forall(member(T-Want, [
               'His dog sleeps.'-'is_sleep(of(dog, he)).\n',
               'John\'s dog barks.'-'bark(of(dog, john)).\n',
               'She sat on the edge of the bed.'-'past(on(sit(she), of(edge, the(bed)))).\n',
               'The boy\'s dog\'s house is big.'-'big(of(house, of(dog, the(boy)))).\n',
               'Mary loves her cat.'-'love(mary, of(cat, she)).\n',
               'His hesitancy revealed his basic indisposition.'-'past(reveal(of(hesitancy, he), of(basic(indisposition), he))).\n',
               'John sleeps. His dog barks.'-'is_sleep(john).\nbark(of(dog, john)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a possessor into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    logic_readings(english, 'The bed\'s edge is soft.', [U1|_]),
    logic_readings(english, 'The edge of the bed is soft.', [U2|_]),
    check('the two possessives are one constant', U1-U2,
          utterance(assertion, [fact(pred(soft, [const(of(edge, the(bed)))]))])-
          utterance(assertion, [fact(pred(soft, [const(of(edge, the(bed)))]))])),
    forall(member(C3-Want3, ['is_sleep(of(dog, he)).'-'His dog sleeps.',
                             'big(of(house, of(dog, the(boy)))).'-'The boy\'s dog\'s house is big.',
                             'happy(of(friend, i)).'-'My friend is happy.',
                             '?- see(X, of(dog, he)).'-'Who sees his dog?']),
           ( ( logic_translate(cocolog, english, C3, E3) -> true ; E3 = none ),
             atomic_list_concat(['a possessor into English: ', C3], L3),
             check(L3, E3, Want3) )),
    ( logic_translate(cocolog, spanish, 'happy(of(friend, i)).', S4) -> true ; S4 = none ),
    check('a possessor into Spanish', S4, 'Mi amigo es feliz.'),
    once(typology_read(english, 'His hands are cold.', IR5)),
    ( logic_from_ir(IR5, _) -> W5 = read ; logic_why(IR5, W5) ),
    check('a plural possessed has its plural word', W5, read).

%% 1.74.0: AN INDEFINITE OBJECT is an individual in a statement, a variable
%% in a question or a condition, and nothing in a rule's conclusion.
objects :-
    section('the indefinite objects'),
    forall(member(T-Want, [
               'He received a letter.'-'letter(a(letter)).\npast(receive(he, a(letter))).\n',
               'They saw an owl.'-'owl(a(owl)).\npast(see(they, a(owl))).\n',
               'They saw a university.'-'university(a(university)).\npast(see(they, a(university))).\n',
               'John sees a big dog.'-'dog(a(big(dog))).\nbig(a(big(dog))).\nsee(john, a(big(dog))).\n',
               'A person likes a dog.'-'person(a(person)).\ndog(a(dog)).\nlike(a(person), a(dog)).\n',
               'Who sees a dog?'-'?- see(A, B), dog(B).\n',
               'Does John see a dog?'-'?- see(john, A), dog(A).\n',
               'A person is happy if they own a dog.'-'happy(A) :-\n    person(A),\n    own(A, B),\n    dog(B).\n',
               'John saw a dog. It was hungry.'-'dog(a(dog)).\npast(see(john, a(dog))).\npast(hungry(a(dog))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['an object into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['letter(a(letter)). past(receive(he, a(letter))).'-'He received a letter.',
                             'person(a(person)). dog(a(dog)). like(a(person), a(dog)).'-'A person likes a dog.',
                             '?- see(X, Y), dog(Y).'-'Who sees a dog?',
                             'happy(X) :- person(X), own(X, Y), dog(Y).'-'A person is happy if they own a dog.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['an object into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'letter(a(letter)). past(receive(he, a(letter))).', S3) -> true ; S3 = none ),
    check('an object into Spanish', S3, 'Él recibió una carta.'),
    once(typology_read(english, 'Every boy sees a dog.', IR4)),
    logic_why(IR4, W4),
    check('a rule\'s conclusion has no indefinite object', W4, object(generic)).

%% 1.75.0: A PLURAL DEFINITE NOUN PHRASE is a constant of the group,
%% the(pl(rebel)) since 1.76.0: the meaning and its number.
plurals :-
    section('the plural definite noun phrases'),
    forall(member(T-Want, [
               'The rebels salted the fields.'-'past(salt(the(pl(rebel)), the(pl(field)))).\n',
               'The small children play.'-'play(the(pl(small(child)))).\n',
               'Mary sees the children.'-'see(mary, the(pl(child))).\n',
               'His hands are cold.'-'cold(of(pl(hand), he)).\n',
               'The dogs are animals.'-'animal(the(pl(dog))).\n',
               'Who sees the dogs?'-'?- see(A, the(pl(dog))).\n',
               'The children sleep. They dream.'-'is_sleep(the(pl(child))).\ndream(the(pl(child))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a plural into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['past(salt(the(pl(rebel)), the(pl(field)))).'-'The rebels salted the fields.',
                             'cold(of(pl(hand), he)).'-'His hands are cold.',
                             'animal(the(pl(dog))).'-'The dogs are animals.',
                             'play(the(pl(small(child)))).'-'The small children play.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['a plural into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'is_sleep(the(pl(dog))).', S3) -> true ; S3 = none ),
    check('a plural into Spanish', S3, 'Los perros duermen.'),
    logic_readings(spanish, 'Los perros duermen.', [U4|_]),
    check('a Spanish plural is the meaning and pl', U4,
          utterance(assertion, [fact(pred(sleep, [const(the(pl(dog)))]))])).

%% 1.76.0: A CONSTANT IS A TERM where its noun phrase has a determiner:
%% the(dog), the(pl(rebel)), the(big(dog)), a(dog), of(dog, john). the, a,
%% of and pl name terms, never predicates.
terms :-
    section('the constants as terms'),
    forall(member(C-Want, [
               'past(the(dog)).'-utterance(assertion, [fact(pred(past, [const(the(dog))]))]),
               'in(live(john), paris).'-utterance(assertion, [fact(modified(pp(in, const(paris)), pred(live, [const(john)])))]),
               'like(the(pl(small(child))), music).'-utterance(assertion, [fact(pred(like, [const(the(pl(small(child)))), const(music)]))]),
               'past(on(stand(he), of(edge, the(bed)))).'-utterance(assertion,
                   [fact(at(past, modified(pp(on, const(of(edge, the(bed)))), pred(stand, [const(he)]))))]),
               '?- sleep(the(X)).'-utterance(question, [query(pred(sleep, [fun(the, [var(1)])]))]) ]),
           ( ( cocolog_read(C, U) -> true ; U = none ),
             atomic_list_concat(['a term read: ', C], Label),
             check(Label, U, Want) )),
    forall(member(T, ['The big old dog sleeps.', 'The small children play.', 'The boy\'s dog\'s house is big.',
                      'His hands are cold.', 'The cinema relies on apparent motion.']),
           ( logic_readings(english, T, [U2|_]),
             ( cocolog_write(U2, C2), logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             atomic_list_concat(['a term, there and back: ', T], L2),
             check(L2, E2, T) )),
    logic_translate(english, cocolog, 'The dog sleeps.', P1),
    logic_translate(english, cocolog, 'John sleeps.', P2),
    logic_translate(english, cocolog, 'The cat sleeps.', P3),
    forall(member(P, [P1, P2, P3]), ( sub_atom(P, 0, _, 2, S), term_string(Cl, S), assertz(Cl) )),
    findall(X, is_sleep(the(X)), Xs),
    check('a query of every definite thing that sleeps', Xs, [dog, cat]).

%% 1.77.0: AN INDEFINITE NOUN PHRASE is an individual a(T) wherever a
%% statement says it, T its term as in the(T) (a(pl(book)), a(big(dog))):
%% an object, an adjunct's, a possessor and a possessed. In a question or a
%% condition it is a variable, in a rule's conclusion nothing.
individuals :-
    section('the indefinite noun phrases'),
    forall(member(T-Want, [
               'She bought books.'-'book(a(pl(book))).\npast(buy(she, a(pl(book)))).\n',
               'A good woman met a bad woman.'-'woman(a(good(woman))).\ngood(a(good(woman))).\nwoman(a(bad(woman))).\nbad(a(bad(woman))).\npast(meet(a(good(woman)), a(bad(woman)))).\n',
               'He sat on a chair.'-'chair(a(chair)).\npast(on(sit(he), a(chair))).\n',
               'Who sat on a chair?'-'?- past(on(sit(A), B)), chair(B).\n',
               'He bought a book of stamps.'-'book(a(of(book, a(pl(stamp))))).\nstamp(a(pl(stamp))).\npast(buy(he, a(of(book, a(pl(stamp)))))).\n',
               'The novel attained the status of a classic.'-'classic(a(classic)).\npast(attain(the(novel), of(status, a(classic)))).\n',
               'Who knows the father of a student?'-'?- know(A, of(father, B)), student(B).\n',
               'She met a man. His dog barked.'-'man(a(man)).\npast(meet(she, a(man))).\npast(bark(of(dog, a(man)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['an individual into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['book(a(pl(book))). past(buy(she, a(pl(book)))).'-'She bought books.',
                             'woman(a(good(woman))). good(a(good(woman))). woman(a(bad(woman))). bad(a(bad(woman))). past(meet(a(good(woman)), a(bad(woman)))).'-'A good woman met a bad woman.',
                             'book(a(of(book, a(pl(stamp))))). stamp(a(pl(stamp))). past(buy(he, a(of(book, a(pl(stamp)))))).'-'He bought a book of stamps.',
                             '?- past(on(sit(X), Y)), chair(Y).'-'Who sat on a chair?',
                             'man(a(man)). past(meet(she, a(man))). past(bark(of(dog, a(man)))).'-'She met a man. His dog barked.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['an individual into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'book(a(of(book, a(pl(stamp))))). stamp(a(pl(stamp))). past(buy(he, a(of(book, a(pl(stamp)))))).', S3) -> true ; S3 = none ),
    check('an individual into Spanish', S3, 'Él compró un libro de sellos.'),
    logic_readings(english, 'The novel attained the status of a classic.', [U4|_]),
    check('a possessor\'s individual inside the possessed\'s constant', U4,
          utterance(assertion, [fact(pred(classic, [const(a(classic))])),
                                fact(at(past, pred(attain, [const(the(novel)), const(of(status, a(classic)))])))])),
    logic_readings(english, 'Who knows the father of a student?', [U5|_]),
    check('a variable inside a constant is a compound term', U5,
          utterance(question, [query(and([pred(know, [var(1), fun(of, [const(father), var(2)])]),
                                          pred(student, [var(2)])]))])),
    forall(member(T6-Want6, ['Lilies of the valley are racemose.'-possessor(generic),
                             'Every dog sleeps on a mat.'-object(generic)]),
           ( once(typology_read(english, T6, IR6)), logic_why(IR6, W6),
             atomic_list_concat(['no individual: ', T6], L6),
             check(L6, W6, Want6) )),
    forall(member(T7, ['She bought books.', 'He bought a book of stamps.']),
           ( logic_translate(english, cocolog, T7, P7), assert_text(P7) )),
    findall(X-Y, ( past(buy(X, Y)), book(Y) ), XYs),
    check('a query of who bought a book', XYs, [she-a(pl(book)), he-a(of(book, a(pl(stamp))))]).

%% Each clause of a Cocolog text asserted.
assert_text(P) :-
    atomic_list_concat(Ps, '.\n', P),
    forall(( member(S, Ps), S \== '' ), ( term_string(Cl, S), assertz(Cl) )).

%% A test's own predicates: what the clauses written from English assert.
:- dynamic is_sleep/1, past/1, book/1, stamp/1.
