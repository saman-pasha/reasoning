%% coding/bench/v2/lang_gen.pl -- one language generator call for v2 Phase 4.
%%
%%     cocolog query "use_module('coding/bench/v2/lang_gen.pl'), run" -- \
%%         --lang LANG --spec SPEC_FILE --out OUT_FILE --effort none|high \
%%         --prev PREV_FILE|- --diag DIAG_FILE|-
%%
%% The parent runs this as a child. LANG is c, python, cocolog or swipl.
%% It writes the source to OUT_FILE and prints:
%%
%%     USAGE Prompt Completion Total Reasoning CacheHit
%%
%% The C, Python and cocolog paths use each language's normal generator,
%% so its normal guide and obligations are part of the experiment. SWI has
%% no generator in this tree; its path is a direct model call with a short
%% SWI-Prolog system prompt.

:- use_module(library(llm)).
:- use_module('coding/bench/v2/config.pl').

run :-
    current_prolog_flag(argv, [_|Args]),
    v2_lang_gen_args(Args, LangAtom, SpecFile, OutFile, EffortAtom,
                     PrevFile, DiagFile),
    atom_string(Lang, LangAtom),
    read_file_to_codes(SpecFile, SpecCodes),
    atom_codes(Spec0, SpecCodes),
    v2_lang_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options),
    v2_lang_code(Lang, Spec, Options, Code),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(OutFile, Codes),
    v2_lang_gen_usage.

%% Named flags: the parent builds them, and a swapped pair cannot hand the
%% child a file name where it expects a language.
v2_lang_gen_args(Args, Lang, Spec, Out, Effort, Prev, Diag) :-
    v2_lang_gen_flags(Args, Pairs),
    memberchk(lang-Lang, Pairs),
    memberchk(spec-Spec, Pairs),
    memberchk(out-Out, Pairs),
    memberchk(effort-Effort, Pairs),
    memberchk(prev-Prev, Pairs),
    memberchk(diag-Diag, Pairs).

v2_lang_gen_flags([], []).
v2_lang_gen_flags([Flag, Value|Rest], [Name-Value|Pairs]) :-
    atom_concat('--', Name, Flag),
    v2_lang_gen_flags(Rest, Pairs).

v2_lang_gen_spec(EffortAtom, Spec0, PrevFile, DiagFile, Spec, Options) :-
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
               '~s~n~nYour previous program failed verification.~nCompiler and test report:~n~s~nThe previous program was:~n~s~nWrite a corrected complete program. Output only the code.',
               [Spec0, Diag, Prev])
    ).

v2_lang_code(c, Spec, Options, Code) :-
    use_module('coding/c/codegen.pl'),
    codegen_c(Spec, Options, Code).
v2_lang_code(python, Spec, Options, Code) :-
    use_module('coding/python/codegen.pl'),
    codegen_python(Spec, Options, Code).
v2_lang_code(cocolog, Spec, Options, Code) :-
    use_module('coding/cocolog/codegen.pl'),
    v2_lang_cocolog_guide(GuideFile),
    call_cleanup(
        v2_lang_with_env('COCOLOG_SKILL', GuideFile,
                         codegen_cocolog(Spec, main, Options, Code)),
        catch(delete_file(GuideFile), _, true)).
v2_lang_code(swipl, Spec, Options, Code) :-
    v2_lang_swipl_code(Spec, Options, Code).

%% The cocolog guide is the language's own, with one benchmark line: the
%% published language run showed the model treating one-character atoms
%% as numbers and repeating the error through every repair. The line is
%% appended to the guide the generator reads, and the environment is put
%% back whatever the call does.
v2_lang_cocolog_guide(File) :-
    use_module('coding/cocolog/codegen.pl'),
    cocolog_skill_text(Base),
    v2_lang_cocolog_hint(Hint),
    format(atom(Text), '~s~n~n~s', [Base, Hint]),
    tmp_file(v2_lang_cocolog_guide, File),
    atom_codes(Text, Codes0),
    append(Codes0, [10], Codes),
    write_file_from_codes(File, Codes).

v2_lang_cocolog_hint(Hint) :-
    atomic_list_concat(
        [ 'A character is not a number. atom_chars/2 gives one-character atoms; to compare or subtract one, take its code with char_code/2, or keep the character codes that read_line_to_codes/2 returns. Write a character code as 0'' and the character itself: 0''( is the code of (, 0'') of ), 0''0 of 0. The token ends at the character; never add a quote after it. 0''0 is the number 48; ''0'' is an atom and not a number.',
          'A parser over codes works on non-empty list patterns: [C|Cs] binds C, and only then compare it (C =:= 0''+). A spaces predicate has three clauses: skip the whitespace with a cut; skip_spaces([], []). for the end; and skip_spaces(List, List) :- List = [_|_]. for a non-space code, so a non-space is returned unchanged (never skip_spaces(Rest, Rest)., which also matches an unbound list). A parenthesized atom binds C and its tail Cs, compares the open with C =:= 0''(, recurses on the tail Cs (not on the list that still begins with the open paren, or the parser loops), and after the inner expression and the spaces compares the close with C2 =:= 0''), as two separate comparisons. The digit collector ends with parse_digits(Rest, [], Rest). and no Rest = [] guard: the remaining codes may be a non-empty suffix. number_codes/2 takes the list of digit codes and gives the number; it has no third argument, so collect the digit codes and the remaining codes yourself. library(stream) already defines digits/3, and a digits/3 of your own is ignored: name the collector parse_digits/3.'
        ],
        '\n\n', Hint).

v2_lang_with_env(Name, Value, Goal) :-
    (   getenv(Name, Old),
        Old \== ''
    ->  Had = yes(Old)
    ;   Had = none
    ),
    setenv(Name, Value),
    call_cleanup(Goal, v2_lang_restore_env(Name, Had)).

v2_lang_restore_env(Name, yes(Old)) :-
    !,
    atom_string(Value, Old),
    setenv(Name, Value).
v2_lang_restore_env(Name, none) :-
    unsetenv(Name).

v2_lang_swipl_code(Spec, Options, Code) :-
    memberchk(provider(Provider), Options),
    memberchk(base_url(BaseUrl), Options),
    retractall(llm_provider(Provider, _, _)),
    assertz(llm_provider(Provider, BaseUrl, 'CODING_ENDPOINT_KEY_ENV')),
    System = 'You are a SWI-Prolog programmer. Write a complete SWI-Prolog program with main/0 that reads standard input and writes standard output. Output only the source, with no Markdown fences and no explanation.',
    llm_chat([msg(system, System), msg(user, Spec)], Options, Reply),
    v2_lang_strip_fence(Reply, Code).

%% A reply is the code, with any Markdown fence taken off: leading and
%% trailing blank space goes, an opening line that begins with ``` and
%% the closing line that is ``` alone go. A closing fence that ends
%% anything but a line of its own is left alone, since it may be the last
%% three characters of a quoted string.
v2_lang_strip_fence(Reply, Code) :-
    v2_lang_trim_atom(Reply, Trimmed),
    (   sub_atom(Trimmed, 0, 3, _, '```')
    ->  v2_lang_drop_fence_line(Trimmed, Body0),
        v2_lang_trim_atom(Body0, Body),
        v2_lang_drop_closing_fence(Body, Inner),
        v2_lang_trim_atom(Inner, Code)
    ;   Code = Trimmed
    ).

v2_lang_drop_fence_line(Text, Rest) :-
    (   sub_atom(Text, P, 1, _, '\n')
    ->  Start is P + 1,
        sub_atom(Text, Start, _, 0, Rest)
    ;   Rest = ''
    ).

v2_lang_drop_closing_fence(Text, Inner) :-
    atom_length(Text, Len),
    (   Len >= 3,
        Start is Len - 3,
        sub_atom(Text, Start, 3, 0, '```'),
        (   Start =:= 0
        ->  Inner = ''
        ;   Prev is Start - 1,
            sub_atom(Text, Prev, 1, _, '\n')
        ->  End is Start - 1,
            sub_atom(Text, 0, End, _, Inner)
        ;   Inner = Text
        )
    ;   Inner = Text
    ).

v2_lang_trim_atom(Text, Code) :-
    atom_string(Text, String),
    split_string(String, "", " \t\r\n", [Core|_]),
    atom_string(Code, Core).

v2_lang_gen_usage :-
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
