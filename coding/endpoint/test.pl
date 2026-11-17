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
                ep_continue_nudge/3,
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
    U = 'The harness appends exit N itself. Let me revert that print from the programs.',
    ( ep_text_dangles(U) -> U1 = yes ; U1 = no ),
    check('a let-me revert dangles', U1, yes),
    V = 'I’ll revert the print.',
    ( ep_text_dangles(V) -> V1 = yes ; V1 = no ),
    check('an arbitrary action after I will dangles', V1, yes),
    W = 'Let me know if you need anything else.',
    ( ep_text_dangles(W) -> W1 = yes ; W1 = no ),
    check('a let-me know offer does not dangle', W1, no),
    X = 'I’ll explain the change.',
    ( ep_text_dangles(X) -> X1 = yes ; X1 = no ),
    check('an explanation after I will does not dangle', X1, no),
    Y = 'Let me finish.',
    ( ep_text_dangles(Y) -> Y1 = yes ; Y1 = no ),
    check('a closing let-me does not dangle', Y1, no),
    Z = 'Now reverting the print from the programs.',
    ( ep_text_dangles(Z) -> Z1 = yes ; Z1 = no ),
    check('a leading now before a gerund dangles', Z1, yes),
    AA = 'I’ll just explain the change.',
    ( ep_text_dangles(AA) -> AA1 = yes ; AA1 = no ),
    check('an adverb before an explanation does not dangle', AA1, no),
    AB = 'Let me quickly revert the print.',
    ( ep_text_dangles(AB) -> AB1 = yes ; AB1 = no ),
    check('an adverb before an action dangles', AB1, yes),
    AC = 'I’m just checking the logs.',
    ( ep_text_dangles(AC) -> AC1 = yes ; AC1 = no ),
    check('an adverb before a gerund action dangles', AC1, yes),
    AD = 'I’m just explaining the change.',
    ( ep_text_dangles(AD) -> AD1 = yes ; AD1 = no ),
    check('an adverb before an explanation does not dangle', AD1, no),
    AE = 'I’m about to revert the print.',
    ( ep_text_dangles(AE) -> AE1 = yes ; AE1 = no ),
    check('an about-to preamble dangles', AE1, yes),
    AF = 'After that, I’ll revert the print.',
    ( ep_text_dangles(AF) -> AF1 = yes ; AF1 = no ),
    check('an after-that preamble dangles', AF1, yes),
    AH = 'It\'s running now (the nice message is harmless). Let me wait for it to finish.',
    ( ep_text_dangles(AH) -> AH1 = yes ; AH1 = no ),
    check('a wait-for-it-to-finish preamble dangles', AH1, yes),
    AI = 'I’ll wait for your input.',
    ( ep_text_dangles(AI) -> AI1 = yes ; AI1 = no ),
    check('a wait-for-your-input offer does not dangle', AI1, no),
    AJ = 'Let me finish the code.',
    ( ep_text_dangles(AJ) -> AJ1 = yes ; AJ1 = no ),
    check('finishing the code dangles', AJ1, yes),
    AK = 'I’ll stop the server.',
    ( ep_text_dangles(AK) -> AK1 = yes ; AK1 = no ),
    check('stopping the server dangles', AK1, yes),
    AL = 'I’ll stop here.',
    ( ep_text_dangles(AL) -> AL1 = yes ; AL1 = no ),
    check('stopping here does not dangle', AL1, no),
    AM = 'I’ll leave the file unchanged.',
    ( ep_text_dangles(AM) -> AM1 = yes ; AM1 = no ),
    check('leaving the file unchanged dangles', AM1, yes),
    AN = 'Progressing well (151 lines). Waiting for the rest.',
    ( ep_text_dangles(AN) -> AN1 = yes ; AN1 = no ),
    check('waiting for the rest dangles', AN1, yes),
    AO = 'Waiting for your input.',
    ( ep_text_dangles(AO) -> AO1 = yes ; AO1 = no ),
    check('waiting for your input does not dangle', AO1, no),
    AP = 'Finishing the code.',
    ( ep_text_dangles(AP) -> AP1 = yes ; AP1 = no ),
    check('finishing the code dangles', AP1, yes),
    AQ = 'Finishing.',
    ( ep_text_dangles(AQ) -> AQ1 = yes ; AQ1 = no ),
    check('finishing alone does not dangle', AQ1, no),
    AR = 'Stopping the server.',
    ( ep_text_dangles(AR) -> AR1 = yes ; AR1 = no ),
    check('stopping the server dangles', AR1, yes),
    AS = 'Stopping here.',
    ( ep_text_dangles(AS) -> AS1 = yes ; AS1 = no ),
    check('stopping here does not dangle', AS1, no),
    AT = 'Leaving the file unchanged.',
    ( ep_text_dangles(AT) -> AT1 = yes ; AT1 = no ),
    check('leaving the file unchanged as a gerund dangles', AT1, yes),
    AU = 'Leaving the rest to you.',
    ( ep_text_dangles(AU) -> AU1 = yes ; AU1 = no ),
    check('leaving the rest as a gerund does not dangle', AU1, no),
    AV = 'I’m just waiting for the rest.',
    ( ep_text_dangles(AV) -> AV1 = yes ; AV1 = no ),
    check('I am waiting for the rest dangles', AV1, yes),
    AW = 'Waiting.',
    ( ep_text_dangles(AW) -> AW1 = yes ; AW1 = no ),
    check('waiting alone dangles', AW1, yes),
    AX = 'Let me simplify: drop the unnecessary exit helper and test whether the mutex type macro works without a template argument.',
    ( ep_text_dangles(AX) -> AX1 = yes ; AX1 = no ),
    check('a colon keeps the let-me head', AX1, yes),
    AY = 'The AST is right; I’ll revert the print.',
    ( ep_text_dangles(AY) -> AY1 = yes ; AY1 = no ),
    check('a semicolon keeps a later subject announcement', AY1, yes),
    AZ = 'Now the report page drawing: a page tall enough for every column, so no line is cut off.',
    ( ep_text_dangles(AZ) -> AZ1 = yes ; AZ1 = no ),
    check('a now-the heading with a gerund dangles', AZ1, yes),
    BA = 'I’ve traced the exact failing step. Let me confirm the rendering failure at the end of the chain — whether anything after the drawing can succeed at all.',
    ( ep_text_dangles(BA) -> BA1 = yes ; BA1 = no ),
    check('a let-me confirm an object dangles', BA1, yes),
    BB = 'Let me confirm that the fix is complete.',
    ( ep_text_dangles(BB) -> BB1 = yes ; BB1 = no ),
    check('a let-me confirm that does not dangle', BB1, no),
    BC = 'The only remaining local blocker is that my machine lacks rsvg-convert; the server installs it. I’ll put a small stand-in on the PATH to exercise the full picture path, then look for leftovers. First, what a systemd unit sees of PATH.',
    ( ep_text_dangles(BC) -> BC1 = yes ; BC1 = no ),
    check('a wh-clause heading dangles', BC1, yes),
    BD = 'First, what a systemd unit sees of PATH.',
    ( ep_text_dangles(BD) -> BD1 = yes ; BD1 = no ),
    check('a first-what fragment dangles', BD1, yes),
    BE = 'First, what matters is the result.',
    ( ep_text_dangles(BE) -> BE1 = yes ; BE1 = no ),
    check('a wh-clause subject with a finite verb does not dangle', BE1, no),
    BF = 'While that runs, let me look at GitHub Actions — the server-side commit did (or didn’t) get pushed, and local main may be behind. That affects any fix I deploy.',
    ( ep_text_dangles(BF) -> BF1 = yes ; BF1 = no ),
    check('an announcement before its explanation dangles', BF1, yes),
    BG = 'The flow tools need a file run in a child of their own, so I’ll point flow/debug at the run shape: if its replay loses the getenv output, that confirms the loss is in the path run takes. First, the tool’s options.',
    ( ep_text_dangles(BG) -> BG1 = yes ; BG1 = no ),
    check('a sequence noun-phrase heading dangles', BG1, yes),
    BH = 'First, the tool’s options.',
    ( ep_text_dangles(BH) -> BH1 = yes ; BH1 = no ),
    check('a first-the fragment alone dangles', BH1, yes),
    BI = 'First, the results are good.',
    ( ep_text_dangles(BI) -> BI1 = yes ; BI1 = no ),
    check('a sequence clause with a finite verb does not dangle', BI1, no),
    BJ = 'Let me explain the situation. The server is behind.',
    ( ep_text_dangles(BJ) -> BJ1 = yes ; BJ1 = no ),
    check('an explanation before its reason does not dangle', BJ1, no),
    BK = 'I’ll check the logs. The server may be behind.',
    ( ep_text_dangles(BK) -> BK1 = yes ; BK1 = no ),
    check('an action announcement before its reason dangles', BK1, yes),
    BL = 'I found something worth checking before more engine work: format(atom(A), "~w", [x]) prints nothing in the scratch build, built with these same flags. That is much simpler than getenv/2. Confirming on the published binary.',
    ( ep_text_dangles(BL) -> BL1 = yes ; BL1 = no ),
    check('a confirming-against gerund dangles', BL1, yes),
    BM = 'Confirming on the published binary.',
    ( ep_text_dangles(BM) -> BM1 = yes ; BM1 = no ),
    check('a bare confirming-against gerund dangles', BM1, yes),
    BN = 'Confirming that the tests pass.',
    ( ep_text_dangles(BN) -> BN1 = yes ; BN1 = no ),
    check('a confirming-that explanation does not dangle', BN1, no),
    BO = 'I want to rule out one thing before going deeper: whether this checkout’s engine differs from the one the green review traced. Comparing the published binary with the scratch build is already done; now checking whether ensure_loaded/consult in the same process reproduces it, which would confirm it is not run-specific.',
    ( ep_text_dangles(BO) -> BO1 = yes ; BO1 = no ),
    check('a checking sentence before a relative clause dangles', BO1, yes),
    BP = 'Now checking whether the process reproduces it, which would confirm it is not run-specific.',
    ( ep_text_dangles(BP) -> BP1 = yes ; BP1 = no ),
    check('a finite verb in a relative clause does not make a statement', BP1, yes),
    BQ = 'Comparing the paths, I found the bug.',
    ( ep_text_dangles(BQ) -> BQ1 = yes ; BQ1 = no ),
    check('a gerund front before a main clause does not dangle', BQ1, no),
    BR = 'Comparing the paths shows the difference, which would confirm it.',
    ( ep_text_dangles(BR) -> BR1 = yes ; BR1 = no ),
    check('a gerund subject with its own verb does not dangle', BR1, no),
    BS = 'The catch didn’t fire, which (per the 3.62.5 changelog line "an if-then’s else is reached") suggests old 3.18 swallows it. One more probe to confirm the message text:',
    ( ep_text_dangles(BS) -> BS1 = yes ; BS1 = no ),
    check('a colon heading dangles', BS1, yes),
    BT = 'One more probe to confirm the message text:',
    ( ep_text_dangles(BT) -> BT1 = yes ; BT1 = no ),
    check('a bare colon fragment dangles', BT1, yes),
    BU = 'The answer is:',
    ( ep_text_dangles(BU) -> BU1 = yes ; BU1 = no ),
    check('a colon after a finite verb does not dangle', BU1, no),
    BV = 'Server cocolog is now 3.62.5 (0b55373, the local version). The modules are separate builds and may not exist yet for the new version; let me rebuild them. Since make modules is a tracked build target, I’ll use it.',
    ( ep_text_dangles(BV) -> BV1 = yes ; BV1 = no ),
    check('a main clause after a comma announces and dangles', BV1, yes),
    BW = 'Since the build is a tracked target, I’ll use it.',
    ( ep_text_dangles(BW) -> BW1 = yes ; BW1 = no ),
    check('a since-clause and its announcement dangle', BW1, yes),
    BX = 'The build is green, I’m confident.',
    ( ep_text_dangles(BX) -> BX1 = yes ; BX1 = no ),
    check('a comma after a statement and an adjective does not dangle', BX1, no),
    BY = 'The build is green, I’ll explain the change.',
    ( ep_text_dangles(BY) -> BY1 = yes ; BY1 = no ),
    check('a comma before an explanation does not dangle', BY1, no),
    continue_reply('I’m checking the parser now.', [], stop, Reply),
    ( ep_reply_dangles(Reply) -> R1 = yes ; R1 = no ),
    check('a text-only reply dangles', R1, yes),
    continue_reply('I’m checking the parser now.', [continue_call], stop, ReplyTool),
    ( ep_reply_dangles(ReplyTool) -> R2 = yes ; R2 = no ),
    check('a reply with a tool call does not dangle', R2, no),
    continue_reply('I’m checking the parser now.', [], length, ReplyLong),
    ( ep_reply_dangles(ReplyLong) -> R3 = yes ; R3 = no ),
    check('a truncated reply dangles', R3, yes),
    continue_reply('The exact line is not y', [], stop, ReplyMid),
    ( ep_reply_dangles(ReplyMid) -> R4 = yes ; R4 = no ),
    check('a reply cut in the middle of a word dangles', R4, yes),
    continue_reply('The exact line is not yet found.', [], stop, ReplyCut),
    ( ep_reply_dangles(ReplyCut) -> R5 = yes ; R5 = no ),
    check('a reply that ends on a word does not dangle', R5, no),
    continue_reply('The value is a', [], stop, ReplyA),
    ( ep_reply_dangles(ReplyA) -> R6 = yes ; R6 = no ),
    check('a final article does not dangle', R6, no),
    (   ep_continue_nudge([finish_reason-length],
                          json([content-'The exact line is not y']), NudgeLong),
        sub_atom(NudgeLong, _, _, _, 'cut off')
    ->  N1 = yes
    ;   N1 = no
    ),
    check('a cut reply is told it was cut off', N1, yes),
    (   ep_continue_nudge([finish_reason-stop],
                          json([content-'I’m checking the parser now.']), NudgeStop),
        sub_atom(NudgeStop, _, _, _, 'announced the next action')
    ->  N2 = yes
    ;   N2 = no
    ),
    check('an announced action keeps its own nudge', N2, yes),
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
