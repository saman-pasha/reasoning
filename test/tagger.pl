%% library(reasoning/tagger) -- the network that labels typed text for the
%% grammar, held to what the grammar then reads: the pure half (vocabulary,
%% encoding, tag ids, the padding plan) on any box, and where library(torch)
%% is built a training, its accuracy on sentences it never saw, SIXTY-SIX
%% HAND-WRITTEN SENTENCES whose names, nouns, adjectives and verbs are
%% outside the lexicon, a paragraph of such prose put to truth/2, and a
%% model one process trains and the next loads.
%%
%%     cocolog -s test/tagger.pl        from this repository's root
%%
%% The network section is a SECTION, not the case: without library/torch.so
%% it says so, indented, and the pure half still decides.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/tagger)).

main :-
    alphabet, vocabulary, encoding, padding, network,
    checks_done.

%% ---- the tag ids are the alphabet's order ---------------------------------------

alphabet :-
    section('alphabet'),
    tagger_tag_id('S', S), check('S is 0', S, 0),
    tagger_tag_id('B', B), check('B is 10', B, 10),
    tagger_tag_id(Nine, 9), check('9 is D, the tag padding carries', Nine, 'D'),
    tagger_tag_id('X', X), check('X, outside, is 11', X, 11),
    tagger_tag_id('M', Mn), check('M, a mentioned word, is 12: the last, so every id before it stands', Mn, 12),
    normalise_tags(Tags),
    findall(I, ( member(T, Tags), tagger_tag_id(T, I) ), Ids), sort(Ids, Distinct),
    check('thirteen tags, ids 0..12, all distinct', Distinct, [0,1,2,3,4,5,6,7,8,9,10,11,12]).

%% ---- the vocabulary -----------------------------------------------------------------

vocabulary :-
    section('vocabulary'),
    normalise_corpus(64, Pairs),
    tagger_vocabulary(Pairs, V), tagger_vocabulary(Pairs, V2),
    check('deterministic: the same pairs, the same vocabulary', V, V2),
    tagger_size(V, NV), yes_no(NV > 50, Big),
    check('64 pairs give more than 50 words', Big, yes),
    tagger_word_id(V, zed, Z), check('a word not in it is 1, <unk>', Z, 1),
    tagger_word_id(V, ',', C), check('the comma is a word, and sorts first: 2', C, 2),
    findall(W, ( member(pair(_, Toks, _, _, _), Pairs), member(word(W, _), Toks) ), Ws), sort(Ws, Words),
    findall(W, ( member(W, Words), tagger_word_id(V, W, Id), ( Id < 2 ; Id >= NV ) ), Out),
    check('every word of the pairs has an id from 2 up to the size', Out, []),
    findall(A-B, ( member(W, Words), tagger_word_id(V, W, A), member(W2, Words), W2 \== W, tagger_word_id(V, W2, B), A == B ), Dup),
    check('and no two words share one', Dup, []).

%% ---- the encoding ----------------------------------------------------------------------

encoding :-
    section('encoding'),
    normalise_corpus(64, Pairs), tagger_vocabulary(Pairs, V),
    tagger_encode(V, [word(alice, upper), word(owns, lower), ',', word(zed, upper)], Ids, Shapes),
    %% a shape is the case and the ending, plus sixteen for every class the
    %% lexicon knows the word by -- adjective 1, noun 2 -- so `owns', a verb
    %% and nothing else, is 4 for its -s and nothing more
    check('shapes: upper 2, lower with -s 4, comma 3, upper with -ed still 2: a capitalised word is a name whatever it ends in, and carries no class', Shapes, [2, 4, 3, 2]),
    tagger_encode(V, [word(wholly, lower), word(walking, lower), word(walked, lower), word(cars, upper)], _, Shapes2),
    check('the ending in the shape: -ly 7, -ing 10 and the adjective bit (walking is one), -ed 13 with no class, and upper with -s 2', Shapes2, [7, 26, 13, 2]),
    Ids = [A, O, C, Z],
    tagger_word_id(V, alice, A1), check('alice by its id', A, A1),
    tagger_word_id(V, owns, O1), check('owns by its id', O, O1),
    check('the comma by its id', C, 2),
    check('Zed, never seen, is <unk>', Z, 1),
    tagger_encode(V, [word(alice, lower)], [A2], [S2]),
    check('the case is the shape, not the word: alice lower has the same id', A2, A1),
    check('and shape 1: a name is in no class file', S2, 1),
    tagger_encode(V, [num(500), word(five, lower)], [N3, _], S3),
    check('a number is one word, <num>, and sorts right after the comma: 3', N3, 3),
    check('its shape is 15, and a number word is a lower-case word like any other', S3, [15, 1]),
    tagger_encode(V, [word(red, lower), word(car, lower)], _, S5),
    check('and it is what an adjective is known by: red is -ed 13 and the adjective and noun bits, car is 1 and the noun bit', S5, [61, 33]),
    tagger_encode(V, [word(map, lower)], _, S5b),
    check('and a noun the lexicon also knows as a verb is a noun like any other: map is 33, as car is', S5b, [33]),
    tagger_encode(V, [quoted(casa), word(casa, lower), quoted(zed)], [Q1, Q2, Q3], Sq),
    yes_no(Q1 == Q2, SameId),
    check('a quoted word keeps its word: the same id quoted and bare', SameId, yes),
    check('and Zed quoted is <unk> as Zed bare is', Q3, 1),
    check('and its shape is 14, whatever is inside the marks', Sq, [14, 1, 14]),
    normalise_corpus(64, Pairs64), tagger_vocabulary(Pairs64, V64),
    tagger_word_id(V64, means, IdMeans), yes_no(IdMeans > 1, Means64),
    check('the lesson shapes are in 64 pairs: `means'' has an id', Means64, yes).

%% ---- the padding plan ---------------------------------------------------------------------

padding :-
    section('padding'),
    tagger_pad([seq([5, 6, 7], [2, 1, 1], [0, 4, 8]), seq([9], [2], [0])], Plan),
    Plan = plan(N, M, IdRows, ShapeRows, MaskRows, Flat),
    check('two sequences', N, 2),
    check('three positions, the longest', M, 3),
    check('ids position-major, padding 0', IdRows, [[5, 9], [6, 0], [7, 0]]),
    check('shapes likewise', ShapeRows, [[2, 2], [1, 0], [1, 0]]),
    check('the mask 1.0 inside a sequence and 0.0 past its end, as rows', MaskRows, [[[1.0], [1.0]], [[1.0], [0.0]], [[1.0], [0.0]]]),
    check('the gold tags position-major, D (9) where there is padding', Flat, [0, 0, 4, 9, 8, 9]),
    tagger_pad([seq([5, 6], [1, 1], none)], plan(_, _, _, _, _, Flat2)),
    check('no gold at all is D throughout', Flat2, [9, 9]).

%% ---- the network -------------------------------------------------------------------------------

network :-
    section('network'),
    (   exists_file('library/torch.so')
    ->  network_checks
    ;   format("     (skipped: no library/torch.so -- sh modules/torch/build.sh against libtorch)~n", [])
    ).

%% FROM THE PAIRS IN THE TREE, which is what tools/tagger/train.sh trains
%% the shipped model from -- train.pl's own call, option
%% for option -- so this case trains the model that SHIPS rather than one
%% of its own. (With `[]' it generates the pairs instead, and they are the
%% same pairs: the file was regenerated and diffed byte for byte.)
%%
%% AND IT STILL DOES NOT REPRODUCE THE SHIPPED MODEL, WHICH IS AN OPEN
%% FINDING. Same file, same seed, same options: here tokens 0.9854,
%% sentences 0.9333 and the adjective grid 271 of 384, where the model
%% tools/tagger/train.sh writes reads 0.9891, 0.9700 and 381. It is not
%% this case -- a BARE process training from the same file gives 271 to
%% the unit -- and it is not the data. The one difference left is the
%% STORE: train.sh runs `cocolog --embed TMP -s train.pl'
%% and a case runs --local. A model file trained --embed and loaded
%% --local grids 381, so it is the TRAINING that differs and not the
%% loading. Nothing here explains why, and the pins are set where both
%% pass.
network_checks :-
    normalise_generated_dir(Dir), atom_concat(Dir, '/training.txt', Training),
    %% UNDER `\+ \+', because the model goes to the STORE and the heap does
    %% not come back otherwise: cocolog reclaims on backtracking and a
    %% training walks 32 768 pairs deterministically, so the sequences,
    %% the batches and every intermediate stay live for the rest of the
    %% case. Three runs in a row were killed by this box's 16 GB after the
    %% last section's checks had printed -- 206, 195 and 232 s, with the
    %% training itself finishing at 158 -- which reads as a hang in
    %% whatever ran last and is the training's leavings. tagger_load/2
    %% reads the parameters back from the store, exactly as
    %% train.pl does.
    get_time(T0), \+ \+ tagger_train(tg_case, [pairs_file(Training)]), get_time(T1), Secs is T1 - T0,
    format("     trained on the pairs in the tree in ~1f s~n", [Secs]),
    tagger_load(tg_case, M),
    tagger_evaluate(M, 30001, 300, report(Tok, Sent, Acc, N)),
    format("     on 300 pairs training never saw, seeds past the corpus: tokens ~4f, sentences ~4f, accepted ~4f~n", [Tok, Sent, Acc]),
    check('evaluated 300', N, 300),
    yes_no(Tok >= 0.97, TokOk), check('at least 0.97 of the tags right', TokOk, yes),
    %% 0.90 until 1.2.42; the evaluation pairs carry an adjective in every verb-object shape
    %% since, one object in three, two in one of six, and the same training reads 0.8867 of them
    yes_no(Sent >= 0.85, SentOk), check('at least 0.85 of the sentences wholly right', SentOk, yes),
    yes_no(Acc >= 0.90, AccOk), check('at least 0.90 assemble and parse to the clean terms', AccOk, yes),
    reason_tokens('Well, Zed really owns a red car, obviously.', Toks0), append(Toks, ['.'], Toks0),
    tagger_tag(M, Toks, Tags),
    check('a noisy sentence with a name never seen, tagged', Tags, ['D', 'D', 'S', 'D', 'R', 'T', 'A', 'O', 'D', 'D']),
    normalise_assemble(Toks, Tags, Asm),
    check('and assembled', Asm, 'Zed owns a red car.'),
    adjective_grid(M, NOkG, NG),
    format("     an adjective before the object keeps its tag under a comma filler in ~w of ~w~n", [NOkG, NG]),
    RateG is NOkG / NG, yes_no(RateG >= 0.60, GridOk), check('in at least three fifths of a grid of them', GridOk, yes),
    ( tagger_normalise(M, 'Well, Zed really owns a red car, obviously. In fact, Eve does not like Zed.', C, Terms) -> true ; C = refused, Terms = refused ),
    check('two sentences of prose, controlled', C, 'Zed owns a red car. Eve does not like Zed.'),
    check('and read', Terms, [car(car_1), red(car_1), own(zed, car_1), neg(like(eve, zed))]),
    ( tagger_normalise(M, 'Bob needs a ladder.', _, T2) -> true ; T2 = refused ),
    check('a noun never seen is copied', T2, [ladder(ladder_1), need(bob, ladder_1)]),
    yes_no(tagger_normalise(M, 'The dog sleeps.', _, _), Def),
    check('a definite subject is no shape of the generator: refused, not misread', Def, no),
    %% THE PARAGRAPH FIRST, AND ON THE MODEL A PROGRAM GETS. First because
    %% the reader's notes accumulate for the life of the process and this
    %% section pins prose word for word: a name read as a mention anywhere
    %% earlier is written back between quotation marks here (paragraph/1
    %% says what that cost). On tagger_pretrained/1's model because that
    %% is what a program runs the loop with, and because a model trained
    %% here is not the shipped one (see above).
    ( catch(tagger_pretrained(MP), _, fail) -> paragraph(MP) ; paragraph(M) ),
    prose_checks(M),
    refusals(M),
    tagger_free(M),
    pretrained,
    across_processes.

%% ---- what it refuses ---------------------------------------------------------------------------
%% The other half of correctness: real sentences the training never saw,
%% which the grammar does not read and the tagger must not make readable.
%% Before the lexicon judged a tagging, a sixth of WordNet's example
%% sentences and a tenth of real government prose came back as facts --
%% `Boston, Mass.' as mass(boston). With it, measured 0.91 to 0.94 refused
%% over slices of 300 of prose.txt while the judge knew only the
%% generator's words, and 0.96 once it knew every counted word of WordNet
%% (the known_*.txt files); the floor is 0.93 because two trainings do not
%% tag the borderline sentences alike.

refusals(M) :-
    tagger_refused(M, 6001, 300, Rate),
    format("     refused ~4f of 300 real sentences training never saw~n", [Rate]),
    yes_no(Rate >= 0.93, Enough),
    check('at least 0.93 of unseen real prose refused', Enough, yes),
    yes_no(tagger_normalise(M, 'Boston, Mass.', _, _), Boston),
    check('`Boston, Mass.'' is refused, not mass(boston)', Boston, no),
    yes_no(tagger_normalise(M, 'Small business management.', _, _), Heading),
    check('and a heading is refused, not business(small)', Heading, no).

%% ---- the shipped model ------------------------------------------------------------------------
%% model.rows, written by tools/tagger/train.sh: a trained
%% tagger without training, loaded as a module so the base is not written,
%% and the model a --local program gets from tagger_pretrained/1 and from
%% library(reasoning/reason)'s reason_prose/2.

%% The shape every model before 1.2.43 was weak on, measured over a grid
%% rather than one sentence: an adjective inside an object with a comma
%% filler after it. Four names, four adjectives, two nouns, three fillers,
%% with and without a filler at the head and an adverb -- 384 sentences.
%% 1.2.41's model kept the A in 59 to 108 of the 128 behind each filler;
%% the first model trained after the Italian lesson grew kept it in none;
%% 1.2.42's, with every verb-object shape carrying an adjective, kept 207
%% -- the network learning the shape by the luck of its minimum. SINCE THE
%% LEXICON'S CLASSES ARE AN INPUT it keeps 381 of 384, and the grid splits
%% by the NOUN: `car', which the lexicon knows only as a noun, 192 of 192,
%% and `house', a verb as well, 189 -- against 101 and 106 on 1.2.42. So
%% the pin is 0.60, the level that tells a collapse (0.00) from a model
%% (0.99) with room for a training to land between. A word that is a noun
%% AND an adjective is the honest hard case and is not in the grid:
%% `flat' went 163 of 192 to 96, because `a red flat' is two adjectives to
%% anything that reads a word's classes. And the cost is the other way
%% about: a word in NO lexicon file reaches the network at mask 0, which
%% is also what a word the lexicon knows is NEITHER wears, so the network
%% requires the bit. `registered' has three adjective senses and no SemCor
%% count, and the whole paragraph/1 section below was refused for that one
%% word until known_adj.txt carried every adjective index.adj names rather
%% than the counted ones alone. ONE SENTENCE AT A TIME, not one batch: measured on the
%% shipped model, tagger_tag_all/3 over these 384 sentences in one batch
%% took the process from 199 MB to 2 267 MB resident and a second pass to
%% 4 213 MB -- the batch's intermediate tensors are never freed -- where
%% twelve batches of 32 cost 140 MB and one sentence at a time nothing
%% measurable. Two such batches on top of the network section's training
%% took this case to the box's 14 GB limit and it was killed there.
adjective_grid(M, NOk, N) :-
    findall(T-Pos, adjective_grid_sentence(T, Pos), Grid),
    findall(ok, ( member(T-Pos, Grid), reason_tokens(T, Toks0), append(Toks, ['.'], Toks0),
                  tagger_tag(M, Toks, Tags), nth0(Pos, Tags, 'A') ), Oks),
    length(Oks, NOk), length(Grid, N).

adjective_grid_sentence(T, Pos) :-
    member(Name, ['Zed', 'Bob', 'Mia', 'Dana']), member(Adj, [red, big, small, licensed]),
    member(Noun, [car, house]), member(Start, ['', 'Well, ']), member(Adv, ['', 'really ']),
    member(End, [', obviously.', ', I think.', ', as far as I know.']),
    atomic_list_concat([Start, Name, ' ', Adv, 'owns a ', Adj, ' ', Noun, End], T),
    ( Start == '' -> P0 = 0 ; P0 = 2 ), ( Adv == '' -> P1 = P0 ; P1 is P0 + 1 ), Pos is P1 + 3.

pretrained :-
    section('the shipped model'),
    (   catch(tagger_pretrained(M), error(existence_error(tagger, pretrained), _), fail)
    ->  (   tagger_normalise(M, 'Well, Zed really owns a red car, obviously. Dana rents a flat in Bristol and is registered. The rent is 700 euros.', C, T)
        ->  true
        ;   C = refused, T = refused
        ),
        check('the shipped model normalises prose', C, 'Zed owns a red car. Dana rents a flat in Bristol. Dana is registered. The rent is 700 euros.'),
        check('and reads it', T, [car(car_1), red(car_1), own(zed, car_1), flat(flat_1), rent_in(dana, flat_1, bristol), registered(dana),
                                  amount(rent, quantity(700, euros))]),
        adjective_grid(M, NOkP, NP),
        format("     an adjective before the object keeps its tag under a comma filler in ~w of ~w~n", [NOkP, NP]),
        RateP is NOkP / NP, yes_no(RateP >= 0.60, GridPOk), check('in at least three fifths of a grid of them', GridPOk, yes),
        tagger_pretrained(M2), check('loaded once a process', M2, M),
        yes_no('$tg_vocab'(tagger, 0, _), Rows), check('its rows are in the store, a module''s', Rows, yes),
        ( tagger_normalise(M, 'The noun casa means house. Leche is feminine, of course. In Spanish, los is the plural of el. Every noun that ends in a is feminine.', CL, TL)
        ->  true
        ;   CL = refused, TL = refused
        ),
        check('a lesson typed bare: the mentioned words back between quotation marks, a bare head word the name reading, the language dropped', CL,
              'The noun "casa" means "house". Leche is feminine. Los is the plural of "el". Every noun that ends_in "a" is feminine.'),
        ( TL = [noun(casa), mean(casa, house), feminine(leche), plural_of(los, el), (feminine(XL) :- noun(YL), end_in(ZL, a))], XL == YL, YL == ZL -> RL = a_lesson ; RL = TL ),
        check('and read as a lesson: facts about words, a rule over their letters', RL, a_lesson),
        ( tagger_normalise(M, 'The word "no" precedes the verb. "amigo" is a person.', _, TQ) -> true ; TQ = refused ),
        check('and written with its marks, read the same', TQ, [word(no), precede(no, verb), person(amigo)]),
        tagger_lessons(M, 1, 400, LessonRate),
        format("     the shipped model reads ~4f of the corpus lines typed bare~n", [LessonRate]),
    %% 0.78, not the 0.85 it was: the Italian lesson grew to 123 lines in 1.2.42, and
    %% a fifth of them mention a word of one letter -- `"i" is the plural of "il"',
    %% `The conjunction "e" means "and"' -- which typed bare is `I' or an article
    %% to the judge, and rightly refused; measured 0.81 on the model trained then
        yes_no(LessonRate >= 0.78, LessonsOk),
        check('at least 0.78 of the corpus lines, typed bare, come back as their own terms', LessonsOk, yes),
        tagger_free(M),
        tagger_pretrained(M3),
        ( tagger_normalise(M3, 'Zed owns a car.', _, T3) -> true ; T3 = refused ),
        check('freed, it loads again', T3, [car(car_1), own(zed, car_1)]),
        tagger_free(M3)
    ;   format("     (skipped: no shipped model -- sh tools/tagger/train.sh writes model.rows)~n", [])
    ).

%% ---- prose it never saw ------------------------------------------------------------------------
%% Hand-written, not generated: the names, and many of the nouns, adjectives
%% and verbs, are outside the lexicon, in every shape the grammar reads and
%% with the noise typed prose carries. Each should give the terms a careful
%% reader would write, up to the names of a rule's variables; every miss is
%% printed by name, and the floor is all but four of the eighty-two, because
%% over a lexicon of thousands two trainings do not miss the same sentence
%% -- measured, one missed `works hard' and the next `may enter the ward' --
%% and a pin on all of them would be a pin on the coin. Two of the lesson
%% sentences mention CLOSED words bare (`no means not', `the contraction of
%% a el'), which the corpus gives the generator a line each of, and those
%% are a coin too.

prose('Zed owns a bicycle.', [bicycle(bicycle_1), own(zed, bicycle_1)]).
prose('Mia is clever.', [clever(mia)]).
prose('Omar is a doctor.', [doctor(omar)]).
prose('Nadia is not tired.', [neg(tired(nadia))]).
prose('Lars does not own a truck.', [neg(own(lars, truck))]).
prose('Priya snores.', [snore(priya)]).
prose('Kai may drive the truck.', [may_drive(kai, truck)]).
prose('Every pilot is a person.', [(person(X) :- pilot(X))]).
prose('Every nurse that is not banned may enter the ward.', [(may_enter(X, ward) :- nurse(X), \+ banned(X))]).
prose('Every guard that is armed must guard the gate.', [(must_guard(X, gate) :- guard(X), armed(X))]).
prose('Ola lives in Lagos.', [live_in(ola, lagos)]).
prose('Tom likes Ana.', [like(tom, ana)]).
prose('Yuki admires Tom.', [admire(yuki, tom)]).
prose('Well, Zed really owns a bicycle, obviously.', [bicycle(bicycle_1), own(zed, bicycle_1)]).
prose('In fact, Mia is clever, I think.', [clever(mia)]).
prose('Omar does own a truck.', [truck(truck_1), own(omar, truck_1)]).
prose('Nadia is tired and Lars is happy.', [tired(nadia), happy(lars)]).
prose('Actually, every pilot that is careful may fly the plane in the morning.', [(may_fly(X, plane) :- pilot(X), careful(X))]).
prose('Priya works at home.', [work(priya)]).
prose('Kai clearly does not like Tom.', [neg(like(kai, tom))]).
prose('Of course, Ana should sell the boat.', [should_sell(ana, boat)]).
prose('Hugo rents an old flat in Rome.', [flat(flat_1), old(flat_1), rent_in(hugo, flat_1, rome)]).
prose('Every diver that is not certified must wear the vest, of course.', [(must_wear(X, vest) :- diver(X), \+ certified(X))]).
prose('Ida is a nurse and Ida is careful.', [nurse(ida), careful(ida)]).
prose('Noor buys a small blue lamp.', [lamp(lamp_1), small(lamp_1), blue(lamp_1), buy(noor, lamp_1)]).
prose('Rex drives the big red truck.', [drive(rex, truck)]).
prose('Mila waits at Oslo.', [wait_at(mila, oslo)]).
prose('Every teacher has a badge.', [(have(X, badge) :- teacher(X))]).
prose('Rex sleeps and Rex is not hungry.', [sleep(rex), neg(hungry(rex))]).
prose('Apparently, Bo does not drive.', [neg(drive(bo))]).
prose('Vera can read the map.', [can_read(vera, map)]).
prose('Every robot that is active may open the door.', [(may_open(X, door) :- robot(X), active(X))]).
prose('Every clerk is careful.', [(careful(X) :- clerk(X))]).
prose('Ana is not a pilot.', [neg(pilot(ana))]).
prose('Bo does not snore.', [neg(snore(bo))]).
prose('Every pilot owns a plane.', [(own(X, plane) :- pilot(X))]).
prose('Every nurse that is certified holds a badge.', [(hold(X, badge) :- nurse(X), certified(X))]).
prose('Kai does not live in Lagos.', [neg(live_in(kai, lagos))]).
prose('Tom likes the old map.', [like(tom, map)]).
prose('Wilma will fix the drone.', [will_fix(wilma, drone)]).
prose('I think that Zed sleeps in Tokyo.', [sleep_in(zed, tokyo)]).
prose('By the way, every farmer that is not insured needs a permit, as far as I know.', [(need(X, permit) :- farmer(X), \+ insured(X))]).
prose('Well, every baker that is not lazy works hard, obviously.', [(work(X) :- baker(X), \+ lazy(X))]).
prose('Dana rents a flat in Bristol.', [flat(flat_1), rent_in(dana, flat_1, bristol)]).
prose('Frankly, Ravi keeps the deposit in Bristol.', [keep_in(ravi, deposit, bristol)]).
prose('Priya is a baker and, as far as I know, Priya is licensed.', [baker(priya), licensed(priya)]).
prose('Rex sleeps and I think that Rex is not hungry.', [sleep(rex), neg(hungry(rex))]).
prose('Priya is a baker and is licensed.', [baker(priya), licensed(priya)]).
prose('Priya is a baker and she is licensed.', [baker(priya), licensed(priya)]).
prose('Marco is a tenant. He does not pay the rent.', [tenant(marco), neg(pay(marco, rent))]).
prose('Well, does Priya sell the bread?', [question(sell(priya, bread))]).
prose('Is Marco really a tenant?', [question(tenant(marco))]).
prose('Who rents a flat in Bristol?', [question(X, (flat(F), rent_in(X, F, bristol)))]).
prose('What does Priya sell, honestly?', [question(X, sell(priya, X))]).
prose('Nadia pays 500 euros.', [pay(nadia, quantity(500, euros))]).
prose('Tariq owns three vineyards.', [own(tariq, quantity(3, vineyards))]).
prose('The rent is 500 euros.', [amount(rent, quantity(500, euros))]).
prose('Every tenant must pay 500 euros.', [(must_pay(X, quantity(500, euros)) :- tenant(X))]).
prose('Well, Nadia clearly does not pay 500 euros.', [neg(pay(nadia, quantity(500, euros)))]).
prose('Noor buys two litres of milk.', [buy(noor, quantity(2, litres, milk))]).
prose('Frankly, the price is 5.5 percent.', [amount(price, quantity(5.5, percent))]).
prose('Does Nadia pay 500 euros?', [question(pay(nadia, quantity(500, euros)))]).
prose('How much does Nadia pay?', [question(Q, (pay(nadia, O), reason_amount(O, Q)))]).
prose('How many vineyards does Tariq own, honestly?', [question(N, (own(tariq, O), reason_count(O, vineyards, N)))]).
prose('Why does Nadia pay 500 euros?', [question(why(pay(nadia, quantity(500, euros))))]).
prose('Well, why is Mia a nurse?', [question(why(nurse(mia)))]).
%% a lesson typed as prose: the mentioned words bare, and the tagger puts the marks back
prose('Casa means house.', [mean(casa, house)]).
prose('The noun perro means dog.', [noun(perro), mean(perro, dog)]).
prose('In Spanish, the word gato means cat.', [word(gato), mean(gato, cat)]).
prose('Well, mesa means table, of course.', [mean(mesa, table)]).
prose('The Spanish word no means not.', [word(no), spanish(no), mean(no, not)]).
prose('Leche is feminine.', [feminine(leche)]).
prose('Los is the plural of el.', [plural_of(los, el)]).
prose('Comió is the past of come, I think.', [past_of('comió', come)]).
prose('Al is the contraction of a el.', [contraction_of(al, 'a el')]).
prose('Amigo is a person and means friend.', [person(amigo), mean(amigo, friend)]).
prose('Every noun that ends in a is feminine.', [(feminine(X) :- noun(X), end_in(X, a))]).
prose('Every verb that ends in e takes n in the plural.', [(take_in(X, n, plural) :- verb(X), end_in(X, e))]).
prose('Every adjective follows the noun.', [(follow(X, noun) :- adjective(X))]).
prose('The word no precedes the verb.', [word(no), precede(no, verb)]).
prose('The word "a" precedes the person.', [word(a), precede(a, person)]).
prose('Spanish is a language.', [language(spanish)]).

prose_checks(M) :-
    findall(T-W, prose(T, W), Ps), length(Ps, N),
    findall(T, ( member(T-W, Ps), \+ ( tagger_normalise(M, T, _, Got), variant(Got, W) ) ), Bad),
    forall(member(T, Bad),
           (   tagger_normalise(M, T, C, G)
           ->  format("     MISREAD  ~w~n              as ~w~n              ~q~n", [T, C, G])
           ;   format("     REFUSED  ~w~n", [T])
           )),
    length(Bad, NB), Ok is N - NB,
    format("     ~w of ~w hand-written sentences give their terms~n", [Ok, N]),
    Floor is N - 4, yes_no(Ok >= Floor, Enough),
    check('all but four of the hand-written sentences give their terms', Enough, yes).

%% variants: the same term up to the names of its variables
variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), number_vars(Va, 0),
    term_variables(B1, Vb), number_vars(Vb, 0),
    A1 == B1.
number_vars([], _).
number_vars(['$v'(N)|Vs], N) :- N1 is N + 1, number_vars(Vs, N1).

%% ---- a paragraph, and then questions --------------------------------------------------------------
%% What the loop is for: prose in, terms asserted, truth/2 answering --
%% including a rule from the prose applied to a fact from the prose. The
%% paragraph is plain on purpose: the noise is the prose section's business
%% and its floor, and this section pins the reading exactly.
%%
%% THE NURSE IS PRIYA AND WAS MIA, AND THE COLLISION IS WORTH THE PARAGRAPH
%% IT TAKES. Every answer here was right and the EXPLANATION came back as
%% `"mia" may enter the ward because "mia" is a nurse and "mia" is
%% careful'. `mia' is the ITALIAN LESSON's own word -- `The feminine
%% possessive "mia" means "my"', in corpus/italian.txt
%% since 1.2.42 -- and the 300 generated sentences tagger_evaluate/4 reads
%% three checks earlier carry the lesson shapes that MENTION it. The reader
%% keeps what it has met as globals of the machine for the life of the
%% process, a word met between quotation marks among them, and re_arg/2
%% puts the marks back before it asks whether the word is a name. So a
%% person whose name some lesson also mentions is WRITTEN as a mention
%% wherever an explanation names them -- working as designed, and invisible
%% until one process reads a lesson and a paragraph both.
%%
%% TWO OTHER READINGS WERE MEASURED AND ARE WRONG, which is why they are
%% written down: it is not the MODEL (the shipped one does it too, and the
%% answers were right on either) and not the hand-written sentences read
%% before it (reading the paragraph first fails the same way). A fixture
%% name has to be one no corpus/*.txt mentions; of the five here, `mia' was
%% the only one, and `grep -i ''"name"'' corpus/*.txt' is the check.

paragraph(M) :-
    Prose = 'Zed owns a bicycle. Priya is a nurse and is careful. Every nurse that is careful may enter the ward. Omar does not like Zed. Ola lives in Lagos. The rent is 500 euros. Priya pays the rent. Dana rents a flat in Bristol. She is registered.',
    ( tagger_normalise(M, Prose, C, Terms) -> true ; C = refused, Terms = [] ),
    check('a paragraph of nine sentences, controlled -- the subject Priya left out supplied, the pronoun kept, the amount kept', C,
          'Zed owns a bicycle. Priya is a nurse. Priya is careful. Every nurse that is careful may_enter the ward. Omar does not like Zed. Ola lives_in Lagos. The rent is 500 euros. Priya pays the rent. Dana rents a flat in Bristol. She is registered.'),
    length(Terms, NT), check('twelve terms', NT, 12),
    forall(member(T, Terms), assertz(T)),
    truth(own(zed, bicycle_1), V1), check('truth: Zed owns the bicycle', V1, true),
    truth(may_enter(priya, ward), V2), check('truth: Priya may enter the ward -- a rule over two facts, all from the prose', V2, true),
    truth(like(omar, zed), V3), check('truth: Omar likes Zed -- denied', V3, false),
    truth(like(zed, omar), V4), check('truth: Zed likes Omar -- never said', V4, unknown),
    truth(live_in(ola, lagos), V5), check('truth: Ola lives in Lagos', V5, true),
    truth(rent_in(dana, flat_1, bristol), V6), check('truth: Dana rents a flat in Bristol -- the place kept', V6, true),
    truth(registered(dana), V7), check('truth: Dana is registered -- `she'' resolved to the last subject', V7, true),
    tagger_ask(M, 'Well, does Dana rent a flat in Bristol?', A1),
    check('asked in prose: yes, and the reason is the fact', A1, [yes(fact)]),
    tagger_ask(M, 'Who is registered?', A2), check('asked: who is registered', A2, [[dana-fact]]),
    tagger_ask(M, 'May Priya enter the ward?', [A3]),
    yes_no(A3 = yes(rule((may_enter(priya, ward) :- nurse(priya), careful(priya)))), R3),
    check('asked: may Priya enter the ward -- yes, by the rule and the two facts it rests on', R3, yes),
    tagger_ask(M, 'Does Omar like Zed?', A4), check('asked: does Omar like Zed -- no, the text denied it', A4, [no(denied(neg(like(omar, zed))))]),
    tagger_ask(M, 'Is Zed a nurse?', A5), check('asked: never said -- unknown', A5, [unknown]),
    tagger_ask(M, 'Is she registered?', A6), check('asked with a pronoun: the subject the paragraph left, Dana -- yes', A6, [yes(fact)]),
    tagger_ask(M, 'How much does Priya pay?', A7),
    check('asked how much: through the amount the paragraph gave the rent', A7, [[quantity(500, euros)-fact]]),
    tagger_ask(M, 'Well, how much is the rent?', A8), check('asked how much the rent is', A8, [[quantity(500, euros)-fact]]),
    tagger_ask(M, 'Why may Priya enter the ward?', A9, E9),
    yes_no(A9 = [because(_)], V9), check('asked why: the answer is because(Text)', V9, yes),
    check('and the text is the whole proof in sentences', E9, ['Priya may enter the ward because Priya is a nurse and Priya is careful.']),
    tagger_ask(M, 'Does Omar like Zed?', _, E10), check('tagger_ask/4: the denial, as said', E10, ['Omar does not like Zed, as said.']).

%% one process trains into a store and asserts what it tagged; the next loads
%% the model from the store and tags the same sentence -- the knowledge base
%% is the model file, which an in-process check cannot claim
across_processes :-
    scratch(Dir),
    atom_concat(Dir, '/KB', KB),
    atom_concat(Dir, '/train.pl', Train),
    atom_concat(Dir, '/load.pl', Load),
    fixture(Train, [
        ':- use_module(library(reasoning/tagger)).',
        'main :- tagger_train(tg_shared, [pairs(128), steps(60), batch(64)]), tagger_load(tg_shared, M),',
        '    reason_tokens(''Actually, Mia really likes Zed, obviously.'', T0), append(T, [''.''], T0),',
        '    tagger_tag(M, T, Tags), assertz(tg_expected(Tags)), tagger_free(M), write(trained), nl.' ]),
    fixture(Load, [
        ':- use_module(library(reasoning/tagger)).',
        'main :- tagger_load(tg_shared, M),',
        '    reason_tokens(''Actually, Mia really likes Zed, obviously.'', T0), append(T, [''.''], T0),',
        '    tagger_tag(M, T, Tags), tg_expected(Want), write(Tags), nl,',
        '    ( Tags == Want -> write(''tags-agree'') ; write(''tags-differ'') ), nl,',
        '    catch(( tagger_load(nosuch, _), write(loaded) ), error(existence_error(tagger, nosuch), _), write(absent)), nl,',
        '    tagger_free(M).' ]),
    %% (what a child printed comes back as codes, which sub_atom/5 takes for
    %% no text since 3.0.0, as swipl's does)
    sh_join(['--embed ', KB, ' -s ', Train], A1), cocolog_out(A1, C1), atom_codes(O1, C1),
    yes_no(sub_atom(O1, _, _, _, trained), Trained),
    check('a process trains into a store', Trained, yes),
    sh_join(['--embed ', KB, ' -s ', Load], A2), cocolog_out(A2, C2), atom_codes(O2, C2),
    yes_no(sub_atom(O2, _, _, _, 'tags-agree'), Agree),
    check('the next process loads the model and tags the sentence the same', Agree, yes),
    yes_no(sub_atom(O2, _, _, _, absent), Absent),
    check('and a name nothing saved under is existence_error(tagger, Name)', Absent, yes),
    sh_join(['rm -rf ', Dir], Rm), shell(Rm, _, _).
