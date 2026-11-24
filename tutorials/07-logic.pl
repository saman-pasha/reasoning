%% The reasoning tutorial 07 -- library(reasoning/logic): level 2 of the
%% translator, a logic form made from the typology IR (TRANSLATOR-PLAN.md).
%%
%% TIER 2: `use_module(library(reasoning/logic))', from logic.pl, over
%% library(reasoning/typology) and its templates. Clauses only: no model,
%% no store.
%%
%%     cocolog -s tutorials/07-logic.pl
%%
%% TWO LEVELS OF IR. The typology IR (lesson 06) keeps what a sentence
%% says: its roles, its tense, its definiteness, its words of meaning, the
%% same for every language. The logic form keeps what a program can hold:
%% facts, rules and queries over predicates and terms. Rules make the
%% second from the first, so every language the typology reads has its
%% logic form; what has none yet says why.
%%
%% COCOLOG IS A TEMPLATE TOO (templates/cocolog.pl): the logic form written
%% as Cocolog source and read back. A programming language connects to the
%% logic form alone, so a Spanish sentence gets its Cocolog by the same
%% rules as an English one.

:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

main :-
    typology_load(english),
    typology_load(spanish),
    facts,
    rules,
    questions,
    why,
    cocolog,
    format("~ndone~n", []).

%% 1. A FACT. A name, a definite noun phrase and a bare noun are constants,
%% and a statement of constants is its facts.
facts :-
    logic_readings(english, 'Socrates is human.', [U1]),
    must('a name is a constant', U1, utterance(assertion, [fact(pred(human, [const(socrates)]))])),
    logic_readings(english, 'John sees the dog.', [U2]),
    must('a verb with an object is a predicate of two', U2,
         utterance(assertion, [fact(pred(see, [const(john), const(the_dog)]))])).

%% 2. A RULE. `every' makes a variable whose noun is the rule's condition;
%% an if clause gives more conditions, its pronoun the main clause's
%% subject; an indefinite subject is generic, a rule first and one
%% individual's facts second.
rules :-
    logic_readings(english, 'Every human is mortal.', [U1]),
    must('every', U1, utterance(assertion, [rule(pred(mortal, [var(1)]), pred(human, [var(1)]))])),
    logic_readings(english, 'A person is happy if they are healthy and safe.', [U2]),
    must('an if clause', U2,
         utterance(assertion, [rule(pred(happy, [var(1)]),
                                    and([pred(person, [var(1)]), pred(healthy, [var(1)]), pred(safe, [var(1)])]))])),
    logic_readings(english, 'A person likes music.', Us3),
    length(Us3, N3),
    must('an indefinite subject has two readings', N3, 2),
    logic_readings(spanish, 'Cada perro duerme.', [U4|_]),
    must('Spanish, the same rules', U4, utterance(assertion, [rule(pred(sleep, [var(1)]), pred(dog, [var(1)]))])).

%% 3. A QUERY. A question word is the query's variable.
questions :-
    logic_readings(english, 'Who is human?', [U1]),
    must('who', U1, utterance(question, [query(pred(human, [var(1)]))])),
    logic_readings(english, 'Is Socrates human?', [U2]),
    must('a yes or no question', U2, utterance(question, [query(pred(human, [const(socrates)]))])).

%% 4. NO GUESS. What has no logic form yet says why, and is not made one.
why :-
    once(typology_read(english, 'The boy saw the dog.', IR1)),
    logic_why(IR1, W1),
    must('a past tense', W1, tense(past)),
    once(typology_read(english, 'Every boy sees a dog.', IR2)),
    logic_why(IR2, W2),
    must('an object that is no constant', W2, object(generic)).

%% 5. COCOLOG. The writer makes a fact, a rule or a query of each item; the
%% reader makes the logic form of a Cocolog text again. A predicate that
%% Cocolog defines already gets the template's prefix: sleep/1 is a
%% builtin, so `John sleeps.' is is_sleep(john), and the reader takes the
%% prefix off. The clause written from Spanish runs.
cocolog :-
    logic_translate(english, cocolog, 'Every human is mortal.', C1),
    must('a rule', C1, 'mortal(A) :-\n    human(A).\n'),
    logic_translate(english, cocolog, 'Who is human?', C2),
    must('a query', C2, '?- human(A).\n'),
    logic_translate(english, cocolog, 'John sleeps.', C3),
    must('a reserved name', C3, 'is_sleep(john).\n'),
    cocolog_read(C3, U4),
    must('read back', U4, utterance(assertion, [fact(pred(sleep, [const(john)]))])),
    logic_readings(english, 'A person is happy if they are healthy and safe.', [U5]),
    cocolog_write(U5, C5),
    cocolog_read(C5, U6),
    ( U6 =@= U5 -> R6 = same ; R6 = U6 ),
    must('English, Cocolog and back', R6, same),
    logic_translate(spanish, cocolog, 'Cada perro duerme.', C7),
    show('Spanish', C7),
    sub_atom(C7, 0, _, 2, S8),
    term_string(T8, S8),
    assertz(T8),
    assertz(dog(rex)),
    ( is_sleep(rex) -> R8 = proved ; R8 = failed ),
    must('a rule written runs', R8, proved).


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
