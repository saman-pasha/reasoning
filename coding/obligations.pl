%% coding/obligations.pl -- the checks a C requirement's words imply.
%%
%% A deterministic reading of the requirement's own vocabulary: no model
%% call, no controlled-English file. A rule fires on a whole word or a
%% phrase, so `assortment' is not `sort' and `deadline' is not `line'.
%% The lines are correctness reminders the model would otherwise have to
%% infer from the prose -- the kind coding/bench's `derive' mode measured.
%%
%%     codegen_obligations(+Spec, -Obligations)
%%         Obligations is a list of atoms, most structural first, one of
%%         each. Spec is an atom or a string.
%%
%%     codegen_obligation_lines(+Obligations, -Lines)
%%         The same, each as a `- ...' atom, ready for a prompt.

%% ---- the reader --------------------------------------------------------

codegen_obligations(Spec, Obligations) :-
    codegen_spec_atom(Spec, Atom),
    codegen_tokens(Atom, Tokens),
    findall(Priority-Text,
            codegen_obligation(Tokens, Priority, Text),
            Pairs),
    keysort(Pairs, Sorted),
    codegen_unique_obligations(Sorted, Obligations).

codegen_obligation_lines(Obligations, Lines) :-
    findall(Line,
            (   member(Text, Obligations),
                format(atom(Line), '- ~s', [Text])
            ),
            Lines).

codegen_spec_atom(Spec, Atom) :-
    (   atom(Spec)
    ->  Atom = Spec
    ;   is_list(Spec)
    ->  atom_codes(Atom, Spec)
    ;   format(atom(Atom), '~w', [Spec])
    ).

%% Lowercase words, with punctuation a separator but a hyphen kept: a
%% phrase written `end-of-file' is one token, and `end of file' is three.
codegen_tokens(Atom, Tokens) :-
    downcase_atom(Atom, Low),
    atom_string(Low, String),
    split_string(String, " \t\n\r.,;:!?()[]{}\"'", "", Parts0),
    exclude(codegen_empty_string, Parts0, Parts),
    findall(Token, (member(Part, Parts), atom_string(Token, Part)), Tokens).

codegen_empty_string(S) :-
    string_length(S, 0).

codegen_token(Tokens, Word) :-
    memberchk(Word, Tokens).

codegen_phrase(Tokens, Phrase) :-
    append(_, Tail, Tokens),
    append(Phrase, _, Tail).

codegen_input_words([read, reads, input, inputs, stdin, eof]).
codegen_output_words([print, prints, output, outputs, stdout, write, writes]).

codegen_any_token(Tokens, Words) :-
    member(Word, Words),
    memberchk(Word, Tokens).

codegen_input_cue(Tokens) :-
    (   codegen_input_words(Words),
        codegen_any_token(Tokens, Words)
    ;   codegen_phrase(Tokens, [standard, input])
    ).

codegen_output_cue(Tokens) :-
    codegen_output_words(Words),
    codegen_any_token(Tokens, Words).

codegen_sort_cue(Tokens) :-
    (   codegen_token(Tokens, sort)
    ;   codegen_token(Tokens, sorts)
    ;   codegen_token(Tokens, sorted)
    ).

%% The first position of any of Words, 0-based. Used to tell a line the
%% program READS from a line it prints: `prints on one line' comes after
%% the output verb, `reads one line' before it.
codegen_first_pos(Tokens, Words, Pos) :-
    codegen_first_pos(Tokens, Words, 0, Pos).

codegen_first_pos([Token|Tokens], Words, N, Pos) :-
    (   memberchk(Token, Words)
    ->  Pos = N
    ;   N1 is N + 1,
        codegen_first_pos(Tokens, Words, N1, Pos)
    ).

%% The first position at or after From. The leading `Write a complete C17
%% program' is an instruction, not an output: an output verb before the
%% input cue does not make a later `line' an output line.
codegen_after([Token|Tokens], Words, N, From, Pos) :-
    (   N >= From,
        memberchk(Token, Words)
    ->  Pos = N
    ;   N1 is N + 1,
        codegen_after(Tokens, Words, N1, From, Pos)
    ).

%% ---- the rules ---------------------------------------------------------

codegen_obligation(Tokens, 10,
    'Read from standard input exactly as the requirement describes; do not assume more input than it gives.') :-
    codegen_input_cue(Tokens).

codegen_obligation(Tokens, 12,
    'Read to end of file; an empty input is valid.') :-
    (   codegen_token(Tokens, eof)
    ;   codegen_token(Tokens, empty)
    ;   codegen_phrase(Tokens, [end, of, file])
    ;   codegen_token(Tokens, 'end-of-file')
    ).

codegen_obligation(Tokens, 13,
    'Check every fopen; close every file; do not assume the file exists.') :-
    (   codegen_token(Tokens, file)
    ;   codegen_token(Tokens, files)
    ;   codegen_token(Tokens, fopen)
    ;   codegen_token(Tokens, fread)
    ;   codegen_token(Tokens, fwrite)
    ;   codegen_token(Tokens, fprintf)
    ).

codegen_obligation(Tokens, 11,
    'Write exactly the required result; do not print a prompt or extra text.') :-
    codegen_output_cue(Tokens).

codegen_obligation(Tokens, 20,
    'Read a number as a whole integer, not digit by digit; values may be negative or zero.') :-
    (   codegen_token(Tokens, integer)
    ;   codegen_token(Tokens, integers)
    ;   codegen_token(Tokens, number)
    ;   codegen_token(Tokens, numbers)
    ;   codegen_token(Tokens, int)
    ;   codegen_token(Tokens, ints)
    ).

codegen_obligation(Tokens, 21,
    'Read whole lines, not whitespace-separated words; a line may be empty.') :-
    codegen_input_words(InWords),
    codegen_first_pos(Tokens, InWords, InPos),
    codegen_first_pos(Tokens, [line, lines], LinePos),
    (   codegen_output_words(OutWords),
        codegen_after(Tokens, OutWords, 0, InPos, OutPos)
    ->  LinePos < OutPos
    ;   true
    ).

codegen_obligation(Tokens, 22,
    'A word is a maximal run of ASCII letters; punctuation and digits separate words.') :-
    (   codegen_token(Tokens, word)
    ;   codegen_token(Tokens, words)
    ).

codegen_obligation(Tokens, 23,
    'Convert every word to lowercase before comparing or printing it.') :-
    codegen_token(Tokens, lowercase),
    (   codegen_token(Tokens, convert)
    ;   codegen_token(Tokens, converts)
    ;   codegen_token(Tokens, 'case-insensitive')
    ).

codegen_obligation(Tokens, 24,
    'The first word of a command line is its verb; state persists across commands.') :-
    (   codegen_token(Tokens, command)
    ;   codegen_token(Tokens, commands)
    ).

codegen_obligation(Tokens, 35,
    'A B-tree of minimum degree 2 is a 2-3-4 tree; keep the keys in each node sorted and split a full node before descending into it.') :-
    (   codegen_token(Tokens, 'b-tree')
    ;   codegen_token(Tokens, btree)
    ;   codegen_token(Tokens, tree)
    ).

codegen_obligation(Tokens, 36,
    'A version is the result of one commit; a reader sees the newest version of a key at or before its snapshot.') :-
    (   codegen_token(Tokens, version)
    ;   codegen_token(Tokens, versions)
    ;   codegen_token(Tokens, 'multi-version')
    ).

codegen_obligation(Tokens, 37,
    'A snapshot is the current commit id when a reader begins; commits after it are invisible to that reader.') :-
    (   codegen_token(Tokens, snapshot)
    ;   codegen_token(Tokens, snapshots)
    ).

codegen_obligation(Tokens, 38,
    'A commit applies its staged operations atomically as one new version; staged writes are invisible before it.') :-
    (   codegen_token(Tokens, commit)
    ;   codegen_token(Tokens, commits)
    ;   codegen_token(Tokens, committed)
    ).

codegen_obligation(Tokens, 39,
    'There is one writer; its staged operations are invisible until commit, and readers never block it or each other.') :-
    (   codegen_token(Tokens, writer)
    ;   codegen_token(Tokens, writers)
    ;   codegen_token(Tokens, reader)
    ;   codegen_token(Tokens, readers)
    ).

codegen_obligation(Tokens, 25,
    'Parse the whole expression with operator precedence and parentheses; do not evaluate left to right.') :-
    (   codegen_token(Tokens, expression)
    ;   codegen_token(Tokens, expressions)
    ;   codegen_token(Tokens, operator)
    ;   codegen_token(Tokens, operators)
    ;   codegen_token(Tokens, precedence)
    ;   codegen_token(Tokens, parentheses)
    ).

codegen_obligation(Tokens, 26,
    'Use integer division and truncate toward zero; do not use floating point.') :-
    (   codegen_token(Tokens, division)
    ;   codegen_token(Tokens, divide)
    ;   codegen_token(Tokens, divides)
    ;   codegen_token(Tokens, quotient)
    ;   codegen_phrase(Tokens, [truncates, toward, zero])
    ;   codegen_phrase(Tokens, [truncate, toward, zero])
    ).

codegen_obligation(Tokens, 27,
    'C strings are NUL-terminated; reserve one byte for the terminator and bound every copy.') :-
    (   codegen_token(Tokens, string)
    ;   codegen_token(Tokens, strings)
    ;   codegen_token(Tokens, character)
    ;   codegen_token(Tokens, characters)
    ;   codegen_token(Tokens, char)
    ;   codegen_token(Tokens, chars)
    ;   codegen_token(Tokens, text)
    ).

codegen_obligation(Tokens, 28,
    'Use double for floating point; do not compare two floating values for equality.') :-
    (   codegen_token(Tokens, float)
    ;   codegen_token(Tokens, floats)
    ;   codegen_token(Tokens, floating)
    ;   codegen_token(Tokens, double)
    ;   codegen_token(Tokens, doubles)
    ;   codegen_token(Tokens, decimal)
    ;   codegen_token(Tokens, decimals)
    ).

codegen_obligation(Tokens, 29,
    'Print exactly the number of decimal places the requirement names.') :-
    (   codegen_token(Tokens, precision)
    ;   codegen_token(Tokens, decimal),
        (   codegen_token(Tokens, places)
        ;   codegen_token(Tokens, digits)
        )
    ).

codegen_obligation(Tokens, 30,
    'Use a type wide enough for the sum; print exactly one integer sum.') :-
    codegen_token(Tokens, sum),
    (   codegen_token(Tokens, integer)
    ;   codegen_token(Tokens, integers)
    ).

codegen_obligation(Tokens, 31,
    'If you track a maximum or minimum, initialize it from the first value, not from zero, so an all-negative input works.') :-
    (   codegen_token(Tokens, maximum)
    ;   codegen_token(Tokens, max)
    ).

codegen_obligation(Tokens, 32,
    'Only even integers contribute to the sum; if none occurs, print 0.') :-
    codegen_token(Tokens, even),
    (   codegen_token(Tokens, sum)
    ;   codegen_token(Tokens, sums)
    ).

codegen_obligation(Tokens, 33,
    'Check every row and column index against its bound.') :-
    (   codegen_token(Tokens, matrix)
    ;   codegen_token(Tokens, matrices)
    ;   codegen_token(Tokens, grid)
    ;   codegen_token(Tokens, grids)
    ;   codegen_token(Tokens, table)
    ;   codegen_token(Tokens, tables)
    ).

codegen_obligation(Tokens, 34,
    'Check every allocation for NULL, and free every allocation.') :-
    (   codegen_token(Tokens, malloc)
    ;   codegen_token(Tokens, calloc)
    ;   codegen_token(Tokens, realloc)
    ;   codegen_token(Tokens, allocate)
    ;   codegen_token(Tokens, allocates)
    ;   codegen_token(Tokens, allocation)
    ;   codegen_token(Tokens, allocations)
    ).

codegen_obligation(Tokens, 35,
    'Bound the recursion depth, or keep the input small enough that it stays bounded.') :-
    (   codegen_token(Tokens, recursive)
    ;   codegen_token(Tokens, recursively)
    ;   codegen_token(Tokens, recursion)
    ).

codegen_obligation(Tokens, 40,
    'The subarray is contiguous and non-empty; with all-negative values choose one element.') :-
    (   codegen_token(Tokens, subarray)
    ;   codegen_token(Tokens, subarrays)
    ;   codegen_token(Tokens, contiguous)
    ).

codegen_obligation(Tokens, 41,
    'A subsequence keeps character order but not adjacency; it is not a substring.') :-
    (   codegen_token(Tokens, subsequence)
    ;   codegen_token(Tokens, subsequences)
    ).

codegen_obligation(Tokens, 42,
    'Track bracket kind and nesting order, not only counts.') :-
    (   codegen_token(Tokens, bracket)
    ;   codegen_token(Tokens, brackets)
    ).

codegen_obligation(Tokens, 43,
    'Separate the values exactly as the requirement says; print no trailing separator.') :-
    (   codegen_token(Tokens, comma)
    ;   codegen_token(Tokens, commas)
    ;   codegen_token(Tokens, tab)
    ;   codegen_token(Tokens, tabs)
    ;   codegen_token(Tokens, 'comma-separated')
    ;   codegen_phrase(Tokens, [comma, separated])
    ;   codegen_phrase(Tokens, [space, separated])
    ).

codegen_obligation(Tokens, 44,
    'Convert the text to uppercase before comparing or printing it.') :-
    codegen_token(Tokens, uppercase),
    (   codegen_token(Tokens, convert)
    ;   codegen_token(Tokens, converts)
    ).

codegen_obligation(Tokens, 50,
    'Sort in descending order.') :-
    codegen_sort_cue(Tokens),
    (   codegen_token(Tokens, descending)
    ;   codegen_token(Tokens, decreasing)
    ;   codegen_phrase(Tokens, [highest, first])
    ;   codegen_phrase(Tokens, [largest, first])
    ).

codegen_obligation(Tokens, 51,
    'Sort in ascending order.') :-
    codegen_sort_cue(Tokens),
    (   codegen_token(Tokens, ascending)
    ;   codegen_token(Tokens, increasing)
    ;   codegen_phrase(Tokens, [lowest, first])
    ;   codegen_phrase(Tokens, [smallest, first])
    ).

codegen_obligation(Tokens, 52,
    'Sort in lexicographic order (byte order for ASCII).') :-
    (   codegen_token(Tokens, lexicographic)
    ;   codegen_token(Tokens, lexicographical)
    ).

codegen_obligation(Tokens, 53,
    'Values with equal keys keep their original input order; the sort must be stable.') :-
    codegen_sort_cue(Tokens),
    (   codegen_token(Tokens, stable)
    ;   codegen_phrase(Tokens, [original, input, order])
    ;   codegen_phrase(Tokens, [original, order])
    ;   codegen_phrase(Tokens, [input, order])
    ;   codegen_phrase(Tokens, [same, score])
    ;   codegen_phrase(Tokens, [same, key])
    ).

codegen_obligation(Tokens, 54,
    'Print each distinct value once.') :-
    (   codegen_token(Tokens, distinct)
    ;   codegen_token(Tokens, unique)
    ).

codegen_obligation(Tokens, 55,
    'Count every occurrence of the value, not only whether it appears.') :-
    (   codegen_token(Tokens, count)
    ;   codegen_token(Tokens, counts)
    ).

%% ---- one line per obligation, its first mention first ------------------

codegen_unique_obligations([], []).
codegen_unique_obligations([_-Text|Rest], [Text|Texts]) :-
    exclude(codegen_same_text(Text), Rest, Rest1),
    codegen_unique_obligations(Rest1, Texts).

codegen_same_text(Text, _-Other) :-
    Text == Other.
