%% coding/endpoint/reasoning.pl -- the endpoint's local reasoning pre-pass.
%%
%%     cocolog -s coding/endpoint/reasoning.pl -- TEXT.txt
%%
%% The file is a request from OpenCode. The output is one line a finding:
%%
%%     obligation<TAB>text      from coding/obligations.pl's keywords
%%     contract<TAB>text        from coding/contract.pl's controlled English
%%     term<TAB>term            from library(reasoning/reason)'s parser
%%
%% Nothing here calls a model. The endpoint appends the findings to the
%% language guide, so the cocolog session is checked against this
%% repository's own reading of the request.

:- use_module('coding/obligations.pl').
:- use_module('coding/contract.pl').
:- use_module(library(reasoning/reason)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [File]
    ->  true
    ;   format(user_error, "usage: cocolog -s reasoning.pl -- TEXT.txt~n", []),
        halt(2)
    ),
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    (   catch(codegen_obligations(Text, Obs), _, fail)
    ->  true
    ;   Obs = []
    ),
    (   catch(codegen_contract_obligations(Text, CObs), _, fail)
    ->  true
    ;   CObs = []
    ),
    (   catch(reason_text(Text, Terms0), _, fail)
    ->  true
    ;   Terms0 = []
    ),
    (   length(Terms0, N), N > 20
    ->  length(Terms, 20)
    ;   Terms = Terms0
    ),
    forall(member(O, Obs), format("obligation\t~s~n", [O])),
    forall(member(O, CObs), format("contract\t~s~n", [O])),
    forall(member(T, Terms), format("term\t~q~n", [T])).
