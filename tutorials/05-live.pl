%% reasoning tutorial 05 -- library(reasoning/live): the readers' two modes.
%%
%% TIER 2: `use_module(library(reasoning/reason))', from reason.pl; the
%% live half, live.pl, loads itself at the first live call. Clauses only.
%%
%%     cocolog -s tutorials/05-live.pl
%%
%% A READER HAS TWO MODES. Static reads with the grammar and the lexicon as
%% they stand and asks no one: everything lessons 01 and 04 showed. Live
%% first asks a language model about the static reading -- is it right,
%% and if not, which words did the reader get wrong and how would the
%% sentence read in plain short sentences -- SAVES what the model teaches,
%% and then reads statically again, with what was saved. And what was saved
%% is the reader's from then on, in both modes: a lexicon fact, a rewrite,
%% a kind, a verb form. Under `cocolog --embed' it is in the store, and the
%% next process reads it with no model at all.
%%
%% The model here is a STUB, reason_live_stub(Key, Round, Reply): a prompt
%% that contains Key is answered Reply, and no call leaves the process. A
%% real one is named by the environment (REASON_LIVE_KEY, REASON_LIVE_MODEL;
%% live.pl's header has the rest), and with none, live mode reads as static
%% mode does.

:- use_module(library(reasoning/reason)).

main :-
    reason_set_mode(static),
    reason_set_tagger(off),           % sections 1-7 are the model's; 8 is the tagger's

    %% 1. A sentence static mode refuses: the grammar reads no conjunction.
    ( reason_text('Alice and Bob own a car.', _) -> R1 = read ; R1 = refused ),
    must('static mode refuses a conjunction', R1, refused),

    %% 2. Live mode asks. The model says the reading is wrong (there was
    %% none) and gives a rewrite the grammar reads; the rewrite is saved,
    %% and the text is read again with it.
    assertz(reason_live_stub('Alice and Bob', 1,
        '{"sentences": [{"n": 1, "verdict": "wrong", "rewrite": ["Alice owns a car.", "Bob owns a car."]}]}')),
    reason_text('Alice and Bob own a car.', [mode(live)], T2),
    must('live mode reads the rewrite where the sentence stood', T2,
         [car(car_1), own(alice, car_1), car(car_2), own(bob, car_2)]),
    reason_live_rewrite(text, 'Alice and Bob own a car.', Rw),
    show('what was saved', Rw),

    %% 3. And static mode reads the same, with no model asked: the stub is
    %% gone, and so is the mode.
    retractall(reason_live_stub(_, _, _)),
    reason_text('Alice and Bob own a car.', T3),
    must('static mode reads the saved rewrite', T3, T2),

    %% 4. A word. `acme' in lower case is no object to the grammar; the
    %% model names it a proper noun, and the lexicon learns it.
    ( reason_sentence('Dave joins acme.', _) -> R4 = read ; R4 = refused ),
    must('a lower-case company is refused', R4, refused),
    assertz(reason_live_stub('joins acme', 1,
        '{"sentences": [{"n": 1, "verdict": "wrong", "words": [{"word": "acme", "class": "proper", "base": "acme_corp"}]}]}')),
    reason_set_mode(live),
    reason_sentence('Dave joins acme.', T4),
    must('live mode: the word is in the lexicon, and the sentence reads', T4, [join(dave, acme_corp)]),
    ( reason_proper(acme, C4) -> true ; C4 = none ),
    must('as reason_proper/2, the lexicon every reader asks first', C4, acme_corp),

    %% 5. A word that would change a reading the model CONFIRMED is taken
    %% back: the model says the first sentence is right, and teaches a
    %% surface form for `owns' that would make it owns/2.
    assertz(reason_live_stub('Dave owns a bike', 1,
        '{"sentences": [{"n": 1, "verdict": "right"}, {"n": 2, "verdict": "wrong", "words": [{"word": "owns", "class": "verb", "base": "owns"}]}]}')),
    reason_text('Carol owns a car. Dave owns a bike.', T5),
    must('the confirmed reading stands', T5,
         [car(car_1), own(carol, car_1), bike(bike_1), own(dave, bike_1)]),
    ( reason_verb(owns, owns) -> R5 = kept ; R5 = taken_back ),
    must('and the word is taken back', R5, taken_back),

    %% 6. A verdict is kept, so a reading the model judged is not sent again.
    use_module(library(reasoning/live)),
    reason_live_stats(S6a), memberchk(calls-C6a, S6a),
    reason_text('Carol owns a car. Dave owns a bike.', _),
    reason_live_stats(S6b), memberchk(calls-C6b, S6b),
    must('the same text again asks nothing', C6b, C6a),

    %% 7. Forgetting takes back every saved fact and every word taught.
    retractall(reason_live_stub(_, _, _)),
    reason_live_forget,
    reason_set_mode(static),
    ( reason_text('Alice and Bob own a car.', _) -> R7 = read ; R7 = refused ),
    must('after reason_live_forget/0 static mode refuses again', R7, refused),

    %% 8. THE TAGGER, a step before any model (since 1.17.0). A sentence the
    %% grammar refuses is tagged alone by the network of lesson 03 -- its
    %% model in the knowledge base, or the one shipped beside the library
    %% -- and the controlled text it makes, if the grammar reads it, is
    %% saved as the sentence's rewrite, in both modes; live mode then asks
    %% the model only about what the tagger could not read. It is on unless
    %% reason_set_tagger(off), REASON_TAGGER=off or a call's tagger(false)
    %% says otherwise, and it needs library(torch).
    reason_set_tagger(on),
    (   catch(( use_module(library(torch)), use_module(library(reasoning/tagger)) ), _, fail)
    ->  ( reason_text('Well, Bob lives in Bristol.', [tagger(false)], _) -> R8 = read ; R8 = refused ),
        must('the grammar alone refuses a word of prose in front', R8, refused),
        reason_text('Alice owns a red car. Well, Bob lives in Bristol.', T8),
        must('the tagger reads it, and the grammar reads the rest', T8,
             [car(car_1), red(car_1), own(alice, car_1), live_in(bob, bristol)]),
        reason_live_rewrite(text, 'Well, Bob lives in Bristol.', Rw8),
        show('the controlled text it made, saved', Rw8)
    ;   show('the tagger', 'library(torch) is not built here, and the grammar reads alone')
    ),
    reason_live_forget,
    format("~ndone~n", []).

%% Duplicated at the foot of every tutorial on purpose: one you can copy
%% anywhere and run is worth six repeated lines, and one that needs a support
%% file beside it stops working the moment it moves.

show(Label, Value) :- format("   ~w = ~q~n", [Label, Value]).

must(Label, Got, Want) :-
    (   Got == Want
    ->  format("   ~w = ~q~n", [Label, Got])
    ;   format("   ~w = ~q  BUT THIS LESSON SAYS ~q~n", [Label, Got, Want]),
        fail
    ).
