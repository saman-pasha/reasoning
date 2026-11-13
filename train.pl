%% library/reasoning/train.pl -- trains the SHIPPED tagger, the one
%% tagger_pretrained/1 loads, into the knowledge base this process proves
%% against, under the name `tagger', and measures it. Run by
%% tools/tagger/train.sh over a fresh --embed store, after
%% library/reasoning/generate.pl has written the data:
%%
%%     sh tools/tagger/train.sh                 # writes library/reasoning/model.rows
%%
%% It trains on library/reasoning/generated/training.txt -- the pairs as
%% a FILE in the tree, so the data the shipped model learned from is
%% committed beside it -- with tagger_train/2's other defaults, 500 steps
%% over 32768 pairs; about four minutes on four cores. Errors are thrown, not printed: a
%% training that did not finish leaves no model to ship. The numbers it
%% prints are the model measured on sentences the training never saw, on
%% real prose it must refuse, and on the corpus's own lesson lines typed
%% bare -- `The noun casa means house.' -- read back to their terms
%% (tagger_lessons/4).
%%
%%     main/0                   the program: trains under `tagger', measures, prints one line

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/tagger)).

main :-
    normalise_generated_dir(Dir),
    atom_concat(Dir, '/training.txt', Training),
    tagger_train(tagger, [pairs_file(Training), verbose(true)]),
    tagger_load(tagger, M),
    tagger_evaluate(M, 30001, 300, report(Tok, Sent, Acc, _)),
    tagger_refused(M, 6001, 300, Rate),
    tagger_lessons(M, 1, 400, Lessons),
    format("tagger: tokens ~4f sentences ~4f accepted ~4f, real prose refused ~4f, lessons typed bare read ~4f~n", [Tok, Sent, Acc, Rate, Lessons]),
    tagger_free(M).
