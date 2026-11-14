%% coding/endpoint/httpd.pl -- start the non-streaming cocolog endpoint.
%%
%%     ../cocolog/cocolog -s coding/endpoint/httpd.pl
%%
%% The pages live in httpd_core.pl. This file only reads the port, says
%% what the guards are, and serves.
%%
%% The endpoint binds INADDR_ANY because library(tcp) has no host argument;
%% set CODING_ENDPOINT_TOKEN and keep the port behind a firewall.

:- use_module(library(httpd)).
:- use_module('coding/endpoint/httpd_core.pl').

main :-
    ep_int('CODING_ENDPOINT_PORT', 8787, Port),
    ep_backend_url(Backend),
    format("cocolog coding endpoint on port ~w (non-streaming backend: ~w)~n",
           [Port, Backend]),
    ep_token(Token),
    (   Token == ''
    ->  format(user_error,
               "warning: CODING_ENDPOINT_TOKEN is empty; the port is open to every client~n", [])
    ;   format(user_error, "every request needs Authorization: Bearer TOKEN~n", [])
    ),
    httpd_serve(Port, [ max_request(16777216),
                        page_limit(100000000),
                        concurrency(none),
                        keep_alive(true),
                        read_timeout(15000),
                        accept_timeout(3600000) ]).
