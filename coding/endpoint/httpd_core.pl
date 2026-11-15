%% coding/endpoint/httpd_core.pl -- the cocolog endpoint, without main.
%%
%% The pages, JSON, backend call, SSE synthesis, CORS, token guard and
%% trace. httpd.pl supplies main/0 and calls httpd_serve/2; test.pl imports
%% these predicates without starting a server.

:- use_module(library(httpd)).
:- use_module(library(http)).
:- use_module(library(json)).
:- use_module(library(curl)).
:- use_module('coding/endpoint/reasoning_core.pl').
:- use_module('coding/languages.pl').

%% ---- configuration -----------------------------------------------------

ep_env(Name, Default, Value) :-
    (   getenv(Name, V), V \== ''
    ->  Value = V
    ;   Value = Default
    ).

ep_int(Name, Default, N) :-
    ep_env(Name, '', V),
    (   V \== '', atom_number(V, N0)
    ->  N = N0
    ;   N = Default
    ).

ep_backend_url(Url) :-
    ep_env('CODING_ENDPOINT_BACKEND',
           'https://api.deepseek.com/v1/chat/completions', Url).

ep_backend_model(c, Model) :-
    ep_env('CODING_ENDPOINT_C_MODEL', '', M0),
    (   M0 \== '' -> Model = M0
    ;   ep_env('CODING_ENDPOINT_MODEL', 'deepseek-chat', Model)
    ).
ep_backend_model(cocolog, Model) :-
    ep_env('CODING_ENDPOINT_COCOLOG_MODEL', '', M0),
    (   M0 \== '' -> Model = M0
    ;   ep_env('CODING_ENDPOINT_MODEL', 'deepseek-chat', Model)
    ).
ep_backend_model(python, Model) :-
    ep_env('CODING_ENDPOINT_PYTHON_MODEL', '', M0),
    (   M0 \== '' -> Model = M0
    ;   ep_env('CODING_ENDPOINT_MODEL', 'deepseek-chat', Model)
    ).

%% Despite its name, CODING_ENDPOINT_KEY_ENV holds the backend key itself;
%% it is not the name of another variable. The generators read the same one.
ep_key(Key) :-
    ep_env('CODING_ENDPOINT_KEY_ENV', '', Key),
    (   Key \== ''
    ->  true
    ;   throw(error(ep_no_key('CODING_ENDPOINT_KEY_ENV'), ep_key/1))
    ).

ep_token(Token) :-
    ep_env('CODING_ENDPOINT_TOKEN', '', Token).

ep_allowed_origins(Origins) :-
    ep_env('CODING_ENDPOINT_ALLOW_ORIGIN',
           'http://localhost:3000,http://127.0.0.1:3000,http://localhost:4096,http://127.0.0.1:4096',
           Text),
    atom_string(Text, String),
    split_string(String, ",", " \t", Parts),
    exclude(ep_nonempty_string, Parts, Kept),
    maplist(atom_string, Origins, Kept).

ep_nonempty_string(S) :- S \== ''.

%% ---- paths and guides --------------------------------------------------

ep_read_text(Path, Text) :-
    catch(read_file_to_codes(Path, Codes), _, fail),
    atom_codes(Text, Codes).

ep_guide(c, Guide) :-
    ep_read_text('coding/endpoint/prompts/c.md', Guide).

ep_guide(cocolog, Guide) :-
    ep_env('COCOLOG_SKILL', '../cocolog/SKILL.md', SkillPath),
    ep_read_text(SkillPath, Skill),
    ep_read_text('coding/endpoint/prompts/cocolog.md', Add),
    atomic_list_concat([Skill, '\n\n', Add], Guide).

ep_guide(python, Guide) :-
    ep_read_text('coding/endpoint/prompts/python.md', Guide).

%% A model name may end in -rN: c-r8, cocolog-r2. The suffix chooses the
%% number of reasoning checks, and the base chooses the language guide.
ep_model_count(Model, N) :-
    atom(Model),
    atom_string(Model, String),
    split_string(String, "-", "", Parts),
    reverse(Parts, [LastString|_]),
    atom_string(Last, LastString),
    atom_concat('r', Digits, Last),
    atom_number(Digits, N),
    integer(N),
    N >= 0.

ep_model_base(Model, Base) :-
    (   ep_model_count(Model, _)
    ->  atom_string(Model, String),
        split_string(String, "-", "", Parts),
        append(BaseParts, [_], Parts),
        atomic_list_concat(BaseParts, '-', Base0),
        atom_string(Base, Base0)
    ;   Base = Model
    ).

ep_alias(Model, Alias) :-
    atom(Model),
    downcase_atom(Model, Low),
    ep_model_base(Low, Base),
    (   memberchk(Base, [c, c89, c99, c11, c17, c23])
    ->  Alias = c
    ;   memberchk(Base, [cocolog, 'cocolog-card'])
    ->  Alias = cocolog
    ;   Base == python
    ->  Alias = python
    ).

%% x-coding-reasoning wins; then a -rN model suffix; then the endpoint's
%% environment. The answer is default, off or count(N).
ep_reasoning_setting(Request, Model, Setting) :-
    (   http_header(Request, 'x-coding-reasoning', Value)
    ->  ep_reasoning_value(Value, Setting)
    ;   ep_model_count(Model, N)
    ->  (   N =:= 0
        ->  Setting = off
        ;   Setting = count(N)
        )
    ;   Setting = default
    ).

ep_reasoning_value(Value, Setting) :-
    (   memberchk(Value, [off, none, plain, '0'])
    ->  Setting = off
    ;   atom_number(Value, N),
        integer(N),
        N >= 0
    ->  Setting = count(N)
    ;   Setting = default
    ).

%% ---- JSON pairs --------------------------------------------------------

ep_json_get(json(Pairs), Key, Value) :-
    memberchk(Key-Value, Pairs).

ep_json_set(json(Pairs), Key, Value, json(Out)) :-
    (   select(Key-_, Pairs, Rest)
    ->  Out = [Key-Value|Rest]
    ;   Out = [Key-Value|Pairs]
    ).

ep_json_del(json(Pairs), Key, json(Out)) :-
    exclude(ep_key_is(Key), Pairs, Out).

ep_key_is(Key, Key-_).

ep_json_set_field(Body0, Key, Value, Body) :-
    (   ep_json_get(Body0, Key, _)
    ->  ep_json_set(Body0, Key, Value, Body)
    ;   ep_json_set(Body0, Key, Value, Body)
    ).

%% ---- messages ----------------------------------------------------------

ep_messages(Body, Messages) :-
    ep_json_get(Body, messages, Messages),
    is_list(Messages),
    Messages \== [].

ep_message_role(json(Pairs), Role) :-
    memberchk(role-Role, Pairs).

ep_last_user_text(Messages, Text) :-
    reverse(Messages, Reversed),
    member(json(Pairs), Reversed),
    memberchk(role-user, Pairs),
    memberchk(content-Text, Pairs),
    atom(Text),
    Text \== '',
    !.

%% The task is the FIRST user turn. Later turns in a tool session are
%% results and follow-ups; the request the reasoning checks belong to is
%% the one that opened the session.
ep_task_text(Messages, Text) :-
    member(json(Pairs), Messages),
    memberchk(role-user, Pairs),
    memberchk(content-Text, Pairs),
    atom(Text),
    Text \== '',
    !.

ep_title_request(Messages) :-
    Messages = [json(Pairs)|_],
    memberchk(role-system, Pairs),
    memberchk(content-Content, Pairs),
    atom(Content),
    sub_atom(Content, 0, _, _, 'You name conversations').

ep_add_guide([json(Pairs)|Rest], Guide, [json(Pairs1)|Rest]) :-
    memberchk(role-system, Pairs),
    !,
    (   memberchk(content-Content, Pairs),
        atom(Content)
    ->  atomic_list_concat([Content, '\n\n', Guide], Content1),
        ep_json_set(json(Pairs), content, Content1, json(Pairs1))
    ;   ep_json_set(json(Pairs), content, Guide, json(Pairs1))
    ).
ep_add_guide(Messages, Guide,
             [json([role-system, content-Guide])|Messages]).

%% ---- the reasoning pre-pass -------------------------------------------

ep_reasoning_on :-
    ep_env('CODING_ENDPOINT_REASONING', 'on', V),
    \+ memberchk(V, [off, '0', no, false]).

ep_unique([], []).
ep_unique([X|Xs], [X|Ys]) :-
    \+ memberchk(X, Xs),
    ep_unique(Xs, Ys).
ep_unique([X|Xs], Ys) :-
    memberchk(X, Xs),
    ep_unique(Xs, Ys).

ep_bullet(Check, Bullet) :-
    format(atom(Bullet), '- ~w', [Check]).

ep_note([], '').
ep_note(Checks, Note) :-
    maplist(ep_bullet, Checks, Bullets),
    atomic_list_concat(Bullets, '\n', Body),
    format(atom(Note),
           '~n~n# Reasoning pre-pass~n~nA deterministic pass by the repository reasoner read the request and found these checks. Verify each one before you say the task is done:~n~n~w',
           [Body]).

%% The checks every code task gets when its wording gives fewer than the
%% minimum. They are deliberately generic: the task's own obligations, when
%% it has any, stay first.
ep_general_check('Read the input exactly as the task describes; do not assume more input than it gives.').
ep_general_check('Write exactly the required result; do not print a prompt, label or debugging text.').
ep_general_check('Compile and run the program before you say the task is done.').
ep_general_check('Handle empty input, end of file and malformed input without crashing.').
ep_general_check('Check every allocation, bound, index and null before it is used.').
ep_general_check('Keep the result deterministic; no timestamps, random values or environment-dependent output.').
ep_general_check('Remove debugging output from the final program.').
ep_general_check('Run the task''s own example and compare its exact output before you say it is done.').

%% By default exactly two checks: the task's first two when it has that
%% many, general ones when it has fewer, and no more when it has more.
%% A request's x-coding-reasoning header overrides both ends: 0 or off
%% turns the pass off, N keeps N checks.
ep_checks(Checks0, Checks) :-
    ep_reasoning_count_from_env(Min, Max),
    ep_checks(Min, Max, Checks0, Checks).

ep_checks(Min, Max, Checks0, Checks) :-
    ep_checks(c, Min, Max, Checks0, Checks).

ep_checks(Language, Min, Max, Checks0, Checks) :-
    ep_general_checks(Language, General),
    ep_limit_checks(Checks0, Max, Limited),
    ep_fill_checks(General, Min, Max, Limited, Checks).

ep_general_checks(c, Checks) :-
    findall(Check, ep_general_check(Check), Checks).
ep_general_checks(cocolog, Checks) :-
    ep_general_checks(c, Checks).
ep_general_checks(python, Checks) :-
    codegen_language(python, Language),
    codegen_language_checks(Language, Checks).

ep_reasoning_count_from_env(Min, Max) :-
    ep_int('CODING_ENDPOINT_REASONING_MIN', 2, Min),
    ep_int('CODING_ENDPOINT_REASONING_MAX', 2, Max).

ep_reasoning_count(default, Min, Max) :-
    ep_reasoning_count_from_env(Min, Max).
ep_reasoning_count(off, 0, 0).
ep_reasoning_count(count(N), N, N).

ep_mode(true, _, title) :-
    !.
ep_mode(false, off, plain) :-
    !.
ep_mode(false, count(0), plain) :-
    !.
ep_mode(false, _, Mode) :-
    (   ep_reasoning_on
    ->  Mode = reasoning
    ;   Mode = plain
    ).

ep_limit_checks(_, Max, []) :-
    Max =< 0,
    !.
ep_limit_checks(Checks, Max, Checks) :-
    length(Checks, N),
    N =< Max,
    !.
ep_limit_checks(Checks, Max, Limited) :-
    length(Limited, Max),
    append(Limited, _, Checks).

ep_fill_checks(_, Min, _, Checks, Checks) :-
    length(Checks, N),
    N >= Min,
    !.
ep_fill_checks(General, Min, Max, Checks, Out) :-
    (   Max > 0, length(Checks, N), N >= Max
    ->  Out = Checks
    ;   member(Check, General),
        \+ memberchk(Check, Checks),
        !,
        append(Checks, [Check], Checks1),
        ep_fill_checks(General, Min, Max, Checks1, Out)
    ;   Out = Checks
    ).

ep_reasoning(Setting, Mode, Title, Messages, Guide0, Guide, N, Terms) :-
    ep_reasoning(c, Setting, Mode, Title, Messages, Guide0, Guide, N, Terms).

ep_reasoning(Language, Setting, Mode, Title, Messages, Guide0, Guide, N, Terms) :-
    (   Mode == reasoning,
        \+ Title,
        ep_task_text(Messages, Text)
    ->  endpoint_reason(Language, Text, Obs, CObs, Terms0),
        append(Obs, CObs, All0),
        ep_unique(All0, All1),
        ep_reasoning_count(Setting, Min, Max),
        ep_checks(Language, Min, Max, All1, All),
        length(All, N),
        Terms = Terms0,
        ep_note(All, Note),
        atomic_list_concat([Guide0, Note], Guide)
    ;   Guide = Guide0, N = 0, Terms = 0
    ).

%% ---- backend -----------------------------------------------------------

ep_cap_tokens(Body0, Body) :-
    ep_int('CODING_ENDPOINT_MAX_TOKENS', 32768, Max),
    (   Max > 0
    ->  (   ep_json_get(Body0, max_tokens, N0),
            integer(N0), N0 > 0, N0 =< Max
        ->  Body = Body0
        ;   ep_json_set(Body0, max_tokens, Max, Body)
        )
    ;   Body = Body0
    ).

%% An omitted, blank or null effort is the endpoint's default: none. The
%% backend distinguishes an absent effort from an explicit one, so the
%% endpoint writes it rather than leave the provider's default in place.
ep_default_effort(Body0, Body) :-
    (   ep_json_get(Body0, reasoning_effort, Value),
        Value \== '',
        Value \== @(null)
    ->  Body = Body0
    ;   ep_json_set_field(Body0, reasoning_effort, none, Body)
    ).

ep_forward(Body0, Alias, Status, Resp) :-
    ep_default_effort(Body0, BodyE),
    ep_backend_model(Alias, Model),
    ep_json_set_field(BodyE, model, Model, Body1),
    ep_json_set_field(Body1, stream, @(false), Body2),
    ep_json_del(Body2, stream_options, Body2a),
    ep_json_del(Body2a, max_completion_tokens, Body3),
    ep_cap_tokens(Body3, Body4),
    json_codes(Body4, Codes),
    ep_backend_url(Url),
    ep_key(Key),
    format(atom(Auth), 'Authorization: Bearer ~w', [Key]),
    curl_post(Url, 'application/json', Codes,
              [header(Auth), timeout(600), max_size(16777216)],
              Status, Resp).

%% The backend's usage object, as flat numbers for the trace. A reply
%% without usage (an error, or a backend that reports none) is all zero.
ep_usage(Resp, Usage) :-
    (   catch(json_parse(Resp, json(Pairs)), _, fail),
        memberchk(usage-json(U), Pairs)
    ->  ep_usage_count(U, prompt_tokens, P),
        ep_usage_count(U, completion_tokens, C),
        ep_usage_reasoning(U, R),
        ep_usage_total(U, P, C, T),
        ep_usage_cache(U, H),
        Usage = usage(P, C, R, T, H)
    ;   Usage = usage(0, 0, 0, 0, 0)
    ).

ep_usage_count(Pairs, Key, N) :-
    (   memberchk(Key-V, Pairs),
        integer(V),
        V >= 0
    ->  N = V
    ;   N = 0
    ).

ep_usage_reasoning(Pairs, R) :-
    (   memberchk(completion_tokens_details-json(Details), Pairs)
    ->  ep_usage_count(Details, reasoning_tokens, R)
    ;   R = 0
    ).

ep_usage_total(Pairs, P, C, T) :-
    (   memberchk(total_tokens-T0, Pairs),
        integer(T0),
        T0 >= 0
    ->  T = T0
    ;   T is P + C
    ).

ep_usage_cache(Pairs, H) :-
    (   memberchk(prompt_cache_hit_tokens-H0, Pairs),
        integer(H0),
        H0 >= 0
    ->  H = H0
    ;   memberchk(prompt_tokens_details-json(Details), Pairs)
    ->  ep_usage_count(Details, cached_tokens, H)
    ;   H = 0
    ).

ep_usage_json(usage(P, C, R, T, H),
              [prompt_tokens-P, completion_tokens-C, reasoning_tokens-R,
               total_tokens-T, cache_hit_tokens-H]).

%% The usage chunk OpenCode reads for the session's token counts. It is
%% the OpenAI streaming shape: an empty choices list and one usage object,
%% sent before [DONE]. DeepSeek's cache fields and OpenAI's details are
%% both written, so a client may read either.
ep_usage_stream_json(usage(P, C, R, T, H),
                     json([prompt_tokens-P,
                           completion_tokens-C,
                           total_tokens-T,
                           prompt_tokens_details-json([cached_tokens-H]),
                           completion_tokens_details-
                               json([reasoning_tokens-R]),
                           prompt_cache_hit_tokens-H,
                           prompt_cache_miss_tokens-M])) :-
    M is max(0, P - H).

ep_usage_chunk(Id, Created, Model, Usage, Chunk) :-
    ep_usage_stream_json(Usage, UsageJson),
    Chunk = json([id-Id,
                  object-'chat.completion.chunk',
                  created-Created,
                  model-Model,
                  choices-[],
                  usage-UsageJson]).

%% ---- the reply as JSON or as one SSE body ------------------------------

ep_chunk(Id, Created, Model, Delta, Finish, Chunk) :-
    Chunk = json([id-Id,
                  object-'chat.completion.chunk',
                  created-Created,
                  model-Model,
                  choices-[json([index-0,
                                 delta-json(Delta),
                                 finish_reason-Finish])]]).

ep_indexed([], _, []).
ep_indexed([json(Pairs)|Rest], I, [json([index-I|Pairs])|Out]) :-
    I1 is I + 1,
    ep_indexed(Rest, I1, Out).

ep_delta(Content, ToolCalls, Reasoning, Delta) :-
    (   atom(Content), Content \== ''
    ->  D0 = [role-assistant, content-Content]
    ;   D0 = [role-assistant]
    ),
    (   atom(Reasoning), Reasoning \== ''
    ->  D1 = [reasoning_content-Reasoning|D0]
    ;   D1 = D0
    ),
    (   is_list(ToolCalls), ToolCalls \== []
    ->  ep_indexed(ToolCalls, 0, Indexed),
        append(D1, [tool_calls-Indexed], Delta)
    ;   Delta = D1
    ).

ep_sse(Resp, Alias, Sse) :-
    json_parse(Resp, json(Pairs)),
    memberchk(id-Id, Pairs),
    memberchk(created-Created, Pairs),
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-json(Message), Choice),
    (   memberchk(finish_reason-Finish, Choice)
    ->  true
    ;   Finish = stop
    ),
    (   memberchk(content-Content, Message)
    ->  true
    ;   Content = @(null)
    ),
    (   memberchk(tool_calls-ToolCalls, Message)
    ->  true
    ;   ToolCalls = []
    ),
    (   memberchk(reasoning_content-Reasoning, Message)
    ->  true
    ;   Reasoning = ''
    ),
    ep_backend_model(Alias, Model),
    ep_delta(Content, ToolCalls, Reasoning, Delta),
    ep_chunk(Id, Created, Model, Delta, @(null), Chunk1),
    ep_chunk(Id, Created, Model, [], Finish, Chunk2),
    ep_usage(Resp, Usage),
    ep_usage_chunk(Id, Created, Model, Usage, Chunk3),
    json_codes(Chunk1, C1),
    json_codes(Chunk2, C2),
    json_codes(Chunk3, C3),
    atom_codes('data: ', Prefix),
    atom_codes('data: [DONE]\n\n', Done),
    append(Prefix, C1, L1), append(L1, [10, 10], S1),
    append(Prefix, C2, L2), append(L2, [10, 10], S2),
    append(Prefix, C3, L3), append(L3, [10, 10], S3),
    append(S1, S2, S12),
    append(S12, S3, S123),
    append(S123, Done, Sse).

%% ---- CORS and token ----------------------------------------------------

ep_cors(Request, Headers) :-
    (   http_header(Request, origin, Origin),
        Origin \== '',
        ep_allowed_origins(Origins),
        memberchk(Origin, Origins)
    ->  Headers = ['Access-Control-Allow-Origin'-Origin,
                   'Vary'-'Origin']
    ;   Headers = []
    ).

ep_preflight(Request, reply(204, Headers, '')) :-
    ep_cors(Request, Cors),
    append(Cors, ['Access-Control-Allow-Headers'-'Authorization, Content-Type',
                  'Access-Control-Allow-Methods'-'GET, POST, OPTIONS'],
           Headers).

ep_token_ok(Request) :-
    ep_token(Token),
    (   Token == ''
    ->  true
    ;   http_header(Request, authorization, Header),
        atom_string(Header, String),
        split_string(String, " ", "", [SchemeS, GivenS]),
        atom_string(Scheme, SchemeS),
        atom_string(Given, GivenS),
        downcase_atom(Scheme, bearer),
        Given == Token
    ).

ep_error_reply(Request, Status, Message, reply(Status, Headers, Codes)) :-
    ep_cors(Request, Cors),
    append(Cors, ['Content-Type'-'application/json'], Headers),
    json_codes(json([error-json([message-Message])]), Codes).

%% ---- trace -------------------------------------------------------------

ep_header(Request, Name, Default, Value) :-
    (   http_header(Request, Name, V), V \== ''
    ->  Value = V
    ;   Value = Default
    ).

ep_trace(Request, Start, Alias, Backend, Effort, Mode, N, Terms,
         Stream, MessageCount, ToolCount, Status, Usage) :-
    ep_env('CODING_ENDPOINT_TRACE', '', File),
    File \== '',
    get_time(Now),
    Seconds is Now - Start,
    ep_header(Request, 'x-opencode-session-id', '-', Session0),
    ep_header(Request, 'x-opencode-session', '-', Session1),
    ep_header(Request, 'x-session-id', '-', Session2),
    (   Session0 \== '-' -> Session = Session0
    ;   Session1 \== '-' -> Session = Session1
    ;   Session = Session2
    ),
    ep_header(Request, 'x-opencode-project', '-', Project),
    (   Stream == true -> StreamJson = @(true) ; StreamJson = @(false) ),
    ep_usage_json(Usage, UsagePairs),
    json_codes(json([ts-Now, session-Session, project-Project,
                     seconds-Seconds, status-Status, model-Alias,
                     backend-Backend, effort-Effort, mode-Mode,
                     reasoning-N, terms-Terms, stream-StreamJson,
                     messages-MessageCount, tools-ToolCount | UsagePairs]),
               Codes),
    append(Codes, [10], Line),
    catch(append_file_from_codes(File, Line), _, true).

%% ---- the loop guard ----------------------------------------------------

ep_repeat_limit(Limit) :-
    ep_int('CODING_ENDPOINT_REPEAT_LIMIT', 16, Limit).

ep_loop_verdict(Messages, Verdict) :-
    ep_repeat_limit(Limit),
    (   Limit > 0,
        ep_tool_signatures(Messages, Signatures),
        ep_signature_counts(Signatures, Counts),
        member(Signature-Count, Counts),
        Count >= Limit
    ->  Verdict = repeat(Signature, Count, Limit)
    ;   Verdict = ok
    ).

ep_tool_signatures([], []).
ep_tool_signatures([json(Pairs)|Messages], Signatures) :-
    (   memberchk(tool_calls-Calls, Pairs),
        is_list(Calls)
    ->  ep_call_signatures(Calls, Here),
        ep_tool_signatures(Messages, Rest),
        append(Here, Rest, Signatures)
    ;   ep_tool_signatures(Messages, Signatures)
    ).

ep_call_signatures([], []).
ep_call_signatures([json(Pairs)|Calls], [Signature|Signatures]) :-
    (   memberchk(function-json(Function), Pairs),
        memberchk(name-Name, Function),
        memberchk(arguments-Arguments, Function)
    ->  ep_tool_signature(Name, Arguments, Signature)
    ;   Signature = unknown
    ),
    ep_call_signatures(Calls, Signatures).

ep_tool_signature(Name, Arguments, Signature) :-
    (   catch(ep_tool_arguments(Arguments, Value), _, fail)
    ->  true
    ;   Value = none
    ),
    (   Name == shell,
        Value = json(ArgumentPairs),
        memberchk(command-Command, ArgumentPairs)
    ->  Key0 = Command
    ;   Value = json(ArgumentPairs),
        memberchk(path-Path, ArgumentPairs)
    ->  ep_path_key(ArgumentPairs, Path, Key0)
    ;   atom(Arguments)
    ->  Key0 = Arguments
    ;   Key0 = none
    ),
    ep_signature_atom(Key0, Key),
    atomic_list_concat([Name, ':', Key], Signature).

%% A tool whose only argument is the path is keyed by that path. A tool
%% that writes, edits or reads a named part of a file carries its other
%% arguments in the key too: eighteen edits of one file, each a different
%% hunk, are eighteen signatures, and the same edit twice is one. Without
%% this, a session that legitimately edits one file many times is stopped.
ep_path_key([path-_], Path, Path) :-
    !.
ep_path_key(ArgumentPairs, Path, Key) :-
    ep_value_digest(json(ArgumentPairs), Digest),
    format(atom(Key), '~w#~w', [Path, Digest]).

%% A 32-bit FNV-1a digest of a value's text, as seven letters. Letters,
%% not digits: the signature's digit normalisation would fold two decimal
%% digests to one '#'. It keeps the signature short; two values that meet
%% here are the same edit, which is what the guard is counting.
ep_value_digest(Value, Digest) :-
    (   atom(Value)
    ->  atom_codes(Value, Codes)
    ;   string(Value)
    ->  string_codes(Value, Codes)
    ;   number(Value)
    ->  format(atom(Text), '~w', [Value]),
        atom_codes(Text, Codes)
    ;   format(atom(Text), '~q', [Value]),
        atom_codes(Text, Codes)
    ),
    ep_codes_digest(Codes, 2166136261, Hash),
    ep_digest_letters(7, Hash, Letters),
    atom_codes(Digest, Letters).

ep_codes_digest([], Hash, Hash).
ep_codes_digest([Code|Codes], Hash0, Hash) :-
    Mixed is Hash0 xor Code,
    Hash1 is (Mixed * 16777619) mod 4294967296,
    ep_codes_digest(Codes, Hash1, Hash).

ep_digest_letters(0, _, []).
ep_digest_letters(N, Hash, [Letter|Letters]) :-
    N > 0,
    Digit is Hash mod 26,
    Letter is 97 + Digit,
    Next is Hash div 26,
    N1 is N - 1,
    ep_digest_letters(N1, Next, Letters).

ep_tool_arguments(Value, Value) :-
    Value = json(_),
    !.
ep_tool_arguments(Arguments, Value) :-
    catch(json_parse(Arguments, Value), _, fail).

ep_signature_atom(Value, Atom) :-
    (   atom(Value)
    ->  Text = Value
    ;   string(Value)
    ->  atom_string(Text, Value)
    ;   number(Value)
    ->  format(atom(Text), '~w', [Value])
    ;   format(atom(Text), '~q', [Value])
    ),
    downcase_atom(Text, Lower),
    atom_codes(Lower, Codes),
    ep_digits_normal(Codes, Normal),
    atom_codes(Atom, Normal).

ep_digits_normal([], []).
ep_digits_normal([C|Codes], Out) :-
    (   C >= 0'0,
        C =< 0'9
    ->  Out = [0'#|Rest],
        ep_digits_skip(Codes, Rest)
    ;   Out = [C|Rest],
        ep_digits_normal(Codes, Rest)
    ).

ep_digits_skip([C|Codes], Out) :-
    C >= 0'0,
    C =< 0'9,
    !,
    ep_digits_skip(Codes, Out).
ep_digits_skip(Codes, Codes).

ep_signature_counts([], []).
ep_signature_counts([Signature|Signatures], Counts) :-
    ep_signature_counts(Signatures, Rest),
    ep_signature_bump(Signature, Rest, Counts).

ep_signature_bump(Signature, [], [Signature-1]).
ep_signature_bump(Signature, [Signature-N|Rest], [Signature-N1|Rest]) :-
    !,
    N1 is N + 1.
ep_signature_bump(Signature, [Other|Rest], [Other|Out]) :-
    ep_signature_bump(Signature, Rest, Out).

%% ---- the chat route ----------------------------------------------------

ep_chat(Request, Reply) :-
    get_time(Start),
    (   \+ ep_token_ok(Request)
    ->  ep_error_reply(Request, 401,
                       'Authorization: Bearer TOKEN is required', Reply)
    ;   Request = request(_, _, _, _, _, BodyCodes),
        (   catch(( ep_body_json_codes(BodyCodes, SafeCodes),
                    json_parse(SafeCodes, Body) ), _, fail)
        ->  ep_chat_body(Request, Body, Start, Reply)
        ;   ep_error_reply(Request, 400, 'the body is not JSON', Reply)
        )
    ).

%% JSON lets a string hold \u0000, and cocolog's json_parse stops at it:
%% a tool that prints binary puts thousands of them into the next request,
%% and the whole body used to be refused. The escape becomes �, the
%% replacement character, so the document still parses and the tool's
%% text stays where it was. Only the escape is touched; a raw NUL byte is
%% not JSON and is still refused.
ep_body_json_codes([], []).
ep_body_json_codes([92, 117, 48, 48, 48, 48 | Codes],
                   [92, 117, 70, 70, 70, 68 | Out]) :-
    !,
    ep_body_json_codes(Codes, Out).
ep_body_json_codes([C|Codes], [C|Out]) :-
    ep_body_json_codes(Codes, Out).

%% A loop guard. OpenCode sends the session's whole tool history, so the
%% endpoint can see the same shell command (or file access) requested again
%% and again. Digits are normalised, so names848.pl and names855.pl are one
%% signature. At the limit the request is refused before the model is paid
%% for another turn.
ep_chat_body(Request, Body, Start, Reply) :-
    (   ep_messages(Body, Messages),
        ep_loop_verdict(Messages, repeat(Signature, Count, Limit))
    ->  format(atom(Message),
               'loop guard: the same tool call was repeated ~w times (limit ~w): ~s. Stop repeating it and summarize what you found.',
               [Count, Limit, Signature]),
        ep_error_reply(Request, 409, Message, Reply)
    ;   ep_chat_body_1(Request, Body, Start, Reply)
    ).

ep_chat_body_1(Request, Body, Start, Reply) :-
    (   ep_json_get(Body, model, Model0),
        ep_alias(Model0, Alias),
        ep_messages(Body, Messages)
    ->  (   ep_guide(Alias, Guide0)
        ->  (   ep_title_request(Messages)
            ->  Title = true
            ;   Title = false
            ),
            ep_reasoning_setting(Request, Model0, Setting),
            ep_mode(Title, Setting, Mode),
            ep_reasoning(Alias, Setting, Mode, Title, Messages, Guide0, Guide,
                         N, Terms),
            ep_backend_model(Alias, BackendModel),
            (   is_list(Terms) -> length(Terms, TermCount) ; TermCount = 0 ),
            (   Title == true
            ->  Body1 = Body
            ;   ep_add_guide(Messages, Guide, Messages1),
                ep_json_set(Body, messages, Messages1, Body1)
            ),
            (   ep_json_get(Body1, stream, Stream0)
            ->  true
            ;   Stream0 = @(true)
            ),
            (   Stream0 == @(true) -> Stream = true ; Stream = false ),
            (   ep_json_get(Body1, reasoning_effort, Effort0),
                Effort0 \== '',
                Effort0 \== @(null)
            ->  Effort = Effort0
            ;   Effort = none
            ),
            (   ep_json_get(Body1, tools, Tools), is_list(Tools)
            ->  length(Tools, ToolCount)
            ;   ToolCount = 0
            ),
            length(Messages, MessageCount),
            ep_cors(Request, Cors),
            (   catch(ep_forward(Body1, Alias, Status, Resp), Error,
                      ( Status = 502,
                        format(atom(Message), 'backend failed: ~q', [Error]),
                        json_codes(json([error-json([message-Message])]), Resp) ))
            ->  true
            ;   Status = 502,
                json_codes(json([error-json([message-'backend failed'])]), Resp)
            ),
            (   Status =:= 200, Stream == true
            ->  (   catch(ep_sse(Resp, Alias, Sse), _, fail)
                ->  append(Cors, ['Content-Type'-'text/event-stream',
                                  'Cache-Control'-'no-cache',
                                  'X-Accel-Buffering'-'no'], Headers),
                    Reply = reply(200, Headers, Sse)
                ;   ep_error_reply(Request, 502,
                                   'the backend reply could not be read as SSE',
                                   Reply)
                )
            ;   append(Cors, ['Content-Type'-'application/json'], Headers),
                Reply = reply(Status, Headers, Resp)
            ),
            ep_usage(Resp, Usage),
            ep_trace(Request, Start, Alias, BackendModel, Effort, Mode,
                     N, TermCount, Stream, MessageCount, ToolCount, Status,
                     Usage)
        ;   ep_error_reply(Request, 500,
                           'the language guide is missing', Reply)
        )
    ;   ep_error_reply(Request, 400,
                       'model and messages are required', Reply)
    ).

%% ---- the Responses route (Codex) --------------------------------------
%%
%% Codex speaks only the Responses API. A Responses request is translated
%% to the chat request the rest of the endpoint already knows -- same
%% messages, guide, reasoning checks, loop guard and backend -- and the
%% chat reply is written back as Responses events (when Codex asked for a
%% stream) or as one Responses object. Codex's developer messages become
%% system messages, so ep_add_guide appends the language guide to the
%% first of them.

ep_responses(Request, Reply) :-
    (   \+ ep_token_ok(Request)
    ->  ep_error_reply(Request, 401,
                       'Authorization: Bearer TOKEN is required', Reply)
    ;   Request = request(_, _, _, _, _, BodyCodes),
        (   catch(( ep_body_json_codes(BodyCodes, SafeCodes),
                    json_parse(SafeCodes, Body) ), _, fail)
        ->  ep_responses_body(Request, Body, Reply)
        ;   ep_error_reply(Request, 400, 'the body is not JSON', Reply)
        )
    ).

ep_responses_body(Request, Body, Reply) :-
    (   ep_responses_chat_body(Body, ChatBody)
    ->  ep_json_get(Body, model, Model),
        (   ep_json_get(Body, stream, Stream0),
            Stream0 == @(true)
        ->  Stream = true
        ;   Stream = false
        ),
        json_codes(ChatBody, ChatCodes),
        Request = request(Method, Path, Headers, Version, Host, _),
        ChatRequest = request(Method, Path, Headers, Version, Host, ChatCodes),
        (   catch(ep_chat(ChatRequest, ChatReply), Error,
                  ( format(user_error, "endpoint: ~q~n", [Error]),
                    ep_error_reply(Request, 500, 'internal error', ChatReply) ))
        ->  true
        ;   ep_error_reply(Request, 500, 'internal error', ChatReply)
        ),
        ChatReply = reply(Status, ChatHeaders, ChatReplyCodes),
        (   Status =:= 200
        ->  ep_responses_reply(Request, Model, Stream, ChatReplyCodes, Reply)
        ;   Reply = reply(Status, ChatHeaders, ChatReplyCodes)
        )
    ;   ep_error_reply(Request, 400, 'model and input are required', Reply)
    ).

ep_responses_chat_body(Body, ChatBody) :-
    ep_json_get(Body, model, Model),
    ep_json_get(Body, input, Input),
    ep_responses_messages(Input, Messages0),
    Messages0 \== [],
    ep_responses_instructions(Body, Messages0, Messages),
    ep_responses_tools(Body, Tools),
    ep_responses_extras(Body, Extras),
    Base = [model-Model, messages-Messages, stream- @(false)],
    ep_responses_tools_pair(Tools, Base, Base1),
    append(Extras, Base1, Pairs),
    ChatBody = json(Pairs).

ep_responses_tools_pair([], Pairs, Pairs).
ep_responses_tools_pair(Tools, Pairs, [tools-Tools|Pairs]) :-
    Tools = [_|_].

ep_responses_instructions(Body, Messages0, Messages) :-
    (   ep_json_get(Body, instructions, Text),
        atom(Text),
        Text \== ''
    ->  Messages = [json([role-system, content-Text])|Messages0]
    ;   Messages = Messages0
    ).

%% The input is a string or a list of items. A run of function_call items
%% is one assistant message with several tool calls; the outputs that
%% follow are the tool messages that answer them.
ep_responses_messages(Input, Messages) :-
    atom(Input),
    Input \== '',
    !,
    Messages = [json([role-user, content-Input])].
ep_responses_messages(Input, Messages) :-
    is_list(Input),
    !,
    ep_r_items(Input, [], Messages).

ep_r_items([], Pending, Messages) :-
    ep_r_flush(Pending, Messages).
ep_r_items([json(Pairs)|Items], Pending, Messages) :-
    memberchk(type-function_call, Pairs),
    !,
    ep_r_function_call(json(Pairs), Call),
    ep_r_items(Items, [Call|Pending], Messages).
ep_r_items([Item|Items], Pending, Messages) :-
    ep_r_flush(Pending, Here),
    ep_r_item_message(Item, Message),
    !,
    ep_r_items(Items, [], Rest),
    ep_r_cons(Here, Message, Rest, Messages).
ep_r_items([_|Items], Pending, Messages) :-
    ep_r_flush(Pending, Here),
    ep_r_items(Items, [], Rest),
    append(Here, Rest, Messages).

ep_r_flush([], []).
ep_r_flush(Pending, [json([role-assistant, tool_calls-Calls])]) :-
    Pending = [_|_],
    reverse(Pending, Calls).

ep_r_cons(Here, none, Rest, Messages) :-
    append(Here, Rest, Messages).
ep_r_cons(Here, Message, Rest, Messages) :-
    Message \== none,
    append(Here, [Message|Rest], Messages).

ep_r_function_call(json(Pairs),
                   json([id-Id, type-function,
                         function-json([name-Name, arguments-Arguments])])) :-
    memberchk(call_id-Id, Pairs),
    memberchk(name-Name, Pairs),
    ep_r_arguments(Pairs, Arguments).

ep_r_arguments(Pairs, Arguments) :-
    (   memberchk(arguments-Value, Pairs),
        atom(Value)
    ->  Arguments = Value
    ;   Arguments = '{}'
    ).

ep_r_item_message(json(Pairs), Message) :-
    memberchk(type-message, Pairs),
    memberchk(role-Role0, Pairs),
    ep_r_role(Role0, Role),
    (   memberchk(content-Content0, Pairs)
    ->  ep_r_text(Content0, Text)
    ;   Text = ''
    ),
    Message = json([role-Role, content-Text]).
ep_r_item_message(json(Pairs), Message) :-
    memberchk(type-function_call_output, Pairs),
    memberchk(call_id-Id, Pairs),
    (   memberchk(output-Output, Pairs)
    ->  ep_r_text(Output, Text)
    ;   Text = ''
    ),
    Message = json([role-tool, tool_call_id-Id, content-Text]).

ep_r_role(developer, system) :-
    !.
ep_r_role(Role, Role).

ep_r_text(Value, Text) :-
    atom(Value),
    !,
    Text = Value.
ep_r_text(Value, Text) :-
    string(Value),
    !,
    atom_string(Text, Value).
ep_r_text(Value, Text) :-
    is_list(Value),
    !,
    ep_r_parts(Value, Parts),
    atomic_list_concat(Parts, '\n', Text).
ep_r_text(_, '').

ep_r_parts([], []).
ep_r_parts([json(Pairs)|Rest], [Text|Texts]) :-
    !,
    (   memberchk(text-Value, Pairs)
    ->  ep_r_text(Value, Text)
    ;   Text = ''
    ),
    ep_r_parts(Rest, Texts).
ep_r_parts([Other|Rest], [Text|Texts]) :-
    ep_r_text(Other, Text),
    ep_r_parts(Rest, Texts).

ep_responses_tools(Body, Tools) :-
    (   ep_json_get(Body, tools, Raw),
        is_list(Raw)
    ->  ep_r_tools(Raw, Tools)
    ;   Tools = []
    ).

ep_r_tools([], []).
ep_r_tools([Item|Items], Tools) :-
    ep_r_tool(Item, Tool),
    !,
    ep_r_tools(Items, Rest),
    ep_r_tools_add(Tool, Rest, Tools).
ep_r_tools([_|Items], Tools) :-
    ep_r_tools(Items, Tools).

ep_r_tools_add(none, Rest, Rest) :-
    !.
ep_r_tools_add(Tool, Rest, [Tool|Rest]).

ep_r_tool(json(Pairs), Tool) :-
    memberchk(type-function, Pairs),
    memberchk(name-Name, Pairs),
    !,
    (   memberchk(description-Description, Pairs)
    ->  true
    ;   Description = ''
    ),
    (   memberchk(parameters-Parameters, Pairs)
    ->  true
    ;   Parameters = json([])
    ),
    Tool = json([type-function,
                 function-json([name-Name, description-Description,
                                parameters-Parameters])]).
ep_r_tool(_, none).

ep_responses_extras(Body, Extras) :-
    findall(Key-Value, ep_responses_extra(Body, Key, Value), Extras).

ep_responses_extra(Body, tool_choice, Value) :-
    ep_json_get(Body, tool_choice, Value),
    Value \== @(null).
ep_responses_extra(Body, parallel_tool_calls, Value) :-
    ep_json_get(Body, parallel_tool_calls, Value),
    (   Value == @(true)
    ;   Value == @(false)
    ).
ep_responses_extra(Body, max_tokens, Value) :-
    ep_json_get(Body, max_output_tokens, Value),
    integer(Value),
    Value > 0.
ep_responses_extra(Body, temperature, Value) :-
    ep_json_get(Body, temperature, Value),
    number(Value).
ep_responses_extra(Body, reasoning_effort, Value) :-
    ep_json_get(Body, reasoning, json(Pairs)),
    memberchk(effort-Value, Pairs),
    atom(Value),
    Value \== ''.

%% ---- the chat reply as Responses --------------------------------------

ep_responses_reply(Request, Model, Stream, ChatCodes, Reply) :-
    ep_cors(Request, Cors),
    (   Stream == true
    ->  ep_responses_events(ChatCodes, Model, Events, _Response),
        ep_responses_sse(Events, Sse),
        append(Cors, ['Content-Type'-'text/event-stream',
                      'Cache-Control'-'no-cache'], Headers),
        Reply = reply(200, Headers, Sse)
    ;   ep_responses_events(ChatCodes, Model, _Events, Response),
        json_codes(Response, Codes),
        Reply = reply(200, ['Content-Type'-'application/json'|Cors], Codes)
    ).

ep_responses_events(ChatCodes, Model, Events, Response) :-
    ep_responses_chat(ChatCodes, Content, Calls),
    ep_responses_outputs(Content, Calls, Items, ItemEvents),
    ep_usage(ChatCodes, Usage),
    ep_responses_usage_json(Usage, UsageJson),
    get_time(Now),
    Created is round(Now),
    IdBase is round(Now * 1000),
    format(atom(RespId), 'resp_~w', [IdBase]),
    Resp0 = json([id-RespId, object-response, created_at-Created,
                  status-in_progress, model-Model, output-[]]),
    Response = json([id-RespId, object-response, created_at-Created,
                     status-completed, model-Model, output-Items,
                     usage-UsageJson]),
    CreatedEvent = 'response.created'-json([type-'response.created',
                                            response-Resp0]),
    DoneEvent = 'response.completed'-json([type-'response.completed',
                                           response-Response]),
    append([CreatedEvent|ItemEvents], [DoneEvent], Events).

ep_responses_chat(ChatCodes, Content, Calls) :-
    json_parse(ChatCodes, json(Pairs)),
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-json(Message), Choice),
    ep_responses_content(Message, Content),
    ep_responses_calls(Message, Calls).

ep_responses_content(Message, Content) :-
    (   memberchk(content-Value, Message),
        Value \== @(null)
    ->  ep_r_text(Value, Content)
    ;   Content = ''
    ).

ep_responses_calls(Message, Calls) :-
    (   memberchk(tool_calls-Value, Message),
        is_list(Value)
    ->  Calls = Value
    ;   Calls = []
    ).

ep_responses_outputs(Content, Calls, Items, Events) :-
    ep_responses_message_part(Content, Calls, 0, MsgItems, MsgEvents),
    length(MsgItems, MsgCount),
    Next is MsgCount,
    ep_responses_call_parts(Calls, Next, CallItems, CallEvents),
    append(MsgItems, CallItems, Items),
    append(MsgEvents, CallEvents, Events).

%% A reply that has only tool calls carries no message item.
ep_responses_message_part('', [_|_], _, [], []) :-
    !.
ep_responses_message_part(Content, _, Index, [Item1], Events) :-
    get_time(Now),
    IdBase is round(Now * 1000),
    format(atom(MsgId), 'msg_~w', [IdBase]),
    Part = json([type-output_text, text-Content, annotations-[]]),
    EmptyPart = json([type-output_text, text-'', annotations-[]]),
    Item0 = json([type-message, id-MsgId, status-in_progress,
                  role-assistant, content-[]]),
    Item1 = json([type-message, id-MsgId, status-completed,
                  role-assistant, content-[Part]]),
    Events = [
        'response.output_item.added'-json([type-'response.output_item.added',
                                           output_index-Index, item-Item0]),
        'response.content_part.added'-json([type-'response.content_part.added',
                                            item_id-MsgId,
                                            output_index-Index,
                                            content_index-0,
                                            part-EmptyPart]),
        'response.output_text.delta'-json([type-'response.output_text.delta',
                                           item_id-MsgId,
                                           output_index-Index,
                                           content_index-0,
                                           delta-Content]),
        'response.output_text.done'-json([type-'response.output_text.done',
                                          item_id-MsgId,
                                          output_index-Index,
                                          content_index-0,
                                          text-Content]),
        'response.content_part.done'-json([type-'response.content_part.done',
                                           item_id-MsgId,
                                           output_index-Index,
                                           content_index-0,
                                           part-Part]),
        'response.output_item.done'-json([type-'response.output_item.done',
                                          output_index-Index, item-Item1])
    ].

ep_responses_call_parts([], _, [], []).
ep_responses_call_parts([json(Pairs)|Calls], Index, [Item1|Items], Events) :-
    memberchk(id-CallId, Pairs),
    memberchk(function-json(Function), Pairs),
    memberchk(name-Name, Function),
    (   memberchk(arguments-Arguments, Function)
    ->  true
    ;   Arguments = '{}'
    ),
    format(atom(FcId), 'fc_~w', [CallId]),
    Item0 = json([type-function_call, id-FcId, call_id-CallId,
                  name-Name, arguments-Arguments, status-in_progress]),
    Item1 = json([type-function_call, id-FcId, call_id-CallId,
                  name-Name, arguments-Arguments, status-completed]),
    Added = 'response.output_item.added'-json([type-'response.output_item.added',
                                               output_index-Index,
                                               item-Item0]),
    Done = 'response.output_item.done'-json([type-'response.output_item.done',
                                             output_index-Index,
                                             item-Item1]),
    Next is Index + 1,
    ep_responses_call_parts(Calls, Next, Items, Rest),
    Events = [Added, Done|Rest].

ep_responses_usage_json(usage(Prompt, Completion, Reasoning, Total, Cache),
                        json([input_tokens-Prompt,
                              output_tokens-Completion,
                              total_tokens-Total,
                              input_tokens_details-
                                  json([cached_tokens-Cache]),
                              output_tokens_details-
                                  json([reasoning_tokens-Reasoning])])).

ep_responses_sse([], []).
ep_responses_sse([Type-Event|Events], Codes) :-
    atom_codes(Type, TypeCodes),
    json_codes(Event, EventCodes),
    append("event: ", TypeCodes, A),
    append(A, "\ndata: ", B),
    append(B, EventCodes, C),
    append(C, "\n\n", D),
    ep_responses_sse(Events, Rest),
    append(D, Rest, Codes).

%% ---- routes ------------------------------------------------------------

ep_models([c, 'c-r0', 'c-r2', 'c-r8',
           cocolog, 'cocolog-r0', 'cocolog-r2', 'cocolog-r8',
           python, 'python-r0', 'python-r2', 'python-r8']).

ep_model_name(c, 'C (C99-C23)').
ep_model_name('c-r0', 'C (r0: plain)').
ep_model_name('c-r2', 'C (r2: two checks)').
ep_model_name('c-r8', 'C (r8: eight checks)').
ep_model_name(cocolog, cocolog).
ep_model_name('cocolog-r0', 'cocolog (r0: plain)').
ep_model_name('cocolog-r2', 'cocolog (r2: two checks)').
ep_model_name('cocolog-r8', 'cocolog (r8: eight checks)').
ep_model_name(python, 'Python 3').
ep_model_name('python-r0', 'Python (r0: plain)').
ep_model_name('python-r2', 'Python (r2: two checks)').
ep_model_name('python-r8', 'Python (r8: eight checks)').

ep_models_reply(Request, reply(200, Headers, Codes)) :-
    ep_cors(Request, Cors),
    append(Cors, ['Content-Type'-'application/json'], Headers),
    ep_int('CODING_ENDPOINT_CONTEXT', 1000000, Context),
    ep_int('CODING_ENDPOINT_MAX_TOKENS', 32768, Output),
    ep_models(Names),
    findall(json([id-Name, object-model, created-0,
                  owned_by-'reasoning-coding',
                  name-Label,
                  context_length-Context,
                  max_output_tokens-Output]),
            ( member(Name, Names), ep_model_name(Name, Label) ),
            Data),
    json_codes(json([object-list, data-Data]), Codes).

ep_health_reply(Request, reply(200, Headers, Codes)) :-
    ep_cors(Request, Cors),
    append(Cors, ['Content-Type'-'application/json'], Headers),
    ep_backend_url(Backend),
    ep_token(Token),
    ep_env('CODING_ENDPOINT_TRACE', '', Trace),
    ep_env('CODING_ENDPOINT_REASONING', 'on', Reasoning),
    (   Token == '' -> Auth = none ; Auth = bearer ),
    ep_models(Names),
    json_codes(json([ok- @(true),
                     service-'reasoning-coding/1.0',
                     models-Names,
                     backend-Backend,
                     reasoning-Reasoning,
                     trace-Trace,
                     auth-Auth]), Codes).

httpd_page('/v1/models', Request, Reply) :-
    Request = request(get, _, _, _, _, _),
    ep_models_reply(Request, Reply).
httpd_page('/v1/models', Request, Reply) :-
    Request = request(options, _, _, _, _, _),
    ep_preflight(Request, Reply).
httpd_page('/v1/models', _, reply(405, ['Allow'-'GET, OPTIONS'], 'method not allowed')).

httpd_page('/health', Request, Reply) :-
    Request = request(get, _, _, _, _, _),
    ep_health_reply(Request, Reply).
httpd_page('/health', Request, Reply) :-
    Request = request(options, _, _, _, _, _),
    ep_preflight(Request, Reply).
httpd_page('/health', _, reply(405, ['Allow'-'GET, OPTIONS'], 'method not allowed')).

httpd_page('/v1/chat/completions', Request, Reply) :-
    Request = request(post, _, _, _, _, _),
    catch(ep_chat(Request, Reply), Error,
          ( format(user_error, "endpoint: ~q~n", [Error]),
            ep_error_reply(Request, 500, 'internal error', Reply) )).
httpd_page('/v1/chat/completions', Request, Reply) :-
    Request = request(options, _, _, _, _, _),
    ep_preflight(Request, Reply).
httpd_page('/v1/chat/completions', _, reply(405, ['Allow'-'POST, OPTIONS'], 'method not allowed')).

httpd_page('/v1/responses', Request, Reply) :-
    Request = request(post, _, _, _, _, _),
    catch(ep_responses(Request, Reply), Error,
          ( format(user_error, "endpoint: ~q~n", [Error]),
            ep_error_reply(Request, 500, 'internal error', Reply) )).
httpd_page('/v1/responses', Request, Reply) :-
    Request = request(options, _, _, _, _, _),
    ep_preflight(Request, Reply).
httpd_page('/v1/responses', _, reply(405, ['Allow'-'POST, OPTIONS'], 'method not allowed')).

