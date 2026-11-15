ns_member(special, [special|_]).
ns_member(special, [_|Rest]) :-
    ns_member(special, Rest).

main :-
    findall(X, ns_member(X, [special, ordinary, special]), Found),
    format("~w~n", [Found]).
