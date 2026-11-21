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
                ep_controlled/6,
                ep_controlled_note/2,
                ep_restate_backend/0,
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
                ep_about_note/2,
                ep_ir_note/2,
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
                ep_chat_memo/2,
                ep_chat_restore/3,
                ep_backend_url/1,
                ep_backend_timeout/1,
                ep_backend_model/2,
                ep_key/1
              ]).
:- use_module('coding/endpoint/reasoning_core.pl',
              [ endpoint_reason/4, endpoint_ir/2 ]).
:- use_module(library(reasoning/reason),
              [ reason_learn/1, reason_live_stub/3, reason_live_restatement/2,
                reason_set_mode/1 ]).
:- use_module(library(reasoning/live), [ reason_live_forget/0, reason_live_stats/1,
                                         reason_live_stats_reset/0 ]).
:- use_module('coding/endpoint/english_lesson.pl', [ ep_english_lesson/0 ]).
:- use_module('coding/endpoint/ir_repair.pl',
              [ ep_ir_readings/2, ep_ir_stats/1, ep_ir_stats_reset/0,
                ep_ir_model_stub/3, ep_ir_lesson/1, ep_ir_rewrite/2,
                ep_ir_unread/2, ep_ir_verdict/3, ep_ir_repair_ready/0,
                ep_ir_reply/4, ep_ir_display/2, ep_ir_refused/1,
                ep_ir_reading_text/2 ]).

main :-
    setenv('CODING_ENDPOINT_TOKEN', 'test-token'),
    %% no check here asks a real model: the repair's own section answers
    %% with ep_ir_model_stub/3
    setenv('CODING_ENDPOINT_IR_REPAIR', 'off'),
    %% nor does the restatement: test_controlled_live answers it with
    %% reason_live_stub/3
    setenv('CODING_ENDPOINT_RESTATE', 'off'),
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
    test_chat_thinking,
    test_sse,
    test_sse_usage,
    test_sse_tools,
    test_reasoning,
    test_about,
    test_c_reasoning,
    test_reasoning_headers,
    test_model_suffix,
    test_python,
    test_controlled_live,
    test_restate_backend,
    test_check_cap,
    test_zero_checks,
    test_backend_key,
    test_defaults,
    test_continue,
    test_ir,
    test_ir_repair,
    test_ir_check,
    test_ir_store,
    unsetenv('CODING_ENDPOINT_TOKEN'),
    unsetenv('CODING_ENDPOINT_RESTATE'),
    checks_done.

test_models :-
    ep_models_reply(request(get, '/v1/models', [], http(1, 1), [], []),
                    reply(200, _, Codes)),
    atom_codes(Text, Codes),
    (   sub_atom(Text, _, _, _, '"id":"c-r8"'),
        sub_atom(Text, _, _, _, '"id":"cocolog-r0"'),
        sub_atom(Text, _, _, _, '"id":"python-r8"'),
        sub_atom(Text, _, _, _, '"name":"Python (r8: the controlled note)"'),
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
                                 reasoning_content-'looked at it',
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
        ep_json_get(Assistant, content, AssistantBlocks),
        member(json(ThinkPairs), AssistantBlocks),
        memberchk(type-thinking, ThinkPairs),
        memberchk(thinking-'looked at it', ThinkPairs),
        member(json(BlockPairs), AssistantBlocks),
        memberchk(type-tool_use, BlockPairs),
        memberchk(input-json(InputPairs), BlockPairs),
        memberchk(cmd-'echo hi', InputPairs)
    ->  InputOk = yes
    ;   InputOk = no
    ),
    check('an Anthropic tool call carries its thinking and an input object',
          InputOk, yes),
    ColdCall = json([id-'call_9', type-function,
                     function-json([name-shell, arguments-'{}'])]),
    ColdAssistant = json([role-assistant, content-'',
                          tool_calls-[ColdCall]]),
    ColdChat = json([model-x,
                     messages-[json([role-user, content-go]),
                               ColdAssistant]]),
    ep_anthropic_body(ColdChat, ColdAnthropic),
    ep_json_get(ColdAnthropic, messages, ColdMessages),
    (   member(ColdMessage, ColdMessages),
        ep_json_get(ColdMessage, role, assistant),
        ep_json_get(ColdMessage, content, [json(ColdPairs)|_]),
        memberchk(type-thinking, ColdPairs),
        memberchk(thinking-'(thinking omitted)', ColdPairs)
    ->  ColdOk = yes
    ;   ColdOk = no
    ),
    check('a cold tool turn carries the placeholder thinking', ColdOk, yes),
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
                  content-[json([type-thinking, thinking-'weighed it']),
                           json([type-text, text-ok]),
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
    ep_json_get(json(Message), reasoning_content, Reasoning),
    check('an Anthropic reply carries its thinking as reasoning_content',
          Reasoning, 'weighed it'),
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

test_chat_thinking :-
    Req = request(post, '/v1/chat/completions', [], http(1, 1),
                  ['x-opencode-session-id'-'test-thinking-session'], []),
    Call = json([id-'call_7', type-function,
                 function-json([name-shell, arguments-'{}'])]),
    Reply = json([id-x,
                  choices-[json([index-0,
                                 message-json([role-assistant, content-'',
                                               reasoning_content-'weighed it',
                                               tool_calls-[Call]])])]]),
    json_codes(Reply, ReplyCodes),
    ep_chat_memo(Req, ReplyCodes),
    Messages = [json([role-user, content-go]),
                json([role-assistant, content-'', tool_calls-[Call]])],
    ep_chat_restore(Req, Messages, Restored),
    (   Restored = [_, json(RestoredPairs)],
        memberchk(reasoning_content-'weighed it', RestoredPairs)
    ->  RestoredOk = yes
    ;   RestoredOk = no
    ),
    check('a chat assistant turn gets its thinking back', RestoredOk, yes),
    Other = request(post, '/v1/chat/completions', [], http(1, 1),
                    ['x-opencode-session-id'-'test-thinking-other'], []),
    ep_chat_restore(Other, Messages, Kept),
    check('an unknown session keeps the turn as it came', Kept, Messages),
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

test_about :-
    endpoint_reason(
        'Alice owns a red car. Every employee that is authorized may access the server.',
        _, _, Terms),
    (   Terms \== []
    ->  TermsRead = parsed
    ;   TermsRead = unparsed
    ),
    check('the reasoner parses a controlled-English request', TermsRead, parsed),
    ep_about_note(Terms, About),
    (   sub_atom(About, _, _, _, 'What the request is about'),
        sub_atom(About, _, _, _, 'concepts'),
        sub_atom(About, _, _, _, 'Why is '),
        sub_atom(About, _, _, _, 'important to this task')
    ->  AboutRead = about
    ;   AboutRead = missing
    ),
    check('the reasoning note names the concepts and asks why they matter',
          AboutRead, about),
    ep_about_note([], NoTerms),
    check('a request with no terms adds no concept note', NoTerms, '').

%% A task the grammar reads already is its own controlled English, so these
%% need no model; a stub answers the one that does (test_controlled_live).
ep_controlled_task('Alice owns a car. Bob sleeps.').

ep_first_user([json(Pairs)|_], Content) :-
    memberchk(role-user, Pairs),
    !,
    memberchk(content-Content, Pairs).
ep_first_user([_|Rest], Content) :-
    ep_first_user(Rest, Content).

test_c_reasoning :-
    ep_controlled_task(Task),
    Messages = [json([role-user, content-Task])],
    Request = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_reasoning_setting(Request, c, Setting),
    ep_mode(false, Setting, Mode),
    ep_controlled(c, Mode, false, Messages, Messages1, N),
    ep_controlled_note(['Alice owns a car.', 'Bob sleeps.'], Note),
    atom_concat(Task, Note, Want),
    ep_first_user(Messages1, Got),
    check('the C model gets the controlled note after its task', Mode-N-Got,
          reasoning-2-Want),
    (   sub_atom(Note, _, _, _, '# The request in controlled English'),
        sub_atom(Note, _, _, _, 'one sentence a line:\n\nAlice owns a car.\nBob sleeps.')
    ->  Shape = bench
    ;   Shape = other
    ),
    check('the note is the benchmark''s, one sentence a line', Shape, bench),
    ep_add_guide(Messages1, 'GUIDE', Messages2),
    Messages2 = [json(System)|_],
    memberchk(content-SystemText, System),
    check('the system prompt is the guide alone', SystemText, 'GUIDE'),
    Prose = [json([role-user, content-'Write hello.c that prints hello.'])],
    ep_controlled(c, reasoning, false, Prose, Prose1, ProseN),
    check('prose with no model and nothing saved gets no note', ProseN-Prose1, 0-Prose),
    ep_controlled(c, reasoning, true, Messages, Title1, TitleN),
    check('a title request gets no note', TitleN-Title1, 0-Messages).

test_reasoning_headers :-
    ep_controlled_task(Task),
    Messages = [json([role-user, content-Task])],
    Off = request(post, '/v1/chat/completions', [], http(1, 1),
                  ['x-coding-reasoning'-'0'], []),
    Eight = request(post, '/v1/chat/completions', [], http(1, 1),
                    ['x-coding-reasoning'-'8'], []),
    ep_reasoning_setting(Off, c, OffSetting),
    ep_mode(false, OffSetting, OffMode),
    ep_controlled(c, OffMode, false, Messages, OffMessages, OffN),
    ep_reasoning_setting(Eight, c, EightSetting),
    ep_mode(false, EightSetting, EightMode),
    ep_controlled(c, EightMode, false, Messages, _, EightN),
    check('x-coding-reasoning 0 sends no note', OffMode-OffN-OffMessages,
          plain-0-Messages),
    check('x-coding-reasoning 8 sends the note', EightMode-EightN, reasoning-2).

test_model_suffix :-
    Empty = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_alias('cocolog-r8', Alias),
    ep_reasoning_setting(Empty, 'cocolog-r8', Setting),
    ep_mode(false, Setting, Mode),
    check('cocolog-r8 selects cocolog', Alias, cocolog),
    check('cocolog-r8 keeps the pass on', Mode-Setting,
          reasoning-count(8)).

test_python :-
    Empty = request(post, '/v1/chat/completions', [], http(1, 1), [], []),
    ep_alias('python-r8', Alias),
    ep_reasoning_setting(Empty, 'python-r8', Setting),
    ep_mode(false, Setting, Mode),
    check('python-r8 selects python', Alias, python),
    check('python-r8 keeps the pass on', Mode-Setting,
          reasoning-count(8)),
    ep_guide(python, Guide),
    (   sub_atom(Guide, _, _, _, 'Python 3')
    ->  GuideRead = python
    ;   GuideRead = wrong
    ),
    check('python has its own guide', GuideRead, python),
    ep_controlled_task(Task),
    Messages = [json([role-system, content-'SYSTEM']),
                json([role-user, content-Task]),
                json([role-assistant, content-'Done.']),
                json([role-user, content-'Alice sleeps.'])],
    ep_controlled(python, reasoning, false, Messages, Messages1, N),
    Messages1 = [S1, json(U1), A1, L1],
    memberchk(content-C1, U1),
    (   sub_atom(C1, 0, _, _, Task),
        sub_atom(C1, _, _, 0, 'Alice owns a car.\nBob sleeps.')
    ->  First = noted
    ;   First = other
    ),
    check('python: the note goes into the first user turn alone', N-First-[S1, A1, L1],
          2-noted-[json([role-system, content-'SYSTEM']),
                   json([role-assistant, content-'Done.']),
                   json([role-user, content-'Alice sleeps.'])]),
    ep_controlled(cocolog, reasoning, false, Messages, Cocolog1, CocologN),
    check('cocolog gets no note unless asked for', CocologN-Cocolog1, 0-Messages),
    setenv('CODING_ENDPOINT_CONTROLLED_LANGS', 'Python, cocolog'),
    ep_controlled(cocolog, reasoning, false, Messages, _, AskedN),
    ep_controlled(c, reasoning, false, Messages, _, CN),
    check('CODING_ENDPOINT_CONTROLLED_LANGS names the languages', AskedN-CN, 2-0),
    setenv('CODING_ENDPOINT_CONTROLLED_LANGS', none),
    ep_controlled(python, reasoning, false, Messages, _, NoneN),
    check('none names no language', NoneN, 0),
    unsetenv('CODING_ENDPOINT_CONTROLLED_LANGS'),
    setenv('CODING_ENDPOINT_CONTROLLED_MAX', '10'),
    ep_controlled(python, reasoning, false, Messages, _, LongN),
    check('a task past CODING_ENDPOINT_CONTROLLED_MAX gets no note', LongN, 0),
    unsetenv('CODING_ENDPOINT_CONTROLLED_MAX').

%% The restatement asks live mode's model, here a stub: no call leaves the
%% process, and REASON_LIVE_KEY is a dummy, so ep_restate_backend/0 copies
%% no key of the shell's.
test_controlled_live :-
    setenv('REASON_LIVE_KEY', 'test-live-key'),
    setenv('CODING_ENDPOINT_RESTATE', on),
    retractall(reason_live_stub(_, _, _)),
    reason_live_forget,
    reason_live_stats_reset,
    Task = 'Write a Python program that prints the sum of two numbers it reads.',
    assertz(reason_live_stub('sum of two numbers', 1,
        '{"sentences": ["Every program reads two numbers.", "Every program prints a sum and a number."]}')),
    assertz(reason_live_stub('sum of two numbers', 2,
        '{"sentences": ["Every program reads two numbers.", "Every program prints a sum."]}')),
    Messages = [json([role-user, content-Task])],
    ep_controlled(python, reasoning, false, Messages, Messages1, N1),
    ep_first_user(Messages1, C1),
    (   sub_atom(C1, _, _, 0, 'one sentence a line:\n\nEvery program reads two numbers.\nEvery program prints a sum.')
    ->  Live = noted
    ;   Live = C1
    ),
    check('live: the task said again by a model, each sentence read', N1-Live, 2-noted),
    reason_live_stats(Stats1),
    memberchk(calls-Calls1, Stats1),
    check('a sentence the grammar did not read went back once', Calls1, 2),
    findall(S, reason_live_restatement(Task, S), Saved),
    check('the restatement is kept in the knowledge base', Saved,
          [['Every program reads two numbers.', 'Every program prints a sum.']]),
    ep_controlled(python, reasoning, false, Messages, Messages2, _),
    reason_live_stats(Stats2),
    memberchk(calls-Calls2, Stats2),
    check('the next turn of the session asks no model', Calls2-Messages2, 2-Messages1),
    setenv('CODING_ENDPOINT_RESTATE', off),
    retractall(reason_live_stub(_, _, _)),
    ep_controlled(python, reasoning, false, Messages, Messages3, _),
    check('with the restatement off, what was kept is still sent', Messages3, Messages1),
    reason_live_forget,
    reason_set_mode(static),
    unsetenv('REASON_LIVE_KEY').

test_restate_backend :-
    forall(member(V, ['REASON_LIVE_KEY', 'REASON_LIVE_API', 'REASON_LIVE_URL',
                      'REASON_LIVE_MODEL']),
           unsetenv(V)),
    setenv('CODING_ENDPOINT_IR_KEY', 'test-ir-key'),
    setenv('CODING_ENDPOINT_IR_API', anthropic),
    setenv('CODING_ENDPOINT_IR_MODEL', 'test-ir-model'),
    nb_setval('$ep_restate_backend', none),
    ep_restate_backend,
    findall(V-X, ( member(V, ['REASON_LIVE_API', 'REASON_LIVE_URL', 'REASON_LIVE_MODEL',
                              'REASON_LIVE_KEY']),
                   getenv(V, X0), atom_string(X, X0) ), Got),
    check('the restatement asks the IR repair''s model where REASON_LIVE_KEY is unset', Got,
          ['REASON_LIVE_API'-anthropic,
           'REASON_LIVE_URL'-'https://api.anthropic.com/v1/messages',
           'REASON_LIVE_MODEL'-'test-ir-model',
           'REASON_LIVE_KEY'-'test-ir-key']),
    setenv('REASON_LIVE_KEY', 'own-key'),
    setenv('REASON_LIVE_MODEL', 'own-model'),
    nb_setval('$ep_restate_backend', none),
    ep_restate_backend,
    getenv('REASON_LIVE_KEY', K), getenv('REASON_LIVE_MODEL', M),
    atom_string(KA, K), atom_string(MA, M),
    check('a REASON_LIVE_KEY of its own is kept, with its model', KA-MA, 'own-key'-'own-model'),
    forall(member(V, ['REASON_LIVE_KEY', 'REASON_LIVE_API', 'REASON_LIVE_URL',
                      'REASON_LIVE_MODEL', 'CODING_ENDPOINT_IR_KEY',
                      'CODING_ENDPOINT_IR_API', 'CODING_ENDPOINT_IR_MODEL']),
           unsetenv(V)),
    nb_setval('$ep_restate_backend', none).

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
    forall(dangle_case(Name, Text, Want),
           (   ( ep_text_dangles(Text) -> Got = yes ; Got = no ),
               check(Name, Got, Want)
           )),
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

%% The texts ep_text_dangles/1 is held to, each with the check's name and
%% whether it dangles. A table, so test_continue's clause fits a store page.
dangle_case('a narrowing preamble dangles', 'Direct `p->a_` works. The failure is specific to `&p->a_` passed as a parameter, so I’m narrowing that case.', yes).
dangle_case('a running-gate preamble dangles', 'Docs updated and C/C++ builds verified. Running the full ccllib gate to confirm GREEN with the atomic C++23 skip.', yes).
dangle_case('a committing preamble dangles', 'The gate is GREEN: 28 programs in all three runs, 175 refusals, 19 standalone. I’m committing and pushing 1d.', yes).
dangle_case('a final answer does not dangle', 'Done. All tests pass and the fix is committed.', no).
dangle_case('a relative clause does not start a sentence', 'The command I’m running takes ten seconds.', no).
dangle_case('a gerund with a finite verb is a statement', 'Testing shows the fix works.', no).
dangle_case('an offer does not dangle', 'The flow gate is green. I’ll leave the remaining choice to you.', no).
dangle_case('a let-me preamble dangles', 'Let me check the compiler source.', yes).
dangle_case('a need to know does not dangle', 'I need to know whether the test passes.', no).
dangle_case('a comparing sentence dangles', 'The C++23 AST itself is right; the failure is in the C++ desugaring of &p->a_. Comparing the two language paths now.', yes).
dangle_case('an early preamble before a final answer does not dangle', 'I’m checking the parser. The fix is ready.', no).
dangle_case('a gerund in an earlier sentence does not dangle', 'Checking the AST, I found the bug. The fix is in the desugaring.', no).
dangle_case('a comparing statement does not dangle', 'Comparing the paths shows the difference.', no).
dangle_case('a bare comparing phrase dangles', 'Comparing the two paths.', yes).
dangle_case('a semicolon starts the last clause', 'The AST is right; comparing the paths now.', yes).
dangle_case('a let-me revert dangles', 'The harness appends exit N itself. Let me revert that print from the programs.', yes).
dangle_case('an arbitrary action after I will dangles', 'I’ll revert the print.', yes).
dangle_case('a let-me know offer does not dangle', 'Let me know if you need anything else.', no).
dangle_case('an explanation after I will does not dangle', 'I’ll explain the change.', no).
dangle_case('a closing let-me does not dangle', 'Let me finish.', no).
dangle_case('a leading now before a gerund dangles', 'Now reverting the print from the programs.', yes).
dangle_case('an adverb before an explanation does not dangle', 'I’ll just explain the change.', no).
dangle_case('an adverb before an action dangles', 'Let me quickly revert the print.', yes).
dangle_case('an adverb before a gerund action dangles', 'I’m just checking the logs.', yes).
dangle_case('an adverb before an explanation does not dangle', 'I’m just explaining the change.', no).
dangle_case('an about-to preamble dangles', 'I’m about to revert the print.', yes).
dangle_case('an after-that preamble dangles', 'After that, I’ll revert the print.', yes).
dangle_case('a wait-for-it-to-finish preamble dangles', 'It\'s running now (the nice message is harmless). Let me wait for it to finish.', yes).
dangle_case('a wait-for-your-input offer does not dangle', 'I’ll wait for your input.', no).
dangle_case('finishing the code dangles', 'Let me finish the code.', yes).
dangle_case('stopping the server dangles', 'I’ll stop the server.', yes).
dangle_case('stopping here does not dangle', 'I’ll stop here.', no).
dangle_case('leaving the file unchanged dangles', 'I’ll leave the file unchanged.', yes).
dangle_case('waiting for the rest dangles', 'Progressing well (151 lines). Waiting for the rest.', yes).
dangle_case('waiting for your input does not dangle', 'Waiting for your input.', no).
dangle_case('finishing the code dangles', 'Finishing the code.', yes).
dangle_case('finishing alone does not dangle', 'Finishing.', no).
dangle_case('stopping the server dangles', 'Stopping the server.', yes).
dangle_case('stopping here does not dangle', 'Stopping here.', no).
dangle_case('leaving the file unchanged as a gerund dangles', 'Leaving the file unchanged.', yes).
dangle_case('leaving the rest as a gerund does not dangle', 'Leaving the rest to you.', no).
dangle_case('I am waiting for the rest dangles', 'I’m just waiting for the rest.', yes).
dangle_case('waiting alone dangles', 'Waiting.', yes).
dangle_case('a colon keeps the let-me head', 'Let me simplify: drop the unnecessary exit helper and test whether the mutex type macro works without a template argument.', yes).
dangle_case('a semicolon keeps a later subject announcement', 'The AST is right; I’ll revert the print.', yes).
dangle_case('a now-the heading with a gerund dangles', 'Now the report page drawing: a page tall enough for every column, so no line is cut off.', yes).
dangle_case('a let-me confirm an object dangles', 'I’ve traced the exact failing step. Let me confirm the rendering failure at the end of the chain — whether anything after the drawing can succeed at all.', yes).
dangle_case('a let-me confirm that does not dangle', 'Let me confirm that the fix is complete.', no).
dangle_case('a wh-clause heading dangles', 'The only remaining local blocker is that my machine lacks rsvg-convert; the server installs it. I’ll put a small stand-in on the PATH to exercise the full picture path, then look for leftovers. First, what a systemd unit sees of PATH.', yes).
dangle_case('a first-what fragment dangles', 'First, what a systemd unit sees of PATH.', yes).
dangle_case('a wh-clause subject with a finite verb does not dangle', 'First, what matters is the result.', no).
dangle_case('an announcement before its explanation dangles', 'While that runs, let me look at GitHub Actions — the server-side commit did (or didn’t) get pushed, and local main may be behind. That affects any fix I deploy.', yes).
dangle_case('a sequence noun-phrase heading dangles', 'The flow tools need a file run in a child of their own, so I’ll point flow/debug at the run shape: if its replay loses the getenv output, that confirms the loss is in the path run takes. First, the tool’s options.', yes).
dangle_case('a first-the fragment alone dangles', 'First, the tool’s options.', yes).
dangle_case('a sequence clause with a finite verb does not dangle', 'First, the results are good.', no).
dangle_case('an explanation before its reason does not dangle', 'Let me explain the situation. The server is behind.', no).
dangle_case('an action announcement before its reason dangles', 'I’ll check the logs. The server may be behind.', yes).
dangle_case('a confirming-against gerund dangles', 'I found something worth checking before more engine work: format(atom(A), "~w", [x]) prints nothing in the scratch build, built with these same flags. That is much simpler than getenv/2. Confirming on the published binary.', yes).
dangle_case('a bare confirming-against gerund dangles', 'Confirming on the published binary.', yes).
dangle_case('a confirming-that explanation does not dangle', 'Confirming that the tests pass.', no).
dangle_case('a checking sentence before a relative clause dangles', 'I want to rule out one thing before going deeper: whether this checkout’s engine differs from the one the green review traced. Comparing the published binary with the scratch build is already done; now checking whether ensure_loaded/consult in the same process reproduces it, which would confirm it is not run-specific.', yes).
dangle_case('a finite verb in a relative clause does not make a statement', 'Now checking whether the process reproduces it, which would confirm it is not run-specific.', yes).
dangle_case('a gerund front before a main clause does not dangle', 'Comparing the paths, I found the bug.', no).
dangle_case('a gerund subject with its own verb does not dangle', 'Comparing the paths shows the difference, which would confirm it.', no).
dangle_case('a colon heading dangles', 'The catch didn’t fire, which (per the 3.62.5 changelog line "an if-then’s else is reached") suggests old 3.18 swallows it. One more probe to confirm the message text:', yes).
dangle_case('a bare colon fragment dangles', 'One more probe to confirm the message text:', yes).
dangle_case('a colon after a finite verb does not dangle', 'The answer is:', no).
dangle_case('a main clause after a comma announces and dangles', 'Server cocolog is now 3.62.5 (0b55373, the local version). The modules are separate builds and may not exist yet for the new version; let me rebuild them. Since make modules is a tracked build target, I’ll use it.', yes).
dangle_case('a since-clause and its announcement dangle', 'Since the build is a tracked target, I’ll use it.', yes).
dangle_case('a comma after a statement and an adjective does not dangle', 'The build is green, I’m confident.', no).
dangle_case('a comma before an explanation does not dangle', 'The build is green, I’ll explain the change.', no).
dangle_case('a hyphenated gerund dangles', 'The trace now shows the first catch/3 never gets an exit marker: the call goes straight from ASK to OPFAIL, with the failing last goal backed into a frame of kind 2 (CATCH). That means the goal is being compiled as if it were the body’s last, and the catch frame is left where $catch_exit should have retired it. I’m re-reading that dispatch path and the code that decides “last goal.”', yes).
dangle_case('a bare re-reading phrase dangles', 'I’m re-reading that dispatch path.', yes).
dangle_case('a hyphenated gerund with its own verb does not dangle', 'Re-reading the trace, the bug is clear.', no).
dangle_case('a gerund before a reason clause dangles', 'Reading the web unit and the /tick route, since a queued strategy job must inherit the Telegram token.', yes).
dangle_case('a gerund before a because clause dangles', 'Reading the trace, because the bug is clear.', yes).
dangle_case('a gerund front with a main clause does not dangle', 'Reading the trace, the bug is clear.', no).
dangle_case('a gerund front before a past clause does not dangle', 'Reading the trace, we found the bug.', no).

test_ir :-
    reason_learn('Spanish is a language. The noun "casa" means "house". The adjective "grande" means "big". The verb "es" means "is". The feminine article "la" means "the". Every noun that ends in "a" is feminine. Every adjective follows the noun. Every noun that ends in a vowel takes "s" in the plural. Every article that ends in a vowel takes "s" in the plural. Every adjective that ends in a vowel takes "s" in the plural. "son" is the plural of "es". "era" is the past of "es". The word "no" means "not".'),
    endpoint_ir('The houses were not big.', IRs),
    (   IRs = [ir(_, _)|_]
    ->  Read = read
    ;   Read = refused
    ),
    check('the translator reads a controlled-English request into its IR',
          Read, read),
    ep_ir_note('The houses were not big.', Note),
    (   sub_atom(Note, _, _, _, 'translator''s IR'),
        sub_atom(Note, _, _, _, houses)
    ->  NoteOk = yes
    ;   NoteOk = no
    ),
    check('the translator''s IR is sent with the note', NoteOk, yes),
    ep_ir_note('Write a complete C program that prints hello.', Plain),
    check('a sentence the translator cannot read adds no IR note',
          Plain, ''),
    ep_english_lesson,
    endpoint_ir('The dog eats the bread.', EnglishIRs),
    (   EnglishIRs = [ir(_, _)|_]
    ->  EnglishRead = read
    ;   EnglishRead = refused
    ),
    check('the English lesson reads a plain sentence into the IR',
          EnglishRead, read),
    ep_ir_note('The houses were not big.', EnglishNote),
    (   sub_atom(EnglishNote, _, _, _, houses)
    ->  EnglishNoteOk = yes
    ;   EnglishNoteOk = no
    ),
    check('the English lesson''s IR reaches the note', EnglishNoteOk, yes),
    ep_ir_note('The xyzzy eats the bread.', UnknownNote),
    check('a sentence with an unknown word adds no IR note',
          UnknownNote, ''),
    Msgs = [json([role-user, content-'Alice owns a car.'])],
    ep_controlled(c, reasoning, false, Msgs, Reasoned, _),
    ep_add_guide(Reasoned, 'GUIDE', Sent),
    format(atom(SentText), '~q', [Sent]),
    (   sub_atom(SentText, _, _, _, 'translator')
    ->  ReasonedIR = yes
    ;   ReasonedIR = no
    ),
    check('the request carries no IR note', ReasonedIR, no),
    !.

%% ---- the model helps the translator read (ir_repair.pl) ----------------
%%
%% The model is a stub, ep_ir_model_stub(Key, Round, Reply): a round's prompt
%% that contains Key is answered Reply, and no backend is called while a stub
%% exists. Runs after test_ir, so the English lesson is loaded.

test_ir_repair :-
    unsetenv('CODING_ENDPOINT_KEY_ENV'),
    unsetenv('CODING_ENDPOINT_IR_KEY'),
    setenv('CODING_ENDPOINT_IR_REPAIR', 'off'),
    ( ep_ir_repair_ready -> Off = ready ; Off = not_ready ),
    check('CODING_ENDPOINT_IR_REPAIR=off asks no model', Off, not_ready),
    setenv('CODING_ENDPOINT_IR_REPAIR', 'on'),
    ( ep_ir_repair_ready -> NoKey = ready ; NoKey = not_ready ),
    check('with no key and no stub the model is not asked', NoKey, not_ready),
    %% these checks send only what the translator could not read; the
    %% check of every reading is test_ir_check's
    setenv('CODING_ENDPOINT_IR_CHECK', failed),
    %% a word the translator does not know, classified and taught
    assertz(ep_ir_model_stub('contiguous subarray', 1,
        '```json\n{"words": [{"word": "subarray", "class": "noun", "base": "subarray"}], "rewrites": []}\n```')),
    ep_ir_readings('It prints the maximum sum of a contiguous subarray.', R1),
    ir_shape(R1, S1),
    check('a word the model classified is taught, and the sentence reads as it stands',
          S1, ['It prints the maximum sum of a contiguous subarray.'-lesson-1]),
    ( ep_ir_lesson('The noun "x_subarray" means "subarray".') -> L1 = kept ; L1 = missing ),
    check('the word is kept as a lesson line in the English lesson''s form', L1, kept),
    ep_ir_stats(ir(_, _, _, _, _, Lessons1, Calls1, _, _, _, _)),
    check('one call taught one lesson', Lessons1-Calls1, 1-1),
    %% a shape the translator does not read, rewritten
    assertz(ep_ir_model_stub('Write a complete C program.', 1,
        '{"words": [], "rewrites": [{"id": 1, "sentences": ["Write a complete program in C."]}]}')),
    ep_ir_readings('Write a complete C program.', R2),
    ir_shape(R2, S2),
    check('a rewrite the translator reads is the sentence''s reading',
          S2, ['Write a complete C program.'-rewrite(['Write a complete program in C.'])-1]),
    ( ep_ir_rewrite('Write a complete C program.', ['Write a complete program in C.']) -> W2 = kept ; W2 = missing ),
    check('the rewrite that read is kept', W2, kept),
    ep_ir_readings('Write a complete C program.', _),
    ep_ir_stats(ir(_, _, _, Rewrite2, _, _, Calls2, _, _, _, _)),
    check('a kept rewrite reads again with no call', Rewrite2-Calls2, 1-0),
    %% a rewrite that does not read goes back with what was tried
    assertz(ep_ir_model_stub('Division truncates toward zero.', 1,
        '{"words": [], "rewrites": [{"id": 1, "sentences": ["Division rounds the result toward zero."]}]}')),
    assertz(ep_ir_model_stub('Tried before: "Division rounds the result toward zero."', 2,
        '{"words": [], "rewrites": [{"id": 1, "sentences": ["The program divides the numbers.", "It drops the fraction."]}]}')),
    ep_ir_readings('Division truncates toward zero.', R3),
    ir_shape(R3, S3),
    check('a second round sends the rewrite that did not read, and reads the next one',
          S3, ['Division truncates toward zero.'-rewrite(['The program divides the numbers.', 'It drops the fraction.'])-2]),
    ep_ir_stats(ir(_, _, _, _, _, _, Calls3, _, _, _, _)),
    check('two rounds are two calls', Calls3, 2),
    %% nothing reads: kept as unread, and not sent again
    forall(between(1, 4, FK),
           assertz(ep_ir_model_stub('The flux capacitor', FK,
               '{"words": [], "rewrites": [{"id": 1, "sentences": ["The flux capacitor glorbs the zinth."]}]}'))),
    ep_ir_readings('The flux capacitor xqzzv the zinth.', R4),
    check('a sentence no rewrite reads is unread',
          R4, [reading('The flux capacitor xqzzv the zinth.', unread, [])]),
    ep_ir_stats(ir(_, _, _, _, _, _, Calls4, _, _, _, _)),
    check('the model is asked once a round, three rounds at most', Calls4, 3),
    ep_ir_readings('The flux capacitor xqzzv the zinth.', _),
    ep_ir_stats(ir(_, _, _, _, Unread5, _, Calls5, _, _, _, _)),
    check('an unread sentence is not sent again under this version', Unread5-Calls5, 1-0),
    %% what a reply may teach: unknown words only, a class it knows, letters only
    assertz(ep_ir_model_stub('The blurgh frobnicates', 1,
        '{"words": [{"word": "house", "class": "noun"}, {"word": "blurgh2", "class": "noun"}, {"word": "frobnicates", "class": "symbol"}, {"word": "blurgh", "class": "noun", "base": "blurgh"}], "rewrites": []}')),
    ep_ir_readings('The blurgh frobnicates the house.', _),
    findall(L, ( ep_ir_lesson(L), once(( sub_atom(L, _, _, _, blurgh) ; sub_atom(L, _, _, _, frobnicat) )) ), GL),
    check('a reply teaches only an unknown word of a known class, in letters', GL,
          ['The noun "x_blurgh" means "blurgh".']),
    ( ep_ir_lesson('The noun "x_house" means "house".') -> HL = taught ; HL = refused ),
    check('a word the translator knows is not taught again', HL, refused),
    %% a lesson that would change a confirmed reading is taken back: `if'
    %% is unknown in the middle of a sentence, and the grammar's own at its head
    If7 = 'If it reads the input, it prints 0.',
    ep_ir_try(If7, IfIRs7), ep_ir_reading_text(IfIRs7, IfText7),
    assertz(ep_ir_verdict(If7, IfText7, right)),
    assertz(ep_ir_model_stub('prints yes if the zorp', 1,
        '{"words": [{"word": "if", "class": "conjunction"}, {"word": "zorp", "class": "noun"}], "rewrites": []}')),
    ep_ir_readings('It prints yes if the zorp is big.', _),
    findall(L, ( ep_ir_lesson(L), once(( sub_atom(L, _, _, _, '"x_if"') ; sub_atom(L, _, _, _, zorp) )) ), GL7),
    ep_ir_refused(Refused7),
    check('a lesson that would change a confirmed reading is taken back, and the other kept',
          GL7-Refused7, ['The noun "x_zorp" means "zorp".']-['The conjunction "x_if" means "if".']),
    ( ep_ir_try(If7, IfIRs8), ep_ir_reading_text(IfIRs8, IfText7), \+ catch(conjunction(x_if), _, fail)
    -> IfKept = yes ; IfKept = no ),
    check('the confirmed reading stands, and no fact of the lesson taken back is left', IfKept, yes),
    retract(ep_ir_verdict(If7, IfText7, right)),
    %% a reply that is no JSON teaches nothing and breaks nothing
    assertz(ep_ir_model_stub('Quux the blarf', 1, 'I cannot help with that.')),
    ep_ir_readings('Quux the blarf.', R6),
    check('a reply that is not JSON leaves the sentence unread', R6, [reading('Quux the blarf.', unread, [])]),
    ep_ir_reply('Here: {"ok": [1, "x"], "words": [], "rewrites": [{"id": 2, "sentences": ["A b."]}]} done', [], OK, RW),
    check('the JSON object is found inside the reply text', OK-RW, [1]-[2-['A b.']]),
    ep_ir_reply('The line holds only the characters ()[]{}. {"ok": [3], "rewrites": []}', _, OK2, _),
    check('a brace before the JSON object does not hide it', OK2, [3]),
    ep_ir_reply('{"ok": [1], "rewrites": []}\n\nWait, that is wrong. Here is the corrected answer:\n\n{"ok": [], "rewrites": [{"id": 1, "sentences": ["It reads one line."]}]}', _, OK3, RW3),
    check('the last object is the answer, the one the model corrected passed by',
          OK3-RW3, []-[1-['It reads one line.']]),
    ep_ir_display('n \x5\1 <= n\x6\, \x3\ 2\nlines', Shown),
    check('the model is shown the brackets, the dash and a blank for a line break',
          Shown, 'n (1 <= n), - 2 lines'),
    %% the note: what was read, and the rewrite beside its reading
    ep_ir_note('Write a complete C program. It prints the maximum sum of a contiguous subarray.', Note),
    (   sub_atom(Note, _, _, _, 'rewritten for the translator as "Write a complete program in C."'),
        sub_atom(Note, _, _, _, 'w(subarray,lower)')
    ->  NoteOk = yes
    ;   NoteOk = no
    ),
    check('the note carries the rewrite and both readings', NoteOk, yes),
    retractall(ep_ir_model_stub(_, _, _)),
    unsetenv('CODING_ENDPOINT_IR_CHECK'),
    setenv('CODING_ENDPOINT_IR_REPAIR', 'off'),
    !.

%% The model checks every reading (CODING_ENDPOINT_IR_CHECK=all, the
%% default): a sentence the translator read is sent with its reading said
%% back in English, and a wrong reading is rewritten and never used.
test_ir_check :-
    setenv('CODING_ENDPOINT_IR_REPAIR', 'on'),
    unsetenv('CODING_ENDPOINT_IR_CHECK'),
    %% a reading the translator gives wrongly, rewritten, the rewrite checked
    assertz(ep_ir_model_stub('Read as: "Every convert words to lowercase."', 1,
        '{"ok": [], "rewrites": [{"id": 1, "sentences": ["It converts each word to lowercase."]}]}')),
    assertz(ep_ir_model_stub('Rewritten as: "It converts each word to lowercase."', 2,
        '{"ok": [1]}')),
    ep_ir_readings('Convert every word to lowercase.', C1),
    ir_shape(C1, CS1),
    check('a reading the model judged wrong is replaced by the rewrite',
          CS1, ['Convert every word to lowercase.'-rewrite(['It converts each word to lowercase.'])-1]),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls1, _, _, Checked1, Wrong1)),
    check('the reading and the rewrite''s reading are checked in two calls',
          CCalls1-Checked1-Wrong1, 2-1-1),
    findall(V, ep_ir_verdict('Convert every word to lowercase.', _, V), Vs1),
    check('both verdicts are kept', Vs1, [wrong, right]),
    ep_ir_readings('Convert every word to lowercase.', C2),
    ir_shape(C2, CS2),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls2, _, _, _, _)),
    check('a judged reading is read again with no call', CS2-CCalls2, CS1-0),
    %% a reading the model confirms
    assertz(ep_ir_model_stub('Read as: "The program reads the input."', 1, '{"ok": [1]}')),
    ep_ir_readings('The program reads the input.', C3),
    ir_shape(C3, CS3),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls3, _, _, Checked3, _)),
    check('a right reading is confirmed in one call',
          CS3-CCalls3-Checked3, ['The program reads the input.'-read-1]-1-1),
    ep_ir_readings('The program reads the input.', _),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls4, _, _, _, _)),
    check('a confirmed reading is not sent again', CCalls4, 0),
    setenv('CODING_ENDPOINT_IR_CHECK', always),
    ep_ir_readings('The program reads the input.', _),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls5, _, _, Checked5, _)),
    check('CODING_ENDPOINT_IR_CHECK=always sends it with every request', CCalls5-Checked5, 1-1),
    unsetenv('CODING_ENDPOINT_IR_CHECK'),
    %% a wrong reading no rewrite reads: unread, and never in the note
    assertz(ep_ir_model_stub('Read as: "Each print words in lowercase."', 1,
        '{"ok": [], "rewrites": [{"id": 1, "sentences": ["The flarbs zorp the word."]}]}')),
    assertz(ep_ir_model_stub('Tried before: "The flarbs zorp the word."', 2,
        '{"rewrites": [{"id": 1, "sentences": ["Glorp each word."]}]}')),
    %% the translator reads that one as a name: a wrong reading, caught
    assertz(ep_ir_model_stub('Rewritten as: "Glorp each word."', 3,
        '{"ok": [], "rewrites": [{"id": 1, "sentences": ["The flarbs zorp each word."]}]}')),
    ep_ir_readings('Print each word in lowercase.', C6),
    ep_ir_stats(ir(_, _, _, _, Unread6, _, CCalls6, _, _, _, Wrong6)),
    check('a wrong reading whose rewrites read wrongly or not at all is unread',
          C6-Unread6-CCalls6-Wrong6, [reading('Print each word in lowercase.', unread, [])]-1-3-2),
    ( ep_ir_rewrite('Print each word in lowercase.', _) -> RW6 = kept ; RW6 = dropped ),
    check('a rewrite whose reading was judged wrong is dropped', RW6, dropped),
    ep_ir_note('Print each word in lowercase.', CNote6),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls7, _, _, _, _)),
    check('the note never carries a wrong reading, and asks no model again', CNote6-CCalls7, ''-0),
    %% a reading the model was shown and said nothing of is used, and kept
    %% as unjudged, so it is not sent again
    assertz(ep_ir_model_stub('Read as: "It prints each word in lowercase."', 1, '{"ok": []}')),
    ep_ir_readings('It prints each word in lowercase.', C8),
    ir_shape(C8, CS8),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls8, _, _, Checked8, _)),
    check('a reading the model said nothing of is used as it stands',
          CS8-CCalls8-Checked8, ['It prints each word in lowercase.'-read-1]-1-0),
    ep_ir_readings('It prints each word in lowercase.', _),
    ep_ir_stats(ir(_, _, _, _, _, _, CCalls9, _, _, _, _)),
    ( ep_ir_verdict('It prints each word in lowercase.', _, unjudged) -> UJ9 = kept ; UJ9 = missing ),
    check('and is kept as unjudged, and not sent again', UJ9-CCalls9, kept-0),
    %% a word taught makes a reading, which the next round checks
    assertz(ep_ir_model_stub('Unknown words: zibbet', 1,
        '{"words": [{"word": "zibbet", "class": "noun", "base": "zibbet"}]}')),
    assertz(ep_ir_model_stub('Read as: "It prints the sum of a contiguous zibbet."', 2, '{"ok": [1]}')),
    ep_ir_readings('It prints the sum of a contiguous zibbet.', C10),
    ir_shape(C10, CS10),
    ep_ir_stats(ir(_, _, _, _, _, Lessons10, CCalls10, _, _, Checked10, _)),
    check('a reading a lesson made is checked in the next round',
          CS10-Lessons10-CCalls10-Checked10,
          ['It prints the sum of a contiguous zibbet.'-lesson-1]-1-2-1),
    %% a sentence whose rounds keep ending on a reading the model never saw
    %% is given up after CODING_ENDPOINT_IR_TRIES requests
    setenv('CODING_ENDPOINT_IR_ROUNDS', '1'),
    assertz(ep_ir_model_stub('Read as: "Each make words lowercase."', 1,
        '{"ok": [], "rewrites": [{"id": 1, "sentences": ["It makes each word lowercase."]}]}')),
    assertz(ep_ir_model_stub('Rewritten as: "It makes each word lowercase."', 1,
        '{"ok": [], "rewrites": [{"id": 1, "sentences": ["The program makes each word lowercase."]}]}')),
    ep_ir_readings('Make each word lowercase.', T11),
    ir_shape(T11, TS11),
    ep_ir_stats(ir(_, _, _, _, _, _, TCalls11, _, _, _, _)),
    check('a rewrite made in the last round is used, once tried',
          TS11-TCalls11, ['Make each word lowercase.'-rewrite(['It makes each word lowercase.'])-1]-1),
    ep_ir_readings('Make each word lowercase.', T12),
    ep_ir_stats(ir(_, _, _, _, _, _, TCalls12, _, _, _, _)),
    ( ep_ir_rewrite('Make each word lowercase.', _) -> TRw12 = kept ; TRw12 = dropped ),
    check('at the second such request the sentence is unread, and its rewrite dropped',
          T12-TCalls12-TRw12, [reading('Make each word lowercase.', unread, [])]-1-dropped),
    ep_ir_readings('Make each word lowercase.', _),
    ep_ir_stats(ir(_, _, _, _, _, _, TCalls13, _, _, _, _)),
    check('and it is not sent again', TCalls13, 0),
    unsetenv('CODING_ENDPOINT_IR_ROUNDS'),
    %% CODING_ENDPOINT_IR_LOG keeps each round's prompt and reply
    os_pid(LogPid),
    format(atom(LogFile), '/tmp/ep_ir_log_~w.txt', [LogPid]),
    setenv('CODING_ENDPOINT_IR_LOG', LogFile),
    assertz(ep_ir_model_stub('Read as: "The program writes the output."', 1, '{"ok": [1]}')),
    ep_ir_readings('The program writes the output.', _),
    unsetenv('CODING_ENDPOINT_IR_LOG'),
    (   catch(read_file_to_codes(LogFile, LogCodes), _, fail),
        atom_codes(LogText, LogCodes),
        sub_atom(LogText, _, _, _, 'Read as: "The program writes the output."'),
        sub_atom(LogText, _, _, _, '-- reply')
    ->  Logged = yes
    ;   Logged = no
    ),
    catch(delete_file(LogFile), _, true),
    check('CODING_ENDPOINT_IR_LOG keeps the round''s prompt and reply', Logged, yes),
    retractall(ep_ir_model_stub(_, _, _)),
    setenv('CODING_ENDPOINT_IR_REPAIR', 'off'),
    !.

ir_shape(Readings, Shape) :-
    findall(S-How-N, ( member(reading(S, How, IRs), Readings), length(IRs, N) ), Shape).

%% Under --embed what one process learned is read by the next: a child
%% learns with a stub, and a second child, whose stub would answer any
%% round, reads both sentences with no call: the lesson, the rewrite and
%% the verdicts came from the store.
test_ir_store :-
    current_prolog_flag(executable, Exe),
    os_pid(Pid),
    format(atom(Dir), '/tmp/ep_ir_store_~w', [Pid]),
    format(atom(Learn), '/tmp/ep_ir_learn_~w.pl', [Pid]),
    format(atom(Read), '/tmp/ep_ir_read_~w.pl', [Pid]),
    atom_codes(LearnText,
":- use_module('coding/endpoint/httpd_core.pl').
    :- use_module('coding/endpoint/english_lesson.pl').
    :- initialization(ep_english_lesson).
    main :- setenv('CODING_ENDPOINT_IR_REPAIR', on),
    assertz(ep_ir_model_stub('Write a complete C program.', 1, '{\"words\": [{\"word\": \"subarray\", \"class\": \"noun\"}], \"rewrites\": [{\"id\": 1, \"sentences\": [\"Write a complete program in C.\"]}]}')),
    assertz(ep_ir_model_stub('Rewritten as: \"Write a complete program in C.\"', 2, '{\"ok\": [1, 2]}')),
    ep_ir_readings('Write a complete C program. It prints the maximum sum of a contiguous subarray.', _),
    retractall(ep_ir_model_stub(_, _, _)),
    ep_ir_stats(S), write(S), nl.
"),
    atom_codes(ReadText,
":- use_module('coding/endpoint/httpd_core.pl').
    :- use_module('coding/endpoint/english_lesson.pl').
    :- initialization(ep_english_lesson).
    main :- setenv('CODING_ENDPOINT_IR_REPAIR', on),
    assertz(ep_ir_model_stub('', 1, '{\"ok\": [1, 2]}')),
    ep_ir_readings('Write a complete C program. It prints the maximum sum of a contiguous subarray.', _),
    ep_ir_stats(S), write(S), nl.
"),
    atom_codes(LearnText, LC), atom_codes(ReadText, RC),
    write_file_from_codes(Learn, LC), write_file_from_codes(Read, RC),
    format(atom(C1), '~w --embed ~w -s ~w 2>&1 | tail -1', [Exe, Dir, Learn]),
    format(atom(C2), '~w --embed ~w -s ~w 2>&1 | tail -1', [Exe, Dir, Read]),
    format(atom(C3), 'cd /tmp && ~w --embed ~w query "aggregate_all(count, mean(_, _), N), aggregate_all(count, ep_ir_verdict(_, _, right), V), write(N-V), nl" 2>&1 | head -1', [Exe, Dir]),
    proc_run(C1, 300000, O1, _), proc_run(C2, 300000, O2, _), proc_run(C3, 120000, O3, _),
    atom_codes(A1, O1), atom_codes(A2, O2), atom_codes(A3, O3),
    check('under --embed a child learns a lesson and a rewrite, and has both readings checked, in two calls',
          A1, 'ir(2,0,1,1,0,1,2,0,0,2,0)\n'),
    check('the next child reads both sentences from the store, checked, with no call',
          A2, 'ir(2,1,0,1,0,0,0,0,0,0,0)\n'),
    check('the store holds the lesson taught, not the English lesson, and the two verdicts',
          A3, '1-2\n'),
    format(atom(Clean), 'rm -rf ~w ~w ~w', [Dir, Learn, Read]),
    proc_run(Clean, 60000, _, _),
    !.

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
