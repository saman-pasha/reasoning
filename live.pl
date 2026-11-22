%% cocolog -- library(reasoning/live): the readers' LIVE mode.
%%
%%     :- use_module(library(reasoning/live)).     % or let a live call load it
%%
%%     ?- reason_set_mode(live),
%%        reason_text("Alice owns a red car.", Terms).
%%
%% library(reasoning/reason)'s header, STATIC AND LIVE, says what the two
%% modes are. This file is the live half: it asks a language model about
%% the static reading, saves what the model teaches, and leaves the
%% extraction to the static reader, which then reads with what was saved.
%% reason.pl loads it at the first live call; a static program never does.
%%
%%     reason_live_read(+Kind, +Text)
%%         The rounds for a text, before a reader of kind Kind reads it:
%%         text (reason.pl's readers), prose (the tagger's) or ir(From)
%%         (the translator's, From a language or `any').
%%     reason_live_kinds(+Terms, +Items)
%%         The check of reason_concepts/2's concepts or reason_topics/2's
%%         topics, Terms the text's terms.
%%     reason_live_explanation(+Text)
%%         The check of an explanation's sentences.
%%     reason_live_restate(+Text, -Sentences)
%%         The restatement of a text in the grammar's forms
%%         (reason_restate/2,3), saved as reason_live_restatement(Text,
%%         Sentences) when any sentence of it reads; a save the store
%%         refuses (a clause past its page) is said on stderr, and the
%%         sentences are answered all the same.
%%     reason_live_topics(+Lang, +Text, +Meanings, +Known)
%%         The topics of library(reasoning/typology)'s meanings that its
%%         tables give none: each meaning of Meanings not asked before
%%         (the IR's meanings of the words of Text, a sentence in Lang),
%%         in ONE call, given 0 to 3 topics of Known. Saved as
%%         reason_live_topics(Meaning, Topics), Topics [] for a meaning
%%         the reply gives none or does not name, so no meaning is asked
%%         twice.
%%     reason_live_ready
%%         There is a model to ask (or a stub, below).
%%     reason_live_stats(-Pairs)
%%     reason_live_stats_reset
%%         This process's counts: calls, prompt and completion tokens,
%%         verdicts, lessons, rewrites, kinds, verb forms, restatements
%%         and the meanings given topics saved.
%%     reason_live_forget
%%         Every saved fact taken back: the verdicts, the rewrites, the
%%         kinds, the verb forms, the topics, and the lexicon facts and
%%         lesson lines live mode taught.
%%
%% ---- ONE ROUND ----------------------------------------------------------
%%
%% A text is cut into sentences (reason.pl's rv_split/2: a stop before
%% layout), each read statically -- as its saved rewrite, where it has one
%% -- and every sentence whose reading has no verdict is sent in ONE call:
%% the whole text for context, then each sentence with its reading. The
%% reply is JSON (below); each verdict is saved; for a sentence judged
%% wrong, its words are taught, each alone, and taken back if it changed a
%% reading the model confirmed (a word the grammar reads by a construction
%% of its own elsewhere, the IR repair's finding of `if'); then its
%% rewrite is saved, if every sentence of it reads and the words did not
%% already change the sentence's own reading. What changed is a new
%% reading, which the next round sends. REASON_LIVE_ROUNDS (default 2)
%% rounds at most a text.
%%
%% A WORD FOR reason.pl's READERS is a lexicon fact (reason_noun/1,
%% reason_adj/1, reason_verb/2, reason_proper/2), and only a word of the
%% sentence. A WORD FOR THE TRANSLATOR is a lesson line in the English
%% lesson's form, `The noun "x_cake" means "cake".', taught PLAIN, as
%% coding/endpoint/english_lesson.pl teaches English, and only a word
%% reason_untranslated/3 names unknown in an English source (`any' or
%% `english'): it reaches a reader whose English comes from a plain lesson,
%% not one under a named lesson (reason_learn/3). A rewrite serves a source
%% in any language.
%%
%% The reply asked for:
%%
%%   {"sentences": [{"n": 1, "verdict": "right" | "wrong",
%%                   "words": [{"word": W, "class": C, "base": B}],
%%                   "rewrite": ["Short plain sentence.", ...]}]}
%%
%%   {"kinds": [{"n": 1, "verdict": "right" | "wrong", "kind": K}]}
%%
%%   {"verdict": "right" | "wrong", "verbs": [{"base": B, "third": T}]}
%%
%%   {"sentences": ["One sentence.", "Another sentence."]}   (a restatement)
%%
%%   {"topics": [{"meaning": M, "topics": [T, ...]}]}       (the typology's)
%%
%% The JSON may come in a fence or after prose: the first `{' to the last
%% `}' is parsed. A reply that will not parse is no answer, and the round
%% saves nothing.
%%
%% ---- THE MODEL ----------------------------------------------------------
%%
%%     REASON_LIVE_KEY         the key; else ANTHROPIC_API_KEY or
%%                             OPENAI_API_KEY, the API's own
%%     REASON_LIVE_MODEL       the model (default claude-opus-5-5 for
%%                             anthropic; none for openai)
%%     REASON_LIVE_API         anthropic (default) or openai
%%     REASON_LIVE_URL         the complete URL (default the API's own)
%%     REASON_LIVE_EFFORT      output_config.effort (default low for
%%                             api.anthropic.com, none elsewhere; `none'
%%                             sends no field)
%%     REASON_LIVE_MAX_TOKENS  the reply's limit, thinking included (8000)
%%     REASON_LIVE_TIMEOUT     seconds a call may take (120)
%%     REASON_LIVE_ROUNDS      rounds at most a text (2)
%%     REASON_LIVE_RESTATE_ROUNDS  calls at most a restatement (3)
%%     REASON_LIVE_LOG         a file each call's prompt and reply are
%%                             appended to (default none)
%%
%% With no key or no model nothing is asked, and live mode reads as static
%% mode does. A call that fails says why on stderr, once, and rests the
%% model for five minutes. The key is never written anywhere.
%%
%% reason_live_stub(Key, Round, Reply) (dynamic, reason.pl) is a test's
%% model: while one such fact exists the backend is never called, and a
%% prompt that contains Key in round Round is answered Reply; a prompt no
%% stub answers ends the rounds.

:- use_module(library(json)).
:- use_module(library(curl)).
:- use_module(library(reasoning/reason)).

%% ---- the entry points ---------------------------------------------------

reason_live_read(Kind, Text) :- ( rv_text(Text) -> lv_busy(lv_rounds(Kind, Text, 1)) ; true ).
reason_live_kinds(Terms, Items) :- lv_busy(lv_kinds(Terms, Items)).
reason_live_explanation(Text) :- lv_busy(lv_explanation(Text)).
reason_live_topics(Lang, Text, Meanings, Known) :- lv_busy(lv_topics(Lang, Text, Meanings, Known)).
reason_live_restate(Text, Sentences) :-
    lv_busy(lv_restate(Text, Sentences)),
    is_list(Sentences).

%% WHILE LIVE MODE WORKS, EVERY READER IS STATIC (reason.pl's rv_quiet/0):
%% the readings it shows the model are the static ones, and nothing it
%% calls asks the model again. Whatever goes wrong inside -- a failure, a
%% ball -- is live mode's, never the reader's: the reader goes on with the
%% static result.
lv_busy(Goal) :-
    (   catch(nb_getval('$reason_live_busy', yes), _, fail)
    ->  true
    ;   setup_call_cleanup(nb_setval('$reason_live_busy', yes),
                           ignore(catch(once(Goal), Ball, lv_warn(Ball))),
                           nb_setval('$reason_live_busy', no))
    ).

lv_warn(Ball) :-
    catch(format(user_error, "reason live: ~q~n", [Ball]), _, true).

%% ---- a text, in rounds ----------------------------------------------------

lv_rounds(Kind, Text, Round) :-
    lv_int('REASON_LIVE_ROUNDS', 2, Max),
    rv_split(Text, Ss),
    lv_items(Kind, Ss, Items),
    include(lv_open(Kind), Items, Open),
    (   Open == []
    ->  true
    ;   Round > Max
    ->  true
    ;   \+ reason_live_ready
    ->  true
    ;   lv_prompt(Kind, Text, Open, System, User),
        lv_ask(Round, System, User, Reply),
        lv_answers(Reply, Answers)
    ->  lv_apply(Kind, Ss, Open, Answers),
        Round1 is Round + 1,
        lv_rounds(Kind, Text, Round1)
    ;   true
    ).

%% item(Sentence, Current, Reading): the sentence, the sentences read for
%% it (its saved rewrite, or itself), and their reading -- read(List) or
%% refused. A text's sentences are read in one pass, so a pronoun reads
%% after its antecedent.
lv_items(Kind, Ss, Items) :-
    findall(S-Cur, ( member(S, Ss), lv_current(Kind, S, Cur) ), Pairs),
    findall(C, ( member(_-Cur, Pairs), member(C, Cur) ), Flat),
    lv_readings(Kind, Flat, Readings),
    lv_regroup(Pairs, Readings, Items).

lv_current(Kind, S, Cur) :-
    (   reason_live_rewrite(Kind, S, Rs) -> Cur = Rs ; Cur = [S] ).

lv_regroup([], _, []).
lv_regroup([S-Cur|Ps], Rs0, [item(S, Cur, R)|Is]) :-
    length(Cur, N), length(Mine, N), append(Mine, Rest, Rs0),
    lv_join(Mine, R),
    lv_regroup(Ps, Rest, Is).

lv_join(Rs, R) :-
    (   memberchk(refused, Rs)
    ->  R = refused
    ;   findall(X, member(read(X), Rs), Xs),
        append(Xs, All),
        R = read(All)
    ).

lv_readings(text, Ss, Rs) :- !, rv_text_readings(Ss, Rs).
lv_readings(prose, Ss, Rs) :- !, maplist(lv_prose_reading, Ss, Rs).
lv_readings(ir(From), Ss, Rs) :- maplist(lv_ir_reading(From), Ss, Rs).

lv_prose_reading(S, R) :-
    (   catch(reason_prose(S, T), _, fail), T \== [] -> R = read(T) ; R = refused ).

lv_ir_reading(From, S, R) :-
    (   catch(reason_ir(S, From, IRs), _, fail) -> R = read(IRs) ; R = refused ).

%% a reading the model has not judged: none of its verdicts, or a wrong one
%% given under an older minor version
lv_open(Kind, item(S, _, R)) :-
    lv_reading_text(Kind, R, RT),
    \+ lv_judged(Kind, S, RT).

lv_judged(Kind, S, RT) :-
    (   reason_live_verdict(Kind, S, tagger, tagger)     % the tagger's rewrite: no model asked
    ->  true
    ;   reason_live_verdict(Kind, S, RT, right)
    ->  true
    ;   reason_live_verdict(Kind, S, RT, wrong(M)),
        lv_minor(M)
    ).

lv_minor(M) :- reason_version(_, M, _).

%% A READING IS SHOWN AS ITS LOGICAL FORM, and the translator's said back
%% in English as well: a wrong parse that keeps the word order says itself
%% back as the very sentence (the IR repair's finding).
lv_reading_text(_, refused, 'none: the parser could not read it') :- !.
lv_reading_text(ir(_), read(IRs), Text) :- !,
    (   catch(reason_ir_text(IRs, english, Back), _, fail)
    ->  true
    ;   Back = '?'
    ),
    lv_term_text(IRs, Form),
    format(atom(Text), 'said back: ~w | logical form: ~w', [Back, Form]).
lv_reading_text(_, read(Terms), Text) :- lv_term_text(Terms, Text).

lv_term_text(T0, Text) :-
    copy_term(T0, T),
    numbervars(T, 0, _),
    format(atom(Text), '~W', [T, [quoted(true), numbervars(true)]]).

%% ---- the prompt ---------------------------------------------------------------

lv_prompt(Kind, Text, Open, System, User) :-
    lv_system(Kind, System),
    findall(Block, ( nth1(N, Open, item(S, _, R)), lv_reading_text(Kind, R, RT),
                     format(atom(Block), '~w. ~w~n   reading: ~w', [N, S, RT]) ),
            Blocks),
    atomic_list_concat(Blocks, '\n', Body),
    lv_text_atom(Text, Whole),
    format(atom(User), 'The whole text, for context:~n~n~w~n~nThe sentences, and what the parser made of each:~n~n~w',
           [Whole, Body]).

lv_system(Kind, System) :-
    lv_describe(Kind, What, Classes),
    format(atom(System),
'You check a deterministic parser and teach it. ~w For each numbered sentence you get the parser\'s reading, or the note that it could not read the sentence.

Answer with one JSON object and nothing else:
{"sentences": [{"n": 1, "verdict": "right", "words": [], "rewrite": []}]}

- verdict: "right" when the reading keeps the sentence\'s meaning, each word in its role; "wrong" when it does not, and when the parser could not read the sentence.
- words: for a wrong sentence, each word the parser read in the wrong role or did not know, as {"word": the word as written, "class": one of ~w, "base": its base form (a verb\'s infinitive; for a proper noun the name in lower case, with _ for a space)}.
- rewrite: for a wrong sentence, short plain sentences with the same meaning that such a parser can read: each one subject, one verb and its objects; no pronoun whose referent is in another sentence; no and, or, but; no subordinate clause. Keep the sentence\'s names and numbers, and end each sentence with a full stop.
Give words, a rewrite or both for a wrong sentence, and neither for a right one.', [What, Classes]).

lv_describe(text,
    'It reads controlled English, one clause a sentence, into Prolog terms: a fact such as own(alice, A) with car(A), a rule (Head :- Body), neg(Fact) for a denial, question(Goal) or question(X, Goal) for a question; a variable is a thing the sentence introduced with a or every. A noun phrase with the (the car) reads as a constant of that name (car), never as a thing an earlier sentence introduced. So a rewrite cannot share one thing between two sentences: say which meaning it keeps, one car for each owner (each sentence with its own a car), or the one shared car as a name.',
    'noun, adjective, verb, proper') :- !.
lv_describe(prose,
    'It normalises plain English prose into Prolog terms: a fact such as own(alice, A) with car(A), a rule (Head :- Body), neg(Fact) for a denial.',
    'noun, adjective, verb, proper') :- !.
lv_describe(ir(_),
    'It reads sentences into an intermediate representation, shown said back in English and as its term, from which other languages are written.',
    'noun, verb, adjective, adverb, preposition, conjunction').

lv_text_atom(Text, A) :- ( atom(Text) -> A = Text ; atom_codes(A, Text) ).

%% ---- a restatement: the whole text said again in the grammar's forms ----
%%
%% ONE CALL A ROUND. The first sends the text; a later one sends the text
%% and the last answer, each sentence marked read or not, and asks for the
%% whole list again with each unread sentence said again or left out. A
%% sentence counts where the grammar ALONE reads it (the reply's sentences
%% are read with no saved rewrite and no tagger, live mode's own readers
%% being static). The rounds end when every sentence reads or at
%% REASON_LIVE_RESTATE_ROUNDS (3); a round that gets no answer leaves the last
%% round's sentences. What reads is saved, in the model's order; a reply
%% with nothing that reads saves nothing.
lv_restate(Text, Read) :-
    reason_live_ready,
    lv_int('REASON_LIVE_RESTATE_ROUNDS', 3, Max0),
    Max is max(1, Max0),
    lv_restate_rounds(1, Max, Text, none, Read),
    Read \== [],
    lv_count(restatements),
    catch(( retractall(reason_live_restatement(Text, _)),
            assertz(reason_live_restatement(Text, Read)) ),
          Ball, lv_warn(Ball)).

lv_restate_rounds(R, Max, Text, Last, Read) :-
    lv_restate_prompt(Text, Last, System, User),
    (   lv_ask(R, System, User, Reply),
        lv_restated(Reply, All),
        All \== []
    ->  partition(lv_grammar_reads, All, Read0, Unread),
        (   ( Unread == [] ; R >= Max )
        ->  Read = Read0
        ;   R1 is R + 1,
            lv_restate_rounds(R1, Max, Text, last(All, Unread, Read0), Read)
        )
    ;   Last = last(_, _, Read)
    ).

lv_grammar_reads(S) :- catch(reason_text(S, _), _, fail).

%% the reply's sentences: each one sentence with its stop, short
lv_restated(Reply, Sentences) :-
    lv_json(Reply, J),
    lv_get(J, sentences, Items), is_list(Items),
    findall(S, ( member(I, Items), atom(I), lv_sentence(I, S) ), Sentences).

lv_restate_prompt(Text, Last, System, User) :-
    lv_restate_system(System),
    lv_text_atom(Text, Whole),
    (   Last == none
    ->  format(atom(User), 'The requirement:~n~n~w', [Whole])
    ;   Last = last(All, Unread, _),
        findall(Line, ( nth1(N, All, S),
                        ( memberchk(S, Unread) -> M = 'NOT READ' ; M = read ),
                        format(atom(Line), '~w. ~w (~w)', [N, S, M]) ),
                Lines),
        atomic_list_concat(Lines, '\n', Body),
        format(atom(User), 'The requirement:~n~n~w~n~nYour sentences, and whether the parser read each:~n~n~w~n~nGive the whole list again: each read sentence as it is, and each sentence the parser did not read said again in other forms, in two or three sentences where one will not do (the list of what the parser refuses says how). Leave a sentence out only when no form can carry its rule.',
               [Whole, Body])
    ).

lv_restate_system(
'You say a requirement again in controlled English: the input language of a deterministic parser, which reads each sentence into a logical term. A programmer will read your sentences beside the requirement, so they must say exactly what the requirement says.

Rules:
- Say what the requirement says, and nothing more. Never add a fact, a value, a default, an output or a format it does not state. Where the requirement leaves a thing open -- what an error prints, how the output is laid out -- leave it open.
- Say every rule, each in a sentence of its own, in the order of the requirement. A rule that no one form says whole is said in two or three sentences of the forms. Leave a rule out only when no sentence of the forms can carry any of it, and never change a rule to fit a form.
- One clause a sentence. No pronoun; no and, or, but, if, when, because; no comparison; no parentheses, code, symbols or lists. End each sentence with a full stop.
- Name the program and each single thing with a proper noun (Ledger, Alice). Say a class with a noun (every account, a key).
- Join the words of a compound noun or a name with _ (latest_version, commit_id, number_of_keys). A command named by a letter or a word is a compound noun: the command d is a d_command. After a verb with no object, join a preposition to the verb (Alice lives_in Rome).
- A word between quotation marks stands for itself.

What the parser refuses, and the form it reads instead:
- An adjective after Every: not "Every visible key gets "yes"." but "Every key that is visible gets "yes"."
- Every anywhere but at the head of the sentence: not "Ledger reads every line." but "Ledger reads the lines."
- A condition said with for, with, per or of a: not "Every q_command prints "yes" for a known key." but "Every q_command that names a known_account prints "yes"."
- No as a determiner: not "Ledger prints no prompt." but "Ledger does not print a prompt."
- An object with no article: not "Ledger uses recursion." but "Ledger uses a recursion."
- A or the before a noun as the subject of a verb: not "A view is a snapshot." or "The last_writer wins." but "Every view is a snapshot." and "Every last_writer wins." The goes before a subject only with is and a value: "The maximum_amount is 1000."
- A phrase after an object takes the: "from the standard_input", "in the ascending_order", "to the balance", "of the account".

The forms the parser reads:
Alice owns a red car.
Alice is happy.
Alice is not happy.
Bob does not own a car.
Alice sleeps.
Alice may access the server.
Alice lives_in Rome.
Alice pays 500 euros.
The rent is 500 euros.
Alice is the mother of Bob.
Every employee is a person.
Every employee has a badge.
Every employee that is authorized may access the server.
Every employee that owns a car may park.
Every noun that ends in "a" is feminine.
Ledger reads the lines from the standard_input.
Every line that is blank is ignored.
Every amount is an integer.
Every account_name is a word.
Every account has a balance.
Every d_command adds an amount to the balance.
Every w_command that names a closed_account causes an error.
Every account that is not open causes an error.
Every withdrawal that exceeds the balance causes an error.
Every account that is open may receive a deposit.
Every q_command that names a known_account prints "yes".
Every account that is frozen gets "frozen".
Every l_command prints the names in the ascending_order.
Every l_command that names an empty_ledger prints nothing.
Every c_command closes the account.
Every report holds the balances of the accounts.
Every b_command begins a session at the latest_state.
Every session excludes the later deposits.
Every output_line ends with a newline.
Every insertion is recursive.
Ledger allocates the records dynamically.
Ledger uses a hash_table.
Ledger does not print a prompt.
Ledger has an unbounded number_of_accounts.
The maximum_amount is 1000.

Answer with one JSON object and nothing else:
{"sentences": ["First sentence.", "Second sentence."]}').

%% ---- the reply -------------------------------------------------------------------

%% answer(N, Verdict, Words, Rewrite): Verdict right or wrong, Words a list
%% of word(W, Class, Base), Rewrite a list of sentences.
lv_answers(Reply, Answers) :-
    lv_json(Reply, J),
    lv_get(J, sentences, Items), is_list(Items),
    findall(A, ( member(I, Items), lv_answer(I, A) ), Answers).

lv_answer(I, answer(N, V, Words, Rewrite)) :-
    lv_get(I, n, N), integer(N),
    lv_get(I, verdict, V0), lv_verdict(V0, V),
    (   lv_get(I, words, Ws0), is_list(Ws0)
    ->  findall(word(W, C, B), ( member(Wj, Ws0), lv_get(Wj, word, W), atom(W),
                                lv_get(Wj, class, C), atom(C),
                                ( lv_get(Wj, base, B0), atom(B0), B0 \== '' -> B = B0 ; B = W ) ),
                Words)
    ;   Words = []
    ),
    (   lv_get(I, rewrite, Rs0), is_list(Rs0)
    ->  findall(R, ( member(R0, Rs0), atom(R0), lv_sentence(R0, R) ), Rewrite)
    ;   Rewrite = []
    ).

lv_verdict(right, right).
lv_verdict(wrong, wrong).

%% the first `{' to the last `}': a fence, or prose around it, is no JSON
lv_json(Reply, J) :-
    atom(Reply),
    sub_atom(Reply, B, _, _, '{'), !,
    findall(E, sub_atom(Reply, E, 1, _, '}'), Es), Es \== [],
    max_list(Es, E0),
    E0 > B, L is E0 - B + 1,
    sub_atom(Reply, B, L, _, Inner),
    catch(json_parse(Inner, J), _, fail).

lv_get(json(Pairs), K, V) :- memberchk(K-V, Pairs).

%% a sentence of a rewrite: trimmed, a stop at its end, and short
lv_sentence(R0, R) :-
    rv_split(R0, [S]),
    atom_length(S, L), L =< 300,
    (   sub_atom(S, _, 1, 0, Stop), memberchk(Stop, ['.', '!', '?']) -> R = S ; atom_concat(S, '.', R) ).

%% ---- saving an answer ---------------------------------------------------------

lv_apply(Kind, Ss, Open, Answers) :-
    lv_minor(Minor),
    forall(( member(answer(N, V, _, _), Answers), nth1(N, Open, item(S, _, R)) ),
           lv_verdict_save(Kind, S, R, V, Minor)),
    forall(( member(answer(N, wrong, Words, Rewrite), Answers), nth1(N, Open, Item) ),
           lv_repair(Kind, Ss, Item, Words, Rewrite)).

lv_verdict_save(Kind, S, R, V, Minor) :-
    lv_reading_text(Kind, R, RT),
    retractall(reason_live_verdict(Kind, S, RT, _)),
    (   V == right -> W = right ; W = wrong(Minor) ),
    assertz(reason_live_verdict(Kind, S, RT, W)),
    lv_count(verdicts).

lv_repair(Kind, Ss, item(S, _, R0), Words, Rewrite) :-
    forall(member(word(W, C, B), Words), lv_teach(Kind, Ss, S, W, C, B)),
    lv_items(Kind, Ss, Items1),
    (   memberchk(item(S, _, R1), Items1) -> true ; R1 = R0 ),
    (   R1 \== R0, R1 \== refused
    ->  true                                % the words changed it: judged next round
    ;   Rewrite \== [],
        lv_readings(Kind, Rewrite, RRs),
        \+ memberchk(refused, RRs)
    ->  retractall(reason_live_rewrite(Kind, S, _)),
        assertz(reason_live_rewrite(Kind, S, Rewrite)),
        lv_count(rewrites)
    ;   true
    ).

%% A WORD IS TAUGHT ALONE, AND TAKEN BACK IF IT MOVED A CONFIRMED READING.
%% Only a word of the sentence is taught, in letters, and only what does
%% not hold already.
lv_teach(Kind, Ss, S, W0, C0, B0) :-
    downcase_atom(W0, W), downcase_atom(C0, C), downcase_atom(B0, B1),
    lv_letters(W),
    (   lv_lesson(Kind, S, W, C, B1, Lesson, Facts)
    ->  lv_confirmed(Kind, Ss, Before),
        forall(member(F, Facts), assertz(F)),
        lv_moved(Kind),
        lv_confirmed_now(Kind, Ss, Before, Kept),
        (   Kept == Before
        ->  assertz(reason_live_lesson(Kind, Lesson)),
            lv_count(lessons)
        ;   forall(member(F, Facts), ignore(retract(F))),
            lv_moved(Kind)
        )
    ;   true
    ).

%% the lexicon fact of a word for reason.pl's readers, or a lesson line in
%% the English lesson's form for the translator's
lv_lesson(Kind, S, W, C, B, Fact, [Fact]) :-
    memberchk(Kind, [text, prose]), !,
    lv_in_sentence(S, W),
    lv_word_fact(C, W, B, Fact),
    \+ catch(Fact, _, fail).
lv_lesson(ir(From), S, W, C, B, Line, Facts) :-
    memberchk(From, [any, english]),
    memberchk(C, [noun, verb, adjective, adverb, preposition, conjunction]),
    catch(reason_untranslated(S, From, Unknown0), _, fail),
    findall(U, ( member(U0, Unknown0), atom(U0), downcase_atom(U0, U) ), Unknown),
    memberchk(W, Unknown),
    lv_letters(B),
    (   C == verb, catch(reason_third(B, T), _, fail) -> English = T ; English = B ),
    atom_concat(x_, English, X),
    \+ catch(mean(X, English), _, fail),
    format(atom(Line), 'The ~w "~w" means "~w".', [C, X, English]),
    catch(reason_text(Line, Terms), _, fail),
    exclude(lv_holds, Terms, Facts),
    Facts \== [].

lv_word_fact(noun, W, _, reason_noun(W)).
lv_word_fact(adjective, W, _, reason_adj(W)).
lv_word_fact(verb, W, B, reason_verb(W, B)) :- lv_letters(B).
lv_word_fact(proper, W, B, reason_proper(W, B)) :- lv_name(B).

lv_holds(T) :- catch(clause(T, true), _, fail), !.

lv_in_sentence(S, W) :-
    catch(reason_tokens(S, Tokens), _, fail),
    memberchk(word(W, _), Tokens).

lv_letters(W) :-
    atom(W), atom_codes(W, Cs), Cs \== [],
    length(Cs, L), L =< 40,
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z )).

lv_name(W) :-
    atom(W), atom_codes(W, Cs), Cs \== [],
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z ; C >= 0'0, C =< 0'9 ; C =:= 0'_ )).

%% the translator caches what its lessons say; a lesson changed tells it
lv_moved(ir(_)) :- !, catch(tr_lessons_moved, _, true).
lv_moved(_).

%% S-ReadingText of each sentence whose reading the model confirmed, and
%% the same of the ones still read so after a lesson
lv_confirmed(Kind, Ss, Confirmed) :-
    lv_items(Kind, Ss, Items),
    findall(S-RT, ( member(item(S, _, R), Items), lv_reading_text(Kind, R, RT),
                    reason_live_verdict(Kind, S, RT, right) ),
            Confirmed).

lv_confirmed_now(Kind, Ss, Before, Kept) :-
    lv_items(Kind, Ss, Items),
    findall(S-RT, ( member(item(S, _, R), Items), lv_reading_text(Kind, R, RT),
                    memberchk(S-RT, Before) ),
            Kept).

%% ---- concepts and topics: the kinds ------------------------------------------------

lv_kinds(Terms, Items) :-
    findall(N-K, ( member(I, Items), lv_kind_item(I, N, K) ), Pairs0),
    list_to_set(Pairs0, Pairs),
    exclude(lv_kind_judged, Pairs, Open),
    (   Open == [] -> true
    ;   \+ reason_live_ready -> true
    ;   lv_kind_prompt(Terms, Open, System, User),
        lv_ask(1, System, User, Reply),
        lv_json(Reply, J),
        lv_get(J, kinds, Ks), is_list(Ks)
    ->  lv_minor(Minor),
        forall(( member(Kj, Ks), lv_get(Kj, n, N), integer(N), nth1(N, Open, Name-Kind),
                 lv_get(Kj, verdict, V0), lv_verdict(V0, V) ),
               lv_kind_save(Name, Kind, V, Kj, Minor))
    ;   true
    ).

lv_kind_item(concept(N, K, _), N, K).
lv_kind_item(topic(N, K, _), N, K).

lv_kind_judged(N-K) :-
    (   reason_live_verdict(kinds, N, K, right)
    ->  true
    ;   reason_live_verdict(kinds, N, K, wrong(M)), lv_minor(M)
    ).

lv_kind_save(Name, Kind, V, Kj, Minor) :-
    retractall(reason_live_verdict(kinds, Name, Kind, _)),
    (   V == right
    ->  assertz(reason_live_verdict(kinds, Name, Kind, right))
    ;   assertz(reason_live_verdict(kinds, Name, Kind, wrong(Minor))),
        (   lv_get(Kj, kind, K0), atom(K0), downcase_atom(K0, K),
            lv_kind_name(K), K \== Kind
        ->  retractall(reason_live_kind(Name, _)),
            assertz(reason_live_kind(Name, K)),
            lv_count(kinds)
        ;   true
        )
    ),
    lv_count(verdicts).

lv_kind_name(name).
lv_kind_name(individual).
lv_kind_name(class).
lv_kind_name(property).
lv_kind_name(relation).
lv_kind_name(word).

lv_kind_prompt(Terms, Open, System, User) :-
    System = 'You check what a reader of controlled English said each subject of a text is. The kinds are: name (a proper noun: a person, a place, a company), individual (a thing the text introduced with a or an, named like car_1), class (a common noun), property (an adjective), relation (a verb that relates things), word (a quoted word the text talks about).

Answer with one JSON object and nothing else:
{"kinds": [{"n": 1, "verdict": "right"}, {"n": 2, "verdict": "wrong", "kind": "name"}]}

verdict is "right" when the kind given is the subject\'s kind in the text; for "wrong", kind is the right one.',
    lv_term_text(Terms, TermsText),
    findall(Line, ( nth1(N, Open, Name-Kind), format(atom(Line), '~w. ~w: ~w', [N, Name, Kind]) ), Lines),
    atomic_list_concat(Lines, '\n', Body),
    format(atom(User), 'The text, as the terms the reader made of it:~n~n~w~n~nEach subject and the kind it was given:~n~n~w', [TermsText, Body]).

%% ---- an explanation: its verbs ---------------------------------------------------

lv_explanation(Text) :-
    (   Text == '' -> true
    ;   lv_judged(explanation, Text, Text) -> true
    ;   \+ reason_live_ready -> true
    ;   System = 'A program wrote an explanation in English from a proof. Check its verbs: after a singular subject a verb is in the third person singular (owns, has, carries, goes). Give each verb form that is wrong, with its base form and its right third person singular.

Answer with one JSON object and nothing else:
{"verdict": "right", "verbs": []}
or
{"verdict": "wrong", "verbs": [{"base": "carry", "third": "carries"}]}',
        format(atom(User), 'The explanation:~n~n~w', [Text]),
        lv_ask(1, System, User, Reply),
        lv_json(Reply, J),
        lv_get(J, verdict, V0), lv_verdict(V0, V)
    ->  lv_minor(Minor),
        retractall(reason_live_verdict(explanation, Text, Text, _)),
        (   V == right
        ->  assertz(reason_live_verdict(explanation, Text, Text, right))
        ;   assertz(reason_live_verdict(explanation, Text, Text, wrong(Minor))),
            (   lv_get(J, verbs, Vs), is_list(Vs) -> true ; Vs = [] ),
            forall(member(Vj, Vs), lv_third_save(Vj))
        ),
        lv_count(verdicts)
    ;   true
    ).

lv_third_save(Vj) :-
    (   lv_get(Vj, base, B0), lv_get(Vj, third, T0), atom(B0), atom(T0),
        downcase_atom(B0, B), downcase_atom(T0, T),
        lv_letters(B), lv_letters(T),
        \+ ( catch(reason_third(B, T1), _, fail), T1 == T )
    ->  retractall(reason_live_third(B, _)),
        assertz(reason_live_third(B, T)),
        lv_count(thirds)
    ;   true
    ).

%% ---- the typology's meanings: their topics ----------------------------------------
%%
%% A meaning library(reasoning/typology) reads is an English word for one
%% sense (`lime', `file'). Where a word has several and the tables give a
%% meaning no topic, the reader cannot choose by the context; the model
%% gives such a meaning its topics, from the topics the tables know, and
%% the reader then chooses as with a topic row.

lv_topics(Lang, Text, Meanings0, Known) :-
    exclude(lv_topics_asked, Meanings0, Meanings),
    (   Meanings == [] -> true
    ;   Known == [] -> true
    ;   \+ reason_live_ready -> true
    ;   lv_topic_prompt(Lang, Text, Meanings, Known, System, User),
        lv_ask(topics, System, User, Reply),
        lv_json(Reply, J),
        lv_get(J, topics, Items), is_list(Items)
    ->  forall(member(M, Meanings), lv_topic_save(M, Items, Known))
    ;   true
    ).

lv_topics_asked(M) :- reason_live_topics(M, _).

%% the topics the reply gives M, each one of Known, three at most; none
%% where it does not name M
lv_topic_save(M, Items, Known) :-
    (   member(I, Items), lv_get(I, meaning, M0), atom(M0), downcase_atom(M0, M)
    ->  (   lv_get(I, topics, Ts0), is_list(Ts0) -> true ; Ts0 = [] ),
        findall(T, ( member(T0, Ts0), atom(T0), downcase_atom(T0, T), memberchk(T, Known) ), Ts1),
        list_to_set(Ts1, Ts2),
        lv_topics_first(3, Ts2, Ts)
    ;   Ts = []
    ),
    retractall(reason_live_topics(M, _)),
    assertz(reason_live_topics(M, Ts)),
    (   Ts == [] -> true ; lv_count(topics) ).

lv_topics_first(N, Xs, Ys) :-
    (   length(Xs, L), L =< N -> Ys = Xs ; length(Ys, N), append(Ys, _, Xs) ).

lv_topic_prompt(Lang, Text, Meanings, Known, System, User) :-
    System = 'A reader of sentences chooses between the meanings of a word by the topics of the words around it. Each meaning is an English word for one sense of a word in the sentence. Give each meaning 0 to 3 topics, only from the topics listed, and only a topic the meaning is clearly about; give [] where none fits.

Answer with one JSON object and nothing else, one entry a meaning:
{"topics": [{"meaning": "apple", "topics": ["food", "plant"]}, {"meaning": "hammer", "topics": ["tool"]}, {"meaning": "idea", "topics": []}]}',
    atomic_list_concat(Known, ', ', KnownText),
    atomic_list_concat(Meanings, '\n', MeaningText),
    format(atom(User), 'The language: ~w~nThe sentence: ~w~n~nThe topics: ~w~n~nThe meanings:~n~w',
           [Lang, Text, KnownText, MeaningText]).

%% ---- the model ---------------------------------------------------------------------

reason_live_ready :-
    (   reason_live_stub(_, _, _)
    ->  true
    ;   lv_key(_, _),
        lv_model(_),
        \+ lv_resting
    ).

lv_ask(Round, System, User, Reply) :-
    (   reason_live_stub(_, _, _)
    ->  reason_live_stub(Key, Round, Reply),
        sub_atom(User, _, _, _, Key),
        !
    ;   lv_backend(System, User, Reply)
    ),
    lv_count(calls),
    lv_log(Round, User, Reply).

lv_log(Round, User, Reply) :-
    lv_env('REASON_LIVE_LOG', '', File),
    (   File == ''
    ->  true
    ;   format(codes(Cs), '== round ~w~n-- prompt~n~w~n-- reply~n~w~n~n', [Round, User, Reply]),
        catch(append_file_from_codes(File, Cs), _, true)
    ).

lv_backend(System, User, Reply) :-
    lv_api(Api),
    lv_key(Api, Key),
    lv_model(Model),
    lv_url(Api, Url),
    lv_int('REASON_LIVE_MAX_TOKENS', 8000, Max),
    lv_int('REASON_LIVE_TIMEOUT', 120, Timeout),
    lv_body(Api, Url, Model, Max, System, User, Body),
    json_codes(Body, Codes),
    lv_headers(Api, Key, Headers),
    append(Headers, [timeout(Timeout), max_size(16777216)], Opts),
    (   catch(curl_post(Url, 'application/json', Codes, Opts, Status, Resp), E, true)
    ->  true
    ;   E = post_failed
    ),
    (   var(E),
        integer(Status), Status >= 200, Status < 300,
        catch(json_parse(Resp, J), _, fail),
        lv_reply_text(Api, J, Reply),
        Reply \== ''
    ->  lv_usage(Api, J)
    ;   lv_failed(E, Status, Resp),
        fail
    ).

lv_body(anthropic, Url, Model, Max, System, User, json(Pairs)) :- !,
    Pairs0 = [model-Model, max_tokens-Max, system-System,
              messages-[json([role-user, content-User])]],
    lv_effort(Url, Effort),
    (   Effort == none
    ->  Pairs = Pairs0
    ;   append(Pairs0, [output_config-json([effort-Effort])], Pairs)
    ).
lv_body(_, _, Model, Max, System, User,
        json([model-Model, max_tokens-Max,
              messages-[json([role-system, content-System]),
                        json([role-user, content-User])]])).

lv_headers(anthropic, Key, [header(H), header('anthropic-version: 2023-06-01')]) :- !,
    format(atom(H), 'x-api-key: ~w', [Key]).
lv_headers(_, Key, [header(H)]) :-
    format(atom(H), 'Authorization: Bearer ~w', [Key]).

%% A REPLY'S TEXT IS ITS TEXT BLOCKS. A reply with only a thinking block, or
%% none -- a refusal reads so -- has no text, and is no answer.
lv_reply_text(anthropic, J, Reply) :- !,
    lv_get(J, content, Blocks), is_list(Blocks),
    findall(T, ( member(B, Blocks), lv_get(B, type, text), lv_get(B, text, T), atom(T) ), Ts),
    atomic_list_concat(Ts, '', Reply).
lv_reply_text(_, J, Reply) :-
    lv_get(J, choices, [C|_]),
    lv_get(C, message, M),
    lv_get(M, content, Reply), atom(Reply).

lv_usage(Api, J) :-
    (   lv_get(J, usage, U)
    ->  (   Api == anthropic
        ->  ( lv_get(U, input_tokens, P) -> true ; P = 0 ),
            ( lv_get(U, output_tokens, C) -> true ; C = 0 )
        ;   ( lv_get(U, prompt_tokens, P) -> true ; P = 0 ),
            ( lv_get(U, completion_tokens, C) -> true ; C = 0 )
        ),
        lv_count(prompt_tokens, P),
        lv_count(completion_tokens, C)
    ;   true
    ).

%% a failed call says why once, and rests the model for five minutes
lv_failed(E, Status, Resp) :-
    (   nonvar(E)
    ->  format(atom(Why), '~q', [E])
    ;   is_list(Resp)
    ->  atom_codes(Why0, Resp), lv_first(Why0, 300, Why)
    ;   atom(Resp)
    ->  lv_first(Resp, 300, Why)
    ;   Why = 'no reply'
    ),
    (   var(Status) -> S = none ; S = Status ),
    catch(format(user_error, "reason live: the model call failed (status ~w): ~w~n", [S, Why]), _, true),
    get_time(Now),
    nb_setval('$reason_live_rest', Now).

lv_first(Text, Max, First) :-
    atom_length(Text, L),
    (   L > Max -> sub_atom(Text, 0, Max, _, First) ; First = Text ).

lv_resting :-
    catch(nb_getval('$reason_live_rest', Then), _, fail),
    number(Then),
    get_time(Now),
    Now - Then < 300.

lv_api(Api) :-
    lv_env('REASON_LIVE_API', anthropic, A0),
    downcase_atom(A0, A),
    (   A == openai -> Api = openai ; Api = anthropic ).

lv_key(Api, Key) :-
    (   lv_env('REASON_LIVE_KEY', '', K0), K0 \== ''
    ->  Key = K0
    ;   ( Api == openai -> Var = 'OPENAI_API_KEY' ; Var = 'ANTHROPIC_API_KEY' ),
        lv_env(Var, '', Key), Key \== ''
    ).
lv_key(Key) :- lv_api(Api), lv_key(Api, Key).

lv_model(Model) :-
    (   lv_env('REASON_LIVE_MODEL', '', M0), M0 \== ''
    ->  Model = M0
    ;   lv_api(anthropic),
        Model = 'claude-opus-5-5'
    ).

lv_url(Api, Url) :-
    (   lv_env('REASON_LIVE_URL', '', U0), U0 \== ''
    ->  Url = U0
    ;   Api == anthropic
    ->  Url = 'https://api.anthropic.com/v1/messages'
    ;   Url = 'https://api.openai.com/v1/chat/completions'
    ).

%% THE MODEL THINKS UNLESS IT IS TOLD HOW MUCH, and the thinking counts
%% against max_tokens: `low' on Anthropic's own API, as the IR repair
%% found, and no field elsewhere.
lv_effort(Url, Effort) :-
    lv_env('REASON_LIVE_EFFORT', '', E0),
    (   E0 \== '' -> Effort = E0
    ;   sub_atom(Url, _, _, _, 'api.anthropic.com') -> Effort = low
    ;   Effort = none
    ).

lv_env(Name, Default, Value) :-
    (   getenv(Name, V0), V0 \== ''
    ->  atom_string(Value, V0)
    ;   Value = Default
    ).

lv_int(Name, Default, N) :-
    lv_env(Name, '', V),
    (   V \== '', catch(atom_number(V, N0), _, fail), integer(N0), N0 >= 0
    ->  N = N0
    ;   N = Default
    ).

%% ---- the counts, and forgetting ----------------------------------------------------

lv_count(K) :- lv_count(K, 1).
lv_count(K, N) :-
    atom_concat('$reason_live_', K, G),
    (   catch(nb_getval(G, V0), _, fail), integer(V0) -> true ; V0 = 0 ),
    V is V0 + N,
    nb_setval(G, V).

reason_live_stats(Pairs) :-
    findall(K-V, ( member(K, [calls, prompt_tokens, completion_tokens, verdicts,
                              lessons, rewrites, kinds, thirds, restatements, topics]),
                   atom_concat('$reason_live_', K, G),
                   ( catch(nb_getval(G, V0), _, fail), integer(V0) -> V = V0 ; V = 0 ) ),
            Pairs).

reason_live_stats_reset :-
    forall(member(K, [calls, prompt_tokens, completion_tokens, verdicts,
                      lessons, rewrites, kinds, thirds, restatements, topics]),
           ( atom_concat('$reason_live_', K, G), nb_setval(G, 0) )).

reason_live_forget :-
    nb_setval('$rv_tagged', []),
    forall(reason_live_lesson(Kind, Lesson), lv_unteach(Kind, Lesson)),
    retractall(reason_live_lesson(_, _)),
    retractall(reason_live_verdict(_, _, _, _)),
    retractall(reason_live_rewrite(_, _, _)),
    retractall(reason_live_kind(_, _)),
    retractall(reason_live_third(_, _)),
    retractall(reason_live_restatement(_, _)),
    retractall(reason_live_topics(_, _)).

lv_unteach(ir(From), Line) :- !,
    (   atom(Line), catch(reason_text(Line, Terms), _, fail)
    ->  forall(member(T, Terms), ignore(retract(T)))
    ;   true
    ),
    lv_moved(ir(From)).
lv_unteach(_, Fact) :- ignore(retract(Fact)).
