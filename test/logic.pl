%% library(reasoning/logic) -- level 2 of the translator: the logic form made
%% from the typology IR (TRANSLATOR-PLAN.md).
%%
%%     cocolog -s test/logic.pl        from this repository's root

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

main :-
    forall(member(L, [english, spanish, italian]), typology_load(L)),
    forall(member(S, [milestone, constants, generic, joined, diagnostics, languages]), once(S)),
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
