%% tools/logic/prose.pl -- how many of lexicon/prose.txt's 8 000 sentences
%% (the first measure's, WordNet's example sentences) go each way: read
%% into the typology IR (level 1) and written back into English
%% (typology_write/3; since 1.76.0), and the same sentence again; and read
%% into the IR, made a logic form (level 2) and written as Cocolog.
%%
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s tools/logic/prose.pl [-- FILE]
%%
%% FILE is lexicon/prose.txt unless named, a sentence a line. Prints the
%% count read into level 1, the counts written back into English and the
%% same, the count translated into Cocolog, and why the others read
%% into level 1 have no Cocolog (logic_why/2's reason for the first IR, by
%% its kind), the commonest first. A sentence is given 4 000 000
%% inferences at each level. A count translated is not a count right: the
%% Cocolog is not checked (lexicon/logic.txt, the second measure, is).
%% STATUS.md records the counts of each version.

:- use_module(library(reasoning/typology)).
:- use_module(library(reasoning/logic)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [F|_] -> true ; F = 'lexicon/prose.txt' ),
    typology_load(english),
    read_file_to_codes(F, Codes), atom_codes(Text, Codes),
    atomic_list_concat(Lines0, '\n', Text),
    exclude(==(''), Lines0, Lines),
    length(Lines, N),
    foldl(prose_one, Lines, c(0, 0, 0, 0, []), c(Read, Back, Same, Done, Ws)),
    P1 is 100 * Read / N, P2 is 100 * Done / N, P3 is 100 * Back / N, P4 is 100 * Same / N,
    format("~w sentences (~w)~n", [N, F]),
    format("read into level 1: ~w (~2f %)~n", [Read, P1]),
    format("into level 1, then English: ~w (~2f %), the same sentence ~w (~2f %)~n", [Back, P3, Same, P4]),
    format("translated into Cocolog: ~w (~2f %)~n", [Done, P2]),
    msort(Ws, Ws1), clumped(Ws1, Cs), sort(2, @>=, Cs, Cs1),
    format("why a sentence read into level 1 has no Cocolog:~n", []),
    forall(member(W-C, Cs1), format("  ~w ~q~n", [C, W])).

prose_one(S, c(A0, E0, Q0, B0, W0), c(A, E, Q, B, W)) :-
    (   prose_limit(once(typology_read(english, S, IR)))
    ->  A is A0 + 1,
        (   prose_limit(once(typology_write(english, IR, S2)))
        ->  E is E0 + 1, ( S2 == S -> Q is Q0 + 1 ; Q = Q0 )
        ;   E = E0, Q = Q0
        ),
        (   prose_limit(once(( logic_read(english, S, U), cocolog_write(U, _) )))
        ->  B is B0 + 1, W = W0
        ;   B = B0,
            ( catch(logic_why(IR, Y), _, fail) -> prose_kind(Y, K) ; K = unknown ),
            W = [K|W0]
        )
    ;   A = A0, E = E0, Q = Q0, B = B0, W = W0
    ).

prose_limit(G) :-
    catch(call_with_inference_limit(G, 4000000, R), _, fail),
    R \== inference_limit_exceeded.

%% A reason by its kind: tense(past) as it is, shape(IR) as shape/1.
prose_kind(Y, K) :-
    (   compound(Y), arg(1, Y, X), atomic(X) -> K = Y
    ;   compound(Y) -> functor(Y, F, Ar), K = F/Ar
    ;   K = Y
    ).
