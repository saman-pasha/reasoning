%% library(reasoning/explain) -- a Cocolog program said in English (since
%% 1.80.0).
%%
%%     cocolog -s test/explain.pl        from this repository's root

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/explain)).

main :-
    forall(member(S, [logic_sentences, rules, controls, grammar, directives,
                      languages, library_measure]), once(S)),
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
               'area(W, H, A) :- A is W * H.'-'area(W, H, A) holds if A is the value of W * H.',
               'evens(L, Es) :- findall(X, ( member(X, L), 0 is X mod 2 ), Es).'-
                   'evens(L, Es) holds if Es is the list of every X for which (X is a member of L and 0 is the value of X mod 2).',
               'count(L, N) :- aggregate_all(count, member(_, L), N).'-
                   'count(L, N) holds if N is the number of answers of (_ is a member of L).',
               'grandfather(X, Z) :- father(X, Y), father(Y, Z).'-
                   'grandfather(X, Z) holds if father(X, Y) holds and father(Y, Z) holds.',
               'size(L, N) :- length(L, N), N > 0.'-'size(L, N) holds if the length of L is N and N is greater than 0.' ]),
           ( explain_text(english, T, E), atomic_list_concat(['explained: ', T], Label), check(Label, E, Want) )).

%% The control constructs: if-then-else, the cut, negation.
controls :-
    section('the control constructs'),
    forall(member(T-Want, [
               'sign(X, S) :- ( X < 0 -> S = minus ; S = plus ).'-
                   'sign(X, S) holds as follows: if X is less than 0, then S is minus, else S is plus.',
               'max(X, Y, X) :- X >= Y, !.'-'max(X, Y, X) holds if X is not less than Y and no other clause is tried.',
               'first([X|_], X) :- !.'-'first([X|_], X) holds. When its head matches, no other clause is tried.',
               'lonely(X) :- \\+ friend(X, _).'-'lonely(X) holds if it is not true that friend(X, _) holds.',
               'g(X, Y) :- X > 0, ( Y = a ; Y = b ), !.'-
                   'g(X, Y) holds if X is greater than 0, (either Y is a, or Y is b) and no other clause is tried.' ]),
           ( explain_text(english, T, E), atomic_list_concat(['explained: ', T], Label), check(Label, E, Want) )).

%% A grammar rule: its items in order; one that takes nothing is empty.
grammar :-
    section('the grammar rules'),
    forall(member(T-Want, [
               'greeting --> [hello], name.'-'A phrase greeting is: the item hello and a phrase name.',
               'digits([D|T]) --> digit(D), !, digits(T).'-
                   'A phrase digits([D|T]) is: a phrase digit(D), no other rule is tried and a phrase digits(T).',
               'digits([]) --> [].'-'A phrase digits([]) is empty.',
               'number(N, N) --> { float(N) }, !.'-'A phrase number(N, N) is empty, where N is a float and no other rule is tried.',
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
