%% coding/test.pl -- the coding helpers' own checks.
%%
%%     cocolog -s coding/test.pl        from this repository's root
%%
%% The obligations' word boundaries, the lines each benchmark task's
%% requirement implies, the controlled-English contract, the guided
%% prompt, the C compile checker and case runner, the command line, and
%% the standalone checker. No model call and no network.

:- use_module('test/prelude.pl').
:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module('coding/bench/contract.pl').
:- use_module('coding/compile.pl').

main :-
    clang_required,
    obligations,
    contract,
    shared,
    boundaries,
    prompt,
    checker,
    runner,
    cases_file,
    cli,
    cflags,
    analyze_gen,
    budget,
    keep,
    dry_run,
    check_tool,
    checks_done.

clang_required :-
    (   catch(proc_run('command -v clang >/dev/null 2>&1', 10000, _, Exit), _, fail)
    ->  (   Exit == 0
        ->  true
        ;   skip('no clang on the path')
        )
    ;   skip('no clang on the path')
    ).

%% ---- the obligations a requirement implies -----------------------------

obligations :-
    section('obligations'),
    stable_sort,
    word_count,
    max_subarray,
    balanced,
    calculator,
    strings,
    general.

general :-
    Spec = 'Read a text file of comma-separated values. Each line is a matrix row of floating point numbers with two decimal places and one string. Allocate a buffer with malloc, recursively parse it, and convert the result to uppercase.',
    has_line('a file is checked', Spec, 'Check every fopen'),
    has_line('a string is NUL-terminated', Spec, 'NUL-terminated'),
    has_line('floating point is double', Spec, 'Use double for floating point'),
    has_line('decimal places are exact', Spec, 'decimal places'),
    has_line('matrix bounds are checked', Spec, 'row and column index'),
    has_line('allocations are checked', Spec, 'Check every allocation'),
    has_line('recursion is bounded', Spec, 'Bound the recursion depth'),
    has_line('separators are exact', Spec, 'Separate the values'),
    has_line('uppercase is applied', Spec, 'Convert the text to uppercase'),
    no_line('dynamic programming is not memory',
            'Use dynamic programming.', 'Check every allocation'),
    no_line('a tablet is not a table',
            'Buy a tablet.', 'row and column index'),
    no_line('format is not float',
            'Format the output.', 'floating point'),
    no_line('uppercase without convert is no rule',
            'Print the uppercase word.', 'Convert the text to uppercase').

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
    check('a leak is not a wrong answer', Y6, yes),
    Loop = 'int main(void) { for (;;) { } }\n',
    yes_no(( c_test_check(Loop, [case('', '', 124)], 200, fail(test, Diag4)),
             sub_atom(Diag4, _, _, _, 'TIMEOUT')
           ), Y7),
    check('a timeout is a failure even if expected', Y7, yes),
    Macro = '#include <stdio.h>\nint main(void) {\n#ifdef ANSWER_YES\n    printf("yes\\n");\n#else\n    printf("no\\n");\n#endif\n    return 0;\n}\n',
    yes_no(c_test_check(Macro, [case('', 'no')], 3000, '', ok), Y8),
    check('a program without the flag runs its branch', Y8, yes),
    yes_no(c_test_check(Macro, [case('', 'yes')], 3000, '-DANSWER_YES', ok), Y9),
    check('cflags reach the compiler', Y9, yes),
    yes_no(( c_test_check(Macro, [case('', 'yes')], 3000, '', fail(test, Diag5)),
             sub_atom(Diag5, _, _, _, 'CASE 1 WRONG')
           ), Y10),
    check('without the flag the expected branch is wrong', Y10, yes),
    BadExit = '#include <stdio.h>\nint main(void) { printf("bad\\n"); return 2; }\n',
    yes_no(c_test_check(BadExit, [case('', 'bad', 2)], ok), Y11),
    check('an expected exit status passes', Y11, yes),
    yes_no(( c_test_check(BadExit, [case('', 'bad')], fail(test, Diag6)),
             sub_atom(Diag6, _, _, _, 'EXIT 2 (expected 0)')
           ), Y12),
    check('an unexpected exit status fails', Y12, yes),
    yes_no(( c_test_check(BadExit, [case('', 'wrong', 2)], fail(test, Diag7)),
             sub_atom(Diag7, _, _, _, 'CASE 1 WRONG')
           ), Y13),
    check('a matching exit still checks the output', Y13, yes),
    Clean = '#include <stdio.h>\nint main(void) { printf("ok\\n"); return 0; }\n',
    yes_no(c_analyze_check(Clean, ok), Y14),
    check('the analyzer passes a clean program', Y14, yes),
    Null = '#include <stdio.h>\nint main(void) { int *p = 0; printf("%d\\n", *p); return 0; }\n',
    yes_no(( c_analyze_check(Null, fail(Diag8)),
             sub_atom(Diag8, _, _, _, 'Dereference of null pointer')
           ), Y15),
    check('the analyzer finds a null dereference', Y15, yes).

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
    check('a file that is not a term is refused', Y3, yes),
    atom_concat(Dir, '/text.pl', TextFile),
    fixture(TextFile,
            ['# input', '1 2 3', '# expected', '6',
             '# input', '4 5', '# expected', '9']),
    yes_no(( c_read_cases(TextFile, TextCases),
             TextCases == [case('1 2 3\n', '6'), case('4 5\n', '9')]
           ), Y4),
    check('a text file is read block by block', Y4, yes),
    atom_concat(Dir, '/empty_in.pl', EmptyInFile),
    fixture(EmptyInFile, ['# input', '# expected', '0']),
    yes_no(( c_read_cases(EmptyInFile, EmptyInCases),
             EmptyInCases == [case('', '0')]
           ), Y5),
    check('an empty input block is empty input', Y5, yes),
    atom_concat(Dir, '/empty_out.pl', EmptyOutFile),
    fixture(EmptyOutFile, ['# input', 'hello', '# expected']),
    yes_no(( c_read_cases(EmptyOutFile, EmptyOutCases),
             EmptyOutCases == [case('hello\n', '')]
           ), Y6),
    check('an empty expected block is empty output', Y6, yes),
    atom_concat(Dir, '/emptyline.pl', EmptyLineFile),
    fixture(EmptyLineFile, ['# input', '', '# expected', 'yes']),
    yes_no(( c_read_cases(EmptyLineFile, EmptyLineCases),
             EmptyLineCases == [case('\n', 'yes')]
           ), Y6b),
    check('a blank line is an empty line, not no input', Y6b, yes),
    atom_concat(Dir, '/hash.pl', HashFile),
    fixture(HashFile, ['# input', '#include <stdio.h>', '# expected', 'ok']),
    yes_no(( c_read_cases(HashFile, HashCases),
             HashCases == [case('#include <stdio.h>\n', 'ok')]
           ), Y7),
    check('a # that is not a marker is content', Y7, yes),
    atom_concat(Dir, '/before.pl', BeforeFile),
    fixture(BeforeFile, ['hello', '# input', 'x', '# expected', 'y']),
    yes_no(( catch(( c_read_cases(BeforeFile, _), fail ),
                   error(codegen_error(cases_file, Diag0), _),
                   sub_atom(Diag0, _, _, _, 'before the first')
           )), Y8),
    check('text before the first block names its line', Y8, yes),
    atom_concat(Dir, '/noclose.pl', NoCloseFile),
    fixture(NoCloseFile, ['# input', 'x', '# input', 'y', '# expected', 'z']),
    yes_no(( catch(( c_read_cases(NoCloseFile, _), fail ),
                   error(codegen_error(cases_file, _), _),
                   true)
           ), Y9),
    check('a second # input before # expected is refused', Y9, yes),
    atom_concat(Dir, '/eofin.pl', EofInFile),
    fixture(EofInFile, ['# input', 'x']),
    yes_no(( catch(( c_read_cases(EofInFile, _), fail ),
                   error(codegen_error(cases_file, Diag1), _),
                   sub_atom(Diag1, _, _, _, 'ends inside')
           )), Y10),
    check('a file that ends inside an input block is refused', Y10, yes),
    atom_concat(Dir, '/twice.pl', TwiceFile),
    fixture(TwiceFile,
            ['# input', 'x', '# expected', 'y', '# expected', 'z']),
    yes_no(( catch(( c_read_cases(TwiceFile, _), fail ),
                   error(codegen_error(cases_file, _), _),
                   true)
           ), Y11),
    check('a second # expected is refused', Y11, yes),
    atom_concat(Dir, '/multi.pl', MultiFile),
    fixture(MultiFile,
            ['# input', 'a', 'b', '# expected', 'out']),
    yes_no(( c_read_cases(MultiFile, MultiCases),
             MultiCases == [case('a\nb\n', 'out')]
           ), Y12),
    check('a multi-line input keeps its newlines', Y12, yes),
    atom_concat(Dir, '/crlf.pl', CrlfFile),
    atom_codes('# input\r\nx\r\n# expected\r\ny\r\n', Crlf),
    write_file_from_codes(CrlfFile, Crlf),
    yes_no(( c_read_cases(CrlfFile, CrlfCases),
             CrlfCases == [case('x\n', 'y')]
           ), Y13),
    check('a CRLF file is read line by line', Y13, yes),
    atom_concat(Dir, '/exitterm.pl', ExitTermFile),
    fixture(ExitTermFile, ['cases([case(''a\\n'', ''b'', 3)]).']),
    yes_no(( c_read_cases(ExitTermFile, ExitTermCases),
             ExitTermCases == [case('a\n', 'b', 3)]
           ), Y14),
    check('a term carries an exit status', Y14, yes),
    atom_concat(Dir, '/exittext.pl', ExitTextFile),
    fixture(ExitTextFile,
            ['# input', 'bad', '# expected', 'error', '# exit 2',
             '# input', 'good', '# expected', 'ok']),
    yes_no(( c_read_cases(ExitTextFile, ExitTextCases),
             ExitTextCases == [case('bad\n', 'error', 2), case('good\n', 'ok')]
           ), Y15),
    check('a text block carries an exit status', Y15, yes),
    atom_concat(Dir, '/afterexit.pl', AfterExitFile),
    fixture(AfterExitFile,
            ['# input', 'x', '# expected', 'y', '# exit 2', 'stray']),
    yes_no(( catch(( c_read_cases(AfterExitFile, _), fail ),
                   error(codegen_error(cases_file, Diag2), _),
                   sub_atom(Diag2, _, _, _, 'after # exit'))
           ), Y16),
    check('content after # exit is refused', Y16, yes),
    atom_concat(Dir, '/badexit.pl', BadExitFile),
    fixture(BadExitFile,
            ['# input', 'x', '# expected', 'y', '# exit -1']),
    yes_no(( catch(( c_read_cases(BadExitFile, _), fail ),
                   error(codegen_error(cases_file, Diag3), _),
                   sub_atom(Diag3, _, _, _, 'non-negative'))
           ), Y17),
    check('a bad exit number is refused', Y17, yes).

%% ---- the command line --------------------------------------------------

cli :-
    section('cli'),
    cli_query("codegen_args(['s','o'], A), write(A)",
              ['args(s,none,none,o,no,no,[],[]']),
    cli_query("codegen_args(['s','--tests','c','o'], A), write(A)",
              ['args(s,c,none,o,no,no,[],[]']),
    cli_query("codegen_args(['s','--contract','k.txt','o'], A), write(A)",
              ['args(s,none,k.txt,o,no,no,[],[]']),
    cli_query("codegen_args(['s','--keep','k','o'], A), write(A)",
              ['args(s,none,none,o,no,no,[keep(dir(k))],[]']),
    cli_query("codegen_args(['s','--attempts','2','--timeout','500','o'], A), write(A)",
              ['attempts(2)', 'case_timeout(500)']),
    cli_query("codegen_args(['s','--cflags','-DANSWER_YES','o'], A), write(A)",
              ['cflags(-DANSWER_YES)']),
    cli_query("codegen_args(['s','--budget','15','o'], A), write(A)",
              ['budget(15)']),
    cli_query("codegen_args(['s','--analyze','o'], A), write(A)",
              ['analyze(yes)']),
    cli_query("codegen_args(['s','--key-env','MY_KEY','--temperature','0.2','--max-tokens','100','o'], A), write(A)",
              ['key_env(MY_KEY)', 'temperature(0.2)', 'max_tokens(100)']),
    cli_query("codegen_args(['--provider','openai','--model','deepseek-flash','--base-url','https://x','--effort','none','s','o'], A), write(A)",
              ['provider(openai)', 'model(deepseek-flash)',
               'base_url(https://x)', 'effort(none)']),
    cli_query("codegen_args(['s','--report','o'], A), write(A)",
              [',yes,no,']),
    cli_query("codegen_args(['s','--dry-run','o'], A), write(A)",
              [',no,yes,']),
    cli_query("( codegen_args(['s','--provider'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--keep'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--attempts','x'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--timeout','x'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--cflags'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--key-env'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--temperature','x'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--temperature','-0.5'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--max-tokens','0'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--budget','0'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--budget','x'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','--budget'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("( codegen_args(['s','o','x'], _) -> write(yes) ; write(no) )",
              ['no']),
    cli_query("codegen_report_reset, codegen_report(R), write(R)",
              ['report(0,0,0,0,0,0,0.0)']),
    cli_query("codegen_report(R), write(R)",
              ['report(0,0,0,0,0,0,0.0)']),
    cli_query("codegen_report_reset, codegen_report_print(yes)",
              ['0 call(s)', '0 cached']),
    cli_query("asserta((llm_chat(_M,_O,'int main(void) { return 0; }') :- nb_setval(llm_usage, json([prompt_tokens-10, completion_tokens-5, total_tokens-15, prompt_cache_hit_tokens-3, completion_tokens_details-json([reasoning_tokens-2])])), !)), codegen_c_compiled('a spec', _), codegen_report(report(1,10,5,2,3,15,S)), float(S), write('USAGE-731')",
              ['USAGE-731']),
    cli_query("( catch(codegen_obligations_for(s, '/no/such/contract', _), error(codegen_error(contract_file, _), _), true) -> write(yes) ; write(no) )",
              ['yes']).

%% ---- cflags in the generator ------------------------------------------

cflags :-
    section('cflags'),
    cflags_child_success,
    cflags_child_failure.

cflags_child_success :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((codegen_call(_P,_O,'int main(void) { return FOO; }') :- !)), codegen_c_from('a spec', [], [], [], [cflags('-DFOO=0')], _), write('CFLAGS-OK-'), write(731)\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the generated program builds with its flag', 'CFLAGS-OK-731', Text).

cflags_child_failure :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((codegen_call(_P,_O,'int main(void) { return FOO; }') :- !)), ( catch(codegen_c_from('a spec', [], [], [], [], _), error(codegen_error(compile_failed,_),_), true) -> write('CFLAGS-FAIL-'), write(731) ; write('CFLAGS-OTHER-'), write(731) )\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('without its flag the generated program fails', 'CFLAGS-FAIL-731', Text).

%% ---- analysis in the generator ----------------------------------------

analyze_gen :-
    section('analyze'),
    analyze_child_stop,
    analyze_child_pass.

analyze_child_stop :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((codegen_call(_,_,'int main(void) { int *p = 0; return *p; }') :- !)), ( catch(codegen_c_from('a spec', [], [], [], [analyze(yes), attempts(1)], _), error(codegen_error(analyze_failed,_),_), true) -> write('ANALYZE-STOP-'), write(731) ; write('ANALYZE-OTHER-'), write(731) )\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the analyzer stops a generated program', 'ANALYZE-STOP-731', Text).

analyze_child_pass :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((codegen_call(_,_,'int main(void) { int *p = 0; return *p; }') :- !)), codegen_c_from('a spec', [], [], [], [attempts(1)], _), write('ANALYZE-PASS-'), write(731)\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('without the flag the program is accepted', 'ANALYZE-PASS-731', Text).

%% ---- the token budget ------------------------------------------------

budget :-
    section('budget'),
    budget_child_stop,
    budget_child_pass.

budget_child_stop :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((llm_chat(_,_,'int main(void) { return missing; }') :- nb_setval(llm_usage, json([prompt_tokens-10, completion_tokens-5, total_tokens-15])), !)), ( catch(codegen_c_from('a spec', [], [], [], [budget(15), attempts(3)], _), error(codegen_error(budget_exceeded,_),_), true) -> write('BUDGET-STOP-'), write(731) ; write('BUDGET-OTHER-'), write(731) ), codegen_report(report(C,_,_,_,_,_,_)), write('BUDGET-CALLS-'), write(C), nl\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the budget stops before a repair', 'BUDGET-STOP-731', Text),
    has('the budget stops after one call', 'BUDGET-CALLS-1', Text).

budget_child_pass :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((llm_chat(_,_,'int main(void) { return 0; }') :- nb_setval(llm_usage, json([prompt_tokens-10, completion_tokens-5, total_tokens-15])), !)), codegen_c_from('a spec', [], [], [], [budget(1)], _), write('BUDGET-PASS-'), write(731)\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('a passing first call ignores the budget', 'BUDGET-PASS-731', Text).

%% ---- keeping the attempts ---------------------------------------------

keep :-
    section('keep'),
    scratch(Dir),
    atom_concat(Dir, '/logs', KeepDir),
    keep_child_success(KeepDir),
    keep_has(KeepDir, 'attempt-1.prompt.txt', 'a spec'),
    keep_has(KeepDir, 'attempt-1.c', 'missing'),
    keep_has(KeepDir, 'attempt-1.diag.txt', 'COMPILE FAILED'),
    keep_has(KeepDir, 'attempt-2.c', 'return 0'),
    keep_absent(KeepDir, 'attempt-2.diag.txt'),
    scratch(Dir2),
    atom_concat(Dir2, '/logs', KeepDir2),
    keep_child_failure(KeepDir2),
    keep_has(KeepDir2, 'attempt-3.diag.txt', 'COMPILE FAILED'),
    keep_absent(KeepDir2, 'attempt-4.prompt.txt'),
    keep_child_attempts(2).

keep_child_success(Dir) :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), nb_setval(keep_calls,0), asserta((codegen_call(_P,_O,C) :- nb_getval(keep_calls,N0), N1 is N0+1, nb_setval(keep_calls,N1), (N1 =:= 1 -> C = 'int main(void) { return missing; }' ; C = 'int main(void) { return 0; }'), !)), codegen_c_from('a spec', [], [], [], [keep(dir('~w'))], _), write('KEEP-SUCCESS-'), write(731)\"",
           [Dir]),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the keeping run succeeds', 'KEEP-SUCCESS-731', Text).

keep_child_failure(Dir) :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), asserta((codegen_call(_P,_O,'int main(void) { return missing; }') :- !)), ( catch(codegen_c_from('a spec', [], [], [], [keep(dir('~w'))], _), error(codegen_error(compile_failed,_),_), true) -> write('KEEP-FAILED-'), write(731) ; write('KEEP-OTHER-'), write(731) )\"",
           [Dir]),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    has('the keeping run refuses', 'KEEP-FAILED-731', Text).

keep_child_attempts(Count) :-
    format(atom(Args),
           "query \"use_module('coding/c/codegen.pl'), nb_setval(keep_calls,0), asserta((codegen_call(_P,_O,'int main(void) { return missing; }') :- nb_getval(keep_calls,N0), N1 is N0+1, nb_setval(keep_calls,N1), !)), catch(codegen_c_from('a spec', [], [], [], [attempts(2)], _), error(codegen_error(compile_failed,_),_), true), nb_getval(keep_calls,C), write('CALLS-731-'), write(C), nl\"",
           []),
    cocolog_out(Args, Codes),
    atom_codes(Text, Codes),
    format(atom(Needle), 'CALLS-731-~w', [Count]),
    has('the attempts option stops at its count', Needle, Text).

keep_has(Dir, Name, Fragment) :-
    atom_concat(Dir, '/', Prefix),
    atom_concat(Prefix, Name, File),
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(Text, Codes),
        (   sub_atom(Text, _, _, _, Fragment)
        ->  Result = yes
        ;   Result = no
        )
    ;   Result = missing
    ),
    format(atom(Label), '~w holds ~s', [Name, Fragment]),
    check(Label, Result, yes).

keep_absent(Dir, Name) :-
    atom_concat(Dir, '/', Prefix),
    atom_concat(Prefix, Name, File),
    (   catch(read_file_to_codes(File, _), _, fail)
    ->  Result = present
    ;   Result = absent
    ),
    format(atom(Label), '~w is not written', [Name]),
    check(Label, Result, absent).

%% ---- the dry run -------------------------------------------------------

dry_run :-
    section('dry run'),
    scratch(Dir),
    atom_concat(Dir, '/sum.txt', SpecFile),
    fixture(SpecFile,
            ['Write a complete C17 program. It reads integers. It prints the sum of all even integers.']),
    atom_concat(Dir, '/contract.txt', ContractFile),
    fixture(ContractFile,
            ['Every program has an input.',
             'Every program has an output.',
             'Balanced reads the line.',
             'Every line has a bracket.']),
    atom_concat(Dir, '/bad_contract.txt', BadContract),
    fixture(BadContract,
            ['The quick brown fox jumps over the lazy dog.']),
    atom_concat(Dir, '/never.c', OutFile),
    format(atom(Args1), "-s coding/c/codegen.pl -- ~w --dry-run ~w",
           [SpecFile, OutFile]),
    cocolog_run(Args1, Text1, Exit1),
    check('a dry run exits 0', Exit1, 0),
    has('the dry run carries the requirement', 'sum of all even integers', Text1),
    has('the dry run carries the keyword obligation',
        'Only even integers contribute', Text1),
    (   catch(read_file_to_codes(OutFile, _), _, fail)
    ->  Wrote = yes
    ;   Wrote = no
    ),
    check('a dry run writes no program', Wrote, no),
    format(atom(Args2), "-s coding/c/codegen.pl -- ~w --contract ~w --dry-run",
           [SpecFile, ContractFile]),
    cocolog_run(Args2, Text2, Exit2),
    check('a contract dry run exits 0', Exit2, 0),
    has('the contract dry run carries its obligation',
        'Track bracket kind', Text2),
    format(atom(Args3), "-s coding/c/codegen.pl -- ~w --contract ~w --dry-run",
           [SpecFile, BadContract]),
    cocolog_run(Args3, _Text3, Exit3),
    check('a bad contract fails before a prompt', Exit3, 1),
    format(atom(Args4), "-s coding/c/codegen.pl -- ~w --tests ~w --dry-run",
           [SpecFile, '/no/such/cases']),
    cocolog_run(Args4, Text4, Exit4),
    check('a dry run ignores the tests file', Exit4, 0),
    has('the dry run still prints a prompt',
        'Write a complete C17 program', Text4).

%% ---- the standalone checker -------------------------------------------

check_tool :-
    section('check tool'),
    scratch(Dir),
    atom_concat(Dir, '/good.c', Good),
    fixture(Good, ['#include <stdio.h>',
                   'int main(void) { printf("ok\\n"); return 0; }']),
    atom_concat(Dir, '/bad.c', Bad),
    fixture(Bad, ['int main(void) { return missing; }']),
    atom_concat(Dir, '/pass.txt', PassFile),
    fixture(PassFile, ['# input', '# expected', 'ok']),
    atom_concat(Dir, '/wrong.txt', WrongFile),
    fixture(WrongFile, ['# input', '# expected', 'no']),
    check_compiles(Good, Text1, Exit1),
    check('a good file compiles', Exit1, 0),
    has('the good file says OK', 'OK:', Text1),
    check_compiles(Bad, Text2, Exit2),
    check('a bad file fails', Exit2, 1),
    has('the bad file names the failure', 'COMPILE FAILED', Text2),
    check_with_cases(Good, PassFile, Text3, Exit3),
    check('a good file passes its cases', Exit3, 0),
    has('the passing cases say OK', 'case(s) pass', Text3),
    check_with_cases(Good, WrongFile, Text4, Exit4),
    check('a wrong answer fails the check', Exit4, 1),
    has('the wrong answer says TESTS FAILED', 'TESTS FAILED', Text4),
    has('the wrong answer names the case', 'CASE 1 WRONG', Text4),
    atom_concat(Dir, '/macro.c', MacroFile),
    fixture(MacroFile,
            ['#include <stdio.h>',
             'int main(void) {',
             '#ifdef ANSWER_YES',
             '    printf("yes\\n");',
             '#else',
             '    printf("no\\n");',
             '#endif',
             '    return 0;',
             '}']),
    atom_concat(Dir, '/yes.txt', YesFile),
    fixture(YesFile, ['# input', '# expected', 'yes']),
    check_with_cases(MacroFile, YesFile, Text8, Exit8),
    check('without the flag the branch is wrong', Exit8, 1),
    has('without the flag the case fails', 'TESTS FAILED', Text8),
    check_with_cases_flags(MacroFile, YesFile, '-DANSWER_YES', Text9, Exit9),
    check('with cflags the branch is right', Exit9, 0),
    has('with cflags the case passes', 'case(s) pass', Text9),
    atom_concat(Dir, '/exit.c', ExitC),
    fixture(ExitC,
            ['#include <stdio.h>',
             'int main(void) { printf("bad\\n"); return 2; }']),
    atom_concat(Dir, '/exit_expected.txt', ExitExpectedFile),
    fixture(ExitExpectedFile,
            ['# input', '# expected', 'bad', '# exit 2']),
    atom_concat(Dir, '/exit_missing.txt', ExitMissingFile),
    fixture(ExitMissingFile, ['# input', '# expected', 'bad']),
    check_with_cases(ExitC, ExitExpectedFile, Text10, Exit10),
    check('the checker honors an expected exit', Exit10, 0),
    has('the expected exit passes', 'case(s) pass', Text10),
    check_with_cases(ExitC, ExitMissingFile, Text11, Exit11),
    check('the checker refuses an unexpected exit', Exit11, 1),
    has('the unexpected exit says TESTS FAILED', 'TESTS FAILED', Text11),
    atom_concat(Dir, '/null.c', NullC),
    fixture(NullC,
            ['#include <stdio.h>',
             'int main(void) { int *p = 0; printf("%d\\n", *p); return 0; }']),
    check_analyze(NullC, Text12, Exit12),
    check('the analyzer check fails a null deref', Exit12, 1),
    has('the analyzer check prints the finding',
        'Dereference of null pointer', Text12),
    check_analyze(Good, Text13, Exit13),
    check('the analyzer check passes a clean file', Exit13, 0),
    has('the analyzer check says OK', 'passes the analyzer', Text13),
    check_with_analyze_cases(Good, PassFile, Text14, Exit14),
    check('analyze and cases can both run', Exit14, 0),
    has('analyze with cases passes', 'case(s) pass', Text14),
    atom_concat(Dir, '/missing.c', Missing),
    check_compiles(Missing, Text5, Exit5),
    check('a missing file fails', Exit5, 1),
    has('the missing file names the path', 'cannot read', Text5),
    cocolog_run('-s coding/c/check.pl', Text6, Exit6),
    check('the check usage is an error', Exit6, 1),
    has('the check usage is printed', 'usage:', Text6),
    cocolog_run('-s coding/c/codegen.pl', Text7, Exit7),
    check('the generator usage is an error', Exit7, 1),
    has('the generator usage is printed', 'usage:', Text7).

check_compiles(File, Text, Exit) :-
    format(atom(Args), "-s coding/c/check.pl -- ~w", [File]),
    cocolog_run(Args, Text, Exit).

check_with_cases(File, Cases, Text, Exit) :-
    format(atom(Args), "-s coding/c/check.pl -- ~w --tests ~w", [File, Cases]),
    cocolog_run(Args, Text, Exit).

check_with_cases_flags(File, Cases, Flags, Text, Exit) :-
    format(atom(Args),
           "-s coding/c/check.pl -- ~w --tests ~w --cflags ~w",
           [File, Cases, Flags]),
    cocolog_run(Args, Text, Exit).

check_analyze(File, Text, Exit) :-
    format(atom(Args), "-s coding/c/check.pl -- ~w --analyze", [File]),
    cocolog_run(Args, Text, Exit).

check_with_analyze_cases(File, Cases, Text, Exit) :-
    format(atom(Args),
           "-s coding/c/check.pl -- ~w --analyze --tests ~w",
           [File, Cases]),
    cocolog_run(Args, Text, Exit).

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
