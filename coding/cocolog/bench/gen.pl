%% coding/cocolog/bench/gen.pl -- one cocolog codegen run for the suite.
%%
%%     cocolog query "use_module('coding/cocolog/bench/gen.pl'), run" -- \
%%         SPEC_FILE EXPECTED_FILE OUT_FILE high|checked
%%
%% The child loads coding/cocolog/codegen.pl and generates a program that
%% must print EXPECTED_FILE. It prints:
%%
%%     USAGE prompt completion total reasoning cache seconds calls
%%     RESULT pass|fail
%%     ERROR Kind
%%
%% `high' is one call at high effort with SKILL.md; `checked' is up to
%% three calls at none, each repair carrying the output mismatch;
%% `no_skill' is the high control with the guide omitted.

:- use_module(library(process)).
:- use_module('coding/cocolog/codegen.pl').
:- use_module('coding/bench/config.pl').

run :-
    current_prolog_flag(argv, [_, SpecFile, ExpectedFile, OutFile, ModeAtom]),
    catch(run_mode(SpecFile, ExpectedFile, OutFile, ModeAtom), _, fail).

run_mode(SpecFile, ExpectedFile, OutFile, ModeAtom) :-
    read_file_codes(SpecFile, Spec),
    bench_config(provider, Provider),
    bench_config(model, Model),
    bench_config(base_url, BaseUrl),
    bench_config(temperature, Temperature),
    mode_effort(ModeAtom, Effort, Attempts),
    mode_skill(ModeAtom, SkillOption),
    Overrides = [provider(Provider),
                 model(Model),
                 base_url(BaseUrl),
                 temperature(Temperature),
                 reasoning_effort(Effort)],
    RunOptions = [attempts(Attempts), timeout(5000),
                  expect(ExpectedFile)|SkillOption],
    (   catch(codegen_cocolog_from(Spec, main, Overrides, RunOptions, Code),
              Ball, (gen_fail(Ball), fail))
    ->  write_code(OutFile, Code),
        gen_usage(yes)
    ;   gen_usage(no)
    ).

mode_effort(high, Effort, 1) :-
    !,
    bench_config(high_effort, Effort).
mode_effort(no_skill, Effort, 1) :-
    !,
    bench_config(high_effort, Effort).
mode_effort(_, Effort, Attempts) :-
    bench_config(loop_effort, Effort),
    bench_config(loop_attempts, Attempts).

mode_skill(no_skill, [skill(no)]) :-
    !.
mode_skill(_, []).

read_file_codes(File, Atom) :-
    read_file_to_codes(File, Codes),
    atom_codes(Atom, Codes).

write_code(File, Code) :-
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(File, Codes).

gen_fail(error(codegen_error(Kind, _), _)) :-
    !,
    format("ERROR ~w~n", [Kind]).
gen_fail(_) :-
    format("ERROR other~n", []).

gen_usage(Pass) :-
    codegen_report(report(Calls, Prompt, Completion, Reasoning, Cache, Total,
                          Seconds)),
    format("USAGE ~w ~w ~w ~w ~w ~2f ~w~n",
           [Prompt, Completion, Total, Reasoning, Cache, Seconds, Calls]),
    (   Pass == yes
    ->  format("RESULT pass~n", [])
    ;   format("RESULT fail~n", [])
    ).
