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
    ep_backend_mode(Mode),
    (   Mode == anthropic
    ->  ep_env('CODING_ENDPOINT_BACKEND',
               'https://api.deepseek.com/anthropic/v1/messages', Url)
    ;   ep_env('CODING_ENDPOINT_BACKEND',
               'https://api.deepseek.com/v1/chat/completions', Url)
    ).

ep_backend_timeout(Timeout) :-
    ep_int('CODING_ENDPOINT_TIMEOUT', 600, Timeout).

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
    include(ep_nonempty_string, Parts, Kept),
    maplist(atom_string, Origins, Kept).

ep_nonempty_string(S) :- S \== ''.

%% ---- paths and guides --------------------------------------------------

ep_read_text(Path, Text) :-
    catch(read_file_to_codes(Path, Codes), _, fail),
    atom_codes(Text, Codes).

ep_guide(c, Guide) :-
    ep_read_text('coding/endpoint/prompts/c.md', Guide).

ep_guide(cocolog, Guide) :-
    ep_env('COCOLOG_SKILL', 'coding/cocolog/SKILL.md', SkillPath),
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

%% ---- what the request is about -----------------------------------------
%%
%% The reasoner's concepts and topics, and the question they raise. The
%% note is appended after the checks so the model names what the request
%% is about and says why it matters before it writes code.

ep_about_note(Terms, Note) :-
    (   Terms == []
    ->  Note = ''
    ;   (   catch(endpoint_about(Terms, Concepts, Topics), _, fail)
        ->  true
        ;   Concepts = [], Topics = []
        ),
        (   Concepts == [],
            Topics == []
        ->  Note = ''
        ;   ep_about_lines(Concepts, Topics, Lines),
            atomic_list_concat(Lines, '\n', Body),
            format(atom(Note), '~n~n# What the request is about~n~n~w', [Body])
        )
    ).

ep_about_lines(Concepts, Topics, Lines) :-
    ep_concept_section(Concepts, A),
    ep_topic_section(Topics, B),
    ep_about_questions(Concepts, Topics, Questions),
    append(A, B, AB),
    append(AB,
           ['', 'Answer these for yourself before you begin, and let the answers shape the code:'|Questions],
           Lines).

ep_concept_section([], []).
ep_concept_section(Concepts, Lines) :-
    findall(Line,
            ( member(concept(Name, Kind, Mentions), Concepts),
              format(atom(Line), '- `~w` (~w, ~w mention(s))',
                     [Name, Kind, Mentions]) ),
            Bullets),
    Lines = ['The reasoner read the request as these concepts, the most mentioned first:'|Bullets].

ep_topic_section([], []).
ep_topic_section(Topics, Lines) :-
    findall(Line,
            ( member(topic(Subject, Kind, _), Topics),
              format(atom(Line), '- `~w` (~w)', [Subject, Kind]) ),
            Bullets),
    Lines = ['', 'The subjects it says something about:'|Bullets].

ep_about_questions(Concepts, Topics, Questions) :-
    findall(Name, member(concept(Name, _, _), Concepts), ConceptNames),
    findall(Subject, member(topic(Subject, _, _), Topics), TopicNames),
    append(ConceptNames, TopicNames, Names0),
    ep_unique(Names0, Names),
    (   length(Names, N),
        N > 5
    ->  length(Top, 5),
        append(Top, _, Names)
    ;   Top = Names
    ),
    findall(Line,
            ( member(Name, Top),
              format(atom(Line), '- Why is `~w` important to this task?', [Name]) ),
            Questions).

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
        ep_about_note(Terms0, About),
        atomic_list_concat([Guide0, Note, About], Guide)
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
    ep_backend_mode(Mode),
    ep_backend_url(Url),
    ep_backend_timeout(Timeout),
    ep_key(Key),
    (   Mode == anthropic
    ->  ep_anthropic_body(Body4, AnthropicBody),
        json_codes(AnthropicBody, AnthropicCodes),
        format(atom(KeyHeader), 'x-api-key: ~w', [Key]),
        curl_post(Url, 'application/json', AnthropicCodes,
                  [ header(KeyHeader),
                    header('anthropic-version: 2023-06-01'),
                    timeout(Timeout), max_size(16777216) ],
                  Status0, AnthropicResp),
        ep_anthropic_reply(Status0, AnthropicResp, Status, Resp)
    ;   json_codes(Body4, Codes),
        format(atom(Auth), 'Authorization: Bearer ~w', [Key]),
        curl_post(Url, 'application/json', Codes,
                  [header(Auth), timeout(Timeout), max_size(16777216)],
                  Status, Resp)
    ).

%% ---- the Anthropic backend --------------------------------------------
%%
%% CODING_ENDPOINT_API=anthropic speaks the Messages wire: the system
%% prompt goes beside the messages, an assistant's tool calls are tool_use
%% blocks and the tool results are tool_result blocks in a user message.

ep_backend_mode(Mode) :-
    ep_env('CODING_ENDPOINT_API', 'openai', Api0),
    downcase_atom(Api0, Api),
    (   Api == anthropic
    ->  Mode = anthropic
    ;   Mode = openai
    ).

ep_anthropic_body(json(Pairs), json(Out)) :-
    memberchk(model-Model, Pairs),
    memberchk(messages-Messages, Pairs),
    ep_anthropic_system(Messages, System, Rest),
    ep_anthropic_messages(Rest, Wire),
    ep_anthropic_max_tokens(Pairs, MaxTokens),
    Base = [model-Model, max_tokens-MaxTokens, messages-Wire],
    ep_anthropic_system_field(System, Base, Base1),
    ep_anthropic_tools_field(Pairs, Base1, Base2),
    ep_anthropic_choice_field(Pairs, Base2, Base3),
    ep_anthropic_sampling_fields(Pairs, Base3, Out).

ep_anthropic_system([], '', []).
ep_anthropic_system([json(Pairs)|Rest], System, Messages) :-
    memberchk(role-system, Pairs),
    !,
    ep_anthropic_field(content, Pairs, Text),
    ep_anthropic_system(Rest, More, Messages),
    ep_anthropic_join_system(Text, More, System).
ep_anthropic_system([Message|Rest], System, [Message|Messages]) :-
    ep_anthropic_system(Rest, System, Messages).

ep_anthropic_join_system('', More, More) :-
    !.
ep_anthropic_join_system(Text, '', Text) :-
    !.
ep_anthropic_join_system(Text, More, System) :-
    atomic_list_concat([Text, '\n\n', More], System).

ep_anthropic_field(Key, Pairs, Text) :-
    (   memberchk(Key-Value, Pairs)
    ->  ep_anthropic_text(Value, Text)
    ;   Text = ''
    ).

ep_anthropic_text(Value, Text) :-
    atom(Value),
    !,
    Text = Value.
ep_anthropic_text(Value, Text) :-
    string(Value),
    !,
    atom_string(Text, Value).
ep_anthropic_text(Value, Text) :-
    is_list(Value),
    !,
    ep_anthropic_parts(Value, Parts),
    atomic_list_concat(Parts, '\n', Text).
ep_anthropic_text(Value, Text) :-
    number(Value),
    !,
    format(atom(Text), '~w', [Value]).
ep_anthropic_text(_, '').

ep_anthropic_parts([], []).
ep_anthropic_parts([json(Pairs)|Rest], [Text|Texts]) :-
    !,
    ep_anthropic_field(text, Pairs, Text),
    ep_anthropic_parts(Rest, Texts).
ep_anthropic_parts([Other|Rest], [Text|Texts]) :-
    ep_anthropic_text(Other, Text),
    ep_anthropic_parts(Rest, Texts).

ep_anthropic_messages([], []).
ep_anthropic_messages([json(Pairs)|Rest], Out) :-
    memberchk(role-tool, Pairs),
    !,
    ep_anthropic_tool_results([json(Pairs)|Rest], Blocks, Rest1),
    ep_anthropic_messages(Rest1, More),
    Out = [json([role-user, content-Blocks])|More].
ep_anthropic_messages([json(Pairs)|Rest], [Wire|More]) :-
    memberchk(role-Role0, Pairs),
    (   Role0 == assistant
    ->  Role = assistant
    ;   Role = user
    ),
    ep_anthropic_message_content(Role, Pairs, Content),
    Wire = json([role-Role, content-Content]),
    ep_anthropic_messages(Rest, More).

ep_anthropic_message_content(assistant, Pairs, Blocks) :-
    memberchk(tool_calls-Calls, Pairs),
    is_list(Calls),
    Calls \== [],
    !,
    ep_anthropic_field(content, Pairs, Text),
    ep_anthropic_text_blocks(Text, TextBlocks),
    ep_anthropic_tool_blocks(Calls, ToolBlocks),
    append(TextBlocks, ToolBlocks, Blocks).
ep_anthropic_message_content(_, Pairs, Text) :-
    ep_anthropic_field(content, Pairs, Text).

ep_anthropic_text_blocks('', []) :-
    !.
ep_anthropic_text_blocks(Text, [json([type-text, text-Text])]).

ep_anthropic_tool_blocks([], []).
ep_anthropic_tool_blocks([json(Pairs)|Calls], [Block|Blocks]) :-
    memberchk(id-Id, Pairs),
    memberchk(function-json(Function), Pairs),
    memberchk(name-Name, Function),
    (   memberchk(arguments-Arguments, Function)
    ->  ep_anthropic_input(Arguments, Input)
    ;   Input = json([])
    ),
    Block = json([type-tool_use, id-Id, name-Name, input-Input]),
    ep_anthropic_tool_blocks(Calls, Blocks).

ep_anthropic_input(Arguments, Input) :-
    (   atom(Arguments),
        catch(json_parse(Arguments, Parsed), _, fail)
    ->  Input = Parsed
    ;   Arguments = json(_)
    ->  Input = Arguments
    ;   Input = json([])
    ).

ep_anthropic_tool_results([json(Pairs)|Rest], [Block|Blocks], Rest1) :-
    memberchk(role-tool, Pairs),
    !,
    memberchk(tool_call_id-Id, Pairs),
    ep_anthropic_field(content, Pairs, Text),
    Block = json([type-tool_result, tool_use_id-Id, content-Text]),
    ep_anthropic_tool_results(Rest, Blocks, Rest1).
ep_anthropic_tool_results(Rest, [], Rest).

ep_anthropic_max_tokens(Pairs, Max) :-
    (   memberchk(max_tokens-Value, Pairs),
        integer(Value),
        Value > 0
    ->  Max = Value
    ;   Max = 32768
    ).

ep_anthropic_system_field('', Pairs, Pairs).
ep_anthropic_system_field(System, Pairs, [system-System|Pairs]).

ep_anthropic_tools_field(Pairs, Base, [tools-Tools|Base]) :-
    memberchk(tools-ChatTools, Pairs),
    is_list(ChatTools),
    ep_anthropic_tools(ChatTools, Tools),
    Tools \== [].
ep_anthropic_tools_field(_, Base, Base).

ep_anthropic_tools([], []).
ep_anthropic_tools([json(Pairs)|Rest], [Tool|Tools]) :-
    memberchk(type-function, Pairs),
    memberchk(function-json(Function), Pairs),
    memberchk(name-Name, Function),
    !,
    (   memberchk(description-Description, Function)
    ->  true
    ;   Description = ''
    ),
    (   memberchk(parameters-Parameters, Function)
    ->  true
    ;   Parameters = json([type-object])
    ),
    Tool = json([name-Name, description-Description,
                 input_schema-Parameters]),
    ep_anthropic_tools(Rest, Tools).
ep_anthropic_tools([_|Rest], Tools) :-
    ep_anthropic_tools(Rest, Tools).

ep_anthropic_choice_field(Pairs, Base, [tool_choice-Choice|Base]) :-
    memberchk(tool_choice-Value, Pairs),
    ep_anthropic_choice(Value, Choice),
    Choice \== none.
ep_anthropic_choice_field(_, Base, Base).

ep_anthropic_choice(auto, json([type-auto])).
ep_anthropic_choice(none, json([type-none])).
ep_anthropic_choice(required, json([type-any])).
ep_anthropic_choice(Value, json([type-tool, name-Name])) :-
    Value = json(Pairs),
    memberchk(type-function, Pairs),
    memberchk(function-json(Function), Pairs),
    memberchk(name-Name, Function).
ep_anthropic_choice(_, none).

ep_anthropic_sampling_fields(Pairs, Base, Out) :-
    findall(Key-Value, ep_anthropic_sampling(Pairs, Key, Value), Extra),
    append(Extra, Base, Out).

ep_anthropic_sampling(Pairs, temperature, Value) :-
    memberchk(temperature-Value, Pairs),
    number(Value).
ep_anthropic_sampling(Pairs, top_p, Value) :-
    memberchk(top_p-Value, Pairs),
    number(Value).

%% The reply becomes the chat reply the rest of the endpoint reads.
ep_anthropic_reply(Status, Codes, Status, Out) :-
    Status >= 200,
    Status < 300,
    catch(json_parse(Codes, json(Pairs)), _, fail),
    !,
    ep_anthropic_chat_reply(Pairs, Reply),
    json_codes(Reply, Out).
ep_anthropic_reply(Status, Codes, Status, Out) :-
    Status >= 400,
    catch(json_parse(Codes, json(Pairs)), _, fail),
    !,
    ep_anthropic_error_reply(Pairs, Reply),
    json_codes(Reply, Out).
ep_anthropic_reply(Status, Codes, Status, Codes).

ep_anthropic_chat_reply(Pairs, json(Out)) :-
    (   memberchk(id-Id, Pairs)
    ->  true
    ;   Id = 'chatcmpl-anthropic'
    ),
    (   memberchk(model-Model, Pairs)
    ->  true
    ;   Model = anthropic
    ),
    (   memberchk(content-Content, Pairs),
        is_list(Content)
    ->  true
    ;   Content = []
    ),
    ep_anthropic_blocks(Content, Text, Calls),
    (   memberchk(stop_reason-Stop, Pairs)
    ->  true
    ;   Stop = end_turn
    ),
    ep_anthropic_finish(Stop, Finish),
    ep_anthropic_usage(Pairs, Usage),
    ep_anthropic_message(Text, Calls, Message),
    get_time(Now),
    Created is round(Now),
    Out = [id-Id, object-'chat.completion', created-Created, model-Model,
           choices-[json([index-0, message-Message, finish_reason-Finish])],
           usage-Usage].

ep_anthropic_usage(Pairs, json([prompt_tokens-Prompt,
                                completion_tokens-Completion,
                                total_tokens-Total,
                                prompt_cache_hit_tokens-Cache,
                                completion_tokens_details-
                                    json([reasoning_tokens-Reasoning])])) :-
    (   memberchk(usage-json(U), Pairs)
    ->  true
    ;   U = []
    ),
    ep_anthropic_count(U, input_tokens, Input),
    ep_anthropic_count(U, output_tokens, Completion),
    ep_anthropic_count(U, cache_read_input_tokens, Cache),
    ep_anthropic_count(U, cache_creation_input_tokens, CacheNew),
    Prompt is Input + Cache + CacheNew,
    (   memberchk(output_tokens_details-json(Details), U),
        memberchk(thinking_tokens-Reasoning, Details)
    ->  true
    ;   Reasoning = 0
    ),
    Total is Prompt + Completion.

ep_anthropic_count(Pairs, Key, Number) :-
    (   memberchk(Key-Value, Pairs),
        integer(Value)
    ->  Number = Value
    ;   Number = 0
    ).

ep_anthropic_blocks([], '', []).
ep_anthropic_blocks([json(Pairs)|Rest], Text, Calls) :-
    memberchk(type-text, Pairs),
    memberchk(text-Here, Pairs),
    !,
    ep_anthropic_blocks(Rest, More, Calls),
    ep_anthropic_join_text(Here, More, Text).
ep_anthropic_blocks([json(Pairs)|Rest], Text, [Call|Calls]) :-
    memberchk(type-tool_use, Pairs),
    !,
    ep_anthropic_call(Pairs, Call),
    ep_anthropic_blocks(Rest, Text, Calls).
ep_anthropic_blocks([_|Rest], Text, Calls) :-
    ep_anthropic_blocks(Rest, Text, Calls).

ep_anthropic_join_text('', More, More) :-
    !.
ep_anthropic_join_text(Text, '', Text) :-
    !.
ep_anthropic_join_text(Text, More, Both) :-
    atom_concat(Text, More, Both).

ep_anthropic_call(Pairs, json([id-Id, type-function,
                              function-json([name-Name,
                                             arguments-Arguments])])) :-
    memberchk(id-Id, Pairs),
    memberchk(name-Name, Pairs),
    (   memberchk(input-Input, Pairs)
    ->  true
    ;   Input = json([])
    ),
    json_codes(Input, Codes),
    atom_codes(Arguments, Codes).

ep_anthropic_finish(tool_use, tool_calls) :-
    !.
ep_anthropic_finish(max_tokens, length) :-
    !.
ep_anthropic_finish(_, stop).

ep_anthropic_message('', [], json([role-assistant, content-''])).
ep_anthropic_message(Text, [], json([role-assistant, content-Text])).
ep_anthropic_message('', Calls, json([role-assistant, content- @(null),
                                     tool_calls-Calls])).
ep_anthropic_message(Text, Calls, json([role-assistant, content-Text,
                                       tool_calls-Calls])).

ep_anthropic_error_reply(Pairs, json([error-json([message-Message])])) :-
    (   memberchk(error-json(Error), Pairs),
        memberchk(message-Message, Error)
    ->  true
    ;   Message = 'backend error'
    ).

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

%% A token list is comma-separated, so two clients can hold different
%% tokens without either one learning the other's.
ep_token_ok(Request) :-
    ep_token(Token),
    (   Token == ''
    ->  true
    ;   ep_tokens(Token, Tokens),
        Tokens \== [],
        http_header(Request, authorization, Header),
        atom_string(Header, String),
        split_string(String, " ", "", [SchemeS, GivenS]),
        atom_string(Scheme, SchemeS),
        atom_string(Given, GivenS),
        downcase_atom(Scheme, bearer),
        memberchk(Given, Tokens)
    ).

ep_tokens(Text, Tokens) :-
    atom_string(Text, String),
    split_string(String, ",", " \t", Parts),
    include(ep_nonempty_string, Parts, Kept),
    maplist(atom_string, Tokens, Kept).

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
         Stream, MessageCount, ToolCount, Status, Finish, Usage,
         Continued) :-
    ep_env('CODING_ENDPOINT_TRACE', '', File),
    File \== '',
    get_time(Now),
    Seconds is Now - Start,
    ep_session_id(Request, Session),
    ep_header(Request, 'x-opencode-project', '-', Project),
    (   Stream == true -> StreamJson = @(true) ; StreamJson = @(false) ),
    ep_usage_json(Usage, UsagePairs),
    json_codes(json([ts-Now, session-Session, project-Project,
                     seconds-Seconds, status-Status, model-Alias,
                     backend-Backend, effort-Effort, mode-Mode,
                     reasoning-N, terms-Terms, stream-StreamJson,
                     messages-MessageCount, tools-ToolCount,
                     finish-Finish, continued-Continued | UsagePairs]),
               Codes),
    append(Codes, [10], Line),
    catch(append_file_from_codes(File, Line), _, true).

%% The backend's finish reason, for the trace: "stop", "length", "tool_calls".
ep_reply_finish(Resp, Finish) :-
    (   catch(json_parse(Resp, json(Pairs)), _, fail),
        memberchk(choices-[json(Choice)|_], Pairs),
        memberchk(finish_reason-Value, Choice),
        atom(Value)
    ->  Finish = Value
    ;   Finish = none
    ).

%% OpenCode names the session in its headers; Codex names it in
%% `session-id'. Both are what the thinking-mode memo is keyed by.
ep_session_id(Request, Session) :-
    ep_header(Request, 'x-opencode-session-id', '-', Session0),
    ep_header(Request, 'x-opencode-session', '-', Session1),
    ep_header(Request, 'x-session-id', '-', Session2),
    ep_header(Request, 'session-id', '-', Session3),
    (   Session0 \== '-' -> Session = Session0
    ;   Session1 \== '-' -> Session = Session1
    ;   Session2 \== '-' -> Session = Session2
    ;   Session = Session3
    ).

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
ep_call_signatures([json(Pairs)|Calls], Signatures) :-
    (   ep_wait_call(Pairs)
    ->  ep_call_signatures(Calls, Signatures)
    ;   (   memberchk(function-json(Function), Pairs),
            memberchk(name-Name, Function),
            memberchk(arguments-Arguments, Function)
        ->  ep_tool_signature(Name, Arguments, Signature)
        ;   Signature = unknown
        ),
        ep_call_signatures(Calls, Rest),
        Signatures = [Signature|Rest]
    ).

%% Codex polls a running PTY with write_stdin and empty chars; a long
%% build or test run legitimately makes many such calls, and the session
%% id and timeouts normalise to one signature. Waiting is not a loop.
ep_wait_call(Pairs) :-
    memberchk(function-json(Function), Pairs),
    memberchk(name-write_stdin, Function),
    memberchk(arguments-Arguments, Function),
    catch(ep_tool_arguments(Arguments, json(ArgumentPairs)), _, fail),
    memberchk(chars-Chars, ArgumentPairs),
    Chars == ''.

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
    nb_setval('$ep_continued', 0),
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
            (   catch(ep_forward(Body1, Alias, Status0, Resp0), Error,
                      ( Status0 = 502,
                        format(atom(Message), 'backend failed: ~q', [Error]),
                        json_codes(json([error-json([message-Message])]), Resp0) ))
            ->  true
            ;   Status0 = 502,
                json_codes(json([error-json([message-'backend failed'])]), Resp0)
            ),
            Status = Status0,
            ep_continue_reply(Body1, Alias, Title, ToolCount, Status0, Resp0,
                              Resp),
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
            ep_reply_finish(Resp, Finish),
            ep_continued(Continued),
            ep_trace(Request, Start, Alias, BackendModel, Effort, Mode,
                     N, TermCount, Stream, MessageCount, ToolCount, Status,
                     Finish, Usage, Continued)
        ;   ep_error_reply(Request, 500,
                           'the language guide is missing', Reply)
        )
    ;   ep_error_reply(Request, 400,
                       'model and messages are required', Reply)
    ).

%% ---- a reply that stops at a preamble --------------------------------
%%
%% Codex ends its turn when a reply carries no function call. A model
%% that writes "I'm running the gate now" and stops therefore leaves the
%% work undone, and the user has to prompt it again. When a reply with no
%% tool call ends on an announcement of the next action, the endpoint
%% puts that reply in the history, adds a nudge and asks the backend
%% once more; the reply with the tool call is the one returned. The
%% extra calls are capped, and the guard can be switched off.

ep_continue_reply(Body, Alias, Title, ToolCount, Status0, Resp0, Resp) :-
    (   Status0 =:= 200,
        Title == false,
        ToolCount > 0,
        ep_continue_on,
        ep_continue_limit(Limit),
        Limit > 0,
        catch(ep_continue_loop(Body, Alias, Limit, Resp0, Resp, Count), _, fail)
    ->  ep_continued_add(Count)
    ;   Resp = Resp0
    ).

ep_continue_on :-
    ep_env('CODING_ENDPOINT_CONTINUE', on, Value),
    downcase_atom(Value, Lower),
    Lower \== off,
    Lower \== '0',
    Lower \== false.

ep_continue_limit(Limit) :-
    ep_int('CODING_ENDPOINT_CONTINUE_LIMIT', 2, Limit).

ep_continue_loop(Body, Alias, Limit, Resp0, Resp, Count) :-
    (   Limit > 0,
        ep_reply_dangles(Resp0)
    ->  ep_continue_messages(Body, Resp0, Body1),
        ep_forward(Body1, Alias, Status1, Resp1),
        (   Status1 =:= 200
        ->  ep_usage(Resp0, Usage0),
            ep_usage(Resp1, Usage1),
            ep_usage_add(Usage0, Usage1, Usage),
            ep_reply_usage(Resp1, Usage, Resp1a),
            ep_merge_continuation(Resp0, Resp1a, Resp1b),
            Limit1 is Limit - 1,
            ep_continue_loop(Body1, Alias, Limit1, Resp1b, Resp, Count1),
            Count is Count1 + 1
        ;   Resp = Resp0,
            Count = 1
        )
    ;   Resp = Resp0,
        Count = 0
    ).

%% The assistant's own message and the nudge: the backend sees what it
%% said and is told either that the message was cut off or that the
%% action it announced has not happened.
ep_continue_messages(Body, Resp, Body1) :-
    catch(json_parse(Resp, json(Pairs)), _, fail),
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-Message, Choice),
    ep_json_get(Body, messages, Messages),
    ep_continue_nudge(Choice, Message, Nudge),
    append(Messages, [Message, json([role-user, content-Nudge])], Messages1),
    ep_json_set(Body, messages, Messages1, Body1).

ep_continue_nudge(Choice, Message, Nudge) :-
    (   Message = json(Pairs),
        memberchk(content-Content, Pairs)
    ->  true
    ;   Content = ''
    ),
    (   ep_reply_truncated(Choice, Content)
    ->  Nudge = 'Your last message was cut off before it finished. Continue it from the exact point where it stopped, without repeating what is already written; when the analysis allows, make the next tool call. If the task is actually complete, give the final answer.'
    ;   Nudge = 'Your last message announced the next action but made no tool call, so the turn ended before the work. Continue the task now: make the tool call that performs the next step. Do not end your turn with a plan, a preamble or a progress note. If the task is actually complete, give the final answer.'
    ).

%% A reply is continued when it was cut before it finished — the token
%% limit, or a last word that stops in the middle ("... is not y") — or
%% when its last sentence announces the next action.
ep_reply_dangles(Resp) :-
    catch(json_parse(Resp, json(Pairs)), _, fail),
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-json(Message), Choice),
    (   memberchk(tool_calls-Calls, Message),
        is_list(Calls),
        Calls \== []
    ->  fail
    ;   true
    ),
    (   memberchk(content-Content, Message)
    ->  true
    ;   Content = ''
    ),
    (   ep_reply_truncated(Choice, Content)
    ->  true
    ;   (   memberchk(finish_reason-Finish, Choice)
        ->  Finish == stop
        ;   true
        ),
        ep_text_dangles(Content)
    ).

%% "length" is the backend saying the token limit cut the reply. A reply
%% that ends on a single letter other than "a" or "i" stopped in the
%% middle of a word: "The exact line is not y" was "not yet".
ep_reply_truncated(Choice, Content) :-
    (   memberchk(finish_reason-Finish, Choice),
        Finish == length
    ->  true
    ;   ep_mid_word(Content)
    ).

ep_mid_word(Text) :-
    atom(Text),
    atom_length(Text, Length),
    Length > 1,
    atom_codes(Text, Codes),
    reverse(Codes, Back),
    ep_first_nonspace(Back, Start),
    ep_letters_prefix(Start, [L], _),
    \+ ep_single_word_end(L).

ep_letters_prefix([C|Codes], [C|Out], Rest) :-
    ep_ascii_letter(C),
    !,
    ep_letters_prefix(Codes, Out, Rest).
ep_letters_prefix(Codes, [], Codes).

ep_ascii_letter(C) :-
    C >= 65,
    C =< 90,
    !.
ep_ascii_letter(C) :-
    C >= 97,
    C =< 122.

ep_single_word_end(97).
ep_single_word_end(65).
ep_single_word_end(105).
ep_single_word_end(73).

%% The LAST sentence is inspected, with curly apostrophes folded to
%% straight ones, and the two last sentences for a reply that announces
%% an action and then explains it ("... let me look at X. That affects
%% ..."). A phrase that announces an action in an earlier sentence and a
%% final answer after it are not a dangling preamble.
ep_text_dangles(Text) :-
    atom(Text),
    Text \== '',
    ep_straight_apostrophes(Text, Flat),
    downcase_atom(Flat, Lower),
    atom_codes(Lower, Codes),
    ep_last_sentence_codes(Codes, SentenceCodes),
    ep_last_clause_codes(Codes, ClauseCodes),
    atom_codes(LastSentence, SentenceCodes),
    atom_codes(LastClause, ClauseCodes),
    (   ep_dangle_subject_phrase(LastSentence, _Before)
    ->  true
    ;   ep_heading_gerund(LastSentence)
    ->  true
    ;   ep_wh_fragment(LastSentence)
    ->  true
    ;   ep_sequence_fragment(LastSentence)
    ->  true
    ;   ep_colon_fragment(LastSentence)
    ->  true
    ;   ep_pending_announcement(Flat)
    ->  true
    ;   ep_sentence_gerund(LastClause, After),
        ep_without_relative(After, Main),
        ep_no_finite_verb(Main)
    ).

%% A subject announcement is looked for in the last sentence, so "Let me
%% simplify: drop ..." keeps its head across the colon. A gerund is looked
%% for at the head of the last clause, so "The AST is right; comparing
%% ..." is read from after the semicolon. Both stop at periods,
%% exclamation marks, question marks and newlines; only a clause also
%% stops at a semicolon or colon.
ep_last_sentence_codes(Codes, Last) :-
    reverse(Codes, Back),
    ep_after_last_break(Back, sentence, [], Last).

ep_last_clause_codes(Codes, Last) :-
    reverse(Codes, Back),
    ep_after_last_break(Back, clause, [], Last).

ep_after_last_break([P|_], _, Acc, Acc) :-
    P =:= 10,
    !.
ep_after_last_break([Space, P|_], Kind, Acc, Acc) :-
    ep_space(Space),
    ep_break_term(Kind, P),
    !.
ep_after_last_break([C|Rest], Kind, Acc, Out) :-
    ep_after_last_break(Rest, Kind, [C|Acc], Out).
ep_after_last_break([], _, Acc, Acc).

ep_break_term(sentence, 46).
ep_break_term(sentence, 33).
ep_break_term(sentence, 63).
ep_break_term(clause, 46).
ep_break_term(clause, 33).
ep_break_term(clause, 63).
ep_break_term(clause, 59).
ep_break_term(clause, 58).

ep_straight_apostrophes(Text, Flat) :-
    atom_codes('’', [Curly]),
    atom_codes(Text, Codes),
    ep_straight_codes(Codes, Curly, FlatCodes),
    atom_codes(Flat, FlatCodes).

ep_straight_codes([], _, []).
ep_straight_codes([Curly|Codes], Curly, [39|Out]) :-
    !,
    ep_straight_codes(Codes, Curly, Out).
ep_straight_codes([C|Codes], Curly, [C|Out]) :-
    ep_straight_codes(Codes, Curly, Out).

ep_sentence_start(_, 0) :- !.
ep_sentence_start(Text, Before) :-
    Before > 0,
    sub_atom(Text, 0, Before, _, Prefix),
    atom_codes(Prefix, Codes),
    reverse(Codes, Back),
    (   ep_first_nonspace(Back, [C|_])
    ->  ( ep_sentence_mark(C)
        ; C =:= 44                 % a comma: the main clause after a front
        ; ep_last_word(Prefix, Word),
          ep_clause_word(Word)
        )
    ;   true
    ).

%% "..., so I'm narrowing" is a clause after a conjunction, not a new
%% sentence, and the conjunction carries the announcement. A comma opens
%% a main clause too: "Since make modules is a tracked build target,
%% I'll use it."
ep_last_word(Text, Word) :-
    atom_codes(Text, Codes),
    reverse(Codes, Back),
    (   ep_first_nonspace(Back, NonSpace)
    ->  ep_take_word(NonSpace, WordCodes),
        reverse(WordCodes, Forward),
        atom_codes(Word, Forward)
    ;   Word = ''
    ).

ep_take_word([C|Codes], [C|Out]) :-
    \+ ep_space(C),
    !,
    ep_take_word(Codes, Out).
ep_take_word(_, []).

ep_space(32).
ep_space(9).
ep_space(10).
ep_space(13).

ep_clause_word(so).
ep_clause_word(and).
ep_clause_word(but).
ep_clause_word(then).
ep_clause_word(thus).
ep_clause_word(therefore).
ep_clause_word(because).
ep_clause_word(which).
ep_clause_word(while).
ep_clause_word(yet).

ep_first_nonspace([C|Codes], Out) :-
    (   C =:= 32
    ;   C =:= 9
    ;   C =:= 10
    ;   C =:= 13
    ),
    !,
    ep_first_nonspace(Codes, Out).
ep_first_nonspace(Codes, Codes).

ep_sentence_mark(C) :-
    memberchk(C, [46, 33, 63, 58, 59, 34, 39, 45, 42, 35, 40, 91, 10]).

%% The announcements seen in Codex turns: a subject and the action it is
%% about to take, and a bare gerund at the head of a sentence. A gerund
%% sentence with a finite verb is a statement ("Testing shows ..."), not
%% an announcement.
ep_dangle_subject_phrase(Text, Before) :-
    ep_dangle_subject(Subject, Kind),
    atomic_list_concat([Subject, ' '], Prefix),
    sub_atom(Text, Before, Length, _, Prefix),
    ep_sentence_start(Text, Before),
    End is Before + Length,
    sub_atom(Text, End, _, 0, Rest),
    ep_dangle_action(Kind, Rest).

%% "Now the report page drawing: ..." announces the next piece of work
%% as a heading, with no subject pronoun. The last word before the colon
%% is a gerund.
ep_heading_gerund(Text) :-
    ep_first_word(Text, now, Rest),
    ep_first_word(Rest, the, _),
    atom_codes(Text, Codes),
    (   append(BeforeColon, [58|_], Codes)
    ->  atom_codes(BeforeAtom, BeforeColon),
        ep_last_word(BeforeAtom, Word),
        ep_gerund_action(Word, '')
    ;   fail
    ).

%% "First, what a systemd unit sees of PATH." is a wh-clause with no
%% main verb: a heading for the next look, not a final answer. A sentence
%% whose wh-clause is the subject of a finite verb ("What matters is the
%% result") is a statement.
ep_wh_fragment(Text) :-
    ep_first_word(Text, Word, Rest),
    (   ep_wh_word(Word)
    ->  After = Rest
    ;   ep_sequence_word(Word)
    ->  ep_first_word(Rest, Word1, Rest1),
        ep_wh_word(Word1),
        After = Rest1
    ;   fail
    ),
    ep_no_finite_verb(After).

ep_wh_word(what).
ep_wh_word(which).
ep_wh_word(how).
ep_wh_word(why).
ep_wh_word(where).
ep_wh_word(when).
ep_wh_word(who).
ep_wh_word(whom).
ep_wh_word(whose).
ep_wh_word(whether).

ep_sequence_word(first).
ep_sequence_word(second).
ep_sequence_word(third).
ep_sequence_word(next).
ep_sequence_word(then).
ep_sequence_word(now).
ep_sequence_word(finally).
ep_sequence_word(also).

%% "First, the tool's options." is a bare noun phrase after a sequence
%% word, the heading of the next look. A sentence with a finite verb
%% ("First, the results are good") is a statement.
ep_sequence_fragment(Text) :-
    ep_first_word(Text, Word, Rest),
    ep_sequence_word(Word),
    ep_no_finite_verb(Rest).

%% A sentence that ends on a colon, with no finite verb, is a heading
%% whose body never came: "One more probe to confirm the message text:".
%% "The answer is:" keeps its finite verb and stays a statement.
ep_colon_fragment(Text) :-
    atom_codes(Text, Codes),
    reverse(Codes, Back),
    ep_first_nonspace(Back, [58|_]),
    ep_no_finite_verb(Text).

%% A reply that announces an action and then explains why it matters
%% stops mid-work as surely as one that ends on the announcement itself:
%% "While that runs, let me look at GitHub Actions ... . That affects any
%% fix I deploy." The last two sentences are asked: an announcement in
%% the one before, and neither an announcement nor a question in the
%% last (a question waits for the user, which is a legitimate stop).
ep_pending_announcement(Text) :-
    atom_codes(Text, Codes),
    ep_last_two_sentences_codes(Codes, PenultCodes, LastCodes),
    PenultCodes \== [],
    atom_codes(Penult, PenultCodes),
    atom_codes(Last, LastCodes),
    ep_announcement_in(Penult),
    \+ ep_announcement_in(Last),
    \+ ep_question_last(Last).

%% The last sentence and the one before it: ep_last_sentence_codes stops
%% at the last break, this walks on to the break before it.
ep_last_two_sentences_codes(Codes, Penult, Last) :-
    reverse(Codes, Back),
    ep_sentence_back(Back, [], Last, Rest),
    Rest \== [],
    ep_sentence_back(Rest, [], Penult, _).

ep_sentence_back([P|Rest], Acc, Acc, Rest) :-
    P =:= 10,
    !.
ep_sentence_back([Space, P|Rest], Acc, Acc, Rest) :-
    ep_space(Space),
    ep_break_term(sentence, P),
    !.
ep_sentence_back([C|Rest], Acc, Out, Tail) :-
    ep_sentence_back(Rest, [C|Acc], Out, Tail).
ep_sentence_back([], Acc, Acc, []).

%% "Let me look at", "I'll check", "I need to run": the announcement can
%% stand anywhere in the sentence ("While that runs, let me look at ...").
ep_announcement_in(Text) :-
    downcase_atom(Text, Lower),
    ep_announcement_phrase(Phrase),
    sub_atom(Lower, Before, Length, After, Phrase),
    Pos is Before + Length,
    sub_atom(Lower, Pos, After, 0, Rest),
    ep_bare_action(Rest),
    !.

ep_announcement_phrase('let me ').
ep_announcement_phrase('let\'s ').
ep_announcement_phrase('i\'ll ').
ep_announcement_phrase('i will ').
ep_announcement_phrase('i need to ').
ep_announcement_phrase('i have to ').
ep_announcement_phrase('i should ').
ep_announcement_phrase('i\'m going to ').
ep_announcement_phrase('i\'m about to ').

ep_question_last(Text) :-
    atom_codes(Text, Codes),
    reverse(Codes, Back),
    ep_first_nonspace(Back, [63|_]).


ep_dangle_action(gerund, Rest) :-
    ep_first_word(Rest, Word, Rest1),
    (   ep_bare_leading_adverb(Word)
    ->  ep_first_word(Rest1, Word1, Rest2),
        ep_gerund_action(Word1, Rest2)
    ;   ep_gerund_action(Word, Rest1)
    ).
ep_dangle_action(bare, Rest) :-
    ep_bare_action(Rest).

%% After "I'll", "Let me", "I need to", any word but a closing one is an
%% action: revert, rewrite, tweak, sanity-check, ... The stop list keeps
%% offers and explanations from being read as work. An adverb before the
%% verb is stepped over: "I'll just explain" is still an explanation.
ep_bare_action(Rest) :-
    ep_first_word(Rest, Word, Rest1),
    (   ep_bare_leading_adverb(Word)
    ->  ep_bare_action(Rest1)
    ;   ep_action_word(Word, Rest1)
    ).

ep_bare_leading_adverb(just).
ep_bare_leading_adverb(now).
ep_bare_leading_adverb(next).
ep_bare_leading_adverb(then).
ep_bare_leading_adverb(first).
ep_bare_leading_adverb(also).
ep_bare_leading_adverb(simply).
ep_bare_leading_adverb(only).
ep_bare_leading_adverb(quickly).
ep_bare_leading_adverb(briefly).
ep_bare_leading_adverb(immediately).
ep_bare_leading_adverb(still).

%% "Let me confirm the rendering failure" is work; "Let me confirm that
%% ..." explains what was already found.
ep_action_word(confirm, Rest) :-
    !,
    \+ ep_rest_empty(Rest),
    \+ ep_rest_begins(Rest, that),
    \+ ep_rest_begins(Rest, this).
ep_action_word(Word, Rest) :-
    (   ep_closing_word(Word)
    ->  \+ ep_closing_rest(Word, Rest)
    ;   \+ ep_nonaction_word(Word)
    ).

%% A closing word closes only with a closing rest: "finish" and "stop
%% here" end the turn, "finish the code" and "stop the server" are work.
ep_closing_word(wait).
ep_closing_word(finish).
ep_closing_word(stop).
ep_closing_word(close).
ep_closing_word(end).
ep_closing_word(leave).
ep_closing_word(wrap).

ep_closing_rest(wait, Rest) :-
    (   ep_rest_empty(Rest)
    ;   ep_rest_begins(Rest, here)
    ;   ep_rest_begins(Rest, 'for your')
    ;   ep_rest_begins(Rest, 'for input')
    ;   ep_rest_begins(Rest, 'for instructions')
    ;   ep_rest_begins(Rest, 'for a response')
    ).
ep_closing_rest(Word, Rest) :-
    memberchk(Word, [finish, stop, close, end, wrap]),
    (   ep_rest_empty(Rest)
    ;   ep_rest_begins(Rest, here)
    ;   ep_rest_begins(Rest, 'for now')
    ;   ep_rest_begins(Rest, up)
    ).
ep_closing_rest(leave, Rest) :-
    (   ep_rest_empty(Rest)
    ;   ep_rest_begins(Rest, 'the rest')
    ;   ep_rest_begins(Rest, 'the remaining')
    ;   ep_rest_begins(Rest, 'the decision')
    ;   ep_rest_begins(Rest, it)
    ;   ep_rest_begins(Rest, that)
    ;   ep_rest_begins(Rest, you)
    ;   ep_rest_begins(Rest, here)
    ).

ep_rest_empty(Rest) :-
    atom_codes(Rest, Codes),
    ep_skip_nonletter(Codes, []).

ep_rest_begins(Rest, Phrase) :-
    atom_codes(Rest, Codes),
    ep_skip_nonletter(Codes, Codes1),
    atom_codes(Flat, Codes1),
    sub_atom(Flat, 0, _, _, Phrase).

ep_sentence_gerund(Text, After) :-
    ep_first_word(Text, Word, Rest),
    (   ep_leading_adverb(Word)
    ->  ep_first_word(Rest, Word1, After),
        ep_gerund_action(Word1, After)
    ;   ep_gerund_action(Word, Rest),
        After = Rest
    ).

%% A finite verb inside a relative clause ("..., which would confirm it")
%% makes a gerund sentence no statement, so the clause from a comma and
%% a relative pronoun on is left out of the finite-verb test. "Comparing
%% the paths shows the difference, which would confirm it" keeps its
%% finite verb before the relative clause.
ep_without_relative(Text, Main) :-
    atom_codes(Text, Codes),
    (   ep_relative_at(Codes, Before)
    ->  atom_codes(Main, Before)
    ;   Main = Text
    ).

ep_relative_at(Codes, Before) :-
    append(Before, [44, 32|Rest], Codes),
    (   append("which", _, Rest)
    ;   append("whom", _, Rest)
    ;   append("whose", _, Rest)
    ;   append("who", _, Rest)
    ;   append("where", _, Rest)
    ),
    !.

ep_leading_adverb(now).
ep_leading_adverb(next).
ep_leading_adverb(then).
ep_leading_adverb(currently).
ep_leading_adverb(still).

%% The first word, skipping leading spaces and marks (**Comparing**).
ep_first_word(Text, Word, After) :-
    atom_codes(Text, Codes),
    ep_skip_nonletter(Codes, Codes1),
    ep_take_letters(Codes1, WordCodes, Rest),
    WordCodes \== [],
    atom_codes(Word, WordCodes),
    atom_codes(After, Rest).

ep_skip_nonletter([C|Codes], Rest) :-
    \+ ep_letter(C),
    !,
    ep_skip_nonletter(Codes, Rest).
ep_skip_nonletter(Codes, Codes).

%% A hyphen between two letters is part of the word: "re-reading" is one
%% gerund, not "re" and the rest.
ep_take_letters([45, C|Codes], [45|Word], Rest) :-
    ep_letter(C),
    !,
    ep_take_letters([C|Codes], Word, Rest).
ep_take_letters([C|Codes], [C|Word], Rest) :-
    ep_letter(C),
    !,
    ep_take_letters(Codes, Word, Rest).
ep_take_letters(Codes, [], Codes).

ep_letter(C) :-
    C >= 97,
    C =< 122.

%% A word in -ing heads a sentence: comparing, checking, desugaring,
%% investigating. A few nouns and prepositions that happen to end in
%% -ing are not actions. "Confirming on the published binary" announces
%% the check; "Confirming that ..." explains what is already known, as
%% "Let me confirm that" does.
ep_gerund_action(confirming, Rest) :-
    !,
    \+ ep_rest_begins(Rest, that),
    \+ ep_rest_begins(Rest, this),
    \+ ep_rest_begins(Rest, 'the fact').
ep_gerund_action(Word, Rest) :-
    ep_ing_base_word(Word),
    (   ep_ing_closing(Word)
    ->  \+ ep_ing_closing_rest(Word, Rest)
    ;   \+ ep_ing_nonaction(Word)
    ).

ep_ing_base_word(Word) :-
    atom_codes(Word, Codes),
    length(Codes, Length),
    Length >= 5,
    append(_, [105, 110, 103], Codes),
    \+ ep_ing_noun_stop(Word).

ep_ing_noun_stop(during).
ep_ing_noun_stop(something).
ep_ing_noun_stop(nothing).
ep_ing_noun_stop(anything).
ep_ing_noun_stop(everything).
ep_ing_noun_stop(thing).
ep_ing_noun_stop(things).
ep_ing_noun_stop(string).
ep_ing_noun_stop(strings).
ep_ing_noun_stop(spring).
ep_ing_noun_stop(king).
ep_ing_noun_stop(ring).
ep_ing_noun_stop(wing).
ep_ing_noun_stop(morning).
ep_ing_noun_stop(evening).

%% A gerund closing word closes with a closing rest, as its bare form
%% does: "Waiting for your input" ends, "Waiting for the rest" is work.
ep_ing_closing(waiting).
ep_ing_closing(finishing).
ep_ing_closing(stopping).
ep_ing_closing(closing).
ep_ing_closing(ending).
ep_ing_closing(leaving).
ep_ing_closing(wrapping).

ep_ing_closing_rest(waiting, Rest) :-
    (   ep_rest_begins(Rest, here)
    ;   ep_rest_begins(Rest, 'for your')
    ;   ep_rest_begins(Rest, 'for input')
    ;   ep_rest_begins(Rest, 'for instructions')
    ;   ep_rest_begins(Rest, 'for a response')
    ).
ep_ing_closing_rest(Word, Rest) :-
    memberchk(Word, [finishing, stopping, closing, ending, wrapping]),
    (   ep_rest_empty(Rest)
    ;   ep_rest_begins(Rest, here)
    ;   ep_rest_begins(Rest, 'for now')
    ;   ep_rest_begins(Rest, up)
    ).
ep_ing_closing_rest(leaving, Rest) :-
    (   ep_rest_empty(Rest)
    ;   ep_rest_begins(Rest, 'the rest')
    ;   ep_rest_begins(Rest, 'the remaining')
    ;   ep_rest_begins(Rest, 'the decision')
    ;   ep_rest_begins(Rest, it)
    ;   ep_rest_begins(Rest, that)
    ;   ep_rest_begins(Rest, you)
    ;   ep_rest_begins(Rest, here)
    ).

ep_ing_nonaction(explaining).
ep_ing_nonaction(summarizing).
ep_ing_nonaction(summarising).
ep_ing_nonaction(noting).
ep_ing_nonaction(mentioning).
ep_ing_nonaction(clarifying).
ep_ing_nonaction(concluding).
ep_ing_nonaction(saying).
ep_ing_nonaction(telling).
ep_ing_nonaction(answering).
ep_ing_nonaction(describing).
ep_ing_nonaction(offering).
ep_ing_nonaction(suggesting).
ep_ing_nonaction(recommending).
ep_ing_nonaction(highlighting).
ep_ing_nonaction(emphasizing).
ep_ing_nonaction(emphasising).
ep_ing_nonaction(outlining).
ep_ing_nonaction(recapping).
ep_ing_nonaction(restating).
ep_ing_nonaction(being).

ep_no_finite_verb(After) :-
    ep_flat_punct(After, Flat),
    atomic_list_concat([' ', Flat, ' '], '', Padded),
    \+ (   ep_finite_verb(Verb),
           atomic_list_concat([' ', Verb, ' '], '', Mark),
           sub_atom(Padded, _, _, _, Mark)
       ).

ep_flat_punct(Text, Flat) :-
    atom_codes(Text, Codes),
    ep_flat_codes(Codes, FlatCodes),
    atom_codes(Flat, FlatCodes).

ep_flat_codes([], []).
ep_flat_codes([C|Codes], [32|Out]) :-
    memberchk(C, [46, 44, 59, 58, 33, 63, 40, 41, 34, 96]),
    !,
    ep_flat_codes(Codes, Out).
ep_flat_codes([C|Codes], [C|Out]) :-
    ep_flat_codes(Codes, Out).

ep_finite_verb(is).
ep_finite_verb(are).
ep_finite_verb(was).
ep_finite_verb(were).
ep_finite_verb(has).
ep_finite_verb(have).
ep_finite_verb(had).
ep_finite_verb(shows).
ep_finite_verb(show).
ep_finite_verb(takes).
ep_finite_verb(take).
ep_finite_verb(makes).
ep_finite_verb(make).
ep_finite_verb(gives).
ep_finite_verb(give).
ep_finite_verb(means).
ep_finite_verb(mean).
ep_finite_verb(proves).
ep_finite_verb(prove).
ep_finite_verb(produces).
ep_finite_verb(produce).
ep_finite_verb(works).
ep_finite_verb(work).
ep_finite_verb(seems).
ep_finite_verb(seem).
ep_finite_verb(appears).
ep_finite_verb(appear).
ep_finite_verb(noticed).
ep_finite_verb(found).
ep_finite_verb(saw).
ep_finite_verb(realized).
ep_finite_verb(observed).
ep_finite_verb(will).
ep_finite_verb(can).
ep_finite_verb(could).
ep_finite_verb(should).
ep_finite_verb(would).
ep_finite_verb(must).
ep_finite_verb(may).
ep_finite_verb(might).
ep_finite_verb(does).
ep_finite_verb(do).
ep_finite_verb(did).
ep_finite_verb(needs).
ep_finite_verb(need).
ep_finite_verb(requires).
ep_finite_verb(require).
ep_finite_verb(enables).
ep_finite_verb(enable).
ep_finite_verb(allows).
ep_finite_verb(allow).
ep_finite_verb(lets).
ep_finite_verb(let).
ep_finite_verb(causes).
ep_finite_verb(cause).

ep_dangle_subject('i\'m', gerund).
ep_dangle_subject('i’m', gerund).
ep_dangle_subject('i am', gerund).
ep_dangle_subject('i\'m now', gerund).
ep_dangle_subject('i’m now', gerund).
ep_dangle_subject('i am now', gerund).
ep_dangle_subject('i\'m going to', bare).
ep_dangle_subject('i’m going to', bare).
ep_dangle_subject('i am going to', bare).
ep_dangle_subject('i\'m about to', bare).
ep_dangle_subject('i’m about to', bare).
ep_dangle_subject('i am about to', bare).
ep_dangle_subject('i need to', bare).
ep_dangle_subject('now i need to', bare).
ep_dangle_subject('next i need to', bare).
ep_dangle_subject('i have to', bare).
ep_dangle_subject('now i have to', bare).
ep_dangle_subject('i should', bare).
ep_dangle_subject('now i should', bare).
ep_dangle_subject('let\'s', bare).
ep_dangle_subject('i\'ll', bare).
ep_dangle_subject('i’ll', bare).
ep_dangle_subject('i will', bare).
ep_dangle_subject('i\'ll now', bare).
ep_dangle_subject('i’ll now', bare).
ep_dangle_subject('i will now', bare).
ep_dangle_subject('now i\'ll', bare).
ep_dangle_subject('now i’ll', bare).
ep_dangle_subject('now i will', bare).
ep_dangle_subject('now let me', bare).
ep_dangle_subject('now, i\'ll', bare).
ep_dangle_subject('now, i’ll', bare).
ep_dangle_subject('now, i will', bare).
ep_dangle_subject('now, let me', bare).
ep_dangle_subject('next i\'ll', bare).
ep_dangle_subject('next i’ll', bare).
ep_dangle_subject('next i will', bare).
ep_dangle_subject('next, i\'ll', bare).
ep_dangle_subject('next, i’ll', bare).
ep_dangle_subject('next, i will', bare).
ep_dangle_subject('next let me', bare).
ep_dangle_subject('next, let me', bare).
ep_dangle_subject('then i\'ll', bare).
ep_dangle_subject('then i’ll', bare).
ep_dangle_subject('then i will', bare).
ep_dangle_subject('then let me', bare).
ep_dangle_subject('then, i\'ll', bare).
ep_dangle_subject('then, i’ll', bare).
ep_dangle_subject('then, i will', bare).
ep_dangle_subject('then, let me', bare).
ep_dangle_subject('after that, i\'ll', bare).
ep_dangle_subject('after that, i’ll', bare).
ep_dangle_subject('after that, i will', bare).
ep_dangle_subject('after that, let me', bare).
ep_dangle_subject('let me', bare).

ep_nonaction_word(know).
ep_nonaction_word(explain).
ep_nonaction_word(summarize).
ep_nonaction_word(summarise).
ep_nonaction_word(note).
ep_nonaction_word(mention).
ep_nonaction_word(clarify).
ep_nonaction_word(say).
ep_nonaction_word(tell).
ep_nonaction_word(answer).
ep_nonaction_word(describe).
ep_nonaction_word(conclude).
ep_nonaction_word(restate).
ep_nonaction_word(recap).
ep_nonaction_word(highlight).
ep_nonaction_word(emphasize).
ep_nonaction_word(emphasise).
ep_nonaction_word(outline).
ep_nonaction_word(offer).
ep_nonaction_word(suggest).
ep_nonaction_word(recommend).
ep_nonaction_word(assure).
ep_nonaction_word(confirm).
ep_nonaction_word(be).

ep_usage_add(usage(P1, C1, R1, T1, H1), usage(P2, C2, R2, T2, H2),
             usage(P, C, R, T, H)) :-
    P is P1 + P2,
    C is C1 + C2,
    R is R1 + R2,
    T is T1 + T2,
    H is H1 + H2.

ep_usage_object(usage(P, C, R, T, H),
                json([prompt_tokens-P,
                      completion_tokens-C,
                      total_tokens-T,
                      prompt_tokens_details-json([cached_tokens-H]),
                      completion_tokens_details-json([reasoning_tokens-R])])).

ep_reply_usage(Resp0, Usage, Resp) :-
    (   catch(json_parse(Resp0, Body0), _, fail),
        ep_usage_object(Usage, Object),
        ep_json_set(Body0, usage, Object, Body)
    ->  json_codes(Body, Resp)
    ;   Resp = Resp0
    ).

%% The preamble said before the action and the continuation's text are
%% one assistant message, as they would have been had the tool call come
%% with the preamble. A continuation with a tool call and no text keeps
%% the preamble.
ep_merge_continuation(Resp0, Resp1, Resp) :-
    ep_reply_text(Resp0, Text0),
    ep_reply_text(Resp1, Text1),
    (   Text0 == ''
    ->  Text = Text1
    ;   Text1 == ''
    ->  Text = Text0
    ;   Text1 == Text0
    ->  Text = Text0
    ;   ep_mid_word(Text0)
    ->  atomic_list_concat([Text0, Text1], Text)
    ;   atomic_list_concat([Text0, '\n\n', Text1], Text)
    ),
    (   Text == ''
    ->  Resp = Resp1
    ;   ep_reply_with_text(Resp1, Text, Resp)
    ).

ep_reply_text(Resp, Text) :-
    (   catch(json_parse(Resp, json(Pairs)), _, fail),
        memberchk(choices-[json(Choice)|_], Pairs),
        memberchk(message-json(Message), Choice),
        memberchk(content-Text0, Message),
        atom(Text0),
        Text0 \== ''
    ->  Text = Text0
    ;   Text = ''
    ).

ep_reply_with_text(Resp0, Text, Resp) :-
    (   catch(json_parse(Resp0, json(Pairs)), _, fail),
        memberchk(choices-[json(Choice0)|Rest], Pairs),
        memberchk(message-json(Message0), Choice0),
        ep_json_set(json(Message0), content, Text, Message),
        ep_json_set(json(Choice0), message, Message, Choice),
        ep_json_set(json(Pairs), choices, [Choice|Rest], Body)
    ->  json_codes(Body, Resp)
    ;   Resp = Resp0
    ).

ep_continued_add(Count) :-
    (   catch(nb_getval('$ep_continued', Was), _, fail)
    ->  true
    ;   Was = 0
    ),
    Now is Was + Count,
    nb_setval('$ep_continued', Now).

ep_continued(Continued) :-
    (   catch(nb_getval('$ep_continued', Value), _, fail)
    ->  Continued = Value
    ;   Continued = 0
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
    ep_session_id(Request, Session),
    (   ep_responses_chat_body(Session, Body, ChatBody)
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
        ->  ep_responses_reply(Session, Request, Model, Stream,
                               ChatReplyCodes, Reply)
        ;   Reply = reply(Status, ChatHeaders, ChatReplyCodes)
        )
    ;   ep_error_reply(Request, 400, 'model and input are required', Reply)
    ).

ep_responses_chat_body(Body, ChatBody) :-
    ep_responses_chat_body('-', Body, ChatBody).

ep_responses_chat_body(Session, Body, ChatBody) :-
    ep_json_get(Body, model, Model),
    ep_json_get(Body, input, Input),
    ep_responses_messages(Session, Input, Messages0),
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
    ep_responses_messages('-', Input, Messages).

ep_responses_messages(_Session, Input, Messages) :-
    atom(Input),
    Input \== '',
    !,
    Messages = [json([role-user, content-Input])].
ep_responses_messages(Session, Input, Messages) :-
    is_list(Input),
    !,
    ep_r_items(Session, Input, [], Messages).

ep_r_items(Session, [], Pending, Messages) :-
    ep_r_flush(Session, Pending, Messages).
ep_r_items(Session, [json(Pairs)|Items], Pending, Messages) :-
    memberchk(type-function_call, Pairs),
    !,
    ep_r_function_call(json(Pairs), Call),
    ep_r_items(Session, Items, [Call|Pending], Messages).
ep_r_items(Session, [Item|Items], Pending, Messages) :-
    ep_r_flush(Session, Pending, Here),
    ep_r_item_message(Session, Item, Message),
    !,
    ep_r_items(Session, Items, [], Rest),
    ep_r_cons(Here, Message, Rest, Messages).
ep_r_items(Session, [_|Items], Pending, Messages) :-
    ep_r_flush(Session, Pending, Here),
    ep_r_items(Session, Items, [], Rest),
    append(Here, Rest, Messages).

ep_r_flush(_, [], []).
ep_r_flush(Session, Pending, [Message]) :-
    Pending = [_|_],
    reverse(Pending, Calls),
    ep_reasoning_memo_calls(Session, Calls, Reasoning),
    ep_r_assistant_calls(Calls, Reasoning, Message).

%% The field is always present, empty when the reply has no reasoning:
%% DeepSeek's thinking mode refuses an assistant turn that omits it, and
%% accepts an empty one when thinking is off.
ep_r_assistant_calls(Calls, Reasoning,
                     json([role-assistant, tool_calls-Calls,
                           reasoning_content-Reasoning])).

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

ep_r_item_message(Session, json(Pairs), Message) :-
    memberchk(type-message, Pairs),
    memberchk(role-Role0, Pairs),
    ep_r_role(Role0, Role),
    (   memberchk(content-Content0, Pairs)
    ->  ep_r_text(Content0, Text)
    ;   Text = ''
    ),
    (   Role == assistant
    ->  ep_reasoning_memo_text(Session, Text, Reasoning)
    ;   Reasoning = ''
    ),
    ep_r_assistant_text(Role, Text, Reasoning, Message).
ep_r_item_message(_, json(Pairs), Message) :-
    memberchk(type-function_call_output, Pairs),
    memberchk(call_id-Id, Pairs),
    (   memberchk(output-Output, Pairs)
    ->  ep_r_text(Output, Text)
    ;   Text = ''
    ),
    Message = json([role-tool, tool_call_id-Id, content-Text]).

ep_r_assistant_text(Role, Text, Reasoning,
                    json([role-Role, content-Text,
                          reasoning_content-Reasoning])).

ep_r_role(developer, system) :-
    !.
ep_r_role(Role, Role).

%% DeepSeek's thinking mode requires an assistant turn's reasoning_content
%% back on the next request, and Codex does not carry a reasoning item
%% through (it drops one from its input). The endpoint remembers the last
%% reasoning per session, under the tool calls or the text it belonged to,
%% and puts it on the assistant messages the next request rebuilds.
ep_reasoning_memo_calls(Session, Calls, Reasoning) :-
    ep_memo_calls_key(Calls, Key),
    ep_reasoning_memo_get(Session, Key, Reasoning).

ep_reasoning_memo_text(_, '', '') :-
    !.
ep_reasoning_memo_text(Session, Text, Reasoning) :-
    ep_memo_text_key(Text, Key),
    ep_reasoning_memo_get(Session, Key, Reasoning).

ep_memo_calls_key(Calls, Key) :-
    findall(Id, ep_memo_call_id(Calls, Id), Ids),
    atomic_list_concat(Ids, ',', Joined),
    atomic_list_concat(['calls:', Joined], Key).

ep_memo_call_id(Calls, Id) :-
    member(Call, Calls),
    Call = json(Pairs),
    memberchk(id-Id, Pairs).

ep_memo_text_key(Text, Key) :-
    ep_value_digest(Text, Digest),
    atomic_list_concat(['text:', Digest], Key).

ep_reasoning_memo_get('-', _, '') :-
    !.
ep_reasoning_memo_get(Session, Key, Text) :-
    (   catch(nb_getval('$ep_reasoning_memo', Memo), _, fail)
    ->  true
    ;   Memo = []
    ),
    (   memberchk(memo(Session, Key)-Found, Memo)
    ->  Text = Found
    ;   Text = ''
    ).

ep_reasoning_memo_store('-', _, _) :-
    !.
ep_reasoning_memo_store(_, _, '') :-
    !.
ep_reasoning_memo_store(Session, Key, Text) :-
    (   catch(nb_getval('$ep_reasoning_memo', Memo0), _, fail)
    ->  true
    ;   Memo0 = []
    ),
    exclude(ep_memo_same(Session, Key), Memo0, Memo1),
    Memo2 = [memo(Session, Key)-Text|Memo1],
    ep_memo_trim(Memo2, 200, Memo),
    nb_setval('$ep_reasoning_memo', Memo).

ep_memo_same(Session, Key, memo(Session0, Key0)-_) :-
    Session0 == Session,
    Key0 == Key.

ep_memo_trim(List, N, List) :-
    length(List, Length),
    Length =< N,
    !.
ep_memo_trim([_|Rest], N, Trimmed) :-
    ep_memo_trim(Rest, N, Trimmed).

ep_reasoning_memo_reply('-', _, _, _) :-
    !.
ep_reasoning_memo_reply(_, _, _, '') :-
    !.
ep_reasoning_memo_reply(Session, Content, Calls, Reasoning) :-
    ep_reasoning_memo_reply_text(Session, Content, Reasoning),
    ep_reasoning_memo_reply_calls(Session, Calls, Reasoning).

ep_reasoning_memo_reply_text(_, '', _) :-
    !.
ep_reasoning_memo_reply_text(Session, Content, Reasoning) :-
    ep_memo_text_key(Content, Key),
    ep_reasoning_memo_store(Session, Key, Reasoning).

ep_reasoning_memo_reply_calls(_, [], _) :-
    !.
ep_reasoning_memo_reply_calls(Session, Calls, Reasoning) :-
    ep_memo_calls_key(Calls, Key),
    ep_reasoning_memo_store(Session, Key, Reasoning).

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

ep_responses_reply(Session, Request, Model, Stream, ChatCodes, Reply) :-
    ep_cors(Request, Cors),
    (   Stream == true
    ->  ep_responses_events(Session, ChatCodes, Model, Events, _Response),
        ep_responses_sse(Events, Sse),
        append(Cors, ['Content-Type'-'text/event-stream',
                      'Cache-Control'-'no-cache'], Headers),
        Reply = reply(200, Headers, Sse)
    ;   ep_responses_events(Session, ChatCodes, Model, _Events, Response),
        json_codes(Response, Codes),
        Reply = reply(200, ['Content-Type'-'application/json'|Cors], Codes)
    ).

ep_responses_events(ChatCodes, Model, Events, Response) :-
    ep_responses_events('-', ChatCodes, Model, Events, Response).

ep_responses_events(Session, ChatCodes, Model, Events, Response) :-
    ep_responses_chat(ChatCodes, Content, Calls, Reasoning),
    ep_reasoning_memo_reply(Session, Content, Calls, Reasoning),
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

ep_responses_chat(ChatCodes, Content, Calls, Reasoning) :-
    json_parse(ChatCodes, json(Pairs)),
    memberchk(choices-[json(Choice)|_], Pairs),
    memberchk(message-json(Message), Choice),
    ep_responses_content(Message, Content),
    ep_responses_calls(Message, Calls),
    ep_responses_reasoning(Message, Reasoning).

ep_responses_reasoning(Message, Reasoning) :-
    (   memberchk(reasoning_content-Value, Message),
        atom(Value)
    ->  Reasoning = Value
    ;   Reasoning = ''
    ).

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

