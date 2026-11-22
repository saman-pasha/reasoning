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

    %% 9. FORMS CHOSEN BY SOUND. ty_before/5 writes a word in another form
    %% when the next word begins with a pattern, the longest pattern of the
    %% word's rows winning: `an apple' but `a university', Italian `lo',
    %% `gli' and `l'' joined to its noun. ty_linked/5 writes a word in
    %% another form when a word of a class follows it, by the word's own
    %% ending: the Persian ezafe, written after a silent h. Reading keeps
    %% only what the writer would write.
    findall(T, ( member(L-IR9, [ english-clause(eat, present, pos, np(boy, sg, def, []), np(apple, sg, indef, [])),
                                 italian-clause(see, present, pos, np(lawyer, sg, def, []), np(student, pl, def, [])),
                                 persian-clause(see, present, pos, np(boy, sg, def, []), np(cat, sg, def, [black])) ]),
                 typology_write(L, IR9, T) ), Ts9),
    must('an apple, l''avvocato and gli studenti, the ezafe', Ts9,
         [ 'The boy eats an apple.',
           'L\'avvocato vede gli studenti.',
           'پسر گربه‌ی سیاه را می‌بیند.' ]),
    ( typology_read(italian, 'Il avvocato vede i studenti.', _) -> R9 = read ; R9 = refused ),
    must('what the writer would not write is not read', R9, refused),
    meanings,
    questions,
    repairs,
    relatives,
    complements,
    format("~ndone~n", []).

%% 10. A WORD WITH SEVERAL MEANINGS IN ONE PLACE. First the words around it
%% choose, a lookback and a lookahead: ty_sense/5 makes Spanish `a' the
%% object's mark after a verb and before an animate noun, and `to'
%% anywhere else. Then the topics of the context (templates/topics.pl, one
%% table for every language): `hoja' is a leaf, a sheet and a blade; beside
%% `árbol' it is a leaf, and after a sentence about a knife a blade. The
%% writer writes a word only where its context gives it the meaning meant.
meanings :-
    once(typology_read(spanish, 'El niño ve a un libro.', IR1)),
    must('a before a thing is to', IR1,
         clause(see, present, pos, np(boy, sg, def, []), none, [pp(to, np(book, sg, indef, []))])),
    once(typology_read(spanish, 'El niño ve la hoja en el árbol.', IR2)),
    must('hoja beside a tree is a leaf', IR2,
         clause(see, present, pos, np(boy, sg, def, []), np(leaf, sg, def, []), [pp(in, np(tree, sg, def, []))])),
    typology_translate_text(spanish, english, ['El hombre ve el cuchillo.', 'El hombre ve la hoja.'], E3),
    must('after a sentence about a knife, a blade', E3, ['The man sees the knife.', 'The man sees the blade.']),
    typology_write(spanish, clause(see, present, pos, np(boy, sg, def, []), np(blade, sg, def, []),
                                   [pp(in, np(book, sg, def, []))]), S4),
    must('a blade beside a book is cuchilla: hoja there would be a sheet', S4,
         'El niño ve la cuchilla en el libro.').

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

%% 11. QUESTIONS. ty_question/4 says how a question changes a level's
%% order, a choice among five: unchanged, a particle at the start or the
%% end, the verb before the subject (front(all)), or its first word only
%% (front(first), with English `does' from ty_question_form/5). ty_wh/2
%% puts a question word at the front or leaves it in place. The IR is
%% question(Clause), a question word wh(M) where its role stands.
questions :-
    IR1 = question(clause(see, past, pos, np(girl, sg, def, []), wh(who))),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('whom did the girl see, four times', Ts1,
         [ english-'Who did the girl see?',
           spanish-'¿A quién vio la niña?',
           italian-'La ragazza chi vide?',
           persian-'دختر چه کسی را دید؟' ]),
    typology_translate(english, spanish, 'Is the dog not big?', S2),
    must('a yes or no question, into Spanish', S2, '¿El perro no es grande?'),
    typology_translate(spanish, persian, '¿Dónde está el perro?', P3),
    must('a question word at the front, into Persian, where it stays in place', P3, 'سگ کجاست؟').

%% 12. REPAIRS. Of several readings of a question the reader keeps the one
%% whose order is closest to the statement's: `Chi vede il ragazzo?' is
%% who sees the boy, so the writer puts whom the girl saw as `La ragazza
%% chi vide?' (above). A sentence the template does not allow is read with
%% the fewest faults -- each check of the template a second road that
%% notes one -- and written as the template has it.
repairs :-
    once(typology_repair(spanish, 'Los perro ven al gato.', _, Fs1, T1)),
    must('one fault, the noun: not the article and the verb, two', T1-Fs1,
         'Los perros ven al gato.'-[agreement(noun, perro)]),
    once(typology_repair(english, 'What the boy sees?', _, Fs2, T2)),
    must('an English question with no does', T2-Fs2,
         'What does the boy see?'-[question(wh, clause, unchanged)]),
    once(typology_repair(persian, 'پسر می‌بیند سگ را.', _, Fs3, T3)),
    must('a Persian verb before its object', T3-Fs3, 'پسر سگ را می‌بیند.'-[order(clause, [s, v, o])]).

%% 13. RELATIVE CLAUSES. A noun phrase with a relative clause is a level of
%% its own, rel: the head (h), the marker (m, ty_relative/4) and the clause
%% (c), six orders like the others. The clause has a GAP where the head
%% stands in it, and the gap is the head to every check: the verb agrees
%% with it, and its role asks its animacy. Persian puts ی on the head's
%% last word, and its object's mark stays with the head.
relatives :-
    IR1 = clause(see, present, pos, np(girl, sg, def, []),
                 rel(np(dog, sg, def, [black]), clause(see, present, pos, np(boy, sg, def, []), gap))),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('the black dog that the boy sees, four times', Ts1,
         [ english-'The girl sees the black dog that the boy sees.',
           spanish-'La niña ve al perro negro que el niño ve.',
           italian-'La ragazza vede il cane nero che il ragazzo vede.',
           persian-'دختر سگ سیاهی را که پسر می‌بیند می‌بیند.' ]),
    once(typology_read(english, 'The boys who see the dog sleep.', IR2)),
    must('the gap is the subject, and the verb agrees with the head', IR2,
         clause(sleep, present, pos, rel(np(boy, pl, def, []), clause(see, present, pos, gap, np(dog, sg, def, []))), none)),
    ( typology_read(english, 'The book that sees the dog sleeps.', _) -> R3 = read ; R3 = refused ),
    must('a book does not see', R3, refused).

%% 14. A VERB'S COMPLEMENT. ty_complement/3 says that a verb's object is an
%% adposition phrase the verb chooses: English `think about', `look at';
%% Spanish `pensar en'; Italian `pensare a'; Persian `به ... فکر کردن'. The
%% IR keeps the plain object, so a complement in one language is a plain
%% object in another. ty_complement_wh/2 says whether the adposition moves
%% with a question word or stays.
complements :-
    IR1 = question(clause(think, present, pos, np(boy, sg, def, []), wh(what))),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('what does the boy think about, four times', Ts1,
         [ english-'What does the boy think about?',
           spanish-'¿En qué piensa el niño?',
           italian-'A cosa pensa il ragazzo?',
           persian-'پسر به چه چیزی فکر می‌کند؟' ]),
    typology_translate(english, spanish, 'The boy looks at the dog.', S2),
    must('look at is mirar, with a plain object', S2, 'El niño mira al perro.'),
    once(typology_repair(english, 'The boy looks the dog.', _, Fs3, T3)),
    must('a complement missing, repaired', T3-Fs3, 'The boy looks at the dog.'-[complement(missing, [at])]).

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
