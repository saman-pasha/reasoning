%% coding/bench/v2/test.pl -- the v2 schema and verifier checks.
%%
%%     COCOLOG_LIBRARY="$PWD/..:$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/bench/v2/test.pl
%%
%% No model and no network. The verifier is exercised on four C fixtures:
%% a correct LCS, one wrong on a repair case, one wrong only on a held-out
%% case, and one that does not compile. The runner's option parsing, task
%% selection, mode prompts and trial order are checked without a call.

:- use_module('test/prelude.pl').
:- use_module(library(json)).
:- use_module('coding/bench/v2/schema.pl').
:- use_module('coding/bench/v2/verify.pl').
:- use_module('coding/bench/v2/runner.pl',
              [ v2_parse_args/2,
                v2_selection/6,
                v2_permute/4,
                v2_mode_spec/3,
                v2_mode_effort/2,
                v2_bool/2,
                v2_add_usage/3,
                v2_attempts/12,
                v2_run/5
              ]).

main :-
    test_schema,
    test_policies,
    test_verifier,
    test_runner,
    test_attempts,
    test_run_integration,
    checks_done.

%% ---- schema ------------------------------------------------------------

test_schema :-
    section('schema'),
    findall(Task, v2_task_name(Task), Tasks),
    check('the v2 tasks', Tasks, [lcs, stable_sort, mvccs_acid]),
    yes_no(v2_task_check, All),
    check('every task has repair and held-out cases', All, yes),
    forall(member(Task, Tasks), test_task_split(Task)),
    test_lcs_split,
    test_stable_sort_fix.

test_task_split(Task) :-
    v2_task(Task, c, _, Repair, Heldout, Policy,
            budget(MaxCalls, _, _)),
    length(Repair, NRepair),
    length(Heldout, NHeldout),
    (   NRepair > 0, NHeldout > 0, Policy == exact, MaxCalls >= 1
    ->  Got = ok
    ;   Got = bad
    ),
    format(atom(Label), '~w declares its cases and budget', [Task]),
    check(Label, Got, ok),
    (   forall(member(Case, Heldout), \+ memberchk(Case, Repair))
    ->  Apart = yes
    ;   Apart = no
    ),
    format(atom(Label2), '~w held-out cases are not repair cases', [Task]),
    check(Label2, Apart, yes).

test_lcs_split :-
    bench_task(lcs, _, Cases),
    v2_task(lcs, c, _, Repair, Heldout, _, _),
    length(Cases, N),
    length(Repair, NR),
    length(Heldout, NH),
    check('lcs case count', N, 6),
    check('lcs repair count', NR, 4),
    check('lcs held-out count', NH, 2),
    nth1(4, Cases, Greedy),
    nth1(6, Cases, Empty),
    (   Heldout == [Greedy, Empty]
    ->  Got = [Greedy, Empty]
    ;   Got = Heldout
    ),
    check('lcs held-out cases are the greedy and empty ones', Got,
          [Greedy, Empty]),
    v2_task(lcs, c, _, Repair2, Heldout2, _, _),
    (   Repair2 == Repair, Heldout2 == Heldout
    ->  Deterministic = yes
    ;   Deterministic = no
    ),
    check('the lcs split is deterministic', Deterministic, yes).

%% The legacy case says five records and gives four. v2 keeps the legacy
%% text for the old run and corrects its own copy.
test_stable_sort_fix :-
    bench_task(stable_sort, _, LegacyCases),
    nth1(1, LegacyCases, case(LegacyInput, _)),
    (   sub_atom(LegacyInput, 0, 2, _, '5\n')
    ->  LegacyCount = five
    ;   LegacyCount = LegacyInput
    ),
    check('the legacy stable_sort case still says five', LegacyCount, five),
    v2_task(stable_sort, c, _, Repair, _, _, _),
    nth1(1, Repair, case(RepairInput, _)),
    (   sub_atom(RepairInput, 0, 2, _, '4\n')
    ->  RepairCount = four
    ;   RepairCount = RepairInput
    ),
    check('the v2 stable_sort case says four', RepairCount, four).

%% ---- output policies ---------------------------------------------------

test_policies :-
    section('output policies'),
    v2_norm(exact, '6\n', Exact),
    check('exact accepts one final newline', Exact, '6'),
    v2_norm(exact, '6\r\n', CrLf),
    check('exact accepts a final CRLF', CrLf, '6'),
    yes_no(v2_norm(exact, ' 6', '6'), Leading),
    check('exact refuses a leading space', Leading, no),
    yes_no(v2_norm(exact, '6\n\n', '6'), TwoNewlines),
    check('exact refuses two final newlines', TwoNewlines, no),
    v2_norm(edge_trim, ' 6 \n\n', Edge),
    check('edge_trim trims each line', Edge, '6'),
    v2_norm(token_normalized, 'a  b', Tokens),
    check('token_normalized folds spaces', Tokens, 'a b'),
    v2_norm(token_normalized, 'a\tb', Tabs),
    check('token_normalized folds tabs', Tabs, 'a b').

%% ---- verifier ----------------------------------------------------------

test_verifier :-
    section('verifier'),
    lcs_correct(Good),
    v2_verify(lcs, Good, GoodVerdict),
    check('a correct LCS passes repair and held-out', GoodVerdict,
          verdict(ok, ok)),
    lcs_wrong(RepairWrong),
    v2_verify(lcs, RepairWrong, RepairVerdict),
    (   RepairVerdict = verdict(fail(cases(Failures)), not_run),
        Failures \== []
    ->  Got = repair_failed
    ;   Got = RepairVerdict
    ),
    check('a wrong repair case fails before held-out', Got, repair_failed),
    lcs_heldout_wrong(HeldoutWrong),
    v2_verify(lcs, HeldoutWrong, HeldoutVerdict),
    check('a wrong held-out case fails the final verdict', HeldoutVerdict,
          verdict(ok, fail(heldout))),
    lcs_stderr(StderrWrong),
    v2_verify(lcs, StderrWrong, StderrVerdict),
    (   StderrVerdict = verdict(fail(cases(StderrFailures)), not_run),
        StderrFailures = [StderrFailure|_],
        sub_atom(StderrFailure, _, _, _, 'stderr:')
    ->  Got2 = stderr_failed
    ;   Got2 = StderrVerdict
    ),
    check('writing to stderr fails even with right stdout', Got2,
          stderr_failed),
    v2_verify(lcs, 'int main(void) { this is not C }', CompileVerdict),
    (   CompileVerdict = verdict(fail(compile(Diag)), not_run),
        sub_atom(Diag, _, _, _, 'COMPILE FAILED')
    ->  Got3 = compile_failed
    ;   Got3 = CompileVerdict
    ),
    check('a compile failure is its own verdict', Got3, compile_failed).

%% A correct LCS: the DP table, with an empty second line read as empty.
lcs_correct(Code) :-
    atomic_list_concat([
        '#include <stdio.h>',
        '#include <string.h>',
        'int main(void) {',
        '    char a[128], b[128];',
        '    if (scanf("%127s", a) != 1) a[0] = 0;',
        '    if (scanf("%127s", b) != 1) b[0] = 0;',
        '    int n = (int)strlen(a), m = (int)strlen(b);',
        '    static int d[130][130];',
        '    for (int i = 0; i <= n; i++)',
        '        for (int j = 0; j <= m; j++) {',
        '            if (i == 0 || j == 0) d[i][j] = 0;',
        '            else if (a[i-1] == b[j-1]) d[i][j] = d[i-1][j-1] + 1;',
        '            else d[i][j] = d[i-1][j] > d[i][j-1] ? d[i-1][j] : d[i][j-1];',
        '        }',
        '    printf("%d\\n", d[n][m]);',
        '    return 0;',
        '}'
    ], '\n', Code).

%% A program that answers 0 to every input: the first repair case fails.
lcs_wrong(Code) :-
    atomic_list_concat([
        '#include <stdio.h>',
        'int main(void) {',
        '    printf("0\\n");',
        '    return 0;',
        '}'
    ], '\n', Code).

%% A correct LCS on the repair cases that answers 3 on two long strings:
%% the held-out `aggtab/gxtxayb' case expects 4.
lcs_heldout_wrong(Code) :-
    atomic_list_concat([
        '#include <stdio.h>',
        '#include <string.h>',
        'int main(void) {',
        '    char a[128], b[128];',
        '    if (scanf("%127s", a) != 1) a[0] = 0;',
        '    if (scanf("%127s", b) != 1) b[0] = 0;',
        '    int n = (int)strlen(a), m = (int)strlen(b);',
        '    static int d[130][130];',
        '    for (int i = 0; i <= n; i++)',
        '        for (int j = 0; j <= m; j++) {',
        '            if (i == 0 || j == 0) d[i][j] = 0;',
        '            else if (a[i-1] == b[j-1]) d[i][j] = d[i-1][j-1] + 1;',
        '            else d[i][j] = d[i-1][j] > d[i][j-1] ? d[i-1][j] : d[i][j-1];',
        '        }',
        '    if (n > 5 && m > 5) d[n][m] = 3;',
        '    printf("%d\\n", d[n][m]);',
        '    return 0;',
        '}'
    ], '\n', Code).

%% The correct LCS with a diagnostic on stderr: right stdout is not enough.
lcs_stderr(Code) :-
    lcs_correct(Plain),
    atomic_list_concat(
        [Plain,
         '__attribute__((constructor)) static void noise(void) { fprintf(stderr, "debug\\n"); }'],
        '\n', Code).

%% ---- runner pieces -----------------------------------------------------

test_runner :-
    section('runner'),
    yes_no(v2_parse_args(['--run', '--tasks', 'lcs,stable_sort',
                          '--trials', '2'],
                         Opts),
           Parsed),
    check('arguments parse', Parsed, yes),
    (   memberchk(run, Opts),
        memberchk(tasks([lcs, stable_sort]), Opts),
        memberchk(trials(2), Opts)
    ->  Got = ok
    ;   Got = Opts
    ),
    check('arguments carry the selection', Got, ok),
    yes_no(v2_selection([tasks([lcs]), modes([plain, derive]),
                         trials(2), seed(5), out('/tmp/v2.jsonl')],
                        Tasks, Modes, Trials, Seed, OutSpec),
           Selected),
    check('a selection is accepted', Selected, yes),
    check('selected tasks', Tasks, [lcs]),
    check('selected modes', Modes, [plain, derive]),
    check('selected trials', Trials, 2),
    check('selected seed', Seed, 5),
    check('selected output', OutSpec, file('/tmp/v2.jsonl')),
    yes_no(v2_selection([modes([extract])], [], _, _, _, _), BadMode),
    check('an unsupported mode is refused', BadMode, no),
    yes_no(v2_selection([tasks([nope])], _, _, _, _, _), BadTask),
    check('an unknown task is refused', BadTask, no),
    bench_task(lcs, Plain0, _),
    v2_mode_spec(plain, lcs, Plain),
    check('plain is the requirement', Plain, Plain0),
    v2_mode_spec(derive, lcs, Derived),
    (   sub_atom(Derived, _, _, _, 'Obligations derived from the requirement keywords:'),
        sub_atom(Derived, _, _, _, '- Read from standard input')
    ->  DerivedOk = yes
    ;   DerivedOk = no
    ),
    check('derive adds the keyword obligations', DerivedOk, yes),
    v2_mode_effort(plain, PlainEffort),
    check('plain has no reasoning effort', PlainEffort, none),
    v2_mode_effort(derive, DeriveEffort),
    check('derive has no reasoning effort', DeriveEffort, none),
    v2_mode_effort(high, HighEffort),
    check('high is high', HighEffort, high),
    v2_permute([1, 2, 3, 4, 5], 7, Order1, _),
    v2_permute([1, 2, 3, 4, 5], 7, Order2, _),
    (   Order1 == Order2
    ->  Same = yes
    ;   Same = no
    ),
    check('the trial order is seeded', Same, yes),
    msort(Order1, Sorted),
    check('the trial order keeps every cell', Sorted, [1, 2, 3, 4, 5]),
    v2_bool(yes, True),
    check('yes is JSON true', True, '@'(true)),
    v2_add_usage(usage(1, 2, 3, 4, 5), usage(10, 20, 30, 40, 50), Sum),
    check('usage adds', Sum, usage(11, 22, 33, 44, 55)),
    json_atom(json([type-header, n-1, b-'@'(true)]), Json),
    (   sub_atom(Json, _, _, _, '"type":"header"'),
        sub_atom(Json, _, _, _, '"b":true')
    ->  JsonOk = yes
    ;   JsonOk = no
    ),
    check('a row is valid JSON', JsonOk, yes).

%% ---- the attempt loop --------------------------------------------------

test_attempts :-
    section('attempt loop'),
    test_attempt_repair_pass,
    test_attempt_repair_fail,
    test_attempt_heldout_fail,
    test_attempt_generator_error.

test_attempt_repair_pass :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, Prev, _, Code, usage(10, 20, 30, 0, 0), none) :-
                (   Prev == none
                ->  lcs_wrong(Code)
                ;   lcs_correct(Code)
                ))),
    v2_attempts(lcs, 'The requirement.', none, 3, 1, none,
                usage(0, 0, 0, 0, 0),
                Attempts, Usage, Outcome, Repair, Heldout),
    v2_retract_hook,
    check('a repair pass takes two attempts', Attempts, 2),
    check('a repaired cell passes', Outcome, pass),
    check('a repaired cell has repair ok', Repair, ok),
    check('a repaired cell has held-out ok', Heldout, ok),
    Usage = usage(_, _, Total, _, _),
    check('a repaired cell sums both usages', Total, 60).

test_attempt_repair_fail :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(1, 2, 3, 0, 0), none) :-
                lcs_wrong(Code))),
    v2_attempts(lcs, 'The requirement.', none, 3, 1, none,
                usage(0, 0, 0, 0, 0),
                Attempts, Usage, Outcome, Repair, Heldout),
    v2_retract_hook,
    check('a failed repair uses every attempt', Attempts, 3),
    check('a failed repair says so', Outcome, fail_repair),
    check('a failed repair has repair fail', Repair, fail),
    check('a failed repair never runs held-out', Heldout, not_run),
    Usage = usage(_, _, Total, _, _),
    check('a failed repair sums every attempt', Total, 9).

test_attempt_heldout_fail :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(1, 1, 2, 0, 0), none) :-
                lcs_heldout_wrong(Code))),
    v2_attempts(lcs, 'The requirement.', none, 3, 1, none,
                usage(0, 0, 0, 0, 0),
                Attempts, Usage, Outcome, Repair, Heldout),
    v2_retract_hook,
    check('a held-out failure stops after repair', Attempts, 1),
    check('a held-out failure is final', Outcome, fail_heldout),
    check('a held-out failure has repair ok', Repair, ok),
    check('a held-out failure marks held-out fail', Heldout, fail),
    Usage = usage(_, _, Total, _, _),
    check('a held-out failure counts one call', Total, 2).

test_attempt_generator_error :-
    v2_retract_hook,
    assertz(v2_generate_hook(_, _, _, '', usage(0, 0, 0, 0, 0), boom)),
    v2_attempts(lcs, 'The requirement.', none, 3, 1, none,
                usage(0, 0, 0, 0, 0),
                Attempts, Usage, Outcome, Repair, Heldout),
    v2_retract_hook,
    check('a generator error uses every attempt', Attempts, 3),
    check('a generator error is its own outcome', Outcome, fail_generator),
    check('a generator error has repair fail', Repair, fail),
    check('a generator error never runs held-out', Heldout, not_run),
    Usage = usage(_, _, Total, _, _),
    check('a generator error has no usage', Total, 0).

v2_retract_hook :-
    retractall(v2_generate_hook(_, _, _, _, _, _)).

%% ---- one whole cell and its JSONL row ---------------------------------

test_run_integration :-
    section('jsonl run'),
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(10, 20, 30, 0, 0), none) :-
                lcs_correct(Code))),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    tmp_file(v2_test_jsonl, OutFile),
    catch(once(v2_run([lcs], [plain], 1, 123, file(OutFile))), Ball,
          ( v2_error_text(Ball, Text),
            format("run error: ~w~n", [Text])
          )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    v2_retract_hook,
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        split_string(Text, "\n", " \t\r", Lines),
        exclude(v2_empty_string, Lines, Kept),
        length(Kept, Count),
        check('the run writes two JSON lines', Count, 2),
        (   Kept = [Header, Cell|_]
        ->  true
        ;   Header = '', Cell = ''
        ),
        (   sub_atom(Header, _, _, _, '"type":"header"')
        ->  H = yes
        ;   H = no
        ),
        check('the first line is the header', H, yes),
        (   sub_atom(Cell, _, _, _, '"type":"cell"'),
            sub_atom(Cell, _, _, _, '"outcome":"pass"'),
            sub_atom(Cell, _, _, _, '"pass_at_1":true')
        ->  C = yes
        ;   C = no
        ),
        check('the cell line records a pass', C, yes),
        catch(delete_file(OutFile), _, true)
    ;   check('the run writes a JSONL file', missing, present)
    ).
