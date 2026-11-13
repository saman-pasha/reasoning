%% cocolog -- test/prelude.pl: what every .pl case shares.
%%
%% A CASE IS ONE PROCESS. The .sh suite spawned a cocolog per check --
%% `timeout 60 cocolog query ... | grep -aoE 'answer(...)' | sed', forty
%% times in test/string.sh alone, ~120 ms each on this machine and most
%% of it start-up and pipe plumbing -- so a case that asked forty
%% questions paid five seconds to hear forty answers it could have had
%% from one proof. A .pl case is `cocolog -s test/<case>.pl' from the
%% checkout root: main/0 runs every check in the one process,
%% checks_done/0 says GREEN or RED, and THE EXIT CODE IS THE VERDICT --
%% 0 exactly when main proved, which checks_done withholds on any red
%% check. CivV's suite made the same move first; its test/prelude.pl is
%% this file's model, and test/run.sh reads a .pl case the way CivV's
%% does: exit status for the colour, a `SKIP' line for a skip.
%%
%% THE VOCABULARY IS COCOLOG'S OWN. library(process) owns check/3 and
%% checks_done/0 -- the harness every .sh re-implemented -- and running
%% a child where a check genuinely IS a second process: a file whose
%% directives report on stderr, a store read back by another cocolog.
%% library(text) is grep as a clause, for pins on captured output.
%% What this file adds is the handful of shapes every case needs:
%%
%%   answer(+Goal, ?Template, -Got)  Goal proved ONCE; Got is Template's
%%                                   value, `failed', or error(Ball) -- so
%%                                   a check whose goal fails or throws is
%%                                   a FAIL line naming what happened, not
%%                                   the end of the case
%%   yes_no(+Goal, -YesOrNo)         the checks that ask a question
%%   written(+Goal, ?Template, -Atom) answer/3, then the value as write/1
%%                                   spells it -- for a pin the .sh made
%%                                   against a written term, kept byte for
%%                                   byte rather than re-guessed as a term
%%   section(+Title)                 the `-- ...' line between groups
%%   skip(+Why)                      prints `SKIP Why' and halts 0
%%   scratch(-Dir)                   a fresh directory for fixtures
%%   fixture(+Path, +Lines)          writes the lines, newline-terminated
%%   cocolog(-Path)                  the binary running this case
%%   cocolog_out(+Args, -Codes)      a child `cocolog ARGS' -- local unless
%%                                   ARGS say otherwise -- its stdout AND
%%                                   stderr, two minutes' grace
%%   cocolog_answer(+Args, -Term)    the child's `answer(...)' line read
%%                                   back as a term, or `none'
%%   spawn(+Cmd, -Pid)               a server, exec'd so the pid IS it
%%   shell(+Cmd, -Text, -Exit)       /bin/sh -c Cmd: stdout as an atom, last
%%                                   newline off, and the exit status
%%   cocolog_run(+Args, -Text, -Exit) shell/3 over `cocolog ARGS'
%%   has(+Label, +Needle, +Text)     a check that Needle occurs in Text
%%   binary_verdict(+Out, +Exit, -V) a test BINARY's verdict, as run.pl
%%                                   reads it: green, skip or red
%%
%% A `SKIP' AT COLUMN 0 SKIPS THE WHOLE CASE -- run.sh greps for it, the
%% way CivV's does -- so a SECTION that cannot run says so indented:
%% `     (skipped: no python3 with numpy on the path)'. The line is still
%% in the case's output for whoever counts the skips.
%%
%% ISOLATION IS THE CASE'S OWN BUSINESS. The .sh suite got a clean slate
%% per check for free, by spawning; here a check that would leave state
%% behind -- a flag set, a clause asserted, a module registered -- either
%% puts it back or takes a child process on purpose, and says which.

:- use_module(library(process)).
:- use_module(library(text)).

answer(Goal, Template, Got) :-
    (   catch(Goal, Ball, Caught = caught(Ball))
    ->  (   nonvar(Caught) -> Caught = caught(B), Got = error(B)
        ;   Got = Template
        )
    ;   Got = failed
    ).

yes_no(Goal, YN) :-
    answer(Goal, yes, A),
    (   A == yes -> YN = yes
    ;   A == failed -> YN = no
    ;   YN = A
    ).

written(Goal, Template, Atom) :-
    answer(Goal, Template, Got),
    format(atom(Atom), "~w", [Got]).

section(Title) :- format("-- ~w~n", [Title]).

skip(Why) :- format("SKIP ~w~n", [Why]), halt(0).

%% NO CUDA, NO TENSOR CASE -- the owner's rule, and it is about what these
%% cases DO rather than what they can load. They TRAIN. On a CPU that is
%% minutes and gigabytes a lesson: measured on a two-core Linux box with no
%% GPU, the forty-two tensor tutorials took 29 minutes and five of them
%% peaked over 2.4 GB resident, the largest three between 4.7 and 5.1 GB.
%% The same run under any other load was killed by the cgroup's OOM killer
%% -- a cocolog at 9.7 GB -- and a SIGKILL takes the output buffer with it,
%% so the case named nothing at all. A machine with no card cannot run these
%% honestly, so it says so instead.
%%
%% `torch_cuda_available(true)' FAILS where there is no card, which is what
%% makes this one question. A case calls it AFTER checking its module is
%% there, so a missing torch.so still reports as a missing module.
%% AND IT READS THE ANSWER, NOT THE EXIT STATUS. `cocolog query' exits 0
%% for a goal that FAILED -- measured: `query fail' is 0 and only an error
%% is 1 -- so an exit-status probe answers yes to everything. This is
%% `test/torch-replay.pl''s shape, which had it right first.
%% A PARALLELISM CLAIM CANNOT BE TESTED ON A MACHINE THAT WILL NOT OVERLAP,
%% and `nproc' is not the question. Measured on a Colab runtime: nproc says
%% 2 and the cgroup's cpu.max says unlimited, while two identical spinners
%% take 1.77x as long as one and four take 2.64x -- about 1.1 to 1.5 usable
%% cores. Three cases assert that four workers do four times the work in
%% under three times the time, which on one usable core is arithmetically
%% impossible, so they went RED for the room rather than for the code.
%%
%% So ASK THE MACHINE, with two OS processes rather than two threads -- the
%% probe must not be the thing under test. Perfect overlap answers about
%% 1.0, no overlap about 2.0, and anything past 1.5 means a parallelism
%% check here would be measuring the box. The answer is kept for the life
%% of the case: it costs three cocolog runs and nothing changes it.
%%
%% `COCOLOG_ASSUME_PARALLEL=1' forces the checks to run anyway, for a box
%% whose slowness you want to see reported rather than excused.
machine_overlaps :-
    (   getenv('COCOLOG_ASSUME_PARALLEL', _)
    ->  true
    ;   catch(nb_getval(overlap_ratio, R0), _, fail)
    ->  R0 < 1.5
    ;   overlap_ratio(R), nb_setval(overlap_ratio, R), R < 1.5
    ).

%% THE WORST OF THREE, because a shared machine's answer MOVES. The same
%% Colab runtime measured 1.93 one minute and 1.10 the next, and a single
%% sample let a check run that then failed on a box that could not overlap
%% when it mattered. What is wanted is not "can it ever" but "can it be
%% relied on", so the worst sample decides: a machine that sometimes cannot
%% overlap produces flaky reds, and a flaky red is worse than a skip.
overlap_ratio(R) :-
    findall(S, (between(1, 3, _), overlap_sample(S)), Rs),
    max_list(Rs, R),
    format("     (this machine overlaps two processes at ~2f worst of ~w -- 1.0 is perfect, 2.0 is none)~n",
           [R, Rs]).

overlap_sample(R) :-
    cocolog(C),
    sh_join([C, ' --local query "between(1, 400000, _), fail" >/dev/null 2>&1'], One),
    sh_join([One, ' & ', One, ' & wait'], Two),
    get_time(A0), shell(One, _, _), get_time(A1),
    get_time(B0), shell(Two, _, _), get_time(B1),
    Solo is A1 - A0, Pair is B1 - B0,
    ( Solo > 0.0 -> R is Pair / Solo ; R = 99.0 ).

%% A parallelism verdict, or a SKIP when the machine cannot show one. The
%% check still runs wherever the box can overlap, so a real regression is
%% still RED; only a machine that cannot answer the question is excused.
parallel_check(Label, Got) :-
    (   Got == parallel
    ->  check(Label, Got, parallel)
    ;   machine_overlaps
    ->  check(Label, Got, parallel)
    ;   format("     (skipped: ~w -- this machine does not overlap two processes)~n", [Label])
    ).

needs_cuda :-
    answer_text('query "use_module(library(torch)), torch_cuda_available(B), write(answer(B)), nl"', Cuda),
    (   Cuda == true
    ->  true
    ;   skip('(no CUDA -- the tensor cases train, and on a CPU that is minutes and gigabytes each)')
    ).

%% ONE SLASH: macOS's TMPDIR ends in one, so tmp_file/2 answers `.../T//coco...'
%% -- a path that works and that no other program prints back that way
%% (swipl names files by their real path, and a check that strips the
%% scratch prefix from both outputs then strips only ours)
scratch(Dir) :-
    tmp_file(cocolog_test, Raw),
    re_replace_atom('//', '/', Raw, Dir),
    make_directory(Dir).

%% JOINED AS CODES, never as one atom: a fixture of a hundred CSV rows is
%% thirty kilobytes, and an atom that size is a buffer somewhere waiting
%% to be overrun
fixture(Path, Lines) :-
    findall(Cs, ( member(L, Lines), atom_codes(L, LCs), append(LCs, [10], Cs) ), Rows),
    append(Rows, Codes),
    write_file_from_codes(Path, Codes).

cocolog(C) :- current_prolog_flag(executable, C).

%% the checkout root, WITHOUT the trailing slash working_directory/2 answers
%% with: `ROOT/test/x' built on the raw answer is `.../cocolog//test/x', and
%% Cicili, handed such a target, put its output somewhere it did not then
%% find
root(Root) :-
    working_directory(Raw, Raw),
    (   atom_concat(Root, '/', Raw), Root \== '' -> true ; Root = Raw ).

cocolog_out(Args, Out) :-
    cocolog(C),
    sh_join([C, ' ', Args, ' 2>&1'], Cmd),
    proc_run(Cmd, 120000, Out, _).

%% spawn(+Cmd, -Pid): proc_spawn/2 with `exec' in front, for the ONE case a
%% test spawns -- a server it will stop again.
%%
%% THE PID MUST BE THE SERVER, NOT A SHELL THAT FORKED IT. proc_spawn runs
%% /bin/sh -c CMD, and this /bin/sh FORKS for a command carrying
%% redirections rather than execing it -- measured: proc_stop said `gone'
%% of the pid it was given while the port was still held, by a pid two
%% higher. The orphan goes on listening, and the next run of that case
%% meets its own port taken: the suite's first end-to-end run lost `tunnel'
%% and `zigurat-tls' that way, to servers a standalone run of the same two
%% cases had left behind an hour earlier. `exec' makes the shell replace
%% itself, so the pid proc_spawn answers is the thing to kill.
%%
%% ONLY FOR A SINGLE COMMAND. A shell LOOP cannot be exec'd, so a case that
%% spawns one (test/ruler.pl's queriers) keeps proc_spawn and lets the loop
%% end on its own.
spawn(Cmd, Pid) :- sh_join(['exec ', Cmd], Exec), proc_spawn(Exec, Pid).

%% unix_listening(+Path): up to eight seconds' wait for a listener on the
%% socket file at Path -- a unix socket's `lsof -iTCP:PORT -sTCP:LISTEN',
%% and for the same reason never a probe connection: a server that counts
%% its accepts would count it. The file alone will not do, because it is
%% there from the bind, and a connect before the listen is refused. lsof
%% prints such a socket's path and `type=STREAM (LISTEN)'; where it prints
%% no state (macOS), this waits its eight seconds and goes on.
unix_listening(Path) :-
    sh_join(['lsof -U 2>/dev/null | grep -F -q ''', Path, ' type=STREAM (LISTEN)'''], Listening),
    ( proc_until(sh_exit(Listening, 0), 8000, 100) -> true ; true ).

%% shell(+Cmd, -Text, -Exit): /bin/sh -c Cmd with two minutes' grace, its
%% stdout (and whatever Cmd redirected into it) as an atom with the last
%% newline taken off -- what `$(...)' handed a .sh -- and the exit status,
%% never failed on. cocolog_run/3 is the same over `cocolog ARGS'.
shell(Cmd, Text, Exit) :- shell(Cmd, Text, Exit, 120000).

%% the same with a ceiling of its own, for a step whose work grows with the
%% tree it reads (test/lint.pl's corpus lint)
shell(Cmd, Text, Exit, Ms) :-
    proc_run(Cmd, Ms, Out, Exit),
    chomp(Out, Body),
    atom_codes(Text, Body).

cocolog_run(Args, Text, Exit) :- cocolog_run(Args, Text, Exit, 120000).

%% the same with a ceiling of its own, for a child that trains: `timeout N'
%% cannot go in ARGS, since ARGS come after the binary
cocolog_run(Args, Text, Exit, Ms) :-
    cocolog(C),
    sh_join([C, ' ', Args], Cmd),
    proc_run(Cmd, Ms, Out, Exit),
    chomp(Out, Body),
    atom_codes(Text, Body).

%% answer_text(+Args, -Text): the .sh suites' `q()' -- a child `cocolog ARGS',
%% stderr dropped, and the inside of the first `answer(...)' on a line of
%% its own, greedy to that line's last `)'; '' when there is none
answer_text(Args, Text) :-
    cocolog(C),
    sh_join([C, ' ', Args, ' 2>/dev/null'], Cmd),
    proc_run(Cmd, 300000, Out, _),
    (   re_first_atom('answer\\([^\n]*\\)', Out, A)
    ->  sub_atom(A, 7, _, 1, Text)
    ;   Text = ''
    ).

%% maxdiff(+Text, -D): the largest |a - b| over two flat lists written as
%% `[a1,a2,...]/[b1,b2,...]' -- `/', because `-' is also a minus sign. A
%% text that is not that shape answers `inf', so a missing answer is off
%% by infinity rather than within anything.
maxdiff(Text, D) :-
    (   atomic_list_concat(Parts, '/', Text), Parts = [LA, LB],
        numbers_of(LA, As), numbers_of(LB, Bs),
        length(As, N), length(Bs, N)
    ->  findall(Ab, ( nth0(I, As, A), nth0(I, Bs, B), Ab is abs(A - B) ), Ds),
        max_list([0|Ds], D)
    ;   D = inf
    ).

numbers_of(Text, Ns) :-
    re_replace_atom('[][]', '', Text, Bare),
    atomic_list_concat(Parts, ',', Bare),
    findall(N, ( member(P, Parts), P \== '', atom_number(P, N) ), Ns).

%% has(+Label, +Needle, +Text): the .sh's `case "$3" in *"$2"*)' -- a
%% check that Needle occurs in Text, the FAIL line showing both
has(Label, Needle, Text) :-
    (   sub_atom(Text, _, _, _, Needle)
    ->  check(Label, found, found)
    ;   check(Label, Text, Needle)
    ).

%% binary_verdict(+Out, +Exit, -Verdict): what one of the test/*.cicili
%% binaries said -- its whole output and its exit status -- as test/run.pl
%% counts it. GREEN on the last line, or a SKIP on the last line or the
%% first, is that verdict only from a binary that EXITED 0, as a .pl case's
%% colour is its exit status alone: one that printed GREEN and then died
%% (a destructor, a free at exit: 139) is red. Through 2.11.0 the runner read
%% the last line and nothing else, and a SIGSEGV after GREEN was green (an
%% outside review's finding). Every binary exits 0 when it is green or
%% skips, and 1 when a check failed.
binary_verdict(Out, Exit, Verdict) :-
    atom_codes(Out, Cs),
    (   codes_lines(Cs, Ls), Ls \== [], last(Ls, L) -> atom_codes(Last, L) ; Last = '' ),
    (   Exit =\= 0 -> Verdict = red
    ;   sub_atom(Last, 0, _, _, 'GREEN') -> Verdict = green
    ;   sub_atom(Last, 0, _, _, 'SKIP') -> Verdict = skip
    ;   sub_atom(Out, 0, _, _, 'SKIP') -> Verdict = skip
    ;   Verdict = red
    ).

%% ONE LINE, not the rest of the transcript: libc's `.' matches a newline,
%% so `answer\(.*\)' ran on to the last `)' of the child's `1 answer(s).'
cocolog_answer(Args, Term) :-
    cocolog_out(Args, Out),
    (   re_first_atom('answer\\([^\n]*\\)', Out, A)
    ->  term_to_atom(Term, A)
    ;   Term = none
    ).
