%% coding/endpoint/reasoning.pl -- the endpoint's reasoning helper.
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
%% repository's own reading of the request. The reading itself is
%% reasoning_core.pl's, shared with the httpd endpoint.

:- use_module('coding/endpoint/reasoning_core.pl').

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [File]
    ->  true
    ;   format(user_error, "usage: cocolog -s reasoning.pl -- TEXT.txt~n", []),
        halt(2)
    ),
    read_file_to_codes(File, Codes),
    atom_codes(Text, Codes),
    endpoint_reason(Text, Obs, CObs, Terms),
    forall(member(O, Obs), format("obligation\t~s~n", [O])),
    forall(member(O, CObs), format("contract\t~s~n", [O])),
    forall(member(T, Terms), format("term\t~q~n", [T])).
