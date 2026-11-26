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
                      adjuncts, pronouns, possessors, objects, plurals, terms, individuals, relations, whens, phrases, commands, noun_adpositions, prepositions, unsaid_subjects, noun_modifiers, adjective_phrases, meanings_apart, graded_adjectives, adjectives_after_noun, capital_adjectives, of_bare_nouns, phrasal_verbs, infinitives, infinitive_places, infinitive_languages, passive, passive_places, object_complement, progressive]), once(S)),
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
    check('the second measure: its sentences', N, 382),
    ( R >= 368 -> VR = ok ; VR = R ),
    check('the second measure: English into Cocolog, at least 368 right', VR, ok),
    ( K >= 374 -> VK = ok ; VK = K ),
    check('the second measure: Cocolog into English and back, at least 374 kept', VK, ok).

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

%% 1.78.0: A NOUN OF RELATION, a copula's noun phrase with a possessor, is
%% a predicate of two, of the subject and the possessor; and a name is a
%% possessor anywhere (level 1).
relations :-
    section('the nouns of relation'),
    forall(member(T-Want, [
               'John is Mary\'s father.'-'father(john, mary).\n',
               'Mary is the mother of John.'-'mother(mary, john).\n',
               'Sculpture is a form of art.'-'form(sculpture, art).\n',
               'Bob was the friend of a farmer.'-'farmer(a(farmer)).\npast(friend(bob, a(farmer))).\n',
               'Who is the father of John?'-'?- father(A, john).\n',
               'Is Bob the father of John?'-'?- father(bob, john).\n',
               'Every set is a subset of the universal set.'-'is_subset(A, the(universal(set))) :-\n    set(A).\n',
               'The boy sees John\'s dog.'-'see(the(boy), of(dog, john)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a relation into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['father(john, mary).'-'John is Mary\'s father.',
                             '?- father(X, john).'-'Who is John\'s father?',
                             'friend(bob, john).'-'Bob is John\'s friend.',
                             'is_subset(X, the(universal(set))) :- set(X).'-'Every set is a subset of the universal set.',
                             'past(salt(the(pl(rebel)), the(pl(field)))).'-'The rebels salted the fields.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['a relation into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'father(john, mary).', S3) -> true ; S3 = none ),
    check('a relation into Spanish', S3, 'John es el padre de Mary.'),
    once(typology_read(english, 'She was his main squeeze.', IR4)),
    logic_why(IR4, W4),
    check('a relation with an adjective has no form yet', W4, relation(adjective)),
    forall(member(T5, ['John is Mary\'s father.', 'Bob is the father of John.']),
           ( logic_translate(english, cocolog, T5, P5), assert_text(P5) )),
    findall(X-Y, ( father(X, Z), father(Z, Y) ), XYs),
    check('a query over the relation: a father\'s father', XYs, [bob-mary]).

%% 1.79.0: WHEN is a rule as `if' in the present; in a tense each atom of
%% the main clause is linked to the when clause's, when(A, B), outside both
%% tenses. A pronoun subject of the when clause is the main subject where
%% it agrees with it.
whens :-
    section('when'),
    forall(member(T-Want, [
               'John sleeps when Mary sings.'-'is_sleep(john) :-\n    sing(mary).\n',
               'John slept when Mary sang.'-'when(past(is_sleep(john)), past(sing(mary))).\n',
               'The saw buckled when it hit a knot.'-'knot(a(knot)).\nwhen(past(buckle(the(saw))), past(hit(the(saw), a(knot)))).\n',
               'The house was a wreck when they bought it.'-'when(past(wreck(the(house))), past(buy(they, it))).\n',
               'She cried with pain when the doctor inserted the needle.'-'when(past(with(cry(she), pain)), past(insert(the(doctor), the(needle)))).\n',
               'The dog will sleep when the boy comes.'-'when(future(is_sleep(the(dog))), come(the(boy))).\n',
               'A dog barked when the bell rang.'-'dog(a(dog)).\nwhen(past(bark(a(dog))), past(ring(the(bell)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['when into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['when(past(is_sleep(john)), past(sing(mary))).'-'John slept when Mary sang.',
                             'when(past(ping(the(bullet))), past(strike(they, the(car)))).'-'The bullet pinged when they struck the car.',
                             'knot(a(knot)). when(past(buckle(the(saw))), past(hit(the(saw), a(knot)))).'-'The saw buckled when the saw hit a knot.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['when into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( cocolog_read('when(past(is_sleep(john)), past(sing(mary))).', U3) -> true ; U3 = none ),
    check('when read: the main atom inside, outside both tenses', U3,
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
          utterance(assertion, [fact(modified(when(at(past, pred(sing, [const(mary)]))),
                                              at(past, pred(sleep, [const(john)]))))])),
    ( logic_translate(cocolog, spanish, 'when(past(is_sleep(john)), past(sing(mary))).', S4) -> true ; S4 = none ),
    check('when into Spanish', S4, 'John durmió cuando Mary cantó.'),
    logic_readings(italian, 'Gianni dormì quando Maria cantò.', [U5|_]),
    check('Italian quando, the same form', U5,
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
          utterance(assertion, [fact(modified(when(at(past, pred(sing, [const(maria)]))),
                                              at(past, pred(sleep, [const(gianni)]))))])),
    forall(member(T6, ['John slept when Mary sang.', 'The dog barked when Mary sang.']),
           ( logic_translate(english, cocolog, T6, P6), assert_text(P6) )),
% cocolint: X3 -- when/2 here is this test's own dynamic predicate, the facts written from English, not SWI's coroutine
    findall(A, when(A, past(sing(mary))), As),
    check('a query of what happened when Mary sang', As, [past(is_sleep(john)), past(bark(the(dog)))]).

%% 1.81.0: A NOUN PHRASE ALONE says its noun and its adjectives of its
%% term: an indefinite one's individual, a definite one's the(T), a bare
%% noun's term; and a group that is those facts is said as the phrase.
phrases :-
    section('a noun phrase alone'),
    forall(member(T-Want, [
               'A heavy coat.'-'coat(a(heavy(coat))).\nheavy(a(heavy(coat))).\n',
               'The past year.'-'year(the(past(year))).\npast(the(past(year))).\n',
               'Good taste.'-'taste(good(taste)).\ngood(good(taste)).\n',
               'The portals of the cathedral.'-'portal(of(pl(portal), the(cathedral))).\n',
               'A hail of bullets.'-'hail(a(of(hail, a(pl(bullet))))).\nbullet(a(pl(bullet))).\n',
               'His newfound aggressiveness.'-'aggressiveness(of(newfound(aggressiveness), he)).\nnewfound(of(newfound(aggressiveness), he)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a phrase into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['coat(a(heavy(coat))). heavy(a(heavy(coat))).'-'A heavy coat.',
                             'year(the(past(year))). past(the(past(year))).'-'The past year.',
                             'taste(good(taste)). good(good(taste)).'-'Good taste.',
                             'dog(the(dog)).'-'The dog.',
                             'dog(a(big(dog))). big(a(big(dog))). past(bark(a(big(dog)))).'-'A big dog barked.',
                             'portal(of(pl(portal), the(cathedral))).'-'The cathedral\'s portals.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['a phrase into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( logic_translate(cocolog, spanish, 'dog(the(big(dog))). big(the(big(dog))).', S3) -> true ; S3 = none ),
    check('a phrase into Spanish', S3, 'El perro grande.'),
    ( cocolog_read('good(good(taste)).', U4) -> true ; U4 = none ),
    check('an adverb never stands on a copula\'s atom: good of good(taste)', U4,
          utterance(assertion, [fact(pred(good, [const(good(taste))]))])),
    ( cocolog_read('quickly(run(the(dog))).', U5) -> true ; U5 = none ),
    check('... and stands on a verb\'s', U5,
          utterance(assertion, [fact(modified(adv(quickly), pred(run, [const(the(dog))])))])),
    forall(member(T6-Want6, ['Roads that lead therefrom.'-phrase(rel), 'Him.'-phrase(pron), 'Some dogs.'-phrase(some)]),
           ( once(typology_read(english, T6, IR6)),
             ( logic_from_ir(IR6, _) -> W6 = read ; logic_why(IR6, W6) ),
             atomic_list_concat(['no form yet: ', T6], L6),
             check(L6, W6, Want6) )),
    forall(member(T7, ['A heavy coat.', 'A warm coat.']),
           ( logic_translate(english, cocolog, T7, P7), assert_text(P7) )),
    findall(X7, coat(X7), Xs7),
    check('a query of the coats the phrases say', Xs7, [a(heavy(coat)), a(warm(coat))]).

%% 1.82.0: A COMMAND is its atoms in the imperative, a tense, its subject
%% you; Cocolog writes imperative(Atom), and a program asks what it is told
%% to do.
commands :-
    section('a command'),
    forall(member(T-Want, [
               'Construct a proof.'-'proof(a(proof)).\nimperative(construct(you, a(proof))).\n',
               'Mince the garlic.'-'imperative(mince(you, the(garlic))).\n',
               'Look at the dog.'-'imperative(look(you, the(dog))).\n',
               'Charge the wagon with hay.'-'imperative(with(charge(you, the(wagon)), hay)).\n',
               'Bathe daily.'-'imperative(daily(bathe(you))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['a command into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, ['imperative(mince(you, the(garlic))).'-'Mince the garlic.',
                             'cake(a(cake)). imperative(make(you, a(cake))).'-'Make a cake.',
                             'imperative(is_sleep(you)).'-'Sleep.']),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['a command into English: ', C2], L2),
             check(L2, E2, Want2) )),
    ( cocolog_read('imperative(mince(you, the(garlic))).', U3) -> true ; U3 = none ),
    check('imperative read: the tense of its atom', U3,
          utterance(assertion, [fact(at(imperative, pred(mince, [const(you), const(the(garlic))])))])),
    once(typology_read(english, 'Do not open the door.', IR4)),
    logic_why(IR4, W4),
    check('a command not to has no form yet', W4, negation),
    forall(member(T5, ['Mince the garlic.', 'Bottle the mineral water.']),
           ( logic_translate(english, cocolog, T5, P5), assert_text(P5) )),
    findall(A, imperative(A), As),
    check('a query of what you are told to do', As, [mince(you, the(garlic)), bottle(you, the(mineral(water)))]).

%% 1.83.0: A NOUN PHRASE WITH AN ADPOSITION PHRASE AFTER IT is a constant
%% of its head with the adposition's term inside, Prep(Head, X), as of/2 is
%% for a possessor: the(with(man, the(hat))). An indefinite one is an
%% individual whose facts are its head's and X's; with `every', `all' or
%% `no' it has no form yet.
noun_adpositions :-
    section('a noun phrase with an adposition phrase after it'),
    forall(member(T-Want, [
               'The man with the hat sleeps.'-'is_sleep(the(with(man, the(hat)))).\n',
               'The house on the hill is old.'-'old(the(on(house, the(hill)))).\n',
               'The boy in the house sees the dog.'-'see(the(in(boy, the(house))), the(dog)).\n',
               'The dog in the house with the garden sleeps.'-'is_sleep(the(in(dog, the(with(house, the(garden)))))).\n',
               'A dip in prices.'-'dip(a(in(dip, a(pl(price))))).\nprice(a(pl(price))).\n',
               'His place in history was foreordained.'-'past(foreordained(in(of(place, he), history))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-T) )),
    ( cocolog_read('old(the(on(house, the(hill)))).', U2) -> true ; U2 = none ),
    check('read: one constant', U2, utterance(assertion, [fact(pred(old, [const(the(on(house, the(hill))))]))])),
    ( logic_translate(cocolog, english, 'in(the(dog), the(house)).', E3) -> true ; E3 = none ),
    check('the adposition predicate stays a predicate', E3, 'The dog is in the house.'),
    forall(member(T4, ['The house on the hill is old.', 'The cabin in the woods is old.']),
           ( logic_translate(english, cocolog, T4, P4), assert_text(P4) )),
    findall(X4, old(X4), Xs4),
    check('a query of what is old', Xs4, [the(on(house, the(hill))), the(in(cabin, the(woods)))]),
    findall(Y5, old(the(on(house, Y5))), Ys5),
    check('a query of what the old house is on', Ys5, [the(hill)]),
    once(typology_read(english, 'Every man with a hat sleeps.', IR6)),
    logic_why(IR6, W6),
    check('every with an adposition phrase has no form yet', W6, determiner(every)).

%% 1.84.0: THE OTHER PREPOSITIONS are predicates of two as in/2 is: round
%% the atom (an adjunct), between a copula's subject and its noun phrase,
%% inside a constant (a noun phrase's).
prepositions :-
    section('the other prepositions'),
    forall(member(T-Want, [
               'He fell into a trap.'-'trap(a(trap)).\npast(into(fall(he), a(trap))).\n',
               'The book is at the station.'-'at(the(book), the(station)).\n',
               'The cat sleeps under the table.'-'under(is_sleep(the(cat)), the(table)).\n',
               'She looked haggardly out of her tent.'-'past(out_of(haggardly(look(she)), of(tent, she))).\n',
               'A large turnout for the meeting.'-'turnout(a(for(large(turnout), the(meeting)))).\nlarge(a(for(large(turnout), the(meeting)))).\n',
               'Guard against infection.'-'imperative(against(guard(you), infection)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-T) )),
    ( cocolog_read('at(the(book), the(station)).', U2) -> true ; U2 = none ),
    check('at read: a predicate of two, no tense', U2,
          utterance(assertion, [fact(pred(at, [const(the(book)), const(the(station))]))])),
    forall(member(T3, ['The book is at the station.', 'The bag is at the door.']),
           ( logic_translate(english, cocolog, T3, P3), assert_text(P3) )),
    findall(X3-Y3, at(X3, Y3), XYs3),
    check('a query of what is where', XYs3, [the(book)-the(station), the(bag)-the(door)]).

%% 1.86.0: A CLAUSE WITH NO SUBJECT says its atoms of someone, the
%% constant `Someone' is said back as.
unsaid_subjects :-
    section('a clause with no subject'),
    forall(member(T-Want-Back, [
               'Took the joke well.'-'past(well(take(someone, the(joke)))).\n'-'Someone took the joke well.',
               'Listened intently.'-'past(intently(listen(someone))).\n'-'Someone listened intently.',
               'Clinched a victory.'-'victory(a(victory)).\npast(clinch(someone, a(victory))).\n'-'Someone clinched a victory.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )),
    once(typology_read(english, 'Took the joke well.', IR2)),
    logic_from_ir(IR2, U2),
    check('the subject no words say is the constant someone', U2,
          utterance(assertion, [fact(at(past, modified(adv(well), pred(take, [const(someone), const(the(joke))]))))])).

noun_modifiers :-
    section('a noun before a noun'),
    forall(member(T-Want-Back, [
               'The patient is on life support.'-'on(the(patient), nn(life, support)).\n'-'The patient is on life support.',
               'A treasure hunter.'-'hunter(a(nn(treasure, hunter))).\nnn(treasure, a(nn(treasure, hunter))).\n'-'A treasure hunter.',
               'The boy sees a leather jacket.'-'jacket(a(nn(leather, jacket))).\nnn(leather, a(nn(leather, jacket))).\nsee(the(boy), a(nn(leather, jacket))).\n'-'The boy sees a leather jacket.',
               'Every leather jacket is expensive.'-'expensive(A) :-\n    jacket(A),\n    nn(leather, A).\n'-'Every leather jacket is expensive.',
               'Who sees a leather jacket?'-'?- see(A, B), jacket(B), nn(leather, B).\n'-'Who sees a leather jacket?' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )),
    once(typology_read(english, 'A black leather jacket.', IR2)),
    logic_from_ir(IR2, U2),
    check('a noun before a noun is no atom of one argument: nn/2', U2,
          utterance(assertion, [fact(pred(jacket, [const(a(black(nn(leather, jacket))))])),
                                fact(pred(black, [const(a(black(nn(leather, jacket))))])),
                                fact(pred(nn, [const(leather), const(a(black(nn(leather, jacket))))]))])).

%% 1.88.0: an adjective with an adposition phrase is the adjective's atom
%% inside the phrase, as a clause's adjunct is round its verb's; a tense
%% round an `of' phrase is the tense (no possessed's term).
adjective_phrases :-
    section('an adjective with an adposition phrase'),
    forall(member(T-Want-Back, [
               'The movie is unsuitable for children.'-'child(a(pl(child))).\nfor(unsuitable(the(movie)), a(pl(child))).\n'-'The movie is unsuitable for children.',
               'He is proud of his son.'-'of(proud(he), of(son, he)).\n'-'He is proud of his son.',
               'He was aware of the danger.'-'past(of(aware(he), the(danger))).\n'-'He was aware of the danger.',
               'All men are equal before the law.'-'before(equal(A), the(law)) :-\n    man(A).\n'-'Every man is equal before the law.',
               'The boy is small and happy with the bone.'-'small(the(boy)).\nwith(happy(the(boy)), the(bone)).\n'-'The boy is small. The boy is happy with the bone.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )),
    once(typology_read(english, 'The dog is big in the house.', IR2)),
    logic_from_ir(IR2, U2),
    check('the adjective\'s atom inside its phrase', U2,
          utterance(assertion, [fact(modified(pp(in, const(the(house))), pred(big, [const(the(dog))])))])),
    ( logic_translate(cocolog, english, 'past(of(big(dog), he)).', E3) -> true ; E3 = none ),
    check('of(big(dog), he) is still his big dog', E3, 'His big dog is past.').

%% 1.89.0: sentences alike in their words and apart in their meanings
%% stay apart. A rule of every thing and a fact of one thing are not the
%% same; in an if clause `something ... it' is any thing (the controlled
%% reading, Attempto's), and alone one thing. A text's individuals are each
%% its own (something_2, a(dog, 2)), an object's apart from its subject's,
%% and a pronoun after a generic sentence is generic too. A sentence with
%% no subject in a text is the text's one someone.
meanings_apart :-
    section('sentences alike and apart in meaning'),
    forall(member(T-Want-Back, [
               'Every human is mortal.'-'mortal(A) :-\n    human(A).\n'-'Every human is mortal.',
               'Something is mortal.'-'mortal(something).\n'-'Something is mortal.',
               'Something is mortal if it is human.'-'mortal(A) :-\n    human(A).\n'-'Every human is mortal.',
               'A human was mortal.'-'human(a(human)).\npast(mortal(a(human))).\n'-'A human was mortal.',
               'Something is red. Something is blue.'-'red(something).\nblue(something_2).\n'-'Something is red. Something is blue.',
               'Someone sleeps. Someone sings.'-'is_sleep(someone).\nsing(someone_2).\n'-'Someone sleeps. Someone sings.',
               'John sees a dog. Mary sees a dog.'-'dog(a(dog)).\nsee(john, a(dog)).\ndog(a(dog, 2)).\nsee(mary, a(dog, 2)).\n'-'John sees a dog. Mary sees a dog.',
               'A dog sees a dog.'-'dog(a(dog)).\ndog(a(dog, 2)).\nsee(a(dog), a(dog, 2)).\n'-'A dog sees a dog.',
               'A dog barked. A dog slept. It sang.'-'dog(a(dog)).\npast(bark(a(dog))).\ndog(a(dog, 2)).\npast(is_sleep(a(dog, 2))).\npast(sing(a(dog, 2))).\n'-'A dog barked. A dog slept. It sang.',
               'A dog barks. It sleeps.'-'bark(A) :-\n    dog(A).\nis_sleep(A) :-\n    dog(A).\n'-'Every dog barks. Every dog sleeps.',
               'A dog barked. It slept.'-'dog(a(dog)).\npast(bark(a(dog))).\npast(is_sleep(a(dog))).\n'-'A dog barked. It slept.',
               'Took the joke well. Took the money.'-'past(well(take(someone, the(joke)))).\npast(take(someone, the(money))).\n'-'Someone took the joke well. Someone took the money.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )),
    logic_readings(english, 'A human is mortal.', Us2),
    length(Us2, N2),
    check('a generic subject has a rule and an individual: two readings', N2, 2),
    once(logic_readings(english, 'Every human is mortal.', [U3|_])),
    once(logic_readings(english, 'Something is mortal.', [U4|_])),
    ( U3 == U4 -> R5 = same ; R5 = apart ),
    check('every human and something: two meanings', R5, apart).

%% 1.90.0: an adverb that grades an adjective is round the adjective's atom,
%% and in a term round the adjective's wrap; an adverb that is an
%% adjective too (good) is the old reading's adjective.
graded_adjectives :-
    section('an adverb that grades an adjective'),
    forall(member(T-Want-Back, [
               'She was incurably optimistic.'-'past(incurably(optimistic(she))).\n'-'She was incurably optimistic.',
               'A perfectly natural explanation.'-'explanation(a(perfectly(natural(explanation)))).\nperfectly(natural(a(perfectly(natural(explanation))))).\n'-'A perfectly natural explanation.',
               'The boy sees a very big dog.'-'dog(a(very(big(dog)))).\nvery(big(a(very(big(dog))))).\nsee(the(boy), a(very(big(dog)))).\n'-'The boy sees a very big dog.',
               'He was blissfully unaware of the danger.'-'past(of(blissfully(unaware(he)), the(danger))).\n'-'He was blissfully unaware of the danger.',
               'Who sees a very big dog?'-'?- see(A, B), dog(B), very(big(B)).\n'-'Who sees a very big dog?',
               'Good taste.'-'taste(good(taste)).\ngood(good(taste)).\n'-'Good taste.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.91.0: AN ADJECTIVE WITH AN ADPOSITION PHRASE IN A NOUN PHRASE is in
%% the noun phrase's term, A(T, Prep, X), and said of it as a copula's
%% phrase is, the adjective's atom inside the phrase; the phrase's
%% individual's facts come after. A clause's adjunct stays the clause's.
adjectives_after_noun :-
    section('an adjective with an adposition phrase in a noun phrase'),
    forall(member(T-Want-Back, [
               'A calyx adnate to the ovary.'-'calyx(a(adnate(calyx, to, the(ovary)))).\nto(adnate(a(adnate(calyx, to, the(ovary)))), the(ovary)).\n'-'A calyx adnate to the ovary.',
               'He sees a man proud of his son.'-'man(a(proud(man, of, of(son, he)))).\nof(proud(a(proud(man, of, of(son, he)))), of(son, he)).\nsee(he, a(proud(man, of, of(son, he)))).\n'-'He sees a man proud of his son.',
               'The man proud of his son sleeps.'-'is_sleep(the(proud(man, of, of(son, he)))).\n'-'The man proud of his son sleeps.',
               'A book full of errors.'-'book(a(full(book, of, a(pl(error))))).\nof(full(a(full(book, of, a(pl(error))))), a(pl(error))).\nerror(a(pl(error))).\n'-'A book full of errors.',
               'A dog sleeps in the house.'-'in(is_sleep(A), the(house)) :-\n    dog(A).\n'-'Every dog sleeps in the house.',
               'He was aware of the danger.'-'past(of(aware(he), the(danger))).\n'-'He was aware of the danger.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.92.0: AN ADJECTIVE WRITTEN WITH A CAPITAL is its meaning's atom, as
%% any adjective is, and its capital is put back where English is written.
capital_adjectives :-
    section('an adjective written with a capital'),
    forall(member(T-Want-Back, [
               'The Guyanese capital.'-'capital(the(guyanese(capital))).\nguyanese(the(guyanese(capital))).\n'-'The Guyanese capital.',
               'American cars are big.'-'big(A) :-\n    car(A),\n    american(A).\n'-'A car is big if it is American.',
               'He left an indelible mark on the American theater.'-'mark(a(indelible(mark))).\nindelible(a(indelible(mark))).\npast(on(leave(he, a(indelible(mark))), the(american(theater)))).\n'-'He left an indelible mark on the American theater.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.93.0: A BARE NOUN AFTER `of' is a constant of its own, as any bare
%% noun is, and the possessed's term holds it.
of_bare_nouns :-
    section('a bare noun after of'),
    forall(member(T-Want-Back, [
               'The incarnation of evil.'-'incarnation(of(incarnation, evil)).\n'-'The incarnation of evil.',
               'He felt a stream of air.'-'stream(a(of(stream, air))).\npast(feel(he, a(of(stream, air)))).\n'-'He felt a stream of air.',
               'A man of quality.'-'man(a(of(man, quality))).\n'-'A man of quality.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.94.0: A PHRASAL VERB is one predicate, its meaning's name
%% (`throw_out'), and English says it back with its particle.
phrasal_verbs :-
    section('a verb with a particle'),
    forall(member(T-Want-Back, [
               'The mayor threw out the first ball.'-'past(throw_out(the(mayor), the(first(ball)))).\n'-'The mayor threw out the first ball.',
               'An opportunity opened up.'-'opportunity(a(opportunity)).\npast(open_up(a(opportunity))).\n'-'An opportunity opened up.',
               'The plane touched down at noon.'-'past(at(touch_down(the(plane)), noon)).\n'-'The plane touched down at noon.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.95.0: AN INFINITIVE AS A VERB'S OBJECT is the term to(Atom), its atom
%% said of the clause's own subject; an indefinite noun phrase in it is a
%% term a(Shape) and no fact.
infinitives :-
    section('an infinitive as a verb\'s object'),
    forall(member(T-Want-Back, [
               'He tried to catch her eye.'-'past(try(he, to(catch(he, of(eye, she))))).\n'-'He tried to catch her eye.',
               'The company tried to project an altruistic image.'-'past(try(the(company), to(project(the(company), a(altruistic(image)))))).\n'-'The company tried to project an altruistic image.',
               'Demographers try to predict social fluidity.'-'try(A, to(predict(A, social(fluidity)))) :-\n    demographer(A).\n'-'Every demographer tries to predict social fluidity.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.96.0: AN INFINITIVE AFTER A NOUN, AN ADJECTIVE AND AN OBJECT, AND OF
%% PURPOSE. A noun's is a constant to(Noun, Atom) of an individual, its
%% atom said of someone; an adjective's the adjective's second argument,
%% to(Atom) said of the subject; after a verb whose object is the
%% infinitive's subject, to(Atom) said of the object; one of purpose the
%% term to(Atom, Atom2), Atom2 said of the subject. `in order' is not said
%% back.
infinitive_places :-
    section('an infinitive after a noun, an adjective and an object, and of purpose'),
    forall(member(T-Want-Back, [
               'A knowing attempt to defraud.'-'attempt(a(to(knowing(attempt), defraud(someone)))).\nknowing(a(to(knowing(attempt), defraud(someone)))).\n'-'A knowing attempt to defraud.',
               'They made arrangements to meet in Chicago.'-'arrangement(a(to(pl(arrangement), in(meet(someone), chicago)))).\npast(make(they, a(to(pl(arrangement), in(meet(someone), chicago))))).\n'-'They made arrangements to meet in Chicago.',
               'He is glad to help.'-'glad(he, to(help(he))).\n'-'He is glad to help.',
               'Dogs are able to swim.'-'able(A, to(swim(A))) :-\n    dog(A).\n'-'Every dog is able to swim.',
               'He asked her to leave the room.'-'past(ask(he, to(leave(she, the(room))))).\n'-'He asked her to leave the room.',
               'He wanted a stone to mark the site.'-'stone(a(stone)).\npast(want(he, to(mark(a(stone), the(site))))).\n'-'He wanted a stone to mark the site.',
               'He used pressure to stop the bleeding.'-'past(to(use(he, pressure), stop(he, the(bleeding)))).\n'-'He used pressure to stop the bleeding.',
               'He saved money in order to buy a house.'-'past(to(save(he, money), buy(he, a(house)))).\n'-'He saved money to buy a house.',
               'He had to sell his car at a considerable sacrifice.'-'past(have(he, to(at(sell(he, of(car, he)), a(considerable(sacrifice)))))).\n'-'He had to sell his car at a considerable sacrifice.',
               'He tried to find out by indirection.'-'past(try(he, to(by(find_out(he), indirection)))).\n'-'He tried to find out by indirection.' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['into Cocolog and back: ', T], Label),
             check(Label, C-E, Want-Back) )).

%% 1.97.0: THE INFINITIVE OF THE OTHER LANGUAGES has the logic form and the
%% Cocolog of English's.
infinitive_languages :-
    section('the infinitive in the other languages'),
    forall(member(L-T-Want, [
               spanish-'El niño quiere ver al perro.'-'want(the(boy), to(see(the(boy), the(dog)))).\n',
               italian-'Il ragazzo vuole vedere il cane.'-'want(the(boy), to(see(the(boy), the(dog)))).\n',
               german-'Der Junge versucht den Hund zu sehen.'-'try(the(boy), to(see(the(boy), the(dog)))).\n' ]),
           ( typology_load(L),
             ( logic_translate(L, cocolog, T, C) -> true ; C = none ),
             one_line([L, ' into Cocolog: ', T], Label),
             check(Label, C, Want) )).

%% 1.98.0: the passive is its active, the agent `by NP' its subject, else
%% someone; an object's infinitive is the patient's. Back into English it
%% is the active.
passive :-
    section('the passive'),
    typology_load(english),
    forall(member(T-Want, [
               'The pass was fumbled.'-'past(fumble(someone, the(pass))).\n',
               'The house was built by the workers.'-'past(build(the(pl(worker)), the(house))).\n',
               'He had been trained rigorously by the monks.'-'pluperfect(rigorously(train(the(pl(monk)), he))).\n',
               'He was asked to leave the room.'-'past(ask(someone, to(leave(he, the(room))))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'past(build(the(pl(worker)), the(house))).\n', E) -> true ; E = none ),
    check('back into English, the active', E, 'The workers built the house.').

%% 1.99.0: a passive infinitive's patient is the clause's own subject, and
%% back into English the passive infinitive; a passive with no subject and
%% an agent is said of someone, an object as a subject is; with neither it
%% has no Cocolog; an adverb inside the verb's words is round its atom.
passive_places :-
    section('the passive in more places, and an adverb inside the verb'),
    typology_load(english),
    forall(member(T-Want, [
               'The machine needs to be serviced.'-'need(the(machine), to(service(someone, the(machine)))).\n',
               'Was praised by the critics.'-'past(praise(the(pl(critic)), someone)).\n',
               'Was fed.'-none,
               'The area is well populated.'-'well(populate(someone, the(area))).\n',
               'He promptly forgot the address.'-'past(promptly(forget(he, the(address)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'need(the(machine), to(service(someone, the(machine)))).\n', E1) -> true ; E1 = none ),
    check('back into English, the passive infinitive', E1, 'The machine needs to be serviced.'),
    ( logic_translate(cocolog, english, 'past(praise(the(pl(critic)), someone)).\n', E2) -> true ; E2 = none ),
    check('someone as an object, back into English', E2, 'The critics praised someone.').

%% 1.102.0: the progressive is a tense of its own in Cocolog, its name the
%% template's (progressive, past_progressive, perfect_progressive ...).
progressive :-
    section('the progressive'),
    typology_load(english),
    forall(member(T-Want, [
               'The engine is idling.'-'progressive(idle(the(engine))).\n',
               'The water was purling.'-'past_progressive(purl(the(water))).\n',
               'The house is being built.'-'progressive(build(someone, the(house))).\n',
               'The dog was being fed by the boy.'-'past_progressive(feed(the(boy), the(dog))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'perfect_progressive(watch(they, the(dog))).\n', E) -> true ; E = none ),
    check('back into English, the perfect progressive', E, 'They have been watching the dog.').

%% 1.100.0: an object's complement is the verb's third argument, the atom a
%% copula would make of the object; a passive's is its active's; back into
%% English the complement. 1.103.0: a noun phrase of several atoms is its
%% term, a(Shape) or a constant; a verb with no complement takes none.
object_complement :-
    section('an object and its complement'),
    typology_load(english),
    forall(member(T-Want, [
               'He considered the dog small.'-'past(consider(he, the(dog), small(the(dog)))).\n',
               'The dog was considered small.'-'past(consider(someone, the(dog), small(the(dog)))).\n',
               'The boy called the dog a hero.'-'past(is_call(the(boy), the(dog), hero(the(dog)))).\n',
               'The accident left her badly shaken.'-'past(leave(the(accident), she, badly(shaken(she)))).\n',
               'He found the dog a big hero.'-'past(find(he, the(dog), a(big(hero)))).\n',
               'The satellite was considered a necessary research step.'-'past(consider(someone, the(satellite), a(necessary(nn(research, step))))).\n',
               'He found the dog the best friend.'-'past(find(he, the(dog), the(best(friend)))).\n',
               'He considered the dog rich and famous.'-none ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, [
               'past(consider(he, the(dog), small(the(dog)))).\n'-'He considered the dog small.',
               'past(leave(the(accident), she, badly(shaken(she)))).\n'-'The accident left her badly shaken.',
               'past(find(he, the(dog), a(big(hero)))).\n'-'He found the dog a big hero.',
               'past(paint(they, it, a(of(light(shade), bluish(green))))).\n'-'They painted it a light shade of bluish green.',
               'past(see(he, the(dog), a(big(hero)))).\n'-'See holds for he, the(dog) and a(big(hero)) in the past.' ]),
           ( ( logic_translate(cocolog, english, C2, E) -> true ; E = none ),
             one_line(['back into English: ', C2], Label2),
             check(Label2, E, Want2) )).

%% Each clause of a Cocolog text asserted.
assert_text(P) :-
    atomic_list_concat(Ps, '.\n', P),
    forall(( member(S, Ps), S \== '' ), ( term_string(Cl, S), assertz(Cl) )).

%% A test's own predicates: what the clauses written from English assert.
:- dynamic is_sleep/1, past/1, book/1, stamp/1, father/2, when/2, coat/1, heavy/1, warm/1, imperative/1, old/1, at/2.
