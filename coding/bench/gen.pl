%% coding/bench/gen.pl -- one generator call for the benchmark.
%%
%%     cocolog query "use_module('coding/bench/gen.pl'), run" -- \
%%         SPEC_FILE OUT_FILE none|high PREV_FILE|- DIAG_FILE|-
%%
%% The benchmark runs this as a child process, so codegen's own main/0 is
%% never called. The child prints one line:
%%
%%     USAGE Prompt Completion Total Reasoning CacheHit
%%
%% and writes the generated code to OUT_FILE. When PREV_FILE is not `-',
%% it is the previous attempt's code and DIAG_FILE is the compiler/test
%% report; both are appended to the requirement as the repair prompt.

:- use_module('coding/c/codegen.pl').
:- use_module('coding/bench/config.pl').

run :-
    current_prolog_flag(argv, [_, SpecFile, OutFile, EffortAtom, PrevFile, DiagFile]),
    read_file_to_codes(SpecFile, SpecCodes),
    atom_codes(Spec0, SpecCodes),
    bench_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options),
    codegen_c(Spec, Options, Code),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(OutFile, Codes),
    bench_gen_usage.

bench_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options) :-
    bench_config(provider, Provider),
    bench_config(model, Model),
    bench_config(base_url, BaseUrl),
    (   EffortAtom == high
    ->  bench_config(high_effort, Effort)
    ;   bench_config(loop_effort, Effort)
    ),
    Options = [provider(Provider),
               model(Model),
               base_url(BaseUrl),
               reasoning_effort(Effort)],
    (   PrevFile == '-'
    ->  Spec = Spec0
    ;   read_file_to_codes(PrevFile, PrevCodes),
        atom_codes(Prev, PrevCodes),
        read_file_to_codes(DiagFile, DiagCodes),
        atom_codes(Diag, DiagCodes),
        format(atom(Spec),
               '~s~n~nYour previous C program failed verification.~nCompiler and test report:~n~s~nThe previous program was:~n~s~nWrite a corrected complete C17 program. Output only the code.',
               [Spec0, Diag, Prev])
    ).

bench_gen_usage :-
    (   llm_last_usage(json(Pairs))
    ->  memberchk(prompt_tokens-P, Pairs),
        memberchk(completion_tokens-C, Pairs),
        memberchk(total_tokens-T, Pairs),
        (   memberchk(completion_tokens_details-json(Details), Pairs),
            memberchk(reasoning_tokens-R, Details)
        ->  true
        ;   R = 0
        ),
        (   memberchk(prompt_cache_hit_tokens-H, Pairs)
        ->  true
        ;   H = 0
        ),
        format("USAGE ~w ~w ~w ~w ~w~n", [P, C, T, R, H])
    ;   format("USAGE 0 0 0 0 0~n", [])
    ).
