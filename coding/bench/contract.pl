%% coding/bench/contract.pl -- obligations from a controlled-English contract.
%%
%% The `contract' benchmark mode gives the generator the plain requirement
%% AND a checklist derived here. The sentences are `bench_requirement/2'
%% in tasks.pl, in the controlled English library(reasoning/reason) reads;
%% the rules below turn the facts and rule heads it parses into
%% obligations. Nothing in this file writes the checklist by hand for a
%% task: a new task gets the obligations its controlled-English sentences
%% imply, and the same sentence in two tasks produces one line.

:- use_module(library(reasoning/reason)).
:- use_module('coding/bench/tasks.pl').

%% bench_obligations(+Task, -Obligations)
%%
%% The requirement's sentences are one paragraph to reason_text/2. The
%% answer is a list of atoms, most structural first.
bench_obligations(Task, Obligations) :-
    bench_requirement(Task, Sentences),
    atomic_list_concat(Sentences, ' ', Text),
    reason_text(Text, Terms),
    findall(Priority-Text2,
            (   member(Term, Terms),
                bench_obligation(Term, Priority, Text2)
            ),
            Pairs),
    keysort(Pairs, Sorted),
    bench_unique_obligations(Sorted, Obligations).

%% bench_obligation_lines(+Obligations, -Lines)
%%
%% The obligations as `- ...' lines, ready to append to a prompt.
bench_obligation_lines(Obligations, Lines) :-
    findall(Line,
            (   member(Obligation, Obligations),
                format(atom(Line), '- ~s', [Obligation])
            ),
            Lines).

%% A universal sentence parses to (Head :- Body); a fact is its own head.
bench_obligation(Term, Priority, Text) :-
    bench_term_head(Term, Head),
    bench_obligation_head(Head, Priority, Text).

bench_term_head(Term, Head) :-
    (   Term = (H :- _)
    ->  Head = H
    ;   Head = Term
    ).

%% ---- the contract's vocabulary -----------------------------------------

bench_obligation_head(have(_, input), 10,
    'Read from standard input to end of file; an empty input is valid.').
bench_obligation_head(have(_, output), 11,
    'Write exactly the required result, with no prompt or extra text.').

bench_obligation_head(read(_, integers), 20,
    'Integers may be negative or zero; read until end of file.').
bench_obligation_head(read(_, line), 21,
    'Read whole lines, not whitespace-separated words; a line may be empty.').
bench_obligation_head(read(_, words), 22,
    'A word is a maximal run of ASCII letters; punctuation and digits separate words; lowercase each word.').
bench_obligation_head(read(_, commands), 23,
    'Parse each command line; the first word is its verb; state persists across commands.').
bench_obligation_head(read(_, expression), 24,
    'Parse the whole expression with operator precedence and parentheses; division truncates toward zero.').

bench_obligation_head(print(_, sum), 30,
    'Print exactly one integer sum.').
bench_obligation_head(print(_, length), 31,
    'Print exactly one integer length.').
bench_obligation_head(print(_, words), 32,
    'Print each distinct word and its count, one per line.').
bench_obligation_head(sort(_, words), 33,
    'Sort the words in lexicographic order before printing.').

bench_obligation_head(even(_), 40,
    'Only even integers contribute to the sum; if no even integer occurs, print 0.').
bench_obligation_head(have(_, length), 41,
    'A length may be zero, so an empty line is a valid input.').
bench_obligation_head(have(_, bracket), 42,
    'Track bracket kind and nesting order, not only counts.').
bench_obligation_head(have(_, operator), 43,
    'Handle +, -, *, and /.').
bench_obligation_head(have(_, parenthesis), 44,
    'Parentheses group subexpressions.').
bench_obligation_head(have(_, number), 45,
    'Parse a number as an integer, not as a single digit.').
bench_obligation_head(have(_, verb), 46,
    'The first word of a command is its verb.').
bench_obligation_head(have(_, name), 47,
    'A name is one word of letters.').
bench_obligation_head(have(_, count), 48,
    'Count each distinct word.').
bench_obligation_head(have(_, letter), 49,
    'A word contains only ASCII letters; no digits or punctuation.').
bench_obligation_head(subarray(_), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
bench_obligation_head(subsequence(_), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').

%% ---- one line per obligation, its first mention first ------------------

bench_unique_obligations([], []).
bench_unique_obligations([_-Text|Rest], [Text|Texts]) :-
    exclude(bench_same_text(Text), Rest, Rest1),
    bench_unique_obligations(Rest1, Texts).

bench_same_text(Text, _-Other) :-
    Text == Other.
