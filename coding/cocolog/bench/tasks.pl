%% coding/cocolog/bench/tasks.pl -- the cocolog benchmark's eight tasks.
%%
%%     bench_task(+Name, -Spec, -Expected)
%%
%% Spec is the requirement, read from the task's spec.txt; Expected is the
%% file its program's standard output must match. Every task's main/0
%% prints several results in one run, so one expected file holds them all.

:- use_module(library(process)).

bench_task(html_template, Spec,
           'coding/cocolog/bench/html_template/expected.txt') :-
    bench_spec('coding/cocolog/bench/html_template/spec.txt', Spec).

bench_task(json, Spec,
           'coding/cocolog/bench/json/expected.txt') :-
    bench_spec('coding/cocolog/bench/json/spec.txt', Spec).

bench_task(dcg, Spec,
           'coding/cocolog/bench/dcg/expected.txt') :-
    bench_spec('coding/cocolog/bench/dcg/spec.txt', Spec).

bench_task(store, Spec,
           'coding/cocolog/bench/store/expected.txt') :-
    bench_spec('coding/cocolog/bench/store/spec.txt', Spec).

bench_task(codes, Spec,
           'coding/cocolog/bench/codes/expected.txt') :-
    bench_spec('coding/cocolog/bench/codes/spec.txt', Spec).

bench_task(file, Spec,
           'coding/cocolog/bench/file/expected.txt') :-
    bench_spec('coding/cocolog/bench/file/spec.txt', Spec).

bench_task(stream, Spec,
           'coding/cocolog/bench/stream/expected.txt') :-
    bench_spec('coding/cocolog/bench/stream/spec.txt', Spec).

bench_task(namespace, Spec,
           'coding/cocolog/bench/namespace/expected.txt') :-
    bench_spec('coding/cocolog/bench/namespace/spec.txt', Spec).

bench_spec(File, Spec) :-
    read_file_to_codes(File, Codes),
    atom_codes(Spec, Codes).
