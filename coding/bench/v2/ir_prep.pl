%% coding/bench/v2/ir_prep.pl -- the translation phase of an IR language run.
%%
%%     CODING_ENDPOINT_IR_API=anthropic \
%%     CODING_ENDPOINT_IR_KEY="$TEST_API_KEY" \
%%     CODING_ENDPOINT_IR_MODEL="$TEST_MODEL" \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog --embed coding/endpoint/store \
%%             -s coding/bench/v2/ir_prep.pl -- \
%%             --tasks mvccs_acid --langs c,python,cocolog,swipl --out DIR
%%
%% THE TRANSLATION IS DONE BEFORE THE BENCHMARK, AND COUNTED APART. For
%% each task and language, the requirement that language's cells are
%% given (v2_language_spec/3) is read by the coding endpoint's translator,
%% with the model's check of every reading and its repair of what was read
%% wrongly or not read (coding/endpoint/ir_repair.pl). The note the
%% endpoint would send, ep_ir_note/2, is written to DIR/TASK-LANG.ir, and
%% the phase's calls, tokens and seconds to DIR/ir-prep.jsonl. The
%% benchmark (lang_run.pl --arms plain,ir --ir-notes DIR) reads the notes
%% from those files and calls no translator, so no translation token and
%% no translation second is in its figures.
%%
%% THE REASONING NOTE TOO (since reasoning 1.15.0): the pre-pass's checks
%% and its "What the request is about" note, the endpoint's own
%% (ep_reasoning_notes/7, the default two checks), written to
%% DIR/TASK-LANG.reasoning for the runner's `reasoning' and `reasoning_ir'
%% arms. They call no model. The endpoint reads a C, cocolog or Python
%% request; `cocolog_noguide' is read as cocolog, and `swipl', which has no
%% endpoint model, as cocolog too (whose checks are C's: the same keyword
%% reader and contract).
%%
%% THE NUMBER OF CHECKS (since reasoning 1.15.4): `--checks N' writes the
%% reasoning note with the pre-pass at count(N), the endpoint's setting for
%% N checks, and `--checks all' at count(N) for every check the endpoint's
%% readers find in that lane's requirement; the default is the endpoint's
%% own (two unless CODING_ENDPOINT_REASONING_MIN and _MAX say otherwise).
%% The keyword reader finds 13 checks in mvccs_acid's C requirement and 12
%% in each other lane's, and the default sends the first two. `--only reasoning' writes
%% the .reasoning notes alone: no translation, no model, no store, and a
%% row of the setting, the checks and the note's length a note.
%%
%% Every sentence of the requirement is read (CODING_ENDPOINT_IR_SENTENCES
%% is 100 unless set), where the endpoint reads a request's first six.
%% What is learned is kept in the store, as the endpoint keeps it: run the
%% phase again until a run makes no call, and the notes are then what the
%% store reads with no model. Its sentences are the benchmark's, which are
%% in the tree already.

:- use_module(library(json)).
:- use_module('coding/endpoint/httpd_core.pl').
:- use_module('coding/endpoint/english_lesson.pl').
:- use_module('coding/bench/v2/langs.pl').
:- initialization(ep_english_lesson).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   ir_prep_args(Args, Tasks, Langs, Dir, Setting, Only)
    ->  true
    ;   format(user_error, "usage: ir_prep.pl -- --tasks A,B --langs A,B --out DIR [--checks N|all] [--only reasoning]~n", []),
        halt(2)
    ),
    forall(member(T, Tasks), v2_language_task(T)),
    forall(member(L, Langs), v2_language_supported(L)),
    (   getenv('CODING_ENDPOINT_IR_SENTENCES', S), S \== ''
    ->  true
    ;   setenv('CODING_ENDPOINT_IR_SENTENCES', '100')
    ),
    catch(make_directory(Dir), _, true),
    (   exists_directory(Dir)
    ->  true
    ;   format(user_error, "ir_prep: cannot make ~w~n", [Dir]),
        halt(1)
    ),
    (   Only == reasoning
    ->  Model = none,
        format("ir prep: the reasoning notes alone, setting ~w~n", [Setting])
    ;   ep_ir_model(Model),
        (   ep_ir_repair_ready
        ->  Ready = yes
        ;   Ready = no
        ),
        format("ir prep: model ~w, repair ready ~w, reasoning setting ~w~n",
               [Model, Ready, Setting])
    ),
    format(atom(Log), '~w/ir-prep.jsonl', [Dir]),
    get_time(Now),
    Stamp is round(Now * 1000),
    foldl(ir_prep_task(Dir, Log, Stamp, Model, Setting, Only, Langs), Tasks,
          t(0, 0, 0, 0.0), t(Calls, Prompt, Completion, Seconds)),
    format("~ntranslation: ~w calls, ~w prompt and ~w completion tokens, ~2f s~n",
           [Calls, Prompt, Completion, Seconds]).

ir_prep_task(Dir, Log, Stamp, Model, Setting, Only, Langs, Task, T0, T) :-
    foldl(ir_prep_one(Dir, Log, Stamp, Model, Setting, Only, Task), Langs,
          T0, T).

%% The reasoning note alone: the pre-pass at Setting, no translation.
ir_prep_one(Dir, Log, Stamp, _, Setting, reasoning, Task, Lang, T, T) :-
    !,
    v2_language_spec(Lang, Task, Spec),
    ir_prep_reasoning(Dir, Task, Lang, Spec, Setting, NChecks, ReasoningChars),
    ir_prep_setting_term(Setting, SettingTerm),
    Row = json([run-Stamp, task-Task, language-Lang,
                reasoning_setting-SettingTerm,
                reasoning_checks-NChecks,
                reasoning_note_chars-ReasoningChars]),
    ir_prep_log(Log, Row),
    format("~w/~w: reasoning note ~w chars, ~w checks~n",
           [Task, Lang, ReasoningChars, NChecks]).

ir_prep_one(Dir, Log, Stamp, Model, Setting, all, Task, Lang,
            t(C0, P0, K0, S0), t(C, P, K, S)) :-
    v2_language_spec(Lang, Task, Spec),
    get_time(A),
    ep_ir_note(Spec, Note),
    get_time(B),
    Seconds is B - A,
    ep_ir_stats(ir(Sentences, Read, Lesson, Rewrite, Unread, Lessons,
                   Calls, Prompt, Completion, Right, Wrong)),
    format(atom(File), '~w/~w-~w.ir', [Dir, Task, Lang]),
    atom_codes(Note, NoteCodes),
    write_file_from_codes(File, NoteCodes),
    atom_length(Note, NoteChars),
    ir_prep_reasoning(Dir, Task, Lang, Spec, Setting, NChecks, ReasoningChars),
    Row = json([run-Stamp, task-Task, language-Lang, model-Model,
                sentences-Sentences, read-Read, lesson-Lesson,
                rewrite-Rewrite, unread-Unread, lessons-Lessons,
                calls-Calls, prompt-Prompt, completion-Completion,
                judged_right-Right, judged_wrong-Wrong,
                seconds-Seconds, note_chars-NoteChars,
                reasoning_checks-NChecks,
                reasoning_note_chars-ReasoningChars]),
    ir_prep_log(Log, Row),
    Readable is Read + Lesson + Rewrite,
    format("~w/~w: ~w of ~w sentences read (~w unread), ~w calls, ~w + ~w tokens, ~2f s, note ~w chars; reasoning note ~w chars, ~w checks~n",
           [Task, Lang, Readable, Sentences, Unread, Calls, Prompt,
            Completion, Seconds, NoteChars, ReasoningChars, NChecks]),
    C is C0 + Calls, P is P0 + Prompt, K is K0 + Completion,
    S is S0 + Seconds.

%% The pre-pass's two notes, as the endpoint would send them at Setting,
%% written to DIR/TASK-LANG.reasoning.
ir_prep_reasoning(Dir, Task, Lang, Spec, Setting0, NChecks, Chars) :-
    ir_prep_endpoint_language(Lang, EpLang),
    ir_prep_setting(EpLang, Spec, Setting0, Setting),
    ep_reasoning_notes(EpLang, Setting, Spec, Checks, About, NChecks, _),
    atom_concat(Checks, About, Reasoning),
    format(atom(RFile), '~w/~w-~w.reasoning', [Dir, Task, Lang]),
    atom_codes(Reasoning, RCodes),
    write_file_from_codes(RFile, RCodes),
    atom_length(Reasoning, Chars).

ir_prep_log(Log, Row) :-
    json_codes(Row, RowCodes),
    append(RowCodes, [0'\n], Line),
    append_file_from_codes(Log, Line).

%% `all' is count(N) for the N checks the endpoint's readers find in the
%% text, the same list ep_reasoning_notes/7 limits to its setting.
ir_prep_setting(EpLang, Spec, all, count(N)) :-
    !,
    endpoint_reason(EpLang, Spec, Obs, CObs, _),
    append(Obs, CObs, All0),
    ep_unique(All0, All),
    length(All, N).
ir_prep_setting(_, _, Setting, Setting).

ir_prep_setting_term(default, default).
ir_prep_setting_term(all, all).
ir_prep_setting_term(count(N), N).

%% The endpoint's language a lane's requirement is read as.
ir_prep_endpoint_language(c, c).
ir_prep_endpoint_language(python, python).
ir_prep_endpoint_language(cocolog, cocolog).
ir_prep_endpoint_language(cocolog_noguide, cocolog).
ir_prep_endpoint_language(swipl, cocolog).

ir_prep_args(Args, Tasks, Langs, Dir, Setting, Only) :-
    ir_prep_flags(Args, Pairs),
    memberchk(tasks-TaskText, Pairs),
    memberchk(langs-LangText, Pairs),
    memberchk(out-Dir, Pairs),
    ir_prep_csv(TaskText, Tasks),
    ir_prep_csv(LangText, Langs),
    (   memberchk(checks-NText, Pairs)
    ->  (   NText == all
        ->  Setting = all
        ;   atom_number(NText, N),
            integer(N),
            N >= 0,
            Setting = count(N)
        )
    ;   Setting = default
    ),
    (   memberchk(only-OnlyText, Pairs)
    ->  OnlyText == reasoning,
        Only = reasoning
    ;   Only = all
    ),
    forall(member(Name-_, Pairs),
           memberchk(Name, [tasks, langs, out, checks, only])).

ir_prep_flags([], []).
ir_prep_flags([Flag, Value|Rest], [Name-Value|Pairs]) :-
    atom_concat('--', Name, Flag),
    ir_prep_flags(Rest, Pairs).

ir_prep_csv(Text, Atoms) :-
    atomic_list_concat(Atoms0, ',', Text),
    exclude(==(''), Atoms0, Atoms),
    Atoms \== [].
