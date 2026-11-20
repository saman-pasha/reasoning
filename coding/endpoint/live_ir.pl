%% coding/endpoint/live_ir.pl -- the IR check and repair against a real model.
%%
%%     CODING_ENDPOINT_IR_API=anthropic \
%%     CODING_ENDPOINT_IR_KEY="$TEST_API_KEY" \
%%     CODING_ENDPOINT_IR_MODEL="$TEST_MODEL" \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog --embed coding/endpoint/store \
%%             -s coding/endpoint/live_ir.pl -- [TASK...]
%%
%% Reads the requirement of each benchmark task (coding/bench/tasks.pl;
%% sum_even, max_subarray and calculator unless named) the way the endpoint
%% reads a request, with the model's help, and prints how each sentence was
%% read, whether the model judged the reading right, the calls and the
%% tokens. THIS COSTS MONEY: every reading the model has not judged, and
%% every sentence the translator cannot read, is sent to the model, at most
%% CODING_ENDPOINT_IR_ROUNDS calls a task. Run it again on the same store and
%% it makes no call, because the lessons, the rewrites and the verdicts were
%% kept: that second run is the check that they were.
%%
%% coding/endpoint/store is the store the endpoint itself runs on
%% (run-httpd.sh), committed so what one machine learned is the next one's
%% start. No key, and it says so and stops before any call. It is not part
%% of coding/endpoint/test.pl, which asks no model.

:- use_module('coding/endpoint/httpd_core.pl').
:- use_module('coding/endpoint/english_lesson.pl').
:- use_module('coding/bench/tasks.pl').
:- initialization(ep_english_lesson).

main :-
    (   ep_ir_key(_)
    ->  true
    ;   format(user_error, "live_ir: no key: set CODING_ENDPOINT_IR_KEY or CODING_ENDPOINT_KEY_ENV~n", []),
        halt(2)
    ),
    current_prolog_flag(argv, [_|Args]),
    (   Args == []
    ->  Tasks = [sum_even, max_subarray, calculator]
    ;   Tasks = Args
    ),
    ep_ir_model(Model),
    format("model ~w~n", [Model]),
    foldl(live_task, Tasks, t(0, 0, 0), t(Calls, Prompt, Completion)),
    format("~ntotal: ~w calls, ~w prompt tokens, ~w completion tokens~n",
           [Calls, Prompt, Completion]).

live_task(Name, t(C0, P0, K0), t(C, P, K)) :-
    (   bench_task(Name, Spec, _)
    ->  format("~n== ~w~n", [Name]),
        ep_ir_readings(Spec, Readings),
        forall(member(R, Readings), live_reading(R)),
        ep_ir_stats(ir(_, _, _, _, _, Lessons, Calls, Prompt, Completion, Right, Wrong)),
        format("   ~w calls, ~w lessons, ~w judged right, ~w judged wrong, ~w + ~w tokens~n",
               [Calls, Lessons, Right, Wrong, Prompt, Completion]),
        ep_ir_refused(Refused),
        forall(member(L, Refused),
               format("   taken back, as it changed a confirmed reading: ~w~n", [L])),
        C is C0 + Calls, P is P0 + Prompt, K is K0 + Completion
    ;   format("~n== ~w: no such task~n", [Name]),
        C = C0, P = P0, K = K0
    ).

live_reading(reading(S0, How, IRs)) :-
    ep_ir_display(S0, S),
    (   How == unread
    ->  Verdict = '-'
    ;   ep_ir_judged(S0, IRs, right)
    ->  Verdict = right
    ;   ep_ir_judged(S0, IRs, unjudged)
    ->  Verdict = unjudged
    ;   Verdict = unchecked
    ),
    (   How = rewrite(Rs)
    ->  atomic_list_concat(Rs, ' ', R),
        format("   rewrite  ~w~n            -> ~w~n", [S, R])
    ;   format("   ~w~t~12|~w~n", [How, S])
    ),
    (   How == unread
    ->  true
    ;   ep_ir_english(IRs, English),
        format("            read as: ~w (~w)~n", [English, Verdict])
    ).
