%% cocolog -- library/reasoning/page.pl: a page translated, sentence by sentence.
%%
%%     cocolog --embed KB-spanish -s library/reasoning/page.pl -- page.txt
%%     cocolog --embed KB-spanish -s library/reasoning/page.pl -- page.txt english
%%     cocolog --embed KB-both    -s library/reasoning/page.pl -- page.txt spanish italian
%%
%% Over a knowledge base teach.pl has taught. Each sentence of the file
%% comes out as its translation, or as `?' with the words no lesson knows,
%% and the last line counts both. The second argument names the language
%% to translate INTO, as reason_translate/3 takes it; without it the words
%% decide. A THIRD names the language the page is IN, and then the page
%% goes from one language to the other through the intermediate
%% representation, with no English sentence written -- which wants both
%% lessons in the store, each taught under its own name.
%%
%%     main/0                                   the program: each sentence, then the count
%%     page_lines(+Text, +From, +Into, -Lines)  the page as Sentence-Out pairs
%%     page_line(+Sentence, +Out)               one pair written, or `?' and its unknown words

:- use_module(library(reasoning/translate)).

main :-
    current_prolog_flag(argv, [_|Args]),
    (   Args = [File|More]
    ->  ( More = [Into|Rest] -> true ; Into = any, Rest = [] ),
        ( Rest = [From|_] -> true ; From = none ),
        read_file_to_codes(File, Codes), atom_codes(Text, Codes),
        page_lines(Text, From, Into, Lines),
        forall(member(S-Out, Lines), page_line(S, Out)),
        aggregate_all(count, ( member(_-Out, Lines), Out \= refused(_) ), Done),
        length(Lines, All),
        format("~n~d of ~d sentences translated~n", [Done, All])
    ;   format("usage: cocolog --embed KB -s library/reasoning/page.pl -- FILE [INTO [FROM]]~n", [])
    ).

page_lines(Text, none, Into, Lines) :- !, reason_translate_page(Text, Into, Lines).
page_lines(Text, From, Into, Lines) :- reason_translate_page(Text, From, Into, Lines).

page_line(S, refused(Ws)) :- !, format("? ~w~n    (untranslated: ~w)~n", [S, Ws]).
page_line(S, Out) :- format("~w~n    ~w~n", [S, Out]).
