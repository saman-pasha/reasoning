main :-
    read_file_to_codes('coding/cocolog/bench/file/lines.txt', Codes),
    lines(Codes, 1).

lines([], _) :-
    !.
lines(Codes, N) :-
    split_line(Codes, Line, Rest),
    atom_codes(Atom, Line),
    format("~w: ~w~n", [N, Atom]),
    N1 is N + 1,
    lines(Rest, N1).

split_line([10|Rest], [], Rest) :-
    !.
split_line([C|Codes], [C|Line], Rest) :-
    split_line(Codes, Line, Rest).
split_line([], [], []).
