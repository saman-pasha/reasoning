%% coding/bench/v2/restate_prep.pl -- the controlled English note, as the
%% coding endpoint makes it: written by a model, no hand-written text.
%%
%%     REASON_LIVE_API=anthropic REASON_LIVE_KEY="$TEST_API_KEY" \
%%     REASON_LIVE_MODEL="$TEST_MODEL" REASON_LIVE_LOG=DIR/restate-rounds.log \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/bench/v2/restate_prep.pl -- \
%%             --tasks mvccs_acid --langs python --out DIR
%%
%% For each task and language, the requirement that language's cells are
%% given (v2_language_spec/3) is the first user turn of a request, and the
%% endpoint's own ep_controlled/6 (coding/endpoint/httpd_core.pl, reasoning
%% 1.18.0) makes the note it would put after it: reason_restate/3 in live
%% mode, the model's sentences, each one read by the grammar alone. The
%% note is written to DIR/TASK-LANG.controlled, byte for byte what the
%% endpoint would send, and the runner's `controlled' arm puts it after
%% the requirement as the endpoint does (lang_run.pl --arms
%% plain,controlled --ir-notes DIR). The phase's calls, tokens, seconds
%% and sentences are written to DIR/restate-prep.jsonl, counted apart from
%% the benchmark, as the endpoint makes the note once a task.
%%
%% RUN IT WITHOUT --embed: no store is read, so a restatement saved before
%% is not used, and the note is the model's of this run. A language the
%% endpoint has no note for (cocolog) is named in
%% CODING_ENDPOINT_CONTROLLED_LANGS here, so any lane can be asked.

:- use_module(library(json)).
:- use_module(library(reasoning/live)).
:- use_module('coding/endpoint/httpd_core.pl').
:- use_module('coding/bench/v2/langs.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   rp_args(Args, Tasks, Langs, Dir)
    ->  true
    ;   format(user_error, "usage: restate_prep.pl -- --tasks A,B --langs A,B --out DIR~n", []),
        halt(2)
    ),
    (   exists_directory(Dir) -> true ; make_directory(Dir) ),
    setenv('CODING_ENDPOINT_RESTATE', on),
    atomic_list_concat([Dir, '/restate-prep.jsonl'], Log),
    forall(( member(Task, Tasks), member(Lang, Langs) ),
           rp_one(Dir, Log, Task, Lang)).

rp_one(Dir, Log, Task, Lang) :-
    (   v2_language_spec(Lang, Task, Spec)
    ->  true
    ;   format(user_error, "restate_prep: no ~w requirement for ~w~n", [Lang, Task]),
        halt(2)
    ),
    setenv('CODING_ENDPOINT_CONTROLLED_LANGS', Lang),
    reason_live_stats_reset,
    get_time(T0),
    ep_controlled(Lang, reasoning, false, [json([role-user, content-Spec])], Messages, N),
    get_time(T1),
    Seconds is T1 - T0,
    reason_live_stats(Stats),
    memberchk(calls-Calls, Stats),
    memberchk(prompt_tokens-Prompt, Stats),
    memberchk(completion_tokens-Completion, Stats),
    atom_length(Spec, SpecChars),
    (   N > 0,
        Messages = [json(Pairs)],
        memberchk(content-Content, Pairs),
        sub_atom(Content, SpecChars, _, 0, Note)
    ->  atomic_list_concat([Dir, '/', Task, '-', Lang, '.controlled'], File),
        atom_codes(Note, NoteCodes),
        write_file_from_codes(File, NoteCodes),
        atom_length(Note, NoteChars),
        format("~w ~w: ~w sentences, ~w characters, ~w calls, ~w + ~w tokens, ~1f s~n",
               [Task, Lang, N, NoteChars, Calls, Prompt, Completion, Seconds])
    ;   NoteChars = 0,
        format(user_error, "restate_prep: no note for ~w ~w (~w calls)~n", [Task, Lang, Calls])
    ),
    lv_model(Model),
    json_codes(json([task-Task, lang-Lang, model-Model, sentences-N,
                     note_chars-NoteChars, spec_chars-SpecChars, calls-Calls,
                     prompt_tokens-Prompt, completion_tokens-Completion,
                     seconds-Seconds]), Row),
    append(Row, [10], Line),
    append_file_from_codes(Log, Line),
    (   N > 0 -> true ; halt(1) ).

rp_args(Args, Tasks, Langs, Dir) :-
    rp_opts(Args, Opts),
    memberchk(tasks-T, Opts), rp_list(T, Tasks),
    memberchk(langs-L, Opts), rp_list(L, Langs),
    memberchk(out-Dir, Opts).

rp_opts([], []).
rp_opts(['--tasks', V|Rest], [tasks-V|Opts]) :- !, rp_opts(Rest, Opts).
rp_opts(['--langs', V|Rest], [langs-V|Opts]) :- !, rp_opts(Rest, Opts).
rp_opts(['--out', V|Rest], [out-V|Opts]) :- !, rp_opts(Rest, Opts).

rp_list(Atom, List) :-
    atomic_list_concat(List, ',', Atom),
    List \== [].
