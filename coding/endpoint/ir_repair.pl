%% coding/endpoint/ir_repair.pl -- the model checks and helps the translator's reading.
%%
%%     ep_ir_readings(+Text, -Readings)
%%     ep_ir_stats(-Stats)
%%
%% The endpoint's IR note is the translator's reading of the request
%% (reason_ir/2). The translator reads only the words a lesson teaches and
%% the shapes it knows. So a request often has sentences it cannot read:
%% a word no lesson gives (`subarray', `toward'), or a shape it does not
%% translate (`It reads integers from standard input until EOF.'). And a
%% sentence it does read can be read WRONGLY: `Convert every word to
%% lowercase.' reads as `Every convert words to lowercase.', with the
%% quantifier on the verb.
%%
%% ep_ir_readings/2 reads the request sentence by sentence, and then asks
%% the model about EVERY sentence, not only those the translator could not
%% read (CODING_ENDPOINT_IR_CHECK, below). One call covers the request. For
%% a sentence the translator read, the prompt gives its reading said back
%% in English (reason_ir_text/3) and its logical form, and the model says
%% whether that reading keeps the sentence's meaning: the logical form,
%% because a wrong parse that keeps the word order says itself back as the
%% very sentence. For a sentence it read wrongly, or did not
%% read, the model gives:
%%
%%   - for each unknown English word, its class and its base form. Each
%%     becomes a LESSON LINE in the controlled English the translator
%%     learns from, `The noun "x_subarray" means "subarray".' -- the
%%     English lesson's own form (english_lesson.pl) -- and reason_learn/1
%%     teaches it;
%%   - a REWRITE: short plain sentences with the same meaning. A rewrite
%%     counts only if the translator reads every sentence of it.
%%
%% What the model's answer made read -- a sentence after a lesson, or a
%% rewrite -- is a new reading, which the next round sends to be checked
%% too. A sentence that still does not read goes back in the next round,
%% with the rewrite it tried and the words the translator did not know in
%% it. CODING_ENDPOINT_IR_ROUNDS (default 3) is the number of calls at most
%% for one request: a round to check and repair, one to check what the
%% repair made, and one more for a rewrite the translator read wrongly. A
%% reading the rounds left unchecked is used as it stands: one the model
%% saw and passed over is not sent again, and one made in the last round,
%% which it never saw, is sent with the next request.
%%
%% WHAT IS LEARNED IS KEPT. The lesson lines are facts the translator reads
%% (noun/1, mean/2, verb/1, ...); the rewrite that read is a fact,
%% ep_ir_rewrite(Sentence, Rewrites); and so is each verdict,
%% ep_ir_verdict(Sentence, Reading, right|wrong|unjudged), Reading the
%% reading's text, `unjudged' one the model was shown and passed over.
%% Under `--embed' (run-httpd.sh) all of them are written into the store
%% when the request commits, so the next request and the next
%% process read the sentence with no model call, and a reading judged
%% wrong is never sent to the coding model again. A verdict is about one
%% reading: when a lesson changes how the translator reads a sentence, the
%% new reading is checked again. A sentence that no rewrite read is kept as
%% ep_ir_unread(Sentence, Version), so the model is not asked about it
%% again until the reasoning version's minor number moves (`1.13',
%% ep_ir_version/1). ep_ir_lesson(Line) keeps each lesson line as the
%% model's words gave it:
%%
%%     cocolog --embed STORE query "forall(ep_ir_lesson(L), (write(L), nl))"
%%
%% Each reading in Readings is reading(Sentence, How, IRs), How one of:
%%
%%     read           the translator read the sentence as it stands
%%     lesson         it read after the words the model classified were taught
%%     rewrite(Rs)    it read the model's rewrite Rs, a list of sentences
%%     unread         nothing read it, or only wrongly; IRs is []
%%
%% THE MODEL. The backend is the endpoint's own unless these name another:
%%
%%     CODING_ENDPOINT_IR_REPAIR      on (default) or off
%%     CODING_ENDPOINT_IR_CHECK       all (default): every reading the model
%%                                    has not judged is sent to be checked;
%%                                    always: every reading, every request,
%%                                    judged or not; failed: only what the
%%                                    translator could not read
%%     CODING_ENDPOINT_IR_API         openai or anthropic (default CODING_ENDPOINT_API)
%%     CODING_ENDPOINT_IR_BACKEND     the complete URL (default: the endpoint's
%%                                    backend, or the provider's own URL when
%%                                    CODING_ENDPOINT_IR_API is set)
%%     CODING_ENDPOINT_IR_KEY         the key (default CODING_ENDPOINT_KEY_ENV)
%%     CODING_ENDPOINT_IR_MODEL       the model (default CODING_ENDPOINT_MODEL)
%%     CODING_ENDPOINT_IR_ROUNDS      calls at most for one request (default 3)
%%     CODING_ENDPOINT_IR_TRIES       requests at most whose rounds end on a
%%                                    reading the model never saw (default 2)
%%     CODING_ENDPOINT_IR_SENTENCES   sentences of the request read (default 6)
%%     CODING_ENDPOINT_IR_MAX_TOKENS  the reply's limit, thinking included (default 8000)
%%     CODING_ENDPOINT_IR_EFFORT      output_config.effort (default low for
%%                                    api.anthropic.com, none elsewhere)
%%     CODING_ENDPOINT_IR_LOG         a file each round's prompt and reply are
%%                                    appended to (default none)
%%
%% With no key the model is not asked, and the note carries what the
%% translator read alone, less the readings a model judged wrong before. A
%% call that fails is not repeated for five minutes, so a backend that is
%% down does not cost every request a timeout.
%%
%% ep_ir_model_stub(Key, Round, Reply) is a test's model: while one such
%% fact exists, the backend is never called, and a round's prompt that
%% contains Key is answered Reply. A round no stub answers ends the rounds.
%% The server never asserts one.

:- use_module(library(json)).
:- use_module(library(curl)).
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/translate)).

:- dynamic ep_ir_rewrite/2.
:- dynamic ep_ir_unread/2.
:- dynamic ep_ir_verdict/3.
:- dynamic ep_ir_tries/3.
:- dynamic ep_ir_lesson/1.
:- dynamic ep_ir_model_stub/3.

%% ---- the readings -------------------------------------------------------
%%
%% While the rounds run, a reading may also be reading(S, check(How), IRs),
%% read and waiting for the model's verdict, or reading(S, pending(F), []),
%% waiting for a rewrite, F what was tried.

ep_ir_readings(Text, Readings) :-
    ep_ir_stats_reset,
    ep_ir_sentences(Text, Sentences),
    ep_ir_check_mode(Mode),
    maplist(ep_ir_first(Mode), Sentences, Readings0),
    (   ep_ir_open(Readings0),
        ep_ir_repair_ready
    ->  ep_ir_int('CODING_ENDPOINT_IR_ROUNDS', 3, Max),
        ep_ir_repair(1, Max, Mode, Readings0, Readings1)
    ;   Readings1 = Readings0
    ),
    maplist(ep_ir_settle, Readings1, Readings),
    ep_ir_count_readings(Readings).

ep_ir_open(Readings) :-
    member(reading(_, How, _), Readings),
    ( How = pending(_) ; How = check(_) ),
    !.

%% The request's first sentences, each with the mark that ended it.
ep_ir_sentences(Text, Sentences) :-
    ep_ir_int('CODING_ENDPOINT_IR_SENTENCES', 6, Max),
    ep_ir_sentences_all(Text, All),
    ep_ir_take(Max, All, Sentences).

ep_ir_take(N, List, Taken) :-
    (   length(List, L), L > N
    ->  length(Taken, N), append(Taken, _, List)
    ;   Taken = List
    ).

%% What the translator reads with no model: the sentence itself, or the
%% rewrite a model gave before -- never a reading a model judged wrong. A
%% sentence nothing read under this version of the library is not sent
%% again.
ep_ir_first(Mode, S, R) :-
    (   ep_ir_try(S, IRs), \+ ep_ir_judged(S, IRs, wrong)
    ->  ep_ir_to_check(Mode, S, read, IRs, R)
    ;   ep_ir_rewrite(S, Rs), ep_ir_try_all(Rs, IRs), \+ ep_ir_judged(S, IRs, wrong)
    ->  ep_ir_to_check(Mode, S, rewrite(Rs), IRs, R)
    ;   ep_ir_version(V), ep_ir_unread(S, V)
    ->  R = reading(S, unread, [])
    ;   R = reading(S, pending([]), [])
    ).

%% A reading, settled or sent to be checked as the mode says.
ep_ir_to_check(failed, S, How, IRs, reading(S, How, IRs)) :- !.
ep_ir_to_check(all, S, How, IRs, reading(S, How, IRs)) :-
    ep_ir_settled(S, IRs),
    !.
ep_ir_to_check(_, S, How, IRs, reading(S, check(How), IRs)).

%% A reading the model judged right, or saw and passed over.
ep_ir_settled(S, IRs) :-
    (   ep_ir_judged(S, IRs, right)
    ->  true
    ;   ep_ir_judged(S, IRs, unjudged)
    ).

ep_ir_settle(reading(S, pending(_), _), reading(S, unread, [])) :- !,
    (   nb_getval('$ep_ir_answered', yes)
    ->  ep_ir_version(V), assertz(ep_ir_unread(S, V))
    ;   true
    ).
%% A READING THE MODEL SAW AND PASSED OVER IS NOT SENT AGAIN. The endpoint
%% reads the task at every turn of the coding model, and a reading the
%% model never answered for was sent again each time, three calls a turn
%% (two readings of `balanced' in a live run, reasoning 1.13.2). One it
%% was shown in a round that answered is kept as ep_ir_verdict(S, Reading,
%% unjudged) and used as it stands; a reading made in the last round, which
%% the model never saw, is sent with the next request.
ep_ir_settle(reading(S, check(How), IRs), Out) :- !,
    ep_ir_reading_text(IRs, Text),
    (   nb_getval('$ep_ir_answered', yes)
    ->  nb_getval('$ep_ir_seen', Seen),
        (   memberchk(S-Text, Seen)
        ->  retractall(ep_ir_verdict(S, Text, _)),
            assertz(ep_ir_verdict(S, Text, unjudged)),
            Out = reading(S, How, IRs)
        ;   ep_ir_tried(S, How, IRs, Out)
        )
    ;   Out = reading(S, How, IRs)
    ).
ep_ir_settle(R, R).

%% A SENTENCE WHOSE ROUNDS KEEP ENDING ON A NEW READING IS GIVEN UP. A
%% reading made in the last round is sent with the next request, and a
%% sentence the model judges wrong round after round -- `... with one writer
%% and any number of readers.', whose rewrites the translator read as
%% `number of readers any', and whose `many readers' the model refused --
%% ended every request that way, three calls a request (a live run,
%% reasoning 1.13.2). ep_ir_tries(Sentence, Version, N) counts the requests
%% that so ended, and at CODING_ENDPOINT_IR_TRIES (default 2) the sentence
%% is unread under this version: its unchecked rewrite is dropped, and no
%% reading nobody checked reaches the coding model.
ep_ir_tried(S, How, IRs, Out) :-
    ep_ir_version(V),
    (   retract(ep_ir_tries(S, V, N0))
    ->  true
    ;   N0 = 0
    ),
    N is N0 + 1,
    ep_ir_int('CODING_ENDPOINT_IR_TRIES', 2, Max),
    (   N >= Max
    ->  retractall(ep_ir_rewrite(S, _)),
        assertz(ep_ir_unread(S, V)),
        Out = reading(S, unread, [])
    ;   assertz(ep_ir_tries(S, V, N)),
        Out = reading(S, How, IRs)
    ).

%% THE VERSION A SENTENCE IS GIVEN UP UNDER IS THE MINOR ONE, `1.13'. This
%% repository moves its patch number with every commit, and a patch is no
%% reason the translator reads a sentence better: keyed by `1.13.1', the
%% fifteen sentences the benchmark tasks gave up would all have gone to the
%% model again at the commit that recorded them.
ep_ir_version(V) :-
    reason_version(Major, Minor, _),
    format(atom(V), '~w.~w', [Major, Minor]).

ep_ir_saw(S, IRs) :-
    ep_ir_reading_text(IRs, Text),
    nb_getval('$ep_ir_seen', Seen),
    nb_setval('$ep_ir_seen', [S-Text|Seen]).

%% One reading of a text, its inferences bounded: a sentence the reader
%% takes a long way round is no help to a request waiting for a reply.
ep_ir_try(Text, IRs) :-
    catch(call_metered(reason_ir(Text, IRs0), 5000000, _, Result), _, fail),
    Result == true,
    IRs0 = [_|_],
    IRs = IRs0.

ep_ir_try_all([], []).
ep_ir_try_all([S|Ss], IRs) :-
    ep_ir_try(S, IRs1),
    ep_ir_try_all(Ss, IRs2),
    append(IRs1, IRs2, IRs).

%% Each sentence of a rewrite read alone: the IRs of those that read, and
%% failed(Sentence, Unknown) for those that did not.
ep_ir_try_each([], [], []).
ep_ir_try_each([S|Ss], IRs, Failed) :-
    ep_ir_try_each(Ss, IRs2, Failed2),
    (   ep_ir_try(S, IRs1)
    ->  append(IRs1, IRs2, IRs), Failed = Failed2
    ;   IRs = IRs2, ep_ir_unknown(S, U), Failed = [failed(S, U)|Failed2]
    ).

ep_ir_unknown(S, Words) :-
    (   catch(reason_untranslated(S, Words0), _, fail)
    ->  Words = Words0
    ;   Words = []
    ).

%% A sentence as the model and the coding model are shown it. The
%% translator's splitter writes a dash before a blank as code 3 and the
%% brackets as codes 5 and 6 (tr_mid_marks/2); they go back to `-', `('
%% and `)', and a line break is a blank. The sentence itself, as the store
%% keys it, is unchanged.
ep_ir_display(S, Text) :-
    atom_codes(S, Cs0),
    maplist(ep_ir_display_code, Cs0, Cs),
    atom_codes(Text, Cs).

ep_ir_display_code(3, 0'-) :- !.
ep_ir_display_code(5, 0'() :- !.
ep_ir_display_code(6, 0')) :- !.
ep_ir_display_code(10, 32) :- !.
ep_ir_display_code(C, C).

%% ---- the verdicts -------------------------------------------------------

%% A reading's text: the IRs written with their variables numbered, so one
%% reading has one text in every process.
ep_ir_reading_text(IRs, Text) :-
    copy_term(IRs, Copy),
    numbervars(Copy, 0, _),
    format(atom(Text), '~q', [Copy]).

ep_ir_judged(S, IRs, Verdict) :-
    ep_ir_reading_text(IRs, Text),
    ep_ir_verdict(S, Text, Verdict),
    !.

ep_ir_judge(S, IRs, Verdict) :-
    ep_ir_reading_text(IRs, Text),
    retractall(ep_ir_verdict(S, Text, _)),
    assertz(ep_ir_verdict(S, Text, Verdict)),
    (   Verdict == right
    ->  ep_ir_count(checked)
    ;   ep_ir_count(wrong)
    ).

%% The reading said back in English, which is what the model judges. A
%% reading the writer cannot say is shown as the logical form itself.
ep_ir_english(IRs, Text) :-
    (   catch(reason_ir_text(IRs, english, Text0), _, fail),
        Text0 \== ''
    ->  Text = Text0
    ;   findall(T, member(ir(T, _), IRs), Ts),
        format(atom(Text), 'the logical form ~q', [Ts])
    ).

%% ---- the rounds ---------------------------------------------------------

ep_ir_repair(K, Max, Mode, Rs0, Rs) :-
    K =< Max,
    ep_ir_numbered(Rs0, 1, Open),
    Open \== [],
    !,
    ep_ir_prompt(K, Open, System, User),
    (   ep_ir_ask(K, System, User, Reply)
    ->  nb_setval('$ep_ir_answered', yes),
        forall(member(_-check(S, _, IRs), Open), ep_ir_saw(S, IRs)),
        (   ep_ir_reply(Reply, Words, Oks, Rewrites)
        ->  true
        ;   Words = [], Oks = [], Rewrites = []
        ),
        ep_ir_allowed_words(Open, Allowed),
        ep_ir_learn(Words, Allowed),
        ep_ir_after_all(Rs0, 1, Mode, Oks, Rewrites, Rs1),
        K1 is K + 1,
        ep_ir_repair(K1, Max, Mode, Rs1, Rs)
    ;   Rs = Rs0
    ).
ep_ir_repair(_, _, _, Rs, Rs).

%% The readings still open, numbered as the prompt numbers them.
ep_ir_numbered([], _, []).
ep_ir_numbered([reading(S, How, IRs)|Rs], N, [N-Item|Ps]) :-
    ep_ir_open_item(How, S, IRs, Item),
    !,
    N1 is N + 1,
    ep_ir_numbered(Rs, N1, Ps).
ep_ir_numbered([_|Rs], N, Ps) :-
    ep_ir_numbered(Rs, N, Ps).

ep_ir_open_item(pending(F), S, _, pending(S, F)).
ep_ir_open_item(check(How), S, IRs, check(S, How, IRs)).

ep_ir_after_all([], _, _, _, _, []).
ep_ir_after_all([R0|Rs], N, Mode, Oks, Rewrites, [R|Out]) :-
    R0 = reading(S, How, IRs),
    ep_ir_open_item(How, S, IRs, Item),
    !,
    ep_ir_after(Item, N, Mode, Oks, Rewrites, R),
    N1 is N + 1,
    ep_ir_after_all(Rs, N1, Mode, Oks, Rewrites, Out).
ep_ir_after_all([R|Rs], N, Mode, Oks, Rewrites, [R|Out]) :-
    ep_ir_after_all(Rs, N, Mode, Oks, Rewrites, Out).

%% After a reply. A reading the model sent a rewrite for is wrong, and
%% the rewrite is tried -- a kept rewrite so judged is dropped; a reading
%% it named ok is right; a reading it
%% said nothing of is sent again in the next round.
ep_ir_after(check(S, How, IRs), N, Mode, Oks, Rewrites, R) :-
    (   ep_ir_rewrite_of(N, Rewrites, Rs)
    ->  ep_ir_judge(S, IRs, wrong),
        (   How = rewrite(_)
        ->  retractall(ep_ir_rewrite(S, _))
        ;   true
        ),
        ep_ir_rewrite_try(Mode, S, Rs, [], R)
    ;   memberchk(N, Oks)
    ->  ep_ir_judge(S, IRs, right),
        R = reading(S, How, IRs)
    ;   R = reading(S, check(How), IRs)
    ).
%% A sentence that was not read: the words the reply taught may make it
%% read as it stands; else its rewrite must read whole; else it waits for
%% the next round with what was tried.
ep_ir_after(pending(S, F), N, Mode, _, Rewrites, R) :-
    (   ep_ir_try(S, IRs), \+ ep_ir_judged(S, IRs, wrong)
    ->  ep_ir_next(Mode, S, lesson, IRs, R)
    ;   ep_ir_rewrite_of(N, Rewrites, Rs)
    ->  ep_ir_rewrite_try(Mode, S, Rs, F, R)
    ;   R = reading(S, pending(F), [])
    ).

ep_ir_rewrite_of(N, Rewrites, Rs) :-
    memberchk(N-Texts, Rewrites),
    ep_ir_split_all(Texts, Rs),
    Rs = [_|_].

ep_ir_rewrite_try(Mode, S, Rs, F, R) :-
    ep_ir_try_each(Rs, IRs, Failed),
    (   Failed == [],
        \+ ep_ir_judged(S, IRs, wrong)
    ->  retractall(ep_ir_rewrite(S, _)),
        assertz(ep_ir_rewrite(S, Rs)),
        ep_ir_next(Mode, S, rewrite(Rs), IRs, R)
    ;   R = reading(S, pending([tried(Rs, Failed)|F]), [])
    ).

%% A reading the model's answer made: settled when only failures are
%% checked, else sent to be checked in the next round, as the model has
%% not seen it.
ep_ir_next(failed, S, How, IRs, reading(S, How, IRs)) :- !.
ep_ir_next(_, S, How, IRs, R) :-
    (   ep_ir_settled(S, IRs)
    ->  R = reading(S, How, IRs)
    ;   R = reading(S, check(How), IRs)
    ).

ep_ir_split_all([], []).
ep_ir_split_all([T|Ts], Rs) :-
    ep_ir_sentences_all(T, R1),
    ep_ir_split_all(Ts, R2),
    append(R1, R2, Rs).

ep_ir_sentences_all(Text, Sentences) :-
    (   catch(tr_pieces(Text, Pieces), _, fail)
    ->  true
    ;   Pieces = []
    ),
    findall(S, ( member(Piece-Stop, Pieces),
                 atom_codes(P0, Piece), tr_trim(P0, P1), P1 \== '',
                 tr_stop_text(P1, Stop, S) ),
            Sentences).

%% ---- the words, as lesson lines ----------------------------------------

%% The words a reply may teach: those the translator named unknown in a
%% sentence it did not read or in a rewrite it tried. A reply never
%% teaches a word the translator already knows.
ep_ir_allowed_words(Open, Allowed) :-
    findall(W, ( member(_-pending(S, F), Open),
                 (   ep_ir_unknown(S, Ws)
                 ;   member(tried(_, Failed), F), member(failed(_, Ws), Failed)
                 ),
                 member(W0, Ws), atom(W0), downcase_atom(W0, W) ),
            Allowed0),
    sort(Allowed0, Allowed).

ep_ir_learn(Words, Allowed) :-
    findall(Line, ( member(word(W, Class, Base), Words),
                    ep_ir_lesson_line(W, Class, Base, Allowed, Line) ),
            Lines0),
    sort(Lines0, Lines),
    (   Lines == []
    ->  true
    ;   ep_ir_confirmed(Confirmed),
        forall(member(Line, Lines), ep_ir_learn_line(Line, Confirmed))
    ).

%% A LESSON MAY NOT CHANGE A READING THE MODEL CONFIRMED. A word a reply
%% classifies is unknown somewhere, but the translator's grammar may read
%% it elsewhere by a construction of its own: `if' is unknown in the middle
%% of `It prints yes if the brackets are balanced.', and `If ..., ...' at a
%% sentence's head is read without any lesson. The lesson `The conjunction
%% "x_if" means "if".' gave it a second meaning, and the confirmed reading
%% of `If the input has no even integers, it prints 0.' became another one,
%% which the model then judged wrong (a live run, reasoning 1.13.2). So each
%% lesson is taught alone, every confirmed reading is read again, and a
%% lesson that changed one is taken back: the facts it added are retracted.
%% A lesson for a word truly unknown changes none, as no confirmed sentence
%% holds an unknown word.
ep_ir_learn_line(Line, Confirmed) :-
    (   catch(reason_grammar(reason_text(Line, Terms)), _, fail),
        Terms = [_|_]
    ->  exclude(ep_ir_holds, Terms, New),
        forall(member(T, New), assertz(T)),
        catch(tr_lessons_moved, _, true),
        (   member(S-Text, Confirmed),
            \+ ep_ir_current_text(S, Text)
        ->  forall(member(T, New), ignore(retract(T))),
            catch(tr_lessons_moved, _, true),
            ep_ir_refused(Refused0),
            nb_setval('$ep_ir_refused', [Line|Refused0])
        ;   assertz(ep_ir_lesson(Line)),
            ep_ir_count(lessons)
        )
    ;   true
    ).

ep_ir_holds(T) :- catch(clause(T, true), _, fail), !.

%% The readings the model confirmed, as they stand: each sentence with a
%% verdict `right' whose reading is that one now.
ep_ir_confirmed(Confirmed) :-
    findall(S-Text, ep_ir_verdict(S, Text, right), All0),
    sort(All0, All),
    include(ep_ir_current, All, Confirmed).

ep_ir_current(S-Text) :- ep_ir_current_text(S, Text).

%% The text of the reading a sentence has now: the sentence's own, or its
%% kept rewrite's, as ep_ir_first/3 takes them.
ep_ir_current_text(S, Text) :-
    (   ep_ir_try(S, IRs), \+ ep_ir_judged(S, IRs, wrong)
    ->  true
    ;   ep_ir_rewrite(S, Rs), ep_ir_try_all(Rs, IRs)
    ),
    ep_ir_reading_text(IRs, Text).

ep_ir_lesson_line(W0, Class, Base0, Allowed, Line) :-
    downcase_atom(W0, W),
    memberchk(W, Allowed),
    memberchk(Class, [noun, verb, adjective, adverb, preposition, conjunction]),
    (   atom(Base0), Base0 \== ''
    ->  downcase_atom(Base0, Base)
    ;   Base = W
    ),
    ep_ir_word_letters(Base),
    ep_ir_lesson_word(Class, Base, English),
    atom_concat(x_, English, X),
    \+ catch(mean(X, English), _, fail),
    format(atom(Line), 'The ~w "~w" means "~w".', [Class, X, English]).

%% A verb is taught in its third person singular, as the English lesson
%% teaches one; every other class in the base form the reply gave.
ep_ir_lesson_word(verb, Base, Third) :- !,
    (   catch(reason_third(Base, Third0), _, fail)
    ->  Third = Third0
    ;   Third = Base
    ).
ep_ir_lesson_word(_, Base, Base).

ep_ir_word_letters(W) :-
    atom_codes(W, Codes),
    length(Codes, L), L > 0, L =< 24,
    forall(member(C, Codes), ( C >= 0'a, C =< 0'z )).

%% ---- the prompt ---------------------------------------------------------

ep_ir_prompt(K, Open, System, User) :-
    ep_ir_system(System),
    findall(Block, ( member(N-Item, Open), ep_ir_block(N, Item, Block) ), Blocks),
    atomic_list_concat(Blocks, '\n', Body),
    format(atom(User), 'Round ~w. The sentences of the task, and what the parser made of each:~n~n~w',
           [K, Body]).

%% A READING IS SHOWN AS ITS LOGICAL FORM AS WELL AS IN ENGLISH. The
%% English is the reading said back, and a wrong parse that keeps the word
%% order says itself back as the sentence: `Blank lines are ignored.' read
%% with `lines' for its verb said back `Blank lines are ignored.', and the
%% model judged it right (the mvccs_acid benchmark's translation, reasoning
%% 1.14.0). The logical form shows each word's role.
ep_ir_block(N, check(S, How, IRs), Block) :-
    ep_ir_display(S, D),
    ep_ir_english(IRs, English),
    ep_ir_logical_form(IRs, Form),
    (   How = rewrite(Rs)
    ->  atomic_list_concat(Rs, ' ', R),
        format(atom(Block), '~w. "~w"~n   Rewritten as: "~w"~n   Read as: "~w"~n   Logical form: ~w', [N, D, R, English, Form])
    ;   format(atom(Block), '~w. "~w"~n   Read as: "~w"~n   Logical form: ~w', [N, D, English, Form])
    ).
ep_ir_block(N, pending(S, F), Block) :-
    ep_ir_display(S, D),
    (   ep_ir_try(S, IRs)
    ->  ep_ir_english(IRs, English),
        format(atom(Head), '~w. "~w"~n   Read wrongly as: "~w"', [N, D, English])
    ;   ep_ir_unknown(S, Ws),
        ep_ir_words_text(Ws, WsText),
        format(atom(Head), '~w. "~w"~n   Not read. Unknown words: ~w.', [N, D, WsText])
    ),
    findall(T, ( member(tried(Rs, Failed), F), ep_ir_tried_text(Rs, Failed, T) ), Ts),
    atomic_list_concat([Head|Ts], '\n', Block).

ep_ir_logical_form(IRs, Form) :-
    findall(T, ( member(ir(T0, _), IRs), format(atom(T), '~q', [T0]) ), Ts),
    atomic_list_concat(Ts, ' ; ', Form).

ep_ir_tried_text(Rs, [], T) :- !,
    atomic_list_concat(Rs, ' ', Tried),
    format(atom(T), '   Tried before: "~w". Its reading was wrong.', [Tried]).
ep_ir_tried_text(Rs, Failed, T) :-
    atomic_list_concat(Rs, ' ', Tried),
    findall(FT, ( member(failed(FS, FU), Failed),
                  ep_ir_words_text(FU, FUText),
                  format(atom(FT), '"~w" (unknown words: ~w)', [FS, FUText]) ),
            FTs),
    atomic_list_concat(FTs, '; ', FailedText),
    format(atom(T), '   Tried before: "~w". Not read: ~w.', [Tried, FailedText]).

ep_ir_words_text([], none) :- !.
ep_ir_words_text(Ws, Text) :- atomic_list_concat(Ws, ', ', Text).

ep_ir_system(System) :-
    atomic_list_concat([
'You check a rule-based English parser that reads the task a user gave to a coding assistant. ',
'The parser reads short, plain English sentences into a logical form. Below, each numbered sentence ',
'of the task is shown with what the parser made of it: its reading, said back in the parser''s own ',
'plain English, or that it could not read the sentence. Answer with one JSON object and nothing else:\n',
'{"ok": [1], "words": [{"word": "subarray", "class": "noun", "base": "subarray"}], ',
'"rewrites": [{"id": 2, "sentences": ["...", "..."]}]}\n\n',
'OK. List the id of each sentence whose reading has the meaning of the sentence. ',
'Judge the logical form, not only the English said back: s(Front, Subject, g(Verb, Tense, Aspect, Negated), ',
'Complements) is a clause, np(Determiner, Number, Modifiers, w(Noun, Case), Count) a noun phrase, obj(...) an ',
'object, pp(w(Preposition, _), ...) a phrase with a preposition, join(Conjunction, Clause, Clause) two clauses. ',
'A reading is wrong when a word has the wrong role, even if the English said back is the same sentence: ',
'a noun read as the verb, a verb read as a noun, an adjective read as a noun. ',
'A different word order, article or plural is not an error when the meaning stays. ',
'A reading is wrong when it changes who does what, an action, a number, a limit, a condition, ',
'a negation, a quantity or a format, or leaves out a requirement.\n\n',
'REWRITES. For each sentence whose reading is wrong, and for each sentence that was not read, ',
'give one or more sentences that the parser can read and that keep its meaning:\n',
'- Keep every fact and requirement: numbers, limits, input, output and formats. Add nothing.\n',
'- Each sentence is one short clause: a subject, a verb in the present tense, an object, and phrases ',
'with prepositions. A subject such as "It" or "The program" is read more safely than an imperative.\n',
'- One if-clause before the main clause, with a comma, is allowed: "If there are no even integers, it prints 0."\n',
'- Do not use brackets, quotation marks, colons, semicolons, dashes, slashes, symbols, code, ',
'abbreviations or lists. Do not join clauses with "and", "or", "that", "which", "until" or "unless".\n',
'- Write a symbol in words, for example "the plus sign". Write a number in digits.\n',
'- Use common English words. The name of a language or a format stays a name with a capital letter.\n',
'- If a sentence was tried before, write it in another way, with other words.\n\n',
'WORDS. For each unknown word of a sentence that was not read, if it is an English word, give its class ',
'(noun, verb, adjective, adverb, preposition or conjunction) and its base form: the singular of a noun, ',
'the bare infinitive of a verb. Leave out names, symbols, numbers and codes.\n\n',
'Sentences the parser reads correctly:\n',
'- It prints the maximum sum of a contiguous subarray.\n',
'- If there are no even integers, it prints 0.\n',
'- It converts each word to lowercase.\n',
'- Write a complete program in C.\n',
'- The program reads the input.'], System).

%% ---- the reply ----------------------------------------------------------

%% The JSON object in the reply text, so a fence or a sentence around it
%% does no harm. A task can hold braces (`only the characters ()[]{}'),
%% and a sentence before the object may quote them, so the first `{' to
%% the last `}' is no object there: an object that parses, with one of the
%% reply's keys, is the reply (ep_ir_json_object/2).
ep_ir_reply(Text, Words, Oks, Rewrites) :-
    atom_codes(Text, Codes),
    ep_ir_json_object(Codes, Pairs),
    (   memberchk(words-WordList, Pairs), is_list(WordList)
    ->  findall(word(W, C, B), ( member(json(WP), WordList),
                                 memberchk(word-W, WP), atom(W),
                                 memberchk(class-C0, WP), atom(C0), downcase_atom(C0, C),
                                 ( memberchk(base-B, WP), atom(B) -> true ; B = W ) ),
                Words)
    ;   Words = []
    ),
    (   memberchk(ok-OkList, Pairs), is_list(OkList)
    ->  include(integer, OkList, Oks)
    ;   Oks = []
    ),
    (   memberchk(rewrites-RewriteList, Pairs), is_list(RewriteList)
    ->  findall(Id-Ss, ( member(json(RP), RewriteList),
                         memberchk(id-Id, RP), integer(Id),
                         memberchk(sentences-Ss0, RP), is_list(Ss0),
                         include(atom, Ss0, Ss) ),
                Rewrites)
    ;   Rewrites = []
    ).

%% THE LAST OBJECT IS THE ANSWER. The model writes an answer, then `Wait,
%% that violates the rule against "and". Here is the corrected answer:'
%% and a second object (a live run, reasoning 1.13.2): the first that
%% parsed was the answer it took back. So the `{' are tried from the
%% right, and an inner object without the reply's keys -- a rewrite's own
%% {"id": 1, ...} -- is passed by.
ep_ir_json_object(Codes, Pairs) :-
    findall(Rest, append(_, [0'{|Rest], Codes), Starts0),
    reverse(Starts0, Starts),
    member(Rest, Starts),
    findall(I, nth0(I, Rest, 0'}), Is0),
    reverse(Is0, Is),
    member(I, Is),
    length(Inner, I),
    append(Inner, _, Rest),
    append([0'{|Inner], [0'}], Object),
    catch(json_parse(Object, json(Pairs)), _, fail),
    (   memberchk(ok-_, Pairs)
    ;   memberchk(words-_, Pairs)
    ;   memberchk(rewrites-_, Pairs)
    ),
    !.

%% ---- the backend --------------------------------------------------------

ep_ir_repair_ready :-
    ep_ir_env('CODING_ENDPOINT_IR_REPAIR', on, Switch),
    \+ memberchk(Switch, [off, '0', no, false]),
    (   ep_ir_model_stub(_, _, _)
    ->  true
    ;   ep_ir_key(_),
        \+ ep_ir_backend_resting
    ).

ep_ir_check_mode(Mode) :-
    ep_ir_env('CODING_ENDPOINT_IR_CHECK', all, Mode0),
    downcase_atom(Mode0, Mode1),
    (   memberchk(Mode1, [all, always, failed])
    ->  Mode = Mode1
    ;   Mode = all
    ).

ep_ir_ask(Round, System, User, Reply) :-
    (   ep_ir_model_stub(_, _, _)
    ->  ep_ir_model_stub(Key, Round, Reply),
        sub_atom(User, _, _, _, Key),
        !,
        ep_ir_count(calls)
    ;   ep_ir_count(calls),
        ep_ir_backend(System, User, Reply)
    ),
    ep_ir_log(Round, User, Reply).

%% CODING_ENDPOINT_IR_LOG names a file each round's prompt and reply are
%% appended to, so a live run can be read afterwards: what the model was
%% shown and what it said.
ep_ir_log(Round, User, Reply) :-
    ep_ir_env('CODING_ENDPOINT_IR_LOG', '', File),
    (   File == ''
    ->  true
    ;   format(codes(Cs), '== round ~w~n-- prompt~n~w~n-- reply~n~w~n~n', [Round, User, Reply]),
        catch(append_file_from_codes(File, Cs), _, true)
    ).

ep_ir_backend(System, User, Reply) :-
    ep_ir_key(Key),
    ep_ir_mode(Mode),
    ep_ir_url(Mode, Url),
    ep_ir_model(Model),
    ep_ir_int('CODING_ENDPOINT_IR_MAX_TOKENS', 8000, MaxTokens),
    ep_backend_timeout(Timeout),
    Body = json([model-Model, max_tokens-MaxTokens, stream- @(false),
                 messages-[json([role-system, content-System]),
                           json([role-user, content-User])]]),
    (   catch(ep_ir_post(Mode, Url, Key, Timeout, Body, Status, Resp), E, true)
    ->  true
    ;   E = post_failed
    ),
    (   var(E),
        integer(Status), Status >= 200, Status < 300,
        ep_reply_text(Resp, Reply),
        Reply \== ''
    ->  ep_usage(Resp, usage(P, C, _, _, _)),
        ep_ir_count(prompt_tokens, P),
        ep_ir_count(completion_tokens, C)
    ;   ep_ir_say_failed(E, Status, Resp),
        get_time(Now),
        nb_setval('$ep_ir_rest_until', Now),
        fail
    ).

%% A failed call says why on stderr, once: the status and the start of the
%% reply, which names the refusal (`temperature` is deprecated for this
%% model.). The key is never in it.
ep_ir_say_failed(E, Status, Resp) :-
    (   nonvar(E)
    ->  format(atom(Why), '~q', [E])
    ;   is_list(Resp)
    ->  atom_codes(Why0, Resp), ep_ir_first_chars(Why0, 300, Why)
    ;   atom(Resp)
    ->  ep_ir_first_chars(Resp, 300, Why)
    ;   Why = 'no reply'
    ),
    (   var(Status) -> S = none ; S = Status ),
    catch(format(user_error, "ir_repair: the model call failed (status ~w): ~w~n", [S, Why]), _, true).

ep_ir_first_chars(Text, Max, First) :-
    atom_length(Text, L),
    (   L > Max
    ->  sub_atom(Text, 0, Max, _, First)
    ;   First = Text
    ).

ep_ir_post(anthropic, Url, Key, Timeout, Body, Status, Resp) :- !,
    ep_anthropic_body(Body, json(Pairs0)),
    ep_ir_effort_field(Url, Pairs0, Pairs),
    json_codes(json(Pairs), Codes),
    format(atom(KeyHeader), 'x-api-key: ~w', [Key]),
    curl_post(Url, 'application/json', Codes,
              [ header(KeyHeader),
                header('anthropic-version: 2023-06-01'),
                timeout(Timeout), max_size(16777216) ],
              Status0, AnthropicResp),
    ep_anthropic_reply(Status0, AnthropicResp, Status, Resp).
%% The OpenAI wire takes temperature 0 for one answer a prompt; Anthropic's
%% newer models refuse the field, so its body has none.
ep_ir_post(_, Url, Key, Timeout, json(Pairs), Status, Resp) :-
    json_codes(json([reasoning_effort-none, temperature-0|Pairs]), Codes),
    format(atom(Auth), 'Authorization: Bearer ~w', [Key]),
    curl_post(Url, 'application/json', Codes,
              [header(Auth), timeout(Timeout), max_size(16777216)],
              Status, Resp).

%% THE MODEL THINKS UNLESS IT IS TOLD HOW MUCH. claude-sonnet-5-5 thinks by
%% default at effort high, the thinking is billed as output and counts
%% against max_tokens, and one call spent its 2000 tokens thinking and
%% answered no text (finish_reason length). A verdict and a rewrite need
%% little: output_config.effort is `low' for Anthropic's own API, which
%% every current model takes, and CODING_ENDPOINT_IR_EFFORT names another
%% level, or `none' for no field -- the default for any other URL, as
%% another provider's messages endpoint may refuse the field. At `low' the
%% twelve benchmark tasks' second run spent some 300 completion tokens a
%% call, where the runs before it spent 1 150.
ep_ir_effort_field(Url, Pairs0, Pairs) :-
    ep_ir_env('CODING_ENDPOINT_IR_EFFORT', '', E0),
    (   E0 \== ''
    ->  E = E0
    ;   sub_atom(Url, _, _, _, 'api.anthropic.com')
    ->  E = low
    ;   E = none
    ),
    (   E == none
    ->  Pairs = Pairs0
    ;   append(Pairs0, [output_config-json([effort-E])], Pairs)
    ).

%% A call that failed rests the backend for five minutes.
ep_ir_backend_resting :-
    catch(nb_getval('$ep_ir_rest_until', Then), _, fail),
    number(Then),
    get_time(Now),
    Now - Then < 300.

ep_ir_key(Key) :-
    ep_ir_env('CODING_ENDPOINT_IR_KEY', '', Key0),
    (   Key0 \== ''
    ->  Key = Key0
    ;   ep_ir_env('CODING_ENDPOINT_KEY_ENV', '', Key),
        Key \== ''
    ).

ep_ir_mode(Mode) :-
    ep_ir_env('CODING_ENDPOINT_IR_API', '', Api0),
    (   Api0 \== ''
    ->  downcase_atom(Api0, Api),
        ( Api == anthropic -> Mode = anthropic ; Mode = openai )
    ;   ep_backend_mode(Mode)
    ).

ep_ir_url(Mode, Url) :-
    (   ep_ir_env('CODING_ENDPOINT_IR_BACKEND', '', Url0), Url0 \== ''
    ->  Url = Url0
    ;   ep_ir_env('CODING_ENDPOINT_IR_API', '', Api), Api \== ''
    ->  (   Mode == anthropic
        ->  Url = 'https://api.anthropic.com/v1/messages'
        ;   Url = 'https://api.openai.com/v1/chat/completions'
        )
    ;   ep_backend_url(Url)
    ).

ep_ir_model(Model) :-
    ep_ir_env('CODING_ENDPOINT_IR_MODEL', '', Model0),
    (   Model0 \== ''
    ->  Model = Model0
    ;   ep_ir_env('CODING_ENDPOINT_MODEL', 'deepseek-chat', Model)
    ).

ep_ir_env(Name, Default, Value) :-
    (   getenv(Name, V), V \== ''
    ->  Value = V
    ;   Value = Default
    ).

ep_ir_int(Name, Default, N) :-
    ep_ir_env(Name, '', V),
    (   V \== '', atom_number(V, N0), integer(N0)
    ->  N = N0
    ;   N = Default
    ).

%% ---- the counts, for the trace ------------------------------------------

ep_ir_stats_reset :-
    nb_setval('$ep_ir_answered', no),
    nb_setval('$ep_ir_refused', []),
    nb_setval('$ep_ir_seen', []),
    nb_setval('$ep_ir_stats', ir(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)).

ep_ir_stats(Stats) :-
    (   catch(nb_getval('$ep_ir_stats', Stats0), _, fail)
    ->  Stats = Stats0
    ;   Stats = ir(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    ).

%% The lesson lines this request took back, the last first.
ep_ir_refused(Lines) :-
    (   catch(nb_getval('$ep_ir_refused', Lines0), _, fail)
    ->  Lines = Lines0
    ;   Lines = []
    ).

%% ir(Sentences, Read, Lesson, Rewrite, Unread, Lessons, Calls,
%%    PromptTokens, CompletionTokens, Checked, Wrong): the first five count
%% the readings by How; Checked and Wrong the verdicts this request gave.
ep_ir_count(What) :- ep_ir_count(What, 1).

ep_ir_count(What, N) :-
    ep_ir_stats(S0),
    ep_ir_field(What, I),
    arg(I, S0, V0),
    V is V0 + N,
    S0 =.. [F|Args0],
    ep_ir_set_nth(I, Args0, V, Args),
    S =.. [F|Args],
    nb_setval('$ep_ir_stats', S).

ep_ir_field(sentences, 1).
ep_ir_field(read, 2).
ep_ir_field(lesson, 3).
ep_ir_field(rewrite, 4).
ep_ir_field(unread, 5).
ep_ir_field(lessons, 6).
ep_ir_field(calls, 7).
ep_ir_field(prompt_tokens, 8).
ep_ir_field(completion_tokens, 9).
ep_ir_field(checked, 10).
ep_ir_field(wrong, 11).

ep_ir_set_nth(1, [_|T], V, [V|T]) :- !.
ep_ir_set_nth(I, [H|T], V, [H|T1]) :-
    I1 is I - 1,
    ep_ir_set_nth(I1, T, V, T1).

ep_ir_count_readings(Readings) :-
    length(Readings, N),
    ep_ir_count(sentences, N),
    forall(member(reading(_, How, _), Readings),
           (   How = rewrite(_)
           ->  ep_ir_count(rewrite)
           ;   ep_ir_count(How)
           )).
