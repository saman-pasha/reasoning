%% coding/bench/v2/lang_gen.pl -- one language generator call for v2 Phase 4.
%%
%%     cocolog query "use_module('coding/bench/v2/lang_gen.pl'), run" -- \
%%         --lang LANG --spec SPEC_FILE --out OUT_FILE --effort none|high \
%%         --prev PREV_FILE|- --diag DIAG_FILE|-
%%
%% The parent runs this as a child. LANG is c, python, cocolog, swipl or
%% cocolog_noguide. It writes the source to OUT_FILE and prints:
%%
%%     USAGE Prompt Completion Total Reasoning CacheHit
%%
%% The C, Python and cocolog paths use each language's normal generator,
%% so its normal guide and obligations are part of the experiment. SWI has
%% no generator in this tree; its path is a direct model call with a short
%% SWI-Prolog system prompt. cocolog_noguide is the cocolog generator with
%% its short --no-skill system prompt in place of the guide.

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
    v2_lang_code_replied(Lang, Spec, Options, 1, Code, Usages),
    atom_concat(Code, '\n', Text),
    atom_codes(Text, Codes),
    write_file_from_codes(OutFile, Codes),
    v2_lang_gen_usage(Usages).

%% A REPLY WITH NO TEXT IS SENT AGAIN, ONCE, AND COUNTED (reasoning 1.15.1).
%% In the runs of 2026-11-20 and 21, claude-sonnet-5-5 answered three
%% repair attempts of some 400 calls with no text: a refusal by its safety
%% classifier, stop_reason `refusal', category `reasoning_extraction'
%% ("reverse engineering or duplicating model outputs" -- a repair prompt
%% sends the model its own previous program), with an empty content, or,
%% twice in the SWI-Prolog lane, a thinking block and no text, the shape a
%% refusal after the thinking began leaves. library(llm) raises
%% llm_error(no_reply, Json) for each, and through 1.15.0 the attempt was a
%% generator failure that counted none of its tokens: the child stopped
%% before it printed USAGE. The same two SWI requests, sent again, were
%% answered with text (end_turn), and server-side fallback does not retry
%% this category on this model. So a reply with no text is sent again,
%% once: with twice the token limit (at most 32000) where it stopped at
%% max_tokens, else as it was. Each such reply prints an `EMPTY' line with
%% its stop reason, category and blocks, which the parent counts in the
%% row (empty_replies); its tokens are in USAGE; and a second one is the
%% generator's failure, its tokens counted too.
v2_lang_code_replied(Lang, Spec, Options, Try, Code, [Usage|Usages]) :-
    catch(( v2_lang_code(Lang, Spec, Options, Code0), Empty = none ),
          error(llm_error(no_reply, Json), _),
          Empty = Json),
    (   Empty == none
    ->  Code = Code0,
        (   llm_last_usage(Usage)
        ->  true
        ;   Usage = none
        ),
        Usages = []
    ;   v2_lang_reply_usage(Empty, Usage),
        v2_lang_empty_reason(Empty, Reason),
        format("EMPTY ~w~n", [Reason]),
        (   Try < 2
        ->  Try1 is Try + 1,
            v2_lang_retry_options(Empty, Options, Options1),
            v2_lang_code_replied(Lang, Spec, Options1, Try1, Code, Usages)
        ;   v2_lang_gen_usage([Usage]),
            format(atom(Msg), 'two replies with no text; the last: ~w', [Reason]),
            throw(error(v2_lang_error(empty_reply, Msg), v2_lang_code_replied/6))
        )
    ).

%% A reply that stopped at its token limit is sent with twice the limit, at
%% most 32000; any other is sent as it was.
v2_lang_retry_options(json(Pairs), Options0, Options) :-
    (   memberchk(stop_reason-max_tokens, Pairs),
        memberchk(max_tokens(N0), Options0)
    ->  N is min(32000, 2 * N0),
        selectchk(max_tokens(N0), Options0, Options1),
        Options = [max_tokens(N)|Options1]
    ;   Options = Options0
    ).

v2_lang_reply_usage(json(Pairs), Usage) :-
    (   memberchk(usage-Usage, Pairs)
    ->  true
    ;   Usage = none
    ).

%% The stop reason and the kinds of block an empty reply held: Anthropic's
%% stop_reason and content, or OpenAI's finish_reason.
v2_lang_empty_reason(json(Pairs), Reason) :-
    (   memberchk(stop_reason-SR, Pairs)
    ->  (   memberchk(content-Content, Pairs), is_list(Content)
        ->  findall(T, ( member(json(B), Content), memberchk(type-T, B) ), Ts)
        ;   Ts = []
        ),
        atomic_list_concat(Ts, '+', Blocks0),
        (   Blocks0 == '' -> Blocks = none ; Blocks = Blocks0 ),
        (   memberchk(stop_details-json(Details), Pairs),
            memberchk(category-Category, Details),
            atom(Category)
        ->  true
        ;   Category = none
        ),
        format(atom(Reason), 'stop_reason=~w category=~w blocks=~w',
               [SR, Category, Blocks])
    ;   memberchk(choices-[json(Choice)|_], Pairs),
        memberchk(finish_reason-FR, Choice)
    ->  format(atom(Reason), 'finish_reason=~w', [FR])
    ;   Reason = 'no stop reason'
    ).

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
    v2_setting(provider, Provider),
    v2_setting(model, Model),
    v2_setting(base_url, BaseUrl),
    v2_setting(temperature, Temperature),
    v2_setting(max_tokens, MaxTokens),
    (   EffortAtom == high
    ->  v2_config(high_effort, Effort)
    ;   v2_setting(effort, Effort)
    ),
    Options0 = [provider(Provider),
                model(Model),
                base_url(BaseUrl),
                reasoning_effort(Effort)],
    (   Temperature == none
    ->  Options1 = Options0
    ;   Options1 = [temperature(Temperature)|Options0]
    ),
    (   MaxTokens == none
    ->  Options = Options1
    ;   Options = [max_tokens(MaxTokens)|Options1]
    ),
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
    codegen_cocolog(Spec, main, Options, Code).
v2_lang_code(swipl, Spec, Options, Code) :-
    v2_lang_swipl_code(Spec, Options, Code).
v2_lang_code(cocolog_noguide, Spec, Options, Code) :-
    use_module('coding/cocolog/codegen.pl'),
    codegen_cocolog_bare(Spec, main, Options, Code).

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

%% The usage of the one call: OpenAI's fields, or Anthropic's --
%% input_tokens and output_tokens, the thinking within the output and
%% reported nowhere apart. input_tokens is only what was read past the
%% cache, so the prompt is it with cache_read_input_tokens (the hit) and
%% cache_creation_input_tokens. Read only the OpenAI way, an Anthropic
%% reply failed the child after its program was written.
%% One USAGE line, the sum of the calls' usages (one call, or the calls of
%% an empty reply and the call that answered it).
v2_lang_gen_usage(Usages) :-
    foldl(v2_lang_usage_add, Usages, u(0, 0, 0, 0, 0), u(P, C, T, R, H)),
    format("USAGE ~w ~w ~w ~w ~w~n", [P, C, T, R, H]).

v2_lang_usage_add(Usage, u(P0, C0, T0, R0, H0), u(P, C, T, R, H)) :-
    v2_lang_usage_parts(Usage, P1, C1, T1, R1, H1),
    P is P0 + P1, C is C0 + C1, T is T0 + T1, R is R0 + R1, H is H0 + H1.

%% A provider's usage as prompt, completion, total, reasoning and cache
%% hit: Anthropic's input_tokens and its cache fields, or OpenAI's.
v2_lang_usage_parts(json(Pairs), P, C, T, 0, H) :-
    memberchk(input_tokens-In, Pairs),
    !,
    (   memberchk(output_tokens-C, Pairs) -> true ; C = 0 ),
    v2_lang_usage_int(cache_read_input_tokens, Pairs, H),
    v2_lang_usage_int(cache_creation_input_tokens, Pairs, W),
    P is In + H + W,
    T is P + C.
v2_lang_usage_parts(json(Pairs), P, C, T, R, H) :-
    memberchk(prompt_tokens-P, Pairs),
    memberchk(completion_tokens-C, Pairs),
    memberchk(total_tokens-T, Pairs),
    !,
    (   memberchk(completion_tokens_details-json(Details), Pairs),
        memberchk(reasoning_tokens-R, Details)
    ->  true
    ;   R = 0
    ),
    (   memberchk(prompt_cache_hit_tokens-H, Pairs)
    ->  true
    ;   H = 0
    ).
v2_lang_usage_parts(_, 0, 0, 0, 0, 0).

v2_lang_usage_int(Key, Pairs, N) :-
    (   memberchk(Key-N0, Pairs), integer(N0)
    ->  N = N0
    ;   N = 0
    ).
