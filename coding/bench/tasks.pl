%% coding/bench/tasks.pl -- the benchmark's requirements and cases.
%%
%% bench_task(+Name, -Spec, -Cases)
%%     Spec is the requirement sent to the generator. Cases is a list of
%%     case(Input, Expected), both atoms; Input keeps its newlines, and
%%     Expected has no final newline (the runner trims both sides).
%%
%% The tasks are deliberately small enough to finish in one benchmark run
%% and hard enough that a no-reasoning model can get one wrong: an empty
%% input, an all-negative maximum subarray, mismatched bracket kinds, a
%% sorted word count, a stateful phonebook, and operator precedence.

bench_task(sum_even, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads integers from standard input until EOF.',
        'It prints, on one line, the sum of all even integers (negative even integers',
        'included). If there are no even integers, it prints 0.'
    ], Spec),
    Cases = [ case('1 2 3 4\n', '6'),
              case('-2 3 -4\n', '-6'),
              case('1 3 5\n', '0'),
              case('\n', '0')
            ].

bench_task(max_subarray, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads an integer n (1 <= n <= 100000),',
        'then n integers. It prints the maximum sum of a non-empty contiguous',
        'subarray, on one line.'
    ], Spec),
    Cases = [ case('5\n-2 1 -3 4 -1\n', '4'),
              case('3\n-5 -2 -9\n', '-2'),
              case('1\n7\n', '7'),
              case('6\n1 2 3 -10 4 5\n', '9'),
              case('4\n-1 -2 -3 -4\n', '-1')
            ].

bench_task(balanced, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads one line of up to 1000 characters',
        'containing only the characters ()[]{}. It prints yes if the brackets are',
        'correctly balanced and properly nested, otherwise no. The newline is not',
        'part of the line.'
    ], Spec),
    Cases = [ case('()[]{}\n', 'yes'),
              case('([{}])\n', 'yes'),
              case('([)]\n', 'no'),
              case('((\n', 'no'),
              case('\n', 'yes')
            ].

bench_task(word_count, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads words from standard input until EOF.',
        'A word is a maximal sequence of ASCII letters. Convert every word to',
        'lowercase. Print each distinct word and its count, one per line, in',
        'lexicographic order, separated by one space.'
    ], Spec),
    Cases = [ case('The cat and the dog.\n', 'and 1\ncat 1\ndog 1\nthe 2'),
              case('a A a\n', 'a 3'),
              case('hello, world! hello\n', 'hello 2\nworld 1'),
              case('\n', '')
            ].

bench_task(phonebook, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads commands from standard input until EOF,',
        'one command per line:',
        '  add NAME NUMBER  -- NAME is one word of letters, NUMBER is an integer; add or replace',
        '  find NAME        -- print NUMBER or not found',
        '  delete NAME      -- remove; print not found if absent',
        '  list             -- print all entries sorted by NAME as NAME NUMBER',
        'Store at most 100 entries. Print exactly one line for each output.'
    ], Spec),
    Cases = [ case('add bob 123\nadd alice 456\nlist\n',
                  'alice 456\nbob 123'),
              case('add bob 1\nadd bob 2\nfind bob\n', '2'),
              case('find x\n', 'not found'),
              case('add a 1\ndelete a\nfind a\n', 'not found'),
              case('delete x\n', 'not found'),
              case('add z 9\nadd a 1\nadd m 5\nlist\n', 'a 1\nm 5\nz 9')
            ].

bench_task(calculator, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads one line containing an arithmetic',
        'expression with non-negative integers, +, -, *, /, parentheses, and spaces.',
        'Evaluate it with integer arithmetic; division truncates toward zero. The',
        'expression is valid and fits in a signed 32-bit int. Print the result on one',
        'line.'
    ], Spec),
    Cases = [ case('1+2*3\n', '7'),
              case('(1+2)*3\n', '9'),
              case('10/3\n', '3'),
              case('2*(3+4)-5\n', '9'),
              case('1-2-3\n', '-4'),
              case('(2+3)*(4-1)\n', '15')
            ].

bench_task(lcs, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads two lines, each a string of',
        'lowercase ASCII letters with length at most 100. Print the length of',
        'their longest common subsequence on one line.'
    ], Spec),
    Cases = [ case('abcde\nace\n', '3'),
              case('abc\nabc\n', '3'),
              case('abc\ndef\n', '0'),
              case('aggtab\ngxtxayb\n', '4'),
              case('a\na\n', '1'),
              case('abc\n\n', '0')
            ].

bench_task(stable_sort, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads an integer n, then n lines',
        '"NAME SCORE", where NAME is one word of letters and SCORE is an integer.',
        'Print the records sorted by SCORE descending. Records with the same',
        'score must keep their original input order.'
    ], Spec),
    Cases = [ case('5\nbob 10\nalice 10\ncarol 5\ndave 20\n',
                  'dave 20\nbob 10\nalice 10\ncarol 5'),
              case('4\na 1\nb 1\nc 1\nd 1\n', 'a 1\nb 1\nc 1\nd 1'),
              case('3\nz 0\na 0\nm 0\n', 'z 0\na 0\nm 0'),
              case('2\nx -5\ny -10\n', 'x -5\ny -10'),
              case('5\na 2\nb 3\nc 2\nd 3\ne 2\n',
                  'b 3\nd 3\na 2\nc 2\ne 2'),
              case('1\nonly 0\n', 'only 0'),
              case('6\na 1\nb 2\nc 1\nd 2\ne 1\nf 2\n',
                  'b 2\nd 2\nf 2\na 1\nc 1\ne 1')
            ].

bench_task(btree, Spec, Cases) :-
    bench_lines([
        'Write a complete C17 program. It reads an integer n, then n integers.',
        'Insert each integer into a B-tree of minimum degree 2 (a 2-3-4 tree),',
        'ignoring a key already present. Print the keys in ascending order, one',
        'per line.'
    ], Spec),
    Cases = [ case('0\n', ''),
              case('5\n3 1 4 1 5\n', '1\n3\n4\n5'),
              case('7\n5 5 5 5 5 5 5\n', '5'),
              case('5\n-1 -5 0 5 1\n', '-5\n-1\n0\n1\n5'),
              case('10\n10 20 30 40 50 60 70 80 90 100\n',
                  '10\n20\n30\n40\n50\n60\n70\n80\n90\n100'),
              case('15\n50 30 70 20 40 60 80 10 25 35 45 55 65 75 85\n',
                  '10\n20\n25\n30\n35\n40\n45\n50\n55\n60\n65\n70\n75\n80\n85')
            ].

%% One requirement from lines. The newline between lines is the atom's
%% own, so the spec reaches the model as written.
bench_lines([], '').
bench_lines([Line], Line) :- !.
bench_lines([Line|Lines], Text) :-
    bench_lines(Lines, Rest),
    atomic_list_concat([Line, '\n', Rest], Text).

%% ---- the controlled-English contract ----------------------------------
%%
%% bench_requirement(+Name, -Sentences) is the same requirement in the
%% controlled English library(reasoning/reason) reads. coding/bench/
%% contract.pl parses these sentences and derives the obligations the
%% `contract' mode adds to the prompt. A sentence this reader refuses is
%% a broken contract, not a hint: keep each one in the shapes it reads
%% (`Every X has a Y.', `Name reads the Y.', `Name prints the Y.').

bench_requirement(sum_even, [
    'Every program has an input.',
    'Every program has an output.',
    'SumEven reads the integers.',
    'SumEven prints the sum.',
    'Every sum is even.'
]).

bench_requirement(max_subarray, [
    'Every program has an input.',
    'Every program has an output.',
    'MaxSubarray has a subarray.',
    'MaxSubarray reads the integers.',
    'MaxSubarray prints the sum.'
]).

bench_requirement(balanced, [
    'Every program has an input.',
    'Every program has an output.',
    'Balanced reads the line.',
    'Every line has a bracket.',
    'Every line has a length.'
]).

bench_requirement(word_count, [
    'Every program has an input.',
    'Every program has an output.',
    'WordCount reads the words.',
    'WordCount prints the words.',
    'WordCount sorts the words.',
    'Every word has a letter.',
    'Every word has a count.'
]).

bench_requirement(phonebook, [
    'Every program has an input.',
    'Every program has an output.',
    'Phonebook reads the commands.',
    'Every command has a verb.',
    'Every command has a name.',
    'Every name has a number.'
]).

bench_requirement(calculator, [
    'Every program has an input.',
    'Every program has an output.',
    'Calculator reads the expression.',
    'Every expression has a number.',
    'Every expression has an operator.',
    'Every expression has a parenthesis.'
]).

bench_requirement(lcs, [
    'Every program has an input.',
    'Every program has an output.',
    'Lcs reads the first line.',
    'Lcs reads the second line.',
    'Lcs has a subsequence.',
    'Lcs prints the length.',
    'Every line has a length.'
]).

bench_requirement(stable_sort, [
    'Every program has an input.',
    'Every program has an output.',
    'SortStable reads the line.',
    'SortStable prints the output.',
    'Every line has a name.',
    'Every line has a number.',
    'Every line has a score.',
    'Every line has an order.'
]).

bench_requirement(btree, [
    'Every program has an input.',
    'Every program has an output.',
    'BTree reads the integers.',
    'BTree prints the output.',
    'Every program has a recursion.',
    'Every program has an allocation.'
]).

%% The capitalized name the extractor is told to use. The controlled
%% English reader capitalizes a proper name; these are the same atoms it
%% will read back as sumeven, maxsubarray, ...
bench_program_name(sum_even, 'SumEven').
bench_program_name(max_subarray, 'MaxSubarray').
bench_program_name(balanced, 'Balanced').
bench_program_name(word_count, 'WordCount').
bench_program_name(phonebook, 'Phonebook').
bench_program_name(calculator, 'Calculator').
bench_program_name(lcs, 'Lcs').
bench_program_name(stable_sort, 'SortStable').
bench_program_name(btree, 'BTree').

%% The extractor's closed vocabulary: the noun it must use for `reads',
%% the noun it must use for `prints', and every noun an optional line may
%% use. input and output are added to every list by the prompt.
bench_extract_nouns(sum_even, integers, sum,
                    [integers, integer, sum, number, count]).
bench_extract_nouns(max_subarray, integers, sum,
                    [integers, integer, subarray, sum, number]).
bench_extract_nouns(balanced, line, output,
                    [line, bracket, length, number]).
bench_extract_nouns(word_count, words, words,
                    [words, word, letter, count, line]).
bench_extract_nouns(phonebook, commands, output,
                    [commands, command, verb, name, number, line]).
bench_extract_nouns(calculator, expression, output,
                    [expression, number, operator, parenthesis]).
bench_extract_nouns(lcs, line, length,
                    [line, length, subsequence]).
bench_extract_nouns(stable_sort, line, output,
                    [line, name, number, score, order, word, count]).
bench_extract_nouns(btree, integers, keys,
                    [integers, integer, node, key, tree]).

%% A line the required set cannot say and the task needs: sum_even's
%% property is what makes its sum the sum of the even integers.
bench_extract_extra_lines(sum_even, ['Every sum is even.']).
bench_extract_extra_lines(stable_sort,
                          ['Every line has a score.',
                           'Every line has an order.']).
bench_extract_extra_lines(_, []).
