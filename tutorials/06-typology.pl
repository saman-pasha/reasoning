%% reasoning tutorial 06 -- library(reasoning/typology): a language as a
%% filled template.
%%
%% TIER 2: `use_module(library(reasoning/typology))', from typology.pl, and
%% the templates in templates/ with their word tables. Clauses only: no
%% model (section 25's is a stub), no store. TYPOLOGY-PLAN.md says what
%% comes next.
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
    negation_place,
    asking_and_answering,
    class_topics,
    gaps,
    possessors,
    more_possessors,
    pronouns,
    echoes,
    french,
    references,
    live_topics,
    french_questions,
    tenses,
    polite,
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
           persian-'دختر سگ سیاهی را می‌بیند که پسر می‌بیند.' ]),
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

%% 15. THE PLACE OF THE NEGATION. A language with ty_negation_place/3 rows
%% puts its negation's words as a part of the order -- at the end (German
%% `Der Junge sieht den Hund nicht'), or in parts around the verb (French
%% `ne ... pas') -- and the verb takes its positive form. The four
%% templates have none: their negation is a part of the verb's form. Here
%% a language made of the English rows puts `not' at the end.
negation_place :-
    forall(( member(F, [ty_order(english, clause, _), ty_order(english, np, _),
                        ty_noun(english, _, _, _, _, _), ty_verb(english, _, _, _, _, _),
                        ty_article(english, _, _, _, _), ty_negation(english, _, _, _, _)]),
             call(F) ),
           ( F =.. [P, english|Args], G =.. [P, nicht|Args], assertz(G) )),
    assertz(ty_negation_place(nicht, [not], end)),
    typology_translate(spanish, nicht, 'El niño no ve al perro.', T1),
    must('no ve, with the negation at the end', T1, 'The boy sees the dog not.'),
    once(typology_read(nicht, 'The boys saw the dog not.', IR2)),
    must('and read back', IR2, clause(see, past, neg, np(boy, pl, def, []), np(dog, sg, def, []))).

%% 16. ASKING AND ANSWERING. Several question words: the subject's moves,
%% else the object's, else the adjunct's, and the others stay in place. A
%% question word inside a noun phrase is its article `which' (np(dog, sg,
%% which, [])), definite to the marks. The answer to a yes or no question
%% is answer(Polarity, Asked): ty_answer/3 gives its words by the
%% language's system, and Persian contradicts a negative question with چرا.
asking_and_answering :-
    IR1 = question(clause(see, present, pos, wh(who), wh(what))),
    findall(L-T, ( member(L, [english, spanish, persian]), typology_write(L, IR1, T) ), Ts1),
    must('who sees what: one question word moves', Ts1,
         [english-'Who sees what?', spanish-'¿Quién ve qué?', persian-'چه کسی چه چیزی می‌بیند؟']),
    typology_translate(spanish, english, '¿A qué perro ve el niño?', E2),
    must('which dog, from Spanish', E2, 'Which dog does the boy see?'),
    Q = question(clause(see, present, neg, np(boy, sg, def, []), np(dog, sg, def, []))),
    findall(L-A, ( member(L, [english, persian]), typology_answer(L, Q, pos, A) ), As3),
    must('yes, he does, to a negative question', As3, [english-'Yes.', persian-'چرا.']).

%% 17. THE TOPICS THE VOCABULARIES GIVE. typology_import(topics) writes
%% templates/topics-words.pl from their class lines (`"sábado" is a
%% time.'), so a word with a time's meaning and another takes the time
%% after a sentence about one: `madrugada' alone is the dawn, its first
%% meaning, and after an hour the morning.
class_topics :-
    typology_topics(np(january, sg, def, []), T1),
    must('january is about the month and the time', T1, [january, month, time]),
    typology_translate_text(spanish, english, ['El hombre ve la madrugada.'], E2),
    must('madrugada alone', E2, ['The man sees the dawn.']),
    typology_translate_text(spanish, english, ['El hombre ve la hora.', 'El hombre ve la madrugada.'], E3),
    must('madrugada after an hour', E3, ['The man sees the hour.', 'The man sees the morning.']).

%% 18. A GAP IN AN ADPOSITION PHRASE, A PRONOUN, A CLAUSE AFTER ITS VERB.
%% ty_gap/3 says how a gap is written: in an adposition phrase the
%% adposition stays (English `sleeps in'), moves into the marker with a
%% relative pronoun of the head (ty_relative_pronoun/3: Spanish `en la
%% que', Italian `in cui'), or stays with a pronoun (ty_resumptive/3:
%% Persian `در آن'). ty_relative_after/3 puts the relative clause of an
%% object or a predicate after the verb, as Persian does, and
%% ty_relative_bare/2 drops Persian یک before it. A person is an animacy
%% of its own, animate to every rule, so Persian tells `او' from `آن'.
gaps :-
    IR1 = clause(see, present, pos, np(boy, sg, def, []),
                 rel(np(house, sg, def, []),
                     clause(sleep, present, pos, np(dog, sg, def, []), none, [pp(in, gap)]))),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('the house the dog sleeps in, four times', Ts1,
         [ english-'The boy sees the house that the dog sleeps in.',
           spanish-'El niño ve la casa en la que el perro duerme.',
           italian-'Il ragazzo vede la casa in cui il cane dorme.',
           persian-'پسر خانه‌ای را می‌بیند که سگ در آن می‌خوابد.' ]),
    typology_translate(spanish, persian, 'El perro es un animal que duerme.', P2),
    must('a predicate''s relative clause after the copula', P2, 'سگ حیوانی است که می‌خوابد.'),
    typology_translate(spanish, persian, 'El perro en el que el niño piensa duerme.', P3),
    must('an animal''s pronoun is آن, a person''s او', P3, 'سگی که پسر به آن فکر می‌کند می‌خوابد.').

%% 19. A POSSESSOR, AND WHOSE. of(Possessor, NP) is a level of its own,
%% poss: the possessed (h), the possessive word (p, ty_possessive/3) and
%% the possessor (g). English writes the possessor first, its last word
%% with `'s' and the possessed with no article; Spanish and Italian `de' and
%% `di'; Persian the ezafe. A relative clause's gap may be a possessor:
%% English `whose', Spanish `cuyo' and Italian `il cui' move into the marker
%% with the possessed (ty_relative_possessive/3), Persian puts a clitic on
%% the possessed, which stays (`سگش').
possessors :-
    IR1 = clause(sleep, present, pos, of(np(boy, sg, def, []), np(dog, sg, def, [])), none),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('the boy''s dog, four times', Ts1,
         [ english-'The boy\'s dog sleeps.', spanish-'El perro del niño duerme.',
           italian-'Il cane del ragazzo dorme.', persian-'سگ پسر می‌خوابد.' ]),
    IR2 = clause(sleep, present, pos, rel(np(boy, sg, def, []),
                                          clause(sleep, present, pos, of(gap, np(dog, sg, def, [])), none)), none),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR2, T) ), Ts2),
    must('the boy whose dog sleeps, four times', Ts2,
         [ english-'The boy whose dog sleeps sleeps.', spanish-'El niño cuyo perro duerme duerme.',
           italian-'Il ragazzo il cui cane dorme dorme.', persian-'پسری که سگش می‌خوابد می‌خوابد.' ]).


%% 20. MORE OF THE POSSESSOR. ty_possessive(L, Order, Words, Article) is a
%% construction, and a language may have several, the first written:
%% English writes `of' where the 's cannot stand. A possessor may be a
%% possessor's phrase, or have a relative clause; a possessor's gap may be
%% in an adjunct (`in whose house'). A possessive pronoun is
%% of(pron(Person, Number, Kind), NP) (ty_possessive_pronoun/4, Persian's
%% clitic; section 21 has the personal pronoun).
more_possessors :-
    IR1 = clause(see, present, pos, np(girl, sg, def, []),
                 of(of(np(boy, sg, def, []), np(dog, sg, def, [])), np(house, sg, def, []))),
    typology_write(english, IR1, E1),
    must('a possessor''s possessor', E1, 'The girl sees the boy\'s dog\'s house.'),
    typology_translate(english, spanish, 'The girl sees the boy in whose house the dog sleeps.', S2),
    must('in whose house, into Spanish', S2, 'La niña ve al niño en cuya casa el perro duerme.'),
    findall(L-T, ( member(L, [english, spanish, italian, persian]),
                   typology_write(L, clause(sleep, present, pos, of(pron(3, sg, f), np(dog, sg, def, [])), none), T) ), Ts3),
    must('her dog, four times', Ts3,
         [ english-'Her dog sleeps.', spanish-'Su perro duerme.',
           italian-'Il suo cane dorme.', persian-'سگش می‌خوابد.' ]).



%% 21. THE PERSONAL PRONOUN AND THE PERSON. pron(Person, Number, Kind) stands
%% where a noun phrase stands: Person 1, 2, 3, Number sg, pl, Kind m, f, n.
%% A reading binds what its words tell and leaves the rest unbound (`you'
%% is pron(2, _, _)). The verb agrees with a person and a number, a key
%% (sg(1) for `I'), its form a row of the template or the template's rule
%% (ty_verb_person/6: English `I see', Persian `می‌بینم'). Spanish, Italian
%% and Persian write no subject pronoun of the first and the second person
%% (ty_pro_drop/2: `Veo al perro.'), and Spanish and Italian an object
%% pronoun as a clitic in the verb's words (ty_clitic/2: `no lo veo').
pronouns :-
    IR1 = clause(see, present, neg, pron(1, sg, _), pron(3, sg, m)),
    findall(L-T, ( member(L, [english, spanish, italian, persian]), typology_write(L, IR1, T) ), Ts1),
    must('I do not see him, four times', Ts1,
         [ english-'I do not see him.', spanish-'No lo veo.',
           italian-'Non lo vedo.', persian-'او را نمی‌بینم.' ]),
    typology_translate(spanish, english, 'Ves nuestra casa.', E2),
    must('the verb tells the subject: you see our house', E2, 'You see our house.'),
    findall(IR, typology_read(english, 'You sleep.', IR), IRs3),
    length(IRs3, N3),
    must('you is one or several, familiar or polite: four readings', N3, 4),
    typology_translate(persian, italian, 'کوچک هستیم.', I4),
    must('we are small, the Persian ending into Italian', I4, 'Siamo piccoli.').


%% 22. THE ECHO, AND EVERY QUESTION WORD AT THE FRONT. typology_answer/5's
%% echo repeats the question's clause short, as ty_answer_echo/3 says:
%% English the subject and its auxiliary, Persian the verb; the subject is
%% as the one who answers says it (you is I). ty_wh(L, all_front) puts
%% every question word at the front, as Bulgarian and Russian do (`Кой
%% какво вижда?', who what sees), here on English's words.
echoes :-
    Q1 = question(clause(see, present, pos, pron(2, sg, _), np(dog, sg, def, []))),
    findall(L-T, ( member(L, [english, persian]), typology_answer(L, Q1, pos, echo, T) ), Ts1),
    must('do you see the dog? yes, I do', Ts1, [english-'Yes, I do.', persian-'بله، می‌بینم.']),
    Q2 = question(clause(see, present, neg, np(girl, sg, def, []), np(dog, sg, def, []))),
    typology_answer(english, Q2, neg, echo, E2),
    must('the girl is she', E2, 'No, she does not.'),
    forall(( member(F, [ty_order(english, _, _), ty_noun(english, _, _, _, _, _),
                        ty_verb(english, _, _, _, _, _), ty_article(english, _, _, _, _),
                        ty_question(english, _, _, _), ty_question_form(english, _, _, _, _),
                        ty_wh_word(english, _, _), ty_adjunct(english, _)]),
             call(F) ),
           ( F =.. [P, english|As], F2 =.. [P, front_all|As], assertz(F2) )),
    assertz(ty_wh(front_all, all_front)),
    IR3 = question(clause(see, past, pos, np(boy, sg, def, []), wh(what), [wh(where)])),
    typology_write(front_all, IR3, F3),
    must('every question word at the front', F3, 'What where did the boy see?').


%% 23. A FIFTH LANGUAGE, FRENCH, FROM ITS TEMPLATE ALONE. The grammar did
%% not change for it but by three slots any language may use: the
%% adjectives that stand before the noun (ty_adjective_before/2: `le petit
%% chien'), a particle of two words (`est-ce que') and `dont', a
%% possessor's gap whose possessed stays (ty_gap(french, poss, stays)).
%% The negation is two words around the verb (ty_negation_place/3), and an
%% object clitic stands inside them.
french :-
    typology_load(french),
    typology_check(french, M1),
    must('the French template lacks nothing', M1, []),
    typology_translate(spanish, french, 'No lo veo.', F2),
    must('I do not see him', F2, 'Je ne le vois pas.'),
    typology_translate(english, french, 'The small girls saw the black dog.', F3),
    must('an adjective before the noun, an adjective after it', F3, 'Les petites filles virent le chien noir.'),
    typology_translate(english, french, 'The girl sees the boy whose dog sleeps.', F4),
    must('dont', F4, 'La fille voit le garçon dont le chien dort.'),
    typology_translate(french, english, 'Est-ce que l\'homme dort?', E5),
    must('est-ce que, and l\'homme, into English', E5, 'Does the man sleep?').


%% 24. A PRONOUN THAT REFERS BACK. typology_read_text/3 gives each pronoun of
%% the third person the noun before it that it stands for, its kind
%% ref(Meaning): the noun of its own role in the latest sentence first,
%% one whose number and kind fit. Each language then takes its own kind
%% for that noun: Spanish, Italian and French the noun's gender
%% (ty_pronoun_gender/2: a house is `la'), English and Persian the
%% meaning's (`it'); and a language that drops a subject drops one whose
%% noun was said.
references :-
    typology_translate_text(spanish, english, ['El niño ve la casa.', 'La ve.'], E1),
    must('la is the house, and the subject no word says the boy', E1,
         ['The boy sees the house.', 'He sees it.']),
    typology_translate_text(english, french, ['The girl sees the house.', 'She sees it.'], F2),
    must('it is the house, so la', F2, ['La fille voit la maison.', 'Elle la voit.']),
    typology_translate_text(english, italian, ['The boy sees the book.', 'He sees it.'], I3),
    must('he is said, so no word; it is the book, so lo', I3, ['Il ragazzo vede il libro.', 'Lo vede.']).

%% 25. TOPICS A MODEL GIVES. Of a word with several meanings the context
%% keeps those whose topics it has (section 10), so a meaning the tables
%% give no topic is never chosen that way. In LIVE mode (reason_set_mode/1)
%% the reader asks a model, once, for the topics of such meanings, from the
%% topics the tables know, and keeps the answer as
%% reason_live_topics(Meaning, Topics), which static mode then uses too.
%% Here a stub stands for the model (reason_live_stub/3): a prompt with
%% `la lima' in it gets the stub's reply.
live_topics :-
    T = 'El niño ve la lima.',
    lima_objects(T, O1),
    must('static: with food given, lima is still the file and the lime', O1, [file, lime]),
    reason_set_mode(live),
    assertz(reason_live_stub('la lima', topics,
        '{"topics": [{"meaning": "lime", "topics": ["food", "plant"]}, {"meaning": "file", "topics": ["tool"]}]}')),
    lima_objects(T, O2),
    reason_set_mode(static),
    retractall(reason_live_stub(_, _, _)),
    must('live: the model says a lime is food, so lima is the lime', O2, [lime]),
    findall(M-Ts, ( member(M, [file, lime]), reason_live_topics(M, Ts) ), Saved),
    must('what is kept', Saved, [file-[tool], lime-[food, plant]]),
    reason_live_forget.

%% The meanings of the object in every reading of T, with food given.
lima_objects(T, Os) :-
    findall(O, ( typology_read(spanish, T, IR, [food]), IR = clause(_, _, _, _, np(O, _, _, _)) ), Os0),
    sort(Os0, Os).

%% 26. FRENCH QUESTIONS. A yes or no question may put a pronoun of the
%% subject after the verb, joined to it (ty_inversion/3, the rule
%% invert(pronoun)): `voit-il', and `-t-' between two vowels, `pense-t-il';
%% a noun subject keeps its place, a pronoun subject has no other. A
%% question word may take `est-ce que' after it, and `what' is `quoi'
%% after a preposition and in place (ty_wh_tonic/3), where `que' opens
%% the question.
french_questions :-
    typology_load(french),
    typology_translate(french, english, 'Le garçon voit-il le chien?', E1),
    must('the inversion is a yes or no question', E1, 'Does the boy see the dog?'),
    typology_translate(french, english, 'Pense-t-il à la fille?', E2),
    must('-t- between two vowels, and the pronoun the subject', E2, 'Does he think about the girl?'),
    typology_translate(french, english, 'Qu\'est-ce que le garçon voit?', E3),
    must('qu\'est-ce que', E3, 'What does the boy see?'),
    typology_translate(english, french, 'What does the boy think about?', F4),
    must('after a preposition, quoi', F4, 'À quoi pense le garçon?').

%% 27. THE FUTURE AND THE PERFECT. A tense is a row (Spanish `verá', the
%% import's futures of the vocabulary's verbs) or a pattern of words and
%% another form (ty_tense_form/5: English [will, form(present, pl)], [has,
%% participle]). A participle agrees with an object clitic before it
%% (Italian `l'ha vista'), and a class of verbs has patterns of its own
%% whose participle agrees with the subject (ty_class_tense_form/6:
%% `essere', `La ragazza è andata'). French puts the negation and an
%% inverted pronoun after the auxiliary (`n'a pas vu', `a-t-il vu').
tenses :-
    IR1 = clause(see, perfect, pos, np(boy, sg, def, []), pron(3, sg, f)),
    findall(L-T, ( member(L, [english, spanish, italian, french]), typology_write(L, IR1, T) ), Ts1),
    must('the boy has seen her, four times', Ts1,
         [english-'The boy has seen her.', spanish-'El niño la ha visto.',
          italian-'Il ragazzo l\'ha vista.', french-'Le garçon l\'a vue.']),
    typology_translate(english, italian, 'The girls have gone.', I2),
    must('essere, and the participle agrees with the subject', I2, 'Le ragazze sono andate.'),
    typology_translate(english, french, 'The boy will not see the dog.', F3),
    must('the future', F3, 'Le garçon ne verra pas le chien.'),
    typology_translate(french, english, 'N\'a-t-il pas vu le chien?', E4),
    must('the negation and the pronoun after the auxiliary', E4, 'Has he not seen the dog?').

%% 28. THE POLITE YOU. pron(polite, Number, Kind) is the polite `you': its
%% verb takes the form ty_polite/3 maps it to (Spanish and Italian one
%% person the third person's, `usted ve', `Lei vede'; French and Persian
%% the second plural's, `vous voyez', `شما می‌بینید'), and it is never a
%% dropped subject. English `you' is both, the familiar reading first.
polite :-
    IR1 = clause(see, present, pos, pron(polite, sg, _), np(dog, sg, def, [])),
    findall(L-T, ( member(L, [spanish, italian, french]), typology_write(L, IR1, T) ), Ts1),
    must('the polite you sees the dog', Ts1,
         [spanish-'Usted ve al perro.', italian-'Lei vede il cane.', french-'Vous voyez le chien.']),
    typology_translate(spanish, french, 'Ustedes no vieron al perro.', F2),
    must('ustedes is vous', F2, 'Vous ne vîtes pas le chien.'),
    typology_translate(english, spanish, 'You see the dog.', S3),
    must('English you is the familiar first', S3, 'Ves al perro.').


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
