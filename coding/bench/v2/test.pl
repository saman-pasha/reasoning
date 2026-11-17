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
:- use_module('coding/bench/v2/stats.pl',
              [ v2_stats_read_run/3,
                v2_stats_summary/2,
                v2_stats_rate/3,
                v2_stats_bootstrap_rate/6,
                v2_stats_paired_diffs/4,
                v2_stats_bootstrap_diff/6,
                v2_stats_pairs/2
              ]).
:- use_module('coding/bench/v2/runner.pl',
              [ v2_parse_args/2,
                v2_selection/6,
                v2_permute/4,
                v2_mode_spec/3,
                v2_mode_result/3,
                v2_mode_effort/2,
                v2_bool/2,
                v2_add_usage/3,
                v2_attempts/12,
                v2_run_cell/9,
                v2_keep_set/1,
                v2_run/5
              ]).

main :-
    test_schema,
    test_policies,
    test_verifier,
    test_runner,
    test_attempts,
    test_stats,
    test_keep,
    test_extract_cell,
    test_run_integration,
    checks_done.

%% ---- schema ------------------------------------------------------------

test_schema :-
    section('schema'),
    findall(Task, v2_task_name(Task), Tasks),
    check('the v2 tasks', Tasks, [lcs, stable_sort, calculator]),
    yes_no(v2_task_check, All),
    check('every task has repair and held-out cases', All, yes),
    forall(member(Task, Tasks), test_task_split(Task)),
    test_lcs_split,
    test_calculator_split,
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

test_calculator_split :-
    bench_task(calculator, _, Cases),
    v2_task(calculator, c, _, Repair, Heldout, _, _),
    length(Cases, N),
    length(Repair, NR),
    length(Heldout, NH),
    check('calculator case count', N, 6),
    check('calculator repair count', NR, 4),
    check('calculator held-out count', NH, 2),
    nth1(1, Cases, Precedence),
    nth1(5, Cases, Association),
    (   Heldout == [Precedence, Association]
    ->  Got = [Precedence, Association]
    ;   Got = Heldout
    ),
    check('calculator held-out cases are precedence and association', Got,
          [Precedence, Association]).

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
    yes_no((forall(member(M, [plain, derive, contract, extract, full]),
                   v2_mode_supported(M))),
           ModesOk),
    check('all five modes are supported', ModesOk, yes),
    yes_no(v2_selection([modes([high])], [], _, _, _, _), BadMode),
    check('an unsupported mode is refused', BadMode, no),
    yes_no(v2_selection([tasks([nope])], _, _, _, _, _), BadTask),
    check('an unknown task is refused', BadTask, no),
    bench_task(lcs, Plain0, _),
    once(v2_mode_spec(plain, lcs, Plain)),
    check('plain is the requirement', Plain, Plain0),
    once(v2_mode_spec(derive, lcs, Derived)),
    (   sub_atom(Derived, _, _, _, 'Obligations derived from the requirement keywords:'),
        sub_atom(Derived, _, _, _, '- Read from standard input')
    ->  DerivedOk = yes
    ;   DerivedOk = no
    ),
    check('derive adds the keyword obligations', DerivedOk, yes),
    once(v2_mode_spec(contract, lcs, Contracted)),
    (   sub_atom(Contracted, _, _, _, 'Obligations derived from a controlled-English contract:'),
        sub_atom(Contracted, _, _, _, '- Read from standard input')
    ->  ContractOk = yes
    ;   ContractOk = no
    ),
    check('contract adds the hand contract', ContractOk, yes),
    once(v2_mode_spec(full, stable_sort, Full)),
    (   sub_atom(Full, _, _, _, 'controlled-English contract and the requirement keywords:'),
        sub_atom(Full, _, _, _, '- A name is one word of letters.'),
        sub_atom(Full, _, _, _, '- A length may be zero')
    ->  FullOk = yes
    ;   FullOk = no
    ),
    check('full adds both obligation sources', FullOk, yes),
    test_extract_mode,
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
    yes_no(v2_parse_args(['--keep', '/tmp/keep'], KeepOpts), KeepParsed),
    check('--keep parses', KeepParsed, yes),
    (   memberchk(keep('/tmp/keep'), KeepOpts)
    ->  KeepOk = yes
    ;   KeepOk = KeepOpts
    ),
    check('--keep carries the directory', KeepOk, yes),
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

test_extract_mode :-
    retractall(v2_extract_hook(_, _, _, _, _)),
    assertz(v2_extract_hook(lcs, _,
                            ['Read the first line.', 'Print the length.'],
                            usage(1, 2, 3, 0, 0), none)),
    once(v2_mode_result(extract, lcs, spec(Full, Usage, Extra, Error))),
    retractall(v2_extract_hook(_, _, _, _, _)),
    check('extract spends one extra call', Extra, 1),
    check('extract carries its usage', Usage, usage(1, 2, 3, 0, 0)),
    check('extract has no error', Error, none),
    (   sub_atom(Full, _, _, _, 'Obligations extracted from the requirement:'),
        sub_atom(Full, _, _, _, '- Read the first line.')
    ->  FullOk = yes
    ;   FullOk = no
    ),
    check('extract adds the extracted obligations', FullOk, yes).

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

%% ---- statistics --------------------------------------------------------

test_stats :-
    section('statistics'),
    stats_cells(Cells),
    v2_stats_summary(Cells, stats(N, Pass1, Final, MeanAttempts, Tokens,
                                  MeanSeconds)),
    check('a summary counts the cells', N, 6),
    check('a summary counts pass@1', Pass1, 5),
    check('a summary counts final passes', Final, 4),
    check('a summary sums tokens', Tokens, 330),
    (   abs(MeanAttempts - 7/6) < 0.0001
    ->  AttemptsOk = yes
    ;   AttemptsOk = MeanAttempts
    ),
    check('a summary means attempts', AttemptsOk, yes),
    (   abs(MeanSeconds - 19/6) < 0.0001
    ->  SecondsOk = yes
    ;   SecondsOk = MeanSeconds
    ),
    check('a summary means seconds', SecondsOk, yes),
    v2_stats_rate(pass1, Cells, Rate1),
    (   abs(Rate1 - 5/6) < 0.0001
    ->  RateOk = yes
    ;   RateOk = Rate1
    ),
    check('a rate is the share of yes', RateOk, yes),
    v2_stats_bootstrap_rate(Cells, pass1, 200, 7, point(Point),
                            ci(Lo, Hi)),
    (   abs(Point - 5/6) < 0.0001,
        Lo >= 0.0,
        Hi =< 1.0,
        Lo =< Hi
    ->  BootOk = yes
    ;   BootOk = point(Point, Lo, Hi)
    ),
    check('a cluster bootstrap is bounded and points at the rate', BootOk,
          yes),
    v2_stats_bootstrap_rate(Cells, pass1, 200, 7, point(Point2),
                            ci(Lo2, Hi2)),
    (   Point2 == Point, Lo2 == Lo, Hi2 == Hi
    ->  Repeat = yes
    ;   Repeat = no
    ),
    check('the bootstrap is seeded', Repeat, yes),
    v2_stats_paired_diffs(Cells, plain, derive, Diffs),
    length(Diffs, NDiffs),
    check('paired differences are one per task', NDiffs, 2),
    v2_stats_bootstrap_diff(Diffs, final, 200, 9, point(DiffPoint),
                            ci(DiffLo, DiffHi)),
    (   abs(DiffPoint - 0.5) < 0.0001,
        DiffLo >= 0.0,
        DiffHi =< 1.0,
        DiffLo =< DiffHi
    ->  DiffOk = yes
    ;   DiffOk = point(DiffPoint, DiffLo, DiffHi)
    ),
    check('a paired difference is the derive gain', DiffOk, yes),
    v2_stats_pairs([plain, derive, contract, extract, full], Pairs),
    check('the report pairs the ablation steps', Pairs,
          [plain-derive, derive-extract, extract-contract, contract-full]),
    test_stats_json.

test_stats_json :-
    Header = json([type-header, run_id-r1, commit-c1, model-m1,
                   trials-1, seed-7, modes-[plain], tasks-[lcs]]),
    Cell = json([type-cell, task-lcs, mode-plain, trial-1,
                 pass_at_1-'@'(true), final_pass-'@'(true), attempts-1,
                 usage-json([prompt-10, completion-20, total-30,
                             reasoning-0, cache_hit-0]),
                 seconds-1.5, outcome-pass, repair-ok, heldout-ok]),
    json_atom(Header, HeaderAtom),
    json_atom(Cell, CellAtom),
    atomic_list_concat([HeaderAtom, '\n', CellAtom, '\n'], Text),
    atom_codes(Text, Codes),
    tmp_file(v2_stats_jsonl, File),
    write_file_from_codes(File, Codes),
    catch(( v2_stats_read_run(File, ReadHeader, Cells) -> Read = ok
          ; Read = failed
          ),
          Ball,
          ( format(atom(Read), 'error(~w)', [Ball])
          )),
    catch(delete_file(File), _, true),
    check('a JSONL run is read', Read, ok),
    (   ReadHeader == Header
    ->  HeaderOk = yes
    ;   HeaderOk = no
    ),
    check('the JSONL header is kept', HeaderOk, yes),
    (   Cells == [cell(lcs, plain, 1, yes, yes, 1,
                       usage(10, 20, 30, 0, 0), 1.5, pass, ok, ok)]
    ->  CellsOk = yes
    ;   CellsOk = Cells
    ),
    check('a JSONL cell is read', CellsOk, yes).

stats_cells([
    cell(lcs, plain, 1, yes, yes, 1, usage(10, 20, 30, 0, 0), 1.0,
         pass, ok, ok),
    cell(lcs, plain, 2, no, no, 2, usage(10, 20, 40, 0, 0), 3.0,
         fail_repair, fail, not_run),
    cell(stable_sort, plain, 1, yes, yes, 1, usage(10, 20, 50, 0, 0), 5.0,
         pass, ok, ok),
    cell(stable_sort, plain, 2, yes, no, 1, usage(10, 20, 60, 0, 0), 7.0,
         fail_heldout, ok, fail),
    cell(lcs, derive, 1, yes, yes, 1, usage(10, 20, 70, 0, 0), 1.0,
         pass, ok, ok),
    cell(stable_sort, derive, 1, yes, yes, 1, usage(10, 20, 80, 0, 0), 2.0,
         pass, ok, ok)
]).

%% ---- kept attempts -----------------------------------------------------

test_keep :-
    section('kept attempts'),
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(10, 20, 30, 0, 0), none) :-
                lcs_correct(Code))),
    tmp_file(v2_keep_test, Root),
    make_directory(Root),
    v2_keep_set(Root),
    catch(once(v2_run_cell(lcs, plain, 1, 1, 123, 'run-keep', 'commit-keep',
                           _Row, _Cell)),
          Ball,
          ( format("keep run error: ~w~n", [Ball]) )),
    v2_keep_set(none),
    v2_retract_hook,
    format(atom(SpecFile), '~s/lcs/plain/trial-1/spec.txt', [Root]),
    format(atom(CodeFile), '~s/lcs/plain/trial-1/attempt-1-code.c', [Root]),
    format(atom(VerdictFile), '~s/lcs/plain/trial-1/attempt-1-verdict.txt',
           [Root]),
    (   exists_file(SpecFile)
    ->  SpecKept = yes
    ;   SpecKept = no
    ),
    check('the spec is kept', SpecKept, yes),
    (   exists_file(CodeFile),
        v2test_read_atom(CodeFile, CodeText),
        sub_atom(CodeText, _, _, _, 'int main')
    ->  CodeKept = yes
    ;   CodeKept = no
    ),
    check('the attempt code is kept', CodeKept, yes),
    (   exists_file(VerdictFile),
        v2test_read_atom(VerdictFile, VerdictText),
        sub_atom(VerdictText, _, _, _, 'usage: 10 20 30 0 0'),
        sub_atom(VerdictText, _, _, _, 'verdict: verdict(ok,ok)')
    ->  VerdictKept = yes
    ;   VerdictKept = no
    ),
    check('the attempt verdict is kept', VerdictKept, yes),
    catch(c_clean_dir(Root), _, true).

v2test_read_atom(File, Atom) :-
    read_file_to_codes(File, Codes),
    atom_codes(Atom, Codes).

%% ---- an extract cell's row ---------------------------------------------

test_extract_cell :-
    section('extract cell'),
    v2_retract_hook,
    retractall(v2_extract_hook(_, _, _, _, _)),
    assertz((v2_generate_hook(_, _, _, Code, usage(10, 20, 30, 0, 0), none) :-
                lcs_correct(Code))),
    assertz(v2_extract_hook(lcs, _, ['Read the first line.'],
                            usage(1, 2, 3, 0, 0), none)),
    catch(once(v2_run_cell(lcs, extract, 1, 1, 123, 'run-x', 'commit-x',
                           Row, _Cell)),
          Ball,
          ( format("extract run error: ~w~n", [Ball]) )),
    v2_retract_hook,
    retractall(v2_extract_hook(_, _, _, _, _)),
    (   Row = json(Pairs)
    ->  true
    ;   Pairs = []
    ),
    v2test_get(extra_calls, Pairs, Extra),
    check('extract records its extra call', Extra, 1),
    v2test_get(calls, Pairs, Calls),
    check('extract counts the extraction call', Calls, 2),
    v2test_get(mode_error, Pairs, ModeError),
    check('extract records no mode error', ModeError, none),
    (   v2test_get(usage, Pairs, json(UsagePairs)),
        v2test_get(total, UsagePairs, Total)
    ->  true
    ;   Total = missing
    ),
    check('extract sums both calls', Total, 33).

v2test_get(Key, Pairs, Value) :-
    memberchk(Key-Value, Pairs),
    !.

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
