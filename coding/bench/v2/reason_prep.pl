%% coding/bench/v2/reason_prep.pl -- the reason_* readers' notes of a requirement.
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/bench/v2/reason_prep.pl -- \
%%             --task mvccs_acid --langs python --out DIR
%%
%% THE READERS READ CONTROLLED ENGLISH, AND A REQUIREMENT IS NOT. Read as
%% it is, mvccs_acid's requirement gives reason_text/2 nothing -- 0 of its
%% 14 sentences with the grammar, 0 with the tagger, one (and that one
%% wrong) in live mode -- so reason_concepts/2, reason_topics/2 and
%% reason_outline/2 have nothing either, and an arm made of them is the
%% prompt alone. So the notes are made from a CONTROLLED RESTATEMENT,
%% coding/bench/v2/controlled/TASK.txt: the requirement's sentences said
%% again in sentences the grammar reads, one a line, written by hand from
%% the requirement alone and saying nothing the requirement does not (its
%% README). This program reads it whole with the grammar alone
%% (reason_grammar/1: no tagger, no saved rewrite, no model) and refuses a
%% restatement any line of which the grammar refuses.
%%
%% For each language it writes, to DIR/TASK-LANG.KIND:
%%
%%   controlled   the restatement itself
%%   terms        reason_text/2's terms, one a line
%%   concepts     reason_concepts/2: each concept, its kind and its mentions
%%   outline      reason_topics/2 and reason_topic_lines/2: a line a subject
%%
%% and a row a note to DIR/reason-prep.jsonl: the kind, the reasoning
%% version, the lines and the characters. The notes are the same for every
%% language; a language only names the file the runner reads. No model is
%% called.

:- use_module(library(json)).
:- use_module(library(reasoning/reason)).
:- use_module('coding/bench/v2/langs.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   rp_args(Args, Task, Langs, Dir)
    ->  true
    ;   format(user_error, "usage: reason_prep.pl -- --task T --langs A,B --out DIR~n", []),
        halt(2)
    ),
    v2_language_task(Task),
    forall(member(L, Langs), v2_language_supported(L)),
    format(atom(Source), 'coding/bench/v2/controlled/~w.txt', [Task]),
    (   exists_file(Source)
    ->  true
    ;   format(user_error, "reason_prep: no restatement ~w~n", [Source]),
        halt(1)
    ),
    read_file_to_codes(Source, Codes),
    atom_codes(Text0, Codes),
    rp_trim(Text0, Text),
    reason_set_mode(static),
    reason_set_tagger(off),
    rp_refused(Text),
    reason_grammar(reason_text(Text, Terms)),
    reason_concepts(Terms, Concepts),
    reason_topics(Terms, Topics),
    reason_topic_lines(Topics, Outline),
    catch(make_directory(Dir), _, true),
    reason_version(Version),
    get_time(Now), Stamp is round(Now * 1000),
    format(atom(Log), '~w/reason-prep.jsonl', [Dir]),
    rp_note(controlled, Text, Terms, Concepts, Outline, Controlled),
    rp_note(terms, Text, Terms, Concepts, Outline, TermsNote),
    rp_note(concepts, Text, Terms, Concepts, Outline, ConceptsNote),
    rp_note(outline, Text, Terms, Concepts, Outline, OutlineNote),
    forall(( member(Lang, Langs),
             member(Kind-Note, [controlled-Controlled, terms-TermsNote,
                                concepts-ConceptsNote, outline-OutlineNote]) ),
           rp_write(Dir, Log, Stamp, Version, Task, Lang, Kind, Note)),
    length(Terms, NT), length(Concepts, NC), length(Outline, NO),
    format("reason prep: ~w terms, ~w concepts, ~w outline lines, for ~w~n", [NT, NC, NO, Langs]).

%% a line the grammar refuses is named, and nothing is written
rp_refused(Text) :-
    (   reason_grammar(reason_refused(Text, Sentence))
    ->  format(user_error, "reason_prep: the grammar refuses: ~w~n", [Sentence]),
        halt(1)
    ;   true
    ).

rp_note(controlled, Text, _, _, _, Note) :-
    format(atom(Note),
'~n~n# The request in controlled English~n~nThe same requirement, said again in the controlled English the repository\'s reasoner reads, one sentence a line:~n~n~w', [Text]).
rp_note(terms, _, Terms, _, _, Note) :-
    findall(L, ( member(T0, Terms), copy_term(T0, T), numbervars(T, 0, _),
                 format(atom(L), '~W', [T, [quoted(true), numbervars(true)]]) ), Ls),
    atomic_list_concat(Ls, '\n', Body),
    format(atom(Note),
'~n~n# The request as logic (reason_text/2)~n~nThe reasoner\'s reading of the requirement, said again in controlled English: one Prolog term a line, a fact or a rule Head :- Body, neg(Fact) a denial, a variable a thing the sentence introduced with a or every.~n~n~w', [Body]).
rp_note(concepts, _, _, Concepts, _, Note) :-
    findall(L, ( member(concept(N, K, C), Concepts),
                 format(atom(L), '- ~w: ~w, mentioned ~w times', [N, K, C]) ), Ls),
    atomic_list_concat(Ls, '\n', Body),
    format(atom(Note),
'~n~n# What the request mentions (reason_concepts/2)~n~nEach concept the requirement mentions, with its kind (name, individual, class, property or relation) and how often, the most mentioned first:~n~n~w', [Body]).
rp_note(outline, _, _, _, Outline, Note) :-
    findall(L, ( member(O, Outline), format(atom(L), '- ~w', [O]) ), Ls),
    atomic_list_concat(Ls, '\n', Body),
    format(atom(Note),
'~n~n# What the request is about (reason_topics/2)~n~nAn outline of the requirement, a line a subject, the subject most said about first:~n~n~w', [Body]).

rp_write(Dir, Log, Stamp, Version, Task, Lang, Kind, Note) :-
    format(atom(File), '~w/~w-~w.~w', [Dir, Task, Lang, Kind]),
    atom_codes(Note, Codes),
    write_file_from_codes(File, Codes),
    atom_length(Note, Chars),
    atomic_list_concat(Lines, '\n', Note), length(Lines, NL),
    Row = json([run-Stamp, task-Task, language-Lang, kind-Kind,
                reasoning-Version, lines-NL, chars-Chars]),
    json_codes(Row, RowCodes),
    append(RowCodes, [0'\n], Line),
    append_file_from_codes(Log, Line),
    format("~w/~w: ~w note, ~w characters~n", [Task, Lang, Kind, Chars]).

rp_trim(A0, A) :-
    atom_codes(A0, Cs0),
    reverse(Cs0, R0), rp_drop(R0, R1), reverse(R1, Cs1), rp_drop(Cs1, Cs),
    atom_codes(A, Cs).
rp_drop([C|Cs], Ds) :- C =< 32, !, rp_drop(Cs, Ds).
rp_drop(Cs, Cs).

rp_args(Args, Task, Langs, Dir) :-
    rp_flags(Args, Pairs),
    memberchk(task-Task, Pairs),
    memberchk(langs-LangText, Pairs),
    memberchk(out-Dir, Pairs),
    atomic_list_concat(Langs0, ',', LangText),
    exclude(==(''), Langs0, Langs),
    Langs \== [].

rp_flags([], []).
rp_flags([Flag, Value|Rest], [Name-Value|Pairs]) :-
    atom_concat('--', Name, Flag),
    rp_flags(Rest, Pairs).
