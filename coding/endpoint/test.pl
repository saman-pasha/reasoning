%% coding/endpoint/test.pl -- the httpd endpoint's local checks.
%%
%%     COCOLOG_LIBRARY="$PWD/..:$PWD/../cocolog/library" \
%%         ../cocolog/cocolog -s coding/endpoint/test.pl
%%
%% No model and no network: the reply constructors, the token guard, the
%% guide merge, the SSE synthesis and the reasoning reading. The endpoint
%% itself is httpd.pl; this file imports its predicates and never starts a
%% server.

:- use_module(library(process)).
:- use_module(library(os)).
:- use_module(library(json)).
:- use_module('coding/endpoint/httpd_core.pl',
              [ ep_models_reply/2,
                ep_health_reply/2,
                ep_token_ok/1,
                ep_cors/2,
                ep_add_guide/3,
                ep_task_text/2,
                ep_reasoning/8,
                ep_reasoning/9,
                ep_reasoning_setting/3,
                ep_reasoning_count/3,
                ep_mode/3,
                ep_alias/2,
                ep_guide/2,
                ep_checks/2,
                ep_sse/3,
                ep_usage/2,
                ep_usage_json/2,
                ep_usage_add/3,
                ep_reply_usage/3,
                ep_reply_text/2,
                ep_merge_continuation/3,
                ep_text_dangles/1,
                ep_reply_dangles/1,
                ep_continue_messages/3,
                ep_continue_on/0,
                ep_continue_limit/1,
                ep_default_effort/2,
                ep_json_get/3,
                ep_loop_verdict/2,
                ep_tool_signature/3,
                ep_responses_chat_body/2,
                ep_responses_chat_body/3,
                ep_responses_events/4,
                ep_responses_events/5,
                ep_responses_sse/2,
                ep_anthropic_body/2,
                ep_anthropic_reply/4,
                ep_backend_url/1,
                ep_backend_timeout/1,
                ep_backend_model/2,
                ep_key/1
              ]).
:- use_module('coding/endpoint/reasoning_core.pl',
              [ endpoint_reason/4 ]).

main :-
    setenv('CODING_ENDPOINT_TOKEN', 'test-token'),
    test_models,
    test_health,
    test_token,
    test_cors,
    test_body_json,
    test_guard,
    test_task_text,
    test_usage,
    test_effort_default,
    test_loop_guard,
    test_responses,
    test_responses_memo,
    test_anthropic,
    test_sse,
    test_sse_usage,
    test_sse_tools,
    test_reasoning,
    test_c_reasoning,
    test_reasoning_headers,
    test_model_suffix,
    test_python,
    test_check_cap,
    test_zero_checks,
    test_backend_key,
    test_defaults,
    test_continue,
    unsetenv('CODING_ENDPOINT_TOKEN'),
    checks_done.

test_models :-
    ep_models_reply(request(get, '/v1/models', [], http(1, 1), [], []),
                    reply(200, _, Codes)),
    atom_codes(Text, Codes),
    (   sub_atom(Text, _, _, _, '"id":"c-r8"'),
        sub_atom(Text, _, _, _, '"id":"cocolog-r0"'),
        sub_atom(Text, _, _, _, '"id":"python-r8"'),
        sub_atom(Text, _, _, _, '"name":"Python (r8: eight checks)"'),
        sub_atom(Text, _, _, _, '"context_length":1000000'),
        sub_atom(Text, _, _, _, '"max_output_tokens":32768')
    ->  Got = all
    ;   Got = missing
    ),
    check('models and limits', Got, all).

test_health :-
    ep_health_reply(request(get, '/health', [], http(1, 1), [], []),
                    reply(200, _, Codes)),
    atom_codes(Text, Codes),
    (   sub_atom(Text, _, _, _, '"reasoning":"on"'),
        sub_atom(Text, _, _, _, '"auth":"bearer"')
    ->  Got = healthy
    ;   Got = wrong
    ),
    check('health says reasoning and bearer', Got, healthy).

test_token :-
    Good = request(post, '/v1/chat/completions', [], http(1, 1),
                   [authorization-'Bearer test-token'], []),
    Bad = request(post, '/v1/chat/completions', [], http(1, 1),
                  [authorization-'Bearer wrong'], []),
    ( ep_token_ok(Good) -> G = yes ; G = no ),
    ( ep_token_ok(Bad) -> B = yes ; B = no ),
    check('the bearer token is accepted', G, yes),
    check('another token is refused', B, no),
    setenv('CODING_ENDPOINT_TOKEN', 'test-token, second-token'),
    Second = request(post, '/v1/chat/completions', [], http(1, 1),
                     [authorization-'Bearer second-token'], []),
    ( ep_token_ok(Second) -> S = yes ; S = no ),
    ( ep_token_ok(Bad) -> B2 = yes ; B2 = no ),
    check('a second listed token is accepted', S, yes),
    check('a token not listed is still refused', B2, no),
    setenv('CODING_ENDPOINT_TOKEN', 'test-token'),
    unsetenv('CODING_ENDPOINT_TOKEN'),
    ( ep_token_ok(Bad) -> Open = open ; Open = closed ),
    check('no token means no guard', Open, open),
    setenv('CODING_ENDPOINT_TOKEN', 'test-token').

test_cors :-
    Allowed = request(post, '/v1/chat/completions', [], http(1, 1),
                      [origin-'http://localhost:3000'], []),
    Other = request(post, '/v1/chat/completions', [], http(1, 1),
                    [origin-'http://example.com'], []),
    ep_cors(Allowed, AllowedHeaders),
    ep_cors(Other, OtherHeaders),
    (   memberchk('Access-Control-Allow-Origin'-'http://localhost:3000',
                  AllowedHeaders)
    ->  Yes = yes
    ;   Yes = no
    ),
    (   memberchk('Access-Control-Allow-Origin'-_, OtherHeaders)
    ->  No = present
    ;   No = absent
    ),
    check('an allowlisted origin is allowed', Yes, yes),
    check('another origin is not', No, absent).

test_body_json :-
    Nul = "{\"model\":\"cocolog\",\"messages\":[{\"role\":\"user\",\"content\":\"x\\u0000y\"}]}",
    ep_body_json_codes(Nul, Safe),
    (   codes_contains(Safe, [92, 117, 70, 70, 70, 68])
    ->  Fixed = yes
    ;   Fixed = no
    ),
    check('a NUL escape becomes the replacement character', Fixed, yes),
    (   catch(json_parse(Safe, json(Pairs)), _, fail),
        memberchk(messages-Messages, Pairs),
        Messages = [json(Message)],
        memberchk(content-Content, Message),
        atom_codes(Content, ContentCodes),
        codes_contains(ContentCodes, [65533])
    ->  Parsed = yes
    ;   Parsed = no
    ),
    check('the sanitized body parses', Parsed, yes),
    Plain = "{\"model\":\"x\"}",
    ep_body_json_codes(Plain, Same),
    check('a body with no NUL is unchanged', Same, Plain).

codes_contains(Codes, Seq) :-
    append(_, Rest, Codes),
    append(Seq, _, Rest),
    !.

test_guard :-
    ep_add_guide([json([role-system, content-agent])], 'GUIDE',
                 [json(Pairs)]),
    memberchk(content-Content, Pairs),
    atomic_list_concat(['agent', '\n\n', 'GUIDE'], Want),
    check('the guide follows the system prompt', Content, Want),
    ep_add_guide([json([role-user, content-hi])], 'GUIDE', Added),
    (   Added = [json(First), json([role-user, content-hi])],
        memberchk(role-system, First),
        memberchk(content-'GUIDE', First)
    ->  Got = prepended
    ;   Got = wrong
    ),
    check('a missing system prompt gets one', Got, prepended).

test_task_text :-
    Messages = [ json([role-system, content-agent]),
                 json([role-user, content-task]),
                 json([role-user, content-tool-result])
               ],
    ep_task_text(Messages, Text),
    check('the first user turn is the task', Text, task).

test_usage :-
    Reply = json([id-test,
                  created-1,
                  choices-[json([index-0,
                                 message-json([role-assistant, content-ok]),
                                 finish_reason-stop])],
                  usage-json([prompt_tokens-120,
                              completion_tokens-45,
                              total_tokens-165,
                              prompt_cache_hit_tokens-64,
                              completion_tokens_details-
                                  json([reasoning_tokens-30])])]),
    json_codes(Reply, Codes),
    ep_usage(Codes, Usage),
    ep_usage_json(Usage, Pairs),
    check('the trace reads token usage', Usage, usage(120, 45, 30, 165, 64)),
    check('the trace writes token usage', Pairs,
          [prompt_tokens-120, completion_tokens-45, reasoning_tokens-30,
           total_tokens-165, cache_hit_tokens-64]),
    json_codes(json([usage-json([prompt_tokens-7,
                                 completion_tokens-3,
                                 prompt_tokens_details-
                                     json([cached_tokens-2])])]),
               Codes2),
    ep_usage(Codes2, Fallback),
    check('a provider that names cached tokens another way', Fallback,
          usage(7, 3, 0, 10, 2)),
    json_codes(json([id-test]), EmptyCodes),
    ep_usage(EmptyCodes, None),
    check('a reply without usage is all zero', None, usage(0, 0, 0, 0, 0)).

test_effort_default :-
    ep_default_effort(json([model-c]), Omitted),
    ep_json_get(Omitted, reasoning_effort, E1),
    check('an omitted effort becomes none', E1, none),
    ep_default_effort(json([reasoning_effort-high]), Chosen),
    ep_json_get(Chosen, reasoning_effort, E2),
    check('a chosen effort is kept', E2, high),
    ep_default_effort(json([reasoning_effort-'']), Blank),
    ep_json_get(Blank, reasoning_effort, E3),
    check('a blank effort becomes none', E3, none).

test_loop_guard :-
    ep_test_calls(16, 848, Sixteen),
    ep_loop_verdict([json([role-assistant, tool_calls-Sixteen])],
                    Verdict16),
    check('sixteen repeated commands are a loop', Verdict16,
          repeat('shell:cat /tmp/names#.pl', 16, 16)),
    ep_test_calls(15, 848, Fifteen),
    ep_loop_verdict([json([role-assistant, tool_calls-Fifteen])],
                    Verdict15),
    check('fifteen repeated commands are allowed', Verdict15, ok),
    ep_test_edits(18, 1, Edits),
    ep_loop_verdict([json([role-assistant, tool_calls-Edits])], EditVerdict),
    check('eighteen different edits of one file are allowed',
          EditVerdict, ok),
    ep_test_same_edits(16, SameEdits),
    ep_loop_verdict([json([role-assistant, tool_calls-SameEdits])],
                    SameVerdict),
    (   SameVerdict = repeat(_, 16, 16)
    ->  Repeated = yes
    ;   Repeated = no
    ),
    check('sixteen identical edits are a loop', Repeated, yes),
    ep_tool_signature(read, '{"path":"/tmp/x.pl"}', ReadSignature),
    check('a path-only tool is keyed by its path', ReadSignature,
          'read:/tmp/x.pl'),
    ep_test_stdin(16, '', Waits),
    ep_loop_verdict([json([role-assistant, tool_calls-Waits])], WaitVerdict),
    check('PTY polls with no input are not a loop', WaitVerdict, ok),
    ep_test_stdin(16, 'y', Sends),
    ep_loop_verdict([json([role-assistant, tool_calls-Sends])], SendVerdict),
    (   SendVerdict = repeat(_, 16, 16)
    ->  Sent = yes
    ;   Sent = no
    ),
    check('sixteen identical PTY writes are a loop', Sent, yes).

ep_test_edits(0, _, []).
ep_test_edits(N, Start,
              [json([id-Id, type-function,
                     function-json([name-edit, arguments-Arguments])])|Rest]) :-
    N > 0,
    format(atom(Id), 'edit~w', [N]),
    format(atom(Arguments),
           '{"path":"/tmp/strategy.pl","oldString":"old ~w","newString":"new ~w"}',
           [Start, Start]),
    N1 is N - 1,
    Start1 is Start + 1,
    ep_test_edits(N1, Start1, Rest).

ep_test_same_edits(0, []).
ep_test_same_edits(N,
                   [json([id-Id, type-function,
                          function-json([name-edit,
                                         arguments-'{"path":"/tmp/strategy.pl","oldString":"same","newString":"same too"}'])])|Rest]) :-
    N > 0,
    format(atom(Id), 'same~w', [N]),
    N1 is N - 1,
    ep_test_same_edits(N1, Rest).

ep_test_stdin(0, _, []).
ep_test_stdin(N, Chars,
              [json([id-Id, type-function,
                     function-json([name-'write_stdin',
                                    arguments-Arguments])])|Rest]) :-
    N > 0,
    format(atom(Id), 'stdin~w', [N]),
    format(atom(Arguments),
           '{"session_id": ~w, "chars": "~w", "yield_time_ms": 30000, "max_output_tokens": 20000}',
           [N, Chars]),
    N1 is N - 1,
    ep_test_stdin(N1, Chars, Rest).

%% ---- the Responses route ----------------------------------------------

test_responses :-
    Input = json([model-'cocolog-r0',
                  input-[json([type-message, role-developer,
                               content-[json([type-input_text,
                                              text-developer])]]),
                         json([type-message, role-user,
                               content-[json([type-input_text,
                                              text-hi])]]),
                         json([type-function_call, call_id-'call_1',
                               name-shell, arguments-'{"cmd":"echo hi"}']),
                         json([type-function_call_output,
                               call_id-'call_1', output-hi])],
                  tools-[json([type-function, name-shell,
                               description-run,
                               parameters-json([type-object])]),
                         json([type-web_search])],
                  reasoning-json([effort-high])]),
    ep_responses_chat_body(Input, Chat),
    ep_json_get(Chat, messages, Messages),
    findall(Role, ( member(Message, Messages),
                    ep_json_get(Message, role, Role) ), Roles),
    check('responses messages keep their order', Roles,
          [system, user, assistant, tool]),
    ep_json_get(Chat, tools, Tools),
    length(Tools, ToolCount),
    check('responses tools are functions alone', ToolCount, 1),
    ep_json_get(Chat, reasoning_effort, Effort),
    check('a responses effort reaches the chat body', Effort, high),
    ep_responses_chat_body('session-with-no-memo', Input, NoMemoChat),
    ep_json_get(NoMemoChat, messages, NoMemoMessages),
    length(NoMemoMessages, NoMemoCount),
    check('a session with no memo still translates', NoMemoCount, 4),
    (   member(NoMemoMessage, NoMemoMessages),
        ep_json_get(NoMemoMessage, role, assistant),
        ep_json_get(NoMemoMessage, reasoning_content, '')
    ->  EmptyField = yes
    ;   EmptyField = no
    ),
    check('a thinking-mode assistant keeps an empty reasoning field',
          EmptyField, yes),
    Reply = json([choices-[json([message-json([role-assistant,
                                               content-'OK'])])],
                  usage-json([prompt_tokens-3, completion_tokens-1,
                              total_tokens-4])]),
    json_codes(Reply, Codes),
    ep_responses_events(Codes, 'cocolog-r0', Events, Response),
    (   member('response.output_text.delta'-Event, Events),
        ep_json_get(Event, delta, 'OK')
    ->  Delta = yes
    ;   Delta = no
    ),
    check('a responses stream carries the text delta', Delta, yes),
    (   member('response.completed'-Done, Events),
        ep_json_get(Done, response, DoneResponse),
        ep_json_get(DoneResponse, status, completed)
    ->  Completed = yes
    ;   Completed = no
    ),
    check('a responses stream completes', Completed, yes),
    ep_json_get(Response, object, Object),
    check('the final reply is a response object', Object, response),
    ep_responses_sse(Events, SseCodes),
    atom_codes(Sse, SseCodes),
    (   sub_atom(Sse, _, _, _, 'event: response.created'),
        sub_atom(Sse, _, _, _, 'event: response.completed')
    ->  Framed = yes
    ;   Framed = no
    ),
    check('responses events are framed as SSE', Framed, yes),
    CallReply = json([choices-[json([message-json([role-assistant,
                                                   content- @(null),
                                                   tool_calls-[json([id-'call_9',
                                                                     type-function,
                                                                     function-json([name-shell,
                                                                                    arguments-'{}'])])]])])],
                      usage-json([prompt_tokens-3, completion_tokens-1,
                                  total_tokens-4])]),
    json_codes(CallReply, CallCodes),
    ep_responses_events(CallCodes, 'cocolog-r0', CallEvents, _),
    (   member('response.output_item.done'-CallEvent, CallEvents),
        ep_json_get(CallEvent, item, CallItem),
        ep_json_get(CallItem, type, function_call),
        ep_json_get(CallItem, call_id, 'call_9')
    ->  Call = yes
    ;   Call = no
    ),
    check('a chat tool call becomes a function_call item', Call, yes).

%% DeepSeek's thinking mode wants the last reasoning back; Codex drops a
%% reasoning item, so the endpoint remembers it and rebuilds it.
test_responses_memo :-
    MemoMessage = json([role-assistant,
                        content-thinking,
                        reasoning_content-because,
                        tool_calls-[json([id-'call_7',
                                          type-function,
                                          function-json([name-shell,
                                                         arguments-'{}'])])]]),
    Reply = json([choices-[json([message-MemoMessage])],
                  usage-json([prompt_tokens-3, completion_tokens-1,
                              total_tokens-4])]),
    json_codes(Reply, Codes),
    ep_responses_events('memo-session', Codes, 'c-r0', _Events, _),
    Input = json([model-'c-r0',
                  input-[json([type-message, role-user,
                               content-[json([type-input_text, text-go])]]),
                         json([type-function_call, call_id-'call_7',
                               name-shell, arguments-'{}']),
                         json([type-function_call_output, call_id-'call_7',
                               output-ok]),
                         json([type-message, role-assistant,
                               content-[json([type-output_text,
                                              text-thinking])]])]]),
    ep_responses_chat_body('memo-session', Input, Chat),
    ep_json_get(Chat, messages, Messages),
    (   member(Message, Messages),
        ep_json_get(Message, role, assistant),
        ep_json_get(Message, tool_calls, _),
        ep_json_get(Message, reasoning_content, because)
    ->  CallsMemo = yes
    ;   CallsMemo = no
    ),
    check('the reasoning of tool calls is put back', CallsMemo, yes),
    (   member(TextMessage, Messages),
        ep_json_get(TextMessage, role, assistant),
        ep_json_get(TextMessage, content, thinking),
        ep_json_get(TextMessage, reasoning_content, because)
    ->  TextMemo = yes
    ;   TextMemo = no
    ),
    check('the reasoning of an assistant text is put back', TextMemo, yes).

%% ---- the Anthropic backend -------------------------------------------

test_anthropic :-
    Chat = json([model-x, max_tokens-100,
                 messages-[json([role-system, content-sys]),
                           json([role-user, content-go]),
                           json([role-assistant, content-'',
                                 tool_calls-[json([id-'call_1',
                                                   type-function,
                                                   function-json([name-shell,
                                                                  arguments-'{"cmd":"echo hi"}'])])]]),
                           json([role-tool, tool_call_id-'call_1',
                                 content-hi])],
                 tools-[json([type-function,
                              function-json([name-shell, description-run,
                                             parameters-json([type-object])])])],
                 tool_choice-auto]),
    ep_anthropic_body(Chat, Anthropic),
    ep_json_get(Anthropic, system, System),    check('an Anthropic request lifts the system prompt', System, sys),
    ep_json_get(Anthropic, messages, Messages),
    findall(Role, (member(Message, Messages),
                    ep_json_get(Message, role, Role)), Roles),
    check('an Anthropic request keeps user, assistant and tool result',
          Roles, [user, assistant, user]),
    (   member(Assistant, Messages),
        ep_json_get(Assistant, role, assistant),
        ep_json_get(Assistant, content, [json(BlockPairs)|_]),
        memberchk(type-tool_use, BlockPairs),
        memberchk(input-json(InputPairs), BlockPairs),
        memberchk(cmd-'echo hi', InputPairs)
    ->  InputOk = yes
    ;   InputOk = no
    ),
    check('an Anthropic tool call carries an input object', InputOk, yes),
    (   member(ToolResult, Messages),
        ep_json_get(ToolResult, role, user),
        ep_json_get(ToolResult, content, [json(ResultPairs)]),
        memberchk(type-tool_result, ResultPairs),
        memberchk(tool_use_id-'call_1', ResultPairs)
    ->  ResultOk = yes
    ;   ResultOk = no
    ),
    check('an Anthropic tool result answers its call', ResultOk, yes),
    Reply = json([id-'msg_1', model-x,
                  content-[json([type-text, text-ok]),
                           json([type-tool_use, id-'call_2',
                                 name-shell,
                                 input-json([cmd-'echo hi'])])],
                  stop_reason-tool_use,
                  usage-json([input_tokens-10, output_tokens-5,
                              cache_read_input_tokens-2,
                              output_tokens_details-
                                  json([thinking_tokens-1])])]),
    json_codes(Reply, Codes),
    ep_anthropic_reply(200, Codes, Status, ChatCodes),
    check('an Anthropic reply has status 200', Status, 200),
    json_parse(ChatCodes, json(OutPairs)),
    memberchk(choices-[json(Choice)|_], OutPairs),
    memberchk(message-json(Message), Choice),
    ep_json_get(json(Message), content, ok),
    ep_json_get(json(Message), tool_calls, [json(Call)|_]),
    memberchk(function-json(Function), Call),
    memberchk(name-shell, Function),
    memberchk(arguments-Arguments, Function),
    atom(Arguments),
    check('an Anthropic reply becomes a chat reply', ok, ok),
    memberchk(finish_reason-tool_calls, Choice),
    memberchk(usage-json(Usage), OutPairs),
    memberchk(prompt_tokens-12, Usage),
    memberchk(completion_tokens-5, Usage),
    memberchk(total_tokens-17, Usage),
    memberchk(prompt_cache_hit_tokens-2, Usage),
    check('an Anthropic reply carries its usage', Usage,
          [prompt_tokens-12, completion_tokens-5, total_tokens-17,
           prompt_cache_hit_tokens-2,
           completion_tokens_details-json([reasoning_tokens-1])]),
    !.

ep_test_calls(0, _, []).
ep_test_calls(N, Start, [json([id-Id, type-function,
                              function-json([name-shell, arguments-Arguments])])|Rest]) :-
    N > 0,
    format(atom(Id), 'call~w', [N]),
    format(atom(Arguments), '{"command":"cat /tmp/names~w.pl"}', [Start]),
    N1 is N - 1,
    Start1 is Start + 1,
    ep_test_calls(N1, Start1, Rest).

test_sse :-
    Reply = json([id-test,
                  created-1,
                  choices-[json([index-0,
                                 message-json([role-assistant, content-ok]),
                                 finish_reason-stop])]]),
    json_codes(Reply, Codes),
    ep_sse(Codes, c, Sse),
    atom_codes(Text, Sse),
    (   sub_atom(Text, 0, 6, _, 'data: '),
        sub_atom(Text, _, _, _, '"content":"ok"'),
        sub_atom(Text, _, _, _, '"finish_reason":"stop"'),
        sub_atom(Text, _, 14, 0, 'data: [DONE]\n\n')
    ->  Got = sse
    ;   Got = wrong
    ),
    check('a non-stream reply becomes SSE', Got, sse).

test_sse_usage :-
    Reply = json([id-test,
                  created-1,
                  choices-[json([index-0,
                                 message-json([role-assistant, content-ok,
                                               reasoning_content-think]),
                                 finish_reason-stop])],
                  usage-json([prompt_tokens-120,
                              completion_tokens-45,
                              total_tokens-165,
                              prompt_cache_hit_tokens-64,
                              completion_tokens_details-
                                  json([reasoning_tokens-30])])]),
    json_codes(Reply, Codes),
    ep_sse(Codes, c, Sse),
    atom_codes(Text, Sse),
    (   sub_atom(Text, _, _, _, '"choices":[]'),
        sub_atom(Text, _, _, _, '"usage":{'),
        sub_atom(Text, _, _, _, '"prompt_tokens":120'),
        sub_atom(Text, _, _, _, '"completion_tokens":45'),
        sub_atom(Text, _, _, _, '"total_tokens":165'),
        sub_atom(Text, _, _, _, '"cached_tokens":64'),
        sub_atom(Text, _, _, _, '"reasoning_content":"think"'),
        sub_atom(Text, _, _, _, '"reasoning_tokens":30')
    ->  Got = usage
    ;   Got = wrong
    ),
    check('the SSE bridge sends usage before DONE', Got, usage).

test_sse_tools :-
    Reply = json([id-test,
                  created-1,
                  choices-[json([index-0,
                                 message-json(
                                     [ role-assistant,
                                       content- @(null),
                                       tool_calls-
                                           [ json([id-call1,
                                                   type-function,
                                                   function-json(
                                                       [name-write,
                                                        arguments-'{}'])]) ]
                                     ]),
                                 finish_reason-tool_calls])]]),
    json_codes(Reply, Codes),
    ep_sse(Codes, c, Sse),
    atom_codes(Text, Sse),
    (   sub_atom(Text, _, _, _, '"tool_calls"'),
        sub_atom(Text, _, _, _, '"index":0'),
        sub_atom(Text, _, _, _, '"name":"write"'),
        sub_atom(Text, _, _, _, '"finish_reason":"tool_calls"')
    ->  Got = tools
    ;   Got = wrong
    ),
    check('tool calls survive the SSE bridge', Got, tools).

test_reasoning :-
    endpoint_reason(
        'Write a program that reads a line and prints its words sorted.',
        Obs, _, _),
    (   Obs \== [],
        member(Obligation, Obs),
        sub_atom(Obligation, _, _, _, 'words')
    ->  Got = read
    ;   Got = nothing
    ),
    check('the reasoner reads the request', Got, read).

test_c_reasoning :-
    Messages = [json([role-user, content-'Write hello.c that prints hello.'])],
    Request = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_reasoning_setting(Request, c, Setting),
    ep_mode(false, Setting, Mode),
    ep_reasoning(Setting, Mode, false, Messages, 'GUIDE', Guide, N, _),
    (   Mode == reasoning,
        N =:= 2,
        sub_atom(Guide, _, _, _, 'Reasoning pre-pass'),
        sub_atom(Guide, _, _, _, 'do not assume more input')
    ->  Got = checks
    ;   Got = wrong
    ),
    check('the C model gets exactly two reasoning checks', Got, checks).

test_reasoning_headers :-
    Messages = [json([role-user, content-'Write hello.c that prints hello.'])],
    Off = request(post, '/v1/chat/completions', [], http(1, 1),
                  ['x-coding-reasoning'-'0'], []),
    Eight = request(post, '/v1/chat/completions', [], http(1, 1),
                    ['x-coding-reasoning'-'8'], []),
    ep_reasoning_setting(Off, cocolog, OffSetting),
    ep_mode(false, OffSetting, OffMode),
    ep_reasoning(OffSetting, OffMode, false, Messages, 'GUIDE', _, OffN, _),
    ep_reasoning_setting(Eight, cocolog, EightSetting),
    ep_mode(false, EightSetting, EightMode),
    ep_reasoning(EightSetting, EightMode, false, Messages, 'GUIDE', _, EightN, _),
    check('x-coding-reasoning 0 is plain', OffMode-OffN, plain-0),
    check('x-coding-reasoning 8 is eight checks', EightMode-EightN,
          reasoning-8).

test_model_suffix :-
    Empty = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_alias('cocolog-r8', Alias),
    ep_reasoning_setting(Empty, 'cocolog-r8', Setting),
    ep_mode(false, Setting, Mode),
    check('cocolog-r8 selects cocolog', Alias, cocolog),
    check('cocolog-r8 asks for eight checks', Mode-Setting,
          reasoning-count(8)).

test_python :-
    Empty = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_alias('python-r8', Alias),
    ep_reasoning_setting(Empty, 'python-r8', Setting),
    ep_mode(false, Setting, Mode),
    check('python-r8 selects python', Alias, python),
    check('python-r8 asks for eight checks', Mode-Setting,
          reasoning-count(8)),
    ep_guide(python, Guide),
    (   sub_atom(Guide, _, _, _, 'Python 3')
    ->  GuideRead = python
    ;   GuideRead = wrong
    ),
    check('python has its own guide', GuideRead, python),
    Messages = [json([role-user,
                      content-'Write a Python program that reads lines and sorts them.'])],
    ep_reasoning(python, count(2), reasoning, false, Messages, 'GUIDE',
                 Reasoned, N, _),
    (   N =:= 2,
        sub_atom(Reasoned, _, _, _, 'sys.stdin')
    ->  ReasonRead = python
    ;   ReasonRead = wrong
    ),
    check('python reasoning uses python checks', ReasonRead, python).

test_check_cap :-
    ep_checks([first, second, third], Checks),
    check('a longer reading is capped at two', Checks, [first, second]).

test_zero_checks :-
    Empty = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_reasoning_setting(Empty, 'c-r0', Setting),
    ep_mode(false, Setting, Mode),
    check('c-r0 without a header is plain', Mode-Setting, plain-off),
    ep_checks(0, 0, [first, second], Checks),
    check('a zero maximum keeps no checks', Checks, []).

test_backend_key :-
    setenv('CODING_ENDPOINT_KEY_ENV', 'test-backend-key'),
    ep_key(Key),
    check('the backend key is read from CODING_ENDPOINT_KEY_ENV',
          Key, 'test-backend-key'),
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    (   catch(ep_key(_), error(ep_no_key(_), _), true)
    ->  check('an absent backend key is refused', yes, yes)
    ;   check('an absent backend key is refused', no, yes)
    ).

test_continue :-
    A = 'Direct `p->a_` works. The failure is specific to `&p->a_` passed as a parameter, so I’m narrowing that case.',
    ( ep_text_dangles(A) -> A1 = yes ; A1 = no ),
    check('a narrowing preamble dangles', A1, yes),
    B = 'Docs updated and C/C++ builds verified. Running the full ccllib gate to confirm GREEN with the atomic C++23 skip.',
    ( ep_text_dangles(B) -> B1 = yes ; B1 = no ),
    check('a running-gate preamble dangles', B1, yes),
    C = 'The gate is GREEN: 28 programs in all three runs, 175 refusals, 19 standalone. I’m committing and pushing 1d.',
    ( ep_text_dangles(C) -> C1 = yes ; C1 = no ),
    check('a committing preamble dangles', C1, yes),
    D = 'Done. All tests pass and the fix is committed.',
    ( ep_text_dangles(D) -> D1 = yes ; D1 = no ),
    check('a final answer does not dangle', D1, no),
    E = 'The command I’m running takes ten seconds.',
    ( ep_text_dangles(E) -> E1 = yes ; E1 = no ),
    check('a relative clause does not start a sentence', E1, no),
    F = 'Testing shows the fix works.',
    ( ep_text_dangles(F) -> F1 = yes ; F1 = no ),
    check('a gerund with a finite verb is a statement', F1, no),
    G = 'The flow gate is green. I’ll leave the remaining choice to you.',
    ( ep_text_dangles(G) -> G1 = yes ; G1 = no ),
    check('an offer does not dangle', G1, no),
    H = 'Let me check the compiler source.',
    ( ep_text_dangles(H) -> H1 = yes ; H1 = no ),
    check('a let-me preamble dangles', H1, yes),
    I = 'I need to know whether the test passes.',
    ( ep_text_dangles(I) -> I1 = yes ; I1 = no ),
    check('a need to know does not dangle', I1, no),
    J = 'The C++23 AST itself is right; the failure is in the C++ desugaring of &p->a_. Comparing the two language paths now.',
    ( ep_text_dangles(J) -> J1 = yes ; J1 = no ),
    check('a comparing sentence dangles', J1, yes),
    K = 'I’m checking the parser. The fix is ready.',
    ( ep_text_dangles(K) -> K1 = yes ; K1 = no ),
    check('an early preamble before a final answer does not dangle', K1, no),
    L = 'Checking the AST, I found the bug. The fix is in the desugaring.',
    ( ep_text_dangles(L) -> L1 = yes ; L1 = no ),
    check('a gerund in an earlier sentence does not dangle', L1, no),
    M = 'Comparing the paths shows the difference.',
    ( ep_text_dangles(M) -> M1 = yes ; M1 = no ),
    check('a comparing statement does not dangle', M1, no),
    N = 'Comparing the two paths.',
    ( ep_text_dangles(N) -> N1 = yes ; N1 = no ),
    check('a bare comparing phrase dangles', N1, yes),
    O = 'The AST is right; comparing the paths now.',
    ( ep_text_dangles(O) -> O1 = yes ; O1 = no ),
    check('a semicolon starts the last clause', O1, yes),
    continue_reply('I’m checking the parser now.', [], stop, Reply),
    ( ep_reply_dangles(Reply) -> R1 = yes ; R1 = no ),
    check('a text-only reply dangles', R1, yes),
    continue_reply('I’m checking the parser now.', [continue_call], stop, ReplyTool),
    ( ep_reply_dangles(ReplyTool) -> R2 = yes ; R2 = no ),
    check('a reply with a tool call does not dangle', R2, no),
    continue_reply('I’m checking the parser now.', [], length, ReplyLong),
    ( ep_reply_dangles(ReplyLong) -> R3 = yes ; R3 = no ),
    check('a truncated reply does not dangle', R3, no),
    Body = json([model-c, messages-[json([role-user, content-'Fix it.'])]]),
    (   ep_continue_messages(Body, Reply, Body1),
        ep_json_get(Body1, messages, Messages1),
        length(Messages1, Count),
        append(_, [Last], Messages1),
        ep_json_get(Last, role, LastRole)
    ->  check('a continuation keeps the reply and adds a nudge',
              Count-LastRole, 3-user)
    ;   check('a continuation keeps the reply and adds a nudge',
              none, 3-user)
    ),
    ep_usage_add(usage(10, 2, 1, 12, 8), usage(20, 3, 2, 23, 18),
                 usage(P, C0, R0, T0, H0)),
    check('a continued usage is summed', P-C0-R0-T0-H0, 30-5-3-35-26),
    continue_reply('I’m running the gate now.', [], stop, Preamble),
    continue_reply('The gate is green.', [], stop, Finished),
    ep_merge_continuation(Preamble, Finished, Merged),
    ep_reply_text(Merged, MergedText),
    check('the preamble and the continuation are one message', MergedText,
          'I’m running the gate now.\n\nThe gate is green.'),
    continue_reply('I’m running the gate now.', [continue_call], stop,
                   ToolReply),
    ep_merge_continuation(Preamble, ToolReply, MergedTool),
    ep_reply_text(MergedTool, MergedToolText),
    check('a tool call keeps the preamble as its text', MergedToolText,
          'I’m running the gate now.'),
    unsetenv('CODING_ENDPOINT_CONTINUE'),
    ( ep_continue_on -> On = yes ; On = no ),
    check('the continuation guard is on by default', On, yes),
    setenv('CODING_ENDPOINT_CONTINUE', 'off'),
    ( ep_continue_on -> Off = yes ; Off = no ),
    check('CODING_ENDPOINT_CONTINUE=off disables it', Off, no),
    unsetenv('CODING_ENDPOINT_CONTINUE'),
    ep_continue_limit(Default),
    check('the continuation limit is two', Default, 2),
    setenv('CODING_ENDPOINT_CONTINUE_LIMIT', '5'),
    ep_continue_limit(Set),
    check('CODING_ENDPOINT_CONTINUE_LIMIT is read', Set, 5),
    unsetenv('CODING_ENDPOINT_CONTINUE_LIMIT').

continue_reply(Text, Calls, Finish, Codes) :-
    (   Calls == []
    ->  Message = json([role-assistant, content-Text])
    ;   Message = json([role-assistant, content-Text, tool_calls-Calls])
    ),
    json_codes(json([id-'x', choices-[json([index-0, message-Message,
                                          finish_reason-Finish])]]), Codes).

test_defaults :-
    unsetenv('CODING_ENDPOINT_API'),
    unsetenv('CODING_ENDPOINT_BACKEND'),
    unsetenv('CODING_ENDPOINT_MODEL'),
    unsetenv('CODING_ENDPOINT_C_MODEL'),
    unsetenv('CODING_ENDPOINT_TIMEOUT'),
    ep_backend_url(OpenUrl),
    check('the default backend is DeepSeek chat completions', OpenUrl,
          'https://api.deepseek.com/v1/chat/completions'),
    setenv('CODING_ENDPOINT_API', 'anthropic'),
    ep_backend_url(AnthropicUrl),
    check('the default Anthropic backend is DeepSeek messages', AnthropicUrl,
          'https://api.deepseek.com/anthropic/v1/messages'),
    unsetenv('CODING_ENDPOINT_API'),
    ep_backend_model(c, Model),
    check('the default model is deepseek-chat', Model, 'deepseek-chat'),
    ep_backend_timeout(Timeout),
    check('the default backend timeout is 600 seconds', Timeout, 600),
    setenv('CODING_ENDPOINT_TIMEOUT', '42'),
    ep_backend_timeout(SetTimeout),
    check('CODING_ENDPOINT_TIMEOUT is read', SetTimeout, 42),
    setenv('CODING_ENDPOINT_C_MODEL', 'deepseek-reasoner'),
    ep_backend_model(c, SetModel),
    check('a language model overrides the default', SetModel,
          'deepseek-reasoner'),
    unsetenv('CODING_ENDPOINT_TIMEOUT'),
    unsetenv('CODING_ENDPOINT_C_MODEL'),
    !.
