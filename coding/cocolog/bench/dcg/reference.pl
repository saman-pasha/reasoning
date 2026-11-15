:- use_module(library(dcg/basics)).

ints([N|Ns]) -->
    integer(N),
    ",",
    !,
    ints(Ns).
ints([N]) -->
    integer(N).

main :-
    atom_codes('3,1,4', Codes1),
    phrase(ints(Ns1), Codes1),
    format("~w~n", [Ns1]),
    atom_codes('2,7', Codes2),
    phrase(ints(Ns2), Codes2),
    format("~w~n", [Ns2]).
