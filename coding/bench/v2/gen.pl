%% coding/bench/v2/gen.pl -- one generator call for a v2 trial.
%%
%%     cocolog query "use_module('coding/bench/v2/gen.pl'), run" -- \
%%         SPEC_FILE OUT_FILE none|high PREV_FILE|- DIAG_FILE|-
%%
%% The parent runner runs this as a child process. The child prints one
%% line, `USAGE Prompt Completion Total Reasoning CacheHit', and writes the
%% generated C to OUT_FILE. When PREV_FILE is not `-', it is the previous
%% attempt's code and DIAG_FILE is the verifier's report; both are appended
%% to the requirement as the repair prompt.

:- use_module('coding/c/codegen.pl').
:- use_module('coding/bench/v2/config.pl').

run :-
    current_prolog_flag(argv, [_, SpecFile, OutFile, EffortAtom, PrevFile, DiagFile]),
    read_file_to_codes(SpecFile, SpecCodes),
    atom_codes(Spec0, SpecCodes),
    v2_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options),
    codegen_c(Spec, Options, Code),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(OutFile, Codes),
    v2_gen_usage.

v2_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options) :-
    v2_config(provider, Provider),
    v2_config(model, Model),
    v2_config(base_url, BaseUrl),
    v2_config(temperature, Temperature),
    (   EffortAtom == high
    ->  v2_config(high_effort, Effort)
    ;   v2_config(loop_effort, Effort)
    ),
    Options = [provider(Provider),
               model(Model),
               base_url(BaseUrl),
               temperature(Temperature),
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

v2_gen_usage :-
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
