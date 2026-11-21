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
:- use_module('coding/bench/v2/langs.pl',
              [ v2_language_supported/1,
                v2_language_task/1,
                v2_language_spec/3,
                v2_language_verify/4,
                v2_language_runtime/2,
                v2_lang_empty_begin/0,
                v2_lang_note_empty/1,
                v2_lang_empty_list/1,
                v2_lang_verify/7
              ]).
:- use_module('coding/bench/v2/lang_runner.pl',
              [ v2_lang_run/7,
                v2_lang_selection/8,
                v2_lang_arm_notes/2 ]).

:- dynamic v2test_seen_spec/1.
:- use_module('coding/bench/v2/lang_gen.pl',
              [ v2_lang_strip_fence/2,
                v2_lang_gen_args/7,
                v2_lang_empty_reason/2,
                v2_lang_retry_options/3,
                v2_lang_usage_parts/6
              ]).
:- use_module('coding/cocolog/codegen.pl',
              [ cocolog_skill_text/1 ]).
:- use_module('coding/bench/v2/stats.pl',
              [ v2_stats_read_run/3,
                v2_stats_summary/2,
                v2_stats_rate/3,
                v2_stats_bootstrap_rate/6,
                v2_stats_paired_diffs/4,
                v2_stats_bootstrap_diff/6,
                v2_stats_pairs/2
              ]).
:- use_module('coding/bench/v2/reasoning_schema.pl',
              [ v2_reasoning_task/1,
                v2_reasoning_task/5,
                v2_reasoning_form/2,
                v2_reasoning_spec/3,
                v2_reasoning_head/2,
                v2_reasoning_check/0,
                v2_reasoning_case/2,
                v2_reasoning_case_ok/2,
                v2_topo_check/3
              ]).
:- use_module('coding/bench/v2/form_runner.pl',
              [ v2_form_run/4,
                v2_form_pair_cells/4
              ]).
:- use_module('coding/bench/v2/runner.pl',
              [ v2_parse_args/2,
                v2_selection/6,
                v2_permute/4,
                v2_mode_spec/3,
                v2_mode_result/3,
                v2_mode_calls/3,
                v2_mode_effort/2,
                v2_bool/2,
                v2_add_usage/3,
                v2_attempts/12,
                v2_pair_attempts/5,
                v2_pair_run/4,
                v2_pair_summary_values/9,
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
    test_pair,
    test_pair_run,
    test_pair_summary,
    test_stats,
    test_langs,
    test_lang_fences,
    test_lang_gen_args,
    test_lang_context,
    test_cocolog_skill,
    test_lang_run,
    test_lang_ir,
    test_lang_reasoning,
    test_reasoning,
    test_form_run,
    test_keep,
    test_extract_cell,
    test_run_integration,
    checks_done.

%% ---- schema ------------------------------------------------------------

test_schema :-
    section('schema'),
    findall(Task, v2_task_name(Task), Tasks),
    check('the v2 tasks', Tasks,
          [lcs, stable_sort, calculator, btree, btree_debug]),
    yes_no(v2_task_check, All),
    check('every task has repair and held-out cases', All, yes),
    forall(member(Task, Tasks), test_task_split(Task)),
    test_lcs_split,
    test_calculator_split,
    test_btree_split,
    test_btree_debug_split,
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

test_btree_split :-
    bench_task(btree, _, Cases),
    v2_task(btree, c, _, Repair, Heldout, _, _),
    length(Cases, N),
    length(Repair, NR),
    length(Heldout, NH),
    check('btree case count', N, 6),
    check('btree repair count', NR, 4),
    check('btree held-out count', NH, 2),
    nth1(3, Cases, AllEqual),
    nth1(6, Cases, DeeperSplit),
    (   Heldout == [AllEqual, DeeperSplit]
    ->  Got = [AllEqual, DeeperSplit]
    ;   Got = Heldout
    ),
    check('btree held-out cases are all-equal and the deeper split', Got,
          [AllEqual, DeeperSplit]).

test_btree_debug_split :-
    bench_task(btree_debug, _, Cases),
    v2_task(btree_debug, c, _, Repair, Heldout, _, _),
    length(Cases, N),
    length(Repair, NR),
    length(Heldout, NH),
    check('btree_debug case count', N, 13),
    check('btree_debug repair count', NR, 11),
    check('btree_debug held-out count', NH, 2),
    nth1(9, Cases, Fifty),
    nth1(13, Cases, Thousand),
    (   Heldout == [Fifty, Thousand]
    ->  Got = [Fifty, Thousand]
    ;   Got = Heldout
    ),
    check('btree_debug held-out cases are n=50 and n=1000', Got,
          [Fifty, Thousand]).

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
    yes_no((forall(member(M, [once, plain, derive, contract, extract, full]),
                   v2_mode_supported(M))),
           ModesOk),
    check('all six modes are supported', ModesOk, yes),
    yes_no(v2_selection([modes([high])], [], _, _, _, _), BadMode),
    check('an unsupported mode is refused', BadMode, no),
    yes_no(v2_selection([tasks([nope])], _, _, _, _, _), BadTask),
    check('an unknown task is refused', BadTask, no),
    bench_task(lcs, Plain0, _),
    once(v2_mode_spec(plain, lcs, Plain)),
    check('plain is the requirement', Plain, Plain0),
    once(v2_mode_spec(once, lcs, Once)),
    check('once is the same requirement', Once, Plain0),
    v2_mode_calls(once, 3, OnceCalls),
    check('once makes one call', OnceCalls, 1),
    v2_mode_calls(plain, 3, PlainCalls),
    check('plain keeps the repair budget', PlainCalls, 3),
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
    yes_no(v2_parse_args(['--paired', '--run'], PairedOpts), PairedParsed),
    check('--paired parses', PairedParsed, yes),
    (   memberchk(paired, PairedOpts), memberchk(run, PairedOpts)
    ->  PairedOk = yes
    ;   PairedOk = PairedOpts
    ),
    check('--paired selects a paired run', PairedOk, yes),
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

%% ---- the paired once/plain experiment ----------------------------------

test_pair :-
    section('paired experiment'),
    once(v2_mode_spec(plain, lcs, Spec)),
    test_pair_first_pass(Spec),
    test_pair_repair_pass(Spec),
    test_pair_repair_fail(Spec),
    test_pair_heldout_fail(Spec).

test_pair_first_pass(Spec) :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(10, 20, 30, 0, 0), none) :-
                lcs_correct(Code))),
    v2_pair_attempts(lcs, 1, Spec, 3, Pair),
    v2_retract_hook,
    Pair = pair(First,
                arm(OnceOutcome, OnceFinal, OncePass1, OnceAttempts,
                    OnceRepair, OnceTotal),
                arm(PlainOutcome, PlainFinal, PlainPass1, PlainAttempts,
                    PlainRepair, PlainTotal),
                Verdict, Shared, PlainRepair),
    check('a first pass is shared', First, ok),
    check('a first pass passes once', OnceOutcome, pass),
    check('a first pass passes plain', PlainOutcome, pass),
    check('a first pass is pass@1', OncePass1, yes),
    check('a first pass is one attempt', OnceAttempts, 1),
    check('a first pass has one attempt in plain', PlainAttempts, 1),
    check('a first pass pays no repair', OnceRepair, usage(0, 0, 0, 0, 0)),
    check('a first pass pays no plain repair', PlainRepair,
          usage(0, 0, 0, 0, 0)),
    check('a first pass counts shared once in each arm', OnceTotal,
          usage(10, 20, 30, 0, 0)),
    check('a first pass has the same plain total', PlainTotal,
          usage(10, 20, 30, 0, 0)),
    check('a first pass is a pair pass', Verdict, both_pass),
    check('a first pass records shared usage', Shared,
          usage(10, 20, 30, 0, 0)),
    check('a first pass has both finals', OnceFinal, yes),
    check('a first pass has both plain finals', PlainFinal, yes),
    check('a first pass is pass@1 in plain', PlainPass1, yes).

test_pair_repair_pass(Spec) :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, Prev, _, Code, U, none) :-
                (   Prev == none
                ->  lcs_wrong(Code), U = usage(1, 1, 1, 0, 0)
                ;   lcs_correct(Code), U = usage(2, 2, 2, 0, 0)
                ))),
    v2_pair_attempts(lcs, 1, Spec, 3, Pair),
    v2_retract_hook,
    Pair = pair(First,
                arm(OnceOutcome, OnceFinal, OncePass1, OnceAttempts,
                    OnceRepair, OnceTotal),
                arm(PlainOutcome, PlainFinal, PlainPass1, PlainAttempts,
                    PlainRepair, PlainTotal),
                Verdict, Shared, PlainRepair),
    check('a failed first attempt is recorded', First, fail),
    check('the once arm fails', OnceOutcome, fail_repair),
    check('the once arm is not pass@1', OncePass1, no),
    check('the once arm stops at one attempt', OnceAttempts, 1),
    check('the once arm pays no repair', OnceRepair, usage(0, 0, 0, 0, 0)),
    check('the once arm pays only the shared call', OnceTotal,
          usage(1, 1, 1, 0, 0)),
    check('the plain arm repairs and passes', PlainOutcome, pass),
    check('the plain arm is not pass@1', PlainPass1, no),
    check('the plain arm takes two attempts', PlainAttempts, 2),
    check('the plain arm pays one repair', PlainRepair,
          usage(2, 2, 2, 0, 0)),
    check('the plain arm total adds the shared call', PlainTotal,
          usage(3, 3, 3, 0, 0)),
    check('the pair is a plain pass', Verdict, plain_pass),
    check('the pair records shared usage', Shared, usage(1, 1, 1, 0, 0)),
    check('the once arm fails final', OnceFinal, no),
    check('the plain arm passes final', PlainFinal, yes).

test_pair_repair_fail(Spec) :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(1, 1, 1, 0, 0), none) :-
                lcs_wrong(Code))),
    v2_pair_attempts(lcs, 1, Spec, 3, Pair),
    v2_retract_hook,
    Pair = pair(_First, _Once,
                arm(PlainOutcome, PlainFinal, PlainPass1, PlainAttempts,
                    PlainRepair, _PlainTotal),
                Verdict, _Shared, PlainRepair),
    check('both arms fail when repair fails', PlainOutcome, fail_repair),
    check('a failed repair is not pass@1', PlainPass1, no),
    check('a failed repair uses every attempt', PlainAttempts, 3),
    check('a failed repair pays two repairs', PlainRepair,
          usage(2, 2, 2, 0, 0)),
    check('a failed repair has no final pass', PlainFinal, no),
    check('a failed repair is a pair failure', Verdict, both_fail).

test_pair_heldout_fail(Spec) :-
    v2_retract_hook,
    assertz((v2_generate_hook(_, _, _, Code, usage(1, 1, 1, 0, 0), none) :-
                lcs_heldout_wrong(Code))),
    v2_pair_attempts(lcs, 1, Spec, 3, Pair),
    v2_retract_hook,
    Pair = pair(First,
                arm(OnceOutcome, OnceFinal, _OncePass1, OnceAttempts,
                    _OnceRepair, _OnceTotal),
                arm(PlainOutcome, PlainFinal, _PlainPass1, PlainAttempts,
                    _PlainRepair, _PlainTotal),
                Verdict, _Shared, _PR),
    check('a held-out failure follows a repair pass', First, ok),
    check('a held-out failure is fail_heldout in once', OnceOutcome,
          fail_heldout),
    check('a held-out failure is fail_heldout in plain', PlainOutcome,
          fail_heldout),
    check('a held-out failure is final in both', OnceFinal, no),
    check('a held-out failure is final in plain', PlainFinal, no),
    check('a held-out failure is one shared attempt', OnceAttempts, 1),
    check('a held-out failure has no plain attempt', PlainAttempts, 1),
    check('a held-out failure is a pair failure', Verdict, both_fail).

test_pair_run :-
    section('paired jsonl'),
    v2_retract_hook,
    assertz((v2_generate_hook(_, Prev, _, Code, U, none) :-
                (   Prev == none
                ->  lcs_wrong(Code), U = usage(1, 1, 1, 0, 0)
                ;   lcs_correct(Code), U = usage(2, 2, 2, 0, 0)
                ))),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    tmp_file(v2_pair_jsonl, OutFile),
    catch(once(v2_pair_run([lcs], 1, 123, file(OutFile))), Ball,
          ( format("paired run error: ~w~n", [Ball]) )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    v2_retract_hook,
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        split_string(Text, "\n", " \t\r", Lines),
        exclude(v2_empty_string, Lines, Kept),
        length(Kept, Count),
        check('a paired run writes two JSON lines', Count, 2),
        (   Kept = [Header, Row]
        ->  true
        ;   Header = '', Row = ''
        ),
        (   sub_atom(Header, _, _, _, '"suite":"v2-paired"')
        ->  H = yes
        ;   H = no
        ),
        check('the paired header names the suite', H, yes),
        (   sub_atom(Row, _, _, _, '"type":"pair"'),
            sub_atom(Row, _, _, _, '"first":"fail"'),
            sub_atom(Row, _, _, _, '"pair_verdict":"plain_pass"'),
            sub_atom(Row, _, _, _, '"plain":{"outcome":"pass"')
        ->  R = yes
        ;   R = no
        ),
        check('the pair row records the plain repair', R, yes),
        catch(delete_file(OutFile), _, true)
    ;   check('the paired run writes a JSONL file', missing, present)
    ).

test_pair_summary :-
    section('paired summary'),
    Pairs = [
        pair(t, 1, ok, yes, yes, 1, 1,
             usage(1, 0, 1, 0, 0), usage(0, 0, 0, 0, 0),
             usage(1, 0, 1, 0, 0), usage(1, 0, 1, 0, 0)),
        pair(t, 2, fail, no, yes, 1, 2,
             usage(2, 0, 2, 0, 0), usage(3, 0, 3, 0, 0),
             usage(2, 0, 2, 0, 0), usage(5, 0, 5, 0, 0)),
        pair(t, 3, fail, no, no, 1, 3,
             usage(4, 0, 4, 0, 0), usage(6, 0, 6, 0, 0),
             usage(4, 0, 4, 0, 0), usage(10, 0, 10, 0, 0))
    ],
    v2_pair_summary_values(Pairs, N, OncePass, PlainPass, PlainOnly,
                           Shared, Repair, OnceTotal, PlainTotal),
    check('a pair summary counts pairs', N, 3),
    check('a pair summary counts once passes', OncePass, 1),
    check('a pair summary counts plain passes', PlainPass, 2),
    check('a pair summary counts plain-only wins', PlainOnly, 1),
    check('a pair summary sums shared usage', Shared,
          usage(7, 0, 7, 0, 0)),
    check('a pair summary sums repair usage', Repair,
          usage(9, 0, 9, 0, 0)),
    check('a pair summary sums once totals', OnceTotal,
          usage(7, 0, 7, 0, 0)),
    check('a pair summary sums plain totals', PlainTotal,
          usage(16, 0, 16, 0, 0)).

%% ---- the language layer ------------------------------------------------

test_langs :-
    section('languages'),
    yes_no((forall(member(L, [c, python, cocolog, swipl]),
                   v2_language_supported(L))),
           Supported),
    check('the four languages are supported', Supported, yes),
    yes_no((forall(member(T, [lcs, stable_sort, calculator]),
                   v2_language_task(T))),
           TasksOk),
    check('the language tasks are declared', TasksOk, yes),
    once(v2_language_spec(python, lcs, PySpec)),
    (   sub_atom(PySpec, _, _, _, 'Write a complete Python 3 program.'),
        sub_atom(PySpec, _, _, _, 'longest common subsequence')
    ->  PySpecOk = yes
    ;   PySpecOk = no
    ),
    check('a Python spec keeps the requirement', PySpecOk, yes),
    once(v2_language_spec(cocolog, lcs, CoSpec)),
    (   sub_atom(CoSpec, _, _, _, 'main/0 reads standard input'),
        sub_atom(CoSpec, _, _, _, 'longest common subsequence')
    ->  CoSpecOk = yes
    ;   CoSpecOk = no
    ),
    check('a cocolog spec names main/0', CoSpecOk, yes),
    once(v2_language_spec(swipl, lcs, SwSpec)),
    (   sub_atom(SwSpec, _, _, _, 'SWI-Prolog'),
        sub_atom(SwSpec, _, _, _, 'longest common subsequence')
    ->  SwSpecOk = yes
    ;   SwSpecOk = no
    ),
    check('a SWI spec names SWI-Prolog', SwSpecOk, yes),
    language_lcs_programs(PyCode, CoCode, SwCode),
    (   v2_test_tool(python3)
    ->  catch(once(v2_language_verify(python, lcs, PyCode, PyV)),
              BallP,
              ( format("python verify error: ~w~n", [BallP]), PyV = error )),
        check('a correct Python LCS passes', PyV, verdict(ok, ok))
    ;   true
    ),
    catch(once(v2_language_verify(cocolog, lcs, CoCode, CoV)),
          BallC,
          ( format("cocolog verify error: ~w~n", [BallC]), CoV = error )),
    check('a correct cocolog LCS passes', CoV, verdict(ok, ok)),
    (   v2_test_tool(swipl)
    ->  catch(once(v2_language_verify(swipl, lcs, SwCode, SwV)),
              BallS,
              ( format("swipl verify error: ~w~n", [BallS]), SwV = error )),
        check('a correct SWI LCS passes', SwV, verdict(ok, ok))
    ;   true
    ).

v2_test_tool(Name) :-
    format(atom(Cmd), 'command -v ~w >/dev/null 2>&1', [Name]),
    catch(proc_run(Cmd, 10000, _, Exit), _, fail),
    Exit == 0.

test_lang_fences :-
    section('language fences'),
    atomic_list_concat(['```prolog', 'main :- writeln(hello).', '```'],
                       '\n', FencedProlog),
    atomic_list_concat(['```', 'main :- writeln(hello).', '```'],
                       '\n', FencedBare),
    atomic_list_concat(['', '```prolog', 'main :- writeln(hello).', '```'],
                       '\n', FencedLeading),
    QuotedFence = 'main :- writeln("```").',
    atomic_list_concat(['main :- writeln(hello).', '', ''], '\n',
                       TrailingLines),
    fence('main :- writeln(hello).', 'main :- writeln(hello).'),
    fence(FencedProlog, 'main :- writeln(hello).'),
    fence(FencedBare, 'main :- writeln(hello).'),
    fence(FencedLeading, 'main :- writeln(hello).'),
    fence(QuotedFence, 'main :- writeln("```").'),
    fence(TrailingLines, 'main :- writeln(hello).'),
    fence('', '').

fence(Reply, Expected) :-
    once(v2_lang_strip_fence(Reply, Code)),
    (   Code == Expected
    ->  format("ok   fence ~q~n", [Reply])
    ;   format("FAIL fence ~q: ~q (expected ~q)~n", [Reply, Code, Expected]),
        fail
    ).

test_lang_gen_args :-
    section('language child args'),
    once(v2_lang_gen_args(
             ['--out', 'c.py', '--lang', 'python', '--prev', '-',
              '--spec', 's.txt', '--effort', 'none', '--diag', '-'],
             Lang, Spec, Out, Effort, Prev, Diag)),
    check('the child flags are read in any order',
          [Lang, Spec, Out, Effort, Prev, Diag],
          [python, 's.txt', 'c.py', none, '-', '-']),
    (   v2_lang_gen_args(['--lang', 'python'], _, _, _, _, _, _)
    ->  Missing = no
    ;   Missing = yes
    ),
    check('a child with missing flags is refused', Missing, yes),
    test_lang_empty_reply.

%% A reply with no text (reasoning 1.15.1): its stop reason, category and
%% blocks are named, a reply cut at max_tokens is sent with twice the
%% limit, any other as it was, its usage is read like any reply's, and
%% the parent keeps each EMPTY line for the cell's row.
test_lang_empty_reply :-
    Refused = json([content-[], stop_reason-refusal,
                    stop_details-json([type-refusal,
                                       category-reasoning_extraction]),
                    usage-json([input_tokens-4936, output_tokens-0])]),
    v2_lang_empty_reason(Refused, R1),
    check('a refusal names its category and no blocks', R1,
          'stop_reason=refusal category=reasoning_extraction blocks=none'),
    Thought = json([content-[json([type-thinking, thinking-''])],
                    stop_reason-max_tokens,
                    usage-json([input_tokens-10, output_tokens-16000])]),
    v2_lang_empty_reason(Thought, R2),
    check('a reply cut in its thinking names the thinking block', R2,
          'stop_reason=max_tokens category=none blocks=thinking'),
    Opts = [max_tokens(16000), provider(anthropic), reasoning_effort(low)],
    v2_lang_retry_options(Thought, Opts, Opts2),
    check('a reply cut at max_tokens is sent with twice the limit', Opts2,
          [max_tokens(32000), provider(anthropic), reasoning_effort(low)]),
    v2_lang_retry_options(Refused, Opts, Opts3),
    check('a refusal is sent as it was', Opts3, Opts),
    v2_lang_usage_parts(json([input_tokens-4936, output_tokens-0]),
                        P, C, T, Rz, H),
    check('an empty reply''s usage is read', [P, C, T, Rz, H],
          [4936, 0, 4936, 0, 0]),
    v2_lang_empty_begin,
    v2_lang_note_empty('EMPTY stop_reason=refusal category=x blocks=none\nUSAGE 1 2 3 0 0\n'),
    v2_lang_note_empty('USAGE 1 2 3 0 0\n'),
    v2_lang_empty_list(Empties),
    check('the parent keeps each EMPTY line for the row', Empties,
          ['stop_reason=refusal category=x blocks=none']),
    v2_lang_empty_begin.

test_lang_context :-
    section('language diagnostics'),
    atomic_list_concat(['main :- writeln(hello).', 'broken :- 1 +.'], '\n',
                       Bad),
    catch(once(v2_language_verify(cocolog, lcs, Bad, Verdict)),
          Ball,
          ( format("context verify error: ~w~n", [Ball]),
            Verdict = error
          )),
    (   Verdict = verdict(fail(cases([Failure|_])), _),
        sub_atom(Failure, _, _, _, 'The source line 2'),
        sub_atom(Failure, _, _, _, 'broken :- 1 +.'),
        sub_atom(Failure, _, _, _, '^')
    ->  Shown = yes
    ;   format("verdict: ~w~n", [Verdict]),
        Shown = no
    ),
    check('a load failure shows the offending source line', Shown, yes),
    catch(once(v2_language_verify(cocolog, lcs, 'main :- fail.',
                                  SilentVerdict)),
          SilentBall,
          ( format("silent verify error: ~w~n", [SilentBall]),
            SilentVerdict = error
          )),
    (   SilentVerdict = verdict(fail(cases([SilentFailure|_])), _),
        sub_atom(SilentFailure, _, _, _, 'entry goal failed with no stderr'),
        sub_atom(SilentFailure, _, _, _, 'Fail:')
    ->  Traced = yes
    ;   format("silent verdict: ~w~n", [SilentVerdict]),
        Traced = no
    ),
    check('a silent goal failure shows the tracer failures', Traced, yes).

test_cocolog_skill :-
    section('cocolog skill'),
    (   exists_file('coding/cocolog/SKILL.md')
    ->  Exists = yes
    ;   Exists = no
    ),
    check('the cocolog guide is in this repository', Exists, yes),
    unsetenv('COCOLOG_SKILL'),
    catch(once(cocolog_skill_text(Text)),
          Ball,
          ( format("cocolog skill error: ~w~n", [Ball]),
            Text = ''
          )),
    atom_length(Text, Length),
    (   Length > 60000
    ->  Long = yes
    ;   Long = no
    ),
    check('the generator reads the full guide', Long, yes),
    (   sub_atom(Text, _, _, _, 'SKILL — working in cocolog')
    ->  Guide = yes
    ;   Guide = no
    ),
    check('the copied guide keeps the language guide', Guide, yes),
    (   sub_atom(Text, _, _, _, 'char_code/2'),
        sub_atom(Text, _, _, _, 'one-character atoms'),
        sub_atom(Text, _, _, _, 'never add a quote after it'),
        sub_atom(Text, _, _, _, 'number_codes/2'),
        sub_atom(Text, _, _, _, 'skip_spaces([], [])'),
        sub_atom(Text, _, _, _, 'skip_spaces(List, List)'),
        sub_atom(Text, _, _, _, 'recurses on the tail'),
        sub_atom(Text, _, _, _, 'The digit collector ends'),
        sub_atom(Text, _, _, _, 'already defines'),
        sub_atom(Text, _, _, _, 'Transpiling Python to cocolog'),
        sub_atom(Text, _, _, _, 'singleton variable'),
        sub_atom(Text, _, _, _, 'Worked example: BFS from Python'),
        sub_atom(Text, _, _, _, 'A table built one row at a time'),
        sub_atom(Text, _, _, _, 'lcs_cells'),
        sub_atom(Text, _, _, _,
                 'A worked row table for the longest common subsequence')
    ->  Added = yes
    ;   Added = no
    ),
    check('the copied guide has the benchmark section', Added, yes).

test_lang_run :-
    section('language jsonl'),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    language_lcs_programs(PyCode, _, _),
    assertz((v2_language_generate_hook(python, _, _, Code,
                                       usage(10, 20, 30, 0, 0), none) :-
                Code = PyCode)),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    tmp_file(v2_lang_keep, KeepRoot),
    make_directory(KeepRoot),
    v2_keep_set(KeepRoot),
    tmp_file(v2_lang_jsonl, OutFile),
    catch(once(v2_lang_run([lcs], [python], [plain], none, 1, 123,
                           file(OutFile))), Ball,
          ( format("language run error: ~w~n", [Ball]) )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    v2_keep_set(none),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        split_string(Text, "\n", " \t\r", Lines),
        exclude(v2_empty_string, Lines, Kept),
        length(Kept, Count),
        check('a language run writes two JSON lines', Count, 2),
        (   Kept = [Header, Row]
        ->  true
        ;   Header = '', Row = ''
        ),
        (   sub_atom(Header, _, _, _, '"suite":"v2-lang"')
        ->  H = yes
        ;   H = no
        ),
        check('the language header names the suite', H, yes),
        (   sub_atom(Row, _, _, _, '"language":"python"'),
            sub_atom(Row, _, _, _, '"outcome":"pass"')
        ->  R = yes
        ;   R = no
        ),
        check('the language row records a Python pass', R, yes),
        catch(delete_file(OutFile), _, true)
    ;   check('the language run writes a JSONL file', missing, present)
    ),
    format(atom(KeptCode), '~s/lcs/python/trial-1/attempt-1-code.py',
           [KeepRoot]),
    (   exists_file(KeptCode),
        v2test_read_atom(KeptCode, KeptText),
        sub_atom(KeptText, _, _, _, 'import sys')
    ->  K = yes
    ;   K = no
    ),
    check('a language attempt keeps the code with its extension', K, yes),
    catch(c_clean_dir(KeepRoot), _, true).

%% The ir arm: the note the translation phase wrote goes after the
%% requirement, the plain arm's requirement is the language's as it was,
%% each row names its arm, and an arm with no note is refused before any
%% call. The generator is the test seam, so no model is called.
test_lang_ir :-
    section('language ir arm'),
    yes_no(v2_language_task(mvccs_acid), Hard),
    check('mvccs_acid is a language task', Hard, yes),
    (   v2_lang_selection([], DefTasks, _, DefArms, _, _, _, _)
    ->  true
    ;   DefTasks = none, DefArms = none
    ),
    check('the default language tasks are still the three, in the plain arm',
          DefTasks-DefArms, [lcs, stable_sort, calculator]-[plain]),
    tmp_file(v2_lang_notes, NotesDir),
    make_directory(NotesDir),
    (   catch(v2_lang_selection([tasks([lcs]), langs([python]), arms([plain, ir]),
                                 ir_notes(NotesDir)], _, _, _, _, _, _, _),
              error(v2_lang_error(no_ir_note, _), _), fail)
    ->  Refused = no
    ;   Refused = yes
    ),
    check('an ir arm with no note is refused before any call', Refused, yes),
    format(atom(NoteFile), '~w/lcs-python.ir', [NotesDir]),
    atom_codes('\n\n# The request in the translator\'s IR\n\n- `s(test)`', NoteCodes),
    write_file_from_codes(NoteFile, NoteCodes),
    retractall(v2test_seen_spec(_)),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    language_lcs_programs(PyCode, _, _),
    assertz((v2_language_generate_hook(python, Spec, _, Code,
                                       usage(10, 20, 30, 0, 0), none) :-
                assertz(v2test_seen_spec(Spec)),
                Code = PyCode)),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    v2_keep_set(none),
    tmp_file(v2_lang_ir_jsonl, OutFile),
    catch(once(v2_lang_run([lcs], [python], [plain, ir], NotesDir, 1, 123,
                           file(OutFile))), Ball,
          ( format("language ir run error: ~w~n", [Ball]) )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    once(v2_language_spec(python, lcs, Base)),
    findall(S, v2test_seen_spec(S), Seen),
    (   msort(Seen, [S1, S2]),
        (   S1 == Base, sub_atom(S2, _, _, _, '`s(test)`')
        ;   S2 == Base, sub_atom(S1, _, _, _, '`s(test)`')
        )
    ->  Specs = yes
    ;   Specs = no
    ),
    check('the ir cell gets the note after the requirement, the plain cell none',
          Specs, yes),
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        (   sub_atom(Text, _, _, _, '"arm":"plain","ir_note_chars":0'),
            sub_atom(Text, _, _, _, '"arm":"ir","ir_note_chars":'),
            sub_atom(Text, _, _, _, '"arms":["plain","ir"]')
        ->  Rows = yes
        ;   Rows = no
        ),
        catch(delete_file(OutFile), _, true)
    ;   Rows = no
    ),
    check('each row names its arm and the note''s length', Rows, yes),
    retractall(v2test_seen_spec(_)),
    catch(c_clean_dir(NotesDir), _, true).

%% The reasoning arms: `reasoning' puts the pre-pass's note after the
%% requirement, `reasoning_ir' the pre-pass's note and then the IR note, in
%% the endpoint's order, and an arm whose note is missing is refused before
%% any call. cocolog_noguide is the cocolog lane's requirement, runtime and
%% verifier with another generator. The generator is the test seam, so no
%% model is called.
test_lang_reasoning :-
    section('language reasoning arms and cocolog_noguide lane'),
    findall(A-K, v2_lang_arm_notes(A, K), Arms),
    check('the arms and the notes each adds', Arms,
          [plain-[], reasoning-[reasoning], reasoning_ir-[reasoning, ir],
           ir-[ir], controlled-[controlled], terms-[terms], concepts-[concepts],
           outline-[outline], alt1-[alt1], alt2-[alt2], alt3-[alt3]]),
    yes_no(v2_language_supported(cocolog_noguide), Lane),
    check('cocolog_noguide is a language lane', Lane, yes),
    once(v2_language_runtime(cocolog_noguide, Runtime)),
    check('cocolog_noguide runs on cocolog', Runtime, cocolog),
    once(v2_language_spec(cocolog, mvccs_acid, SpecG)),
    once(v2_language_spec(cocolog_noguide, mvccs_acid, SpecN)),
    check('cocolog_noguide gets the cocolog requirement', SpecN, SpecG),
    tmp_file(v2_lang_rnotes, NotesDir),
    make_directory(NotesDir),
    format(atom(IrFile), '~w/lcs-python.ir', [NotesDir]),
    atom_codes('\n\n# The request in the translator\'s IR\n\n- `s(test)`', IrCodes),
    write_file_from_codes(IrFile, IrCodes),
    (   catch(v2_lang_selection([tasks([lcs]), langs([python]),
                                 arms([reasoning]), ir_notes(NotesDir)],
                                _, _, _, _, _, _, _),
              error(v2_lang_error(no_reasoning_note, _), _), fail)
    ->  Refused = no
    ;   Refused = yes
    ),
    check('a reasoning arm with no reasoning note is refused', Refused, yes),
    forall(member(L, [python, cocolog_noguide]),
           (   format(atom(RFile), '~w/lcs-~w.reasoning', [NotesDir, L]),
               atom_codes('\n\n# Reasoning pre-pass\n\n- check one', RCodes),
               write_file_from_codes(RFile, RCodes)
           )),
    format(atom(IrFile2), '~w/lcs-cocolog_noguide.ir', [NotesDir]),
    write_file_from_codes(IrFile2, IrCodes),
    retractall(v2test_seen_spec(_)),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    language_lcs_programs(PyCode, CoCode, _),
    assertz((v2_language_generate_hook(Lang, Spec, _, Code,
                                       usage(10, 20, 30, 0, 0), none) :-
                assertz(v2test_seen_spec(Lang-Spec)),
                (   Lang == python
                ->  Code = PyCode
                ;   Code = CoCode
                ))),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    v2_keep_set(none),
    tmp_file(v2_lang_r_jsonl, OutFile),
    catch(once(v2_lang_run([lcs], [python, cocolog_noguide],
                           [plain, reasoning, reasoning_ir], NotesDir, 1, 123,
                           file(OutFile))),
          Ball,
          ( format("language reasoning run error: ~w~n", [Ball]) )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    once(v2_language_spec(python, lcs, Base)),
    findall(S, v2test_seen_spec(python-S), PySpecs0),
    msort(PySpecs0, PySpecs),
    atom_concat(Base, '\n\n# Reasoning pre-pass\n\n- check one', WithR),
    atom_concat(WithR, '\n\n# The request in the translator\'s IR\n\n- `s(test)`', WithRI),
    msort([Base, WithR, WithRI], Want),
    check('plain, reasoning and reasoning_ir get the requirement, its pre-pass, and its pre-pass and IR',
          PySpecs, Want),
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        (   sub_atom(Text, _, _, _, '"arm":"plain","ir_note_chars":0,"reasoning_note_chars":0'),
            sub_atom(Text, _, _, _, '"arm":"reasoning","ir_note_chars":0,"reasoning_note_chars":35'),
            sub_atom(Text, _, _, _, '"arm":"reasoning_ir","ir_note_chars":51,"reasoning_note_chars":35')
        ->  Rows = yes
        ;   Rows = no
        ),
        split_string(Text, "\n", " \t\r", Lines),
        include([Line]>>( sub_string(Line, _, _, _, '"language":"cocolog_noguide"'),
                          sub_string(Line, _, _, _, '"outcome":"pass"') ),
                Lines, Passes),
        length(Passes, NPass),
        catch(delete_file(OutFile), _, true)
    ;   Rows = no, NPass = 0
    ),
    check('each row names the length of each note', Rows, yes),
    check('a cocolog program passes in the cocolog_noguide lane, in each arm',
          NPass, 3),
    retractall(v2test_seen_spec(_)),
    catch(c_clean_dir(NotesDir), _, true).

language_lcs_programs(Python, Cocolog, Swipl) :-
    atomic_list_concat([
        'import sys',
        'a = sys.stdin.readline().rstrip("\\n")',
        'b = sys.stdin.readline().rstrip("\\n")',
        'n, m = len(a), len(b)',
        'dp = [[0] * (m + 1) for _ in range(n + 1)]',
        'for i in range(1, n + 1):',
        '    for j in range(1, m + 1):',
        '        if a[i - 1] == b[j - 1]:',
        '            dp[i][j] = dp[i - 1][j - 1] + 1',
        '        else:',
        '            dp[i][j] = max(dp[i - 1][j], dp[i][j - 1])',
        'print(dp[n][m])'
    ], '\n', Python),
    atomic_list_concat([
        ':- use_module(library(stream)).',
        'main :-',
        '    current_input(S),',
        '    stream_read_line(S, L1),',
        '    stream_read_line(S, L2),',
        '    ( L1 == end_of_file -> A = [] ; A = L1 ),',
        '    ( L2 == end_of_file -> B = [] ; B = L2 ),',
        '    lcs(A, B, N),',
        '    format("~w~n", [N]).',
        'lcs([], _, 0) :- !.',
        'lcs(_, [], 0) :- !.',
        'lcs([X|Xs], [Y|Ys], N) :-',
        '    ( X == Y -> lcs(Xs, Ys, N0), N is N0 + 1',
        '    ; lcs([X|Xs], Ys, N1), lcs(Xs, [Y|Ys], N2), N is max(N1, N2)',
        '    ).'
    ], '\n', Cocolog),
    atomic_list_concat([
        ':- use_module(library(readutil)).',
        'line_codes(end_of_file, []) :- !.',
        'line_codes(S, Cs) :- string_codes(S, Cs).',
        'lcs([], _, 0) :- !.',
        'lcs(_, [], 0) :- !.',
        'lcs([X|Xs], [Y|Ys], N) :-',
        '    ( X =:= Y -> lcs(Xs, Ys, N0), N is N0 + 1',
        '    ; lcs([X|Xs], Ys, N1), lcs(Xs, [Y|Ys], N2), N is max(N1, N2)',
        '    ).',
        'main :-',
        '    read_line_to_string(user_input, A0),',
        '    read_line_to_string(user_input, B0),',
        '    line_codes(A0, A), line_codes(B0, B),',
        '    lcs(A, B, N),',
        '    format("~w~n", [N]).'
    ], '\n', Swipl).

%% ---- Phase 5 -----------------------------------------------------------

test_reasoning :-
    section('reasoning tasks'),
    findall(T, v2_reasoning_task(T), Tasks),
    check('the reasoning tasks', Tasks, [reach, topo, parses]),
    yes_no(v2_reasoning_check, All),
    check('every reasoning task has repair and held-out cases', All, yes),
    yes_no((forall(member(Task, [reach, topo]),
                   forall(v2_reasoning_case(Task, Case),
                          v2_reasoning_case_ok(Task, Case)))),
           CasesOk),
    check('every graph case header matches its edges', CasesOk, yes),
    once(v2_reasoning_spec(imperative, reach, SI)),
    once(v2_reasoning_spec(declarative, reach, SD)),
    once(v2_reasoning_head(imperative, HI)),
    once(v2_reasoning_head(declarative, HD)),
    (   atom_concat(HI, RestI, SI),
        atom_concat(HD, RestD, SD),
        RestI == RestD
    ->  Same = yes
    ;   Same = no
    ),
    check('the two forms share the requirement', Same, yes),
    (   sub_atom(SI, _, _, _, 'Python 3'),
        sub_atom(SD, _, _, _, 'facts, relations and rules')
    ->  Heads = yes
    ;   Heads = no
    ),
    check('the forms name their languages', Heads, yes),
    once(v2_topo_check('3 2\n1 2\n1 3\n', '1 2 3\n', R1)),
    check('a topological order passes', R1, ok),
    once(v2_topo_check('3 2\n1 2\n1 3\n', '2 1 3\n', R2)),
    (   R2 = fail(W2),
        sub_atom(W2, _, _, _, 'not in order')
    ->  Edge = yes
    ;   Edge = no
    ),
    check('a reversed edge fails with its reason', Edge, yes),
    once(v2_topo_check('3 2\n1 2\n1 3\n', '1 2\n', R3)),
    (   R3 = fail(_)
    ->  Perm = yes
    ;   Perm = no
    ),
    check('an incomplete order fails', Perm, yes),
    once(v2_match_case(property(v2_topo_check), '3 2\n1 2\n1 3\n',
                       '1 2 3\n', any, M1, Why1)),
    check('the verifier handles a property match', [M1, Why1], [yes, none]),
    once(v2_match_case(property(v2_topo_check), '3 2\n1 2\n1 3\n',
                       '2 1 3\n', any, M2, Why2)),
    (   M2 == no,
        Why2 \== none
    ->  PropFail = yes
    ;   PropFail = no
    ),
    check('the verifier reports a property failure', PropFail, yes),
    (   v2_test_tool(python3)
    ->  catch(once(v2_lang_verify(python, 'print("1 2 3")',
                                  [case('3 2\n1 2\n1 3\n', any)], [],
                                  property(v2_topo_check), 10000, PV)),
              BallP,
              ( format("python topo verify error: ~w~n", [BallP]),
                PV = error
              )),
        check('the Python verifier accepts a valid topological order', PV,
              verdict(ok, ok))
    ;   true
    ).

test_form_run :-
    section('form run'),
    CellI = cell(reach, imperative, python, 1, yes, yes, 1,
                 usage(1, 1, 2, 0, 0), 1.0, 1, 1, pass),
    CellD = cell(reach, declarative, cocolog, 1, no, no, 1,
                 usage(1, 1, 2, 0, 0), 1.0, 1, 1, fail_repair),
    once(v2_form_pair_cells(CellD, CellI, I2, D2)),
    check('the pair summary finds both orders', [I2, D2], [CellI, CellD]),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    assertz((v2_language_generate_hook(python, _, _, '',
                                       usage(1, 1, 2, 0, 0), none))),
    assertz((v2_language_generate_hook(cocolog, _, _, '',
                                       usage(1, 1, 2, 0, 0), none))),
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-key'),
    tmp_file(v2_form_jsonl, OutFile),
    catch(once(v2_form_run([reach], 1, 123, file(OutFile))), Ball,
          ( format("form run error: ~w~n", [Ball]) )),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    retractall(v2_language_generate_hook(_, _, _, _, _, _)),
    (   exists_file(OutFile)
    ->  read_file_to_codes(OutFile, Codes),
        atom_codes(Text, Codes),
        split_string(Text, "\n", " \t\r", Lines0),
        exclude(v2_empty_string, Lines0, Lines),
        length(Lines, Count),
        check('a form run writes four JSON lines', Count, 4),
        (   member(Header, Lines),
            sub_atom(Header, _, _, _, '"suite":"v2-form"')
        ->  H = yes
        ;   H = no
        ),
        check('the form header names the suite', H, yes),
        (   member(LineI, Lines),
            sub_atom(LineI, _, _, _, '"form":"imperative"'),
            sub_atom(LineI, _, _, _, '"outcome":"fail_compile"')
        ->  C1 = yes
        ;   C1 = no
        ),
        check('the imperative cell is recorded', C1, yes),
        (   member(LineD, Lines),
            sub_atom(LineD, _, _, _, '"form":"declarative"'),
            sub_atom(LineD, _, _, _, '"outcome":"fail_compile"')
        ->  C2 = yes
        ;   C2 = no
        ),
        check('the declarative cell is recorded', C2, yes),
        (   member(Pair, Lines),
            sub_atom(Pair, _, _, _, '"pair":"both_fail"')
        ->  P = yes
        ;   P = no
        ),
        check('the pair records both forms failing', P, yes),
        catch(delete_file(OutFile), _, true)
    ;   check('the form run writes a JSONL file', missing, present)
    ).

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
    v2_stats_pairs([once, plain, derive, contract, extract, full], Pairs),
    check('the report pairs the ablation steps', Pairs,
          [once-plain, plain-derive, derive-extract, extract-contract,
           contract-full]),
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
