%% reasoning test/version.pl -- the version a commit moves, and nothing else.
%%
%%     cocolog -s test/version.pl                    from this repository's root
%%
%% CLAUDE.md's rule under "The version" is a rule about HISTORY: a commit
%% that changes the code, corpus/, lexicon/, generated/ or model.rows moves
%% reason_version/3, and a documentation-only commit does not. A case cannot
%% see a commit, so this holds the half it can:
%%
%%   -- the fact       reason.pl has ONE reason_version/3, answering once,
%%                     and reason_version/1 joins it with dots
%%   -- the spelling   X.Y.Z, each an integer, none negative, not 0.0.0
%%   -- the history    in a git checkout, an UNCOMMITTED change to reason.pl
%%                     with the version still at HEAD's is a failure: the
%%                     version that has to move was not moved
%%
%% A tarball has no HEAD, so the history section says SKIP there, not red.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).

main :-
    section('the fact'),
    version_shape,
    section('the history'),
    version_history,
    checks_done.

version_shape :-
    findall(Ma-Mi-Pa, reason_version(Ma, Mi, Pa), Triples),
    (   Triples = [Ma-Mi-Pa],
        integer(Ma), integer(Mi), integer(Pa)
    ->  check('one reason_version/3 fact, answering once', yes, yes)
    ;   check('one reason_version/3 fact, answering once', Triples, '[X-Y-Z]')
    ),
    findall(V, reason_version(V), Vs),
    (   Vs = [V], atom(V)
    ->  check('reason_version/1 answers once, an atom', yes, yes)
    ;   check('reason_version/1 answers once, an atom', Vs, "[X.Y.Z]")
    ),
    (   atomic_list_concat([Ma, Mi, Pa], '.', Joined)
    ->  check('and joins the three integers with dots', V, Joined)
    ;   check('and joins the three integers with dots', V, 'the integers in dots')
    ),
    (   forall(member(N, [Ma, Mi, Pa]), ( integer(N), N >= 0 ))
    ->  check('each is an integer, none negative', yes, yes)
    ;   check('each is an integer, none negative', [Ma, Mi, Pa], 'integers >= 0')
    ),
    (   Ma + Mi + Pa > 0
    ->  check('not 0.0.0: a version nobody has moved', yes, yes)
    ;   check('not 0.0.0: a version nobody has moved', V, 'a number past 0.0.0')
    ).

version_history :-
    (   exists_directory('.git')
    ->  version_compare_head
    ;   skip('version: no .git here, so no HEAD to compare against')
    ).

%% An uncommitted reason.pl keeps the version HEAD committed: the change
%% that must move the number has not. An unread HEAD is no comparison.
version_compare_head :-
    (   version_head_value(HeadVersion)
    ->  reason_version(WorkingVersion),
        version_reason_dirty(Dirty),
        (   Dirty == yes,
            WorkingVersion == HeadVersion
        ->  check('reason.pl is changed and the version is HEAD\'s: move it',
                  WorkingVersion, 'a number past HEAD\'s')
        ;   check('the working tree takes no version the number has not moved for',
                  yes, yes)
        )
    ;   skip('version: HEAD has no reason_version/3 to compare against')
    ).

%% HEAD's reason.pl, and only its version line: the whole file is 100 KB of
%% text a term reader should not be asked to swallow.
version_head_value(Version) :-
    shell("git show HEAD:reason.pl | grep -m1 '^reason_version(1, '", Line, 0),
    Line \== '',
    catch(read_term_from_atom(Line, reason_version(A, B, C), []), _, fail),
    atomic_list_concat([A, B, C], '.', Version).

version_reason_dirty(yes) :-
    shell('git diff --quiet HEAD -- reason.pl', _, Exit),
    Exit \== 0,
    !.
version_reason_dirty(no).
