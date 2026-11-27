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
    plurals,
    terms,
    individuals,
    relations,
    whens,
    phrases,
    commands,
    noun_adpositions,
    prepositions,
    unsaid_subjects,
    noun_modifiers,
    adjective_phrases,
    text_individuals,
    graded_adjectives,
    adjectives_after_noun,
    capital_adjectives,
    of_bare_nouns,
    phrasal_verbs,
    infinitives,
    infinitive_places,
    infinitive_languages,
    passive,
    passive_places,
    object_complement,
    passive_languages,
    progressive,
    complement_terms,
    pp_phrase,
    adjunct_first,
    perfect_passive,
    count_words,
    modals,
    negation,
    adjective_alone,
    format("~ndone~n", []).

%% 1. A FACT. A name, a definite noun phrase and a bare noun are constants,
%% and a statement of constants is its facts.
facts :-
    logic_readings(english, 'Socrates is human.', [U1]),
    must('a name is a constant', U1, utterance(assertion, [fact(pred(human, [const(socrates)]))])),
    logic_readings(english, 'John sees the dog.', [U2]),
    must('a verb with an object is a predicate of two', U2,
         utterance(assertion, [fact(pred(see, [const(john), const(the(dog))]))])).

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
    once(typology_read(english, 'The dog is not big and black.', IR1)),
    logic_why(IR1, W1),
    must('a negation of two atoms', W1, negation),
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
    logic_translate(cocolog, english, '?- see(X, the(dog)).', E3),
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
%% written by hand (lexicon/logic.txt has 208): how many the translator
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
    logic_translate(cocolog, english, 'future(see(mary, the(dog))).', E3),
    must('the future, in English', E3, 'Mary will see the dog.'),
    logic_translate(cocolog, spanish, 'perfect(see(mary, the(dog))).', E4),
    show('the perfect, in Spanish', E4).

%% 9. AN ADJUNCT. An adposition phrase or an adverb of a clause is said of
%% each atom of the clause, inside its tense: Cocolog writes it round the
%% atom, the adposition of two arguments (the atom and the place) and the
%% adverb of one. An adposition phrase after `is' is a predicate of two.
adjuncts :-
    logic_translate(english, cocolog, 'John walked to the house.', C1),
    must('a place in the past', C1, 'past(to(walk(john), the(house))).\n'),
    logic_translate(english, cocolog, 'Mary runs quickly.', C2),
    must('an adverb', C2, 'quickly(run(mary)).\n'),
    logic_translate(english, cocolog, 'The book is on the table.', C3),
    must('a predicate of a place', C3, 'on(the(book), the(table)).\n'),
    logic_translate(cocolog, english, 'in(is_sleep(X), the(house)) :- dog(X).', E4),
    must('back into English', E4, 'Every dog sleeps in the house.').

%% 10. A PRONOUN. In a text a pronoun is the noun phrase it refers to, from
%% an earlier sentence; alone it is a constant of its own, its word, which
%% every sentence that says it shares.
pronouns :-
    logic_translate(english, cocolog, 'John sleeps. He dreams.', C1),
    must('a referent', C1, 'is_sleep(john).\ndream(john).\n'),
    logic_translate(english, cocolog, 'She sees him.', C2),
    must('no referent', C2, 'see(she, he).\n'),
    logic_translate(cocolog, english, 'dog(a(dog)). past(bark(a(dog))). past(hungry(a(dog))).', E3),
    must('an individual said again', E3, 'A dog barked. It was hungry.').

%% 11. A POSSESSOR. The possessed and its possessor are one constant,
%% of(Possessed, Possessor). `the edge of the bed' and `the bed's edge' are
%% one constant, of(edge, the(bed)), as they say one thing.
possessors :-
    logic_translate(english, cocolog, 'His dog sleeps.', C1),
    must('a possessive pronoun', C1, 'is_sleep(of(dog, he)).\n'),
    logic_translate(english, cocolog, 'She sat on the edge of the bed.', C2),
    must('an adposition\'s possessor', C2, 'past(on(sit(she), of(edge, the(bed)))).\n'),
    logic_translate(cocolog, english, 'big(of(house, of(dog, the(boy)))).', E3),
    must('a possessor\'s possessor, back', E3, 'The boy\'s dog\'s house is big.').

%% 12. AN INDEFINITE OBJECT. In a statement it is an individual and its
%% noun a fact of it; in a question or a condition a variable, as `a dog'
%% there means some dog; in a rule's conclusion nothing yet: `Every boy
%% sees a dog.' says each boy may see another dog.
objects :-
    logic_translate(english, cocolog, 'He received a letter.', C1),
    must('in a statement', C1, 'letter(a(letter)).\npast(receive(he, a(letter))).\n'),
    logic_translate(english, cocolog, 'Who sees a dog?', C2),
    must('in a question', C2, '?- see(A, B), dog(B).\n'),
    logic_translate(cocolog, english, 'happy(X) :- person(X), own(X, Y), dog(Y).', E3),
    must('in a condition, back', E3, 'A person is happy if they own a dog.').

%% 13. A PLURAL DEFINITE NOUN PHRASE. `the rebels' is one constant, the
%% group: the(pl(rebel)), the meaning and its number, the same in every
%% language (Spanish `los perros' is the(pl(dog)) too).
plurals :-
    logic_translate(english, cocolog, 'The rebels salted the fields.', C1),
    must('a group', C1, 'past(salt(the(pl(rebel)), the(pl(field)))).\n'),
    logic_translate(spanish, cocolog, 'Los perros duermen.', C2),
    must('from Spanish', C2, 'is_sleep(the(pl(dog))).\n'),
    logic_translate(cocolog, english, 'cold(of(pl(hand), he)).', E3),
    must('a plural possessed, back', E3, 'His hands are cold.').

%% 14. A CONSTANT IS A TERM. A noun phrase with a determiner keeps its
%% structure in Cocolog: the(dog), the(pl(rebel)), the(big(dog)), a(dog),
%% of(dog, john). So a program can ask by the structure: is_sleep(the(X))
%% finds every definite thing that sleeps, and a name is no definite thing.
terms :-
    logic_translate(english, cocolog, 'The big old dog sleeps.', C1),
    must('adjectives', C1, 'is_sleep(the(big(old(dog)))).\n'),
    logic_translate(english, cocolog, 'His hands are cold.', C2),
    must('a plural possessed', C2, 'cold(of(pl(hand), he)).\n'),
    assertz(lesson_sleeps(the(dog))), assertz(lesson_sleeps(john)), assertz(lesson_sleeps(the(cat))),
    findall(X, lesson_sleeps(the(X)), Xs),
    must('every definite thing that sleeps', Xs, [dog, cat]).

:- dynamic lesson_sleeps/1.

%% 15. AN INDEFINITE NOUN PHRASE IS AN INDIVIDUAL wherever a statement says
%% it: an object, an adjunct's, a possessor and a possessed. Its term is
%% a(T), T as in the(T), so it keeps its adjectives and its number, and its
%% facts say its noun and its adjectives. In a question it is a variable.
individuals :-
    logic_translate(english, cocolog, 'He sat on a chair.', C1),
    must('an adjunct\'s individual', C1, 'chair(a(chair)).\npast(on(sit(he), a(chair))).\n'),
    logic_translate(english, cocolog, 'She bought books.', C2),
    must('a plural individual', C2, 'book(a(pl(book))).\npast(buy(she, a(pl(book)))).\n'),
    logic_translate(english, cocolog, 'He bought a book of stamps.', C3),
    must('a possessed and its possessor',
         C3, 'book(a(of(book, a(pl(stamp))))).\nstamp(a(pl(stamp))).\npast(buy(he, a(of(book, a(pl(stamp)))))).\n'),
    logic_translate(cocolog, english, 'woman(a(good(woman))). good(a(good(woman))). woman(a(bad(woman))). bad(a(bad(woman))). past(meet(a(good(woman)), a(bad(woman)))).', E4),
    must('two individuals of one noun', E4, 'A good woman met a bad woman.'),
    logic_translate(english, cocolog, 'Who knows the father of a student?', C5),
    must('a variable inside a constant', C5, '?- know(A, of(father, B)), student(B).\n').

%% 16. A NOUN OF RELATION is a predicate of two: `John is Mary's father.'
%% and `John is the father of Mary.' are father(john, mary). So a program
%% can reason over the relation: a father's father is a grandfather.
relations :-
    logic_translate(english, cocolog, 'John is Mary\'s father.', C1),
    must('a possessive', C1, 'father(john, mary).\n'),
    logic_translate(english, cocolog, 'Bob is the father of John.', C2),
    must('of', C2, 'father(bob, john).\n'),
    logic_translate(english, cocolog, 'Who is the father of John?', C3),
    must('a question', C3, '?- father(A, john).\n'),
    logic_translate(cocolog, english, 'father(john, mary).', E4),
    must('back into English', E4, 'John is Mary\'s father.'),
    assertz(lesson_father(john, mary)), assertz(lesson_father(bob, john)),
    findall(G-C, ( lesson_father(G, F), lesson_father(F, C) ), GCs),
    must('a grandfather', GCs, [bob-mary]).

:- dynamic lesson_father/2.

%% 17. WHEN. In the present it is a rule, as `if' is; in a tense it links
%% the main clause's atom to the when clause's, when(A, B), each in its own
%% tense, so a program can ask what happened when something happened.
whens :-
    logic_translate(english, cocolog, 'John sleeps when Mary sings.', C1),
    must('the present, a rule', C1, 'is_sleep(john) :-\n    sing(mary).\n'),
    logic_translate(english, cocolog, 'John slept when Mary sang.', C2),
    must('a tense, a link', C2, 'when(past(is_sleep(john)), past(sing(mary))).\n'),
    logic_translate(cocolog, english, 'when(past(bark(the(dog))), past(sing(mary))).', E3),
    must('back into English', E3, 'The dog barked when Mary sang.'),
    assertz(lesson_when(past(sleep(john)), past(sing(mary)))),
    assertz(lesson_when(past(bark(the(dog))), past(sing(mary)))),
    findall(A, lesson_when(A, past(sing(mary))), As),
    must('what happened when Mary sang', As, [past(sleep(john)), past(bark(the(dog)))]).

:- dynamic lesson_when/2.

%% 18. A NOUN PHRASE ALONE is a sentence too (most of WordNet's example
%% sentences are one): it says its noun and its adjectives of its term,
%% an indefinite one's individual, and comes back as the phrase.
phrases :-
    logic_translate(english, cocolog, 'A heavy coat.', C1),
    must('an individual', C1, 'coat(a(heavy(coat))).\nheavy(a(heavy(coat))).\n'),
    logic_translate(english, cocolog, 'The portals of the cathedral.', C2),
    must('a possessed', C2, 'portal(of(pl(portal), the(cathedral))).\n'),
    logic_translate(cocolog, english, 'year(the(past(year))). past(the(past(year))).', E3),
    must('back into English', E3, 'The past year.').

%% 19. A COMMAND is its atoms in the imperative, a tense, its subject you:
%% Cocolog writes imperative(Atom).
commands :-
    logic_translate(english, cocolog, 'Mince the garlic.', C1),
    must('a command', C1, 'imperative(mince(you, the(garlic))).\n'),
    logic_translate(cocolog, english, 'cake(a(cake)). imperative(make(you, a(cake))).', E2),
    must('back into English', E2, 'Make a cake.').

%% 20. A NOUN PHRASE WITH AN ADPOSITION PHRASE AFTER IT is one constant, the
%% adposition's term inside the(...) or a(...), Prep(Head, X), as of/2 is
%% for a possessor; a program asks by its structure.
noun_adpositions :-
    logic_translate(english, cocolog, 'The house on the hill is old.', C1),
    must('one constant', C1, 'old(the(on(house, the(hill)))).\n'),
    logic_translate(cocolog, english, 'is_sleep(the(with(man, the(hat)))).', E2),
    must('back into English', E2, 'The man with the hat sleeps.').

%% 21. EVERY PREPOSITION is a predicate of two, as in/2 is: round the atom
%% it modifies, or between a copula's subject and its noun phrase.
prepositions :-
    logic_translate(english, cocolog, 'He slept during the storm.', C1),
    must('round the atom', C1, 'past(during(is_sleep(he), the(storm))).\n'),
    logic_translate(english, cocolog, 'The book is at the station.', C2),
    must('after is', C2, 'at(the(book), the(station)).\n').

%% 22. A CLAUSE WITH NO SUBJECT says its atoms of someone, and is said back
%% with `Someone'.
unsaid_subjects :-
    logic_translate(english, cocolog, 'Took the joke well.', C1),
    must('of someone', C1, 'past(well(take(someone, the(joke)))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'Someone took the joke well.').

%% 23. A NOUN BEFORE A NOUN is no atom of one argument (a glove
%% compartment is no glove): nn(Modifier, Thing), in a constant's term and
%% as a predicate of two.
noun_modifiers :-
    logic_translate(english, cocolog, 'Every leather jacket is expensive.', C1),
    must('a rule', C1, 'expensive(A) :-\n    jacket(A),\n    nn(leather, A).\n'),
    logic_translate(english, cocolog, 'The patient is on life support.', C2),
    must('a constant', C2, 'on(the(patient), nn(life, support)).\n').

%% 24. AN ADJECTIVE WITH AN ADPOSITION PHRASE is the adjective's atom
%% inside the phrase, as a clause's adjunct is round its verb's.
adjective_phrases :-
    logic_translate(english, cocolog, 'He was aware of the danger.', C1),
    must('in the past', C1, 'past(of(aware(he), the(danger))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'He was aware of the danger.').

%% 25. A TEXT'S INDIVIDUALS are each its own: a second `something' or `a
%% dog' is another one (something_2, a(dog, 2)), and a pronoun after a
%% generic sentence is generic too.
text_individuals :-
    logic_translate(english, cocolog, 'Something is red. Something is blue.', C1),
    must('two things', C1, 'red(something).\nblue(something_2).\n'),
    logic_translate(english, cocolog, 'A dog barks. It sleeps.', C2),
    must('every dog, twice', C2, 'bark(A) :-\n    dog(A).\nis_sleep(A) :-\n    dog(A).\n').

%% 26. AN ADVERB THAT GRADES AN ADJECTIVE is round the adjective's atom, as
%% a clause's adverb is round its verb's.
graded_adjectives :-
    logic_translate(english, cocolog, 'She was incurably optimistic.', C1),
    must('in the past', C1, 'past(incurably(optimistic(she))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'She was incurably optimistic.').

%% 27. AN ADJECTIVE WITH AN ADPOSITION PHRASE IN A NOUN PHRASE is in the
%% noun phrase's term, A(T, Prep, X), and said of it as a copula's phrase
%% is: the adjective's atom inside the phrase.
adjectives_after_noun :-
    logic_translate(english, cocolog, 'A book full of errors.', C1),
    must('an individual and its phrase', C1, 'book(a(full(book, of, a(pl(error))))).\nof(full(a(full(book, of, a(pl(error))))), a(pl(error))).\nerror(a(pl(error))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'A book full of errors.').

%% 28. AN ADJECTIVE WRITTEN WITH A CAPITAL is its meaning's atom, and the
%% English template puts the capital back.
capital_adjectives :-
    logic_translate(english, cocolog, 'The Guyanese capital.', C1),
    must('the small atom', C1, 'capital(the(guyanese(capital))).\nguyanese(the(guyanese(capital))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English, the capital', E2, 'The Guyanese capital.').

%% 29. A BARE NOUN AFTER `of' is a constant of its own, inside the
%% possessed's term.
of_bare_nouns :-
    logic_translate(english, cocolog, 'He felt a stream of air.', C1),
    must('the air a constant', C1, 'stream(a(of(stream, air))).\npast(feel(he, a(of(stream, air)))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'He felt a stream of air.').

%% 30. A PHRASAL VERB is one predicate, named by its meaning.
phrasal_verbs :-
    logic_translate(english, cocolog, 'The mayor threw out the first ball.', C1),
    must('the predicate throw_out', C1, 'past(throw_out(the(mayor), the(first(ball)))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English, the particle after the verb', E2, 'The mayor threw out the first ball.').

%% 31. AN INFINITIVE AS A VERB'S OBJECT is the term to(Atom), said of the
%% clause's own subject.
infinitives :-
    logic_translate(english, cocolog, 'He tried to catch her eye.', C1),
    must('the term to(...)', C1, 'past(try(he, to(catch(he, of(eye, she))))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('back into English', E2, 'He tried to catch her eye.').

%% 32. AN INFINITIVE AFTER AN ADJECTIVE is its second argument, to(Atom);
%% after an object of a verb like `ask', to(Atom) said of the object; ONE
%% OF PURPOSE is the term to(Atom, Atom2), said of the subject.
infinitive_places :-
    logic_translate(english, cocolog, 'He is glad to help.', C1),
    must('the adjective\'s second argument', C1, 'glad(he, to(help(he))).\n'),
    logic_translate(english, cocolog, 'He asked her to leave the room.', C2),
    must('said of the object', C2, 'past(ask(he, to(leave(she, the(room))))).\n'),
    logic_translate(english, cocolog, 'He used pressure to stop the bleeding.', C3),
    must('of purpose', C3, 'past(to(use(he, pressure), stop(he, the(bleeding)))).\n'),
    logic_translate(cocolog, english, C3, E4),
    must('back into English', E4, 'He used pressure to stop the bleeding.').

%% 33. THE INFINITIVE OF ANOTHER LANGUAGE has English's logic form, so the
%% same Cocolog.
infinitive_languages :-
    typology_load(spanish),
    logic_translate(spanish, cocolog, 'El niño quiere ver al perro.', C1),
    must('Spanish into Cocolog', C1, 'want(the(boy), to(see(the(boy), the(dog)))).\n'),
    logic_translate(cocolog, english, C1, E2),
    must('and into English', E2, 'The boy wants to see the dog.').

%% 34. THE PASSIVE (1.98.0) is its active: the agent `by NP' its subject,
%% else someone the text does not name, and an object's infinitive the
%% patient's. Back into English it is the active.
passive :-
    typology_load(english),
    logic_translate(english, cocolog, 'The pass was fumbled.', C1),
    must('the passive into Cocolog', C1, 'past(fumble(someone, the(pass))).\n'),
    logic_translate(english, cocolog, 'The house was built by the workers.', C2),
    must('with its agent', C2, 'past(build(the(pl(worker)), the(house))).\n'),
    logic_translate(cocolog, english, C2, E2),
    must('and into English', E2, 'The workers built the house.'),
    logic_translate(english, cocolog, 'He was asked to leave the room.', C3),
    must('an object\'s infinitive', C3, 'past(ask(someone, to(leave(he, the(room))))).\n').

%% 35. A PASSIVE INFINITIVE (1.99.0) is the active's, its patient the
%% clause's own subject, and back into English the passive infinitive; an
%% adverb inside the verb's words is round the atom, as any adverb is.
passive_places :-
    typology_load(english),
    logic_translate(english, cocolog, 'The machine needs to be serviced.', C1),
    must('a passive infinitive', C1, 'need(the(machine), to(service(someone, the(machine)))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'The machine needs to be serviced.'),
    logic_translate(english, cocolog, 'He promptly forgot the address.', C2),
    must('an adverb before the verb', C2, 'past(promptly(forget(he, the(address)))).\n').

%% 36. AN OBJECT'S COMPLEMENT (1.100.0) is the verb's third argument: the
%% atom a copula would make of the object, the object its first argument;
%% a passive's is its active's, and back into English the complement after
%% the object.
object_complement :-
    typology_load(english),
    logic_translate(english, cocolog, 'He considered the dog small.', C1),
    must('the complement an atom of the object', C1, 'past(consider(he, the(dog), small(the(dog)))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'He considered the dog small.'),
    logic_translate(english, cocolog, 'The dog was considered small.', C2),
    must('a passive with a complement', C2, 'past(consider(someone, the(dog), small(the(dog)))).\n').

%% 37. A PASSIVE IN ANOTHER LANGUAGE (1.101.0) is its active at level 2, as
%% English's is: a Spanish passive into Cocolog and out as German.
passive_languages :-
    typology_load(spanish),
    typology_load(german),
    logic_translate(spanish, cocolog, 'El perro fue visto por el niño.', C1),
    must('a Spanish passive, its active', C1, 'past(see(the(boy), the(dog))).\n'),
    logic_translate(cocolog, german, C1, G1),
    must('and into German', G1, 'Der Junge sah den Hund.').

%% 38. THE PROGRESSIVE (1.102.0) is a tense of its own in Cocolog: the
%% template's name round the atom, progressive, past_progressive,
%% perfect_progressive ...; and back into English.
progressive :-
    typology_load(english),
    logic_translate(english, cocolog, 'The engine is idling.', C1),
    must('the present progressive', C1, 'progressive(idle(the(engine))).\n'),
    logic_translate(cocolog, english, 'past_progressive(purl(the(water))).\n', E2),
    must('back into English', E2, 'The water was purling.').

%% 39. A COMPLEMENT OF SEVERAL ATOMS (1.103.0) is the noun phrase's term,
%% an indefinite one a(Shape) and no fact; a progressive passive is the
%% progressive of its active.
complement_terms :-
    typology_load(english),
    logic_translate(english, cocolog, 'They considered him a good man.', C1),
    must('a noun phrase of two atoms', C1, 'past(consider(they, he, a(good(man)))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'They considered him a good man.'),
    logic_translate(english, cocolog, 'The house is being built.', C2),
    must('a progressive passive', C2, 'progressive(build(someone, the(house))).\n').

%% 40. AN ADPOSITION PHRASE ALONE (1.104.0) is said of something, as a
%% copula's adposition phrase is said of its subject; back into English
%% it is that copula.
pp_phrase :-
    typology_load(english),
    logic_translate(english, cocolog, 'In direct sunlight.', C1),
    must('the phrase said of something', C1, 'in(something, direct(sunlight)).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'Something is in direct sunlight.').

%% 41. AN ADJUNCT BEFORE THE SUBJECT (1.105.0) is the clause's adjunct as
%% any is, round its atom; back into English it stands at the end.
adjunct_first :-
    typology_load(english),
    logic_translate(english, cocolog, 'Suddenly the dog barked.', C1),
    must('the adverb round the atom', C1, 'past(suddenly(bark(the(dog)))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'The dog barked suddenly.').

%% 42. THE PERFECT PASSIVE OF GERMAN (1.106.0) is the active's perfect, as
%% English's is.
perfect_passive :-
    typology_load(german),
    logic_translate(german, cocolog, 'Das Mädchen ist vom Jungen gesehen worden.', C1),
    must('the active perfect', C1, 'perfect(see(the(boy), the(girl))).\n').

%% 43. A NUMBER OR A QUANTIFIER (1.107.0) is an indefinite noun phrase
%% with the word its first modifier, as an adjective is; back into
%% English the word is the determiner again.
count_words :-
    typology_load(english),
    logic_translate(english, cocolog, 'Two dogs slept.', C1),
    must('the group', C1, 'dog(a(pl(two(dog)))).\ntwo(a(pl(two(dog)))).\npast(is_sleep(a(pl(two(dog))))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'Two dogs slept.').

%% 44. THE CONDITIONAL AND THE MODALS (1.108.0) are tenses, each its own
%% name in Cocolog, as past is.
modals :-
    typology_load(english),
    logic_translate(english, cocolog, 'In bridge you must follow suit.', C1),
    must('a modal', C1, 'must(in(follow(you, suit), bridge)).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'You must follow suit in bridge.'),
    logic_translate(english, cocolog, 'The dog would sleep.', C2),
    must('the conditional', C2, 'conditional(is_sleep(the(dog))).\n').

%% 45. A NEGATION (1.109.0) is said round the clause's one atom, outside
%% its tense; not/1 is Cocolog's, so its name is is_not.
negation :-
    typology_load(english),
    logic_translate(english, cocolog, 'John did not sleep.', C1),
    must('a negation', C1, 'is_not(past(is_sleep(john))).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'John did not sleep.').

%% 46. AN ADJECTIVE PHRASE ALONE (1.113.0) is said of something, as an
%% adposition phrase alone is.
adjective_alone :-
    typology_load(english),
    logic_translate(english, cocolog, 'Potentially useful.', C1),
    must('an adjective phrase alone', C1, 'potentially(useful(something)).\n'),
    logic_translate(cocolog, english, C1, E1),
    must('and into English', E1, 'Something is potentially useful.').


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
