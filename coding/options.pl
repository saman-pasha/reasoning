%% coding/options.pl -- the defaults every code generator shares.
%%
%% A language has a directory of its own: `coding/<language>/codegen.pl'.
%% It loads this file, and gets the options every generator is expected to
%% start from. The reasoning library is one directory above `coding/'.
%%
%% THE TWO EFFORT NAMES ARE PER PROVIDER. `library(llm)' treats
%% `effort(L)' and `reasoning_effort(L)' as the same level under two names
%% and refuses two different levels in one request. So the default here is
%% the provider's own field:
%%
%%     Anthropic    effort(low)
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
%% depends on the provider.

codegen_default(effort, low).
codegen_default(reasoning_effort, none).

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
    codegen_other_options(Overrides, Rest),
    Options = [EffortOption|Rest].

%% provider(P) is library(llm)'s own default, anthropic.
codegen_provider(Overrides, Provider) :-
    (   memberchk(provider(P), Overrides)
    ->  Provider = P
    ;   Provider = anthropic
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

%% The caller's options, less the two effort names (the native one is
%% already at the head), plus defaults whose key the caller did not name.
codegen_other_options(Overrides, Options) :-
    findall(O,
            (   member(O, Overrides),
                O \= effort(_),
                O \= reasoning_effort(_)
            ),
            Rest),
    findall(Option,
            (   codegen_default(Key, Value),
                Key \== effort,
                Key \== reasoning_effort,
                Option =.. [Key, Value],
                \+ codegen_key(Key, Rest)
            ),
            Defaults),
    append(Rest, Defaults, Options).

codegen_key(Key, Options) :-
    member(O, Options),
    functor(O, Key, _).
