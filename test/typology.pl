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
                      word_tables, reproduced, free_order, incomplete, blank_template]),
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
                    spanish-'El niño ve a un libro.'-'a personal a before a thing',
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
    check('Spanish into English with the vocabulary: a word''s first meaning there is read first', E1,
          'The lawyer saw a red home.'),
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
reproduced :-
    section('the word tables are what the import writes'),
    scratch(Dir),
    forall(member(L, [spanish, italian, english]),
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
    check('every order of every level is offered', N, 12).
