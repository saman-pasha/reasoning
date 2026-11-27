%% tools/logic/prose.pl -- how many of lexicon/prose.txt's 8 000 sentences
%% (the first measure's, WordNet's example sentences) go each way: read
%% into the typology IR (level 1) and written back into English
%% (typology_write/3; since 1.76.0), and the same sentence again; and read
%% into the IR, made a logic form (level 2) and written as Cocolog.
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/logic/prose.pl [-- [FILE] [jobs=N] [table=OUT]]
%%
%% FILE is lexicon/prose.txt unless named, a sentence a line. Prints the
%% count read into level 1, the counts written back into English and the
%% same, the count translated into Cocolog, and why the others read
%% into level 1 have no Cocolog (logic_why/2's reason for the first IR, by
%% its kind), the commonest first. A sentence is given 4 000 000
%% inferences at each level. A count translated is not a count right: the
%% Cocolog is not checked (lexicon/logic.txt, the second measure, is).
%% STATUS.md records the counts of each version.
%%
%% jobs=N (since 1.137.0) reads the sentences in N child processes at once,
%% each the lines whose number modulo N is its part (part=K/N out=FILE, its
%% records written to a file of os_tmp/1), and prints what one process
%% prints: each sentence is read alone, so the counts are the same.
%% table=OUT writes a line a sentence, in the file's order: the sentence,
%% its first IR (writeq) and its Cocolog on one line, or none, tab
%% between.

:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).
:- use_module(library(process)).
:- use_module(library(os)).

:- dynamic prose_self/1.
:- prolog_load_context(file, F), assertz(prose_self(F)).

main :-
    current_prolog_flag(argv, [_|Args]),
    prose_args(Args, 'lexicon/prose.txt', F, 1, Jobs, none, Table, none, Part, none, Out),
    read_file_to_codes(F, Codes), atom_codes(Text, Codes),
    atomic_list_concat(Lines0, '\n', Text),
    exclude(==(''), Lines0, Lines),
    (   Part = K/N
    ->  typology_load(english),
        prose_part(Lines, K, N, Out)
    ;   Jobs > 1
    ->  prose_jobs(F, Jobs, Lines, Recs),
        prose_report(F, Lines, Recs, Table)
    ;   typology_load(english),
        maplist(prose_rec, Lines, Recs),
        prose_report(F, Lines, Recs, Table)
    ).

prose_args([], F, F, J, J, T, T, P, P, O, O).
prose_args([A|As], F0, F, J0, J, T0, T, P0, P, O0, O) :-
    (   atom_concat('jobs=', V, A) -> atom_number(V, J1), prose_args(As, F0, F, J1, J, T0, T, P0, P, O0, O)
    ;   atom_concat('table=', V, A) -> prose_args(As, F0, F, J0, J, V, T, P0, P, O0, O)
    ;   atom_concat('part=', V, A) -> term_to_atom(P1, V), prose_args(As, F0, F, J0, J, T0, T, P1, P, O0, O)
    ;   atom_concat('out=', V, A) -> prose_args(As, F0, F, J0, J, T0, T, P0, P, V, O)
    ;   prose_args(As, A, F, J0, J, T0, T, P0, P, O0, O)
    ).

%% A sentence's record: r(Read, Back, Same, Done, Kind, IR, Cocolog), each
%% count 0 or 1, Kind the reason of a sentence read with no Cocolog.
prose_rec(S, r(A, E, Q, B, K, IR, C)) :-
    (   prose_limit(once(typology_read(english, S, IR)))
    ->  A = 1,
        (   prose_limit(once(typology_write(english, IR, S2)))
        ->  E = 1, ( S2 == S -> Q = 1 ; Q = 0 )
        ;   E = 0, Q = 0
        ),
        (   prose_limit(once(( logic_read(english, S, U), cocolog_write(U, C0) )))
        ->  B = 1, K = none, atomic_list_concat(Ps, '\n', C0), atomic_list_concat(Ps, ' ', C)
        ;   B = 0, C = none,
            ( catch(logic_why(IR, Y), _, fail) -> prose_kind(Y, K) ; K = unknown )
        )
    ;   A = 0, E = 0, Q = 0, B = 0, K = none, IR = none, C = none
    ).

prose_report(F, Lines, Recs, Table) :-
    length(Lines, N),
    foldl(prose_add, Recs, c(0, 0, 0, 0, []), c(Read, Back, Same, Done, Ws)),
    P1 is 100 * Read / N, P2 is 100 * Done / N, P3 is 100 * Back / N, P4 is 100 * Same / N,
    format("~w sentences (~w)~n", [N, F]),
    format("read into level 1: ~w (~2f %)~n", [Read, P1]),
    format("into level 1, then English: ~w (~2f %), the same sentence ~w (~2f %)~n", [Back, P3, Same, P4]),
    format("translated into Cocolog: ~w (~2f %)~n", [Done, P2]),
    msort(Ws, Ws1), clumped(Ws1, Cs), sort(2, @>=, Cs, Cs1),
    format("why a sentence read into level 1 has no Cocolog:~n", []),
    forall(member(W-C, Cs1), format("  ~w ~q~n", [C, W])),
    ( Table == none -> true ; prose_table(Table, Lines, Recs) ).

prose_add(r(A, E, Q, B, K, _, _), c(A0, E0, Q0, B0, W0), c(A1, E1, Q1, B1, W1)) :-
    A1 is A0 + A, E1 is E0 + E, Q1 is Q0 + Q, B1 is B0 + B,
    ( A =:= 1, B =:= 0 -> W1 = [K|W0] ; W1 = W0 ).

prose_table(Table, Lines, Recs) :-
    open(Table, write, O),
    forall(nth1(I, Lines, S),
           ( nth1(I, Recs, r(_, _, _, _, _, IR, C)), format(O, "~w\t~q\t~w~n", [S, IR, C]) )),
    close(O).

%% A child's part: the lines whose number (from 0) modulo N is K, each
%% record i(Number, Record) written to Out.
prose_part(Lines, K, N, Out) :-
    open(Out, write, O),
    forall(( nth0(I, Lines, S), I mod N =:= K ),
           ( prose_rec(S, R), writeq(O, i(I, R)), write(O, '.\n') )),
    close(O).

%% N children at once, then their records in the file's order.
prose_jobs(F, N, Lines, Recs) :-
    prose_self(Self), current_prolog_flag(executable, Exe),
    os_tmp(Tmp), os_pid(Pid), N1 is N - 1,
    findall(K-Out, ( between(0, N1, K), format(atom(Out), '~w/prose_~w_~w.txt', [Tmp, Pid, K]) ), Parts),
    findall(K-P, ( member(K-Out, Parts),
                   format(atom(Cmd), 'exec ~q -s ~q -- ~q part=~w/~w out=~q', [Exe, Self, F, K, N, Out]),
                   proc_spawn(Cmd, P) ), Pids),
    forall(member(K-P, Pids), ( proc_wait(P, 86400000, X), ( X == 0 -> true ; format(user_error, "part ~w exited ~w~n", [K, X]), fail ) )),
    findall(I-R, ( member(_-Out, Parts), prose_read(Out, Is), member(i(I, R), Is) ), IRs0),
    forall(member(_-Out, Parts), delete_file(Out)),
    keysort(IRs0, IRs), pairs_values(IRs, Recs),
    length(Lines, L), length(Recs, L).

prose_read(File, Ts) :-
    open(File, read, In), prose_terms(In, Ts), close(In).
prose_terms(In, Ts) :-
    read_term(In, T, []), ( T == end_of_file -> Ts = [] ; Ts = [T|Ts1], prose_terms(In, Ts1) ).

prose_limit(G) :-
    catch(call_with_inference_limit(G, 4000000, R), _, fail),
    R \== inference_limit_exceeded.

%% A reason by its kind: tense(past) as it is, shape(IR) as shape/1.
prose_kind(Y, K) :-
    (   compound(Y), arg(1, Y, X), atomic(X) -> K = Y
    ;   compound(Y) -> functor(Y, F, Ar), K = F/Ar
    ;   K = Y
    ).
