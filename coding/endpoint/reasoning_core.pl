%% coding/endpoint/reasoning_core.pl -- the endpoint's reasoning reading.
%%
%%     endpoint_reason(+Text, -Obligations, -Contract, -Terms)
%%     endpoint_reason(+Language, +Text, -Obligations, -Contract, -Terms)
%%
%% Text is an atom or codes. Obligations come from the language's keyword
%% reader, Contract from coding/contract.pl's controlled English for C and
%% cocolog, and Terms from library(reasoning/reason)'s parser. A reader
%% that fails contributes an empty list; a request never fails because one
%% did.

:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module('coding/python/obligations.pl').
:- use_module(library(reasoning/reason)).

endpoint_reason(Text, Obs, CObs, Terms) :-
    endpoint_reason(c, Text, Obs, CObs, Terms).

endpoint_reason(Language, Text, Obs, CObs, Terms) :-
    endpoint_obligations(Language, Text, Obs),
    endpoint_contract(Language, Text, CObs),
    (   catch(reason_text(Text, Terms0), _, fail)
    ->  true
    ;   Terms0 = []
    ),
    (   length(Terms0, N), N > 20
    ->  length(Terms, 20)
    ;   Terms = Terms0
    ).

endpoint_obligations(c, Text, Obs) :-
    (   catch(codegen_obligations(Text, Obs0), _, fail)
    ->  Obs = Obs0
    ;   Obs = []
    ).
endpoint_obligations(cocolog, Text, Obs) :-
    endpoint_obligations(c, Text, Obs).
endpoint_obligations(python, Text, Obs) :-
    (   catch(codegen_python_obligations(Text, Obs0), _, fail)
    ->  true
    ;   Obs0 = []
    ),
    (   catch(codegen_python_sanity_checks(Sanity), _, fail)
    ->  true
    ;   Sanity = []
    ),
    append(Obs0, Sanity, Obs).

endpoint_contract(c, Text, CObs) :-
    (   catch(codegen_contract_obligations(Text, CObs0), _, fail)
    ->  CObs = CObs0
    ;   CObs = []
    ).
endpoint_contract(cocolog, Text, CObs) :-
    endpoint_contract(c, Text, CObs).
endpoint_contract(python, _, []).
