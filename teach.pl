%% cocolog -- library/reasoning/teach.pl: a language's lessons learned into the knowledge base.
%%
%%     cocolog --embed KB-spanish -s library/reasoning/teach.pl -- spanish
%%     cocolog --embed KB-italian -s library/reasoning/teach.pl -- italian
%%     cocolog --embed KB-both    -s library/reasoning/teach.pl -- spanish spanish
%%     cocolog --embed KB-both    -s library/reasoning/teach.pl -- italian italian
%%
%% Reads corpus/<language>.txt -- the grammar, written by hand -- and then
%% corpus/vocabulary/<language>.txt -- the words, written by build.pl -- and
%% learns both, in chunks of a few hundred lines so the reader's heap
%% stays small, into whatever knowledge base this process proves against.
%% Under --embed that is a store on disk, and every later process over the
%% same store finds the lesson learned: page.pl and any program that calls
%% reason_translate/2 start in a second where the learning takes a minute
%% or two.
%%
%% A SECOND ARGUMENT NAMES THE LESSON, and that is how two languages share
%% one store. Without it the lesson is learned plain -- the language with
%% no name -- and two plain lessons in one store would answer for each
%% other's words, so one language a store was the rule. Learned under
%% names they share nothing (reason_learn/3), and the intermediate
%% representation then translates between them: reason_translate/4 takes
%% Italian into Spanish over one store with no English sentence written.
%%
%% The grammar goes first, so its meaning of a word is the first the
%% translator finds (`casa' means `house' before it means `home').
%%
%%     main/0                               the program: the language and the name from argv
%%     teach(+Language, +Name)              the grammar, then the vocabulary, into this store
%%     teach_file(+File, +Name, -N)         a lesson file's lines learned, N terms
%%     teach_chunks(+Lines, +Name, +N0, -N) 400 lines to a reason_learn call
%%     teach_text(+Text, +Name, -Terms)     one chunk, learned plain or under Name

:- use_module(library(reasoning/translate)).
:- use_module(library(reasoning/normalise)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [Lang|More] -> true ; Lang = spanish, More = [] ),
    ( More = [Name|_] -> true ; Name = none ),
    teach(Lang, Name).

teach(Lang, Name) :-
    normalise_corpus_dir(Dir),
    atomic_list_concat([Dir, '/', Lang, '.txt'], Grammar),
    atomic_list_concat([Dir, '/vocabulary/', Lang, '.txt'], Words),
    teach_file(Grammar, Name, N1), format("~w: ~d terms~n", [Grammar, N1]),
    ( exists_file(Words) -> teach_file(Words, Name, N2), format("~w: ~d terms~n", [Words, N2]) ; format("no vocabulary file ~w~n", [Words]) ).

%% the lines of a lesson file that are not comments, learned 400 at a time
teach_file(File, Name, N) :-
    read_file_to_codes(File, Codes), split_string(Codes, "\n", " \t\r", Lines0),
    findall(L, ( member(S, Lines0), S \== "", \+ sub_string(S, 0, 1, _, '#'), atom_string(L, S) ), Lines),
    teach_chunks(Lines, Name, 0, N).

teach_chunks([], _, N, N).
teach_chunks(Lines, Name, N0, N) :-
    ( length(Chunk, 400), append(Chunk, Rest, Lines) -> true ; Chunk = Lines, Rest = [] ),
    atomic_list_concat(Chunk, ' ', Text),
    teach_text(Text, Name, Terms), length(Terms, K), N1 is N0 + K,
    teach_chunks(Rest, Name, N1, N).

teach_text(Text, none, Terms) :- !, reason_learn(Text, Terms).
teach_text(Text, Name, Terms) :- reason_learn(Text, Name, Terms).
