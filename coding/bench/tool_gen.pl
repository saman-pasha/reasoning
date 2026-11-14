%% coding/bench/tool_gen.pl -- one real-tool run for coding/bench/tool.pl.
%%
%%     cocolog query "use_module('coding/bench/tool_gen.pl'), run" \
%%         -- SPEC.txt CASES.txt EFFORT
%%
%% It reads the requirement and its cases, calls the shipped
%% codegen_c_tested/4 with the benchmark's provider, model, endpoint and
%% effort, and prints the tool's own report:
%%
%%     USAGE prompt completion total reasoning cache_hit
%%     CALLS n
%%     SECONDS s
%%     RESULT pass|fail
%%     ERROR kind
%%
%% The child is a query rather than `-s', because coding/c/codegen.pl has a
%% main/0 of its own; this file defines run/0 only.

:- use_module('coding/c/codegen.pl').
:- use_module('coding/compile.pl').
:- use_module('coding/bench/config.pl').

run :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [SpecFile, CasesFile, Effort]
    ->  (   tool_generate(SpecFile, CasesFile, Effort)
        ->  true
        ;   format("RESULT fail~nERROR setup~n", [])
        )
    ;   format("RESULT fail~nERROR args~n", [])
    ).

tool_generate(SpecFile, CasesFile, Effort) :-
    catch(read_file_to_codes(SpecFile, Codes), _, fail),
    atom_codes(Spec, Codes),
    c_read_cases(CasesFile, Cases),
    bench_config(provider, Provider),
    bench_config(model, Model),
    bench_config(base_url, BaseUrl),
    bench_config(temperature, Temperature),
    Options = [provider(Provider),
               model(Model),
               base_url(BaseUrl),
               temperature(Temperature),
               reasoning_effort(Effort)],
    Failed = none,
    (   catch(codegen_c_tested(Spec, Cases, Options, _Code), Ball,
              ( Failed = Ball, fail ))
    ->  Result = pass
    ;   Result = fail,
        (   Failed = error(codegen_error(Kind, _), _)
        ->  true
        ;   Kind = other
        )
    ),
    codegen_report(report(Calls, Prompt, Completion, Reasoning, Cache, Total,
                          Seconds)),
    format("USAGE ~w ~w ~w ~w ~w~n",
           [Prompt, Completion, Total, Reasoning, Cache]),
    format("CALLS ~w~nSECONDS ~2f~nRESULT ~w~n", [Calls, Seconds, Result]),
    (   Result == fail
    ->  format("ERROR ~w~n", [Kind])
    ;   true
    ).
