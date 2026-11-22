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
    forall(member(L, [english, spanish, italian, persian]), typology_load(L)),
    forall(member(S, [choices, complete, written, round_trips, refused, marks, sounds,
                      copulas, adjuncts, meanings, questions, repairs, relatives, complements, negation_places,
                      question_words, answers,
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
    check('the four templates are loaded', Ls, [english, italian, persian, spanish]).

complete :-
    section('the four templates are complete'),
    forall(member(L, [english, spanish, italian, persian]),
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
                    persian-'پسر سگ می‌بیند.'-'a Persian object that is neither definite nor indefinite',
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
    check('Spanish: a question word in a statement, three faults', F3-Fs3,
          '¿Qué ve el niño?'-[mood(question), wh_place(in_place), question(wh, clause, unchanged)]),
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
             italian-'La ragazza vede il cane nero che dorme.', persian-'دختر سگ سیاهی را که می‌خوابد می‌بیند.'],
        clause(sleep, past, pos, rel(np(girl, pl, def, [small]),
                                     clause(see, past, pos, gap, np(cat, sg, indef, []))), none)-
            [english-'The small girls that saw a cat slept.',
             spanish-'Las niñas pequeñas que vieron a un gato durmieron.',
             italian-'Le ragazze piccole che videro un gatto dormirono.',
             persian-'دخترهای کوچکی که یک گربه دیدند خوابیدند.'],
        clause(see, present, pos, B, rel(np(girl, sg, def, []), copula(present, pos, gap, adj([small]))))-
            [english-'The boy sees the girl that is small.', spanish-'El niño ve a la niña que es pequeña.',
             italian-'Il ragazzo vede la ragazza che è piccola.', persian-'پسر دختری را که کوچک است می‌بیند.'],
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
             persian-'پسری که سگی را که گربه می‌بیند می‌بیند می‌خوابد.'],
        question(clause(see, present, pos, wh(who), rel(D, clause(sleep, present, pos, gap, none))))-
            [english-'Who sees the dog that sleeps?', spanish-'¿Quién ve al perro que duerme?',
             italian-'Chi vede il cane che dorme?', persian-'چه کسی سگی را که می‌خوابد می‌بیند؟'],
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
          'پسر سگی را که می‌خوابد می‌بیند.'),
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
            [english-'The girl that the boy thinks about sleeps.'] ]),
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
    %% Not yet: a relative clause whose gap is a complement where the
    %% adposition moves (Spanish `la niña en la que piensa el niño').
    ( typology_write(spanish, clause(sleep, present, pos, rel(G, clause(think, present, pos, B, gap)), none), _)
    -> R3 = written ; R3 = not_yet ),
    check('Spanish: a complement''s gap where the adposition moves is not written yet', R3, not_yet).

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
    check('every order of every level is offered: 6 + 6 + 6 + 2 + 6', N, 26).
