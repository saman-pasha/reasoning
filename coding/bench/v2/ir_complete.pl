%% coding/bench/v2/ir_complete.pl -- a COMPLETE IR note: every sentence of a controlled restatement
%% translated to the translator's IR, with no model.
%%
%%     cp -r coding/endpoint/store /tmp/irstore && rm -f /tmp/irstore/lock
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog --embed /tmp/irstore -s coding/bench/v2/ir_complete.pl -- \
%%             coding/bench/v2/controlled/mvccs_acid.txt \
%%             coding/bench/v2/controlled/mvccs_acid.translator.txt OUT
%%
%% THE ENDPOINT'S IR NOTE IS INCOMPLETE. ir_prep.pl has the coding
%% endpoint's translator read the requirement itself, with the model's
%% check and repair, and for mvccs_acid it read 5 of the 14 sentences: the
%% command table, which holds most of the rules, was never among them. The
%% controlled restatement (controlled/TASK.txt) is a text the reasoner's
%% grammar reads whole, so its IR can be whole too -- but the translator's
%% lexicon is not the grammar's: it reads no compound joined by `_'
%% (`latest_version'), and `commit' and `abort' only as verbs.
%%
%% So the restatement has a second form, controlled/TASK.translator.txt:
%% line N is line N of the restatement in a form the translator reads, and
%% reads RIGHT (controlled/README.md says where each came from). This
%% program reads each line of that form with the translator alone -- the
%% repair off, no key, every sentence -- and refuses a pair of files any
%% line of which it does not read. The note gives each sentence of the
%% restatement, its translator form where that differs, and the IR of each
%% of that form's sentences, in the shape of the endpoint's note.
%%
%% The translator reads with the lessons the endpoint's store holds
%% (coding/endpoint/store): run it over a COPY of that store, as above.

:- use_module('coding/endpoint/httpd_core.pl').
:- use_module('coding/endpoint/english_lesson.pl').
:- use_module('coding/endpoint/ir_repair.pl').
:- initialization(ep_english_lesson).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [ControlledFile, ReadyFile, Out|_]
    ->  true
    ;   format(user_error, "usage: ir_complete.pl -- CONTROLLED TRANSLATOR_FORM OUT~n", []),
        halt(2)
    ),
    setenv('CODING_ENDPOINT_IR_REPAIR', off),
    setenv('CODING_ENDPOINT_IR_SENTENCES', 100000),
    unsetenv('CODING_ENDPOINT_IR_KEY'),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    ic_lines(ControlledFile, Cs),
    ic_lines(ReadyFile, Rs),
    length(Cs, N), length(Rs, NR),
    (   N =:= NR
    ->  true
    ;   format(user_error, "ir_complete: ~w lines against ~w~n", [N, NR]),
        halt(1)
    ),
    maplist(ic_entry, Cs, Rs, Entries),
    append(Entries, All),
    atomic_list_concat(All, '\n', Body),
    aggregate_all(count, ( member(L, All), sub_atom(L, 0, _, _, '  - `') ), NIR),
    format(atom(Note),
'~n~n# The request in the translator''s IR~n~nThe translator read the request, said again in controlled English, sentence by sentence, as:~n~n~w',
           [Body]),
    atom_codes(Note, NCs),
    write_file_from_codes(Out, NCs),
    atom_length(Note, Len),
    format("ir_complete: ~w sentences, ~w IR terms, ~w characters to ~w~n", [N, NIR, Len, Out]).

%% One sentence of the restatement and its translator form, read; a form
%% any sentence of which is not read ends the program.
ic_entry(C, R, [Head|Lines]) :-
    ep_ir_readings(R, Readings),
    (   member(reading(S, unread, _), Readings)
    ->  format(user_error, "ir_complete: the translator does not read: ~w~n", [S]),
        halt(1)
    ;   true
    ),
    (   C == R
    ->  format(atom(Head), '- "~w":', [C])
    ;   format(atom(Head), '- "~w", said for the translator as "~w":', [C, R])
    ),
    findall(L, ( member(reading(_, _, IRs), Readings), member(ir(T, _), IRs),
                 format(atom(L), '  - `~w`', [T]) ),
            Lines).

ic_lines(File, Lines) :-
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    atomic_list_concat(Lines0, '\n', Text),
    exclude(==(''), Lines0, Lines).
