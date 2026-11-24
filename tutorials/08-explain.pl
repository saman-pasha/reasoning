%% The reasoning tutorial 08 -- library(reasoning/explain): a Cocolog
%% program said in English.
%%
%% TIER 2: `use_module(library(reasoning/explain))', from explain.pl, over
%% library(reasoning/logic) (lesson 07). Clauses only: no model, no store.
%%
%%     cocolog -s tutorials/08-explain.pl
%%
%% TWO WAYS INTO ENGLISH. The translator (lesson 07) says the logic form:
%% a fact, a rule, a query whose predicates are English words, and it keeps
%% a sentence only where it reads back to the same clause. A program has
%% more: a cut, an if-then-else, arithmetic, a grammar rule, a builtin, a
%% name that is no English word. The explainer says each clause of a
%% program: the translator's sentence where there is one, else an
%% explanation, a phrase for each control construct and builtin it has a
%% row for, and the term with `holds' for any other goal. An explanation
%% does not read back.

:- use_module(library(reasoning/explain)).

main :-
    the_logic_form,
    a_rule,
    the_controls,
    a_grammar,
    a_directive,
    format("~ndone~n", []).

%% 1. A CLAUSE OF THE LOGIC FORM is said as the translator says it.
the_logic_form :-
    explain_text(english, 'mortal(X) :- human(X).', E1),
    must('a rule of English words', E1, 'Every human is mortal.').

%% 2. A RULE'S BODY: each goal a phrase, the source's variable names and
%% operators kept.
a_rule :-
    explain_text(english, 'area(W, H, A) :- A is W * H.', E1),
    must('arithmetic', E1, 'area(W, H, A) holds if A is the value of W * H.'),
    explain_text(english, 'evens(L, Es) :- findall(X, ( member(X, L), 0 is X mod 2 ), Es).', E2),
    must('findall', E2, 'evens(L, Es) holds if Es is the list of every X for which (X is a member of L and 0 is the value of X mod 2).').

%% 3. THE CONTROL CONSTRUCTS. A cut that begins a body is a sentence of its
%% own: once the head matches, no other clause is tried.
the_controls :-
    explain_text(english, 'sign(X, S) :- ( X < 0 -> S = minus ; S = plus ).', E1),
    must('if-then-else', E1, 'sign(X, S) holds as follows: if X is less than 0, then S is minus, else S is plus.'),
    explain_text(english, 'first([X|_], X) :- !.', E2),
    must('a cut', E2, 'first([X|_], X) holds. When its head matches, no other clause is tried.'),
    explain_text(english, 'lonely(X) :- \\+ friend(X, _).', E3),
    must('negation', E3, 'lonely(X) holds if it is not true that friend(X, _) holds.').

%% 4. A GRAMMAR RULE is its items in order; one that takes nothing is
%% empty.
a_grammar :-
    explain_text(english, 'greeting --> [hello], name.', E1),
    must('items and a phrase', E1, 'A phrase greeting is: the item hello and a phrase name.'),
    explain_text(english, 'number(N, N) --> { float(N) }, !.', E2),
    must('a condition', E2, 'A phrase number(N, N) is empty, where N is a float and no other rule is tried.').

%% 5. A DIRECTIVE is a sentence, and an operator it makes is obeyed by the
%% clauses after it.
a_directive :-
    explain_text(english, ':- op(700, xfx, ===>).\na ===> b.', E1),
    must('an operator, then a clause that uses it', E1,
         'This file makes ===> an infix operator of priority 700.\n\na ===> b holds.').


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
