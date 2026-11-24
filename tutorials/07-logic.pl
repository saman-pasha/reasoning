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
%%
%% AND BACK. Cocolog is said in a natural language the other way: the logic
%% form to the typology IR, the typology IR to a sentence. A sentence is
%% kept only where it reads back to the same logic form; what none says is
%% a general sentence.

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
    english_again,
    measured,
    tenses,
    adjuncts,
    pronouns,
    possessors,
    objects,
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
    once(typology_read(english, 'The boy would see the dog.', IR1)),
    logic_why(IR1, W1),
    must('the conditional', W1, tense(conditional)),
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

%% 6. COCOLOG INTO ENGLISH. Each item is a sentence that reads back to it.
%% A word of two classes is said as its commoner use of one thing (`sleep'
%% a verb, `man' a noun); a predicate that is no word holds for its terms.
english_again :-
    logic_translate(cocolog, english, 'mortal(X) :- human(X).', E1),
    must('a rule', E1, 'Every human is mortal.'),
    logic_translate(cocolog, english, 'is_sleep(john). man(socrates).', E2),
    must('two facts', E2, 'John sleeps. Socrates is a man.'),
    logic_translate(cocolog, english, '?- see(X, the_dog).', E3),
    must('a query', E3, 'Who sees the dog?'),
    logic_translate(cocolog, english, 'append(a, b, c).', E4),
    must('no word', E4, 'Append holds for a, b and c.'),
    logic_translate(cocolog, spanish, 'happy(X) :- person(X), healthy(X), safe(X).', E5),
    show('Spanish', E5),
    logic_readings(english, 'A person is happy if they are healthy and safe.', [U6]),
    cocolog_write(U6, C6),
    logic_translate(cocolog, english, C6, E6),
    logic_readings(english, E6, Us6),
    ( memberchk(U6, Us6) -> R6 = kept ; R6 = lost ),
    must('English, Cocolog, English', R6, kept).

%% 7. THE SECOND MEASURE. Sentences and the Cocolog each should give,
%% written by hand (lexicon/logic.txt has 161): how many the translator
%% gets right, and how many of the Cocolog texts come back as English that
%% reads to them. tools/logic/measure.pl prints the whole file's.
measured :-
    logic_measure(english, ['Socrates is human.'-'human(socrates).',
                            'John is taller than Mary.'-'taller(john, mary).'],
                  measure(N, Right, _, Kept, _, Misses, _)),
    must('sentences', N, 2),
    must('right', Right, 1),
    must('kept', Kept, 1),
    must('why one is not', Misses, [miss('John is taller than Mary.', unread)]).

%% 8. A TENSE. The past, the future, the perfect and the pluperfect are said
%% of each atom of their clause, never of a subject's noun: a man is a man
%% at all times. Cocolog writes the tense round the atom.
tenses :-
    logic_translate(english, cocolog, 'John slept.', C1),
    must('the past', C1, 'past(is_sleep(john)).\n'),
    logic_translate(english, cocolog, 'Every man was happy.', C2),
    must('a rule in the past', C2, 'past(happy(A)) :-\n    man(A).\n'),
    logic_translate(cocolog, english, 'future(see(mary, the_dog)).', E3),
    must('the future, in English', E3, 'Mary will see the dog.'),
    logic_translate(cocolog, spanish, 'perfect(see(mary, the_dog)).', E4),
    show('the perfect, in Spanish', E4).

%% 9. AN ADJUNCT. An adposition phrase or an adverb of a clause is said of
%% each atom of the clause, inside its tense: Cocolog writes it round the
%% atom, the adposition of two arguments (the atom and the place) and the
%% adverb of one. An adposition phrase after `is' is a predicate of two.
adjuncts :-
    logic_translate(english, cocolog, 'John walked to the house.', C1),
    must('a place in the past', C1, 'past(to(walk(john), the_house)).\n'),
    logic_translate(english, cocolog, 'Mary runs quickly.', C2),
    must('an adverb', C2, 'quickly(run(mary)).\n'),
    logic_translate(english, cocolog, 'The book is on the table.', C3),
    must('a predicate of a place', C3, 'on(the_book, the_table).\n'),
    logic_translate(cocolog, english, 'in(is_sleep(X), the_house) :- dog(X).', E4),
    must('back into English', E4, 'Every dog sleeps in the house.').

%% 10. A PRONOUN. In a text a pronoun is the noun phrase it refers to, from
%% an earlier sentence; alone it is a constant of its own, its word, which
%% every sentence that says it shares.
pronouns :-
    logic_translate(english, cocolog, 'John sleeps. He dreams.', C1),
    must('a referent', C1, 'is_sleep(john).\ndream(john).\n'),
    logic_translate(english, cocolog, 'She sees him.', C2),
    must('no referent', C2, 'see(she, he).\n'),
    logic_translate(cocolog, english, 'dog(a_dog). past(bark(a_dog)). past(hungry(a_dog)).', E3),
    must('an individual said again', E3, 'A dog barked. It was hungry.').

%% 11. A POSSESSOR. The possessed and its possessor are one constant: the
%% possessed's words, `_of_', the possessor's constant. `the edge of the
%% bed' and `the bed's edge' are one constant, as they say one thing.
possessors :-
    logic_translate(english, cocolog, 'His dog sleeps.', C1),
    must('a possessive pronoun', C1, 'is_sleep(dog_of_he).\n'),
    logic_translate(english, cocolog, 'She sat on the edge of the bed.', C2),
    must('an adposition\'s possessor', C2, 'past(on(sit(she), edge_of_the_bed)).\n'),
    logic_translate(cocolog, english, 'big(house_of_dog_of_the_boy).', E3),
    must('a possessor\'s possessor, back', E3, 'The boy\'s dog\'s house is big.').

%% 12. AN INDEFINITE OBJECT. In a statement it is an individual and its
%% noun a fact of it; in a question or a condition a variable, as `a dog'
%% there means some dog; in a rule's conclusion nothing yet: `Every boy
%% sees a dog.' says each boy may see another dog.
objects :-
    logic_translate(english, cocolog, 'He received a letter.', C1),
    must('in a statement', C1, 'letter(a_letter).\npast(receive(he, a_letter)).\n'),
    logic_translate(english, cocolog, 'Who sees a dog?', C2),
    must('in a question', C2, '?- see(A, B), dog(B).\n'),
    logic_translate(cocolog, english, 'happy(X) :- person(X), own(X, Y), dog(Y).', E3),
    must('in a condition, back', E3, 'A person is happy if they own a dog.').


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
