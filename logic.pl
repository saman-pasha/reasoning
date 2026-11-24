%% library(reasoning/logic) -- level 2 of the translator (TRANSLATOR-PLAN.md):
%% a logic form made by rules from the typology IR, the same for every
%% language, because the typology IR is.
%%
%% THE LOGIC FORM:
%%
%%     utterance(Intent, Items)    Intent assertion or question; Items a
%%                                 list of fact/1, rule/2 and query/1
%%     fact(Atom)                  a statement with no condition
%%     rule(Atom, Body)            a conclusion and its conditions
%%     query(Body)                 a question
%%     pred(Name, Args)            an atom of the logic: Name a meaning
%%                                 (the English word), Args terms
%%     and(Bodies)                 conditions that must all hold
%%     const(Name)                 a constant: a name (socrates), a
%%                                 definite noun phrase (the_dog), a bare
%%                                 noun (music), one individual (a_person)
%%     var(N)                      a variable, numbered from 1 by its first
%%                                 use in its item
%%     num(N), str(S), list(Terms), fun(Name, Args)
%%                                 a number, a string, a list (since
%%                                 1.68.0) and a compound term of Cocolog
%%
%% WHAT A NOUN PHRASE IS. A name, a definite noun phrase and a bare noun
%% are constants. `every', `each' and `all' make a variable whose noun is a
%% condition of each rule; an indefinite subject (`A person likes music.',
%% `Dogs sleep.') is generic: a rule first, and one individual's facts
%% second (a_person). `something' and `someone' are one individual
%% (something), except in a conditional, where they are the rule's variable.
%% A question word is the query's variable. A pronoun of an if clause
%% stands for its main clause's subject.
%%
%% WHAT HAS NO LOGIC FORM YET: a tense other than the present, a negation,
%% an adjunct, an object that is no constant, `when' and `because', a
%% pronoun outside an if clause, `no' and `nothing', and a determiner
%% other than the ones above. logic_why/2 names the first reason.
%%
%% WHAT IS PUBLIC:
%%
%%     logic_from_ir(+IR, -Utterance)  a typology IR's logic forms, each
%%                                     reading on backtracking
%%     logic_read(+Lang, +Text, -Utterance)
%%                                     typology_read/3, then logic_from_ir/2
%%     logic_readings(+Lang, +Text, -Utterances)
%%                                     every distinct logic form of a text,
%%                                     in the order read (two senses of a
%%                                     word, or a name and a bare noun,
%%                                     give one form twice)
%%     logic_why(+IR, -Why)            why an IR has no logic form:
%%                                     tense(T), negation, adjunct,
%%                                     object(Q), subordinate(K), pronoun,
%%                                     determiner(D), predicate(P),
%%                                     shape(IR)
%%     cocolog_write(+Utterance, -Text)
%%                                     the logic form as Cocolog source
%%                                     (since 1.67.0)
%%     cocolog_read(+Text, -Utterance) Cocolog source's logic form
%%     logic_translate(+From, +To, +Text, -Text2)
%%                                     a natural language's text into
%%                                     Cocolog (To cocolog), or Cocolog
%%                                     into a natural language (From
%%                                     cocolog, since 1.68.0)
%%     logic_write(+Lang, +Utterance, -Text)
%%                                     the logic form said in Lang, each
%%                                     sentence one that reads back to its
%%                                     items, else a general sentence
%%                                     (since 1.68.0)

:- module(logic, [logic_from_ir/2, logic_read/3, logic_readings/3, logic_why/2,
                  cocolog_write/2, cocolog_read/2, logic_translate/4, logic_write/3,
                  logic_measure/3, logic_measure_cases/2]).

:- use_module(library(reasoning/typology)).

logic_read(L, Text, U) :-
    typology_read(L, Text, IR),
    logic_from_ir(IR, U).

logic_readings(L, Text, Us) :-
    findall(U, logic_read(L, Text, U), Us0),
    lg_distinct(Us0, Us).

lg_distinct([], []).
lg_distinct([U|Us], [U|Ds]) :-
    exclude(==(U), Us, Rest),
    lg_distinct(Rest, Ds).

logic_from_ir(IR, utterance(Intent, Items)) :-
    catch(lg_utterance(IR, Intent, Items0), lg_no(_), fail),
    maplist(lg_number, Items0, Items).

logic_why(IR, Why) :-
    catch(( lg_utterance(IR, _, _) -> fail ; Why = shape(IR) ), lg_no(Why), true).

lg_no(Why) :- throw(lg_no(Why)).

%% ---- utterances ----------------------------------------------------------------

lg_utterance(question(C), question, [query(B)]) :- !,
    lg_parts(C, S, Pred),
    lg_entity(S, ent(T, Conds, Q)),
    ( memberchk(Q, [const, wh]) -> true ; lg_no(determiner(Q)) ),
    lg_atoms(C, T, Pred, Atoms),
    append(Atoms, Conds, Bs),
    lg_body(Bs, B).
lg_utterance(IR, assertion, Items) :-
    lg_statement(IR, Items).

lg_statement(C, Items) :-
    nonvar(C), C =.. [K, [C1, C2]], memberchk(K, [and, but]), !,
    lg_statement(C1, Items1),
    lg_same(C2, C1, C2a),
    lg_statement(C2a, Items2),
    append(Items1, Items2, Items).
lg_statement(C, Items) :-
    lg_joined(C, Cs), !,
    lg_statements(Cs, Items).
lg_statement(sub(K, Main, Cond), Items) :- !,
    ( K == if -> true ; lg_no(subordinate(K)) ),
    lg_conditional(Main, Cond, Items).
lg_statement(C, Items) :-
    lg_parts(C, S, Pred),
    lg_entity(S, E),
    E = ent(T, Conds, Q),
    lg_atoms(C, T, Pred, Atoms),
    lg_assert(Q, T, Conds, Atoms, S, Items).

%% A clause of a joined subject or object (`John and Mary sleep.') is a
%% clause of each item.
lg_joined(C, Cs) :-
    lg_subject(C, S), nonvar(S), S = and(Xs), !,
    findall(C1, ( member(X, Xs), lg_set_subject(C, X, C1) ), Cs).
lg_joined(C, Cs) :-
    lg_object(C, O), nonvar(O), O = and(Xs), !,
    findall(C1, ( member(X, Xs), lg_set_object(C, X, C1) ), Cs).

lg_statements([], []).
lg_statements([C|Cs], Items) :-
    lg_statement(C, Items1), lg_statements(Cs, Items2), append(Items1, Items2, Items).

lg_object(clause(_, _, _, _, O), O).
lg_object(clause(_, _, _, _, O, _), O).

lg_set_object(clause(V, T, P, S, _), O, clause(V, T, P, S, O)).
lg_set_object(clause(V, T, P, S, _, J), O, clause(V, T, P, S, O, J)).

%% The second clause of a coordination that says no subject (same) has the
%% first clause's.
lg_same(C2, C1, C2a) :-
    (   lg_subject(C2, S2), S2 == same
    ->  lg_subject(C1, S1), lg_set_subject(C2, S1, C2a)
    ;   C2a = C2
    ).

lg_subject(clause(_, _, _, S, _), S).
lg_subject(clause(_, _, _, S, _, _), S).
lg_subject(copula(_, _, S, _), S).

lg_set_subject(clause(V, T, P, _, O), S, clause(V, T, P, S, O)).
lg_set_subject(clause(V, T, P, _, O, J), S, clause(V, T, P, S, O, J)).
lg_set_subject(copula(T, P, _, Pr), S, copula(T, P, S, Pr)).

%% A statement of a constant is its facts; of every, each or all its rules;
%% of a generic indefinite its rules first and one individual's facts
%% second; of something or someone one individual's facts.
lg_assert(const, _, [], Atoms, _, Items) :- !,
    findall(fact(A), member(A, Atoms), Items).
lg_assert(every, T, Conds, Atoms, _, Items) :- !,
    lg_rules(Atoms, T, Conds, Items).
lg_assert(generic, T, Conds, Atoms, S, Items) :- !,
    (   lg_rules(Atoms, T, Conds, Items)
    ;   lg_individual(S, T), lg_facts(Conds, Atoms, Items)
    ).
lg_assert(some, T, Conds, Atoms, S, Items) :- !,
    lg_individual(S, T), lg_facts(Conds, Atoms, Items).
lg_assert(Q, _, _, _, _, _) :- lg_no(determiner(Q)).

lg_rules(Atoms, T, Conds, Items) :-
    findall(R, ( member(A, Atoms), lg_rule(A, T, Conds, R) ), Items).

%% A rule whose conclusion is its only condition says nothing new; a rule
%% with no condition is a fact of a variable (`Everything is mortal.').
lg_rule(A, _, [], fact(A)) :- !.
lg_rule(A, _, Conds, rule(A, B)) :- lg_body(Conds, B).

lg_facts(Conds, Atoms, Items) :-
    append(Conds, Atoms, As),
    findall(fact(A), member(A, As), Items).

lg_body([B], B) :- !.
lg_body(Bs, and(Bs)).

%% One individual: a_person for a person, something and someone.
lg_individual(np(N, _, _, _), const(C)) :- !, atom_concat(a_, N, C).
lg_individual(qp(_, thing), const(something)) :- !.
lg_individual(qp(_, person), const(someone)) :- !.
lg_individual(S, _) :- lg_no(determiner(S)).

%% IF: the conditional's conclusions are its main clause's atoms; its
%% conditions the main subject's own (person(X)), then the if clause's
%% atoms and their conditions. A pronoun subject of the if clause stands
%% for the main clause's subject; something and someone are the variable.
lg_conditional(Main, Cond, Items) :-
    lg_parts(Main, S, Pred),
    lg_entity(S, ent(T, Conds, _)),
    lg_atoms(Main, T, Pred, Atoms),
    lg_parts(Cond, S2, Pred2),
    (   nonvar(S2), S2 = pron(3, _, _) -> T2 = T, Conds2 = []
    ;   lg_entity(S2, ent(T2, Conds2, Q2)), ( Q2 == const -> true ; lg_no(determiner(Q2)) )
    ),
    lg_atoms(Cond, T2, Pred2, Atoms2),
    append([Conds, Conds2, Atoms2], Body),
    findall(R, ( member(A, Atoms), lg_rule(A, T, Body, R) ), Items).

%% ---- a clause's parts ---------------------------------------------------------------

lg_parts(C, _, _) :- var(C), !, lg_no(shape(C)).
lg_parts(copula(T, P, S, Pred), S, Pred) :- !, lg_present(T, P).
lg_parts(clause(V, T, P, S, O), S, verb(V, O)) :- !, lg_present(T, P).
lg_parts(clause(V, T, P, S, O, Js), S, verb(V, O)) :- !,
    lg_present(T, P),
    ( Js == [] -> true ; lg_no(adjunct) ).
lg_parts(C, _, _) :- lg_no(shape(C)).

lg_present(T, P) :-
    ( T == present -> true ; lg_no(tense(T)) ),
    ( P == pos -> true ; lg_no(negation) ).

%% The atoms a clause says of its subject's term T; an object is a
%% constant.
lg_atoms(copula(_, _, _, _), T, adj(As), Atoms) :- !,
    lg_adjectives(As, Ms),
    lg_preds_of(Ms, T, Atoms).
lg_atoms(copula(_, _, _, _), T, np(N, _, D, As), Atoms) :-
    memberchk(D, [indef, mass]), !,
    lg_adjectives(As, Ms),
    lg_preds_of([N|Ms], T, Atoms).
lg_atoms(copula(_, _, _, _), _, Pred, _) :- !, lg_no(predicate(Pred)).
lg_atoms(_, T, verb(V, none), [pred(V, [T])]) :- !.
lg_atoms(_, T, verb(V, O), [pred(V, [T, To])]) :-
    lg_entity(O, ent(To, _, Q)),
    ( Q == const -> true ; lg_no(object(Q)) ).

%% The adjectives of a phrase, a joined pair's items each.
lg_adjectives(As, Ms) :-
    findall(M, ( member(A, As), lg_adjective(A, M) ), Ms).

lg_adjective(A, M) :-
    (   atom(A) -> M = A
    ;   nonvar(A), A = and(Bs) -> member(M, Bs)
    ;   lg_no(predicate(adj(A)))
    ).

%% ---- noun phrases ---------------------------------------------------------------

lg_entity(X, _) :- var(X), !, lg_no(shape(X)).
lg_entity(name(N), ent(const(C), [], const)) :- !, lg_name_atom(N, C).
lg_entity(np(N, sg, def, As), ent(const(C), [], const)) :- !,
    lg_adjectives(As, Ms), append([the|Ms], [N], Ws), atomic_list_concat(Ws, '_', C).
lg_entity(np(N, _, mass, As), ent(const(C), [], const)) :- !,
    lg_adjectives(As, Ms), append(Ms, [N], Ws), atomic_list_concat(Ws, '_', C).
lg_entity(np(N, _, D, As), ent(V, Conds, every)) :- memberchk(D, [every, each, all]), !,
    lg_noun_conds(N, As, V, Conds).
lg_entity(np(N, _, D, As), ent(V, Conds, generic)) :- D == indef, !,
    lg_noun_conds(N, As, V, Conds).
lg_entity(np(N, _, some, As), ent(V, Conds, some)) :- !,
    lg_noun_conds(N, As, V, Conds).
lg_entity(qp(every, _), ent(_, [], every)) :- !.
lg_entity(qp(some, _), ent(_, [], some)) :- !.
lg_entity(wh(_), ent(_, [], wh)) :- !.
lg_entity(pron(_, _, _), _) :- !, lg_no(pronoun).
lg_entity(np(_, _, D, _), _) :- !, lg_no(determiner(D)).
lg_entity(qp(Q, _), _) :- !, lg_no(determiner(Q)).
lg_entity(X, _) :- lg_no(shape(X)).

lg_noun_conds(N, As, V, Cs) :-
    lg_adjectives(As, Ms),
    lg_preds_of([N|Ms], V, Cs).

%% The atoms of meanings said of one term; never by findall/3, which would
%% copy the term apart from the rule's other atoms.
lg_preds_of([], _, []).
lg_preds_of([M|Ms], T, [pred(M, [T])|Ps]) :- lg_preds_of(Ms, T, Ps).

%% A name's constant: its words lowered, joined by `_' (`John Smith' is
%% john_smith).
lg_name_atom(N, C) :-
    downcase_atom(N, D),
    atomic_list_concat(Ws, ' ', D),
    atomic_list_concat(Ws, '_', C).

%% ---- variables ------------------------------------------------------------------

%% An item's variables, var(1), var(2), ... by their first use.
lg_number(Item0, Item) :-
    copy_term(Item0, Item),
    term_variables(Item, Vs),
    lg_bind(Vs, 1).

lg_bind([], _).
lg_bind([var(N)|Vs], N) :- N1 is N + 1, lg_bind(Vs, N1).

%% ---- Cocolog (since 1.67.0) -------------------------------------------------------
%%
%% THE COCOLOG TEMPLATE (templates/cocolog.pl, read once) writes the logic
%% form as Cocolog source and reads it back. A fact is a clause with no
%% body, a rule `Head :- Body', a query `?- Body.'; and/1 is `,', a const/1
%% an atom, a var/1 a variable (A, B, ... as portray_clause/1 names them).
%% A predicate the system defines (sleep/1, member/2) is written with the
%% template's prefix (is_sleep/1) and read back without it.

:- dynamic lg_code/1, lg_code_reserved_prefix/2, lg_code_name/3, lg_code_query_mark/2,
           lg_code_class/3, '$lg_lex'/3.

lg_code_loaded(L) :-
    (   lg_code(L) -> true
    ;   L == cocolog -> consult(library(reasoning/templates/cocolog))
    ;   true
    ),
    lg_code(L).

cocolog_write(utterance(_, Items), Text) :-
    lg_code_loaded(cocolog),
    maplist(lg_item_text, Items, Texts),
    atomic_list_concat(Texts, Text).

lg_item_text(Item, Text) :-
    lg_item_term(Item, T),
    (   T = query(B)
    ->  lg_code_query_mark(cocolog, Mark),
        \+ \+ ( numbervars(B, 0, _),
                with_output_to(string(S), write_term(B, [quoted(true), numbervars(true), spacing(next_argument)])),
                atomic_list_concat([Mark, ' ', S, '.\n'], Text0), nb_setval('$lg_text', Text0) ),
        nb_getval('$lg_text', Text)
    ;   with_output_to(string(S), portray_clause(T)),
        atom_string(Text, S)
    ).

%% An item as a Cocolog term, each var(N) one variable.
lg_item_term(Item, T) :-
    lg_out(Item, [], _, T).

lg_out(fact(A), M0, M, A1) :- !, lg_out_atom(A, M0, M, A1).
lg_out(rule(H, B), M0, M, (H1 :- B1)) :- !, lg_out_atom(H, M0, M1, H1), lg_out_body(B, M1, M, B1).
lg_out(query(B), M0, M, query(B1)) :- lg_out_body(B, M0, M, B1).

lg_out_body(and([B]), M0, M, B1) :- !, lg_out_body(B, M0, M, B1).
lg_out_body(and([B|Bs]), M0, M, (B1, Bs1)) :- !, lg_out_body(B, M0, M1, B1), lg_out_body(and(Bs), M1, M, Bs1).
lg_out_body(A, M0, M, A1) :- lg_out_atom(A, M0, M, A1).

lg_out_atom(pred(N, As), M0, M, A) :-
    length(As, Ar),
    lg_code_pred_name(N, Ar, N1),
    lg_out_terms(As, M0, M, As1),
    A =.. [N1|As1].

lg_out_terms([], M, M, []).
lg_out_terms([T|Ts], M0, M, [T1|Ts1]) :- lg_out_term(T, M0, M1, T1), lg_out_terms(Ts, M1, M, Ts1).

lg_out_term(const(C), M, M, C) :- !.
lg_out_term(num(N), M, M, N) :- !.
lg_out_term(str(S), M, M, S) :- !.
lg_out_term(list(Ts), M0, M, L) :- !, lg_out_terms(Ts, M0, M, L).
lg_out_term(var(N), M0, M, V) :- !, ( memberchk(N-V0, M0) -> V = V0, M = M0 ; M = [N-V|M0] ).
lg_out_term(fun(F, As), M0, M, T) :- !, lg_out_terms(As, M0, M, As1), T =.. [F|As1].
lg_out_term(X, _, _, _) :- lg_no(term(X)).

%% A predicate's name in Cocolog: a row's, else its meaning, the template's
%% prefix before it where the system defines that name and arity.
lg_code_pred_name(N, Ar, N1) :-
    (   lg_code_name(cocolog, N/Ar, N0) -> true ; N0 = N ),
    (   lg_reserved(N0, Ar) -> lg_code_reserved_prefix(cocolog, P), atom_concat(P, N0, N1) ; N1 = N0 ).

lg_reserved(N, Ar) :- functor(H, N, Ar), predicate_property(H, imported_from(_)), !.

%% READING: the text cut into clauses outside quotes and comments, each read
%% as a term; its variables var(1), var(2) by their first use.
cocolog_read(Text, utterance(Intent, Items)) :-
    lg_code_loaded(cocolog),
    lg_clauses(Text, Cs),
    Cs \== [],
    maplist(lg_clause_item, Cs, Items0),
    maplist(lg_number, Items0, Items),
    ( forall(member(I, Items), I = query(_)) -> Intent = question ; Intent = assertion ).

lg_clause_item(C, Item) :-
    catch(term_string(T, C), _, lg_no(syntax(C))),
    lg_in(T, Item).

lg_in(T, _) :- var(T), !, lg_no(term(T)).
lg_in((?- B), query(B1)) :- !, lg_in_body(B, B1).
lg_in((H :- B), rule(H1, B1)) :- !, lg_in_atom(H, H1), lg_in_body(B, B1).
lg_in(H, fact(H1)) :- lg_in_atom(H, H1).

lg_in_body(B, _) :- var(B), !, lg_no(term(B)).
lg_in_body((A, B), and([A1|Bs])) :- !, lg_in_atom(A, A1), lg_in_body(B, B0), ( B0 = and(Bs) -> true ; Bs = [B0] ).
lg_in_body(A, A1) :- lg_in_atom(A, A1).

lg_in_atom(A, _) :- \+ callable(A), !, lg_no(term(A)).
lg_in_atom(A, pred(N, As1)) :-
    A =.. [N1|As], length(As, Ar),
    lg_code_meaning(N1, Ar, N),
    maplist(lg_in_term, As, As1).

%% A name read back: the prefix off where the rest is a reserved name of
%% that arity, a row's meaning, else the name.
lg_code_meaning(N1, Ar, N) :-
    lg_code_reserved_prefix(cocolog, P),
    (   atom_concat(P, N0, N1), lg_reserved(N0, Ar) -> true ; N0 = N1 ),
    (   lg_code_name(cocolog, M/Ar, N0) -> N = M ; N = N0 ).

lg_in_term(V, V) :- var(V), !.
lg_in_term(L, list(Ts)) :- is_list(L), !, maplist(lg_in_term, L, Ts).
lg_in_term(A, const(A)) :- atom(A), !.
lg_in_term(N, num(N)) :- number(N), !.
lg_in_term(S, str(S)) :- string(S), !.
lg_in_term(T, fun(F, As1)) :- compound(T), !, T =.. [F|As], maplist(lg_in_term, As, As1).

%% The clauses of a text: each ends at a full stop before layout or the
%% text's end, outside a quoted atom or string and a comment; a full stop
%% after a symbol (`=..') ends none.
lg_clauses(Text, Cs) :-
    atom_codes(Text, Codes),
    lg_cut(Codes, normal, [], Cs0),
    exclude(==(''), Cs0, Cs).

lg_cut([], _, Acc, Cs) :- !, lg_rest(Acc, Cs).
lg_cut([0'%|Cs0], normal, Acc, Cs) :- !, lg_skip_line(Cs0, Cs1), lg_cut(Cs1, normal, Acc, Cs).
lg_cut([Q|Cs0], normal, Acc, Cs) :- ( Q == 0'' ; Q == 0'" ), !, lg_cut(Cs0, quote(Q), [Q|Acc], Cs).
lg_cut([Q|Cs0], quote(Q), Acc, Cs) :- !, lg_cut(Cs0, normal, [Q|Acc], Cs).
lg_cut([0'\\, C|Cs0], quote(Q), Acc, Cs) :- !, lg_cut(Cs0, quote(Q), [C, 0'\\|Acc], Cs).
lg_cut([C|Cs0], quote(Q), Acc, Cs) :- !, lg_cut(Cs0, quote(Q), [C|Acc], Cs).
lg_cut([0'.|Cs0], normal, Acc, [C|Cs]) :-
    ( Cs0 = [] ; Cs0 = [N|_], code_type(N, space) ),
    \+ ( Acc = [P|_], lg_symbol_code(P) ), !,
    reverse([0'.|Acc], R), lg_trim(R, C),
    lg_cut(Cs0, normal, [], Cs).
lg_cut([C|Cs0], normal, Acc, Cs) :- lg_cut(Cs0, normal, [C|Acc], Cs).

lg_rest(Acc, Cs) :-
    reverse(Acc, R), lg_trim(R, A1),
    ( A1 == '' -> Cs = [] ; lg_no(syntax(A1)) ).

%% Codes as an atom, the layout at its two ends off.
lg_trim(Codes, A) :-
    lg_drop_space(Codes, C1), reverse(C1, R1), lg_drop_space(R1, R2), reverse(R2, C2),
    atom_codes(A, C2).

lg_drop_space([C|Cs], Rest) :- code_type(C, space), !, lg_drop_space(Cs, Rest).
lg_drop_space(Cs, Cs).

lg_skip_line([], []).
lg_skip_line([0'\n|Cs], Cs) :- !.
lg_skip_line([_|Cs0], Cs) :- lg_skip_line(Cs0, Cs).

lg_symbol_code(C) :- memberchk(C, `+-*/\\^<>=~:.?@#&$`).

%% ---- translating (since 1.67.0) --------------------------------------------------

%% logic_translate(+From, +To, +Text, -Text2): a natural language's text
%% into Cocolog through both levels, its first logic form; Cocolog into a
%% natural language through both levels the other way.
logic_translate(From, cocolog, Text, Code) :-
    From \== cocolog, !,
    logic_readings(From, Text, [U|_]),
    cocolog_write(U, Code).
logic_translate(cocolog, To, Code, Text) :-
    To \== cocolog, !,
    cocolog_read(Code, U),
    logic_write(To, U, Text).

%% ---- level 2 into a natural language (since 1.68.0) -------------------------------
%%
%% logic_write(+Lang, +Utterance, -Text): the logic form said in Lang, one
%% sentence a group of items. A group's level-1 IRs are tried in order, each
%% written by typology_write/3 and kept only where the sentence reads back to
%% the group's own items (logic_readings/3): so what is written means what
%% the logic form says, and a word class guessed wrong is never written. A
%% group no IR keeps is a general sentence, English words whatever Lang:
%% `append holds for X, Y and Z.'
%%
%% A GROUP is one item, or one individual's facts together: the fact of its
%% noun (person(a_person)), its adjectives' and one more, which level 2 made
%% from one sentence (`A person likes music.', its second reading).
%%
%% THE WORD CLASS of a predicate is the template's row (lg_code_class/3),
%% else the language's tables (typology_meaning/3): an adjective, then a
%% noun, then a verb of one argument, a verb of two.

logic_write(L, utterance(_, Items), Text) :-
    must_be(atom, L),
    lg_code_loaded(cocolog),
    lg_groups(Items, Groups),
    maplist(lg_say(L), Groups, Ss),
    atomic_list_concat(Ss, ' ', Text).

lg_groups([], []).
lg_groups([F|Is], [[F|Run]|Gs]) :-
    lg_individual_fact(F, _, C),
    lg_run(Is, C, Run, Rest), Run \== [], !,
    lg_groups(Rest, Gs).
lg_groups([I|Is], [[I]|Gs]) :- lg_groups(Is, Gs).

lg_individual_fact(fact(pred(N, [const(C)])), N, C) :- atom(C), atom_concat(a_, N, C).

lg_run([I|Is], C, [I|Run], Rest) :-
    I = fact(pred(_, Args)), memberchk(const(C), Args), !,
    lg_run(Is, C, Run, Rest).
lg_run(Is, _, [], Is).

lg_say(L, Group, S) :- lg_say(L, Group, S, _).

%% How a group was said: sentence (one that reads back) or general.
lg_say(L, Group, S, How) :-
    (   lg_group_ir(L, Group, IR),
        catch(typology_write(L, IR, S0), _, fail),
        lg_reads_back(L, S0, Group)
    ->  S = S0, How = sentence
    ;   lg_general(Group, S), How = general
    ).

lg_reads_back(L, S, Group) :-
    catch(logic_readings(L, S, Us), _, fail),
    member(utterance(_, Is), Us), Is == Group, !.

%% A group's level-1 IRs, the likeliest first.
lg_group_ir(L, [F|Run], IR) :-
    Run = [_|_], !,
    lg_individual_fact(F, N, C),
    append(AFs, [fact(A)], Run),
    lg_adjective_facts(L, AFs, C, As),
    lg_atom_ir(L, A, sub(C, np(N, sg, indef, As)), IR).
lg_group_ir(L, [fact(A)], IR) :- lg_atom_ir(L, A, every, IR).
lg_group_ir(L, [query(A)], question(IR)) :- A = pred(_, _), lg_atom_ir(L, A, wh, IR).
lg_group_ir(L, [rule(H, B)], IR) :- lg_body_list(B, Cs), lg_rule_ir(L, H, Cs, IR).

lg_adjective_facts(_, [], _, []).
lg_adjective_facts(L, [fact(pred(A, [const(C1)]))|Fs], C, [A|As]) :-
    C1 == C, lg_class_ok(L, A/1, adjective),
    lg_adjective_facts(L, Fs, C, As).

lg_body_list(and(Bs), Bs) :- !.
lg_body_list(B, [B]).

%% A rule over var(1), its subject: one noun is `every' (`Every human is
%% mortal.'); a noun and more conditions an if clause whose pronoun is the
%% subject (`A person is happy if they are healthy and safe.'), or the noun's
%% adjectives (`Every happy dog sleeps.'); no noun `something' and an if
%% clause (`Something sleeps if it is tired.').
lg_rule_ir(L, pred(H, Args), [pred(N, [var(1)])], IR) :-
    lg_class_ok(L, N/1, noun),
    lg_atom_ir(L, pred(H, Args), var1(np(N, sg, every, [])), IR).
lg_rule_ir(L, pred(H, Args), [pred(N, [var(1)])|Cs], sub(if, Main, Cond)) :-
    Cs \== [], lg_class_ok(L, N/1, noun),
    lg_atom_ir(L, pred(H, Args), var1(np(N, sg, indef, [])), Main),
    lg_pronoun(L, N, P),
    lg_cond_ir(L, Cs, P, Cond).
lg_rule_ir(L, pred(H, Args), [pred(N, [var(1)])|Cs], IR) :-
    Cs \== [], lg_class_ok(L, N/1, noun),
    lg_adjective_conds(L, Cs, As),
    lg_atom_ir(L, pred(H, Args), var1(np(N, sg, every, As)), IR).
lg_rule_ir(L, pred(H, Args), Cs, sub(if, Main, Cond)) :-
    member(K-P, [thing-pron(3, sg, n), person-pron(3, pl, _)]),
    lg_atom_ir(L, pred(H, Args), var1(qp(some, K)), Main),
    lg_cond_ir(L, Cs, P, Cond).

lg_adjective_conds(_, [], []).
lg_adjective_conds(L, [pred(A, [V])|Cs], [A|As]) :-
    V == var(1), lg_class_ok(L, A/1, adjective),
    lg_adjective_conds(L, Cs, As).

%% An if clause of the subject's pronoun: its adjectives joined (`they are
%% healthy and safe'), or one atom.
lg_cond_ir(L, Cs, P, copula(present, pos, P, adj(As))) :-
    Cs = [_, _|_], lg_adjective_conds(L, Cs, As).
lg_cond_ir(L, [A], P, IR) :- lg_atom_ir(L, A, var1(P), IR).

lg_pronoun(L, N, P) :-
    (   typology_meaning(L, person, N)
    ->  member(P, [pron(3, pl, _), pron(3, sg, n)])
    ;   member(P, [pron(3, sg, n), pron(3, pl, _)])
    ).

%% An atom's level-1 clause. How a term is said: SUB names one constant's
%% noun phrase (sub(C, NP)), var1(NP) var(1)'s; `every' says a variable of a
%% fact (`Everything is mortal.'), wh a query's (`Who is human?').
lg_atom_ir(L, pred(P, [A]), How, IR) :-
    lg_arg_np(L, How, A, S),
    lg_unary_ir(L, P, S, IR).
lg_atom_ir(L, pred(P, [A, B]), How, clause(P, present, pos, S, O)) :-
    lg_class_ok(L, P/2, verb),
    lg_arg_np(L, How, A, S),
    lg_arg_np(L, How, B, O).

lg_unary_ir(L, P, S, IR) :-
    lg_unary_classes(L, P, S, Cs),
    member(C, Cs),
    lg_unary_shape(C, P, S, IR).

lg_unary_shape(adjective, P, S, copula(present, pos, S, adj([P]))).
lg_unary_shape(noun, P, S, copula(present, pos, S, np(P, sg, indef, []))).
lg_unary_shape(verb, P, S, clause(P, present, pos, S, none)).

%% THE ORDER OF THE CLASSES of a word said of one thing S, from WordNet's
%% lists in lexicon/: an adjective of the 3 000 commonest (adj.txt: human,
%% mortal, wise; not animal, student); then a noun and a verb that takes no
%% object (vi.txt), the verb first where S is a person or an animal
%% (`John works.', `Rex sleeps.'), else the commoner first by their ranks
%% in known_noun.txt and vi.txt (`Every bird flies.', `A novel is a
%% book.'); a noun before a verb that takes an object (`to man', `to dog');
%% then any adjective. The sentence is still kept only where it reads back.
lg_unary_classes(L, P, S, Cs) :-
    (   lg_lex(adj, P, _) -> Cs1 = [adjective] ; Cs1 = [] ),
    (   lg_lex(vi, P, Rv)
    ->  (   lg_animate_np(L, S) -> Cs2 = [verb, noun]
        ;   lg_lex(known_noun, P, Rn), Rn < Rv -> Cs2 = [noun, verb]
        ;   Cs2 = [verb, noun]
        )
    ;   Cs2 = [noun, verb]
    ),
    append([Cs1, Cs2, [adjective]], Cs3),
    findall(C, ( member(C, Cs3), lg_class_ok(L, P/1, C) ), Cs4),
    list_to_set(Cs4, Cs).

%% A noun phrase of a person or an animal: a name a row says so, or no row
%% has (a name with no row is a person's); a noun of one; someone, who, a
%% pronoun of a person.
lg_animate_np(L, name(W)) :- !, ( typology_meaning(L, animate, W) -> true ; \+ typology_meaning(L, name, W) ).
lg_animate_np(L, np(N, _, _, _)) :- !, typology_meaning(L, animate, N).
lg_animate_np(_, qp(_, person)) :- !.
lg_animate_np(_, wh(who)) :- !.
lg_animate_np(_, pron(_, pl, _)) :- !.
lg_animate_np(_, pron(_, sg, G)) :- G \== n.

%% A word's place in a list of lexicon/ (adj, vi, known_noun), the
%% commonest first; each list is read once.
lg_lex(File, W, R) :-
    (   nb_current('$lg_lex', Read), memberchk(File, Read) -> true
    ;   (   atomic_list_concat(['lexicon/', File, '.txt'], Rel),
            catch(absolute_file_name(library(reasoning/Rel), F, [access(read)]), _, fail)
        ->  read_file_to_codes(F, Codes), atom_codes(Text, Codes),
            atomic_list_concat(Ws, '\n', Text),
            foldl(lg_lex_row(File), Ws, 1, _)
        ;   true
        ),
        ( nb_current('$lg_lex', R0) -> true ; R0 = [] ),
        nb_setval('$lg_lex', [File|R0])
    ),
    '$lg_lex'(File, W, R), !.

lg_lex_row(_, '', N, N) :- !.
lg_lex_row(File, W, N0, N) :- assertz('$lg_lex'(File, W, N0)), N is N0 + 1.

lg_arg_np(_, sub(C, NP), const(C1), NP) :- C1 == C, !.
lg_arg_np(_, var1(NP), var(1), NP) :- !.
lg_arg_np(_, wh, var(_), wh(W)) :- !, member(W, [who, what]).
lg_arg_np(_, every, var(_), qp(every, K)) :- !, member(K, [thing, person]).
lg_arg_np(L, _, const(C), NP) :- lg_const_np(L, C, NP).

%% A constant's noun phrase: something, someone; the_ a definite noun
%% phrase; a name a row has; a bare noun; a name no row has.
lg_const_np(_, something, qp(some, thing)).
lg_const_np(_, someone, qp(some, person)).
lg_const_np(L, C, np(N, sg, def, As)) :- atom_concat(the_, R, C), lg_noun_split(L, R, N, As).
lg_const_np(L, C, name(W)) :- lg_name_written(C, W), typology_meaning(L, name, W).
lg_const_np(L, C, np(N, sg, mass, As)) :- \+ atom_concat(the_, _, C), lg_noun_split(L, C, N, As).
lg_const_np(L, C, name(W)) :- lg_name_written(C, W), \+ typology_meaning(L, name, W).

%% A constant's words as adjectives and a noun, the longest noun first.
lg_noun_split(L, C, N, As) :-
    atomic_list_concat(Ps, '_', C),
    append(As, Ns, Ps), Ns \== [],
    atomic_list_concat(Ns, '_', N),
    typology_meaning(L, noun, N),
    forall(member(A, As), typology_meaning(L, adjective, A)).

%% A name's constant written: each word with a capital (john_smith is
%% `John Smith').
lg_name_written(C, W) :-
    atomic_list_concat(Ps, '_', C),
    maplist(lg_capital, Ps, Ws),
    atomic_list_concat(Ws, ' ', W).

lg_capital(W, C) :-
    (   sub_atom(W, 0, 1, _, F)
    ->  upcase_atom(F, U), sub_atom(W, 1, _, 0, R), atom_concat(U, R, C)
    ;   C = W
    ).

lg_class_ok(L, P/A, C) :-
    (   lg_code_class(cocolog, P/A, _)
    ->  lg_code_class(cocolog, P/A, C)
    ;   A == 1 -> typology_meaning(L, C, P)
    ;   C == verb, typology_meaning(L, verb, P)
    ).

%% THE GENERAL SENTENCE: `P holds for T1, T2 and T3.', a rule's conditions
%% after `if', a query `Does P hold for T?' or `For which X does it hold
%% that ...?'.
lg_general(Group, S) :-
    maplist(lg_general_item, Group, Ss),
    atomic_list_concat(Ss, ' ', S).

lg_general_item(fact(A), S) :-
    lg_holds(A, T), lg_sentence(T, '.', S).
lg_general_item(rule(H, B), S) :-
    lg_holds(H, T1),
    lg_body_list(B, Cs), maplist(lg_holds, Cs, Ts), lg_and(Ts, T2),
    format(atom(T), '~w if ~w', [T1, T2]),
    lg_sentence(T, '.', S).
lg_general_item(query(B), S) :-
    lg_vars_of(B, Ns),
    (   Ns == [], B = pred(P, [_|_])
    ->  B = pred(P, Args), maplist(lg_term_words, Args, Ws), lg_and(Ws, W),
        format(atom(T), 'does ~w hold for ~w', [P, W])
    ;   lg_body_list(B, Cs), maplist(lg_holds, Cs, Ts), lg_and(Ts, T2),
        (   Ns == []
        ->  format(atom(T), 'does it hold that ~w', [T2])
        ;   maplist(lg_var_word, Ns, Vs), lg_and(Vs, V),
            format(atom(T), 'for which ~w does it hold that ~w', [V, T2])
        )
    ),
    lg_sentence(T, '?', S).

lg_holds(pred(P, []), T) :- !, format(atom(T), '~w holds', [P]).
lg_holds(pred(P, Args), T) :-
    maplist(lg_term_words, Args, Ws), lg_and(Ws, W),
    format(atom(T), '~w holds for ~w', [P, W]).

lg_and([W], W) :- !.
lg_and(Ws, T) :-
    append(Init, [Last], Ws),
    atomic_list_concat(Init, ', ', I),
    format(atom(T), '~w and ~w', [I, Last]).

lg_term_words(var(N), W) :- !, lg_var_word(N, W).
lg_term_words(const(C), C) :- !.
lg_term_words(num(N), N) :- !.
lg_term_words(str(S), W) :- !, format(atom(W), '"~w"', [S]).
lg_term_words(list(Ts), W) :- !,
    maplist(lg_term_words, Ts, Ws), atomic_list_concat(Ws, ', ', A),
    format(atom(W), '[~w]', [A]).
lg_term_words(fun(F, As), W) :- !,
    maplist(lg_term_words, As, Ws), atomic_list_concat(Ws, ', ', A),
    format(atom(W), '~w(~w)', [F, A]).
lg_term_words(X, _) :- lg_no(term(X)).

lg_var_word(N, W) :-
    (   nth1(N, ['X', 'Y', 'Z', 'W'], W) -> true ; format(atom(W), 'X~w', [N]) ).

%% The numbers of a body's variables, in order of first use.
lg_vars_of(B, Ns) :- lg_vars_of(B, [], Ns0), reverse(Ns0, Ns).
lg_vars_of(var(N), Ns0, Ns) :- !, ( memberchk(N, Ns0) -> Ns = Ns0 ; Ns = [N|Ns0] ).
lg_vars_of(T, Ns0, Ns) :- compound(T), !, T =.. [_|As], foldl(lg_vars_of, As, Ns0, Ns).
lg_vars_of(_, Ns, Ns).

lg_sentence(T, End, S) :-
    lg_capital(T, T1), atom_concat(T1, End, S).

%% ---- the second measure (since 1.69.0) ----------------------------------------------
%%
%% logic_measure(+Lang, +Cases, -Result): of Cases, Sentence-Cocolog pairs
%% (lexicon/logic.txt, hand-written), how many Lang's reader and writer get
%% right. Result is measure(N, Right, Later, Kept, General, Misses, Unkept):
%%
%%     Right     the sentences whose first logic form is the Cocolog's
%%               (compared as items, cocolog_read/2, so layout, variable
%%               names and a reserved name's prefix are free)
%%     Later     the ones a later reading gets right
%%     Kept      the Cocolog texts logic_write/3 says in sentences that
%%               read back to them, each group's its own
%%     General   the ones with a group it says as a general sentence
%%     Misses    miss(Sentence, Why) for each sentence not Right: later,
%%               got(Items), why(W) logic_why/2's reason, or unread
%%     Unkept    unkept(Cocolog, Text) for each Cocolog text not Kept
%%
%% Each sentence is given 20 000 000 inferences. tools/logic/measure.pl
%% prints it over lexicon/logic.txt.
logic_measure(L, Cases, measure(N, Right, Later, Kept, General, Misses, Unkept)) :-
    must_be(atom, L),
    must_be(list, Cases),
    lg_code_loaded(cocolog),
    length(Cases, N),
    foldl(lg_measure_case(L), Cases, m(0, 0, 0, 0, [], []), m(Right, Later, Kept, General, Ms, Us)),
    reverse(Ms, Misses), reverse(Us, Unkept).

lg_measure_case(L, S-C, m(R0, A0, K0, G0, Ms0, Uk0), m(R, A, K, G, Ms, Uk)) :-
    (   catch(cocolog_read(C, utterance(_, Want)), _, fail)
    ->  true
    ;   throw(error(domain_error(cocolog, C), logic_measure/3))
    ),
    (   catch(call_with_inference_limit(logic_readings(L, S, Us), 20000000, Lim), _, fail),
        Lim \== inference_limit_exceeded
    ->  true
    ;   Us = []
    ),
    (   Us = [utterance(_, Is)|_], Is == Want
    ->  R is R0 + 1, A = A0, Ms = Ms0
    ;   member(utterance(_, Is), Us), Is == Want
    ->  R = R0, A is A0 + 1, Ms = [miss(S, later)|Ms0]
    ;   Us = [utterance(_, Is)|_]
    ->  R = R0, A = A0, Ms = [miss(S, got(Is))|Ms0]
    ;   R = R0, A = A0, lg_measure_why(L, S, W), Ms = [miss(S, W)|Ms0]
    ),
    lg_groups(Want, Gs),
    maplist(lg_say(L), Gs, Ss, Hows),
    atomic_list_concat(Ss, ' ', T),
    (   \+ memberchk(general, Hows)
    ->  K is K0 + 1, G = G0, Uk = Uk0
    ;   K = K0, G is G0 + 1, Uk = [unkept(C, T)|Uk0]
    ).

lg_measure_why(L, S, W) :-
    (   catch(once(typology_read(L, S, IR)), _, fail)
    ->  ( logic_why(IR, W0) -> W = why(W0) ; W = why(unknown) )
    ;   W = unread
    ).

%% logic_measure_cases(+File, -Cases): a measure file's Sentence-Cocolog
%% pairs, a line each, apart by a tab; a line beginning # a comment.
logic_measure_cases(F, Cases) :-
    read_file_to_codes(F, Codes), atom_codes(Text, Codes),
    atomic_list_concat(Lines, '\n', Text),
    findall(S-C, ( member(Line, Lines), Line \== '', \+ sub_atom(Line, 0, 1, _, '#'),
                   atomic_list_concat([S, C], '\t', Line) ), Cases).
