%% coding/bench/v2/reasoning_schema.pl -- the Phase 5 reasoning tasks.
%%
%% Three tasks where the declarative form is the point: a transitive
%% closure, a topological order with many valid answers, and the number
%% of parse trees of an ambiguous grammar. Each is declared once with its
%% cases, held-out split, output policy and budget; the two forms differ
%% only in the requirement's first sentence.

:- use_module('coding/shell.pl').

v2_reasoning_task(reach).
v2_reasoning_task(topo).
v2_reasoning_task(parses).

v2_reasoning_form(imperative, python).
v2_reasoning_form(declarative, cocolog).

v2_reasoning_head(imperative,
                  'Write a complete Python 3 program. ').
v2_reasoning_head(declarative,
                  'Write a complete cocolog program of facts, relations and rules whose main/0 reads standard input and writes standard output. ').

v2_reasoning_spec(Form, Task, Spec) :-
    v2_reasoning_form(Form, _),
    v2_reasoning_task(Task),
    v2_reasoning_head(Form, Head),
    v2_reasoning_requirement(Task, Rest),
    atom_concat(Head, Rest, Spec).

v2_reasoning_requirement(reach,
    'The first line is "n m": n nodes numbered from 1 to n, and m directed edges. Each of the next m lines is "u v", an edge from u to v. The last line is the start node s. Print every node reachable from s, including s, on one line separated by single spaces, in increasing order.').
v2_reasoning_requirement(topo,
    'The first line is "n m": n nodes numbered from 1 to n, and m directed edges. Each of the next m lines is "u v", an edge from u to v. The graph is acyclic. Print a topological order of the nodes on one line separated by single spaces: each node once, and for every edge u v, u appears before v. Any valid order is accepted.').
v2_reasoning_requirement(parses,
    'Read one line of lowercase letters a and b. A phrase is one letter, or two phrases written one after the other (the grammar S -> S S | a | b). Print the number of distinct parse trees for the line, modulo 1000000007.').

v2_reasoning_task(reach, Repair, Heldout, exact, budget(3, 10000, 0)) :-
    Repair =
        [ case('3 2\n1 2\n2 3\n1\n', '1 2 3\n'),
          case('4 2\n1 2\n3 4\n2\n', '2\n'),
          %% The pre-registered run gave this case the header "3 3" with
          %% two edges; the header must match the edge count. Corrected
          %% to "3 2" before the rerun. The other cases are unchanged.
          case('3 2\n1 2\n2 1\n3\n', '3\n'),
          case('5 4\n1 2\n2 3\n3 4\n4 5\n1\n', '1 2 3 4 5\n')
        ],
    Heldout =
        [ case('5 4\n1 2\n2 3\n3 4\n4 5\n3\n', '3 4 5\n'),
          case('6 5\n1 2\n2 3\n3 1\n4 5\n5 6\n4\n', '4 5 6\n')
        ].
v2_reasoning_task(topo, Repair, Heldout, property(v2_topo_check),
                  budget(3, 10000, 0)) :-
    Repair =
        [ case('3 2\n1 2\n1 3\n', any),
          case('4 3\n1 2\n2 3\n3 4\n', any),
          case('4 2\n1 2\n3 4\n', any),
          case('5 4\n1 2\n1 3\n2 4\n3 5\n', any)
        ],
    Heldout =
        [ case('5 4\n1 2\n2 3\n1 4\n4 5\n', any),
          case('6 4\n1 2\n2 3\n4 5\n5 6\n', any)
        ].
v2_reasoning_task(parses, Repair, Heldout, exact, budget(3, 10000, 0)) :-
    Repair =
        [ case('a\n', '1\n'),
          case('aaa\n', '2\n'),
          case('abba\n', '5\n'),
          case('aab\n', '2\n')
        ],
    Heldout =
        [ case('aaaaa\n', '14\n'),
          case('\n', '0\n')
        ].

v2_reasoning_check :-
    forall(v2_reasoning_task(Task),
           (   v2_reasoning_task(Task, Repair, Heldout, _, _),
               Repair \== [],
               Heldout \== []
           )).

v2_reasoning_case(Task, Case) :-
    v2_reasoning_task(Task, Repair, Heldout, _, _),
    (   member(Case, Repair)
    ;   member(Case, Heldout)
    ).

%% The graph cases must say how many edges they give: a header "n m"
%% with m edge lines (and, for reach, the start node after them). The
%% first pre-registered reach run had "3 3" with two edges, which made
%% both forms fail; this check is why it cannot recur.
v2_reasoning_case_ok(Task, case(Input, _)) :-
    memberchk(Task, [reach, topo]),
    !,
    split_string(Input, "\n", " \t\r", Lines0),
    exclude(v2_reasoning_blank, Lines0, Lines),
    Lines = [First|Rest],
    split_string(First, " ", " \t\r", [NS, MS]),
    v2_reasoning_number(NS, N),
    v2_reasoning_number(MS, M),
    (   Task == reach
    ->  length(Rest, M1),
        M1 =:= M + 1,
        append(EdgeLines, [StartLine], Rest),
        split_string(StartLine, " ", " \t\r", [SS]),
        v2_reasoning_number(SS, S),
        S >= 1,
        S =< N
    ;   EdgeLines = Rest,
        length(EdgeLines, M)
    ),
    forall(member(Line, EdgeLines), v2_reasoning_edge_ok(Line, N)).
v2_reasoning_case_ok(_, _).

v2_reasoning_edge_ok(Line, N) :-
    split_string(Line, " ", " \t\r", [US, VS]),
    v2_reasoning_number(US, U),
    v2_reasoning_number(VS, V),
    U >= 1,
    U =< N,
    V >= 1,
    V =< N.

%% ---- the topological order's property ---------------------------------

v2_topo_check(Input, Actual, Result) :-
    (   catch(v2_topo_check_1(Input, Actual), Ball,
              (   Ball = v2_topo(Why)
              ->  Result = fail(Why)
              ;   v2_error_text(Ball, Text),
                  Result = fail(Text)
              ))
    ->  (   var(Result)
        ->  Result = ok
        ;   true
        )
    ;   Result = fail('the output is not a valid topological order')
    ).

v2_topo_check_1(Input, Actual) :-
    v2_topo_input(Input, N, Edges),
    v2_topo_nodes(Actual, Nodes),
    length(Nodes, N),
    findall(I, between(1, N, I), All),
    msort(Nodes, Sorted),
    Sorted == All,
    v2_topo_positions(Nodes, 1, Pos),
    v2_topo_edges(Edges, Pos).

v2_topo_input(Input, N, Edges) :-
    split_string(Input, "\n", " \t\r", Lines0),
    exclude(v2_reasoning_blank, Lines0, Lines),
    Lines = [First|EdgeLines],
    split_string(First, " ", " \t\r", [NS, MS]),
    v2_reasoning_number(NS, N),
    v2_reasoning_number(MS, M),
    length(EdgeLines, M),
    maplist(v2_topo_edge, EdgeLines, Edges).

v2_topo_edge(Line, U-V) :-
    split_string(Line, " ", " \t\r", [US, VS]),
    v2_reasoning_number(US, U),
    v2_reasoning_number(VS, V).

v2_topo_nodes(Actual, Nodes) :-
    split_string(Actual, " \t\r\n", " ", Tokens0),
    exclude(v2_reasoning_blank, Tokens0, Tokens),
    maplist(v2_reasoning_number, Tokens, Nodes).

v2_topo_positions([], _, []).
v2_topo_positions([N|Ns], I, [N-I|Ps]) :-
    I1 is I + 1,
    v2_topo_positions(Ns, I1, Ps).

v2_topo_edges([], _).
v2_topo_edges([U-V|Edges], Pos) :-
    (   memberchk(U-PU, Pos),
        memberchk(V-PV, Pos),
        PU < PV
    ->  v2_topo_edges(Edges, Pos)
    ;   format(atom(Why), 'edge ~w ~w is not in order', [U, V]),
        throw(v2_topo(Why))
    ).

v2_reasoning_number(Text, N) :-
    atom_string(A, Text),
    atom_number(A, N),
    integer(N).

v2_reasoning_blank(Text) :-
    (   string(Text)
    ->  string_length(Text, 0)
    ;   Text == ''
    ).
