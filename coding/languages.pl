%% coding/languages.pl -- the languages the coding endpoint exposes.
%%
%%     codegen_language(+Base, -Language)
%%         Base is what is left of an OpenCode model name once a `-rN'
%%         suffix is taken off: c, cocolog, python. Language is
%%         `language(Name, Guide, Obligations, Checks, Example)':
%%
%%         Name        the alias, as the word a trace records: c,
%%                     cocolog, python
%%         Guide       how the language's system prompt is made
%%         Obligations the reader that turns a request into checks
%%         Checks      the general checks that fill a short reading
%%         Example     the program a dry run shows
%%
%%     codegen_language_models(-Names)
%%         the OpenCode model names: every base, and its -r0, -r2 and -r8
%%         variants. The endpoint serves exactly these.
%%
%%     codegen_language_label(+Name, -Label)
%%         the name OpenCode lists in /v1/models.
%%
%%     codegen_language_backend_env(+Base, -Variable)
%%         the environment variable that names the backend model for Base,
%%         so a Python session can be sent to another model than a C one.
%%
%%     codegen_python_obligations(+Spec, -Obligations)
%%         the keyword reading for Python: `coding/obligations.pl' is the
%%         C reading and keeps its name there.
%%
%%     codegen_language_check_key(+Base, -Trigger, -Needle)
%%         a substring a reply SHOWS tests by, and one it RUNS tests by.
%%         A request that names tests and a reply that shows a test without
%%         running one is the failure these exist to catch.
%%
%% THE LANGUAGES ARE ONE TABLE, because three things read a language and
%% used to agree only by hand: the endpoint's alias list, its `-rN'
%% bookkeeping and its guide lookup. A language added here is served,
%% listed and guided; a language left out is refused by `ep_alias/2'
%% rather than answered with the C guide.
%%
%% THE C AND COCOLOG CHECKS ARE THE ONES THAT WERE MEASURED, unchanged: the
%% tables in `coding/bench/README.md' were recorded under them, and a
%% general check that moved would move the reading of every request already
%% measured. Python's are its own -- an unbound name, an import the
%% environment does not have, a test that was not run -- because the checks
%% a C task is filled with do not describe a Python module.

:- use_module(library(os)).
:- use_module('coding/obligations.pl').
:- use_module('coding/python/obligations.pl').

%% ---- the table ---------------------------------------------------------

codegen_languages([c, cocolog, python]).

codegen_language(c,
                 language(c,
                          guide(file('coding/endpoint/prompts/c.md')),
                          obligations(codegen_obligations),
                          checks(codegen_c_general_checks),
                          example(c_example))).
codegen_language(cocolog,
                 language(cocolog,
                          guide(skill),
                          obligations(codegen_obligations),
                          checks(codegen_c_general_checks),
                          example(none))).
codegen_language(python,
                 language(python,
                          guide(file('coding/endpoint/prompts/python.md')),
                          obligations(codegen_python_obligations),
                          checks(codegen_python_general_checks),
                          example(python_example))).

codegen_language_models(Names) :-
    codegen_languages(Bases),
    findall(Name,
            (   member(Base, Bases),
                codegen_language_name(Base, Name)
            ),
            Names).

codegen_language_name(Base, Name) :-
    (   Name = Base
    ;   format(atom(Name), '~w-r0', [Base])
    ;   format(atom(Name), '~w-r2', [Base])
    ;   format(atom(Name), '~w-r8', [Base])
    ).

codegen_language_label(c, 'C (C99-C23)').
codegen_language_label(cocolog, cocolog).
codegen_language_label(python, 'Python 3').
codegen_language_label(Name, Label) :-
    codegen_language_suffix(Name, Base, N),
    codegen_language_label(Base, Plain),
    codegen_language_prose(N, Prose),
    format(atom(Label), '~w (r~w: ~w)', [Plain, N, Prose]).

%% `python-r8' -> python, 8. A base with a hyphen in it (`r' is not one
%% today) would still be read right to left, the suffix first.
codegen_language_suffix(Name, Base, N) :-
    atom(Name),
    atom_string(Name, String),
    split_string(String, "-", "", Parts),
    reverse(Parts, [LastString|Rest]),
    atom_string(Last, LastString),
    atom_concat('r', Digits, Last),
    atom_number(Digits, N),
    integer(N),
    Rest \== [],
    atomic_list_concat(Rest, '-', Base0),
    atom_string(Base, Base0),
    codegen_languages(Bases),
    memberchk(Base, Bases).

codegen_language_prose(0, 'plain').
codegen_language_prose(2, 'two checks').
codegen_language_prose(8, 'eight checks').
codegen_language_prose(N, Prose) :-
    \+(memberchk(N, [0, 2, 8])),
    format(atom(Prose), '~w checks', [N]).

codegen_language_base(Base) :-
    codegen_languages(Bases),
    memberchk(Base, Bases).

%% ---- the backend model of one language ---------------------------------

codegen_language_backend_env(c, 'CODING_ENDPOINT_C_MODEL').
codegen_language_backend_env(cocolog, 'CODING_ENDPOINT_COCOLOG_MODEL').
codegen_language_backend_env(python, 'CODING_ENDPOINT_PYTHON_MODEL').

%% ---- the checks a reading gives ----------------------------------------

codegen_language_obligations(Language, Spec, Obligations) :-
    Language = language(_, _, obligations(Reader), _, _),
    Goal =.. [Reader, Spec, Obligations0],
    (   catch(call(Goal), _, fail)
    ->  Obligations = Obligations0
    ;   Obligations = []
    ).

%% ---- the general checks ------------------------------------------------

codegen_general_check(c, 'Read the input exactly as the task describes; do not assume more input than it gives.').
codegen_general_check(c, 'Write exactly the required result; do not print a prompt, label or debugging text.').
codegen_general_check(c, 'Compile and run the program before you say the task is done.').
codegen_general_check(c, 'Handle empty input, end of file and malformed input without crashing.').
codegen_general_check(c, 'Check every allocation, bound, index and null before it is used.').
codegen_general_check(c, 'Keep the result deterministic; no timestamps, random values or environment-dependent output.').
codegen_general_check(c, 'Remove debugging output from the final program.').
codegen_general_check(c, 'Run the task''s own example and compare its exact output before you say it is done.').

codegen_general_check(cocolog, Check) :-
    codegen_general_check(c, Check).

codegen_general_check(python, 'Read the input exactly as the task describes; do not assume more input than it gives.').
codegen_general_check(python, 'Write exactly the required result; no prompt, label, debug print or extra line.').
codegen_general_check(python, 'Give every name you read or return a value on every path; a missing value is a defined error, not an unbound name.').
codegen_general_check(python, 'Run the program or the tests before you say the task is done: `python3 FILE` or `python3 -m pytest`, from the directory the user named.').
codegen_general_check(python, 'Handle empty input, end of file and malformed input with a defined answer, not a traceback.').
codegen_general_check(python, 'Keep the result deterministic: no clock, no set or dict order over hash-randomised keys, no unseeded `random`.').
codegen_general_check(python, 'A test that was not run is not a test that passed; run the tests you wrote and read their output.').
codegen_general_check(python, 'Import only the standard library, or a package the environment has; check before you import it.').

codegen_c_general_checks(Checks) :-
    findall(Check, codegen_general_check(c, Check), Checks).

codegen_python_general_checks(Checks) :-
    findall(Check, codegen_general_check(python, Check), Checks).

codegen_language_checks(Language, Checks) :-
    Language = language(_, _, _, checks(Reader), _),
    Goal =.. [Reader, Checks],
    call(Goal).

%% ---- what a reply must show to be believed -----------------------------
%%
%% A request that names tests, and a reply that shows one without running
%% any, is the failure these exist to catch: a test file pytest cannot
%% collect passes nothing, and a module that does not parse fails on
%% import. Each key is a substring the reply SHOWS a test by and one it
%% RUNS tests by. Only Python is judged this way; a C task's cases are
%% the benchmark's.

codegen_language_check_key(python, 'def test_', 'pytest').
codegen_language_check_key(python, 'class Test', 'pytest').
codegen_language_check_key(python, 'assert ', 'pytest').
codegen_language_check_key(python, 'assert ', 'unittest').
codegen_language_check_key(python, 'import unittest', 'unittest').

%% A request that asks for tests at all, as the keyword reader sees it.
codegen_request_tests_cue(Text) :-
    downcase_atom(Text, Low),
    atom_string(Low, String),
    split_string(String, " \t\n\r.,;:!?()[]{}\"'", "", Parts0),
    exclude(codegen_language_empty_string, Parts0, Parts),
    member(Word, [test, tests, pytest, unittest]),
    memberchk(Word, Parts).

codegen_language_empty_string(S) :-
    string_length(S, 0).
