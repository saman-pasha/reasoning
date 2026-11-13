%% reasoning tutorial 02 -- library(reasoning/normalise): the grammar as a data generator, and the tags that undo the noise.
%%
%% TIER 2: `use_module(library(reasoning/normalise))', from normalise.pl. Clauses only,
%% and it needs nothing but library(reasoning/reason).
%%
%%     cocolog -s tutorials/02-normalise.pl
%%
%% THE PROBLEM THIS SOLVES. library(reasoning/reason) reads a controlled English and
%% refuses everything else -- tutorial 01 ends on a list of ordinary
%% sentences it will not read. The road from typed prose to that grammar
%% is a network that labels every token: subject, relation, object, or
%% noise. Prolog then rebuilds the sentence in the grammar's shapes and
%% the grammar verifies it. Such a network needs examples, and no corpus
%% of (prose, controlled English) exists -- so this library MAKES one,
%% from the grammar's own shapes: a clean sentence with its gold tags,
%% then noise transforms that carry the tags along.
%%
%% NO NETWORK IS TRAINED HERE. This lesson is about the data: that every
%% clean sentence parses, that every noisy one is refused, and that the
%% gold tags assemble the noisy sentence back into the clean one's terms.
%% That last property is the whole contract -- it is what makes the tags a
%% possible target for a network at all -- and section 4 holds it.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).

main :-
    format("~n1. A clean pair: the sentence, its tokens, its gold tags~n", []),
    normalise_pair(3, [transforms([])], pair(N1, Toks1, Tags1, C1, A1)),
    show('clean text', C1),
    show('tokens', Toks1),
    show('tags', Tags1),
    must('with no transforms, noisy = clean', N1, C1),
    must('and nothing applied', A1, []),
    ( reason_text(C1, T1) -> true ; T1 = refused ),
    show('what the grammar makes of it', T1),

    format("~n2. The same seed with every transform that fits~n", []),
    normalise_pair(3, [always(true)], pair(N2, Toks2, Tags2, C2, A2)),
    show('noisy text', N2),
    show('applied', A2),
    show('tags', Tags2),
    ( reason_text(N2, _) -> R2 = parsed ; R2 = refused ),
    must('the grammar refuses the noisy text', R2, refused),
    length(Toks2, LT2), length(Tags2, LG2),
    must('one tag a token', LT2, LG2),

    format("~n3. The assembler: D dropped, an R run joined, B a break~n", []),
    normalise_assemble(Toks2, Tags2, Asm3),
    show('assembled from the gold tags', Asm3),
    ( reason_text(Asm3, T3) -> true ; T3 = refused ),
    show('what the grammar makes of THAT', T3),

    format("~n4. The contract: the assembled text gives the clean text's terms~n", []),
    reason_text(C2, TC), reason_text(Asm3, TA),
    must('same terms, up to variable names', variant(TC, TA), variant(TC, TA)),
    ( rt_variant(TC, TA) -> V4 = yes ; V4 = no ),
    must('checked properly, with the variables numbered', V4, yes),
    normalise_corpus(60, Pairs),
    findall(S, ( member(pair(_, Tk, Tg, C, _), Pairs), normalise_assemble(Tk, Tg, A),
                 reason_text(A, X), reason_text(C, Y), rt_variant(X, Y), S = 1 ), Oks),
    length(Oks, NOk),
    must('over 60 seeds, how many round-trip', NOk, 60),

    format("~n5. The transforms, one example each~n", []),
    normalise_transforms(Ts),
    forall(member(T, Ts), (
        ( between(1, 80, I), normalise_pair(I, [transforms([T]), always(true)], pair(N, _, _, C, [T])) -> true ; N = none, C = none ),
        format("   ~w~n      ~w~n   -> ~w~n", [T, C, N]) )),

    format("~n6. What a tag cannot do, and so what is not in the set~n", []),
    normalise_tags(Tags6),
    must('the alphabet is closed', Tags6, ['S','Q','C','N','R','K','T','A','O','D','B','X','M']),
    show('a tag drops, joins or splits; it never changes a word', '"All tenants have badges" is not generated'),
    show('so a plural, a passive, a pronoun are not noise here', 'they are the next transforms, once a tag can carry them'),

    format("~n7. And M, the one tag that ADDS something: the quotation marks a lesson writes~n", []),
    normalise_assemble([word(the, upper), word(noun, lower), word(casa, lower), word(means, lower), word(house, lower)],
                       ['T', 'A', 'M', 'R', 'M'], Asm7),
    must('a word tagged M is written between quotation marks', Asm7, 'The noun "casa" means "house".'),
    reason_text(Asm7, Terms7),
    must('which the grammar reads as facts about the WORD', Terms7, [noun(casa), mean(casa, house)]),
    normalise_lessons(Lessons7), length(Lessons7, NL7),
    show('lesson lines in corpus, the words the lesson shapes draw from', NL7),
    normalise_lexicon(wclass, Classes7), show('the classes a lesson says of a word, read out of those lines', Classes7),
    normalise_bare('Every noun that ends in "a" is feminine.', Bare7),
    must('normalise_bare/2 types a line as prose types it', Bare7, 'Every noun that ends in a is feminine.'),
    ( reason_text(Bare7, _) -> R7 = parsed ; R7 = refused ),
    must('which the grammar refuses: `a'' is the article to it', R7, refused),
    normalise_pair(43, pair(N7, Toks7, Tags7, C7, A7)),
    show('a lesson pair, seed 43', N7),
    show('its tags', Tags7),
    show('what was applied', A7),
    show('the clean text it was made from', C7),
    normalise_assemble(Toks7, Tags7, Asm7b),
    show('assembled with the gold tags', Asm7b),
    reason_text(Asm7b, T7b), reason_text(C7, T7c),
    ( rt_variant(T7b, T7c) -> R7b = the_same_terms ; R7b = T7b ),
    must('and the two give the same terms: a bare head word is the name reading, and the marks are back on the rest', R7b, the_same_terms),

    format("~ndone~n", []).

%% variants: the same term up to the names of its variables
rt_variant(A, B) :-
    copy_term(A, A1), copy_term(B, B1),
    term_variables(A1, Va), rt_number(Va, 0),
    term_variables(B1, Vb), rt_number(Vb, 0),
    A1 == B1.
rt_number([], _).
rt_number(['$v'(N)|Vs], N) :- N1 is N + 1, rt_number(Vs, N1).

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
