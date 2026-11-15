:- use_module(library(json)).

main :-
    json_parse('{"name":"Ada","n":42,"ok":true}', json(Pairs)),
    memberchk(name-Name, Pairs),
    format("~w~n", [Name]),
    json_atom(json([lang-json([name-'Ada']), ok- @(true)]), Json),
    format("~w~n", [Json]).
