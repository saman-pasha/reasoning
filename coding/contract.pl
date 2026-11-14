%% coding/contract.pl -- obligations from a controlled-English contract.
%%
%% A contract is sentences in the controlled English
%% library(reasoning/reason) reads. The reader parses them, and the rules
%% below turn the parsed facts and rule heads into the same kind of
%% obligation the keyword reader in `coding/obligations.pl' writes. This
%% is the one contract reader and vocabulary: coding/bench/contract.pl
%% uses it too, so the benchmark's contract mode and the generator cannot
%% drift. A person who writes the contract says what the requirement
%% means, and the reasoner, not a keyword, decides what it implies.
%%
%%     codegen_contract_obligations(+Text, -Obligations)
%%         Text is an atom, a list of atoms (one sentence each), or codes.
%%         Obligations is a list of atoms, most structural first, one of
%%         each. A sentence the reader refuses is dropped; a contract it
%%         reads as nothing gives [].
%%
%%     codegen_contract_terms_obligations(+Terms, -Obligations)
%%         the same mapping for terms `reason_text/2' has already
%%         answered, which is how coding/bench/contract.pl reads the
%%         extractor's reply. The benchmark and the generator share this
%%         vocabulary, so they cannot drift.
%%
%% The shapes the rules know, one obligation each:
%%
%%     Every program has an input.
%%     Every program has an output.
%%     NAME reads the line.        (also integers, words, commands, ...)
%%     NAME prints the sum.        (also length, words, ...)
%%     NAME sorts the words.
%%     Every line has a bracket.   (also length, name, number, score, ...)
%%     Every word has a letter.    (also count)
%%     Every command has a verb.   (also name)
%%     Every expression has an operator. (also number, parenthesis)
%%     Every sum is even.
%%     NAME has a subarray.        (or a subsequence)
%%     Every program has a file.   (also string, decimal, matrix, ...)
%%
%% The last group is the general C checks coding/obligations.pl also
%% reads: file, string/character, float/decimal, precision, matrix/grid/
%% table, allocation/memory, recursion, separator, uppercase.
%%
%% A sentence outside these shapes is read by reason_text/2 but adds no
%% obligation; a sentence reason_text/2 refuses is not part of the
%% contract at all.

:- use_module(library(reasoning/reason)).

codegen_contract_obligations(Text, Obligations) :-
    codegen_contract_text(Text, Atom),
    (   catch(reason_text(Atom, Terms), _, fail)
    ->  codegen_contract_terms_obligations(Terms, Obligations)
    ;   Obligations = []
    ).

codegen_contract_terms_obligations(Terms, Obligations) :-
    findall(Priority-Text,
            (   member(Term, Terms),
                contract_obligation(Term, Priority, Text)
            ),
            Pairs),
    keysort(Pairs, Sorted),
    contract_unique(Sorted, Obligations).

codegen_contract_text(Text, Atom) :-
    (   atom(Text)
    ->  Atom = Text
    ;   is_list(Text),
        Text \== [],
        Text = [First|_],
        atom(First)
    ->  atomic_list_concat(Text, ' ', Atom)
    ;   is_list(Text)
    ->  atom_codes(Atom, Text)
    ;   format(atom(Atom), '~w', [Text])
    ).

%% A universal sentence parses to (Head :- Body); a fact is its own head.
contract_obligation(Term, Priority, Text) :-
    contract_term_head(Term, Head),
    contract_obligation_head(Head, Priority, Text).
contract_obligation(Term, Priority, Text) :-
    Term = (_Head :- Body),
    contract_obligation_body(Body, Priority, Text).

contract_term_head(Term, Head) :-
    (   Term = (H :- _)
    ->  Head = H
    ;   Head = Term
    ).

contract_obligation_body(subarray(_), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
contract_obligation_body(subsequence(_), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').

%% ---- the vocabulary ----------------------------------------------------

contract_obligation_head(have(_, input), 10,
    'Read from standard input to end of file; an empty input is valid.').
contract_obligation_head(read(_, input), 10,
    'Read from standard input to end of file; an empty input is valid.').
contract_obligation_head(have(_, output), 11,
    'Write exactly the required result, with no prompt or extra text.').
contract_obligation_head(print(_, output), 11,
    'Write exactly the required result, with no prompt or extra text.').

contract_obligation_head(read(_, integers), 20,
    'Integers may be negative or zero; read until end of file.').
contract_obligation_head(read(_, line), 21,
    'Read whole lines, not whitespace-separated words; a line may be empty.').
contract_obligation_head(read(_, words), 22,
    'A word is a maximal run of ASCII letters; punctuation and digits separate words; lowercase each word.').
contract_obligation_head(read(_, commands), 23,
    'Parse each command line; the first word is its verb; state persists across commands.').
contract_obligation_head(read(_, expression), 24,
    'Parse the whole expression with operator precedence and parentheses; division truncates toward zero.').

contract_obligation_head(print(_, sum), 30,
    'Print exactly one integer sum.').
contract_obligation_head(print(_, length), 31,
    'Print exactly one integer length.').
contract_obligation_head(print(_, words), 32,
    'Print each distinct word and its count, one per line.').
contract_obligation_head(sort(_, words), 33,
    'Sort the words in lexicographic order before printing.').

contract_obligation_head(even(_), 40,
    'Only even integers contribute to the sum; if no even integer occurs, print 0.').
contract_obligation_head(have(_, length), 41,
    'A length may be zero, so an empty line is a valid input.').
contract_obligation_head(have(_, bracket), 42,
    'Track bracket kind and nesting order, not only counts.').
contract_obligation_head(have(_, operator), 43,
    'Handle +, -, *, and /.').
contract_obligation_head(have(_, parenthesis), 44,
    'Parentheses group subexpressions.').
contract_obligation_head(have(_, number), 45,
    'Parse a number as an integer, not as a single digit.').
contract_obligation_head(have(_, verb), 46,
    'The first word of a command is its verb.').
contract_obligation_head(have(_, name), 47,
    'A name is one word of letters.').
contract_obligation_head(have(_, count), 48,
    'Count each distinct word.').
contract_obligation_head(have(_, letter), 49,
    'A word contains only ASCII letters; no digits or punctuation.').
contract_obligation_head(subarray(_), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
contract_obligation_head(have(_, subarray), 50,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.').
contract_obligation_head(subsequence(_), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').
contract_obligation_head(have(_, subsequence), 51,
    'A subsequence keeps character order but not adjacency; it is not a substring.').
contract_obligation_head(have(_, score), 59,
    'Sort the records by score, highest first.').
contract_obligation_head(have(_, order), 60,
    'Records with equal scores keep their original input order; the sort is stable.').
contract_obligation_head(have(_, tree), 35,
    'A B-tree of minimum degree 2 is a 2-3-4 tree; keep the keys in each node sorted and split a full node before descending into it.').
contract_obligation_head(have(_, version), 36,
    'A version is the result of one commit; a reader sees the newest version of a key at or before its snapshot.').
contract_obligation_head(have(_, snapshot), 37,
    'A snapshot is the current commit id when a reader begins; commits after it are invisible to that reader.').
contract_obligation_head(have(_, commit), 38,
    'A commit applies its staged operations atomically as one new version; staged writes are invisible before it.').
contract_obligation_head(have(_, transaction), 39,
    'There is one writer; its staged operations are invisible until commit, and readers never block it or each other.').

%% The general C checks, the same lines coding/obligations.pl writes.
contract_obligation_head(have(_, file), 13,
    'Check every fopen; close every file; do not assume the file exists.').
contract_obligation_head(read(_, file), 13,
    'Check every fopen; close every file; do not assume the file exists.').
contract_obligation_head(have(_, string), 27,
    'C strings are NUL-terminated; reserve one byte for the terminator and bound every copy.').
contract_obligation_head(read(_, string), 27,
    'C strings are NUL-terminated; reserve one byte for the terminator and bound every copy.').
contract_obligation_head(have(_, character), 27,
    'C strings are NUL-terminated; reserve one byte for the terminator and bound every copy.').
contract_obligation_head(have(_, float), 28,
    'Use double for floating point; do not compare two floating values for equality.').
contract_obligation_head(have(_, decimal), 28,
    'Use double for floating point; do not compare two floating values for equality.').
contract_obligation_head(have(_, precision), 29,
    'Print exactly the number of decimal places the requirement names.').
contract_obligation_head(have(_, matrix), 33,
    'Check every row and column index against its bound.').
contract_obligation_head(have(_, grid), 33,
    'Check every row and column index against its bound.').
contract_obligation_head(have(_, table), 33,
    'Check every row and column index against its bound.').
contract_obligation_head(have(_, allocation), 34,
    'Check every allocation for NULL, and free every allocation.').
contract_obligation_head(have(_, memory), 34,
    'Check every allocation for NULL, and free every allocation.').
contract_obligation_head(have(_, recursion), 35,
    'Bound the recursion depth, or keep the input small enough that it stays bounded.').
contract_obligation_head(have(_, separator), 43,
    'Separate the values exactly as the requirement says; print no trailing separator.').
contract_obligation_head(have(_, uppercase), 44,
    'Convert the text to uppercase before comparing or printing it.').

%% ---- one line per obligation, its first mention first ------------------

contract_unique([], []).
contract_unique([_-Text|Rest], [Text|Texts]) :-
    exclude(contract_same_text(Text), Rest, Rest1),
    contract_unique(Rest1, Texts).

contract_same_text(Text, _-Other) :-
    Text == Other.
