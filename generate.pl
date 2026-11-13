%% library/reasoning/generate.pl -- writes the training data the shipped
%% tagger learns from, as files in the tree.
%%
%%     cocolog -s library/reasoning/generate.pl                  # the defaults
%%     cocolog -s library/reasoning/generate.pl -- 32768 300     # pairs, evaluation pairs
%%     sh tools/tagger/train.sh                                  # runs this, then train.pl
%%
%% library(reasoning/normalise) makes a pair from a seed and nothing else,
%% so the corpus is reproducible from the code, the lexicon and the
%% lessons -- and it is still written down, because data a training used
%% and nobody can read back is data lost the moment a shape, a lexicon
%% file or a lesson line changes under it. Two files, one canonical term
%% a line (normalise_save/2, read back by normalise_load/2):
%%
%%     library/reasoning/generated/training.txt      seeds 1..N, the pairs tagger_train/2 fits
%%     library/reasoning/generated/evaluation.txt    seeds 30001..30000+M, the pairs
%%                                                   tagger_evaluate/4 measures on: sentences
%%                                                   the training never saw
%%
%% The negatives -- real sentences the tagger must refuse -- are not
%% generated: lexicon/prose.txt holds them, and the lessons are in corpus/.
%% A generator is a .pl in this library and its output is committed beside
%% the lexicon and the corpus, which is the rule for every file under
%% library/reasoning: nothing trains on what the tree does not hold.
%%
%%     main/0                   the program: the two files written, and a line each on stdout

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [NA|_], atom_number(NA, N) -> true ; N = 32768 ),
    ( Args = [_, MA|_], atom_number(MA, M) -> true ; M = 300 ),
    normalise_generated_dir(Dir),
    atom_concat(Dir, '/training.txt', Training),
    atom_concat(Dir, '/evaluation.txt', Evaluation),
    normalise_corpus(N, Pairs),
    normalise_save(Pairs, Training),
    length(Pairs, NP),
    format("generate: wrote ~w pairs, seeds 1..~w, to ~w~n", [NP, N, Training]),
    From is 30001, To is 30000 + M,
    findall(P, ( between(From, To, I), normalise_pair(I, P) ), Eval),
    normalise_save(Eval, Evaluation),
    length(Eval, NE),
    format("generate: wrote ~w pairs, seeds ~w..~w, to ~w~n", [NE, From, To, Evaluation]).
