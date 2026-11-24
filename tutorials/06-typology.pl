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
    %% template to fill (templates/template.pl is it, section 41).
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
    german,
    senses,
    copula_tenses,
    other_tenses,
    negative_article,
    predicate_and,
    months,
    german_possessives,
    german_v2,
    german_dessen,
    german_object_first,
    bridge,
    blank_template,
    english_noun_classes,
    english_verb_classes,
    english_modifiers,
    coordination,
    coordination_same,
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

%% 29. GERMAN. A template with cases: a role or an adposition gives its
%% noun phrase a case (ty_case/3, ty_case_after/3), which the article, the
%% noun and an adjective's ending take (`den kleinen Hund', `mit den
%% Hunden'). The verb stands second, and the last part of a verb of two
%% at the end (`hat ... gesehen'); a relative clause has its verb last and
%% commas round it. `nicht' stands at the end, and an indefinite object
%% takes `kein' in its place.
german :-
    typology_load(german),
    typology_translate(english, german, 'The boy has not seen the small dog.', G1),
    must('the verb second, nicht before the participle', G1, 'Der Junge hat den kleinen Hund nicht gesehen.'),
    typology_translate(english, german, 'The dog that the girl saw sleeps in the house.', G2),
    must('a relative clause, its verb last, between commas', G2, 'Der Hund, den das Mädchen sah, schläft im Haus.'),
    typology_write(german, clause(see, present, neg, np(boy, sg, def, []), np(dog, sg, indef, [])), G3),
    must('kein for an indefinite object', G3, 'Der Junge sieht keinen Hund.'),
    typology_translate(german, spanish, 'Wen hat das Mädchen gesehen?', S4),
    must('a question word in its case', S4, '¿A quién ha visto la niña?').

%% 30. A SENSE OF ITS OWN, AND THE REFERENCE SENTENCES. A hand row gives one
%% sense of an English word a meaning of its own (ty_meaning_sense/2):
%% Spanish and Italian `marzo', the month, is march_month, so it no longer
%% becomes `marcha' or `marcia', the walk, and its class line gives the
%% month's topics to it alone. templates/references.pl's sentences keep
%% their readings: typology_references/2 names any that does not, and in
%% live mode the topics a model gives that would take one away are refused.
senses :-
    typology_translate(spanish, italian, 'El niño duerme en marzo.', I1),
    must('marzo is the month', I1, 'Il ragazzo dorme in marzo.'),
    typology_translate(spanish, italian, 'El niño ve la marcha.', I2),
    must('marcha is the walk', I2, 'Il ragazzo vede la marcia.'),
    typology_references(spanish, F),
    must('every Spanish reference sentence holds', F, []).

%% 31. THE COPULA'S FUTURE AND PERFECT. A template's copula rows name the
%% future and the perfect too (`will be', `ha sido', `wird ... sein'). An
%% Italian participle agrees with the subject (`agree(stato)': `è stata',
%% `sono state'), and German splits a copula of two words as it splits a
%% verb: the second word at the end, or before the verb in a relative
%% clause. An English echo keeps the first word alone (`Yes, it will.').
copula_tenses :-
    typology_translate(english, german, 'The dog will be small.', G1),
    must('wird at the second place, sein at the end', G1, 'Der Hund wird klein sein.'),
    typology_translate(english, italian, 'The house has been big.', I2),
    must('the participle agrees with the subject', I2, 'La casa è stata grande.'),
    typology_translate(english, french, 'The dog has not been small.', F3),
    must('ne ... pas round the first word', F3, 'Le chien n\'a pas été petit.'),
    typology_write(german, clause(sleep, present, pos, rel(np(dog, sg, def, []), copula(future, pos, gap, adj([small]))), none), G4),
    must('a relative clause, both copula words last', G4, 'Der Hund, der klein sein wird, schläft.'),
    typology_answer(english, question(copula(future, pos, np(dog, sg, def, []), adj([small]))), pos, echo, A5),
    must('the echo keeps the first word', A5, 'Yes, it will.').

%% 32. THE IMPERFECT, THE CONDITIONAL AND THE PLUPERFECT. Rows of the hand
%% verbs and of the import (`veía', `vedrebbe'), and the pluperfect a
%% pattern as the perfect is (`había visto', `hatte ... gesehen', `era
%% andata'). A tense a language has no form of is written as another
%% (ty_tense_like/4): English and German write the imperfect as the past.
other_tenses :-
    typology_translate(spanish, english, 'El niño veía al perro.', E1),
    must('the imperfect written as the past', E1, 'The boy saw the dog.'),
    typology_translate(english, italian, 'The boy would see the dog.', I2),
    must('the conditional', I2, 'Il ragazzo vedrebbe il cane.'),
    typology_translate(spanish, german, 'El niño había visto al perro.', G3),
    must('the pluperfect, its participle at the end', G3, 'Der Junge hatte den Hund gesehen.'),
    typology_translate(italian, french, 'La ragazza era andata.', F4),
    must('the pluperfect of a verb of the class essere and être', F4, 'La fille était allée.'),
    typology_translate(italian, spanish, 'I medici mangerebbero le mele.', S5),
    must('an imported verb\'s conditional', S5, 'Los médicos comerían las manzanas.').

%% 33. THE NEGATIVE ARTICLE OF A SUBJECT, AND FRENCH PAS DE. The roles
%% whose indefinite phrase takes the negative article in a negative clause
%% are the template's (ty_negative_article_roles/2): German's subject too
%% (`Kein Hund schläft.'). French keeps its negation beside the article
%% (ty_negative_article_keeps/1): `ne ... pas de'.
negative_article :-
    typology_translate(english, german, 'A dog does not sleep.', G1),
    must('kein for a subject', G1, 'Kein Hund schläft.'),
    typology_translate(english, french, 'The boy does not see a dog.', F2),
    must('pas de for an object', F2, 'Le garçon ne voit pas de chien.'),
    typology_translate(german, french, 'Der Junge sieht keine Tiere.', F3),
    must('de before a vowel', F3, 'Le garçon ne voit pas d\'animaux.'),
    typology_write(french, copula(present, neg, np(dog, sg, def, []), np(animal, sg, indef, [])), F4),
    must('a predicate keeps its article', F4, 'Le chien n\'est pas un animal.').

%% 34. A PREDICATE'S ADJECTIVES JOINED BY AND. ty_and/2 gives the words
%% before a copula's last predicate adjective, a comma before each of the
%% others; a noun phrase's adjectives stay as they are.
predicate_and :-
    typology_translate(english, german, 'The dog is small and black.', G1),
    must('und before the last', G1, 'Der Hund ist klein und schwarz.'),
    typology_translate(german, spanish, 'Der Hund ist klein, schwarz und groß.', S2),
    must('a comma before the others', S2, 'El perro es pequeño, negro y grande.'),
    typology_write(spanish, copula(present, pos, np(dog, sg, def, []), adj([small, important])), S3),
    must('y is e before the sound i', S3, 'El perro es pequeño e importante.'),
    typology_translate(english, persian, 'The dog is small and black.', P4),
    must('and in Persian', P4, 'سگ کوچک و سیاه است.').

%% 35. THE MONTHS. A noun of a topic ty_bare_topic/2 names takes no
%% definite article (`in March', `en marzo', `in gennaio'), where German
%% keeps it (`im März'); ty_adposition_topic/4 gives an adposition its
%% words before a noun of a topic (French `en mars', where `in' is `dans').
months :-
    typology_translate(spanish, english, 'El niño duerme en marzo.', E1),
    must('no article, and the capital', E1, 'The boy sleeps in March.'),
    typology_translate(english, french, 'The boy sleeps in March.', F2),
    must('en before a month', F2, 'Le garçon dort en mars.'),
    typology_translate(english, german, 'The boy sleeps in March.', G3),
    must('German keeps the article', G3, 'Der Junge schläft im März.').

%% 36. THE GERMAN POSSESSIVE PRONOUNS. A stem of the possessor and the
%% ending of the possessed's gender, number and case (`mein', `meinen',
%% `meinem'), the case asked of the phrase where a condition names one; an
%% adjective after one takes the mixed declension, as after `ein'.
german_possessives :-
    typology_translate(english, german, 'The boy sees my small dog.', G1),
    must('the accusative, the mixed declension', G1, 'Der Junge sieht meinen kleinen Hund.'),
    typology_translate(english, german, 'The boy sleeps with my small dog.', G2),
    must('the dative after mit', G2, 'Der Junge schläft mit meinem kleinen Hund.'),
    typology_translate(german, spanish, 'Unser Haus ist groß.', S3),
    must('unser, read', S3, 'Nuestra casa es grande.').

%% 37. GERMAN: AN ADJUNCT FIRST, THE VERB SECOND. ty_adjunct_front(L, v2)
%% reads a statement with an adjunct first and the verb before the subject
%% (`Heute schläft der Hund.'), in a main clause; the writer keeps the
%% template's own place, at the end.
german_v2 :-
    typology_translate(german, english, 'Heute schläft der Hund.', E1),
    must('read with the verb second', E1, 'The dog sleeps today.'),
    typology_translate(english, german, 'The dog sleeps today.', G2),
    must('written at the end', G2, 'Der Hund schläft heute.'),
    ( typology_read(german, 'Heute der Hund schläft.', _) -> R3 = read ; R3 = refused ),
    must('the verb third is no German', R3, refused).

%% 38. GERMAN DESSEN AND DEREN. A possessive relative pronoun's row may
%% name the head's features, head(Features), where Spanish `cuyo' names
%% the possessed's: German `dessen' after a masculine or a neuter head,
%% `deren' after a feminine or a plural one. The possessed after it takes
%% no article, its adjectives strong.
german_dessen :-
    typology_translate(english, german, 'The boy whose dog sleeps sleeps.', G1),
    must('dessen after a masculine head', G1, 'Der Junge, dessen Hund schläft, schläft.'),
    typology_translate(german, english, 'Die Katze, deren kleinen Hund der Junge sieht, schläft.', E2),
    must('deren after a feminine head', E2, 'The cat whose small dog the boy sees sleeps.'),
    ( typology_read(german, 'Der Junge, deren Hund schläft, schläft.', _) -> R3 = read ; R3 = refused ),
    must('deren after a masculine head is no German', R3, refused).

%% 39. GERMAN: AN OBJECT FIRST, THE VERB SECOND. ty_object_front(L, v2)
%% reads a statement with its object first, where the first word cannot
%% begin a subject (`den', `einen', `keinen', `ihn'); `die' and `das' may,
%% so `Die Katze sieht das Mädchen.' keeps its one reading. The writer puts
%% the subject first.
german_object_first :-
    typology_translate(german, english, 'Den Hund sieht der Junge.', E1),
    must('the object first', E1, 'The boy sees the dog.'),
    typology_translate(english, german, 'The boy sees the dog.', G2),
    must('written with the subject first', G2, 'Der Junge sieht den Hund.'),
    typology_translate(german, english, 'Die Katze sieht das Mädchen.', E3),
    must('die may begin a subject', E3, 'The cat sees the girl.').

%% 40. THE BRIDGE TO TRANSLATE.PL (Phase 6). typology_reason_ir/2 maps the
%% typology IR to the term translate.pl reads and writes, ir(S, Stop), and
%% back, for the shapes the two have alike, in the English template's
%% words; test/typology.pl holds the two translators to the same Spanish
%% over a shared set of sentences. A shape the other has not fails.
bridge :-
    typology_read(english, 'The dog does not see the boy.', IR),
    typology_reason_ir(IR, R),
    must('over the bridge', R,
         ir(s(none, np(det(article, the, w(the, lower)), none, [], w(dog, lower), singular),
              g(sees, present, simple, yes),
              [obj(np(det(article, the, w(the, lower)), none, [], w(boy, lower), singular))]), 46)),
    typology_reason_ir(IR2, ir(s(none, np(det(article, the, w(the, lower)), none, [], w(dogs, lower), plural),
                                 g(sleeps, past, simple, no), [adv(w(today, lower))]), 46)),
    must('and back, a noun read in its plural', IR2,
         clause(sleep, past, pos, np(dog, pl, def, []), none, [adv(today)])),
    typology_write(spanish, IR2, S),
    must('written by the template', S, 'Los perros durmieron hoy.'),
    ( typology_reason_ir(clause(see, present, pos, pron(1, sg, _), np(dog, sg, def, [])), _) -> R3 = bridged ; R3 = no_shape ),
    must('a pronoun has no shape on the other side yet', R3, no_shape).

%% 41. THE BLANK TEMPLATE. templates/template.pl is every slot of the
%% template with every choice (typology_template/1 writes it for a name,
%% typology_import(template) the file): a choice is a row of code, which a
%% new language keeps or deletes, and a slot of words is its shape in a
%% comment with another language's row as an example.
blank_template :-
    with_output_to(string(S), typology_template(klingon)),
    split_string(S, "\n", "", Lines),
    include([L]>>sub_string(L, 0, _, _, 'ty_'), Lines, Choices),
    length(Choices, N1),
    must('the choices, each a row of code', N1, 84),
    ( member(L2, Lines), sub_string(L2, 0, _, _, '%% ty_noun(klingon, Meaning, Gender') -> R2 = shape ; R2 = none ),
    must('a slot of words, its shape', R2, shape),
    ( member(L3, Lines), sub_string(L3, 0, _, _, '%%   e.g. ty_noun_in(english, dog,') -> R3 = example ; R3 = none ),
    must('and an example', R3, example).

%% 42. THE CLASSES FIRST, THEN THE ITEMS: the English nouns. A class of the
%% plural is one fact of endings (ty_noun_class/3), a noun of a class one
%% fact (ty_noun_in/6; templates/english-nouns.pl holds some 20 000, from
%% the vocabularies and lexicon/), and an irregular noun one ty_noun/6 fact
%% with its plural; typology_load/1 makes each plural from its class.
english_noun_classes :-
    ( ty_noun(english, city, _, _, _, P1) -> true ; P1 = none ),
    must('a regular noun: the class''s y-ies', P1, cities),
    ( ty_noun(english, crisis, _, _, _, P2) -> true ; P2 = none ),
    must('a noun of the class is-es', P2, crises),
    ( ty_noun(english, child, _, _, _, P3) -> true ; P3 = none ),
    must('an irregular noun, its one fact', P3, children),
    typology_read(english, 'The farmers watched the crises.', IR4),
    must('read', IR4, clause(watch, past, pos, np(farmer, pl, def, []), np(crisis, pl, def, []))).

%% 43. THE ENGLISH VERBS: the classes of the conjugation, then the verbs.
%% A class is one fact of parts and rules (ty_conjugation/3), a verb of a
%% class one fact (ty_verb_in/4; templates/english-verbs.pl holds some
%% 3 800), an irregular verb one fact with the parts its class does not
%% make (ty_irregular_verb/5: see, [past(sg)-saw, participle-seen]); the
%% import puts a verb of one vowel before a consonant that doubles in the
%% class double (ty_class_when/4: stop, stopped).
english_verb_classes :-
    ( ty_verb(english, study, past, sg, pos, [W1]) -> true ; W1 = none ),
    must('a regular verb: the class''s y-ied', W1, studied),
    ( ty_verb(english, stop, past, sg, pos, [W2]) -> true ; W2 = none ),
    must('the class double', W2, stopped),
    ( ty_participle(english, write, W3) -> true ; W3 = none ),
    must('an irregular verb''s own participle', W3, written),
    ( ty_verb(english, write, present, sg, pos, [W4]) -> true ; W4 = none ),
    must('and its class''s present', W4, writes),
    typology_read(english, 'The girl has studied the book.', IR5),
    must('read', IR5, clause(study, perfect, pos, np(girl, sg, def, []), np(book, sg, def, []))).

%% 44. THE ENGLISH ADJECTIVES AND ADVERBS: one fact each. An English
%% adjective has one form, so it is one ty_adjective/5 fact, its word its
%% meaning (templates/english-adjectives.pl, some 17 700), and an adverb one
%% ty_adverb/3 fact (-adverbs.pl, some 1 080), both from lexicon/ and the
%% vocabularies; ty_closed/2's words of grammar are neither. Every English
%% row now has a file of its kind, so there is no English words file.
english_modifiers :-
    typology_read(english, 'The team played poorly.', IR1),
    must('an imported adverb', IR1, clause(play, past, pos, np(team, sg, def, []), none, [adv(poorly)])),
    typology_read(english, 'The wine was unclouded.', IR2),
    must('an imported adjective', IR2, copula(past, pos, np(wine, sg, def, []), adj([unclouded]))),
    ( ty_adverb(english, very, _) -> W3 = adverb ; W3 = grammar ),
    must('very waits for its grammar', W3, grammar).

%% 45. COORDINATION (step 3 of the English goal, 1.59.0): and(Xs) and or(Xs)
%% where a noun phrase stands, and(Cs), or(Cs) and but(Cs) of two clauses.
%% The words are ty_and/2's and ty_conjunction/3's; an and of noun phrases
%% is plural, an or its last item's number; a list is written `A, B and C',
%% and English reads `A, B, and C' too (ty_serial_comma/1).
coordination :-
    B = np(boy, sg, def, []), G = np(girl, sg, def, []), D = np(dog, sg, def, []),
    typology_read(english, 'The boy and the girl see the dog.', IR1),
    must('two subjects, a plural verb', IR1, clause(see, present, pos, and([B, G]), D)),
    ( typology_read(english, 'The boy and the girl sees the dog.', _) -> R2 = read ; R2 = refused ),
    must('a singular verb is refused', R2, refused),
    typology_write(spanish, clause(see, present, pos, B, and([D, G])), W3),
    must('Spanish puts the mark before each object', W3, 'El niño ve al perro y a la niña.'),
    typology_read(english, 'The boy sleeps but the girl sees the dog.', IR4),
    must('two clauses', IR4, but([clause(sleep, present, pos, B, none), clause(see, present, pos, G, D)])),
    typology_write(german, IR4, W5),
    must('German writes a comma before aber', W5, 'Der Junge schläft, aber das Mädchen sieht den Hund.').

%% 46. THE VERBS OF ONE SUBJECT (1.60.0): the second clause of a coordination
%% may say no subject, same in the IR, the first clause's; its verb agrees
%% with that subject, and each language writes no subject there.
coordination_same :-
    typology_read(english, 'The boys sleep and see the dog.', IR1),
    must('same is the first clause''s subject', IR1,
         and([clause(sleep, present, pos, np(boy, pl, def, []), none),
              clause(see, present, pos, same, np(dog, sg, def, []))])),
    ( typology_read(english, 'The boys sleep and sees the dog.', _) -> R2 = read ; R2 = refused ),
    must('and its verb agrees with it', R2, refused),
    typology_write(italian, and([clause(sleep, present, pos, np(girl, sg, def, []), none),
                                 copula(present, pos, same, adj([small]))]), W3),
    must('Italian, its adjective agreeing with the girl', W3, 'La ragazza dorme ed è piccola.').


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
