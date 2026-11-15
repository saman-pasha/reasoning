%% coding/shell.pl -- one POSIX single-quote quoting for every generator.
%%
%%     codegen_shell_quote(+Value, -Quoted)
%%
%% Quoted is an atom whose text is Value wrapped in single quotes, with
%% every embedded single quote written the POSIX way: close the quote, a
%% backslash, the quote, reopen the quote. A path with a space, a dollar
%% sign or a backtick therefore reaches the command as one word.
%%
%% `~w' in a format string prints such an atom as its characters, so a
%% command is built with `~w' and the quoted atoms; `~s' would do too.

codegen_shell_quote(Value, Quoted) :-
    (   atom(Value)
    ->  atom_codes(Value, Codes)
    ;   string(Value)
    ->  string_codes(Value, Codes)
    ;   format(atom(Text), '~w', [Value]),
        atom_codes(Text, Codes)
    ),
    codegen_shell_escape(Codes, Escaped),
    Q = 39,
    append([Q|Escaped], [Q], All),
    atom_codes(Quoted, All).

codegen_shell_escape([], []).
codegen_shell_escape([C|Codes], Out) :-
    (   C =:= 39
    ->  Out = [39, 92, 39, 39|Rest]
    ;   Out = [C|Rest]
    ),
    codegen_shell_escape(Codes, Rest).

%% codegen_env_prefix(+KeyVar, -Prefix)
%%
%% The shell prefix that removes the selected key, CODING_ENDPOINT_KEY_ENV
%% and library(llm)'s two key defaults from a child's environment. Prefix
%% is empty when there is nothing to remove; otherwise it ends with a
%% space, ready to stand before the command.
codegen_env_prefix(KeyVar, Prefix) :-
    codegen_env_keys(KeyVar, Keys),
    codegen_env_unset(Keys, Options),
    (   Options == ''
    ->  Prefix = ''
    ;   format(atom(Prefix), 'env ~s ', [Options])
    ).

codegen_env_keys(KeyVar, Keys) :-
    (   atom(KeyVar),
        KeyVar \== ''
    ->  Keys0 = [KeyVar]
    ;   Keys0 = []
    ),
    append(Keys0,
           ['CODING_ENDPOINT_KEY_ENV', 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY'],
           Keys1),
    sort(Keys1, Keys).

codegen_env_unset([], '').
codegen_env_unset([Key|Rest], Options) :-
    codegen_shell_quote(Key, QKey),
    codegen_env_unset(Rest, RestOptions),
    format(atom(Options), '-u ~w ~s', [QKey, RestOptions]).
