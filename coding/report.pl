%% coding/report.pl -- the run report every code generator shares.
%%
%%     codegen_report_reset/0
%%     codegen_report_finish(+Start)
%%     codegen_report_add(+CallSeconds)
%%     codegen_report_calls(-Calls)
%%     codegen_report(-Report)
%%     codegen_report_print(no|yes)
%%     codegen_cli_failure(+Report, +Ball)
%%
%% One set of predicates and one global prefix, so loading the C, cocolog
%% and Python generators in one process does not merge two reports.
%%
%% codegen_cli_failure/2 is what each command line's catch/3 answers: the
%% report first (the tokens a refused run spent are still seen), then the
%% error. A codegen_error names its kind; any other ball -- a missing key,
%% an HTTP failure, a bad provider -- is printed as the term it is. It
%% never returns: the process ends with exit 1.

:- use_module(library(llm)).

codegen_report_reset :-
    nb_setval('$codegen_calls', 0),
    nb_setval('$codegen_prompt', 0),
    nb_setval('$codegen_completion', 0),
    nb_setval('$codegen_reasoning', 0),
    nb_setval('$codegen_cache', 0),
    nb_setval('$codegen_total', 0),
    nb_setval('$codegen_seconds', 0.0),
    nb_setval('$codegen_verify_model', none),
    nb_setval('$codegen_verify_provider', none),
    nb_setval('$codegen_call_list', []).

codegen_report_finish(Start) :-
    get_time(End),
    Seconds is End - Start,
    nb_setval('$codegen_seconds', Seconds).

codegen_report_add(CallSeconds) :-
    (   catch(nb_getval('$codegen_calls', Calls0), _, fail)
    ->  Calls is Calls0 + 1
    ;   Calls = 1
    ),
    nb_setval('$codegen_calls', Calls),
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  codegen_usage_first(Pairs, prompt_tokens, input_tokens, Prompt),
        codegen_usage_first(Pairs, completion_tokens, output_tokens,
                            Completion),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R0, Details),
            integer(R0)
        ->  Reasoning = R0
        ;   codegen_usage_found(Pairs, reasoning_tokens, R1)
        ->  Reasoning = R1
        ;   Reasoning = 0
        ),
        codegen_usage_first(Pairs, prompt_cache_hit_tokens,
                            cache_read_input_tokens, CacheHit),
        (   codegen_usage_number(Pairs, total_tokens, Total0),
            Total0 > 0
        ->  Total = Total0
        ;   Total is Prompt + Completion
        ),
        codegen_bump('$codegen_prompt', Prompt),
        codegen_bump('$codegen_completion', Completion),
        codegen_bump('$codegen_reasoning', Reasoning),
        codegen_bump('$codegen_cache', CacheHit),
        codegen_bump('$codegen_total', Total),
        codegen_call_record(call(CallSeconds, Prompt, Completion, Reasoning,
                                 CacheHit, Total))
    ;   codegen_call_record(call(CallSeconds, 0, 0, 0, 0, 0))
    ).

codegen_call_record(Call) :-
    (   catch(nb_getval('$codegen_call_list', Calls), _, fail)
    ->  true
    ;   Calls = []
    ),
    nb_setval('$codegen_call_list', [Call|Calls]).

codegen_report_calls(Calls) :-
    (   catch(nb_getval('$codegen_call_list', Reversed), _, fail)
    ->  reverse(Reversed, Calls)
    ;   Calls = []
    ).

codegen_usage_first(Pairs, Key, Alternate, Number) :-
    (   codegen_usage_found(Pairs, Key, Found)
    ->  Number = Found
    ;   codegen_usage_found(Pairs, Alternate, Found)
    ->  Number = Found
    ;   Number = 0
    ).

codegen_usage_found(Pairs, Key, Number) :-
    memberchk(Key-Value, Pairs),
    integer(Value),
    Number = Value.

codegen_usage_number(Pairs, Key, Number) :-
    (   codegen_usage_found(Pairs, Key, Found)
    ->  Number = Found
    ;   Number = 0
    ).

codegen_bump(Global, Number) :-
    (   catch(nb_getval(Global, Old), _, fail)
    ->  true
    ;   Old = 0
    ),
    New is Old + Number,
    nb_setval(Global, New).

codegen_report(report(Calls, Prompt, Completion, Reasoning, CacheHit, Total, Seconds)) :-
    codegen_global('$codegen_calls', Calls),
    codegen_global('$codegen_prompt', Prompt),
    codegen_global('$codegen_completion', Completion),
    codegen_global('$codegen_reasoning', Reasoning),
    codegen_global('$codegen_cache', CacheHit),
    codegen_global('$codegen_total', Total),
    codegen_report_seconds(Seconds).

codegen_report_seconds(Seconds) :-
    (   catch(nb_getval('$codegen_seconds', Found), _, fail),
        float(Found)
    ->  Seconds = Found
    ;   Seconds = 0.0
    ).

%% A report asked before any generation (an early error, say) is zeros.
codegen_global(Global, Value) :-
    (   catch(nb_getval(Global, Current), _, fail)
    ->  Value = Current
    ;   Value = 0
    ).

codegen_report_print(no) :-
    !.
codegen_report_print(yes) :-
    codegen_report_calls(Calls),
    codegen_report_print_calls(Calls, 1),
    codegen_report_verify_model,
    codegen_report(report(Calls0, Prompt, Completion, Reasoning, CacheHit, Total,
                          Seconds)),
    format(user_error,
           'codegen: ~w call(s), ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [Calls0, Prompt, Completion, Total, Reasoning, CacheHit, Seconds]).

%% The command lines' common ending: the report, the error, exit 1.
codegen_cli_failure(Report, Ball) :-
    codegen_report_print(Report),
    (   Ball = error(codegen_error(Kind, Detail), _)
    ->  format(user_error, 'codegen: ~w~n~s~n', [Kind, Detail])
    ;   Ball = error(Term, _)
    ->  format(user_error, 'codegen: ~w~n', [Term])
    ;   format(user_error, 'codegen: ~w~n', [Ball])
    ),
    halt(1).

codegen_report_verify_model :-
    (   catch(nb_getval('$codegen_verify_model', Model), _, fail),
        Model \== none
    ->  (   catch(nb_getval('$codegen_verify_provider', Provider), _, fail),
            Provider \== none
        ->  format(user_error, 'codegen: reference model ~w via ~w~n',
                   [Model, Provider])
        ;   format(user_error, 'codegen: reference model ~w~n', [Model])
        )
    ;   true
    ).

codegen_report_print_calls([], _).
codegen_report_print_calls([call(CallSeconds, Prompt, Completion, Reasoning,
                                 CacheHit, Total)|Rest], N) :-
    format(user_error,
           'codegen call ~w: ~w prompt + ~w completion = ~w tokens (~w reasoning, ~w cached) in ~2f s~n',
           [N, Prompt, Completion, Total, Reasoning, CacheHit, CallSeconds]),
    N1 is N + 1,
    codegen_report_print_calls(Rest, N1).
