%% coding/bench/v2/lang_runner.pl -- Phase 4 language comparison.
%%
%%     cocolog -s coding/bench/v2/lang_run.pl -- [--plan|--doctor|--run] [options]
%%
%%     --tasks A,B     lcs, stable_sort, calculator (default all)
%%     --langs A,B     c, python, cocolog, swipl (default all)
%%     --trials N      trials per task and language (default 3)
%%     --seed N        order seed
%%     --out FILE      JSONL output
%%     --keep DIR      write each task/language/trial's attempts
%%
%% The arm is plain (the repair loop, no obligations). Specs, cases,
%% held-out split and budget are the same across languages; only the
%% language sentence and each language's normal generator differ.
%% This runner is separate from the C mode matrix so no existing C result
%% changes.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module(library(stream)).
:- use_module(library(json)).
:- use_module('coding/shell.pl').
:- use_module('coding/bench/v2/config.pl').
:- use_module('coding/bench/v2/schema.pl').
:- use_module('coding/bench/v2/langs.pl').
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

:- dynamic v2_lang_cell/8.

v2_lang_cli_main :-
    current_prolog_flag(argv, [_|Args]),
    (   catch(v2_lang_parse_args(Args, Opts), _, fail)
    ->  true
    ;   v2_lang_usage,
        halt(2)
    ),
    (   memberchk(help, Opts)
    ->  v2_lang_usage,
        halt(0)
    ;   true
    ),
    (   catch(v2_lang_selection(Opts, Tasks, Langs, Trials, Seed, OutSpec),
              Ball,
              ( v2_error_text(Ball, Text),
                format("v2 language selection error: ~w~n", [Text]),
                halt(2)
              ))
    ->  true
    ;   v2_lang_usage,
        halt(2)
    ),
    (   memberchk(run, Opts)
    ->  v2_lang_keep_option(Opts),
        v2_lang_run(Tasks, Langs, Trials, Seed, OutSpec)
    ;   memberchk(doctor, Opts)
    ->  v2_lang_doctor(Langs)
    ;   v2_lang_plan(Tasks, Langs, Trials, Seed)
    ).

v2_lang_parse_args([], []).
v2_lang_parse_args(['--plan'|Rest], [plan|Opts]) :-
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--doctor'|Rest], [doctor|Opts]) :-
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--run'|Rest], [run|Opts]) :-
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--help'|Rest], [help|Opts]) :-
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--tasks', Value|Rest], [tasks(Tasks)|Opts]) :-
    v2_lang_csv_atoms(Value, Tasks),
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--langs', Value|Rest], [langs(Langs)|Opts]) :-
    v2_lang_csv_atoms(Value, Langs),
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--trials', Value|Rest], [trials(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    N >= 1,
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--seed', Value|Rest], [seed(N)|Opts]) :-
    atom_number(Value, N),
    integer(N),
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--out', Value|Rest], [out(Value)|Opts]) :-
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--keep', Value|Rest], [keep(Value)|Opts]) :-
    v2_lang_parse_args(Rest, Opts).

v2_lang_csv_atoms(Value, Atoms) :-
    split_string(Value, ",", " ", Parts0),
    exclude(v2_lang_empty_string, Parts0, Parts),
    maplist(atom_string, Atoms, Parts),
    Atoms \== [].

v2_lang_selection(Opts, Tasks, Langs, Trials, Seed, OutSpec) :-
    (   memberchk(tasks(Tasks0), Opts)
    ->  Tasks = Tasks0
    ;   findall(Task, v2_language_task(Task), Tasks)
    ),
    Tasks \== [],
    forall(member(Task, Tasks), v2_language_task(Task)),
    (   memberchk(langs(Langs0), Opts)
    ->  Langs = Langs0
    ;   Langs = [c, python, cocolog, swipl]
    ),
    Langs \== [],
    forall(member(Lang, Langs), v2_language_supported(Lang)),
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

v2_lang_keep_option(Opts) :-
    (   memberchk(keep(KeepDir), Opts)
    ->  v2_keep_set(KeepDir)
    ;   v2_keep_set(none)
    ).

v2_lang_usage :-
    format("usage: cocolog -s coding/bench/v2/lang_run.pl -- [--plan|--run] [options]~n", []),
    format("  --plan          print the grid; no model call~n", []),
    format("  --doctor        print each language's toolchain; no model call~n", []),
    format("  --run           run the comparison~n", []),
    format("  --tasks A,B     lcs, stable_sort, calculator~n", []),
    format("  --langs A,B     c, python, cocolog, swipl~n", []),
    format("  --trials N      trials per task and language~n", []),
    format("  --seed N        order seed~n", []),
    format("  --out FILE      JSONL output~n", []),
    format("  --keep DIR      write each task/language/trial's attempts~n", []).

v2_lang_plan(Tasks, Langs, Trials, Seed) :-
    format("v2 language plan (no model calls)~n", []),
    format("task languages trials budget~n", []),
    forall(member(Task, Tasks),
           (   v2_task(Task, _, _, _, _, _, budget(Max, _, _)),
               atomic_list_concat(Langs, ',', LangText),
               format("~w ~w ~w ~w~n", [Task, LangText, Trials, Max])
           )),
    length(Tasks, NT),
    length(Langs, NL),
    Cells is NT * NL * Trials,
    format("cells: ~w task(s) x ~w language(s) x ~w trial(s) = ~w~n",
           [NT, NL, Trials, Cells]),
    format("mode: plain; seed: ~w~n", [Seed]).

v2_lang_doctor(Langs) :-
    format("v2 language toolchain (no model calls)~n", []),
    forall(member(Lang, Langs), v2_lang_doctor_line(Lang)).

v2_lang_doctor_line(Lang) :-
    v2_lang_tool_command(Lang, Command),
    format(atom(Cmd), '~w 2>&1', [Command]),
    catch(proc_run(Cmd, 10000, Codes, Exit),
          Ball,
          ( Exit = -1,
            v2_error_text(Ball, Error),
            atom_codes(Error, Codes)
          )),
    atom_codes(Text, Codes),
    v2_lang_first_line(Text, Line),
    (   Exit == 0
    ->  format("~w: ok (~w)~n", [Lang, Line])
    ;   format("~w: unavailable (exit ~w) ~w~n", [Lang, Exit, Line])
    ).

v2_lang_tool_command(c, 'cc --version').
v2_lang_tool_command(python, Cmd) :-
    v2_lang_python(Python),
    codegen_shell_quote(Python, QPython),
    format(atom(Cmd), '~w --version', [QPython]).
v2_lang_tool_command(cocolog, Cmd) :-
    current_prolog_flag(executable, Exe),
    codegen_shell_quote(Exe, QExe),
    format(atom(Cmd), '~w --version', [QExe]).
v2_lang_tool_command(swipl, Cmd) :-
    v2_lang_swipl(Swipl),
    codegen_shell_quote(Swipl, QSwipl),
    format(atom(Cmd), '~w --version', [QSwipl]).

v2_lang_first_line(Text, Line) :-
    split_string(Text, "\n", " \t\r", Lines),
    (   member(Line0, Lines),
        \+ v2_lang_empty_string(Line0)
    ->  Line = Line0
    ;   Line = "no output"
    ).

v2_lang_run(Tasks, Langs, Trials, Seed, OutSpec) :-
    (   getenv('CODING_ENDPOINT_KEY_ENV', Key),
        Key \== ''
    ->  true
    ;   format("CODING_ENDPOINT_KEY_ENV is not set.~n", []),
        halt(1)
    ),
    get_time(Now),
    Stamp is round(Now * 1000),
    format(atom(RunId), 'v2-lang-~w', [Stamp]),
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
                   suite-'v2-lang',
                   run_id-RunId,
                   commit-Commit,
                   started-Stamp,
                   seed-Seed,
                   trials-Trials,
                   model-Model,
                   provider-Provider,
                   temperature-Temperature,
                   tasks-Tasks,
                   languages-Langs,
                   mode-plain]),
    v2_write_row(Stream, Header),
    retractall(v2_lang_cell(_, _, _, _, _, _, _, _)),
    length(Tasks, NT),
    length(Langs, NL),
    Cells is NT * NL * Trials,
    format("v2 language run ~w~n", [RunId]),
    format("commit ~w, model ~w, ~w cell(s), seed ~w~n",
           [Commit, Model, Cells, Seed]),
    format("jsonl: ~w~n~n", [OutFile]),
    forall(between(1, Trials, Trial),
           v2_lang_trial(Trial, Tasks, Langs, Trials, Seed, RunId, Commit,
                         Stream)),
    close(Stream),
    v2_lang_print_summary(Tasks, Langs).

v2_lang_trial(Trial, Tasks, Langs, Trials, Seed, RunId, Commit, Stream) :-
    TrialSeed is Seed + Trial * 7919,
    findall(Task-Lang,
            ( member(Task, Tasks), member(Lang, Langs) ),
            Jobs0),
    v2_permute(Jobs0, TrialSeed, Jobs, _),
    length(Jobs, Count),
    format("===== language trial ~w/~w (~w cells) =====~n",
           [Trial, Trials, Count]),
    v2_lang_jobs(Jobs, 1, Trial, TrialSeed, RunId, Commit, Stream).

v2_lang_jobs([], _, _, _, _, _, _).
v2_lang_jobs([Task-Lang|Jobs], Pos, Trial, TrialSeed, RunId, Commit,
             Stream) :-
    v2_lang_cell_run(Task, Lang, Trial, Pos, TrialSeed, RunId, Commit,
                     Row, Cell),
    v2_write_row(Stream, Row),
    v2_lang_cell_report(Cell),
    Next is Pos + 1,
    v2_lang_jobs(Jobs, Next, Trial, TrialSeed, RunId, Commit, Stream).

v2_lang_cell_run(Task, Lang, Trial, Pos, Seed, RunId, Commit, Row, Cell) :-
    v2_task(Task, _, _, _, _, _, budget(MaxCalls, _, _)),
    v2_language_spec(Lang, Task, Spec),
    usage(0, 0, 0, 0, 0) = Usage0,
    get_time(T0),
    v2_keep_begin(Task, Lang, Trial, Spec),
    call_cleanup(
        v2_lang_attempts(Lang, Task, Spec, MaxCalls, 1, none, Usage0,
                         Attempts, Usage, Outcome, Repair, Heldout),
        v2_keep_cell_set(none)),
    get_time(T1),
    Seconds is T1 - T0,
    (   Attempts =:= 1, Outcome == pass -> Pass1 = yes ; Pass1 = no ),
    (   Outcome == pass -> Final = yes ; Final = no ),
    Cell = cell(Task, Lang, Trial, Pass1, Final, Attempts, Usage, Seconds,
                Outcome, Repair, Heldout),
    assertz(v2_lang_cell(Task, Lang, Trial, Pass1, Final, Attempts, Usage,
                         Seconds)),
    v2_config(model, Model),
    v2_config(temperature, Temperature),
    v2_bool(Pass1, Pass1Json),
    v2_bool(Final, FinalJson),
    Usage = usage(P, C, T, R, H),
    Row = json([type-cell,
                suite-'v2-lang',
                run_id-RunId,
                commit-Commit,
                task-Task,
                language-Lang,
                mode-plain,
                trial-Trial,
                order_position-Pos,
                seed-Seed,
                model-Model,
                temperature-Temperature,
                pass_at_1-Pass1Json,
                final_pass-FinalJson,
                outcome-Outcome,
                attempts-Attempts,
                repair-Repair,
                heldout-Heldout,
                max_calls-MaxCalls,
                usage-json([prompt-P,
                            completion-C,
                            total-T,
                            reasoning-R,
                            cache_hit-H]),
                seconds-Seconds]).

v2_lang_attempts(Lang, Task, Spec, Max, Attempt, Prev, Usage0,
                 Attempts, Usage, Outcome, Repair, Heldout) :-
    catch(v2_language_generate(Lang, Spec, Prev, Code, U, GenError),
          Ball,
          ( Code = '',
            U = usage(0, 0, 0, 0, 0),
            GenError = Ball
          )),
    v2_add_usage(Usage0, U, Usage1),
    (   GenError == none
    ->  catch(v2_language_verify(Lang, Task, Code, Verdict), Ball1,
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
    catch(v2_keep_attempt_ext(Attempt, Ext, Code, U, GenError, Verdict), _,
          true),
    (   Verdict = verdict(ok, HeldoutVerdict)
    ->  Attempts = Attempt,
        Usage = Usage1,
        Repair = ok,
        (   HeldoutVerdict == ok
        ->  Outcome = pass, Heldout = ok
        ;   Outcome = fail_heldout, Heldout = fail
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
            v2_lang_attempts(Lang, Task, Spec, Max, Next, Prev1, Usage1,
                             Attempts, Usage, Outcome, Repair, Heldout)
        )
    ).

v2_lang_cell_report(cell(Task, Lang, Trial, Pass1, Final, Attempts, Usage,
                         Seconds, Outcome, Repair, Heldout)) :-
    Usage = usage(_, _, Total, _, _),
    format("~w/~w trial ~w: ~w attempts ~w, repair ~w, heldout ~w, ~w tokens, ~2f s~n",
           [Task, Lang, Trial, Outcome, Attempts, Repair, Heldout, Total,
            Seconds]),
    (   Pass1 == yes -> format("  pass@1~n", [])
    ;   Final == yes -> format("  final pass~n", [])
    ;   true
    ).

v2_lang_print_summary(Tasks, Langs) :-
    format("~ntask language trials pass@1 final attempts tokens seconds~n", []),
    forall(member(Task, Tasks),
           forall(member(Lang, Langs), v2_lang_summary_row(Task, Lang))),
    v2_lang_summary_total(Tasks, Langs).

v2_lang_summary_row(Task, Lang) :-
    findall(cell(Trial, P1, Final, Attempts, Total, Seconds),
            (   v2_lang_cell(Task, Lang, Trial, P1, Final, Attempts,
                             usage(_, _, Total, _, _), Seconds)
            ),
            Cells),
    (   Cells == [] -> true
    ;   v2_lang_summary_cells(Cells, Task, Lang)
    ).

v2_lang_summary_cells(Cells, Task, Lang) :-
    length(Cells, N),
    findall(P, member(cell(_, P, _, _, _, _), Cells), Ps),
    v2_count_yes(Ps, P1Sum),
    findall(F, member(cell(_, _, F, _, _, _), Cells), Fs),
    v2_count_yes(Fs, FSum),
    findall(A, member(cell(_, _, _, A, _, _), Cells), As),
    v2_sum(As, 0, ASum),
    findall(T, member(cell(_, _, _, _, T, _), Cells), Ts),
    v2_sum(Ts, 0, TSum),
    findall(S, member(cell(_, _, _, _, _, S), Cells), Ss),
    v2_sum(Ss, 0.0, SSum),
    MeanA is ASum / N,
    MeanS is SSum / N,
    format("~w ~w ~w ~w/~w ~w/~w ~2f ~w ~1f~n",
           [Task, Lang, N, P1Sum, N, FSum, N, MeanA, TSum, MeanS]).

v2_lang_summary_total(Tasks, Langs) :-
    findall(cell(Trial, P1, Final, Attempts, Total, Seconds),
            (   member(Task, Tasks), member(Lang, Langs),
                v2_lang_cell(Task, Lang, Trial, P1, Final, Attempts,
                             usage(_, _, Total, _, _), Seconds)
            ),
            Cells),
    (   Cells == [] -> true
    ;   length(Cells, N),
        findall(P, member(cell(_, P, _, _, _, _), Cells), Ps),
        v2_count_yes(Ps, P1Sum),
        findall(F, member(cell(_, _, F, _, _, _), Cells), Fs),
        v2_count_yes(Fs, FSum),
        findall(A, member(cell(_, _, _, A, _, _), Cells), As),
        v2_sum(As, 0, ASum),
        findall(T, member(cell(_, _, _, _, T, _), Cells), Ts),
        v2_sum(Ts, 0, TSum),
        findall(S, member(cell(_, _, _, _, _, S), Cells), Ss),
        v2_sum(Ss, 0.0, SSum),
        MeanA is ASum / N,
        format("~nall: ~w cells, pass@1 ~w/~w, final ~w/~w, ~2f attempts, ~w tokens, ~1f s~n",
               [N, P1Sum, N, FSum, N, MeanA, TSum, SSum])
    ).

v2_lang_empty_string(S) :-
    (   string(S) -> string_length(S, 0) ; S == '' ).
