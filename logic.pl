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
%%     at(Tense, Atom)             an atom said in a tense other than the
%%                                 present: past, future, perfect,
%%                                 pluperfect, imperfect (since 1.70.0;
%%                                 Cocolog past(Atom))
%%     modified(Adjunct, Atom)     an atom with an adjunct of its clause
%%                                 (since 1.71.0): pp(Prep, Term), an
%%                                 adposition phrase, or adv(Meaning), an
%%                                 adverb; Cocolog in(Atom, Term) and
%%                                 quickly(Atom); when(Atom2), a when
%%                                 clause's atom, outside the tenses
%%                                 (since 1.79.0; Cocolog when(Atom,
%%                                 Atom2))
%%     const(Name)                 a constant: a name (socrates), a
%%                                 definite noun phrase (the(dog),
%%                                 the(pl(rebel)), the(big(dog))), a bare
%%                                 noun (music), one individual
%%                                 (a(person), a(big(dog)), a(pl(book)),
%%                                 a(of(book, a(pl(stamp))))), a possessed
%%                                 (of(dog, john)); terms since 1.76.0,
%%                                 one atom each (the_dog) through 1.75.0
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
%% second (a(person)). `something' and `someone' are one individual
%% (something), except in a conditional, where they are the rule's variable.
%% A question word is the query's variable. A pronoun of an if clause
%% stands for its main clause's subject.
%%
%% A TENSE (since 1.70.0) is said of each atom its clause says, at(past,
%% pred(sleep, [const(john)])), never of a subject's noun: `Every man was
%% happy.' is at(past, happy(X)) if man(X). An indefinite subject in a
%% tense gives one individual's facts first and the rule second (`A dog
%% barked.').
%%
%% AN ADJUNCT (since 1.71.0) is said of each atom its clause says, inside
%% the tense, the clause's first adjunct the innermost: `The dog ran
%% quickly to the house.' is at(past, modified(pp(to, const(the(house))),
%% modified(adv(quickly), pred(run, [const(the(dog))])))), Cocolog
%% past(to(quickly(run(the(dog))), the(house))). An adposition phrase as a
%% copula's predicate is a predicate of two: `The book is on the table.' is
%% pred(on, [const(the(book)), const(the(table))]).
%%
%% A POSSESSOR (since 1.73.0): the possessed and the possessor are one
%% constant, of(dog, john), of(spot, he), of(edge, the(bed)).
%%
%% A PRONOUN (since 1.72.0): in a text, the noun phrase it refers to; with
%% none, a constant of its own, its word (he, she, it, they, i, we, you).
%%
%% A PLURAL DEFINITE NOUN PHRASE (since 1.75.0): a constant of the group,
%% the(pl(rebel)) since 1.76.0.
%%
%% AN INDEFINITE OBJECT (since 1.74.0): in a statement an individual
%% (letter(a(letter)), receive(he, a(letter))), in a question or a
%% condition a variable (`Who sees a dog?' is see(X, Y), dog(Y)); in a
%% rule's conclusion none.
%%
%% AN INDEFINITE NOUN PHRASE (since 1.77.0) is so wherever a statement
%% says it: an object, an adjunct's (`He sat on a chair.': on(sit(he),
%% a(chair))), a possessor (of(status, a(classic))) and a possessed
%% (a(of(book, a(pl(stamp))))). Its individual is a(T), T its term as in
%% the(T), so its adjectives and its number are in it: a(big(dog)),
%% a(pl(book)), and `A good woman met a bad woman.' names two (a(woman)
%% for both through 1.76.0). Its facts are its noun's and its adjectives'
%% (dog(a(big(dog))), big(a(big(dog)))). In a question a variable inside
%% a constant is a compound term: `Who knows the father of a student?' is
%% know(X, of(father, Y)), student(Y).
%%
%% A NOUN OF RELATION (since 1.78.0), a copula's noun phrase with a
%% possessor, is a predicate of two, the noun's, of the subject and the
%% possessor: `John is Mary's father.' and `John is the father of Mary.'
%% are father(john, mary), `Every set is a subset of the universal set.'
%% subset(X, the(universal(set))) :- set(X).
%%
%% WHEN (since 1.79.0): in the present a rule as `if' (`John sleeps when
%% Mary sings.': sleep(john) :- sing(mary)); in a tense each atom of the
%% main clause linked to the when clause's one atom, when(A, B), each in
%% its own tense (`John slept when Mary sang.': when(past(sleep(john)),
%% past(sing(mary)))).
%%
%% WHAT HAS NO LOGIC FORM YET: the conditional, a negation, `because', a pronoun whose gender is not known, an indefinite noun
%% phrase in a rule's conclusion, a generic subject with a possessor in
%% the present (`Lilies of the valley are racemose.'), a noun phrase of
%% `every' or `some' that is no subject, a noun of relation with an
%% adjective (`the main source of'), a copula's definite noun phrase with
%% no possessor (`Leather is the latest vogue.'), `no' and `nothing', and
%% a determiner other than the ones above. logic_why/2 names the first
%% reason.
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
%%                                     tense(conditional), negation, adjunct,
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
    (   lg_sentences(Text, Ss), Ss = [_, _|_],
        findall(U, lg_text_read(L, Ss, U), Us0), Us0 \== []
    ->  true
    ;   findall(U, logic_read(L, Text, U), Us0)
    ),
    lg_distinct(Us0, Us).

%% A TEXT OF SEVERAL SENTENCES (since 1.72.0) is read by
%% typology_read_text/3, whose pronouns of the third person name the noun
%% they stand for (pron(3, sg, ref(boy))); each such pronoun is the noun
%% phrase it refers to, from an earlier sentence, the nearest first: a
%% name or a definite noun phrase as it is, an indefinite one its
%% individual (a(dog)). The utterance is the sentences' items in order, a
%% question if every sentence is one.
%% Since 1.89.0 the sentences are read in turn, each with the logic forms
%% of the ones before it: a pronoun of an indefinite noun phrase whose
%% sentence was a rule is generic too (`A dog barks. It sleeps.' is two
%% rules of every dog; through 1.88.0 the second was a fact of one dog),
%% else the individual that sentence named; and a new individual of a
%% sentence is named apart from an earlier one of the same name
%% (lg_new_inds/4: `Something is red. Something is blue.' is
%% red(something), blue(something_2); `John sees a dog. Mary sees a dog.'
%% a(dog) and a(dog, 2); through 1.88.0 one thing and one dog). A
%% referent's constant is marked ref(C) until its sentence's new
%% individuals are named.
lg_text_read(L, Ss, utterance(Intent, Items)) :-
    typology_read_text(L, Ss, IRs),
    lg_text_items(IRs, [], [], Us),
    findall(I, member(utterance(I, _), Us), Is),
    ( forall(member(I, Is), I == question) -> Intent = question ; Intent = assertion ),
    findall(It, ( member(utterance(_, Its), Us), member(It, Its) ), Items).

lg_text_items([], _, _, []).
lg_text_items([IR|IRs], Prev, Seen0, [U|Us]) :-
    lg_subst_refs(IR, Prev, IR1),
    logic_from_ir(IR1, U0),
    lg_new_inds(U0, Seen0, Seen, U),
    lg_text_items(IRs, [IR-U|Prev], Seen, Us).

%% A sentence with no subject (pron(3, sg, zero)) in a text is the text's
%% one someone, never a new one: the text goes on about whom it has not
%% named.
lg_subst_refs(T, _, T) :- var(T), !.
lg_subst_refs(pron(_, _, K), Prev, NP) :- nonvar(K), K = ref(X), !,
    ( lg_antecedent(X, Prev, NP) -> true ; NP = pron(3, _, unresolved) ).
lg_subst_refs(pron(3, N, K), _, '$const'(ref(someone))) :- K == zero, N == sg, !.
lg_subst_refs(T, Prev, T1) :- compound(T), !,
    T =.. [F|As], maplist(lg_subst_arg(Prev), As, As1), T1 =.. [F|As1].
lg_subst_refs(T, _, T).

lg_subst_arg(Prev, A, A1) :- lg_subst_refs(A, Prev, A1).

%% The noun phrase a pronoun's referent X names, in the nearest earlier
%% sentence that has one.
lg_antecedent(name(W), Prev, name(W)) :- !,
    member(IR-_, Prev), lg_np_in(IR, name(W1)), W1 == W, !.
lg_antecedent(M, Prev, NP) :-
    member(IR-U, Prev), lg_np_in(IR, np(M1, Num, D, As)), M1 == M, !,
    (   memberchk(D, [def, mass]) -> NP = np(M, Num, D, As)
    ;   D == indef, lg_generic_for(U, M) -> ( Num == pl -> Q = all ; Q = every ), NP = np(M, Num, Q, As)
    ;   D == indef, lg_ind_of(U, M, C) -> NP = '$const'(ref(C))
    ;   D == indef -> catch(lg_np_term(M, Num, As, T), lg_no(_), fail), NP = '$const'(ref(a(T)))
    ).

%% A sentence's logic form is a rule of the noun M's things.
lg_generic_for(utterance(_, Items), M) :-
    member(rule(_, B), Items),
    ( B = and(Bs) -> member(C, Bs) ; C = B ),
    C = pred(M1, [var(_)]), M1 == M, !.

%% The individual of the noun M a sentence's logic form names.
lg_ind_of(utterance(_, Items), M, C) :-
    member(fact(pred(M1, [const(C)])), Items), M1 == M,
    lg_ind_shape(C, S), lg_shape_head(S, M2), M2 == M, !.

%% AN INDIVIDUAL'S TERM: a(Shape), or a(Shape, K) for the K-th of that
%% shape in a text (since 1.89.0).
lg_ind_shape(C, S) :- compound(C), ( C = a(S) -> true ; C = a(S, K), integer(K) ).

%% something_2's word and number, read back (since 1.89.0).
lg_numbered(C, W) :-
    atomic_list_concat([W, N], '_', C), atom_number(N, K), integer(K), K > 1.

%% A SENTENCE'S NEW INDIVIDUALS in a text (since 1.89.0): every a(Shape),
%% something and someone its logic form names, but a referent's (ref(C)),
%% each named apart where an earlier sentence named one so: the sentence's
%% K-th of a name (a(Shape) the first, a(Shape, K) since its object took a
%% name its subject had) is the text's C+K-th, C the earlier sentences'
%% count (a(Shape, C+K), something_C+K), and the referents' marks taken
%% off. Seen and the names are Name-K pairs, Name a shape or something or
%% someone.
lg_new_inds(utterance(I, Items0), Seen0, Seen, utterance(I, Items)) :-
    lg_inds_named(Items0, [], Ns),
    lg_ind_seen(Ns, Seen0, Seen0, Seen),
    lg_ind_rename(Items0, Seen0, Items).

lg_inds_named(T, Ns, Ns) :- var(T), !.
lg_inds_named(ref(_), Ns, Ns) :- !.
lg_inds_named(T, Ns0, Ns) :-
    atom(T), !,
    ( memberchk(T, [something, someone]) -> lg_ind_add(T-1, Ns0, Ns) ; Ns = Ns0 ).
lg_inds_named(T, Ns0, Ns) :-
    compound(T), !,
    T =.. [_|As], foldl(lg_inds_named, As, Ns0, Ns1),
    (   T = a(S) -> lg_ind_add(S-1, Ns1, Ns)
    ;   T = a(S, K), integer(K) -> lg_ind_add(S-K, Ns1, Ns)
    ;   Ns = Ns1
    ).
lg_inds_named(_, Ns, Ns).

lg_ind_add(S-K, Ns0, Ns) :- ( member(S1-K1, Ns0), S1 == S, K1 == K -> Ns = Ns0 ; Ns = [S-K|Ns0] ).

%% A name's count in the text after a sentence: its count before it (in
%% Seen0) and the highest K the sentence gives it.
lg_ind_seen([], _, Seen, Seen).
lg_ind_seen([S-K|Ns], Seen0, SeenA, Seen) :-
    lg_ind_count(S, Seen0, C), N is C + K,
    (   select(S1-N0, SeenA, Rest), S1 == S
    ->  N1 is max(N0, N), SeenB = [S-N1|Rest]
    ;   SeenB = [S-N|SeenA]
    ),
    lg_ind_seen(Ns, Seen0, SeenB, Seen).

lg_ind_count(S, Seen, C) :- ( member(S1-C0, Seen), S1 == S -> C = C0 ; C = 0 ).

lg_ind_named_as(S, K, Seen, T) :-
    lg_ind_count(S, Seen, C), N is C + K,
    (   atom(S), memberchk(S, [something, someone])
    ->  ( N =:= 1 -> T = S ; atomic_list_concat([S, '_', N], T) )
    ;   ( N =:= 1 -> T = a(S) ; T = a(S, N) )
    ).

lg_ind_rename(T, _, T) :- var(T), !.
lg_ind_rename(ref(C), _, C) :- !.
lg_ind_rename(T, Seen, T1) :-
    atom(T), !,
    ( memberchk(T, [something, someone]) -> lg_ind_named_as(T, 1, Seen, T1) ; T1 = T ).
lg_ind_rename(T, Seen, T1) :-
    compound(T), !,
    T =.. [F|As], maplist([A, A1]>>lg_ind_rename(A, Seen, A1), As, As1), T2 =.. [F|As1],
    (   T = a(S) -> T2 = a(S2), lg_ind_named_as(S, 1, Seen, T3), lg_ind_inner(T3, S2, T1)
    ;   T = a(S, K), integer(K) -> T2 = a(S2, _), lg_ind_named_as(S, K, Seen, T3), lg_ind_inner(T3, S2, T1)
    ;   T1 = T2
    ).
lg_ind_rename(T, _, T).

%% The text's name of an individual, its shape's inner names the text's
%% too.
lg_ind_inner(a(_), S2, a(S2)).
lg_ind_inner(a(_, N), S2, a(S2, N)).

%% The noun phrases of an IR; an indefinite possessed is no referent of its
%% own (its individual is a(of(...)), lg_possessed/4).
lg_np_in(T, _) :- var(T), !, fail.
lg_np_in(T, T) :- ( T = np(_, _, _, _) ; T = name(_) ).
lg_np_in(of(P, NP), X) :- !,
    (   lg_np_in(P, X)
    ;   nonvar(NP), NP = np(_, _, D, _), D \== indef, lg_np_in(NP, X)
    ).
lg_np_in(T, NP) :- compound(T), T =.. [_|As], member(A, As), lg_np_in(A, NP).

%% A text's sentences: each ends at a full stop, a question mark or an
%% exclamation mark before a space.
lg_sentences(Text, Ss) :-
    atom(Text),
    atom_codes(Text, Cs),
    lg_split(Cs, [], Ss0),
    exclude(==(''), Ss0, Ss).

lg_split([], Acc, [S]) :- !, reverse(Acc, R), lg_trim(R, S).
lg_split([C, 0' |Cs], Acc, [S|Ss]) :- memberchk(C, `.?!`), !,
    reverse([C|Acc], R), lg_trim(R, S),
    lg_split(Cs, [], Ss).
lg_split([C|Cs], Acc, Ss) :- lg_split(Cs, [C|Acc], Ss).

lg_distinct([], []).
lg_distinct([U|Us], [U|Ds]) :-
    exclude(==(U), Us, Rest),
    lg_distinct(Rest, Ds).

logic_from_ir(IR0, utterance(Intent, Items)) :-
    catch(( lg_active(IR0, IR), lg_utterance(IR, Intent, Items0) ), lg_no(_), fail),
    maplist(lg_number, Items0, Items).

logic_why(IR0, Why) :-
    catch(( lg_active(IR0, IR), lg_utterance(IR, _, _) -> fail ; Why = shape(IR0) ), lg_no(Why), true).

%% THE PASSIVE (since 1.98.0) is its active: clause(V, pass(T), P, S,
%% none, Js) is clause(V, T, P, Agent, S, Js1), the agent the NP of the
%% first adjunct pp(by, NP), wherever it stands, else someone the text
%% does not name, pron(3, sg, zero), as a clause's with no subject (`The
%% pass was fumbled.' is past(fumble(someone, the(pass))), `The house was
%% built by the workers.' past(build(the(pl(worker)), the(house))), `He had
%% been trained rigorously by the monks.' pluperfect(rigorously(train(
%% the(pl(monk)), he)))). A passive's infinitive object is the patient's,
%% as an object's infinitive is (`The auditor was required to produce his
%% working papers.' is past(require(someone, to(produce(the(auditor),
%% ...))))). A passive with another object (`He was given a book.') has
%% none, and so has one whose patient and agent the text both leaves
%% unsaid (since 1.99.0: `Was transferred up to headquarters.'), each of
%% which would be someone.
lg_active(X, X) :- var(X), !.
lg_active(clause(V, T, P, S, O), C) :- nonvar(T), T = pass(_), !,
    lg_active(clause(V, T, P, S, O, []), C).
lg_active(clause(V, T, P, S, O), C) :- lg_pass_inf(O), !,
    lg_active(clause(V, T, P, S, O, []), C).
%% A passive infinitive object (since 1.99.0) is the active's, its patient
%% the clause's own subject: `The machine needs to be serviced.' is
%% need(the(machine), to(service(someone, the(machine)))).
lg_active(clause(V, T, P, S, O0, Js0), C) :- \+ ( nonvar(T), T = pass(_) ), lg_pass_inf(O0), !,
    ( O0 = clause(V2, _, _, _, _, Js2) -> true ; O0 = clause(V2, _, _, _, _), Js2 = [] ),
    lg_active(S, S1), maplist(lg_active, Js2, Js3), maplist(lg_active, Js0, Js),
    ( Js3 == [] -> O = clause(V2, infinitive, pos, pron(3, sg, zero), S1) ; O = clause(V2, infinitive, pos, pron(3, sg, zero), S1, Js3) ),
    ( Js == [] -> C = clause(V, T, P, S1, O) ; C = clause(V, T, P, S1, O, Js) ).
lg_active(clause(V, pass(T), P, S, O0, Js0), C) :- !,
    lg_active(S, S1),
    (   O0 == none -> O = S1
    ;   nonvar(O0), O0 = oc(Pred) -> O = oc(S1, Pred)
    ;   nonvar(O0), ( O0 = inf(V2, O2) -> Js3 = [] ; O0 = inf(V2, O2, Js3) )
    ->  lg_active(O2, O3), maplist(lg_active, Js3, Js4),
        ( Js4 == [] -> O = clause(V2, infinitive, pos, S1, O3) ; O = clause(V2, infinitive, pos, S1, O3, Js4) )
    ;   lg_no(passive(object))
    ),
    (   select(J, Js0, Js2), nonvar(J), J = pp(by, A0) -> true ; A0 = pron(3, sg, zero), Js2 = Js0 ),
    ( S == pron(3, sg, zero), A0 == pron(3, sg, zero) -> lg_no(passive(unsaid)) ; true ),
    lg_active(A0, A), maplist(lg_active, Js2, Js),
    ( Js == [] -> C = clause(V, T, P, A, O) ; C = clause(V, T, P, A, O, Js) ).
lg_active(X, Y) :- compound(X), !, X =.. [F|As], maplist(lg_active, As, Bs), Y =.. [F|Bs].
lg_active(X, X).

lg_pass_inf(O) :-
    nonvar(O), ( O = clause(_, T, _, Z, _) ; O = clause(_, T, _, Z, _, _) ),
    T == pass(infinitive), Z == pron(3, sg, zero).

lg_no(Why) :- throw(lg_no(Why)).

%% ---- utterances ----------------------------------------------------------------

lg_utterance(question(C), question, [query(B)]) :- !,
    lg_parts(C, S, Pred),
    lg_entity(S, ent(T, Conds, Q), SMs),
    ( memberchk(Q, [const, wh]) -> true ; lg_no(determiner(Q)) ),
    lg_atoms(C, T, Pred, Atoms00),
    append(Atoms00, SMs, Atoms0),
    lg_obj_conds(Atoms0, Atoms, OConds),
    append([Atoms, OConds, Conds], Bs),
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
    (   K == if -> lg_conditional(Main, Cond, Items)
    ;   K == when, lg_clause_tense(Main, present), lg_clause_tense(Cond, present)
    ->  lg_conditional(Main, Cond, Items)
    ;   K == when -> lg_when(Main, Cond, Items)
    ;   lg_no(subordinate(K))
    ).
lg_statement(phrase(X), Items) :- !, lg_phrase(X, Items).
lg_statement(C, Items) :-
    lg_parts(C, S, Pred),
    lg_entity(S, ent(T, Conds, Q), SMs),
    lg_atoms(C, T, Pred, Atoms0),
    partition(lg_is_ind, SMs, Inds, SObjs),
    append(Atoms0, SObjs, Atoms),
    lg_assert(Q, T, Conds, Atoms, S, Inds, Items).

lg_is_ind('$ind'(_, _)).

lg_someone(person, someone).
lg_someone(thing, something).

%% A NOUN PHRASE ALONE (since 1.81.0): its noun and its adjectives said of
%% its term, as facts. An indefinite one is its individual (`A heavy
%% coat.' is coat(a(heavy(coat))) and heavy(a(heavy(coat))); `Dry sobs.'
%% sob(a(pl(dry(sob))))), a definite one the(T) (`The past year.'
%% year(the(past(year)))), a bare noun its term (`Good taste.'
%% taste(good(taste))), a possessed of(T, P) with an indefinite
%% possessor's own facts after (`A severe case of flu.'); each item of a
%% coordination its own (`Mines and traps.'). A name, a pronoun and a
%% phrase of another determiner say nothing of a noun: none
%% (phrase(Kind)).
lg_phrase(X, _) :- var(X), !, lg_no(phrase(X)).
lg_phrase(and(Xs), Items) :- !, lg_phrases(Xs, Items).
lg_phrase(X0, Items) :-
    ( lg_phrase_noun(X0, N, As0) -> true ; functor(X0, F, _), lg_no(phrase(F)) ),
    lg_phrase_aps(X0, X, As0, As, XMs),
    lg_arg(phrase, X, V, _, Ms0),
    append(Ms0, XMs, Ms),
    (   Ms = ['$obj'(_, V1, _, _)|_], V1 == V
    ->  lg_facts([], Ms, Items)
    ;   lg_noun_conds(N, As, V, Cs),
        lg_facts(Cs, Ms, Items)
    ).

lg_phrases([], []).
lg_phrases([X|Xs], Items) :-
    lg_phrase(X, Items1), lg_phrases(Xs, Items2), append(Items1, Items2, Items).

lg_phrase_noun(np(N, _, _, As), N, As).

%% A phrase's adjectives with an adposition phrase made items with their
%% arguments (lg_np_aps/3) once, for its term and its facts alike.
lg_phrase_aps(np(N, Num, D, As0), np(N, Num, D, As), As0, As, Ms) :- lg_has_ap(As0), !,
    lg_np_aps(As0, As, Ms).
lg_phrase_aps(X, X, As, As, []).
lg_phrase_noun(of(_, NP), N, As) :- nonvar(NP), lg_phrase_noun(NP, N, As).
lg_phrase_noun(np_pp(H, _), N, As) :- nonvar(H), lg_phrase_noun(H, N, As).

%% An atom in a tense, its when clause round it or not.
lg_in_tense(at(_, _)) :- !.
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_in_tense(modified(when(_), A)) :- lg_in_tense(A).

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
lg_assert(const, _, [], Atoms, _, _, Items) :- !,
    lg_facts([], Atoms, Items).
lg_assert(every, T, Conds, Atoms, _, _, Items) :- !,
    lg_rules(Atoms, T, Conds, Items).
lg_assert(generic, T, Conds, Atoms, S, Inds, Items) :- !,
    (   lg_has_obj(Atoms)
    ->  lg_individual(S, Inds, T), lg_facts(Conds, Atoms, Items)
    ;   Atoms = [A1|_], lg_in_tense(A1)
    ->  (   lg_individual(S, Inds, T), lg_facts(Conds, Atoms, Items)
        ;   lg_generic_rules(Inds, Atoms, T, Conds, Items)
        )
    ;   (   lg_generic_rules(Inds, Atoms, T, Conds, Items)
        ;   lg_individual(S, Inds, T), lg_facts(Conds, Atoms, Items)
        )
    ).
lg_assert(some, T, Conds, Atoms, S, Inds, Items) :- !,
    lg_individual(S, Inds, T), lg_facts(Conds, Atoms, Items).
lg_assert(Q, _, _, _, _, _, _) :- lg_no(determiner(Q)).

%% A generic subject's rules; none where its noun has a possessor
%% (`Lilies of the valley are racemose.': the rule's variable would lose
%% it).
lg_generic_rules(Inds, Atoms, T, Conds, Items) :-
    ( memberchk('$ind'(_, of(_, _)), Inds) -> lg_no(possessor(generic)) ; true ),
    ( member('$ind'(_, S), Inds), lg_pp_term(S) -> lg_no(adposition(generic)) ; true ),
    lg_rules(Atoms, T, Conds, Items).

lg_rules(Atoms, T, Conds, Items) :-
    ( lg_has_obj(Atoms) -> lg_no(object(generic)) ; true ),
    findall(R, ( member(A, Atoms), lg_rule(A, T, Conds, R) ), Items).

%% A rule whose conclusion is its only condition says nothing new; a rule
%% with no condition is a fact of a variable (`Everything is mortal.').
lg_rule(A, _, [], fact(A)) :- !.
lg_rule(A, _, Conds, rule(A, B)) :- lg_body(Conds, B).

lg_facts(Conds, Atoms, Items) :-
    lg_inds_named(Conds, [], Used),
    lg_obj_facts(Atoms, Used, Plain, OFacts),
    append([Conds, OFacts, Plain], As),
    findall(fact(A), member(A, As), Items).

lg_body([B], B) :- !.
lg_body(Bs, and(Bs)).

%% One individual: a(T) for an indefinite noun phrase, T its term as in
%% the(T) (a(person), a(big(dog)), a(pl(book)), a(of(pair, a(pl(post)))));
%% since 1.77.0, a(Noun) through 1.76.0 and a_person through 1.75.0), and
%% something and someone.
lg_individual(_, Inds, T) :- member('$ind'(V, Shape), Inds), V == T, !, T = const(a(Shape)).
lg_individual(qp(_, thing), _, const(something)) :- !.
lg_individual(qp(_, person), _, const(someone)) :- !.
lg_individual(S, _, _) :- lg_no(determiner(S)).

%% WHEN (since 1.79.0): in the present, a rule as `if' is (`When liberty
%% becomes license dictatorship is near.': near(dictatorship) :-
%% become(liberty, license)); in a tense, each atom of the main clause is
%% linked to the when clause's one atom, modified(when(B), A), outside both
%% tenses: `The saw buckled when it hit a knot.' is
%% when(past(buckle(the(saw))), past(hit(the(saw), a(knot)))). A pronoun
%% subject of the when clause is the main subject where it agrees with it
%% (`it' the saw; `they' not the house), else a constant of its own.
lg_when(Main, Cond, Items) :-
    lg_parts(Main, S, Pred),
    lg_entity(S, ent(T, Conds, Q), SMs),
    lg_atoms(Main, T, Pred, Atoms0),
    lg_parts(Cond, S2, Pred2),
    (   lg_pron_agrees(S2, S) -> T2 = T, SMs2 = []
    ;   lg_entity(S2, ent(T2, _, Q2), SMs2), ( Q2 == const -> true ; lg_no(determiner(Q2)) )
    ),
    lg_atoms(Cond, T2, Pred2, Atoms20),
    lg_split_objs(Atoms20, Bs, BObjs),
    ( Bs = [B] -> true ; lg_no(subordinate(when)) ),
    lg_split_objs(Atoms0, As, AObjs),
    maplist(lg_wrap_when(B), As, Ws),
    partition(lg_is_ind, SMs, Inds, SObjs),
    exclude(lg_is_ind, SMs2, SObjs2),
    append([Ws, AObjs, SObjs, BObjs, SObjs2], Atoms),
    lg_assert(Q, T, Conds, Atoms, S, Inds, Items).

% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_wrap_when(B, A, modified(when(B), A)).

%% A pronoun of the third person agrees with a noun phrase of its number
%% and its kind: `it' with a thing's, `he' and `she' with a person's or a
%% name, `they' with any plural.
lg_pron_agrees(P, S) :-
    nonvar(P), P = pron(3, N, G), nonvar(S), nonvar(N),
    (   S = np(M, Num, _, _) -> N == Num, lg_pron_kind(N, G, M)
    ;   S = name(_) -> N == sg, nonvar(G), G \== n
    ;   S = of(_, NP) -> lg_pron_agrees(P, NP)
    ;   S = pron(3, N2, G2) -> N == N2, G == G2
    ).

lg_pron_kind(pl, _, _) :- !.
lg_pron_kind(sg, G, M) :-
    nonvar(G),
    ( typology_meaning(english, person, M) -> memberchk(G, [m, f]) ; G == n ).

%% IF: the conditional's conclusions are its main clause's atoms; its
%% conditions the main subject's own (person(X)), then the if clause's
%% atoms and their conditions. A pronoun subject of the if clause stands
%% for the main clause's subject; something and someone are the variable.
lg_conditional(Main, Cond, Items) :-
    lg_parts(Main, S, Pred),
    lg_entity(S, ent(T, Conds, _), SMs),
    lg_atoms(Main, T, Pred, Atoms0),
    exclude(lg_is_ind, SMs, SObjs),
    append(Atoms0, SObjs, Atoms),
    ( lg_has_obj(Atoms) -> lg_no(object(generic)) ; true ),
    lg_parts(Cond, S2, Pred2),
    (   nonvar(S2), S2 = pron(3, _, _) -> T2 = T, Conds2 = [], SMs2 = []
    ;   lg_entity(S2, ent(T2, Conds2, Q2), SMs2), ( Q2 == const -> true ; lg_no(determiner(Q2)) )
    ),
    lg_atoms(Cond, T2, Pred2, Atoms21),
    append(Atoms21, SMs2, Atoms20),
    lg_obj_conds(Atoms20, Atoms2, OConds2),
    append([Conds, Conds2, Atoms2, OConds2], Body),
    findall(R, ( member(A, Atoms), lg_rule(A, T, Body, R) ), Items).

%% ---- a clause's parts ---------------------------------------------------------------

lg_parts(C, _, _) :- var(C), !, lg_no(shape(C)).
lg_parts(copula(T, P, S, Pred), S, Pred) :- !, lg_present(T, P).
lg_parts(clause(V, T, P, S, O), S, verb(V, O)) :- !, lg_present(T, P).
lg_parts(clause(V, T, P, S, O, _), S, verb(V, O)) :- !,
    lg_present(T, P).
lg_parts(C, _, _) :- lg_no(shape(C)).

lg_present(T, P) :-
    ( lg_tense(T) -> true ; lg_no(tense(T)) ),
    ( P == pos -> true ; lg_no(negation) ).

%% Since 1.82.0 the imperative too: a command is its atoms in it, its
%% subject you (`Construct a proof.' is imperative(construct(you,
%% a(proof)))).
%% The progressive of a tense (since 1.102.0), prog(T): `The engine is
%% idling.' is progressive(idle(the(engine))).
lg_tense(T) :- atom(T), memberchk(T, [present, past, future, perfect, pluperfect, imperfect, imperative]).
lg_tense(prog(T)) :- atom(T), memberchk(T, [present, past, future, perfect, pluperfect]).

%% A clause's tense, and its atoms in it: present as they are, any other
%% each at(Tense, Atom).
lg_clause_tense(copula(T, _, _, _), T).
lg_clause_tense(clause(_, T, _, _, _), T).
lg_clause_tense(clause(_, T, _, _, _, _), T).

lg_tensed(present, As, As) :- !.
lg_tensed(_, [], []).
lg_tensed(T, [A|As], [at(T, A)|Bs]) :- lg_tensed(T, As, Bs).

%% The atoms a clause says of its subject's term T, in the clause's tense;
%% an object is a constant.
lg_atoms(C, T, Pred, Atoms) :-
    lg_atoms_(C, T, Pred, Atoms00),
    lg_split_objs(Atoms00, Atoms0, Objs),
    lg_clause_adjuncts(C, T, Js, JObjs),
    lg_adjuncted(Js, Atoms0, Atoms1),
    lg_clause_tense(C, Tn),
    lg_tensed(Tn, Atoms1, Atoms2),
    append([Atoms2, Objs, JObjs], Atoms).

%% AN INDEFINITE NOUN PHRASE THAT IS NO SUBJECT (an object since 1.74.0;
%% an adjunct's, a possessor and a possessed since 1.77.0) is a variable
%% at first, and its noun's conditions travel beside the atoms as
%% '$obj'(Shape, Var, Raw, Conds): Shape its term (letter, big(dog),
%% pl(book), of(bag, ...)), Var the term an atom names it by, Raw the term
%% a possessed's term names it by. A statement makes it an individual
%% (lg_obj_facts/3: Raw a(Shape), Var const(Raw), its conditions facts), a
%% question or a condition keeps the variable and its conditions in the
%% body (lg_obj_conds/3), a rule's conclusion has no form of it (`Every
%% boy sees a dog.': each boy may see another dog).
lg_split_objs([], [], []).
lg_split_objs([O|As], Ps, [O|Os]) :- O = '$obj'(_, _, _, _), !, lg_split_objs(As, Ps, Os).
lg_split_objs([A|As], [A|Ps], Os) :- lg_split_objs(As, Ps, Os).

%% An object's individual is named apart from the ones its sentence named
%% before it (since 1.89.0: `A dog sees a dog.' is see(a(dog), a(dog, 2));
%% through 1.88.0 a dog that sees itself). Used holds Shape-K pairs.
lg_obj_facts([], _, [], []).
lg_obj_facts(['$obj'(S, V, R, Cs)|As], Used, Ps, Fs) :- !,
    (   var(R)
    ->  lg_ind_free(S, Used, 1, K),
        ( K =:= 1 -> R = a(S) ; R = a(S, K) ),
        Used1 = [S-K|Used]
    ;   Used1 = Used
    ),
    V = const(R),
    lg_obj_facts(As, Used1, Ps, Fs0),
    append(Cs, Fs0, Fs).
lg_obj_facts([A|As], Used, [A|Ps], Fs) :- lg_obj_facts(As, Used, Ps, Fs).

lg_ind_free(S, Used, K0, K) :-
    (   member(S1-K0, Used), S1 =@= S -> K1 is K0 + 1, lg_ind_free(S, Used, K1, K) ; K = K0 ).

lg_obj_conds([], [], []).
lg_obj_conds(['$obj'(_, V, R, Cs)|As], Ps, Fs) :- !,
    R = V,
    lg_obj_conds(As, Ps, Fs0),
    append(Cs, Fs0, Fs).
lg_obj_conds([A|As], [A|Ps], Fs) :- lg_obj_conds(As, Ps, Fs).

lg_has_obj(Atoms) :- memberchk('$obj'(_, _, _, _), Atoms).

%% A clause's adjuncts at level 2: pp(Prep, Term) of a constant or (since
%% 1.77.0) an indefinite noun phrase's individual, its marks beside them;
%% adv(M), each adverb of a joined pair its own.
lg_clause_adjuncts(clause(_, _, _, _, _, Js), T, Ks, Os) :- !, lg_adjuncts(Js, T, Ks, Os).
lg_clause_adjuncts(_, _, [], []).

lg_adjuncts([], _, [], []).
lg_adjuncts([J|Js], T, Ks, Os) :-
    lg_adjunct(J, T, K1, O1),
    lg_adjuncts(Js, T, Ks2, Os2),
    append(K1, Ks2, Ks),
    append(O1, Os2, Os).

lg_adjunct(J, _, _, _) :- var(J), !, lg_no(adjunct(J)).
%% AN INFINITIVE OF PURPOSE (since 1.96.0) is the adjunct pp(to, Atom), its
%% atom said of the clause's subject: `He used pressure to stop the
%% bleeding.' is to(use(he, pressure), stop(he, the(bleeding))).
lg_adjunct(Inf, S, [pp(to, F)], []) :- lg_inf_parts(Inf, V2, O2, Js2), !,
    lg_inf_fun(S, V2, O2, Js2, F).
lg_adjunct(pp(P, NP), _, [pp(P, T)], Os) :- atom(P), !,
    lg_arg(adjunct, NP, T, _, Os).
lg_adjunct(adv(M), _, [adv(M)], []) :- atom(M), !.
lg_adjunct(adv(and(Ms)), _, Ks, []) :- is_list(Ms), forall(member(M, Ms), atom(M)), !,
    findall(adv(M), member(M, Ms), Ks).
lg_adjunct(J, _, _, _) :- lg_no(adjunct(J)).

%% Each atom inside its adjuncts, the first the innermost.
lg_adjuncted([], As, As) :- !.
lg_adjuncted(_, [], []).
lg_adjuncted(Js, [A|As], [B|Bs]) :- foldl(lg_wrap_adjunct, Js, A, B), lg_adjuncted(Js, As, Bs).

lg_wrap_adjunct(J, A, modified(J, A)).

lg_atoms_(copula(_, _, _, _), T, adj(As), Atoms) :- !,
    lg_ap_split(As, Ps, Aps),
    lg_adjectives(Ps, Ms),
    lg_preds_of(Ms, T, Atoms0),
    lg_ap_atoms(Aps, T, Atoms1, Os),
    append([Atoms0, Atoms1, Os], Atoms).
lg_atoms_(copula(_, _, _, _), T, np(N, _, D, As0), Atoms) :-
    memberchk(D, [indef, mass]), !,
    lg_np_aps(As0, As, XMs),
    lg_adjectives(As, Ms),
    lg_preds_of([N|Ms], T, Atoms0),
    append(Atoms0, XMs, Atoms).
%% A NOUN OF RELATION (since 1.78.0): a copula's noun phrase with a
%% possessor is a predicate of two, the noun's, of the subject and the
%% possessor: `John is Mary's father.' and `John is the father of Mary.'
%% are father(john, mary), `Sculpture is a form of art.' form(sculpture,
%% art). One with an adjective has no form yet (relation(adjective)): `the
%% main source of his frustration', `a mere skeleton of its former self'
%% say the adjective of the relation, not of the subject.
lg_atoms_(copula(_, _, _, _), T, of(P, NP), [pred(N, [T, Pc])|Ms]) :-
    nonvar(NP), NP = np(N, _, D, As), memberchk(D, [def, indef, mass]), !,
    ( As == [] -> true ; lg_no(relation(adjective)) ),
    lg_arg(possessor, P, Pc, _, Ms).
lg_atoms_(copula(_, _, _, _), T, pp(P, NP), [pred(P, [T, To])|Os]) :- atom(P), !,
    lg_arg(object, NP, To, _, Os).
lg_atoms_(copula(_, _, _, _), _, Pred, _) :- !, lg_no(predicate(Pred)).
lg_atoms_(_, T, verb(V, none), [pred(V, [T])]) :- !.
%% AN INFINITIVE AS A VERB'S OBJECT (since 1.95.0) is a term, to(Atom), its
%% atom the infinitive's verb said of the clause's own subject, with its
%% object and adjuncts: `He tried to catch her eye.' is pred(try,
%% [const(he), fun(to, [fun(catch, [const(he), const(of(eye, she))])])]),
%% Cocolog past(try(he, to(catch(he, of(eye, she))))). An indefinite noun
%% phrase in it is the term a(Shape) and no fact: the thing tried for
%% need not be (`The company tried to project an altruistic image.' is
%% past(try(the(company), to(project(the(company),
%% a(altruistic(image)))))), and no image(...) fact).
lg_atoms_(_, T, verb(V, Inf), [pred(V, [T, fun(to, [F])])]) :-
    lg_inf_parts(Inf, V2, O2, Js2), !,
    lg_inf_fun(T, V2, O2, Js2, F).
%% AN OBJECT AND ITS INFINITIVE (since 1.96.0): the infinitive's atom said
%% of the object's term, `Pressure causes plantar warts to develop a
%% painful callus.' cause(pressure, to(develop(a(pl(plantar(wart))),
%% a(painful(callus))))), the object's facts beside it.
lg_atoms_(_, T, verb(V, C2), [pred(V, [T, fun(to, [F])])|Os]) :-
    lg_oinf_parts(C2, NP, V2, O2, Js2), !,
    lg_arg(object, NP, To, _, Os),
    lg_inf_fun(To, V2, O2, Js2, F).

lg_inf_obj('$obj'(S, const(a(S)), a(S), _)).
%% AN OBJECT AND ITS COMPLEMENT (since 1.100.0): the complement's atom, a
%% copula's of the object (lg_atoms_/4 of copula(present, pos, Object,
%% Predicate)), is the verb's third argument, the object's facts beside it:
%% `They considered colonialism immoral.' is past(consider(they,
%% colonialism, immoral(colonialism))), `His landscapes were deemed the
%% acme of beauty.' past(deem(someone, of(pl(landscape), he),
%% acme(of(pl(landscape), he), beauty))). A COMPLEMENT OF SEVERAL ATOMS
%% (since 1.103.0), a noun phrase the copula says more than one atom of,
%% is the noun phrase's term, an indefinite one a(Shape) and no fact, as an
%% infinitive's object is: `A manned earth satellite was considered a
%% necessary research step.' is past(consider(someone,
%% a(manned(nn(earth, satellite))), a(necessary(nn(research, step))))),
%% the satellite's facts beside it. Any other complement of several atoms
%% (rich and famous) has no form yet (complement(Pred)).
lg_atoms_(_, T, verb(V, OC), [pred(V, [T, To, F])|Os]) :-
    nonvar(OC), OC = oc(NP, Pred), !,
    lg_arg(object, NP, To, _, Os),
    (   catch(lg_atoms_(copula(present, pos, NP, Pred), To, Pred, [A]), lg_no(_), fail)
    ->  lg_fun_of_atom(A, F)
    ;   lg_oc_term(Pred, F)
    ->  true
    ;   lg_no(complement(Pred))
    ).
lg_atoms_(_, T, verb(V, O), [pred(V, [T, To])|Os]) :-
    lg_arg(object, O, To, _, Os).

lg_oc_term(Pred, F) :-
    nonvar(Pred), ( Pred = np(_, _, _, _) ; Pred = of(_, _) ; Pred = np_pp(_, _) ), !,
    catch(lg_arg(object, Pred, F, _, Ms), lg_no(_), fail),
    (   Ms == [] -> true
    ;   Ms = [M], lg_inf_obj(M)
    ).

lg_inf_how(How, F, How2) :-
    findall(I, lg_fun_ind(F, I), Is),
    ( Is == [] -> How2 = How ; How2 = inds(Is, How) ).

lg_fun_ind(const(C), C) :- nonvar(C), ( C = a(_) ; C = a(_, _) ).
lg_fun_ind(fun(_, As), I) :- member(A, As), lg_fun_ind(A, I).

%% An infinitive's term: its atom said of S, an indefinite noun phrase in it
%% a term and no fact.
lg_inf_fun(S, V2, O2, Js2, F) :-
    lg_atoms(clause(V2, present, pos, none, O2, Js2), S, verb(V2, O2), [A2|Objs]),
    ( maplist(lg_inf_obj, Objs) -> true ; lg_no(object(infinitive)) ),
    lg_fun_of_atom(A2, F).

lg_oinf_parts(C, NP, V, O, Js) :-
    nonvar(C),
    (   C = clause(V, T, pos, NP, O) -> Js = [] ; C = clause(V, T, pos, NP, O, Js) ),
    T == infinitive.

lg_inf_parts(Inf, V, O, Js) :-
    nonvar(Inf),
    (   Inf = inf(V, O) -> Js = [] ; Inf = inf(V, O, Js) ).

%% An atom as the term Cocolog writes inside another's argument: a
%% predicate the term of its name and arguments, an adjunct's the term
%% round the atom's, as lg_out_atom/4 writes them; and back.
lg_fun_of_atom(pred(N, As), fun(N1, As)) :- !,
    length(As, Ar), lg_code_pred_name(N, Ar, N1).
lg_fun_of_atom(modified(pp(P, T), A), fun(N1, [F, T])) :- !,
    lg_fun_of_atom(A, F), lg_code_pred_name(P, 2, N1).
lg_fun_of_atom(modified(adv(M), A), fun(N1, [F])) :- !,
    lg_fun_of_atom(A, F), lg_code_pred_name(M, 1, N1).
lg_fun_of_atom(A, _) :- lg_no(infinitive(A)).

lg_atom_of_fun(fun(N1, [F, T]), modified(pp(P, T), A)) :-
    nonvar(F), F = fun(_, _),
    lg_code_meaning(N1, 2, P), typology_meaning(english, adposition, P), !,
    lg_atom_of_fun(F, A).
lg_atom_of_fun(fun(N1, [F]), modified(adv(M), A)) :-
    nonvar(F), F = fun(_, _),
    lg_code_meaning(N1, 1, M), typology_meaning(english, adverb, M), !,
    lg_atom_of_fun(F, A).
lg_atom_of_fun(fun(N1, As), pred(N, As)) :-
    length(As, Ar), lg_code_meaning(N1, Ar, N).

%% AN ADJECTIVE WITH AN ADPOSITION PHRASE (since 1.88.0), ap(A, pp(Prep,
%% NP)) in a copula's predicate, is the adjective's atom inside the
%% phrase, as a clause's adjunct is round the verb's: `The movie is
%% unsuitable for children.' is modified(pp(for, a(pl(child))),
%% pred(unsuitable, [const(the(movie))])), Cocolog
%% for(unsuitable(the(movie)), a(pl(child))). The phrase's noun phrase is a
%% constant or an indefinite one's individual, its facts after.
lg_ap_split([], [], []).
lg_ap_split([A|As], Ps, Aps) :-
    (   nonvar(A), A = ap(_, _) -> Aps = [A|Aps1], lg_ap_split(As, Ps, Aps1)
    ;   Ps = [A|Ps1], lg_ap_split(As, Ps1, Aps)
    ).

lg_ap_atoms([], _, [], []).
%% AN ADJECTIVE AND ITS INFINITIVE (since 1.96.0): a predicate of two, the
%% adjective's, of the subject and the infinitive's term, its atom said of
%% the subject: `She is liable to forget.' liable(she, to(forget(she))).
lg_ap_atoms([ap(A, Inf)|Xs], T, [pred(A, [T, fun(to, [F])])|As], Os) :-
    atom(A), lg_inf_parts(Inf, V2, O2, Js2), !,
    lg_inf_fun(T, V2, O2, Js2, F),
    lg_ap_atoms(Xs, T, As, Os).
lg_ap_atoms([ap(A, PP)|Xs], T, [modified(pp(P, To), At)|As], Os) :-
    ( lg_ap_adj(A, T, At), nonvar(PP), PP = pp(P, NP), atom(P) -> true ; lg_no(predicate(adj(ap(A, PP)))) ),
    lg_arg(adjunct, NP, To, _, Os1),
    lg_ap_atoms(Xs, T, As, Os2),
    append(Os1, Os2, Os).

lg_ap_adj(A, T, pred(A, [T])) :- atom(A), !.
lg_ap_adj(adv(M, A), T, modified(adv(M), pred(A, [T]))) :- atom(M), atom(A).

%% A noun phrase's adjectives with an adposition phrase (since 1.91.0):
%% each ap(A, pp(Prep, NP)) the item ap(A, Prep, V, X), V its noun phrase
%% as an argument and X its term (lg_arg/5), and the marks of its
%% indefinite noun phrases.
lg_has_ap(As) :- is_list(As), member(X, As), nonvar(X), X = ap(_, _), !.

lg_np_aps([], [], []).
lg_np_aps([X|Xs], [Y|Ys], Ms) :-
    (   nonvar(X), X = ap(A, PP)
    ->  ( atom(A), nonvar(PP), PP = pp(P, NP), atom(P) -> true ; lg_no(adjective(X)) ),
        lg_arg(adposition, NP, V, Raw, Ms1), Y = ap(A, P, V, Raw)
    ;   Y = X, Ms1 = []
    ),
    lg_np_aps(Xs, Ys, Ms2),
    append(Ms1, Ms2, Ms).

%% The adjectives of a phrase, a joined pair's items each, and its nouns
%% before its noun as they are (n(M), since 1.87.0).
%% An adjective with an adposition phrase (ap/4, since 1.91.0) is kept as
%% it is, never copied: its argument may be an individual's variable.
lg_adjectives([], []).
lg_adjectives([A|As], Ms) :-
    (   nonvar(A), A = ap(_, _, _, _) -> Ms = [A|Ms1]
    ;   findall(M, lg_adjective(A, M), Ms0), append(Ms0, Ms1, Ms)
    ),
    lg_adjectives(As, Ms1).

lg_adjective(A, M) :-
    (   atom(A) -> M = A
    ;   nonvar(A), A = and(Bs) -> member(M, Bs)
    ;   nonvar(A), A = n(X), atom(X) -> M = A
    ;   nonvar(A), A = adv(Ad, B), atom(Ad), atom(B) -> M = A
    ;   lg_no(predicate(adj(A)))
    ).

%% ---- noun phrases ---------------------------------------------------------------

%% A noun phrase's entity, ent(Term, Conds, Q), and the marks of the
%% indefinite noun phrases in it: '$ind'(Var, Shape) for itself where it
%% is indefinite (its individual, lg_individual/3), and its possessor's
%% '$obj' marks (lg_arg/5).
lg_entity(X, _, _) :- var(X), !, lg_no(shape(X)).
%% AN ADJECTIVE WITH AN ADPOSITION PHRASE IN A NOUN PHRASE (since 1.91.0):
%% ap(A, pp(Prep, NP)), its phrase's noun phrase an argument (lg_np_aps/3),
%% is in the term A(T, Prep, X) round the noun's (`a calyx adnate to the
%% ovary' a(adnate(calyx, to, the(ovary)))) and said of the term as a
%% copula's phrase is, the adjective's atom inside the phrase
%% (to(adnate(K), the(ovary))). Its individual's facts come after the
%% noun phrase's.
lg_entity(np(N, Num, D, As0), E, Ms) :- lg_has_ap(As0), !,
    lg_np_aps(As0, As, XMs),
    lg_entity(np(N, Num, D, As), E, Ms0),
    append(Ms0, XMs, Ms).
lg_entity(name(N), ent(const(C), [], const), []) :- !, lg_name_atom(N, C).
lg_entity(np(N, Num, def, As), ent(const(the(T)), [], const), []) :- memberchk(Num, [sg, pl]), !,
    lg_np_term(N, Num, As, T).
lg_entity(np(N, _, mass, As), ent(const(T), [], const), []) :- !,
    lg_np_term(N, sg, As, T).
lg_entity(np(N, _, D, As), ent(V, Conds, every), []) :- memberchk(D, [every, each, all]), !,
    lg_noun_conds(N, As, V, Conds).
lg_entity(np(N, Num, D, As), ent(V, Conds, generic), ['$ind'(V, T)]) :- D == indef, !,
    lg_noun_conds(N, As, V, Conds),
    lg_np_term(N, Num, As, T).
lg_entity(np(N, Num, some, As), ent(V, Conds, some), ['$ind'(V, T)]) :- !,
    lg_noun_conds(N, As, V, Conds),
    lg_np_term(N, Num, As, T).
lg_entity(qp(every, _), ent(_, [], every), []) :- !.
lg_entity(qp(some, _), ent(_, [], some), []) :- !.
lg_entity(wh(_), ent(_, [], wh), []) :- !.
lg_entity('$const'(C), ent(const(C), [], const), []) :- !.
lg_entity(of(P, NP), E, Ms) :- !, lg_possessed(P, NP, E, Ms).
lg_entity(np_pp(H, pp(P, X)), E, Ms) :- !, lg_np_pp(H, P, X, E, Ms).
%% A NOUN AND ITS INFINITIVE (since 1.96.0) is a term as a noun and its
%% adposition phrase is, to(T, Atom), the atom said of someone: `A knowing
%% attempt to defraud.' is the individual a(to(knowing(attempt),
%% defraud(someone))).
lg_entity(np_pp(H, Inf), E, Ms) :- lg_inf_parts(Inf, V2, O2, Js2), !,
    lg_inf_fun(const(someone), V2, O2, Js2, F),
    lg_out_term(F, [], _, Xc),
    ( ground(Xc) -> true ; lg_no(shape(np_pp(H, Inf))) ),
    lg_np_pp_c(H, to, Xc, [], E, Ms).
lg_entity(pron(P, N, K), ent(const(C), [], const), []) :- lg_pron_const(pron(P, N, K), C), !.
lg_entity(pron(_, _, _), _, _) :- !, lg_no(pronoun).
lg_entity(np(_, _, D, _), _, _) :- !, lg_no(determiner(D)).
lg_entity(qp(Q, _), _, _) :- !, lg_no(determiner(Q)).
lg_entity(X, _, _) :- lg_no(shape(X)).

%% A NOUN PHRASE AS AN ARGUMENT (an object, an adjunct's, a copula's
%% adposition phrase's, a possessor): a constant, or (since 1.77.0 where
%% it is no object) an indefinite one, then a '$obj' mark; anything else
%% has no form there, its reason K(Q) (object(every), adjunct(some)). Raw
%% is the term a possessed's term names it by: the constant, or the
%% individual's a(Shape), or the variable. `someone' and `something' are
%% the one individual a subject of them is (since 1.99.0: `The critics
%% praised someone.' is past(praise(the(pl(critic)), someone)), which a
%% passive's agent with its patient unsaid says).
lg_arg(K, X, V, Raw, Ms) :-
    lg_entity(X, ent(T, Conds, Q), Ms0),
    (   Q == const
    ->  V = T, T = const(Raw), Ms = Ms0
    ;   Q == some, nonvar(X), X = qp(_, Kind), lg_someone(Kind, Raw)
    ->  V = const(Raw), Ms = Ms0
    ;   Q == generic, Ms0 = ['$ind'(V0, Shape)|Rest]
    ->  V = V0, Ms = ['$obj'(Shape, V, Raw, Conds)|Rest]
    ;   Why =.. [K, Q], lg_no(Why)
    ).

lg_noun_conds(N, As, V, Cs) :-
    lg_adjectives(As, Ms),
    lg_preds_of([N|Ms], V, Cs).

%% The atoms of meanings said of one term; never by findall/3, which would
%% copy the term apart from the rule's other atoms.
lg_preds_of([], _, []).
lg_preds_of([M|Ms], T, [P|Ps]) :- lg_pred_of(M, T, P), lg_preds_of(Ms, T, Ps).

%% A NOUN BEFORE A NOUN (since 1.87.0) is no atom of one argument (a glove
%% compartment is no glove): nn(Modifier, Thing), the noun-compound
%% relation of the two, which says nothing more of how they are related
%% (`a leather jacket' nn(leather, X), `life support' nn(life, X)).
lg_pred_of(n(X), T, pred(nn, [const(X), T])) :- !.
%% AN ADVERB THAT GRADES AN ADJECTIVE (since 1.90.0) is round the
%% adjective's atom, as a clause's adverb is round its verb's: `She was
%% incurably optimistic.' is past(incurably(optimistic(she))), `a perfectly
%% natural explanation' says perfectly(natural(T)).
lg_pred_of(adv(M, A), T, modified(adv(M), pred(A, [T]))) :- !.
%% An adjective with an adposition phrase (since 1.91.0): the adjective's
%% atom inside the phrase, `a calyx adnate to the ovary' to(adnate(T),
%% the(ovary)).
lg_pred_of(ap(A, P, V, _), T, modified(pp(P, V), pred(A, [T]))) :- !.
lg_pred_of(M, T, pred(M, [T])).

%% A NOUN PHRASE'S TERM (since 1.76.0): its noun inside its adjectives,
%% the first adjective the outermost, and pl round them for a plural:
%% `big old dog' big(old(dog)), `the small children' the(pl(small(child))).
%% A definite noun phrase is the(T), a bare noun T itself (music,
%% apparent(motion)). Through 1.75.0 the constant was one atom,
%% the_small_children, its structure in its spelling (1.75.0's form).
lg_np_term(N, Num, As, T) :-
    lg_adjectives(As, Ms),
    reverse(Ms, Rs),
    foldl(lg_wrap1, Rs, N, T0),
    ( Num == pl -> T = pl(T0) ; T = T0 ).

lg_wrap1(n(M), X, nn(M, X)) :- !.
lg_wrap1(ap(A, P, _, Raw), X, T) :- !, T =.. [A, X, P, Raw].
lg_wrap1(adv(M, A), X, T) :- !,
    ( lg_grade_adverb(M) -> true ; lg_no(adjective(adv(M, A))) ),
    T0 =.. [A, X], T =.. [M, T0].
lg_wrap1(M, X, T) :- T =.. [M, X].

%% A POSSESSOR (since 1.73.0): the possessed and its possessor are one
%% term, of(Possessed, Possessor) since 1.76.0: `his spot' is of(spot, he),
%% `John's dog' of(dog, john), `the edge of the bed' and `the bed's edge'
%% of(edge, the(bed)), `the boy's dog's house' of(house, of(dog,
%% the(boy))), `his hands' of(pl(hand), he). A definite or a bare possessed
%% is a constant (`in favor of landlords': of(favor, ...)); an indefinite
%% one an individual's shape (`a book of stamps': a(of(book,
%% a(pl(stamp))))). The possessor is a constant or an indefinite noun
%% phrase (`the status of a classic': of(status, a(classic))). The bare
%% possessed, the indefinite possessed and the indefinite possessor since
%% 1.77.0.
lg_possessed(P, NP, E, Ms) :-
    lg_arg(possessor, P, _, Pc, PMs),
    ( nonvar(NP), NP = np(N, Num, D, As) -> true ; lg_no(shape(NP)) ),
    (   D == def
    ->  lg_np_term(N, Num, As, T), E = ent(const(of(T, Pc)), [], const), Ms = PMs
    ;   D == mass
    ->  lg_np_term(N, sg, As, T), E = ent(const(of(T, Pc)), [], const), Ms = PMs
    ;   D == indef
    ->  lg_np_term(N, Num, As, T), lg_noun_conds(N, As, V, Conds),
        E = ent(V, Conds, generic), Ms = ['$ind'(V, of(T, Pc))|PMs]
    ;   lg_no(determiner(D))
    ).

%% A NOUN PHRASE WITH AN ADPOSITION PHRASE AFTER IT (since 1.83.0): the
%% phrase is in the term, as a possessor is, Prep(T, X) round the head's
%% term (`the man with the hat' the(with(man, the(hat))), `a dip in
%% prices' the individual a(in(dip, a(pl(price)))), `the elevation of the
%% temperature in the afternoon' in(of(elevation, the(temperature)),
%% the(afternoon))), X a constant or an indefinite noun phrase, whose
%% individual's facts come after; a head of `every' or `some' has none.
lg_np_pp(H, P, X, E, Ms) :-
    ( atom(P) -> true ; lg_no(adposition(P)) ),
    lg_arg(adposition, X, _, Xc, XMs),
    lg_np_pp_c(H, P, Xc, XMs, E, Ms).

lg_np_pp_c(H, P, Xc, XMs, E, Ms) :-
    (   nonvar(H), H = np(N, Num, D, As)
    ->  lg_np_term(N, Num, As, T0), T =.. [P, T0, Xc],
        (   D == def -> E = ent(const(the(T)), [], const), Ms = XMs
        ;   D == mass -> E = ent(const(T), [], const), Ms = XMs
        ;   D == indef
        ->  lg_noun_conds(N, As, V, Conds),
            E = ent(V, Conds, generic), Ms = ['$ind'(V, T)|XMs]
        ;   lg_no(determiner(D))
        )
    ;   nonvar(H), H = of(Pr, NP)
    ->  lg_possessed(Pr, NP, E0, Ms0),
        (   E0 = ent(const(C0), [], const)
        ->  C =.. [P, C0, Xc], E = ent(const(C), [], const), append(Ms0, XMs, Ms)
        ;   E0 = ent(V, Conds, generic), Ms0 = ['$ind'(V0, S0)|R], V0 == V
        ->  S =.. [P, S0, Xc], E = ent(V, Conds, generic), append(['$ind'(V, S)|R], XMs, Ms)
        ;   lg_no(shape(H))
        )
    ;   lg_no(shape(H))
    ).

%% A PRONOUN WITH NO REFERENT (since 1.72.0) is a constant of its own, its
%% word as a subject: he, she, it, they, i, we, you. All the sentences that
%% say `he' share one he; a text's pronoun that refers to a noun is that
%% noun's (lg_text_read/3). A pronoun of the third person singular whose
%% gender is not known has none.
lg_pron_const(pron(1, N, _), C) :- N == sg, !, C = i.
lg_pron_const(pron(1, N, _), C) :- N == pl, !, C = we.
lg_pron_const(pron(P, _, _), you) :- ( P == 2 ; P == polite ), !.
lg_pron_const(pron(3, N, _), they) :- N == pl, !.
%% a subject no words say (pron(3, sg, zero), since 1.86.0) is someone
lg_pron_const(pron(3, N, G), C) :- N == sg, atom(G), memberchk(G-C, [m-he, f-she, n-it, zero-someone]).

%% A name's constant: its words lowered, joined by `_' (`John Smith' is
%% john_smith).
lg_name_atom(N, C) :-
    downcase_atom(N, D),
    atomic_list_concat(Ws, ' ', D),
    atomic_list_concat(Ws, '_', C).

%% ---- variables ------------------------------------------------------------------

%% An item's variables, var(1), var(2), ... by their first use.
lg_number(Item0, Item) :-
    copy_term(Item0, Item1),
    lg_fix(Item1, Item),
    term_variables(Item, Vs),
    lg_bind(Vs, 1).

%% A constant with a variable in it is a compound term (since 1.77.0): `Who
%% has the hands of a surgeon?' names fun(of, [fun(pl, [const(hand)]),
%% var(2)]), as Cocolog's reader reads of(pl(hand), B).
lg_fix(X, X) :- var(X), !.
lg_fix(const(C), T) :- !, ( ground(C) -> T = const(C) ; lg_in_term(C, T) ).
lg_fix(X, Y) :- compound(X), !, X =.. [F|As], maplist(lg_fix, As, Bs), Y =.. [F|Bs].
lg_fix(X, X).

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
           lg_code_class/3, lg_code_tense/3, '$lg_lex'/3.

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

lg_out_atom(at(T, P), M0, M, A) :- !,
    lg_out_atom(P, M0, M, P1),
    lg_code_tense(cocolog, T, W),
    A =.. [W, P1].
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_out_atom(modified(when(B), At), M0, M, A) :- !,
    lg_out_atom(At, M0, M1, At1),
    lg_out_atom(B, M1, M, B1),
    lg_code_pred_name(when, 2, N),
    A =.. [N, At1, B1].
lg_out_atom(modified(pp(P, T), At), M0, M, A) :- !,
    lg_out_atom(At, M0, M1, At1),
    lg_out_term(T, M1, M, T1),
    lg_code_pred_name(P, 2, N),
    A =.. [N, At1, T1].
lg_out_atom(modified(adv(Ad), At), M0, M, A) :- !,
    lg_out_atom(At, M0, M, At1),
    lg_code_pred_name(Ad, 1, N),
    A =.. [N, At1].
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
lg_in_atom(A, at(T, P)) :-
    compound(A), A =.. [W, Inner], compound(Inner), \+ lg_det_term(Inner),
    lg_code_tense(cocolog, T, W), !,
    lg_in_atom(Inner, P).
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_in_atom(A, modified(when(B), At)) :-
    compound(A), A =.. [N, Inner, Sub], lg_adjunct_inner(Inner), lg_adjunct_inner(Sub),
    lg_code_meaning(N, 2, when), !,
    lg_in_atom(Inner, At),
    lg_in_atom(Sub, B).
lg_in_atom(A, modified(pp(P, T), At)) :-
    compound(A), A =.. [N, Inner, Arg], lg_adjunct_inner(Inner),
    lg_code_meaning(N, 2, P), typology_meaning(english, adposition, P), !,
    lg_in_atom(Inner, At),
    (   P == to, lg_purpose_arg(Inner, Arg) -> lg_in_atom_term(Arg, T) ; lg_in_term(Arg, T) ).

%% An infinitive of purpose's atom (since 1.96.0): said of the clause's own
%% subject, so to(make(they, a(pl(arrangement))), in(meet(they), chicago))
%% is no adposition phrase of a noun phrase `they meet in Chicago'.
lg_purpose_arg(Inner, Arg) :-
    compound(Arg), lg_atom_subject(Inner, S), lg_atom_subject(Arg, S2), S2 == S.

lg_atom_subject(A, S) :-
    compound(A), A =.. [N, X1|Xs],
    (   compound(X1), length(Xs, K), K =< 1, Ar is K + 1,
        lg_code_meaning(N, Ar, M), lg_round_word(K, M)
    ->  lg_atom_subject(X1, S)
    ;   S = X1
    ).
lg_in_atom(A, modified(adv(M), At)) :-
    compound(A), A =.. [N, Inner], lg_adjunct_inner(Inner),
    lg_code_meaning(N, 1, M), typology_meaning(english, adverb, M),
    ( \+ lg_copula_atom(Inner) -> true ; lg_grade_adverb(M) ), !,
    lg_in_atom(Inner, At).
%% A verb's third argument said of its second is an object's complement
%% (since 1.100.0), an atom, not a constant's term: consider(they,
%% colonialism, immoral(colonialism)) has immoral(colonialism) as
%% a(fair(trial)) has fair(trial), and leave(the(accident), she,
%% badly(shaken(she))) an adverb round it.
lg_in_atom(A, pred(N, As1)) :-
    A =.. [N1|As], length(As, Ar),
    lg_code_meaning(N1, Ar, N),
    (   As = [X, Y, Z], compound(Z), lg_atom_subject(Z, S2), S2 == Y
    ->  lg_in_term(X, T1), lg_in_term(Y, T2), lg_in_atom_term(Z, T3),
        As1 = [T1, T2, T3]
    ;   maplist(lg_in_term, As, As1)
    ).

%% An adjunct's atom: a compound term that is no list (size([a], 1) is a
%% predicate of a list).
%% An adverb's atom is no copula's (since 1.81.0): an atom that is a
%% constant's term too, its name an adjective and no verb, is said by a
%% copula, which takes no adjunct, so good(good(taste)) is the predicate
%% good of good(taste) (`Good taste.'), never the adverb good of
%% good(taste); quietly(slowly(sing(mary))) keeps both adverbs.
lg_copula_atom(T) :-
    lg_const_term(T),
    T =.. [N, _], lg_code_meaning(N, 1, M),
    \+ catch(typology_meaning(english, verb, M), _, fail).

lg_adjunct_inner(T) :- compound(T), \+ is_list(T), \+ T = [_|_], \+ lg_det_term(T).

%% A CONSTANT'S TERM in Cocolog (since 1.76.0): the(T), a(Noun), of(T,
%% Possessor) and, where the English template is loaded, a bare noun with
%% an adjective (apparent(motion)); T a noun inside adjectives and pl.
%% the, a, of and pl name terms, never predicates, so past(the(dog)) is
%% the predicate past of the dog, not the tense of the(dog). A tense's and
%% an adjunct's atom is told from these alone (lg_det_term/1): a bare noun
%% with an adjective is a term only as an argument, as live(john) in
%% in(live(john), paris) is an atom, `live' an adjective too.
lg_const_term(T) :-
    lg_det_term(T), !.
lg_const_term(T) :-
    compound(T), ground(T),
    T =.. [A, X], \+ memberchk(A, [the, a, of, pl]), lg_np_shape(X),
    catch(typology_meaning(english, adjective, A), _, fail).
lg_const_term(T) :- ground(T), lg_pp_shape(T).
%% A bare noun with a graded adjective (since 1.90.0): very(hot(water)).
lg_const_term(T) :-
    compound(T), ground(T), T =.. [M, Y], lg_grade_adverb(M), lg_const_term(Y).
%% A bare noun with an adjective's adposition phrase (since 1.91.0):
%% suitable(water, for, a(pl(use))).
lg_const_term(T) :- ground(T), lg_ap_shape(T).
%% A bare noun with a noun before it (since 1.87.0): nn(life, support).
lg_const_term(nn(M, X)) :- ground(X), atom(M), lg_np_shape(X).

lg_det_term(T) :-
    compound(T), ground(T),
    (   T = the(X) -> ( lg_np_shape(X) -> true ; lg_pp_shape(X) -> true ; lg_to_shape(X) )
    ;   T = a(X) -> ( X = of(Y, P) -> lg_np_shape(Y), lg_poss_term(P) ; lg_np_shape(X) -> true ; lg_pp_shape(X) -> true ; lg_to_shape(X) )
    ;   T = a(X, K) -> integer(K), K > 1, lg_det_term(a(X))
    ;   T = of(X, P) -> lg_np_shape(X), \+ lg_ap_atom(X), lg_poss_term(P)
    ).

%% An adjective's atom of a pronoun or of a name that is no noun is no
%% possessed's term, so past(of(aware(he), the(danger))) is the tense of an
%% adjective's `of' phrase (since 1.88.0: `He was aware of the danger.'),
%% where of(big(dog), he) is his big dog. A name that is a noun too (john,
%% a toilet's) is read as the possessed.
lg_ap_atom(X) :-
    compound(X), X =.. [M, Y], lg_grade_adverb(M), !, lg_ap_atom(Y).
lg_ap_atom(X) :-
    compound(X), X =.. [F, Y], atom(Y),
    catch(typology_meaning(english, adjective, F), _, fail),
    \+ catch(typology_meaning(english, noun, Y), _, fail).

lg_poss_term(P) :- ( atom(P) -> true ; lg_const_term(P) ).

%% A noun's term with an adjective's adposition phrase (since 1.91.0):
%% A(T, Prep, X), A an adjective of the English template, Prep an
%% adposition, T a noun's term, X a constant.
lg_ap_shape(S) :-
    compound(S), S =.. [A, T, P, X], atom(A), atom(P),
    catch(typology_meaning(english, adposition, P), _, fail),
    catch(typology_meaning(english, adjective, A), _, fail),
    lg_np_shape(T), lg_poss_term(X).

%% A noun phrase's term with an adposition phrase (since 1.83.0):
%% Prep(T, X) where the English template's adposition is Prep, T a noun's
%% term or a possessed's or one of these, X a constant (the(with(man,
%% the(hat)))).
lg_pp_shape(S) :-
    compound(S), S =.. [P, T, X], P \== of,
    catch(typology_meaning(english, adposition, P), _, fail),
    ( lg_np_shape(T) -> true ; T = of(Y, Z) -> lg_np_shape(Y), lg_poss_term(Z) ; lg_pp_shape(T) ),
    lg_poss_term(X).

%% A noun with its infinitive (since 1.96.0): to(attempt, defraud(someone)),
%% the infinitive's atom said of someone, its adjuncts around it
%% (in(explain(someone, it), the(world))).
lg_to_shape(to(Y, Z)) :- lg_np_shape(Y), lg_inf_shape(Z).

lg_inf_shape(Z) :-
    compound(Z), functor(Z, F, _), \+ memberchk(F, [the, a, of, pl, nn, to]),
    arg(1, Z, A),
    (   A == someone -> true ; lg_inf_shape(A) ).

%% An infinitive's atom read as a term (since 1.96.0): never a constant,
%% the atom an adjunct is round an atom too, so by(find_out(he),
%% indirection) is no noun phrase `he find_out by indirection'.
lg_in_atom_term(X, fun(N, [F1|Ts])) :-
    X =.. [N, X1|Xs], compound(X1), length(Xs, K), K =< 1,
    Ar is K + 1, lg_code_meaning(N, Ar, M), lg_round_word(K, M), !,
    lg_in_atom_term(X1, F1),
    maplist(lg_in_term, Xs, Ts).
lg_in_atom_term(X, fun(N, Ts)) :-
    X =.. [N|Xs], maplist(lg_in_term, Xs, Ts).

lg_round_word(1, M) :- catch(typology_meaning(english, adposition, M), _, fail).
lg_round_word(0, M) :- catch(typology_meaning(english, adverb, M), _, fail).

lg_np_shape(X) :- atom(X), !.
lg_np_shape(pl(X)) :- !, lg_np_shape(X).
lg_np_shape(nn(M, X)) :- !, atom(M), lg_np_shape(X).
lg_np_shape(X) :- lg_ap_shape(X), !.
lg_np_shape(X) :- compound(X), X =.. [A, Y], atom(A), \+ memberchk(A, [the, a, of]), lg_np_shape(Y).

%% A name read back: the prefix off where the rest is a reserved name of
%% that arity, a row's meaning, else the name.
lg_code_meaning(N1, Ar, N) :-
    lg_code_reserved_prefix(cocolog, P),
    (   atom_concat(P, N0, N1), lg_reserved(N0, Ar) -> true ; N0 = N1 ),
    (   lg_code_name(cocolog, M/Ar, N0) -> N = M ; N = N0 ).

lg_in_term(V, V) :- var(V), !.
lg_in_term(L, list(Ts)) :- is_list(L), !, maplist(lg_in_term, L, Ts).
lg_in_term(A, const(A)) :- atom(A), !.
lg_in_term(to(X), fun(to, [F])) :- compound(X), !, lg_in_atom_term(X, F).
lg_in_term(T, const(T)) :- lg_const_term(T), !.
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
%% noun (person(a(person))), its adjectives' and one more, which level 2 made
%% from one sentence (`A person likes music.', its second reading).
%%
%% THE WORD CLASS of a predicate is the template's row (lg_code_class/3),
%% else the language's tables (typology_meaning/3): an adjective, then a
%% noun, then a verb of one argument, a verb of two.

logic_write(L, utterance(_, Items), Text) :-
    must_be(atom, L),
    lg_code_loaded(cocolog),
    lg_groups(Items, Groups),
    lg_say_all(L, Groups, Said),
    findall(S, member(S-_, Said), Ss),
    atomic_list_concat(Ss, ' ', Text).

%% Each group's sentence and how it was said (sentence, general). A group
%% no sentence says alone that names an individual an earlier group
%% brought in (a(dog)) is said again with a pronoun for it, kept where the
%% text so far reads back to the items so far (since 1.72.0): `A dog
%% barked. It was hungry.'; an individual inside a term too, as a
%% possessor's pronoun (since 1.77.0): `Its addition was major.'
lg_say_all(L, Groups, Said) :- lg_say_all(L, Groups, [], [], Said).

lg_say_all(_, [], _, _, []).
lg_say_all(L, [G|Gs], Ss0, Done, [S-How|Said]) :-
    lg_say(L, G, S1, How1),
    (   How1 == general, lg_say_again(L, G, Ss0, Done, S2)
    ->  S = S2, How = sentence
    ;   S = S1, How = How1
    ),
    append(Ss0, [S], Ss1),
    append(Done, G, Done1),
    lg_say_all(L, Gs, Ss1, Done1, Said).

lg_say_again(L, [fact(A)], Ss0, Done, S) :-
    member(F, Done), lg_individual_fact(F, N, C),
    lg_core(A, pred(_, Args)), lg_names_in(C, Args),
    (   typology_meaning(L, person, N) -> member(P, [pron(3, sg, m), pron(3, sg, f)]) ; P = pron(3, sg, n) ),
    lg_atom_ir(L, A, sub(C, P), IR),
    catch(typology_write(L, IR, S), _, fail),
    append(Ss0, [S], Ss1), atomic_list_concat(Ss1, ' ', Text),
    append(Done, [fact(A)], Want),
    catch(logic_readings(L, Text, Us), _, fail),
    member(utterance(_, Is), Us), Is == Want, !.

lg_groups([], []).
lg_groups(Is, [G|Gs]) :-
    lg_phrase_group(Is, G, Rest), !,
    lg_groups(Rest, Gs).
lg_groups([F|Is], [[F|Run]|Gs]) :-
    lg_individual_fact(F, _, C),
    lg_run(Is, [C], Run, Rest), Run \== [], !,
    lg_groups(Rest, Gs).
lg_groups([I|Is], [[I]|Gs]) :- lg_groups(Is, Gs).

%% A NOUN PHRASE ALONE'S GROUP (since 1.81.0): the facts a noun phrase
%% alone says of its term (lg_term_facts/2: `A heavy coat.' coat and
%% heavy of a(heavy(coat))), where they begin the items; an individual's
%% only where no item after them names it, which its own run takes (`A
%% big dog barked.', `A person likes a dog.').
lg_phrase_group([F|Is], G, Rest) :-
    F = fact(pred(_, [const(C)])), nonvar(C),
    lg_term_facts(C, G),
    append(G, Rest, [F|Is]),
    \+ ( lg_ind_shape(C, _), member(I, Rest), lg_names_in(C, I) ).

%% The facts a noun phrase alone says of its term (as lg_phrase/2 makes
%% them): its noun's, its adjectives' (the first the outermost), and an
%% indefinite possessor's own after them.
lg_term_facts(a(S), Fs) :- !, lg_shape_facts(S, const(a(S)), Fs).
lg_term_facts(a(S, K), Fs) :- integer(K), !, lg_shape_facts(S, const(a(S, K)), Fs).
lg_term_facts(the(T), Fs) :- !, lg_shape_facts(T, const(the(T)), Fs).
lg_term_facts(of(T, P), Fs) :- !, lg_shape_facts(of(T, P), const(of(T, P)), Fs).
lg_term_facts(T, Fs) :- lg_shape_facts(T, const(T), Fs).

lg_shape_facts(of(T, P), K, Fs) :- !,
    lg_np_facts(T, K, Fs0),
    (   nonvar(P), lg_ind_shape(P, _) -> lg_term_facts(P, Fs1) ; Fs1 = [] ),
    append(Fs0, Fs1, Fs).
lg_shape_facts(S, K, Fs) :- lg_pp_term(S), !,
    S =.. [_, T, X],
    lg_shape_facts(T, K, Fs0),
    (   nonvar(X), lg_ind_shape(X, _) -> lg_term_facts(X, Fs1) ; Fs1 = [] ),
    append(Fs0, Fs1, Fs).
lg_shape_facts(T, K, Fs) :- lg_np_facts(T, K, Fs).

%% A term of an adposition phrase after a noun (since 1.83.0): Prep(T, X),
%% two arguments, any name but of.
lg_pp_term(S) :- compound(S), S =.. [P, _, _], atom(P), P \== of, P \== nn.

lg_np_facts(T, _, _) :- var(T), !, fail.
lg_np_facts(pl(T), K, Fs) :- !, lg_np_facts(T, K, Fs).
lg_np_facts(T, K, [fact(pred(N, [K]))|AFs]) :-
    lg_np_parts(T, N, As),
    findall(F, ( member(A, As), lg_pred_of(A, K, P), F = fact(P) ), AFs0),
    findall(F, ( member(ap(_, _, _, R), As), lg_ind_shape(R, _), lg_term_facts(R, Fs), member(F, Fs) ), IFs),
    append(AFs0, IFs, AFs).

%% The individuals a term holds, itself among them.
lg_term_individuals(C, Cs) :- lg_term_inds(C, Cs, []).

lg_term_inds(X, Cs, Cs) :- \+ compound(X), !.
lg_term_inds(X, [X|Cs0], Cs) :- lg_ind_shape(X, _), !, X =.. [_|As], lg_term_inds_list(As, Cs0, Cs).
lg_term_inds(X, Cs0, Cs) :- X =.. [_|As], lg_term_inds_list(As, Cs0, Cs).

lg_term_inds_list([], Cs, Cs).
lg_term_inds_list([A|As], Cs0, Cs) :- lg_term_inds(A, Cs0, Cs1), lg_term_inds_list(As, Cs1, Cs).

lg_individual_fact(fact(pred(N, [const(C)])), N, C) :- nonvar(C), lg_ind_shape(C, S), lg_shape_head(S, N1), N1 == N.

%% The noun an individual's shape is of: book of pl(book) and of
%% of(large(book), a(pl(stamp))).
lg_shape_head(S, _) :- var(S), !, fail.
lg_shape_head(of(T, _), N) :- !, lg_shape_head(T, N).
lg_shape_head(S, N) :- lg_pp_term(S), !, arg(1, S, T), lg_shape_head(T, N).
lg_shape_head(pl(T), N) :- !, lg_shape_head(T, N).
lg_shape_head(nn(_, T), N) :- !, lg_shape_head(T, N).
lg_shape_head(N, N) :- atom(N), !.
lg_shape_head(T, N) :- compound(T), T =.. [_, X, _, _], !, lg_shape_head(X, N).
lg_shape_head(T, N) :- compound(T), T =.. [_, X], lg_shape_head(X, N).

%% The individuals' facts of one sentence: the noun facts of the ones it
%% brings in (a(person), then a(dog), since 1.74.0), their adjectives'
%% (plain facts of one argument), and then one more; a fact in a tense or
%% with an adjunct, or of two arguments, ends the run.
lg_run([I|Is], Cs, [I|Run], Rest) :-
    lg_individual_fact(I, _, C), !,
    lg_run(Is, [C|Cs], Run, Rest).
%% An individual's noun before its noun is one of its facts (since 1.87.0).
lg_run([I|Is], Cs, [I|Run], Rest) :-
    I = fact(pred(nn, [const(_), const(C)])), memberchk(C, Cs), !,
    lg_run(Is, Cs, Run, Rest).
%% So is a graded adjective's (since 1.90.0).
lg_run([I|Is], Cs, [I|Run], Rest) :-
    I = fact(modified(adv(_), pred(_, [const(C)]))), memberchk(C, Cs), !,
    lg_run(Is, Cs, Run, Rest).
%% So is an adjective's with an adposition phrase (since 1.91.0), its name
%% an adjective's and no verb's: in(sleep(a(dog)), the(house)) is a
%% clause's adjunct.
lg_run([I|Is], Cs, [I|Run], Rest) :-
    I = fact(modified(pp(_, _), pred(A, [const(C)]))), memberchk(C, Cs),
    lg_ap_adjective(A), !,
    lg_run(Is, Cs, Run, Rest).
lg_run([I|Is], Cs, [I|Run], Rest) :-
    I = fact(A), lg_core(A, pred(_, Args)), member(const(C), Args), memberchk(C, Cs), !,
    (   A = pred(_, [_]) -> lg_run(Is, Cs, Run, Rest) ; Run = [], Rest = Is ).
lg_run([I|Is], Cs, [I], Is) :-
    I = fact(A), member(C, Cs), lg_names_in(C, A), !.
lg_run(Is, _, [], Is).

%% A term names an individual inside it (of(pl(hand), a(surgeon)) names
%% a(surgeon)).
lg_ap_adjective(A) :-
    atom(A),
    catch(typology_meaning(english, adjective, A), _, fail),
    \+ catch(typology_meaning(english, verb, A), _, fail).

lg_names_in(C, X) :- X == C, !.
lg_names_in(C, X) :- compound(X), X =.. [_|As], member(A, As), lg_names_in(C, A), !.

lg_say(L, Group, S) :- lg_say(L, Group, S, _).

%% How a group was said: sentence (one that reads back) or general.
lg_say(L, Group, S, How) :-
    (   lg_group_ir(L, Group, IR),
        catch(typology_write(L, IR, S0), _, fail),
        lg_reads_back(L, S0, Group)
    ->  S = S0, How = sentence
    ;   lg_general(Group, S), How = general
    ).

%% A sentence is read alone, so a text's numbered individual (a(dog, 2),
%% something_2) reads back as its sentence numbers it: the two are compared
%% with no numbers (since 1.89.0).
lg_reads_back(L, S, Group) :-
    catch(logic_readings(L, S, Us), _, fail),
    lg_unnumbered(Group, Group1),
    member(utterance(_, Is), Us), lg_unnumbered(Is, Is1), Is1 == Group1, !.

lg_unnumbered(T, T) :- var(T), !.
lg_unnumbered(T, B) :-
    atom(T), !,
    ( lg_numbered(T, B0), memberchk(B0, [something, someone]) -> B = B0 ; B = T ).
lg_unnumbered(T, T1) :-
    compound(T), !,
    T =.. [F|As], maplist(lg_unnumbered, As, As1), T2 =.. [F|As1],
    ( T2 = a(S, K), integer(K) -> T1 = a(S) ; T1 = T2 ).
lg_unnumbered(T, T).

%% A group's level-1 IRs, the likeliest first: a noun phrase alone first
%% where the group is its facts (`The past year.', not `The past year is
%% a year. The past year is past.').
lg_group_ir(L, Group, phrase(NP)) :-
    Group = [fact(pred(_, [const(C)]))|_], nonvar(C),
    lg_term_facts(C, G), G == Group, !,
    lg_term_individuals(C, Cs),
    lg_const_np(L, Cs, C, NP).
lg_group_ir(L, [F|Run], IR) :-
    Run = [_|_], !,
    append(Init, [fact(A)], [F|Run]),
    lg_ind_map(L, Init, Map),
    lg_atom_ir(L, A, map(Map), IR).
lg_group_ir(L, [query(and([A|Cs]))], question(IR)) :-
    lg_core(A, pred(_, _)),
    lg_var_map(L, Cs, Map), Map \== [],
    lg_atom_ir(L, A, vmap(Map, wh), IR).
lg_group_ir(L, [fact(A)], IR) :- lg_atom_ir(L, A, every, IR).
lg_group_ir(L, [query(A)], question(IR)) :- lg_core(A, pred(_, _)), lg_atom_ir(L, A, wh, IR).

%% An atom without its tense and its adjuncts.
lg_core(at(_, P), C) :- !, lg_core(P, C).
lg_core(modified(_, P), C) :- !, lg_core(P, C).
lg_core(P, P).
lg_group_ir(L, [rule(H, B)], IR) :- lg_body_list(B, Cs), lg_rule_ir(L, H, Cs, IR).

%% The individuals a group brings in, each said as its term's indefinite
%% noun phrase (lg_const_np/4: a(big(dog)) `a big dog', a(pl(book))
%% `books'; since 1.77.0, the adjectives from the facts through 1.76.0):
%% every fact before the last one is an individual's, its noun's or an
%% adjective's.
lg_ind_map(L, Init, Cs) :-
    findall(C-N, ( member(F, Init), lg_individual_fact(F, N, C) ), CNs),
    forall(member(fact(A), Init),
           (   A = pred(nn, [const(M), const(C)]), memberchk(C-_, CNs)
           ->  lg_class_ok(L, M/1, noun)
           ;   A = modified(adv(M), pred(P, [const(C)])), memberchk(C-_, CNs)
           ->  lg_grade_adverb(M), lg_class_ok(L, P/1, adjective)
           ;   A = modified(pp(_, _), pred(P, [const(C)])), memberchk(C-_, CNs)
           ->  lg_class_ok(L, P/1, adjective)
           ;   A = pred(P, [const(C)]), memberchk(C-_, CNs),
               ( memberchk(C-P, CNs) -> true ; lg_class_ok(L, P/1, adjective) )
           )),
    findall(C, member(C-_, CNs), Cs0),
    list_to_set(Cs0, Cs).

%% The variables a question or a condition says of things it names by a
%% noun (`Who sees a dog?': dog(var(2))) as their noun phrases.
lg_var_map(L, Cs, Map) :-
    forall(member(C, Cs), ( C = pred(_, [var(_)]) ; C = pred(nn, [const(_), var(_)]) ; C = modified(adv(_), pred(_, [var(_)])) )),
    findall(K, member(pred(_, [var(K)]), Cs), Ks0), sort(Ks0, Ks),
    maplist(lg_var_np(L, Cs), Ks, Map).

lg_var_np(L, Cs, K, K-np(N, sg, indef, As)) :-
    findall(P, ( member(C, Cs), lg_cond_part(C, K, P) ), [N|As]),
    atom(N), lg_class_ok(L, N/1, noun),
    forall(member(A, As), lg_mod_ok(L, A)).

%% A condition of var(K): its predicate's name, or n(M) of nn(M, var(K)).
lg_cond_part(pred(nn, [const(M), var(K0)]), K, n(M)) :- K0 == K, !.
lg_cond_part(pred(P, [var(K0)]), K, P) :- K0 == K.
lg_cond_part(modified(adv(M), pred(A, [var(K0)])), K, adv(M, A)) :- K0 == K.

%% An adjective, or a noun before the noun (n(M)).
lg_mod_ok(L, n(M)) :- !, atom(M), lg_class_ok(L, M/1, noun).
lg_mod_ok(L, adv(M, A)) :- !, lg_grade_adverb(M), lg_class_ok(L, A/1, adjective).
lg_mod_ok(L, A) :- lg_class_ok(L, A/1, adjective).

lg_body_list(and(Bs), Bs) :- !.
lg_body_list(B, [B]).

%% A rule over var(1), its subject: one noun is `every' (`Every human is
%% mortal.'); a noun and more conditions an if clause whose pronoun is the
%% subject (`A person is happy if they are healthy and safe.'), or the noun's
%% adjectives (`Every happy dog sleeps.'); no noun `something' and an if
%% clause (`Something sleeps if it is tired.').
lg_rule_ir(L, H, [pred(N, [var(1)])], IR) :-
    lg_class_ok(L, N/1, noun),
    lg_atom_ir(L, H, var1(np(N, sg, every, [])), IR).
lg_rule_ir(L, H, [pred(N, [var(1)])|Cs], sub(if, Main, Cond)) :-
    Cs \== [], lg_class_ok(L, N/1, noun),
    lg_atom_ir(L, H, var1(np(N, sg, indef, [])), Main),
    lg_pronoun(L, N, P),
    lg_cond_ir(L, Cs, P, Cond).
lg_rule_ir(L, H, [pred(N, [var(1)])|Cs], IR) :-
    Cs \== [], lg_class_ok(L, N/1, noun),
    lg_adjective_conds(L, Cs, As),
    lg_atom_ir(L, H, var1(np(N, sg, every, As)), IR).
lg_rule_ir(L, H, Cs, sub(if, Main, Cond)) :-
    member(K-P, [thing-pron(3, sg, n), person-pron(3, pl, _)]),
    lg_atom_ir(L, H, var1(qp(some, K)), Main),
    lg_cond_ir(L, Cs, P, Cond).

lg_adjective_conds(_, [], []).
lg_adjective_conds(L, [pred(A, [V])|Cs], [A|As]) :-
    V == var(1), lg_class_ok(L, A/1, adjective),
    lg_adjective_conds(L, Cs, As).
lg_adjective_conds(L, [pred(nn, [const(M), V])|Cs], [n(M)|As]) :-
    V == var(1), atom(M), lg_class_ok(L, M/1, noun),
    lg_adjective_conds(L, Cs, As).
lg_adjective_conds(L, [modified(adv(M), pred(A, [V]))|Cs], [adv(M, A)|As]) :-
    V == var(1), lg_grade_adverb(M), lg_class_ok(L, A/1, adjective),
    lg_adjective_conds(L, Cs, As).
lg_adjective_conds(L, [modified(pp(P, const(R)), pred(A, [V]))|Cs], [ap(A, pp(P, NP))|As]) :-
    V == var(1), lg_class_ok(L, A/1, adjective), lg_const_np(L, [], R, NP),
    lg_adjective_conds(L, Cs, As).

%% An if clause of the subject's pronoun: its adjectives joined (`they are
%% healthy and safe'), or one atom.
lg_cond_ir(L, Cs, P, copula(present, pos, P, adj(As))) :-
    Cs = [_, _|_], lg_adjective_conds(L, Cs, As).
lg_cond_ir(L, [A], P, IR) :- lg_atom_ir(L, A, var1(P), IR).
lg_cond_ir(L, [A|Cs], P, IR) :-
    Cs \== [], lg_var_map(L, Cs, Map), \+ memberchk(1-_, Map),
    lg_atom_ir(L, A, vmap(Map, var1(P)), IR).

lg_pronoun(L, N, P) :-
    (   typology_meaning(L, person, N)
    ->  member(P, [pron(3, pl, _), pron(3, sg, n)])
    ;   member(P, [pron(3, sg, n), pron(3, pl, _)])
    ).

%% An atom's level-1 clause. How a term is said: SUB names one constant's
%% noun phrase (sub(C, NP)), var1(NP) var(1)'s; `every' says a variable of a
%% fact (`Everything is mortal.'), wh a query's (`Who is human?').
lg_atom_ir(L, at(T, A), How, IR) :- !,
    lg_atom_ir(L, A, How, IR0),
    lg_ir_tense(IR0, T, IR).
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_atom_ir(L, modified(when(B), A), How, sub(when, IR1, IR2)) :- !,
    lg_atom_ir(L, A, How, IR1),
    lg_atom_ir(L, B, How, IR2).
%% Inside an adposition phrase a word that is a verb which may take no
%% object (vi.txt) is the verb first, an adjective's phrase after (since
%% 1.88.0: in(live(john), paris) is `John lives in Paris.', where `live' is
%% a common adjective too).
lg_atom_ir(L, modified(J, A), How, IR) :- !,
    (   A = pred(P, [_]), J = pp(_, _), lg_lex(vi, P, _)
    ->  (   lg_atom_ir(L, A, How, IR0), IR0 \= copula(_, _, _, _),
            lg_adjunct_ir(L, How, J, J1), lg_ir_adjunct(IR0, J1, IR)
        ;   lg_atom_ir(L, A, How, IR0), IR0 = copula(_, _, _, _),
            lg_adjunct_ir(L, How, J, J1), lg_ir_adjunct(IR0, J1, IR)
        )
    ;   lg_atom_ir(L, A, How, IR0),
        lg_adjunct_ir(L, How, J, J1),
        lg_ir_adjunct(IR0, J1, IR)
    ).
lg_atom_ir(L, pred(P, [A]), How, IR) :-
    lg_arg_np(L, How, A, S),
    lg_unary_ir(L, P, S, IR).
%% An infinitive (since 1.95.0): to(Atom) where a verb's object stands, the
%% atom said of the clause's own subject, is inf(Verb, Object, Adjuncts);
%% an individual a(Shape) in it, which no fact names, is said as one there.
%% Said of another term (since 1.96.0) it is the object's infinitive,
%% clause(Verb, infinitive, pos, Object's NP, ...); after an adjective, the
%% adjective's (copula(..., adj([ap(A, inf(...))]))). Said by someone of
%% the clause's own subject (since 1.99.0) it is the passive infinitive
%% (need(the(machine), to(service(someone, the(machine)))) is `The machine
%% needs to be serviced.').
lg_atom_ir(L, pred(P, [A, fun(to, [F])]), How, IR) :-
    lg_arg_np(L, How, A, S),
    lg_inf_ir(L, How, F, V2, S2, O2, Js2),
    (   catch(typology_meaning(L, verb, P), _, fail),
        (   S2 = S
        ->  ( Js2 == [] -> Inf = inf(V2, O2) ; Inf = inf(V2, O2, Js2) )
        ;   ( S2 == pron(3, sg, zero) -> true ; S2 == qp(some, person) ), O2 =@= S
        ->  Z = pron(3, sg, zero),
            ( Js2 == [] -> Inf = clause(V2, pass(infinitive), pos, Z, none) ; Inf = clause(V2, pass(infinitive), pos, Z, none, Js2) )
        ;   ( Js2 == [] -> Inf = clause(V2, infinitive, pos, S2, O2) ; Inf = clause(V2, infinitive, pos, S2, O2, Js2) )
        ),
        IR = clause(P, present, pos, S, Inf)
    ;   catch(typology_meaning(L, adjective, P), _, fail),
        S2 = S,
        ( Js2 == [] -> Inf = inf(V2, O2) ; Inf = inf(V2, O2, Js2) ),
        IR = copula(present, pos, S, adj([ap(P, Inf)]))
    ).

%% An infinitive's atom term read back: its verb, the noun phrase it is
%% said of, its object and adjuncts.
lg_inf_ir(L, How, F, V2, S2, O2, Js2) :-
    nonvar(F), F = fun(_, _),
    lg_atom_of_fun(F, A2),
    lg_inf_how(How, F, How2),
    lg_inf_peel(A2, A3, Ms),
    (   A3 = pred(V, [A]), catch(typology_meaning(L, verb, V), _, fail)
    ->  lg_arg_np(L, How2, A, S),
        foldl(lg_inf_adjunct(L, How2), Ms, clause(V, present, pos, S, none), IR2)
    ;   lg_atom_ir(L, A2, How2, IR2)
    ),
    (   IR2 = clause(V2, present, pos, S2, O2) -> Js2 = []
    ;   IR2 = clause(V2, present, pos, S2, O2, Js2)
    ).
%% The adjuncts round an infinitive's atom, the innermost first: a verb of
%% one place inside them is the verb (`He tried to find out by
%% indirection.' is to(by(find_out(he), indirection))).
lg_inf_peel(modified(J, A), Core, Ms) :-
    ( J = pp(_, _) ; J = adv(_) ), !,
    lg_inf_peel(A, Core, Ms0),
    append(Ms0, [J], Ms).
lg_inf_peel(A, A, []).

lg_inf_adjunct(L, How, J, IR0, IR) :-
    lg_adjunct_ir(L, How, J, J1),
    lg_ir_adjunct(IR0, J1, IR).

%% An object's complement (since 1.100.0): a verb's third argument, an
%% atom whose first argument is the object, is the copula's predicate it
%% makes of the object, oc(Object, Predicate); an adverb round an
%% adjective's atom grades it (leave(the(accident), she,
%% badly(shaken(she))) is `left her badly shaken').
lg_atom_ir(L, pred(P, [A, B, F]), How, IR) :-
    nonvar(F), F = fun(_, [B2|_]),
    catch(typology_meaning(L, verb, P), _, fail),
    lg_arg_np(L, How, A, S),
    lg_arg_np(L, How, B, O),
    lg_atom_of_fun(F, A2),
    (   A2 = modified(adv(M), A3), B2 = fun(_, [B3|_]), B3 == B,
        lg_atom_ir(L, A3, How, copula(present, pos, _, adj([Ad]))), atom(Ad)
    ->  Pred = adj([adv(M, Ad)])
    ;   B2 == B,
        lg_atom_ir(L, A2, How, IR2),
        IR2 = copula(present, pos, _, Pred)
    ), !,
    IR = clause(P, present, pos, S, oc(O, Pred)).
%% A complement of several atoms (since 1.103.0): a noun phrase's term as
%% the third argument of a verb of the complement list is the noun phrase,
%% consider(someone, a(satellite), a(necessary(nn(research, step)))) `A
%% satellite was considered a necessary research step.'.
lg_atom_ir(L, pred(P, [A, B, F]), How, IR) :-
    nonvar(F), F = const(C), compound(C),
    catch(typology_meaning(L, verb, P), _, fail),
    catch(ty_verb_of(L, complement, P), _, fail),
    lg_arg_np(L, How, A, S),
    lg_arg_np(L, How, B, O),
    lg_inf_how(How, F, How2),
    lg_arg_np(L, How2, F, Pred),
    ( Pred = np(_, _, _, _) ; Pred = of(_, _) ; Pred = np_pp(_, _) ), !,
    IR = clause(P, present, pos, S, oc(O, Pred)).
lg_atom_ir(L, pred(P, [A, B]), How, IR) :-
    lg_binary_classes(L, P, Cs),
    lg_arg_np(L, How, A, S),
    lg_arg_np(L, How, B, O),
    member(C, Cs),
    lg_binary_shape(C, P, How, S, O, IR).

%% A predicate of two said as a verb (`John likes Mary.'), an adposition
%% (`The book is on the table.') or (since 1.78.0) a noun of relation
%% (`John is Mary's father.'): the noun first where the word is no
%% adposition and its first sense is a person (class.txt: father, friend,
%% owner) or it is no verb at all (known_verb.txt: source; not salt,
%% form, love). The sentence is still kept only where it reads back.
lg_binary_classes(L, P, Cs) :-
    (   typology_meaning(L, adposition, P) -> Order = [verb, adposition]
    ;   lg_noun_first2(L, P) -> Order = [noun, verb]
    ;   Order = [verb, noun]
    ),
    findall(C, ( member(C, Order), lg_class_ok(L, P/2, C) ), Cs).

lg_noun_first2(_, P) :- lg_lex(class, P, _), !.
lg_noun_first2(_, P) :- \+ lg_lex(known_verb, P, _).

lg_binary_shape(verb, P, _, S, O, clause(P, present, pos, S, O)).
lg_binary_shape(adposition, P, _, S, O, copula(present, pos, S, pp(P, O))).
lg_binary_shape(noun, P, How, S, O, copula(present, pos, S, of(O, np(P, Num, D, [])))) :-
    lg_relation_det(How, Ds), member(D, Ds),
    ( lg_plural_np(S) -> member(Num, [pl, sg]) ; Num = sg ).

%% A noun of relation is definite first (`the father of'), and indefinite
%% first said of a rule's variable (`Every set is a subset of the universal
%% set.').
lg_relation_det(var1(_), [indef, def]) :- !.
lg_relation_det(vmap(_, H), Ds) :- !, lg_relation_det(H, Ds).
lg_relation_det(_, [def, indef]).

lg_ir_tense(copula(_, P, S, Pr), T, copula(T, P, S, Pr)).
lg_ir_tense(clause(V, _, P, S, O), T, clause(V, T, P, S, O)).
lg_ir_tense(clause(V, _, P, S, O, Js), T, clause(V, T, P, S, O, Js)).

%% An infinitive of purpose (since 1.96.0): to(Atom, Atom2), Atom2 said of
%% the clause's subject.
lg_adjunct_ir(L, How, pp(to, F), Inf) :-
    nonvar(F), F = fun(_, _),
    lg_inf_ir(L, How, F, V2, _, O2, Js2), !,
    ( Js2 == [] -> Inf = inf(V2, O2) ; Inf = inf(V2, O2, Js2) ).
lg_adjunct_ir(L, How, pp(P, T), pp(P, NP)) :- lg_arg_np(L, How, T, NP).
lg_adjunct_ir(_, _, adv(M), adv(M)).

%% An adjunct after a clause's others; a copula takes none, but an
%% adjective's atom inside an adposition phrase is the adjective's phrase
%% (since 1.88.0: `The movie is unsuitable for children.').
lg_ir_adjunct(clause(V, T, P, S, O), J, clause(V, T, P, S, O, [J])).
lg_ir_adjunct(copula(T, P, S, adj([A])), pp(Pr, NP), copula(T, P, S, adj([ap(A, pp(Pr, NP))]))) :-
    ( atom(A) -> true ; A = adv(_, A1), atom(A1) ).
lg_ir_adjunct(copula(T, P, S, adj([A])), adv(M), copula(T, P, S, adj([adv(M, A)]))) :- atom(A), lg_grade_adverb(M).
lg_ir_adjunct(clause(V, T, P, S, O, Js), J, clause(V, T, P, S, O, Js1)) :- lg_add_adjunct(Js, J, Js1).

%% Two adverbs side by side are joined (`slowly and quietly').
lg_add_adjunct(Js, adv(M), Js1) :-
    append(Init, [adv(M0)], Js), !,
    ( M0 = and(Ms0) -> append(Ms0, [M], Ms) ; Ms = [M0, M] ),
    append(Init, [adv(and(Ms))], Js1).
lg_add_adjunct(Js, J, Js1) :- append(Js, [J], Js1).

lg_unary_ir(L, P, S, IR) :-
    lg_unary_classes(L, P, S, Cs),
    member(C, Cs),
    lg_unary_shape(C, P, S, IR).

lg_unary_shape(adjective, P, S, copula(present, pos, S, adj([P]))).
lg_unary_shape(noun, P, S, copula(present, pos, S, np(P, Num, indef, []))) :-
    ( lg_plural_np(S) -> member(Num, [pl, sg]) ; member(Num, [sg, pl]) ).
lg_unary_shape(verb, P, S, clause(P, present, pos, S, none)).

%% A noun phrase of a group: a noun's plural, a plural pronoun, a joined
%% pair; its noun predicate is a plural first (`The dogs are animals.').
lg_plural_np(NP) :- nonvar(NP), ( NP = np(_, pl, _, _) ; NP = pron(_, pl, _) ; NP = of(_, np(_, pl, _, _)) ; NP = and(_) ), !.

%% THE ORDER OF THE CLASSES of a word said of one thing S, from WordNet's
%% lists in lexicon/: an adjective of the 3 000 commonest (adj.txt: human,
%% mortal, wise; not animal, student) first. Then, where S is a person or
%% an animal, a noun whose first sense is a person, an animal or a thing
%% (class.txt, noun.txt: `Rex is a dog.', `Tweety is a bird.') before a
%% verb, and any other noun after it (`John works.', `Rex barks.': vi.txt
%% stops at 1 200 verbs and has no `bark'). Where S is none, a verb that
%% takes no object (vi.txt) and a noun the commoner first, by their ranks
%% in known_noun.txt and vi.txt (`Every bird flies.', `A novel is a
%% book.'), and any other noun first. Then any adjective. The sentence is
%% still kept only where it reads back.
lg_unary_classes(L, P, S, Cs) :-
    (   lg_lex(adj, P, _) -> Cs1 = [adjective] ; Cs1 = [] ),
    (   lg_animate_np(L, S)
    ->  (   ( lg_lex(class, P, _) ; lg_lex(noun, P, _) ; typology_meaning(L, animate, P) )
        ->  Cs2 = [noun, verb]
        ;   Cs2 = [verb, noun]
        )
    ;   lg_lex(vi, P, Rv)
    ->  (   lg_lex(known_noun, P, Rn), Rn < Rv -> Cs2 = [noun, verb] ; Cs2 = [verb, noun] )
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

%% A word's place in a list of lexicon/ (adj, vi, known_noun, class, noun), the
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

lg_arg_np(L, How, fun(of, [T, P]), of(PNP, np(N, Num, def, As))) :- !,
    lg_fun_shape(T, S),
    lg_np_of_term(L, S, N, Num, As),
    lg_arg_np(L, How, P, PNP).
lg_arg_np(L, inds(Is, How), T, NP) :- !,
    (   T = const(C), nonvar(C), memberchk(C, Is) -> lg_const_np(L, Is, C, NP) ; lg_arg_np(L, How, T, NP) ).
lg_arg_np(L, vmap(Map, How), T, NP) :- !,
    ( T = var(K), memberchk(K-NP0, Map) -> NP = NP0 ; lg_arg_np(L, How, T, NP) ).
lg_arg_np(L, map(Cs), const(C), NP) :- !, lg_const_np(L, Cs, C, NP).
lg_arg_np(_, sub(C, NP), const(C1), NP) :- C1 == C, !.
lg_arg_np(L, sub(C, NP), const(C1), NP1) :- !, lg_const_np(L, [sub(C, NP)], C1, NP1).
lg_arg_np(_, var1(NP), var(1), NP) :- !.
lg_arg_np(_, wh, var(_), wh(W)) :- !, member(W, [who, what]).
lg_arg_np(_, every, var(_), qp(every, K)) :- !, member(K, [thing, person]).
lg_arg_np(L, _, const(C), NP) :- lg_const_np(L, [], C, NP).

%% A shape read from the compound term a variable in it makes (lg_fix/2):
%% fun(pl, [const(hand)]) is pl(hand).
lg_fun_shape(const(X), X) :- !.
lg_fun_shape(fun(F, As), T) :- maplist(lg_fun_shape, As, Xs), T =.. [F|Xs].

%% A constant's noun phrase: a pronoun's, something, someone; the(T) a
%% definite noun phrase, of(T, P) a possessed, each read from its term (no
%% spelling taken apart since 1.76.0); a name a row has; a bare noun; a
%% name no row has.
lg_const_np(_, Cs, C, NP) :- member(sub(C1, NP0), Cs), C1 == C, !, NP = NP0.
lg_const_np(_, _, C, P) :- atom(C), lg_pron_np(C, P).
lg_const_np(_, _, something, qp(some, thing)).
lg_const_np(_, _, someone, qp(some, person)).
lg_const_np(_, _, C, qp(some, K)) :- atom(C), lg_numbered(C, W), memberchk(W-K, [something-thing, someone-person]), !.
lg_const_np(L, _, the(T), np_pp(np(N, Num, def, As), Inf)) :-
    nonvar(T), T = to(T0, X), lg_inf_term(L, X, Inf), !,
    lg_np_of_term(L, T0, N, Num, As).
lg_const_np(L, Cs, the(T), np_pp(np(N, Num, def, As), pp(P, XNP))) :-
    lg_pp_term(T), T =.. [P, T0, X], typology_meaning(L, adposition, P), !,
    lg_np_of_term(L, T0, N, Num, As),
    lg_const_np(L, Cs, X, XNP).
lg_const_np(L, Cs, the(T), np(N, Num, def, As)) :- !, lg_np_of_term(L, Cs, T, N, Num, As).
lg_const_np(L, Cs, a(S), NP) :- !, memberchk(a(S), Cs), lg_indef_np(L, Cs, S, NP).
lg_const_np(L, Cs, a(S, K), NP) :- integer(K), !, memberchk(a(S, K), Cs), lg_indef_np(L, Cs, S, NP).
lg_const_np(L, Cs, of(T, P), of(PNP, np(N, Num, def, As))) :- !,
    lg_np_of_term(L, T, N, Num, As),
    lg_const_np(L, Cs, P, PNP).
lg_const_np(L, Cs, C, np_pp(HNP, Inf)) :-
    nonvar(C), C = to(T0, X), lg_inf_term(L, X, Inf), !,
    lg_const_np(L, Cs, T0, HNP).
lg_const_np(L, Cs, C, np_pp(HNP, pp(P, XNP))) :-
    lg_pp_term(C), C =.. [P, T0, X], typology_meaning(L, adposition, P), !,
    lg_const_np(L, Cs, T0, HNP),
    lg_const_np(L, Cs, X, XNP).
lg_const_np(L, _, C, name(W)) :- atom(C), lg_name_written(C, W), typology_meaning(L, name, W).
lg_const_np(L, Cs, C, np(N, sg, mass, As)) :- lg_np_of_term(L, Cs, C, N, sg, As).
lg_const_np(L, _, C, name(W)) :- atom(C), lg_name_written(C, W), \+ typology_meaning(L, name, W).

%% An individual's noun phrase, from its shape (since 1.77.0): a(pl(book))
%% `books', a(of(book, a(pl(stamp)))) `a book of stamps'. Only the
%% individuals a group brings in (Cs) are said so.
lg_indef_np(L, Cs, S, np_pp(HNP, Inf)) :-
    nonvar(S), S = to(T0, X), lg_inf_term(L, X, Inf), !,
    lg_indef_np(L, Cs, T0, HNP).
lg_indef_np(L, Cs, S, np_pp(HNP, pp(P, XNP))) :-
    lg_pp_term(S), S =.. [P, T0, X], typology_meaning(L, adposition, P), !,
    lg_indef_np(L, Cs, T0, HNP),
    lg_const_np(L, Cs, X, XNP).
lg_indef_np(L, Cs, of(T, P), of(PNP, np(N, Num, indef, As))) :- !,
    lg_np_of_term(L, T, N, Num, As),
    lg_const_np(L, Cs, P, PNP).
lg_indef_np(L, Cs, T, np(N, Num, indef, As)) :- lg_np_of_term(L, Cs, T, N, Num, As).

%% A noun's infinitive in a term (since 1.96.0): an atom of a verb said of
%% someone, inf(Verb, Object[, Adjuncts]).
lg_inf_term(L, X, Inf) :-
    compound(X), lg_inf_shape(X),
    lg_in_atom_term(X, F),
    lg_inf_ir(L, every, F, V2, S2, O2, Js2),
    S2 == qp(some, person),
    ( Js2 == [] -> Inf = inf(V2, O2) ; Inf = inf(V2, O2, Js2) ).

%% A pronoun's constant written as the pronoun.
lg_pron_np(i, pron(1, sg, _)).
lg_pron_np(we, pron(1, pl, _)).
lg_pron_np(you, pron(2, sg, _)).
lg_pron_np(you, pron(2, pl, _)).
lg_pron_np(he, pron(3, sg, m)).
lg_pron_np(she, pron(3, sg, f)).
lg_pron_np(it, pron(3, sg, n)).
lg_pron_np(they, pron(3, pl, _)).

%% A noun phrase's term read back: its number, noun and adjectives, each
%% a word of its class.
lg_np_of_term(L, pl(T), N, pl, As) :- !, lg_np_of_term(L, T, N, sg, As).
lg_np_of_term(L, T, N, sg, As) :-
    lg_np_parts(T, N, As),
    typology_meaning(L, noun, N),
    forall(member(A, As), lg_np_item_ok(L, A)).

%% With the individuals a group brings in (Cs), an adjective's adposition
%% phrase's term read as its noun phrase (since 1.91.0: ap(A, pp(Prep,
%% NP))).
lg_np_of_term(L, Cs, T, N, Num, As) :-
    lg_np_of_term(L, T, N, Num, As0),
    lg_ir_aps(L, Cs, As0, As).

lg_ir_aps(_, _, [], []).
lg_ir_aps(L, Cs, [X|Xs], [Y|Ys]) :-
    (   nonvar(X), X = ap(A, P, _, R)
    ->  lg_const_np(L, Cs, R, NP), Y = ap(A, pp(P, NP))
    ;   Y = X
    ),
    lg_ir_aps(L, Cs, Xs, Ys).

lg_np_item_ok(L, n(M)) :- !, typology_meaning(L, noun, M).
lg_np_item_ok(L, ap(A, P, _, _)) :- !, typology_meaning(L, adjective, A), typology_meaning(L, adposition, P).
lg_np_item_ok(L, adv(M, A)) :- !, typology_meaning(L, adverb, M), typology_meaning(L, adjective, A).
lg_np_item_ok(L, A) :- typology_meaning(L, adjective, A).

%% An adverb that grades an adjective in a term: an adverb's word that is
%% no adjective's (`incurably', `very'); one that is (`pretty') is the
%% adjective level 1 reads first.
lg_grade_adverb(M) :-
    atom(M),
    catch(typology_meaning(english, adverb, M), _, fail),
    \+ catch(typology_meaning(english, adjective, M), _, fail).

lg_np_parts(N, N, []) :- atom(N), !.
lg_np_parts(nn(M, X), N, [n(M)|As]) :- !, atom(M), lg_np_parts(X, N, As).
lg_np_parts(T, N, [ap(A, P, const(R), R)|As]) :-
    compound(T), T =.. [A, X, P, R], atom(A), atom(P), !,
    lg_np_parts(X, N, As).
lg_np_parts(T, N, [adv(M, A)|As]) :-
    compound(T), T =.. [M, Y], atom(M), compound(Y), Y =.. [A, X], atom(A),
    lg_grade_adverb(M), !,
    lg_np_parts(X, N, As).
lg_np_parts(T, N, [A|As]) :- compound(T), T =.. [A, X], atom(A), lg_np_parts(X, N, As).

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
    ;   memberchk(C, [verb, adposition, noun]), typology_meaning(L, C, P)
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

lg_holds(at(Tn, A), T) :- !,
    lg_holds(A, T0),
    ( memberchk(Tn, [future]) -> W = 'in the future' ; W = 'in the past' ),
    format(atom(T), '~w ~w', [T0, W]).
% cocolint: X3 -- when/1 here is a term of the logic form, a when clause's atom, not SWI's when/2
lg_holds(modified(when(B), A), T) :- !,
    lg_holds(A, T1), lg_holds(B, T2),
    format(atom(T), '~w when ~w', [T1, T2]).
lg_holds(modified(pp(P, Tm), A), T) :- !,
    lg_holds(A, T0), lg_term_words(Tm, W),
    format(atom(T), '~w ~w ~w', [T0, P, W]).
lg_holds(modified(adv(M), A), T) :- !,
    lg_holds(A, T0),
    format(atom(T), '~w ~w', [T0, M]).
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
lg_term_words(const(C), W) :- !, ( atom(C) -> W = C ; format(atom(W), '~w', [C]) ).
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
    lg_say_all(L, Gs, Said),
    findall(S1, member(S1-_, Said), Ss), findall(H1, member(_-H1, Said), Hows),
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
