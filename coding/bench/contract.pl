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

%% bench_extract_prompt(+Task, +Spec, -Prompt)
%%
%% The prompt that asks a model for the controlled-English sentences.
%% Both the nouns and the shapes are closed on purpose: a sentence outside
%% them is dropped by bench_reply_obligations/3. The read and print lines
%% are required and named, so the extractor cannot spend its lines on
%% noise and leave out what the program reads or prints.
bench_extract_prompt(Task, Spec, Prompt) :-
    bench_program_name(Task, Name),
    bench_extract_nouns(Task, ReadNoun, PrintNoun, Nouns0),
    atomic_list_concat(['input', output|Nouns0], ', ', Nouns),
    bench_extract_shape_lines(Task, ShapeLines),
    atomic_list_concat(ShapeLines, '\n', Shapes),
    bench_extract_extra_lines(Task, ExtraLines),
    atomic_list_concat(ExtraLines, '\n', Extras),
    format(atom(Prompt),
'Rewrite this programming requirement as controlled-English sentences.
Use ONLY these nouns: ~s.
Use ONLY these sentence shapes:
~s
Required lines, exactly as written:
Every program has an input.
Every program has an output.
~w reads the ~w.
~w prints the ~w.
~s
Add optional lines only from the remaining shapes and the allowed nouns.
Use lowercase nouns exactly as listed. Do not use any other noun. Do not
output bullets, numbering, explanations, or any other line. Do not copy a
line containing <NAME> or <noun>.
The program name is ~w.

Requirement:
~s',
           [Nouns, Shapes, Name, ReadNoun, Name, PrintNoun, Extras, Name, Spec]).

%% The shape list is task-specific: only word_count gets `sorts', only
%% sum_even gets a property line. A shape a task cannot use is a line the
%% model will invent a use for.
bench_extract_shape_lines(Task, Lines) :-
    Lines0 = ['Every program has an input.',
              'Every program has an output.',
              '<NAME> reads the <noun>.',
              '<NAME> prints the <noun>.',
              'Every <noun> has a <noun>.',
              '<NAME> has a <noun>.'],
    (   Task == word_count
    ->  append(Lines0, ['<NAME> sorts the <noun>.'], Lines1)
    ;   Lines1 = Lines0
    ),
    (   Task == sum_even
    ->  append(Lines1, ['Every <noun> is even.'], Lines)
    ;   Lines = Lines1
    ).

%% bench_derive_sentences(+Task, +Spec, -Sentences)
%%
%% The deterministic alternative to the extractor: the task's known read
%% and print nouns make the required lines, and a keyword in the plain
%% requirement adds the optional line it implies. No model call.
bench_derive_sentences(Task, Spec, Sentences) :-
    bench_program_name(Task, Name),
    bench_extract_nouns(Task, ReadNoun, PrintNoun, _),
    format(atom(ReadLine), '~w reads the ~w.', [Name, ReadNoun]),
    format(atom(PrintLine), '~w prints the ~w.', [Name, PrintNoun]),
    findall(Optional, bench_derive_optional(Task, Spec, Name, Optional), Optionals0),
    sort(Optionals0, Optionals),
    Sentences = ['Every program has an input.',
                 'Every program has an output.',
                 ReadLine,
                 PrintLine|Optionals].

%% A keyword the task's own noun list does not allow is not a keyword for
%% this task: phonebook's `one word of letters' must not add a word-count
%% obligation.
bench_task_has_noun(Task, Noun) :-
    bench_extract_nouns(Task, _, _, Nouns),
    member(Noun, Nouns).

bench_derive_optional(Task, Spec, _, 'Every sum is even.') :-
    bench_task_has_noun(Task, sum),
    sub_atom(Spec, _, _, _, 'even'),
    sub_atom(Spec, _, _, _, 'sum').
bench_derive_optional(Task, Spec, _, 'Every subarray has a sum.') :-
    bench_task_has_noun(Task, subarray),
    sub_atom(Spec, _, _, _, 'subarray').
bench_derive_optional(Task, Spec, _, 'Every subsequence has a length.') :-
    bench_task_has_noun(Task, subsequence),
    sub_atom(Spec, _, _, _, 'subsequence').
bench_derive_optional(Task, Spec, _, 'Every line has a bracket.') :-
    bench_task_has_noun(Task, bracket),
    sub_atom(Spec, _, _, _, 'bracket').
bench_derive_optional(Task, Spec, _, 'Every line has a length.') :-
    bench_task_has_noun(Task, line),
    sub_atom(Spec, _, _, _, 'line').
bench_derive_optional(Task, Spec, _, 'Every line has a score.') :-
    bench_task_has_noun(Task, score),
    sub_atom(Spec, _, _, _, 'score').
bench_derive_optional(Task, Spec, _, 'Every line has an order.') :-
    bench_task_has_noun(Task, order),
    sub_atom(Spec, _, _, _, 'order').
bench_derive_optional(Task, Spec, _, 'Every line has a name.') :-
    bench_task_has_noun(Task, name),
    sub_atom(Spec, _, _, _, 'name').
bench_derive_optional(Task, Spec, _, 'Every line has a number.') :-
    bench_task_has_noun(Task, number),
    sub_atom(Spec, _, _, _, 'integer').
bench_derive_optional(Task, Spec, _, 'Every word has a letter.') :-
    bench_task_has_noun(Task, word),
    sub_atom(Spec, _, _, _, 'word').
bench_derive_optional(Task, Spec, _, 'Every word has a count.') :-
    bench_task_has_noun(Task, word),
    sub_atom(Spec, _, _, _, 'word').
bench_derive_optional(Task, Spec, Name, Sentence) :-
    bench_task_has_noun(Task, words),
    sub_atom(Spec, _, _, _, 'word'),
    (   sub_atom(Spec, _, _, _, 'sort')
    ;   sub_atom(Spec, _, _, _, 'lexicographic')
    ),
    format(atom(Sentence), '~w sorts the words.', [Name]).
bench_derive_optional(Task, Spec, _, 'Every command has a verb.') :-
    bench_task_has_noun(Task, command),
    sub_atom(Spec, _, _, _, 'command').
bench_derive_optional(Task, Spec, _, 'Every command has a name.') :-
    bench_task_has_noun(Task, command),
    sub_atom(Spec, _, _, _, 'command').
bench_derive_optional(Task, Spec, _, 'Every name has a number.') :-
    bench_task_has_noun(Task, name),
    sub_atom(Spec, _, _, _, 'command').
bench_derive_optional(Task, Spec, _, 'Every expression has a number.') :-
    bench_task_has_noun(Task, expression),
    sub_atom(Spec, _, _, _, 'expression').
bench_derive_optional(Task, Spec, _, 'Every expression has an operator.') :-
    bench_task_has_noun(Task, expression),
    sub_atom(Spec, _, _, _, 'expression').
bench_derive_optional(Task, Spec, _, 'Every expression has a parenthesis.') :-
    bench_task_has_noun(Task, expression),
    sub_atom(Spec, _, _, _, 'expression').

%% bench_derive_obligations(+Task, +Spec, -Obligations)
%%
%% The sentences go through the same controlled-English reader and
%% obligation rules as the extractor's reply.
bench_derive_obligations(Task, Spec, Obligations) :-
    bench_derive_sentences(Task, Spec, Sentences),
    atomic_list_concat(Sentences, '\n', Text),
    bench_reply_obligations(Text, _Parsed, Obligations).

%% bench_reply_obligations(+Reply, -Parsed, -Obligations)
%%
%% Parse each line the extractor wrote. A line the controlled-English
%% reader refuses is dropped, not fatal: the extractor is a model, and the
%% reader is the judge. Parsed is the accepted Line-Terms pairs, for a
%% caller that wants to show what survived.
bench_reply_obligations(Reply, Parsed, Obligations) :-
    split_string(Reply, "\n", " \t\r", Lines0),
    exclude(contract_empty_string, Lines0, Lines1),
    findall(LineAtom-Terms,
            (   member(Line, Lines1),
                atom_string(Line0, Line),
                bench_clean_line(Line0, LineAtom),
                LineAtom \== '',
                catch(reason_text(LineAtom, Terms), _, fail)
            ),
            Parsed),
    findall(Priority-Text,
            (   member(_-Terms, Parsed),
                member(Term, Terms),
                bench_obligation(Term, Priority, Text)
            ),
            Pairs),
    keysort(Pairs, Sorted),
    bench_unique_obligations(Sorted, Obligations).

%% The model sometimes writes a bullet even when asked for sentences.
bench_clean_line(Line, Clean) :-
    (   sub_atom(Line, 0, 2, _, '- ')
    ->  sub_atom(Line, 2, _, 0, Clean)
    ;   Clean = Line
    ).

contract_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

%% A universal sentence parses to (Head :- Body); a fact is its own head.
bench_obligation(Term, Priority, Text) :-
    bench_term_head(Term, Head),
    bench_obligation_head(Head, Priority, Text).

%% A class in the body of a universal sentence names the thing the
%% obligation is about, even when the head only says `has': `Every
%% subarray has a sum' is still about the subarray.
bench_obligation(Term, Priority, Text) :-
    Term = (_Head :- Body),
    bench_obligation_body(Body, Priority, Text).

bench_obligation_body(subarray(_), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
bench_obligation_body(subsequence(_), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').

bench_term_head(Term, Head) :-
    (   Term = (H :- _)
    ->  Head = H
    ;   Head = Term
    ).

%% ---- the contract's vocabulary -----------------------------------------

bench_obligation_head(have(_, input), 10,
    'Read from standard input to end of file; an empty input is valid.').
bench_obligation_head(read(_, input), 10,
    'Read from standard input to end of file; an empty input is valid.').
bench_obligation_head(have(_, output), 11,
    'Write exactly the required result, with no prompt or extra text.').
bench_obligation_head(print(_, output), 11,
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
bench_obligation_head(have(_, subarray), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
bench_obligation_head(subsequence(_), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').
bench_obligation_head(have(_, subsequence), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').
bench_obligation_head(have(_, score), 59,
    'Sort the records by score, highest first.').
bench_obligation_head(have(_, order), 60,
    'Records with equal scores keep their original input order; the sort is stable.').

%% ---- one line per obligation, its first mention first ------------------

bench_unique_obligations([], []).
bench_unique_obligations([_-Text|Rest], [Text|Texts]) :-
    exclude(bench_same_text(Text), Rest, Rest1),
    bench_unique_obligations(Rest1, Texts).

bench_same_text(Text, _-Other) :-
    Text == Other.
