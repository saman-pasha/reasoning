%% cocolog -- library(reasoning/typology): a language as a filled template,
%% and one grammar that reads every language into the IR and writes the IR
%% into every language.
%%
%%     :- use_module(library(reasoning/typology)).
%%
%%     ?- typology_load(spanish), typology_load(persian),
%%        typology_read(spanish, 'El niño ve al perro negro.', IR),
%%        typology_write(persian, IR, P).
%%     IR = clause(see, present, pos, np(boy, sg, def, []),
%%                 np(dog, sg, def, [black])),
%%     P = 'پسر سگ سیاه را می‌بیند.'
%%
%% A LANGUAGE IS A CHOICE AMONG ALL THE ORDERS, NOT A LIST OF SENTENCES. The
%% grammar here knows ROLES and LEVELS and no word and no order of any
%% language. A level is a head and the parts around it, and its parts can
%% stand in a fixed number of orders, all of them listed:
%%
%%     clause   s the subject, v the verb, o the object     6 orders
%%     np       d the article, a the adjectives, n the noun  6 orders
%%
%% A language keeps the orders it uses (typology_choices/2 lists all of
%% them; typology_template/1 prints a blank template with every order in
%% it), and the reader takes any order the language keeps; the writer
%% writes the first. Two levels, not one flat order of every word: an
%% adjective belongs to its noun and not to the verb, two nouns are told
%% apart by their ROLE and not by their class, and the count of choices
%% ADDS across levels (6 + 6) where one flat order would multiply them.
%%
%% THE TEMPLATE. A language file is facts, the language's name first in
%% each, one file a language in templates/ beside this file
%% (templates/english.pl, templates/persian.pl, ...; typology_load/1 reads
%% one):
%%
%%     ty_order(L, Level, Order)       an order of a level's parts the
%%                                     language uses; the first is written
%%     ty_noun(L, Meaning, Gender, Animacy, Singular, Plural)
%%                                     Gender: the language's own (m, f,
%%                                     ...), or none; Animacy: animate,
%%                                     inanimate, or unknown (an imported
%%                                     noun the vocabulary says nothing of:
%%                                     no mark asks for it)
%%     ty_adjective(L, Meaning, Gender, Number, Word)
%%                                     a form for a gender and a number;
%%                                     any for a form that does not change
%%     ty_verb(L, Meaning, Tense, Number, Polarity, Words)
%%                                     Tense present or past, Number sg or
%%                                     pl (the subject's), Polarity pos or
%%                                     neg; Words a LIST, so `does not see',
%%                                     `no ve' and `نمی‌بیند' are all forms
%%     ty_article(L, Definiteness, Gender, Number, Word)
%%                                     def or indef; a combination with no
%%                                     row has NO article (an English plural
%%                                     indefinite: `dogs')
%%     ty_mark(L, Role, Place, Word, Conditions)
%%                                     a word before or after a role's
%%                                     phrase, written when the phrase has
%%                                     every feature of one of the
%%                                     Conditions (a list of lists of def,
%%                                     indef, sg, pl, animate, inanimate):
%%                                     Persian `را' after a definite object,
%%                                     Spanish `a' before an animate one
%%     ty_contraction(L, Words, Word)  two words written as one (`a el' is
%%                                     `al'), and read back as two
%%     ty_negation(L, Tense, Number, Words, Form)
%%                                     a negative the template does not list
%%                                     is Words before a positive form: the
%%                                     same one (Form `same': `no ve') or
%%                                     another (`form(T, N)': English `does
%%                                     not' before the present plural, `see');
%%                                     Tense and Number may be any
%%     ty_letters(L, Class, Letters)   a class of letters a pattern names
%%                                     (vowel, consonant)
%%     ty_before(L, Word, Patterns, Form, Join)
%%                                     Word is written Form before a word
%%                                     that begins with a pattern, the
%%                                     longest pattern winning: English `an'
%%                                     before a vowel and `a' before `uni',
%%                                     Italian `lo', `gli', `uno', and `l''
%%                                     and `un'' written joined to the noun
%%                                     (Join `joined', else `space'),
%%                                     Spanish `el' before `agua'. A pattern
%%                                     is a list of letters, classes and
%%                                     `end' (the word ends there)
%%     ty_linked(L, Class, NextClass, From, To)
%%                                     a word of Class right before a word of
%%                                     NextClass in its phrase ends in To in
%%                                     place of From, the longest From
%%                                     winning: the written Persian ezafe
%%                                     (`گربه' before an adjective is
%%                                     `گربه‌ی'); a word no row fits is
%%                                     unchanged
%%     ty_ending(L, Feature, From, To) a form a rule makes: a word ending in
%%                                     From takes To in its place, the
%%                                     longest From that fits winning
%%                                     (English plural: `y' to `ies', `ay' to
%%                                     `ays', `' to `s'); the import uses it
%%                                     where the vocabulary states no form
%%
%% THE WORD TABLES. templates/<name>-words.pl holds the rows
%% typology_import/1 writes from corpus/vocabulary/<name>.txt (and, for
%% English, from every vocabulary's English meanings); typology_load/1 reads
%% it after the hand template, whose rows come first and win. Edit the hand
%% template, never the words file, and import again.
%%
%% THE IR is the meaning with English words in it, the same for every
%% language:
%%
%%     clause(Predicate, Tense, Polarity, Subject, Object)  Object none
%%                                     for a clause with no object
%%     np(Noun, Number, Definiteness, Adjectives)
%%
%% WHAT IS PUBLIC:
%%
%%     typology_load(+Name)            consult templates/Name.pl, then
%%                                     templates/Name-words.pl if it exists
%%     typology_import(+Name)          write templates/Name-words.pl
%%     typology_import(+Name, +File)   or File, and report the counts
%%     typology_languages(-Names)      the languages loaded
%%     typology_choices(+Level, -Orders)  every order of a level's parts
%%     typology_template(+Name)        a blank template on the output:
%%                                     every order, and the shape of each
%%                                     row
%%     typology_check(+Name, -Missing) what the template lacks: a level
%%                                     with no order, an order that is no
%%                                     order of its parts, a verb form or
%%                                     an adjective form the grammar may
%%                                     need, a row with a value no slot
%%                                     takes. [] is a complete template
%%     typology_read(+Name, +Text, -IR)   a sentence into the IR; each
%%                                     reading on backtracking
%%     typology_write(+Name, +IR, -Text)  the IR into a sentence
%%     typology_translate(+From, +To, +Text, -Text2)
%%
%% THE GRAMMAR IS ONE DCG THAT RUNS BOTH WAYS. Each slot offers what may
%% stand there, and a check at the end of its level keeps what the
%% template allows -- agreement of the adjectives and the article with the
%% noun, the article a combination has or lacks, the marks a role's
%% phrase needs -- so the same clauses read (the words given) and write
%% (the IR given), and no order is written into them.
%%
%% TYPOLOGY-PLAN.md says what comes next. NOT YET (each is a slot to add,
%% not a change to the grammar): prepositions, adverbs, questions,
%% relative clauses, persons other than the third, more tenses; a
%% language written without spaces.

:- module(typology, [ typology_load/1, typology_languages/1, typology_choices/2,
                      typology_template/1, typology_check/2, typology_read/3,
                      typology_write/3, typology_translate/4,
                      typology_import/1, typology_import/2 ]).

:- use_module(library(reasoning/reason), [ reason_base/2 ]).

:- dynamic ty_order/3, ty_noun/6, ty_adjective/5, ty_verb/6, ty_article/5,
           ty_mark/5, ty_contraction/3, ty_negation/5, ty_ending/4,
           ty_letters/3, ty_before/5, ty_linked/5.
:- discontiguous ty_order/3, ty_noun/6, ty_adjective/5, ty_verb/6,
                 ty_article/5, ty_mark/5, ty_contraction/3, ty_negation/5,
                 ty_ending/4, ty_letters/3, ty_before/5, ty_linked/5.

%% ---- the levels and the values a slot takes -----------------------------------

ty_level(clause, [s, v, o]).
ty_level(np, [d, a, n]).

ty_values(tense, [present, past]).
ty_values(number, [sg, pl]).
ty_values(polarity, [pos, neg]).
ty_values(definiteness, [def, indef]).
ty_values(animacy, [animate, inanimate, unknown]).
ty_values(place, [before, after]).
ty_values(role, [s, o]).

%% ---- loading --------------------------------------------------------------------

typology_load(Name) :-
    must_be(atom, Name),
    consult(library(reasoning/templates/Name)),
    atom_concat(Name, '-words', Words),
    (   ty_file(Words, File)
    ->  consult(File)
    ;   true
    ).

%% templates/Base.pl, found on the library path.
ty_file(Base, File) :-
    atomic_list_concat(['templates/', Base, '.pl'], Rel),
    catch(absolute_file_name(library(reasoning/Rel), File, [access(read)]), _, fail).

typology_languages(Names) :-
    (   setof(L, O^ty_order(L, clause, O), Names) -> true ; Names = [] ).

%% ---- the choices and the blank template -------------------------------------------

typology_choices(Level, Orders) :-
    ty_level(Level, Parts),
    findall(O, permutation(Parts, O), Orders).

typology_template(Name) :-
    must_be(atom, Name),
    format("%% The template of ~w. Keep the orders the language uses and~n", [Name]),
    format("%% delete the others; the first one kept is the one written.~n~n", []),
    forall(ty_level(Level, Parts),
           ( format("%% ~w: ~w~n", [Level, Parts]),
             typology_choices(Level, Orders),
             forall(member(O, Orders),
                    format("ty_order(~q, ~q, ~q).~n", [Name, Level, O])),
             nl )),
    forall(ty_row_shape(Shape), format("%% ~w~n", [Shape])).

ty_row_shape('ty_noun(L, Meaning, Gender, Animacy, Singular, Plural).').
ty_row_shape('ty_adjective(L, Meaning, Gender, Number, Word).').
ty_row_shape('ty_verb(L, Meaning, Tense, Number, Polarity, Words).').
ty_row_shape('ty_article(L, Definiteness, Gender, Number, Word).').
ty_row_shape('ty_mark(L, Role, Place, Word, Conditions).').
ty_row_shape('ty_contraction(L, Words, Word).').
ty_row_shape('ty_negation(L, Tense, Number, Words, Form).').
ty_row_shape('ty_ending(L, Feature, From, To).').
ty_row_shape('ty_letters(L, Class, Letters).').
ty_row_shape('ty_before(L, Word, Patterns, Form, Join).').
ty_row_shape('ty_linked(L, Class, NextClass, From, To).').

%% ---- the check ----------------------------------------------------------------------

typology_check(L, Missing) :-
    must_be(atom, L),
    findall(M, ty_missing(L, M), Missing0),
    sort(Missing0, Missing).

ty_missing(L, order(Level)) :-
    ty_level(Level, _),
    \+ ty_order(L, Level, _).
ty_missing(L, not_an_order(Level, Order)) :-
    ty_order(L, Level, Order),
    \+ ( ty_level(Level, Parts), permutation(Parts, Order) ).
ty_missing(L, verb_form(V, T, N, P)) :-
    ty_verb_meaning(L, V),
    ty_values(tense, Ts), member(T, Ts),
    ty_values(number, Ns), member(N, Ns),
    ty_values(polarity, Ps), member(P, Ps),
    \+ ty_verb_form(L, V, T, N, P, _).
ty_missing(L, adjective_form(A, G, N)) :-
    ty_adjective_meaning(L, A),
    ty_gender(L, G),
    ty_values(number, Ns), member(N, Ns),
    \+ ( ty_adjective(L, A, RG, RN, _), ty_fits(RG, G), ty_fits(RN, N) ).
ty_missing(L, bad(ty_verb(L, V, T, N, P, Ws))) :-
    ty_verb(L, V, T, N, P, Ws),
    \+ ( ty_values(tense, Ts), memberchk(T, Ts),
         ty_values(number, Ns), memberchk(N, Ns),
         ty_values(polarity, Ps), memberchk(P, Ps),
         is_list(Ws), Ws \== [] ).
ty_missing(L, bad(ty_noun(L, M, G, A, S, P))) :-
    ty_noun(L, M, G, A, S, P),
    \+ ( ty_values(animacy, As), memberchk(A, As) ).
ty_missing(L, bad(ty_before(L, W, Ps, F, J))) :-
    ty_before(L, W, Ps, F, J),
    \+ ( memberchk(J, [space, joined]), is_list(Ps),
         forall(( member(P, Ps), member(E, P) ),
                ( E == end ; atom_length(E, 1) ; ty_letters(L, E, _) )) ).
ty_missing(L, bad(ty_mark(L, R, Pl, W, Cs))) :-
    ty_mark(L, R, Pl, W, Cs),
    \+ ( ty_values(role, Rs), memberchk(R, Rs),
         ty_values(place, Ps), memberchk(Pl, Ps),
         is_list(Cs) ).

ty_verb_meaning(L, V) :- setof(V0, T^N^P^W^ty_verb(L, V0, T, N, P, W), Vs), member(V, Vs).
ty_adjective_meaning(L, A) :- setof(A0, G^N^W^ty_adjective(L, A0, G, N, W), As), member(A, As).
ty_gender(L, G) :- setof(G0, M^A^S^P^ty_noun(L, M, G0, A, S, P), Gs), member(G, Gs).

%% ---- reading and writing -------------------------------------------------------------

%% Reading takes each word back to the word of the table it may stand for
%% (`an' to `a', `l'avvocato' to `il avvocato' or `la avvocato'), parses
%% those, and keeps a reading only where the writer would write the very
%% words read: `il avvocato' and `a apple' are not read.
typology_read(L, Text, IR) :-
    must_be(atom, L),
    ty_tokens(L, Text, Tokens),
    ty_unsound(L, Tokens, Bases),
    phrase(ty_clause(L, IR), Bases),
    ty_sound(L, Bases, Again),
    Again == Tokens.

typology_write(L, IR, Text) :-
    must_be(atom, L),
    once(phrase(ty_clause(L, IR), Tokens0)),
    ty_sound(L, Tokens0, Tokens1),
    ty_contract(L, Tokens1, Tokens),
    ty_text(Tokens, Text).

typology_translate(From, To, Text, Text2) :-
    once(typology_read(From, Text, IR)),
    typology_write(To, IR, Text2).

%% The words of a sentence: the full stop off, the first word lowered (a
%% script with no capitals is unchanged), each contraction opened.
ty_tokens(L, Text, Tokens) :-
    atom_string(A0, Text),
    ty_unstop(A0, A),
    split_string(A, " ", " ", Parts0),
    exclude(==(""), Parts0, [First0|Rest0]),
    maplist([P, W]>>atom_string(W, P), [First0|Rest0], [FirstA|Rest]),
    downcase_atom(FirstA, First),
    ty_open(L, [First|Rest], Tokens).

%% The text without its full stop.
ty_unstop(A0, A) :-
    (   sub_atom(A0, B, 1, 0, '.') -> sub_atom(A0, 0, B, _, A) ; A = A0 ).

%% ---- forms chosen by the next word's sound -----------------------------------
%%
%% ty_before(L, Word, Patterns, Form, Join): Word is written Form when the
%% next word begins with one of Patterns, the longest pattern of all the
%% word's rows winning (so `a uni...' keeps `a' where `a' + a vowel is
%% `an'). A pattern is a list of letters, ty_letters/3 classes and `end'
%% (the word ends there: `agua' and not `aguacate'). Join `joined' writes
%% the form and the next word as one (`l'avvocato').

ty_sound(_, [], []).
ty_sound(L, [W, N|Ws], Out) :-
    ty_sound_form(L, W, N, F, J), !,
    (   J == joined
    ->  atom_concat(F, N, WN), Out = [WN|Rest], ty_sound(L, Ws, Rest)
    ;   Out = [F|Rest], ty_sound(L, [N|Ws], Rest)
    ).
ty_sound(L, [W|Ws], [W|Rest]) :-
    ty_sound(L, Ws, Rest).

ty_sound_form(L, W, Next, Form, Join) :-
    atom_chars(Next, Cs),
    findall(Len-(F-J), ( ty_before(L, W, Patterns, F, J),
                         member(P, Patterns),
                         ty_pattern(L, P, Cs),
                         length(P, Len) ), Fits),
    Fits \== [],
    keysort(Fits, Sorted),
    last(Sorted, _-(Form-Join)),
    Form \== W.

ty_pattern(_, [], _).
ty_pattern(_, [end], []) :- !.
ty_pattern(L, [E|Es], [C|Cs]) :-
    E \== end,
    (   atom_length(E, 1) -> E == C ; ty_letters(L, E, Ls), memberchk(C, Ls) ),
    ty_pattern(L, Es, Cs).

%% Each word as the word of the table it may stand for: itself, the word
%% whose form it is, or a joined form and the word after it.
ty_unsound(_, [], []).
ty_unsound(L, [T|Ts], Bases) :-
    (   Bases = [T|Bs]
    ;   setof(B, P^ty_before(L, B, P, T, space), Bs0),
        member(B, Bs0), B \== T,
        Bases = [B|Bs]
    ;   setof(B-F, P^ty_before(L, B, P, F, joined), Pairs),
        member(B-F, Pairs), atom_concat(F, Rest, T), Rest \== '',
        Bases = [B, Rest|Bs]
    ),
    ty_unsound(L, Ts, Bs).

ty_open(_, [], []).
ty_open(L, [W|Ws], Out) :-
    (   ty_contraction(L, Parts, W)
    ->  append(Parts, Rest, Out)
    ;   Out = [W|Rest]
    ),
    ty_open(L, Ws, Rest).

ty_contract(_, [], []).
ty_contract(L, [A, B|Ws], [C|Rest]) :-
    ty_contraction(L, [A, B], C), !,
    ty_contract(L, Ws, Rest).
ty_contract(L, [W|Ws], [W|Rest]) :-
    ty_contract(L, Ws, Rest).

ty_text(Tokens, Text) :-
    atomic_list_concat(Tokens, ' ', Body),
    sub_atom(Body, 0, 1, _, F),
    sub_atom(Body, 1, _, 0, R),
    upcase_atom(F, U),
    atomic_list_concat([U, R, '.'], Text).

%% ---- the grammar ---------------------------------------------------------------------

ty_clause(L, C) -->
    { C = clause(_, _, _, _, O),
      ty_order(L, clause, Order0),
      ty_valency(Order0, O, Order) },
    ty_clause_parts(Order, L, C).

%% A clause with no object leaves o out of the order; it is tried first.
ty_valency(Order0, none, Order) :- exclude(==(o), Order0, Order).
ty_valency(Order, O, Order) :- O \== none.

ty_clause_parts([], _, _) --> [].
ty_clause_parts([P|Ps], L, C) --> ty_clause_part(P, L, C), ty_clause_parts(Ps, L, C).

ty_clause_part(s, L, clause(_, _, _, S, _)) --> ty_role(L, s, S).
ty_clause_part(o, L, clause(_, _, _, _, O)) --> ty_role(L, o, O).
ty_clause_part(v, L, clause(V, T, P, np(_, N, _, _), _)) -->
    ty_verb_words(L, V, T, N, P).

%% Reading, the words are taken first and looked up (one to four of them),
%% so a table of thousands of verbs is asked by the words read; writing,
%% the form is looked up by its meaning and its words written.
ty_verb_words(L, V, T, N, P, S0, S) :-
    (   nonvar(S0)
    ->  between(1, 4, K), length(Words, K), append(Words, S, S0),
        ty_verb_form(L, V, T, N, P, Words)
    ;   ty_verb_form(L, V, T, N, P, Words),
        append(Words, S, S0)
    ).

%% A form the template lists, or a negative its negation rule makes from a
%% positive form it lists.
ty_verb_form(L, V, T, N, P, Words) :-
    ty_verb(L, V, T, N, P, Words).
ty_verb_form(L, V, T, N, neg, Words) :-
    ty_negation(L, T0, N0, Neg, Form),
    append(Neg, Pos, Words),
    ( Form == same -> T1 = T, N1 = N ; Form = form(T1, N1) ),
    ty_verb(L, V, T1, N1, pos, Pos),
    ty_values(tense, Ts), member(T, Ts), ty_fits(T0, T),
    ty_values(number, Ns), member(N, Ns), ty_fits(N0, N),
    \+ ty_verb(L, V, T, N, neg, _).

%% A role's phrase, with the marks the template puts before or after it.
ty_role(L, Role, NP) -->
    ty_mark_slot(L, Role, before, Before),
    ty_np(L, NP, Features),
    ty_mark_slot(L, Role, after, After),
    { ty_marks_needed(L, Role, before, Features, Before),
      ty_marks_needed(L, Role, after, Features, After) }.

ty_mark_slot(L, Role, Place, [W]) --> [W], { ty_mark(L, Role, Place, W, _) }.
ty_mark_slot(_, _, _, []) --> [].

ty_marks_needed(L, Role, Place, Features, Marks) :-
    findall(W, ( ty_mark(L, Role, Place, W, Alternatives),
                 member(Need, Alternatives),
                 subset(Need, Features) ), Marks0),
    sort(Marks0, Marks).

%% A noun phrase: its parts in an order the template keeps, then the check
%% that the article and the adjectives agree with the noun.
ty_np(L, NP, [Def, N, Anim]) -->
    { NP = np(_, N, Def, _),
      ty_order(L, np, Order) },
    ty_np_parts(Order, L, NP, got(Det, Noun, Adjs)),
    { ty_np_ok(L, NP, Det, Noun, Adjs, Anim) }.

ty_np_parts([], _, _, _) --> [].
ty_np_parts([P|Ps], L, NP, Got) --> ty_np_part(P, Ps, L, NP, Got), ty_np_parts(Ps, L, NP, Got).

%% Each part knows the parts after it: a noun right before the adjectives
%% takes its linked form (the Persian ezafe), and so does each adjective
%% before another.
ty_np_part(d, _, L, _, got(Det, _, _)) --> ty_det(L, Det).
ty_np_part(n, Ps, L, np(M, N, _, As), got(_, noun(G, A), _)) -->
    [W],
    { ty_linked_here(Ps, As, Linked),
      ty_linked_word(L, n, a, Linked, W0, W, ty_noun_form(L, M, G, A, N, W0)) }.
ty_np_part(a, _, L, np(_, _, _, As), got(_, _, Rows)) --> ty_adjs(L, As, Rows).

ty_linked_here([a|_], As, Linked) :- !, ( As = [_|_], Linked = yes ; As = [], Linked = no ).
ty_linked_here(_, _, no).

%% Reading the word is bound and the table is asked by it; writing, by the
%% meaning.
ty_noun_form(L, M, G, A, sg, W) :- ty_noun(L, M, G, A, W, _).
ty_noun_form(L, M, G, A, pl, W) :- ty_noun(L, M, G, A, _, W).

ty_det(L, art(W)) --> [W], { ty_article(L, _, _, _, W) }.
ty_det(_, none) --> [].

ty_adjs(_, [], []) --> [].
ty_adjs(L, [A|As], [adj(G, N)|Rows]) -->
    [W],
    { ( As = [_|_], Linked = yes ; As = [], Linked = no ),
      ty_linked_word(L, a, a, Linked, W0, W, ty_adjective(L, A, G, N, W0)) },
    ty_adjs(L, As, Rows).

%% The word W0 of the table, written W: itself, or its linked form when a
%% word of class C2 follows it. Lookup finds W0; reading it runs after W0 is
%% taken back from W, writing before W is made from it.
ty_linked_word(_, _, _, no, W, W, Lookup) :- !, call(Lookup).
ty_linked_word(L, C1, C2, yes, W0, W, Lookup) :-
    (   nonvar(W)
    ->  ty_unlinked(L, C1, C2, W, W0), call(Lookup), ty_link_form(L, C1, C2, W0, W1), W1 == W
    ;   call(Lookup), ty_link_form(L, C1, C2, W0, W)
    ).

%% The linked form: the longest ending a ty_linked/5 row names, replaced;
%% a word no row fits is unchanged (the ezafe is not written after a
%% consonant).
ty_link_form(L, C1, C2, W0, W) :-
    findall(Len-(From-To), ( ty_linked(L, C1, C2, From, To),
                             atom_concat(_, From, W0),
                             atom_length(From, Len) ), Fits),
    (   Fits == []
    ->  W = W0
    ;   keysort(Fits, Sorted), last(Sorted, _-(From-To)),
        atom_concat(Stem, From, W0), atom_concat(Stem, To, W)
    ).

ty_unlinked(_, _, _, W, W).
ty_unlinked(L, C1, C2, W, W0) :-
    ty_linked(L, C1, C2, From, To),
    atom_concat(Stem, To, W),
    atom_concat(Stem, From, W0),
    W0 \== W.

ty_np_ok(L, np(_, N, Def, _), Det, noun(G, Anim), Rows, Anim) :-
    ty_values(definiteness, Defs), member(Def, Defs),
    forall(member(adj(RG, RN), Rows), ( ty_fits(RG, G), ty_fits(RN, N) )),
    (   Det = art(W)
    ->  ty_article(L, Def, AG, AN, W), ty_fits(AG, G), ty_fits(AN, N)
    ;   \+ ( ty_article(L, Def, AG, AN, _), ty_fits(AG, G), ty_fits(AN, N) )
    ).

ty_fits(any, _) :- !.
ty_fits(X, X).

%% ---- the word tables from corpus/vocabulary ---------------------------------------
%%
%% A vocabulary file is lesson lines of a few fixed shapes, read here by
%% their shape and not by the grammar, so 160 000 lines take seconds:
%%
%%     The masculine noun "perro" means "dog".      (feminine, or no gender)
%%     The feminine adjective "negra" means "black".
%%     The verb "ve" means "sees".                  (the third person)
%%     "perros" is the plural of "perro".           (a verb's too: "ven")
%%     "vio" is the past of "ve".                   ("vieron" of "ven")
%%     "perro" is animate.   "niño" is a person.   "casa" is feminine.
%%
%% Only complete entries are written, and only single words; a row the hand
%% template has already (its meaning and its word) is not written again.
%%
%% A FORM BELONGS TO THE CLASS OF THE ENTRY ITS LINE FOLLOWS. The file puts
%% each entry's forms right after it, and one spelling can be two words:
%% `fría' is an adjective whose plural is `frías', and a form of `freír'
%% whose plural is `frían'. So a form line is kept with the class of the
%% last entry line (tyi_form(Kind, Form, Of, Class)), and a noun's plural is
%% asked of the nouns' blocks alone.

:- dynamic tyi_entry/4, tyi_form/4, tyi_animate/1, tyi_gender/2, tyi_count/2,
           tyi_hand/1.

typology_import(Name) :-
    must_be(atom, Name),
    ty_dir(Dir),
    atomic_list_concat([Dir, '/templates/', Name, '-words.pl'], File),
    typology_import(Name, File).

%% The hand template's rows are READ from its file, not asked of the
%% knowledge base, so what is loaded (a words file, an earlier import)
%% changes nothing in what is written.
typology_import(Name, File) :-
    must_be(atom, Name),
    ty_import_reset,
    ty_hand_rows(Name, Hand),
    forall(member(H, Hand), assertz(tyi_hand(H))),
    (   Name == english
    ->  findall(V, ( member(Src, [spanish, italian]), ty_vocabulary_file(Src, V) ), Vs),
        Vs \== [],
        forall(member(V, Vs), ty_read_vocabulary(V)),
        findall(R, ty_english_row(R), Rows0)
    ;   ty_vocabulary_file(Name, V),
        ty_read_vocabulary(V),
        findall(R, ty_import_row(Name, R), Rows0)
    ),
    ty_dedupe(Rows0, Rows),
    length(Rows, NRows),
    with_output_to(codes(Codes), ty_write_rows(Name, Rows)),
    write_file_from_codes(File, Codes),
    format("~w: ~w rows into ~w~n", [Name, NRows, File]),
    forall(tyi_count(What, N), format("  ~w: ~w~n", [What, N])),
    ty_import_reset.

%% The rows once each, in the vocabulary's order: a word's first meaning
%% there is the first it is read as.
ty_dedupe(Rows0, Rows) :-
    findall(R-I, nth1(I, Rows0, R), Pairs0),
    msort(Pairs0, Pairs1),
    ty_first_of_each(Pairs1, Firsts),
    findall(I-R, member(R-I, Firsts), ByPlace0),
    keysort(ByPlace0, ByPlace),
    findall(R, member(_-R, ByPlace), Rows).

ty_first_of_each([], []).
ty_first_of_each([R-I|Ps], [R-I|Fs]) :-
    ty_skip_same(R, Ps, Rest),
    ty_first_of_each(Rest, Fs).

ty_skip_same(R, [R1-_|Ps], Rest) :- R1 == R, !, ty_skip_same(R, Ps, Rest).
ty_skip_same(_, Ps, Ps).

ty_dir(Dir) :-
    absolute_file_name(library(reasoning/typology), F, [file_type(prolog), access(read)]),
    file_directory_name(F, Dir).

ty_vocabulary_file(Name, File) :-
    atomic_list_concat(['corpus/vocabulary/', Name, '.txt'], Rel),
    catch(absolute_file_name(library(reasoning/Rel), File, [access(read)]), _, fail).

ty_hand_rows(Name, Rows) :-
    ty_file(Name, File),
    use_module(library(stream)),
    setup_call_cleanup(open(File, read, S), ty_read_terms(S, Rows), close(S)).

ty_read_terms(S, Ts) :-
    read_term(S, T, []),
    (   T == end_of_file -> Ts = [] ; Ts = [T|Ts1], ty_read_terms(S, Ts1) ).

ty_import_reset :-
    retractall(tyi_entry(_, _, _, _)), retractall(tyi_form(_, _, _, _)),
    retractall(tyi_animate(_)), retractall(tyi_gender(_, _)),
    retractall(tyi_count(_, _)), retractall(tyi_hand(_)).

ty_count(What) :-
    (   retract(tyi_count(What, N0)) -> N is N0 + 1 ; N = 1 ),
    assertz(tyi_count(What, N)).

ty_read_vocabulary(File) :-
    read_file_to_codes(File, Codes),
    split_string(Codes, "\n", "", Lines),
    nb_setval('$ty_block', none),
    forall(member(S, Lines), ( atom_string(Line, S), ty_vocabulary_line(Line) )).

ty_vocabulary_line(Line) :-
    atomic_list_concat(Parts, '"', Line),
    (   Parts = [Head, W, ' means ', M, '.'], ty_entry_head(Head, Class, G)
    ->  assertz(tyi_entry(Class, G, W, M)),
        nb_setval('$ty_block', Class)
    ;   Parts = ['', A, Rel, B, '.'], ty_form_relation(Rel, Kind)
    ->  nb_getval('$ty_block', Class),
        assertz(tyi_form(Kind, A, B, Class))
    ;   Parts = ['', W, Says], ty_says(Says, Fact, W)
    ->  assertz(Fact)
    ;   true
    ).

ty_entry_head('The masculine noun ', noun, m).
ty_entry_head('The feminine noun ', noun, f).
ty_entry_head('The noun ', noun, none).
ty_entry_head('The masculine adjective ', adjective, m).
ty_entry_head('The feminine adjective ', adjective, f).
ty_entry_head('The adjective ', adjective, none).
ty_entry_head('The verb ', verb, none).

ty_form_relation(' is the plural of ', plural).
ty_form_relation(' is the past of ', past).

ty_says(' is animate.', tyi_animate(W), W).
ty_says(' is a person.', tyi_animate(W), W).
ty_says(' is feminine.', tyi_gender(W, f), W).
ty_says(' is not feminine.', tyi_gender(W, m), W).

ty_single(W) :- \+ sub_atom(W, _, _, _, ' ').

ty_once_form(Kind, Class, Of, Form) :- once(( tyi_form(Kind, Form, Of, Class), ty_single(Form) )).

%% The rows of a language that has a vocabulary.
ty_import_row(L, ty_noun(L, M, G, Anim, W, P)) :-
    tyi_entry(noun, G0, W, M),
    (   ty_single(W), ty_single(M) -> true ; ty_count(noun_not_a_single_word), fail ),
    (   G0 \== none -> G = G0
    ;   once(tyi_gender(W, G)) -> true
    ;   ty_count(noun_with_no_gender), fail
    ),
    (   ty_once_form(plural, noun, W, P) -> true ; ty_count(noun_with_no_plural), fail ),
    (   tyi_animate(W) -> Anim = animate ; Anim = unknown ),
    (   tyi_hand(ty_noun(L, M, _, _, W, _)) -> ty_count(noun_in_the_hand_template), fail ; true ).
ty_import_row(L, ty_adjective(L, M, G, N, W)) :-
    setof(M0, G0^W0^tyi_entry(adjective, G0, W0, M0), Ms),
    member(M, Ms),
    ty_single(M),
    findall(R, ty_adjective_form(M, R), Forms),
    (   ty_adjective_complete(Forms) -> true ; ty_count(adjective_meaning_incomplete), fail ),
    member(form(G, N, W), Forms),
    \+ tyi_hand(ty_adjective(L, M, _, _, W)).
ty_import_row(L, ty_verb(L, B, T, N, pos, [W])) :-
    tyi_entry(verb, _, W3, M3),
    (   ty_single(W3), ty_single(M3) -> true ; ty_count(verb_not_a_single_word), fail ),
    (   ty_once_form(plural, verb, W3, W3p), ty_once_form(past, verb, W3, Wp),
        ty_once_form(past, verb, W3p, Wpp)
    ->  true
    ;   ty_count(verb_with_a_form_missing), fail
    ),
    reason_base(M3, B),
    (   tyi_hand(ty_verb(L, B, present, sg, pos, [W3])) -> ty_count(verb_in_the_hand_template), fail ; true ),
    member(T-N-W, [present-sg-W3, present-pl-W3p, past-sg-Wp, past-pl-Wpp]).

%% An adjective's forms: a word with no gender stands for both, and each
%% word needs its plural.
ty_adjective_form(M, form(G, N, W)) :-
    tyi_entry(adjective, G0, W0, M),
    ty_single(W0),
    ty_once_form(plural, adjective, W0, P),
    ( G0 == none -> G = any ; G = G0 ),
    member(N-W, [sg-W0, pl-P]).

ty_adjective_complete(Forms) :-
    forall(( member(G, [m, f]), member(N, [sg, pl]) ),
           ( member(form(G1, N, _), Forms), ( G1 == any ; G1 == G ) )).

%% English: a row for every meaning the vocabularies give, its forms by the
%% reason library (the base of a third person) and by the English
%% template's endings, and a past the vocabulary states where it states one
%% (`"saw" is the past of "sees"').
ty_english_row(ty_noun(english, M, none, Anim, M, P)) :-
    setof(M0, G^W^tyi_entry(noun, G, W, M0), Ms),
    member(M, Ms),
    ty_single(M),
    \+ tyi_hand(ty_noun(english, M, _, _, _, _)),
    ty_apply_ending(english, plural, M, P),
    (   tyi_entry(noun, _, W, M), tyi_animate(W) -> Anim = animate ; Anim = unknown ).
ty_english_row(ty_adjective(english, M, any, any, M)) :-
    setof(M0, G^W^tyi_entry(adjective, G, W, M0), Ms),
    member(M, Ms),
    ty_single(M),
    \+ tyi_hand(ty_adjective(english, M, _, _, _)).
ty_english_row(ty_verb(english, B, T, N, pos, [W])) :-
    setof(M3, G^W3^tyi_entry(verb, G, W3, M3), M3s),
    member(M3, M3s),
    ty_single(M3),
    reason_base(M3, B),
    \+ tyi_hand(ty_verb(english, B, _, _, _, _)),
    (   tyi_form(past, P0, M3, verb), \+ tyi_entry(verb, _, M3, _), ty_single(P0)
    ->  P = P0
    ;   ty_apply_ending(english, past, B, P)
    ),
    member(T-N-W, [present-sg-M3, present-pl-B, past-sg-P, past-pl-P]).

%% The form the hand template's ending rule makes: the longest From that
%% fits.
ty_apply_ending(L, Feature, Word, Form) :-
    findall(Len-(From-To), ( tyi_hand(ty_ending(L, Feature, From, To)),
                             atom_concat(_, From, Word),
                             atom_length(From, Len) ), Fits),
    keysort(Fits, Sorted),
    last(Sorted, _-(From-To)),
    atom_concat(Stem, From, Word),
    atom_concat(Stem, To, Form).

ty_write_rows(L, Rows) :-
    format("%% templates/~w-words.pl -- GENERATED by typology_import(~w) from~n", [L, L]),
    format("%% corpus/vocabulary/. Do not edit: edit templates/~w.pl, whose rows~n", [L]),
    format("%% win, and import again.~n~n", []),
    forall(member(R, Rows), portray_clause(R)).
