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
                      adjuncts, pronouns, possessors, objects, plurals, terms, individuals, relations, whens, phrases, commands, noun_adpositions, prepositions, unsaid_subjects, noun_modifiers, adjective_phrases, meanings_apart, graded_adjectives, adjectives_after_noun, capital_adjectives, of_bare_nouns, phrasal_verbs, infinitives, infinitive_places, infinitive_languages, passive, passive_places, object_complement, progressive, adjunct_first, passive_perfect, count_words, modals, negation, existential, adjective_alone, operator_names, ones, article_names, two_objects, predeterminers, possessed_heads, comparatives, demonstratives, linking_verbs, every_words, long_words, such_words, reflexives, numbers_and_groups, hyphen_words, dash_words, particles, grading_words, unsaid_copula, small_words, but_words, joined_terms, relatives, more_grammar_words, gerund_places, quantified_args, copula_names, relation_names, copula_tails, clause_objects, parts_and_equals, adverbs_and_articles]), once(S)),
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
               'The dog is not big and black.'-negation,
               'Every boy sees a dog.'-object(generic),
               'The boy sleeps because the dog sleeps.'-subordinate(because),
               'He did not read every book.'-negation,
               'Every boy sees no dog.'-object(quantifier),
               'He feared the decline of every man.'-possessor(every),
               'John sleeps with every dog and a cat.'-joined(quantifier),
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
    check('the second measure: its sentences', N, 691),
    ( R >= 681 -> VR = ok ; VR = R ),
    check('the second measure: English into Cocolog, at least 681 right', VR, ok),
    ( K >= 682 -> VK = ok ; VK = K ),
    check('the second measure: Cocolog into English and back, at least 682 kept', VK, ok).

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
    ( logic_translate(cocolog, english, 'can(append(a, b, c)).', E5a) -> true ; E5a = none ),
    check('a modal in a general sentence', E5a, 'It can be that append holds for a, b and c.'),
    ( logic_translate(cocolog, english, 'conditional(append(a, b, c)).', E5b) -> true ; E5b = none ),
    check('the conditional in a general sentence', E5b, 'It would be that append holds for a, b and c.'),
    ( cocolog_read('past(the(war)).', U6) -> true ; U6 = none ),
    check('a tense\'s name before no compound term is a predicate', U6,
          utterance(assertion, [fact(pred(past, [const(the(war))]))])),
    ( logic_translate(english, cocolog, 'John would sleep.', C7) -> true ; C7 = none ),
    check('the conditional has its logic form (since 1.108.0)', C7, 'conditional(is_sleep(john)).\n'),
    ( logic_why(clause(sleep, infinitive, pos, name('John'), none), W8) -> true ; W8 = none ),
    check('an infinitive alone has no logic form', W8, tense(infinitive)).

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
    once(typology_read(english, 'John sleeps with an old dog.', IR6)),
    ( logic_from_ir(IR6, _) -> W6 = read ; logic_why(IR6, W6) ),
    check('an adjunct\'s indefinite noun phrase', W6, read),
    ( logic_translate(english, cocolog, 'John sleeps with every dog.', C7) -> true ; C7 = none ),
    check('an adjunct\'s noun phrase of every (since 1.139.0)', C7, 'with(is_sleep(john), A) :-\n    dog(A).\n').

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
    once(typology_read(english, 'He is one hell of a jumper.', IR4)),
    logic_why(IR4, W4),
    check('a relation with a number word has no form (one with an adjective since 1.141.0)', W4, relation(adjective)),
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
    forall(member(T6-Want6, ['Him.'-phrase(pron), 'Every dog.'-phrase(every)]),
           ( once(typology_read(english, T6, IR6)),
             ( logic_from_ir(IR6, _) -> W6 = read ; logic_why(IR6, W6) ),
             atomic_list_concat(['no form yet: ', T6], L6),
             check(L6, W6, Want6) )),
    forall(member(T7, ['A heavy coat.', 'A warm coat.']),
           ( logic_translate(english, cocolog, T7, P7), assert_text(P7) )),
    findall(X7, coat(X7), Xs7),
    check('a query of the coats the phrases say', Xs7, [a(heavy(coat)), a(warm(coat))]),
    %% 1.104.0: an adposition phrase alone is said of something.
    forall(member(T8-Want8, [
               'In direct sunlight.'-'in(something, direct(sunlight)).\n',
               'With dry eyes.'-'eye(a(pl(dry(eye)))).\ndry(a(pl(dry(eye)))).\nwith(something, a(pl(dry(eye)))).\n' ]),
           ( ( logic_translate(english, cocolog, T8, C8) -> true ; C8 = none ),
             one_line(['a phrase into Cocolog: ', T8], Label8),
             check(Label8, C8, Want8) )),
    ( logic_translate(cocolog, english, 'in(something, direct(sunlight)).\n', E9) -> true ; E9 = none ),
    check('and back into English, a copula of something', E9, 'Something is in direct sunlight.').

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
    ( logic_translate(english, cocolog, 'Do not open the door.', C4) -> true ; C4 = none ),
    check('a command not to: its negation (since 1.109.0)', C4, 'is_not(imperative(open(you, the(door)))).\n'),
    ( logic_translate(cocolog, english, C4, E4) -> true ; E4 = none ),
    check('and back into English', E4, 'Do not open the door.'),
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
               'past(paint(they, it, light_shade(it, bluish(green)))).\n'-'They painted it the light shade of bluish green.',
               'past(see(he, the(dog), a(big(hero)))).\n'-'See holds for he, the(dog) and a(big(hero)) in the past.' ]),
           ( ( logic_translate(cocolog, english, C2, E) -> true ; E = none ),
             one_line(['back into English: ', C2], Label2),
             check(Label2, E, Want2) )).

%% 1.105.0: an adjunct before the subject is a clause's adjunct as any is,
%% the last; back into English it stands at the end.
adjunct_first :-
    section('an adjunct before the subject'),
    typology_load(english),
    forall(member(T-Want, [
               'In England they call a fender a wing.'-'fender(a(fender)).\nin(is_call(they, a(fender), wing(a(fender))), england).\n',
               'Suddenly the dog barked.'-'past(suddenly(bark(the(dog)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'past(suddenly(bark(the(dog)))).\n', E) -> true ; E = none ),
    check('back into English, the adverb at the end', E, 'The dog barked suddenly.').

%% 1.106.0: the Italian and the German perfect passive are the active's
%% perfect at level 2, as English's is.
passive_perfect :-
    section('the perfect passive in Italian and German'),
    typology_load(german),
    forall(member(L-T-Want, [
               italian-'La ragazza è stata vista dal ragazzo.'-'perfect(see(the(boy), the(girl))).\n',
               german-'Das Mädchen ist vom Jungen gesehen worden.'-'perfect(see(the(boy), the(girl))).\n',
               english-'The girl has been seen by the boy.'-'perfect(see(the(boy), the(girl))).\n' ]),
           ( ( logic_translate(L, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )).

%% 1.107.0: a number or a quantifier is an indefinite noun phrase with the
%% word its first modifier, as several is an adjective; and back.
count_words :-
    section('a number or a quantifier'),
    typology_load(english),
    forall(member(T-Want, [
               'The board has seven members.'-'member(a(pl(seven(member)))).\nseven(a(pl(seven(member)))).\nhave(the(board), a(pl(seven(member)))).\n',
               'Two dogs slept.'-'dog(a(pl(two(dog)))).\ntwo(a(pl(two(dog)))).\npast(is_sleep(a(pl(two(dog))))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'member(a(pl(seven(member)))).\nseven(a(pl(seven(member)))).\nhave(the(board), a(pl(seven(member)))).\n', E) -> true ; E = none ),
    check('back into English, the determiner', E, 'The board has seven members.').

%% 1.108.0: the conditional and the modals, each its own name in Cocolog,
%% read back into its tense.
modals :-
    section('the conditional and the modals'),
    typology_load(english),
    forall(member(T-Want, [
               'He can hear the snap of a twig.'-'twig(a(twig)).\ncan(hear(he, of(snap, a(twig)))).\n',
               'The dog would sleep.'-'conditional(is_sleep(the(dog))).\n',
               'In bridge you must follow suit.'-'must(in(follow(you, suit), bridge)).\n',
               'Our ideas must be substantiated into actions.'-'action(a(pl(action))).\nmust(into(substantiate(someone, of(pl(idea), we)), a(pl(action)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, [
               'can(hear(he, the(dog))).\n'-'He can hear the dog.',
               'conditional(is_sleep(the(dog))).\n'-'The dog would sleep.',
               'should(happy(the(dog))).\n'-'The dog should be happy.' ]),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['back into English: ', Want2], Label2),
             check(Label2, E2, Want2) )).

%% 1.109.0: a negation round the clause's one atom and its tense.
negation :-
    section('a negation'),
    typology_load(english),
    forall(member(T-Want, [
               'John did not sleep.'-'is_not(past(is_sleep(john))).\n',
               'The priest could not reveal her confidences.'-'is_not(could(reveal(the(priest), of(pl(confidence), she)))).\n',
               'If John does not sleep Mary sings.'-'sing(mary) :-\n    is_not(is_sleep(john)).\n',
               'He could not suppress a yawn.'-'yawn(a(yawn)).\nis_not(could(suppress(he, a(yawn)))).\n',
               'They didn\'t follow our lead.'-'is_not(past(follow(they, of(lead, we)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    forall(member(C2-Want2, [
               'is_not(past(is_sleep(john))).\n'-'John did not sleep.',
               'is_not(could(reveal(the(priest), of(pl(confidence), she)))).\n'-'The priest could not reveal her confidences.',
               'is_not(append(a, b, c)).\n'-'It is not so that append holds for a, b and c.' ]),
           ( ( logic_translate(cocolog, english, C2, E2) -> true ; E2 = none ),
             one_line(['back into English: ', Want2], Label2),
             check(Label2, E2, Want2) )),
    ( cocolog_read('is_not(the(war)).', U3) -> true ; U3 = none ),
    check('is_not of no compound term is a predicate', U3, utterance(assertion, [fact(pred(not, [const(the(war))]))])).

%% 1.111.0: a noun phrase's existence, in the present the phrase alone, in
%% another tense the clause of exist.
%% 1.116.0: a name with its article is a constant the_Name, its article
%% small when it is written back.
article_names :-
    section('a name with its article'),
    typology_load(english),
    forall(member(T-Want, [
               'The Earth is an ellipsoid.'-'ellipsoid(the_earth).\n',
               'The Missouri feeds into the Mississippi.'-'into(feed(the_missouri), the_mississippi).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.126.0: a reflexive pronoun has no form at level 2 yet.
%% 1.127.0: a reflexive is its clause's subject where that is a constant,
%% and back from Cocolog a reflexive again.
reflexives :-
    section('reflexive pronouns'),
    typology_load(english),
    logic_translate(english, cocolog, 'She expressed herself pithily.', C1),
    check('a reflexive is its subject', C1, 'past(pithily(express(she, she))).\n'),
    logic_translate(cocolog, english, C1, E1),
    check('and back, a reflexive', E1, 'She expressed herself pithily.'),
    once(typology_read(english, 'Perfectly poised and sure of himself.', IR)),
    ( logic_from_ir(IR, _) -> W = read ; logic_why(IR, W) ),
    check('a reflexive with no subject has no logic form', W, pronoun(reflexive)).

%% 1.138.0: a gerund after an adposition, after `of' and as a verb's
%% object is the constant ing(Atom) where its term stands, its atom said of
%% someone; an adposition of several words is one predicate
%% (because_of/2); an adjective `too' grades with its infinitive is the
%% adverb round the adjective's predicate of two.
%% 1.139.0: `this' and `that' alone are constants; `no' is `every' and
%% the clause denied; `every', `no' and `any' where a constant's clause has
%% its object, an adposition's or an adjunct's noun phrase make a rule over
%% that noun phrase's variable, an individual beside it a constant whose
%% facts come first; `some' before a noun that is no subject is its first
%% modifier. Back, a denied rule says its variable by `no', and a rule
%% whose variable is no subject by `every'.
%% 1.140.0: a copula's definite noun phrase is same(Subject, Term); a
%% copula's noun phrase with a relative clause is the noun phrase's atoms
%% and the clause's said of the subject (of a definite head, of the head);
%% a command of a verb no row has is a command; a noun phrase of time is
%% at_time(Atom, Term), `every' a rule over it; a command in a general
%% sentence is asked.
%% 1.141.0: a noun of relation with adjectives is one name, the words
%% joined (a number's word and `own' none); `as' is a subordinator; a
%% complement of adjectives joined is and(F1, ..., Fn); `such' before an
%% indefinite noun phrase is its first modifier, none in a copula's
%% predicate.
relation_names :-
    section('a noun of relation with adjectives, as, a complement of adjectives, such'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'She was his main squeeze.'-'past(main_squeeze(she, he)).\n'-same,
               'Gossip was the main business of the evening.'-'past(main_business(gossip, the(evening))).\n'-'Gossip was the evening\'s main business.',
               'Open-angle glaucoma is the most common type of glaucoma.'-'most_common_type(nn(\'open-angle\', glaucoma), glaucoma).\n'-'Open-angle glaucoma is glaucoma\'s most common type.',
               'Their closeness grew as the night wore on.'-'is_as(past(grow(of(closeness, they))), past(wear_on(the(night)))).\n'-same,
               'His arguments seemed shallow and tedious.'-'past(seem(of(pl(argument), he), and(shallow(of(pl(argument), he)), tedious(of(pl(argument), he))))).\n'-same,
               'He could barely exist on such a low wage.'-'wage(a(such(low(wage)))).\nlow(a(such(low(wage)))).\ncould(on(barely(exist(he)), a(such(low(wage))))).\n'-'He could exist barely on such a low wage.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    forall(member(S2, ['He is one hell of a jumper.', 'He is such a baby.']),
           ( ( logic_translate(english, cocolog, S2, C2) -> true ; C2 = none ),
             atomic_list_concat(['no form: ', S2], L2),
             check(L2, C2, none) )).

clause_objects :-
    section('a clause as a verb object, an adverb before a copula noun phrase, all over'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'He claimed that the evidence was a plant.'-'past(claim(he, that(past(plant(the(evidence)))))).\n'-same,
               'He believes that she has a soul.'-'believe(he, that(have(she, a(soul)))).\n'-same,
               'He feels that you are in the wrong.'-'feel(he, that(in(you, the(wrong)))).\n'-same,
               'He is still a child.'-'still(child(he)).\n'-same,
               'The holding company was just a blind.'-'past(just(blind(the(nn(holding, company))))).\n'-same,
               'She was clearly the gainer in that exchange.'-'past(clearly(same(she, the(gainer)))).\npast(in(she, that(exchange))).\n'-'She was clearly the gainer. She was in that exchange.',
               'Spill the beans all over the table.'-'imperative(all_over(spill(you, the(pl(bean))), the(table))).\n'-same ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )).

parts_and_equals :-
    section('an equative, a part of a noun phrase, rather than, a floating all, an adverb before a phrasal verb'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'He is as tall as his father.'-'as_tall(he, of(father, he)).\n'-same,
               'One of the boys came.'-'past(come(one_of(the(pl(boy))))).\n'-same,
               'Each of them came.'-'past(come(each_of(they))).\n'-same,
               'Much of the land is dry.'-'dry(much_of(the(land))).\n'-same,
               'All of the boys came.'-'past(come(all(the(pl(boy))))).\n'-'All the boys came.',
               'The house is big rather than small.'-'big(the(house)).\nis_not(small(the(house))).\n'-'The house is big. The house is not small.',
               'Totem poles are modern rather than prehistoric.'-'modern(A) :-\n    pole(A),\n    nn(totem, A).\nis_not(prehistoric(A)) :-\n    pole(A),\n    nn(totem, A).\n'-'Every totem pole is modern. No totem pole is prehistoric.',
               'The reviews were all positive.'-'past(positive(all(the(pl(review))))).\n'-'All the reviews were positive.',
               'He suddenly gave up.'-'past(suddenly(give_up(he))).\n'-'He gave up suddenly.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(english, cocolog, 'None of her sisters would betray her.', C2) -> true ; C2 = none ),
    check('a part of none has no form yet', C2, none).

adverbs_and_articles :-
    section('so, those who, adjectives joined by or, a few, a possessor in a possessed head, no longer, please'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'Treat the water so it can be drunk.'-'so(imperative(treat(you, the(water))), can(drunk(it))).\n'-same,
               'He works so he can eat.'-'so(work(he), can(eat(he))).\n'-same,
               'He forgave those who had harmed him.'-'past(forgive(he, A)) :-\n    pluperfect(harm(A, he)).\n'-'Forgive holds for he and X in the past if harm holds for X and he in the past.',
               'His hair was red or brown.'-'past(red_or_brown(of(hair, he))).\n'-same,
               'He made a few remarks.'-'remark(a(pl(a_few(remark)))).\na_few(a(pl(a_few(remark)))).\npast(make(he, a(pl(a_few(remark))))).\n'-same,
               'The world\'s heritage of knowledge.'-'heritage(of(of(heritage, the(world)), knowledge)).\n'-same,
               'A nation\'s balance of trade is favorable.'-'nation(a(nation)).\nfavorable(of(of(balance, a(nation)), trade)).\n'-same,
               'He determined the upper bound with Descartes\' rule of signs.'-'sign(a(pl(sign))).\npast(with(determine(he, the(upper(bound))), of(of(rule, descartes), a(pl(sign))))).\n'-same,
               'He could no longer contain his hostility.'-'could(no_longer(contain(he, of(hostility, he)))).\n'-'He could contain his hostility no longer.',
               'Refill my glass, please.'-'imperative(please(refill(you, of(glass, i)))).\n'-'Refill my glass please.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(english, cocolog, 'Close the door if it rains.', C2) -> true ; C2 = none ),
    check('a command under if has no form yet', C2, none).

copula_tails :-
    section('a copula noun phrase with an adposition phrase, a gerund noun, a particle verb passive'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'He is a man with a hat.'-'hat(a(hat)).\nwith(he, a(hat)).\nman(he).\n'-'He is with a hat. He is a man.',
               'He was a hero in the war.'-'past(hero(he)).\npast(in(he, the(war))).\n'-'He was a hero. He was in the war.',
               'He was the hero in the war.'-'past(same(he, the(hero))).\npast(in(he, the(war))).\n'-'He was the hero. He was in the war.',
               'Vodka is an unaged liquor from Russia.'-'liquor(vodka).\nunaged(vodka).\nfrom(vodka, russia).\n'-'Vodka is a liquor. Vodka is unaged. Vodka is from Russia.',
               'The harvesting was complete.'-'past(complete(the(harvesting))).\n'-same,
               'He gave the brat a good spanking.'-'spanking(a(good(spanking))).\ngood(a(good(spanking))).\npast(give(he, the(brat), a(good(spanking)))).\n'-same,
               'The supernatant fat was skimmed off.'-'past(skim_off(someone, the(supernatant(fat)))).\n'-'Someone skimmed off the supernatant fat.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )).

copula_names :-
    section('the same thing, a predicate with a relative clause, commands and times'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'Leather is the latest vogue.'-'same(leather, the(latest(vogue))).\n'-same,
               'That was not the case.'-'is_not(past(same(that, the(case)))).\n'-same,
               'He is a man who enjoys his comfort.'-'enjoy(he, of(comfort, he)).\nman(he).\n'-'He enjoys his comfort. He is a man.',
               'An integer is a number that is not a fraction.'-'is_number(A) :-\n    is_integer(A).\nis_not(fraction(A)) :-\n    is_integer(A).\n'-'Every integer is a number. No integer is a fraction.',
               'Tar the roads.'-'imperative(tar(you, the(pl(road)))).\n'-same,
               'He painted all day in the garden.'-'past(in(at_time(paint(he), all(day)), the(garden))).\n'-same,
               'She topped her class every year.'-'past(at_time(top(she, of(class, she)), A)) :-\n    year(A).\n'-same,
               'The plant sprouted early this year.'-'past(at_time(early(sprout(the(plant))), this(year))).\n'-same ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(cocolog, english, 'imperative(foo(you, bar)).\n', E2) -> true ; E2 = none ),
    check('a command in a general sentence is asked', E2, 'It is asked that foo holds for you and bar.').

quantified_args :-
    section('this and that alone; no; every, any and some that are no subject'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'That is cool.'-'cool(that).\n'-same,
               'This immediately concerns your future.'-'immediately(concern(this, of(future, you))).\n'-'This concerns your future immediately.',
               'No dog barks.'-'is_not(bark(A)) :-\n    dog(A).\n'-same,
               'No one heard him.'-'is_not(past(hear(_, he))).\n'-'Nobody heard him.',
               'We have no bananas.'-'is_not(have(we, A)) :-\n    banana(A).\n'-'We have no banana.',
               'You are in no danger.'-'is_not(in(you, A)) :-\n    danger(A).\n'-same,
               'He reads every big book.'-'is_read(he, A) :-\n    book(A),\n    big(A).\n'-same,
               'Any dog barks.'-'bark(A) :-\n    dog(A).\n'-'Every dog barks.',
               'He hadn\'t had any love in months.'-'month(a(pl(month))).\nis_not(pluperfect(in(have(he, A), a(pl(month))))) :-\n    love(A).\n'-'He had had no love in months.',
               'Felt panicked before each exam.'-'past(before(feel(someone, panicked(someone)), A)) :-\n    exam(A).\n'-'Someone felt panicked before every exam.',
               'He explored every nook with a lamp.'-'lamp(a(lamp)).\npast(with(explore(he, A), a(lamp))) :-\n    nook(A).\n'-same,
               'He had made some money on the side.'-'money(a(some(money))).\nsome(a(some(money))).\npluperfect(on(make(he, a(some(money))), the(side))).\n'-same ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(english, cocolog, 'He did not read every book.', C2) -> true ; C2 = none ),
    check('not every is no rule of every', C2, none),
    ( catch(logic_why(clause(read, present, neg, pron(3, sg, m), np(book, sg, every, [])), W), _, W = err) -> true ; W = failed ),
    check('not every says why', W, negation).

gerund_places :-
    section('the gerund after an adposition, of and a verb; because of, like; too ADJ to INF'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'He was fined for littering.'-'past(for(fine(someone, he), ing(litter(someone)))).\n'-'Someone fined him for littering.',
               'He had a special knack for getting into trouble.'-'knack(a(special(knack))).\nspecial(a(special(knack))).\npast(for(have(he, a(special(knack))), ing(into(get(someone), trouble)))).\n'-same,
               'He hated painting the ceiling.'-'past(hate(he, ing(paint(someone, the(ceiling))))).\n'-same,
               'He learned drawing from his father.'-'past(from(learn(he, ing(draw(someone))), of(father, he))).\n'-same,
               'The job of repairing the engine took several hours.'-'hour(a(pl(several(hour)))).\nseveral(a(pl(several(hour)))).\npast(take(of(job, ing(repair(someone, the(engine)))), a(pl(several(hour))))).\n'-same,
               'She could not forbear weeping.'-'is_not(could(forbear(she, ing(weep(someone))))).\n'-same,
               'He left because of the rain.'-'past(because_of(leave(he), the(rain))).\n'-same,
               'He sat in front of the house.'-'past(in_front_of(sit(he), the(house))).\n'-same,
               'He worked like a demon.'-'demon(a(demon)).\npast(like(work(he), a(demon))).\n'-same,
               'The dog is too old to run.'-'too(old(the(dog), to(run(the(dog))))).\n'-same ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(cocolog, english, 'like(they, music).\n', E2) -> true ; E2 = none ),
    check('like of two constants is the verb', E2, 'They like music.').

%% 1.137.0: a subordinate clause of though, since, until, while, unless,
%% before or after is its kind's atom over the main clause's and its own,
%% K(Main, Clause), each in its tense; a tense's atom is a clause's after
%% a subordinator though `past' is an adjective too; the copula's
%% infinitive is to(P(Subject)), an adposition phrase to(in(Subject,
%% Term)); a gerund is the constant ing(Atom), its atom said of someone,
%% and a gerund alone the progressive of someone's atom; `there' and
%% `less' are an adverb's atom.
more_grammar_words :-
    section('there, the other subordinators, to be, less, and the gerund'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'Though his associates were dishonest, he remained uncorrupted.'-'though(past(remain(he, uncorrupted(he))), past(dishonest(of(pl(associate), he)))).\n'-'He remained uncorrupted though his associates were dishonest.',
               'Combustion grew until revolt was unavoidable.'-'until(past(grow(combustion)), past(unavoidable(revolt))).\n'-same,
               'Her performance proved to be unsatisfactory.'-'past(prove(of(performance, she), to(unsatisfactory(of(performance, she))))).\n'-same,
               'The patient appeared to be in distress.'-'past(appear(the(patient), to(in(the(patient), distress)))).\n'-same,
               'Swimming is fun.'-'fun(ing(swim(someone))).\n'-same,
               'Getting that job was definitely fluky.'-'past(definitely(fluky(ing(get(someone, that(job)))))).\n'-same,
               'Jogging works off my excess energy.'-'work_off(ing(jog(someone)), of(excess(energy), i)).\n'-same,
               'Grading papers is a thankless task.'-'task(ing(grade(someone, a(pl(paper))))).\nthankless(ing(grade(someone, a(pl(paper))))).\n'-'Grading papers is a task. Grading papers is thankless.',
               'Editing a prolix manuscript.'-'manuscript(a(prolix(manuscript))).\nprolix(a(prolix(manuscript))).\nprogressive(edit(someone, a(prolix(manuscript)))).\n'-'Someone is editing a prolix manuscript.',
               'The smart set goes there.'-'there(go(the(smart(set)))).\n'-same,
               'They snobbishly excluded their less wealthy friends from the party.'-'past(from(snobbishly(exclude(they, of(pl(less(wealthy(friend))), they))), the(party))).\n'-'They excluded their less wealthy friends snobbishly from the party.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             ( Back == same -> Back1 = S ; Back1 = Back ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back1) )),
    ( logic_translate(cocolog, english, 'past(before(arrive(he), the(war))).\n', E2) -> true ; E2 = none ),
    check('before a constant is the adposition', E2, 'He arrived before the war.').

%% 1.136.0: a noun phrase with a relative clause is its head's entity,
%% the clause's atoms said of the head's term: a constant's or an
%% individual's facts, a rule's or a question's conditions; once in its
%% own tense; a rule's conclusion of no variable a fact.
relatives :-
    section('a noun phrase with a relative clause'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'The horse that won the race is a good stayer.'-'past(win(the(horse), the(race))).\nstayer(the(horse)).\ngood(the(horse)).\n'-'The horse won the race. The horse is a stayer. The horse is good.',
               'Parasitic vines that strangle the trees.'-'vine(a(pl(parasitic(vine)))).\nparasitic(a(pl(parasitic(vine)))).\nstrangle(a(pl(parasitic(vine))), the(pl(tree))).\n'-'Parasitic vines strangle the trees.',
               'Every man who is wise is happy.'-'happy(A) :-\n    man(A),\n    wise(A).\n'-'A man is happy if they are wise.',
               'Every boy sees the man who sleeps.'-'see(A, the(man)) :-\n    boy(A).\nis_sleep(the(man)).\n'-'Every boy sees the man. The man sleeps.',
               'Our neighbor was very kind about the window our son broke.'-'past(break(of(son, we), the(window))).\npast(about(very(kind(of(neighbor, we))), the(window))).\n'-'Our son broke the window. Our neighbor was very kind about the window.',
               'A favor that cannot be paid back.'-'favor(a(favor)).\nis_not(can(back(pay(someone, a(favor))))).\n'-'Someone cannot pay a favor back.',
               'This merchandise is returnable if you save the receipt.'-'returnable(this(merchandise)) :-\n    save(you, the(receipt)).\n'-'This merchandise is returnable if you save the receipt.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )),
    ( logic_translate(english, cocolog, 'Is the man who sleeps happy?', Q) -> true ; Q = none ),
    check('a question: the relative clause a condition', Q, '?- happy(the(man)), is_sleep(the(man)).\n'),
    ( once(typology_read(english, 'A man whose name is permanently stamped on our maps.', IR)) -> true ; IR = none ),
    ( logic_from_ir(IR, _) -> W = read ; logic_why(IR, W) ),
    check('a gap that is a possessor has no logic form', W, relative(possessor)).

%% 1.135.0: noun phrases joined where a term stands are one constant,
%% and(T1, ..., Tn), or(T1, ..., Tn) of constants alone; a joined subject
%% or object of `and' is a clause of each item still.
joined_terms :-
    section('noun phrases joined where a term stands, one constant'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'The city pulsated with music and excitement.'-'past(with(pulsate(the(city)), and(music, excitement))).\n'-'The city pulsated with music and excitement.',
               'The rebels had salted the fields with mines and traps.'-'mine(a(pl(mine))).\ntrap(a(pl(trap))).\npluperfect(with(salt(the(pl(rebel)), the(pl(field))), and(a(pl(mine)), a(pl(trap))))).\n'-'The rebels had salted the fields with mines and traps.',
               'The area was poor in timber and coal.'-'past(in(poor(the(area)), and(timber, coal))).\n'-'The area was poor in timber and coal.',
               'John or Mary sleeps.'-'is_sleep(or(john, mary)).\n'-'John or Mary sleeps.',
               'Heckle hemp or flax.'-'imperative(heckle(you, or(hemp, flax))).\n'-'Heckle hemp or flax.',
               'John and Mary sleep.'-'is_sleep(john).\nis_sleep(mary).\n'-'John sleeps. Mary sleeps.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )),
    ( once(typology_read(english, 'Drive a car or bus.', IR)) -> true ; IR = none ),
    ( logic_from_ir(IR, _) -> W = read ; logic_why(IR, W) ),
    check('an indefinite item of or has no logic form', W, shape(or([np(car, sg, indef, []), np(bus, sg, mass, [])]))).

%% 1.134.0: two adjectives or adverbs `but' joins are each a predicate,
%% as `and''s are; `Don't' is a command's negation.
but_words :-
    section('but joining two adjectives or adverbs, Don\'t'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'An intelligent but argumentative child.'-'child(a(intelligent(argumentative(child)))).\nintelligent(a(intelligent(argumentative(child)))).\nargumentative(a(intelligent(argumentative(child)))).\n'-'An intelligent argumentative child.',
               'His shooting was slow but accurate.'-'past(slow(of(shooting, he))).\npast(accurate(of(shooting, he))).\n'-'His shooting was slow. His shooting was accurate.',
               'The power increased gradually but imperceptibly.'-'past(imperceptibly(gradually(increase(the(power))))).\n'-'The power increased gradually and imperceptibly.',
               'Don\'t overload the car.'-'is_not(imperative(overload(you, the(car)))).\n'-'Do not overload the car.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )),
    ( once(typology_read(english, 'His shooting was slow or accurate.', IR)) -> true ; IR = none ),
    ( logic_from_ir(IR, _) -> W = read ; logic_why(IR, W) ),
    %% since 1.146.0 one predicate, slow_or_accurate (adverbs_and_articles)
    check('two adjectives or joins have a logic form', W, read).

%% 1.129.0: a dash is its two sentences' items; a joined group is
%% the(group(and(A, B))); `of' after a verb an adposition's predicate.
%% 1.133.0: a capital word read in small letters is its word's predicate.
small_words :-
    section('a capital word in small letters'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'The Confederate army was a vast grey.'-'past(grey(the(confederate(army)))).\npast(vast(the(confederate(army)))).\n'-'The confederate army was a grey. The confederate army was vast.',
               'An Englishman would interrupt a war.'-'englishman(a(englishman)).\nwar(a(war)).\nconditional(interrupt(a(englishman), a(war))).\n'-'An englishman would interrupt a war.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )).

%% 1.132.0: a copula with no subject is said of someone; `of' first.
unsaid_copula :-
    section('a copula with no subject, of first'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'Was quick to make friends.'-'past(quick(someone, to(make(someone, a(pl(friend)))))).\n'-'Someone was quick to make friends.',
               'Was red-faced with anger.'-'past(with(\'red-faced\'(someone), anger)).\n'-'Someone was red-faced with anger.',
               'The ceremony was of short duration.'-'past(of(the(ceremony), short(duration))).\n'-'The ceremony was of short duration.',
               'Of noble birth.'-'of(something, noble(birth)).\n'-'Something is of noble birth.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )),
    ( logic_translate(english, cocolog, 'To face a problem squarely.', C2) -> true ; C2 = none ),
    check('an infinitive alone: none yet', C2, none).

%% 1.131.0: an adjective's word that grades one, most, only before a
%% definite noun phrase.
grading_words :-
    section('adjectives that grade an adjective, most, only'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'The building is still unfinished.'-'still(unfinished(the(building))).\n'-'The building is still unfinished.',
               'Her beauty is only skin-deep.'-'only(\'skin-deep\'(of(beauty, she))).\n'-'Her beauty is only skin-deep.',
               'The University suspended the most recalcitrant demonstrators.'-'past(suspend(the_university, the(pl(most(recalcitrant(demonstrator)))))).\n'-'The University suspended the most recalcitrant demonstrators.',
               'He saw only his mother.'-'past(see(he, only(of(mother, he)))).\n'-'He saw only his mother.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )),
    ( logic_translate(english, cocolog, 'He gave only a crumb.', C2) -> true ; C2 = none ),
    check('only before an indefinite noun phrase: none yet', C2, none).

%% 1.130.0: a particle as an adverb or an adposition, a plural first.
particles :-
    section('particles as adverbs and adpositions, plurals first'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'The music surged up.'-'past(up(surge(the(music)))).\n'-'The music surged up.',
               'Smoke billowed up into the sky.'-'past(into(up(billow(smoke)), the(sky))).\n'-'Smoke billowed up into the sky.',
               'The veterans paraded down the street.'-'past(down(parade(the(pl(veteran))), the(street))).\n'-'The veterans paraded down the street.',
               'She awoke in the arms of her cruel undoer.'-'past(in(awake(she), of(pl(arm), of(cruel(undoer), she)))).\n'-'She awoke in her cruel undoer\'s arms.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )).

dash_words :-
    section('a dash, joined groups, of after a verb'),
    typology_load(english),
    forall(member(S-Want-Back, [
               'That intangible thing--the soul.'-'thing(that(intangible(thing))).\nintangible(that(intangible(thing))).\nsoul(the(soul)).\n'-'That intangible thing. The soul.',
               'The poor and disabled knew themselves.'-'past(know(the(group(and(poor, disabled))), the(group(and(poor, disabled))))).\n'-'The poor and disabled knew themselves.',
               'This passage smells of plagiarism.'-'of(smell(this(passage)), plagiarism).\n'-'This passage smells of plagiarism.',
               'A well-wired house.'-'house(a(\'well-wired\'(house))).\n\'well-wired\'(a(\'well-wired\'(house))).\n'-'A well-wired house.' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want),
             ( C \== none, logic_translate(cocolog, english, C, E) -> true ; E = none ),
             atomic_list_concat(['and back: ', S], Label),
             check(Label, E, Back) )).

%% 1.128.0: a hyphenated word is a quoted atom in Cocolog.
hyphen_words :-
    section('hyphenated words'),
    typology_load(english),
    logic_translate(english, cocolog, 'He is self-conscious.', C1),
    check('a hyphenated adjective', C1, '\'self-conscious\'(he).\n'),
    logic_translate(cocolog, english, C1, E1),
    check('and back', E1, 'He is self-conscious.').

%% 1.127.0: a number after a definite determiner, an emphatic reflexive, an
%% adjective as a group.
numbers_and_groups :-
    section('numbers after the article, groups, more reflexives'),
    typology_load(english),
    forall(member(S-Want, [
               'The two lovers killed themselves.'-'past(kill(the(pl(two(lover))), the(pl(two(lover))))).\n',
               'The law itself was unclear.'-'past(unclear(the(law))).\n',
               'The poor knew themselves.'-'past(know(the(group(poor)), the(group(poor)))).\n' ]),
           ( ( logic_translate(english, cocolog, S, C) -> true ; C = none ),
             check(S, C, Want) )),
    logic_translate(cocolog, english, 'past(know(the(group(poor)), the(group(poor)))).\n', E),
    check('a group back', E, 'The poor knew themselves.').

%% 1.125.0: such_as is an adposition's predicate; such before a noun phrase
%% has no form at level 2 yet.
such_words :-
    section('such and such as'),
    typology_load(english),
    ( logic_translate(english, cocolog, 'A professional field such as law.', C1) -> true ; C1 = none ),
    check('such as, into Cocolog', C1, 'field(a(such_as(professional(field), law))).\nprofessional(a(such_as(professional(field), law))).\n'),
    ( logic_translate(cocolog, english, C1, E1) -> true ; E1 = none ),
    check('and back into English', E1, 'A professional field such as law.'),
    once(typology_read(english, 'He is such a baby.', IR2)),
    ( logic_from_ir(IR2, _) -> W2 = read ; logic_why(IR2, W2) ),
    check('such before a noun phrase has no logic form yet', W2, determiner(such)).

%% 1.124.0: a long word is a word of Cocolog as any is.
long_words :-
    section('words of any length'),
    typology_load(english),
    forall(member(T-Want, [
               'It grew geometrically.'-'past(geometrically(grow(it))).\n',
               'The errors increased multiplicatively.'-'past(multiplicatively(increase(the(pl(error))))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.123.0: a word only WordNet's index has is a word of Cocolog as any is.
every_words :-
    section('every word WordNet knows'),
    typology_load(english),
    forall(member(T-Want, [
               'The cancer had metastasized.'-'pluperfect(metastasize(the(cancer))).\n',
               'She could smell the soapiness.'-'could(smell(she, the(soapiness))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.122.0: a linking verb's complement is the verb's second argument, the
%% atom a copula would make of the subject.
linking_verbs :-
    section('a linking verb and its complement'),
    typology_load(english),
    forall(member(T-Want, [
               'The situation became ugly.'-'past(become(the(situation), ugly(the(situation)))).\n',
               'He remained faithful to his wife.'-'past(to(remain(he, faithful(he)), of(wife, he))).\n',
               'The dog seems very old.'-'seem(the(dog), very(old(the(dog)))).\n',
               'Get ready.'-'imperative(get(you, ready(you))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )),
    ( logic_translate(english, cocolog, 'Dogs become old.', C3) -> true ; C3 = none ),
    check('a rule with a linking verb', C3, 'become(A, old(A)) :-\n    dog(A).\n').

%% 1.121.0: a noun phrase with a demonstrative is a constant this(T) or
%% that(T), a possessed one's this(of(T, P)).
demonstratives :-
    section('a noun phrase with a demonstrative'),
    typology_load(english),
    forall(member(T-Want, [
               'This matrix is idempotent.'-'idempotent(this(matrix)).\n',
               'He was familiar with those roads.'-'past(with(familiar(he), that(pl(road)))).\n',
               'This style of shoe is in demand.'-'in(this(of(style, shoe)), demand).\n',
               'Scratch that remark.'-'imperative(scratch(you, that(remark))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.120.0: a comparative is a predicate named by its word, of two with
%% what `than' names.
comparatives :-
    section('the comparative'),
    typology_load(english),
    forall(member(T-Want, [
               'John is taller than Mary.'-'taller(john, mary).\n',
               'John is taller.'-'taller(john).\n',
               'His second marriage was happier than the first.'-'past(happier(of(second(marriage), he), the(first))).\n',
               'The tales are more approachable than the novels.'-'more_approachable(the(pl(tale)), the(pl(novel))).\n',
               'John is better than Mary.'-'better(john, mary).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.119.0: a possessed head with its own possessive pronoun is the inner
%% possessive's term inside the outer one.
possessed_heads :-
    section('a possessed head with its own possessive pronoun'),
    typology_load(english),
    forall(member(T-Want, [
               'His love of music.'-'love(of(of(love, he), music)).\n',
               'Her acceptance of the gift encouraged him.'-'past(encourage(of(of(acceptance, she), the(gift)), he)).\n',
               'His manipulation of his friends was scandalous.'-'past(scandalous(of(of(manipulation, he), of(pl(friend), he)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.118.0: all before a definite noun phrase is the constant all(T).
predeterminers :-
    section('all before a definite noun phrase'),
    typology_load(english),
    forall(member(T-Want, [
               'All the dogs bark.'-'bark(all(the(pl(dog)))).\n',
               'He paid all his bills by check.'-'past(by(pay(he, all(of(pl(bill), he))), check)).\n',
               'Chemicals could kill all the wildlife.'-'chemical(a(pl(chemical))).\ncould(kill(a(pl(chemical)), all(the(wildlife)))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.117.0: a verb with two objects is a predicate of three, the subject,
%% the one the thing goes to and the thing.
two_objects :-
    section('a verb with two objects'),
    typology_load(english),
    forall(member(T-Want, [
               'John gives Mary the book.'-'give(john, mary, the(book)).\n',
               'He gave the customer a demonstration.'-'demonstration(a(demonstration)).\npast(give(he, the(customer), a(demonstration))).\n',
               'Does John give Mary the book?'-'?- give(john, mary, the(book)).\n',
               'Who gave Mary the book?'-'?- past(give(A, mary, the(book))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want),
             ( logic_translate(cocolog, english, C, E) -> true ; E = none ),
             one_line(['and back into English: ', T], Label2),
             check(Label2, E, T) )).

%% 1.115.0: `one's' is someone's at level 2, and a possessor someone is
%% `one's' in English.
ones :-
    section('one\'s'),
    typology_load(english),
    ( logic_translate(english, cocolog, 'Catch one\'s breath.', C1) -> true ; C1 = none ),
    check('into Cocolog', C1, 'imperative(catch(you, of(breath, someone))).\n'),
    ( logic_translate(cocolog, english, C1, E1) -> true ; E1 = none ),
    check('and back into English', E1, 'Catch one\'s breath.').

%% 1.114.0: an operator's name is a reserved name, written with is_.
operator_names :-
    section('an operator\'s name'),
    typology_load(english),
    ( logic_translate(english, cocolog, 'Meek as a mouse.', C1) -> true ; C1 = none ),
    check('as/2 is is_as/2', C1, 'mouse(a(mouse)).\nis_as(meek(something), a(mouse)).\n'),
    ( logic_translate(cocolog, english, C1, E1) -> true ; E1 = none ),
    check('and back into English', E1, 'Something is meek as a mouse.'),
    ( logic_translate(english, cocolog, 'The application of indexes to tables of data.', C2) -> true ; C2 = none ),
    ( sub_atom(C2, _, _, _, 'is_table(a(of(pl(table), data)))') -> V2 = yes ; V2 = C2 ),
    check('table/1 is is_table/1', V2, yes).

%% 1.113.0: an adjective phrase alone is said of something; a person's bare
%% noun alone as a mass noun's.
adjective_alone :-
    section('an adjective phrase alone'),
    typology_load(english),
    forall(member(T-Want, [
               'Potentially useful.'-'potentially(useful(something)).\n',
               'Short in stature.'-'in(short(something), stature).\n',
               'Tragic hero.'-'hero(tragic(hero)).\ntragic(tragic(hero)).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )),
    ( logic_translate(cocolog, english, 'potentially(useful(something)).\n', E) -> true ; E = none ),
    check('and back into English', E, 'Something is potentially useful.').

existential :-
    section('a noun phrase\'s existence'),
    typology_load(english),
    forall(member(T-Want, [
               'There is a dog.'-'dog(a(dog)).\n',
               'There was a salvo of approval.'-'salvo(a(of(salvo, approval))).\npast(exist(a(of(salvo, approval)))).\n',
               'There were millions of flies.'-'million(a(of(pl(million), a(pl(fly))))).\nfly(a(pl(fly))).\npast(exist(a(of(pl(million), a(pl(fly)))))).\n' ]),
           ( ( logic_translate(english, cocolog, T, C) -> true ; C = none ),
             one_line(['into Cocolog: ', T], Label),
             check(Label, C, Want) )).

%% Each clause of a Cocolog text asserted.
assert_text(P) :-
    atomic_list_concat(Ps, '.\n', P),
    forall(( member(S, Ps), S \== '' ), ( term_string(Cl, S), assertz(Cl) )).

%% A test's own predicates: what the clauses written from English assert.
:- dynamic is_sleep/1, past/1, book/1, stamp/1, father/2, when/2, coat/1, heavy/1, warm/1, imperative/1, old/1, at/2.
