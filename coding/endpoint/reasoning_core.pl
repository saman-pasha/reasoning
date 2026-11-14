%% coding/endpoint/reasoning_core.pl -- the endpoint's reasoning reading.
%%
%%     endpoint_reason(+Text, -Obligations, -Contract, -Terms)
%%
%% Text is an atom or codes. Obligations come from coding/obligations.pl's
%% keywords, Contract from coding/contract.pl's controlled English, and
%% Terms from library(reasoning/reason)'s parser. A reader that fails
%% contributes an empty list; a request never fails because one did.

:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module(library(reasoning/reason)).

endpoint_reason(Text, Obs, CObs, Terms) :-
    (   catch(codegen_obligations(Text, Obs0), _, fail)
    ->  Obs = Obs0
    ;   Obs = []
    ),
    (   catch(codegen_contract_obligations(Text, CObs0), _, fail)
    ->  CObs = CObs0
    ;   CObs = []
    ),
    (   catch(reason_text(Text, Terms0), _, fail)
    ->  true
    ;   Terms0 = []
    ),
    (   length(Terms0, N), N > 20
    ->  length(Terms, 20)
    ;   Terms = Terms0
    ).
