main :-
    "hello" = [First|_],
    length("hello", Length),
    format("~w ~w~n", [First, Length]),
    atom_length('hello', AtomLength),
    format("~w ~w~n", ['hello', AtomLength]).
