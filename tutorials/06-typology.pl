%% reasoning tutorial 06 -- library(reasoning/typology): a language as a
%% filled template.
%%
%% TIER 2: `use_module(library(reasoning/typology))', from typology.pl, and
%% the templates in templates/ with their word tables. Clauses only: no
%% model, no store. TYPOLOGY-PLAN.md says what comes next.
%%
%%     cocolog -s tutorials/06-typology.pl
%%
%% A LANGUAGE IS A CHOICE AMONG ALL THE ORDERS. A clause has three parts
%% (the subject, the verb, the object) and a noun phrase three (the
%% article, the adjectives, the noun), so each can stand in six orders and
%% no other. A language keeps the orders it uses and gives its words and
%% forms; the grammar knows the roles and the levels and no language. The
%% same clauses read a sentence into the IR and write the IR into a
%% sentence, so four templates are four languages and twelve directions.

:- use_module(library(reasoning/typology)).

main :-
    %% 1. Every order of a level. There are no others to choose from.
    typology_choices(clause, Cs),
    length(Cs, N1),
    must('the clause can stand in six orders', N1, 6),
    show('they are', Cs),

    %% 2. A template per language, in templates/. Each is complete: an
    %% order for each level, and every form the grammar may ask for.
    forall(member(L, [english, spanish, italian, persian]), typology_load(L)),
    findall(L-M, ( member(L, [english, spanish, italian, persian]), typology_check(L, M) ), Ms),
    must('nothing is missing from the four', Ms,
         [english-[], spanish-[], italian-[], persian-[]]),

    %% 3. One IR, four sentences: each language's order, agreement and marks.
    IR = clause(see, present, pos, np(boy, sg, def, []), np(dog, sg, def, [black])),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR, T) ), Ts),
    must('the boy sees the black dog, four times', Ts,
         [ english-'The boy sees the black dog.',
           spanish-'El niño ve al perro negro.',
           italian-'Il ragazzo vede il cane nero.',
           persian-'پسر سگ سیاه را می‌بیند.' ]),

    %% 4. Any language into any other, through the IR: Spanish into Persian.
    typology_read(spanish, 'Las niñas no vieron un libro rojo.', IR4),
    show('the IR of the Spanish', IR4),
    typology_write(persian, IR4, P4),
    must('and the IR in Persian', P4, 'دخترها یک کتاب قرمز ندیدند.'),

    %% 5. What the template does not allow is not read: an adjective that
    %% does not agree with its noun, a verb before a Persian object.
    ( typology_read(spanish, 'La niña pequeño duerme.', _) -> R5a = read ; R5a = refused ),
    must('a Spanish adjective that does not agree', R5a, refused),
    ( typology_read(persian, 'پسر می‌بیند سگ را.', _) -> R5b = read ; R5b = refused ),
    must('a Persian verb before its object', R5b, refused),

    %% 6. A new language is a filled template, nothing more: here an
    %% invented one whose verb comes first and whose article follows the
    %% noun and its adjective. typology_template/1 prints the blank
    %% template to fill.
    new_language,
    typology_write(verbish, IR, V6),
    must('the boy sees the black dog, in a fifth order', V6, 'Seo kalo ba pito noro ba.'),
    typology_read(verbish, 'Seo kalo ba pito noro ba.', IR6),
    must('and read back', IR6, IR),

    %% 7. A template with a gap says what it lacks.
    retract(ty_verb(verbish, see, past, pl, neg, _)),
    typology_check(verbish, M7),
    must('typology_check/2 names the missing form', M7, [verb_form(see, past, pl, neg)]),

    %% 8. THE WORD TABLES. templates/<name>-words.pl holds the rows
    %% typology_import/1 wrote from corpus/vocabulary: some twelve thousand
    %% Spanish nouns with their gender and plural, the adjectives' forms,
    %% the verbs' present and past. A negative no table lists is the
    %% template's negation rule (`no', `non', `does not'), and the English
    %% plurals and pasts are its ending rules. Round the three languages
    %% and back, with no word of the sentence in a hand template:
    typology_translate(spanish, english, 'Los médicos no comieron las manzanas verdes.', E8),
    must('Spanish into English', E8, 'The doctors did not eat the green apples.'),
    typology_translate(english, italian, E8, I8),
    must('English into Italian', I8, 'I medici non mangiarono le mele verdi.'),
    typology_translate(italian, spanish, I8, S8),
    must('and Italian into Spanish, the sentence it began as', S8,
         'Los médicos no comieron las manzanas verdes.'),
    format("~ndone~n", []).

new_language :-
    assertz(ty_order(verbish, clause, [v, s, o])),
    assertz(ty_order(verbish, np, [n, a, d])),
    assertz(ty_noun(verbish, boy, none, animate, kalo, kaloi)),
    assertz(ty_noun(verbish, dog, none, animate, pito, pitoi)),
    assertz(ty_adjective(verbish, black, any, any, noro)),
    assertz(ty_article(verbish, def, any, any, ba)),
    forall(( member(T-Tn, [present-'', past-'k']), member(N-Nn, [sg-'', pl-'i']),
             member(P-Pn, [pos-'', neg-'na']) ),
           ( atomic_list_concat([Pn, se, Tn, o, Nn], W), assertz(ty_verb(verbish, see, T, N, P, [W])) )).

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
