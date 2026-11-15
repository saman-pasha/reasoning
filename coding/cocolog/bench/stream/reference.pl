:- use_module(library(stream)).

main :-
    stream_open('coding/cocolog/bench/stream/lines.txt', read, Stream),
    read_lines(Stream, 1),
    stream_close(Stream).

read_lines(Stream, N) :-
    stream_read_line(Stream, Codes),
    (   Codes == end_of_file
    ->  true
    ;   atom_codes(Atom, Codes),
        format("~w: ~w~n", [N, Atom]),
        N1 is N + 1,
        read_lines(Stream, N1)
    ).
