%% coding/bench/v2/lang_runner.pl -- Phase 4 language comparison.
%%
%%     cocolog -s coding/bench/v2/lang_run.pl -- [--plan|--doctor|--run] [options]
%%
%%     --tasks A,B     lcs, stable_sort, calculator, mvccs_acid (default
%%                     the first three)
%%     --langs A,B     c, python, cocolog, swipl, cocolog_noguide
%%                     (default the first four)
%%     --arms A,B      plain, reasoning, reasoning_ir, ir (default plain)
%%     --ir-notes DIR  the prep phase's notes, for every arm but plain
%%     --trials N      trials per task and language (default 3)
%%     --seed N        order seed
%%     --out FILE      JSONL output
%%     --keep DIR      write each task/language/trial's attempts
%%
%% The mode is plain (the repair loop, no obligations). Specs, cases,
%% held-out split and budget are the same across languages; only the
%% language sentence and each language's normal generator differ.
%% This runner is separate from the C mode matrix so no existing C result
%% changes.
%%
%% THE IR ARM is plain with the translator's reading of the requirement
%% after it: the note the coding endpoint sends ("The request in the
%% translator's IR"), which ir_prep.pl wrote to DIR/TASK-LANG.ir before
%% the run. The note is read from that file, so the run calls no
%% translator and no model for it: the arm's tokens and seconds are the
%% coding model's alone, the note's own prompt tokens among them. An arm
%% whose note is missing is refused before the first call. Within a trial
%% the cells of both arms are shuffled together, so neither arm runs at
%% another hour of the provider's day. The note goes after the
%% requirement in the user prompt, where every language's generator puts
%% the requirement; the endpoint puts it in the system prompt, after the
%% guide.
%%
%% THE REASONING ARMS (since reasoning 1.15.0) measure what the coding
%% endpoint's reasoning pre-pass adds to a prompt. `plain' is the prompt
%% forwarded as it is (the endpoint's `-r0'); `reasoning' is the prompt with
%% the pre-pass's checks and its "What the request is about" note, and
%% `reasoning_ir' those and then the IR note -- the three notes in the
%% endpoint's order (httpd_core.pl's ep_reasoning/9). The checks and the
%% about note are the endpoint's own (`ep_reasoning_notes/7', two checks,
%% the endpoint's default), which ir_prep.pl wrote to DIR/TASK-LANG.reasoning
%% before the run; they call no model. `ir' is the IR note alone, as in
%% reasoning 1.14. The model's effort is the run's in every arm.

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

:- dynamic v2_lang_cell/9.

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
    (   catch(v2_lang_selection(Opts, Tasks, Langs, Arms, Notes, Trials, Seed,
                                OutSpec),
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
        v2_lang_run(Tasks, Langs, Arms, Notes, Trials, Seed, OutSpec)
    ;   memberchk(doctor, Opts)
    ->  v2_lang_doctor(Langs)
    ;   v2_lang_plan(Tasks, Langs, Arms, Trials, Seed)
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
v2_lang_parse_args(['--arms', Value|Rest], [arms(Arms)|Opts]) :-
    v2_lang_csv_atoms(Value, Arms),
    v2_lang_parse_args(Rest, Opts).
v2_lang_parse_args(['--ir-notes', Value|Rest], [ir_notes(Value)|Opts]) :-
    v2_lang_parse_args(Rest, Opts).

v2_lang_csv_atoms(Value, Atoms) :-
    split_string(Value, ",", " ", Parts0),
    exclude(v2_lang_empty_string, Parts0, Parts),
    maplist(atom_string, Atoms, Parts),
    Atoms \== [].

v2_lang_selection(Opts, Tasks, Langs, Arms, Notes, Trials, Seed, OutSpec) :-
    (   memberchk(tasks(Tasks0), Opts)
    ->  Tasks = Tasks0
    ;   findall(Task, ( v2_language_task(Task), \+ v2_hard_task(Task) ),
                Tasks)
    ),
    Tasks \== [],
    forall(member(Task, Tasks), v2_language_task(Task)),
    (   memberchk(langs(Langs0), Opts)
    ->  Langs = Langs0
    ;   Langs = [c, python, cocolog, swipl]
    ),
    Langs \== [],
    forall(member(Lang, Langs), v2_language_supported(Lang)),
    (   memberchk(arms(Arms0), Opts)
    ->  Arms = Arms0
    ;   Arms = [plain]
    ),
    Arms \== [],
    forall(member(Arm, Arms), v2_lang_arm_notes(Arm, _)),
    (   member(Arm1, Arms),
        v2_lang_arm_notes(Arm1, [_|_])
    ->  (   memberchk(ir_notes(Notes), Opts)
        ->  true
        ;   throw(error(v2_lang_error(ir_arm_without_notes,
                                      'an arm with notes needs --ir-notes DIR: run coding/bench/v2/ir_prep.pl first'),
                        v2_lang_selection/8))
        ),
        forall(( member(Arm2, Arms), v2_lang_arm_notes(Arm2, Kinds),
                 member(Kind, Kinds), member(Task, Tasks), member(Lang, Langs) ),
               v2_lang_note_file(Notes, Task, Lang, Kind, _))
    ;   Notes = none
    ),
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

%% The note file the prep phase wrote for a task and a language, which
%% must be there: a missing one is refused before the first call. Kind is
%% `ir' (the translator's IR) or `reasoning' (the pre-pass's checks and its
%% about note).
v2_lang_note_file(Dir, Task, Lang, File) :-
    v2_lang_note_file(Dir, Task, Lang, ir, File).

v2_lang_note_file(Dir, Task, Lang, Kind, File) :-
    format(atom(File), '~w/~w-~w.~w', [Dir, Task, Lang, Kind]),
    (   exists_file(File)
    ->  true
    ;   v2_lang_note_error(Kind, Error, Name),
        format(atom(Msg), 'no ~w note ~w: run coding/bench/v2/ir_prep.pl (reason_prep.pl for a reason_* note) for ~w in ~w first',
               [Name, File, Task, Lang]),
        throw(error(v2_lang_error(Error, Msg), v2_lang_note_file/5))
    ).

v2_lang_note_error(ir, no_ir_note, 'IR').
v2_lang_note_error(reasoning, no_reasoning_note, reasoning).
v2_lang_note_error(Kind, no_reason_note, Kind) :-
    memberchk(Kind, [controlled, terms, concepts, outline]).

%% The arms, and the notes each puts after the requirement, in the
%% endpoint's order: the prompt alone, the prompt with the reasoning
%% pre-pass, the prompt with the pre-pass and the IR, and the IR alone.
v2_lang_arm_notes(plain, []).
v2_lang_arm_notes(reasoning, [reasoning]).
v2_lang_arm_notes(reasoning_ir, [reasoning, ir]).
v2_lang_arm_notes(ir, [ir]).
%% the reason_* readers' notes (since reasoning 1.17.1), each made by
%% coding/bench/v2/reason_prep.pl from a CONTROLLED restatement of the
%% requirement the grammar reads whole: the restatement itself, then what
%% reason_text/2, reason_concepts/2 and reason_topics/2 with
%% reason_topic_lines/2 make of it
v2_lang_arm_notes(controlled, [controlled]).
v2_lang_arm_notes(terms, [terms]).
v2_lang_arm_notes(concepts, [concepts]).
v2_lang_arm_notes(outline, [outline]).

%% The requirement a cell is given: the language's, and after it the
%% arm's notes. Chars is chars(IR, Reasoning), each note's length.
v2_lang_arm_spec(Arm, Notes, Task, Lang, Spec0, Spec, Chars) :-
    v2_lang_arm_notes(Arm, Kinds),
    foldl(v2_lang_arm_note(Notes, Task, Lang), Kinds,
          Spec0-chars(0, 0), Spec-Chars).

v2_lang_arm_note(Notes, Task, Lang, Kind, Spec0-Chars0, Spec-Chars) :-
    v2_lang_note_file(Notes, Task, Lang, Kind, File),
    read_file_to_codes(File, Codes),
    atom_codes(Note, Codes),
    atom_length(Note, N),
    atom_concat(Spec0, Note, Spec),
    v2_lang_add_chars(Kind, N, Chars0, Chars).

v2_lang_add_chars(ir, N, chars(I0, R), chars(I, R)) :- I is I0 + N.
v2_lang_add_chars(reasoning, N, chars(I, R0), chars(I, R)) :- R is R0 + N.
%% a reason_* note counts as the reasoning's
v2_lang_add_chars(Kind, N, chars(I, R0), chars(I, R)) :-
    memberchk(Kind, [controlled, terms, concepts, outline]),
    R is R0 + N.

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
    format("  --tasks A,B     lcs, stable_sort, calculator, mvccs_acid~n", []),
    format("  --langs A,B     c, python, cocolog, swipl, cocolog_noguide~n", []),
    format("  --arms A,B      plain, reasoning, reasoning_ir, ir, controlled, terms, concepts, outline~n", []),
    format("  --ir-notes DIR  the notes coding/bench/v2/ir_prep.pl wrote~n", []),
    format("  --trials N      trials per task and language~n", []),
    format("  --seed N        order seed~n", []),
    format("  --out FILE      JSONL output~n", []),
    format("  --keep DIR      write each task/language/trial's attempts~n", []).

v2_lang_plan(Tasks, Langs, Arms, Trials, Seed) :-
    format("v2 language plan (no model calls)~n", []),
    format("task languages arms trials budget~n", []),
    atomic_list_concat(Arms, ',', ArmText),
    forall(member(Task, Tasks),
           (   v2_task(Task, _, _, _, _, _, budget(Max, _, _)),
               atomic_list_concat(Langs, ',', LangText),
               format("~w ~w ~w ~w ~w~n", [Task, LangText, ArmText, Trials, Max])
           )),
    length(Tasks, NT),
    length(Langs, NL),
    length(Arms, NA),
    Cells is NT * NL * NA * Trials,
    format("cells: ~w task(s) x ~w language(s) x ~w arm(s) x ~w trial(s) = ~w~n",
           [NT, NL, NA, Trials, Cells]),
    v2_setting(provider, Provider),
    v2_setting(model, Model),
    v2_setting(effort, Effort),
    v2_setting(max_tokens, MaxTokens),
    format("mode: plain; seed: ~w; provider ~w, model ~w, effort ~w, max_tokens ~w~n",
           [Seed, Provider, Model, Effort, MaxTokens]).

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
v2_lang_tool_command(cocolog_noguide, Cmd) :-
    v2_lang_tool_command(cocolog, Cmd).

v2_lang_first_line(Text, Line) :-
    split_string(Text, "\n", " \t\r", Lines),
    (   member(Line0, Lines),
        \+ v2_lang_empty_string(Line0)
    ->  Line = Line0
    ;   Line = "no output"
    ).

v2_lang_run(Tasks, Langs, Arms, Notes, Trials, Seed, OutSpec) :-
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
    v2_setting(model, Model),
    v2_setting(provider, Provider),
    v2_setting(temperature, Temperature),
    v2_setting(effort, Effort),
    v2_setting(max_tokens, MaxTokens),
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
                   effort-Effort,
                   max_tokens-MaxTokens,
                   tasks-Tasks,
                   languages-Langs,
                   arms-Arms,
                   ir_notes-Notes,
                   mode-plain]),
    v2_write_row(Stream, Header),
    retractall(v2_lang_cell(_, _, _, _, _, _, _, _, _)),
    length(Tasks, NT),
    length(Langs, NL),
    length(Arms, NA),
    Cells is NT * NL * NA * Trials,
    format("v2 language run ~w~n", [RunId]),
    format("commit ~w, model ~w, effort ~w, ~w cell(s), seed ~w~n",
           [Commit, Model, Effort, Cells, Seed]),
    format("jsonl: ~w~n~n", [OutFile]),
    forall(between(1, Trials, Trial),
           v2_lang_trial(Trial, Tasks, Langs, Arms, Notes, Trials, Seed,
                         RunId, Commit, Stream)),
    close(Stream),
    v2_lang_print_summary(Tasks, Langs, Arms).

v2_lang_trial(Trial, Tasks, Langs, Arms, Notes, Trials, Seed, RunId, Commit,
              Stream) :-
    TrialSeed is Seed + Trial * 7919,
    findall(job(Task, Lang, Arm),
            ( member(Task, Tasks), member(Lang, Langs), member(Arm, Arms) ),
            Jobs0),
    v2_permute(Jobs0, TrialSeed, Jobs, _),
    length(Jobs, Count),
    format("===== language trial ~w/~w (~w cells) =====~n",
           [Trial, Trials, Count]),
    v2_lang_jobs(Jobs, 1, Notes, Trial, TrialSeed, RunId, Commit, Stream).

v2_lang_jobs([], _, _, _, _, _, _, _).
v2_lang_jobs([job(Task, Lang, Arm)|Jobs], Pos, Notes, Trial, TrialSeed,
             RunId, Commit, Stream) :-
    v2_lang_cell_run(Task, Lang, Arm, Notes, Trial, Pos, TrialSeed, RunId,
                     Commit, Row, Cell),
    v2_write_row(Stream, Row),
    v2_lang_cell_report(Cell),
    Next is Pos + 1,
    v2_lang_jobs(Jobs, Next, Notes, Trial, TrialSeed, RunId, Commit, Stream).

v2_lang_cell_run(Task, Lang, Arm, Notes, Trial, Pos, Seed, RunId, Commit,
                 Row, Cell) :-
    v2_task(Task, _, _, _, _, _, budget(MaxCalls, _, _)),
    v2_language_spec(Lang, Task, Spec0),
    v2_lang_arm_spec(Arm, Notes, Task, Lang, Spec0, Spec,
                     chars(NoteChars, ReasoningChars)),
    usage(0, 0, 0, 0, 0) = Usage0,
    get_time(T0),
    v2_lang_keep_name(Lang, Arm, KeepLang),
    v2_keep_begin(Task, KeepLang, Trial, Spec),
    v2_lang_empty_begin,
    call_cleanup(
        v2_lang_attempts(Lang, Task, Spec, MaxCalls, 1, none, Usage0,
                         Attempts, Usage, Outcome, Repair, Heldout),
        v2_keep_cell_set(none)),
    get_time(T1),
    v2_lang_empty_list(EmptyReasons),
    length(EmptyReasons, NEmpty),
    Seconds is T1 - T0,
    (   Attempts =:= 1, Outcome == pass -> Pass1 = yes ; Pass1 = no ),
    (   Outcome == pass -> Final = yes ; Final = no ),
    Cell = cell(Task, Lang, Arm, Trial, Pass1, Final, Attempts, Usage,
                Seconds, Outcome, Repair, Heldout),
    assertz(v2_lang_cell(Task, Lang, Arm, Trial, Pass1, Final, Attempts,
                         Usage, Seconds)),
    v2_setting(model, Model),
    v2_setting(temperature, Temperature),
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
                arm-Arm,
                ir_note_chars-NoteChars,
                reasoning_note_chars-ReasoningChars,
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
                empty_replies-NEmpty,
                empty_reasons-EmptyReasons,
                max_calls-MaxCalls,
                usage-json([prompt-P,
                            completion-C,
                            total-T,
                            reasoning-R,
                            cache_hit-H]),
                seconds-Seconds]).

%% The name a cell's kept attempts go under: the language for the plain
%% arm, as before, and LANG-ir for the ir arm, so one trial's two arms do
%% not write over each other.
v2_lang_keep_name(Lang, plain, Lang) :- !.
v2_lang_keep_name(Lang, Arm, Name) :-
    format(atom(Name), '~w-~w', [Lang, Arm]).

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

v2_lang_cell_report(cell(Task, Lang, Arm, Trial, Pass1, Final, Attempts,
                         Usage, Seconds, Outcome, Repair, Heldout)) :-
    Usage = usage(_, _, Total, _, _),
    format("~w/~w/~w trial ~w: ~w attempts ~w, repair ~w, heldout ~w, ~w tokens, ~2f s~n",
           [Task, Lang, Arm, Trial, Outcome, Attempts, Repair, Heldout, Total,
            Seconds]),
    (   Pass1 == yes -> format("  pass@1~n", [])
    ;   Final == yes -> format("  final pass~n", [])
    ;   true
    ).

%% A line per task, language and arm, then one per arm over every task and
%% language, then all. Prompt and completion tokens are apart: the ir arm's
%% note is prompt tokens of every call it is in.
v2_lang_print_summary(Tasks, Langs, Arms) :-
    format("~ntask language arm trials pass@1 final attempts prompt completion tokens seconds~n", []),
    forall(member(Task, Tasks),
           forall(member(Lang, Langs),
                  forall(member(Arm, Arms),
                         v2_lang_summary_row(Task, Lang, Arm)))),
    nl,
    forall(member(Arm, Arms),
           (   findall(C, ( member(Task, Tasks), member(Lang, Langs),
                            v2_lang_summary_cell(Task, Lang, Arm, C) ),
                       Cells),
               format(atom(Label), 'arm ~w', [Arm]),
               v2_lang_summary_line(Cells, Label)
           )),
    findall(C, ( member(Task, Tasks), member(Lang, Langs), member(Arm, Arms),
                 v2_lang_summary_cell(Task, Lang, Arm, C) ),
            All),
    v2_lang_summary_line(All, all).

v2_lang_summary_row(Task, Lang, Arm) :-
    findall(C, v2_lang_summary_cell(Task, Lang, Arm, C), Cells),
    (   Cells == []
    ->  true
    ;   format(atom(Label), '~w ~w ~w', [Task, Lang, Arm]),
        v2_lang_summary_line(Cells, Label)
    ).

v2_lang_summary_cell(Task, Lang, Arm,
                     cell(P1, Final, Attempts, Prompt, Completion, Total,
                          Seconds)) :-
    v2_lang_cell(Task, Lang, Arm, _, P1, Final, Attempts,
                 usage(Prompt, Completion, Total, _, _), Seconds).

v2_lang_summary_line([], _) :- !.
v2_lang_summary_line(Cells, Label) :-
    length(Cells, N),
    findall(P, member(cell(P, _, _, _, _, _, _), Cells), Ps),
    v2_count_yes(Ps, P1Sum),
    findall(F, member(cell(_, F, _, _, _, _, _), Cells), Fs),
    v2_count_yes(Fs, FSum),
    findall(A, member(cell(_, _, A, _, _, _, _), Cells), As),
    v2_sum(As, 0, ASum),
    findall(X, member(cell(_, _, _, X, _, _, _), Cells), Xs),
    v2_sum(Xs, 0, XSum),
    findall(Y, member(cell(_, _, _, _, Y, _, _), Cells), Ys),
    v2_sum(Ys, 0, YSum),
    findall(T, member(cell(_, _, _, _, _, T, _), Cells), Ts),
    v2_sum(Ts, 0, TSum),
    findall(S, member(cell(_, _, _, _, _, _, S), Cells), Ss),
    v2_sum(Ss, 0.0, SSum),
    MeanA is ASum / N,
    format("~w: ~w cells, pass@1 ~w/~w, final ~w/~w, ~2f attempts, ~w prompt + ~w completion = ~w tokens, ~1f s~n",
           [Label, N, P1Sum, N, FSum, N, MeanA, XSum, YSum, TSum, SSum]).

v2_lang_empty_string(S) :-
    (   string(S) -> string_length(S, 0) ; S == '' ).
