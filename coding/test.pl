%% coding/test.pl -- the coding helpers' own checks.
%%
%%     cocolog -s coding/test.pl        from this repository's root
%%
%% The obligations' word boundaries, the lines each benchmark task's
%% requirement implies, the controlled-English contract, the guided
%% prompt, the C compile checker and case runner, and the command line.
%% No model call and no network.

:- use_module('test/prelude.pl').
:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module('coding/bench/contract.pl').
:- use_module('coding/compile.pl').

main :-
    obligations,
    contract,
    shared,
    boundaries,
    prompt,
    checker,
    runner,
    cases_file,
    cli,
    checks_done.

%% ---- the obligations a requirement implies -----------------------------

obligations :-
    section('obligations'),
    stable_sort,
    word_count,
    max_subarray,
    balanced,
    calculator,
    strings.

stable_sort :-
    Spec = 'Write a complete C17 program. It reads an integer n, then n lines "NAME SCORE", where NAME is one word of letters and SCORE is an integer. Print the records sorted by SCORE descending. Records with the same score must keep their original input order.',
    has_line('the stable sort reads lines', Spec, 'Read whole lines'),
    has_line('the stable sort reads a whole integer', Spec, 'whole integer'),
    has_line('the stable sort has words of letters', Spec, 'maximal run of ASCII letters'),
    has_line('the sort is descending', Spec, 'Sort in descending order.'),
    has_line('equal scores keep their order', Spec, 'the sort must be stable'),
    no_line('no subarray in a stable sort', Spec, 'subarray'),
    no_line('no expression in a stable sort', Spec, 'operator precedence'),
    one_of_each('the stable obligations are distinct', Spec).

word_count :-
    Spec = 'Write a complete C17 program. It reads words from standard input until EOF. A word is a maximal sequence of ASCII letters. Convert every word to lowercase. Print each distinct word and its count, one per line, in lexicographic order, separated by one space.',
    has_line('a word is ASCII letters', Spec, 'maximal run of ASCII letters'),
    has_line('every word is lowered', Spec, 'lowercase'),
    has_line('the words are sorted by bytes', Spec, 'lexicographic order'),
    has_line('each distinct word once', Spec, 'each distinct value once'),
    has_line('every occurrence is counted', Spec, 'Count every occurrence'),
    has_line('the input ends at EOF', Spec, 'end of file'),
    no_line('a printed line is no input line', Spec, 'Read whole lines').

max_subarray :-
    Spec = 'Write a complete C17 program. It reads an integer n (1 <= n <= 100000), then n integers. It prints the maximum sum of a non-empty contiguous subarray, on one line.',
    has_line('the subarray is contiguous', Spec, 'subarray is contiguous'),
    has_line('a maximum starts at the first value', Spec, 'maximum or minimum'),
    has_line('the sum has room', Spec, 'type wide enough for the sum'),
    no_line('a printed line is no input line', Spec, 'Read whole lines').

balanced :-
    Spec = 'Write a complete C17 program. It reads one line of up to 1000 characters containing only the characters ()[]{}. It prints yes if the brackets are correctly balanced and properly nested, otherwise no.',
    has_line('the input line is read whole', Spec, 'Read whole lines'),
    has_line('the bracket kind is tracked', Spec, 'bracket kind').

calculator :-
    Spec = 'Write a complete C17 program. It reads one line containing an arithmetic expression with non-negative integers, +, -, *, /, parentheses, and spaces. Evaluate it with integer arithmetic; division truncates toward zero. Print the result on one line.',
    has_line('the input line is read whole', Spec, 'Read whole lines'),
    has_line('precedence is respected', Spec, 'operator precedence'),
    has_line('division is integer', Spec, 'integer division').

strings :-
    Spec = "Read until end-of-file and print the sum of integers.",
    has_line('a string is a requirement too', Spec, 'end of file'),
    has_line('the sum is mentioned', Spec, 'wide enough for the sum').

%% ---- the controlled-English contract ----------------------------------

contract :-
    section('contract'),
    Stable = 'Every program has an input. Every program has an output. SortStable reads the line. SortStable prints the output. Every line has a name. Every line has a number. Every line has a score. Every line has an order.',
    contract_has('a contract reads lines', Stable, 'Read whole lines'),
    contract_has('the score is ordered highest first', Stable, 'Sort the records by score'),
    contract_has('equal scores keep their order', Stable, 'the sort is stable'),
    contract_has('a number is one integer', Stable, 'Parse a number as an integer'),
    contract_has('a name is one word', Stable, 'A name is one word of letters'),
    contract_has('the output is exact', Stable, 'Write exactly the required result'),
    contract_no('no subarray in the stable contract', Stable, 'subarray'),
    Calculator = 'Every program has an input. Every program has an output. Calculator reads the expression. Every expression has a number. Every expression has an operator. Every expression has a parenthesis.',
    contract_has('the operators are named', Calculator, 'Handle +, -, *, and /'),
    contract_has('parentheses group', Calculator, 'Parentheses group subexpressions'),
    contract_has('the expression is whole', Calculator, 'Parse the whole expression'),
    yes_no(( codegen_contract_obligations(['Every program has an input.', 'Every program has an output.'], Lines),
             member('Read from standard input to end of file; an empty input is valid.', Lines)
           ), Y1),
    check('a list of sentences is a contract', Y1, yes),
    yes_no(( codegen_contract_obligations('Every dog has a tail.', Lines2),
             Lines2 == []
           ), Y2),
    check('a shape with no rule adds no line', Y2, yes),
    yes_no(( codegen_contract_obligations('The quick brown fox jumps over the lazy dog.', Lines3),
             Lines3 == []
           ), Y3),
    check('a contract the reader refuses is empty', Y3, yes).

contract_has(Label, Text, Fragment) :-
    yes_no(contract_has_line(Text, Fragment), YN),
    check(Label, YN, yes).

contract_no(Label, Text, Fragment) :-
    yes_no(contract_has_line(Text, Fragment), YN),
    check(Label, YN, no).

contract_has_line(Text, Fragment) :-
    codegen_contract_obligations(Text, Obligations),
    atomic_list_concat(Obligations, '\n', All),
    sub_atom(All, _, _, _, Fragment).

%% ---- one vocabulary for the tool and the benchmark --------------------

shared :-
    section('shared contract'),
    findall(Task, bench_task(Task, _, _), Tasks),
    forall(member(Task, Tasks), shared_one(Task)),
    yes_no(( bench_reply_obligations('Every line has a bracket.\n', Parsed, Obs),
             Parsed \== [],
             member('Track bracket kind and nesting order, not only counts.', Obs)
           ), Y),
    check('the extractor reply uses the shared vocabulary', Y, yes),
    yes_no(( bench_task(stable_sort, Spec, _),
             bench_derive_obligations(stable_sort, Spec, Derived),
             member('Sort the records by score, highest first.', Derived),
             member('Records with equal scores keep their original input order; the sort is stable.', Derived)
           ), Y2),
    check('the derive mode uses the shared vocabulary', Y2, yes).

shared_one(Task) :-
    bench_requirement(Task, Sentences),
    codegen_contract_obligations(Sentences, Tool),
    bench_obligations(Task, Bench),
    (   Tool == Bench
    ->  Same = yes
    ;   Same = no
    ),
    format(atom(Label), 'the benchmark and the tool agree on ~w', [Task]),
    check(Label, Same, yes).

%% ---- whole words, not substrings --------------------------------------

boundaries :-
    section('boundaries'),
    Spec = 'Write an assortment for the deadline; a password is not a sort.',
    no_line('assortment is not a sort', Spec, 'Sort in'),
    no_line('deadline is not a line', Spec, 'Read whole lines'),
    no_line('password is not a word', Spec, 'maximal run of ASCII letters'),
    has_line('Write is still an output verb', Spec, 'do not print a prompt').

%% ---- the guided prompt -------------------------------------------------

prompt :-
    section('prompt'),
    Spec = 'Read lines. Print them sorted in descending order.',
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), codegen_obligations('~w', Os), codegen_guided_prompt('~w', Os, none, P), write(P)\"",
           [Spec, Spec]),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the prompt says the checks are mandatory', 'must satisfy every one', Text),
    has('the prompt carries the sort line', 'Sort in descending order.', Text),
    has('the prompt carries the requirement', 'Read lines.', Text).

%% ---- the compile checker ----------------------------------------------

checker :-
    section('compile'),
    Good = '#include <stdio.h>\nint main(void) { return 0; }\n',
    yes_no(c_compile_check(Good, ok), Y1),
    check('a valid program compiles', Y1, yes),
    Bad = 'int main(void) { return missing; }\n',
    yes_no(( c_compile_check(Bad, Verdict),
             Verdict = fail(Diag),
             sub_atom(Diag, _, _, _, 'missing')
           ), Y2),
    check('an invalid program fails and names the identifier', Y2, yes),
    Warn = 'int main(void) { int unused; return 0; }\n',
    yes_no(c_compile_check(Warn, ok), Y3),
    check('a warning is not a failure', Y3, yes).

%% ---- the case runner ---------------------------------------------------

runner :-
    section('runner'),
    Sum = '#include <stdio.h>\nint main(void) { long a, s = 0; while (scanf("%ld", &a) == 1) s += a; printf("%ld\\n", s); return 0; }\n',
    Cases = [case('1 2 3\n', '6'), case('4 5\n', '9')],
    yes_no(c_test_check(Sum, Cases, ok), Y1),
    check('a right program passes every case', Y1, yes),
    Wrong = '#include <stdio.h>\nint main(void) { printf("0\\n"); return 0; }\n',
    yes_no(( c_test_check(Wrong, Cases, fail(test, Diag)),
             sub_atom(Diag, _, _, _, 'CASE 1 WRONG')
           ), Y2),
    check('a wrong answer is a test failure', Y2, yes),
    Broken = 'int main(void) { return missing; }\n',
    yes_no(c_test_check(Broken, Cases, fail(compile, _)), Y3),
    check('a compile failure is not a test failure', Y3, yes),
    Overflow = '#include <stdio.h>\nint main(void) { volatile int x = 2147483647; x = x + 1; printf("%d\\n", x); return 0; }\n',
    yes_no(( c_test_check(Overflow, [case('', '')], fail(test, Diag1)),
             sub_atom(Diag1, _, _, _, 'runtime error')
           ), Y4),
    check('undefined behaviour fails a case', Y4, yes),
    Heap = '#include <stdio.h>\n#include <stdlib.h>\nint main(void) { int *a = malloc(sizeof(int)); a[0] = 7; volatile int i = 1; printf("%d\\n", a[i]); return 0; }\n',
    yes_no(( c_test_check(Heap, [case('', '')], fail(test, Diag2)),
             sub_atom(Diag2, _, _, _, 'AddressSanitizer')
           ), Y5),
    check('a heap overflow fails a case', Y5, yes),
    Leak = '#include <stdio.h>\n#include <stdlib.h>\nint main(void) { char *p = malloc(10); p[0] = 0; printf("ok\\n"); return 0; }\n',
    yes_no(c_test_check(Leak, [case('', 'ok')], ok), Y6),
    check('a leak is not a wrong answer', Y6, yes).

%% ---- the cases file ----------------------------------------------------

cases_file :-
    section('cases file'),
    scratch(Dir),
    atom_concat(Dir, '/good.pl', GoodFile),
    fixture(GoodFile, ['cases([case(''1 2\\n'', ''3''), case('''', ''0'')]).']),
    yes_no(( c_read_cases(GoodFile, Cases),
             Cases == [case('1 2\n', '3'), case('', '0')]
           ), Y1),
    check('a cases term is read, its escapes kept', Y1, yes),
    atom_concat(Dir, '/bad.pl', BadFile),
    fixture(BadFile, ['cases([case(''a''), case(''b'', ''c'')]).']),
    yes_no(( catch(( c_read_cases(BadFile, _), fail ),
                   error(codegen_error(cases_file, _), _),
                   true)
           ), Y2),
    check('a malformed case is refused', Y2, yes),
    atom_concat(Dir, '/notaterm.pl', NoFile),
    fixture(NoFile, ['this is not a term']),
    yes_no(( catch(( c_read_cases(NoFile, _), fail ),
                   error(codegen_error(cases_file, _), _),
                   true)
           ), Y3),
    check('a file that is not a term is refused', Y3, yes).

%% ---- the command line --------------------------------------------------

cli :-
    section('cli'),
    cli_query("codegen_args(['s','o'], S,T,C,O,R,Os), write(args(S,T,C,O,R,Os))",
              ['args(s,none,none,o,no,[]']),
    cli_query("codegen_args(['s','--tests','c','o'], S,T,C,O,R,Os), write(args(S,T,C,O,R,Os))",
              ['args(s,c,none,o,no,[]']),
    cli_query("codegen_args(['s','--contract','k.txt','o'], S,T,C,O,R,Os), write(args(S,T,C,O,R,Os))",
              ['args(s,none,k.txt,o,no,[]']),
    cli_query("codegen_args(['--provider','openai','--model','deepseek-flash','--base-url','https://x','--effort','none','s','o'], S,T,C,O,R,Os), write(args(S,T,C,O,R,Os))",
              ['provider(openai)', 'model(deepseek-flash)',
               'base_url(https://x)', 'effort(none)']),
    cli_query("codegen_args(['s','--report','o'], S,T,C,O,R,Os), write(args(S,T,C,O,R,Os))",
              [',yes,']),
    cli_query("( codegen_args(['s','--provider'],_,_,_,_,_,_) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','o','x'],_,_,_,_,_,_) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("codegen_report_reset, codegen_report(R), write(R)",
              ['report(0,0,0,0,0)']),
    cli_query("codegen_report(R), write(R)",
              ['report(0,0,0,0,0)']),
    cli_query("( catch(codegen_obligations_for(s, '/no/such/contract', _), error(codegen_error(contract_file, _), _), true) -> write(yes) ; write(no) )",
              ['yes']).

cli_query(Goal, Needles) :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), ~s\"",
           [Goal]),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    forall(member(Needle, Needles),
           has('the command line says the expected term', Needle, Text)).

%% ---- helpers -----------------------------------------------------------

has_line(Label, Spec, Fragment) :-
    yes_no(codegen_has_line(Spec, Fragment), YN),
    check(Label, YN, yes).

no_line(Label, Spec, Fragment) :-
    yes_no(codegen_has_line(Spec, Fragment), YN),
    check(Label, YN, no).

codegen_has_line(Spec, Fragment) :-
    codegen_obligations(Spec, Obligations),
    atomic_list_concat(Obligations, '\n', All),
    sub_atom(All, _, _, _, Fragment).

one_of_each(Label, Spec) :-
    codegen_obligations(Spec, Obligations),
    sort(Obligations, Sorted),
    length(Obligations, N),
    length(Sorted, M),
    Diff is N - M,
    check(Label, Diff, 0).
