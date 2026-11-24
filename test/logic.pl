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
                      code_write, code_read, code_round_trip]), once(S)),
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
               'The boy saw the dog.'-tense(past),
               'The boy does not sleep.'-negation,
               'Every boy sees a dog.'-object(generic),
               'The boy sleeps because the dog sleeps.'-subordinate(because),
               'He sleeps.'-pronoun,
               'No dog sleeps.'-determiner(no),
               'The boy sleeps in the house.'-adjunct ]),
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
