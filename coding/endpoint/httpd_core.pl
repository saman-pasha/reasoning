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

ep_key(Key) :-
    ep_env('CODING_ENDPOINT_KEY_ENV', 'REASONING_API_KEY', Var),
    (   getenv(Var, Key), Key \== ''
    ->  true
    ;   throw(error(ep_no_key(Var), ep_key/1))
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

ep_alias(Model, Alias) :-
    atom(Model),
    downcase_atom(Model, Low),
    (   memberchk(Low, [c, c89, c99, c11, c17, c23])
    ->  Alias = c
    ;   memberchk(Low, [cocolog, 'cocolog-card'])
    ->  Alias = cocolog
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
    ep_limit_checks(Checks0, Max, Limited),
    ep_fill_checks(Min, Max, Limited, Checks).

ep_reasoning_count_from_env(Min, Max) :-
    ep_int('CODING_ENDPOINT_REASONING_MIN', 2, Min),
    ep_int('CODING_ENDPOINT_REASONING_MAX', 2, Max).

ep_reasoning_count(Request, Min, Max) :-
    (   http_header(Request, 'x-coding-reasoning', Value)
    ->  (   memberchk(Value, [off, none, plain, '0'])
        ->  Min = 0, Max = 0
        ;   atom_number(Value, N),
            integer(N),
            N >= 0
        ->  Min = N, Max = N
        ;   ep_reasoning_count_from_env(Min, Max)
        )
    ;   ep_reasoning_count_from_env(Min, Max)
    ).

ep_mode(Request, Title, Mode) :-
    (   Title == true
    ->  Mode = title
    ;   http_header(Request, 'x-coding-reasoning', Value),
        memberchk(Value, [off, none, plain, '0'])
    ->  Mode = plain
    ;   ep_reasoning_on
    ->  Mode = reasoning
    ;   Mode = plain
    ).

ep_limit_checks(Checks, Max, Checks) :-
    Max =< 0,
    !.
ep_limit_checks(Checks, Max, Checks) :-
    length(Checks, N),
    N =< Max,
    !.
ep_limit_checks(Checks, Max, Limited) :-
    length(Limited, Max),
    append(Limited, _, Checks).

ep_fill_checks(Min, _, Checks, Checks) :-
    length(Checks, N),
    N >= Min,
    !.
ep_fill_checks(Min, Max, Checks, Out) :-
    (   Max > 0, length(Checks, N), N >= Max
    ->  Out = Checks
    ;   ep_general_check(Check),
        \+ memberchk(Check, Checks),
        !,
        append(Checks, [Check], Checks1),
        ep_fill_checks(Min, Max, Checks1, Out)
    ;   Out = Checks
    ).

ep_reasoning(Request, Mode, Title, Messages, Guide0, Guide, N, Terms) :-
    (   Mode == reasoning,
        \+ Title,
        ep_task_text(Messages, Text)
    ->  endpoint_reason(Text, Obs, CObs, Terms0),
        append(Obs, CObs, All0),
        ep_unique(All0, All1),
        ep_reasoning_count(Request, Min, Max),
        ep_checks(Min, Max, All1, All),
        length(All, N),
        Terms = Terms0,
        ep_note(All, Note),
        atomic_list_concat([Guide0, Note], Guide)
    ;   Guide = Guide0, N = 0, Terms = 0
    ).

%% ---- backend -----------------------------------------------------------

ep_cap_tokens(Body0, Body) :-
    ep_int('CODING_ENDPOINT_MAX_TOKENS', 8192, Max),
    (   Max > 0
    ->  (   ep_json_get(Body0, max_tokens, N0),
            integer(N0), N0 > 0, N0 =< Max
        ->  Body = Body0
        ;   ep_json_set(Body0, max_tokens, Max, Body)
        )
    ;   Body = Body0
    ).

ep_forward(Body0, Alias, Status, Resp) :-
    ep_backend_model(Alias, Model),
    ep_json_set_field(Body0, model, Model, Body1),
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

ep_delta(Content, ToolCalls, Delta) :-
    (   atom(Content), Content \== ''
    ->  D0 = [role-assistant, content-Content]
    ;   D0 = [role-assistant]
    ),
    (   is_list(ToolCalls), ToolCalls \== []
    ->  ep_indexed(ToolCalls, 0, Indexed),
        append(D0, [tool_calls-Indexed], Delta)
    ;   Delta = D0
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
    ep_backend_model(Alias, Model),
    ep_delta(Content, ToolCalls, Delta),
    ep_chunk(Id, Created, Model, Delta, @(null), Chunk1),
    ep_chunk(Id, Created, Model, [], Finish, Chunk2),
    json_codes(Chunk1, C1),
    json_codes(Chunk2, C2),
    atom_codes('data: ', Prefix),
    atom_codes('data: [DONE]\n\n', Done),
    append(Prefix, C1, L1), append(L1, [10, 10], S1),
    append(Prefix, C2, L2), append(L2, [10, 10], S2),
    append(S1, S2, S3),
    append(S3, Done, Sse).

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
         Stream, MessageCount, ToolCount, Status) :-
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
    json_codes(json([ts-Now, session-Session, project-Project,
                     seconds-Seconds, status-Status, model-Alias,
                     backend-Backend, effort-Effort, mode-Mode,
                     reasoning-N, terms-Terms, stream-StreamJson,
                     messages-MessageCount, tools-ToolCount]), Codes),
    append(Codes, [10], Line),
    catch(append_file_from_codes(File, Line), _, true).

%% ---- the chat route ----------------------------------------------------

ep_chat(Request, Reply) :-
    get_time(Start),
    (   \+ ep_token_ok(Request)
    ->  ep_error_reply(Request, 401,
                       'Authorization: Bearer TOKEN is required', Reply)
    ;   Request = request(_, _, _, _, _, BodyCodes),
        (   catch(json_parse(BodyCodes, Body), _, fail)
        ->  ep_chat_body(Request, Body, Start, Reply)
        ;   ep_error_reply(Request, 400, 'the body is not JSON', Reply)
        )
    ).

ep_chat_body(Request, Body, Start, Reply) :-
    (   ep_json_get(Body, model, Model0),
        ep_alias(Model0, Alias),
        ep_messages(Body, Messages)
    ->  (   ep_guide(Alias, Guide0)
        ->  (   ep_title_request(Messages)
            ->  Title = true
            ;   Title = false
            ),
            ep_mode(Request, Title, Mode),
            ep_reasoning(Request, Mode, Title, Messages, Guide0, Guide, N, Terms),
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
            (   ep_json_get(Body1, reasoning_effort, Effort)
            ->  true
            ;   Effort = '-'
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
            ep_trace(Request, Start, Alias, BackendModel, Effort, Mode,
                     N, TermCount, Stream, MessageCount, ToolCount, Status)
        ;   ep_error_reply(Request, 500,
                           'the language guide is missing', Reply)
        )
    ;   ep_error_reply(Request, 400,
                       'model and messages are required', Reply)
    ).

%% ---- routes ------------------------------------------------------------

ep_models_reply(Request, reply(200, Headers, Codes)) :-
    ep_cors(Request, Cors),
    append(Cors, ['Content-Type'-'application/json'], Headers),
    ep_int('CODING_ENDPOINT_CONTEXT', 1000000, Context),
    ep_int('CODING_ENDPOINT_MAX_TOKENS', 8192, Output),
    json_codes(json([object-list,
                     data-[json([id-c, object-model, created-0,
                                 owned_by-'reasoning-coding',
                                 name-'C (C99-C23)',
                                 context_length-Context,
                                 max_output_tokens-Output]),
                           json([id-cocolog, object-model, created-0,
                                 owned_by-'reasoning-coding',
                                 name-cocolog,
                                 context_length-Context,
                                 max_output_tokens-Output])]]),
               Codes).

ep_health_reply(Request, reply(200, Headers, Codes)) :-
    ep_cors(Request, Cors),
    append(Cors, ['Content-Type'-'application/json'], Headers),
    ep_backend_url(Backend),
    ep_token(Token),
    ep_env('CODING_ENDPOINT_TRACE', '', Trace),
    ep_env('CODING_ENDPOINT_REASONING', 'on', Reasoning),
    (   Token == '' -> Auth = none ; Auth = bearer ),
    json_codes(json([ok- @(true),
                     service-'reasoning-coding/1.0',
                     models-[c, cocolog],
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

