%% library(reasoning/typology) -- a language as a filled template, and one
%% grammar that reads it into the IR and writes it from the IR.
%%
%%     cocolog -s test/typology.pl        from this repository's root

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/typology)).

%% Each section runs ONCE: a red check makes checks_done/0 fail, and a
%% main written as one conjunction then backtracked into the sections'
%% choice points and ran the later ones again over a changed state (the
%% free language's rows asserted twice), a second report that was not
%% true.
main :-
    forall(member(L, [english, spanish, italian, persian, french, german]), typology_load(L)),
    forall(member(S, [choices, complete, written, round_trips, refused, marks, sounds,
                      copulas, adjuncts, meanings, questions, repairs, relatives, gaps, possessors, complements, negation_places,
                      question_words, answers, pronouns, echoes, french, references, live_topics,
                      french_questions, tenses, polite, german, reference_sentences, copula_tenses, other_tenses, negative_article, predicate_and, months, german_possessives, german_v2,
                      word_tables, class_topics, reproduced, free_order,
                      incomplete,
                      blank_template]),
           once(S)),
    checks_done.

%% ---- the choices ----------------------------------------------------------------

choices :-
    section('every order of a level'),
    typology_choices(clause, C1), length(C1, N1),
    check('the clause has six orders', N1, 6),
    typology_choices(np, C2), length(C2, N2),
    check('the noun phrase has six orders', N2, 6),
    typology_languages(Ls),
    check('the six templates are loaded', Ls, [english, french, german, italian, persian, spanish]).

complete :-
    section('the six templates are complete'),
    forall(member(L, [english, spanish, italian, persian, french, german]),
           ( typology_check(L, M), atom_concat(L, ' lacks nothing', Label),
             check(Label, M, []) )).

%% ---- one IR, four sentences ---------------------------------------------------------

written :-
    section('one IR written in each language'),
    IR = clause(see, present, pos, np(boy, sg, def, []), np(dog, sg, def, [black])),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR, T) ), Ts),
    check('each language in its own order and forms', Ts,
          [ english-'The boy sees the black dog.',
            spanish-'El niño ve al perro negro.',
            italian-'Il ragazzo vede il cane nero.',
            persian-'پسر سگ سیاه را می‌بیند.' ]),
    typology_translate(spanish, persian, 'Las niñas no vieron un libro rojo.', P2),
    check('Spanish into Persian: the article, the plural, the past, the negative', P2,
          'دخترها یک کتاب قرمز ندیدند.'),
    typology_translate(persian, english, 'پسرها سگ سیاه را دیدند.', E3),
    check('Persian into English: را is read as the definite object', E3,
          'The boys saw the black dog.'),
    typology_translate(english, italian, 'A small girl does not sleep.', I4),
    check('English into Italian: an intransitive clause', I4, 'Una ragazza piccola non dorme.').

%% ---- every clause of a sample, written and read back ---------------------------

sample_np(Nouns, Adjs, np(N, Num, Def, A)) :-
    member(N, Nouns), member(Num, [sg, pl]), member(Def, [def, indef]), member(A, Adjs).

sample_ir(clause(see, T, P, S, O)) :-
    member(T, [present, past]), member(P, [pos, neg]),
    sample_np([boy, girl], [[], [small]], S),
    sample_np([dog, girl, book], [[], [red]], O).
sample_ir(clause(sleep, T, P, S, none)) :-
    member(T, [present, past]), member(P, [pos, neg]),
    sample_np([boy, girl, mouse], [[], [small, red]], S).

round_trips :-
    section('every clause of a sample: written, and read back'),
    aggregate_all(count, sample_ir(_), N),
    format("   ~w clauses a language~n", [N]),
    forall(member(L, [english, spanish, italian, persian]),
           ( aggregate_all(count, ( sample_ir(IR), \+ round_trip(L, IR) ), Bad),
             atom_concat(L, ': each reads back as its own IR', Label),
             check(Label, Bad, 0) )),
    findall(R, typology_read(persian, 'پسرها می‌خوابند.', R), Rs),
    check('a reading the forms leave open is two readings: Persian has no definite article',
          Rs, [ clause(sleep, present, pos, np(boy, pl, def, []), none),
                clause(sleep, present, pos, np(boy, pl, indef, []), none) ]).

round_trip(L, IR) :-
    typology_write(L, IR, Text),
    once(typology_read(L, Text, IR)).

%% ---- what the template does not allow ----------------------------------------------

refused :-
    section('a sentence the template does not allow is not read'),
    forall(member(L-T-Why,
                  [ spanish-'Perro el ve al gato.'-'the article after the noun',
                    spanish-'Los perro ven al gato.'-'an article that does not agree',
                    spanish-'La niño duerme.'-'a gender that does not agree',
                    spanish-'La niña pequeño duerme.'-'an adjective that does not agree',
                    spanish-'Los niños ve al gato.'-'a verb that does not agree',
                    spanish-'El niño ve el perro.'-'an animate object with no personal a',
                    english-'The dog black sleeps.'-'an English adjective after its noun',
                    english-'Dog the sleeps.'-'an English article after its noun',
                    persian-'پسر می‌بیند سگ را.'-'a Persian verb before its object',
                    italian-'Il ragazzo vede la cane.'-'an Italian article that does not agree' ]),
           ( yes_no(typology_read(L, T, _), R),
             atomic_list_concat([L, ': ', Why], Label),
             check(Label, R, no) )).

marks :-
    section('marks and contractions'),
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), np(girl, sg, indef, [])), S1),
    check('Spanish: a before an animate singular object', S1, 'El niño ve a una niña.'),
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), np(dog, pl, indef, [])), S2),
    check('Spanish: none before an animate plural indefinite object', S2, 'El niño ve perros.'),
    typology_read(spanish, 'El niño ve al perro.', R3),
    check('Spanish: al is read as a el', R3,
          clause(see, present, pos, np(boy, sg, def, []), np(dog, sg, def, []))),
    typology_write(persian, clause(see, present, pos, np(boy, sg, def, []), np(book, sg, indef, [])), S4),
    check('Persian: no را after an indefinite object', S4, 'پسر یک کتاب می‌بیند.').

%% ---- forms chosen by sound (Phase 3) -------------------------------------------

sounds :-
    section('forms chosen by the next word and by the word''s own ending'),
    forall(member(L-IR-Want,
                  [ english-clause(eat, present, pos, np(boy, sg, def, []), np(apple, sg, indef, []))-'The boy eats an apple.',
                    english-clause(see, present, pos, np(boy, sg, def, []), np(university, sg, indef, []))-'The boy sees a university.',
                    english-clause(see, present, pos, np(boy, sg, def, []), np(hour, sg, indef, []))-'The boy sees an hour.',
                    italian-clause(see, present, pos, np(lawyer, sg, def, []), np(student, pl, def, []))-'L\'avvocato vede gli studenti.',
                    italian-clause(see, past, neg, np(lawyer, pl, def, []), np(student, sg, indef, []))-'Gli avvocati non videro uno studente.',
                    spanish-clause(see, present, pos, np(boy, sg, def, []), np(water, sg, def, [cold]))-'El niño ve el agua fría.',
                    spanish-clause(see, present, pos, np(boy, pl, def, []), np(water, pl, def, [cold]))-'Los niños ven las aguas frías.',
                    persian-clause(see, present, pos, np(boy, sg, def, []), np(cat, sg, def, [black]))-'پسر گربه‌ی سیاه را می‌بیند.',
                    persian-clause(see, past, pos, np(boy, pl, def, []), np(dog, pl, def, [black, small]))-'پسرها سگ‌های سیاه کوچک را دیدند.',
                    persian-clause(see, present, pos, np(boy, sg, def, []), np(cat, sg, def, []))-'پسر گربه را می‌بیند.' ]),
           ( typology_write(L, IR, T),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( typology_read(L, T, IR) -> Back = read ; Back = not_read ),
             atomic_list_concat([L, ': and read back: ', Want], Label2),
             check(Label2, Back, read) )),
    ( typology_read(italian, 'Il ragazzo vede un\'amica.', _) -> R1 = read ; R1 = refused ),
    check('Italian: un\' joined to a feminine noun is read', R1, read),
    forall(member(L-T-Why,
                  [ english-'The boy eats a apple.'-'a before a vowel',
                    english-'The boy sees an university.'-'an before uni',
                    italian-'Il avvocato vede i studenti.'-'il before a vowel, i before s and a consonant',
                    italian-'Lo ragazzo vede il cane.'-'lo before a plain consonant',
                    spanish-'El niño ve la agua fría.'-'la before a stressed a',
                    persian-'پسر گربه سیاه را می‌بیند.'-'a silent h with no ezafe before its adjective',
                    persian-'پسر گربه‌ی را می‌بیند.'-'an ezafe with no adjective after it' ]),
           ( yes_no(typology_read(L, T, _), R),
             atomic_list_concat([L, ': not read: ', Why], Label),
             check(Label, R, no) )).

%% ---- the copula clause and the adjuncts (Phase 4) -------------------------------

%% Each IR written in each language, and read back: the IR is one of its
%% readings. A word of several meanings has a reading each, and with no
%% valency yet a verb's object can also read as an adjunct (`ve al perro':
%% sees the dog, or sees, to the dog), so the IR need not be the first.
written_each(Section, Rows) :-
    forall(member(IR-Wants, Rows),
           forall(member(L-Want, Wants),
                  ( typology_write(L, IR, T),
                    atomic_list_concat([L, ': ', Want], Label),
                    check(Label, T, Want),
                    ( typology_read(L, T, IR) -> R = read ; R = not_read ),
                    atomic_list_concat([L, ': read back, the IR among its readings: ', Want], Label2),
                    check(Label2, R, read) ))),
    format("   (~w)~n", [Section]).

copulas :-
    section('the copula clause: subject, copula and predicate in the template''s order'),
    written_each(copula, [
        copula(present, pos, np(dog, sg, def, []), adj([big]))-
            [english-'The dog is big.', spanish-'El perro es grande.',
             italian-'Il cane è grande.', persian-'سگ بزرگ است.'],
        copula(past, neg, np(dog, pl, def, []), adj([black]))-
            [english-'The dogs were not black.', spanish-'Los perros no eran negros.',
             italian-'I cani non erano neri.', persian-'سگ‌ها سیاه نبودند.'],
        copula(present, pos, np(girl, sg, def, []), adj([small]))-
            [spanish-'La niña es pequeña.', italian-'La ragazza è piccola.'],
        copula(present, pos, np(dog, sg, def, []), np(animal, sg, indef, []))-
            [english-'The dog is an animal.', spanish-'El perro es un animal.',
             italian-'Il cane è un animale.', persian-'سگ یک حیوان است.'],
        copula(present, pos, np(dog, sg, def, []), pp(in, np(house, sg, def, [])))-
            [english-'The dog is in the house.', spanish-'El perro está en la casa.',
             italian-'Il cane è nella casa.', persian-'سگ در خانه است.'] ]),
    forall(member(L-T-Why,
                  [ spanish-'El perro es en la casa.'-'ser before a place (estar is the template''s)',
                    english-'The dog are big.'-'a copula that does not agree',
                    spanish-'La niña es pequeño.'-'a predicate adjective that does not agree',
                    persian-'سگ است بزرگ.'-'a Persian copula before its predicate' ]),
           ( yes_no(typology_read(L, T, _), R),
             atomic_list_concat([L, ': not read: ', Why], Label),
             check(Label, R, no) )),
    aggregate_all(count, copula_sample(_), N),
    forall(member(L, [english, spanish, italian, persian]),
           ( aggregate_all(count, ( copula_sample(IR), \+ round_trip(L, IR) ), Bad),
             atomic_list_concat([L, ': each of ', N, ' copula clauses reads back as its own IR'], Label),
             check(Label, Bad, 0) )).

copula_sample(copula(T, P, S, Pred)) :-
    member(T, [present, past]), member(P, [pos, neg]),
    sample_np([boy, girl], [[], [small]], S),
    member(Pred, [adj([red]), np(animal, sg, indef, []), pp(in, np(house, sg, def, []))]).

adjuncts :-
    section('adjuncts: adposition phrases and adverbs, where the template puts them'),
    written_each(adjuncts, [
        clause(see, present, pos, np(boy, sg, def, []), np(dog, sg, def, []), [pp(in, np(house, sg, def, []))])-
            [english-'The boy sees the dog in the house.', spanish-'El niño ve al perro en la casa.',
             italian-'Il ragazzo vede il cane nella casa.', persian-'پسر سگ را در خانه می‌بیند.'],
        clause(sleep, present, pos, np(boy, sg, def, []), none, [adv(today)])-
            [english-'The boy sleeps today.', spanish-'El niño duerme hoy.',
             italian-'Il ragazzo dorme oggi.', persian-'پسر امروز می‌خوابد.'],
        clause(sleep, past, pos, np(boy, pl, def, []), none, [pp(with, np(dog, sg, def, [black])), adv(here)])-
            [english-'The boys slept with the black dog here.', spanish-'Los niños durmieron con el perro negro aquí.',
             italian-'I ragazzi dormirono con il cane nero qui.', persian-'پسرها با سگ سیاه اینجا خوابیدند.'],
        clause(sleep, present, pos, np(boy, sg, def, []), none, [pp(in, np(water, sg, def, []))])-
            [italian-'Il ragazzo dorme nell\'acqua.'],
        clause(sleep, present, pos, np(boy, sg, def, []), none, [pp(in, np(student, sg, def, []))])-
            [italian-'Il ragazzo dorme nello studente.'],
        clause(sleep, present, pos, np(boy, sg, def, []), none, [pp(in, np(student, pl, def, []))])-
            [italian-'Il ragazzo dorme negli studenti.'],
        clause(sleep, present, pos, np(boy, sg, def, []), none, [pp(from, np(book, sg, def, []))])-
            [spanish-'El niño duerme del libro.'] ]),
    forall(member(L-T-Why,
                  [ italian-'Il cane dorme in la casa.'-'in la, which is nella',
                    spanish-'El niño duerme de el libro.'-'de el, which is del',
                    persian-'پسر سگ را می‌بیند در خانه.'-'a Persian adjunct after the verb',
                    english-'The boy in the house sees the dog.'-'an English adjunct after the subject' ]),
           ( yes_no(typology_read(L, T, _), R),
             atomic_list_concat([L, ': not read: ', Why], Label),
             check(Label, R, no) )).

%% ---- questions ------------------------------------------------------------------------

questions :-
    section('questions: yes or no, and a question word at the front or in place'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    written_each(questions, [
        question(clause(see, present, pos, B, D))-
            [english-'Does the boy see the dog?', spanish-'¿El niño ve al perro?',
             italian-'Il ragazzo vede il cane?', persian-'پسر سگ را می‌بیند؟'],
        question(clause(see, present, pos, B, wh(what)))-
            [english-'What does the boy see?', spanish-'¿Qué ve el niño?',
             italian-'Cosa vede il ragazzo?', persian-'پسر چه چیزی می‌بیند؟'],
        question(clause(see, present, pos, wh(who), D))-
            [english-'Who sees the dog?', spanish-'¿Quién ve al perro?',
             italian-'Chi vede il cane?', persian-'چه کسی سگ را می‌بیند؟'],
        question(clause(see, past, pos, G, wh(who)))-
            [english-'Who did the girl see?', spanish-'¿A quién vio la niña?',
             italian-'La ragazza chi vide?', persian-'دختر چه کسی را دید؟'],
        question(clause(sleep, present, pos, D, none, [wh(where)]))-
            [english-'Where does the dog sleep?', spanish-'¿Dónde duerme el perro?',
             italian-'Dove dorme il cane?', persian-'سگ کجا می‌خوابد؟'],
        question(clause(sleep, past, neg, np(boy, pl, def, []), none))-
            [english-'Did the boys not sleep?', spanish-'¿Los niños no durmieron?',
             italian-'I ragazzi non dormirono?', persian-'پسرها نخوابیدند؟'],
        question(clause(see, present, neg, B, wh(what)))-
            [english-'What does the boy not see?', spanish-'¿Qué no ve el niño?',
             italian-'Cosa non vede il ragazzo?', persian-'پسر چه چیزی نمی‌بیند؟'],
        question(copula(present, pos, D, adj([big])))-
            [english-'Is the dog big?', spanish-'¿El perro es grande?',
             italian-'Il cane è grande?', persian-'سگ بزرگ است؟'],
        question(copula(present, neg, D, adj([big])))-
            [english-'Is the dog not big?', spanish-'¿El perro no es grande?',
             italian-'Il cane non è grande?', persian-'سگ بزرگ نیست؟'],
        question(copula(present, pos, D, wh(where)))-
            [english-'Where is the dog?', spanish-'¿Dónde está el perro?',
             italian-'Dov\'è il cane?', persian-'سگ کجاست؟'] ]),
    %% The other orders a template keeps are read.
    once(typology_read(spanish, '¿Ve el niño al perro?', R1)),
    check('Spanish: the verb before the subject, the mark read past the subject', R1,
          question(clause(see, present, pos, B, D))),
    object_parts('¿Ve el niño al perro?', R1b),
    check('Spanish: and never `to the dog''', R1b, [np(dog, sg, def, [])-[]]),
    once(typology_read(persian, 'آیا پسر سگ را می‌بیند؟', R2)),
    check('Persian: the particle آیا first', R2, question(clause(see, present, pos, B, D))),
    wh_roles('Chi vede il ragazzo?', W3s),
    check('Italian: chi vede il ragazzo is who sees the boy, the order closest to the statement''s', W3s, [subject]),
    wh_roles('Cosa vede il ragazzo?', W3bs),
    check('Italian: cosa vede il ragazzo is what the boy sees, as a thing does not see', W3bs, [object]),
    ( typology_read(spanish, 'El libro ve al perro.', _) -> R3c = read ; R3c = refused ),
    check('Spanish: a book that sees is not read', R3c, refused),
    %% What the templates do not allow is not read.
    forall(member(L-T-Why,
                  [ english-'What the boy sees?'-'a question word at the front with no does',
                    english-'Sees the boy the dog?'-'an English verb before its subject',
                    spanish-'El niño ve al perro?'-'a Spanish question with no ¿',
                    spanish-'¿Qué el niño ve?'-'a Spanish subject before its verb after a question word',
                    spanish-'El niño ve qué.'-'a question word in a statement',
                    english-'The boy sees what.'-'a question word in an English statement',
                    english-'Does the boy see the dog.'-'a question with a full stop' ]),
           ( yes_no(typology_read(L, T, _), R),
             atomic_list_concat([L, ': ', Why], Label),
             check(Label, R, no) )),
    %% Across the languages, through the IR.
    typology_translate(spanish, english, '¿A quién vio la niña?', E4),
    check('Spanish into English: a quién, who did', E4, 'Who did the girl see?'),
    typology_translate(english, persian, 'Where does the dog sleep?', P5),
    check('English into Persian: the question word in place', P5, 'سگ کجا می‌خوابد؟'),
    %% Every intransitive clause of the sample as a question.
    aggregate_all(count, ( sample_ir(clause(sleep, T6, P6, S6, none)),
                           member(L6, [english, spanish, italian, persian]),
                           \+ round_trip(L6, question(clause(sleep, T6, P6, S6, none))) ), Bad6),
    check('every intransitive clause of the sample as a question, four languages, reads back', Bad6, 0).

%% ---- a word with several meanings ----------------------------------------------

meanings :-
    section('a word with several meanings: the words around it, the topics'),
    %% The lookback and the lookahead: Spanish `a' after a verb and before
    %% an animate noun is the mark; before a thing it is `to'.
    %% (niño and ve have several meanings of their own; only the object's
    %% part of each reading is compared.)
    object_parts('El niño ve al perro.', R1),
    check('Spanish: a before an animate noun after a verb is the mark', R1,
          [np(dog, sg, def, [])-[]]),
    object_parts('El niño ve a un libro.', R2),
    check('Spanish: a before a thing is to', R2,
          [none-[pp(to, np(book, sg, indef, []))]]),
    ( typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), none,
                                     [pp(to, np(dog, sg, def, []))]), _) -> R3 = yes ; R3 = no ),
    check('Spanish: `to the dog'' after a verb is not written (it reads as the mark)', R3, no),
    %% The topics of the sentence's other words.
    hoja_meanings('El niño ve la hoja.', M4),
    check('Spanish: hoja alone is a leaf, a sheet and a blade', M4, [blade, leaf, sheet]),
    hoja_meanings('El niño ve la hoja en el libro.', M5),
    check('Spanish: hoja beside a book is a sheet', M5, [sheet]),
    hoja_meanings('El niño ve la hoja en el árbol.', M6),
    check('Spanish: hoja beside a tree is a leaf', M6, [leaf]),
    once(typology_read(spanish, 'El hombre ve la carta en el restaurante.', IR7)),
    check('Spanish: carta in a restaurant is the menu', IR7,
          clause(see, present, pos, np(man, sg, def, []), np(menu, sg, def, []),
                 [pp(in, np(restaurant, sg, def, []))])),
    %% The topics of the sentences before.
    typology_translate_text(spanish, english, ['El hombre ve el cuchillo.', 'El hombre ve la hoja.'], T8),
    check('Spanish into English: hoja after a knife is a blade', T8,
          ['The man sees the knife.', 'The man sees the blade.']),
    typology_translate_text(spanish, english, ['El hombre ve el libro.', 'El hombre ve la hoja.'], T9),
    check('Spanish into English: hoja after a book is a sheet', T9,
          ['The man sees the book.', 'The man sees the sheet.']),
    typology_topics(clause(see, present, pos, np(man, sg, def, []), np(knife, sg, def, [])), T10),
    check('the topics of an IR: its meanings and their topics', T10, [knife, man, see, tool]),
    %% The writer writes a word only where its context gives the meaning.
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), np(blade, sg, def, []),
                                   [pp(in, np(book, sg, def, []))]), T11),
    check('Spanish: a blade beside a book is written cuchilla, not hoja', T11,
          'El niño ve la cuchilla en el libro.'),
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), np(sheet, sg, def, []),
                                   [pp(in, np(book, sg, def, []))]), T12),
    check('Spanish: a sheet beside a book is hoja', T12, 'El niño ve la hoja en el libro.'),
    %% A row the check refuses, in a small language of its own.
    assertz(ty_adposition(tiny, to, [ta])),
    assertz(ty_sense(tiny, ta, noun(dog), [], [])),
    assertz(ty_sense(tiny, ta, adposition(to), [klass(verb)], [])),
    assertz(ty_sense(tiny, ta, adposition(to), [class(verb)], [opt(class(noun, animate))])),
    typology_check(tiny, M13),
    retractall(ty_sense(tiny, _, _, _, _)),
    retractall(ty_adposition(tiny, _, _)),
    findall(B, ( member(B, M13), B = bad(ty_sense(_, _, _, _, _)) ), Bad13),
    check('typology_check/2 names a sense the word lacks and an item that is none', Bad13,
          [bad(ty_sense(tiny, ta, adposition(to), [klass(verb)], [])),
           bad(ty_sense(tiny, ta, noun(dog), [], []))]).

%% The role the question word has in every reading of an Italian question.
wh_roles(T, Ws) :-
    findall(W, ( typology_read(italian, T, question(clause(_, _, _, S, _))),
                 ( S = wh(_) -> W = subject ; W = object ) ), Ws0),
    sort(Ws0, Ws).

%% ---- repairs ----------------------------------------------------------------------------

repairs :-
    section('a sentence the template does not allow, repaired'),
    forall(member(L-T-Want-WantFs,
                  [ spanish-'Los perro ven al gato.'-'Los perros ven al gato.'-[agreement(noun, perro)],
                    spanish-'La niña pequeño duerme.'-'La niña pequeña duerme.'-[agreement(adjective)],
                    spanish-'El niño ve el perro.'-'El niño ve al perro.'-[mark(o, [], [a])],
                    spanish-'Los niños ve al gato.'-'Los niños ven al gato.'-[agreement(verb, [ve])],
                    spanish-'El perro es en la casa.'-'El perro está en la casa.'-[copula([es])],
                    spanish-'El niño ve al perro?'-'¿El niño ve al perro?'-[marks(question)],
                    spanish-'¿Qué el niño ve?'-'¿Qué ve el niño?'-[question(wh, clause, unchanged)],
                    english-'What the boy sees?'-'What does the boy see?'-[question(wh, clause, unchanged)],
                    english-'Sees the boy the dog?'-'Does the boy see the dog?'-[question_form([sees])],
                    english-'The dog black sleeps.'-'The black dog sleeps.'-[order(np, [d, n, a])],
                    english-'Does the boy see the dog.'-'Does the boy see the dog?'-[mood(question)],
                    italian-'Il ragazzo vede la cane.'-'Il ragazzo vede il cane.'-[agreement(article, la)],
                    persian-'پسر می‌بیند سگ را.'-'پسر سگ را می‌بیند.'-[order(clause, [s, v, o])] ]),
           ( ( once(typology_repair(L, T, _, Fs, F)) -> true ; F = none, Fs = none ),
             atomic_list_concat([L, ': ', T, ' is ', Want], Label),
             check(Label, F, Want),
             atomic_list_concat([L, ': the faults of ', T], Label2),
             check(Label2, Fs, WantFs) )),
    once(typology_repair(italian, 'Il avvocato vede i studenti.', _, [sound(_)], F2)),
    check('Italian: a form the next word chooses, il avvocato', F2, 'L\'avvocato vede gli studenti.'),
    once(typology_repair(spanish, 'El niño ve qué.', _, Fs3, F3)),
    %% 1.36.0: a question word in place keeps the statement's order, so the
    %% rule's order is no third fault.
    check('Spanish: a question word in a statement, two faults', F3-Fs3,
          '¿Qué ve el niño?'-[mood(question), wh_place(in_place)]),
    findall(F4, typology_repair(english, 'Boy sees the dog.', _, _, F4), F4s),
    check('English: an article missing, two repairs of one fault', F4s,
          ['The boy sees the dog.', 'A boy sees the dog.']),
    once(typology_repair(spanish, 'El niño ve al perro.', _, Fs5, F5)),
    check('a sentence the template allows needs no repair', F5-Fs5, 'El niño ve al perro.'-[]),
    ( typology_repair(spanish, 'El niño ve un zzz.', _, _, _) -> R6 = repaired ; R6 = not ),
    check('a word no table has is not repaired', R6, not).

%% ---- relative clauses ---------------------------------------------------------------

relatives :-
    section('relative clauses: the head, the marker, and the clause with its gap'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    Obj = rel(D, clause(see, present, pos, B, gap)),
    Subj = rel(B, clause(see, present, pos, gap, D)),
    written_each(relatives, [
        clause(sleep, present, pos, Obj, none)-
            [english-'The dog that the boy sees sleeps.', spanish-'El perro que el niño ve duerme.',
             italian-'Il cane che il ragazzo vede dorme.', persian-'سگی که پسر می‌بیند می‌خوابد.'],
        clause(sleep, present, pos, Subj, none)-
            [english-'The boy that sees the dog sleeps.', spanish-'El niño que ve al perro duerme.',
             italian-'Il ragazzo che vede il cane dorme.', persian-'پسری که سگ را می‌بیند می‌خوابد.'],
        clause(see, present, pos, np(girl, sg, def, []),
               rel(np(dog, sg, def, [black]), clause(sleep, present, pos, gap, none)))-
            [english-'The girl sees the black dog that sleeps.', spanish-'La niña ve al perro negro que duerme.',
             italian-'La ragazza vede il cane nero che dorme.', persian-'دختر سگ سیاهی را می‌بیند که می‌خوابد.'],
        clause(sleep, past, pos, rel(np(girl, pl, def, [small]),
                                     clause(see, past, pos, gap, np(cat, sg, indef, []))), none)-
            [english-'The small girls that saw a cat slept.',
             spanish-'Las niñas pequeñas que vieron a un gato durmieron.',
             italian-'Le ragazze piccole che videro un gatto dormirono.',
             persian-'دخترهای کوچکی که یک گربه دیدند خوابیدند.'],
        clause(see, present, pos, B, rel(np(girl, sg, def, []), copula(present, pos, gap, adj([small]))))-
            [english-'The boy sees the girl that is small.', spanish-'El niño ve a la niña que es pequeña.',
             italian-'Il ragazzo vede la ragazza che è piccola.', persian-'پسر دختری را می‌بیند که کوچک است.'],
        clause(sleep, present, pos, D, none, [pp(in, rel(np(house, sg, def, []), clause(see, present, pos, B, gap)))])-
            [english-'The dog sleeps in the house that the boy sees.',
             spanish-'El perro duerme en la casa que el niño ve.',
             italian-'Il cane dorme nella casa che il ragazzo vede.',
             persian-'سگ در خانه‌ای که پسر می‌بیند می‌خوابد.'],
        clause(sleep, present, pos, rel(B, clause(see, present, pos, gap,
                                                   rel(D, clause(see, present, pos, np(cat, sg, def, []), gap)))), none)-
            [english-'The boy that sees the dog that the cat sees sleeps.',
             spanish-'El niño que ve al perro que el gato ve duerme.',
             italian-'Il ragazzo che vede il cane che il gatto vede dorme.',
             persian-'پسری که سگی را می‌بیند که گربه می‌بیند می‌خوابد.'],
        question(clause(see, present, pos, wh(who), rel(D, clause(sleep, present, pos, gap, none))))-
            [english-'Who sees the dog that sleeps?', spanish-'¿Quién ve al perro que duerme?',
             italian-'Chi vede il cane che dorme?', persian-'چه کسی سگی را می‌بیند که می‌خوابد؟'],
        question(clause(see, present, pos, rel(B, clause(sleep, present, pos, gap, none)), D))-
            [english-'Does the boy that sleeps see the dog?', spanish-'¿El niño que duerme ve al perro?',
             italian-'Il ragazzo che dorme vede il cane?', persian-'پسری که می‌خوابد سگ را می‌بیند؟'] ]),
    %% The other markers are read; no marker where the gap is the object.
    forall(member(T-Want, [ 'The dog the boy sees sleeps.'-clause(sleep, present, pos, Obj, none),
                            'The dog which the boy sees sleeps.'-clause(sleep, present, pos, Obj, none),
                            'The boy who sees the dog sleeps.'-clause(sleep, present, pos, Subj, none) ]),
           ( ( typology_read(english, T, Want) -> R = read ; R = not_read ),
             atomic_list_concat(['English: ', T], Label),
             check(Label, R, read) )),
    %% Refused: a marker of no words where the gap is the subject, a verb
    %% that does not agree with its head, a head the verb does not take, a
    %% noun phrase that is no clause.
    forall(member(L-T, [ english-'The boy sees the dog sleeps.',
                         spanish-'Los niños que ve al perro duermen.',
                         english-'The book that sees the dog sleeps.',
                         english-'The boy who sleeps.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    %% An adjunct after a relative clause may be the main clause's or the
    %% relative clause's: both are read.
    findall(At, ( typology_read(spanish, 'El niño ve al perro que duerme en la casa.', IR),
                  pp_owner(IR, At) ), At0),
    sort(At0, Ats),
    check('Spanish: en la casa, of the main clause or of the relative clause', Ats, [main, relative]),
    typology_translate(spanish, persian, 'El niño ve al perro que duerme.', P1),
    check('Spanish into Persian: the head takes ی, را stays with the head', P1,
          'پسر سگی را می‌بیند که می‌خوابد.'),
    typology_translate(persian, english, 'سگی که پسر می‌بیند می‌خوابد.', E1),
    check('Persian into English: the gap is the object', E1, 'The dog that the boy sees sleeps.'),
    once(typology_repair(spanish, 'Los niños que ve al perro duermen.', _, Fs2, F2)),
    check('Spanish: a relative clause''s verb repaired to agree with its head', F2-Fs2,
          'Los niños que ven al perro duermen.'-[agreement(verb, [ve])]),
    %% A language whose relative clause stands before its head, its marker
    %% after the clause (c m h), then with no marker (c h): the reader ends,
    %% a clause first starting no relative clause again at its own place.
    forall(( member(F, [ty_order(english, clause, _), ty_order(english, np, _),
                        ty_noun(english, _, _, _, _, _), ty_adjective(english, _, _, _, _),
                        ty_verb(english, _, _, _, _, _), ty_article(english, _, _, _, _),
                        ty_negation(english, _, _, _, _)]),
             call(F) ),
           ( F =.. [P, english|Args], G =.. [P, before|Args], assertz(G) )),
    assertz(ty_order(before, rel, [c, m, h])),
    assertz(ty_relative(before, any, [de], [[]])),
    IR3 = clause(sleep, present, pos, Obj, none),
    typology_write(before, IR3, W3),
    findall(R3, typology_read(before, W3, R3), R3s),
    check('the clause before its head, its marker after it', W3-R3s,
          'The boy sees de the dog sleeps.'-[IR3]),
    %% (cocolog 3.72.0: retractall/1 of a qualified head removes nothing.)
    retractall(ty_relative(before, _, _, _)),
    assertz(ty_relative(before, any, [], [[]])),
    typology_write(before, IR3, W4),
    findall(R4, typology_read(before, W4, R4), R4s),
    check('and with no marker', W4-R4s, 'The boy sees the dog sleeps.'-[IR3]).

%% Where the adjunct of a reading stands: in the main clause or in the
%% object's relative clause.
pp_owner(clause(_, _, _, _, _, [pp(_, _)]), main).
pp_owner(clause(_, _, _, _, rel(_, clause(_, _, _, _, _, [pp(_, _)]))), relative).

%% ---- the gap in an adposition phrase, the pronoun, the clause after the verb ----

gaps :-
    section('a gap in an adposition phrase, a resumptive pronoun, a relative clause after its verb'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    House = rel(np(house, sg, def, []), clause(sleep, present, pos, D, none, [pp(in, gap)])),
    written_each(gaps, [
        clause(see, present, pos, B, House)-
            [english-'The boy sees the house that the dog sleeps in.',
             spanish-'El niño ve la casa en la que el perro duerme.',
             italian-'Il ragazzo vede la casa in cui il cane dorme.',
             persian-'پسر خانه‌ای را می‌بیند که سگ در آن می‌خوابد.'],
        clause(see, present, pos, B, rel(np(house, pl, def, []),
                                         clause(sleep, present, pos, D, none, [pp(in, gap)])))-
            [spanish-'El niño ve las casas en las que el perro duerme.',
             persian-'پسر خانه‌هایی را می‌بیند که سگ در آنها می‌خوابد.'],
        clause(see, present, pos, D, rel(G, clause(think, present, pos, B, gap)))-
            [english-'The dog sees the girl that the boy thinks about.',
             spanish-'El perro ve a la niña en la que el niño piensa.',
             italian-'Il cane vede la ragazza a cui il ragazzo pensa.',
             persian-'سگ دختری را می‌بیند که پسر به او فکر می‌کند.'],
        copula(present, pos, D, rel(np(animal, sg, indef, []), clause(sleep, present, pos, gap, none)))-
            [english-'The dog is an animal that sleeps.', spanish-'El perro es un animal que duerme.',
             italian-'Il cane è un animale che dorme.', persian-'سگ حیوانی است که می‌خوابد.'],
        clause(think, present, pos, B, rel(G, clause(sleep, present, pos, gap, none)))-
            [english-'The boy thinks about the girl that sleeps.',
             spanish-'El niño piensa en la niña que duerme.',
             italian-'Il ragazzo pensa alla ragazza che dorme.',
             persian-'پسر به دختری فکر می‌کند که می‌خوابد.'],
        clause(sleep, present, pos, rel(np(dog, sg, indef, []), clause(see, present, pos, B, gap)), none)-
            [persian-'سگی که پسر می‌بیند می‌خوابد.'] ]),
    %% Read as well: the other way of each language, the clause in place,
    %% the article before a relative clause, the pronoun of an object.
    Comp = clause(see, present, pos, D, rel(G, clause(think, present, pos, B, gap))),
    Obj = clause(see, present, pos, G, rel(np(dog, sg, def, [black]), clause(sleep, present, pos, gap, none))),
    Pred = copula(present, pos, D, rel(np(animal, sg, indef, []), clause(sleep, present, pos, gap, none))),
    forall(member(L-T-Want, [ english-'The boy sees the house in which the dog sleeps.'-clause(see, present, pos, B, House),
                              english-'The boy sees the house the dog sleeps in.'-clause(see, present, pos, B, House),
                              english-'The dog sees the girl about whom the boy thinks.'-Comp,
                              spanish-'El niño ve la casa en que el perro duerme.'-clause(see, present, pos, B, House),
                              persian-'دختر سگ سیاهی را که می‌خوابد می‌بیند.'-Obj,
                              persian-'سگ یک حیوانی که می‌خوابد است.'-Pred,
                              persian-'سگی که پسر آن را می‌بیند می‌خوابد.'-
                                  clause(sleep, present, pos, rel(D, clause(see, present, pos, B, gap)), none) ]),
           ( ( typology_read(L, T, Want) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, read) )),
    %% Refused: `whom' of a thing, the article of another gender, an
    %% adposition with no pronoun where Persian needs one, a moved adposition
    %% in English where its own place still has it.
    forall(member(L-T, [ english-'The boy sees the house in whom the dog sleeps.',
                         spanish-'El niño ve la casa en el que el perro duerme.',
                         persian-'پسر خانه‌ای را می‌بیند که سگ در می‌خوابد.',
                         english-'The boy sees the house in which the dog sleeps in.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    typology_translate(spanish, persian, 'El niño ve la casa en la que el perro duerme.', P1),
    check('Spanish into Persian: en la que is a pronoun after در', P1,
          'پسر خانه‌ای را می‌بیند که سگ در آن می‌خوابد.'),
    typology_translate(persian, italian, 'سگ دختری را می‌بیند که پسر به او فکر می‌کند.', I2),
    check('Persian into Italian: the pronoun is cui after a', I2,
          'Il cane vede la ragazza a cui il ragazzo pensa.'),
    %% A template's gap rows are checked.
    assertz(ty_gap(tiny, o, moves)),
    assertz(ty_gap(tiny, pp, resumptive)),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms),
                 memberchk(M, [bad(ty_gap(tiny, o, moves)), resumptive_pronoun]) ), M3),
    retractall(ty_gap(tiny, _, _)),
    check('typology_check/2: moves is no object''s rule, and a resumptive gap needs a pronoun', M3,
          [resumptive_pronoun, bad(ty_gap(tiny, o, moves))]),
    more_gaps.

%% 1.31.0: an adjunct's gap beside other adjuncts, a subject's relative
%% clause after the verb (read), and a person apart from an animal.
more_gaps :-
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    Today = clause(see, present, pos, B, rel(np(house, sg, def, []),
                                           clause(sleep, present, pos, D, none, [pp(in, gap), adv(today)]))),
    written_each(more_gaps, [
        Today-
            [english-'The boy sees the house that the dog sleeps in today.',
             spanish-'El niño ve la casa en la que el perro duerme hoy.',
             italian-'Il ragazzo vede la casa in cui il cane dorme oggi.',
             persian-'پسر خانه‌ای را می‌بیند که سگ در آن امروز می‌خوابد.'],
        clause(sleep, present, pos, rel(D, clause(think, present, pos, B, gap)), none)-
            [persian-'سگی که پسر به آن فکر می‌کند می‌خوابد.'],
        clause(sleep, present, pos, rel(np(girl, pl, def, []), clause(think, present, pos, B, gap)), none)-
            [persian-'دخترهایی که پسر به آنها فکر می‌کند می‌خوابند.'] ]),
    %% A moved adposition's gap is the first adjunct: one reading.
    findall(Js, ( typology_read(spanish, 'El niño ve la casa en la que el perro duerme hoy.', IR1),
                  IR1 = clause(see, _, _, np(boy, _, _, _), rel(np(house, _, _, _), clause(_, _, _, _, _, Js))) ), Jss1),
    sort(Jss1, Jss1s),
    check('Spanish: hoy of the relative clause is read once, after its gap', Jss1s,
          [[pp(in, gap), adv(today)]]),
    ( typology_write(spanish, clause(see, present, pos, B, rel(np(house, sg, def, []),
             clause(sleep, present, pos, D, none, [adv(today), pp(in, gap)]))), _) -> R2 = written ; R2 = not_written ),
    check('Spanish: a moved gap after another adjunct is no IR of a sentence', R2, not_written),
    %% A subject's relative clause after the verb: Persian reads it and
    %% writes the clause in place.
    Subj = clause(sleep, present, pos, rel(D, clause(see, present, pos, B, gap)), none),
    ( typology_read(persian, 'سگی می‌خوابد که پسر می‌بیند.', Subj) -> R3 = read ; R3 = not_read ),
    check('Persian: a subject''s relative clause after the verb is read', R3, read),
    typology_write(persian, Subj, P4),
    check('Persian: and written in place', P4, 'سگی که پسر می‌بیند می‌خوابد.'),
    ( typology_read(persian, 'پسری بزرگ است که سگ را می‌بیند.',
                    copula(present, pos, rel(B, clause(see, present, pos, gap, D)), adj([big]))) -> R5 = read ; R5 = not_read ),
    check('Persian: a copula''s subject too', R5, read),
    %% A person is animate to every rule, and Persian's pronoun tells them.
    ( typology_read(persian, 'سگی که پسر به او فکر می‌کند می‌خوابد.', _) -> R6 = read ; R6 = refused ),
    check('Persian: او is no animal''s', R6, refused),
    findall(A, ( member(M, [boy, dog, book]), ty_noun(english, M, _, A, _, _) ), As7),
    check('English: a person, an animal, a thing', As7, [person, animate, inanimate]),
    typology_write(spanish, clause(see, present, pos, D, np(girl, sg, def, [])), S8),
    check('Spanish: a person takes the personal a', S8, 'El perro ve a la niña.'),
    assertz(ty_relative_after(tiny, s, third)),
    findall(M9, ( typology_check(tiny, Ms9), member(M9, Ms9), M9 = bad(ty_relative_after(_, _, _)) ), M9s),
    retractall(ty_relative_after(tiny, _, _)),
    check('typology_check/2: a rank is first or second', M9s, [bad(ty_relative_after(tiny, s, third))]).

%% ---- the possessor, and `whose' ---------------------------------------------------

possessors :-
    section('a possessor in a noun phrase, and a relative clause whose gap is the possessor'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    written_each(possessors, [
        clause(sleep, present, pos, of(B, D), none)-
            [english-'The boy\'s dog sleeps.', spanish-'El perro del niño duerme.',
             italian-'Il cane del ragazzo dorme.', persian-'سگ پسر می‌خوابد.'],
        clause(see, present, pos, G, of(np(boy, pl, def, []), np(house, sg, def, [black])))-
            [english-'The girl sees the boys\' black house.',
             spanish-'La niña ve la casa negra de los niños.',
             italian-'La ragazza vede la casa nera dei ragazzi.',
             persian-'دختر خانه‌ی سیاه پسرها را می‌بیند.'],
        copula(present, pos, of(G, np(house, sg, def, [])), adj([big]))-
            [english-'The girl\'s house is big.', spanish-'La casa de la niña es grande.',
             italian-'La casa della ragazza è grande.', persian-'خانه‌ی دختر بزرگ است.'],
        clause(sleep, present, pos, D, none, [pp(in, of(B, np(house, sg, def, [])))])-
            [english-'The dog sleeps in the boy\'s house.', spanish-'El perro duerme en la casa del niño.',
             italian-'Il cane dorme nella casa del ragazzo.', persian-'سگ در خانه‌ی پسر می‌خوابد.'],
        clause(sleep, present, pos, rel(B, clause(sleep, present, pos, of(gap, D), none)), none)-
            [english-'The boy whose dog sleeps sleeps.', spanish-'El niño cuyo perro duerme duerme.',
             italian-'Il ragazzo il cui cane dorme dorme.', persian-'پسری که سگش می‌خوابد می‌خوابد.'],
        clause(sleep, present, pos, rel(G, clause(see, present, pos, D, of(gap, np(house, sg, def, [])))), none)-
            [english-'The girl whose house the dog sees sleeps.', spanish-'La niña cuya casa el perro ve duerme.',
             italian-'La ragazza la cui casa il cane vede dorme.',
             persian-'دختری که سگ خانه‌اش را می‌بیند می‌خوابد.'],
        clause(see, present, pos, G, rel(B, clause(see, present, pos, np(cat, sg, def, []), of(gap, np(dog, pl, def, [])))))-
            [english-'The girl sees the boy whose dogs the cat sees.',
             spanish-'La niña ve al niño a cuyos perros el gato ve.',
             italian-'La ragazza vede il ragazzo i cui cani il gatto vede.',
             persian-'دختر پسری را می‌بیند که گربه سگ‌هایش را می‌بیند.'],
        clause(sleep, present, pos, rel(np(boy, pl, def, []), clause(sleep, present, pos, of(gap, D), none)), none)-
            [english-'The boys whose dog sleeps sleep.', spanish-'Los niños cuyo perro duerme duermen.',
             italian-'I ragazzi il cui cane dorme dormono.',
             persian-'پسرهایی که سگشان می‌خوابد می‌خوابند.'] ]),
    %% `de' is a possessor's word and an adposition: both are read.
    findall(O, ( typology_read(spanish, 'El niño ve al perro del niño.', IR1),
                 ( IR1 = clause(see, _, _, B, of(B, D)) -> O = possessor
                 ; IR1 = clause(see, _, _, B, D, [pp(from, B)]) -> O = adjunct ) ), Os0),
    sort(Os0, Os1),
    check('Spanish: del niño, a possessor or an adjunct', Os1, [adjunct, possessor]),
    ( typology_read(english, 'The boys\' dog sleeps.', clause(sleep, present, pos, of(np(boy, pl, def, []), D), none))
    -> R2 = read ; R2 = not_read ),
    check('English: the boys\' dog, s\' after s', R2, read),
    %% A Persian object that is neither definite nor indefinite is not read;
    %% the two nouns are a possessor, the ezafe unwritten after a consonant
    %% (the dog's boy sees).
    findall(IR5, typology_read(persian, 'پسر سگ می‌بیند.', IR5), IRs5),
    check('Persian: پسر سگ is the dog''s boy, never a bare object', IRs5,
          [clause(see, present, pos, of(D, B), none)]),
    %% Refused: an article before a possessor's head in English, `cuyo' that
    %% does not agree with the possessed.
    forall(member(L-T, [ english-'The the boy\'s dog sleeps.', english-'The boy\'s the dog sleeps.',
                         spanish-'El niño cuya perro duerme duerme.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    typology_translate(english, persian, 'The girl sees the boy whose dog sleeps.', P3),
    check('English into Persian: whose is a clitic on the possessed', P3, 'دختر پسری را می‌بیند که سگش می‌خوابد.'),
    assertz(ty_gap(tiny, poss, moves)),
    assertz(ty_possessive(tiny, [h, g], [x], maybe)),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms),
                 memberchk(M, [relative_possessive, bad(ty_possessive(tiny, [h, g], [x], maybe))]) ), M4),
    retractall(ty_gap(tiny, _, _)), retractall(ty_possessive(tiny, _, _, _)),
    check('typology_check/2: a moved possessor needs its pronoun, and a construction its three parts and keep or drop', M4,
          [relative_possessive, bad(ty_possessive(tiny, [h, g], [x], maybe))]),
    more_possessors.

%% 1.33.0: a possessor's possessor, a possessor with a relative clause,
%% `in whose house', and the possessive pronouns.
more_possessors :-
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    House = np(house, sg, def, []),
    written_each(more_possessors, [
        clause(see, present, pos, G, of(of(B, D), House))-
            [english-'The girl sees the boy\'s dog\'s house.', spanish-'La niña ve la casa del perro del niño.',
             italian-'La ragazza vede la casa del cane del ragazzo.',
             persian-'دختر خانه‌ی سگ پسر را می‌بیند.'],
        clause(sleep, present, pos, of(rel(B, clause(sleep, present, pos, gap, none)), D), none)-
            [english-'The dog of the boy that sleeps sleeps.', spanish-'El perro del niño que duerme duerme.',
             italian-'Il cane del ragazzo che dorme dorme.', persian-'سگ پسری که می‌خوابد می‌خوابد.'],
        clause(see, present, pos, G, rel(B, clause(sleep, present, pos, D, none, [pp(in, of(gap, House))])))-
            [english-'The girl sees the boy in whose house the dog sleeps.',
             spanish-'La niña ve al niño en cuya casa el perro duerme.',
             italian-'La ragazza vede il ragazzo nella cui casa il cane dorme.',
             persian-'دختر پسری را می‌بیند که سگ در خانه‌اش می‌خوابد.'],
        clause(sleep, present, pos, of(pron(3, sg, m), D), none)-
            [english-'His dog sleeps.', spanish-'Su perro duerme.',
             italian-'Il suo cane dorme.', persian-'سگش می‌خوابد.'],
        clause(see, present, pos, G, of(pron(3, pl, _), np(house, pl, def, [black])))-
            [english-'The girl sees their black houses.', spanish-'La niña ve sus casas negras.',
             italian-'La ragazza vede le loro case nere.', persian-'دختر خانه‌های سیاهشان را می‌بیند.'],
        clause(sleep, present, pos, D, none, [pp(in, of(pron(3, sg, f), House))])-
            [english-'The dog sleeps in her house.', spanish-'El perro duerme en su casa.',
             italian-'Il cane dorme nella sua casa.', persian-'سگ در خانه‌اش می‌خوابد.'] ]),
    ( typology_read(english, 'The dog of the boy sleeps.', clause(sleep, present, pos, of(B, D), none))
    -> R1 = read ; R1 = not_read ),
    check('English: the dog of the boy, the second construction, is read', R1, read),
    %% A pronoun's words tell what they tell, and leave the rest unbound.
    forall(member(L-T-Want, [ spanish-'Su perro duerme.'-[pron(3, _, _), pron(polite, _, _)],
                              english-'Its dog sleeps.'-[pron(3, sg, n)],
                              italian-'Il loro cane dorme.'-[pron(3, pl, _)],
                              persian-'سگش می‌خوابد.'-[pron(3, sg, _)] ]),
           ( findall(Pr, typology_read(L, T, clause(sleep, present, pos, of(Pr, D), none)), Prs0),
             sort(Prs0, Prs),
             atomic_list_concat([L, ': ', T, ' is the pronoun its words tell'], Label),
             ( Prs =@= Want -> R = told ; R = Prs ),
             check(Label, R, told) )),
    forall(member(L-T, [ english-'The his dog sleeps.', italian-'Il sua cane dorme.',
                         english-'The boy\'s that sleeps dog sleeps.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    typology_translate(spanish, english, 'La niña ve al niño en cuya casa el perro duerme.', E2),
    check('Spanish into English: en cuya casa is in whose house', E2,
          'The girl sees the boy in whose house the dog sleeps.').

%% ---- a verb's complement ---------------------------------------------------------------

complements :-
    section('a verb''s complement: an adposition phrase the verb chooses'),
    B = np(boy, sg, def, []), G = np(girl, sg, def, []), D = np(dog, sg, def, []),
    written_each(complements, [
        clause(think, present, pos, B, G)-
            [english-'The boy thinks about the girl.', spanish-'El niño piensa en la niña.',
             italian-'Il ragazzo pensa alla ragazza.', persian-'پسر به دختر فکر می‌کند.'],
        clause(look, past, pos, B, D)-
            [english-'The boy looked at the dog.', spanish-'El niño miró al perro.',
             italian-'Il ragazzo guardò il cane.', persian-'پسر به سگ نگاه کرد.'],
        clause(depend, present, neg, B, np(house, sg, def, []))-
            [english-'The boy does not depend on the house.', spanish-'El niño no depende de la casa.',
             italian-'Il ragazzo non dipende dalla casa.'],
        question(clause(think, present, pos, B, wh(what)))-
            [english-'What does the boy think about?', spanish-'¿En qué piensa el niño?',
             italian-'A cosa pensa il ragazzo?', persian-'پسر به چه چیزی فکر می‌کند؟'],
        question(clause(think, present, pos, B, wh(who)))-
            [english-'Who does the boy think about?', spanish-'¿En quién piensa el niño?',
             italian-'A chi pensa il ragazzo?', persian-'پسر به چه کسی فکر می‌کند؟'],
        question(clause(think, present, pos, B, G))-
            [english-'Does the boy think about the girl?', spanish-'¿El niño piensa en la niña?',
             italian-'Il ragazzo pensa alla ragazza?', persian-'پسر به دختر فکر می‌کند؟'],
        clause(sleep, present, pos, rel(G, clause(think, present, pos, B, gap)), none)-
            [english-'The girl that the boy thinks about sleeps.',
             spanish-'La niña en la que el niño piensa duerme.',
             italian-'La ragazza a cui il ragazzo pensa dorme.',
             persian-'دختری که پسر به او فکر می‌کند می‌خوابد.'] ]),
    %% The IR is the plain object, so a complement in one language is a
    %% plain object in another.
    typology_translate(english, spanish, 'The boy looks at the dog.', S1),
    check('English into Spanish: look at is mirar, and its object takes a', S1, 'El niño mira al perro.'),
    typology_translate(spanish, english, 'El niño mira al perro.', E1),
    check('and back', E1, 'The boy looks at the dog.'),
    %% With no object, the verb's own adposition is its complement, never
    %% an adjunct.
    findall(O2, typology_read(spanish, 'El niño piensa en la casa.', clause(think, _, _, _, O2)), O2s0),
    sort(O2s0, O2s),
    check('Spanish: piensa en la casa is about the house, never thinking in it', O2s,
          [np(home, sg, def, []), np(house, sg, def, []), np(household, sg, def, [])]),
    %% Refused: a plain object where the verb takes a complement, the
    %% adposition moved where it stays, a mark on a complement.
    forall(member(L-T, [ english-'The boy looks the dog.',
                         english-'About what does the boy think?',
                         spanish-'El niño piensa a la niña.',
                         persian-'پسر به دختر را فکر می‌کند.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    forall(member(L-T-Want-WantFs,
                  [ english-'The boy looks the dog.'-'The boy looks at the dog.'-[complement(missing, [at])],
                    english-'About what does the boy think?'-'What does the boy think about?'-[complement_wh(moves)],
                    spanish-'El niño piensa a la niña.'-'El niño piensa en la niña.'-[complement(missing, [en])] ]),
           ( ( once(typology_repair(L, T, _, Fs, F)) -> true ; F = none, Fs = none ),
             atomic_list_concat([L, ': ', T, ' is repaired to ', Want], Label),
             check(Label, F-Fs, Want-WantFs) )),
    %% A complement's gap where the adposition moves (above, Spanish and
    %% Italian) is written since 1.30.0; the section on gaps has the rest.
    true.

%% ---- the place of the negation ---------------------------------------------------------

negation_places :-
    section('the place of the negation: a part of the order'),
    %% Two languages of the English rows: `not' at the end (as German
    %% `nicht'), and `ne' and `pas' around the verb (as French).
    english_rows_as(nicht),
    assertz(ty_negation_place(nicht, [not], end)),
    retractall(ty_question(nicht, _, _, _)),
    assertz(ty_question(nicht, yes_no, clause, front(all))),
    assertz(ty_question(nicht, wh, clause, front(all))),
    english_rows_as(nepas),
    assertz(ty_negation_place(nepas, [ne], before(v))),
    assertz(ty_negation_place(nepas, [pas], after(v))),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    written_each(negation_places, [
        clause(see, present, neg, B, D)-
            [english-'The boy does not see the dog.', nicht-'The boy sees the dog not.',
             nepas-'The boy ne sees pas the dog.'],
        clause(see, past, neg, np(boy, pl, def, []), D)-
            [nicht-'The boys saw the dog not.', nepas-'The boys ne saw pas the dog.'],
        clause(sleep, present, neg, B, none, [pp(in, np(house, sg, def, []))])-
            [nicht-'The boy sleeps in the house not.', nepas-'The boy ne sleeps pas in the house.'],
        clause(see, present, pos, B, D)-
            [nicht-'The boy sees the dog.', nepas-'The boy sees the dog.'],
        question(clause(see, present, neg, B, D))-
            [nicht-'Sees the boy the dog not?', nepas-'Ne sees pas the boy the dog?'] ]),
    forall(member(L-T, [ nicht-'The boy does not see the dog.', nicht-'The boy sees not the dog.',
                         nepas-'The boy ne sees the dog.', nepas-'The boy does not see the dog.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    once(typology_repair(nicht, 'The boy sees not the dog.', _, Fs1, F1)),
    check('a negation in another place, repaired', F1-Fs1,
          'The boy sees the dog not.'-[negation_place([[not]-after(v)])]),
    typology_translate(spanish, nicht, 'El niño no ve al perro.', N2),
    check('Spanish into the language of the place: the verb positive, not at the end', N2,
          'The boy sees the dog not.'),
    maplist([L, M]>>typology_check(L, M), [nicht, nepas], Ms),
    check('both templates are complete', Ms, [[], []]).

%% ---- several question words, and `which' ----------------------------------------------

question_words :-
    section('several question words, and a question word inside a noun phrase'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    written_each(question_words, [
        question(clause(see, present, pos, wh(who), wh(what)))-
            [english-'Who sees what?', spanish-'¿Quién ve qué?',
             italian-'Chi vede cosa?', persian-'چه کسی چه چیزی می‌بیند؟'],
        question(clause(see, present, pos, wh(who), wh(who)))-
            [english-'Who sees who?', spanish-'¿Quién ve a quién?',
             italian-'Chi vede chi?', persian-'چه کسی چه کسی را می‌بیند؟'],
        question(clause(sleep, present, pos, wh(who), none, [wh(where)]))-
            [english-'Who sleeps where?', spanish-'¿Quién duerme dónde?',
             italian-'Chi dorme dove?', persian-'چه کسی کجا می‌خوابد؟'],
        question(clause(see, present, pos, B, np(dog, sg, which, [])))-
            [english-'Which dog does the boy see?', spanish-'¿A qué perro ve el niño?',
             italian-'Il ragazzo quale cane vede?', persian-'پسر کدام سگ را می‌بیند؟'],
        question(clause(see, past, pos, np(girl, pl, which, [small]), D))-
            [english-'Which small girls saw the dog?', spanish-'¿Qué niñas pequeñas vieron al perro?',
             italian-'Quali ragazze piccole videro il cane?', persian-'کدام دخترهای کوچک سگ را دیدند؟'],
        question(clause(sleep, present, pos, D, none, [pp(in, np(house, sg, which, []))]))-
            [english-'In which house does the dog sleep?', spanish-'¿En qué casa duerme el perro?',
             italian-'In quale casa dorme il cane?', persian-'سگ در کدام خانه می‌خوابد؟'],
        question(copula(present, pos, np(dog, sg, which, []), adj([big])))-
            [english-'Which dog is big?', spanish-'¿Qué perro es grande?',
             italian-'Quale cane è grande?', persian-'کدام سگ بزرگ است؟'],
        question(clause(see, present, pos, np(boy, sg, which, []), wh(what)))-
            [english-'Which boy sees what?', spanish-'¿Qué niño ve qué?',
             italian-'Quale ragazzo vede cosa?', persian-'کدام پسر چه چیزی می‌بیند؟'] ]),
    %% Refused: the object's question word moved over the subject's, a
    %% question word in a statement.
    forall(member(L-T, [ english-'What does who see?', english-'The boy sees which dog.',
                         spanish-'¿Qué ve quién?', spanish-'El niño ve qué perro.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    typology_translate(english, persian, 'Which dog does the boy see?', P1),
    check('English into Persian: the noun phrase of which stays in place, with را', P1,
          'پسر کدام سگ را می‌بیند؟').

%% ---- the yes or no answer -----------------------------------------------------------

answers :-
    section('the answer to a yes or no question'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    written_each(answers, [
        answer(pos, pos)-[english-'Yes.', spanish-'Sí.', italian-'Sì.', persian-'بله.'],
        answer(neg, pos)-[english-'No.', spanish-'No.', italian-'No.', persian-'نه.'],
        answer(pos, neg)-[persian-'چرا.'],
        answer(pos, pos, clause(see, present, pos, B, D))-
            [english-'Yes, the boy sees the dog.', spanish-'Sí, el niño ve al perro.',
             italian-'Sì, il ragazzo vede il cane.', persian-'بله، پسر سگ را می‌بیند.'],
        answer(neg, pos, clause(see, present, neg, B, D))-
            [english-'No, the boy does not see the dog.', spanish-'No, el niño no ve al perro.',
             italian-'No, il ragazzo non vede il cane.', persian-'نه، پسر سگ را نمی‌بیند.'],
        answer(pos, neg, copula(present, pos, D, adj([big])))-
            [english-'Yes, the dog is big.', persian-'چرا، سگ بزرگ است.'] ]),
    Q = question(clause(see, present, neg, B, D)),
    findall(L-A1-A2, ( member(L, [english, spanish, italian, persian]),
                       typology_answer(L, Q, pos, A1), typology_answer(L, Q, neg, A2) ), As),
    check('the answers to a negative question: Persian contradicts with چرا', As,
          [english-'Yes.'-'No.', spanish-'Sí.'-'No.', italian-'Sì.'-'No.', persian-'چرا.'-'نه.']),
    findall(R1, typology_read(english, 'Yes.', R1), R1s),
    check('English yes answers a positive or a negative question', R1s,
          [answer(pos, pos), answer(pos, neg)]),
    ( typology_read(english, 'Yes, the boy does not see the dog.', _) -> R2 = read ; R2 = refused ),
    check('a yes and a negative clause are refused', R2, refused),
    %% An agreement system (as Japanese): yes agrees with the question.
    english_rows_as(agree),
    assertz(ty_answer(agree, yes, [yes])),
    assertz(ty_answer(agree, no, [no])),
    assertz(ty_answer_system(agree, agreement)),
    findall(A3-A4, ( typology_answer(agree, Q, pos, A3), typology_answer(agree, Q, neg, A4) ), A34),
    check('in an agreement system, to a negative question, he does is no and he does not yes', A34,
          ['No.'-'Yes.']),
    typology_check(agree, M5),
    check('the agreement template is complete', M5, []).

%% ---- the personal pronoun -------------------------------------------------------

%% 1.34.0: a personal pronoun of every person as a subject, an object, an
%% adposition's and a possessor; the verb's person; a subject no word
%% says; an object clitic.
pronouns :-
    section('personal pronouns, the verb''s person, a subject the verb''s form tells, an object clitic'),
    D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    written_each(pronouns, [
        clause(see, present, pos, pron(1, sg, _), D)-
            [english-'I see the dog.', spanish-'Veo al perro.', italian-'Vedo il cane.',
             persian-'سگ را می‌بینم.'],
        clause(see, present, neg, pron(2, sg, _), D)-
            [english-'You do not see the dog.', spanish-'No ves al perro.', italian-'Non vedi il cane.',
             persian-'سگ را نمی‌بینی.'],
        clause(sleep, past, pos, pron(3, sg, f), none)-
            [english-'She slept.', spanish-'Ella durmió.', italian-'Lei dormì.', persian-'او خوابید.'],
        clause(see, present, pos, G, pron(3, sg, m))-
            [english-'The girl sees him.', spanish-'La niña lo ve.', italian-'La ragazza lo vede.',
             persian-'دختر او را می‌بیند.'],
        clause(see, present, neg, pron(1, pl, _), pron(3, pl, f))-
            [english-'We do not see them.', spanish-'No las vemos.', italian-'Non le vediamo.',
             persian-'آنها را نمی‌بینیم.'],
        clause(see, past, pos, pron(2, pl, _), D)-
            [english-'You saw the dog.', spanish-'Visteis al perro.', italian-'Vedeste il cane.',
             persian-'سگ را دیدید.'],
        clause(sleep, present, pos, of(pron(1, sg, _), D), none)-
            [english-'My dog sleeps.', spanish-'Mi perro duerme.', italian-'Il mio cane dorme.',
             persian-'سگم می‌خوابد.'],
        clause(see, present, pos, pron(2, pl, _), of(pron(1, pl, _), np(house, sg, def, [])))-
            [english-'You see our house.', spanish-'Veis nuestra casa.', italian-'Vedete la nostra casa.',
             persian-'خانه‌مان را می‌بینید.'],
        copula(present, pos, pron(1, sg, _), adj([small]))-
            [english-'I am small.', spanish-'Soy pequeño.', italian-'Sono piccolo.', persian-'کوچک هستم.'],
        copula(past, neg, pron(2, pl, f), adj([small]))-
            [english-'You were not small.', spanish-'No erais pequeñas.', italian-'Non eravate piccole.',
             persian-'کوچک نبودید.'],
        clause(sleep, present, pos, D, none, [pp(with, pron(1, sg, _))])-
            [english-'The dog sleeps with me.', spanish-'El perro duerme conmigo.',
             italian-'Il cane dorme con me.', persian-'سگ با من می‌خوابد.'],
        clause(think, present, pos, pron(3, sg, m), pron(3, sg, f))-
            [english-'He thinks about her.', spanish-'Él piensa en ella.', italian-'Lui pensa a lei.',
             persian-'او به او فکر می‌کند.'],
        clause(sleep, present, pos, pron(3, sg, _), none)-
            [english-'He sleeps.', spanish-'Duerme.', italian-'Dorme.', persian-'می‌خوابد.'],
        question(clause(see, present, pos, pron(2, sg, _), D))-
            [english-'Do you see the dog?', spanish-'¿Ves al perro?', italian-'Vedi il cane?',
             persian-'سگ را می‌بینی؟'],
        question(clause(see, present, pos, G, pron(3, sg, m)))-
            [english-'Does the girl see him?', spanish-'¿La niña lo ve?', italian-'La ragazza lo vede?',
             persian-'دختر او را می‌بیند؟'] ]),
    %% A reading binds what its words tell.
    forall(member(L-T-Want, [ english-'I see the dog.'-[clause(see, present, pos, pron(1, sg, _), D)],
                              english-'Do you see the dog?'-[question(clause(see, present, pos, pron(2, sg, _), D)),
                                                             question(clause(see, present, pos, pron(2, pl, _), D)),
                                                             question(clause(see, present, pos, pron(polite, sg, _), D)),
                                                             question(clause(see, present, pos, pron(polite, pl, _), D))],
                              spanish-'Duerme.'-[clause(sleep, present, pos, pron(3, sg, _), none)],
                              spanish-'Soy pequeña.'-[copula(present, pos, pron(1, sg, f), adj([small]))],
                              spanish-'No las vemos.'-[clause(see, present, neg, pron(1, pl, _), pron(3, pl, f)),
                                                       clause(see, present, neg, pron(1, pl, _), pron(polite, pl, f))],
                              persian-'کوچک نیستید.'-[copula(present, neg, pron(2, pl, _), adj([small]))],
                              italian-'Lo vedi.'-[clause(see, present, pos, pron(2, sg, _), pron(3, sg, m)),
                                                  clause(see, present, pos, pron(2, sg, _), pron(3, sg, n))] ]),
           ( findall(IR, ( typology_read(L, T, IR), \+ ty_meanings_other(IR) ), IRs),
             atomic_list_concat([L, ': ', T, ' is what its words tell'], Label),
             ( IRs =@= Want -> R = told ; R = IRs ),
             check(Label, R, told) )),
    typology_translate(spanish, english, 'La niña la ve.', E1),
    check('Spanish into English: the clitic la is her', E1, 'The girl sees her.'),
    typology_translate(english, spanish, 'She does not see me.', S1),
    check('English into Spanish: ella and the clitic after no', S1, 'Ella no me ve.'),
    typology_translate(persian, italian, 'کتاب‌هایمان را دیدی.', I1),
    check('Persian into Italian: two clitics, our and the verb''s you', I1, 'Vedesti i nostri libri.'),
    typology_translate(italian, persian, 'Non sei piccolo.', P1),
    check('Italian into Persian: the copula of you', P1, 'کوچک نیستی.'),
    %% `sleep' takes no object, so a subject no word says is no reading of
    %% a question in the verb's order.
    findall(Q, typology_read(spanish, '¿Duerme el perro?', Q), Qs),
    check('Spanish: ¿Duerme el perro? is the dog sleeping, not his sleeping of a dog', Qs,
          [question(clause(sleep, present, pos, D, none))]),
    %% Refused: a verb of another person, an object pronoun as a subject, a
    %% clitic before the negation.
    forall(member(L-T, [ english-'I sees the dog.', english-'Me see the dog.', english-'Him sleeps.',
                         spanish-'Yo ve al perro.', spanish-'Lo no veo.', italian-'Io dorme.',
                         persian-'من می‌خوابد.' ]),
           ( ( typology_read(L, T, _) -> R = read ; R = refused ),
             atomic_list_concat([L, ': ', T], Label),
             check(Label, R, refused) )),
    %% The import gives the persons of a verb the hand template has not.
    ( ty_verb(spanish, think, present, sg(1), pos, [pienso]) -> R2 = imported ; R2 = missing ),
    check('Spanish: pienso, the first person of think, is imported', R2, imported),
    assertz(ty_pronoun(tiny, x, [w], [[4]])),
    assertz(ty_pro_drop(tiny, [3, 5])),
    assertz(ty_clitic(tiny, o)),
    assertz(ty_verb_person(tiny, any, sg(7), pl, '', '')),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms),
                 memberchk(M, [bad(ty_pronoun(tiny, x, [w], [[4]])), bad(ty_pro_drop(tiny, [3, 5])),
                               clitic_pronoun, bad(ty_verb_person(tiny, any, sg(7), pl, '', ''))]) ), M3),
    retractall(ty_pronoun(tiny, _, _, _)), retractall(ty_pro_drop(tiny, _)),
    retractall(ty_clitic(tiny, _)), retractall(ty_verb_person(tiny, _, _, _, _, _)),
    check('typology_check/2: a pronoun''s role and condition, the persons, a clitic''s rows, a rule''s key', M3,
          [clitic_pronoun, bad(ty_pro_drop(tiny, [3, 5])), bad(ty_pronoun(tiny, x, [w], [[4]])),
           bad(ty_verb_person(tiny, any, sg(7), pl, '', ''))]).

%% ---- the echo, and every question word at the front --------------------------

%% 1.35.0: the answer that repeats its clause short (English `Yes, he
%% does.', Persian `بله، می‌بینم.'), and every question word at the front.
echoes :-
    section('the answer that repeats its clause, and every question word at the front'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    forall(member(L-Q-Pol-Want,
                  [ english-question(clause(see, present, pos, B, D))-pos-'Yes, he does.',
                    english-question(clause(see, present, neg, G, D))-neg-'No, she does not.',
                    english-question(clause(see, present, pos, pron(2, sg, _), D))-pos-'Yes, I do.',
                    english-question(clause(sleep, past, pos, pron(2, pl, _), none))-neg-'No, we did not.',
                    english-question(copula(present, pos, G, adj([small])))-pos-'Yes, she is.',
                    english-question(copula(present, pos, pron(2, sg, _), adj([small])))-neg-'No, I am not.',
                    english-question(copula(past, pos, D, adj([big])))-pos-'Yes, it was.',
                    persian-question(clause(see, present, pos, pron(2, sg, _), D))-pos-'بله، می‌بینم.',
                    persian-question(clause(see, present, neg, pron(2, sg, _), D))-pos-'چرا، می‌بینم.',
                    persian-question(clause(sleep, past, pos, pron(2, pl, _), none))-neg-'نه، نخوابیدیم.',
                    persian-question(copula(present, pos, pron(2, sg, _), adj([small])))-pos-'بله، هستم.' ]),
           ( ( typology_answer(L, Q, Pol, echo, T) -> true ; T = none ),
             atomic_list_concat([L, ': the echo ', Want], Label),
             check(Label, T, Want) )),
    findall(R1, typology_read(english, 'Yes, he does.', R1), R1s),
    ( R1s =@= [answer(pos, pos, echo(clause(_, present, pos, pron(3, sg, m), none))),
               answer(pos, neg, echo(clause(_, present, pos, pron(3, sg, m), none)))] -> X1 = told ; X1 = R1s ),
    check('English: Yes, he does. says no verb, and answers a positive or a negative question', X1, told),
    ( typology_read(english, 'Yes, he do.', _) -> X2 = read ; X2 = refused ),
    check('English: an auxiliary of another person is refused', X2, refused),
    Q3 = question(clause(see, present, pos, B, D)),
    typology_answer(english, Q3, pos, word, A3), typology_answer(english, Q3, pos, A3b),
    check('the word form is typology_answer/4''s', A3, A3b),
    typology_answer(english, Q3, neg, clause, A4),
    check('the clause form, of the answer''s polarity', A4, 'No, the boy does not see the dog.'),
    ( typology_answer(spanish, Q3, pos, echo, _) -> X5 = written ; X5 = none ),
    check('Spanish has no echo row, and no echo', X5, none),
    retract(ty_answer_echo(persian, verb, keep)), assertz(ty_answer_echo(persian, verb, drop)),
    typology_answer(persian, question(clause(see, present, pos, pron(2, sg, _), D)), pos, echo, A6),
    retract(ty_answer_echo(persian, verb, drop)), assertz(ty_answer_echo(persian, verb, keep)),
    check('Word drop: the verb alone, as Portuguese Vejo.', A6, 'می‌بینم.'),
    %% Every question word at the front, on English's rows under another
    %% name (Bulgarian `Кой какво вижда?', who what sees).
    english_rows_as(front_all),
    forall(( member(F, [ty_question_form(english, _, _, _, _), ty_adverb(english, _, _)]), call(F) ),
           ( F =.. [P, english|Args], F2 =.. [P, front_all|Args], assertz(F2) )),
    retractall(ty_wh(front_all, _)), assertz(ty_wh(front_all, all_front)),
    forall(member(Q-Want, [ question(clause(see, present, pos, wh(who), wh(what)))-'Who what sees?',
                            question(clause(see, past, pos, B, wh(what), [wh(where)]))-'What where did the boy see?',
                            question(clause(see, past, pos, B, wh(what)))-'What did the boy see?' ]),
           ( typology_write(front_all, Q, T),
             atomic_list_concat(['every question word at the front: ', Want], Label),
             check(Label, T, Want),
             findall(R, typology_read(front_all, T, R), Rs),
             atomic_list_concat(['read back, one reading: ', Want], Label2),
             check(Label2, Rs, [Q]) )),
    ( typology_read(front_all, 'Who sees what?', _) -> X7 = read ; X7 = refused ),
    check('a question word in place is refused where every one is at the front', X7, refused),
    typology_write(english, question(clause(see, present, pos, wh(who), wh(what))), E8),
    check('English keeps the second in place', E8, 'Who sees what?'),
    typology_check(front_all, M9),
    check('the template of every question word at the front is complete', M9, []),
    assertz(ty_answer_echo(tiny, x, y)),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms), M = bad(ty_answer_echo(_, _, _)) ), M10),
    retractall(ty_answer_echo(tiny, _, _)),
    check('typology_check/2: an echo''s rule and word', M10, [bad(ty_answer_echo(tiny, x, y))]).

%% ---- French ------------------------------------------------------------------

%% 1.36.0: a French template: elision, contractions, the negation around
%% the verb, adjectives before the noun, `est-ce que', `dont', `qui' and
%% `que', `lequel', clitics inside the negation.
french :-
    section('French: elision, ne ... pas, adjectives before the noun, est-ce que, dont'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    H = np(house, sg, def, []),
    Rows = [ clause(see, present, pos, B, np(dog, sg, def, [black]))-'Le garçon voit le chien noir.',
             clause(see, present, neg, B, D)-'Le garçon ne voit pas le chien.',
             clause(see, past, pos, np(girl, pl, def, [small]), np(book, pl, indef, [red]))-
                 'Les petites filles virent des livres rouges.',
             clause(sleep, present, pos, np(man, sg, def, []), none)-'L\'homme dort.',
             clause(sleep, present, neg, D, none, [pp(in, H)])-'Le chien ne dort pas dans la maison.',
             clause(think, present, pos, B, D)-'Le garçon pense au chien.',
             clause(see, present, pos, G, pron(3, sg, m))-'La fille le voit.',
             clause(see, present, neg, pron(1, sg, _), pron(3, sg, f))-'Je ne la vois pas.',
             copula(present, neg, pron(2, pl, _), adj([small]))-'Vous n\'êtes pas petits.',
             clause(sleep, present, pos, of(B, D), none)-'Le chien du garçon dort.',
             clause(see, present, pos, G, of(pron(3, pl, _), np(house, pl, def, [])))-'La fille voit leurs maisons.',
             clause(sleep, present, pos, rel(D, clause(see, present, pos, B, gap)), none)-
                 'Le chien que le garçon voit dort.',
             clause(sleep, present, pos, rel(D, clause(sleep, present, pos, gap, none)), none)-'Le chien qui dort dort.',
             clause(sleep, present, pos, rel(B, clause(sleep, present, pos, of(gap, D), none)), none)-
                 'Le garçon dont le chien dort dort.',
             clause(sleep, present, pos, D, none,
                    [pp(in, rel(H, clause(sleep, present, pos, np(cat, sg, def, []), none, [pp(in, gap)])))])-
                 'Le chien dort dans la maison dans laquelle le chat dort.',
             clause(sleep, present, pos, rel(G, clause(think, present, pos, B, gap)), none)-
                 'La fille à qui le garçon pense dort.',
             question(clause(see, present, pos, B, D))-'Est-ce que le garçon voit le chien?',
             question(clause(see, present, pos, B, wh(what)))-'Que voit le garçon?',
             question(clause(see, past, pos, G, wh(who)))-'Qui est-ce que la fille vit?',
             question(copula(present, pos, D, wh(where)))-'Où est le chien?',
             answer(pos, neg)-'Si.' ],
    forall(member(IR-Want, Rows),
           ( typology_write(french, IR, T),
             atomic_list_concat(['French: ', Want], Label),
             check(Label, T, Want),
             ( typology_read(french, T, IR) -> R = read ; R = not_read ),
             atomic_list_concat(['French: read back: ', Want], Label2),
             check(Label2, R, read) )),
    ( typology_read(french, 'Le chien petit dort.', clause(sleep, present, pos, np(dog, sg, def, [small]), none))
    -> R1 = read ; R1 = refused ),
    check('French: an adjective written before is read after too', R1, read),
    forall(member(T, [ 'Le homme dort.', 'La garçon dort.', 'Le garçon voit pas le chien.',
                       'Le garçon ne voit le chien.', 'Le garçon ne le voit le chien pas.' ]),
           ( ( typology_read(french, T, _) -> R = read ; R = refused ),
             atomic_list_concat(['French: ', T], Label),
             check(Label, R, refused) )),
    forall(member(From-T-Want, [ spanish-'No lo veo.'-'Je ne le vois pas.',
                                 english-'The girl sees the boy whose dog sleeps.'-'La fille voit le garçon dont le chien dort.',
                                 italian-'Il ragazzo pensa al cane.'-'Le garçon pense au chien.',
                                 persian-'دختر خانه‌مان را می‌بیند.'-'La fille voit notre maison.',
                                 english-'Who did the girl see?'-'Qui est-ce que la fille vit?' ]),
           ( typology_translate(From, french, T, F),
             atomic_list_concat([From, ' into French: ', Want], Label),
             check(Label, F, Want) )),
    typology_translate(french, spanish, 'La fille à qui le garçon pense dort.', S2),
    check('French into Spanish: à qui is en la que', S2, 'La niña en la que el niño piensa duerme.').

%% ---- the pronoun of the text ---------------------------------------------------

%% 1.37.0: a pronoun that refers back to a noun of the text,
%% pron(3, Number, ref(Meaning)), and each language's kind for it.
references :-
    section('a pronoun that refers back to a noun of the text'),
    typology_read_text(spanish, ['El niño ve la casa.', 'La ve.'], IRs1),
    ( IRs1 =@= [clause(see, present, pos, np(boy, sg, def, []), np(house, sg, def, [])),
                clause(see, present, pos, pron(3, sg, ref(boy)), pron(3, sg, ref(house)))] -> X1 = told ; X1 = IRs1 ),
    check('Spanish: the subject no word says is the boy, la the house', X1, told),
    forall(member(F-To-Ts-Want,
                  [ spanish-english-['El niño ve la casa.', 'La ve.']-['The boy sees the house.', 'He sees it.'],
                    english-spanish-['The girl sees the house.', 'She sees it.']-['La niña ve la casa.', 'La ve.'],
                    english-italian-['The boy sees the book.', 'He sees it.']-['Il ragazzo vede il libro.', 'Lo vede.'],
                    english-french-['The girl sees the house.', 'She sees it.']-['La fille voit la maison.', 'Elle la voit.'],
                    spanish-english-['La niña ve al perro.', 'Lo ve.']-['The girl sees the dog.', 'She sees it.'],
                    english-spanish-['The boy sees the girl.', 'She sleeps.', 'He sees her.']-
                        ['El niño ve a la niña.', 'Duerme.', 'La ve.'],
                    english-french-['The houses are big.', 'The boy sees them.']-
                        ['Les maisons sont grandes.', 'Le garçon les voit.'],
                    persian-english-['پسر سگ را می‌بیند.', 'آن را می‌بیند.']-['The boy sees the dog.', 'He sees it.'],
                    persian-english-['دختر می‌خوابد.', 'او سگ را می‌بیند.']-['The girl sleeps.', 'She sees the dog.'],
                    spanish-english-['El niño ve a su perro.']-['The boy sees his dog.'],
                    english-spanish-['He sleeps.']-['Él duerme.'] ]),
           ( typology_translate_text(F, To, Ts, Out),
             atomic_list_concat(Ts, ' ', Tx),
             atomic_list_concat([F, ' into ', To, ': ', Tx], Label),
             check(Label, Out, Want) )),
    IR2 = clause(see, present, pos, pron(3, sg, ref(girl)), pron(3, sg, ref(house))),
    findall(L-T, ( member(L, [english, spanish, italian, french, persian]), typology_write(L, IR2, T) ), Ts2),
    check('each language''s kind for the girl and the house', Ts2,
          [english-'She sees it.', spanish-'La ve.', italian-'La vede.', french-'Elle la voit.',
           persian-'آن را می‌بیند.']),
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), of(pron(3, sg, m), np(dog, sg, def, []))), S3),
    check('Spanish: a before a possessive pronoun and an animate noun is the mark', S3, 'El niño ve a su perro.'),
    assertz(ty_pronoun_gender(tiny, both)),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms), M = bad(ty_pronoun_gender(_, _)) ), M4),
    retractall(ty_pronoun_gender(tiny, _)),
    check('typology_check/2: a pronoun''s gender system', M4, [bad(ty_pronoun_gender(tiny, both))]).

%% ---- the topics a model gives ---------------------------------------------------

%% 1.38.0: in live mode the model gives the meanings the tables give no
%% topic their topics, once (reason_live_topics/2); a stub is the model.
%% The mode, the stubs and what was saved are put back whatever happens.
live_topics :-
    section('the topics a model gives a meaning in live mode'),
    setup_call_cleanup(true, live_topic_checks,
                       ( reason_set_mode(static), retractall(reason_live_stub(_, _, _)),
                         retractall(reason_live_topics(_, _)) )).

live_topic_checks :-
    use_module(library(reasoning/live)),
    T = 'El niño ve la lima.',
    lima_objects(T, O1),
    check('static: lima is the file and the lime, as neither has a topic', O1, [file, lime]),
    reason_set_mode(live),
    assertz(reason_live_stub('la lima', topics,
        '{"topics": [{"meaning": "lime", "topics": ["food", "plant"]}, {"meaning": "file", "topics": ["tool", "tool"]}, {"meaning": "see", "topics": ["nonsense"]}]}')),
    reason_live_stats_reset,
    lima_objects(T, O2),
    check('live: the model makes the lime food, and the food given keeps it', O2, [lime]),
    findall(M-Ts, reason_live_topics(M, Ts), Saved),
    check('each meaning asked is kept: known topics once, [] for the rest', Saved,
          [boy-[], child-[], file-[tool], infant-[], kid-[], lime-[food, plant], see-[], view-[]]),
    lima_objects(T, _),
    reason_live_stats(St3), memberchk(calls-C3, St3), memberchk(topics-N3, St3),
    check('one call, two meanings given topics: a meaning asked is not asked again', C3-N3, 1-2),
    typology_read(english, 'The dog sees the cat.', _),
    reason_live_stats(St4), memberchk(calls-C4, St4),
    check('a sentence with no word of several meanings asks nothing', C4, 1),
    assertz(reason_live_stub('la cometa', topics, 'Not JSON.')),
    findall(O, ( typology_read(spanish, 'El niño ve la cometa.', IR5), IR5 = clause(_, _, _, _, np(O, _, _, _)) ), O5a),
    sort(O5a, O5),
    reason_live_stats(St5), memberchk(calls-C5, St5),
    ( reason_live_topics(comet, _) -> K5 = kept ; K5 = none ),
    check('a reply that does not parse keeps nothing, and the reading is static''s', C5-K5-O5, 2-none-[comet, kite]),
    reason_set_mode(static),
    typology_read_text(spanish, ['El niño come la manzana.', T], [_, IR6]),
    check('static, after: the apple before it makes lima the lime', IR6,
          clause(see, present, pos, np(boy, sg, def, []), np(lime, sg, def, []))),
    reason_live_stats(St7), memberchk(calls-C7, St7),
    check('static mode asks nothing', C7, 2),
    reason_live_forget,
    findall(M, reason_live_topics(M, _), Left),
    check('reason_live_forget/0 takes the topics back', Left, []).

%% The meanings of the object in every reading of T, with food given.
lima_objects(T, Os) :-
    findall(O, ( typology_read(spanish, T, IR, [food]), IR = clause(_, _, _, _, np(O, _, _, _)) ), Os0),
    sort(Os0, Os).

%% ---- French questions ------------------------------------------------------------

%% 1.39.0: the inversion (ty_inversion/3, invert(pronoun)), `est-ce que'
%% after a question word, and `quoi' after a preposition and in place
%% (ty_wh_tonic/3).
french_questions :-
    section('French questions: the inversion, qu''est-ce que, quoi'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    Rows = [ 'Le garçon voit-il le chien?'-question(clause(see, present, pos, B, D)),
             'La fille dort-elle?'-question(clause(sleep, present, pos, G, none)),
             'Les filles voient-elles le chien?'-question(clause(see, present, pos, np(girl, pl, def, []), D)),
             'Le garçon ne voit-il pas le chien?'-question(clause(see, present, neg, B, D)),
             'Le garçon le voit-il?'-question(clause(see, present, pos, B, pron(3, sg, m))),
             'Vois-tu le chien?'-question(clause(see, present, pos, pron(2, sg, _), D)),
             'Pense-t-il à la fille?'-question(clause(think, present, pos, pron(3, sg, m), G)),
             'La maison est-elle grande?'-question(copula(present, pos, np(house, sg, def, []), adj([big]))),
             'Est-elle grande?'-question(copula(present, pos, pron(3, sg, f), adj([big]))),
             'Qu\'est-ce que le garçon voit?'-question(clause(see, present, pos, B, wh(what))),
             'Qui est-ce que la fille voit?'-question(clause(see, present, pos, G, wh(who))),
             'Que voit-il?'-question(clause(see, present, pos, pron(3, sg, m), wh(what))),
             'À quoi pense le garçon?'-question(clause(think, present, pos, B, wh(what))),
             'La fille voit quoi?'-question(clause(see, present, pos, G, wh(what))) ],
    forall(member(T-Want, Rows),
           ( findall(IR, typology_read(french, T, IR), IRs),
             ( member(IR1, IRs), IR1 =@= Want -> X = read ; X = IRs ),
             atomic_list_concat(['French: read ', T], Label),
             check(Label, X, read) )),
    forall(member(T-Why, [ 'Le garçon voit il le chien?'-'a pronoun after the verb is joined to it',
                           'Pense-il à la fille?'-'between two vowels the join is -t-',
                           'Voit-t-il le chien?'-'-t- only between two vowels',
                           'Le garçon voit-elle le chien?'-'the pronoun agrees with the subject',
                           'Il voit-il le chien?'-'a pronoun subject has one place',
                           'À que pense le garçon?'-'after a preposition what is quoi',
                           'Quoi voit le garçon?'-'what that opens the question is que' ]),
           ( ( typology_read(french, T, _) -> X = read ; X = refused ),
             atomic_list_concat(['French: not read: ', T, ' (', Why, ')'], Label),
             check(Label, X, refused) )),
    forall(member(IR-Want, [ question(clause(see, present, pos, pron(3, sg, m), D))-'Est-ce qu\'il voit le chien?',
                             question(clause(think, present, pos, B, wh(what)))-'À quoi pense le garçon?',
                             question(clause(see, present, pos, pron(3, sg, f), wh(what)))-'Que voit-elle?' ]),
           ( typology_write(french, IR, T),
             atomic_list_concat(['French: write ', Want], Label),
             check(Label, T, Want) )),
    typology_translate(english, french, 'What does the boy think about?', F1),
    check('English into French: quoi after the preposition', F1, 'À quoi pense le garçon?'),
    typology_translate(french, english, 'Le garçon voit-il le chien?', E2),
    check('French into English: the inversion is a yes or no question', E2, 'Does the boy see the dog?'),
    findall(M, ( typology_check(french, Ms), member(M, Ms) ), M3),
    check('typology_check/2: the French template lacks nothing', M3, []),
    assertz(ty_question(tiny, yes_no, clause, invert(pronoun))),
    findall(M, ( typology_check(tiny, Ms4), member(M, Ms4), M == inversion ), M4),
    retractall(ty_question(tiny, _, _, _)),
    check('typology_check/2: invert(pronoun) wants ty_inversion/3', M4, [inversion]).

%% ---- the future and the perfect -------------------------------------------------

%% 1.40.0: the tenses future and perfect: rows, ty_tense_form/5 patterns of
%% words and another form, the participle (ty_participle/3), its agreement
%% with an object clitic (Italian, French) and, in the patterns of a class
%% of verbs (essere, être), with the subject; the French verb split at its
%% auxiliary; and the import's participles and futures.
tenses :-
    section('the future and the perfect'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    Bs = np(boy, pl, def, []), Gs = np(girl, pl, def, []),
    Rows = [ english-clause(see, future, pos, B, D)-'The boy will see the dog.',
             english-clause(see, future, neg, B, D)-'The boy will not see the dog.',
             english-clause(see, perfect, pos, B, D)-'The boy has seen the dog.',
             english-clause(see, perfect, neg, Bs, D)-'The boys have not seen the dog.',
             english-clause(see, perfect, pos, pron(1, sg, _), D)-'I have seen the dog.',
             english-clause(walk, perfect, pos, B, none)-'The boy has walked.',
             english-clause(speak, perfect, pos, G, none)-'The girl has spoken.',
             english-question(clause(see, future, pos, B, D))-'Will the boy see the dog?',
             english-question(clause(see, perfect, neg, B, D))-'Has the boy not seen the dog?',
             spanish-clause(see, future, pos, B, D)-'El niño verá al perro.',
             spanish-clause(see, perfect, neg, Bs, D)-'Los niños no han visto al perro.',
             spanish-clause(see, perfect, pos, B, pron(3, sg, f))-'El niño la ha visto.',
             italian-clause(see, future, pos, B, D)-'Il ragazzo vedrà il cane.',
             italian-clause(see, perfect, pos, B, pron(3, sg, f))-'Il ragazzo l\'ha vista.',
             italian-clause(see, perfect, neg, B, pron(3, pl, m))-'Il ragazzo non li ha visti.',
             italian-clause(go, perfect, pos, Gs, none)-'Le ragazze sono andate.',
             italian-clause(go, perfect, pos, pron(1, sg, f), none)-'Sono andata.',
             french-clause(see, future, neg, B, D)-'Le garçon ne verra pas le chien.',
             french-clause(see, perfect, neg, B, D)-'Le garçon n\'a pas vu le chien.',
             french-clause(see, perfect, neg, B, pron(3, sg, f))-'Le garçon ne l\'a pas vue.',
             french-clause(go, perfect, pos, G, none)-'La fille est allée.',
             french-clause(go, perfect, neg, B, none)-'Le garçon n\'est pas allé.',
             french-question(clause(see, perfect, pos, pron(3, sg, m), wh(what)))-'Qu\'a-t-il vu?',
             persian-clause(see, future, pos, B, D)-'پسر سگ را خواهد دید.',
             persian-clause(see, perfect, neg, Bs, D)-'پسرها سگ را ندیده\x200C\اند.',
             persian-clause(think, future, pos, B, G)-'پسر به دختر فکر خواهد کرد.' ],
    forall(member(L-IR-Want, Rows),
           ( typology_write(L, IR, T),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), I1 =@= IR -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    forall(member(L-T-Why, [ english-'The boy has saw the dog.'-'the participle, not the past',
                             english-'The boy will sees the dog.'-'will before the base',
                             spanish-'El niño ha vio al perro.'-'haber before the participle',
                             italian-'Il ragazzo l\'ha visti.'-'the participle agrees with the clitic',
                             italian-'La ragazza ha andata.'-'andare takes essere',
                             french-'Le garçon n\'a vu pas le chien.'-'pas after the auxiliary',
                             french-'La fille est allé.'-'the participle agrees with the subject',
                             french-'Le garçon a allé.'-'aller takes être' ]),
           ( ( typology_read(L, T, _) -> X = read ; X = refused ),
             atomic_list_concat([L, ': not read: ', T, ' (', Why, ')'], Label),
             check(Label, X, refused) )),
    forall(member(L-T-Want, [ french-'N\'a-t-il pas vu le chien?'-question(clause(see, perfect, neg, pron(3, sg, m), D)),
                              french-'Le garçon a-t-il vu le chien?'-question(clause(see, perfect, pos, B, D)),
                              english-'Has he seen the dog?'-question(clause(see, perfect, pos, pron(3, sg, m), D)) ]),
           ( findall(I, typology_read(L, T, I), Is),
             ( member(I1, Is), I1 =@= Want -> X = read ; X = Is ),
             atomic_list_concat([L, ': read ', T], Label),
             check(Label, X, read) )),
    typology_answer(english, question(clause(see, future, pos, B, D)), pos, echo, A1),
    check('English: the echo of a future', A1, 'Yes, he will.'),
    typology_answer(english, question(clause(see, perfect, pos, B, D)), neg, echo, A2),
    check('English: the echo of a perfect', A2, 'No, he has not.'),
    forall(member(F-To-S-Want, [ spanish-english-'La niña ha hablado.'-'The girl has spoken.',
                                 english-italian-'The girls have gone.'-'Le ragazze sono andate.',
                                 english-spanish-'The boy will speak.'-'El niño hablará.',
                                 italian-english-'Il ragazzo parlerà.'-'The boy will speak.',
                                 french-italian-'Le garçon l\'a vue.'-'Il ragazzo l\'ha vista.' ]),
           ( typology_translate(F, To, S, Out),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, Out, Want) )),
    ( ty_participle(spanish, err, equivocado) -> P1 = yes ; P1 = no ),
    check('the import: a participle the vocabulary states', P1, yes),
    ( ty_verb(spanish, have, future, sg(1), pos, ['tendré']) -> P2 = yes ; P2 = no ),
    check('the import: a future on the stem of the infinitive (tener)', P2, yes),
    ( ty_verb(spanish, make, future, sg, pos, ['hará']), ty_verb(spanish, make, future, sg(1), pos, ['haré']) -> P3 = yes ; P3 = no ),
    check('the import: a future the vocabulary states, and its stem', P3, yes),
    assertz(ty_verb_class(tiny, see, odd)),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms), M = verb_class(_, _) ), M4),
    retractall(ty_verb_class(tiny, _, _)),
    check('typology_check/2: a verb class with no pattern', M4, [verb_class(see, odd)]).

%% ---- the polite you -------------------------------------------------------------

%% 1.41.0: the polite `you', pron(polite, Number, Kind): its own agreement
%% key, polite(Number), which ty_polite/3 maps to the form it takes (Spanish
%% and Italian one person the third person's, French and Persian the
%% second plural's), its own pronouns, never a dropped subject.
polite :-
    section('the polite you'),
    D = np(dog, sg, def, []),
    IR1 = clause(see, present, pos, pron(polite, sg, _), D),
    findall(L-T, ( member(L, [english, spanish, italian, persian, french]), typology_write(L, IR1, T) ), Ts1),
    check('the polite you sees the dog, five times', Ts1,
          [english-'You see the dog.', spanish-'Usted ve al perro.', italian-'Lei vede il cane.',
           persian-'شما سگ را می\x200C\بینید.', french-'Vous voyez le chien.']),
    Rows = [ spanish-clause(see, present, pos, pron(polite, pl, _), D)-'Ustedes ven al perro.',
             spanish-copula(present, pos, pron(polite, sg, m), adj([small]))-'Usted es pequeño.',
             spanish-clause(see, present, pos, pron(1, sg, _), pron(polite, sg, f))-'La veo.',
             spanish-clause(sleep, present, pos, of(pron(polite, sg, _), D), none)-'Su perro duerme.',
             italian-clause(see, present, pos, pron(polite, pl, _), D)-'Voi vedete il cane.',
             italian-clause(see, present, pos, pron(1, sg, _), pron(polite, sg, _))-'La vedo.',
             french-copula(present, pos, pron(polite, sg, m), adj([small]))-'Vous êtes petit.',
             french-clause(sleep, present, pos, of(pron(polite, sg, _), D), none)-'Votre chien dort.',
             french-question(clause(see, present, pos, pron(polite, sg, _), D))-'Est-ce que vous voyez le chien?',
             persian-clause(sleep, present, pos, of(pron(polite, sg, _), D), none)-'سگتان می\x200C\خوابد.' ],
    forall(member(L-IR-Want, Rows),
           ( typology_write(L, IR, T),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    forall(member(L-T-IR, [ spanish-'Duerme.'-clause(sleep, present, pos, pron(polite, _, _), none),
                            persian-'کوچک نیستید.'-copula(present, neg, pron(polite, _, _), adj([small])) ]),
           ( ( typology_read(L, T, IR) -> X = read ; X = refused ),
             atomic_list_concat([L, ': ', T, ' has no polite subject: it is never dropped'], Label),
             check(Label, X, refused) )),
    forall(member(F-To-S-Want, [ spanish-english-'Usted ve al perro.'-'You see the dog.',
                                 spanish-french-'Usted ve al perro.'-'Vous voyez le chien.',
                                 spanish-italian-'Ustedes ven al perro.'-'Voi vedete il cane.',
                                 english-spanish-'You see the dog.'-'Ves al perro.' ]),
           ( typology_translate(F, To, S, Out),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, Out, Want) )),
    typology_answer(english, question(IR1), pos, echo, A1),
    check('English: the polite you answers I', A1, 'Yes, I do.'),
    assertz(ty_pronoun(tiny, s, [thou], [[polite, sg]])),
    findall(M, ( typology_check(tiny, Ms), member(M, Ms), M = polite(_) ), M2),
    retractall(ty_pronoun(tiny, _, _, _)),
    check('typology_check/2: a polite pronoun wants ty_polite/3', M2, [polite(pl), polite(sg)]).

%% A reading of a verb's other sense (`view' for `see', `little' for
%% `small'): the checks above want the first sense's.
ty_meanings_other(IR) :-
    ( IR = question(C) -> true ; C = IR ),
    ( C = clause(V, _, _, _, _) ; C = clause(V, _, _, _, _, _) ; C = copula(_, _, _, adj([V])) ),
    memberchk(V, [view, little]), !.

%% The English rows a test language is made of, under another name.
english_rows_as(L) :-
    forall(( member(F, [ty_order(english, clause, _), ty_order(english, np, _), ty_order(english, pp, _),
                        ty_noun(english, _, _, _, _, _), ty_adjective(english, _, _, _, _),
                        ty_verb(english, _, _, _, _, _), ty_article(english, _, _, _, _),
                        ty_negation(english, _, _, _, _), ty_adposition(english, _, _),
                        ty_adjunct(english, _), ty_question(english, _, _, _), ty_wh(english, _),
                        ty_wh_word(english, _, _)]),
             call(F) ),
           ( F =.. [P, english|Args], G =.. [P, L|Args], assertz(G) )).

%% The object and the adjuncts of every reading of a Spanish sentence.
object_parts(T, Ps) :-
    findall(O-Js, ( typology_read(spanish, T, IR0),
                    ( IR0 = question(IR) -> true ; IR = IR0 ),
                    ( IR = clause(_, _, _, _, O), Js = []
                    ; IR = clause(_, _, _, _, O, Js) ) ), Ps0),
    sort(Ps0, Ps).

%% The meanings of hoja, the object, in every reading of a sentence.
hoja_meanings(T, Ms) :-
    findall(M, ( typology_read(spanish, T, IR), ir_object_noun(IR, M) ), Ms0),
    sort(Ms0, Ms).

ir_object_noun(clause(_, _, _, _, np(M, _, _, _)), M).
ir_object_noun(clause(_, _, _, _, np(M, _, _, _), _), M).

%% ---- the copula's future and perfect ------------------------------------------------

%% 1.44.0: ty_copula/6 rows of the future and the perfect in the six
%% templates; Italian `agree(stato)'; the German copula of two words split
%% as a verb is.
copula_tenses :-
    section('the copula\'s future and perfect'),
    D = np(dog, sg, def, []), H = np(house, sg, def, []),
    Rows = [ english-copula(future, pos, D, adj([small]))-'The dog will be small.',
             spanish-copula(future, pos, D, adj([small]))-'El perro será pequeño.',
             italian-copula(future, pos, D, adj([small]))-'Il cane sarà piccolo.',
             persian-copula(future, pos, D, adj([small]))-'سگ کوچک خواهد بود.',
             french-copula(future, pos, D, adj([small]))-'Le chien sera petit.',
             german-copula(future, pos, D, adj([small]))-'Der Hund wird klein sein.',
             english-copula(perfect, neg, D, adj([small]))-'The dog has not been small.',
             spanish-copula(perfect, neg, D, adj([small]))-'El perro no ha sido pequeño.',
             italian-copula(perfect, neg, D, adj([small]))-'Il cane non è stato piccolo.',
             persian-copula(perfect, neg, D, adj([small]))-'سگ کوچک نبوده است.',
             french-copula(perfect, neg, D, adj([small]))-'Le chien n\'a pas été petit.',
             german-copula(perfect, neg, D, adj([small]))-'Der Hund ist nicht klein gewesen.',
             italian-copula(perfect, pos, H, adj([big]))-'La casa è stata grande.',
             italian-copula(perfect, pos, np(house, pl, def, []), adj([big]))-'Le case sono state grandi.',
             persian-copula(perfect, pos, np(house, pl, def, []), adj([big]))-'خانه\x200C\ها بزرگ بوده\x200C\اند.',
             spanish-copula(future, neg, D, pp(in, H))-'El perro no estará en la casa.',
             german-copula(future, neg, D, pp(in, H))-'Der Hund wird nicht im Haus sein.',
             italian-copula(perfect, pos, pron(1, sg, f), adj([small]))-'Sono stata piccola.',
             french-copula(future, neg, pron(1, pl, m), adj([small]))-'Nous ne serons pas petits.',
             english-question(copula(future, pos, D, adj([small])))-'Will the dog be small?',
             german-question(copula(future, pos, D, adj([small])))-'Wird der Hund klein sein?',
             german-question(copula(perfect, pos, D, adj([small])))-'Ist der Hund klein gewesen?',
             german-question(copula(future, pos, D, wh(where)))-'Wo wird der Hund sein?',
             german-question(copula(present, pos, D, wh(where)))-'Wo ist der Hund?',
             italian-question(copula(perfect, neg, pron(2, sg, m), adj([small])))-'Non sei stato piccolo?',
             german-clause(sleep, present, pos, rel(D, copula(future, pos, gap, adj([small]))), none)-'Der Hund, der klein sein wird, schläft.',
             german-clause(sleep, present, pos, rel(D, copula(perfect, neg, gap, adj([small]))), none)-'Der Hund, der nicht klein gewesen ist, schläft.' ],
    forall(member(L-IR-Want, Rows),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    forall(member(T-P-Want, [future-pos-'Yes, it will.', perfect-neg-'No, it has not.',
                             present-pos-'Yes, it is.', present-neg-'No, it is not.']),
           ( typology_answer(english, question(copula(T, pos, D, adj([small]))), P, echo, A),
             atomic_list_concat(['English echo: ', Want], Label),
             check(Label, A, Want) )).

%% ---- the imperfect, the conditional and the pluperfect -------------------------------

%% 1.45.0: hand rows and the import's rows of the imperfect and the
%% conditional, patterns of the pluperfect, and a tense written as another
%% (ty_tense_like/4: English and German imperfect the past, the copula's
%% imperfect its past, Persian conditional the imperfect).
other_tenses :-
    section('the imperfect, the conditional and the pluperfect'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []), G = np(girl, sg, def, []),
    H = np(house, sg, def, []),
    Rows = [ spanish-clause(see, imperfect, pos, B, D)-'El niño veía al perro.',
             italian-clause(see, imperfect, neg, B, D)-'Il ragazzo non vedeva il cane.',
             french-clause(see, imperfect, neg, B, D)-'Le garçon ne voyait pas le chien.',
             persian-clause(see, imperfect, pos, B, D)-'پسر سگ را می‌دید.',
             english-clause(see, conditional, pos, B, D)-'The boy would see the dog.',
             spanish-clause(see, conditional, neg, B, D)-'El niño no vería al perro.',
             italian-clause(see, conditional, pos, B, D)-'Il ragazzo vedrebbe il cane.',
             french-clause(see, conditional, pos, B, D)-'Le garçon verrait le chien.',
             german-clause(see, conditional, neg, B, D)-'Der Junge würde den Hund nicht sehen.',
             english-clause(see, pluperfect, neg, B, D)-'The boy had not seen the dog.',
             spanish-clause(see, pluperfect, pos, B, D)-'El niño había visto al perro.',
             italian-clause(see, pluperfect, pos, B, D)-'Il ragazzo aveva visto il cane.',
             french-clause(see, pluperfect, neg, B, D)-'Le garçon n\'avait pas vu le chien.',
             german-clause(see, pluperfect, pos, B, D)-'Der Junge hatte den Hund gesehen.',
             persian-clause(see, pluperfect, neg, B, D)-'پسر سگ را ندیده بود.',
             italian-clause(go, pluperfect, pos, G, none)-'La ragazza era andata.',
             french-clause(go, pluperfect, pos, G, none)-'La fille était allée.',
             german-clause(go, pluperfect, pos, G, none)-'Das Mädchen war gegangen.',
             spanish-clause(see, imperfect, pos, pron(1, pl, m), D)-'Veíamos al perro.',
             french-clause(see, pluperfect, pos, pron(1, sg, m), D)-'J\'avais vu le chien.',
             persian-clause(see, pluperfect, pos, pron(1, sg, m), D)-'سگ را دیده بودم.',
             english-question(clause(see, pluperfect, neg, B, D))-'Had the boy not seen the dog?',
             german-question(clause(see, conditional, pos, B, D))-'Würde der Junge den Hund sehen?',
             english-copula(conditional, neg, D, adj([small]))-'The dog would not be small.',
             spanish-copula(conditional, pos, D, pp(in, H))-'El perro estaría en la casa.',
             italian-copula(pluperfect, neg, H, adj([big]))-'La casa non era stata grande.',
             french-copula(pluperfect, pos, D, adj([small]))-'Le chien avait été petit.',
             german-copula(pluperfect, neg, H, adj([big]))-'Das Haus war nicht groß gewesen.',
             persian-copula(pluperfect, pos, D, adj([small]))-'سگ کوچک بوده بود.',
             german-clause(sleep, present, pos, rel(D, copula(conditional, pos, gap, adj([small]))), none)-'Der Hund, der klein sein würde, schläft.',
             german-clause(sleep, present, pos, rel(D, clause(see, pluperfect, pos, B, gap)), none)-'Der Hund, den der Junge gesehen hatte, schläft.' ],
    forall(member(L-IR-Want, Rows),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    %% A tense written as another, read back as that tense.
    Likes = [ english-clause(see, imperfect, pos, B, D)-'The boy saw the dog.'-past,
              german-clause(see, imperfect, neg, B, D)-'Der Junge sah den Hund nicht.'-past,
              spanish-copula(imperfect, pos, D, adj([small]))-'El perro era pequeño.'-past,
              persian-clause(see, conditional, pos, B, D)-'پسر سگ را می‌دید.'-imperfect,
              persian-copula(conditional, pos, D, adj([small]))-'سگ کوچک بود.'-past ],
    forall(member(L-IR-Want-As, Likes),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': written as another tense: ', Want], Label),
             check(Label, T, Want),
             ( once(typology_read(L, T, I)), ( I = clause(_, TR, _, _, _) ; I = clause(_, TR, _, _, _, _) ; I = copula(TR, _, _, _) ) -> true ; TR = none ),
             atomic_list_concat([L, ': read back in the tense it is written as: ', Want], Label2),
             check(Label2, TR, As) )),
    forall(member(F-To-S-Want, [ spanish-english-'El niño veía al perro.'-'The boy saw the dog.',
                                 spanish-german-'El niño había visto al perro.'-'Der Junge hatte den Hund gesehen.',
                                 italian-french-'La ragazza era andata.'-'La fille était allée.',
                                 english-spanish-'The boy would see the dog.'-'El niño vería al perro.',
                                 italian-spanish-'I medici mangerebbero le mele.'-'Los médicos comerían las manzanas.',
                                 english-italian-'The house had been big.'-'La casa era stata grande.',
                                 french-german-'Les filles étaient allées.'-'Die Mädchen waren gegangen.' ]),
           ( ( typology_translate(F, To, S, X) -> true ; X = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, X, Want) )),
    forall(member(Q-P-Want, [ clause(see, conditional, pos, B, D)-pos-'Yes, he would.',
                              clause(see, pluperfect, pos, B, D)-neg-'No, he had not.',
                              copula(conditional, pos, D, adj([small]))-pos-'Yes, it would.' ]),
           ( typology_answer(english, question(Q), P, echo, A),
             atomic_list_concat(['English echo: ', Want], Label),
             check(Label, A, Want) )),
    findall(V-W, ( member(V, [eat, make, say]), once(ty_verb(spanish, V, conditional, sg, pos, [W])) ), Cs),
    check('the import\'s Spanish conditional on the future\'s stem', Cs, [eat-'comería', make-'haría', say-'diría']),
    findall(V-W, ( member(V, [eat, make, drink]), once(ty_verb(italian, V, imperfect, sg(1), pos, [W])) ), Is2),
    check('the import\'s Italian imperfect of the infinitive and its person', Is2, [eat-mangiavo, make-facevo, drink-bevevo]).

%% ---- the negative article: a subject's, and French pas de ----------------------------

%% 1.46.0: ty_negative_article_roles/2 (German [s, o, p]: `Kein Hund
%% schläft.') and ty_negative_article_keeps/1 (French: the negation stays
%% beside `de', `ne ... pas de').
negative_article :-
    section('the negative article: a subject\'s, and French pas de'),
    Di = np(dog, sg, indef, []), Dp = np(dog, pl, indef, []), D = np(dog, sg, def, []),
    B = np(boy, sg, def, []), Bi = np(boy, sg, indef, []),
    Rows = [ german-clause(sleep, present, neg, Di, none)-'Kein Hund schläft.',
             german-clause(sleep, present, neg, Dp, none)-'Keine Hunde schlafen.',
             german-clause(see, present, neg, Bi, Di)-'Kein Junge sieht einen Hund.',
             german-clause(see, present, neg, B, Di)-'Der Junge sieht keinen Hund.',
             german-copula(present, neg, Di, adj([small]))-'Kein Hund ist klein.',
             german-question(clause(sleep, present, neg, Di, none))-'Schläft kein Hund?',
             german-clause(sleep, present, pos, rel(D, clause(see, present, neg, gap, Di)), none)-'Der Hund, der keinen Hund sieht, schläft.',
             french-clause(see, present, neg, B, Di)-'Le garçon ne voit pas de chien.',
             french-clause(see, present, neg, B, Dp)-'Le garçon ne voit pas de chiens.',
             french-clause(see, present, neg, B, np(animal, pl, indef, []))-'Le garçon ne voit pas d\'animaux.',
             french-clause(see, perfect, neg, B, Di)-'Le garçon n\'a pas vu de chien.',
             french-clause(see, present, neg, pron(1, sg, m), Di)-'Je ne vois pas de chien.',
             french-clause(sleep, present, neg, Di, none)-'Un chien ne dort pas.',
             french-copula(present, neg, D, np(animal, sg, indef, []))-'Le chien n\'est pas un animal.',
             french-clause(see, present, neg, B, D)-'Le garçon ne voit pas le chien.',
             french-clause(see, present, pos, B, Di)-'Le garçon voit un chien.' ],
    forall(member(L-IR-Want, Rows),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    ( typology_read(french, 'Le garçon ne voit pas un chien.', _) -> R1 = read ; R1 = refused ),
    check('French: after a negation an indefinite object takes de, not un', R1, refused),
    forall(member(F-To-S-Want, [ german-english-'Kein Hund schläft.'-'A dog does not sleep.',
                                 english-french-'The boy does not see a dog.'-'Le garçon ne voit pas de chien.',
                                 french-german-'Je ne vois pas d\'animaux.'-'Ich sehe keine Tiere.',
                                 german-french-'Der Junge sieht keinen Hund.'-'Le garçon ne voit pas de chien.' ]),
           ( ( typology_translate(F, To, S, X) -> true ; X = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, X, Want) )).

%% ---- the predicate's adjectives joined by `and' --------------------------------------

%% 1.47.0: ty_and/2.
predicate_and :-
    section('the predicate\'s adjectives joined by and'),
    D = np(dog, sg, def, []), H = np(house, pl, def, []),
    Rows = [ english-copula(present, pos, D, adj([small, black]))-'The dog is small and black.',
             spanish-copula(present, pos, D, adj([small, black, big]))-'El perro es pequeño, negro y grande.',
             spanish-copula(present, pos, D, adj([small, important]))-'El perro es pequeño e importante.',
             italian-copula(past, neg, H, adj([big, red]))-'Le case non erano grandi e rosse.',
             french-copula(present, pos, D, adj([small, black]))-'Le chien est petit et noir.',
             german-copula(present, pos, D, adj([small, black]))-'Der Hund ist klein und schwarz.',
             german-clause(sleep, present, pos, rel(D, copula(present, pos, gap, adj([small, black]))), none)-'Der Hund, der klein und schwarz ist, schläft.',
             persian-copula(present, pos, D, adj([small, black]))-'سگ کوچک و سیاه است.',
             persian-copula(present, pos, D, adj([small, black, big]))-'سگ کوچک، سیاه و بزرگ است.',
             english-question(copula(present, pos, D, adj([small, black])))-'Is the dog small and black?',
             english-clause(sleep, present, pos, np(dog, sg, def, [small, black]), none)-'The small black dog sleeps.' ],
    forall(member(L-IR-Want, Rows),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    ( typology_read(english, 'The dog is small black.', _) -> R1 = read ; R1 = refused ),
    check('a predicate\'s two adjectives take and', R1, refused),
    typology_answer(english, question(copula(present, pos, D, adj([small, black]))), pos, echo, A),
    check('an answer keeps its comma', A, 'Yes, it is.'),
    typology_translate(spanish, german, 'El perro es pequeño, negro y grande.', G),
    check('Spanish into German, three adjectives', G, 'Der Hund ist klein, schwarz und groß.').

%% ---- the months: no article, and French en ----------------------------------------

%% 1.48.0: ty_bare_topic/2 and ty_adposition_topic/4.
months :-
    section('the months: no article, and French en'),
    B = np(boy, sg, def, []), M = np(march_month, sg, def, []),
    Rows = [ english-clause(sleep, present, pos, B, none, [pp(in, M)])-'The boy sleeps in March.',
             english-clause(sleep, present, pos, B, none, [pp(in, np(january, sg, def, []))])-'The boy sleeps in January.',
             spanish-clause(sleep, present, pos, B, none, [pp(in, M)])-'El niño duerme en marzo.',
             spanish-clause(sleep, present, pos, B, none, [pp(in, np(house, sg, def, []))])-'El niño duerme en la casa.',
             italian-clause(sleep, present, pos, B, none, [pp(in, np(january, sg, def, []))])-'Il ragazzo dorme in gennaio.',
             french-clause(sleep, present, pos, B, none, [pp(in, M)])-'Le garçon dort en mars.',
             french-clause(sleep, present, pos, B, none, [pp(in, np(house, sg, def, []))])-'Le garçon dort dans la maison.',
             german-clause(sleep, present, pos, B, none, [pp(in, M)])-'Der Junge schläft im März.',
             persian-clause(sleep, present, pos, B, none, [pp(in, M)])-'پسر در مارس می‌خوابد.',
             spanish-clause(see, present, pos, B, M)-'El niño ve marzo.' ],
    forall(member(L-IR-Want, Rows),
           ( ( typology_write(L, IR, T) -> true ; T = none ),
             atomic_list_concat([L, ': ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(L, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat([L, ': read back: ', Want], Label2),
             check(Label2, R, read) )),
    ( typology_read(french, 'Le garçon dort dans mars.', _) -> R1 = read ; R1 = refused ),
    check('French: a month takes en, not dans', R1, refused),
    ( typology_read(spanish, 'El niño duerme en el marzo.', _) -> R2 = read ; R2 = refused ),
    check('Spanish: a month is still read with its article', R2, read),
    forall(member(F-To-S-Want, [ spanish-french-'El niño duerme en marzo.'-'Le garçon dort en mars.',
                                 german-english-'Der Junge schläft im März.'-'The boy sleeps in March.' ]),
           ( ( typology_translate(F, To, S, X) -> true ; X = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, X, Want) )).

%% ---- German: the possessive pronouns, and ans ----------------------------------

%% 1.49.0: the German possessive pronouns, their endings by the possessed's
%% case, the mixed declension after them, and `ans'.
german_possessives :-
    section('German: the possessive pronouns, and ans'),
    B = np(boy, sg, def, []), D = np(dog, sg, def, []),
    Rows = [ clause(sleep, present, pos, of(pron(1, sg, _), D), none)-'Mein Hund schläft.',
             clause(see, present, pos, B, of(pron(1, sg, _), np(dog, sg, def, [small])))-'Der Junge sieht meinen kleinen Hund.',
             clause(sleep, present, pos, of(pron(1, sg, _), np(dog, sg, def, [small])), none)-'Mein kleiner Hund schläft.',
             clause(sleep, present, pos, B, none, [pp(with, of(pron(1, sg, _), np(dog, sg, def, [small])))])-'Der Junge schläft mit meinem kleinen Hund.',
             clause(sleep, present, pos, of(pron(3, sg, m), np(cat, sg, def, [])), none)-'Seine Katze schläft.',
             clause(see, present, pos, B, of(pron(1, pl, _), np(house, sg, def, [])))-'Der Junge sieht unser Haus.',
             clause(see, present, pos, B, of(pron(2, pl, _), np(dog, sg, def, [])))-'Der Junge sieht euren Hund.',
             clause(see, present, pos, of(pron(2, sg, _), np(girl, pl, def, [small])), B)-'Deine kleinen Mädchen sehen den Jungen.',
             copula(present, pos, D, of(pron(1, sg, _), np(animal, sg, def, [])))-'Der Hund ist mein Tier.',
             clause(think, present, pos, B, np(girl, sg, def, []))-'Der Junge denkt ans Mädchen.' ],
    forall(member(IR-Want, Rows),
           ( ( typology_write(german, IR, T) -> true ; T = none ),
             atomic_list_concat(['German: ', Want], Label),
             check(Label, T, Want),
             ( findall(I, typology_read(german, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat(['German: read back: ', Want], Label2),
             check(Label2, R, read) )),
    ( typology_read(german, 'Der Junge sieht mein Hund.', _) -> R1 = read ; R1 = refused ),
    check('German: an accusative masculine takes meinen', R1, refused),
    forall(member(F-To-S-Want, [ spanish-german-'Mi perro duerme.'-'Mein Hund schläft.',
                                 english-german-'The boy sleeps with my small dog.'-'Der Junge schläft mit meinem kleinen Hund.',
                                 german-spanish-'Unser Haus ist groß.'-'Nuestra casa es grande.' ]),
           ( ( typology_translate(F, To, S, X) -> true ; X = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, X, Want) )).

%% ---- German: an adjunct first, the verb second ---------------------------------

%% 1.50.0: ty_adjunct_front(german, v2).
german_v2 :-
    section('German: an adjunct first, the verb second'),
    Rows = [ 'Heute schläft der Hund.'-clause(sleep, present, pos, np(dog, sg, def, []), none, [adv(today)])-'Der Hund schläft heute.',
             'Im Haus schläft der Hund.'-clause(sleep, present, pos, np(dog, sg, def, []), none, [pp(in, np(house, sg, def, []))])-'Der Hund schläft im Haus.',
             'Heute hat der Junge den Hund gesehen.'-clause(see, perfect, pos, np(boy, sg, def, []), np(dog, sg, def, []), [adv(today)])-'Der Junge hat den Hund heute gesehen.',
             'Heute sieht der Junge den Hund nicht.'-clause(see, present, neg, np(boy, sg, def, []), np(dog, sg, def, []), [adv(today)])-'Der Junge sieht den Hund heute nicht.',
             'Heute schläft kein Hund.'-clause(sleep, present, neg, np(dog, sg, indef, []), none, [adv(today)])-'Kein Hund schläft heute.' ],
    forall(member(S-IR-Want, Rows),
           ( findall(I, typology_read(german, S, I), Is),
             atomic_list_concat(['German: read: ', S], Label),
             check(Label, Is, [IR]),
             ( typology_write(german, IR, T) -> true ; T = none ),
             atomic_list_concat(['German: written at the end: ', Want], Label2),
             check(Label2, T, Want) )),
    ( typology_read(german, 'Heute der Hund schläft.', _) -> R1 = read ; R1 = refused ),
    check('German: an adjunct first takes the verb second', R1, refused),
    ( typology_read(german, 'Der Hund, der heute schläft, ist klein.', R2) -> true ; R2 = none ),
    check('German: a relative clause keeps its verb last', R2,
          copula(present, pos, rel(np(dog, sg, def, []), clause(sleep, present, pos, gap, none, [adv(today)])), adj([small]))),
    typology_translate(german, english, 'Heute schläft der Hund.', E),
    check('German into English', E, 'The dog sleeps today.').

%% ---- the reference sentences and the senses -------------------------------------------

%% 1.43.0: templates/references.pl's sentences hold a model's topics, and a
%% hand row gives one sense of an English word a meaning of its own
%% (march_month, ty_meaning_sense/2).
reference_sentences :-
    section('the reference sentences hold the topics a model gives, and a sense of its own'),
    forall(member(L, [spanish, italian]),
           ( typology_references(L, F),
             atomic_list_concat([L, ': every reference sentence holds'], Label),
             check(Label, F, []) )),
    setup_call_cleanup(true, reference_checks,
                       ( reason_set_mode(static), retractall(reason_live_stub(_, _, _)),
                         retractall(reason_live_topics(_, _)) )),
    forall(member(F-To-S-Want, [ spanish-italian-'El niño duerme en marzo.'-'Il ragazzo dorme in marzo.',
                                 spanish-italian-'El niño ve la marcha.'-'Il ragazzo vede la marcia.',
                                 spanish-english-'El niño duerme en marzo.'-'The boy sleeps in March.',
                                 english-spanish-'The boy sees the march.'-'El niño ve la marcha.',
                                 italian-spanish-'Il ragazzo dorme in marzo.'-'El niño duerme en marzo.' ]),
           ( ( typology_translate(F, To, S, Out) -> true ; Out = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, Out, Want) )),
    findall(M-Ts, ( member(M, [march, march_month]), findall(T, ty_topic(M, T), Ts) ), Topics),
    check('marzo\'s class line gives its topics to march_month, not to march', Topics,
          [march-[], march_month-[month, time]]),
    assertz(ty_meaning_sense(nail_finger, nail)),
    findall(X, ( typology_check(english, Ms), member(X, Ms), X = sense_word(_) ), Ws),
    retractall(ty_meaning_sense(nail_finger, nail)),
    check('a sense of its own with no English row is missing', Ws, [sense_word(nail_finger)]).

reference_checks :-
    use_module(library(reasoning/live)),
    reason_live_forget,
    reason_set_mode(live),
    assertz(reason_live_stub('la lima', topics,
        '{"topics": [{"meaning": "lime", "topics": ["tool"]}, {"meaning": "file", "topics": ["food"]}]}')),
    reason_live_stats_reset,
    lima_objects('El niño ve la lima.', O1),
    check('topics the wrong way round take nothing away', O1, [file, lime]),
    findall(M-Ts, ( member(M, [lime, file]), reason_live_topics(M, Ts) ), Saved),
    check('each is refused: a reference sentence would lose its reading', Saved, [lime-[], file-[]]),
    reason_live_stats(St), memberchk(topics-N1, St), memberchk(topics_refused-N2, St),
    check('none kept, two refused', N1-N2, 0-2),
    reason_live_forget,
    retractall(reason_live_stub(_, _, _)),
    assertz(reason_live_stub('la lima', topics,
        '{"topics": [{"meaning": "lime", "topics": ["food"]}, {"meaning": "file", "topics": ["tool"]}]}')),
    reason_live_stats_reset,
    lima_objects('El niño ve la lima.', O2),
    check('the right topics are kept, and food makes it the lime', O2, [lime]),
    reason_live_stats(St2), memberchk(topics-N3, St2), memberchk(topics_refused-N4, St2),
    check('two kept, none refused', N3-N4, 2-0).

%% ---- German -------------------------------------------------------------------------

german :-
    section('German: the cases, the verb second, nicht and kein'),
    B = np(boy, sg, def, []), Dg = np(dog, sg, def, []), G = np(girl, sg, def, []),
    Rows = [ clause(see, present, pos, B, Dg)-'Der Junge sieht den Hund.',
             clause(see, present, neg, B, Dg)-'Der Junge sieht den Hund nicht.',
             clause(see, perfect, pos, B, Dg)-'Der Junge hat den Hund gesehen.',
             clause(see, perfect, neg, B, np(dog, sg, def, [small]))-'Der Junge hat den kleinen Hund nicht gesehen.',
             clause(see, future, pos, G, np(cat, pl, indef, [black]))-'Das Mädchen wird schwarze Katzen sehen.',
             clause(sleep, present, pos, np(dog, sg, indef, [small]), none)-'Ein kleiner Hund schläft.',
             clause(sleep, past, neg, np(dog, pl, def, [big]), none)-'Die großen Hunde schliefen nicht.',
             clause(sleep, present, pos, Dg, none, [pp(in, np(house, sg, def, []))])-'Der Hund schläft im Haus.',
             clause(sleep, present, pos, Dg, none, [pp(with, np(dog, pl, def, []))])-'Der Hund schläft mit den Hunden.',
             clause(sleep, present, pos, np(cat, sg, def, []), none, [pp(with, np(cat, sg, def, [black]))])-'Die Katze schläft mit der schwarzen Katze.',
             clause(think, present, pos, B, G)-'Der Junge denkt ans Mädchen.',
             clause(go, perfect, pos, B, none)-'Der Junge ist gegangen.',
             clause(sleep, perfect, neg, B, none, [pp(in, np(house, sg, def, []))])-'Der Junge hat im Haus nicht geschlafen.',
             clause(sleep, present, neg, B, none, [adv(today)])-'Der Junge schläft heute nicht.',
             clause(sleep, present, pos, np(dog, pl, indef, []), none)-'Hunde schlafen.',
             clause(see, present, pos, of(G, np(cat, sg, def, [])), Dg)-'Die Katze des Mädchens sieht den Hund.',
             clause(sleep, present, pos, of(of(np(man, sg, def, []), B), Dg), none)-'Der Hund des Jungen des Mannes schläft.',
             copula(present, pos, Dg, adj([small]))-'Der Hund ist klein.',
             copula(present, neg, Dg, adj([small]))-'Der Hund ist nicht klein.',
             copula(present, pos, Dg, np(animal, sg, indef, []))-'Der Hund ist ein Tier.',
             copula(present, pos, Dg, pp(in, np(house, sg, def, [])))-'Der Hund ist im Haus.',
             clause(see, present, neg, B, np(dog, sg, indef, []))-'Der Junge sieht keinen Hund.',
             clause(see, present, neg, B, np(dog, pl, indef, [small]))-'Der Junge sieht keine kleinen Hunde.',
             clause(see, perfect, neg, B, np(cat, sg, indef, []))-'Der Junge hat keine Katze gesehen.',
             copula(present, neg, Dg, np(animal, sg, indef, []))-'Der Hund ist kein Tier.',
             clause(see, present, neg, B, pron(3, sg, m))-'Der Junge sieht ihn nicht.',
             question(clause(see, present, pos, B, Dg))-'Sieht der Junge den Hund?',
             question(clause(see, perfect, neg, B, Dg))-'Hat der Junge den Hund nicht gesehen?',
             question(clause(see, present, pos, B, wh(who)))-'Wen sieht der Junge?',
             question(clause(see, present, pos, wh(who), Dg))-'Wer sieht den Hund?',
             question(clause(see, perfect, pos, B, wh(what)))-'Was hat der Junge gesehen?',
             question(clause(sleep, perfect, pos, Dg, none, [wh(where)]))-'Wo hat der Hund geschlafen?',
             question(clause(think, present, pos, B, wh(who)))-'An wen denkt der Junge?',
             question(clause(see, present, pos, B, np(dog, sg, which, [])))-'Welchen Hund sieht der Junge?',
             question(copula(present, neg, Dg, adj([small])))-'Ist der Hund nicht klein?',
             question(clause(see, present, neg, B, np(dog, sg, indef, [])))-'Sieht der Junge keinen Hund?',
             clause(see, present, pos, rel(B, clause(sleep, present, pos, gap, none)), Dg)-'Der Junge, der schläft, sieht den Hund.',
             clause(see, present, pos, B, rel(Dg, clause(see, present, pos, G, gap)))-'Der Junge sieht den Hund, den das Mädchen sieht.',
             clause(see, present, pos, B, rel(Dg, clause(see, perfect, neg, G, gap)))-'Der Junge sieht den Hund, den das Mädchen nicht gesehen hat.',
             clause(see, present, pos, B, rel(Dg, clause(see, future, neg, G, gap)))-'Der Junge sieht den Hund, den das Mädchen nicht sehen wird.',
             clause(sleep, present, pos, rel(Dg, copula(present, neg, gap, adj([small]))), none)-'Der Hund, der nicht klein ist, schläft.',
             clause(sleep, present, pos, rel(Dg, copula(present, neg, gap, np(animal, sg, indef, []))), none)-'Der Hund, der kein Tier ist, schläft.',
             clause(sleep, present, pos, rel(np(dog, pl, def, []), clause(see, present, pos, gap, np(cat, sg, def, []))), none)-'Die Hunde, die die Katze sehen, schlafen.',
             clause(sleep, present, pos, Dg, none, [pp(in, rel(np(house, sg, def, []), clause(sleep, present, pos, B, none, [pp(in, gap)])))])-'Der Hund schläft im Haus, in dem der Junge schläft.',
             clause(see, present, pos, B, rel(G, clause(think, present, pos, np(man, sg, def, []), gap)))-'Der Junge sieht das Mädchen, an das der Mann denkt.',
             question(clause(see, present, pos, pron(2, sg, _), rel(Dg, clause(sleep, present, pos, gap, none))))-'Siehst du den Hund, der schläft?',
             clause(see, present, pos, pron(1, sg, _), pron(3, sg, m))-'Ich sehe ihn.',
             clause(think, present, pos, B, pron(3, sg, m))-'Der Junge denkt an ihn.',
             clause(sleep, present, pos, pron(3, pl, _), none, [pp(with, pron(1, sg, _))])-'Sie schlafen mit mir.',
             clause(see, present, pos, pron(polite, sg, _), Dg)-'Sie sehen den Hund.',
             answer(pos, neg, clause(see, present, pos, B, Dg))-'Doch, der Junge sieht den Hund.' ],
    forall(member(IR-Want, Rows),
           ( ( typology_write(german, IR, T) -> true ; T = none ),
             check(Want, T, Want),
             ( findall(I, typology_read(german, T, I), Is), member(I1, Is), subsumes_term(I1, IR) -> R = read ; R = not_read ),
             atomic_list_concat(['read back: ', Want], Label2),
             check(Label2, R, read) )),
    forall(member(T-Want, [ 'Sie sehen den Hund.'-3,
                            'Der Junge sieht sie.'-2,
                            'Sie schläft.'-1 ]),
           ( findall(I, typology_read(german, T, I), Is), length(Is, N),
             atomic_list_concat([T, ': its readings'], Label),
             check(Label, N, Want) )),
    forall(member(T, [ 'Der Junge sieht keinen Hund nicht.', 'Der Junge sieht kein Hund.',
                       'Der Hund schläft in dem Haus.', 'Der Junge sieht der Hund.',
                       'Der Junge hat gesehen den Hund.', 'Der Hund, den der Junge sieht schläft.' ]),
           ( ( typology_read(german, T, _) -> X = read ; X = refused ),
             atomic_list_concat([T, ' is refused'], Label),
             check(Label, X, refused) )),
    forall(member(F-To-S-Want, [ english-german-'The boy does not see the small dog.'-'Der Junge sieht den kleinen Hund nicht.',
                                 english-german-'The dog that the girl saw sleeps.'-'Der Hund, den das Mädchen sah, schläft.',
                                 english-german-'The girl\'s cat sleeps in the house.'-'Die Katze des Mädchens schläft im Haus.',
                                 german-spanish-'Wen hat das Mädchen gesehen?'-'¿A quién ha visto la niña?',
                                 german-french-'Der Junge sieht den Hund nicht.'-'Le garçon ne voit pas le chien.',
                                 german-italian-'Der Hund, den der Junge sieht, schläft.'-'Il cane che il ragazzo vede dorme.' ]),
           ( ( typology_translate(F, To, S, Out) -> true ; Out = none ),
             atomic_list_concat([F, ' into ', To, ': ', S], Label),
             check(Label, Out, Want) )),
    assertz(ty_case(tiny2, s, nom)),
    assertz(ty_adjective_ending(tiny2, weak, nom, any, sg, e)),
    assertz(ty_declension(tiny2, def, weak)),
    findall(M, ( typology_check(tiny2, Ms), member(M, Ms), M = declension(_) ), M2),
    retractall(ty_case(tiny2, _, _)), retractall(ty_adjective_ending(tiny2, _, _, _, _, _)),
    retractall(ty_declension(tiny2, _, _)),
    check('endings with no declension for an article are missing rows', M2,
          [declension(indef), declension(none)]).

%% ---- the word tables from corpus/vocabulary --------------------------------------

word_tables :-
    section('the word tables from corpus/vocabulary'),
    forall(member(L-Want, [spanish-36000, italian-25000, english-25000]),
           ( aggregate_all(count, ty_noun(L, _, _, _, _, _), Nn),
             aggregate_all(count, ty_adjective(L, _, _, _, _), Na),
             aggregate_all(count, ty_verb(L, _, _, _, _, _), Nv),
             N is Nn + Na + Nv,
             ( N >= Want -> R = enough ; R = N ),
             atomic_list_concat([L, ' has its word tables: ', Want, ' rows or more'], Label),
             check(Label, R, enough) )),
    typology_translate(spanish, english, 'El abogado vio una casa roja.', E1),
    check('Spanish into English with the vocabulary: the hand template''s casa (house) before the vocabulary''s first meaning (home)', E1,
          'The lawyer saw a red house.'),
    typology_translate(spanish, italian, 'Los médicos no comieron las manzanas verdes.', I2),
    check('Spanish into Italian: the plural, the past, the negation rule, agreement', I2,
          'I medici non mangiarono le mele verdi.'),
    typology_translate(english, spanish, 'The farmers carried the heavy boxes.', S3),
    check('English into Spanish: a plural and a past the English endings made', S3,
          'Los labradores llevaron las cajas pesadas.'),
    findall(W, ( member(M-F, [city-plural, day-plural, carry-past, like-past, play-past, eat-past]),
                 ( F == plural -> ty_noun(english, M, _, _, _, W)
                 ; ty_verb(english, M, past, sg, pos, [W]) ) ), Ws),
    check('the English endings, and a past the vocabulary states', Ws,
          [cities, days, carried, liked, played, ate]),
    typology_write(english, clause(eat, present, neg, np(lawyer, pl, def, []), none), E5),
    check('an imported English verb takes the negation rule', E5, 'The lawyers do not eat.'),
    statistics(inferences, I0),
    findall(x, typology_read(spanish, 'Los médicos no comieron las manzanas verdes.', _), Rs),
    statistics(inferences, I1),
    Cost is I1 - I0,
    length(Rs, NR),
    ( Cost < 20000 -> Cheap = cheap ; Cheap = Cost ),
    format("   every reading of a sentence over 36 000 rows: ~w readings, ~w inferences~n", [NR, Cost]),
    check('every reading over the full tables costs under 20 000 inferences', Cheap, cheap).

%% The import run again reproduces the committed files byte for byte.
class_topics :-
    section('the topics the vocabularies'' class lines give'),
    typology_topics(np(january, sg, def, []), T1),
    check('a month is about the month and the time', T1, [january, month, time]),
    typology_topics(np(avenue, sg, def, []), T2),
    check('an avenue is about a street and a place', T2, [avenue, place, street]),
    findall(T3, ty_topic(fly, T3), Ts3),
    check('a class word that is also a name gives nothing (mosca, Moscow and a fly)', Ts3, []),
    findall(M4-T4, ( member(M4, [metre, subway]), ty_topic(M4, T4) ), Ts4),
    check('a word of two meanings no other word of its class gives gives none (metro)', Ts4, []),
    findall(T5, ty_topic(time, T5), Ts5),
    check('a meaning is no row of its own topic', Ts5, []),
    typology_translate_text(spanish, english, ['El hombre ve la madrugada.'], E6),
    check('Spanish into English: madrugada alone is the dawn, its first meaning', E6,
          ['The man sees the dawn.']),
    typology_translate_text(spanish, english, ['El hombre ve la hora.', 'El hombre ve la madrugada.'], E7),
    check('Spanish into English: madrugada after an hour is the morning', E7,
          ['The man sees the hour.', 'The man sees the morning.']),
    typology_translate_text(italian, english, ['Il ragazzo vede la piazza.', 'Il ragazzo vede la via.'], E8),
    check('Italian into English: via after a square is the road', E8,
          ['The boy sees the square.', 'The boy sees the road.']),
    typology_translate_text(spanish, english, ['El hombre ve la madrugada en la semana.'], E9),
    check('Spanish into English: madrugada in a week is the morning', E9,
          ['The man sees the morning in the week.']).

reproduced :-
    section('the word tables are what the import writes'),
    scratch(Dir),
    forall(member(L, [spanish, italian, english, topics]),
           ( atomic_list_concat([Dir, '/', L, '-words.pl'], Fresh),
             with_output_to(string(_), typology_import(L, Fresh)),
             read_file_to_codes(Fresh, New),
             atomic_list_concat(['templates/', L, '-words.pl'], Committed),
             read_file_to_codes(Committed, Old),
             ( New == Old -> R = same ; R = differs ),
             atomic_list_concat(['templates/', L, '-words.pl is what typology_import(', L, ') writes'], Label),
             check(Label, R, same) )).

%% ---- a language with two orders ---------------------------------------------------

free_order :-
    section('a language that keeps two orders'),
    forall(( member(F, [ty_order(english, clause, _), ty_noun(english, _, _, _, _, _),
                        ty_adjective(english, _, _, _, _), ty_verb(english, _, _, _, _, _),
                        ty_article(english, _, _, _, _), ty_negation(english, _, _, _, _)]),
             call(F) ),
           ( F =.. [P, english|Args], G =.. [P, free|Args], assertz(G) )),
    retractall(ty_order(free, clause, _)),
    assertz(ty_order(free, clause, [s, v, o])),
    assertz(ty_order(free, clause, [o, v, s])),
    assertz(ty_order(free, np, [d, a, n])),
    findall(R, typology_read(free, 'The cat sees the dog.', R), Rs),
    length(Rs, N),
    check('either order is read, so one sentence is two readings', N, 2),
    typology_write(free, clause(see, present, pos, np(cat, sg, def, []), np(dog, sg, def, [])), W),
    check('the first order is the one written', W, 'The cat sees the dog.').

%% ---- what typology_check/2 reports ---------------------------------------------

incomplete :-
    section('typology_check/2 names what a template lacks'),
    retract(ty_verb(free, sleep, past, pl, pos, _)),
    retractall(ty_adjective(free, red, _, _, _)),
    assertz(ty_adjective(free, red, any, sg, red)),
    assertz(ty_order(free, np, [d, n])),
    retractall(ty_noun(free, book, _, _, _, _)),
    assertz(ty_noun(free, book, none, thing, book, books)),
    assertz(ty_before(free, a, [[nonclass]], an, space)),
    typology_check(free, M),
    check('a missing verb form (its negative is still the rule''s), a missing adjective form, an order of the wrong parts, a value no slot takes, a class no row names', M,
          [ bad(ty_before(free, a, [[nonclass]], an, space)),
            bad(ty_noun(free, book, none, thing, book, books)),
            not_an_order(np, [d, n]),
            adjective_form(red, none, pl),
            verb_form(sleep, past, pl, pos) ]).

blank_template :-
    section('the blank template'),
    with_output_to(string(S), typology_template(klingon)),
    split_string(S, "\n", "", Lines),
    include([Line]>>sub_string(Line, 0, _, _, 'ty_order(klingon'), Lines, Orders),
    length(Orders, N),
    check('every order of every level is offered: 6 + 6 + 6 + 2 + 6', N, 26),
    include([Line]>>sub_string(Line, 0, _, _, '%% ty_possessive(klingon'), Lines, Constructions),
    length(Constructions, N2),
    check('and the six orders of a possessor, each a construction''s row', N2, 6).
