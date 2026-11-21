%% library(reasoning/live) -- the readers' two modes: static reads as it
%% always has and asks no one; live asks a model about the static reading,
%% saves what the model teaches, and reads again with it, and what was
%% saved is read in static mode too.
%%
%%     cocolog -s test/live.pl        from this repository's root
%%
%% Every model here is a STUB, reason_live_stub(Key, Round, Reply): no
%% call leaves the process, so the case runs everywhere and costs nothing.
%% The keys are unset first, so a key in the environment cannot reach a
%% real model through a section that has no stub.

:- use_module('test/prelude.pl').
:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/live)).
:- use_module(library(reasoning/translate)).

main :-
    forall(member(V, ['REASON_LIVE_KEY', 'ANTHROPIC_API_KEY', 'OPENAI_API_KEY', 'REASON_MODE']),
           catch(unsetenv(V), _, true)),
    modes, splitting, static_asks_nothing, no_model, rewrite, words, take_back,
    second_round, context, bad_reply, kinds, explanation, translator, forget,
    checks_done.

fresh :-
    retractall(reason_live_stub(_, _, _)),
    reason_live_forget,
    reason_live_stats_reset,
    reason_set_mode(static).

calls(N) :- reason_live_stats(S), memberchk(calls-N, S).

%% ---- the mode ----------------------------------------------------------------

modes :-
    section('the mode'),
    fresh,
    nb_setval('$reason_mode', none),
    reason_mode(M1),
    check('static unless something says otherwise', M1, static),
    setenv('REASON_MODE', 'Live'),
    reason_mode(M2),
    check('REASON_MODE names the mode, in either case', M2, live),
    reason_set_mode(static),
    reason_mode(M3),
    check('reason_set_mode/1 comes before the environment', M3, static),
    unsetenv('REASON_MODE'),
    catch(( reason_set_mode(loud), E4 = none ), error(E4, _), true),
    check('a mode that is none is a domain error', E4, domain_error(reason_mode, loud)),
    catch(( reason_text('Alice sleeps.', [mode(loud)], _), E5 = none ), error(E5, _), true),
    check('and so is a mode(M) option that names none', E5, domain_error(reason_mode, loud)),
    reason_text('Alice sleeps.', [mode(live)], T6),
    check('mode(live) on one call, with no model to ask, reads as static does', T6, [sleep(alice)]).

%% ---- the sentences live mode keys by -------------------------------------------

splitting :-
    section('the sentences'),
    rv_split('Alice owns 5.5 acres.  Is she happy?  Yes!', S1),
    check('a stop before layout ends a sentence, and 5.5 is one number', S1,
          ['Alice owns 5.5 acres.', 'Is she happy?', 'Yes!']),
    rv_split("No stop at the end", S2),
    check('codes, and a last sentence with no stop', S2, ['No stop at the end']).

%% ---- static mode asks nothing -------------------------------------------------

static_asks_nothing :-
    section('static mode'),
    fresh,
    assertz(reason_live_stub('Alice', _, '{"sentences": [{"n": 1, "verdict": "wrong", "rewrite": ["Alice owns a car.", "Bob owns a car."]}]}')),
    yes_no(reason_text('Alice and Bob own a car.', _), R1),
    check('a refused sentence stays refused in static mode', R1, no),
    calls(C1),
    check('and no model is asked', C1, 0),
    findall(x, reason_live_verdict(_, _, _, _), V1),
    check('and nothing is saved', V1, []).

no_model :-
    section('live mode with no model'),
    fresh,
    reason_set_mode(live),
    yes_no(reason_live_ready, R0),
    check('no key and no stub: nothing to ask', R0, no),
    yes_no(reason_text('Alice and Bob own a car.', _), R1),
    check('live mode reads as static mode does', R1, no),
    calls(C1),
    check('and asks no one', C1, 0).

%% ---- a rewrite --------------------------------------------------------------------

rewrite :-
    section('a rewrite'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('Alice and Bob', 1,
        '```json\n{"sentences": [{"n": 1, "verdict": "wrong", "words": [], "rewrite": ["Alice owns a car.", "Bob owns a car."]}]}\n```')),
    reason_text('Alice and Bob own a car.', T1),
    check('the rewrite is read where the sentence stood (the JSON in a fence)', T1,
          [car(car_1), own(alice, car_1), car(car_2), own(bob, car_2)]),
    findall(K-S-R, reason_live_rewrite(K, S, R), Rs),
    check('and saved, keyed by the sentence', Rs,
          [text-'Alice and Bob own a car.'-['Alice owns a car.', 'Bob owns a car.']]),
    reason_version(_, Minor, _),
    findall(V, reason_live_verdict(text, 'Alice and Bob own a car.', _, V), Vs),
    check('the verdict on the refused reading is saved, with the minor version', Vs, [wrong(Minor)]),
    calls(C1),
    check('one call: the stub answers no second round', C1, 1),
    reason_set_mode(static),
    reason_text('Alice and Bob own a car.', T2),
    check('static mode reads the saved rewrite', T2, T1),
    calls(C2),
    check('and asks nothing', C2, 1),
    reason_refused('Alice and Bob own a car. Bob and Carol sleep.', F3),
    check('reason_refused/2 reads the rewrite too: the refused one is the next', F3, 'bob and carol sleep').

%% ---- a word ---------------------------------------------------------------------

words :-
    section('a word'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('joins acme', 1,
        'The verdict: {"sentences": [{"n": 1, "verdict": "wrong", "words": [{"word": "acme", "class": "proper", "base": "acme_corp"}]}]}')),
    reason_text('Dave joins acme.', T1),
    check('a proper noun the model named is in the lexicon, and the sentence reads', T1,
          [join(dave, acme_corp)]),
    findall(L, reason_live_lesson(text, L), Ls),
    check('kept as the lesson it is', Ls, [reason_proper(acme, acme_corp)]),
    retractall(reason_live_stub(_, _, _)),
    reason_set_mode(static),
    reason_sentence('Acme employs Dave.', T2),
    check('static mode reads with the word as well', T2, [employ(acme_corp, dave)]),
    fresh,
    yes_no(reason_sentence('Dave joins acme.', _), R3),
    check('forgetting takes the word back', R3, no).

take_back :-
    section('a word that moves a confirmed reading'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('Dave owns a bike', 1,
        '{"sentences": [{"n": 1, "verdict": "right"}, {"n": 2, "verdict": "wrong", "words": [{"word": "owns", "class": "verb", "base": "owns"}]}]}')),
    reason_text('Carol owns a car. Dave owns a bike.', T1),
    check('the confirmed reading is the one read', T1,
          [car(car_1), own(carol, car_1), bike(bike_1), own(dave, bike_1)]),
    yes_no(reason_verb(owns, owns), R2),
    check('the word that changed it is taken back', R2, no),
    findall(L, reason_live_lesson(_, L), Ls),
    check('and kept as no lesson', Ls, []).

second_round :-
    section('the next round'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('Alice and Bob', 1,
        '{"sentences": [{"n": 1, "verdict": "wrong", "rewrite": ["Alice owns a car.", "Bob owns a car."]}]}')),
    assertz(reason_live_stub('own(alice', 2, '{"sentences": [{"n": 1, "verdict": "right"}]}')),
    reason_text('Alice and Bob own a car.', _),
    calls(C1),
    check('the rewrite\'s reading goes back to be judged', C1, 2),
    findall(V, reason_live_verdict(text, 'Alice and Bob own a car.', _, V), Vs),
    reason_version(_, Minor, _),
    check('a verdict on each reading the sentence had', Vs, [wrong(Minor), right]),
    reason_text('Alice and Bob own a car.', _),
    calls(C2),
    check('a judged reading is not sent again', C2, 2).

%% the readings are made with the state carried, as reason_text/2 reads:
%% a pronoun is read after its antecedent, not refused alone
context :-
    section('the context'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('own(alice', 1,
        '{"sentences": [{"n": 1, "verdict": "right"}, {"n": 2, "verdict": "right"}]}')),
    reason_text('Alice is a baker. She owns a car.', _),
    findall(S, reason_live_verdict(text, S, _, right), Ss),
    check('the pronoun\'s sentence was shown with its reading, and confirmed', Ss,
          ['Alice is a baker.', 'She owns a car.']).

bad_reply :-
    section('a reply that is no answer'),
    fresh,
    reason_set_mode(live),
    assertz(reason_live_stub('Alice and Bob', 1, 'I cannot help with that.')),
    yes_no(reason_text('Alice and Bob own a car.', _), R1),
    check('the static result stands', R1, no),
    findall(x, reason_live_verdict(_, _, _, _), V1),
    check('and nothing is saved', V1, []).

%% ---- concepts and topics ------------------------------------------------------------

kinds :-
    section('the kinds of concepts and topics'),
    fresh,
    reason_text('Alice owns a car. Acme employs Alice.', Terms),
    reason_concepts(Terms, C0),
    check('static', C0, [concept(car_1, individual, 2), concept(alice, name, 2), concept(car, class, 1),
                         concept(own, relation, 1), concept(employ, relation, 1), concept(acme, name, 1)]),
    reason_set_mode(live),
    assertz(reason_live_stub('kind it was given', 1,
        '{"kinds": [{"n": 1, "verdict": "right"}, {"n": 6, "verdict": "wrong", "kind": "individual"}]}')),
    reason_concepts(Terms, C1),
    check('a kind the model corrects is the concept\'s', C1,
          [concept(car_1, individual, 2), concept(alice, name, 2), concept(car, class, 1),
           concept(own, relation, 1), concept(employ, relation, 1), concept(acme, individual, 1)]),
    findall(N-K, reason_live_kind(N, K), Ks),
    check('saved as reason_live_kind/2', Ks, [acme-individual]),
    reason_set_mode(static),
    reason_topics(Terms, Tp),
    findall(S-K2, member(topic(S, K2, _), Tp), SKs),
    check('and reason_topics/2 reads it in static mode', SKs,
          [car_1-individual, alice-name, acme-individual]).

%% ---- an explanation -------------------------------------------------------------------

explanation :-
    section('an explanation'),
    fresh,
    reason_learn('Every baker sells a cake. Alice is a baker.'),
    reason_explanation(sell(alice, cake), E0),
    check('static', E0, 'Alice sells the cake because Alice is a baker.'),
    reason_set_mode(live),
    assertz(reason_live_stub('The explanation', 1,
        '{"verdict": "wrong", "verbs": [{"base": "sell", "third": "vends"}]}')),
    reason_explanation(sell(alice, cake), E1),
    check('a verb form the model gives is the one written', E1,
          'Alice vends the cake because Alice is a baker.'),
    findall(B-T, reason_live_third(B, T), BTs),
    check('saved as reason_live_third/2', BTs, [sell-vends]),
    reason_set_mode(static),
    reason_third(sell, T2),
    check('reason_third/2 reads it in static mode', T2, vends),
    retractall(sell(_, _)), retractall(baker(_)).

%% ---- the translator ------------------------------------------------------------------

translator :-
    section('the translator'),
    fresh,
    English = 'The noun "x_dog" means "dog". The noun "x_bread" means "bread". The verb "x_eats" means "eats". The article "x_the" means "the".',
    reason_learn(English, Lesson),
    yes_no(reason_ir('The dog eats the bread.', english, _), R0),
    check('an English sentence of a plain lesson\'s words reads (the endpoint\'s English lesson)', R0, yes),
    yes_no(reason_ir('The dog eats the cake.', english, _), R1),
    check('one with a word no lesson knows does not', R1, no),
    reason_set_mode(live),
    assertz(reason_live_stub('eats the cake', 1,
        '{"sentences": [{"n": 1, "verdict": "wrong", "words": [{"word": "cake", "class": "noun", "base": "cake"}]}]}')),
    yes_no(reason_ir('The dog eats the cake.', english, _), R2),
    check('live mode teaches the word as a lesson line, and the sentence reads', R2, yes),
    findall(L, reason_live_lesson(ir(english), L), Ls),
    check('the line in the English lesson\'s form', Ls, ['The noun "x_cake" means "cake".']),
    reason_set_mode(static),
    retractall(reason_live_stub(_, _, _)),
    yes_no(reason_ir('The dog eats the cake.', english, _), R3),
    check('and static mode reads it', R3, yes),
    reason_live_forget,
    catch(tr_lessons_moved, _, true),
    yes_no(reason_ir('The dog eats the cake.', english, _), R4),
    check('forgetting takes the line back', R4, no),
    forall(member(T, Lesson), ignore(retract(T))),
    catch(tr_lessons_moved, _, true).

%% ---- forgetting --------------------------------------------------------------------

forget :-
    section('forgetting'),
    fresh,
    findall(x, ( reason_live_verdict(_, _, _, _) ; reason_live_rewrite(_, _, _) ; reason_live_kind(_, _)
               ; reason_live_third(_, _) ; reason_live_lesson(_, _) ), Left),
    check('reason_live_forget/0 leaves nothing saved', Left, []),
    reason_mode(M),
    check('and the tests leave the mode static', M, static).
