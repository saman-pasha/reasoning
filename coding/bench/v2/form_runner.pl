%% coding/bench/v2/form_runner.pl -- the Phase 5 declarative/imperative pair.
%%
%%     cocolog -s coding/bench/v2/form_run.pl -- [--plan|--doctor|--run] [options]
%%
%%     --tasks A,B     reach, topo, parses (default all)
%%     --trials N      trials per task (default 3)
%%     --seed N        order seed
%%     --out FILE      JSONL output
%%     --keep DIR      write each form/task/trial's attempts
%%
%% Each task runs twice: an imperative Python 3 program and a cocolog
%% program of facts, relations and rules. The two forms share the spec
%% after its first sentence, the cases, the held-out split, the output
%% policy and the budget. The result is per task and form; there is no
%% combined score.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module(library(json)).
:- use_module('coding/shell.pl').
:- use_module('coding/bench/v2/config.pl').
:- use_module('coding/bench/v2/langs.pl').
:- use_module('coding/bench/v2/reasoning_schema.pl').
:- use_module('coding/bench/v2/runner.pl',
              [ v2_permute/4,
                v2_commit/1,
                v2_resolve_out/3,
                v2_open_results/2,
                v2_write_row/2,
                v2_add_usage/3,
                v2_why_diag/2,
                v2_limit/1,
                v2_next_prev/4,
                v2_fail_outcome/2,
                v2_bool/2,
                v2_count_yes/2,
                v2_sum/3,
                v2_error_text/2,
                v2_keep_set/1,
                v2_keep_begin/4,
                v2_keep_attempt_ext/6,
                v2_keep_cell_set/1
              ]).

:- dynamic v2_form_cell/10.
:- dynamic v2_form_pair/5.

v2_form_cli_main :-
    current_prolog_flag(argv, [_|Args]),
    (   catch(v2_form_parse_args(Args, Opts), _, fail)
    ->  true
    ;   v2_form_usage,
        halt(2)
    ),
    (   memberchk(help, Opts)
    ->  v2_form_usage,
        halt(0)
    ;   true
    ),
    (   catch(v2_form_selection(Opts, Tasks, Trials, Seed, OutSpec),
              Ball,
              ( v2_error_text(Ball, Text),
                format("v2 form selection error: ~w~n", [Text]),
                halt(2)
              ))
    ->  true
    ;   v2_form_usage,
        halt(2)
    ),
    (   memberchk(run, Opts)
    ->  v2_form_keep_option(Opts),
        v2_form_run(Tasks, Trials, Seed, OutSpec)
    ;   memberchk(doctor, Opts)
    ->  v2_form_doctor
    ;   v2_form_plan(Tasks, Trials, Seed)
    ).

v2_form_parse_args([], []).
v2_form_parse_args(['--plan'|Rest], [plan|Opts]) :-
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--doctor'|Rest], [doctor|Opts]) :-
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--run'|Rest], [run|Opts]) :-
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--help'|Rest], [help|Opts]) :-
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--tasks', Value|Rest], [tasks(Tasks)|Opts]) :-
    v2_form_csv_atoms(Value, Tasks),
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--trials', Value|Rest], [trials(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    N >= 1,
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--seed', Value|Rest], [seed(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--out', Value|Rest], [out(Value)|Opts]) :-
    v2_form_parse_args(Rest, Opts).
v2_form_parse_args(['--keep', Value|Rest], [keep(Value)|Opts]) :-
    v2_form_parse_args(Rest, Opts).

v2_form_csv_atoms(Value, Atoms) :-
    split_string(Value, ",", " ", Parts0),
    exclude(v2_form_empty_string, Parts0, Parts),
    maplist(atom_string, Atoms, Parts),
    Atoms \== [].

v2_form_selection(Opts, Tasks, Trials, Seed, OutSpec) :-
    (   memberchk(tasks(Tasks0), Opts)
    ->  Tasks = Tasks0
    ;   findall(Task, v2_reasoning_task(Task), Tasks)
    ),
    Tasks \== [],
    forall(member(Task, Tasks), v2_reasoning_task(Task)),
    (   memberchk(trials(Trials), Opts)
    ->  true
    ;   v2_config(trials, Trials)
    ),
    (   memberchk(seed(Seed), Opts)
    ->  true
    ;   v2_config(seed, Seed)
    ),
    (   memberchk(out(File), Opts)
    ->  OutSpec = file(File)
    ;   OutSpec = default
    ).

v2_form_keep_option(Opts) :-
    (   memberchk(keep(KeepDir), Opts)
    ->  v2_keep_set(KeepDir)
    ;   v2_keep_set(none)
    ).

v2_form_usage :-
    format("usage: cocolog -s coding/bench/v2/form_run.pl -- [--plan|--doctor|--run] [options]~n", []),
    format("  --plan          print the grid; no model call~n", []),
    format("  --doctor        print the Python and cocolog toolchains; no model call~n", []),
    format("  --run           run the paired experiment~n", []),
    format("  --tasks A,B     reach, topo, parses~n", []),
    format("  --trials N      trials per task~n", []),
    format("  --seed N        order seed~n", []),
    format("  --out FILE      JSONL output~n", []),
    format("  --keep DIR      write each form/task/trial's attempts~n", []),
    format("forms: imperative Python 3, declarative cocolog~n", []).

v2_form_plan(Tasks, Trials, Seed) :-
    format("v2 form plan (no model calls)~n", []),
    format("task form language repair heldout policy calls timeout~n", []),
    forall(member(Task, Tasks),
           forall(v2_reasoning_form(Form, Lang),
                  (   v2_reasoning_task(Task, Repair, Heldout, Policy,
                                        budget(MaxCalls, Timeout, _)),
                      length(Repair, NR),
                      length(Heldout, NH),
                      format("~w ~w ~w ~w ~w ~w ~w ~w~n",
                             [Task, Form, Lang, NR, NH, Policy, MaxCalls,
                              Timeout])
                  ))),
    length(Tasks, NT),
    Cells is NT * 2 * Trials,
    format("cells: ~w task(s) x 2 form(s) x ~w trial(s) = ~w~n",
           [NT, Trials, Cells]),
    format("seed: ~w~n", [Seed]).

v2_form_doctor :-
    format("v2 form toolchain (no model calls)~n", []),
    v2_form_doctor_line(python),
    v2_form_doctor_line(cocolog),
    (   exists_file('coding/cocolog/SKILL.md')
    ->  format("guide: ok (coding/cocolog/SKILL.md)~n", [])
    ;   format("guide: missing (coding/cocolog/SKILL.md)~n", [])
    ),
    (   catch(v2_reasoning_check, _, fail)
    ->  format("tasks: ok~n", [])
    ;   format("tasks: invalid~n", [])
    ).

v2_form_doctor_line(Lang) :-
    v2_form_tool_command(Lang, Command),
    format(atom(Cmd), '~w 2>&1', [Command]),
    catch(proc_run(Cmd, 10000, Codes, Exit),
          Ball,
          ( Exit = -1,
            v2_error_text(Ball, Error),
            atom_codes(Error, Codes)
          )),
    atom_codes(Text, Codes),
    split_string(Text, "\n", " \t\r", Lines),
    (   member(Line, Lines),
        \+ v2_form_empty_string(Line)
    ->  format("~w: ok (~w)~n", [Lang, Line])
    ;   format("~w: unavailable (exit ~w)~n", [Lang, Exit])
    ).

v2_form_tool_command(python, Cmd) :-
    v2_lang_python(Python),
    codegen_shell_quote(Python, QPython),
    format(atom(Cmd), '~w --version', [QPython]).
v2_form_tool_command(cocolog, Cmd) :-
    current_prolog_flag(executable, Exe),
    codegen_shell_quote(Exe, QExe),
    format(atom(Cmd), '~w --version', [QExe]).

v2_form_run(Tasks, Trials, Seed, OutSpec) :-
    (   getenv('CODING_ENDPOINT_KEY_ENV', Key),
        Key \== ''
    ->  true
    ;   format("CODING_ENDPOINT_KEY_ENV is not set.~n", []),
        halt(1)
    ),
    get_time(Now),
    Stamp is round(Now * 1000),
    format(atom(RunId), 'v2-form-~w', [Stamp]),
    v2_commit(Commit),
    v2_resolve_out(OutSpec, RunId, OutFile),
    (   v2_open_results(OutFile, Stream)
    ->  true
    ;   format("cannot write ~w~n", [OutFile]),
        halt(1)
    ),
    v2_config(model, Model),
    v2_config(provider, Provider),
    v2_config(temperature, Temperature),
    Header = json([type-header,
                   suite-'v2-form',
                   run_id-RunId,
                   commit-Commit,
                   started-Stamp,
                   seed-Seed,
                   trials-Trials,
                   model-Model,
                   provider-Provider,
                   temperature-Temperature,
                   tasks-Tasks,
                   form_imperative-json([language-python]),
                   form_declarative-json([language-cocolog])]),
    v2_write_row(Stream, Header),
    retractall(v2_form_cell(_, _, _, _, _, _, _, _, _, _)),
    retractall(v2_form_pair(_, _, _, _, _)),
    length(Tasks, NT),
    Cells is NT * 2 * Trials,
    format("v2 form run ~w~n", [RunId]),
    format("commit ~w, model ~w, ~w cell(s), seed ~w~n",
           [Commit, Model, Cells, Seed]),
    format("jsonl: ~w~n~n", [OutFile]),
    forall(between(1, Trials, Trial),
           v2_form_trial(Trial, Tasks, Trials, Seed, RunId, Commit, Stream)),
    close(Stream),
    v2_form_print_summary(Tasks).

v2_form_trial(Trial, Tasks0, Trials, Seed, RunId, Commit, Stream) :-
    TrialSeed is Seed + Trial * 7919,
    v2_permute(Tasks0, TrialSeed, Tasks, _),
    length(Tasks, NT),
    Cells is NT * 2,
    format("===== form trial ~w/~w (~w cells) =====~n",
           [Trial, Trials, Cells]),
    v2_form_jobs(Tasks, 1, 1, Trial, TrialSeed, RunId, Commit, Stream).

v2_form_jobs([], _, _, _, _, _, _, _).
v2_form_jobs([Task|Tasks], TaskNo, Pos0, Trial, TrialSeed, RunId, Commit,
             Stream) :-
    FormSeed is TrialSeed + TaskNo * 104729,
    v2_permute([imperative, declarative], FormSeed, [F1, F2], _),
    v2_form_cell_run(Task, F1, Trial, Pos0, TrialSeed, RunId, Commit,
                     Row1, Cell1),
    v2_write_row(Stream, Row1),
    v2_form_cell_report(Cell1),
    Pos1 is Pos0 + 1,
    v2_form_cell_run(Task, F2, Trial, Pos1, TrialSeed, RunId, Commit,
                     Row2, Cell2),
    v2_write_row(Stream, Row2),
    v2_form_cell_report(Cell2),
    Pos2 is Pos1 + 1,
    (   F1 == imperative
    ->  Order = imperative_first
    ;   Order = declarative_first
    ),
    v2_form_pair_row(Task, Trial, Order, TrialSeed, RunId, Commit, Cell1, Cell2,
                     PairRow, PairOutcome),
    v2_write_row(Stream, PairRow),
    v2_form_pair_report(Task, Trial, PairOutcome),
    assertz(v2_form_pair(Task, Trial, Order, Cell1, Cell2)),
    TaskNo1 is TaskNo + 1,
    v2_form_jobs(Tasks, TaskNo1, Pos2, Trial, TrialSeed, RunId, Commit,
                 Stream).

v2_form_cell_run(Task, Form, Trial, Pos, Seed, RunId, Commit, Row, Cell) :-
    v2_reasoning_form(Form, Lang),
    v2_reasoning_task(Task, RepairCases, HeldoutCases, Policy,
                      budget(MaxCalls, TimeoutMs, _)),
    v2_lang_case_timeout(Lang, TimeoutMs, Timeout),
    v2_reasoning_spec(Form, Task, Spec),
    usage(0, 0, 0, 0, 0) = Usage0,
    get_time(T0),
    v2_keep_begin(Task, Form, Trial, Spec),
    call_cleanup(
        v2_form_attempts(Lang, Task, Spec, RepairCases, HeldoutCases, Policy,
                         Timeout, MaxCalls, 1, none, Usage0,
                         Attempts, Usage, Outcome, RepairStatus,
                         HeldoutStatus, Code),
        v2_keep_cell_set(none)),
    get_time(T1),
    Seconds is T1 - T0,
    (   Attempts =:= 1, Outcome == pass
    ->  Pass1 = yes
    ;   Pass1 = no
    ),
    (   Outcome == pass
    ->  Final = yes
    ;   Final = no
    ),
    v2_form_code_size(Code, Lines, Bytes),
    Cell = cell(Task, Form, Lang, Trial, Pass1, Final, Attempts, Usage,
                Seconds, Lines, Bytes, Outcome),
    assertz(v2_form_cell(Task, Form, Trial, Pass1, Final, Attempts, Usage,
                         Seconds, Lines, Bytes)),
    v2_config(model, Model),
    v2_config(temperature, Temperature),
    v2_bool(Pass1, Pass1Json),
    v2_bool(Final, FinalJson),
    Usage = usage(P, C, T, R, H),
    Row = json([type-'form-cell',
                suite-'v2-form',
                run_id-RunId,
                commit-Commit,
                task-Task,
                form-Form,
                language-Lang,
                trial-Trial,
                order_position-Pos,
                seed-Seed,
                model-Model,
                temperature-Temperature,
                pass_at_1-Pass1Json,
                final_pass-FinalJson,
                outcome-Outcome,
                attempts-Attempts,
                repair-RepairStatus,
                heldout-HeldoutStatus,
                max_calls-MaxCalls,
                usage-json([prompt-P,
                            completion-C,
                            total-T,
                            reasoning-R,
                            cache_hit-H]),
                seconds-Seconds,
                code_lines-Lines,
                code_bytes-Bytes]).

v2_form_attempts(Lang, Task, Spec, RepairCases, HeldoutCases, Policy, Timeout,
                 Max, Attempt, Prev, Usage0, Attempts, Usage, Outcome,
                 RepairStatus, HeldoutStatus, Code) :-
    catch(v2_language_generate(Lang, Spec, Prev, Code0, U, GenError),
          Ball,
          ( Code0 = '',
            U = usage(0, 0, 0, 0, 0),
            GenError = Ball
          )),
    v2_add_usage(Usage0, U, Usage1),
    (   GenError == none
    ->  catch(v2_lang_verify(Lang, Code0, RepairCases, HeldoutCases, Policy,
                             Timeout, Verdict),
              Ball1,
              ( v2_error_text(Ball1, Text1),
                Verdict = verdict(fail(verifier(Text1)), not_run)
              ))
    ;   v2_error_text(GenError, Text1),
        Verdict = verdict(fail(generator(Text1)), not_run)
    ),
    (   v2_language_extension(Lang, Ext)
    ->  true
    ;   Ext = txt
    ),
    catch(v2_keep_attempt_ext(Attempt, Ext, Code0, U, GenError, Verdict), _,
          true),
    (   Verdict = verdict(ok, HeldoutVerdict)
    ->  Attempts = Attempt,
        Usage = Usage1,
        Code = Code0,
        RepairStatus = ok,
        (   HeldoutVerdict == ok
        ->  Outcome = pass,
            HeldoutStatus = ok
        ;   Outcome = fail_heldout,
            HeldoutStatus = fail
        )
    ;   Verdict = verdict(fail(Why), not_run),
        (   Attempt >= Max
        ->  Attempts = Attempt,
            Usage = Usage1,
            Code = Code0,
            RepairStatus = fail,
            HeldoutStatus = not_run,
            v2_fail_outcome(Why, Outcome)
        ;   Next is Attempt + 1,
            v2_why_diag(Why, Diag0),
            v2_limit(Diag0, Diag),
            v2_next_prev(Why, Code0, Diag, Prev1),
            v2_form_attempts(Lang, Task, Spec, RepairCases, HeldoutCases,
                             Policy, Timeout, Max, Next, Prev1, Usage1,
                             Attempts, Usage, Outcome, RepairStatus,
                             HeldoutStatus, Code)
        )
    ).

v2_form_pair_row(Task, Trial, Order, Seed, RunId, Commit, Cell1, Cell2,
                 Row, PairOutcome) :-
    Cell1 = cell(_, Form1, _, _, _, Final1, _, _, Seconds1, _, _, _),
    Cell2 = cell(_, _, _, _, _, Final2, _, _, Seconds2, _, _, _),
    (   Form1 == imperative
    ->  Imperative = Cell1, Declarative = Cell2
    ;   Imperative = Cell2, Declarative = Cell1
    ),
    v2_form_pair_outcome(Final1, Final2, Form1, PairOutcome),
    Total is Seconds1 + Seconds2,
    v2_form_cell_json(Imperative, ImperativeJson),
    v2_form_cell_json(Declarative, DeclarativeJson),
    Row = json([type-'form-pair',
                suite-'v2-form',
                run_id-RunId,
                commit-Commit,
                task-Task,
                trial-Trial,
                order-Order,
                seed-Seed,
                imperative-ImperativeJson,
                declarative-DeclarativeJson,
                pair-PairOutcome,
                seconds-Total]).

v2_form_pair_outcome(Final1, Final2, Form1, Outcome) :-
    (   Form1 == imperative
    ->  FinalI = Final1, FinalD = Final2
    ;   FinalI = Final2, FinalD = Final1
    ),
    (   FinalI == yes, FinalD == yes
    ->  Outcome = both_pass
    ;   FinalI == yes
    ->  Outcome = imperative_only
    ;   FinalD == yes
    ->  Outcome = declarative_only
    ;   Outcome = both_fail
    ).

v2_form_cell_json(cell(_, Form, Lang, _, Pass1, Final, Attempts, Usage,
                       Seconds, Lines, Bytes, Outcome),
                  json([form-Form,
                        language-Lang,
                        pass_at_1-Pass1Json,
                        final_pass-FinalJson,
                        outcome-Outcome,
                        attempts-Attempts,
                        usage-json([prompt-P,
                                    completion-C,
                                    total-T,
                                    reasoning-R,
                                    cache_hit-H]),
                        seconds-Seconds,
                        code_lines-Lines,
                        code_bytes-Bytes])) :-
    usage(P, C, T, R, H) = Usage,
    v2_bool(Pass1, Pass1Json),
    v2_bool(Final, FinalJson).

%% ---- reporting ---------------------------------------------------------

v2_form_cell_report(cell(Task, Form, _Lang, Trial, _Pass1, _Final, Attempts,
                         Usage, Seconds, Lines, Bytes, Outcome)) :-
    Usage = usage(_, _, Total, _, _),
    format("~w/~w trial ~w: ~w attempts ~w, ~w tokens, ~w lines, ~w bytes, ~2f s~n",
           [Task, Form, Trial, Outcome, Attempts, Total, Lines, Bytes,
            Seconds]).

v2_form_pair_report(Task, Trial, Outcome) :-
    format("  pair ~w trial ~w: ~w~n", [Task, Trial, Outcome]).

v2_form_print_summary(Tasks) :-
    format("~ntask form trials pass@1 final attempts tokens seconds lines bytes~n", []),
    forall(member(Task, Tasks),
           forall(v2_reasoning_form(Form, _),
                  v2_form_summary_row(Task, Form))),
    format("~npaired, declarative minus imperative~n", []),
    format("task pass@1 final tokens lines~n", []),
    forall(member(Task, Tasks), v2_form_paired_row(Task)),
    v2_form_cost(Tasks).

v2_form_summary_row(Task, Form) :-
    findall(cell(Trial, P1, Final, Attempts, Usage, Seconds, Lines, Bytes),
            v2_form_cell(Task, Form, Trial, P1, Final, Attempts, Usage,
                         Seconds, Lines, Bytes),
            Cells),
    (   Cells == []
    ->  true
    ;   length(Cells, N),
        findall(P, member(cell(_, P, _, _, _, _, _, _), Cells), Ps),
        v2_count_yes(Ps, P1Sum),
        findall(F, member(cell(_, _, F, _, _, _, _, _), Cells), Fs),
        v2_count_yes(Fs, FSum),
        findall(A, member(cell(_, _, _, A, _, _, _, _), Cells), As),
        v2_sum(As, 0, ASum),
        findall(T, member(cell(_, _, _, _, usage(_, _, T, _, _), _, _, _),
                          Cells), Ts),
        v2_sum(Ts, 0, TSum),
        findall(S, member(cell(_, _, _, _, _, S, _, _), Cells), Ss),
        v2_sum(Ss, 0.0, SSum),
        findall(L, member(cell(_, _, _, _, _, _, L, _), Cells), Ls),
        v2_sum(Ls, 0, LSum),
        findall(B, member(cell(_, _, _, _, _, _, _, B), Cells), Bs),
        v2_sum(Bs, 0, BSum),
        MeanA is ASum / N,
        MeanS is SSum / N,
        MeanL is LSum / N,
        MeanB is BSum / N,
        format("~w ~w ~w ~w/~w ~w/~w ~2f ~w ~1f ~1f ~1f~n",
               [Task, Form, N, P1Sum, N, FSum, N, MeanA, TSum, MeanS,
                MeanL, MeanB])
    ).

v2_form_paired_row(Task) :-
    findall(pair(Trial, CellI, CellD),
            (   v2_form_pair(Task, Trial, _, CellI, CellD),
                CellI = cell(_, imperative, _, _, _, _, _, _, _, _, _, _)
            ),
            Pairs),
    (   Pairs == []
    ->  true
    ;   length(Pairs, N),
        v2_form_pair_counts(Pairs, P1I, P1D, FI, FD, TI, TD, LI, LD),
        D1 is P1D - P1I,
        DF is FD - FI,
        DTok is round(TD / N - TI / N),
        DLines is LD / N - LI / N,
        v2_form_signed(D1, S1),
        v2_form_signed(DF, SF),
        format("~w ~w/~w ~w/~w ~w ~1f~n", [Task, S1, N, SF, N, DTok, DLines])
    ).

v2_form_signed(N, S) :-
    (   N >= 0
    ->  format(atom(S), '+~w', [N])
    ;   S = N
    ).

v2_form_pair_counts([], 0, 0, 0, 0, 0, 0, 0, 0).
v2_form_pair_counts([pair(_, CellI, CellD)|Pairs],
                    P1I, P1D, FI, FD, TI, TD, LI, LD) :-
    v2_form_pair_counts(Pairs, P1I0, P1D0, FI0, FD0, TI0, TD0, LI0, LD0),
    CellI = cell(_, _, _, _, PI, FIm, _, usage(_, _, TIx, _, _), _, LIx, _,
                 _),
    CellD = cell(_, _, _, _, PD, FDm, _, usage(_, _, TDx, _, _), _, LDx, _,
                 _),
    (   PI == yes -> P1I is P1I0 + 1 ; P1I = P1I0 ),
    (   PD == yes -> P1D is P1D0 + 1 ; P1D = P1D0 ),
    (   FIm == yes -> FI is FI0 + 1 ; FI = FI0 ),
    (   FDm == yes -> FD is FD0 + 1 ; FD = FD0 ),
    TI is TI0 + TIx,
    TD is TD0 + TDx,
    LI is LI0 + LIx,
    LD is LD0 + LDx.

v2_form_cost(Tasks) :-
    findall(T, ( member(Task, Tasks),
                 v2_form_cell(Task, _, _, _, _, _, usage(_, _, T, _, _), _,
                              _, _) ),
            Ts),
    (   Ts == [] -> true
    ;   v2_sum(Ts, 0, Total),
        format("~ntotal tokens (cost only; no combined score): ~w~n", [Total])
    ).

v2_form_code_size(Code, Lines, Bytes) :-
    atom_length(Code, Bytes),
    atom_codes(Code, Codes),
    (   Codes == []
    ->  Lines = 0
    ;   v2_form_count_lines(Codes, 1, Lines)
    ).

v2_form_count_lines([], N, N).
v2_form_count_lines([10], N, N) :-
    !.
v2_form_count_lines([10|Cs], N, Lines) :-
    !,
    N1 is N + 1,
    v2_form_count_lines(Cs, N1, Lines).
v2_form_count_lines([_|Cs], N, Lines) :-
    v2_form_count_lines(Cs, N, Lines).

v2_form_empty_string(S) :-
    (   string(S) -> string_length(S, 0) ; S == '' ).
