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
%%                                     Cocolog (To cocolog)

:- module(logic, [logic_from_ir/2, logic_read/3, logic_readings/3, logic_why/2,
                  cocolog_write/2, cocolog_read/2, logic_translate/4]).

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

:- dynamic lg_code/1, lg_code_reserved_prefix/2, lg_code_name/3, lg_code_query_mark/2.

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
%% into Cocolog through both levels, its first logic form.
logic_translate(From, cocolog, Text, Code) :-
    From \== cocolog, !,
    logic_readings(From, Text, [U|_]),
    cocolog_write(U, Code).
