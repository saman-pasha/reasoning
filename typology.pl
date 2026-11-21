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
%%                                     ...), or none; Animacy: animate or
%%                                     inanimate
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
%%     typology_load(+Name)            consult templates/Name.pl
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
%% NOT YET (each is a slot to add, not a change to the grammar): a/an and
%% Italian il/lo, which choose a form by the sound after them; a
%% Persian ezafe that is written (it is unwritten after a consonant, and
%% the nouns here end in one); prepositions, adverbs, questions,
%% relative clauses, persons other than the third, more tenses; a
%% language written without spaces; reading the lexicon from
%% corpus/vocabulary/.

:- module(typology, [ typology_load/1, typology_languages/1, typology_choices/2,
                      typology_template/1, typology_check/2, typology_read/3,
                      typology_write/3, typology_translate/4 ]).

:- dynamic ty_order/3, ty_noun/6, ty_adjective/5, ty_verb/6, ty_article/5,
           ty_mark/5, ty_contraction/3.
:- discontiguous ty_order/3, ty_noun/6, ty_adjective/5, ty_verb/6,
                 ty_article/5, ty_mark/5, ty_contraction/3.

%% ---- the levels and the values a slot takes -----------------------------------

ty_level(clause, [s, v, o]).
ty_level(np, [d, a, n]).

ty_values(tense, [present, past]).
ty_values(number, [sg, pl]).
ty_values(polarity, [pos, neg]).
ty_values(definiteness, [def, indef]).
ty_values(animacy, [animate, inanimate]).
ty_values(place, [before, after]).
ty_values(role, [s, o]).

%% ---- loading --------------------------------------------------------------------

typology_load(Name) :-
    must_be(atom, Name),
    consult(library(reasoning/templates/Name)).

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
    \+ ty_verb(L, V, T, N, P, _).
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
ty_missing(L, bad(ty_mark(L, R, Pl, W, Cs))) :-
    ty_mark(L, R, Pl, W, Cs),
    \+ ( ty_values(role, Rs), memberchk(R, Rs),
         ty_values(place, Ps), memberchk(Pl, Ps),
         is_list(Cs) ).

ty_verb_meaning(L, V) :- setof(V0, T^N^P^W^ty_verb(L, V0, T, N, P, W), Vs), member(V, Vs).
ty_adjective_meaning(L, A) :- setof(A0, G^N^W^ty_adjective(L, A0, G, N, W), As), member(A, As).
ty_gender(L, G) :- setof(G0, M^A^S^P^ty_noun(L, M, G0, A, S, P), Gs), member(G, Gs).

%% ---- reading and writing -------------------------------------------------------------

typology_read(L, Text, IR) :-
    must_be(atom, L),
    ty_tokens(L, Text, Tokens),
    phrase(ty_clause(L, IR), Tokens).

typology_write(L, IR, Text) :-
    must_be(atom, L),
    once(phrase(ty_clause(L, IR), Tokens0)),
    ty_contract(L, Tokens0, Tokens),
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
    { ty_verb(L, V, T, N, P, Words) },
    ty_seq(Words).

ty_seq([]) --> [].
ty_seq([W|Ws]) --> [W], ty_seq(Ws).

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
ty_np_parts([P|Ps], L, NP, Got) --> ty_np_part(P, L, NP, Got), ty_np_parts(Ps, L, NP, Got).

ty_np_part(d, L, _, got(Det, _, _)) --> ty_det(L, Det).
ty_np_part(n, L, np(M, N, _, _), got(_, noun(G, A), _)) -->
    [W],
    { ty_noun(L, M, G, A, Sg, Pl),
      ( N = sg, W = Sg ; N = pl, W = Pl ) }.
ty_np_part(a, L, np(_, _, _, As), got(_, _, Rows)) --> ty_adjs(L, As, Rows).

ty_det(L, art(W)) --> [W], { ty_article(L, _, _, _, W) }.
ty_det(_, none) --> [].

ty_adjs(_, [], []) --> [].
ty_adjs(L, [A|As], [adj(G, N)|Rows]) -->
    [W], { ty_adjective(L, A, G, N, W) },
    ty_adjs(L, As, Rows).

ty_np_ok(L, np(_, N, Def, _), Det, noun(G, Anim), Rows, Anim) :-
    ty_values(definiteness, Defs), member(Def, Defs),
    forall(member(adj(RG, RN), Rows), ( ty_fits(RG, G), ty_fits(RN, N) )),
    (   Det = art(W)
    ->  ty_article(L, Def, AG, AN, W), ty_fits(AG, G), ty_fits(AN, N)
    ;   \+ ( ty_article(L, Def, AG, AN, _), ty_fits(AG, G), ty_fits(AN, N) )
    ).

ty_fits(any, _) :- !.
ty_fits(X, X).
