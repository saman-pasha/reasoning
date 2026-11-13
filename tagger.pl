%% cocolog -- library(reasoning/tagger): the network that labels typed text for
%% library(reasoning/reason), trained on what library(reasoning/normalise) makes.
%%
%%     :- use_module(library(reasoning/tagger)).
%%
%% TIER 2, clauses only, over library(tensor_expr) and library(torch). It
%% LOADS where torch is absent -- the vocabulary, the encoding, the tag ids
%% and the padding plan are pure, and test/tagger.pl proves them on any box
%% -- and a goal that touches a tensor then throws torch's existence_error.
%%
%% WHAT IT IS. A TAGGER: one label a token, from the alphabet
%% library(reasoning/normalise) fixes, so that normalise_assemble/3 can
%% rebuild the sentence in the shapes library(reasoning/reason) reads and
%% the grammar can verify it. It never emits a word: a name it has never
%% seen is copied by the assembler, and a wrong label costs a refusal or a
%% wrong term the grammar still reads -- so tag accuracy is the correctness
%% number, and tagger_evaluate/4 answers it on sentences training never saw.
%%
%% AND THE LEXICON JUDGES WHAT IT LABELS. Shown 875 sentences of real
%% government prose, the tagger "read" a tenth of them -- `Boston, Mass.'
%% as mass(boston), a heading as business(small) -- because every sentence
%% it had ever seen had a reading, and the grammar's defaults are
%% positional. So a tagging is put to the lexicon before the assembler
%% sees it (tagger_sane/2, eleven rules, each a clause), and one the lexicon
%% contradicts comes back X throughout, the twelfth tag, which the
%% assembler refuses. Three ways of teaching the network itself to refuse
%% were tried and each took a tenth of the hand-written sentences it should
%% read; the rules take none. What the lexicon knows is the known_*.txt
%% files beside the generator's -- every SemCor-counted noun, verb,
%% adjective and adverb, whatever its sense -- because the generator's
%% nouns are things to own and `Death put a period' walked past a judge that
%% had never heard of death. tagger_refused/4 measures the refusals over
%% prose.txt, WordNet's example sentences, which nothing here trains on.
%%
%% THE NETWORK. Two embeddings -- the word, 24 wide, and its SHAPE (the case
%% it was written in and, for a lower-case word, the ending it carries: -s,
%% -ly, -ing, -ed or none, WITH the classes the lexicon knows the word by,
%% adjective and noun, as two bits; a capitalised word is a
%% name whatever it ends in and carries no class; a number is one word,
%% <num>, with a shape of its own; a word between quotation marks keeps its
%% word and takes the shape `quoted'), 4 wide --
%% concatenated into 28; a GRU over the sentence in each -- and the width
%% stayed 4 when the classes joined it, because widening it to 8 widened
%% every activation the autograd graph keeps: the training went from
%% finishing in 205 s to thrashing against the box's 16 GB at 14.0 GB
%% resident, with more kernel time than user time and 45 000 major faults
%% direction, 96 wide each, so a token's label sees what came before it and
%% what follows; a linear head from the two states to the twelve tags inside
%% the grammar, M among them -- a MENTIONED word, which the assembler writes
%% between quotation marks, so `The noun casa means house' comes back as
%% the lesson's line. X is never the network's to answer: it is the
%% lexicon's verdict on a tagging, below. Sequences are padded to the
%% longest in the batch and batched position-major, as tutorials/tensor/41
%% batches its sequences; a MASK holds a sequence's state still past its
%% end, so the backward pass starts at the real last word and not at
%% padding. The forward is a tensor_expr PROCEDURE, tg_forward//5, and
%% exec/1 frees every state and gate it made but the logits.
%%
%% AN UNSEEN WORD IS THE POINT. A word outside the vocabulary is `<unk>',
%% and a capitalised one keeps the shape `upper'. Training replaces an
%% open-class word by `<unk>' at some of its positions -- a name at a
%% quarter, a noun or an adjective at a fifth, a verb at a seventh,
%% deterministic in the pair and the position so a run reproduces -- and
%% the network learns the label of a word it does not know from where it
%% stands. Then `Zed owns a bicycle' tags as `Alice owns a car' does, and
%% the assembler writes Zed and bicycle. (Without the nouns in that set,
%% measured, `must pay the rent' lost its object: `rent' was tagged D, the
%% only label an unknown lower-case word had ever carried.) THE CLASS BITS
%% ARE NOT WITHHELD WITH IT, so the network is entitled to require them:
%% a lower-case word at mask 0 is one the lexicon knows is neither an
%% adjective nor a thing, and an adjective the lexicon has never heard of
%% wears the same code. That is a claim about the LEXICON and it is
%% answered there -- known_adj.txt carries every adjective index.adj names
%% rather than only the SemCor-counted ones, 16 706 where it held 5 102,
%% because `registered' has three adjective senses and no count. Withholding
%% the bits at training, as the word ids are withheld, is the answer for a
%% word WordNet does not know at all, and it does not fit on the box this
%% was trained on -- tg_dropout/6 below carries what it costs.
%%
%% THE KNOWLEDGE BASE IS THE MODEL FILE. tagger_train/2 saves the parameters
%% through params_save/2 and the vocabulary as one fact, '$tg_vocab'/2, so a
%% process run over a store (--embed DIR, or a server) hands the model to
%% the next one, and a --local process keeps it for its own life. No file
%% format, and nothing exported.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     tagger_train(+Name, +Options)
%%         Trains on normalise_corpus/2 and saves under Name -- the parameters
%%         through params_save/2, the vocabulary as '$tg_vocab'/3 rows of
%%         two hundred words. Options:
%%         pairs_file(F) train on the pairs normalise_load/2 reads from F
%%         (library/reasoning/generated/training.txt, what generate.pl
%%         wrote) instead of generating them, the first pairs(N) of them;
%%         pairs(N) the corpus, seeds 1..N (32768); steps(K) optimiser steps
%%         (500); batch(B) sequences a step (128); lr(R) Adam's rate (0.005);
%%         seed(S) the tensor seed (45); min_count(C) the times a word must
%%         be seen to have an embedding row of its own (2); hidden(H) the
%%         width of each GRU (96) -- a saved model carries its own, in the
%%         shapes of its parameters;
%%         verbose(true) prints the loss.
%%
%%     tagger_load(+Name, -Model)        the parameters back as parameters, and the vocabulary
%%     tagger_free(+Model)               frees them
%%
%%     tagger_tag(+Model, +Tokens, -Tags)
%%         One sentence's tokens, as reason_tokens/2 gives them without the
%%         stop, to one tag each.
%%     tagger_tag_all(+Model, +TokenLists, -TagLists)      many sentences, ONE batch
%%
%%     tagger_normalise(+Model, +Text, -Controlled, -Terms)
%%         Prose in: every sentence tagged, assembled with
%%         normalise_assemble/3, and the whole read by reason_text/2. FAILS
%%         when the grammar refuses what came out, and reason_refused/2 over
%%         Controlled then names the sentence.
%%
%%     tagger_ask(+Model, +Text, -Answers)
%%     tagger_ask(+Model, +Text, -Answers, -Explanations)
%%         Prose in, questions answered: the controlled text as
%%         tagger_normalise/4 makes it, then reason_ask/2 over it, so
%%         `Well, does Dana rent a flat in Bristol?' answers yes(fact)
%%         against the knowledge base. The subject state is NOT reset, and
%%         a subject pronoun in a question's first two words is replaced by
%%         that subject BEFORE tagging, so `Is she registered?' asks about
%%         the subject the last paragraph left and the controlled text
%%         names her. Fails as tagger_normalise/4 fails. With a fourth
%%         argument, reason_ask/3: the explanation in sentences beside each
%%         answer, and `Why ...?' typed answers because(Text).
%%
%%     tagger_pretrained(-Model)
%%         A trained model without training: the one named `tagger' in the
%%         knowledge base this process proves against, when there is one --
%%         what a program over its own --embed store keeps after running
%%         library/reasoning/train.pl there once -- and otherwise the model
%%         shipped beside the library, library/reasoning/model.rows, the
%%         rows tagger_export/2 wrote, consulted as a module (muted, so
%%         nothing is written through) and loaded as tagger_load/2 loads.
%%         Once a process, and tagger_free/1 on it forgets that.
%%         $COCOLOG_TAGGER_MODEL names another such file. Raises
%%         existence_error(tagger, pretrained) when there is neither.
%%
%%     tagger_export(+Name, +File)
%%         The model's rows -- '$tg_vocab'/3, '$te_param'/3, '$te_chunk'/4
%%         -- written to File, one canonical term a line: the shipped
%%         model's form, which tools/tagger/train.sh writes and a fresh
%%         store consults (cocolog --embed DIR run File true).
%%
%%     tagger_refused(+Model, +From, +N, -Rate)
%%         Over N real sentences of prose.txt from the From-th, the
%%         fraction tagger_normalise/4 refuses. The other half of
%%         correctness: a tagger that reads `Boston, Mass.' as a fact is
%%         wrong even when every tag of every sentence it should read is
%%         right.
%%
%%     tagger_sane(+Tokens, +Tags)
%%         The lexicon's judgement of a tagging: fails where the lexicon
%%         contradicts it, eleven rules. Applied by tagger_tag/3 and
%%         tagger_tag_all/3, whose refused sentence comes back X throughout.
%%
%%     tagger_lessons(+Model, +From, +N, -Rate)
%%         Over N lines of the corpus (library/reasoning/corpus/*.txt, as
%%         normalise_lessons/1 lists them) from the From-th, each with its
%%         quotation marks taken off by normalise_bare/2 -- `The noun casa
%%         means house.' -- the fraction tagger_normalise/4 reads back to
%%         the terms the line itself gives: a lesson typed as prose, put
%%         to the tagger that was trained on the corpus's words.
%%
%%     tagger_evaluate(+Model, +From, +N, -Report)
%%         Over the pairs of seeds From..From+N-1 -- sentences a training
%%         over seeds 1..Pairs never saw when From is past Pairs.
%%         Report = report(TokenAccuracy, SentenceAccuracy, Accepted, N):
%%         the fraction of tags right, of sentences with every tag right,
%%         and of sentences whose assembled text parses to the clean text's
%%         terms.
%%
%%   pure, and proved without torch:
%%
%%     tagger_vocabulary(+Pairs, -Vocab)    every word of the pairs, sorted; `<pad>' 0, `<unk>' 1, the words from 2
%%     tagger_vocabulary(+Pairs, +MinCount, -Vocab)   only the words seen MinCount times
%%     tagger_word_id(+Vocab, +Word, -Id)   1 for a word not in it
%%     tagger_size(+Vocab, -V)              the rows of the word embedding
%%     tagger_encode(+Vocab, +Tokens, -Ids, -Shapes)     a shape is the case, the ending and the classes; 1 lower,
%%                                          2 upper, 3 comma, then +3 for -s, +6 for -ly, +9 for -ing, +12 for -ed
%%                                          on a lower-case word only, and +16 for each class the lexicon knows
%%                                          it by (adjective 1, noun 2), so `red' is 61 and `car' 33;
%%                                          14 a quoted word, 15 a number; 0 is padding
%%     tagger_tag_id(?Tag, ?Id)             normalise_tags/1's order, S 0 .. B 10
%%     tagger_pad(+Seqs, -Plan)             seq(Ids, Shapes, TagIds|none) each, to
%%                                          plan(N, M, IdRows, ShapeRows, MaskRows, Flat):
%%                                          M rows of N, position-major, padding 0, its
%%                                          mask 0.0 and its gold tag D
%%
%% THE CORPUS IS THE CAPABILITY. The first draft trained on 512 pairs from
%% a lexicon of ten names and twelve nouns, and read its own kind of
%% sentence at 0.99 -- and dropped the noun of `a small blue lamp', because
%% no object it had seen carried two adjectives, and dropped `in Lagos'
%% after `lives', because the only place it had seen after a verb was an
%% adjunct to be thrown away. Every such miss was a SHAPE the generator did
%% not make, never the network, and every one was fixed in
%% library(reasoning/normalise): fifty-five shapes, thirteen transforms, and a
%% lexicon no longer written by hand at all -- files beside the library,
%% 2500 census names and some seventeen thousand WordNet words ranked by
%% use, read as they are needed (library/reasoning/lexicon/SOURCES.md). A
%% tagger generalises to the words it never saw exactly as far as the
%% shapes it did.
%%
%% MEASURED, on a four-core box with no GPU, the defaults: 500 steps over
%% 32768 pairs train in about four minutes; over 300 pairs training never
%% saw (seeds past the corpus) 0.988 of the tags and 0.93 to 0.96 of the
%% sentences are right and 0.95 to 0.97 assemble and parse to the clean
%% terms, a training apart (0.9997 and 0.997 before the ten lesson shapes
%% joined, whose bare mentions are the hard part); of eighty-two hand-written sentences whose
%% names, nouns, adjectives and verbs are outside the lexicon -- questions,
%% shared subjects and seventeen lines of a lesson typed bare among them
%% -- seventy-eight or more give their terms, a different one missed from
%% one training to the next; and of the corpus's 194 lesson lines typed
%% bare, 0.88 read back to their own terms (tagger_lessons/4) --
%% test/tagger.pl holds all three. And the other half: of 300 WordNet example sentences from
%% prose.txt, 0.93 to 0.94 came back refused where the network alone
%% refused 0.85, and of 757 sentences of real government prose 0.96 where
%% it was 0.87 -- with the hand-written sentences read exactly as before,
%% which is what the learned refusers could not do. With the judge reading
%% the known_*.txt files rather than the generator's concrete nouns alone
%% it is 0.95 to 0.96 of prose.txt, the same model going from 28 sentences
%% read to 11.
%% Over the WordNet lexicon the corpus is the
%% lever twice over: 8192 pairs read 0.96 of the unseen sentences whatever
%% the step count (the loss fell to 0.001 while the evaluation stood still,
%% which is memorising), 16384 read 0.987 and 32768 read 0.993 in 140
%% seconds. A corpus too large to memorise is what makes a tagger
%% generalise, and the steps and not the pairs are what a training costs.
%% The lesson is tutorials/library/45-tagger.pl.

:- use_module(library(torch)).
:- use_module(library(tensor_expr)).
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

:- dynamic '$tg_vocab'/3.

%% ---- the shape of the network ---------------------------------------------

tg_hidden(96).
tg_word_dim(24).
tg_shape_dim(4).
tg_shapes(64).                     % padding, then case x ending x the lexicon's classes, below

%% ---- the vocabulary ---------------------------------------------------------

tagger_vocabulary(Pairs, Vocab) :- tagger_vocabulary(Pairs, 1, Vocab).

%% tagger_vocabulary(+Pairs, +MinCount, -Vocab): the words seen at least
%% MinCount times, sorted. A word seen once cannot be learned and is `<unk>'
%% in all but name, and over a lexicon of thousands most words are seen
%% once -- so tagger_train/2 keeps those at two by default, which bounds the
%% embedding and is exactly the dropout the rare words would have had.
tagger_vocabulary(Pairs, MinCount, Vocab) :-
    findall(W, ( member(pair(_, Toks, _, _, _), Pairs), member(T, Toks), tg_word(T, W) ), Ws0),
    msort(Ws0, Sorted),
    tg_counted(Sorted, MinCount, Words),
    tg_vocab(Words, Vocab).

tg_counted([], _, []).
tg_counted([W|Ws], Min, Out) :-
    tg_run(W, Ws, 1, N, Rest),
    ( N >= Min -> Out = [W|Out1] ; Out = Out1 ),
    tg_counted(Rest, Min, Out1).
tg_run(W, [W|Ws], N0, N, Rest) :- !, N1 is N0 + 1, tg_run(W, Ws, N1, N, Rest).
tg_run(_, Ws, N, N, Ws).

tg_vocab(Words, vocab(Words, Assoc, Classes)) :-
    findall(W-Id, ( nth0(I, Words, W), Id is I + 2 ), Ps),
    list_to_assoc(Ps, Assoc),
    tg_class_assoc(Classes).

tagger_word_id(vocab(_, Assoc, _), W, Id) :- ( get_assoc(W, Assoc, Id0) -> Id = Id0 ; Id = 1 ).

tagger_size(vocab(Words, _, _), V) :- length(Words, N), V is N + 2.

%% the word a token carries, and its SHAPE: the case it was written in and,
%% for a lower-case word, the ending it carries -- none, -s, -ly, -ing or
%% -ed, so `flies' and `curses' look like verbs and `wholly' like an adverb
%% before any word is known. A capitalised word carries NO ending: it is a
%% name whatever it ends in. Measured before that was so: `Zed' and `Ted'
%% after `does not like' were dropped by three trainings in a row, because
%% their -ed made them a shape that twenty-three objects in sixteen thousand
%% pairs had worn, where `Bob' and `Mia' were kept every time. 0 is
%% padding; a comma is 3. A word between quotation marks keeps its word --
%% `"house"' and `house' share an embedding, and only the shape says it
%% was mentioned -- so the bare mentions the unquote transform makes are
%% read by the same row.
tg_word(word(W, _), W) :- !.
tg_word(quoted(W), W) :- !.                % a mention keeps its word: the shape carries the marks
tg_word(num(_), '<num>') :- !.             % every number is one word: its value is not its tag
tg_word(T, T).
tg_shape(_, ',', 3) :- !.
tg_shape(_, quoted(_), 14) :- !.           % a mention, its own shape
tg_shape(_, num(_), 15) :- !.              % a number, its own shape
tg_shape(_, word(_, upper), 2) :- !.       % a name, whatever it ends in
tg_shape(C, word(W, lower), S) :- !,
    tg_ending(W, E), tg_class_mask(C, W, M),
    S is 1 + 3 * E + 16 * M.
tg_shape(_, _, 1).

tg_ending(W, 2) :- sub_atom(W, _, 2, 0, ly), !.
tg_ending(W, 3) :- sub_atom(W, _, 3, 0, ing), !.
tg_ending(W, 4) :- sub_atom(W, _, 2, 0, ed), !.
tg_ending(W, 1) :- sub_atom(W, _, 1, 0, s), !.
tg_ending(_, 0).

%% AND THE CLASSES THE LEXICON KNOWS THE WORD BY, two bits beside the
%% ending: adjective 1 and noun 2, from the same table the judge reads
%% (tg_lexicon_classes/1, a class noun counted as a noun and a name left
%% out). ONLY A LOWER-CASE WORD carries them -- a name is a name whatever a
%% lexicon says of it, and a mention stands for itself.
%%
%% THE VERB AND ADVERB BITS WERE IN IT AND ARE OUT, by measurement: with
%% them, `map' and `house' -- nouns the lexicon also knows as verbs -- wore
%% a bit the corpus's verbs wore too, and the model dropped the object of
%% `Tom likes the old map' and `Vera can read the map' where it had read
%% both. A tagger needs to know that a word can be an adjective and that it
%% can be a thing; what else the word can be is what the SENTENCE says.
%%
%% It is here because the network could not learn an ADJECTIVE from
%% anything else. `red', `big' and `small' are picked rarely enough to be
%% <unk>, and an adjective before an object with a comma filler after it is
%% a fifth of a per cent of the tokens: measured over four generators
%% differing only in how often they make the shape, the same training read
%% it 0, 20 and 207 times out of 384, by the luck of its minimum, and a
%% SEVEN-LINE change to the corpus took a model from 207 to 0 with every
%% tag n-gram count unmoved. A class the lexicon states is a feature the
%% network cannot lose that way: every adjective of the grid wears the
%% same bit whatever word it is.
%%
%% IT TIES A MODEL TO THE LEXICON FILES, which is the cost and is worth
%% saying: the shape a word is encoded with depends on lexicon/*.txt, so a
%% tree without them encodes every word at mask 0 and a model trained with
%% them reads the wrong rows. The judge needs the same files, so nothing
%% that can read prose was ever without them.
tg_class_mask(Classes, W, M) :- ( get_assoc(W, Classes, M0) -> M = M0 ; M = 0 ).

%% THE TABLE TRAVELS IN THE VOCABULARY, and both other roads were measured
%% and are why. A read of tg_lexicon_classes/1 copies the whole assoc out
%% of the store -- 2.44 ms -- so asking per TOKEN, four hundred thousand
%% times over a training, was killed by the box's memory limit at 110 s.
%% One global a word is worse still: a global is found by a SCAN, 4.7 us
%% among twenty thousand and 31.5 us among the lexicon's fifty-five, and
%% the encoding of 32 768 pairs had not finished in two minutes. An assoc
%% built once and carried in the vocab term is a heap lookup at every
%% token and costs nothing -- and the vocabulary is where a word's class
%% belongs anyway. It is the LEXICON's table and not the pairs', so the
%% shape a word is encoded with is the same at training and at tagging
%% whether or not the word was frequent enough to have an embedding.
tg_class_assoc(Classes) :-
    ( catch(nb_getval('$tg_classes', _), _, fail) -> true ; \+ \+ tg_class_build ),
    nb_getval('$tg_classes', Classes).

%% BUILT UNDER `\+ \+', because what it builds it on is far larger than
%% what it keeps: the judge's table is a word to a LIST of classes, over
%% two hundred thousand pairs sorted and grouped, and cocolog gives the
%% heap back on backtracking and not otherwise. The answer goes to the
%% store as a global, which a failed branch does not undo, so the caller
%% reads it back with the transients gone.
tg_class_build :-
    (   catch(tg_lexicon_classes(Lex), _, fail)
    ->  assoc_to_list(Lex, Pairs),
        findall(W-M, ( member(W-Cs, Pairs), tg_bits([adj-1, noun-2, class-2], Cs, 0, M), M > 0 ), Ms),
        list_to_assoc(Ms, Classes)
    ;   empty_assoc(Classes)
    ),
    nb_setval('$tg_classes', Classes).

tg_bits([], _, M, M).
tg_bits([C-B|Rest], Cs, M0, M) :-
    ( memberchk(C, Cs), 0 =:= M0 /\ B -> M1 is M0 + B ; M1 = M0 ),
    tg_bits(Rest, Cs, M1, M).

tagger_encode(_, [], [], []).
tagger_encode(V, [T|Ts], [Id|Ids], [S|Ss]) :-
    V = vocab(_, _, Classes),
    tg_word(T, W), tagger_word_id(V, W, Id), tg_shape(Classes, T, S),
    tagger_encode(V, Ts, Ids, Ss).

tagger_tag_id(Tag, Id) :- normalise_tags(Tags), nth0(Id, Tags, Tag).

%% ---- the padding plan ---------------------------------------------------------
%% N sequences to M positions: at each position the N ids, the N shapes, the
%% N masks as one-element rows (1.0 inside a sequence, 0.0 past its end),
%% and the gold tags position-major with D where there is padding -- the
%% order cat(Ls, 0) puts the logits in.

tagger_pad(Seqs, plan(N, M, IdRows, ShapeRows, MaskRows, Flat)) :-
    length(Seqs, N),
    findall(L, ( member(seq(Ids, _, _), Seqs), length(Ids, L) ), Ls),
    tg_max(Ls, M), M1 is M - 1,
    tagger_tag_id('D', Pad),
    findall(Row, ( between(0, M1, P), findall(Id, ( member(seq(Ids, _, _), Seqs), tg_at(P, Ids, 0, Id) ), Row) ), IdRows),
    findall(Row, ( between(0, M1, P), findall(S, ( member(seq(_, Shs, _), Seqs), tg_at(P, Shs, 0, S) ), Row) ), ShapeRows),
    findall(Row, ( between(0, M1, P), findall([Mk], ( member(seq(Ids, _, _), Seqs), length(Ids, L), ( P < L -> Mk = 1.0 ; Mk = 0.0 ) ), Row) ), MaskRows),
    findall(T, ( between(0, M1, P), member(seq(_, _, Tags), Seqs), ( Tags == none -> T = Pad ; tg_at(P, Tags, Pad, T) ) ), Flat).

tg_at(P, List, Default, X) :- ( nth0(P, List, X0) -> X = X0 ; X = Default ).

tg_max([X], X) :- !.
tg_max([X|Xs], M) :- tg_max(Xs, M0), ( X > M0 -> M = X ; M = M0 ).

%% ---- a batch: the plan as tensors -------------------------------------------------
%% Made when a step needs it and freed after: the plans of a whole corpus
%% are lists and cost nothing, where the tensors of 128 batches at once ran
%% the module's handle table out (a handle came back 0, and the next step
%% died with `tensor expected, found 0').

tg_batch(Seqs, Gold, Batch) :- tagger_pad(Seqs, Plan), tg_batch_tensors(Plan, Gold, Batch).

tg_batch_tensors(plan(_, _, IdRows, ShapeRows, MaskRows, Flat), Gold, batch(Ins, Shs, Mks, Flat, Y)) :-
    findall(T, ( member(R, IdRows), T := R ), Ins),
    findall(T, ( member(R, ShapeRows), T := R ), Shs),
    findall(T, ( member(R, MaskRows), T := R ), Mks),
    (   Gold == yes
    ->  tg_inside_tags(K), one_hot(Flat, K, Y)
    ;   Y = none
    ).

tg_batch_free(batch(Ins, Shs, Mks, _, Y)) :-
    free_all(Ins), free_all(Shs), free_all(Mks),
    ( Y == none -> true ; tensor_free(Y) ).

%% ---- the parameters ---------------------------------------------------------------

tg_parameters(V, Ps) :- tg_hidden(H), tg_parameters(V, H, Ps).
tg_parameters(V, H, Ps) :-
    tg_word_dim(Dw), tg_shape_dim(Ds), tg_shapes(NS),
    In is Dw + Ds, H2 is 2 * H,
    tg_inside_tags(K),
    Ew := parameter(randn([V, Dw]) * 0.5),
    Es := parameter(randn([NS, Ds]) * 0.5),
    tg_gru_params(In, H, F), tg_gru_params(In, H, B),
    Wo := parameter(glorot(H2, K)), Bo := parameter(zeros([1, K])),
    append([[Ew, Es], F, B, [Wo, Bo]], Ps), !.

tg_gru_params(In, H, [Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn]) :-
    Wz := parameter(glorot(In, H)), Uz := parameter(glorot(H, H)), Bz := parameter(zeros([1, H])),
    Wr := parameter(glorot(In, H)), Ur := parameter(glorot(H, H)), Br := parameter(zeros([1, H])),
    Wn := parameter(glorot(In, H)), Un := parameter(glorot(H, H)), Bn := parameter(zeros([1, H])), !.

%% the head answers the whole alphabet, one output a tag id, so that the
%% argmax IS the id; X, outside, is never a gold target and so never
%% learned -- it is what a tagging the lexicon contradicts comes back as,
%% tagger_sane/2 below. (It was the alphabet less one, on the assumption
%% that X was the last tag; when M joined after it the head lost M, the
%% network could never answer a mention, and the shipped model read a
%% lesson typed bare at 0.05.)
tg_inside_tags(K) :- normalise_tags(Tags), length(Tags, K).

tg_unpack(Ps, Ew, Es, F, B, Wo, Bo) :-
    length(F, 9), length(B, 9), append([[Ew, Es], F, B, [Wo, Bo]], Ps), !.

%% ---- the forward, as procedures --------------------------------------------------------
%% tg_gru(+Cell, +X, +H, +Mask, -H2): one step over the batch's rows, and the
%% mask keeps the old state where a sequence has ended.

tg_gru([Wz, Uz, Bz, Wr, Ur, Br, Wn, Un, Bn], X, H, Mk, H2) -->
    Z = sigmoid(X matmul Wz + H matmul Uz + Bz),
    R = sigmoid(X matmul Wr + H matmul Ur + Br),
    C = tanh(X matmul Wn + (R * H) matmul Un + Bn),
    Hc = (1.0 - Z) * H + Z * C,
    H2 = Hc * Mk + H * (1.0 - Mk).

%% the embedded input at every position: the word's row beside the shape's
tg_embeds(_, _, [], [], []) --> [].
tg_embeds(Ew, Es, [In|Ins], [Sh|Shs], [X|Xs]) -->
    X = cat([index_rows(Ew, In), index_rows(Es, Sh)], 1),
    tg_embeds(Ew, Es, Ins, Shs, Xs).

%% one direction: every state kept, in the order the inputs came
tg_scan(_, [], [], _, []) --> [].
tg_scan(Cell, [X|Xs], [Mk|Mks], H, [H2|Hs]) -->
    tg_gru(Cell, X, H, Mk, H2),
    tg_scan(Cell, Xs, Mks, H2, Hs).

%% the head at every position, over the two states
tg_heads(_, _, [], [], []) --> [].
tg_heads(Wo, Bo, [Hf|Hfs], [Hb|Hbs], [L|Ls]) -->
    L = cat([Hf, Hb], 1) matmul Wo + Bo,
    tg_heads(Wo, Bo, Hfs, Hbs, Ls).

%% tg_forward(+Ps, +Ins, +Shapes, +Masks, -Logits): [M*N, 11], position-major
tg_forward(Ps, Ins, Shs, Mks, Logits) -->
    { tg_unpack(Ps, Ew, Es, F, B, Wo, Bo), Ins = [In0|_],
      F = [_, Uz|_], tensor_shape(Uz, [Hd, _]) },              % the width is the model's own
    [N] = shape(In0),
    H0 = zeros([N, Hd]),
    tg_embeds(Ew, Es, Ins, Shs, Xs),
    tg_scan(F, Xs, Mks, H0, Hfs),
    { reverse(Xs, Rxs), reverse(Mks, Rmks) },
    tg_scan(B, Rxs, Rmks, H0, Hbs0),
    { reverse(Hbs0, Hbs) },
    tg_heads(Wo, Bo, Hfs, Hbs, Ls),
    Logits = cat(Ls, 0).

%% ---- training -------------------------------------------------------------------------

tagger_train(Name, Options) :-
    tg_option(pairs(NP), Options, 32768),
    tg_option(steps(K), Options, 500),
    tg_option(batch(B), Options, 128),
    tg_option(lr(LR), Options, 0.005),
    tg_option(seed(S), Options, 45),
    tg_option(min_count(MinCount), Options, 2),
    tg_option(hidden(H), Options, 96),
    ( memberchk(verbose(true), Options) -> Verbose = yes ; Verbose = no ),
    (   memberchk(pairs_file(File), Options)
    ->  normalise_load(File, All),
        ( length(Pairs, NP), append(Pairs, _, All) -> true ; Pairs = All )
    ;   normalise_corpus(NP, Pairs)
    ),
    tagger_vocabulary(Pairs, MinCount, Vocab), Vocab = vocab(Words, _, _),
    tg_drop_table(Table),
    tg_training_sequences(Vocab, Table, Pairs, 1, PosSeqs),
    tg_by_length(PosSeqs, PosSorted), tg_chunks(PosSorted, B, PosGroups),
    findall(Plan, ( member(G, PosGroups), tagger_pad(G, Plan) ), Plans),
    seed(S),
    tagger_size(Vocab, V),
    tg_parameters(V, H, Ps0), adam_init(Ps0, St0),
    tg_fit(K, Ps0, St0, Plans, LR, Verbose, Ps),
    params_save(Name, Ps),
    tg_vocab_save(Name, Words),
    free_all(Ps).

%% the vocabulary in the store, 200 words a clause: a row must fit in a
%% page, and one clause holding thousands of words would not
tg_vocab_save(Name, Words) :-
    retractall('$tg_vocab'(Name, _, _)),
    tg_vocab_chunks(Words, Name, 0).
tg_vocab_chunks([], _, _) :- !.
tg_vocab_chunks(Words, Name, Seq) :-
    ( length(Chunk, 200), append(Chunk, Rest, Words) -> true ; Chunk = Words, Rest = [] ),
    assertz('$tg_vocab'(Name, Seq, Chunk)),
    Seq1 is Seq + 1, tg_vocab_chunks(Rest, Name, Seq1).
tg_vocab_load(Name, Words) :-
    findall(Seq-Chunk, '$tg_vocab'(Name, Seq, Chunk), Cs0), Cs0 \== [],
    msort(Cs0, Cs), findall(W, ( member(_-Chunk, Cs), member(W, Chunk) ), Words).

tg_option(Term, Options, Default) :-
    ( memberchk(Term, Options) -> true ; arg(1, Term, Default) ).

%% the pairs as sequences, with WORD DROPOUT: an open-class word is `<unk>'
%% at some of its positions -- decided by a hash of the pair's index and the
%% position, never by a random number, so a run reproduces -- and the
%% network learns the label of a word it does not know from where it
%% stands. The closed words, the fillers and the adverbs are never dropped:
%% those ARE the shape the rest is read by.
tg_training_sequences(_, _, [], _, []).
tg_training_sequences(Vocab, Table, [pair(_, Toks, Tags, _, _)|Ps], I, [seq(Ids, Shs, TagIds)|Ss]) :-
    tagger_encode(Vocab, Toks, Ids0, Shs),
    tg_dropout(Toks, Ids0, Table, I, 0, Ids),
    findall(T, ( member(Tag, Tags), tagger_tag_id(Tag, T) ), TagIds),
    I1 is I + 1,
    tg_training_sequences(Vocab, Table, Ps, I1, Ss).

tg_dropout([], [], _, _, _, []).
tg_dropout([T|Ts], [Id|Ids], Table, I, P, [Id2|Ids2]) :-
    (   tg_word(T, W), get_assoc(W, Table, Rate), tg_hash(I * 131 + P, R), R < Rate
    ->  Id2 = 1
    ;   Id2 = Id
    ),
    P1 is P + 1,
    tg_dropout(Ts, Ids, Table, I, P1, Ids2).

%% THE SHAPE IS NOT DROPPED WITH IT, AND THE ARM THAT WOULD WAS RUN FOUR
%% TIMES. `Sh mod 16' is exactly the shape without its classes -- the case
%% and the ending are 1 to 15 and the classes are what sixteen multiplies --
%% so a second hash at the same rates would hand a fifth of the adjectives
%% to the network wearing nothing but `-ed' or `-ly', and a word no lexicon
%% knows would be read from where it stands. FOUR TRAININGS WITH IT WERE
%% KILLED by this box's 16 GB at 192, 208, 212 and 226 s, where the same
%% training without it finishes at 192; the fourth was written as one pass
%% -- the encoding and both drops in a single walk, building two lists a
%% pair where the first three built four -- to test whether the cost was the
%% intermediates, and it died at the same place. So the cost is not the
%% lists and is not yet located, and the sentence that wanted it,
%% `She is registered', was answered in the lexicon instead.

%% the rate a word is dropped at, as ONE table built before the pairs are
%% walked: a name at a quarter of its positions, a noun, an adjective or an
%% adverb at a fifth, a verb -- base or third person, the verb half of a
%% phrasal one -- at about a seventh. (Three in ten and a quarter were
%% tried over the WordNet lexicon and read fewer sentences, not more: what
%% a rare word's embedding still carries is worth keeping.) (Adverbs joined when `works hard' was
%% read as works_hard over the WordNet lexicon: an unknown word after a verb
%% at the end had never been seen, because no adverb had ever been dropped.) (Looked up per token instead, with the lexicon
%% scanned through downcase_atom/2 and the inflector each time, this cost
%% 25 ms a pair: 207 of the 235 seconds an 8192-pair training took.)
%% A language is dropped as a name is, and a MENTIONED word of the corpus
%% at a third of its positions -- last in the table, so an English word
%% the lessons mention keeps its own rate, and never a closed word: the
%% lessons mention `the' and `not', and those are the shape.
tg_drop_table(Table) :-
    findall(W-0.25, ( member(C, [proper, place, language]), normalise_lexicon(C, Ws), member(X, Ws), downcase_atom(X, W) ), Names),
    findall(W-0.20, ( member(C, [noun, class, adj, adverb]), normalise_lexicon(C, Ws), member(W, Ws) ), Nouns),
    findall(W-0.15, ( member(C, [vt, vi, vpp]), normalise_lexicon(C, Vs), member(V0, Vs),
                      ( V0 = V-_ -> true ; V = V0 ), ( W = V ; normalise_third(V, W) ) ), Verbs),
    findall(W-0.33, ( normalise_lexicon(mention, Ws), member(W, Ws), \+ rl_closed(W) ), Mentions),
    append([Names, Nouns, Verbs, Mentions], All),
    keysort(All, Sorted),
    tg_first_rates(Sorted, Pairs),
    list_to_assoc(Pairs, Table).

%% one entry a word, the first rate given winning: keysort is stable, so of
%% two rates for one word the earlier list's comes first
tg_first_rates([], []).
tg_first_rates([W-R|Ws], [W-R|Pairs]) :- tg_drop_same(W, Ws, Rest), tg_first_rates(Rest, Pairs).
tg_drop_same(W, [W-_|Ws], Rest) :- !, tg_drop_same(W, Ws, Rest).
tg_drop_same(_, Ws, Ws).

tg_hash(I, R) :- S is sin(I * 78.233) * 43758.5453, R is abs(S - truncate(S)).

%% batches of NEIGHBOURS IN LENGTH: a batch is padded to its longest
%% sequence and every position costs a GRU step each way, so sixty-four
%% sentences drawn at random pay for the longest of them all -- measured,
%% sorting them first nearly halves a step
tg_by_length(Seqs, Sorted) :-
    findall(L-S, ( member(S, Seqs), S = seq(Ids, _, _), length(Ids, L) ), Keyed),
    keysort(Keyed, Ordered),
    findall(S, member(_-S, Ordered), Sorted).

tg_chunks([], _, []) :- !.
tg_chunks(Xs, B, [G|Gs]) :- length(G, B), append(G, Rest, Xs), !, tg_chunks(Rest, B, Gs).
tg_chunks(Xs, _, [Xs]).

%% the fit loop: the batches in turn, an Adam step each, the old parameters
%% and the gradients freed by the step itself
tg_fit(0, Ps, _, _, _, _, Ps) :- !.
tg_fit(K, Ps, St, Plans, LR, Verbose, PsF) :-
    length(Plans, NB), B is K mod NB, nth0(B, Plans, Plan),
    tg_batch_tensors(Plan, yes, Batch), Batch = batch(Ins, Shs, Mks, _, Y),
    exec(tg_forward(Ps, Ins, Shs, Mks, Logits)),
    L := cross_entropy(Logits, Y),
    Gs := grad(L, Ps),
    (   Verbose == yes, K mod 40 =:= 0
    ->  Lv := item(L), format("   ~w steps to go, loss ~4f~n", [K, Lv])
    ;   true
    ),
    adam_step(Ps, Gs, St, LR, Ps2, St2),
    free_all([Logits, L]), tg_batch_free(Batch),
    K1 is K - 1,
    tg_fit(K1, Ps2, St2, Plans, LR, Verbose, PsF).

%% ---- loading ------------------------------------------------------------------------------

tagger_load(Name, model(Ps, Vocab)) :-
    (   catch(tg_vocab_load(Name, Words), _, fail)
    ->  true
    ;   throw(error(existence_error(tagger, Name), tagger_load/2))
    ),
    params_load(Name, Ps),
    tg_vocab(Words, Vocab).

tagger_free(model(Ps, V)) :-
    (   catch(nb_getval('$tg_pretrained', model(Ps, V)), _, fail) -> nb_setval('$tg_pretrained', none) ; true ),
    free_all(Ps).

%% ---- tagging ---------------------------------------------------------------------------------

tagger_tag(Model, Tokens, Tags) :- tagger_tag_all(Model, [Tokens], [Tags]).

tagger_tag_all(_, [], []) :- !.
tagger_tag_all(model(Ps, Vocab), TokenLists, TagLists) :-
    findall(seq(Ids, Shs, none), ( member(Toks, TokenLists), tagger_encode(Vocab, Toks, Ids, Shs) ), Seqs),
    tg_batch(Seqs, no, Batch), Batch = batch(Ins, Shs, Mks, _, _),
    exec(tg_forward(Ps, Ins, Shs, Mks, Logits)),
    Got := list(argmax(Logits, 1)),
    tensor_free(Logits), tg_batch_free(Batch),
    length(Seqs, N),
    tg_decode(Seqs, 0, N, Got, TagLists0),
    tg_heads(TokenLists, TagLists0, TagLists1),
    tg_judged(TokenLists, TagLists1, TagLists).

%% ONE THING THE LEXICON REWRITES RATHER THAN REFUSES, because the term is
%% the same either way: a capitalised word at the head of a sentence, or
%% right after a fronted `is', `does' or a modal, that the network calls M
%% is S when it could stand as a subject (normalise_head_bare/1: not
%% closed, and a name or a word the lexicon does not know) -- the rule the
%% generator wrote the training data by, applied to the answer, so that
%% `Los is the plural of el' after `In Spanish,' is Los and not "los",
%% and `Is Dana late?' asks about Dana. Sentence by sentence, at the B
%% breaks, the noise before the head passed over.
tg_heads([], [], []).
tg_heads([Toks|TLs], [Tags|Tgs], [Out|Outs]) :-
    tg_head_rule(Toks, Tags, head, Out),
    tg_heads(TLs, Tgs, Outs).

tg_head_rule([], [], _, []).
tg_head_rule([T|Ts], [G|Gs], Pos, [G1|Out]) :-
    (   G == 'B' -> G1 = G, Pos1 = head
    ;   G == 'D' -> G1 = G, Pos1 = Pos
    ;   T == ',' -> G1 = G, Pos1 = Pos
    ;   Pos == head, T = word(W, upper), G == 'M', normalise_head_bare(W) -> G1 = 'S', Pos1 = rest
    ;   Pos == head, T = word(F, _), ( rl_copula(F) ; rl_aux(F) ; rl_modal(F) ) -> G1 = G, Pos1 = head   % the subject follows a fronted verb
    ;   G1 = G, Pos1 = rest
    ),
    tg_head_rule(Ts, Gs, Pos1, Out).

tg_decode([], _, _, _, []).
tg_decode([seq(Ids, _, _)|Ss], I, N, Got, [Tags|Ts]) :-
    length(Ids, L), L1 is L - 1,
    findall(Tag, ( between(0, L1, P), J is P * N + I, nth0(J, Got, G), Id is round(G), tagger_tag_id(Tag, Id) ), Tags),
    I1 is I + 1,
    tg_decode(Ss, I1, N, Got, Ts).

%% ---- the lexicon's judgement of a tagging -------------------------------------------------
%% A tagging the LEXICON contradicts is refused -- the sentence comes back
%% X throughout -- before the assembler sees it. These are the fragments the
%% grammar would read, because its defaults are positional: `Boston, Mass.'
%% tagged S D O is mass(boston), `Loan policies' is policies(loan), `This
%% should be played' is should_played(this). Eleven rules, a bullet each; the
%% code is tagger_sane/2 and the clauses of tg_sane_token/4:
%%
%%   * a sentence has a relation word, and no token is outside;
%%   * a relation word is a closed word of the grammar (is, may, will), or
%%     lower case and not the first token and not a word the lexicon knows
%%     only as a noun, an adjective or an adverb: `Mass', `policies';
%%   * a subject at the head of the sentence, capitalised only by its
%%     position, is not a common word of the lexicon unless it is a known
%%     first name: `Loan', `Small' -- and Rose or Bill, who are both;
%%   * a subject, an object or an adjective is not a closed word: `This',
%%     `It', `up' -- and a subject or an object in lower case is not a
%%     word the lexicon knows only as a verb: `Discuss values' (unless
%%     its base is some other word, as `keys' is `key');
%%   * an adjective is not a word the lexicon knows only as an adverb:
%%     `often' after `is';
%%   * a word between quotation marks is M and nothing else: the marks
%%     are the reader's own signal, and a tagger that dropped one would
%%     lose what the text said most plainly;
%%   * a number, in digits or in words, counts a noun (T), is an object
%%     (O) or is noise (D);
%%   * `much' and `many' are the object asked for (O) or noise (D): `how
%%     much';
%%   * a question word is a subject or an object: `who' S, `what' and
%%     `where' O;
%%   * a sentence with a mention in it is related by `is', or by a verb
%%     some lesson of the corpus uses -- means, precedes, ends in, takes
%%     -- because `Boston, Mass.' tagged M R would otherwise be a fact
%%     about the word `boston', and because the verbs a lesson may use
%%     are the corpus's to give, not the network's to guess;
%%   * and a sentence assembled to nothing -- every token dropped -- is
%%     refused, not read as nothing (tg_assemble_all/3).
%% A subject pronoun tagged S passes (`she' may be a subject: the grammar
%% resolves it), and a language's name may head a sentence as a subject
%% (`Spanish is a language'): it joins the first names in the judge's lexicon.
%%
%% An unknown word passes every rule, so `Priya snores' and `Zed owns a
%% bicycle' read as before. (A second network trained to tell generated
%% sentences from real ones was tried instead and refused a sixth of the
%% hand-written sentences: it learned the two sources apart, not what the
%% grammar reads.)

tg_judged([], [], []).
tg_judged([Toks|TLs], [Tags0|Tgs], [Out|Outs]) :-
    tg_repair(Toks, Tags0, Tags),
    (   tagger_sane(Toks, Tags)
    ->  Out = Tags
    ;   length(Tags, L), findall('X', between(1, L, _), Out)
    ),
    tg_judged(TLs, Tgs, Outs).

%% A TAGGING THE TRAINING DATA CALLS IMPOSSIBLE IS CORRECTED, NOT REFUSED,
%% which is the one place the judge does more than say no. Counted over the
%% 32 768 pairs of generated/training.txt, what sits between a determiner
%% and the noun it counts is A 5 001 times, T 762 and S 25 -- and D NEVER.
%% So a lower-case word the judge's own lexicon knows as an adjective,
%% tagged D between a T and an O, is an A.
%%
%% IT TAKES A REFUSAL'S PLACE AND NOT A READING'S: without it the sentence
%% is not refused, it is READ WITH THE ADJECTIVE SILENTLY GONE, which is the
%% worse of the two. `Kim rents a small flat in Oslo.' keeps `small' and so
%% does `Honestly, Kim rents a small flat.'; put the head filler and the
%% place in the same sentence and the shipped model drops it -- neither
%% alone does, and 787 of the training pairs carry exactly that combination,
%% so the count is not the lever and 1.2.42 already measured that it is not.
tg_repair(Toks, Tags0, Tags) :-
    (   append(Pre, ['T', 'D', 'O'|Post], Tags0),
        length(Pre, N), Ix is N + 1,
        nth0(Ix, Toks, word(W, lower)),
        tg_lexicon_classes(Lex), tg_classes(W, Lex, Cs), memberchk(adj, Cs)
    ->  append(Pre, ['T', 'A', 'O'|Post], Tags1),
        tg_repair(Toks, Tags1, Tags)
    ;   Tags = Tags0
    ).

tagger_sane(Toks, Tags) :-
    \+ memberchk('X', Tags),
    memberchk('R', Tags),
    tg_lexicon_classes(Lex),
    forall(( nth0(I, Toks, Tok), nth0(I, Tags, Tag) ), tg_sane_token(I, Tok, Tag, Lex)),
    tg_sane_mentions(Toks, Tags).

%% a sentence about a word is related by the copula or by a verb of the
%% lessons -- both forms, `precedes' and `precede' -- or by a preposition
%% joined to one (`ends in')
%% -- sentence by sentence, at the B breaks: `"casa" means "house" and
%% Alice owns a car' has a mention in its first sentence only
tg_sane_mentions(Toks, Tags) :-
    tg_segments(Toks, Tags, Segs),
    normalise_lexicon(wverb, Vs),
    forall(member(seg(STs, SGs), Segs),
           (   \+ memberchk('M', SGs)
           ->  true
           ;   forall(( nth0(I, SGs, 'R'), nth0(I, STs, word(W, _)) ), ( rl_closed(W) ; memberchk(W, Vs) ))
           )).

tg_segments([], [], []) :- !.
tg_segments(Toks, Tags, [seg(STs, SGs)|Segs]) :-
    tg_upto_b(Toks, Tags, STs, SGs, RT, RG),
    tg_segments(RT, RG, Segs).
tg_upto_b([], [], [], [], [], []).
tg_upto_b([_|Ts], ['B'|Gs], [], [], Ts, Gs) :- !.
tg_upto_b([T|Ts], [G|Gs], [T|STs], [G|SGs], RT, RG) :- tg_upto_b(Ts, Gs, STs, SGs, RT, RG).

tg_sane_token(_, quoted(_), Tag, _) :- !, Tag == 'M'.                  % a word in quotation marks is mentioned, whatever else
tg_sane_token(I, word(W, Case), 'R', Lex) :- !,
    (   rl_closed(W)
    ->  true
    ;   I > 0, Case == lower,
        \+ tg_only(W, Lex, [noun, class, adj, adverb]),
        ( rs_base(W, Base), Base \== W -> \+ tg_only(Base, Lex, [noun, class, adj, adverb]) ; true )
    ).
tg_sane_token(_, num(_), Tag, _) :- !,
    memberchk(Tag, ['T', 'O', 'D']).                                     % a number counts a noun, is an object, or is noise
tg_sane_token(_, word(W, _), Tag, _) :-
    ( rl_number(W, _) ; rl_scale(W, _) ), !, memberchk(Tag, ['T', 'O', 'D']).   % and so is a number word
tg_sane_token(_, word(W, _), Tag, _) :-
    ( W == much ; W == many ), !, memberchk(Tag, ['O', 'D']).            % `how much', `how many': the object asked for
tg_sane_token(_, word(W, _), Tag, _) :-
    rl_question(W), !, memberchk(Tag, ['S', 'O']).                       % `who' a subject, `what' or `where' an object
tg_sane_token(_, word(W, _), 'S', _) :-
    rl_subject_pronoun(W), !.                                            % `she' may be a subject: the grammar resolves it
tg_sane_token(I, word(W, Case), Tag, Lex) :-
    memberchk(Tag, ['S', 'O', 'A', 'C']), !,
    \+ rl_closed(W),
    (   memberchk(Tag, ['S', 'O']), Case == lower, tg_only(W, Lex, [verb])                 % `Discuss values': no subject --
    ->  rs_base(W, B), B \== W, tg_classes(B, Lex, Cs), Cs \== [], \+ tg_only(B, Lex, [verb])   % unless `keys' is the noun `key'
    ;   true
    ),
    (   I =:= 0, Tag == 'S', Case == upper, tg_classes(W, Lex, Cs), Cs \== []
    ->  memberchk(name, Cs)
    ;   true
    ),
    (   memberchk(Tag, ['A', 'C'])
    ->  \+ tg_only(W, Lex, [adverb])
    ;   true
    ).
tg_sane_token(_, _, _, _).

tg_classes(W, Lex, Cs) :- ( get_assoc(W, Lex, Cs0) -> Cs = Cs0 ; Cs = [] ).
%% known, and known as nothing outside the classes given
tg_only(W, Lex, Only) :- tg_classes(W, Lex, Cs), Cs \== [], forall(member(C, Cs), memberchk(C, Only)).

%% the lexicon as one assoc, word -> its classes, made once a machine
tg_lexicon_classes(Lex) :-
    (   catch(nb_getval('$tg_lexicon_classes', Lex), _, fail)
    ->  true
    ;   findall(W-C, ( member(File-C, [noun-noun, class-class, adj-adj, adverb-adverb, unit-noun,
                                       known_noun-noun, known_adj-adj, known_adverb-adverb]),
                       normalise_lexicon(File, Ws), member(W0, Ws),
                       ( W = W0 ; C == noun, normalise_third(W0, W) ) ), Cs1),        % a noun and its plural: `500 pounds'
        findall(W-name, ( member(File, [proper, language]), normalise_lexicon(File, Ws), member(X, Ws), downcase_atom(X, W) ), Cs2),   % a language heads a sentence as a name does
        findall(W-verb, ( member(C, [vt, vi, vpp, known_verb]), normalise_lexicon(C, Vs), member(V0, Vs),
                          ( V0 = V-_ -> true ; V = V0 ), ( W = V ; normalise_third(V, W) ) ), Cs3),
        append([Cs1, Cs2, Cs3], All), keysort(All, Sorted),
        tg_group_classes(Sorted, Pairs), list_to_assoc(Pairs, Lex),
        nb_setval('$tg_lexicon_classes', Lex)
    ).
tg_group_classes([], []).
tg_group_classes([W-C|Rest], [W-[C|Cs]|Pairs]) :- tg_same_word(W, Rest, Cs, Others), tg_group_classes(Others, Pairs).
tg_same_word(W, [W-C|R], [C|Cs], O) :- !, tg_same_word(W, R, Cs, O).
tg_same_word(_, R, [], R).

%% ---- prose to predicates -----------------------------------------------------------------

%% prose in, its questions answered against the knowledge base. Not through
%% tagger_normalise/4, whose reason_text/2 resets the subject state: a
%% question is asked AFTER the paragraph, and `Is she insured?' asks about
%% the subject that paragraph left.
tagger_ask(Model, Text, Answers) :-
    tg_controlled(Model, Text, resolve, Controlled),
    reason_ask(Controlled, Answers).
tagger_ask(Model, Text, Answers, Explanations) :-
    tg_controlled(Model, Text, resolve, Controlled),
    reason_ask(Controlled, Answers, Explanations).

%% ---- the trained model, kept -----------------------------------------------------------
%% THE KNOWLEDGE BASE IS THE MODEL FILE. A program over its own --embed
%% store trains once (library/reasoning/train.pl, or tagger_train/2 under the
%% name `tagger') and every later run over that store finds the model there.
%% A program with no such store -- --local, or a base nobody trained in --
%% gets the model shipped beside the library, library/reasoning/model.rows:
%% the rows as tagger_export/2 writes them, consulted as a module, so they
%% are muted and never written into the program's own base. A store was
%% tried for the shipped copy and a text file shipped instead: the store
%% came to sixteen megabytes for three of live rows, never shrinks below
%% its high-water mark, and travels in one machine's byte order.

tagger_pretrained(Model) :-
    (   catch(nb_getval('$tg_pretrained', Cached), _, Cached = none), Cached \== none
    ->  Model = Cached
    ;   (   catch(tagger_load(tagger, Model0), error(existence_error(tagger, _), _), fail)
        ->  true
        ;   tg_model_file(File), tg_forget_model(tagger), use_module(File), tagger_load(tagger, Model0)
        ),
        nb_setval('$tg_pretrained', Model0),
        Model = Model0
    ).

tg_model_file(File) :-
    getenv('COCOLOG_TAGGER_MODEL', File), File \== '', exists_file(File), !.
tg_model_file(File) :-
    ng_library_dirs(Ds), member(D, Ds),
    atom_concat(D, '/reasoning/model.rows', File), exists_file(File), !.
tg_model_file(_) :-
    throw(error(existence_error(tagger, pretrained),
                context(tagger_pretrained/1, 'no model named tagger here and no library/reasoning/model.rows: sh tools/tagger/train.sh writes it'))).

%% the rows of an earlier load under the same name, or two copies would
%% answer every chunk twice
tg_forget_model(Name) :-
    retractall('$tg_vocab'(Name, _, _)),
    retractall('$te_param'(Name, _, _)),
    retractall('$te_chunk'(Name, _, _, _)).

%% a parameter is written to six decimals: a weight near one carries no
%% seventh the tagging could feel, and the shipped file is half the size
tagger_export(Name, File) :-
    findall(R, tg_model_row(Name, R), Rows),
    (   Rows == [] -> throw(error(existence_error(tagger, Name), tagger_export/2)) ; true ),
    with_output_to(string(S), forall(member(R, Rows), tg_write_row(R))),
    string_codes(S, Cs),
    write_file_from_codes(File, Cs).

tg_write_row('$te_chunk'(Name, I, Seq, Chunk)) :- !,
    format("'$te_chunk'(~q,~w,~w,[", [Name, I, Seq]), tg_write_numbers(Chunk), format("]).~n", []).
tg_write_row(R) :- writeq(R), write('.'), nl.

tg_write_numbers([]).
tg_write_numbers([X]) :- !, format("~6f", [X]).
tg_write_numbers([X|Xs]) :- format("~6f,", [X]), tg_write_numbers(Xs).

tg_model_row(Name, '$tg_vocab'(Name, Seq, Chunk)) :- '$tg_vocab'(Name, Seq, Chunk).
tg_model_row(Name, '$te_param'(Name, I, Shape)) :- '$te_param'(Name, I, Shape).
tg_model_row(Name, '$te_chunk'(Name, I, Seq, Chunk)) :- '$te_chunk'(Name, I, Seq, Chunk).

tagger_normalise(Model, Text, Controlled, Terms) :-
    tg_controlled(Model, Text, keep, Controlled),
    reason_text(Controlled, Terms).

%% prose to the controlled text alone: every sentence tagged, judged and
%% assembled -- FAILS on a refused sentence. With `resolve', a subject
%% pronoun in a sentence's first two words is replaced by the subject the
%% grammar's state holds BEFORE tagging: the network has seen `she' after
%% `and' and at the head of a statement, never after `Is' or `Does', and a
%% question is asked after the paragraph whose subject it means.
tg_controlled(Model, Text, Resolve, Controlled) :-
    reason_tokens(Text, Toks),
    tg_sentences(Toks, Sents0),
    Sents0 \== [],
    ( Resolve == resolve -> tg_resolved(Sents0, Sents) ; Sents = Sents0 ),
    tagger_tag_all(Model, Sents, TagLists),
    tg_assemble_all(Sents, TagLists, Texts),
    atomic_list_concat(Texts, ' ', Controlled).

tg_resolved(Sents, Out) :-
    (   catch(nb_getval('$rs_subject', S), _, S = none), S \== none, atom(S)
    ->  tg_resolved(Sents, S, Out)
    ;   Out = Sents
    ).
tg_resolved([], _, []).
tg_resolved([Toks|Ts], S, [Toks1|Ts1]) :-
    (   Toks = [word(P, _)|Rest], rl_subject_pronoun(P) -> Toks1 = [word(S, upper)|Rest]
    ;   Toks = [W1, word(P, _)|Rest], rl_subject_pronoun(P) -> Toks1 = [W1, word(S, upper)|Rest]
    ;   Toks1 = Toks
    ),
    tg_resolved(Ts, S, Ts1).

%% every sentence assembled, or the paragraph refused: a sentence the
%% tagger marks outside must not vanish into an empty reading (it did once,
%% and 319 sentences of government prose "read" as nothing at all)
tg_assemble_all([], [], []).
tg_assemble_all([S|Ss], [Tg|Tgs], [T|Texts]) :-
    normalise_assemble(S, Tg, T),
    T \== '',                                          % every token dropped is a refusal too
    tg_assemble_all(Ss, Tgs, Texts).

%% the token list cut at every stop, empty sentences dropped
tg_sentences([], []) :- !.
tg_sentences(Toks, Sents) :-
    tg_upto_stop(Toks, S, Rest),
    ( S == [] -> Sents = Sents1 ; Sents = [S|Sents1] ),
    tg_sentences(Rest, Sents1).
tg_upto_stop([], [], []).
tg_upto_stop(['.'|Ts], [], Ts) :- !.
tg_upto_stop([T|Ts], [T|S], Rest) :- tg_upto_stop(Ts, S, Rest).

%% ---- evaluation ---------------------------------------------------------------------------

tagger_refused(Model, From, N, Rate) :-
    normalise_negatives(From, N, Pairs),
    tg_chunks(Pairs, 64, Groups),
    findall(x, ( member(G, Groups),
                 findall(Toks, member(pair(_, Toks, _, _, _), G), TLs),
                 tagger_tag_all(Model, TLs, Gots),
                 nth0(I, TLs, Toks), nth0(I, Gots, Got),
                 \+ ( normalise_assemble(Toks, Got, Asm), catch(reason_text(Asm, _), _, fail) ) ),
            Refused),
    length(Refused, NR), length(Pairs, NP),
    ( NP > 0 -> Rate is NR / NP ; Rate = 0.0 ).

tagger_evaluate(Model, From, N, report(TokenAcc, SentenceAcc, Accepted, N)) :-
    To is From + N - 1,
    findall(p(Toks, Tags, Clean), ( between(From, To, I), normalise_pair(I, pair(_, Toks, Tags, Clean, _)) ), Ps),
    tg_chunks(Ps, 64, Groups),
    findall(r(Toks, Gold, Got, Clean),
            ( member(G, Groups),
              findall(Toks, member(p(Toks, _, _), G), TLs),
              tagger_tag_all(Model, TLs, Gots),
              nth0(I, G, p(Toks, Gold, Clean)), nth0(I, Gots, Got) ),
            Rs),
    findall(H-T, ( member(r(_, Gold, Got, _), Rs), tg_hits(Gold, Got, H), length(Gold, T) ), HTs),
    findall(H, member(H-_, HTs), Hs), sum_list(Hs, Hits),
    findall(T, member(_-T, HTs), Ts), sum_list(Ts, Tokens),
    ( Tokens > 0 -> TokenAcc is Hits / Tokens ; TokenAcc = 0.0 ),
    findall(x, ( member(r(_, Gold, Got, _), Rs), Gold == Got ), Right), length(Right, NR),
    findall(x, ( member(r(Toks, _, Got, Clean), Rs), tg_accepted(Toks, Got, Clean) ), Acc), length(Acc, NA),
    ( N > 0 -> SentenceAcc is NR / N, Accepted is NA / N ; SentenceAcc = 0.0, Accepted = 0.0 ).

tg_hits([], _, 0).
tg_hits([G|Gs], [T|Ts], H) :- !, tg_hits(Gs, Ts, H0), ( G == T -> H is H0 + 1 ; H = H0 ).
tg_hits([_|Gs], [], H) :- tg_hits(Gs, [], H).

%% the lessons typed as prose: each corpus line bare, tagged in one batch,
%% assembled and read, against what the line itself gives
tagger_lessons(Model, From, N, Rate) :-
    normalise_lessons(Lines), length(Lines, NL),
    To0 is From + N - 1, ( To0 > NL -> To = NL ; To = To0 ),
    findall(l(Toks, Line), ( between(From, To, I), nth1(I, Lines, Line), normalise_bare(Line, Bare),
                             reason_tokens(Bare, Toks0), ( append(Toks, ['.'], Toks0) -> true ; Toks = Toks0 ), Toks \== [] ),
            Ls),
    tg_chunks(Ls, 64, Groups),
    findall(x, ( member(G, Groups),
                 findall(Toks, member(l(Toks, _), G), TLs),
                 tagger_tag_all(Model, TLs, Gots),
                 nth0(I, G, l(Toks, Line)), nth0(I, Gots, Got),
                 tg_accepted(Toks, Got, Line) ),
            Ok),
    length(Ok, NOk), length(Ls, NLs),
    ( NLs > 0 -> Rate is NOk / NLs ; Rate = 0.0 ).

%% the assembled sentence parses, to the clean text's terms up to variable names
tg_accepted(Toks, Got, Clean) :-
    normalise_assemble(Toks, Got, Asm),
    catch(reason_text(Asm, T2), _, fail),
    catch(reason_text(Clean, T1), _, fail),
    tg_variant(T1, T2).

tg_variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), tg_number(Va, 0),
    term_variables(B1, Vb), tg_number(Vb, 0),
    A1 == B1.
tg_number([], _).
tg_number(['$v'(N)|Vs], N) :- N1 is N + 1, tg_number(Vs, N1).
