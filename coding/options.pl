%% coding/options.pl -- the defaults every code generator shares.
%%
%% A language has a directory of its own: `coding/<language>/codegen.pl'.
%% It loads this file, and gets the options every generator is expected to
%% start from. The reasoning library is one directory above `coding/'.
%%
%% THE TWO EFFORT NAMES ARE PER PROVIDER. `library(llm)' treats
%% `effort(L)' and `reasoning_effort(L)' as the same level under two names
%% and refuses two different levels in one request. Both defaults are
%% `none': the generator spends no reasoning tokens unless a caller asks
%% for them. The provider's own field is used:
%%
%%     Anthropic    effort(none)
%%     OpenAI       reasoning_effort(none)
%%
%% A caller may override either name; codegen_options/2 rewrites it to the
%% provider's field, so the two defaults never meet in one request.
%%
%% A further default is one more `codegen_default/2' fact. It is filled in
%% unless the caller names the same key -- for example:
%%
%%     codegen_default(max_tokens, 16000).
%%     codegen_default(temperature, 0).
%%
%% The two effort keys are special-cased below, because which one is used
%% depends on the provider. `key_env/1' is not an option of `library(llm)':
%% codegen.pl reads it and points the selected provider at that variable.
%% The provider, model and base_url are special-cased too: codegen.pl
%% points library(llm) at the endpoint before the call.
%%
%% THE PROVIDER, ITS MODEL AND ITS ENDPOINT ARE ONE SETTING. Change the
%% three facts together when you change the provider. A call's
%% provider(P), model(M) or base_url(U) overrides any of them.
%%
%%     Anthropic:  the facts below.
%%     DeepSeek:   provider openai, model 'deepseek-flash', base_url
%%                 'https://api.deepseek.com/v1/chat/completions'.
%%     Local:      provider openai, model 'qwen3.6-colibri', base_url
%%                 'http://127.0.0.1:8000/v1/chat/completions'.
%%
%% DeepSeek's Anthropic-compatible endpoint is
%% 'https://api.deepseek.com/anthropic/v1/messages'; the facts below
%% already send effort(none), so its reasoning is off there too. Raise
%% `effort' in a call (or in `codegen_default(effort, ...)') to turn it
%% on.

codegen_default(provider, anthropic).
codegen_default(model, 'claude-sonnet-4-5').
codegen_default(base_url, 'https://api.anthropic.com/v1/messages').
codegen_default(effort, none).
codegen_default(reasoning_effort, none).
codegen_default(key_env, 'REASONING_API_KEY').

%% codegen_options(+Overrides, -Options)
%%
%% Overrides are option terms of `library(llm)' -- provider(P), model(M),
%% max_tokens(N), temperature(T), and so on -- plus either effort(L) or
%% reasoning_effort(L). The answer is what to hand to `llm_chat/3':
%% the provider's native effort option, the caller's other options, and
%% any `codegen_default/2' the caller did not override.
codegen_options(Overrides, Options) :-
    codegen_provider(Overrides, Provider),
    codegen_effort_option(Provider, Overrides, EffortOption),
    codegen_model(Overrides, Provider, Model),
    codegen_other_options(Overrides, Rest),
    Options = [EffortOption, provider(Provider), model(Model)|Rest].

%% provider(P) in the call wins; otherwise the project's
%% codegen_default(provider, P); otherwise library(llm)'s
%% llm_default_provider/1, and anthropic if that is not loaded.
codegen_provider(Overrides, Provider) :-
    (   memberchk(provider(P), Overrides)
    ->  Provider = P
    ;   codegen_default(provider, P)
    ->  Provider = P
    ;   catch(llm_default_provider(P), _, fail)
    ->  Provider = P
    ;   Provider = anthropic
    ).

%% model(M) in the call wins. Otherwise the project's model applies when
%% the call uses the project's provider; a provider chosen for one call
%% keeps library(llm)'s default model, so `provider(openai)' does not send
%% an Anthropic model to OpenAI.
codegen_model(Overrides, Provider, Model) :-
    (   memberchk(model(M), Overrides)
    ->  Model = M
    ;   codegen_default(provider, Provider),
        codegen_default(model, M)
    ->  Model = M
    ;   catch(llm_model_default(Provider, M), _, fail)
    ->  Model = M
    ;   Model = ''
    ).

%% either effort name in Overrides wins over the default; the answer is
%% spelled the way the provider reads it. Two different levels are
%% refused here, as they are in library(llm).
codegen_effort_option(Provider, Overrides, Option) :-
    (   codegen_effort_override(Overrides, Level)
    ->  codegen_native_effort(Provider, Level, Option)
    ;   codegen_effort_default(Provider, Option)
    ).

codegen_effort_override(Overrides, Level) :-
    (   memberchk(effort(E), Overrides)
    ->  (   memberchk(reasoning_effort(R), Overrides),
            E \== R
        ->  throw(error(llm_error(conflicting_effort, E-R), codegen_options/2))
        ;   Level = E
        )
    ;   memberchk(reasoning_effort(R), Overrides)
    ->  Level = R
    ).

codegen_native_effort(anthropic, Level, effort(Level)) :- !.
codegen_native_effort(_, Level, reasoning_effort(Level)).

codegen_effort_default(anthropic, Option) :-
    !,
    codegen_default(effort, Level),
    Option = effort(Level).
codegen_effort_default(_, Option) :-
    codegen_default(reasoning_effort, Level),
    Option = reasoning_effort(Level).

%% codegen_key_env(+Overrides, -KeyVar)
%%
%% The environment variable the provider's key is read from. The default
%% is REASONING_API_KEY; `key_env(NAME)' in Overrides replaces it.
codegen_key_env(Overrides, KeyVar) :-
    (   memberchk(key_env(K), Overrides)
    ->  KeyVar = K
    ;   codegen_default(key_env, KeyVar)
    ).

%% codegen_base_url(+Overrides, +Provider, -BaseUrl)
%%
%% The full request URL. `base_url(U)' in the call wins. Otherwise the
%% project's base_url applies when the call uses the project's provider; a
%% provider chosen for one call keeps library(llm)'s endpoint. A provider
%% library(llm) has no endpoint for needs base_url(U) in the call.
codegen_base_url(Overrides, Provider, BaseUrl) :-
    (   memberchk(base_url(U), Overrides)
    ->  BaseUrl = U
    ;   codegen_default(provider, DefaultProvider),
        Provider == DefaultProvider,
        codegen_default(base_url, U)
    ->  BaseUrl = U
    ;   catch(llm_provider(Provider, U, _), _, fail)
    ->  BaseUrl = U
    ;   throw(error(llm_error(missing_base_url, Provider), codegen_options/2))
    ).

%% The caller's options, less the names codegen handles itself (the
%% provider, model, two effort names, key variable and base URL), plus
%% defaults whose key the caller did not name.
codegen_other_options(Overrides, Options) :-
    findall(O,
            (   member(O, Overrides),
                O \= provider(_),
                O \= model(_),
                O \= effort(_),
                O \= reasoning_effort(_),
                O \= key_env(_),
                O \= base_url(_)
            ),
            Rest),
    findall(Option,
            (   codegen_default(Key, Value),
                Key \== provider,
                Key \== model,
                Key \== effort,
                Key \== reasoning_effort,
                Key \== key_env,
                Key \== base_url,
                Option =.. [Key, Value],
                \+ codegen_key(Key, Rest)
            ),
            Defaults),
    append(Rest, Defaults, Options).

codegen_key(Key, Options) :-
    member(O, Options),
    functor(O, Key, _).
