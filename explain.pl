%% library(reasoning/explain) -- a Cocolog program said in English (since
%% 1.80.0): code that the translator's round trip has no sentence for, a
%% grammar rule, a cut, an if-then-else, arithmetic, a builtin, a name that
%% is no English word.
%%
%% A clause of the logic form is said as the translator says it
%% (library(reasoning/logic)'s logic_write/3) where that English reads back
%% to the same clause. Any other clause is EXPLAINED: a fact is `Head
%% holds.', a rule `Head holds if Body.', a grammar rule `A phrase Head is:
%% Body.', a directive a sentence of its own. A goal of a control construct
%% or of a builtin that this file has a row for is said in English (`X is
%% the value of A + B', `L is the list of every T for which G', `if C, then
%% T, else E', `no other clause is tried'); any other goal is written as its
%% term, with the source's variable names and operators, and `holds'. The
%% English explains: it does not read back.
%%
%% WHAT IS PUBLIC:
%%
%%     explain_text(+Lang, +Text, -English)    every clause of a source
%%                                             text, a paragraph each
%%     explain_file(+Lang, +File, -Clauses)    explained(Source, English,
%%                                             How) a clause: How logic
%%                                             (the translator's sentence)
%%                                             or rows(Unexplained), the
%%                                             names of the goals said as
%%                                             terms that the text does not
%%                                             define (N/A, a list)
%%     explain_measure(+Lang, +File, -Measure) measure(Clauses, ByLogic,
%%                                             Full, Unexplained): the
%%                                             clauses, those the
%%                                             translator says, those whose
%%                                             every goal is explained or
%%                                             the text's own, and the names
%%                                             with no row (N/A-Count, the
%%                                             commonest first)
%%
%% Lang is english: the rows of the other languages are not written yet.
%% The text's op/3 directives are obeyed as the text is read, as a load
%% obeys them, and they stay.

:- module(explain, [explain_text/3, explain_file/3, explain_measure/3]).

:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

explain_text(L, Text, English) :-
    ex_clauses(L, Text, Es),
    findall(E, member(explained(_, E, _), Es), Ts),
    atomic_list_concat(Ts, '\n\n', English).

explain_file(L, File, Es) :-
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    ex_clauses(L, Text, Es).

explain_measure(L, File, measure(N, ByLogic, Full, Unexplained)) :-
    explain_file(L, File, Es),
    length(Es, N),
    aggregate_all(count, member(explained(_, _, logic), Es), ByLogic),
    aggregate_all(count, ( member(explained(_, _, H), Es), ( H == logic ; H == rows([]) ) ), Full),
    findall(PI, ( member(explained(_, _, rows(Us)), Es), member(PI, Us) ), PIs0),
    msort(PIs0, PIs1), clumped(PIs1, Cs), sort(2, @>=, Cs, Unexplained).

ex_lang(L) :- must_be(atom, L), ( L == english -> true ; throw(error(domain_error(explain_language, L), _)) ).

%% ---- reading ----------------------------------------------------------------------

%% The clauses of a text, each read with its variables' names; a directive
%% op/3 is obeyed before the next clause is read.
ex_clauses(L, Text, Es) :-
    ex_lang(L),
    typology_load(L),
    logic:lg_clauses(Text, Cs),
    ex_read_all(Cs, Items),
    findall(PI, ( member(clause(_, T, _), Items), ex_defines(T, PI) ), PIs0),
    sort(PIs0, Defined),
    maplist(ex_item(L, Defined), Items, Es).

ex_read_all([], []).
ex_read_all([C|Cs], [I|Is]) :-
    (   catch(term_string(T, C, [variable_names(Vs)]), _, fail)
    ->  I = clause(C, T, Vs),
        ( nonvar(T), T = (:- op(P, Ty, N)) -> catch(op(P, Ty, N), _, true) ; true )
    ;   I = unread(C)
    ),
    ex_read_all(Cs, Is).

%% What a clause defines: its head's name and arity, a grammar rule's two
%% more, a dynamic directive's each.
ex_defines(T, _) :- var(T), !, fail.
ex_defines((:- dynamic(S)), PI) :- !, ex_spec_pi(S, PI).
ex_defines((:- _), _) :- !, fail.
ex_defines((H, _ --> _), PI) :- !, ex_defines((H --> x), PI).
ex_defines((H --> _), N/A) :- !, callable(H), functor(H, N, A0), A is A0 + 2.
ex_defines((H :- _), N/A) :- !, callable(H), functor(H, N, A).
ex_defines(H, N/A) :- callable(H), functor(H, N, A).

ex_spec_pi(S, _) :- var(S), !, fail.
ex_spec_pi((A, B), PI) :- !, ( ex_spec_pi(A, PI) ; ex_spec_pi(B, PI) ).
ex_spec_pi(L, PI) :- is_list(L), !, member(X, L), ex_spec_pi(X, PI).
ex_spec_pi(N/A, N/A) :- atom(N), integer(A).

%% ---- a clause ----------------------------------------------------------------------

ex_item(_, _, unread(C), explained(C, E, rows([]))) :- !,
    format(atom(E), 'This text cannot be read as a clause: ~w', [C]).
ex_item(L, Ds, clause(C, T, Vs), explained(C, E, How)) :-
    (   ex_logic_sentence(L, C, T, E0)
    ->  E = E0, How = logic
    ;   copy_term(T-Vs, T1-Vs1),
        ex_name_vars(Vs1, T1),
        ex_clause(L, Ds, T1, E, Us0),
        sort(Us0, Us),
        How = rows(Us)
    ).

%% A clause of the logic form, every goal a plain predicate: the
%% translator's sentence, where it reads back to the same clause.
ex_logic_sentence(L, C, T, E) :-
    nonvar(T), T \= (:- _), T \= (_ --> _),
    ( T = (_ :- B) -> ex_plain_body(B) ; true ),
    ex_limit(( cocolog_read(C, U), logic_write(L, U, E),
               logic_readings(L, E, Us), U = utterance(_, Is0),
               member(utterance(_, Is), Us), Is == Is0 )), !.

ex_plain_body(B) :- var(B), !, fail.
ex_plain_body((A, B)) :- !, ex_plain_body(A), ex_plain_body(B).
ex_plain_body(G) :- callable(G), \+ ex_row(G), \+ ex_control(G).

ex_control(G) :- functor(G, N, A), memberchk(N/A, [(;)/2, (->)/2, (*->)/2, (\+)/1, !/0]).

ex_limit(G) :- catch(call_with_inference_limit(G, 3000000, R), _, fail), R \== inference_limit_exceeded.

%% Each variable as its name in the source ('$VAR'(Name)), and one with no
%% name `_'.
ex_name_vars(Vs, T) :-
    maplist(ex_name_var, Vs),
    term_variables(T, Free),
    maplist(=('$VAR'('_')), Free).

ex_name_var(N=V) :- ( var(V) -> V = '$VAR'(N) ; true ).

ex_clause(L, Ds, (:- D), E, Us) :- !, ex_directive(L, Ds, D, P, Us), ex_sentence(P, E).
ex_clause(L, Ds, (H, PB --> B0), E, Us) :- !,
    ex_lead_cut(B0, B, Cut),
    ex_term(H, HT), ex_dcg_body(L, Ds, PB, PBP, Us1),
    ex_dcg_body(L, Ds, B, BP, Us2), append(Us1, Us2, Us),
    format(atom(P), 'a phrase ~w, followed by ~w, is~w', [HT, PBP, BP]),
    ex_sentence(P, E0), ex_cut_sentence(Cut, rule, E0, E).
ex_clause(L, Ds, (H --> B0), E, Us) :- !,
    ex_lead_cut(B0, B, Cut),
    ex_term(H, HT), ex_dcg_body(L, Ds, B, BP, Us),
    ex_dcg_space(BP, Sp), format(atom(P), 'a phrase ~w is~w~w', [HT, Sp, BP]),
    ex_sentence(P, E0), ex_cut_sentence(Cut, rule, E0, E).
ex_clause(L, Ds, (H :- B0), E, Us) :- !,
    ex_lead_cut(B0, B, Cut),
    ex_term(H, HT),
    (   B == true
    ->  Us = [], format(atom(P), '~w holds', [HT])
    ;   ex_body(L, Ds, B, BP, Us),
        (   ex_control_first(BP) -> format(atom(P), '~w holds as follows: ~w', [HT, BP])
        ;   format(atom(P), '~w holds if ~w', [HT, BP])
        )
    ),
    ex_sentence(P, E0), ex_cut_sentence(Cut, clause, E0, E).
ex_clause(_, _, H, E, []) :-
    ex_term(H, HT),
    format(atom(P), '~w holds', [HT]),
    ex_sentence(P, E).

%% A cut that begins a body is a sentence of its own after the clause's:
%% once the head matches, no other clause or rule is tried.
ex_lead_cut(B, B, no) :- var(B), !.
ex_lead_cut((!, B), B, yes) :- !.
ex_lead_cut(!, true, yes) :- !.
ex_lead_cut(B, B, no).

ex_cut_sentence(no, _, E, E).
ex_cut_sentence(yes, K, E0, E) :-
    format(atom(E), '~w When its head matches, no other ~w is tried.', [E0, K]).

ex_control_first(P) :-
    member(W, ['if ', 'either ', 'for every ', 'for each ']), sub_atom(P, 0, _, _, W), !.

%% A sentence: its first letter a capital where it begins with a word of
%% English (not a term), a full stop at its end.
ex_sentence(P, E) :-
    (   sub_atom(P, 0, 1, _, F), char_type(F, lower), ex_word_first(P)
    ->  upcase_atom(F, U), sub_atom(P, 1, _, 0, R), atomic_list_concat([U, R, '.'], E)
    ;   atomic_list_concat([P, '.'], E)
    ).

ex_word_first(P) :-
    member(W, ['a phrase ', 'this file ', 'when the file ', 'the flag ', 'it ', 'either ', 'if ', 'for every ']),
    sub_atom(P, 0, _, _, W), !.

%% ---- a directive -------------------------------------------------------------------

ex_directive(_, _, use_module(library(X)), P, []) :- !,
    ex_term(X, XT), format(atom(P), 'this file uses the library ~w', [XT]).
ex_directive(_, _, use_module(F), P, []) :- !,
    ex_term(F, FT), format(atom(P), 'this file uses ~w', [FT]).
ex_directive(_, _, op(Pr, Ty, N), P, []) :- !,
    ex_term(N, NT), ex_op_kind(Ty, K),
    format(atom(P), 'this file makes ~w ~w of priority ~w', [NT, K, Pr]).
ex_directive(_, _, dynamic(S), P, []) :- !,
    ex_term(S, ST),
    format(atom(P), 'this file makes ~w dynamic: a program adds and removes its clauses', [ST]).
ex_directive(_, _, discontiguous(S), P, []) :- !,
    ex_term(S, ST), format(atom(P), 'this file lets the clauses of ~w stand apart', [ST]).
ex_directive(_, _, module(N, Es), P, []) :- !,
    ex_term(N, NT), ex_term(Es, ET),
    format(atom(P), 'this file is the module ~w, which gives ~w', [NT, ET]).
ex_directive(_, _, set_prolog_flag(F, V), P, []) :- !,
    ex_term(F, FT), ex_term(V, VT), format(atom(P), 'the flag ~w is set to ~w', [FT, VT]).
ex_directive(L, Ds, initialization(G), P, Us) :- !,
    ex_body(L, Ds, G, GP, Us), format(atom(P), 'when the file is loaded, ~w', [GP]).
ex_directive(L, Ds, G, P, Us) :-
    ex_body(L, Ds, G, GP, Us), format(atom(P), 'when the file is loaded, ~w', [GP]).

ex_op_kind(T, K) :-
    (   memberchk(T, [fx, fy]) -> K = 'a prefix operator'
    ;   memberchk(T, [xf, yf]) -> K = 'a postfix operator'
    ;   K = 'an infix operator'
    ).

%% ---- a body ------------------------------------------------------------------------

%% A body's goals in order, each a phrase; `true' between others is no step.
%% Among several goals a control construct's phrase is in parentheses, so
%% its own `and' does not join the goals round it.
ex_body(L, Ds, B, P, Us) :-
    ex_conj(B, Gs0),
    ( Gs0 = [_, _|_] -> exclude(==(true), Gs0, Gs) ; Gs = Gs0 ),
    ex_goals(L, Ds, Gs, Ps0, Us),
    (   Gs = [_, _|_]
    ->  maplist(ex_bracket_control, Gs, Ps0, Ps)
    ;   Ps = Ps0
    ),
    ex_and(Ps, P).

%% A goal of answers (findall/3, forall/2, aggregate_all/3): always in
%% parentheses, as the phrase round it ends in it.
ex_paren_inner(L, Ds, B, P, Us) :-
    ex_body(L, Ds, B, P0, Us), format(atom(P), '(~w)', [P0]).

%% A body inside a construct: in parentheses where it has several goals.
ex_inner(L, Ds, B, P, Us) :-
    ex_body(L, Ds, B, P0, Us),
    ex_conj(B, Gs0), exclude(==(true), Gs0, Gs),
    ( Gs = [_, _|_] -> format(atom(P), '(~w)', [P0]) ; P = P0 ).

ex_bracket_control(G, P0, P) :-
    (   nonvar(G), functor(G, N, A),
        memberchk(N/A, [(;)/2, (->)/2, (*->)/2, forall/2, findall/3, findall/4, catch/3, aggregate_all/3, setof/3, bagof/3])
    ->  format(atom(P), '(~w)', [P0])
    ;   P = P0
    ).

ex_conj(B, [B]) :- var(B), !.
ex_conj((A, B), Gs) :- !, ex_conj(A, As), ex_conj(B, Bs), append(As, Bs, Gs).
ex_conj(G, [G]).

ex_goals(_, _, [], [], []).
ex_goals(L, Ds, [G|Gs], [P|Ps], Us) :-
    ex_goal(L, Ds, G, P, Us1),
    ex_goals(L, Ds, Gs, Ps, Us2),
    append(Us1, Us2, Us).

ex_and([], 'true') :- !.
ex_and([P], P) :- !.
ex_and(Ps, T) :-
    append(Init, [Last], Ps),
    atomic_list_concat(Init, ', ', I),
    format(atom(T), '~w and ~w', [I, Last]).

%% A goal's phrase. The control constructs first, then the builtins'
%% rows, then any other goal as its term and `holds', named among the
%% unexplained where the text does not define it.
ex_goal(_, _, G, P, []) :- G = '$VAR'(_), !, ex_term(G, T), format(atom(P), 'the goal ~w is called', [T]).
ex_goal(L, Ds, (A, B), P, Us) :- !, ex_body(L, Ds, (A, B), P, Us).
ex_goal(L, Ds, (C -> T ; E), P, Us) :- !,
    ex_inner(L, Ds, C, CP, U1), ex_inner(L, Ds, T, TP, U2), ex_inner(L, Ds, E, EP, U3),
    append([U1, U2, U3], Us),
    format(atom(P), 'if ~w, then ~w, else ~w', [CP, TP, EP]).
ex_goal(L, Ds, (C *-> T ; E), P, Us) :- !,
    ex_inner(L, Ds, C, CP, U1), ex_inner(L, Ds, T, TP, U2), ex_inner(L, Ds, E, EP, U3),
    append([U1, U2, U3], Us),
    format(atom(P), 'for each answer of ~w, ~w; where it has none, ~w', [CP, TP, EP]).
ex_goal(L, Ds, (A ; B), P, Us) :- !,
    ex_inner(L, Ds, A, AP, U1), ex_inner(L, Ds, B, BP, U2), append(U1, U2, Us),
    format(atom(P), 'either ~w, or ~w', [AP, BP]).
ex_goal(L, Ds, (C -> T), P, Us) :- !,
    ex_inner(L, Ds, C, CP, U1), ex_inner(L, Ds, T, TP, U2), append(U1, U2, Us),
    format(atom(P), 'if ~w, then ~w, else it fails', [CP, TP]).
ex_goal(L, Ds, \+ G, P, Us) :- !,
    ex_inner(L, Ds, G, GP, Us), format(atom(P), 'it is not true that ~w', [GP]).
ex_goal(_, _, !, 'no other clause is tried', []) :- !.
ex_goal(L, Ds, G, P, Us) :-
    ex_row(G), once(ex_row_phrase(L, Ds, G, P, Us)), !.
ex_goal(_, Ds, G, P, Us) :-
    ex_term(G, T),
    format(atom(P), '~w holds', [T]),
    ( callable(G), functor(G, N, A), \+ memberchk(N/A, Ds) -> Us = [N/A] ; Us = [] ).

%% ---- the rows of the builtins (english) ----------------------------------------------
%%
%% ex_row/1 says which goals have a row; ex_row_phrase/5 makes the phrase,
%% a goal argument said by ex_body/5 and a term by ex_term/2.

ex_row(G) :- callable(G), functor(G, N, A), ex_row_pi(N/A), !.

ex_row_pi(PI) :- memberchk(PI, [
    true/0, fail/0, false/0, call/1, once/1, ignore/1, findall/3, findall/4, forall/2,
    aggregate_all/3, catch/3, throw/1, (is)/2, (=)/2, (\=)/2, (==)/2, (\==)/2,
    (=:=)/2, (=\=)/2, (<)/2, (>)/2, (=<)/2, (>=)/2, (@<)/2, (@>)/2, (@=<)/2, (@>=)/2,
    (=..)/2, functor/3, arg/3, copy_term/2, var/1, nonvar/1, atom/1, number/1,
    integer/1, float/1, atomic/1, compound/1, callable/1, is_list/1, string/1,
    ground/1, between/3, succ/2, plus/3, length/2, append/3, append/2, member/2,
    memberchk/2, nth0/3, nth1/3, last/2, reverse/2, msort/2, sort/2, sort/4,
    keysort/2, predsort/3, flatten/2, sum_list/2, max_list/2, min_list/2,
    list_to_set/2, exclude/3, include/3, partition/4, maplist/2, maplist/3,
    maplist/4, foldl/4, foldl/5, atom_concat/3, atomic_list_concat/2,
    atomic_list_concat/3, atom_codes/2, atom_chars/2, atom_length/2,
    atom_number/2, number_codes/2, sub_atom/5, upcase_atom/2, downcase_atom/2,
    term_to_atom/2, term_string/2, format/1, format/2, format/3, write/1,
    writeln/1, print/1, nl/0, print_message/2, assertz/1, asserta/1, assert/1,
    retract/1, retractall/1, clause/2, phrase/2, phrase/3, term_variables/2,
    nb_getval/2, b_getval/2, nb_setval/2, b_setval/2, must_be/2,
    use_module/1, op/3, (dynamic)/1, tab/1, string_concat/3, split_string/4,
    number_string/2, string_codes/2, string_chars/2, string_to_atom/2,
    sub_string/5, string_length/2, char_code/2, numbervars/3,
    setof/3, bagof/3, call/2, call/3, call/4, call/5, call/6]).

ex_row_phrase(_, _, true, 'true', []).
ex_row_phrase(_, _, fail, 'it fails', []).
ex_row_phrase(_, _, false, 'it fails', []).
ex_row_phrase(L, Ds, call(G), P, Us) :- ex_called(L, Ds, G, [], P, Us).
ex_row_phrase(L, Ds, G, P, Us) :-
    G =.. [call, C|As], As \== [], ex_called(L, Ds, C, As, P, Us).
ex_row_phrase(L, Ds, once(G), P, Us) :-
    ex_inner(L, Ds, G, GP, Us), format(atom(P), '~w, its first answer only', [GP]).
ex_row_phrase(L, Ds, ignore(G), P, Us) :-
    ex_inner(L, Ds, G, GP, Us), format(atom(P), '~w, where it can', [GP]).
ex_row_phrase(L, Ds, findall(T, G, Xs), P, Us) :-
    ex_paren_inner(L, Ds, G, GP, Us), ex_terms([Xs, T], [XT, TT]),
    format(atom(P), '~w is the list of every ~w for which ~w', [XT, TT, GP]).
ex_row_phrase(L, Ds, findall(T, G, Xs, Tail), P, Us) :-
    ex_paren_inner(L, Ds, G, GP, Us), ex_terms([Xs, T, Tail], [XT, TT, TlT]),
    format(atom(P), '~w is the list of every ~w for which ~w, followed by ~w', [XT, TT, GP, TlT]).
ex_row_phrase(L, Ds, setof(T, G, Xs), P, Us) :-
    ex_paren_inner(L, Ds, G, GP, Us), ex_terms([Xs, T], [XT, TT]),
    format(atom(P), '~w is the sorted set of every ~w for which ~w', [XT, TT, GP]).
ex_row_phrase(L, Ds, bagof(T, G, Xs), P, Us) :-
    ex_paren_inner(L, Ds, G, GP, Us), ex_terms([Xs, T], [XT, TT]),
    format(atom(P), '~w is the list of every ~w for which ~w, and it is not empty', [XT, TT, GP]).
ex_row_phrase(L, Ds, forall(C, A), P, Us) :-
    ex_paren_inner(L, Ds, C, CP, U1), ex_inner(L, Ds, A, AP, U2), append(U1, U2, Us),
    format(atom(P), 'for every answer of ~w, ~w', [CP, AP]).
ex_row_phrase(L, Ds, aggregate_all(count, G, N), P, Us) :- !,
    ex_paren_inner(L, Ds, G, GP, Us), ex_term(N, NT),
    format(atom(P), '~w is the number of answers of ~w', [NT, GP]).
ex_row_phrase(L, Ds, aggregate_all(S, G, N), P, Us) :-
    ex_paren_inner(L, Ds, G, GP, Us), ex_terms([N, S], [NT, ST]),
    format(atom(P), '~w is ~w over the answers of ~w', [NT, ST, GP]).
ex_row_phrase(L, Ds, catch(G, E, R), P, Us) :-
    ex_inner(L, Ds, G, GP, U1), ex_inner(L, Ds, R, RP, U2), append(U1, U2, Us), ex_term(E, ET),
    format(atom(P), '~w, and where that raises ~w, ~w', [GP, ET, RP]).
ex_row_phrase(_, _, throw(E), P, []) :- ex_term(E, ET), format(atom(P), 'it raises ~w', [ET]).
ex_row_phrase(_, _, X is E, P, []) :- ex_terms([X, E], [XT, ET]), format(atom(P), '~w is the value of ~w', [XT, ET]).
ex_row_phrase(_, _, X = Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is ~w', [XT, YT]).
ex_row_phrase(_, _, X \= Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w cannot be ~w', [XT, YT]).
ex_row_phrase(_, _, X == Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is identical to ~w', [XT, YT]).
ex_row_phrase(_, _, X \== Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is not identical to ~w', [XT, YT]).
ex_row_phrase(_, _, X =:= Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), 'the values of ~w and ~w are equal', [XT, YT]).
ex_row_phrase(_, _, X =\= Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), 'the values of ~w and ~w are not equal', [XT, YT]).
ex_row_phrase(_, _, X < Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is less than ~w', [XT, YT]).
ex_row_phrase(_, _, X > Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is greater than ~w', [XT, YT]).
ex_row_phrase(_, _, X =< Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is not greater than ~w', [XT, YT]).
ex_row_phrase(_, _, X >= Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is not less than ~w', [XT, YT]).
ex_row_phrase(_, _, X @< Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is before ~w in the standard order', [XT, YT]).
ex_row_phrase(_, _, X @> Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is after ~w in the standard order', [XT, YT]).
ex_row_phrase(_, _, X @=< Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is not after ~w in the standard order', [XT, YT]).
ex_row_phrase(_, _, X @>= Y, P, []) :- ex_terms([X, Y], [XT, YT]), format(atom(P), '~w is not before ~w in the standard order', [XT, YT]).
ex_row_phrase(_, _, T =.. L, P, []) :- ex_terms([L, T], [LT, TT]), format(atom(P), '~w is the name and the arguments of ~w', [LT, TT]).
ex_row_phrase(_, _, functor(T, N, A), P, []) :- ex_terms([T, N, A], [TT, NT, AT]), format(atom(P), '~w has the name ~w and ~w arguments', [TT, NT, AT]).
ex_row_phrase(_, _, arg(N, T, A), P, []) :- ex_terms([A, N, T], [AT, NT, TT]), format(atom(P), '~w is argument ~w of ~w', [AT, NT, TT]).
ex_row_phrase(_, _, copy_term(A, B), P, []) :- ex_terms([B, A], [BT, AT]), format(atom(P), '~w is a copy of ~w with new variables', [BT, AT]).
ex_row_phrase(_, _, var(X), P, []) :- ex_term(X, XT), format(atom(P), '~w is not bound', [XT]).
ex_row_phrase(_, _, nonvar(X), P, []) :- ex_term(X, XT), format(atom(P), '~w is bound', [XT]).
ex_row_phrase(_, _, G, P, []) :-
    G =.. [N, X], ex_type_word(N, W), !,
    ex_term(X, XT), format(atom(P), '~w is ~w', [XT, W]).
ex_row_phrase(_, _, between(Lo, Hi, X), P, []) :- ex_terms([X, Lo, Hi], [XT, LT, HT]), format(atom(P), '~w is an integer from ~w to ~w', [XT, LT, HT]).
ex_row_phrase(_, _, succ(A, B), P, []) :- ex_terms([B, A], [BT, AT]), format(atom(P), '~w is ~w plus one', [BT, AT]).
ex_row_phrase(_, _, plus(A, B, C), P, []) :- ex_terms([C, A, B], [CT, AT, BT]), format(atom(P), '~w is ~w plus ~w', [CT, AT, BT]).
ex_row_phrase(_, _, length(L, N), P, []) :- ex_terms([L, N], [LT, NT]), format(atom(P), 'the length of ~w is ~w', [LT, NT]).
ex_row_phrase(_, _, append(A, B, C), P, []) :- ex_terms([C, A, B], [CT, AT, BT]), format(atom(P), '~w is ~w followed by ~w', [CT, AT, BT]).
ex_row_phrase(_, _, append(Ls, L), P, []) :- ex_terms([L, Ls], [LT, LsT]), format(atom(P), '~w is the lists of ~w joined', [LT, LsT]).
ex_row_phrase(_, _, member(X, L), P, []) :- ex_terms([X, L], [XT, LT]), format(atom(P), '~w is a member of ~w', [XT, LT]).
ex_row_phrase(_, _, memberchk(X, L), P, []) :- ex_terms([X, L], [XT, LT]), format(atom(P), '~w is a member of ~w, the first that matches', [XT, LT]).
ex_row_phrase(_, _, nth0(I, L, X), P, []) :- ex_terms([X, I, L], [XT, IT, LT]), format(atom(P), '~w is the element at index ~w of ~w, counted from 0', [XT, IT, LT]).
ex_row_phrase(_, _, nth1(I, L, X), P, []) :- ex_terms([X, I, L], [XT, IT, LT]), format(atom(P), '~w is the element at index ~w of ~w, counted from 1', [XT, IT, LT]).
ex_row_phrase(_, _, last(L, X), P, []) :- ex_terms([X, L], [XT, LT]), format(atom(P), '~w is the last element of ~w', [XT, LT]).
ex_row_phrase(_, _, reverse(L, R), P, []) :- ex_terms([R, L], [RT, LT]), format(atom(P), '~w is ~w in the reverse order', [RT, LT]).
ex_row_phrase(_, _, msort(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is ~w in the standard order, with its duplicates', [ST, LT]).
ex_row_phrase(_, _, sort(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is ~w in the standard order, without duplicates', [ST, LT]).
ex_row_phrase(_, _, sort(K, O, L, S), P, []) :- ex_terms([S, L, K, O], [ST, LT, KT, OT]), format(atom(P), '~w is ~w sorted on argument ~w by ~w', [ST, LT, KT, OT]).
ex_row_phrase(_, _, keysort(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is the pairs of ~w sorted by their keys', [ST, LT]).
ex_row_phrase(_, _, predsort(G, L, S), P, []) :- ex_terms([S, L, G], [ST, LT, GT]), format(atom(P), '~w is ~w sorted by ~w', [ST, LT, GT]).
ex_row_phrase(_, _, flatten(L, F), P, []) :- ex_terms([F, L], [FT, LT]), format(atom(P), '~w is ~w with its nested lists flattened', [FT, LT]).
ex_row_phrase(_, _, sum_list(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is the sum of ~w', [ST, LT]).
ex_row_phrase(_, _, max_list(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is the largest number of ~w', [ST, LT]).
ex_row_phrase(_, _, min_list(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is the smallest number of ~w', [ST, LT]).
ex_row_phrase(_, _, list_to_set(L, S), P, []) :- ex_terms([S, L], [ST, LT]), format(atom(P), '~w is ~w without duplicates', [ST, LT]).
ex_row_phrase(_, _, include(G, L, I), P, []) :- ex_terms([I, L, G], [IT, LT, GT]), format(atom(P), '~w is the elements of ~w for which ~w holds', [IT, LT, GT]).
ex_row_phrase(_, _, exclude(G, L, I), P, []) :- ex_terms([I, L, G], [IT, LT, GT]), format(atom(P), '~w is the elements of ~w for which ~w does not hold', [IT, LT, GT]).
ex_row_phrase(_, _, partition(G, L, I, E), P, []) :- ex_terms([I, E, L, G], [IT, ET, LT, GT]), format(atom(P), '~w and ~w are the elements of ~w for which ~w holds and does not hold', [IT, ET, LT, GT]).
ex_row_phrase(_, _, maplist(G, L), P, []) :- ex_terms([G, L], [GT, LT]), format(atom(P), '~w holds for each element of ~w', [GT, LT]).
ex_row_phrase(_, _, maplist(G, L1, L2), P, []) :- ex_terms([G, L1, L2], [GT, L1T, L2T]), format(atom(P), '~w holds for each pair of elements of ~w and ~w', [GT, L1T, L2T]).
ex_row_phrase(_, _, maplist(G, L1, L2, L3), P, []) :- ex_terms([G, L1, L2, L3], [GT, L1T, L2T, L3T]), format(atom(P), '~w holds for each three elements of ~w, ~w and ~w', [GT, L1T, L2T, L3T]).
ex_row_phrase(_, _, foldl(G, L, V0, V), P, []) :- ex_terms([V, G, L, V0], [VT, GT, LT, V0T]), format(atom(P), '~w is ~w applied to each element of ~w in turn, from ~w', [VT, GT, LT, V0T]).
ex_row_phrase(_, _, foldl(G, L1, L2, V0, V), P, []) :- ex_terms([V, G, L1, L2, V0], [VT, GT, L1T, L2T, V0T]), format(atom(P), '~w is ~w applied to each pair of ~w and ~w in turn, from ~w', [VT, GT, L1T, L2T, V0T]).
ex_row_phrase(_, _, atom_concat(A, B, C), P, []) :- ex_terms([C, A, B], [CT, AT, BT]), format(atom(P), 'the atom ~w is ~w followed by ~w', [CT, AT, BT]).
ex_row_phrase(_, _, atomic_list_concat(L, A), P, []) :- ex_terms([A, L], [AT, LT]), format(atom(P), 'the atom ~w is the parts of ~w joined', [AT, LT]).
ex_row_phrase(_, _, atomic_list_concat(L, S, A), P, []) :- ex_terms([A, L, S], [AT, LT, ST]), format(atom(P), 'the atom ~w is the parts of ~w joined by ~w', [AT, LT, ST]).
ex_row_phrase(_, _, atom_codes(A, C), P, []) :- ex_terms([C, A], [CT, AT]), format(atom(P), '~w is the character codes of ~w', [CT, AT]).
ex_row_phrase(_, _, atom_chars(A, C), P, []) :- ex_terms([C, A], [CT, AT]), format(atom(P), '~w is the characters of ~w', [CT, AT]).
ex_row_phrase(_, _, atom_length(A, N), P, []) :- ex_terms([A, N], [AT, NT]), format(atom(P), 'the atom ~w has ~w characters', [AT, NT]).
ex_row_phrase(_, _, atom_number(A, N), P, []) :- ex_terms([A, N], [AT, NT]), format(atom(P), 'the atom ~w is the number ~w', [AT, NT]).
ex_row_phrase(_, _, number_codes(N, C), P, []) :- ex_terms([C, N], [CT, NT]), format(atom(P), '~w is the character codes of the number ~w', [CT, NT]).
ex_row_phrase(_, _, sub_atom(A, B, L, Af, S), P, []) :- ex_terms([S, A, B, L, Af], [ST, AT, BT, LT, AfT]), format(atom(P), '~w is the part of ~w after ~w characters, of length ~w, before ~w', [ST, AT, BT, LT, AfT]).
ex_row_phrase(_, _, upcase_atom(A, U), P, []) :- ex_terms([U, A], [UT, AT]), format(atom(P), '~w is ~w in capitals', [UT, AT]).
ex_row_phrase(_, _, downcase_atom(A, D), P, []) :- ex_terms([D, A], [DT, AT]), format(atom(P), '~w is ~w in small letters', [DT, AT]).
ex_row_phrase(_, _, term_to_atom(T, A), P, []) :- ex_terms([A, T], [AT, TT]), format(atom(P), 'the atom ~w is the text of ~w', [AT, TT]).
ex_row_phrase(_, _, term_string(T, S), P, []) :- ex_terms([S, T], [ST, TT]), format(atom(P), 'the string ~w is the text of ~w', [ST, TT]).
ex_row_phrase(_, _, format(F), P, []) :- ex_term(F, FT), format(atom(P), 'it writes ~w', [FT]).
ex_row_phrase(_, _, format(F, As), P, []) :- ex_terms([F, As], [FT, AT]), format(atom(P), 'it writes ~w with ~w', [FT, AT]).
ex_row_phrase(_, _, format(atom(A), F, As), P, []) :- !, ex_terms([A, F, As], [AT, FT, AsT]), format(atom(P), 'the atom ~w is ~w with ~w', [AT, FT, AsT]).
ex_row_phrase(_, _, format(S, F, As), P, []) :- ex_terms([S, F, As], [ST, FT, AT]), format(atom(P), 'it writes ~w with ~w to ~w', [FT, AT, ST]).
ex_row_phrase(_, _, write(X), P, []) :- ex_term(X, XT), format(atom(P), 'it writes ~w', [XT]).
ex_row_phrase(_, _, print(X), P, []) :- ex_term(X, XT), format(atom(P), 'it writes ~w', [XT]).
ex_row_phrase(_, _, writeln(X), P, []) :- ex_term(X, XT), format(atom(P), 'it writes ~w and a new line', [XT]).
ex_row_phrase(_, _, nl, 'it writes a new line', []).
ex_row_phrase(_, _, tab(N), P, []) :- ex_term(N, NT), format(atom(P), 'it writes ~w spaces', [NT]).
ex_row_phrase(_, _, print_message(K, M), P, []) :- ex_terms([M, K], [MT, KT]), format(atom(P), 'it reports ~w as ~w', [MT, KT]).
ex_row_phrase(_, _, assertz(C), P, []) :- ex_term(C, CT), format(atom(P), 'the clause ~w is added at the end of its predicate', [CT]).
ex_row_phrase(_, _, assert(C), P, []) :- ex_term(C, CT), format(atom(P), 'the clause ~w is added at the end of its predicate', [CT]).
ex_row_phrase(_, _, asserta(C), P, []) :- ex_term(C, CT), format(atom(P), 'the clause ~w is added at the start of its predicate', [CT]).
ex_row_phrase(_, _, retract(C), P, []) :- ex_term(C, CT), format(atom(P), 'a clause ~w is removed', [CT]).
ex_row_phrase(_, _, retractall(H), P, []) :- ex_term(H, HT), format(atom(P), 'every clause of ~w is removed', [HT]).
ex_row_phrase(_, _, clause(H, B), P, []) :- ex_terms([H, B], [HT, BT]), format(atom(P), '~w :- ~w is a clause of the program', [HT, BT]).
ex_row_phrase(_, _, phrase(G, L), P, []) :- ex_terms([L, G], [LT, GT]), format(atom(P), '~w is a phrase ~w', [LT, GT]).
ex_row_phrase(_, _, phrase(G, L, R), P, []) :- ex_terms([L, G, R], [LT, GT, RT]), format(atom(P), '~w is a phrase ~w followed by ~w', [LT, GT, RT]).
ex_row_phrase(_, _, term_variables(T, Vs), P, []) :- ex_terms([Vs, T], [VT, TT]), format(atom(P), '~w is the list of the variables of ~w', [VT, TT]).
ex_row_phrase(_, _, nb_getval(K, V), P, []) :- ex_terms([V, K], [VT, KT]), format(atom(P), '~w is the value of the global ~w', [VT, KT]).
ex_row_phrase(_, _, b_getval(K, V), P, []) :- ex_terms([V, K], [VT, KT]), format(atom(P), '~w is the value of the global ~w', [VT, KT]).
ex_row_phrase(_, _, nb_setval(K, V), P, []) :- ex_terms([K, V], [KT, VT]), format(atom(P), 'the global ~w is set to ~w', [KT, VT]).
ex_row_phrase(_, _, b_setval(K, V), P, []) :- ex_terms([K, V], [KT, VT]), format(atom(P), 'the global ~w is set to ~w until backtracking', [KT, VT]).
ex_row_phrase(_, _, must_be(T, X), P, []) :- ex_terms([X, T], [XT, TT]), format(atom(P), '~w must be of the type ~w, else an error is raised', [XT, TT]).
ex_row_phrase(_, _, use_module(library(X)), P, []) :- !, ex_term(X, XT), format(atom(P), 'the library ~w is loaded', [XT]).
ex_row_phrase(_, _, use_module(F), P, []) :- ex_term(F, FT), format(atom(P), 'the file ~w is loaded', [FT]).
ex_row_phrase(_, _, op(Pr, Ty, N), P, []) :- ex_terms([N, Pr], [NT, PrT]), ex_op_kind(Ty, K), format(atom(P), '~w is made ~w of priority ~w', [NT, K, PrT]).
ex_row_phrase(_, _, dynamic(S), P, []) :- ex_term(S, ST), format(atom(P), '~w is made dynamic', [ST]).
ex_row_phrase(_, _, string_concat(A, B, C), P, []) :- ex_terms([C, A, B], [CT, AT, BT]), format(atom(P), 'the string ~w is ~w followed by ~w', [CT, AT, BT]).
ex_row_phrase(_, _, split_string(S, Sep, Pad, Ps), P, []) :- ex_terms([Ps, S, Sep, Pad], [PsT, ST, SepT, PadT]), format(atom(P), '~w is the parts of ~w cut at ~w, ~w taken off their ends', [PsT, ST, SepT, PadT]).
ex_row_phrase(_, _, number_string(N, S), P, []) :- ex_terms([S, N], [ST, NT]), format(atom(P), 'the string ~w is the number ~w', [ST, NT]).
ex_row_phrase(_, _, string_codes(S, C), P, []) :- ex_terms([C, S], [CT, ST]), format(atom(P), '~w is the character codes of the string ~w', [CT, ST]).
ex_row_phrase(_, _, string_chars(S, C), P, []) :- ex_terms([C, S], [CT, ST]), format(atom(P), '~w is the characters of the string ~w', [CT, ST]).
ex_row_phrase(_, _, string_to_atom(S, A), P, []) :- ex_terms([A, S], [AT, ST]), format(atom(P), 'the atom ~w is the string ~w', [AT, ST]).
ex_row_phrase(_, _, sub_string(S, B, L, Af, Sub), P, []) :- ex_terms([Sub, S, B, L, Af], [SubT, ST, BT, LT, AfT]), format(atom(P), '~w is the part of ~w after ~w characters, of length ~w, before ~w', [SubT, ST, BT, LT, AfT]).
ex_row_phrase(_, _, string_length(S, N), P, []) :- ex_terms([S, N], [ST, NT]), format(atom(P), 'the string ~w has ~w characters', [ST, NT]).
ex_row_phrase(_, _, char_code(C, N), P, []) :- ex_terms([C, N], [CT, NT]), format(atom(P), 'the character ~w has the code ~w', [CT, NT]).
ex_row_phrase(_, _, numbervars(T, S, E), P, []) :- ex_terms([T, S, E], [TT, ST, ET]), format(atom(P), 'the variables of ~w are named from ~w to ~w', [TT, ST, ET]).

ex_type_word(atom, 'an atom').
ex_type_word(number, 'a number').
ex_type_word(integer, 'an integer').
ex_type_word(float, 'a float').
ex_type_word(atomic, 'atomic').
ex_type_word(compound, 'a compound term').
ex_type_word(callable, 'callable').
ex_type_word(is_list, 'a proper list').
ex_type_word(string, 'a string').
ex_type_word(ground, 'a term with no variables').

%% A goal called with arguments: a goal of the program the text says as
%% its phrase, a variable or a closure as `the goal G is called'.
ex_called(_, _, G, As, P, []) :-
    ex_terms([G|As], [GT|AsT]),
    (   As == [] -> format(atom(P), 'the goal ~w is called', [GT])
    ;   ex_and(AsT, AT), format(atom(P), 'the goal ~w is called with ~w', [GT, AT])
    ).

%% ---- a grammar rule's body -----------------------------------------------------------

%% A grammar rule's body: `empty, where ...' where it takes no item and
%% calls no phrase, else `: ...', its items in order.
ex_dcg_body(L, Ds, B, P, Us) :-
    ex_conj(B, Is0),
    ( Is0 = [_, _|_] -> exclude(==(true), Is0, Is) ; Is = Is0 ),
    ex_dcg_items(L, Ds, Is, Ps, Us),
    (   Ps == [] -> P = 'empty'
    ;   \+ ( member(I, Is), ex_dcg_takes(I) )
    ->  ex_and(Ps, P0), format(atom(P), 'empty, ~w', [P0])
    ;   ex_and(Ps, P0), format(atom(P), ': ~w', [P0])
    ).

%% An item that takes a part of the phrase: a list that is not empty, a
%% string, a non-terminal, a construct of them.
ex_dcg_takes(I) :- var(I), !.
ex_dcg_takes(I) :- I = '$VAR'(_), !.
ex_dcg_takes(!) :- !, fail.
ex_dcg_takes([]) :- !, fail.
ex_dcg_takes({}(_)) :- !, fail.
ex_dcg_takes(I) :- functor(I, N, A), memberchk(N/A, [(',')/2, (;)/2, (->)/2]), !,
    I =.. [_|As], member(X, As), ex_dcg_takes(X), !.
ex_dcg_takes(_).

ex_dcg_space(BP, Sp) :- ( sub_atom(BP, 0, 1, _, ':') -> Sp = '' ; Sp = ' ' ).

ex_dcg_items(_, _, [], [], []).
ex_dcg_items(L, Ds, [I|Is], Ps, Us) :-
    ex_dcg_item(L, Ds, I, P, Us1),
    ex_dcg_items(L, Ds, Is, Ps1, Us2),
    ( P == '' -> Ps = Ps1 ; Ps = [P|Ps1] ),
    append(Us1, Us2, Us).

ex_dcg_item(_, _, I, P, []) :- I = '$VAR'(_), !, ex_term(I, T), format(atom(P), 'a phrase ~w', [T]).
ex_dcg_item(_, _, !, 'no other rule is tried', []) :- !.
ex_dcg_item(_, _, [], '', []) :- !.
ex_dcg_item(_, _, L, P, []) :- is_list(L), !,
    ex_terms(L, Ts), ex_and(Ts, T),
    ( L = [_] -> format(atom(P), 'the item ~w', [T]) ; format(atom(P), 'the items ~w', [T]) ).
ex_dcg_item(_, _, S, P, []) :- string(S), !, format(atom(P), 'the text "~w"', [S]).
ex_dcg_item(L, Ds, {}(G), P, Us) :- !, ex_body(L, Ds, G, GP, Us), format(atom(P), 'where ~w', [GP]).
ex_dcg_item(L, Ds, (C -> T ; E), P, Us) :- !,
    ex_dcg_body(L, Ds, C, CP, U1), ex_dcg_body(L, Ds, T, TP, U2), ex_dcg_body(L, Ds, E, EP, U3),
    append([U1, U2, U3], Us),
    format(atom(P), 'if ~w, then ~w, else ~w', [CP, TP, EP]).
ex_dcg_item(L, Ds, (A ; B), P, Us) :- !,
    ex_dcg_body(L, Ds, A, AP, U1), ex_dcg_body(L, Ds, B, BP, U2), append(U1, U2, Us),
    format(atom(P), 'either ~w, or ~w', [AP, BP]).
ex_dcg_item(L, Ds, (C -> T), P, Us) :- !,
    ex_dcg_body(L, Ds, C, CP, U1), ex_dcg_body(L, Ds, T, TP, U2), append(U1, U2, Us),
    format(atom(P), 'if ~w, then ~w', [CP, TP]).
ex_dcg_item(L, Ds, \+ A, P, Us) :- !,
    ex_dcg_body(L, Ds, A, AP, Us), format(atom(P), 'not ~w', [AP]).
ex_dcg_item(L, Ds, (A, B), P, Us) :- !, ex_dcg_body(L, Ds, (A, B), P, Us).
ex_dcg_item(_, Ds, NT, P, Us) :-
    ex_term(NT, T), format(atom(P), 'a phrase ~w', [T]),
    (   callable(NT), functor(NT, N, A0), A is A0 + 2, \+ memberchk(N/A, Ds), \+ ex_dcg_builtin(N/A0)
    ->  Us = [N/A]
    ;   Us = []
    ).

%% The grammar's own non-terminals (call//N, phrase//N) are no name to
%% explain.
ex_dcg_builtin(call/_).

%% ---- terms -------------------------------------------------------------------------

%% A term as text: the source's operators with a space on each side of an
%% infix one (`J * Cin', `Y := index_rows(Xz, I) matmul rows(K, F, To)'),
%% a list in brackets, {G} in braces, any other compound as its name and
%% its arguments.
ex_term(T, A) :- ex_term(T, 1200, A).

ex_term(T, _, '_') :- var(T), !.
ex_term('$VAR'(N), _, A) :- !, ( atom(N) -> A = N ; ex_write(N, A) ).
ex_term(T, _, A) :- ( atomic(T) ; is_list(T), T == [] ), !, ex_write(T, A).
ex_term(T, _, A) :- T = [_|_], !, ex_list(T, Ps, Tail), ex_terms_at(Ps, 999, As),
    atomic_list_concat(As, ', ', I),
    (   Tail == [] -> format(atom(A), '[~w]', [I])
    ;   ex_term(Tail, 999, TA), format(atom(A), '[~w|~w]', [I, TA])
    ).
ex_term({}(G), _, A) :- !, ex_term(G, 1200, GA), format(atom(A), '{~w}', [GA]).
ex_term(N/Ar, _, A) :- atom(N), integer(Ar), !, ex_write(N, NA), format(atom(A), '~w/~w', [NA, Ar]).
ex_term(T, Max, A) :-
    T =.. [F, X, Y], atom(F), current_op(P, Ty, F), memberchk(Ty, [xfx, xfy, yfx]), !,
    ex_op_sides(Ty, P, LP, RP),
    ex_term(X, LP, XA), ex_term(Y, RP, YA), ex_write(F, FA),
    ( F == (',') -> Sep = ', ' ; atomic_list_concat([' ', FA, ' '], Sep) ),
    atomic_list_concat([XA, Sep, YA], A0),
    ex_paren(P, Max, A0, A).
ex_term(T, Max, A) :-
    T =.. [F, X], atom(F), current_op(P, Ty, F), memberchk(Ty, [fx, fy]), \+ number(X), !,
    ( Ty == fy -> AP = P ; AP is P - 1 ),
    ex_term(X, AP, XA), ex_write(F, FA),
    format(atom(A0), '~w ~w', [FA, XA]),
    ex_paren(P, Max, A0, A).
ex_term(T, _, A) :-
    compound(T), T =.. [F|As], ex_write(F, FA), ex_terms_at(As, 999, Ts),
    atomic_list_concat(Ts, ', ', I), format(atom(A), '~w(~w)', [FA, I]).

ex_op_sides(xfx, P, L, L) :- L is P - 1.
ex_op_sides(xfy, P, L, P) :- L is P - 1.
ex_op_sides(yfx, P, P, R) :- R is P - 1.

ex_paren(P, Max, A0, A) :- ( P > Max -> format(atom(A), '(~w)', [A0]) ; A = A0 ).

ex_terms_at([], _, []).
ex_terms_at([T|Ts], P, [A|As]) :- ex_term(T, P, A), ex_terms_at(Ts, P, As).

ex_list(T, [], T) :- var(T), !.
ex_list([X|Xs], [X|Ps], Tail) :- !, ex_list(Xs, Ps, Tail).
ex_list(T, [], T).

ex_write(T, A) :-
    with_output_to(string(S), writeq(T)), atom_string(A, S).

ex_terms(Ts, As) :- maplist(ex_term, Ts, As).
