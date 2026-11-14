%% coding/bench/bench.pl -- DeepSeek codegen, high reasoning against a
%% no-reasoning verification loop.
%%
%%     REASONING_API_KEY=... \
%%     COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/bench/bench.pl [-- task ...]
%%
%% Seven modes per task:
%%
%%     high       one call with reasoning_effort(high)
%%     loop       up to three calls with reasoning_effort(none); after each
%%                the code is compiled with clang and run on the task's cases,
%%                and the compiler/test report goes back with the next call
%%     contract   the loop, with the obligation checklist contract.pl derives
%%                from the task's controlled-English requirement added to
%%                the prompt
%%     extract    one extra reasoning_effort(none) call rewrites the plain
%%                requirement into controlled English; the lines the reader
%%                accepts give the obligations, then the loop runs
%%     derive     the loop, with obligations derived deterministically from
%%                the plain requirement's keywords and the task's noun list
%%     escalate   the first attempt is the plain loop; only a repair attempt
%%                adds the keyword-derived obligations
%%     escalate2  the first two attempts are the plain loop; only the third
%%                adds the keyword-derived obligations
%%
%% The measurement is the provider's own usage: prompt, completion (which
%% includes reasoning), reasoning, total, and prompt-cache hits. The code
%% is generated in a child cocolog (coding/bench/gen.pl) so this file's
%% main/0 is the only main/0 the benchmark process sees.
%%
%% The provider, model, endpoint and efforts are coding/bench/config.pl's.
%% They are DeepSeek's OpenAI-compatible endpoint, not coding/options.pl's
%% Anthropic default, so the modes differ in reasoning effort and prompt
%% only.

:- use_module(library(llm)).
:- use_module(library(process)).
:- use_module('coding/bench/config.pl').
:- use_module('coding/bench/tasks.pl').
:- use_module('coding/bench/contract.pl').
:- use_module('coding/options.pl').

:- dynamic bench_result/7.

%% ---- the provider under test -------------------------------------------
%%
%% bench_config/2 is coding/bench/config.pl's: DeepSeek's OpenAI-compatible
%% endpoint, one model, high effort for the high mode and none for the
%% others. The extract mode also calls it directly, so the parent points
%% library(llm) at the same endpoint the children use.
%%
%% THE BENCHMARK MEASURES THE MODES AGAINST EACH OTHER, not against a
%% quality bar: what matters is that the effort and prompt differ and the
%% task, cases and backend do not. A change to one mode that also moved a
%% default in config.pl would make every number before it incomparable,
%% which is why config.pl is separate and shared with the child.

%% ---- the run -----------------------------------------------------------
%%
%% main/0 does three things and no more: check the key, name the tasks
%% (all, or those on the command line), and hand each to bench_task_modes.
%% Results are asserted as they arrive -- a provider outage at task four
%% must not lose tasks one to three -- and the report is read back from
%% those facts at the end.
%%
%% A CHILD COCOLOG DOES THE GENERATION (gen.pl), so the parent's main/0 is
%% the only main/0 in the process and a model reply that defines main/0
%% cannot take the benchmark's own entry point over.

main :-
    (   getenv('REASONING_API_KEY', Key),
        Key \== ''
    ->  true
    ;   format("REASONING_API_KEY is not set.~n", []),
        halt(1)
    ),
    bench_llm_setup,
    bench_selected_tasks(Tasks),
    (   Tasks == []
    ->  format("no benchmark task named.~n", []),
        halt(1)
    ;   true
    ),
    catch(bench_scratch(Dir), Ball,
          ( bench_error_text(Ball, Text),
            format("cannot make benchmark directory: ~w~n", [Text]),
            halt(1)
          )),
    format("benchmark directory: ~s~n", [Dir]),
    retractall(bench_result(_, _, _, _, _, _, _)),
    format("~n===== per task =====~n", []),
    format("task mode pass attempts prompt completion reasoning total cache_hit seconds~n", []),
    forall(member(Task, Tasks), bench_task_modes(Task, Dir)),
    findall(result(Task, Mode, Success, Attempts, Usage, Seconds, Diag),
            bench_result(Task, Mode, Success, Attempts, Usage, Seconds, Diag),
            Results),
    bench_report(Results, Tasks, Dir).

bench_selected_tasks(Tasks) :-
    current_prolog_flag(argv, [_|Args]),
    (   Args == []
    ->  findall(Task, bench_task(Task, _, _), Tasks)
    ;   findall(Task, (member(Task, Args), bench_task(Task, _, _)), Tasks)
    ).

bench_scratch(Dir) :-
    tmp_file(codegen_bench, Dir),
    make_directory(Dir).

%% The parent's own model call is the extractor; it uses the same endpoint
%% and key the child generators use.
bench_llm_setup :-
    bench_config(provider, Provider),
    bench_config(base_url, BaseUrl),
    retractall(llm_provider(Provider, _, _)),
    assertz(llm_provider(Provider, BaseUrl, 'REASONING_API_KEY')).

%% ---- one task, its modes -----------------------------------------------
%%
%% A task's modes run in a rotated order: task 1 starts with `high', task 2
%% with `loop', and so on round seven. A provider caches a prompt's prefix
%% and prices a hit differently, and the modes share the task's requirement
%% at the head of every prompt; a fixed order would hand whoever ran last
%% the cached prefix always. Rotating spreads that cost over the modes, so
%% the difference measured is effort and prompt, not position in the run.

bench_task_modes(Task, Dir) :-
    format("===== ~w =====~n", [Task]),
    bench_mode_order(Task, Modes),
    forall(member(Mode, Modes), bench_run_mode(Task, Mode, Dir)).

%% Alternate which mode goes first, to spread any prompt-cache effect.
bench_mode_order(Task, Modes) :-
    findall(T, bench_task(T, _, _), Tasks),
    bench_index(Tasks, Task, 1, Index),
    Cycle is Index mod 7,
    bench_mode_cycle(Cycle, Modes).

bench_mode_cycle(1, [high, loop, contract, extract, derive, escalate, escalate2]).
bench_mode_cycle(2, [loop, contract, extract, derive, escalate, escalate2, high]).
bench_mode_cycle(3, [contract, extract, derive, escalate, escalate2, high, loop]).
bench_mode_cycle(4, [extract, derive, escalate, escalate2, high, loop, contract]).
bench_mode_cycle(5, [derive, escalate, escalate2, high, loop, contract, extract]).
bench_mode_cycle(6, [escalate, escalate2, high, loop, contract, extract, derive]).
bench_mode_cycle(0, [escalate2, high, loop, contract, extract, derive, escalate]).

bench_index([Task|_], Task, I, I) :- !.
bench_index([_|Tasks], Task, I0, I) :-
    I1 is I0 + 1,
    bench_index(Tasks, Task, I1, I).

bench_run_mode(Task, Mode, Dir) :-
    format("--- ~w / ~w ---~n", [Task, Mode]),
    bench_max_attempts(Mode, Max),
    bench_mode_spec(Mode, Task, Spec, Usage0, ExtraAttempts),
    get_time(T0),
    bench_attempts(1, Max, Task, Mode, Spec, Dir, Usage0, none,
                   Success, Attempts0, Usage, LastDiag),
    get_time(T1),
    Seconds is T1 - T0,
    Attempts is Attempts0 + ExtraAttempts,
    assertz(bench_result(Task, Mode, Success, Attempts, Usage, Seconds, LastDiag)),
    bench_print_result(Task, Mode, Success, Attempts, Usage, Seconds).

%% ---- the modes ---------------------------------------------------------
%%
%% ONE ROW PER MODE, AND THE ROW IS THE WHOLE POLICY. max_attempts is how
%% many calls a mode may spend; effort_atom is the level sent with each;
%% mode_spec is the requirement that call carries; attempt_spec is what a
%% REPAIR attempt carries. Splitting them this way is what lets
%% `escalate' be "plain first, obliged on repair" without a second loop:
%% only attempt_spec changes between attempts.
%%
%% A NEW MODE IS FOUR CLAUSES HERE -- max_attempts, mode_spec, effort_atom,
%% and a line in bench_mode_cycle/2's lists -- plus bench_attempt_spec/4
%% where its repairs differ from its first call. bench_mode_cycle/2 is
%% seven clauses of seven modes each; adding an eighth mode means editing
%% every one, which is why it is kept together and named as a cycle.

bench_max_attempts(high, 1) :- !.
bench_max_attempts(contract, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(extract, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(derive, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(escalate, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(escalate2, N) :-
    !,
    bench_config(loop_attempts, N).
bench_max_attempts(loop, N) :-
    bench_config(loop_attempts, N).

%% The contract mode adds the checklist derived by contract.pl to the
%% plain requirement. high and loop get the requirement alone. extract
%% spends one no-reasoning call rewriting the requirement into controlled
%% English; its usage is returned so the loop's total carries it.
bench_mode_spec(high, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).
bench_mode_spec(loop, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).
bench_mode_spec(contract, Task, Full, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _),
    bench_obligations(Task, Obligations),
    bench_obligation_lines(Obligations, Lines),
    atomic_list_concat(Lines, '\n', ObligationsText),
    format(atom(Full),
           '~s~n~nObligations derived from a controlled-English contract:~n~s',
           [Spec, ObligationsText]).
bench_mode_spec(extract, Task, Full, Usage, 1) :-
    bench_task(Task, Spec, _),
    bench_extract_contract(Task, Spec, Obligations, Usage, Error),
    (   Error == none
    ->  true
    ;   format("extract warning: ~w~n", [Error])
    ),
    (   Obligations == []
    ->  Full = Spec
    ;   bench_obligation_lines(Obligations, Lines),
        atomic_list_concat(Lines, '\n', ObligationsText),
        format(atom(Full),
               '~s~n~nObligations extracted from the requirement:~n~s',
               [Spec, ObligationsText])
    ).
bench_mode_spec(derive, Task, Full, usage(0, 0, 0, 0, 0), 0) :-
    bench_derive_full(Task, Full).
bench_mode_spec(escalate, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).
bench_mode_spec(escalate2, Task, Spec, usage(0, 0, 0, 0, 0), 0) :-
    bench_task(Task, Spec, _).

%% The keyword-derived requirement, shared by the derive mode and by the
%% escalate mode's repair attempts.
bench_derive_full(Task, Full) :-
    bench_task(Task, Spec, _),
    bench_derive_obligations(Task, Spec, Obligations),
    bench_obligation_lines(Obligations, Lines),
    atomic_list_concat(Lines, '\n', ObligationsText),
    format(atom(Full),
           '~s~n~nObligations derived from the requirement keywords:~n~s',
           [Spec, ObligationsText]).

%% One extraction call. The reply is parsed by contract.pl; a line the
%% controlled-English reader refuses is dropped. A failed call leaves the
%% mode with the plain requirement and its usage at zero.
bench_extract_contract(Task, Spec, Obligations, Usage, Error) :-
    bench_extract_prompt(Task, Spec, Prompt),
    bench_config(provider, Provider),
    bench_config(model, Model),
    bench_config(temperature, Temperature),
    catch(( llm_chat([msg(system,
                          'You rewrite programming requirements into controlled English sentences. Output only sentences of the allowed shapes.'),
                     msg(user, Prompt)],
                    [provider(Provider), model(Model),
                     temperature(Temperature), reasoning_effort(none)],
                    Reply),
            bench_usage_now(Usage0),
            bench_reply_obligations(Reply, _Parsed, Obligations0),
            Usage = Usage0,
            Obligations = Obligations0,
            Error = none
          ),
          Ball,
          ( Usage = usage(0, 0, 0, 0, 0),
            Obligations = [],
            bench_error_text(Ball, Error)
          )).

bench_usage_now(Usage) :-
    (   catch(llm_last_usage(json(Pairs)), _, fail)
    ->  bench_usage_pairs(Pairs, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

bench_usage_pairs(Pairs, usage(P, C, T, R, H)) :-
    memberchk(prompt_tokens-P, Pairs),
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
    ).

%% ---- attempts, generation and verification -----------------------------
%%
%% AN ATTEMPT IS A PAIR: one model call, then a verdict. bench_attempts
%% repeats until a verdict is ok or the mode's ceiling is reached, and a
%% failed verdict becomes `prev(CodeFile, DiagFile)' -- the program and the
%% report -- which the next call is given. This is the same repair loop
%% coding/c/codegen.pl runs in one process; here it is spread over child
%% cocologs so a reply's assertz or halt cannot reach the runner.
%%
%% The mode's usage is the SUM over its attempts, the extract call
%% included: a mode that spends a call rewriting the requirement pays for
%% it in its own total, which is what makes `contract' and `extract'
%% comparable to `loop'.

bench_attempts(Attempt, Max, Task, Mode, Spec0, Dir, Usage0, Prev,
               Success, Attempts, Usage, LastDiag) :-
    (   Attempt > Max
    ->  Success = no,
        Attempts is Max,
        Usage = Usage0,
        LastDiag = 'attempts exhausted'
    ;   bench_paths(Task, Mode, Dir, Attempt, SpecFile, CodeFile, DiagFile),
        bench_attempt_spec(Mode, Task, Attempt, Spec0, Spec),
        bench_codegen(Mode, Spec, SpecFile, CodeFile, Prev, _Code, Usage1, Error),
        bench_add_usage(Usage0, Usage1, Usage2),
        (   Error == none
        ->  bench_verify(Task, Mode, Dir, Attempt, Verdict, Diag)
        ;   Verdict = fail,
            Diag = Error
        ),
        (   Verdict == ok
        ->  Success = yes,
            Attempts = Attempt,
            Usage = Usage2,
            LastDiag = ''
        ;   bench_write_atom(DiagFile, Diag),
            Next is Attempt + 1,
            bench_attempts(Next, Max, Task, Mode, Spec0, Dir, Usage2,
                           prev(CodeFile, DiagFile),
                           Success, Attempts, Usage, LastDiag)
        )
    ).

%% The first escalate attempt is the plain requirement; a repair attempt
%% adds the keyword-derived obligations. Every other mode keeps one spec
%% for every attempt.
%% The paired run's obligation branch uses the keyword-derived requirement
%% on its repair attempts; the plain branch keeps the plain one.
bench_attempt_spec(pair_obliged, Task, Attempt, Spec, Full) :-
    !,
    (   Attempt >= 2,
        bench_derive_full(Task, Full)
    ->  true
    ;   Full = Spec
    ).
bench_attempt_spec(escalate2, Task, Attempt, Spec, Full) :-
    !,
    (   Attempt >= 3,
        bench_derive_full(Task, Full)
    ->  true
    ;   Full = Spec
    ).
bench_attempt_spec(Mode, _, _, Spec, Spec) :-
    Mode \== escalate,
    !.
bench_attempt_spec(escalate, _, 1, Spec, Spec) :-
    !.
bench_attempt_spec(escalate, Task, _, Spec, Full) :-
    (   bench_derive_full(Task, Full)
    ->  true
    ;   Full = Spec
    ).

bench_paths(Task, Mode, Dir, Attempt, SpecFile, CodeFile, DiagFile) :-
    format(atom(SpecFile), '~s/~w_~w_~w.spec.txt', [Dir, Task, Mode, Attempt]),
    format(atom(CodeFile), '~s/~w_~w_~w.c', [Dir, Task, Mode, Attempt]),
    format(atom(DiagFile), '~s/~w_~w_~w.diag.txt', [Dir, Task, Mode, Attempt]).

bench_code_file(Task, Mode, Dir, Attempt, File) :-
    format(atom(File), '~s/~w_~w_~w.c', [Dir, Task, Mode, Attempt]).

bench_exe_file(Task, Mode, Dir, Attempt, File) :-
    format(atom(File), '~s/~w_~w_~w.out', [Dir, Task, Mode, Attempt]).

%% The benchmark's edition, from coding/bench/config.pl, and validated here
%% so a misspelt one stops the run at the first task rather than compiling
%% with clang's guess. It is NOT codegen_std/1: the benchmark's numbers are
%% a record of the generator under one edition, and an options default
%% changed for some other program must not move them.
bench_std(Std) :-
    bench_config(std, Std).

bench_input_file(Task, Mode, Dir, Attempt, Index, File) :-
    format(atom(File), '~s/~w_~w_~w_~w.in', [Dir, Task, Mode, Attempt, Index]).

%% One child cocolog per call. It writes CodeFile and prints its usage.
bench_codegen(Mode, Spec, SpecFile, CodeFile, Prev, Code, Usage, Error) :-
    bench_write_atom(SpecFile, Spec),
    bench_prev_files(Prev, PrevFile, DiagFile),
    bench_effort_atom(Mode, EffortAtom),
    cocolog(Cocolog),
    format(atom(Cmd),
           '"~s" query "use_module(''coding/bench/gen.pl''), run" -- ~s ~s ~w ~s ~s 2>&1',
           [Cocolog, SpecFile, CodeFile, EffortAtom, PrevFile, DiagFile]),
    bench_run_command(Cmd, 600000, OutCodes, Exit, RunError),
    atom_codes(OutText, OutCodes),
    (   Exit == 0,
        exists_file(CodeFile)
    ->  read_file_to_codes(CodeFile, CodeCodes),
        atom_codes(Code, CodeCodes),
        (   Code == ''
        ->  Usage = usage(0, 0, 0, 0, 0),
            Error = 'child wrote empty code'
        ;   bench_parse_usage(OutText, Usage),
            (   RunError == none
            ->  Error = none
            ;   Error = RunError
            )
        )
    ;   Code = '',
        Usage = usage(0, 0, 0, 0, 0),
        bench_limit(4000, OutText, OutTail),
        format(atom(Error0), 'codegen child failed (exit ~w)~n~s', [Exit, OutTail]),
        (   RunError == none
        ->  Error = Error0
        ;   Error = RunError
        )
    ).

bench_prev_files(none, '-', '-') :- !.
bench_prev_files(prev(CodeFile, DiagFile), CodeFile, DiagFile).

bench_effort_atom(high, high) :- !.
bench_effort_atom(contract, none) :- !.
bench_effort_atom(extract, none) :- !.
bench_effort_atom(derive, none) :- !.
bench_effort_atom(escalate, none) :- !.
bench_effort_atom(escalate2, none) :- !.
bench_effort_atom(pair_first, none) :- !.
bench_effort_atom(pair_plain, none) :- !.
bench_effort_atom(pair_obliged, none) :- !.
bench_effort_atom(loop, none).

cocolog(Cocolog) :-
    current_prolog_flag(executable, Cocolog).

%% ---- the child's usage line --------------------------------------------
%%
%% The child prints one line, `USAGE prompt completion total reasoning
%% cache_hit', from library(llm)'s usage for its single call. A child that
%% died before printing it -- a timeout, a provider error -- gives zeros
%% rather than failing the task: the attempt is already a failure for a
%% better-known reason, and a missing usage must not hide it.
%%
%% reasoning and cache_hit are fields the provider may not send, and zero
%% is what "not reported" means here.

bench_parse_usage(Text, Usage) :-
    (   bench_usage_line(Text, Line)
    ->  bench_usage_parts(Line, Usage)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

bench_usage_line(Text, LineAtom) :-
    split_string(Text, "\n", " \t\r", Lines),
    member(Line, Lines),
    atom_string(LineAtom, Line),
    sub_atom(LineAtom, 0, 6, _, 'USAGE '),
    !.

bench_usage_parts(Line, usage(P, C, T, R, H)) :-
    split_string(Line, " ", " ", Parts),
    Parts = [_, P0, C0, T0, R0, H0],
    bench_number(P0, P),
    bench_number(C0, C),
    bench_number(T0, T),
    bench_number(R0, R),
    bench_number(H0, H).

bench_number(String, N) :-
    atom_string(A, String),
    atom_number(A, N).

%% ---- compile and run the cases -----------------------------------------
%%
%% The verdict is the SAME one coding/c/check.pl gives: `clang -std=<edition>
%% -Wall -Wextra -O0', then each case run with the binary's stdout trimmed
%% of trailing whitespace and compared to the expected text, also trimmed.
%% A case that times out (exit 124), exits nonzero or could not run is a
%% failure with the reason named, so the repair call is told what went
%% wrong and not only that something did.
%%
%% The diagnostic is cut at 4000 characters before it goes back: a runaway
%% program can print megabytes of output, and the prompt must stay inside
%% the backend's context.

bench_verify(Task, Mode, Dir, Attempt, Verdict, Diag) :-
    bench_code_file(Task, Mode, Dir, Attempt, CodeFile),
    bench_exe_file(Task, Mode, Dir, Attempt, Exe),
    bench_std(Std),
    codegen_std_value(Std, Spelling),
    format(atom(Cmd), 'clang -std=~w -Wall -Wextra -O0 -o ~s ~s 2>&1',
           [Spelling, Exe, CodeFile]),
    bench_run_command(Cmd, 120000, CompCodes, CompExit, CompError),
    atom_codes(CompText, CompCodes),
    (   CompError \== none
    ->  Verdict = fail,
        format(atom(Diag0), 'compiler could not run: ~w', [CompError]),
        bench_limit(4000, Diag0, Diag)
    ;   CompExit == 0
    ->  bench_task(Task, _, Cases),
        bench_run_cases(Cases, Exe, Task, Mode, Dir, Attempt, 1, Failures),
        (   Failures == []
        ->  Verdict = ok,
            Diag = ''
        ;   atomic_list_concat(Failures, '\n\n', Diag0),
            Verdict = fail,
            bench_limit(4000, Diag0, Diag)
        )
    ;   Verdict = fail,
        format(atom(Diag0), 'COMPILE FAILED (exit ~w)~n~s', [CompExit, CompText]),
        bench_limit(4000, Diag0, Diag)
    ).

bench_run_cases([], _, _, _, _, _, _, []).
bench_run_cases([case(Input, Expected)|Rest], Exe, Task, Mode, Dir, Attempt, Index,
                Failures) :-
    bench_input_file(Task, Mode, Dir, Attempt, Index, InputFile),
    bench_write_text(InputFile, Input),
    format(atom(Cmd), '~s < ~s 2>&1', [Exe, InputFile]),
    bench_run_command(Cmd, 3000, OutCodes, Exit, RunError),
    atom_codes(Actual0, OutCodes),
    bench_norm(Actual0, Actual),
    bench_norm(Expected, ExpNorm),
    (   RunError == none,
        Exit == 0,
        Actual == ExpNorm
    ->  Here = []
    ;   bench_case_failure(Index, Input, Expected, Exit, Actual, RunError, Failure),
        Here = [Failure]
    ),
    Next is Index + 1,
    bench_run_cases(Rest, Exe, Task, Mode, Dir, Attempt, Next, Tail),
    append(Here, Tail, Failures).

bench_case_failure(Index, Input, Expected, Exit, Actual, RunError, Failure) :-
    (   RunError \== none
    ->  format(atom(Failure),
               'CASE ~w COULD NOT RUN~ninput: ~w~nexpected: ~w~nerror: ~w',
               [Index, Input, Expected, RunError])
    ;   Exit == 124
    ->  format(atom(Failure),
               'CASE ~w TIMEOUT~ninput: ~w~nexpected: ~w',
               [Index, Input, Expected])
    ;   Exit \== 0
    ->  format(atom(Failure),
               'CASE ~w EXIT ~w~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Exit, Input, Expected, Actual])
    ;   format(atom(Failure),
               'CASE ~w WRONG~ninput: ~w~nexpected: ~w~nactual: ~w',
               [Index, Input, Expected, Actual])
    ).

bench_run_command(Cmd, Timeout, OutCodes, Exit, Error) :-
    catch(( proc_run(Cmd, Timeout, OutCodes0, Exit0),
            OutCodes = OutCodes0,
            Exit = Exit0,
            Error = none
          ),
          Ball,
          ( OutCodes = [],
            Exit = -1,
            bench_error_text(Ball, Error)
          )).

%% ---- small helpers -----------------------------------------------------
%%
%% bench_norm is the comparison's one rule, and it is NOT `trim': each line
%% loses its leading and trailing spaces and the empty lines between them,
%% then the lines are joined -- so `6' and `  6\n\n' and `6\r' are one
%% answer, while `6\n7' and `6 7' stay two. A program that pads a column or
%% ends in a newline should not fail a case for the padding.
%%
%% bench_run_command catches a process that could not start at all (a
%% missing clang, a timeout that killed the shell) and answers Exit -1 with
%% the reason, so the caller has one shape to read.

bench_norm(Text, Norm) :-
    split_string(Text, "\n", " \t\r", Lines0),
    exclude(bench_empty_string, Lines0, Lines),
    findall(A, (member(L, Lines), atom_string(A, L)), Atoms),
    atomic_list_concat(Atoms, '\n', Norm).

bench_empty_string(S) :-
    (   string(S)
    ->  string_length(S, 0)
    ;   S == ''
    ).

bench_write_atom(File, Atom) :-
    atom_codes(Atom, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

bench_write_text(File, Atom) :-
    atom_codes(Atom, Codes),
    write_file_from_codes(File, Codes).

bench_limit(Max, Atom, Limited) :-
    atom_length(Atom, Len),
    (   Len =< Max
    ->  Limited = Atom
    ;   sub_atom(Atom, 0, Max, _, Limited)
    ).

bench_add_usage(usage(P0, C0, T0, R0, H0), usage(P, C, T, R, H),
                usage(P1, C1, T1, R1, H1)) :-
    P1 is P0 + P,
    C1 is C0 + C,
    T1 is T0 + T,
    R1 is R0 + R,
    H1 is H0 + H.

bench_error_text(Ball, Text) :-
    catch(format(atom(Text), 'error: ~w', [Ball]), _, Text = 'error').

%% ---- the report --------------------------------------------------------
%%
%% The report answers three questions, and none of them is the printer's
%% own: whether a mode solves the tasks (passed), what it cost to try
%% (total, reasoning, attempts), and what it costs to SUCCEED (tokens per
%% solved task). The third is the one to compare: a mode can win on total
%% by giving up cheaply, so tokens_per_solved divides the tokens of the
%% tasks it PASSED by how many it passed, never by every task.
%%
%% The per-mode totals are summed by bench_sum_rows/2 over rows built for
%% the mode, so a mode with no row prints zeros instead of vanishing --
%% a missing line would read as "not measured" where it means "all failed".
%%
%% The `~2f' seconds is wall time for the whole mode over a task, the child
%% cocologs and their process starts included. It is not the provider's
%% latency and must not be read as one.

bench_print_result(Task, Mode, Success, Attempts, usage(P, C, T, R, H), Seconds) :-
    (   Success == yes
    ->  Pass = pass
    ;   Pass = fail
    ),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Task, Mode, Pass, Attempts, P, C, R, T, H, Seconds]).

bench_report(Results, Tasks, Dir) :-
    format("~n===== totals =====~n", []),
    format("mode tasks passed attempts prompt completion reasoning total cache_hit seconds~n", []),
    bench_print_mode_totals(high, Results),
    bench_print_mode_totals(loop, Results),
    bench_print_mode_totals(contract, Results),
    bench_print_mode_totals(extract, Results),
    bench_print_mode_totals(derive, Results),
    bench_print_mode_totals(escalate, Results),
    bench_print_mode_totals(escalate2, Results),
    format("~n===== totals by task =====~n", []),
    format("task high_total loop_total contract_total extract_total derive_total escalate_total escalate2_total high_reasoning~n", []),
    forall(member(Task, Tasks), bench_print_seven(Task, Results)),
    format("~n===== per solved task =====~n", []),
    format("mode solved total tokens_per_solved~n", []),
    bench_print_per_solved(high, Results),
    bench_print_per_solved(loop, Results),
    bench_print_per_solved(contract, Results),
    bench_print_per_solved(extract, Results),
    bench_print_per_solved(derive, Results),
    bench_print_per_solved(escalate, Results),
    bench_print_per_solved(escalate2, Results),
    format("~nbenchmark files: ~s~n", [Dir]).

bench_print_mode_totals(Mode, Results) :-
    findall(row(P, C, T, R, H, Secs, Attempts, Succ),
            (   member(result(_, Mode0, Success, Attempts0,
                              usage(P, C, T, R, H), Secs0, _), Results),
                Mode0 == Mode,
                Attempts = Attempts0,
                Secs = Secs0,
                (   Success == yes
                ->  Succ = 1
                ;   Succ = 0
                )
            ),
            Rows),
    bench_sum_rows(Rows,
                   acc(N, Passed, AttemptsSum, PSum, CSum,
                       TSum, RSum, HSum, SecSum)),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w ~2f~n",
           [Mode, N, Passed, AttemptsSum, PSum, CSum, RSum, TSum, HSum, SecSum]).

bench_sum_rows([], acc(0, 0, 0, 0, 0, 0, 0, 0, 0)).
bench_sum_rows([row(P, C, T, R, H, Secs, Attempts, Succ)|Rest],
               acc(N1, Passed1, Attempts1, P1, C1, T1, R1, H1, Sec1)) :-
    bench_sum_rows(Rest,
                   acc(N0, Passed0, Attempts0, P0, C0, T0, R0, H0, Sec0)),
    N1 is N0 + 1,
    Passed1 is Passed0 + Succ,
    Attempts1 is Attempts0 + Attempts,
    P1 is P0 + P,
    C1 is C0 + C,
    T1 is T0 + T,
    R1 is R0 + R,
    H1 is H0 + H,
    Sec1 is Sec0 + Secs.

bench_print_seven(Task, Results) :-
    bench_mode_usage(Task, high, Results, usage(_, _, HT, HR, _)),
    bench_mode_usage(Task, loop, Results, usage(_, _, LT, _, _)),
    bench_mode_usage(Task, contract, Results, usage(_, _, CT, _, _)),
    bench_mode_usage(Task, extract, Results, usage(_, _, ET, _, _)),
    bench_mode_usage(Task, derive, Results, usage(_, _, DT, _, _)),
    bench_mode_usage(Task, escalate, Results, usage(_, _, ST, _, _)),
    bench_mode_usage(Task, escalate2, Results, usage(_, _, S2T, _, _)),
    format("~w ~w ~w ~w ~w ~w ~w ~w ~w~n",
           [Task, HT, LT, CT, ET, DT, ST, S2T, HR]).

bench_mode_usage(Task, Mode, Results, Usage) :-
    bench_find_result(Task, Mode, Results,
                      result(_, _, _, _, Usage, _, _)).

bench_find_result(Task, Mode, Results, Result) :-
    member(Result0, Results),
    Result0 = result(Task0, Mode0, _, _, _, _, _),
    Task0 == Task,
    Mode0 == Mode,
    Result = Result0.

bench_print_per_solved(Mode, Results) :-
    findall(usage(P, C, T, R, H),
            (   member(result(_, Mode0, yes, _, U, _, _), Results),
                Mode0 == Mode,
                U = usage(P, C, T, R, H)
            ),
            Usages),
    (   Usages == []
    ->  true
    ;   length(Usages, N),
        bench_sum_usage_list(Usages, usage(_, _, Total, _, _)),
        Per is Total / N,
        format("~w ~w ~w ~2f~n", [Mode, N, Total, Per])
    ).

bench_sum_usage_list([], usage(0, 0, 0, 0, 0)).
bench_sum_usage_list([U|Us], Total) :-
    bench_sum_usage_list(Us, T),
    bench_add_usage(U, T, Total).
