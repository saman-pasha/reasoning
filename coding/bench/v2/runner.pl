%% coding/bench/v2/runner.pl -- repeated v2 trials, one JSON line each.
%%
%%     cocolog -s coding/bench/v2/run.pl -- [--plan|--run] [options]
%%
%%     --plan           print the selected tasks and budgets, no model call
%%     --run            run the trials (the default is --plan)
%%     --tasks A,B      tasks to run (default: every v2 task)
%%     --modes A,B      plain, derive, contract, extract, full
%%                      (default: config.pl's modes)
%%     --trials N       trials per task and mode (default: config.pl's 3)
%%     --seed N         order seed (default: config.pl's seed)
%%     --out FILE       JSONL file (default: results/<run id>.jsonl)
%%     --keep DIR       write each cell's spec and each attempt's code,
%%                      usage and verdict under DIR/task/mode/trial-N
%%
%% A cell is one task, mode and trial. Its attempts are the repair loop:
%% the verifier judges the repair cases first and the held-out cases only
%% for the final verdict. A repair failure's diagnostic goes back to the
%% next attempt; a held-out failure does not, because the held-out cases
%% are never shown. Rows are appended as they finish, so an interrupted
%% run keeps every completed cell.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module(library(stream)).
:- use_module(library(json)).
:- use_module(library(llm)).
:- use_module('coding/shell.pl').
:- use_module('coding/bench/tasks.pl').
:- use_module('coding/bench/contract.pl').
:- use_module('coding/bench/v2/config.pl').
:- use_module('coding/bench/v2/schema.pl').
:- use_module('coding/bench/v2/verify.pl').

:- dynamic v2_cell/8.
:- dynamic v2_generate_hook/6.
:- dynamic v2_extract_hook/5.
:- dynamic v2_pair/11.

v2_cli_main :-
    current_prolog_flag(argv, [_|Args]),
    (   catch(v2_parse_args(Args, Opts), _, fail)
    ->  true
    ;   v2_usage,
        halt(2)
    ),
    (   memberchk(help, Opts)
    ->  v2_usage,
        halt(0)
    ;   true
    ),
    (   catch(v2_selection(Opts, Tasks, Modes, Trials, Seed, OutSpec), Ball,
              ( v2_error_text(Ball, Text),
                format("v2 selection error: ~w~n", [Text]),
                halt(2)
              ))
    ->  true
    ;   v2_usage,
        halt(2)
    ),
    (   memberchk(paired, Opts)
    ->  v2_cli_paired(Opts, Tasks, Trials, Seed, OutSpec)
    ;   v2_cli_modes(Opts, Tasks, Modes, Trials, Seed, OutSpec)
    ).

v2_cli_paired(Opts, Tasks, Trials, Seed, OutSpec) :-
    (   memberchk(run, Opts)
    ->  v2_keep_option(Opts),
        v2_pair_run(Tasks, Trials, Seed, OutSpec)
    ;   v2_pair_plan(Tasks, Trials, Seed)
    ).

v2_cli_modes(Opts, Tasks, Modes, Trials, Seed, OutSpec) :-
    (   memberchk(run, Opts)
    ->  v2_keep_option(Opts),
        v2_run(Tasks, Modes, Trials, Seed, OutSpec)
    ;   v2_plan(Tasks, Modes, Trials, Seed)
    ).

v2_keep_option(Opts) :-
    (   memberchk(keep(KeepDir), Opts)
    ->  v2_keep_set(KeepDir)
    ;   v2_keep_set(none)
    ).

%% ---- arguments ---------------------------------------------------------

v2_parse_args([], []).
v2_parse_args(['--plan'|Rest], [plan|Opts]) :-
    v2_parse_args(Rest, Opts).
v2_parse_args(['--run'|Rest], [run|Opts]) :-
    v2_parse_args(Rest, Opts).
v2_parse_args(['--help'|Rest], [help|Opts]) :-
    v2_parse_args(Rest, Opts).
v2_parse_args(['--tasks', Value|Rest], [tasks(Tasks)|Opts]) :-
    v2_csv_atoms(Value, Tasks),
    v2_parse_args(Rest, Opts).
v2_parse_args(['--modes', Value|Rest], [modes(Modes)|Opts]) :-
    v2_csv_atoms(Value, Modes),
    v2_parse_args(Rest, Opts).
v2_parse_args(['--trials', Value|Rest], [trials(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    N >= 1,
    v2_parse_args(Rest, Opts).
v2_parse_args(['--seed', Value|Rest], [seed(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    v2_parse_args(Rest, Opts).
v2_parse_args(['--out', Value|Rest], [out(Value)|Opts]) :-
    v2_parse_args(Rest, Opts).
v2_parse_args(['--keep', Value|Rest], [keep(Value)|Opts]) :-
    v2_parse_args(Rest, Opts).
v2_parse_args(['--paired'|Rest], [paired|Opts]) :-
    v2_parse_args(Rest, Opts).

v2_csv_atoms(Value, Atoms) :-
    split_string(Value, ",", " ", Parts0),
    exclude(v2_empty_string, Parts0, Parts),
    maplist(atom_string, Atoms, Parts),
    Atoms \== [].

v2_selection(Opts, Tasks, Modes, Trials, Seed, OutSpec) :-
    (   memberchk(tasks(Tasks0), Opts)
    ->  Tasks = Tasks0
    ;   findall(Task, v2_task_name(Task), Tasks)
    ),
    Tasks \== [],
    forall(member(Task, Tasks), v2_task_name(Task)),
    (   memberchk(modes(Modes0), Opts)
    ->  Modes = Modes0
    ;   v2_config(modes, Modes)
    ),
    Modes \== [],
    forall(member(Mode, Modes), v2_mode_supported(Mode)),
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

v2_mode_supported(once).
v2_mode_supported(plain).
v2_mode_supported(derive).
v2_mode_supported(contract).
v2_mode_supported(extract).
v2_mode_supported(full).

v2_max_calls(Tasks, MaxCalls) :-
    findall(Max,
            ( member(Task, Tasks),
              v2_task(Task, _, _, _, _, _, budget(Max, _, _))
            ),
            Maxima),
    (   Maxima == []
    ->  MaxCalls = 0
    ;   max_list(Maxima, MaxCalls)
    ).

v2_usage :-
    format("usage: cocolog -s coding/bench/v2/run.pl -- [--plan|--run] [options]~n", []),
    format("  --plan          print tasks and budgets; no model call~n", []),
    format("  --run           run the trials~n", []),
    format("  --tasks A,B     tasks (default: every v2 task)~n", []),
    format("  --modes A,B     plain, derive, contract, extract, full~n", []),
    format("  --trials N      trials per task and mode (default: 3)~n", []),
    format("  --seed N        order seed~n", []),
    format("  --out FILE      JSONL output~n", []),
    format("  --keep DIR      write each attempt's spec, code and verdict~n", []),
    format("  --paired        pair once and plain over one shared first attempt~n", []).

%% ---- plan --------------------------------------------------------------

v2_plan(Tasks, Modes, Trials, Seed) :-
    format("v2 plan (no model calls)~n", []),
    format("task language policy repair heldout max_calls timeout_ms~n", []),
    forall(member(Task, Tasks),
           (   v2_task(Task, Lang, _, Repair, Heldout, Policy,
                       budget(MaxCalls, TimeoutMs, _)),
               length(Repair, NRepair),
               length(Heldout, NHeldout),
               format("~w ~w ~w ~w ~w ~w ~w~n",
                      [Task, Lang, Policy, NRepair, NHeldout,
                       MaxCalls, TimeoutMs])
           )),
    atomic_list_concat(Modes, ',', ModeText),
    format("modes: ~w~ntrials: ~w~nseed: ~w~n", [ModeText, Trials, Seed]).

%% ---- run ---------------------------------------------------------------

v2_run(Tasks, Modes, Trials, Seed, OutSpec) :-
    (   getenv('CODING_ENDPOINT_KEY_ENV', Key),
        Key \== ''
    ->  true
    ;   format("CODING_ENDPOINT_KEY_ENV is not set.~n", []),
        halt(1)
    ),
    get_time(Now),
    Stamp is round(Now * 1000),
    format(atom(RunId), 'v2-~w', [Stamp]),
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
                   suite-v2,
                   run_id-RunId,
                   commit-Commit,
                   started-Stamp,
                   seed-Seed,
                   trials-Trials,
                   model-Model,
                   provider-Provider,
                   temperature-Temperature,
                   tasks-Tasks,
                   modes-Modes]),
    v2_write_row(Stream, Header),
    retractall(v2_cell(_, _, _, _, _, _, _, _)),
    length(Tasks, NTask),
    length(Modes, NMode),
    Cells is NTask * NMode * Trials,
    v2_max_calls(Tasks, MaxCalls),
    format("v2 run ~w~n", [RunId]),
    format("commit ~w, model ~w, ~w trial(s), seed ~w~n",
           [Commit, Model, Trials, Seed]),
    format("~w task(s) x ~w mode(s) x ~w trial(s) = ~w cell(s), at most ~w generator call(s) per cell; extract adds one~n",
           [NTask, NMode, Trials, Cells, MaxCalls]),
    format("jsonl: ~w~n~n", [OutFile]),
    forall(between(1, Trials, Trial),
           v2_run_trial(Trial, Tasks, Modes, Trials, Seed, RunId, Commit,
                        Stream)),
    close(Stream),
    v2_print_summary(Tasks, Modes).

v2_run_trial(Trial, Tasks, Modes, Trials, Seed, RunId, Commit, Stream) :-
    TrialSeed is Seed + Trial * 7919,
    findall(Task-Mode,
            ( member(Task, Tasks),
              member(Mode, Modes)
            ),
            Jobs0),
    v2_permute(Jobs0, TrialSeed, Jobs, _),
    length(Jobs, Count),
    format("===== trial ~w/~w (~w cells) =====~n", [Trial, Trials, Count]),
    v2_run_jobs(Jobs, 1, Trial, TrialSeed, RunId, Commit, Stream).

v2_run_jobs([], _, _, _, _, _, _).
v2_run_jobs([Task-Mode|Jobs], Pos, Trial, TrialSeed, RunId, Commit, Stream) :-
    v2_run_cell(Task, Mode, Trial, Pos, TrialSeed, RunId, Commit,
                Row, Cell),
    v2_write_row(Stream, Row),
    v2_cell_report(Cell),
    Next is Pos + 1,
    v2_run_jobs(Jobs, Next, Trial, TrialSeed, RunId, Commit, Stream).

v2_run_cell(Task, Mode, Trial, Pos, Seed, RunId, Commit, Row, Cell) :-
    v2_task(Task, _, _, _, _, _, budget(TaskCalls, _, _)),
    v2_mode_calls(Mode, TaskCalls, MaxCalls),
    v2_mode_result(Mode, Task, spec(Spec, ModeUsage, ExtraCalls, ModeError)),
    v2_mode_effort(Mode, Effort),
    Usage0 = ModeUsage,
    get_time(T0),
    v2_keep_begin(Task, Mode, Trial, Spec),
    call_cleanup(
        v2_attempts(Task, Spec, Effort, MaxCalls, 1, none, Usage0,
                    Attempts, Usage, Outcome, Repair, Heldout),
        v2_keep_cell_set(none)),
    get_time(T1),
    Seconds is T1 - T0,
    Calls is Attempts + ExtraCalls,
    (   Attempts =:= 1,
        Outcome == pass
    ->  Pass1 = yes
    ;   Pass1 = no
    ),
    (   Outcome == pass
    ->  Final = yes
    ;   Final = no
    ),
    Cell = cell(Task, Mode, Trial, Pass1, Final, Attempts, Usage, Seconds,
                Outcome, Repair, Heldout),
    assertz(v2_cell(Task, Mode, Trial, Pass1, Final, Attempts, Usage,
                    Seconds)),
    v2_config(model, Model),
    v2_config(temperature, Temperature),
    v2_bool(Pass1, Pass1Json),
    v2_bool(Final, FinalJson),
    Usage = usage(P, C, T, R, H),
    Row = json([type-cell,
                suite-v2,
                run_id-RunId,
                commit-Commit,
                task-Task,
                language-c,
                mode-Mode,
                trial-Trial,
                order_position-Pos,
                seed-Seed,
                model-Model,
                temperature-Temperature,
                pass_at_1-Pass1Json,
                final_pass-FinalJson,
                outcome-Outcome,
                attempts-Attempts,
                extra_calls-ExtraCalls,
                calls-Calls,
                mode_error-ModeError,
                repair-Repair,
                heldout-Heldout,
                max_calls-MaxCalls,
                usage-json([prompt-P,
                            completion-C,
                            total-T,
                            reasoning-R,
                            cache_hit-H]),
                seconds-Seconds]).

v2_cell_report(cell(Task, Mode, Trial, Pass1, Final, Attempts, Usage, Seconds,
                    Outcome, Repair, Heldout)) :-
    Usage = usage(_, _, Total, _, _),
    format("~w/~w trial ~w: ~w attempts ~w, repair ~w, heldout ~w, ~w tokens, ~2f s~n",
           [Task, Mode, Trial, Outcome, Attempts, Repair, Heldout, Total,
            Seconds]),
    (   Pass1 == yes
    ->  format("  pass@1~n", [])
    ;   Final == yes
    ->  format("  final pass~n", [])
    ;   true
    ).

%% ---- one cell's attempts -----------------------------------------------

v2_attempts(Task, Spec, Effort, Max, Attempt, Prev, Usage0,
            Attempts, Usage, Outcome, Repair, Heldout) :-
    catch(v2_generate(Spec, Prev, Effort, Code, U, GenError),
          Ball,
          ( Code = '',
            U = usage(0, 0, 0, 0, 0),
            GenError = Ball
          )),
    v2_add_usage(Usage0, U, Usage1),
    (   GenError == none
    ->  catch(v2_verify(Task, Code, Verdict), Ball,
              ( v2_error_atom(Ball, Text),
                Verdict = verdict(fail(verifier(Text)), not_run)
              ))
    ;   v2_error_atom(GenError, Text),
        Verdict = verdict(fail(generator(Text)), not_run)
    ),
    catch(v2_keep_attempt(Attempt, Code, U, GenError, Verdict), _, true),
    (   Verdict = verdict(ok, HeldoutVerdict)
    ->  Attempts = Attempt,
        Usage = Usage1,
        Repair = ok,
        (   HeldoutVerdict == ok
        ->  Outcome = pass,
            Heldout = ok
        ;   Outcome = fail_heldout,
            Heldout = fail
        )
    ;   Verdict = verdict(fail(Why), not_run),
        (   Attempt >= Max
        ->  Attempts = Attempt,
            Usage = Usage1,
            Repair = fail,
            Heldout = not_run,
            v2_fail_outcome(Why, Outcome)
        ;   Next is Attempt + 1,
            v2_why_diag(Why, Diag0),
            v2_limit(Diag0, Diag),
            v2_next_prev(Why, Code, Diag, Prev1),
            v2_attempts(Task, Spec, Effort, Max, Next, Prev1, Usage1,
                        Attempts, Usage, Outcome, Repair, Heldout)
        )
    ).

v2_fail_outcome(compile(_), fail_compile) :- !.
v2_fail_outcome(cases(_), fail_repair) :- !.
v2_fail_outcome(generator(_), fail_generator) :- !.
v2_fail_outcome(verifier(_), fail_verifier).

v2_why_diag(compile(Diag), Diag) :- !.
v2_why_diag(cases(Failures), Text) :-
    !,
    atomic_list_concat(Failures, '\n\n', Text).
v2_why_diag(generator(Text), Text) :- !.
v2_why_diag(verifier(Text), Text).

v2_next_prev(generator(_), _, _, none) :- !.
v2_next_prev(verifier(_), _, _, none) :- !.
v2_next_prev(_, Code, Diag, prev(Code, Diag)).

%% ---- the mode's prompt -------------------------------------------------
%%
%% v2_mode_spec/6 answers spec(Spec, Usage, ExtraCalls, Error). The usage
%% is the extraction call's, spent before any repair attempt; it is the
%% only extra call any mode makes. Modes:
%%
%%     plain     the requirement alone
%%     derive    plus keyword-derived obligations (no model call)
%%     contract  plus the hand controlled-English contract (no model call)
%%     extract   one call writes a controlled-English contract, then its
%%               obligations (ExtraCalls = 1)
%%     full      the hand contract and the keyword derivation together
%%
%% `full' does not call the extractor: the plan's third factor is the
%% guide, and the C codegen's system prompt is the guide in every mode.
%% Its two obligation sources are the ones that cost no extra call.

v2_mode_spec(Mode, Task, Spec) :-
    v2_mode_result(Mode, Task, spec(Spec, _, _, _)).

v2_mode_result(once, Task,
               spec(Spec, usage(0, 0, 0, 0, 0), 0, none)) :-
    bench_task(Task, Spec, _).

v2_mode_result(plain, Task,
               spec(Spec, usage(0, 0, 0, 0, 0), 0, none)) :-
    bench_task(Task, Spec, _).

v2_mode_result(derive, Task,
               spec(Full, usage(0, 0, 0, 0, 0), 0, none)) :-
    bench_task(Task, Spec, _),
    bench_derive_obligations(Task, Spec, Obligations),
    v2_obligations_prompt(
        Spec,
        'Obligations derived from the requirement keywords:',
        Obligations, Full).

v2_mode_result(contract, Task,
               spec(Full, usage(0, 0, 0, 0, 0), 0, none)) :-
    bench_task(Task, Spec, _),
    bench_obligations(Task, Obligations),
    v2_obligations_prompt(
        Spec,
        'Obligations derived from a controlled-English contract:',
        Obligations, Full).

v2_mode_result(extract, Task,
               spec(Full, Usage, 1, Error)) :-
    bench_task(Task, Spec, _),
    v2_extract_contract(Task, Spec, Obligations, Usage, Error),
    (   Obligations == []
    ->  Full = Spec
    ;   v2_obligations_prompt(
            Spec,
            'Obligations extracted from the requirement:',
            Obligations, Full)
    ).

v2_mode_result(full, Task,
               spec(Full, usage(0, 0, 0, 0, 0), 0, none)) :-
    bench_task(Task, Spec, _),
    bench_obligations(Task, Contract),
    bench_derive_obligations(Task, Spec, Derived),
    v2_union(Contract, Derived, Obligations),
    v2_obligations_prompt(
        Spec,
        'Obligations derived from a controlled-English contract and the requirement keywords:',
        Obligations, Full).

v2_obligations_prompt(Spec, Label, Obligations, Full) :-
    bench_obligation_lines(Obligations, Lines),
    atomic_list_concat(Lines, '\n', ObligationsText),
    format(atom(Full), '~s~n~n~w~n~s', [Spec, Label, ObligationsText]).

v2_union([], Second, Second).
v2_union([X|Xs], Second, Union) :-
    (   memberchk(X, Second)
    ->  v2_union(Xs, Second, Union)
    ;   Union = [X|Rest],
        v2_union(Xs, Second, Rest)
    ).

%% One extraction call. The reply is parsed by the same controlled-English
%% reader and vocabulary the contract mode uses; a refused line is dropped.
%% A failed call leaves the plain requirement, charges its usage if the
%% provider reported one, and names the error in the JSONL row.
v2_extract_contract(Task, Spec, Obligations, Usage, Error) :-
    (   v2_extract_hook(Task, Spec, Obligations, Usage, Error)
    ->  !
    ;   v2_extract_contract_call(Task, Spec, Obligations, Usage, Error)
    ).

%% The real extraction is a parent call. v2_extract_hook/5 is a test
%% seam: the runner asserts none, and test.pl proves the extract mode
%% without a provider.
v2_extract_contract_call(Task, Spec, Obligations, Usage, Error) :-
    bench_extract_prompt(Task, Spec, Prompt),
    v2_config(provider, Provider),
    v2_config(model, Model),
    v2_config(base_url, BaseUrl),
    v2_config(temperature, Temperature),
    v2_llm_setup(Provider, BaseUrl),
    catch(
        (   llm_chat(
                [ msg(system,
                      'You rewrite programming requirements into controlled English sentences. Output only sentences of the allowed shapes.'),
                  msg(user, Prompt)
                ],
                [ provider(Provider),
                  model(Model),
                  temperature(Temperature),
                  reasoning_effort(none)
                ],
                Reply),
            v2_llm_usage(Usage0),
            bench_reply_obligations(Reply, _Parsed, Obligations0),
            Usage = Usage0,
            (   Obligations0 == []
            ->  Error = no_obligations
            ;   Error = none
            ),
            Obligations = Obligations0
        ),
        Ball,
        (   Usage = usage(0, 0, 0, 0, 0),
            Obligations = [],
            v2_error_text(Ball, Error)
        )).

v2_llm_setup(Provider, BaseUrl) :-
    retractall(llm_provider(Provider, _, _)),
    assertz(llm_provider(Provider, BaseUrl, 'CODING_ENDPOINT_KEY_ENV')).

v2_llm_usage(usage(P, C, T, R, H)) :-
    (   llm_last_usage(json(Pairs))
    ->  memberchk(prompt_tokens-P, Pairs),
        memberchk(completion_tokens-C, Pairs),
        memberchk(total_tokens-T, Pairs),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R, Details)
        ->  true
        ;   R = 0
        ),
        (   memberchk(prompt_cache_hit_tokens-H, Pairs)
        ->  true
        ;   H = 0
        )
    ;   usage(0, 0, 0, 0, 0) = usage(P, C, T, R, H)
    ).

v2_mode_effort(high, high) :- !.
v2_mode_effort(_, none).

%% once is the no-feedback arm: one generator call and no repair. Every
%% other mode keeps the task's repair budget.
v2_mode_calls(once, _, 1) :- !.
v2_mode_calls(_, Max, Max).

%% ---- one child call ----------------------------------------------------

v2_generate(Spec, Prev, Effort, Code, Usage, Error) :-
    (   v2_generate_hook(Spec, Prev, Effort, Code, Usage, Error)
    ->  !
    ;   v2_generate_child(Spec, Prev, Effort, Code, Usage, Error)
    ).

%% The real call is a child cocolog, so a model reply that defines main/0
%% cannot take the runner's own entry point over. v2_generate_hook/6 is a
%% test seam: the runner asserts none, and test.pl makes the attempt loop
%% prove with fixtures and no provider.
v2_generate_child(Spec, Prev, Effort, Code, Usage, Error) :-
    tmp_file(v2_spec, SpecFile),
    tmp_file(v2_code, CodeFile),
    v2_write_atom(SpecFile, Spec),
    v2_prev_files(Prev, PrevFile, DiagFile),
    current_prolog_flag(executable, Cocolog),
    codegen_shell_quote(Cocolog, QCocolog),
    codegen_shell_quote(SpecFile, QSpec),
    codegen_shell_quote(CodeFile, QCode),
    codegen_shell_quote(PrevFile, QPrev),
    codegen_shell_quote(DiagFile, QDiag),
    format(atom(Cmd),
           '~w query "use_module(''coding/bench/v2/gen.pl''), run" -- ~w ~w ~w ~w ~w 2>&1',
           [QCocolog, QSpec, QCode, Effort, QPrev, QDiag]),
    v2_config(child_timeout_ms, Timeout),
    catch(proc_run(Cmd, Timeout, OutCodes0, Exit0),
          Ball,
          ( OutCodes0 = [],
            Exit0 = -1,
            v2_error_atom(Ball, RunError)
          )),
    (   var(RunError) -> RunError = none ; true ),
    atom_codes(OutText, OutCodes0),
    (   RunError == none,
        Exit0 == 0,
        exists_file(CodeFile)
    ->  read_file_to_codes(CodeFile, CodeCodes),
        atom_codes(Code, CodeCodes),
        (   Code == ''
        ->  Usage = usage(0, 0, 0, 0, 0),
            Error = 'child wrote empty code'
        ;   catch(v2_parse_usage(OutText, Usage), _,
                  Usage = usage(0, 0, 0, 0, 0)),
            Error = none
        )
    ;   Code = '',
        Usage = usage(0, 0, 0, 0, 0),
        v2_limit(OutText, OutTail),
        (   RunError == none
        ->  format(atom(Error0), 'codegen child failed (exit ~w)~n~s',
                   [Exit0, OutTail]),
            Error = Error0
        ;   Error = RunError
        )
    ),
    v2_remove_files([SpecFile, CodeFile, PrevFile, DiagFile]).

v2_prev_files(none, '-', '-') :- !.
v2_prev_files(prev(Code, Diag), PrevFile, DiagFile) :-
    tmp_file(v2_prev, PrevFile),
    tmp_file(v2_diag, DiagFile),
    v2_write_atom(PrevFile, Code),
    v2_write_atom(DiagFile, Diag).

v2_parse_usage(Text, Usage) :-
    (   v2_usage_line(Text, Line)
    ->  v2_usage_parts(Line, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

v2_usage_line(Text, LineAtom) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    sub_atom(LineAtom, 0, 6, _, 'USAGE '),
    !.

v2_usage_parts(Line, usage(P, C, T, R, H)) :-
    split_string(Line, " ", " ", Parts),
    Parts = [_, P0, C0, T0, R0, H0],
    v2_number(P0, P),
    v2_number(C0, C),
    v2_number(T0, T),
    v2_number(R0, R),
    v2_number(H0, H).

v2_number(String, N) :-
    atom_string(A, String),
    atom_number(A, N).

%% ---- small helpers -----------------------------------------------------

v2_add_usage(usage(P0, C0, T0, R0, H0), usage(P, C, T, R, H),
             usage(P1, C1, T1, R1, H1)) :-
    P1 is P0 + P,
    C1 is C0 + C,
    T1 is T0 + T,
    R1 is R0 + R,
    H1 is H0 + H.

v2_bool(yes, '@'(true)).
v2_bool(no, '@'(false)).

v2_write_atom(File, Atom) :-
    atom_codes(Atom, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

v2_limit(Text, Limited) :-
    v2_config(max_diagnostic, Max),
    atom_length(Text, Len),
    (   Len =< Max
    ->  Limited = Text
    ;   sub_atom(Text, 0, Max, _, Limited)
    ).

v2_remove_files([]).
v2_remove_files([File|Files]) :-
    (   File == '-'
    ->  true
    ;   catch(delete_file(File), _, true)
    ),
    v2_remove_files(Files).

%% ---- paired once and plain ---------------------------------------------
%%
%% One first attempt per task and trial, then two arms over the same code:
%% once (stop) and plain (repair with the requirement alone). If the first
%% attempt passes its repair cases, both arms are that result. The shared
%% first attempt's usage is counted in both arms' totals, as the legacy
%% paired.pl does, so the comparison isolates the repair policy instead of
%% first-attempt luck. A pair row nests the two arms and records the
%% shared usage once.

v2_pair_plan(Tasks, Trials, Seed) :-
    length(Tasks, N),
    Pairs is N * Trials,
    format("v2 paired plan (no model calls)~n", []),
    format("task language budget timeout_ms~n", []),
    forall(member(Task, Tasks),
           (   v2_task(Task, Lang, _, _, _, _, budget(MaxCalls, TimeoutMs, _)),
               format("~w ~w ~w ~w~n", [Task, Lang, MaxCalls, TimeoutMs])
           )),
    format("pairs: ~w task(s) x ~w trial(s) = ~w~n", [N, Trials, Pairs]),
    format("arms: once vs plain over one shared first attempt~n", []),
    format("seed: ~w~n", [Seed]).

v2_pair_run(Tasks, Trials, Seed, OutSpec) :-
    (   getenv('CODING_ENDPOINT_KEY_ENV', Key),
        Key \== ''
    ->  true
    ;   format("CODING_ENDPOINT_KEY_ENV is not set.~n", []),
        halt(1)
    ),
    get_time(Now),
    Stamp is round(Now * 1000),
    format(atom(RunId), 'v2-paired-~w', [Stamp]),
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
                   suite-'v2-paired',
                   run_id-RunId,
                   commit-Commit,
                   started-Stamp,
                   seed-Seed,
                   trials-Trials,
                   model-Model,
                   provider-Provider,
                   temperature-Temperature,
                   tasks-Tasks,
                   pair_modes-[once, plain]]),
    v2_write_row(Stream, Header),
    retractall(v2_pair(_, _, _, _, _, _, _, _, _, _, _)),
    length(Tasks, NTask),
    Pairs is NTask * Trials,
    format("v2 paired run ~w~n", [RunId]),
    format("commit ~w, model ~w, ~w pair(s), seed ~w~n",
           [Commit, Model, Pairs, Seed]),
    format("jsonl: ~w~n~n", [OutFile]),
    forall(between(1, Trials, Trial),
           v2_pair_trial(Trial, Tasks, Trials, Seed, RunId, Commit, Stream)),
    close(Stream),
    v2_pair_print_summary(Tasks).

v2_pair_trial(Trial, Tasks, Trials, Seed, RunId, Commit, Stream) :-
    TrialSeed is Seed + Trial * 7919,
    v2_permute(Tasks, TrialSeed, Ordered, _),
    length(Ordered, Count),
    format("===== pair trial ~w/~w (~w tasks) =====~n",
           [Trial, Trials, Count]),
    v2_pair_jobs(Ordered, 1, Trial, TrialSeed, RunId, Commit, Stream).

v2_pair_jobs([], _, _, _, _, _, _).
v2_pair_jobs([Task|Tasks], Pos, Trial, TrialSeed, RunId, Commit, Stream) :-
    v2_pair_cell(Task, Trial, Pos, TrialSeed, RunId, Commit, Stream),
    Next is Pos + 1,
    v2_pair_jobs(Tasks, Next, Trial, TrialSeed, RunId, Commit, Stream).

v2_pair_cell(Task, Trial, Pos, Seed, RunId, Commit, Stream) :-
    v2_task(Task, _, _, _, _, _, budget(MaxCalls, _, _)),
    v2_mode_result(plain, Task, spec(Spec, _, _, _)),
    get_time(T0),
    v2_keep_begin(Task, paired, Trial, Spec),
    call_cleanup(
        v2_pair_attempts(Task, Trial, Spec, MaxCalls, Pair),
        v2_keep_cell_set(none)),
    get_time(T1),
    Seconds is T1 - T0,
    Pair = pair(First, Once, Plain, PairVerdict, SharedUsage, PlainRepair),
    Once = arm(OnceOutcome, OnceFinal, OncePass1, OnceAttempts,
               OnceRepair, OnceTotal),
    Plain = arm(PlainOutcome, PlainFinal, PlainPass1, PlainAttempts,
                PlainRepair, PlainTotal),
    assertz(v2_pair(Task, Trial, First, OnceFinal, PlainFinal,
                    OnceAttempts, PlainAttempts, SharedUsage, PlainRepair,
                    OnceTotal, PlainTotal)),
    v2_pair_bool(OncePass1, OnceP1Json),
    v2_pair_bool(OnceFinal, OnceFJson),
    v2_pair_bool(PlainPass1, PlainP1Json),
    v2_pair_bool(PlainFinal, PlainFJson),
    v2_usage_json(OnceRepair, OnceRepairJson),
    v2_usage_json(OnceTotal, OnceTotalJson),
    v2_usage_json(PlainRepair, PlainRepairJson),
    v2_usage_json(PlainTotal, PlainTotalJson),
    v2_usage_json(SharedUsage, SharedJson),
    OnceJson = json([outcome-OnceOutcome,
                     pass_at_1-OnceP1Json,
                     final_pass-OnceFJson,
                     attempts-OnceAttempts,
                     repair_usage-OnceRepairJson,
                     total_usage-OnceTotalJson]),
    PlainJson = json([outcome-PlainOutcome,
                      pass_at_1-PlainP1Json,
                      final_pass-PlainFJson,
                      attempts-PlainAttempts,
                      repair_usage-PlainRepairJson,
                      total_usage-PlainTotalJson]),
    v2_config(model, Model),
    v2_config(temperature, Temperature),
    Row = json([type-pair,
                suite-'v2-paired',
                run_id-RunId,
                commit-Commit,
                task-Task,
                trial-Trial,
                order_position-Pos,
                seed-Seed,
                model-Model,
                temperature-Temperature,
                first-First,
                pair_verdict-PairVerdict,
                shared_usage-SharedJson,
                once-OnceJson,
                plain-PlainJson,
                seconds-Seconds]),
    v2_write_row(Stream, Row),
    v2_pair_report_cell(Task, Trial, First, PairVerdict, Once, Plain,
                        SharedUsage, Seconds).

v2_pair_attempts(Task, _Trial, Spec, MaxCalls,
                 pair(First, Once, Plain, PairVerdict, U1, PlainRepair)) :-
    catch(v2_generate(Spec, none, none, Code1, U1, E1),
          Ball,
          ( Code1 = '',
            U1 = usage(0, 0, 0, 0, 0),
            E1 = Ball
          )),
    (   E1 == none
    ->  catch(v2_verify(Task, Code1, V1), Ball1,
              ( v2_error_atom(Ball1, Text1),
                V1 = verdict(fail(verifier(Text1)), not_run)
              ))
    ;   v2_error_atom(E1, Text1),
        V1 = verdict(fail(generator(Text1)), not_run)
    ),
    catch(v2_keep_attempt(1, Code1, U1, E1, V1), _, true),
    (   V1 = verdict(ok, Heldout1)
    ->  First = ok,
        (   Heldout1 == ok
        ->  OnceOutcome = pass,
            OnceFinal = yes
        ;   OnceOutcome = fail_heldout,
            OnceFinal = no
        ),
        OncePass1 = OnceFinal,
        Once = arm(OnceOutcome, OnceFinal, OncePass1, 1,
                   usage(0, 0, 0, 0, 0), U1),
        Plain = Once,
        PlainRepair = usage(0, 0, 0, 0, 0),
        (   OnceFinal == yes
        ->  PairVerdict = both_pass
        ;   PairVerdict = both_fail
        )
    ;   V1 = verdict(fail(Why), not_run)
    ->  First = fail,
        v2_why_diag(Why, Diag0),
        v2_limit(Diag0, Diag),
        v2_next_prev(Why, Code1, Diag, Prev),
        v2_attempts(Task, Spec, none, MaxCalls, 2, Prev,
                    usage(0, 0, 0, 0, 0),
                    PlainAttempts, PlainRepair, PlainOutcome, _PlainRepair,
                    _PlainHeldout),
        v2_fail_outcome(Why, OnceOutcome),
        Once = arm(OnceOutcome, no, no, 1, usage(0, 0, 0, 0, 0), U1),
        v2_add_usage(U1, PlainRepair, PlainTotal),
        (   PlainOutcome == pass
        ->  PlainFinal = yes,
            PairVerdict = plain_pass
        ;   PlainFinal = no,
            PairVerdict = both_fail
        ),
        Plain = arm(PlainOutcome, PlainFinal, no, PlainAttempts,
                    PlainRepair, PlainTotal)
    ).

v2_pair_bool(yes, '@'(true)) :- !.
v2_pair_bool(no, '@'(false)) :- !.
v2_pair_bool(V, V).

v2_usage_json(usage(P, C, T, R, H),
              json([prompt-P,
                    completion-C,
                    total-T,
                    reasoning-R,
                    cache_hit-H])).

v2_pair_report_cell(Task, Trial, First, Verdict, Once, Plain, Shared,
                    Seconds) :-
    Once = arm(OnceOutcome, _, _, OnceAttempts, _, OnceTotal),
    Plain = arm(PlainOutcome, _, _, PlainAttempts, _, PlainTotal),
    v2_usage_json(Shared, json(SharedPairs)),
    memberchk(total-SharedTotal, SharedPairs),
    v2_usage_json(OnceTotal, json(OncePairs)),
    memberchk(total-OnceTotalN, OncePairs),
    v2_usage_json(PlainTotal, json(PlainPairs)),
    memberchk(total-PlainTotalN, PlainPairs),
    format("~w pair ~w: first ~w, ~w; once ~w (~w attempts, ~w tokens); plain ~w (~w attempts, ~w tokens), shared ~w, ~2f s~n",
           [Task, Trial, First, Verdict, OnceOutcome, OnceAttempts,
            OnceTotalN, PlainOutcome, PlainAttempts, PlainTotalN,
            SharedTotal, Seconds]).

v2_pair_print_summary(Tasks) :-
    format("~ntask pairs once_pass plain_pass plain_only shared plain_repair once_total plain_total~n",
           []),
    forall(member(Task, Tasks), v2_pair_summary_row(Task)),
    findall(pair(Task, Trial, First, OnceFinal, PlainFinal, OnceAttempts,
                 PlainAttempts, U1, PlainRepair, OnceTotal, PlainTotal),
            (   member(Task, Tasks),
                v2_pair(Task, Trial, First, OnceFinal, PlainFinal,
                        OnceAttempts, PlainAttempts, U1, PlainRepair,
                        OnceTotal, PlainTotal)
            ),
            Pairs),
    (   Pairs == []
    ->  true
    ;   v2_pair_summary_values(Pairs, N, OncePass, PlainPass, PlainOnly,
                              Shared, Repair, OnceTotal, PlainTotal2),
        format("~nall ~w ~w ~w ~w ~w ~w ~w ~w~n",
               [N, OncePass, PlainPass, PlainOnly, Shared, Repair,
                OnceTotal, PlainTotal2])
    ).

v2_pair_summary_row(Task) :-
    findall(pair(Task, Trial, First, OnceFinal, PlainFinal, OnceAttempts,
                 PlainAttempts, U1, PlainRepair, OnceTotal, PlainTotal),
            v2_pair(Task, Trial, First, OnceFinal, PlainFinal,
                    OnceAttempts, PlainAttempts, U1, PlainRepair,
                    OnceTotal, PlainTotal),
            Pairs),
    (   Pairs == []
    ->  true
    ;   v2_pair_summary_values(Pairs, N, OncePass, PlainPass, PlainOnly,
                              Shared, Repair, OnceTotal, PlainTotal2),
        format("~w ~w ~w ~w ~w ~w ~w ~w ~w~n",
               [Task, N, OncePass, PlainPass, PlainOnly, Shared, Repair,
                OnceTotal, PlainTotal2])
    ).

v2_pair_summary_values(Pairs, N, OncePass, PlainPass, PlainOnly,
                       Shared, Repair, OnceTotal, PlainTotal) :-
    length(Pairs, N),
    findall(F, member(pair(_,_,_,F,_,_,_,_,_,_,_), Pairs), OnceFinals),
    v2_count_yes(OnceFinals, OncePass),
    findall(F, member(pair(_,_,_,_,F,_,_,_,_,_,_), Pairs), PlainFinals),
    v2_count_yes(PlainFinals, PlainPass),
    findall(x,
            ( member(pair(_,_,_,OF,PF,_,_,_,_,_,_), Pairs),
              PF == yes,
              OF == no
            ),
            Wins),
    length(Wins, PlainOnly),
    findall(U, member(pair(_,_,_,_,_,_,_,U,_,_,_), Pairs), Shareds),
    findall(U, member(pair(_,_,_,_,_,_,_,_,U,_,_), Pairs), Repairs),
    findall(U, member(pair(_,_,_,_,_,_,_,_,_,U,_), Pairs), OnceTotals),
    findall(U, member(pair(_,_,_,_,_,_,_,_,_,_,U), Pairs), PlainTotals),
    v2_usage_sum(Shareds, Shared),
    v2_usage_sum(Repairs, Repair),
    v2_usage_sum(OnceTotals, OnceTotal),
    v2_usage_sum(PlainTotals, PlainTotal).

v2_usage_sum([], usage(0, 0, 0, 0, 0)).
v2_usage_sum([U|Us], Total) :-
    v2_usage_sum(Us, Rest),
    v2_add_usage(U, Rest, Total).

%% ---- kept attempts -----------------------------------------------------
%%
%% --keep DIR writes the cell's spec once and every attempt's raw code and
%% a verdict/usage text. It is for a diagnostic run, not for the normal
%% matrix: the files are large and the JSONL already carries the counts.
%% A write failure never fails the cell.

v2_keep_set(Dir) :-
    nb_setval('$v2_keep', Dir).

v2_keep_root(Dir) :-
    (   catch(nb_getval('$v2_keep', D), _, fail)
    ->  Dir = D
    ;   Dir = none
    ).

v2_keep_cell_set(Dir) :-
    nb_setval('$v2_keep_cell', Dir).

v2_keep_cell_root(Dir) :-
    (   catch(nb_getval('$v2_keep_cell', D), _, fail),
        D \== none
    ->  Dir = D
    ;   fail
    ).

v2_keep_begin(Task, Mode, Trial, Spec) :-
    (   v2_keep_cell_dir(Task, Mode, Trial, Dir)
    ->  catch(v2_make_dirs(Dir), _, true),
        v2_keep_cell_set(Dir),
        catch(v2_keep_atom_file(Dir, 'spec.txt', Spec), _, true)
    ;   v2_keep_cell_set(none)
    ).

v2_keep_cell_dir(Task, Mode, Trial, Dir) :-
    v2_keep_root(Root),
    Root \== none,
    format(atom(Dir), '~s/~w/~w/trial-~w', [Root, Task, Mode, Trial]).

v2_keep_attempt(Attempt, Code, usage(P, C, T, R, H), GenError, Verdict) :-
    (   v2_keep_cell_root(Dir)
    ->  format(atom(CodeName), 'attempt-~w-code.c', [Attempt]),
        (   Code == ''
        ->  true
        ;   catch(v2_keep_atom_file(Dir, CodeName, Code), _, true)
        ),
        format(atom(VerdictName), 'attempt-~w-verdict.txt', [Attempt]),
        format(atom(Text),
               'usage: ~w ~w ~w ~w ~w~ngenerator: ~w~nverdict: ~w~n',
               [P, C, T, R, H, GenError, Verdict]),
        catch(v2_keep_atom_file(Dir, VerdictName, Text), _, true)
    ;   true
    ).

v2_keep_atom_file(Dir, Name, Atom) :-
    format(atom(File), '~s/~w', [Dir, Name]),
    atom_codes(Atom, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

v2_make_dirs(Dir) :-
    exists_directory(Dir),
    !.
v2_make_dirs(Dir) :-
    file_directory_name(Dir, Parent),
    Parent \== Dir,
    v2_make_dirs(Parent),
    (   exists_directory(Dir)
    ->  true
    ;   catch(make_directory(Dir), _, fail)
    ).

v2_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

%% A deterministic Fisher-Yates over a list, so the trial order is seeded
%% and reproduced by the row's seed. Lists are short (tasks x modes). The
%% cuts keep a permutation from leaving choicepoints: a caller asks for one
%% order, and backtracking into it would make the same seed produce a
%% second, longer one.
v2_permute([], S, [], S) :-
    !.
v2_permute(List, S0, [X|Rest], S) :-
    length(List, N),
    v2_rand(S0, S1),
    K is S1 mod N,
    nth0(K, List, X, Remaining),
    !,
    v2_permute(Remaining, S1, Rest, S).

v2_rand(S0, S) :-
    S is (S0 * 1103515245 + 12345) mod 2147483648.

v2_commit(Commit) :-
    catch(proc_run('git rev-parse HEAD', 10000, Codes, Exit),
          _,
          ( Codes = [],
            Exit = -1
          )),
    (   Exit == 0,
        Codes \== []
    ->  atom_codes(Text, Codes),
        split_string(Text, "\n", " \t\r", [Line|_]),
        atom_string(Commit, Line)
    ;   Commit = unknown
    ).

v2_resolve_out(default, RunId, File) :-
    v2_config(results_dir, Dir),
    format(atom(File), '~s/~s.jsonl', [Dir, RunId]).
v2_resolve_out(file(File), _, File).

v2_open_results(File, Stream) :-
    (   file_directory_name(File, Dir),
        Dir \== '',
        Dir \== '.'
    ->  (   exists_directory(Dir)
        ->  true
        ;   catch(make_directory(Dir), _, fail)
        )
    ;   true
    ),
    catch(open(File, write, Stream), _, fail).

v2_write_row(Stream, Row) :-
    json_atom(Row, Atom),
    format(Stream, '~s~n', [Atom]),
    flush_output(Stream).

v2_error_atom(Ball, Text) :-
    v2_error_text(Ball, Text).

v2_error_text(Ball, Text) :-
    (   Ball = error(Formal, _)
    ->  format(atom(Text), '~w', [Formal])
    ;   format(atom(Text), '~w', [Ball])
    ).

%% ---- summary -----------------------------------------------------------

v2_print_summary(Tasks, Modes) :-
    format("~ntask mode trials pass@1 final attempts tokens seconds~n", []),
    forall(member(Task, Tasks),
           forall(member(Mode, Modes),
                  v2_summary_row(Task, Mode))),
    v2_summary_total(Tasks, Modes).

v2_summary_row(Task, Mode) :-
    findall(cell(Trial, P1, Final, Attempts, Total, Seconds),
            (   v2_cell(Task, Mode, Trial, P1, Final, Attempts,
                        usage(_, _, Total, _, _), Seconds)
            ),
            Cells),
    (   Cells == []
    ->  true
    ;   length(Cells, N),
        v2_sum(Cells, P1s, Finals, AttemptsList, Totals, SecondsList),
        v2_count_yes(P1s, P1Sum),
        v2_count_yes(Finals, FinalSum),
        v2_sum(AttemptsList, 0, AttemptsSum),
        v2_sum(Totals, 0, TokenSum),
        v2_sum(SecondsList, 0.0, SecondSum),
        MeanAttempts is AttemptsSum / N,
        MeanSeconds is SecondSum / N,
        format("~w ~w ~w ~w/~w ~w/~w ~2f ~w ~1f~n",
               [Task, Mode, N, P1Sum, N, FinalSum, N, MeanAttempts,
                TokenSum, MeanSeconds])
    ).

v2_sum(Cells, P1s, Finals, Attempts, Totals, Seconds) :-
    findall(P1, member(cell(_, P1, _, _, _, _), Cells), P1s),
    findall(Final, member(cell(_, _, Final, _, _, _), Cells), Finals),
    findall(A, member(cell(_, _, _, A, _, _), Cells), Attempts),
    findall(T, member(cell(_, _, _, _, T, _), Cells), Totals),
    findall(S, member(cell(_, _, _, _, _, S), Cells), Seconds).

v2_sum([], Acc, Acc).
v2_sum([X|Xs], Acc0, Acc) :-
    Acc1 is Acc0 + X,
    v2_sum(Xs, Acc1, Acc).

v2_count_yes(Values, Count) :-
    findall(x, (member(V, Values), V == yes), Yes),
    length(Yes, Count).

v2_summary_total(Tasks, Modes) :-
    findall(cell(Trial, P1, Final, Attempts, Total, Seconds),
            (   member(Task, Tasks),
                member(Mode, Modes),
                v2_cell(Task, Mode, Trial, P1, Final, Attempts,
                        usage(_, _, Total, _, _), Seconds)
            ),
            Cells),
    (   Cells == []
    ->  true
    ;   length(Cells, N),
        v2_sum(Cells, P1s, Finals, Attempts, Totals, Seconds),
        v2_count_yes(P1s, P1Sum),
        v2_count_yes(Finals, FinalSum),
        v2_sum(Attempts, 0, AttemptsSum),
        v2_sum(Totals, 0, TokenSum),
        v2_sum(Seconds, 0.0, SecondSum),
        MeanAttempts is AttemptsSum / N,
        format("~nall: ~w cells, pass@1 ~w/~w, final ~w/~w, ~2f attempts, ~w tokens, ~1f s~n",
               [N, P1Sum, N, FinalSum, N, MeanAttempts, TokenSum, SecondSum])
    ).
