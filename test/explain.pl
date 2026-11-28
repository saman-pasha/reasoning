%% library(reasoning/explain) -- a Cocolog program said in English (since
%% 1.80.0).
%%
%%     cocolog -s test/explain.pl        from this repository's root

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/explain)).

main :-
    forall(member(S, [logic_sentences, rules, controls, grammar, directives,
                      languages, library_measure, arguments]), once(S)),
    checks_done.

%% A clause of the logic form is said as the translator says it.
logic_sentences :-
    section('the logic form, said by the translator'),
    explain_text(english, 'mortal(X) :- human(X).\nhuman(socrates).\nfather(john, mary).', E1),
    check('three clauses of the logic form', E1,
          'Every human is mortal.\n\nSocrates is human.\n\nJohn is Mary\'s father.').

%% A rule's body: each goal a phrase, the source's names and operators.
rules :-
    section('a rule and the builtins'),
    forall(member(T-Want, [
               'area(W, H, A) :- A is W * H.'-'area/3 takes three arguments: W, an input; H, an input; and A, an output.\n\narea(W, H, A) holds if A is the value of W * H.',
               'evens(L, Es) :- findall(X, ( member(X, L), 0 is X mod 2 ), Es).'-
                   'evens/2 takes two arguments: L, an input, and Es, an output.\n\nevens(L, Es) holds if Es is the list of every X for which (X is a member of L and 0 is the value of X mod 2).',
               'count(L, N) :- aggregate_all(count, member(_, L), N).'-
                   'count/2 takes two arguments: L, an input, and N, an output.\n\ncount(L, N) holds if N is the number of answers of (_ is a member of L).',
               'grandfather(X, Z) :- father(X, Y), father(Y, Z).'-
                   'grandfather(X, Z) holds if father(X, Y) holds and father(Y, Z) holds.',
               'size(L, N) :- length(L, N), N > 0.'-'size/2 takes two arguments: L, an input, and N, an output.\n\nsize(L, N) holds if the length of L is N and N is greater than 0.' ]),
           ( explain_text(english, T, E), atomic_list_concat(['explained: ', T], Label), check(Label, E, Want) )).

%% The control constructs: if-then-else, the cut, negation.
controls :-
    section('the control constructs'),
    forall(member(T-Want, [
               'sign(X, S) :- ( X < 0 -> S = minus ; S = plus ).'-
                   'sign/2 takes two arguments: X, an input, and S, an output.\n\nsign(X, S) holds as follows: if X is less than 0, then S is minus, else S is plus.',
               'max(X, Y, X) :- X >= Y, !.'-'max/3 takes three arguments: the first argument, an input; Y, an input; and the third argument, an output.\n\nmax(X, Y, X) holds if X is not less than Y and no other clause is tried.',
               'first([X|_], X) :- !.'-'first/2 takes two arguments: the first argument, an input, and the second argument, an output.\n\nfirst([X|_], X) holds. When its head matches, no other clause is tried.',
               'lonely(X) :- \\+ friend(X, _).'-'lonely(X) holds if it is not true that friend(X, _) holds.',
               'g(X, Y) :- X > 0, ( Y = a ; Y = b ), !.'-
                   'g/2 takes two arguments: X, an input, and Y, an output.\n\ng(X, Y) holds if X is greater than 0, (either Y is a, or Y is b) and no other clause is tried.' ]),
           ( explain_text(english, T, E), atomic_list_concat(['explained: ', T], Label), check(Label, E, Want) )).

%% A grammar rule: its items in order; one that takes nothing is empty.
grammar :-
    section('the grammar rules'),
    forall(member(T-Want, [
               'greeting --> [hello], name.'-'A phrase greeting is: the item hello and a phrase name.',
               'digits([D|T]) --> digit(D), !, digits(T).'-
                   'A phrase digits([D|T]) is: a phrase digit(D), no other rule is tried and a phrase digits(T).',
               'digits([]) --> [].'-'A phrase digits([]) is empty.',
               'number(N, N) --> { float(N) }, !.'-'number//2 takes two arguments: the first argument, an input, and the second argument, an output; and two lists, the list before its phrase and the list after it.\n\nA phrase number(N, N) is empty, where N is a float and no other rule is tried.',
               'word(W) --> !, [W].'-'A phrase word(W) is: the item W. When its head matches, no other rule is tried.' ]),
           ( explain_text(english, T, E), atomic_list_concat(['explained: ', T], Label), check(Label, E, Want) )).

%% A directive is a sentence, and an operator it makes reads the next
%% clause.
directives :-
    section('the directives'),
    explain_text(english, ':- use_module(library(lists)).\n:- dynamic seen/1.\n:- op(700, xfx, ===>).\na ===> b.', E1),
    check('a directive each, and the operator obeyed', E1,
          'This file uses the library lists.\n\nThis file makes seen/1 dynamic: a program adds and removes its clauses.\n\nThis file makes ===> an infix operator of priority 700.\n\na ===> b holds.').

languages :-
    section('the languages'),
    catch(( explain_text(spanish, 'a.', _), R = explained ), error(domain_error(explain_language, L), _), R = refused(L)),
    check('English only: another language is refused by name', R, refused(spanish)).

%% The test the owner asked for: cocolog's library(tensor_expr), where the
%% cocolog checkout is beside this repository.
library_measure :-
    section('cocolog\'s library(tensor_expr)'),
    F = '../cocolog/library/tensor_expr.pl',
    (   exists_file(F)
    ->  explain_measure(english, F, measure(N, _, Full, Us)),
        check('its clauses', N, 217),
        ( Full >= 177 -> VF = ok ; VF = Full ),
        check('at least 177 with every goal explained or its own', VF, ok),
        ( forall(member(Nm/_-_, Us), ( sub_atom(Nm, 0, _, _, tensor) ; sub_atom(Nm, 0, _, _, model) ; sub_atom(Nm, 0, _, _, torch) )) -> VU = ok ; VU = Us ),
        check('the names said as terms are library(torch)\'s', VU, ok),
        explain_file(english, F, Es),
        ( member(explained(C, E, _), Es), sub_atom(C, 0, _, _, '\'$te_gathers\'([I|Is]') -> true ; E = none ),
        check('a clause with an if-then-else among its goals', E,
              '\'$te_gathers\'([I|Is], J, Xz, K, Cin, Acc, T) holds if F is the value of J * Cin, To is the value of F + Cin, Y := index_rows(Xz, I) matmul rows(K, F, To) holds, (if Acc is identical to none, then Acc2 is Y, else (Acc2 := Acc + Y holds and free_all([Acc, Y]) holds)), J1 is the value of J + 1 and \'$te_gathers\'(Is, J1, Xz, K, Cin, Acc2, T) holds.')
    ;   format("   (no ../cocolog/library/tensor_expr.pl: this section is skipped)~n")
    ).

%% 1.85.0: EACH ARGUMENT'S ROLE -- a goal, an input, an output, either, a
%% term -- from a meta_predicate declaration, a mode comment or the
%% clauses, said before a predicate's first clause where one is more than
%% a term.
arguments :-
    section('the arguments'),
    forall(member(T-Want, [
               'area(W, H, A) :- A is W * H.'-[role('W', input, inferred), role('H', input, inferred), role('A', output, inferred)],
               'twice(G) :- call(G), call(G).'-[role('G', goal(0), inferred)],
               'apply_all(G, L) :- maplist(G, L).'-[role('G', goal(1), inferred), role('L', term, inferred)],
               '%% pick(-X, +List)\npick(X, L) :- member(X, L).'-[role('X', output, comment), role('List', input, comment)],
               ':- meta_predicate run(0, ?).\nrun(G, R) :- ( call(G) -> R = yes ; R = no ).'-[role('G', goal(0), declared), role('R', either, declared)],
               'len([], 0).\nlen([_|T], N) :- len(T, N0), N is N0 + 1.'-[role('the first argument', input, inferred), role('N', output, inferred)],
               'app([], L, L).\napp([H|T], L, [H|R]) :- app(T, L, R).'-[role('the first argument', input, inferred), role('L', term, inferred), role('the third argument', output, inferred)],
               'color(red).\ncolor(blue).'-[role('the first argument', term, inferred)] ]),
           ( explain_arguments(english, T, [arguments(_, Rs, _)|_]),
             atomic_list_concat(Ls, '\n', T), atomic_list_concat(Ls, ' ', T1),
             atomic_list_concat(['roles: ', T1], Label), check(Label, Rs, Want) )),
    explain_arguments(english, 'digit(D) --> [D], { code_type(D, digit) }.\ndigits([D|T]) --> digit(D), !, digits(T).\ndigits([]) --> [].', As2),
    findall(PI2-R2, member(arguments(PI2, [role(_, R2, _)|_], _), As2), Rs2),
    check('a grammar rule: what a terminal holds is an output', Rs2, [digit/3-output, digits/3-output]),
    explain_text(english, 'digit(D) --> [D], { code_type(D, digit) }.', E3),
    check('a grammar rule\'s sentence', E3,
          'digit//1 takes one argument: D, an output; and two lists, the list before its phrase and the list after it.\n\nA phrase digit(D) is: the item D and where code_type(D, digit) holds.'),
    explain_text(english, 'zork(red).\nzork(blue).', E4),
    check('only terms: no sentence', E4, 'zork(red) holds.\n\nzork(blue) holds.'),
    %% A bare noun of an adjective's word is a subject since 1.142.0.
    explain_text(english, 'color(red).\ncolor(blue).', E4b),
    check('facts the translator says', E4b, 'Red is a color.\n\nBlue is a color.'),
    explain_text(english, 'mortal(X) :- human(X).', E5),
    check('a clause the translator says: no sentence', E5, 'Every human is mortal.'),
    explain_text(english, ':- meta_predicate twice(0).\ntwice(G) :- call(G), call(G).', E6),
    check('the declaration said, and the role it gives', E6,
          'This file declares the meta-predicate twice(0): an argument 0 to 9 is a goal it calls with that many more arguments.\n\ntwice/1 takes one argument: G, a goal it calls.\n\ntwice(G) holds if the goal G is called and the goal G is called.'),
    F = '../cocolog/library/tensor_expr.pl',
    (   exists_file(F)
    ->  explain_arguments_measure(english, F, measure(N7, A7, Ms7)),
        check('cocolog\'s library(tensor_expr): the arguments its mode comments name', N7, 41),
        ( A7 >= 41 -> V7 = ok ; V7 = Ms7 ),
        check('... every one inferred as its comment says, the comment unread', V7, ok)
    ;   format("   (no ../cocolog/library/tensor_expr.pl: the measure is skipped)~n")
    ).
