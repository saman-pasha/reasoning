---
name: cocolog
description: Use for any work in or with cocolog, the Prolog whose knowledge base is a database — writing, porting from SWI-Prolog, running or debugging a Prolog program on it (the dialect, the builtins, the libraries, the store, threads and green threads); tensor programs with library(tensor_expr) over torch or tensorflow; drawing a predicate or explaining a failed, raised or slow query with the flow libraries (flow/chart, flow/debug, tools/flow); linting with cocolint; and changing cocolog itself — the engine in Cicili, a loadable module, a library, a suite case or a lesson. Read it before writing a line of Prolog or Cicili here, even for a small script, because cocolog reads like SWI-Prolog and differs exactly where a ported program does not look (one namespace, codes for double-quoted text, 64-bit integers, a prefix operator's atom, a store that outlives the process).
---

# SKILL — working in cocolog

cocolog is a Prolog. Its language is ISO Prolog as SWI-Prolog 9.0.4 runs it,
held to swipl's answers case by case. What is its own is the **knowledge
base**: a runtime arrangement — memory, a store embedded in the process, a
ZiguratIP server, Zeytun over HTTP — in which a clause is a row, and a running
proof is a term that can be frozen into rows and resumed by another process.
It is one binary, written in **Cicili** (C in S-expressions).

Version at the time of writing: cocolog 3.62.4, built with
Cicili 3.3.0. `./cocolog --version` answers it.

**Part A** is for writing and running Prolog on cocolog. **Part B** is for
changing cocolog itself. Each section stands alone: go to the one the task
names.

**A debug situation — a program that fails, raises, hangs, or is slow — is
answered with the flow tools, and they must be used first.** **Before the
first run**, `tools/flow/chart.pl` reads the program WITHOUT running it and
names the unknown call (and the predicate it probably meant), the argument
free where the engine refuses one, the left recursion, the clause never
tried, and the clauses not together (§8). **When a query fails, raises or is
slow**, `tools/flow/debug.pl` runs the goal in a child and writes
`BASE.txt`, one line a call, down to the call that failed, with the clauses
tried and where each stood (§9). **Do not guess, do not scatter `write/1`
through the program, and do not bisect the file by hand before the two
tools have run**: in a debug situation they are the first step, not the
last.

| the task | read |
|---|---|
| run a file, a goal, a script with arguments | §1 |
| write a program, or port one from SWI-Prolog | §2, §3, then lint it (§11) |
| find a predicate or a library | §4 |
| keep facts between processes, a server, transactions | §5 |
| threads, green threads, a pool | §6 |
| tensors, a network, training | §7 |
| what a predicate CAN do, and what is wrong in it | §8 |
| why a query failed, raised, or took so long | §9 |
| trace, backtrace, lint | §10, §11 |
| write a lesson or a suite case | §12 |
| change the engine, a module, a library | Part B: §13 to §16 first |

The documents, and what each one answers:

| file | answers |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | the owner's standing rules, the build's hazards, one bullet for each mechanism of the engine. Its rule wins over this file |
| [`README.md`](README.md), [`MORE.md`](MORE.md) | what cocolog is; the long form of every feature |
| [`COMPAT.md`](COMPAT.md) | every difference from SWI-Prolog and ISO, each row with what to write instead |
| [`MODULES.md`](MODULES.md) | how a module is written; the compiled-in libraries, one section each |
| [`TRACING.md`](TRACING.md) | the tracer, backtraces, a recorded window, the journal |
| [`STATUS.md`](STATUS.md) | what is proven, release by release, with its numbers |
| [`DESIGN-flow.md`](DESIGN-flow.md), [`DESIGN-compiling.md`](DESIGN-compiling.md) | the plans behind the flow libraries and the clause compiler |
| [`tutorials/`](tutorials) | 131 lessons that run: the fastest way to learn one library |
| [`tools/cocolint/GUIDE.md`](tools/cocolint/GUIDE.md) | the linter, the dialect card, the retrieval index |
| [`../cicili/SKILL.md`](../cicili/SKILL.md), [`../cicili/lib/README.md`](../cicili/lib/README.md) | the language of the C half, and its declarations |

When this file and `CLAUDE.md` disagree, `CLAUDE.md` has the owner's current
rule. When a document and the source disagree, the source wins. When cocolog
and swipl 9.0.4 disagree and `COMPAT.md` has no row for it, that is a bug.

---

# Part A — Prolog on cocolog

## 1. Run a program

```sh
./cocolog run FILE.pl                  # consult FILE, prove main
./cocolog run FILE.pl 'goal(X)'        # ... or this goal
./cocolog run a.pl b.pl main           # several files: the LAST argument is the goal
./cocolog -s FILE.pl -- ARG ...        # load FILE as a module, prove main
./cocolog query 'member(X, [a, b])'    # prove a goal and print every answer
./cocolog                              # the toplevel: ?- , ; for more, halt.
```

- **`run` consults; `-s` loads a module.** A consulted file's clauses are the
  program's own: with a store (§5) they are written into it, replacing what
  the file put there last time. `-s FILE` is `use_module(FILE), main`: the
  clauses are a module's, never written to a store, and every thread and
  isolated proof sees them (§6). Under the default `--local` the two look
  alike until a thread or a store is involved. A tool or a server is `-s`; a
  program whose clauses are the data is `run`.
- `run a.pl b.pl` with no goal reads `b.pl` as the goal (`Unknown procedure:
  b/0`). Name the goal when there is more than one file.
- `run` and `-s` print only what the program prints. `query` prints each
  answer as the goal instantiated, ten at most (`--answers N`, 0 for all).
- **Exit status** of `run` and `-s`: 0 proved, 1 failed (nothing is said), 2
  an uncaught error (its message and a backtrace on stderr), N after
  `halt(N)`. `query` exits 0 whether it answered or printed `false.`, and 1
  on an error.
- **A program's arguments come after `--`**:
  `current_prolog_flag(argv, [Exe|Args])`. `library(main)` parses them: define
  `main(Argv)` and `opt_type/3`, one row for each spelling of a flag
  (`opt_type(n, count, integer). opt_type(count, count, integer).`), and call
  `argv_options(Argv, Positional, Options)` (lesson 38).
- Write no `:- initialization(main).`: both commands call `main` themselves.
  A file that must also run under swipl says `:- initialization(main, main).`
- stdout into a pipe is block-buffered: `flush_output/0` before the program
  waits for anything.
- `--trace` prints the four ports, `--backtrace` every call an uncaught error
  was raised in, `--no-backtrace` the message alone (§10).
- `./cocolog --help` lists the other commands (`consult`, `forget`, `vacuum`,
  `start`, `step`, `finish`, `work`, `swarm`, `list`, `drop`: the store's
  housekeeping, and machines suspended in it).

The binary finds its libraries in `$COCOLOG_LIBRARY` (colon-separated), then
`./library`, then beside itself. Set the variable when a program is run from
another directory against a checkout that is not the binary's.

## 2. The dialect: write SWI-Prolog, then check these

Each row compiles, loads and runs, and does something other than what a
SWI-Prolog programmer expects. The first four are the ones that bite a port.

| you write | what happens here | write instead |
|---|---|---|
| a predicate with a library's name: `append/3`, `step/4`, a grammar `digit//1` | **one namespace.** `:- module/2` is read and import lists are accepted, but every clause is in one store, so yours JOIN the library's clauses | prefix what you define: `shop_total/2`, `shop_digit//1`. A grammar head counts two more arguments. cocolint finds each one (N1) |
| `"text"` | a list of codes, ISO's default | `'text'` for an atom; `:- set_prolog_flag(double_quotes, string).` (or `atom`, `chars`) at the file's head for strings. `sub_atom/5`, `atom_concat/3`, `string_concat/3` and `sub_string/5` refuse a code list |
| an integer past 64 bits | `evaluation_error(int_overflow)` | `library(bigint)`; rationals (`1r3`) are 64-bit too |
| `K == dynamic -> A ; B`, `X = table, G`, `Op = - ^ Y` | a syntax error, as in swipl: a prefix operator's atom before an infix operator | brackets: `(dynamic)`, `(table)`, `(-)`. The atoms: `dynamic discontiguous initialization meta_predicate module_transparent multifile public table thread_initialization thread_local volatile`, `\+`, `-`, `+`, `\` |
| `open/3`, `read/1`, `write/2`, `nl/1`, `tab/2`, `read_term/2` | unknown procedure: the engine has no streams | `:- use_module(library(stream)).` gives ISO's. Without it: `format/3` with a sink (`atom(A)`, `codes(Cs)`, `string(S)`), `with_output_to/2`, `read_file_to_codes/2`, `write_file_from_codes/2`, `term_to_atom/2`, `read_term_from_atom/3` |
| `shell/1`, `thread_create/2`, `tcp_connect/2` | unknown until its module is loaded | `:- use_module(library(process)).` (`sh/1`, `proc_run/4`), `library(thread)`, `library(tcp)` (§4) |
| `:- table p/2.`, `freeze/2`, `dif/2`, `when/2`, attributed variables, dicts, `flag/3`, `recorda/2`, `predsort/3`, `assertion/1`, `random_between/3`, `read_string/3`, a postfix operator | not there, on purpose: an existence error stops a port where a near-copy would differ in silence. `:- table` reads and the load reports `table/1` unknown; `op(200, xf, f)` is a domain error | write it out: `msort/2` or `sort/4`, `must_be/2`, `X is random(N)` |
| `call_with_inference_limit/3` | absent: swipl's keeps choice points this cannot | `call_limited(G, Limit, R)`: commits to the first solution, R is `true` or `inference_limit_exceeded`, fails when G fails. `call_metered(G, Limit, Used, R)` also says what G spent |
| `current_prolog_flag(F, V)` of any flag | fails: twenty flags answer. `set_prolog_flag/2` of an unknown flag is `existence_error(prolog_flag, F)` | keep state with `nb_setval/2`; do not branch on flags |
| `functor(T, '[\|]', 2)` | the list cell is `'.'/2` | `T = [_\|_]`. (`[]` is not `'[]'`, as in SWI 7.) |
| a string asserted into a database store, or sent down a channel | comes back a code list: both carry canonical text | store atoms; convert at the edge |
| `catch(G, error(T, context(_, _)), R)` | misses a loader's error, whose context is unbound, and a refusal, `error(cocolog_error(Text), _)` | `error(T, _)` |
| `current_predicate(N/A)` to probe a library | answers for the program's and the system's predicates, not for a loadable module's | call inside `catch/3` and catch `existence_error` |
| bytes from a socket as text | `library(tcp)` and `library(tls)` read and write BYTES whatever the program counts | cross with `string_bytes(Text, Bytes, utf8)`, as `library(http)` does |

Three more facts hold everywhere:

- **Text is counted in characters**, as SWI counts it. A program that wants
  bytes says `:- set_prolog_flag(text_units, bytes).`
- **A clause must fit one page of a database store** (65 536 bytes on a store
  made by a current build, 8 192 on an older one): `assertz/1` raises
  `resource_error(clause_length)` past it. Chunk big data.
- **Every builtin written in C is deterministic.** The ones that enumerate are
  the ones that enumerate in swipl, and they do here: `between/3`, `member/2`,
  `nth0/3`, `select/3`, `sub_atom/5`, `atom_concat/3`, `clause/2`,
  `retract/1`, `arg/3`, `char_type/2`, `current_op/3`, `repeat/0`.

What is swipl's and worth knowing it is: error terms with their contexts
(`error(type_error(integer, a), context(system:succ/2, _))`) and the messages
printed for them; the logical update view; first-argument and just-in-time
indexing; `setup_call_cleanup/3`; single-sided rules (`Head => Body`); the
determinism guards `$/0` and `$/1`; `print_message/2` with `message_hook/3`;
`term_expansion/2` and `goal_expansion/2`; `:- include/1`, `:- encoding/1`;
cyclic terms; every option of `write_term/2`; `listing/1`'s layout; a float's
text.

[`COMPAT.md`](COMPAT.md) is the whole table, about 150 rows: search it for
the predicate before calling a difference a bug.
`sh tools/cocolint/tool.sh card --card` prints the dialect card, the two dozen
rows a port trips on most.

## 3. Files and loading

- `:- use_module(library(json)).` loads a tier-2 library (§4). **Tier 1 is
  always there**: a `use_module` for it does nothing, and cocolint says so
  (T1). Keep one only in a file swipl also runs.
- `consult/1`, `[File]`, `ensure_loaded/1`, `load_files/2` and `:- include/1`
  are swipl's. A relative name is looked for beside the loading file first,
  then in the working directory, with `.pl` added.
- **A load reports and goes on.** A directive that fails or throws, and a
  clause that does not read, are each reported on stderr in swipl's words
  (`ERROR: FILE:LINE:COL: Syntax error: ...`, `Warning: ... Goal (directive)
  failed`) and the rest of the file loads. So a typo is a predicate with one
  clause less, not a program that stops. Read a load's stderr:

  ```sh
  ./cocolog run FILE.pl true 2>&1 | grep -E 'ERROR|Warning'
  ```

- The load warns as swipl's: singleton variables, a predicate's clauses not
  together, a test the compiler can decide. Every file of this tree loads with
  no warning. Keep it so: a variable used once is `_`, a variable used twice
  is not named `_X`, and a helper goes after the predicate that calls it,
  never between two of its clauses.
- Consulting a file again replaces the clauses it put there last time and
  leaves asserted clauses and other files' alone.

## 4. What is there

### The engine and tier 1 — nothing to load

| area | predicates |
|---|---|
| control | `,` `;` `->` `*->` `\+` `!` `call/1..` `once/1` `ignore/1` `not/1` `catch/3` `throw/1` `findall/3,4` `forall/2` `bagof/3` `setof/3` `aggregate_all/3` `between/3` `repeat/0` `halt/0,1` `setup_call_cleanup/3` `call_cleanup/2` `call_limited/3` `call_metered/4` `$/0` `$/1` `G@M` `apply/2` |
| type and order | `var nonvar atom number integer float rational atomic compound callable is_list string ground` `acyclic_term/1` `cyclic_term/1` `= \= == \== @< @=< @> @>=` `compare/3` `=@=` `\=@=` `unify_with_occurs_check/2` `subsumes_term/2` |
| arithmetic | `is =:= =\= < =< > >=` `succ/2` `plus/3` `set_random/1`; functions `+ - * / // div mod rem min max ** ^ gcd lcm >> << /\ \/ xor \ msb lsb popcount getbit powm abs sign float integer truncate round floor ceiling ceil sqrt exp log log10 sin cos tan asin acos atan atan2 sinh cosh tanh asinh acosh atanh erf erfc lgamma copysign nexttoward rdiv rational rationalize numerator denominator float_integer_part float_fractional_part eval roundtoward cputime random random_float pi e inf nan epsilon` |
| terms | `functor/3` `arg/3` `=../2` `copy_term/2` `compound_name_arity/3` `compound_name_arguments/3` `setarg/3` `nb_setarg/3` `term_variables/2` `numbervars/3,4` |
| atoms and text | `atom_codes atom_chars char_code atom_length atom_concat/3 sub_atom/5 atom_number number_codes number_chars upcase_atom downcase_atom atomic_list_concat/2,3 term_to_atom atom_to_term/3 read_term_from_atom/3 char_type/2 code_type/2 name/2 atom_string` |
| strings | `string_concat/3 sub_string/5 string_length string_chars string_codes string_code/3 string_to_atom string_lower string_upper number_string split_string/4 string_bytes/3 term_string/2,3 text_concat/3 text_to_string/2` |
| lists | `append/2,3 member memberchk length nth0/3,4 nth1/3,4 last reverse msort sort/2,4 keysort select/3,4 selectchk subtract intersection union subset delete flatten sum_list max_list min_list max_member min_member numlist/3 list_to_set is_set permutation prefix nextto same_length proper_length clumped` |
| apply | `maplist/2..5 foldl/4..7 include/3 exclude/3 partition/4,5 convlist/3 scanl/4..7`, and yall's lambdas: `[X, Y]>>Goal`, `Free/[X]>>Goal` |
| database | `assert/1 asserta/1 assertz/1 retract/1 retractall/1 abolish/1,2 clause/2 dynamic/1 discontiguous/1 multifile/1 listing/0,1 portray_clause/1 current_predicate/1 predicate_property/2 op/3 current_op/3` |
| globals | `nb_setval/2 nb_getval/2 nb_current/2` (kept across backtracking), `b_setval/2 b_getval/2` (undone by it) |
| output | `write/1 writeln/1 print/1 writeq/1 write_canonical/1 write_term/2 nl/0 tab/1 format/1,2,3 with_output_to/2 flush_output/0 print_message/2 message_to_string/2` |
| files and the system | `exists_file exists_directory access_file size_file time_file delete_file rename_file make_directory make_directory_path delete_directory directory_files working_directory tmp_file read_file_to_codes/2 write_file_from_codes/2 append_file_from_codes/2 absolute_file_name/2,3 file_base_name file_directory_name file_name_extension same_file read_link/3 expand_file_name` `getenv/2 setenv/2 unsetenv/1 get_time/1 sleep/1 statistics/2 garbage_collect/0`. `read_file_to_codes/2` FAILS for a missing file or a directory (ask `exists_file/1` first), and raises `resource_error(stack)` for a file whose codes pass the stack limit: a code is 24 bytes of list, so the default 1 GB holds a file of 44 MB; read a bigger one a line at a time through `library(stream)` |
| loading | `consult/1 load_files/2 ensure_loaded/1 use_module/1,2 include/1 initialization/1,2 module/2 source_location/2 prolog_load_context/2 expand_term/2 expand_goal/2 current_prolog_flag/2 set_prolog_flag/2` |
| grammars | `-->` `phrase/2,3` `call_dcg/3` `dcg_translate_rule/2`; `library(dcg/basics)`: `blank blanks white whites digits//1 integer//1 float//1 number//1 string//1 string_without//2 nonblanks//1 xinteger//1 eos eol remainder//1`; `library(dcg/high_order)`: `sequence//2,3,5 optional//2 foreach//2,3` |
| errors | `must_be/2 is_of_type/2 type_error/2 domain_error/2 instantiation_error/1` |
| SWI's own libraries, vendored unmodified | `assoc` (`list_to_assoc put_assoc get_assoc ...`), `pairs`, `ordsets`, `ugraphs`, `aggregate` (`aggregate/3,4 aggregate_all/3,4 foreach/2`), `yall` |
| green threads | `library(async)`, §6 |
| the store's connection | `zigurat_begin/0 zigurat_commit/0 zigurat_rollback/0 zigurat_isolation/1 zigurat_call/2,3` (§5), `vacuum_kb/0,1` |

### Tier 2 — Prolog libraries, loaded when asked

`:- use_module(library(NAME)).` The lesson is
`tutorials/library/NN-NAME.pl`.

| library | what it is | lesson |
|---|---|---|
| `json`, `xml`, `html` | a term as a document and back; writers answer CODES, readers take codes or an atom; text is said `str("...")`; html carries CSS | 12, 13, 14 |
| `http`, `httpd`, `websocket` | HTTP/1.1 as a grammar; a server whose pages are clauses (`httpd_serve/2,3`, the hook `httpd_page/3`); RFC 6455, client and server | 15, 16, 49 |
| `template` | text with holes, and the clauses that fill them | 52 |
| `main` | an entry point and its argv: `main/0`, `argv_options/3` | 38 |
| `kbs` | many knowledge bases driven from one script | 34 |
| `cowork` | a crew of worker threads that outlives the turn | 42 |
| `ca` | a certificate authority as rules, over `x509` | 27 |
| `astar`, `hex` | shortest paths over a graph of goals; hexagonal-grid arithmetic | 31, 30 |
| `llm` | a language model as a goal: `llm_chat/2,3`, `llm_stream/3`, `llm_embed/3`, over `curl` and `json`. The key is read from the environment, never written in a file or a term | 36 |
| `clay_ray` | Clay's render commands drawn with `ray` | 47 |
| `tensor_expr` | tensors as expressions over `torch` or `tensorflow` | §7, 39 |
| `flow/chart`, `flow/debug` | a predicate drawn; a query explained | §8, §9, 50, 51 |

### Tier 2 — loadable modules

`:- use_module(library(NAME)).` loads `library/NAME.so`, built by
`sh modules/NAME/build.sh` or all at once by `make modules`. The suite and
the lessons load them and do not build them: a missing `.so` is a missing
library, said at load.

| module | gives | needs |
|---|---|---|
| `stream` | ISO streams: `open/3,4 close/1 read_term/2,3 get_char/1,2 put_char/1,2 format/3 on a stream set_output/1 stream_property/2 ...` | nothing |
| `process` | `sh/1,2 shl/1,2 proc_run/4 proc_spawn/2 proc_wait/3 proc_stop/1`, and the suite's `check/3 checks_done/0` | nothing |
| `thread` | `thread_create/2 thread_join/2`, channels, mutexes, conditions (§6) | nothing |
| `tcp` | `tcp_listen/2 tcp_accept/2 tcp_connect/2 tcp_read/2 tcp_write/2 tcp_close/1`; `unix(Path)` where a port stands | nothing |
| `os`, `signal`, `text` | `os_is/1 os_cpus/1 os_tmp/1 os_which/2 ...`; `on_signal/3`; `re_match/2 re_replace/4 head_lines/3 ...` | nothing |
| `regex` | PCRE2: `rx_match/2 rx_first/3 rx_all/3 rx_replace/4 rx_split/3 rx_named/4` | libpcre2 |
| `curl` | an HTTP client: `curl_get/3 curl_post/5 curl_request/5` | libcurl |
| `sha`, `aes`, `der`, `x509`, `tls`, `bigint` | hashes and HMAC, AES, DER, certificates, TLS sockets, arbitrary-precision integers | a built ZiguratIP |
| `torch`, `tensorflow` | the `tensor_*` and `model_*` predicates (§7) | libtorch; TensorFlow's C library |
| `numpy` | `np_*` arrays (opt-in, embeds CPython) | python3 with numpy |
| `opencv` | `cv_*`: images, features, dnn | OpenCV 4 |
| `ray`, `clay` | raylib's 2D, 3D and input; a user interface as a term laid out by Clay | raylib; nothing |

**The exact surface of a library is its file's header**: `library/NAME.pl`,
or `modules/NAME/NAME.cicili` for a module. Its lesson shows it used.
`make index` writes `tools/cocolint/surface.jsonl`, one JSON object a library
with its header and its documented predicates, which is the quickest thing to
search.

## 5. The knowledge base

Nothing above the store knows which arrangement it runs in. `assertz/1` is
`assertz/1` in all four; what differs is whether the clause outlives the
process and who else can see it.

| option | the store | who sees a write |
|---|---|---|
| `--local` (the default) | memory | this process, until it ends |
| `--embed [DIR]` | ZiguratIP's storage engine in this process, over a directory (`./KB`) | every later process that opens DIR; one process at a time, the others wait their turn |
| `--kb NAME --host H --tcp [PORT]`, `--tls [PORT]` | a ZiguratIP server | every process on that knowledge base |
| `--http [PORT]`, `--https [PORT]` | Zeytun, read only | nobody: it only reads |

```sh
./cocolog --embed /tmp/kb run shop.pl 'assertz(shop_seen(today))'
./cocolog --embed /tmp/kb query 'shop_seen(X), shop_price(apple, P)'   # a second process
./cocolog --embed /tmp/kb forget shop_seen 1                           # drop one predicate
./cocolog --embed /tmp/kb vacuum                                       # reclaim dead rows
```

- With a store, `run FILE` writes the file's clauses into it and `-s FILE`
  does not. A tool run with `run` against a real knowledge base leaves its own
  source in the database.
- Each finished goal is one committed transaction. `library(zigurat)`'s
  predicates steer it from inside: `zigurat_begin/0`, `zigurat_commit/0`,
  `zigurat_rollback/0`, `zigurat_isolation/1`. Under `--local` they raise.
- A writing process rewrites the whole predicate and the old rows stay dead
  until `vacuum`. A store that has grown slow wants a vacuum.
- The first call of a predicate fetches all its clauses. A predicate the store
  cannot read raises `resource_error(knowledge_base)`.
- A store is in the writing machine's byte order and does not travel.
- Lesson: `tutorials/basics/11-the-knowledge-base.pl`.

## 6. Threads and green threads

Two models. Choose by what must be shared.

| | `library(async)` — green threads | `library(thread)` — OS threads |
|---|---|---|
| load | nothing: tier 1 | `:- use_module(library(thread)).` |
| shares | ONE store with its caller: a task sees and writes the program's clauses | nothing: a machine, a store and a connection of its own |
| sees | everything the caller sees | every registered module; nothing the parent asserted or consulted |
| passes terms | `async_run/2`'s result, `await/2`, channels: each a copy | channels and `thread_join/2`: each a copy |
| scheduling | one worker a core, a task preempted every 10 000 steps | the kernel's |

```prolog
conc_square(X, Y) :- Y is X * X.

conc_green(Got) :-
    async_run(( channel(C),
                go(( conc_square(3, Y), channel_send(C, Y), channel_close(C) )),
                channel_recv(C, _) ), Answer),
    Answer = (_, _, channel_recv(_, Got)).        % Got = 9

conc_os(Status) :-                                % Status = true
    thread_create(conc_square(5, _), Id),
    thread_join(Id, Status).
```

- **A result is a copy.** The variables of the goal given to `async_run/2`,
  `go/2` or `thread_create/2` are not bound in the caller. Read the answer
  from `async_run/2`'s second argument (the goal as instantiated), from
  `await(Id, Result)`, or from a channel.
- **An OS thread sees modules, not consulted clauses.** `conc_os/1` above
  answers `true` under `cocolog -s FILE`. Under `cocolog run FILE` its Status
  is `error('uncaught exception: ...')` around
  `existence_error(procedure, conc_square/2)`: a thread's store starts empty
  and is filled from the module registry. Load the program with `-s` or
  `use_module`, before the first thread starts. The same holds for an httpd
  pool: a page consulted or asserted is a 404 in a worker.
- Green tasks run under `async_run/1,2` only: `go/1,2`, `yield/0`,
  `await/1,2`, `await_all/1`, `channel/1,2`, `channel_send/2`,
  `channel_recv/2` (fails on a closed, empty channel), `channel_close/1`,
  `async_workers/1`. A task that fails makes `await` fail; one that throws
  makes it throw; every task blocked is `resource_error(deadlock)` at
  `async_run`.
- **The world ends when its main task ends**, as a Go program ends when
  `main` returns: a task still running is stopped and one still ready is
  never run. `await/1,2` or `await_all/1` what must finish. `halt/0,1` in a
  task halts the process.
- **Short of memory, a task is one task's affair**: it ends with
  `resource_error(memory)` for its status, its `await` raises that, and the
  world goes on. `go/1,2`, `channel_send/2` and `channel/2` raise it too
  where a text or a buffer is what there is no room for. A host whose own
  machine is refused memory outright ends its run, `out of memory`, exit 2.
- An `await` or a blocking send or receive inside `findall/3` (any nested
  search) cannot suspend its task: it waits there and holds its worker.
  Wait outside the search where the program allows it.
- A store write in a green world stops every worker while it lands. Write
  seldom, and do the first call of each predicate before the world starts.
- Size work from `async_workers/1`, never from a number: a machine may have
  three cores.
- Mutexes and conditions (`with_mutex/2`) serialise the world outside — a
  file, a socket, the terminal — not terms.
- Lessons 18 and 54; `library/async/README.md` has the model and its limits.

## 7. `library(tensor_expr)` — tensors as expressions

```prolog
:- use_module(library(tensor_expr)).    % loads library(torch), lends the operators
```

An expression names a tensor. `T := Expr` runs it and frees every
intermediate, so only the result is left to free:

```prolog
L := mean((X matmul W + B - Y) ^ 2.0)
```

**A float is a number; an integer is a handle.** `A * 2.0` scales A, `A * 2`
multiplies by the tensor whose handle is 2. Write `2.0`.

| form | meaning |
|---|---|
| `A matmul B`, `A + B  A - B  A * B  A / B` | binary, elementwise but for `matmul` |
| `A + 1.5`, `A ^ 2.0`, `1.5 - A`, `2.0 / A` | with a float scalar |
| `- A`, `relu(A) sigmoid(A) tanh(A) exp(A) log(A) sqrt(A) abs(A) transpose(A)` | unary; each is a prefix operator too (`relu A`) |
| `mean(A) sum(A) max(A) min(A) std(A)` | a one-element TENSOR, so it differentiates |
| `[[1.0], [2.0]]`, `zeros(S) ones(S) randn(S) rand(S) full(S, V) eye(N) arange(N) randperm(N) csv(Path)` | leaves; S is a shape list |
| `reshape(A, S) cat([A, B], Dim) argmax(A, Dim) rows(A, From, To) cols(A, From, To) standardise(A, N) index_rows(A, I)` | shape and selection |
| `parameter(A)` | a fresh leaf that requires gradient, with A's values |
| `step(W, G, LR)` | `W - LR*G` as a NEW leaf: a step makes a parameter, not a node |
| `glorot(R, C)` | `randn([R, C])` scaled; wrap it in `parameter(...)` |
| `softmax(A) log_softmax(A) layer_norm(A) gelu(A) row_sum(A) row_mean(A) mean_rows(A, L)` | row-wise composites |
| `conv2d(A, K, Shifts) pool2(A, P) up2(A, U)` | pictures as rows `[N*H*W, Cin]`; the helpers come from `shifts/3`, `pool_matrix/3`, `up_matrix/3` (or `taps/4`, `pool_taps/4`, `up_taps/4` for large pictures) |
| `cross_entropy(Logits, OneHot) bce(P, Y) mse(P, Y)` | losses, the mean over rows |
| `loss(X, Y, W, B)` after `loss(X, Y, W, B) ::= mse(X matmul W + B, Y).` | a function the program defined with `::=`, used by name |

The **answers** stand outermost on the right of `:=` and give a Prolog term,
never a handle to free:

| form | answers |
|---|---|
| `L := list(E)`, `V := item(E)`, `S := shape(E)` | nested lists; the one number; the shape |
| `V := reduce(mean, E)` | a NUMBER: `sum mean max min std` |
| `Gs := grad(E, Ps)` | one gradient for each parameter handle in Ps |
| `Tr-Te := split(E, N)` | a train and a test part |
| `Ps := params(Name)` | the parameters saved under Name, as parameters |
| `T := force(E)`, `S := stats` | compute now under graph mode; the graph's statistics |

### A procedure is a grammar rule

A rule whose body is `Var = Expr` bindings is a procedure: each binding runs
through `:=`, and `exec/1` frees every tensor the rule made that its head does
not return. A plain goal goes in braces. This is the shape of all forty-two
tutorials (`tutorials/tensor/01-linear-regression.pl`):

```prolog
:- use_module(library(tensor_expr)).

loss(X, Y, W, B) ::= mse(X matmul W + B, Y).

parameters([W, B]) :-
    W := parameter(randn([1, 1])),
    B := parameter(zeros([1])).

train :- exec(train).
train -->
    seed(1),
    lin_data(64, X, Y),                              % another procedure
    { parameters(Ps0), fit(200, Ps0, X, Y, [W, B]) },
    L = item(loss(X, Y, W, B)),
    { format("final mse ~4f~n", [L]) },
    params_save(t01_linreg, [W, B]).

fit(0, Ps, _, _, Ps) :- !.
fit(K, [W, B], X, Y, PsF) :-
    L := loss(X, Y, W, B),
    Gs := grad(L, [W, B]),
    sgd_step([W, B], Gs, 0.2, Ps2),                  % frees W, B and Gs
    tensor_free(L),
    K1 is K - 1,
    fit(K1, Ps2, X, Y, PsF).

predict :- exec(predict).
predict -->
    [W, B] = params(t01_linreg),
    Out = list([[0.5]] matmul W + B),
    { format("~w~n", [Out]) }.
```

**The one discipline: a rule frees nothing by hand.**

- `tensor_free/1`, `free_all/1`, `sgd_step/4` and `adam_step/6` free what they
  are given, so they are predicates, never written in a rule. The loop that
  steps an optimiser is a predicate (`fit/5` above); its forward pass may be a
  procedure.
- Parameters are made in that predicate and brought in through braces:
  `{ parameters(Ps0), fit(..., Ps0, Ps) }`. Written as `W0 = parameter(...)`
  in the rule, `W0` would be freed by the optimiser's first step and again by
  `exec/1`: the goal fails after its last print, and a store it meant to save
  into is never committed.
- Inside a rule `=` is the binding. A plain unification goes in braces.
- Usable in a rule without braces: `seed/1`, `tensor_execution/1,2,3` (to set),
  `torch_device/1`, the `model_*` predicates, `params_save/2`, `params_load/2`,
  `one_hot/3`, `accuracy/3`, `block_mask/3`, `causal_mask/3`, `shifts/3`,
  `pool_matrix/3`, `up_matrix/3`, `taps/4`, `pool_taps/4`, `up_taps/4`.

### Predicates, backends, running

- Optimisers: `sgd_step(+Ps, +Gs, +LR, -Ps2)`; `adam_init(+Ps, -State)`,
  `adam_init(+Ps, [beta1(B)], -State)`,
  `adam_step(+Ps, +Gs, +State, +LR, -Ps2, -State2)`.
- `params_save(+Name, +Ps)` writes the parameters as TERMS into the knowledge
  base; `params_load(+Name, -Ps)` (or `params(Name)` in an expression) reads
  them. Handles are integers local to a process; terms are what the next
  process loads. So each tutorial has three goals, `train`, `test` and
  `predict`, and each is its own process over one store:

  ```sh
  ./cocolog --embed /tmp/t run tutorials/tensor/01-linear-regression.pl train
  ./cocolog --embed /tmp/t run tutorials/tensor/01-linear-regression.pl test
  ./cocolog --embed /tmp/t run tutorials/tensor/01-linear-regression.pl predict
  ```

- **Two backends, one grammar.** The file never names its backend; set it
  from outside: `tensor_execution(torch | tensorflow, eager | graph)`, with a
  third argument `cpu | cuda | auto` for the device.

  ```sh
  ./cocolog --embed /tmp/t run tutorials/tensor/32-resnet.pl \
      "tensor_execution(tensorflow, graph), train"
  ```

- The layer underneath is `library(torch)`: `tensor_*` predicates over
  handles, and whole models as terms — `model_new(+Spec, -M)` with layers
  `input(N) dense(W, Act) conv(...) pool(...) flatten dropout(P) norm
  embedding(V, D) lstm(H) attention(H) ...`, `model_train/4`,
  `model_predict/3`, `model_evaluate/5`, `model_save/2`, `model_load/2`
  (`modules/torch/README.md`, lesson 22).
- A bad expression raises `error(domain_error(tensor_expression, E), _)`; an
  unbound one, `error(instantiation_error, _)`.
- To add a form, add an `expr//2` clause in your own file: it is an extension
  point.
- Needs `library/torch.so` (`sh modules/torch/build.sh`, with libtorch) or
  `library/tensorflow.so`. Without one the load says so. References:
  `library/tensor_expr.pl`'s header, `tutorials/tensor/README.md` (the
  forty-two networks, linear regression to object detection), lesson 39.

## 8. `library(flow/chart)` — what a predicate can do

A flowchart of a predicate, from the query down to the C it reaches.
**Nothing is run**: the program is read and analysed for one call pattern.
It writes `BASE.svg` for a person and `BASE.xml` for an agent, one graph with
shared ids.

```sh
./cocolog -s tools/flow/chart.pl -- SPEC FILE BASE [OPTION ...]
./cocolog -s tools/flow/chart.pl -- 'f_show(+)' faults.pl out/faults
```

```
out/faults.svg
out/faults.xml
faults.pl:5:29: error: f_show/1: f_print/1 is defined nowhere: no clause, builtin, module or dynamic declaration answers it, so this call raises existence_error [unknown_procedure p1.c1.g2]
faults.pl:3:23: error: f_total/2: S0 is free on every path to here, and is/2 evaluates it: this call raises an instantiation error [instantiation p2.c2.g1]
```

- **SPEC** is a call pattern, `report(+, -)`, with `+` bound, `-` free and `?`
  either; or `Name/Arity` (every argument `?`); or `Name//Arity` for a
  nonterminal.
- **Exit status**: 0 both files written, 1 no such predicate, 2 anything else,
  with the reason on stderr. A finding is not a failure of the command. The
  directory of BASE must exist.
- **Options**: `libraries=none|reach|all`, `depth=N|all` and
  `only=NAME/ARITY,...` (what the picture shows; the XML is never pruned),
  `load=FILE,library(NAME),...` (the program's other files, whose predicates
  then count as defined), `modules=SRC.cicili,...` (a program's own modules),
  `title=TEXT`, `progress=S`.
- **Findings**, each one line as a compiler writes it, a `<finding>` at the
  head of the XML, and a red disc on its box: a call nothing answers (with the
  name it probably meant); an argument free where the engine refuses one;
  left recursion; a clause never tried; a `%! p(...) is det` the code does not
  keep; a predicate's clauses not together, or defined twice; a thread never
  joined; a lock kept on a way out.
- **The XML says what the picture does**: every goal with its file, line and
  column, its modes, `can_fail`, `choice`, the panel it calls and `on_fail`
  (the id of the goal tried again, `next_clause`, or `fail`). Ids are shared
  with the SVG: panel `p3`, clause `p3.c2`, goal `p3.c2.g4`.
- From Prolog (`:- use_module(library(flow/chart)).`):
  `flow_chart(+Spec, +Base, +Options)` with `source(File)` required,
  `flow_graph(+Spec, -Graph, +Options)`, `flow_findings(+Graph, -Findings)`,
  `flow_svg/2`, `flow_xml/2`. A finding is `finding(N, Kind, Severity, At, In,
  where(File, Line, Col), Text, See)`.
- It needs `library/stream.so` and `library/flow/tables.pl`, which
  `make modules` writes. **After adding a C builtin, give it a line in
  `library/flow/modes.pl` and run `sh tools/flow/build.sh`**: the chart reads
  its modes from there, and `test/flowchart.pl` holds the two together.
- A large program takes time: the translator (1 066 predicates) charts in
  about fifty seconds. Lesson 50.

Use it before running anything: a chart of the entry predicate finds the
misspelt call and the unbound `is/2` without a test.

## 9. `library(flow/debug)` — what a query did

```sh
./cocolog -s tools/flow/debug.pl -- GOAL FILE BASE [OPTION ...]
./cocolog -s tools/flow/debug.pl -- 'shop_order([apple-1, pear-1], T)' shop.pl out/shop txt=true
```

```
out/shop.svg
out/shop.xml
out/shop.txt
shop_order([apple - 1, pear - 1], T): false at step 11; recorded 1 to 11; diverged no; ...
```

The program runs twice, each time in a child process that reads it afresh: a
**probe** at full speed learns how the run ends and at which step, and a
**replay** records a window of steps. Nothing slows the run being explained.
`BASE.svg` draws the path over the flowchart (reached boxes heavy, failed red,
raised purple); `BASE.xml` holds the same as `<call>`, `<event>` and `<why>`.
`txt=true` writes `BASE.txt`, one line a call, which is the form to read:

```
1 shop_order([apple-1,pear-1],_G22) fail [c2] query.g1
2   shop_buy(apple,1,_G410) exit shop_buy(apple,1,3) [c1] p1.c2.g1 :16:5
...
8     shop_buy(pear,1,_G505) fail [c1] p1.c2.g1 :16:5
10       shop_stock(pear,_G539) exit shop_stock(pear,0) [c2] p2.c1.g2 :10:5
11       >=(0,1) fail [] p2.c1.g3 :11:5
% where it got furthest:
%  shop_order([apple-1,pear-1],_G22): clause 2, the furthest of 1 tried: 1 of its calls exited (call 1)
%      shop_buy(pear,1,_G505): clause 1, the furthest of 1 tried: 2 of its calls exited (call 8)
%        >=(0,1): failed, nothing of the program's to say why (call 11)
```

Each line is `STEP INDENT GOAL FATE [CLAUSES] BOX WHERE`. The indent is the
depth, two spaces a level. `cK` is a clause entered, `hK` a head that did not
unify. `pP.cK.gN` names the clause the call was made in, `:LINE:COL` where.

- **The unit is the step**, one a goal. `statistics/2` counts inferences, the
  steps less each `true` and `=/2`.
- **Exit status**: 0 the run was recorded, 1 the program has no such
  predicate, 2 anything else. A run that failed or threw is not a failure of
  the command.
- **Debug the entry goal.** Each child starts afresh, so a goal from the
  middle of a program lacks the globals and facts an earlier call set.
- **Record the whole run.** The window is the last 2 000 steps by default,
  whose why is only the last fallbacks. The first run says `false at step N`:
  run it again with `from=1 to=N`, and the foot of `BASE.txt` then says where
  each failed call got furthest, down to the call it failed at.
- **The furthest path can name a scan.** It ranks a clause by the calls of its
  body that exited. A clause that walks every position with `append/3` and
  tests each beats the clauses that did the work, and has read nothing. When
  the path ends in such a clause, rank the clauses by the steps they spent and
  read the arguments on the way.
- **A whole-run record is held in memory**, about 6 KB a step: 1.5 million
  steps took 8.8 GB and seven minutes. For a longer run, debug the entry goal
  over a shorter input, or take windows.

| option | does |
|---|---|
| `txt=true`, `svg=false`, `xml=false` | write `BASE.txt`; leave a document out |
| `window=N`, `from=I to=J` | the last N steps; or exactly these |
| `until=end\|answer(K)` | stop at the end, or at the K-th answer |
| `text=N` | write arguments whole up to N characters (a long one is cut, `...[318]`) |
| `when=COND` (`step=N`) | not how the run went but WHEN: the first step at which COND, a goal over GOAL's variables, holds. `when=nonvar(T)` answers `first holds at step 15` |
| `profile=all` | `BASE.prof`: steps by predicate, inclusive and self, the callers, the goals asked more than once, and where the TIME went. `profile=run` times the whole run |
| `windows=N jobs=J` | N windows along one run, J at a time, their profiles added up |
| `diff=FILE_B`, `diff_goal=GOAL_B` | two runs compared: the calls both made that answered differently, deepest first (`BASE.diff`) |
| `journal=true` | the probe journals every call that reaches the world — clock, file, process, thread — and the replay is answered from the journal and runs none of them |
| `cache=DIR` | keep the program's chart (a big program's chart is most of the time; needs `library/sha.so`) |
| `embed=DIR kb=NAME` | run over a store. What the run writes is written: debug against a copy |
| `own=all\|FILE,...` | explain the failed calls of every predicate, not only the chart's panels |

- A replay that does not end where the probe did — the program read the time,
  a file, the knowledge base — is said to have **diverged**. `journal=true`
  takes that away.
- From Prolog (`:- use_module(library(flow/debug)).`):
  `flow_debug(+Goal, +Base, +Options, -Run)` with `source(File)` required;
  `flow_why(+Run, -Whys)`, `flow_why_furthest/2`, `flow_why_raised/2,3` (why it
  raised: the calls the exception ended, the branch that chose it);
  `flow_when(+Goal, +Cond, +Options, -When)`; `flow_diff/3`;
  `flow_run_end/3`, `flow_run_time/3`; `flow_debug_windows/4` with
  `flow_profile_merge/4,5`. Run is `run(How, At, Answers, window(From, To),
  Calls, Bindings, Diverged, Journal)`, and How is `answer`, `false`, `limit`,
  `exception(Ball)`, `halt(Code)`, `error(Message)` or
  `diverged(I, Want, Got)`.
- Lesson 51; `library/flow/debug.pl`'s header is the reference.

**To find a cost**: `profile=all` over a few windows spread along the run,
rank the predicates by calls, then by callers, then read the repeats. A count
finds the cheap step taken a million times; `profile=time` finds the one step
that costs a thousand.

## 10. Tracing and backtraces

- An uncaught error prints its message, then `ERROR: In:` with the goal that
  raised and the goals left to run. `--backtrace` prints every call it was
  raised in instead, as `[Depth] Goal` (the run is slower). `--no-backtrace`
  prints the message alone.
- `--trace`, or `trace/0` and `notrace/0` from inside, prints swipl's four
  ports on stderr. It hides what swipl's hides: a library predicate shows its
  own call, not its helpers.
- `statistics(inferences, N)`, `call_metered/4` and `statistics(cputime, T)`
  measure from inside.
- [`TRACING.md`](TRACING.md) has the ports, the inference clock, a recorded
  window and the journal.

## 11. cocolint

```sh
sh tools/cocolint/lint.sh FILE.pl ...     # exit 1 on a HARD finding
sh tools/cocolint/lint.sh --auto          # every changed .pl, and the dialect card
make lint FILES=FILE.pl
```

```
port.pl:3:1 HARD N1 `append/3' is already defined by lib/lists.cicili. Consult APPENDS, so the two sets of clauses merge ...
    fix: prefix it ...
port.pl:5:9 HARD S1 [X3] Deliberately absent so ported code errors instead of silently differing ...
cocolint: 2 HARD, 1 WARN over 1 file(s)
```

| rule | fires on |
|---|---|
| N1, N2, N3 | a head that collides with a library's clauses; with a loaded module's C name (dead code); with a control construct |
| S1 | a banned form of the dialect card: `:- table`, `error(T, context(_, _))`, `'[\|]'`, stream predicates without `library(stream)`, `predsort/3` and its kin, a flag that does not answer |
| T1, Z1 | `use_module` of a tier-1 library; a clause too long for a page |
| U1 | an acknowledgement that excuses nothing |

- A form committed on purpose carries `% cocolint: ID -- why` on its line, or
  alone on the line before. The reason is required.
- **The whole tree lints clean, and `test/lint.pl` holds it to that.** Lint
  every new or changed `.pl` before a commit.
- **cocolint cuts a file into clauses with a scanner of its own.** A clause
  that does not read lints clean. A load's stderr is what finds it (§3).
- The dialect card cites engine lines. After touching `lib/` or
  `cocolog.cicili`: `sh tools/cocolint/tool.sh card --check`.

## 12. A lesson, a suite case

- **A lesson is a test.** Every claim is a `must(Label, Got, Want)`; the
  helper is repeated at the foot of each file so a lesson can be copied
  anywhere; the last line a lesson prints is exactly `done`. Run one as the
  suite does:

  ```sh
  COCOLOG_LIBRARY=$PWD/library ./cocolog run tutorials/library/12-json.pl main
  ```

  (A lesson run with `-s` is a module: a thread it starts loads it again.)
- **A new library gets a lesson in the same commit**:
  `tutorials/library/NN-name.pl`.
- **A suite case is `test/NAME.pl`**, run from the checkout root as
  `./cocolog -s test/NAME.pl`. `main/0` runs the checks, `check/3` and
  `checks_done/0` are `library(process)`'s, and the exit status is the
  verdict. `test/prelude.pl` has the helpers (`answer/3`, `cocolog_out/2`,
  `scratch/1`, `skip/1`, `spawn/2`). A check is a second process only when it
  must be. Add the case to `pl_names/1` in `test/run.pl`.
- **A swipl-compatibility case is `test/files/NAME.pl`**: one file run by
  both systems in the same empty directory, the two outputs compared byte for
  byte (`./cocolog -s test/files.pl -- NAME`). It wants the REFERENCE swipl
  9.0.4 and skips by name on any other.
- A clause has one scope: suffix a check's variables with its number, and
  never reuse a suffix.

---

# Part B — changing cocolog

## 13. Rule zero: Cicili's `lib/`

**Before writing any `(decl) (func …)`, `(struct …)`, `(typedef …)`,
`@define`, C or POSIX binding, or `(code …)`, look in `../cicili/lib/`.**

Cicili already declares the C17 and POSIX headers
([`../cicili/lib/std/c/`](../cicili/lib/std/c)), the standard containers
([`../cicili/lib/std/`](../cicili/lib/std)), and the bindings under `db`,
`net`, `python`, `cpp` and `parsi`. Import the binding, include the real
header, add the link flags. Do not copy a declaration from a header or from
another project. What is usually missing is only a C typedef for a struct the
real header leaves untyped — `(@define (code "pollfd struct pollfd"))` — named
exactly as the std declaration names it.

If a declaration is truly missing, it belongs in Cicili's `lib/`, and Cicili
is an input to this repository: that change needs the owner's explicit leave.
What belongs here is cocolog's own seams: `lib/module.cicili` and
`lib/sdk.cicili`, the two backends, and each module's `binding.cicili`.

Read [`../cicili/SKILL.md`](../cicili/SKILL.md) before a line of Cicili. A
wrong guess there compiles to something that fails much later.

## 14. Source map

| path | what lives there |
|---|---|
| [`cocolog.cicili`](cocolog.cicili) | the composition root: the commands, the options, the toplevel, and the version (`coco_version_text`) |
| `lib/term.cicili`, `term-walk` | cells, the machine, text, names, the heap; binding, the trail, unification, copying, cycles, the standard order |
| `lib/syntax.cicili` | the reader and the writer over one operator table; the parser is written once as macros and emitted twice |
| `lib/dcg.cicili` | the grammar translator, `phrase/2,3`, term and goal expansion |
| `lib/kb.cicili`, `kb-compile`, `kb-pred`, `kb-consult` | the clause store and its five backend hooks; compiled clauses, guards, environments; predicates, indexes, the update view, compaction; assert, consult, retract |
| `lib/solve.cicili`, `solve-journal`, `solve-control`, `solve-gc`, `solve-loop`, `solve-arith`, `solve-text`, `solve-db` | the engine: tables and declarations; the journal; continuations, choice points, throwing, error text, the tracer; the collector; the step loop; arithmetic; text; the database, listing and dispatch |
| `lib/builtins.cicili`, `builtins-format`, `builtins-db` | the builtins module: its table and Prolog half; `format` and the character classes; the database half and the dispatcher |
| `lib/lists.cicili`, `apply`, `files`, `library` | `library(lists)`, `library(apply)`, the Files library; `use_module` and the library path |
| `lib/swipl-ctype.cicili`, `swipl-det`, `swipl-props`, `swipl-system` | tables GENERATED under the reference swipl by `tools/ctype`, `tools/det`, `tools/props`, `tools/dwim`: run the generator again, never edit the table |
| `lib/swipl/` | SWI's eight vendored libraries, unmodified: do not edit |
| `lib/state.cicili` | the frozen machine: freeze and thaw |
| `lib/green.cicili` | the green scheduler: workers, channels, the write barrier |
| `lib/module.cicili`, `lib/sdk.cicili` | the module seam, and the SDK a loadable module is written against |
| `lib/zigurat-kb.cicili`, `zeytun-kb`, `zigurat-mod` | the two remote backends; `library(zigurat)` |
| [`client/`](client), [`embed/`](embed), [`parsi/`](parsi) | the wire client in C (`client/tls.c` the one TLS unit); the embedded store; the schema `make schema` compiles |
| [`modules/`](modules) | the twenty-one loadable modules, one directory each |
| [`library/`](library) | tier-2 Prolog libraries and the built `.so` files; `library/flow/` |
| [`tools/`](tools) | `cocolint/` the linter; `flow/` chart, debug, `zero.sh`; `cc/` the compiler wrappers; `ci/`, `cloud/` |
| [`test/`](test), [`tutorials/`](tutorials), [`bench/`](bench) | the suite; the lessons; the benchmarks |

**A heavy lib file is pieces of one translation unit.** The head keeps the
tables, the macros and every declaration; a function calls only what an
earlier piece defined or the head declared. A new piece goes into
`cocolog.cicili`'s list and into each test binary's that emits the head, or
its functions are declared and never defined.

## 15. Build

```sh
export CICILI=/path/to/cicili              # a Cicili checkout, 3.3.0 or later
export ZIGURATIP=/path/to/ZiguratIP        # a BUILT ZiguratIP checkout
export ZIGURATIP_HOME=$ZIGURATIP/home
export CL_SOURCE_REGISTRY="$CICILI/:"      # the Cicili that ASDF loads
export PATH=$PWD/tools/cc:$PATH            # clang, through the wrappers
make                    # the client and the one binary, embedded store linked in
make EMBED=0            # the same binary with no ZiguratIP
make modules            # every module this box can build, and the flow tables
make schema             # the Parsi objects into $ZIGURATIP_HOME
make index              # cocolint's blocklist and retrieval index
make lint FILES=x.pl
make test               # the suite: ask the owner first
```

- **Everything is built by clang, in release mode.** Cicili names `gcc`, so
  `tools/cc` comes first on PATH and hands over to clang. Check an object, not
  the command: `readelf -p .comment .libs/cocolog.o` names clang.
- **`CICILI` does not choose the Cicili that runs; ASDF does.**
  `cicili.lisp` loads the first `cicili.asd` in ASDF's registry, and
  `~/common-lisp/cicili` usually answers first. Set `CL_SOURCE_REGISTRY` to
  the checkout meant, and ask before trusting a build:
  `cd "$CICILI" && sbcl --script cicili.lisp --version`.
- This tree needs Cicili 3.3.0 or later (`stat`'s file times; `(cold)`;
  `realpath`). An older one stops at `unknown member: st_mtim` or `unknown
  symbol: cold`.
- A missing ZiguratIP fails in Cicili with
  `FILE-DOES-NOT-EXIST … embed/mvccs-lib.cicili`. A test binary that links the
  engine takes about a hundred seconds to build.
- Cicili treats compiler chatter as fatal: an `Unhandled SIMPLE-ERROR` whose
  text is a warning is a warning to silence in the target's own `:compile`
  list.
- **After a new Cicili or a ZiguratIP change, rebuild in order**: ZiguratIP,
  then here `make clean && make`, `make schema`, `make modules`. A stale Parsi
  object takes the server down with `symbol lookup error`.
- On a Mac whose compiler is Homebrew's LLVM and whose binary needs Z3 through
  libCore, the build may need
  `DYLD_LIBRARY_PATH=/usr/local/Cellar/z3/5.1.0/lib
  CICILI_CC=/usr/local/opt/llvm/bin/clang
  CICILI_CXX=/usr/local/opt/llvm/bin/clang++ make`. `CLAUDE.md`'s macOS
  section has the rest.
- **Never commit build output**: `.o`, `.so`, the C that Cicili emits, the
  `sdk.cicili` and `zigheaders` links in `modules/*`. The test is to delete
  everything a `build.sh` makes and run it: what comes back was output.

## 16. The suite, and proving a change

`make test` is `./cocolog -s test/run.pl`: 77 lines, seven Cicili test
binaries (term, syntax, solve, module, state, zigurat, shared) and seventy
Prolog cases, each with its seconds.

```sh
./cocolog -s test/run.pl -- lint          # one case through the runner
./cocolog -s test/engine.pl               # a case alone, from the checkout root
./cocolog -s test/files.pl -- op_reduce   # one file of the swipl comparison
```

- **Ask the owner before the full suite, a gate, or a whole tutorial run.**
  Prove a change with narrow cases; say what was run and what was not.
- **The lint case first**, so a card citation that the edit moved is settled
  before a long run. **A red case that was fixed is rerun alone**, not with
  the suite.
- **`red: 0` is not a pass.** Database cases SKIP with no server, and others
  for a missing tool: `files` and `trace` want swipl 9.0.4, `ray` a screen,
  the tensor cases their libraries. Count the SKIPs, read their reasons, and
  run `pgrep ziguratip`.
- The suite loads `library/*.so` and does not build them: `make modules` after
  a pull.
- A server is raised detached, with its libraries on the path (`CLAUDE.md`,
  "Running a program"). A plain `nohup … &` from a tool call does not survive
  the turn.
- A case that passes alone proves the case; the suite proves the contract
  between cases.

**The method for a swipl-compatibility change**, which is most changes here:

1. Probe swipl 9.0.4 over the shapes, odd ones included. Its answers are the
   specification.
2. Write them as `test/files/NAME.pl`, a file both systems run.
3. Fix the engine. Extend a table rather than the code it generates.
4. **One rule, one arm**: for each rule of the fix, a build with that rule
   alone taken out must turn the case red. A guard whose arm stays green
   proves nothing, and is taken out or kept only for a measured cost.
5. Narrow cases, the lint case, the card check.
6. Count the cost (§18).
7. Write it down: a bullet in `CLAUDE.md` where the next session will trip, a
   row in `COMPAT.md` for what still differs, a section in `STATUS.md` with
   the numbers. Bump the version in the same commit (§19).

## 17. The engine: what must stay true

- **Flat cells, no pointers in terms.** A term is a cell index. The
  continuation is the term `'$k'(Goal, Barrier, Rest)`; choice points are
  integer frames. Freezing a machine is writing its arrays.
- **Dispatch is construct, C builtin, module, store, by name and arity.** A
  program file's clause for a builtin's name takes it over.
- **Add to the table, never to the generated code.** The tables emit several
  things that must not drift apart: `*builtins*`, `*operators*`,
  `*arith-names*`, `*functor-names*`, `*construct-names*`, `*error-contexts*`,
  `*frame-contexts*`, `*wt-options*`, `*coco-ct-classes*`.
- **A new C builtin wants four things**: its row; an `*error-contexts*` row,
  or its errors name nothing; a line in `library/flow/modes.pl`; and
  `make modules` and `make index` afterwards, so the flow tables and the
  linter's blocklist know it. A new library helper wants a `*frame-contexts*`
  row under swipl's name for it.
- **A builtin raises swipl's error through `coco_raise`**, catchably. What a
  `coco_m_*_error` returns is the predicate's ANSWER (2), not a status: pass
  it through, never test `not`.
- **Read text through `coco_tx_get`**, an integer through `coco-is-int` and
  `coco_int_val`, build one with `coco_new_int`. Compare floats with
  `coco_flt_eq`. Ask `coco_is_nil`, never `strcmp` with `"[]"`.
- **A cell index held across a step is a root** the collector must be told
  (`coco_heap_root_push`, `coco_store_root_push`). The store's compaction
  moves cells.
- **A new field of the machine is appended**, never inserted: a field in the
  middle moves every offset after it.
- **The step loop is measured, not reasoned about.** A branch, a call, a lock
  or a `defer` added to anything it reaches can move its registers. Slow paths
  go out of line (`(weak) (cold)`); count before and after (§18).
- **The logical update view**: a call sees the clauses that stood when it
  began. A reader of the clause list skips the dead; a writer of the counts
  calls `coco_pred_nprobe`.
- **A feature that touches the knowledge base must consider all three
  arrangements**: local (no hooks), Zigurat (all five), Zeytun (`fetch` and
  `warm` only).

`CLAUDE.md`'s section "The engine: what is not obvious" has one bullet for
each mechanism. **Grep it for the function's name before changing the
function**: each bullet is there because its fact has already cost a day.

### The store and the green world

- `library(async)` runs green tasks over **one shared store**, one worker a
  core, each task a machine of its own, preempted every 10 000 steps.
- A store write takes the **write barrier**: every other worker acknowledges
  at a safe point, the writer changes the store with no lock held, and the
  world goes on. Writes are dear and reads run in parallel. Every piece of
  metadata a first call makes — a predicate created, a clause compiled, an
  index built — is a write too.
- A blocking C call that touches no store declares itself
  (`coco_g_foreign_begin`/`_end`) and is not waited for; its return syncs with
  a write in flight. A call that touches the store must not declare itself.
- The name tables are shared across the machines of a world: an intern hit
  takes no lock, a miss takes the names mutex, and a growth publishes a new
  array and never frees the old one while the world lives.
- `findall/3`'s results and a caught ball live in **private per-engine
  stores**; their puts skip the barrier. Only a ball no catch takes is copied
  to the shared store.
- The nested engine behind `findall/3`, `forall/2` and `call_limited/3` cannot
  suspend its C search: a blocking call inside one waits in the builtin and
  runs the worker's ready tasks, and `yield` there is a no-op.
- No table reclamation and no store compaction runs while a world does.
- `run_isolated/2` gives a proof a fresh store; terms cross only as text,
  never as shared cell indices.

### A loadable module

- One directory under `modules/`: `NAME.cicili`, a `build.sh`, and a
  `binding.cicili` when it binds a library. `sh modules/NAME/build.sh` writes
  `library/NAME.so`, which git ignores.
- It imports **only** `lib/sdk.cicili`, never `lib/module.cicili` beside it,
  and holds the engine as an opaque pointer.
- A C++ module declares the SDK's prototypes with C linkage before
  `(coco-sdk)`. Do not wrap `(coco-sdk)` in `(extern-c …)`.
- A handle is an integer index into the module's own table. A library that
  makes text from wire bytes, or wire bytes from the program's text, crosses
  with `string_bytes/3`, never with `atom_codes/2`.
- A predicate that reaches the world says so (`coco_m_portal`), so that the
  journal can answer it in a replay.
- A `$`-prefixed name is quoted in a module's Prolog half.
- A new module gets its lesson, its row in `make modules`, and its header:
  the header is what `make index` reads. [`MODULES.md`](MODULES.md) is the
  reference.

## 18. Measuring

- `sh tools/flow/zero.sh OLD NEW` counts the untraced engine's instructions on
  naive reverse, queens and lookup, the jump padding apart. The two binaries
  must stand at paths of one length, in sibling directories.
- A start: `valgrind --tool=callgrind ./cocolog query true`. A function's own
  count is callgrind's.
- **A count is not a clock.** Count to find a cost, time to confirm it. This
  box drifts about 20 % between runs of one build: compare two builds in one
  round, alternating, and do not read a ratio under a tenth from ten rounds.
- A count is comparable within one engine, not across two versions of it.
- `statistics/2` is about the calling thread.

## 19. Editing rules

- **Read `CLAUDE.md` first.** Only this repository may be modified unless the
  owner says otherwise; `../cicili` and `../ZiguratIP` are the owner's.
- **Write Prolog in `.pl` and C in `.cicili`.** A module comes from a C or C++
  API declared in a binding and called as Cicili, never from C pasted into
  `(code "...")`.
- **The version moves with the change, in the same commit.** cocolog's is
  `coco_version_text` in `cocolog.cicili`, and README's closing line names it
  too: a patch for any change to the binary or to a library, a minor for
  something new reachable from a program, a major for a program that stops
  working. Read master's number first: two lines of work bump the same one.
- **A documentation-only commit bumps nothing** and says `cocolog stays X.Y.Z`
  in its message.
- **Commit or push only when the owner asks.** Push with
  `git push git@github.com:saman-pasha/cocolog.git master:master`.
- **GitHub's CI only when the owner asks.** `ci.yml` starts on every push to
  master, so a pushed commit's message carries `[skip ci]`; start no run by
  hand and watch none.
- Lint changed `.pl` files, run `sh tools/cocolint/tool.sh card --check` and
  `git diff --check` before a commit.
- **A red case is not a pass.** Rerun it alone; tell a missing optional
  dependency (SKIP) from a regression.
- **Wait for a background job by what it writes** (a `DONE` line in its log),
  never by `pgrep -f` of its script's name: the pattern matches the waiting
  shell's own command line, and the wait never ends.
- Never ask for an API key in chat, and never write one into a file: a key is
  read from the environment. A live run of the token benchmark wants the
  owner's go-ahead.

## 20. When something fails

**In a debug situation the flow tools MUST be used, and in this order:**

```sh
./cocolog -s tools/flow/chart.pl -- 'entry_predicate(+, -)' prog.pl out/name
./cocolog -s tools/flow/debug.pl -- 'entry_goal(...)' prog.pl out/name txt=true
```

- **The chart first, before the first run.** It names the misspelt call (and
  the predicate it probably meant), the argument free where the engine
  refuses one, the left recursion, the clause never tried and the clauses not
  together — with no input, no store and no run (§8).
- **The debug run before any edit made on a guess.** It says where the goal
  failed, clause by clause, down to the call that failed; read `BASE.txt`,
  not only the picture (§9). A first run that says `false at step N` is run
  again with `from=1 to=N`, so the whole run is recorded.
- **Do not debug by scattering `write/1` through the program, and do not
  bisect the clauses by hand before the flow tools have run.** They answer
  both cheaper and exactly.

| symptom | start here |
|---|---|
| a predicate is unknown | §2 and §4: is it in a module not loaded, absent on purpose, or a typo? A chart of the caller names the predicate it probably meant (§8) |
| a clause seems missing | the load's stderr (§3): a syntax error drops one clause and goes on |
| an answer differs from swipl's | `COMPAT.md`, then the case in `test/files/` that pins it |
| a goal fails and you do not know where | `tools/flow/debug.pl` with `txt=true` and the whole run recorded (§9) |
| a predicate's clauses are doubled, or some never run | one namespace (§2): `listing(Name/Arity)` shows both sets in the order tried |
| a thread or a pool cannot see the program | it was consulted: load it with `-s` or `use_module` (§6) |
| a green task hangs, or a write stalls | `lib/green.cicili`, `test/async.pl`, the barrier (§17) |
| nothing persists, or a second process sees nothing | `--local` is the default (§5); `-s` writes no clause |
| a slow suite, a `lock wait timeout` | the server's uptime, then `cocolog vacuum` (`CLAUDE.md`, "Hazards") |
| a module will not load or call | `MODULES.md`, the module's `binding.cicili`, `nm -D --defined-only` |
| a build stops with a warning's text | Cicili treats chatter as fatal: the target's `:compile` list (§15) |
| a build behaves like an older Cicili | `sbcl --script cicili.lisp --version`, then `CL_SOURCE_REGISTRY` (§15) |
| the linter's citation drifted | `sh tools/cocolint/tool.sh card --check`; correct the range in `traps.jsonl` |
| a chart calls a builtin unknown | its line in `library/flow/modes.pl`, then `sh tools/flow/build.sh` (§8) |
| a case is SKIP | its own first line says why; report it, do not call it green |

## 21. Before you call it done

For a program:

- [ ] Every predicate you defined has your own prefix; cocolint is clean.
- [ ] The load's stderr is empty of `ERROR` and `Warning`.
- [ ] Text is quoted for what it must be: `'atom'`, or the flag set for strings.
- [ ] It was run the way it will be run: `run` or `-s`, with the store it will
      have.
- [ ] A thread, a pool or a crew gets the program as a module.

For a change to cocolog:

- [ ] `CLAUDE.md` was grepped for the functions touched.
- [ ] The answer is swipl 9.0.4's, held by a `test/files/` case, or
      `COMPAT.md` says how it differs.
- [ ] Each rule has an arm that goes red.
- [ ] Narrow cases, the lint case, the card check; the cost counted.
- [ ] The version, the lesson for a new library, `CLAUDE.md`, `STATUS.md`.
- [ ] No build output in `git status`; nothing run that the owner must be
      asked for.

## Transpiling Python to cocolog

Most models know Python best. Translate the **shape** of the Python
program into relations: a function with a return value becomes a
predicate with an extra output argument, a loop becomes a recursive
predicate with an accumulator, and a mutable variable becomes an
argument passed to the next call. Do not transliterate `print`, `return`
or assignment.

| Python | cocolog |
|---|---|
| `def f(a, b): ... return r` | `f(A, B, R) :- ...` |
| `x = 1` | `X = 1` (bind once) |
| `x += 1` | `X1 is X + 1` |
| `if c: a else: b` | `( C -> A ; B )` or clause guards |
| `for x in xs:` | a recursive predicate over `[X|Xs]` |
| `while stack:` | `loop(Stack, ...)` with `[X|Rest]` |
| `return` early | cut or if-then-else |
| `a == b` (numbers) | `A =:= B` |
| `a == b` (atoms) | `A == B` or `A = B` |
| `lst.append(x)` | `append(Lst, [X], New)` or an accumulator |
| `len(lst)` | `length(Lst, N)` |
| `set()` | a sorted list and `memberchk/2` |
| `dict` | an association list or `library(assoc)` |
| `print(x)` | `format("~w~n", [X])` |
| `input()` / `sys.stdin` | `read_line_to_codes(user_input, Codes)` |
| `s.split()` | `split_string(S, " ", " \t\r", Parts)` |
| `int(s)` | `number_codes(N, S)` |
| `range(n)` | `between(0, N1, I)` |
| `[f(x) for x in xs]` | `findall(Y, (member(X, Xs), f(X, Y)), Ys)` |
| `sorted(xs)` | `sort(Xs, Sorted)` or `msort` |
| `try/except` | `catch(Goal, Ball, Handler)` |

Use `_` for a value you do not use. A **singleton variable** (a named
variable used once) is a warning, and a warning on stderr fails the
benchmark's exact policy even when the output is right: name it `_` or
use it. A predicate name a loaded library already defines is silently
ignored (`digits/3` in `library(stream)`); prefix your own helpers.

### Worked example: BFS from Python

Python:

```python
import sys
data = sys.stdin.read().split()
it = iter(data)
n = int(next(it)); m = int(next(it))
adj = [[] for _ in range(n + 1)]
for _ in range(m):
    u = int(next(it)); v = int(next(it))
    adj[u].append(v)
s = int(next(it))
seen = {s}
stack = [s]
while stack:
    u = stack.pop()
    for v in adj[u]:
        if v not in seen:
            seen.add(v)
            stack.append(v)
print(" ".join(str(i) for i in range(1, n + 1) if i in seen))
```

cocolog, with the same shape: the stack is a list, the seen set is a
list with `memberchk/2`, the loop is `closure/4`, and every named
variable is used (the header's n is `_` because the edges carry the
nodes).

```prolog
:- use_module(library(stream)).

main :-
    read_line_to_codes(user_input, L0),
    ( L0 == end_of_file -> L = [] ; L = L0 ),
    split_string(L, " ", " \t\r", [_, MS]),
    number_codes(M, MS),
    read_edges(M, Edges),
    read_line_to_codes(user_input, S0),
    ( S0 == end_of_file -> S = [] ; S = S0 ),
    split_string(S, " ", " \t\r", [SS]),
    number_codes(Start, SS),
    reach(Start, Edges, Seen),
    sort(Seen, Sorted),
    write_nodes(Sorted).

read_edges(0, []) :- !.
read_edges(K, [U-V|Rest]) :-
    read_line_to_codes(user_input, L0),
    ( L0 == end_of_file -> L = [] ; L = L0 ),
    split_string(L, " ", " \t\r", [US, VS]),
    number_codes(U, US),
    number_codes(V, VS),
    K1 is K - 1,
    read_edges(K1, Rest).

reach(Start, Edges, Seen) :-
    closure([Start], Edges, [Start], Seen).

closure([], _, Seen, Seen).
closure([X|Xs], Edges, Seen, Reach) :-
    findall(V, (member(U-V, Edges), U =:= X, \+ memberchk(V, Seen)), New0),
    sort(New0, New),
    append(Xs, New, Queue),
    append(Seen, New, Seen1),
    closure(Queue, Edges, Seen1, Reach).

write_nodes([X]) :- !,
    format("~w~n", [X]).
write_nodes([X|Xs]) :-
    format("~w ", [X]),
    write_nodes(Xs).
```

## Codes, parsers and tables

This file is the reasoning repository's copy of the cocolog skill; the
benchmark's cocolog lane reads it. The notes below are its additions.

### A character is not a number

`atom_chars/2` gives one-character atoms; to compare or subtract one,
take its code with `char_code/2`, or keep the character codes that
`read_line_to_codes/2` returns. Write a character code as `0'` and the
character itself: `0'(` is the code of `(`, `0')` of `)`, `0'0` of `0`.
The token ends at the character; never add a quote after it. `0'0` is
the number 48; `'0'` is an atom and not a number.

### A parser over a list of codes

A parser over codes works on non-empty list patterns: `[C|Cs]` binds
`C`, and only then compare it (`C =:= 0'+`). A spaces predicate has
three clauses: skip the whitespace with a cut; `skip_spaces([], []).`
for the end; and `skip_spaces(List, List) :- List = [_|_].` for a
non-space code, so a non-space is returned unchanged (never
`skip_spaces(Rest, Rest).`, which also matches an unbound list).

A parenthesized atom binds `C` and its tail `Cs`, compares the open
with `C =:= 0'(`, recurses on the tail `Cs` (not on the list that still
begins with the open paren, or the parser loops), and after the inner
expression and the spaces compares the close with `C2 =:= 0')`, as two
separate comparisons.

The digit collector ends with `parse_digits(Rest, [], Rest).` and no
`Rest = []` guard: the remaining codes may be a non-empty suffix.
`number_codes/2` takes the list of digit codes and gives the number; it
has no third argument, so collect the digit codes and the remaining
codes yourself. `library(stream)` already defines `digits/3`, and a
`digits/3` of your own is ignored: name the collector `parse_digits/3`.

### A table built one row at a time

A table built one row at a time returns the row it just built: the
clause for a non-empty prefix computes the previous row, computes the
new row from that row and the next character, and returns the new row.
Do not call the row builder again on the same prefix after building the
row; that returns an earlier row and discards the new one.

A worked row table for the longest common subsequence:

```prolog
main :-
    read_line_to_codes(user_input, A0),
    read_line_to_codes(user_input, B0),
    ( A0 == end_of_file -> A = [] ; A = A0 ),
    ( B0 == end_of_file -> B = [] ; B = B0 ),
    length(B, M),
    M1 is M + 1,
    zeros(M1, Row0),
    lcs_rows(A, B, Row0, Row),
    last(Row, N),
    format("~w~n", [N]).

zeros(0, []) :- !.
zeros(N, [0|Zs]) :-
    N1 is N - 1,
    zeros(N1, Zs).

lcs_rows([], _, Row, Row).
lcs_rows([C|Cs], B, Prev, Final) :-
    lcs_row(C, B, Prev, Row),
    lcs_rows(Cs, B, Row, Final).

lcs_row(_, [], _, [0]).
lcs_row(C, [D|Ds], [Diag,Above|Aboves], [0|Cells]) :-
    lcs_cells(C, [D|Ds], [Diag,Above|Aboves], 0, Cells).

lcs_cells(_, [], _, _, []).
lcs_cells(C, [D|Ds], [Diag,Above|Aboves], Left, [V|Vs]) :-
    ( C =:= D -> V is Diag + 1 ; V is max(Above, Left) ),
    lcs_cells(C, Ds, [Above|Aboves], V, Vs).
```
