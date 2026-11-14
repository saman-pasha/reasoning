%% coding/bench/tool.pl -- the shipped C tool over the benchmark tasks.
%%
%%     coding/bench/tool.sh              all tasks
%%     coding/bench/tool.sh -- lcs       one task
%%
%% The tool is coding/c/codegen.pl's codegen_c_tested/4: the keyword
%% obligations on every attempt, compile repair, and the task's cases under
%% the sanitizers. Each task runs in a child (coding/bench/tool_gen.pl), so
%% this file's main/0 is the only one; the child prints the usage from
%% codegen_report/1. A task passes only when the real tool accepts it.
%%
%% The provider, model, endpoint, temperature and effort are
%% coding/bench/config.pl's, as in the rest of the benchmark.

:- use_module(library(process)).
:- use_module('coding/bench/tasks.pl').
:- use_module('coding/bench/config.pl').

main :-
    (   getenv('REASONING_API_KEY', Key),
        Key \== ''
    ->  true
    ;   format("REASONING_API_KEY is not set.~n", []),
        halt(1)
    ),
    tool_selected_tasks(Tasks),
    (   Tasks == []
    ->  format("no benchmark task named.~n", []),
        halt(1)
    ;   true
    ),
    tmp_file(bench_tool, Dir),
    make_directory(Dir),
    format("tool directory: ~s~n~n", [Dir]),
    format("task pass calls prompt completion reasoning total cache_hit seconds~n", []),
    findall(result(Task, Pass, Calls, usage(P, C, T, R, H), Seconds),
            (   member(Task, Tasks),
                tool_task(Task, Dir, Pass, Calls, usage(P, C, T, R, H),
                          Seconds)
            ),
            Results),
    tool_totals(Results),
    format("~ntool files: ~s~n", [Dir]).

tool_selected_tasks(Tasks) :-
    current_prolog_flag(argv, [_|Args]),
    (   Args == []
    ->  findall(Task, bench_task(Task, _, _), Tasks)
    ;   findall(Task, (member(Task, Args), bench_task(Task, _, _)), Tasks)
    ).

tool_task(Task, Dir, Pass, Calls, Usage, Seconds) :-
    bench_task(Task, Spec, Cases),
    format(atom(SpecFile), '~s/~w.spec.txt', [Dir, Task]),
    format(atom(CasesFile), '~s/~w.cases.pl', [Dir, Task]),
    tool_write_text(SpecFile, Spec),
    tool_write_cases(CasesFile, Cases),
    bench_config(loop_effort, Effort),
    current_prolog_flag(executable, Cocolog),
    format(atom(Cmd),
           '"~s" query "use_module(''coding/bench/tool_gen.pl''), run" -- ~s ~s ~w 2>&1',
           [Cocolog, SpecFile, CasesFile, Effort]),
    catch(proc_run(Cmd, 600000, Codes, Exit), _,
          ( Codes = [], Exit = -1 )),
    atom_codes(Text, Codes),
    (   Exit == 0,
        tool_field(Text, 'RESULT ', Result),
        Result == pass
    ->  Pass = pass
    ;   Pass = fail
    ),
    tool_number_field(Text, 'CALLS ', 0, Calls),
    tool_usage_field(Text, Usage),
    tool_float_field(Text, 'SECONDS ', 0.0, Seconds),
    Usage = usage(P, C, T, R, H),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Task, Pass, Calls, P, C, R, T, H, Seconds]),
    (   Pass == fail
    ->  tool_diag(Text, Diag),
        format("  ~s~n", [Diag])
    ;   true
    ).

tool_write_text(File, Atom) :-
    atom_codes(Atom, Codes),
    write_file_from_codes(File, Codes).

tool_write_cases(File, Cases) :-
    with_output_to(atom(Text), (writeq(cases(Cases)), write('.\n'))),
    atom_codes(Text, Codes),
    write_file_from_codes(File, Codes).

tool_field(Text, Prefix, Value) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    atom_concat(Prefix, Value, LineAtom).

tool_number_field(Text, Prefix, Default, Number) :-
    (   tool_field(Text, Prefix, Atom),
        atom_number(Atom, Value)
    ->  Number = Value
    ;   Number = Default
    ).

tool_float_field(Text, Prefix, Default, Number) :-
    (   tool_field(Text, Prefix, Atom),
        atom_number(Atom, Value),
        number(Value)
    ->  Number = Value
    ;   Number = Default
    ).

tool_usage_field(Text, usage(P, C, T, R, H)) :-
    (   tool_field(Text, 'USAGE ', Rest),
        tool_atom_numbers(Rest, [P0, C0, T0, R0, H0])
    ->  P = P0,
        C = C0,
        T = T0,
        R = R0,
        H = H0
    ;   P = 0,
        C = 0,
        T = 0,
        R = 0,
        H = 0
    ).

tool_atom_numbers(Atom, Numbers) :-
    split_string(Atom, " ", " ", Parts),
    findall(Number,
            (   member(Part, Parts),
                atom_string(AtomPart, Part),
                atom_number(AtomPart, Number)
            ),
            Numbers).

tool_diag(Text, Diag) :-
    (   tool_field(Text, 'ERROR ', Kind)
    ->  format(atom(Diag), 'error: ~w', [Kind])
    ;   Diag = 'no result'
    ).

%% ---- the totals --------------------------------------------------------

tool_totals(Results) :-
    findall(Passed,
            (   member(result(_, Pass, _, _, _), Results),
                (   Pass == pass
                ->  Passed = 1
                ;   Passed = 0
                )
            ),
            Passes),
    findall(Calls, member(result(_, _, Calls, _, _), Results), CallsList),
    findall(P, member(result(_, _, _, usage(P, _, _, _, _), _), Results), Prompts),
    findall(C, member(result(_, _, _, usage(_, C, _, _, _), _), Results), Completions),
    findall(T, member(result(_, _, _, usage(_, _, T, _, _), _), Results), Totals),
    findall(R, member(result(_, _, _, usage(_, _, _, R, _), _), Results), Reasonings),
    findall(H, member(result(_, _, _, usage(_, _, _, _, H), _), Results), Caches),
    findall(S, member(result(_, _, _, _, S), Results), SecondsList),
    length(Results, Count),
    tool_sum(Passes, Passed),
    tool_sum(CallsList, CallsSum),
    tool_sum(Prompts, PromptSum),
    tool_sum(Completions, CompletionSum),
    tool_sum(Totals, TotalSum),
    tool_sum(Reasonings, ReasoningSum),
    tool_sum(Caches, CacheSum),
    tool_sum(SecondsList, SecondsSum),
    format("~noverall ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Count, Passed, CallsSum, PromptSum, CompletionSum,
            ReasoningSum, TotalSum, CacheSum, SecondsSum]).

tool_sum([], 0).
tool_sum([X|Xs], Sum) :-
    tool_sum(Xs, Rest),
    Sum is Rest + X.
