%% coding/python/obligations.pl -- the checks a Python requirement's words imply.
%%
%%     codegen_python_obligations(+Spec, -Obligations)
%%         Obligations is a list of atoms, most structural first, one of
%%         each. Spec is an atom or codes. Python's words, read
%%         deterministically: no model call.
%%
%%     codegen_python_sanity_checks(-Checks)
%%         the checks the tool adds whatever the requirement says: the
%%         ones a Python reply is refused for.
%%
%% THE C READING IS `coding/obligations.pl', AND IT IS NOT THIS ONE. Its
%% words are C's -- a NUL terminator, `double', `fopen', `malloc' -- and a
%% request for Python that says `file' or `floating point' was answered
%% with them. This file reads the same SHAPES (input, output, lines, a
%% number, a word, a sort, a matrix, recursion, distinct values, a count,
%% brackets, a separator, upper and lower case) and adds what only Python
%% has: a test, a module, unicode, an exception, a generator.
%%
%% The reading is whole-word, as the C reading is: `assortment' is not
%% `sort', `deadline' is not `line', and `list' is a container rather than
%% a line.

:- use_module('coding/obligations.pl').

%% ---- the reader --------------------------------------------------------

codegen_python_obligations(Spec, Obligations) :-
    codegen_spec_atom(Spec, Atom),
    codegen_tokens(Atom, Tokens),
    findall(Priority-Text,
            codegen_python_obligation(Tokens, Priority, Text),
            Pairs),
    keysort(Pairs, Sorted),
    codegen_unique_obligations(Sorted, Obligations).

codegen_python_token(Tokens, Word) :-
    memberchk(Word, Tokens).

codegen_python_any(Tokens, Words) :-
    member(Word, Words),
    memberchk(Word, Tokens).

codegen_python_phrase(Tokens, Phrase) :-
    append(_, Tail, Tokens),
    append(Phrase, _, Tail).

%% The first position of a word of Words, counting a hyphen as part of a
%% word: `end-of-file' is one token and `end of file' is three, so both
%% spellings are a phrase the rules below look for.
codegen_python_first(Tokens, Words, Pos) :-
    codegen_python_first(Tokens, Words, 0, Pos).

codegen_python_first([Token|Tokens], Words, N, Pos) :-
    (   memberchk(Token, Words)
    ->  Pos = N
    ;   N1 is N + 1,
        codegen_python_first(Tokens, Words, N1, Pos)
    ).

codegen_python_input_cue(Tokens) :-
    codegen_python_any(Tokens,
                       [read, reads, input, inputs, stdin,
                        'standard-input']).

codegen_python_output_cue(Tokens) :-
    codegen_python_any(Tokens, [print, prints, output, outputs, stdout]).

%% ---- the rules ---------------------------------------------------------

codegen_python_obligation(Tokens, 10,
    'Read from standard input, `sys.stdin` or the `input()` builtin, exactly as the task describes; do not assume more input than it gives.') :-
    codegen_python_input_cue(Tokens).

codegen_python_obligation(Tokens, 11,
    'Write exactly the required result with `print`, one line per answer; no prompt, label or debug output.') :-
    codegen_python_output_cue(Tokens).

codegen_python_obligation(Tokens, 12,
    'A name the program uses is bound on every path before it is read, and the definition that must run before use is above the use.') :-
    (   codegen_python_token(Tokens, name)
    ;   codegen_python_token(Tokens, names)
    ;   codegen_python_token(Tokens, variable)
    ;   codegen_python_token(Tokens, variables)
    ;   codegen_python_token(Tokens, function)
    ;   codegen_python_token(Tokens, functions)
    ;   codegen_python_token(Tokens, module)
    ;   codegen_python_token(Tokens, modules)
    ).

codegen_python_obligation(Tokens, 13,
    'Open a file in a `with` block, close it, and let a missing file raise the error the task names rather than printing a traceback.') :-
    (   codegen_python_token(Tokens, file)
    ;   codegen_python_token(Tokens, files)
    ;   codegen_python_token(Tokens, open)
    ;   codegen_python_token(Tokens, opens)
    ;   codegen_python_token(Tokens, filename)
    ).

codegen_python_obligation(Tokens, 14,
    'Read to end of file: iterate over the remaining lines, and read an empty input as no value, not as a crash.') :-
    (   codegen_python_token(Tokens, eof)
    ;   codegen_python_token(Tokens, empty)
    ;   codegen_python_phrase(Tokens, [end, of, file])
    ;   codegen_python_token(Tokens, 'end-of-file')
    ).

codegen_python_obligation(Tokens, 20,
    'Use `int(token)`, not character arithmetic; a value may be negative, and Python integers do not overflow.') :-
    (   codegen_python_token(Tokens, integer)
    ;   codegen_python_token(Tokens, integers)
    ;   codegen_python_token(Tokens, number)
    ;   codegen_python_token(Tokens, numbers)
    ;   codegen_python_token(Tokens, int)
    ;   codegen_python_token(Tokens, ints)
    ).

codegen_python_obligation(Tokens, 21,
    'Read whole lines with `sys.stdin` or `readline()`, not `input().split()`; a line may be empty, and only its final newline goes.') :-
    codegen_python_input_cue(Tokens),
    codegen_python_first(Tokens, [read, reads, input, inputs, stdin], InPos),
    codegen_python_first(Tokens, [line, lines], LinePos),
    LinePos > InPos,
    (   codegen_python_first(Tokens, [output, outputs, stdout], OutPos)
    ->  LinePos < OutPos
    ;   true
    ).

codegen_python_obligation(Tokens, 22,
    'Split words on whitespace with `str.split()`, or find them with `re.finditer(r"[A-Za-z]+", text)`; punctuation and digits separate words.') :-
    (   codegen_python_token(Tokens, word)
    ;   codegen_python_token(Tokens, words)
    ).

codegen_python_obligation(Tokens, 23,
    'Lowercase with `text.lower()` before comparing or printing.') :-
    codegen_python_token(Tokens, lowercase),
    codegen_python_any(Tokens, [convert, converts, converted]).

codegen_python_obligation(Tokens, 25,
    'Parse the expression with precedence and parentheses; the standard library has no infix reader, so write one, and use `//` for a quoted floor.') :-
    (   codegen_python_token(Tokens, expression)
    ;   codegen_python_token(Tokens, expressions)
    ;   codegen_python_token(Tokens, operator)
    ;   codegen_python_token(Tokens, operators)
    ;   codegen_python_token(Tokens, precedence)
    ;   codegen_python_token(Tokens, parentheses)
    ).

codegen_python_obligation(Tokens, 26,
    'Use `//` for floor division of integers and `int(a / b)` only where the task says truncate toward zero; `int()` truncates, `round()` does not.') :-
    (   codegen_python_token(Tokens, division)
    ;   codegen_python_token(Tokens, divide)
    ;   codegen_python_token(Tokens, divides)
    ;   codegen_python_token(Tokens, quotient)
    ;   codegen_python_phrase(Tokens, [truncates, toward, zero])
    ;   codegen_python_phrase(Tokens, [truncate, toward, zero])
    ).

codegen_python_obligation(Tokens, 27,
    'A `str` is not a `bytes`: iterate over characters, not code units, and encode only at a file or a socket.') :-
    (   codegen_python_token(Tokens, string)
    ;   codegen_python_token(Tokens, strings)
    ;   codegen_python_token(Tokens, character)
    ;   codegen_python_token(Tokens, characters)
    ;   codegen_python_token(Tokens, char)
    ;   codegen_python_token(Tokens, chars)
    ;   codegen_python_token(Tokens, text)
    ).

codegen_python_obligation(Tokens, 28,
    'A float is `float`; compare with a tolerance, not `==`, and print with an f-string format the task names.') :-
    (   codegen_python_token(Tokens, float)
    ;   codegen_python_token(Tokens, floats)
    ;   codegen_python_token(Tokens, floating)
    ;   codegen_python_phrase(Tokens, [floating, point])
    ;   codegen_python_token(Tokens, decimal)
    ;   codegen_python_token(Tokens, decimals)
    ).

codegen_python_obligation(Tokens, 29,
    'Print exactly the number of decimal places named, as `f"{value:.2f}"` prints two.') :-
    (   codegen_python_token(Tokens, precision)
    ;   codegen_python_token(Tokens, decimal),
        codegen_python_any(Tokens, [places, digits])
    ).

codegen_python_obligation(Tokens, 30,
    'Sum with `sum(...)` over the parsed values, not over their characters; Python integers do not overflow.') :-
    codegen_python_token(Tokens, sum),
    codegen_python_any(Tokens, [integer, integers]).

codegen_python_obligation(Tokens, 31,
    'A maximum or minimum is `max(...)` or `min(...)` over the values, not a zero to start from, so an all-negative input works.') :-
    (   codegen_python_token(Tokens, maximum)
    ;   codegen_python_token(Tokens, max)
    ;   codegen_python_token(Tokens, minimum)
    ;   codegen_python_token(Tokens, min)
    ).

codegen_python_obligation(Tokens, 32,
    'Only even integers contribute to the sum; if none occurs the answer is 0.') :-
    codegen_python_token(Tokens, even),
    codegen_python_any(Tokens, [sum, sums]).

codegen_python_obligation(Tokens, 33,
    'A matrix is a list of lists; check every row and column index against `len(...)` before subscripting.') :-
    (   codegen_python_token(Tokens, matrix)
    ;   codegen_python_token(Tokens, matrices)
    ;   codegen_python_token(Tokens, grid)
    ;   codegen_python_token(Tokens, grids)
    ).

codegen_python_obligation(Tokens, 35,
    'A recursion that may nest deeper than 1000 needs `sys.setrecursionlimit`, or an iteration with a stack of its own; `fib(30)` by the plain definition is a slow path the task may mean.') :-
    (   codegen_python_token(Tokens, recursive)
    ;   codegen_python_token(Tokens, recursively)
    ;   codegen_python_token(Tokens, recursion)
    ).

codegen_python_obligation(Tokens, 40,
    'A subarray is a contiguous, non-empty slice; with all-negative values choose one element.') :-
    (   codegen_python_token(Tokens, subarray)
    ;   codegen_python_token(Tokens, subarrays)
    ;   codegen_python_token(Tokens, contiguous)
    ).

codegen_python_obligation(Tokens, 41,
    'A subsequence keeps order and not adjacency; it is not a substring.') :-
    (   codegen_python_token(Tokens, subsequence)
    ;   codegen_python_token(Tokens, subsequences)
    ).

codegen_python_obligation(Tokens, 42,
    'Track bracket kind and nesting order with a stack, not a count.') :-
    (   codegen_python_token(Tokens, bracket)
    ;   codegen_python_token(Tokens, brackets)
    ).

codegen_python_obligation(Tokens, 43,
    'Join with the separator the task names, as `sep.join(...)`, with no trailing separator; `print(*values, sep=",")` puts none.') :-
    (   codegen_python_token(Tokens, comma)
    ;   codegen_python_token(Tokens, commas)
    ;   codegen_python_token(Tokens, tab)
    ;   codegen_python_token(Tokens, tabs)
    ;   codegen_python_token(Tokens, 'comma-separated')
    ;   codegen_python_phrase(Tokens, [comma, separated])
    ;   codegen_python_phrase(Tokens, [space, separated])
    ;   codegen_python_phrase(Tokens, ['comma-separated'])
    ).

codegen_python_obligation(Tokens, 44,
    'Uppercase with `text.upper()` before comparing or printing.') :-
    codegen_python_token(Tokens, uppercase),
    codegen_python_any(Tokens, [convert, converts, converted]).

codegen_python_obligation(Tokens, 50,
    'Sort descending with `sorted(values, key=KEY, reverse=True)`.') :-
    codegen_python_sort_cue(Tokens),
    (   codegen_python_any(Tokens, [descending, decreasing])
    ;   codegen_python_phrase(Tokens, [highest, first])
    ;   codegen_python_phrase(Tokens, [largest, first])
    ;   codegen_python_phrase(Tokens, [highest, score])
    ).

codegen_python_obligation(Tokens, 51,
    'Sort ascending with `sorted(values, key=KEY)`, which is ascending by default.') :-
    codegen_python_sort_cue(Tokens),
    (   codegen_python_any(Tokens, [ascending, increasing])
    ;   codegen_python_phrase(Tokens, [lowest, first])
    ;   codegen_python_phrase(Tokens, [smallest, first])
    ).

codegen_python_obligation(Tokens, 52,
    '`sorted()` over `str` is lexicographic by code point; `min` of two of them, and `key=str.lower` only where case does not matter.') :-
    (   codegen_python_token(Tokens, lexicographic)
    ;   codegen_python_token(Tokens, lexicographical)
    ;   codegen_python_phrase(Tokens, [lexicographic, order])
    ).

%% Python's sort is stable, so the rule is a caution against
%% `list.sort()` inside a comparator or a second sort that undoes the first.
codegen_python_obligation(Tokens, 53,
    '`sorted()` and `list.sort()` are stable; sort once by the last key, or sort by a tuple of keys, and never re-sort a list that is already ordered.') :-
    codegen_python_sort_cue(Tokens),
    (   codegen_python_token(Tokens, stable)
    ;   codegen_python_phrase(Tokens, [original, input, order])
    ;   codegen_python_phrase(Tokens, [original, order])
    ;   codegen_python_phrase(Tokens, [input, order])
    ;   codegen_python_phrase(Tokens, [same, score])
    ;   codegen_python_phrase(Tokens, [same, key])
    ).

codegen_python_obligation(Tokens, 54,
    'Print each distinct value once: `set` loses the order (dicts keep it), so print `sorted(set(values))` or a `dict.fromkeys` where the task wants first occurrence.') :-
    (   codegen_python_token(Tokens, distinct)
    ;   codegen_python_token(Tokens, unique)
    ).

codegen_python_obligation(Tokens, 55,
    'Count every occurrence with `collections.Counter`, not only whether a value appears.') :-
    (   codegen_python_token(Tokens, count)
    ;   codegen_python_token(Tokens, counts)
    ).

codegen_python_obligation(Tokens, 56,
    'A test runs under `python3 -m pytest` (or `python3 -m unittest`); a test that was written and not run is not a test that passed.') :-
    (   codegen_python_token(Tokens, test)
    ;   codegen_python_token(Tokens, tests)
    ;   codegen_python_token(Tokens, pytest)
    ;   codegen_python_token(Tokens, unittest)
    ).

codegen_python_obligation(Tokens, 57,
    'An error the task names is raised with `raise ValueError("...")`, caught by its class, and never reported by a bare `except:`.') :-
    (   codegen_python_token(Tokens, exception)
    ;   codegen_python_token(Tokens, exceptions)
    ;   codegen_python_token(Tokens, error)
    ;   codegen_python_token(Tokens, errors)
    ;   codegen_python_token(Tokens, raise)
    ;   codegen_python_token(Tokens, raises)
    ;   codegen_python_token(Tokens, valueerror)
    ;   codegen_python_token(Tokens, typeerror)
    ).

codegen_python_obligation(Tokens, 58,
    'A generator is consumed once: materialise it with `list(...)` before a second pass over it.') :-
    (   codegen_python_token(Tokens, generator)
    ;   codegen_python_token(Tokens, generators)
    ;   codegen_python_token(Tokens, yield)
    ).

codegen_python_obligation(Tokens, 59,
    'Check a type before an operation that needs it: `TypeError` and `ValueError` are different answers, and `isinstance` is the check.') :-
    (   codegen_python_token(Tokens, type)
    ;   codegen_python_token(Tokens, types)
    ;   codegen_python_token(Tokens, isinstance)
    ).

%% ---- a sort cue --------------------------------------------------------

codegen_python_sort_cue(Tokens) :-
    codegen_python_any(Tokens, [sort, sorts, sorted, sortby, order,
                                ordered, reverses, reverse]).

%% ---- the checks the tool adds ------------------------------------------

codegen_python_sanity_checks([
    'Each new name is assigned or bound before it is used, and each new function is defined above its first use.',
    'Run the program or the tests you wrote, and read the output of that run.'
]).
