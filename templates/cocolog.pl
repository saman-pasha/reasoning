%% templates/cocolog.pl -- Cocolog as a template of the translator's level 2
%% (TRANSLATOR-PLAN.md, since reasoning 1.67.0): what library(reasoning/logic)
%% needs to write the logic form as Cocolog source and to read it back. A
%% programming language connects to level 2 alone; its rows are facts, as a
%% natural language's are.
%%
%% THE SLOTS:
%%
%%     lg_code(L)                      L is a programming language's template
%%     lg_code_reserved_prefix(L, P)   a predicate the system already
%%                                     defines (a builtin, a library's:
%%                                     predicate_property/2 says
%%                                     imported_from/1) is written with the
%%                                     prefix P, and read back without it:
%%                                     `John sleeps.' is is_sleep(john), as
%%                                     sleep/1 is Cocolog's
%%     lg_code_name(L, Meaning/Arity, Name)
%%                                     a predicate written by another name
%%                                     than its meaning; none: a predicate's
%%                                     name is its meaning (the English word)
%%     lg_code_query_mark(L, Mark)     the mark before a query

lg_code(cocolog).
lg_code_reserved_prefix(cocolog, is_).
lg_code_query_mark(cocolog, '?-').
