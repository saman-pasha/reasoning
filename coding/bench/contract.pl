%% coding/bench/contract.pl -- obligations from a controlled-English contract.
%%
%% The `contract' benchmark mode gives the generator the plain requirement
%% AND a checklist derived here. The sentences are `bench_requirement/2'
%% in tasks.pl, in the controlled English library(reasoning/reason) reads.
%% The reader AND the vocabulary are `coding/contract.pl''s, which the C
%% generator uses too, so the benchmark's contract mode and the tool
%% cannot drift. Nothing in this file writes the checklist by hand for a
%% task: a new task gets the obligations its controlled-English sentences
%% imply.

:- use_module(library(reasoning/reason)).
:- use_module('coding/bench/tasks.pl').
:- use_module('coding/contract.pl').

%% bench_obligations(+Task, -Obligations)
%%
%% The requirement's sentences are one contract to the shared reader. The
%% answer is a list of atoms, most structural first.
bench_obligations(Task, Obligations) :-
    bench_requirement(Task, Sentences),
    codegen_contract_obligations(Sentences, Obligations).

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
    bench_task_has_noun(Task, name),
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
bench_derive_optional(Task, Spec, _, 'Every commit has a version.') :-
    bench_task_has_noun(Task, commit),
    sub_atom(Spec, _, _, _, 'commit').
bench_derive_optional(Task, Spec, _, 'Every reader has a snapshot.') :-
    bench_task_has_noun(Task, reader),
    sub_atom(Spec, _, _, _, 'reader').
bench_derive_optional(Task, Spec, _, 'Every writer has a transaction.') :-
    bench_task_has_noun(Task, writer),
    sub_atom(Spec, _, _, _, 'writer').
bench_derive_optional(Task, Spec, _, 'Every program has an allocation.') :-
    bench_task_has_noun(Task, allocation),
    sub_atom(Spec, _, _, _, 'allocation').
bench_derive_optional(Task, Spec, _, 'Every program has a recursion.') :-
    bench_task_has_noun(Task, recursion),
    sub_atom(Spec, _, _, _, 'recursion').
bench_derive_optional(Task, Spec, _, 'Every program has a tree.') :-
    bench_task_has_noun(Task, tree),
    bench_task_has_noun(Task, version),
    sub_atom(Spec, _, _, _, 'B-tree').

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
    findall(Term,
            (   member(_-Terms, Parsed),
                member(Term, Terms)
            ),
            AllTerms),
    codegen_contract_terms_obligations(AllTerms, Obligations).

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

%% The vocabularies are `coding/contract.pl''s: contract_obligation/3 and
%% contract_obligation_head/3. A benchmark task's sentences reach them
%% through codegen_contract_obligations/2, the extractor's reply through
%% codegen_contract_terms_obligations/2.
