%% cocolog -- library(reasoning/reason): a paragraph in, predicates out.
%%
%%     :- use_module(library(reasoning/reason)).
%%
%%     ?- reason_text("Alice owns a red car. Every employee that is
%%                     authorized may access the server.", Terms).
%%     Terms = [ car(car_1), red(car_1), own(alice, car_1),
%%               (may_access(X, server) :- employee(X), authorized(X)) ].
%%
%% TIER 2, and clauses only. Its grammar is a DCG over tokens, the way
%% library(http) reads HTTP/1.1 and library(xml) reads a document: the
%% semantic argument of each nonterminal is the TERM the phrase stands for,
%% so parsing and interpretation are one walk. Nothing is called out to.
%%
%% THE LEXICON IS DATA. Four dynamic predicates say what a word is --
%% reason_noun/1, reason_adj/1, reason_verb/2, reason_proper/2 -- and a
%% program extends them with assertz/1 like any other fact. They are
%% consulted FIRST; when they are silent, POSITION decides: the last word of
%% a noun phrase is its noun, every word between the determiner and that
%% noun is an adjective, and the word after the subject is the verb. So the
%% examples above parse with an empty lexicon, and a lexicon entry is how a
%% program says a word is not what its position suggests. The closed
%% classes -- determiners, quantifiers, modals, the copula, `does', `not',
%% `that' -- are fixed, because those are the words the grammar is made of.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     reason_text(+Text, -Terms)
%%     reason_text(+Text, +Options, -Terms)
%%         Text is an atom, a string or a code list; sentences end at `.',
%%         `!' or `?'. Terms is a list: facts, neg/1 facts, and rules
%%         written (Head :- Body), each one a term assertz/1 will take.
%%         Indefinite individuals are NAMED, car_1 then car_2 across the
%%         whole text, unless Options carries variables(true).
%%
%%     reason_learn(+Text)
%%     reason_learn(+Text, -Terms)
%%         reason_text/2, and every term asserted: the text is knowledge
%%         now, its rules run, and reason_ask/2 answers about it.
%%
%%     reason_sentence(+Text, -Terms)
%%     reason_sentence(+Text, +Options, -Terms)
%%         One sentence, with no state: a subject pronoun in it is refused.
%%         The grammar is DETERMINISTIC by construction --
%%         the noun is the last word of its phrase and the closed classes
%%         are fixed -- so there is one reading or none; a program that
%%         adds grammar clauses of its own gets its readings on
%%         backtracking, which is the engine's search and needs nothing
%%         from here.
%%
%%     reason_tokens(+Text, -Tokens)
%%         The tokeniser, exposed. A token is word(Lower, upper|lower),
%%         num(N) for digits (500, 5.5, 1,000; `5%' is 5 and the word
%%         percent), quoted(Word) for a word between quotation marks, `.'
%%         or `,'. A byte past 127 is part of a word, so `pequeño' is one;
%%         `¿', `¡' and the typographic dashes are punctuation. An
%%         APOSTROPHE between letters ends the word and stays with it, so
%%         `l'incolumità' is `l'' and the noun -- two words, which a lesson
%%         can then give meanings; with no letter after it (`un po'') it is
%%         punctuation like any other. The typographic apostrophe is
%%         written as the plain one.
%%
%%     reason_refused(+Text, -Sentence)
%%         The first sentence reason_text/2 would refuse, as its words
%%         joined by spaces -- and every later one on backtracking. FAILS
%%         when the whole text parses. reason_text/2 refuses a paragraph
%%         whole and says nothing; this is how a caller finds out which
%%         sentence to rewrite.
%%
%%     reason_question(+Text, -Question)
%%         One sentence read as a question: question(Goal) for yes or no,
%%         question(X, Goal) with X for what `who', `what' or `where' asks.
%%         The forms are under THE QUESTIONS IT READS, below.
%%
%%     reason_ask(+Text, -Answers)
%%         Every question in Text answered against the knowledge base as it
%%         stands, one answer each in order; the statements in Text are
%%         read for their state and asserted by nobody. A yes-or-no
%%         question answers yes(Why), no(Why), unknown or conflict --
%%         truth/2's verdict, with the fact or the rule it rests on -- and a
%%         who, what or where question a list of Value-Why, empty when
%%         nobody. Neither this nor reason_question/2 resets the state, so
%%         `Is she licensed?' may follow the paragraph that introduced her.
%%         A `Why ...?' question answers because(Text), the explanation
%%         below, or unknown.
%%
%%     reason_ask(+Text, -Answers, -Explanations)
%%         The same, with the EXPLANATION beside each answer: the proof in
%%         sentences (reason_explanation/2) for a yes, the denial as said
%%         for a no, `Nothing shows that ...' for unknown, and for a who,
%%         what or where question a list of Value-Text.
%%
%%     reason_explain(+Goal, -Why)
%%         The whole proof of a goal, every level of it: fact(G) when G was
%%         said; rule(G, Whys) when a rule gave it, with the why of every
%%         goal of its body; absent(G) for a \+ G that held because nothing
%%         proves G, denied(G) when neg(G) was said besides; forall(A, B,
%%         Instances) for \+ (A, \+ B), a universal -- every square the
%%         king may move to is unsafe -- with each instance's own why;
%%         holds(G) for a builtin, holds(\+ G) for one that fails (`"perro"
%%         does not end in "a"'); conj(Whys) for a conjunction asked.
%%         Fails when nothing proves the goal; reason_why/2 is one level of
%%         this.
%%
%%     reason_explanation(+Goal, -Text)
%%         That proof in sentences, depth first: `Kh8 is checkmated because
%%         Kh8 is a captive and nothing shows that Kh8 is defended. Kh8 is
%%         a captive because ...', one sentence per rule, `as said' for a
%%         fact at the top, and `whenever Kh8 may move to X, X is unsafe
%%         (X: G8, G7 and H7)' for a universal, each instance explained
%%         after it. A goal nothing proves is tried as its denial, so a
%%         denied goal explains as `..., as said.'; fails otherwise. The
%%         words are the knowledge base's own: a verb in the third person
%%         (reason_third/2), a proper noun the reader met capitalised, a
%%         class noun it met after `a', `the' or `every' with its article,
%%         any other atom as `the ...', an individual car_1 as `the car'.
%%
%%     reason_concepts(+Terms, -Concepts)
%%         What the terms MENTION: concept(Name, Kind, Mentions), the most
%%         mentioned first, ties in order of first mention. Kind is name (a
%%         proper noun the reader met), individual (flat_1), class (a noun:
%%         king in king(kh8), `the rent' as an object), property (attacked),
%%         or relation (attack, may_move_to); a mention is one occurrence in
%%         a fact, a denial, an amount, or a rule's head or body.
%%
%%     reason_topics(+Terms, -Topics)
%%         The terms as an OUTLINE: topic(Subject, Kind, Subtopics), one per
%%         subject something is said about -- a name, an individual, a class
%%         atom, and the class or property a rule defines -- the most said
%%         about first, ties in order of first mention. Subtopics is a list
%%         of Group-Items in order of first mention: class-[king],
%%         property-[black], relation(occupy)-[[h8]], relation(rent_in)-
%%         [[flat_1, bristol]], denied-[pay(marco, rent)], amount-
%%         [quantity(600, euros)]; members-[kh8] under a class, rules-[Rule]
%%         under the class a rule quantifies over, definition-[Rule] under
%%         the class or property its head names; and by(attack)-[Claim]
%%         under the object of a claim, what is said of it from the other
%%         side.
%%
%%     reason_topic_lines(+Topics, -Lines)
%%         Topics as lines, one atom each: `Kh8, a king: black; occupies H8;
%%         may move to G8, G7 and H7.', `Square (G8, G7 and H7): every
%%         square that is attacked is unsafe; ...', `Unsafe: a square that
%%         is attacked; ...', `H8: Kh8 occupies it; Re8 attacks it.'
%%
%%     reason_outline(+Text, -Lines)
%%     reason_outline_prose(+Text, -Lines)
%%         reason_text/2, or the shipped tagger over typed prose, and then
%%         the topics as lines.
%%
%%     reason_third(+Base, -ThirdPerson)
%%         The inflector, rs_base/2's inverse: own -> owns, watch ->
%%         watches, carry -> carries, have -> has. library(reasoning/normalise)'s
%%         normalise_third/2 is this.
%%
%%     reason_prose(+Text, -Terms)
%%     reason_ask_prose(+Text, -Answers)
%%     reason_ask_prose(+Text, -Answers, -Explanations)
%%         TYPED prose, not the controlled English: the shipped tagger
%%         normalises it first, then reason_text/2 or reason_ask/2 reads
%%         what came out. OPTIONAL, and loaded on first use --
%%         library(reasoning/tagger) and the model beside the library
%%         (tagger_pretrained/1 there), which need library(torch) and the
%%         embedded engine. Without them the call raises
%%         existence_error(tagger, pretrained), and nothing else here
%%         changes.
%%
%%     reason_why(+Goal, -Why)
%%         The REASON a ground goal holds: fact when it was said,
%%         rule(Head :- Body) with the body as it proved when a rule gave
%%         it (one level), denied when its negation was said; fails when
%%         nothing holds it up.
%%
%%     reason_amount(+Object, -Quantity)
%%         What `how much' asks for: the quantity the object IS -- a
%%         quantity/2,3 term or a bare number -- or, for a class atom, the
%%         amount the text gave it: after `Nadia pays the rent. The rent is
%%         500 euros.' the object `rent' answers quantity(500, euros). The
%%         goal a how-much question reads to calls it last.
%%
%%     reason_count(+Object, +Noun, -N)
%%         What `how many NOUN' asks for: N when the object is
%%         quantity(N, Noun) or quantity(N, Noun, Of). The goal a how-many
%%         question reads to calls it last.
%%
%%     end_in(+Word, +Suffix)         end_with/2, begin_with/2, start_with/2
%%         What a rule over WORDS asks: `Every noun that ends in "a" is
%%         feminine' is feminine(X) :- noun(X), end_in(X, a), and these
%%         four are the library's so that the rule RUNS. Both atoms; and
%%         `a vowel' or `a consonant' in place of the letters -- `ends in
%%         a vowel' is end_in(X, vowel) -- the five vowels and their
%%         accented forms being the vowels.
%%
%%     reason_base(+Word, -Base)
%%         The stemmer, reason_third/2's inverse: owns -> own, has -> have,
%%         carries -> carry -- and houses -> house, boxes -> box, since a
%%         noun's plural is made the same way.
%%
%%     truth(+Goal, -Truth)
%%         true, false, unknown or conflict, for a GROUND goal against the
%%         knowledge base as it stands: what a text said, what it denied,
%%         what it never mentioned, and what it contradicted. The whole
%%         argument is below, under FIVE DECISIONS.
%%
%%     reason_closed(?Name/Arity)          dynamic; see truth/2
%%
%%     reason_name(+Terms, -Named)
%%         What reason_text/2 does last: every variable is named after the
%%         noun that introduced it, numbered from 1 in order of appearance.
%%
%%     reason_noun(?Word)                  dynamic, the lexicon
%%     reason_adj(?Word)
%%     reason_verb(?Word, ?Base)
%%     reason_proper(?Word, ?Constant)
%%
%%     reason_version(-Version)
%%     reason_version(-Major, -Minor, -Patch)
%%         The version of THIS LIBRARY -- everything under library/reasoning/:
%%         the grammar, the translator, the tagger, the lexicon, the lessons
%%         and the shipped model -- which is its own number and not cocolog's:
%%         a change here moves this one and `cocolog --version' stays. Version
%%         is an atom, 'X.Y.Z'; the three integers are what a program
%%         compares, since '1.10.0' sorts before '1.9.0' as an atom. The
%%         rules for moving it are in CLAUDE.md, under The version.
%%
%% ---- THE SENTENCES IT READS -------------------------------------------
%%
%%   Alice owns a red car.               car(V), red(V), own(alice, V)
%%   Alice is happy.                     happy(alice)
%%   Alice is a person.                  person(alice)
%%   Alice is not happy.                 neg(happy(alice))
%%   Bob does not own a car.             neg(own(bob, car))
%%   Alice sleeps.                       sleep(alice)
%%   Alice may access the server.        may_access(alice, server)
%%   Alice lives_in Rome.                live_in(alice, rome)
%%   Alice rents a flat in Rome.         flat(V), rent_in(alice, V, rome)
%%   Alice is a baker. She is licensed.  baker(alice), licensed(alice)
%%   Alice pays 500 euros.               pay(alice, quantity(500, euros))
%%   Alice owns three vineyards.         own(alice, quantity(3, vineyards))
%%   Alice buys two litres of milk.      buy(alice, quantity(2, litres, milk))
%%   The rent is 500 euros.              amount(rent, quantity(500, euros))
%%   "casa" means "house".               mean(casa, house)
%%   The noun "casa" means "house".      noun(casa), mean(casa, house)
%%   The feminine article "la" means "the".   article(la), feminine(la), mean(la, the)
%%   "casa" ends in "a".                 end_in(casa, a)
%%   "casa" ends in a vowel.             end_in(casa, vowel)
%%   "los" is the plural of "el".        plural_of(los, el)
%%   Alice is the mother of Bob.         mother_of(alice, bob)
%%   Omar keeps the tractor in the barn. keep_in(omar, tractor, barn)
%%   Does Alice own a car?               question((car(V), own(alice, V)))
%%   Who is licensed?                    question(X, licensed(X))
%%   Why is Alice licensed?              question(why(licensed(alice)))
%%   Is "mesa" feminine?                 question(feminine(mesa))
%%   What does "perro" mean?             question(X, mean(perro, X))
%%   What is the plural of "el"?         question(X, plural_of(X, el))
%%   Is "los" the plural of "el"?        question(plural_of(los, el))
%%
%% And what a text is ABOUT: reason_concepts/2 ranks what it mentions,
%% reason_topics/2 turns it into an outline by subject with the sub-topics
%% under each, and reason_outline/2 writes that outline as lines.
%%   How much does Alice pay?            question(Q, (pay(alice, O), reason_amount(O, Q)))
%%   How many vineyards does Alice own?  question(N, (own(alice, O), reason_count(O, vineyards, N)))
%%   Every employee is a person.         person(X) :- employee(X)
%%   Every employee has a badge.         have(X, badge) :- employee(X)
%%   Every employee that is authorized   may_access(X, server) :-
%%       may access the server.              employee(X), authorized(X)
%%   Every employee that is not          may_access(X, server) :-
%%       suspended may access the server.    employee(X), \+ suspended(X)
%%   Every person that is a baker        sell(X, bread) :- person(X), baker(X)
%%       sells the bread.
%%   Every employee that owns a car      may_park(X) :- employee(X), own(X, car)
%%       may park.
%%   Every noun that ends in "a"         feminine(X) :- noun(X), end_in(X, a)
%%       is feminine.
%%   Every noun that does not end in     masculine(X) :- noun(X), \+ end_in(X, a)
%%       "a" is masculine.
%%   Every noun that ends in a vowel     take_in(X, s, plural) :- noun(X), end_in(X, vowel)
%%       takes "s" in the plural.
%%
%% A subject is a proper noun or a quantified class; an object is a proper
%% noun or a determined noun phrase. A place after an object joins the
%% relation -- `rents a flat in Rome' is rent_in/3, the place its last
%% argument -- exactly as a preposition written joined to a bare verb does
%% (`lives_in Rome' is live_in/2, the verb inside it stemmed): after a bare
%% verb the two words are ONE relation and are written as one, so `sleeps
%% in Rome' is refused where `sleeps_in Rome' is read, and it is
%% library(reasoning/normalise)'s assembler that joins them. Which is also
%% why `Alice owns a house in Rome' is a fact about a house in Rome and
%% `Alice sleeps in Rome' is not a fact at all: only after an object can the
%% preposition belong to nothing else. A paragraph carries ONE piece of
%% state from sentence to sentence, the subject of the last fact, and
%% `she', `he' or `they' as a subject stands for it -- so `Alice is a
%% baker. She is licensed.' is two facts about Alice, and `She is licensed'
%% with no fact before it is refused. That is the one coreference this
%% reader does: `it' is left alone (`It rains' is not about anybody), and
%% a pronoun as an object is refused. A QUESTION IS A GOAL, the term the
%% statement would have asserted with a variable where the question word
%% stood, and reason_ask/2 answers it against the knowledge base with the
%% REASON beside the answer: the fact that was said, the rule and the
%% body that proved it, or the denial. AND `WHY' ASKS FOR THE WHOLE
%% PROOF: `Why is Kh8 checkmated?' answers because(Text), where Text is
%% every level of the proof in sentences (reason_explanation/2) -- the
%% rule that gave the claim, each goal of its body, and what gave each of
%% those, down to what was said; a universal in a body, \+ (A, \+ B),
%% is `whenever A, B' with every instance explained. A QUANTITY IS A VALUE, NOT AN
%% INDIVIDUAL: a number and the noun it counts -- `500 euros', `three
%% vineyards', `5.5 percent', `two litres of milk' -- reads as
%% quantity(N, Noun) or quantity(N, Unit, Noun), the noun AS WRITTEN
%% (euros, not euro, by the rule below), the number as digits or as the
%% number words (`twenty five', `two hundred', `a hundred'), and a bare
%% number as the number. No car_1 is introduced for `three cars', because
%% three of them is not one, so the object of the claim is the quantity
%% term itself, in a fact, a rule and a denial alike -- must_pay(X,
%% quantity(500, euros)) :- tenant(X); neg(pay(bob, quantity(500,
%% euros))). `The rent is 500 euros' is the one sentence with a definite
%% SUBJECT, and it is amount(rent, quantity(500, euros)): what a definite
%% object costs, said once and asked for by `how much'. A quantity
%% carries no adjective (`three red cars' is refused, not read with `red'
%% dropped) and no comparison (`more than 500 euros' is refused). A
%% CONDITION IS A RELATIVE CLAUSE -- `that is [not] ADJ', `that is [not]
%% a NOUN', or `that [does not] VERB [OBJECT]' -- and it is deliberately
%% the ONLY way: `if ... then ...' with a pronoun would need the pronoun bound
%% inside a rule, and a rule with two conditions is two sentences or one
%% relative clause per condition. A WORD IN QUOTATION MARKS IS MENTIONED,
%% NOT USED, and stands for itself: `"casa" means "house"' is mean(casa,
%% house) whatever the words are -- `"a"' is the letter and not the
%% article, `"is"' a word and not the copula -- and `the noun "casa"',
%% `the feminine article "la"' say what the word is besides: noun(casa);
%% article(la), feminine(la). A quoted word stands as a subject, as an
%% object, and -- with a determined noun, as its class atom -- after a
%% preposition after a BARE verb, where a place is refused: `ends in "a"'
%% is end_in(X, a) and `ends in a vowel' end_in(X, vowel), because
%% neither can belong to anything but the verb, and end_in/2 knows the
%% two letter classes. `is the NOUN of X' is a relation the noun names,
%% plural_of(los, el), mother_of(alice, bob); and a place after an object
%% may be a definite phrase, `keeps the tractor in the barn' being
%% keep_in(omar, tractor, barn). That is how a LANGUAGE LESSON reads --
%% vocabulary as facts, grammar as rules over the classes and end_in/2 --
%% and library(reasoning/translate) is the translator over it, asking the
%% knowledge base and knowing no word of the language itself. What it
%% does not read it REFUSES, by
%% failing -- reason_text/2 fails on the first sentence that does not
%% parse rather than skipping it, because a paragraph half understood is
%% worse than one refused; reason_refused/2 then names the sentence.
%%
%% ---- FIVE DECISIONS, EACH WITH ITS REASON -----------------------------
%%
%% A NOUN IS TAKEN AS WRITTEN. `All employees are people' gives
%% people(X) :- employees(X): no plural comes off, because a rule that
%% strips an `s' from a noun turns `bus' into `bu' and `glass' into
%% `glas', and a program that wants the singular writes it.
%%
%% A VERB IS REPORTED IN ITS BASE FORM. `Alice owns a car' and `Bob does
%% not own a car' must name ONE predicate or no rule can mention both, and
%% the surface forms differ (`owns', `own'). So a third-person `-s' comes
%% off, `has' becomes `have', and reason_verb/2 overrides: assertz(
%% reason_verb(owns, owns)) keeps the surface form if a program wants it.
%%
%% AN INDEFINITE OBJECT IS AN INDIVIDUAL IN A FACT AND A CLASS EVERYWHERE
%% ELSE. `Alice owns a car' asserts that some car exists -- so a fresh
%% individual, car_1, and the fact car(car_1) beside own(alice, car_1).
%% `Bob does not own a car' asserts that NO such car exists, and a fresh
%% car_2 would assert one; `Every employee has a badge' has no single
%% badge for the head of a rule to name. Both report the object by its
%% class atom: neg(own(bob, car)), have(X, badge) :- employee(X). Prolog
%% has no existential in a head and no negative fact, and this is the
%% honest projection onto what it has, written where a reader will see
%% it rather than left to be discovered.
%%
%% A DEFINITE OBJECT IS THE CLASS ATOM. `the server' names THE server, the
%% one this program is about, so it is the constant `server' -- which is
%% what a rule wants: may_access(X, server). A program with several
%% servers writes their names.
%%
%% NEGATION IS neg/1, NOT \+/1. A negative SENTENCE is knowledge -- `Bob
%% does not own a car' is something the text said -- and \+ is a question
%% about provability, which is not the same claim. neg/1 is a term a
%% program can assertz, query and reason over as it likes; the one place
%% \+ appears is the BODY of a rule from `that is not', where "not
%% provable" is exactly what a rule condition means.
%%
%% A RULE DECLARES WHAT ITS BODY NAMES, because otherwise it throws.
%% `\+ exempt(X)' over a knowledge base with no exempt/1 in it is an
%% existence_error, not a failure -- SWI's rule too -- so `every tenant that
%% is not exempt must pay the rent' would throw at the first tenant unless
%% somebody had also been declared exempt. reason_text/2 therefore calls
%% dynamic/1 for every predicate a rule's body mentions, at the moment it
%% hands the rule back: the promise that every term is one assertz/1 takes
%% is only worth keeping if the rule then RUNS. Found by the lesson, whose
%% twelfth section named nobody exempt.
%%
%% A MODAL JOINS ITS VERB. `may access' is may_access/2 and `must submit'
%% is must_submit/2, because a modality is part of what is claimed and a
%% predicate name is where a claim's shape lives. `may' and `must' as
%% separate wrapper terms would be a deontic logic, which this is not.
%%
%% truth/2 IS FOUR-VALUED, AND THAT IS ONE MORE THAN WAS ASKED FOR. Prolog
%% answers yes or no, and no means "not provable", which is not "false":
%% a knowledge base that never mentioned cats cannot deny that Tom is one.
%% So truth(G, T) asks two questions -- does G prove, does neg(G) prove --
%% and reads the pair:
%%
%%     G proves, neg(G) does not      true      the text said it
%%     neg(G) proves, G does not      false     the text denied it
%%     neither proves                 unknown   the text never said
%%     BOTH prove                     conflict  the text contradicted itself
%%
%% The fourth is the one a three-valued answer would hide: a paragraph that
%% says `Alice is happy' and `Alice is not happy' has told you something,
%% and answering `true' about it because the positive fact was found first
%% is not reading the text, it is reading the clause order. A predicate that
%% does not exist proves nothing and is `unknown', not an error: the whole
%% point of the value is that silence is an answer.
%%
%% AND A PROGRAM MAY CLOSE A PREDICATE. Sometimes the text IS the whole
%% truth -- a roster, a list of who is exempt -- and then not-provable
%% really is false. assertz(reason_closed(exempt/1)) says so, and truth/2
%% answers `false' for exempt(X) it cannot prove. It is opt-in, per
%% predicate, and the default is open, because the text that gives you
%% every fact about a predicate is rarer than the one that gives you some.
%%
%% THE GOAL MUST BE GROUND. truth(own(bob, X), T) is not a question with a
%% truth value, it is a search -- and `true' for "some X proves" beside
%% `false' for "some other X is denied" would be two quantifiers wearing
%% one word. A variable raises instantiation_error; findall/3 is the tool
%% for the question that was meant. And the class-atom decision above
%% reaches here: neg(own(bob, car)) makes truth(own(bob, car), T) false and
%% leaves truth(own(bob, car_1), T) unknown, because the projection kept
%% the class and lost the individual. That is the cost, stated.
%%
%% ---- WHAT IT IS NOT ---------------------------------------------------
%%
%% It is not a parser of English. It reads a controlled subset -- the
%% shapes above and nothing else -- and a program that wants more writes
%% grammar clauses of its own beside these, the way a library(httpd) page
%% is written beside the server. It does not resolve pronouns, so `Alice
%% bought a car. She uses it.' is two sentences of which the second fails.
%% It reads a prepositional phrase only where it can belong to one thing:
%% a place after an object (`rents a flat in Rome', `keeps the tractor in
%% the barn'), and a mention or a determined noun after a bare verb's
%% preposition (`ends in a vowel', `sleeps at the house'); a proper noun
%% after a bare verb is refused, because `sleeps_in Rome' is that
%% relation's written form. What it cannot place it REFUSES rather than
%% misreads: `Alice owns a house in Rome' once came back as rome(rome_1),
%% house(rome_1), in(rome_1), own(alice, rome_1) -- the position rule
%% taking the last word for the noun -- and that is worse than a refusal.
%% Prepositions are closed, so a phrase that fits nowhere is left over,
%% the sentence fails, and reason_refused/2 names it.
%% It does not read a conjunction, and refuses one BY RULE: `Alice and
%% Bob' parsed as and(alice, bob) while `and' was an open word, and a
%% sentence refused only because its tail did not fit is one misreading
%% away from being accepted. `and', `or' and `but' are closed.
%% It does not read compound nouns: `an identification number' is a
%% `number' that is `identification', by the position rule, and a program
%% that means one word writes identification_number. And it decides nothing
%% about truth: what comes out is what the text SAID, shaped for a
%% knowledge base, and whether it is so is the rest of the program's job.

:- dynamic reason_noun/1.
:- dynamic reason_adj/1.
:- dynamic reason_verb/2.
:- dynamic reason_proper/2.
:- dynamic reason_closed/1.

%% ---- version ---------------------------------------------------------
%%
%% THE ONE PLACE. This line is the library's version; reason_version/1 is
%% made from it, and no code, test or lesson in the tree spells the number.
%% Bump it in the commit that changes this repository, never afterwards.

reason_version(1, 0, 57).

reason_version(Version) :-
    reason_version(Major, Minor, Patch),
    atomic_list_concat([Major, Minor, Patch], '.', Version).

%% ---- text ------------------------------------------------------------

reason_text(Text, Terms) :- reason_text(Text, [], Terms).

reason_text(Text, Options, Terms) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    nb_setval('$rs_subject', none),
    rs_read(Sentences, Options, Terms).

rs_read(Sentences, Options, Terms) :-
    rs_each(Sentences, Raw),
    rs_declare(Raw),
    (   memberchk(variables(true), Options)
    ->  Terms = Raw
    ;   reason_name(Raw, Terms)
    ).

%% ---- learn: read, and assert ------------------------------------------

reason_learn(Text) :- reason_learn(Text, _).
reason_learn(Text, Terms) :- reason_text(Text, Terms), forall(member(T, Terms), assertz(T)).

%% ---- what a rule over WORDS asks ---------------------------------------
%% `Every noun that ends in "a" is feminine' is feminine(X) :- noun(X),
%% end_in(X, a), and end_in/2 has to hold of the word for the rule to run:
%% these four are the library's. A suffix or a prefix, both atoms, and a
%% whole word is its own suffix. The explanation says one as it is
%% (`"mesa" ends in "a"'), never through its clause.
end_in(W, C)     :- atom(C), rl_letter_class(C), !, atom(W), rl_last_letter(W, L), rl_letter_is(L, C).
end_in(W, S)     :- atom(W), atom(S), sub_atom(W, _, _, 0, S).
end_with(W, S)   :- end_in(W, S).
begin_with(W, C) :- atom(C), rl_letter_class(C), !, atom(W), rl_first_letter(W, L), rl_letter_is(L, C).
begin_with(W, P) :- atom(W), atom(P), sub_atom(W, 0, _, _, P).
start_with(W, P) :- begin_with(W, P).

%% `ends in a vowel', `begins with a consonant': the class atom a determined
%% noun reads to, and a letter is a byte or, past 127, the two bytes of an
%% accented one; the vowels are the five and their accented forms
rl_letter_class(vowel).
rl_letter_class(consonant).
rl_letter_is(L, vowel) :- rl_vowel(L).
rl_letter_is(L, consonant) :- rl_letter(L), \+ rl_vowel(L).
rl_last_letter(W, L) :-
    atom_codes(W, Cs), Cs \== [],
    ( \+ rt_chars, append(_, [B1, B2], Cs), B1 >= 192, B2 >= 128 -> L = [B1, B2] ; last(Cs, C), L = [C] ).
rl_first_letter(W, L) :-
    atom_codes(W, [C|Cs]),
    ( \+ rt_chars, C >= 192, Cs = [C2|_], C2 >= 128 -> L = [C, C2] ; L = [C] ).
rl_vowel([C]) :- memberchk(C, [0'a, 0'e, 0'i, 0'o, 0'u, 0'A, 0'E, 0'I, 0'O, 0'U]).
rl_vowel([195, C]) :- memberchk(C, [161, 169, 173, 179, 186, 129, 137, 141, 147, 154]).   % á é í ó ú Á É Í Ó Ú
rl_vowel([C]) :- memberchk(C, [225, 233, 237, 243, 250, 193, 201, 205, 211, 218]), rt_chars.   % the same, as code points
rl_letter([C]) :- ( C >= 0'a, C =< 0'z -> true ; C >= 0'A, C =< 0'Z ).
rl_letter([_, _]).
rl_letter([C]) :- C >= 128, C =< 2047, rt_chars.      % a letter or a sign of the two-byte range, as one code point

%% the stemmer, reason_third/2's inverse, for a program: owns -> own, and
%% houses -> house, since a plural is made the same way
reason_base(W, B) :- rs_base(W, B).

re_helper(end_in(_, _)).    re_helper(end_with(_, _)).
re_helper(begin_with(_, _)). re_helper(start_with(_, _)).

%% ---- questions: a goal, and the reason with the answer ----------------
%% The state is NOT reset here: a question may follow the paragraph the
%% last reason_text/2 read, and `Is she licensed?' asks about its subject.

reason_question(Text, Question) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, [S|_]),
    rs_notes_reset,
    phrase(rs_question(Question), S),
    rs_notes_commit.

reason_ask(Text, Answers) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    rs_read(Sentences, [variables(true)], Terms),
    findall(A, ( member(Q, Terms), rq_answer(Q, A) ), Answers).

%% the same, and beside each answer its explanation in sentences
reason_ask(Text, Answers, Explanations) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    rs_read(Sentences, [variables(true)], Terms),
    findall(A-E, ( member(Q, Terms), rq_answer(Q, A), rq_explain(Q, A, E) ), Pairs),
    rq_unzip(Pairs, Answers, Explanations).

rq_unzip([], [], []).
rq_unzip([A-E|Ps], [A|As], [E|Es]) :- rq_unzip(Ps, As, Es).

rq_explain(question(why(_)), because(T), T) :- !.
rq_explain(question(why(G)), _, T) :- !, re_unknown(G, T).
rq_explain(question(Goal), yes(_), T) :- !, ( reason_explanation(Goal, T0) -> T = T0 ; T = '' ).
rq_explain(question(_), no(denied(D)), T) :- !, ( reason_explanation(D, T0) -> T = T0 ; T = '' ).
rq_explain(question(Goal), no(closed), T) :- !,
    re_unknown(Goal, T0), atom_concat(T0, ' It is closed: what nothing shows is false.', T).
rq_explain(question(Goal), conflict, T) :- !,
    reason_explanation(Goal, T1), reason_explanation(neg(Goal), T2), atomic_list_concat([T1, ' And yet: ', T2], T).
rq_explain(question(Goal), _, T) :- !, re_unknown(Goal, T).
rq_explain(question(X, Goal), As, Es) :-
    findall(V-T, ( member(V-_, As), copy_term(X-Goal, V-G1), ( reason_explanation(G1, T0) -> T = T0 ; T = '' ) ), Es).

%% ---- prose, through the shipped tagger: optional ----------------------

reason_prose(Text, Terms) :- rp_model(M), tagger_normalise(M, Text, _, Terms).
reason_ask_prose(Text, Answers) :- rp_model(M), tagger_ask(M, Text, Answers).
reason_ask_prose(Text, Answers, Explanations) :- rp_model(M), tagger_ask(M, Text, Answers, Explanations).

%% LIBRARY(TORCH) IS ASKED FOR FIRST. The tagger LOADS where torch is
%% absent -- its vocabulary, encoding and tag ids are clauses -- so a load
%% of it that did not fail never meant torch was there, and the shipped
%% model then died at its first tensor with torch's own
%% existence_error(procedure, tensor_from_list/2), which no caller of the
%% header's promise catches: test/reason.pl and lesson 01 went red on every
%% box without torch where they meant to say "no shipped tagger here".
rp_model(M) :-
    (   catch(nb_getval('$rp_model', Cached), _, Cached = none), Cached \== none
    ->  M = Cached
    ;   catch(( use_module(library(torch)), use_module(library(reasoning/tagger)) ), _,
              throw(error(existence_error(tagger, pretrained),
                          context(reason_prose/2, 'library(torch) or library(reasoning/tagger) would not load: is library(torch) built?')))),
        tagger_pretrained(M0),
        nb_setval('$rp_model', M0),
        M = M0
    ).

%% `Why ...?': the whole proof, in sentences, or unknown
rq_answer(question(why(Goal)), A) :- !,
    ( reason_explanation(Goal, T) -> A = because(T) ; A = unknown ).
rq_answer(question(Goal), A) :- !, rq_yes_no(Goal, A).
rq_answer(question(X, Goal), As) :- !,
    findall(X-Why, ( rq_solve(Goal), rq_why(Goal, Why) ), As0),
    list_to_set(As0, As).

%% yes or no: truth/2's verdict over a goal that may carry an existential
%% (`a flat' is some flat), with the denial in the class form a negative
%% sentence gives -- neg(rent_in(priya, flat, bristol)) -- and the reason
rq_yes_no(Goal, A) :-
    rq_denial(Goal, Denial),
    ( rq_solve(Goal) -> Pos = yes ; Pos = no ),
    ( rq_solve(Denial) -> Neg = yes ; Neg = no ),
    (   Pos == yes, Neg == yes -> A = conflict
    ;   Pos == yes -> rq_why(Goal, Why), A = yes(Why)
    ;   Neg == yes -> A = no(denied(Denial))
    ;   rq_split(Goal, _, P), functor(P, F, Ar), reason_closed(F/Ar) -> A = no(closed)
    ;   A = unknown
    ).

rq_solve(Goal) :- catch(Goal, error(existence_error(procedure, _), _), fail).

rq_split((A, B), [A|As], P) :- !, rq_split(B, As, P).
rq_split(P, [], P).

rq_denial(Goal, neg(ClassP)) :-
    rq_split(Goal, [First|_], P), First =.. [N, V], var(V), !,
    copy_term(V-P, N-ClassP).
rq_denial(Goal, neg(Goal)).

rq_why(Goal, Why) :- rq_claim(Goal, P), ( reason_why(P, Why0) -> Why = Why0 ; Why = proved ).

%% the claim a goal makes: its last conjunct, or the one before a trailing
%% reason_amount/2 or reason_count/3, which a how-much or how-many
%% question puts after the claim
rq_claim(Goal, P) :-
    rq_split(Goal, Pre, Last),
    (   ( Last = reason_amount(_, _) ; Last = reason_count(_, _, _) ), append(_, [P0], Pre)
    ->  P = P0
    ;   P = Last
    ).

%% reason_why(+Goal, -Why): fact when the goal was said; rule(Head :- Body)
%% with the body as it proved when a rule gave it, one level; denied when
%% its negation was said. Fails when nothing holds it up.
reason_why(P, fact) :- catch(clause(P, true), _, fail), !.
reason_why(P, rule((P :- Body))) :-
    catch(clause(P, Body), _, fail), Body \== true, rq_solve(Body), !.
reason_why(P, denied) :- catch(clause(neg(P), true), _, fail), !.

%% reason_amount(+Object, -Quantity): what `how much' asks for. The object
%% IS a quantity -- quantity/2, quantity/3 or a bare number -- or it is a
%% class atom the text gave an amount: `Nadia pays the rent. The rent is
%% 500 euros.' answers quantity(500, euros) for the object `rent'. A
%% knowledge base with no amount/2 in it answers nothing, not an error.
reason_amount(Q, Q) :- nonvar(Q), ( number(Q) ; Q = quantity(_, _) ; Q = quantity(_, _, _) ), !.
reason_amount(O, Q) :- atom(O), catch(amount(O, Q), error(existence_error(procedure, _), _), fail).

%% reason_count(+Object, +Noun, -N): what `how many NOUN' asks for -- the
%% number in a quantity of that noun, with or without an `of' part
reason_count(quantity(N, U), U, N).
reason_count(quantity(N, U, _), U, N).

%% ---- explanation: the proof, every level of it, in sentences ---------------
%%
%% reason_why/2 answers ONE level, and a chess position wants the whole
%% proof: the king is checkmated because it is attacked, cannot move and
%% nothing rescues it; it cannot move because every square it may move to
%% is unsafe; and each square is unsafe for a reason of its own. So this is
%% a meta-interpreter that proves the goal as Prolog would -- the first
%% proof, clause order, the body left to right -- and keeps what it proved
%% by. A universal is the one shape that needs its own record: \+ (A, \+ B)
%% says every solution of A satisfies B, and the instances are the
%% explanation. reason_amount/2 and reason_count/3 in a how-much goal are
%% the library's own and explain as the amount fact they read, or as
%% nothing.

reason_explain(Goal, Why) :-
    ( var(Goal) -> throw(error(instantiation_error, reason_explain/2)) ; true ),
    re_goal(Goal, Why).

re_goal((A, B), conj(Ws)) :- !, re_conj((A, B), Ws).
re_goal(\+ G, W) :- !, re_not(G, W).
re_goal(G, holds(G)) :- re_helper(G), !, rq_solve(G).
re_goal(G, fact(G)) :- catch(clause(G, true), _, fail).
re_goal(G, rule(G, Ws)) :- catch(clause(G, Body), _, fail), Body \== true, re_conj(Body, Ws).
re_goal(G, holds(G)) :-
    \+ catch(clause(G, _), _, fail),
    catch(G, error(existence_error(procedure, _), _), fail).

re_conj((A, B), Ws) :- !, re_conj(A, W1), re_conj(B, W2), append(W1, W2, Ws).
re_conj((C -> T ; E), Ws) :- !, ( rq_solve(C) -> re_conj(C, W1), re_conj(T, W2), append(W1, W2, Ws) ; re_conj(E, Ws) ).
re_conj((A ; B), Ws) :- !, ( re_conj(A, Ws) ; re_conj(B, Ws) ).          % the branch that proved
re_conj(true, []) :- !.
re_conj(reason_amount(O, Q), Ws) :- !,
    reason_amount(O, Q),
    ( atom(O), Q \== O -> re_goal(amount(O, Q), W), Ws = [W] ; Ws = [] ).
re_conj(reason_count(O, U, N), []) :- !, reason_count(O, U, N).
re_conj(\+ G, [W]) :- !, re_not(G, W).
re_conj(G, [W]) :- re_goal(G, W).

%% \+ (A, \+ B): nothing satisfies A without B -- every instance of A, with
%% the why of B for it; otherwise \+ G holds because nothing proves G, and
%% denied when its negation was said as well
re_not(G, holds(\+ G)) :- re_helper(G), !, \+ rq_solve(G).                  % `"perro" does not end in "a"'
re_not((A, \+ B), forall(A, B, Insts)) :- !,
    \+ rq_solve((A, \+ B)),
    findall(A-W, ( rq_solve(A), once(re_goal(B, W)) ), Insts).
re_not(G, W) :-
    \+ rq_solve(G),
    ( rq_solve(neg(G)) -> W = denied(G) ; W = absent(G) ).

%% ---- the proof in sentences ------------------------------------------------

reason_explanation(Goal, Text) :-
    (   once(re_goal(Goal, W)) -> true
    ;   once(re_goal(neg(Goal), W))
    ),
    re_text(W, Text).

re_text(W, Text) :- re_top(W, Ss), atomic_list_concat(Ss, ' ', Text).

%% the sentences, depth first: a rule gives `Head because B1, B2 and B3.'
%% and then the sentences of every goal of its body that is a rule or a
%% universal itself; a fact at the top is `Fact, as said.'; an existence
%% fact of an individual, flat(flat_1), says nothing on its own
re_top(fact(G), Ss) :- ( re_existence(G) -> Ss = [] ; re_sentence(G, S), re_stop([S, ', as said'], T), Ss = [T] ).
re_top(holds(G), [T]) :- re_sentence(G, S), re_stop([S], T).
re_top(absent(G), [T]) :- re_open(G, S), re_stop(['nothing shows that ', S], T).
re_top(denied(G), [T]) :- re_sentence(neg(G), S), re_stop([S, ', as said'], T).
re_top(conj(Ws), Ss) :- re_children(Ws, top, Ss).
re_top(forall(A, B, Insts), [T|Ss]) :- re_phrase(forall(A, B, Insts), P), re_stop([P], T), re_children_of(Insts, Ss).
re_top(rule(G, Ws), [T|Ss]) :-
    re_sentence(G, S), re_phrases(Ws, Ps), re_join(Ps, Body),
    re_stop([S, ' because ', Body], T),
    re_children(Ws, body, Ss).

%% the goals of a body that have sentences of their own: a rule, a
%% universal's instances; at the top of a conjunction every part speaks
re_children([], _, []).
re_children([W|Ws], Where, Ss) :- re_child(W, Where, S1), re_children(Ws, Where, S2), append(S1, S2, Ss).
re_child(rule(G, Ws), _, Ss) :- !, re_top(rule(G, Ws), Ss).
re_child(forall(_, _, Insts), _, Ss) :- !, re_children_of(Insts, Ss).
re_child(W, top, Ss) :- !, re_top(W, Ss).
re_child(_, _, []).
re_children_of([], []).
re_children_of([_-W|Is], Ss) :- re_child(W, body, S1), re_children_of(Is, S2), append(S1, S2, Ss).

%% a body goal as a phrase of the `because' sentence
re_phrases([], []).
re_phrases([W|Ws], Ps) :- re_phrase(W, P), re_phrases(Ws, Ps1), ( P == '' -> Ps = Ps1 ; Ps = [P|Ps1] ).
re_phrase(fact(G), P) :- !, ( re_existence(G) -> P = '' ; re_sentence(G, P) ).
re_phrase(holds(G), P) :- !, re_sentence(G, P).
re_phrase(rule(G, _), P) :- !, re_sentence(G, P).
re_phrase(absent(G), P) :- !, re_open(G, S), atom_concat('nothing shows that ', S, P).
re_phrase(denied(G), P) :- !, re_sentence(neg(G), P).
re_phrase(conj(Ws), P) :- !, re_phrases(Ws, Ps), re_join(Ps, P).
re_phrase(forall(A, B, Insts), P) :-
    copy_term(A-B, A1-B1), term_variables(A1-B1, Vs), re_letters(Vs, 0),
    re_sentence(A1, SA), re_sentence(B1, SB), re_letter_list(Vs, Ls),
    (   Insts == []
    ->  atomic_list_concat(['there is no ', Ls, ' with ', SA], P)
    ;   term_variables(A, Vs0),
        findall(G, ( member(I-_, Insts), copy_term(A-Vs0, I1-Vals), I1 = I, re_args(Vals, G) ), Groups),
        re_join(Groups, GL),
        atomic_list_concat(['whenever ', SA, ', ', SB, ' (', Ls, ': ', GL, ')'], P)
    ).

re_letters([], _).
re_letters(['$re_var'(L)|Vs], N) :- nth0(N, ['X', 'Y', 'Z', 'U', 'V', 'W'], L), N1 is N + 1, re_letters(Vs, N1).
re_letter_list(Vs, Ls) :- findall(L, member('$re_var'(L), Vs), L0), re_join(L0, Ls).
re_args(Vals, G) :- findall(A, ( member(V, Vals), re_arg(V, A) ), As), re_join(As, G).

%% a goal nothing proves, with its existential read as `a flat'
re_unknown(Goal, T) :- re_open(Goal, S), re_stop(['nothing shows that ', S], T).
re_open(Goal, S) :-
    copy_term(Goal, G1), re_indefinites(G1), term_variables(G1, Vs), re_letters(Vs, 0),
    re_claims(G1, Ss), re_join(Ss, S).
re_indefinites((A, B)) :- !, re_indefinites(A), re_indefinites(B).
re_indefinites(G) :- ( compound(G), functor(G, N, 1), arg(1, G, V), var(V) -> V = '$re_indef'(N) ; true ).
re_claims((A, B), Ss) :- !, re_claims(A, S1), re_claims(B, S2), append(S1, S2, Ss).
re_claims(G, []) :- compound(G), functor(G, _, 1), arg(1, G, '$re_indef'(_)), !.
re_claims(G, [S]) :- re_sentence(G, S).

%% an individual's own noun: flat(flat_1)
re_existence(G) :-
    compound(G), functor(G, N, 1), arg(1, G, A), atom(A),
    atom_concat(N, '_', Pre), atom_concat(Pre, Rest, A), atom_number(Rest, _).

re_join([], '').
re_join([P], P) :- !.
re_join([P, Q], S) :- !, atomic_list_concat([P, ' and ', Q], S).
re_join([P|Ps], S) :- re_join(Ps, Rest), atomic_list_concat([P, ', ', Rest], S).

re_stop(Parts, T) :-
    atomic_list_concat(Parts, S0), atom_codes(S0, [C|Cs]),
    ( C >= 97, C =< 122 -> C1 is C - 32 ; C1 = C ),
    append([C1|Cs], [46], Codes), atom_codes(T, Codes).                        % 46 is `.'

%% ---- concepts and topics: what a text is about -------------------------------
%%
%% A concept is anything the claims mention -- a name, an individual, a
%% class, a property, a relation -- counted, so the most mentioned is what
%% the text is about. A topic is a SUBJECT with what is said of it grouped:
%% its classes, its properties, each relation with its objects, what it
%% denies, its amount; a class with its members and the rules over it; a
%% class or property with the rules that define it; and an object with what
%% is said of it from the other side (by(attack)-[re8] under h8). The
%% terms are what reason_text/2 gives, so a knowledge base dumped as terms
%% outlines the same way.

reason_concepts(Terms, Concepts) :-
    rc_mentions(Terms, Ms),
    rc_count(Ms, 0, [], Counted),
    findall(K-concept(N, Kind, C), ( member(c(N, Kind, C, F), Counted), NC is -C, K = NC-F ), Keyed),
    keysort(Keyed, Sorted),
    findall(X, member(_-X, Sorted), Concepts).

rc_mentions([], []).
rc_mentions([T|Ts], Ms) :- rc_term(T, M1), rc_mentions(Ts, M2), append(M1, M2, Ms).

rc_term(V, []) :- var(V), !.
rc_term((H :- B), Ms) :- !, rc_claim(H, M1), rc_body(B, M2), append(M1, M2, Ms).
rc_term(question(_), []) :- !.
rc_term(question(_, _), []) :- !.
rc_term(neg(C), Ms) :- !, rc_claim(C, Ms).
rc_term(amount(N, Q), Ms) :- !, rc_arg(N, M1), rc_arg(Q, M2), append(M1, M2, Ms).
rc_term(C, Ms) :- rc_claim(C, Ms).

rc_body((A, B), Ms) :- !, rc_body(A, M1), rc_body(B, M2), append(M1, M2, Ms).
rc_body(\+ G, Ms) :- !, rc_body(G, Ms).
rc_body(G, Ms) :- rc_claim(G, Ms).

rc_claim(C, [P-K|Ms]) :-
    compound(C), C =.. [P|Args], !,
    ( Args = [_] -> ( re_noun(P) -> K = class ; K = property ) ; K = relation ),
    rc_args(Args, Ms).
rc_claim(_, []).
rc_args([], []).
rc_args([A|As], Ms) :- rc_arg(A, M1), rc_args(As, M2), append(M1, M2, Ms).
rc_arg(A, [A-K]) :- atom(A), !, rc_atom_kind(A, K).
rc_arg(_, []).

rc_atom_kind(A, word) :- re_quoted(A), !.
rc_atom_kind(A, name) :- re_name(A), !.
rc_atom_kind(A, individual) :- re_individual(A), !.
rc_atom_kind(_, class).

%% count, keeping the order of first mention
rc_count([], _, Acc, Counted) :- reverse(Acc, Counted).
rc_count([N-K|Ms], I, Acc, Counted) :-
    I1 is I + 1,
    (   select(c(N, K, C, F), Acc, Rest) -> C1 is C + 1, rc_count(Ms, I1, [c(N, K, C1, F)|Rest], Counted)
    ;   rc_count(Ms, I1, [c(N, K, 1, I)|Acc], Counted)
    ).

%% an individual the naming gave: flat_1
re_individual(A) :-
    atom(A), atom_codes(A, Cs), append(Pre, [95|Digits], Cs), Pre \== [], Digits \== [],   % 95 is `_'
    catch(number_codes(_, Digits), _, fail).

%% ---- topics ------------------------------------------------------------------

reason_topics(Terms, Topics) :-
    rt_claims(Terms, Cs),
    rt_group(Cs, [], Grouped),
    findall(K-topic(S, Kind, Groups), ( member(t(S, Kind, F, Groups), Grouped), rt_weight(Groups, W), NW is -W, K = NW-F ), Keyed),
    keysort(Keyed, Sorted),
    findall(X, member(_-X, Sorted), Topics).

%% every claim as t(Subject, Group, Item), in order
rt_claims([], []).
rt_claims([T|Ts], Cs) :- rt_term(T, C1), rt_claims(Ts, C2), append(C1, C2, Cs).

rt_term(V, []) :- var(V), !.
rt_term(question(_), []) :- !.
rt_term(question(_, _), []) :- !.
rt_term((H :- Body), Cs) :- !,
    ( rt_guard(Body, G) -> Cs1 = [t(G, rules, (H :- Body))] ; Cs1 = [] ),
    ( compound(H), H =.. [P, _] -> Cs = [t(P, definition, (H :- Body))|Cs1] ; Cs = Cs1 ).
rt_term(neg(C), [t(S, denied, C)]) :- compound(C), arg(1, C, S), atom(S), !.
rt_term(amount(N, Q), [t(N, amount, Q)]) :- atom(N), !.
rt_term(C, Cs) :-
    compound(C), C =.. [P, S|Args], atom(S), !,
    (   Args == []
    ->  (   re_existence(C) -> Cs = [t(S, class, P)]                       % flat(flat_1): its own noun, no class of flats
        ;   re_noun(P) -> Cs = [t(S, class, P), t(P, members, S)]
        ;   Cs = [t(S, property, P)]
        )
    ;   Args = [O|_], ( atom(O) -> Cs = [t(S, relation(P), Args), t(O, by(P), C)] ; Cs = [t(S, relation(P), Args)] )
    ).
rt_term(_, []).

rt_guard(Body, G) :- ( Body = (First, _) -> true ; First = Body ), compound(First), First =.. [G, X], var(X).

%% the groups of each subject, and the items of each group, in order of
%% first mention, an item once
rt_group([], Acc, Grouped) :- reverse(Acc, Grouped).
rt_group([t(S, G, I)|Cs], Acc, Grouped) :-
    length(Acc, F),
    (   select(t(S, K, F0, Groups), Acc, Rest)
    ->  rt_add(Groups, G, I, Groups1), rt_group(Cs, [t(S, K, F0, Groups1)|Rest], Grouped)
    ;   rt_kind(S, G, K), rt_group(Cs, [t(S, K, F, [G-[I]])|Acc], Grouped)
    ).
rt_add([], G, I, [G-[I]]).
rt_add([G-Is|Gs], G, I, [G-Is1|Gs]) :- !, ( memberchk(I, Is) -> Is1 = Is ; append(Is, [I], Is1) ).
rt_add([X|Gs], G, I, [X|Gs1]) :- rt_add(Gs, G, I, Gs1).

rt_kind(S, G, K) :-
    (   ( G == members ; G == rules ; G == definition )
    ->  ( re_noun(S) -> K = class ; G == definition -> K = property ; K = class )
    ;   rc_atom_kind(S, K)
    ).

rt_weight(Groups, W) :- findall(N, ( member(_-Is, Groups), length(Is, N) ), Ns), sum_list(Ns, W).

%% ---- the outline as lines ------------------------------------------------------
%% `Kh8, a king: black; occupies H8; may move to G8, G7 and H7.' -- the
%% head is the subject with its classes (a class with its members), the
%% rest is one phrase a group, the explanation's renderer writing each
%% claim and the subject taken off the front.

reason_outline(Text, Lines) :- reason_text(Text, Terms), reason_topics(Terms, Topics), reason_topic_lines(Topics, Lines).
reason_outline_prose(Text, Lines) :- reason_prose(Text, Terms), reason_topics(Terms, Topics), reason_topic_lines(Topics, Lines).

reason_topic_lines([], []).
reason_topic_lines([topic(S, K, Groups)|Ts], [L|Ls]) :- rt_line(S, K, Groups, L), reason_topic_lines(Ts, Ls).

rt_line(S, K, Groups, Line) :-
    rt_head(S, K, Groups, Head, Rest),
    rt_phrases(S, Rest, Ps),
    (   Ps == [] -> atom_concat(Head, '.', L0)
    ;   atomic_list_concat(Ps, '; ', Body), atomic_list_concat([Head, ': ', Body, '.'], L0)
    ),
    re_cap(L0, Line).

%% the head: a name or an individual with its classes -- but not an
%% individual's own noun, `the flat, a flat' -- and a class with its members
rt_head(S, K, Groups, Head, Rest) :-
    ( K == name ; K == individual ; K == word ), !,
    re_arg(S, SA),
    (   select(class-Cs0, Groups, Rest0)
    ->  findall(C, ( member(C, Cs0), \+ ( K == individual, atom_concat(C, '_', Pre), atom_concat(Pre, _, S) ) ), Cs),
        (   Cs == [] -> Head = SA, Rest = Rest0
        ;   findall(A, ( member(C, Cs), re_predicate(C, is, A) ), As), re_join(As, AJ),
            atomic_list_concat([SA, ', ', AJ], Head), Rest = Rest0
        )
    ;   Head = SA, Rest = Groups
    ).
%% a class as a class -- members, rules, a definition -- heads its line
%% bare, `King (Kh8)'; a class atom something is said OF, `the rent' with
%% its amount, heads it as the reader wrote it
rt_head(S, _, Groups, Head, Rest) :-
    (   \+ ( member(G-_, Groups), \+ memberchk(G, [members, rules, definition]) )
    ->  (   select(members-Ms, Groups, Rest)
        ->  findall(A, ( member(M, Ms), re_arg(M, A) ), As), re_join(As, AJ), atomic_list_concat([S, ' (', AJ, ')'], Head)
        ;   Head = S, Rest = Groups
        )
    ;   re_arg(S, Head), Rest = Groups
    ).

rt_phrases(_, [], []).
rt_phrases(S, [G-Is|Gs], Ps) :- rt_phrase(S, G, Is, P1), rt_phrases(S, Gs, P2), append(P1, P2, Ps).

rt_phrase(_, class, Cs, [P]) :- findall(A, ( member(C, Cs), re_predicate(C, is, A) ), As), re_join(As, P).
rt_phrase(_, property, As, [P]) :- re_join(As, P).
rt_phrase(S, relation(R), Items, Ps) :-
    (   forall(member(I, Items), I = [_])                                  % binary: one verb phrase, the objects joined
    ->  Items = [[O1]|_], T1 =.. [R, S, O1], rt_after_subject(S, T1, Sent1),
        re_arg(O1, OA1), atom_concat(VP, OA1, Sent1),
        findall(OA, ( member([O], Items), re_arg(O, OA) ), OAs), re_join(OAs, OJ),
        atom_concat(VP, OJ, P), Ps = [P]
    ;   findall(P, ( member(I, Items), T =.. [R, S|I], rt_after_subject(S, T, P) ), Ps)
    ).
rt_phrase(S, denied, Cs, Ps) :- findall(P, ( member(C, Cs), re_negative(C, Sent), rt_strip(S, Sent, P) ), Ps).
rt_phrase(_, amount, Qs, [P]) :- findall(A, ( member(Q, Qs), re_arg(Q, A) ), As), re_join(As, P).
rt_phrase(_, members, Ms, [P]) :- findall(A, ( member(M, Ms), re_arg(M, A) ), As), re_join(As, P).
rt_phrase(_, rules, Rs, Ps) :- findall(P, ( member(R, Rs), rt_rule(R, P) ), Ps).
rt_phrase(_, definition, Rs, Ps) :- findall(P, ( member(R, Rs), rt_guard_phrase(R, P) ), Ps).
rt_phrase(_, by(_), Claims, Ps) :-                                        % the claim with its object as `it'
    findall(P, ( member(C, Claims), C =.. [R, S2, _|Rest], T =.. [R, S2, '$re_it'|Rest], re_sentence(T, P) ), Ps).

rt_after_subject(S, T, P) :- re_sentence(T, Sent), rt_strip(S, Sent, P).
rt_strip(S, Sent, P) :- re_arg(S, SA), atom_concat(SA, ' ', Pre), ( atom_concat(Pre, P0, Sent) -> P = P0 ; P = Sent ).

%% a rule as `every king that is attacked is a target', its guard as `a king
%% that is attacked'
rt_rule((H :- Body), P) :-
    copy_term((H :- Body), (H1 :- B1)),
    rt_goals(B1, [G1|Conds]), G1 =.. [C, X], X = '$re_indef'(C),
    rt_conds(Conds, CP), re_sentence(H1, Sent), rt_strip(X, Sent, Rest),
    atomic_list_concat(['every ', C, CP, ' ', Rest], P).
rt_guard_phrase((H :- Body), P) :-
    copy_term((H :- Body), (_ :- B1)),
    rt_goals(B1, [G1|Conds]), G1 =.. [C, X], X = '$re_indef'(C),
    rt_conds(Conds, CP), re_article(C, Art), atomic_list_concat([Art, ' ', C, CP], P).

rt_goals((A, B), [A|Gs]) :- !, rt_goals(B, Gs).
rt_goals(G, [G]).

rt_conds([], '').
rt_conds([\+ G|Gs], P) :- !, rt_cond(G, not, CP), rt_conds(Gs, P1), atomic_list_concat([' that ', CP, P1], P).
rt_conds([G|Gs], P) :- rt_cond(G, yes, CP), rt_conds(Gs, P1), atomic_list_concat([' that ', CP, P1], P).

%% `is [not] attacked', `is a noun'; a condition with an object as its
%% sentence with the subject taken off, `ends in "a"', `does not end in "a"'
rt_cond(G, Neg, CP) :-
    G =.. [A, _], !, re_predicate(A, is, AP),
    ( Neg == not -> atom_concat('is not ', AP, CP) ; atom_concat('is ', AP, CP) ).
rt_cond(G, Neg, CP) :-
    G =.. [_, S|_], ( Neg == not -> re_negative(G, Sent) ; re_sentence(G, Sent) ), rt_strip(S, Sent, CP).

%% ---- a term as a sentence ------------------------------------------------
%% A unary term is `X is [a] P' -- with the article when P is a class noun
%% the reader met, an adjective otherwise; a binary one `X VERB Y', the
%% verb in the third person unless a modal leads it (may_move_to: `may
%% move to'); a ternary one puts the last part of the name, the
%% preposition, before the third argument (rent_in: `rents ... in ...');
%% a comparison is said in words (`5 is more than 3'), and a body's
%% if-then-else or disjunction explains the branch that proved.
re_sentence(neg(G), S) :- !, re_negative(G, S).
re_sentence(\+ G, S) :- !, re_negative(G, S).
re_sentence(amount(N, Q), S) :- !, re_arg(N, NA), re_arg(Q, QA), atomic_list_concat([NA, ' is ', QA], S).
re_sentence(A > B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is more than ', Y], S).
re_sentence(A < B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is less than ', Y], S).
re_sentence(A >= B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is at least ', Y], S).
re_sentence(A =< B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is at most ', Y], S).
re_sentence(A =:= B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' equals ', Y], S).
re_sentence(A =\= B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is not ', Y], S).
re_sentence(A is B, S) :- !, re_arg(A, X), format(atom(Y), "~w", [B]), atomic_list_concat([X, ' is ', Y], S).
re_sentence(A \== B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is not ', Y], S).
re_sentence(A \= B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is not ', Y], S).
re_sentence(A == B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is ', Y], S).
re_sentence(A = B, S) :- !, re_arg(A, X), re_arg(B, Y), atomic_list_concat([X, ' is ', Y], S).
re_sentence(G, S) :- compound(G), G =.. [P, X], !, re_arg(X, XA), re_predicate(P, is, PA), atomic_list_concat([XA, ' is ', PA], S).
re_sentence(G, S) :- re_helper(G), G =.. [V, X, C], atom(C), rl_letter_class(C), !, re_arg(X, XA), re_verb(V, third, VP), atomic_list_concat([XA, ' ', VP, ' a ', C], S).
re_sentence(G, S) :- compound(G), G =.. [V, X, Y], re_of_noun(V, N), !, re_arg(X, XA), re_arg(Y, YA), atomic_list_concat([XA, ' is the ', N, ' of ', YA], S).
re_sentence(G, S) :- compound(G), G =.. [V, X, Y], !, re_arg(X, XA), re_arg(Y, YA), re_verb(V, third, VP), atomic_list_concat([XA, ' ', VP, ' ', YA], S).
re_sentence(G, S) :-
    compound(G), G =.. [V, X, Y, Z], atomic_list_concat(Parts, '_', V), append(Front, [Prep], Parts), Front \== [], !,
    atomic_list_concat(Front, '_', V2), re_verb(V2, third, VP),
    re_arg(X, XA), re_arg(Y, YA), re_arg(Z, ZA), atomic_list_concat([XA, ' ', VP, ' ', YA, ' ', Prep, ' ', ZA], S).
re_sentence(G, S) :- format(atom(S), "~w", [G]).

re_negative(amount(N, Q), S) :- !, re_arg(N, NA), re_arg(Q, QA), atomic_list_concat([NA, ' is not ', QA], S).
re_negative(G, S) :- compound(G), G =.. [P, X], !, re_arg(X, XA), re_predicate(P, is, PA), atomic_list_concat([XA, ' is not ', PA], S).
re_negative(G, S) :- re_helper(G), G =.. [V, X, C], atom(C), rl_letter_class(C), !, re_arg(X, XA), re_verb(V, not, VP), atomic_list_concat([XA, ' ', VP, ' a ', C], S).
re_negative(G, S) :- compound(G), G =.. [V, X, Y], re_of_noun(V, N), !, re_arg(X, XA), re_arg(Y, YA), atomic_list_concat([XA, ' is not the ', N, ' of ', YA], S).
re_negative(G, S) :- compound(G), G =.. [V, X, Y], !, re_arg(X, XA), re_arg(Y, YA), re_verb(V, not, VP), atomic_list_concat([XA, ' ', VP, ' ', YA], S).
re_negative(G, S) :-
    compound(G), G =.. [V, X, Y, Z], atomic_list_concat(Parts, '_', V), append(Front, [Prep], Parts), Front \== [], !,
    atomic_list_concat(Front, '_', V2), re_verb(V2, not, VP),
    re_arg(X, XA), re_arg(Y, YA), re_arg(Z, ZA), atomic_list_concat([XA, ' ', VP, ' ', YA, ' ', Prep, ' ', ZA], S).
re_negative(G, S) :- format(atom(S), "not ~w", [G]).

%% mother_of, plural_of: a relation a noun the reader met names
re_of_noun(V, N) :- atom(V), atom_concat(N, '_of', V), N \== '', re_noun(N).

%% `a king' for a class noun the reader met, `attacked' for anything else
re_predicate(P, is, PA) :-
    (   re_noun(P) -> re_article(P, Art), atomic_list_concat([Art, ' ', P], PA)
    ;   PA = P
    ).

%% the verb phrase: may_move_to -> `may move to' (a modal leads, base forms);
%% live_in -> `lives in' / `does not live in'
re_verb(V, Form, VP) :-
    atomic_list_concat([First|Rest], '_', V),
    (   rl_modal(First)
    ->  ( Form == not -> Words = [First, not|Rest] ; Words = [First|Rest] )
    ;   Form == not
    ->  Words = [does, not, First|Rest]
    ;   reason_third(First, Third), Words = [Third|Rest]
    ),
    atomic_list_concat(Words, ' ', VP).

%% an argument: a word the reader met in quotation marks, in them; a
%% proper noun it met capitalised; an individual car_1 as `the car'; a
%% number as itself, a quantity as `500 euros', a variable as its letter,
%% `a flat' for an existential, any other atom as `the ...'
re_arg('$re_var'(L), L) :- !.
re_arg('$re_indef'(N), A) :- !, re_article(N, Art), atomic_list_concat([Art, ' ', N], A).
re_arg('$re_it', it) :- !.
re_arg(V, 'something') :- var(V), !.
re_arg(N, A) :- number(N), !, format(atom(A), "~w", [N]).
re_arg(quantity(N, U), A) :- !, re_arg(N, NA), atomic_list_concat([NA, ' ', U], A).
re_arg(quantity(N, U, Of), A) :- !, re_arg(N, NA), atomic_list_concat([NA, ' ', U, ' of ', Of], A).
re_arg(X, A) :- atom(X), re_quoted(X), !, atomic_list_concat(['"', X, '"'], A).
re_arg(X, A) :- atom(X), re_name(X), !, re_cap(X, A).
re_arg(X, A) :- atom(X), atom_codes(X, Cs), append(Pre, [95|Digits], Cs), Digits \== [], catch(number_codes(_, Digits), _, fail), !,   % 95 is `_'
    atom_codes(N, Pre), atom_concat('the ', N, A).
re_arg(X, A) :- atom(X), !, atom_concat('the ', X, A).
re_arg(X, A) :- format(atom(A), "~w", [X]).

re_article(W, an) :- atom_codes(W, [C|_]), memberchk(C, [0'a, 0'e, 0'i, 0'o, 0'u]), !.
re_article(_, a).

re_cap(W, C) :- atom_codes(W, [F|R]), ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ), atom_codes(C, [F1|R]).

%% what the reader met: the proper nouns, the class nouns after `a', `the'
%% or `every', and the words in quotation marks -- globals of this machine,
%% never asserted, so the explanation can write `Kh8', `a king' and
%% `"casa"' where the terms hold kh8, king(kh8) and casa. A note is PENDING
%% until its sentence parses and is dropped when it does not: `the big
%% barn' in a refused sentence once made `big' a noun for the rest of the
%% process, and an explanation said `the box is a big'.
%% A WORD'S NOTE IS A GLOBAL OF ITS OWN (1.9.4), `'$rs_quoted|casa'' and the
%% like, found by name through the store's hash: one list a kind grew with
%% every word the process met, and a global is copied whole each time it is
%% read -- the translator's lesson copied 135 million cells of
%% `'$rs_quoted'' to ask 18 thousand times whether a word was in it, and put
%% the grown list back into the store for every word it added. A note that
%% is not an atom keeps the list under the bare name, as before.
re_name(X) :- rs_noted('$rs_names', '$rs_names|', X).
re_noun(P) :- rs_noted('$rs_nouns', '$rs_nouns|', P).
re_quoted(W) :- rs_noted('$rs_quoted', '$rs_quoted|', W).
rs_noted(Key, Prefix, X) :-
    (   atom(X)
    ->  atom_concat(Prefix, X, K), catch(nb_getval(K, _), _, fail)
    ;   catch(nb_getval(Key, L), _, fail), memberchk(X, L)
    ).
rs_note_prefix('$rs_names', '$rs_names|').
rs_note_prefix('$rs_nouns', '$rs_nouns|').
rs_note_prefix('$rs_quoted', '$rs_quoted|').
rs_note(Key, X) :-
    catch(nb_getval('$rs_pending', L), _, L = []),
    nb_setval('$rs_pending', [Key-X|L]).
rs_notes_reset :- nb_setval('$rs_pending', []).
%% noted in THIS sentence so far: the quoted words, to keep a place off a mention
rs_pending(Key, X) :- catch(nb_getval('$rs_pending', L), _, L = []), memberchk(Key-X, L).
rs_notes_commit :-
    catch(nb_getval('$rs_pending', L), _, L = []),
    reverse(L, Notes),
    forall(member(Key-X, Notes), rs_register(Key, X)),
    nb_setval('$rs_pending', []).
rs_register(Key, X) :-
    (   atom(X), rs_note_prefix(Key, Prefix)
    ->  atom_concat(Prefix, X, K), nb_setval(K, yes)
    ;   catch(nb_getval(Key, L), _, L = []),
        ( memberchk(X, L) -> true ; nb_setval(Key, [X|L]) )
    ).

%% the sentences in order, and the STATE between them: the subject of the
%% last fact, which a subject pronoun in the next sentence stands for
rs_each([], []).
rs_each([S|Ss], Terms) :-
    rs_notes_reset,
    once(phrase(rs_sentence(T, State), S)),
    rs_notes_commit,
    rs_remember(State),
    append(T, Rest, Terms),
    rs_each(Ss, Rest).

rs_remember(subject(S)) :- !, nb_setval('$rs_subject', S).
rs_remember(_).

reason_sentence(Text, Terms) :- reason_sentence(Text, [], Terms).

reason_sentence(Text, Options, Terms) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, [S|_]),
    nb_setval('$rs_subject', none),
    rs_notes_reset,
    phrase(rs_sentence(Raw, _), S),
    rs_notes_commit,
    rs_declare(Raw),
    (   memberchk(variables(true), Options)
    ->  Terms = Raw
    ;   reason_name(Raw, Terms)
    ).

%% A RULE DECLARES WHAT ITS BODY NAMES. `\+ exempt(X)' THROWS an
%% existence_error when no exempt/1 was ever asserted -- and so does a
%% plain tenant(X) -- so a rule handed back from `every tenant that is not
%% exempt ...' would throw for every caller in a knowledge base that
%% mentions no exemption, which is the ordinary case. dynamic/1 as a goal
%% is the cure (measured: after it, \+ over the empty predicate fails, as
%% it should), and it is done HERE, at the boundary, once per call, over
%% the finished terms -- never inside the grammar, so reason_refused/2's
%% checks declare nothing. A predicate that already exists is unchanged;
%% one that cannot be declared (a builtin's name) is left as it was.
rs_declare([]).
rs_declare([T|Ts]) :-
    ( nonvar(T), T = (_ :- Body) -> rs_declare_body(Body) ; true ),
    rs_declare(Ts).

rs_declare_body((A, B)) :- !, rs_declare_body(A), rs_declare_body(B).
rs_declare_body(\+ G)   :- !, rs_declare_body(G).
rs_declare_body(G) :-
    callable(G), functor(G, N, A),
    catch(dynamic(N/A), _, true).

%% Split the token stream at `.', dropping empty sentences. THE CUT IS
%% LOAD-BEARING: without it rs_sentences([], _) has two applicable clauses
%% and the second recurses on [] again, so anything that backtracks into
%% this -- a findall over reason_sentence/2, or every refused sentence --
%% never returns. Found by the suite case hanging at its first refusal.
rs_sentences([], []) :- !.
rs_sentences(Tokens, Sentences) :-
    rs_upto(Tokens, S, Rest),
    (   S == [] -> Sentences = More ; Sentences = [S|More] ),
    rs_sentences(Rest, More).

rs_upto([], [], []).
rs_upto(['.'|Rest], [], Rest) :- !.
rs_upto([T|Ts], [T|S], Rest) :- rs_upto(Ts, S, Rest).

%% ---- what was refused -------------------------------------------------

reason_refused(Text, Sentence) :-
    reason_tokens(Text, Tokens),
    rs_sentences(Tokens, Sentences),
    nb_setval('$rs_subject', none),
    rr_refused(Sentences, S),
    rs_words(S, Sentence).

%% the sentences in order with the state carried exactly as reason_text/2
%% carries it, so a pronoun after its antecedent is not reported refused;
%% each refused sentence in turn on backtracking
rr_refused([S|Ss], R) :-
    rs_notes_reset,
    (   phrase(rs_sentence(_, State), S)
    ->  rs_notes_commit, rs_remember(State), rr_refused(Ss, R)
    ;   ( R = S ; rr_refused(Ss, R) )
    ).

rs_words(Tokens, Atom) :-
    findall(W, ( member(T, Tokens), rs_token_text(T, W) ), Ws),
    atomic_list_concat(Ws, ' ', Atom).

rs_token_text(word(W, _), W).
rs_token_text(num(N), A) :- format(atom(A), "~w", [N]).
rs_token_text(quoted(W), A) :- atomic_list_concat(['"', W, '"'], A).

%% ---- truth -------------------------------------------------------------
%%
%% Two questions, and the pair read as one of four answers. A predicate
%% that does not exist is caught here and counts as not proving: silence
%% is `unknown', never an error. Any other ball is the program's and
%% travels.

truth(Goal, Truth) :-
    (   ground(Goal) -> true
    ;   throw(error(instantiation_error, truth/2))
    ),
    ( rt_proves(Goal)      -> Pos = yes ; Pos = no ),
    ( rt_proves(neg(Goal)) -> Neg = yes ; Neg = no ),
    rt_verdict(Pos, Neg, Goal, Truth).

rt_verdict(yes, yes, _, conflict) :- !.
rt_verdict(yes, no,  _, true)     :- !.
rt_verdict(no,  yes, _, false)    :- !.
rt_verdict(no,  no,  Goal, Truth) :-
    functor(Goal, N, A),
    ( reason_closed(N/A) -> Truth = false ; Truth = unknown ).

rt_proves(Goal) :-
    catch(Goal, error(existence_error(procedure, _), _), fail), !.

%% ---- tokens ----------------------------------------------------------

reason_tokens(Text, Tokens) :-
    rt_codes(Text, Codes),
    rt_tokens(Codes, Tokens).

rt_codes(T, Cs) :- is_list(T), !, Cs = T.
rt_codes(T, Cs) :- atom(T), !, atom_codes(T, Cs).
rt_codes(T, Cs) :- string(T), !, string_codes(T, Cs).
rt_codes(T, _)  :- throw(error(type_error(text, T), reason_tokens/2)).

rt_tokens([], []).
rt_tokens([C|Cs], ['.'|Ts]) :- rt_stop(C), !, rt_tokens(Cs, Ts).
rt_tokens([44|Cs], [','|Ts]) :- !, rt_tokens(Cs, Ts).          % 44 is `,'
%% a word between quotation marks is MENTIONED, not used: quoted(Word), the
%% text between them as written (its letters lower-cased), whatever it is
%% -- `"a"' is the letter and not the article, `"is"' a word and not the
%% copula. The plain `"' and the typographic pair (UTF-8 E2 80 9C and 9D)
%% both open and close one; an unclosed one runs to the end of the text.
rt_tokens(Cs, [quoted(W)|Ts]) :-
    rt_quote_open(Cs, Cs1), !,
    rt_quoted(Cs1, Word, Rest),
    rt_lowers(Word, Ls), atom_codes(W, Ls),
    rt_tokens(Rest, Ts).
%% a number: digits, a comma between digits passed over (1,000), a point
%% between digits kept (5.5), and `%' right after it the word `percent'
%% a sign past 127 is not a letter: `¿' and `¡' (U+00BF, U+00A1, with the
%% rest of U+0080..U+00BF) and the general punctuation (U+2000..U+207F:
%% dashes, the ellipsis) are dropped like any other punctuation, so
%% `¿Qué' is the word `qué'
rt_tokens([194, _|Cs], Ts) :- !, rt_tokens(Cs, Ts).
rt_tokens([226, B, _|Cs], Ts) :- ( B == 128 ; B == 129 ), !, rt_tokens(Cs, Ts).
rt_tokens([C|Cs], Ts) :- C >= 128, rt_sign(C), !, rt_tokens(Cs, Ts).                     % the same signs, as code points
rt_tokens([C|Cs], [num(N)|Ts]) :-
    rt_digit(C), !,
    rt_digits(Cs, More, Rest0),
    (   Rest0 = [46, D|Rest1], rt_digit(D)                      % 46 is `.'
    ->  rt_digits([D|Rest1], Frac, Rest2), append([C|More], [46|Frac], NCs)
    ;   NCs = [C|More], Rest2 = Rest0
    ),
    atom_codes(NA, NCs), atom_number(NA, N),
    (   Rest2 = [37|Rest] -> Ts = [word(percent, lower)|Ts1]    % 37 is `%'
    ;   Rest = Rest2, Ts = Ts1
    ),
    rt_tokens(Rest, Ts1).
rt_tokens([C|Cs], [word(W, Case)|Ts]) :-
    rt_alpha(C), !,
    rt_run(Cs, More, Rest),
    rt_word_case([C|More], Case),
    rt_lowers([C|More], Ls),
    atom_codes(W, Ls),
    rt_tokens(Rest, Ts).
rt_tokens([_|Cs], Ts) :- rt_tokens(Cs, Ts).

%% a word is capitalised by its first letter: an ASCII capital, or one of
%% U+00C0..U+00DE -- the bytes 195 and 128..158 in UTF-8, the
%% multiplication sign left out -- so `Él' is the word `él' capitalised
rt_word_case([C|_], upper) :- rt_upper(C), !.
rt_word_case([195, B|_], upper) :- rt_upper2(B), !.
rt_word_case([C|_], upper) :- rt_upper_cp(C), rt_chars, !.
rt_word_case(_, lower).

rt_stop(46). rt_stop(33). rt_stop(63).                          % . ! ?

rt_quote_open([34|Cs], Cs).                                      % "
rt_quote_open([226, 128, 156|Cs], Cs).                           % the typographic open quote
rt_quote_open([8220|Cs], Cs).                                    % ... as a code point
rt_quote_close([34|Cs], Cs).
rt_quote_close([226, 128, 157|Cs], Cs).
rt_quote_close([8221|Cs], Cs).
rt_quoted(Cs, [], Rest) :- rt_quote_close(Cs, Rest), !.
rt_quoted([], [], []).
rt_quoted([C|Cs], [C|Ws], Rest) :- rt_quoted(Cs, Ws, Rest).

%% AN APOSTROPHE BETWEEN LETTERS ENDS THE WORD AND STAYS WITH IT.
%% `l'incolumita' is the elided article and the noun -- two words -- and it
%% was read as `l' and the noun, because an apostrophe is no letter and the
%% run simply stopped there. The `l' left behind is a word no lesson can
%% give a meaning, so every sentence carrying an elision was refused for a
%% word that is not missing: measured over Italian newspaper prose, `l' and
%% `dell' were two of the six words that refused four sentences in twelve.
%% The typographic apostrophe (U+2019) is written as the plain one, so a
%% lesson spells the form once.
rt_run([39|Cs], [39], Cs) :- rt_letter_next(Cs), !.
rt_run([226, 128, 153|Cs], [39], Cs) :- rt_letter_next(Cs), !.
rt_run([8217|Cs], [39], Cs) :- rt_letter_next(Cs), !.                       % U+2019 as a code point
rt_run([194, B|Cs], [], [194, B|Cs]) :- !.                              % a sign ends the word
rt_run([226, B, C|Cs], [], [226, B, C|Cs]) :- ( B == 128 ; B == 129 ), !.
rt_run([C|Cs], [], [C|Cs]) :- C >= 128, rt_sign(C), !.                           % a sign as a code point ends the word
rt_run([C|Cs], [C|More], Rest) :- ( rt_alpha(C) ; rt_digit(C) ; C == 95 ), !, rt_run(Cs, More, Rest).
rt_run(Cs, [], Cs).

%% a letter follows, and not the first byte of a sign this reader drops:
%% rt_alpha answers YES for any byte past 127, so an em dash after an
%% apostrophe would otherwise read as a letter
rt_letter_next([194, _|_]) :- !, fail.
rt_letter_next([226, B, _|_]) :- ( B == 128 ; B == 129 ), !, fail.
rt_letter_next([C|_]) :- C >= 128, rt_sign(C), !, fail.
rt_letter_next([C|_]) :- rt_alpha(C).

rt_digits([C|Cs], [C|More], Rest) :- rt_digit(C), !, rt_digits(Cs, More, Rest).
rt_digits([44, C|Cs], More, Rest) :- rt_digit(C), !, rt_digits([C|Cs], More, Rest).   % 1,000: the comma is a separator
rt_digits(Cs, [], Cs).

rt_alpha(C) :- C >= 97, C =< 122, !.
rt_alpha(C) :- C >= 65, C =< 90, !.
rt_alpha(C) :- C >= 128.                                         % a byte of a UTF-8 letter: `pequeño' is one word
rt_upper(C) :- C >= 65, C =< 90.
rt_digit(C) :- C >= 48, C =< 57.
rt_upper2(B) :- B >= 128, B =< 158, B =\= 151.
%% THE TEXT UNIT. By default a code list holds the UTF-8 BYTES of a text:
%% `é' is 195 169, `¿' is 194 191, an en dash 226 128 147. A program that
%% sets the flag text_units to characters holds CODE POINTS: 233, 191,
%% 8211. Each clause above and in library(reasoning/translate) that names
%% bytes has a twin that names code points. A twin on a code past 255
%% needs no test (no byte is so big). A twin on a code of 128..255 asks
%% rt_chars/0, and only after its numbers matched, because there the
%% two readings meet: 195 is the lead byte of `é' and the code point of
%% `Ã', and 226, the lead byte of a dash and of a quotation mark, is the
%% code point of `â'.
rt_chars :- current_prolog_flag(text_units, characters).
%% a sign the tokeniser drops, as a code point: U+0080..U+00BF (`¿', `¡',
%% the angled marks, the ordinal signs) and U+2000..U+207F (dashes,
%% quotation marks, the ellipsis), the signs the byte clauses 194 and 226 drop
rt_sign(C) :- C >= 8192, C =< 8319.
rt_sign(C) :- C =< 191, rt_chars.
%% a capital of U+00C0..U+00DE as a code point (the multiplication sign is no letter)
rt_upper_cp(C) :- C >= 192, C =< 222, C =\= 215.
rt_lower(C, L) :- ( rt_upper(C) -> L is C + 32 ; L = C ).
rt_lowers([], []).
rt_lowers([195, B|Cs], [195, L|Ls]) :- rt_upper2(B), !, L is B + 32, rt_lowers(Cs, Ls).
rt_lowers([C|Cs], [L|Ls]) :- rt_upper_cp(C), rt_chars, !, L is C + 32, rt_lowers(Cs, Ls).
rt_lowers([C|Cs], [L|Ls]) :- rt_lower(C, L), rt_lowers(Cs, Ls).

%% ---- the grammar -----------------------------------------------------
%%
%% Every nonterminal carries the TERMS its phrase contributes. A subject
%% is either a constant (a proper noun) or a variable with a guard -- the
%% class goals a rule's body will need -- and `Ctx' says which: `fact'
%% for a proper subject, `rule' under a quantifier. An object read under
%% `rule' or under negation is a class atom; under `fact' an indefinite
%% object is a fresh variable with its noun and adjectives as terms.

rs_sentence(Terms) --> rs_sentence(Terms, _).
rs_sentence([Q], none) --> rs_question(Q), !.
rs_sentence([Claim], none) --> rs_amount(Claim), !.
rs_sentence(Terms, State) -->
    rs_subject(S, Guard, Ctx),
    rs_predication(S, Ctx, Claim, Extra),
    { rs_assemble(Ctx, Guard, Claim, Extra, Terms),
      ( Ctx == fact -> State = subject(S) ; State = none ) }.

%% ---- questions ---------------------------------------------------------
%% `?' is a stop like `.', so a question is known by its first word. It
%% reads to the GOAL the statement would have asserted, with a variable
%% where `who', `what' or `where' stood:
%%
%%   Does Priya sell the bread?        question(sell(priya, bread))
%%   Does Priya rent a flat in Rome?   question((flat(V), rent_in(priya, V, rome)))
%%   Is Priya licensed?  Is Priya a baker?   question(licensed(priya)), question(baker(priya))
%%   May Priya sell the bread?         question(may_sell(priya, bread))
%%   Who rents a flat in Rome?         question(X, (flat(V), rent_in(X, V, rome)))
%%   Who is licensed?  Who is a baker?  question(X, licensed(X)), question(X, baker(X))
%%   What does Priya sell?             question(X, sell(priya, X))
%%   What does Priya keep in Leeds?    question(X, keep_in(priya, X, leeds))   -- or `keep_in Leeds', joined
%%   Where does Priya sleep?           question(X, sleep_in(priya, X))     -- `in' assumed
%%   Does Priya pay 500 euros?         question(pay(priya, quantity(500, euros)))
%%   Is the rent 500 euros?            question(amount(rent, quantity(500, euros)))
%%   How much does Priya pay?          question(Q, (pay(priya, O), reason_amount(O, Q)))
%%   How much must Priya pay?          question(Q, (must_pay(priya, O), reason_amount(O, Q)))
%%   How much does Priya pay to Omar?  question(Q, (pay_to(priya, O, omar), reason_amount(O, Q)))   -- or `pay_to Omar'
%%   How many vineyards does Priya own?  question(N, (own(priya, O), reason_count(O, vineyards, N)))
%%   How much is the rent?             question(Q, amount(rent, Q))
%%   Why is Priya licensed?            question(why(licensed(priya)))   -- `why' before any yes-or-no form
%%
%% The subject may be a pronoun, resolved as a statement's is. `How much'
%% asks for the object THROUGH reason_amount/2, so that `Priya pays the
%% rent' beside `The rent is 500 euros' answers the 500 euros and not the
%% word `rent'; `how many' asks, through reason_count/3, for the number
%% in a quantity of the noun it names -- quantity(2, litres) and
%% quantity(2, litres, milk) both answer 2 litres.

rs_question(question(why(Goal))) --> [word(why, _)], !, rs_question(question(Goal)).
rs_question(question(Goal)) -->
    rs_aux, rs_qsubject(S), rs_verb(V), rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), rs_goal(Extra, P, Goal) }.
rs_question(question(Goal)) -->
    rs_copula, rs_qsubject(S), rs_property(S, Goal).
rs_question(question(Goal)) -->
    [word(M, _)], { rl_modal(M) }, rs_qsubject(S), rs_verb_word(W), { atomic_list_concat([M, '_', W], V) },
    rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), rs_goal(Extra, P, Goal) }.
rs_question(question(X, Goal)) -->
    [word(who, _)], rs_copula, !, rs_property(X, Goal).
rs_question(question(X, Goal)) -->
    [word(who, _)], rs_modal_verb(V), rs_object_opt(fact, O, Extra), rs_place_opt(O, Pl),
    { rs_claim(V, X, O, Pl, P), rs_goal(Extra, P, Goal) }.
%% `What is the plural of "el"?': the relation the noun names, with the
%% variable where what is asked stood
rs_question(question(X, Goal)) -->
    [word(what, _)], rs_copula, rs_det(def), rs_adjs(As), rs_noun(N), [word(of, _)], rs_of_object(O),
    { rs_note('$rs_nouns', N), atom_concat(N, '_of', NO), G =.. [NO, X, O], rs_adj_terms(As, X, Extra), rs_conj([G|Extra], Goal) }.
rs_question(question(X, Goal)) -->
    [word(Wh, _)], { Wh == what ; Wh == whom }, rs_aux, rs_qsubject(S), rs_verb_place(V, X, Pl),
    { rs_claim(V, S, X, Pl, Goal) }.
rs_question(question(X, Goal)) -->
    [word(where, _)], rs_aux, rs_qsubject(S), rs_verb(V), rs_object_opt(fact, O, Extra),
    { rs_claim(V, S, O, in-X, P), rs_goal(Extra, P, Goal) }.
rs_question(question(Q, (P, reason_amount(O, Q)))) -->
    [word(how, _)], [word(much, _)], rs_aux, rs_qsubject(S), rs_verb_place(V, O, Pl),
    { rs_claim(V, S, O, Pl, P) }.
rs_question(question(Q, (P, reason_amount(O, Q)))) -->
    [word(how, _)], [word(much, _)], [word(M, _)], { rl_modal(M) }, rs_qsubject(S), rs_verb_word_place(W, O, Pl),
    { atomic_list_concat([M, '_', W], V), rs_claim(V, S, O, Pl, P) }.
rs_question(question(Q, amount(N, Q))) -->
    [word(how, _)], [word(much, _)], rs_copula, rs_det(def), rs_noun(N).
rs_question(question(N, (P, reason_count(O, U, N)))) -->
    [word(how, _)], [word(many, _)], rs_noun(U), rs_aux, rs_qsubject(S), rs_verb_place(V, O, Pl),
    { rs_claim(V, S, O, Pl, P) }.
rs_question(question(amount(N, Q))) -->
    rs_copula, rs_det(def), rs_noun(N), rs_quantity(Q).

%% the verb and a place after it: `keep in Leeds' as it is written, or
%% `keep_in Leeds' as the assembler writes it, taken apart again
rs_verb_place(V, O, Pl) --> rs_verb_word_place(W, O, Pl), { rs_base(W, V) }.
rs_verb_word_place(W, O, Pl) -->
    rs_verb_word(W0),
    (   rs_proper(Place), { rs_unjoin(W0, W, Prep) } -> { Pl = Prep-Place }
    ;   { W = W0 }, rs_place_opt(O, Pl)
    ).

%% keep_in -> keep, in: a relation the assembler joined, taken apart when
%% the object it asks for stood in front
rs_unjoin(V0, V, Prep) :-
    atomic_list_concat(Parts, '_', V0), append(Front, [Prep], Parts), Front \== [], rl_preposition(Prep), !,
    atomic_list_concat(Front, '_', V).

%% `The rent is [not] 500 euros': the one sentence with a definite subject,
%% and the amount a definite object has -- what `how much' reads back
rs_amount(Claim) -->
    rs_det(def), rs_noun(N), rs_copula,
    (   [word(not, _)] -> { Claim = neg(amount(N, Q)) } ; { Claim = amount(N, Q) } ),
    rs_quantity(Q).

rs_qsubject(S) --> rs_subject(S, _, fact).

rs_goal([], P, P).
rs_goal([E|Es], P, (E, G)) :- rs_goal(Es, P, G).

%% a proper noun, a quoted word, `the [ADJ..] CLASS "word"', `every NOUN
%% [that ...]', or a subject pronoun. A word in quotation marks stands for
%% itself, and with a class noun before it -- `the noun "casa"', `the
%% feminine article "la"' -- the class and the adjectives are facts about
%% the word besides, handed back before the claim: noun(casa); article(la),
%% feminine(la)
rs_subject(S, [], fact) --> rs_proper(S).
rs_subject(W, [], fact) --> rs_quoted(W).
rs_subject(W, [Class|Adjs], fact) -->
    rs_det(def), rs_adjs(As), rs_noun(C), rs_quoted(W),
    { rs_note('$rs_nouns', C), Class =.. [C, W], rs_adj_terms(As, W, Adjs) }.
rs_subject(X, Guard, rule) -->
    [word(Q, _)], { rl_quant(Q) },
    rs_noun(N), { rs_note('$rs_nouns', N), G1 =.. [N, X] },
    rs_relative(X, Rel),
    { Guard = [G1|Rel] }.
%% `she', `he' or `they': the subject of the last FACT read, carried from
%% sentence to sentence by reason_text/2 and reason_refused/2 -- the one
%% coreference this reader does. With no fact before it the sentence is
%% refused, and reason_sentence/2 reads one sentence with no state at all.
rs_subject(S, [], fact) -->
    [word(P, _)], { rl_subject_pronoun(P), catch(nb_getval('$rs_subject', S0), _, S0 = none), S0 \== none, S = S0 }.

%% one condition: `that is [not] ADJ', `that is [not] a NOUN', or `that
%% [does not] VERB [OBJECT] [in PLACE]' -- the object read as a rule's is,
%% a class atom, and `ends in "a"' the joined relation end_in(X, a)
rs_relative(X, Rel) -->
    [word(that, _)], rs_copula, !,
    (   [word(not, _)] -> { Neg = yes } ; { Neg = no } ),
    rs_property(X, G), { rs_negate(Neg, G, Rel) }.
rs_relative(X, Rel) -->
    [word(that, _)], !,
    (   rs_aux, [word(not, _)] -> { Neg = yes }, rs_verb(V) ; { Neg = no }, rs_modal_verb(V) ),
    rs_object_opt(rule, O, _), rs_place_opt(O, Pl),
    { rs_claim(V, X, O, Pl, G), rs_negate(Neg, G, Rel) }.
rs_relative(_, []) --> [].

rs_negate(yes, G, [\+ G]).
rs_negate(no, G, [G]).

%% what is said of the subject: Claim is the head term, Extra the object's
%% existence terms (only ever non-empty for an indefinite object in a fact)
rs_predication(S, _, Claim, []) -->
    rs_copula, [word(not, _)], !, rs_property(S, P), { Claim = neg(P) }.
rs_predication(S, _, Claim, Extra) -->
    rs_copula, rs_property(S, Claim, Extra).
rs_predication(S, _, Claim, []) -->
    rs_aux, [word(not, _)], rs_verb(V),
    rs_object_opt(class, O),
    rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, P), Claim = neg(P) }.
rs_predication(S, Ctx, Claim, Extra) -->
    rs_modal_verb(V),
    rs_object_opt(Ctx, O, Extra),
    rs_place_opt(O, Pl),
    { rs_claim(V, S, O, Pl, Claim) }.

%% `is ADJ', `is a [ADJ..] NOUN' -- a unary property of the subject -- or
%% `is the [ADJ..] NOUN of X', a relation the noun names: mother_of(alice,
%% bob), plural_of(los, el). An adjective before the noun is a fact about
%% the subject besides, handed back before the claim: `"como" is the first
%% person of "come"' is first(como), person_of(como, come), and `"casa" is
%% a feminine noun' is noun(casa), feminine(casa) -- the same reading `the
%% feminine article "la"' gets as a subject, and what a lesson typed as
%% prose says most often. The noun is the LAST word before `of' or the
%% stop, so nothing is noted until the shape is sure.
rs_property(S, P, Extra) -->
    rs_det(Kind), !,
    (   { Kind == def }, rs_adjs(As), rs_noun(N), [word(of, _)], rs_of_object(O)
    ->  { rs_note('$rs_nouns', N), atom_concat(N, '_of', NO), P =.. [NO, S, O], rs_adj_terms(As, S, Extra) }
    ;   rs_adjs(As), rs_noun(N), { rs_note('$rs_nouns', N), P =.. [N, S], rs_adj_terms(As, S, Extra) }
    ).
rs_property(S, P, []) --> rs_adj(A), { P =.. [A, S] }.

%% the same as one goal, for a question, a relative clause and a denial:
%% the relation first, the adjectives after it
rs_property(S, P) --> rs_property(S, P0, Extra), { rs_conj([P0|Extra], P) }.

%% after `of': a mention, or a proper noun
rs_of_object(W) --> rs_mention(W).
rs_of_object(P) --> rs_proper(P).

%% a modal in front of the verb joins it: may_access
rs_modal_verb(V) --> [word(M, _)], { rl_modal(M) }, !, rs_verb_word(W), { atomic_list_concat([M, '_', W], V) }.
rs_modal_verb(V) --> rs_verb(V).

%% an object, or none for an intransitive verb
rs_object_opt(Ctx, O, Extra) --> rs_object(Ctx, O, Extra).
rs_object_opt(_, none, []) --> [].
rs_object_opt(Ctx, O) --> rs_object_opt(Ctx, O, _).

%% `in Rome' or `in the barn' AFTER AN OBJECT: the preposition joins the
%% relation, as it does when it is written joined to a bare verb (`lives_in
%% Rome'), and the place is a third argument -- rent_in(alice, V, rome),
%% keep_in(omar, tractor, barn), a definite phrase being its class atom.
%% Only after an object: after a bare verb the two words are ONE relation
%% and are written as one, so `Alice sleeps in Rome' is still refused
%% where `Alice sleeps_in Rome' is read, and library(reasoning/normalise)'s
%% assembler is what joins them.
rs_place_opt(O, Prep-Place) --> { O \== none }, [word(Prep, _)], { rl_preposition(Prep) }, rs_place(Place), !.
%% and after a BARE verb a preposition and a MENTION -- a quoted word, or a
%% determined noun as its class atom: `ends in "a"' is end_in(X, a) and
%% `ends in a vowel' end_in(X, vowel), where `sleeps in Rome' stays
%% refused. A mention can belong to nothing but the verb, and a place
%% could be a phrase left over.
rs_place_opt(O, Prep-W) --> { O == none }, [word(Prep, _)], { rl_preposition(Prep) }, rs_mention(W), { \+ rl_time_noun(W) }, !.
rs_place_opt(_, none) --> [].

%% a place is never a TIME: `in the morning', `at the moment', `for a
%% while' are adjuncts this grammar does not read, and the generator's
%% noise (normalise.pl's pp_extra) must stay refused. And a sentence that
%% MENTIONS a word names no place: `"casa" means "house" in Spanish' and
%% `The word "no" precedes the verb in Spanish' are refused rather than
%% read as mean_in/3 and precede_in/3, because the proper noun after a
%% word said of a word is the language, which the normaliser drops --
%% where `takes "s" in the plural', a definite phrase, is still the form
rs_place(P) --> { \+ rs_pending('$rs_quoted', _) }, rs_proper(P).
rs_place(N) --> rs_det(def), rs_noun(N), { \+ rl_time_noun(N), rs_note('$rs_nouns', N) }.

rs_mention(W) --> rs_quoted(W).
rs_mention(N) --> rs_det(_), rs_noun(N), { rs_note('$rs_nouns', N) }.

%% a quoted word, a quantity, a proper noun; `the N' as the class atom;
%% `a N' as an individual in a fact and the class atom otherwise
rs_object(_, W, []) --> rs_quoted(W).
rs_object(_, Q, []) --> rs_quantity(Q).
rs_object(_, O, []) --> rs_proper(O).
rs_object(_, N, []) --> rs_det(def), rs_adjs(_), rs_noun(N), { rs_note('$rs_nouns', N) }.
rs_object(fact, V, [Noun|Adjs]) -->
    rs_det(indef), rs_adjs(As), rs_noun(N),
    { rs_note('$rs_nouns', N), Noun =.. [N, V], rs_adj_terms(As, V, Adjs) }.
rs_object(Ctx, N, []) --> { Ctx \== fact }, rs_det(indef), rs_adjs(_), rs_noun(N), { rs_note('$rs_nouns', N) }.

%% a quantity: a number and the noun it counts, as written -- `500 euros'
%% quantity(500, euros), `three vineyards' quantity(3, vineyards), `5.5
%% percent' quantity(5.5, percent); `two litres of milk' quantity(2,
%% litres, milk), and `a litre of milk' the same with 1; a bare number the
%% number itself. A VALUE, never an individual: nothing is introduced, and
%% no adjective is read inside one (`three red cars' is refused).
rs_quantity(quantity(N, U, Of)) --> rs_number_or_one(N), rs_noun(U), [word(of, _)], !, rs_noun(Of).
rs_quantity(quantity(N, U)) --> rs_number(N), rs_noun(U), !.
rs_quantity(N) --> rs_number(N).

rs_number_or_one(N) --> rs_number(N).
rs_number_or_one(1) --> rs_det(indef).

%% digits as the tokeniser read them, or the number words: `five', `twenty
%% five', `two hundred', `two hundred fifty', `a hundred', `three thousand'
rs_number(N) --> [num(N)].
rs_number(N) --> [word(a, _)], [word(S, _)], { rl_scale(S, N) }.
rs_number(N) --> [word(W, _)], { rl_number(W, N0) }, rs_number_rest(N0, N).

rs_number_rest(N0, N) --> [word(S, _)], { rl_scale(S, M) }, !, { N1 is N0 * M }, rs_number_rest(N1, N).
rs_number_rest(N0, N) --> { N0 >= 20, N0 mod 10 =:= 0 }, [word(U, _)], { rl_number(U, D), D > 0, D < 10 }, !, { N is N0 + D }.
rs_number_rest(N0, N) --> { N0 >= 100 }, [word(W, _)], { rl_number(W, D0), D0 < 100 }, rs_number_rest(D0, D), { D < 100 }, !, { N is N0 + D }.
rs_number_rest(N, N) --> [].

%% O == none, never a unification: an indefinite object is still a fresh
%% VARIABLE here, and a variable unifies with `none' happily
rs_claim(V, S, O, P) :- O == none, !, P =.. [V, S].
rs_claim(V, S, O, P) :- P =.. [V, S, O].

rs_claim(V, S, O, none, P) :- !, rs_claim(V, S, O, P).
rs_claim(V, S, O, Prep-Place, P) :- O == none, !, atomic_list_concat([V, '_', Prep], VP), P =.. [VP, S, Place].
rs_claim(V, S, O, Prep-Place, P) :- atomic_list_concat([V, '_', Prep], VP), P =.. [VP, S, O, Place].

rs_adj_terms([], _, []).
rs_adj_terms([A|As], V, [T|Ts]) :- T =.. [A, V], rs_adj_terms(As, V, Ts).

%% a fact's Guard is what an apposition said of a quoted subject, and it
%% comes first: noun(casa), mean(casa, house)
rs_assemble(fact, Facts, Claim, Extra, Terms) :- append(Facts, Extra, Ts0), append(Ts0, [Claim], Terms).
rs_assemble(rule, Guard, Claim, _, [(Claim :- Body)]) :- rs_conj(Guard, Body).

rs_conj([G], G) :- !.
rs_conj([G|Gs], (G, B)) :- rs_conj(Gs, B).

%% ---- words -----------------------------------------------------------

%% a capitalised word that is not one of the grammar's own, or a lexicon
%% entry whatever its case
rs_proper(C) --> [word(W, _)], { reason_proper(W, C) }, !, { rs_note('$rs_names', C) }.
rs_proper(W) --> [word(W, upper)], { \+ rl_closed(W), rs_note('$rs_names', W) }.

rs_det(Kind) --> [word(D, _)], { rl_det(D, Kind) }.
rs_quoted(W) --> [quoted(W)], { rs_note('$rs_quoted', W) }.
rs_copula   --> [word(C, _)], { rl_copula(C) }.
rs_aux      --> [word(A, _)], { rl_aux(A) }.

%% the lexicon first, position second
rs_noun(N) --> [word(W, _)], { reason_noun(W) }, !, { N = W }.
rs_noun(N) --> [word(W, _)], { \+ rl_closed(W), N = W }.

rs_adj(A)  --> [word(W, _)], { reason_adj(W) }, !, { A = W }.
rs_adj(A)  --> [word(W, _)], { \+ rl_closed(W), A = W }.

%% zero or more adjectives before a noun -- the noun is the LAST word, so
%% this takes what precedes it
rs_adjs([A|As]) --> rs_adj(A), rs_adjs(As).
rs_adjs([]) --> [].

rs_verb(V) --> rs_verb_word(W), { rs_base(W, V) }.
rs_verb_word(W) --> [word(W, _)], { \+ rl_closed(W) }.

rs_base(W, B) :- reason_verb(W, B), !.
rs_base(W, B) :-                                   % a joined relation, lives_in: the verb stems, the rest stays
    atomic_list_concat([Head|Tails], '_', W), Tails \== [], !,
    (   rl_modal(Head) -> B = W                    % may_use: a modal and a base form, as written
    ;   rs_base(Head, HB), atomic_list_concat([HB|Tails], '_', B)
    ).
rs_base(W, B) :- rl_irregular(W, B), !.
rs_base(W, B) :-                                   % carries, tries -- but dies, lies: die, lie
    atom_codes(W, Cs), append(Pre, [0'i, 0'e, 0's], Cs),
    length(Pre, N), N >= 2, !,
    append(Pre, [0'y], BCs), atom_codes(B, BCs).
rs_base(W, B) :-                                   % watches, passes, fixes, goes
    atom_codes(W, Cs), append(Pre, [0'e, 0's], Cs),
    rl_es_stem(Pre), !,
    atom_codes(B, Pre).
rs_base(W, B) :-                                   % owns, likes, uses
    atom_codes(W, Cs), append(Pre, [0's], Cs),
    length(Pre, N), N >= 3, \+ append(_, [0's], Pre), !,
    atom_codes(B, Pre).
rs_base(W, W).

%% a stem that takes -es rather than -s: it ends in ss, sh, ch, x, z or o.
%% A SINGLE s OR h IS NOT ENOUGH: `uses' is use+s, not us+es, and the first
%% draft answered `us' -- and `clos', `rais', `bath'. Found by writing
%% library(reasoning/normalise)'s inflector, which this must invert exactly:
%% normalise_third/2 there and the four rules above are one pair, changed
%% together. The -ies rule wants two letters before it, so `dies' and `lies'
%% are die+s and lie+s rather than dy and ly, and `carries' is carry. What
%% no rule can settle -- `buses' from bus, `belies' from belie, `aches' from
%% ache -- reason_verb/2 is there for, and library(reasoning/normalise)
%% DROPS from its lexicon as it loads: a verb whose third person does not
%% come back to it here is never generated, so the round trip holds by
%% construction.
%% ---- the inflector: the stemmer's inverse, in the same file ---------------
%% Third person singular: -es after ss, sh, ch, x, z, o; -ies for a
%% consonant and y; -s otherwise; `has' by name. rs_base/2 must give the
%% base back, so the pair lives here and is changed together;
%% library(reasoning/normalise)'s normalise_third/2 is this, and the
%% explanation writes `Re8 attacks H8' with it.
reason_third(have, has) :- !.
reason_third(B, T) :- atom_codes(B, Cs), rl_es_stem(Cs), !, atom_concat(B, es, T).
reason_third(B, T) :- rl_y_stem(B, Stem), !, atom_concat(Stem, ies, T).
reason_third(B, T) :- atom_concat(B, s, T).

%% a consonant and y: carry -> carries; a vowel and y (play) takes -s
rl_y_stem(B, Stem) :-
    sub_atom(B, _, 1, 0, y), sub_atom(B, 0, _, 1, Stem),
    sub_atom(Stem, _, 1, 0, C), \+ memberchk(C, [a, e, i, o, u]).

rl_es_stem(Pre) :- append(_, [0's, 0's], Pre), !.
rl_es_stem(Pre) :- append(_, [0's, 0'h], Pre), !.
rl_es_stem(Pre) :- append(_, [0'c, 0'h], Pre), !.
rl_es_stem(Pre) :- append(_, [0'x], Pre), !.
rl_es_stem(Pre) :- append(_, [0'z], Pre), !.
rl_es_stem(Pre) :- append(_, [0'o], Pre).

%% ---- the closed classes ----------------------------------------------

rl_det(a, indef).   rl_det(an, indef).   rl_det(the, def).
rl_quant(every).    rl_quant(all).       rl_quant(each).
rl_copula(is).      rl_copula(are).      rl_copula(was).     rl_copula(were).
rl_aux(does).       rl_aux(do).          rl_aux(did).
rl_modal(may).      rl_modal(must).      rl_modal(can).
rl_modal(should).   rl_modal(shall).     rl_modal(will).
rl_irregular(has, have). rl_irregular(is, be). rl_irregular(does, do).
rl_irregular(was, be).   rl_irregular(were, be). rl_irregular(goes, go).

rl_closed(W) :- rl_det(W, _), !.
rl_closed(W) :- rl_quant(W), !.
rl_closed(W) :- rl_copula(W), !.
rl_closed(W) :- rl_aux(W), !.
rl_closed(W) :- rl_modal(W), !.
rl_closed(not).
rl_closed(that).
rl_closed(if).
rl_closed(then).
%% number words and scales: closed, so `five' is never an adjective and
%% `Six' never a name; `much' and `many' with them, the words of a how-much
%% question
rl_closed(W) :- rl_number(W, _), !.
rl_closed(W) :- rl_scale(W, _), !.
rl_closed(much).
rl_closed(many).
%% pronouns: closed, so a capitalised `It' at the head of a sentence is
%% not a proper noun named `it' -- `It rains' answered rain(it) until the
%% suite asked for it to be refused. Nothing here resolves one; a sentence
%% built on one is refused whole, as the header says.
rl_closed(W) :- rl_pronoun(W).
rl_closed(W) :- rl_question(W).
rl_closed(W) :- rl_preposition(W).
rl_closed(W) :- rl_conjunction(W).
rl_pronoun(it).   rl_pronoun(he).   rl_pronoun(she).  rl_pronoun(they).
rl_pronoun(we).   rl_pronoun(i).    rl_pronoun(you).  rl_pronoun(him).
rl_pronoun(her).  rl_pronoun(them). rl_pronoun(us).   rl_pronoun(me).
rl_pronoun(his).  rl_pronoun(its).  rl_pronoun(their). rl_pronoun(our).
rl_subject_pronoun(she). rl_subject_pronoun(he). rl_subject_pronoun(they).   % the ones that stand for a subject; not `it'
%% question words: closed, so that `Who' at the head of a sentence is never
%% read as somebody's name
rl_question(who).   rl_question(whom).  rl_question(what).  rl_question(which).
rl_question(where). rl_question(when).  rl_question(why).   rl_question(how).
%% prepositions: closed, so a phrase after the object is LEFT OVER and the
%% sentence fails. Without this the position rule -- the noun is the last
%% word -- read `Alice owns a house in Rome' as a `rome' that is `house'
%% and `in', and accepted it. A wrong reading accepted is worse than a
%% refusal, and this library refuses.
%% the nouns of a time adjunct, which no place or class atom is made of --
%% not `past', `present' or `future', which a lesson names as TENSES
%% (`takes "ba" in the past' is take_in(V, ba, past))
rl_time_noun(moment).    rl_time_noun(morning).   rl_time_noun(afternoon). rl_time_noun(evening).
rl_time_noun(night).     rl_time_noun(day).       rl_time_noun(week).      rl_time_noun(weekend).
rl_time_noun(month).     rl_time_noun(year).      rl_time_noun(hour).      rl_time_noun(minute).
rl_time_noun(time).      rl_time_noun(while).     rl_time_noun(end).       rl_time_noun(beginning).
rl_time_noun(meantime).
rl_time_noun(whole).       % `on the whole', an adjunct of the same kind: never a place

rl_preposition(in).      rl_preposition(on).      rl_preposition(at).
rl_preposition(to).      rl_preposition(from).    rl_preposition(with).
rl_preposition(by).      rl_preposition(for).     rl_preposition(of).
rl_preposition(after).   rl_preposition(before).  rl_preposition(under).
rl_preposition(over).    rl_preposition(into).    rl_preposition(onto).
rl_preposition(about).   rl_preposition(between). rl_preposition(through).
rl_preposition(during).  rl_preposition(without). rl_preposition(within).
rl_preposition(across).  rl_preposition(against). rl_preposition(among).
rl_preposition(around).  rl_preposition(behind).  rl_preposition(below).
rl_preposition(beneath). rl_preposition(beside).  rl_preposition(beyond).
rl_preposition(near).    rl_preposition(off).     rl_preposition(out).
rl_preposition(since).   rl_preposition(until).   rl_preposition(upon).
rl_preposition(toward).  rl_preposition(towards). rl_preposition(via).
rl_preposition(as).      rl_preposition(than).
%% conjunctions: closed, because `Alice and Bob' PARSED as and(alice, bob)
%% -- the conjunction fell through as the verb -- and `Alice and Bob signed
%% the contract' was refused only because what followed did not fit. A
%% refusal by luck is a misreading waiting for the sentence that fits.
rl_conjunction(and). rl_conjunction(or). rl_conjunction(but).
%% the number words, and the scales a number word multiplies by
rl_number(zero, 0).      rl_number(one, 1).       rl_number(two, 2).       rl_number(three, 3).
rl_number(four, 4).      rl_number(five, 5).      rl_number(six, 6).       rl_number(seven, 7).
rl_number(eight, 8).     rl_number(nine, 9).      rl_number(ten, 10).      rl_number(eleven, 11).
rl_number(twelve, 12).   rl_number(thirteen, 13). rl_number(fourteen, 14). rl_number(fifteen, 15).
rl_number(sixteen, 16).  rl_number(seventeen, 17). rl_number(eighteen, 18). rl_number(nineteen, 19).
rl_number(twenty, 20).   rl_number(thirty, 30).   rl_number(forty, 40).    rl_number(fifty, 50).
rl_number(sixty, 60).    rl_number(seventy, 70).  rl_number(eighty, 80).   rl_number(ninety, 90).
rl_scale(hundred, 100).  rl_scale(thousand, 1000). rl_scale(million, 1000000). rl_scale(billion, 1000000000).

%% ---- naming the individuals ------------------------------------------
%%
%% A fresh individual is a variable while the grammar runs, so a sentence
%% with several stays one term with shared variables. Naming is a pass
%% over the finished list: each variable takes the noun of the first
%% unary term that mentions it -- the grammar always emits the noun term
%% first -- and a counter per noun, so two cars are car_1 and car_2.

%% ONLY THE FACTS. A variable in a rule is universal -- the X of `every
%% employee' -- and must stay one; a variable in a fact is an individual
%% the text introduced and gets its name. The grammar never shares a
%% variable between the two.
reason_name(Terms, Terms) :-
    rn_facts(Terms, Facts),
    term_variables(Facts, Vs),
    rn_each(Vs, Facts, []).

%% rules and questions keep their variables: a question's variable is
%% what it asks
rn_facts([], []).
rn_facts([T|Ts], Fs) :-
    ( nonvar(T), ( T = (_ :- _) ; T = question(_) ; T = question(_, _) ) -> Fs = Fs1 ; Fs = [T|Fs1] ),
    rn_facts(Ts, Fs1).

rn_each([], _, _).
rn_each([V|Vs], Terms, Counts0) :-
    ( rn_noun_of(V, Terms, N) -> true ; N = thing ),
    ( memberchk(N-C0, Counts0) -> C is C0 + 1, rn_bump(Counts0, N, C, Counts)
    ; C = 1, Counts = [N-1|Counts0] ),
    atomic_list_concat([N, '_', C], Name),
    V = Name,
    rn_each(Vs, Terms, Counts).

rn_bump([], _, _, []).
rn_bump([N-_|Cs], N, C, [N-C|Cs]) :- !.
rn_bump([X|Cs], N, C, [X|Ds]) :- rn_bump(Cs, N, C, Ds).

rn_noun_of(V, [T|Ts], N) :-
    (   compound(T), \+ T = (_ :- _), \+ T = neg(_),
        functor(T, N, 1), arg(1, T, A), A == V
    ->  true
    ;   rn_noun_of(V, Ts, N)
    ).
