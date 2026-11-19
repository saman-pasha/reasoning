%% coding/endpoint/english_lesson.pl -- the English lesson the endpoint reads.
%%
%%     ep_english_lesson/0
%%
%% library(reasoning/translate) reads a language from a lesson: a noun is
%% said as `The noun "casa" means "house".', read by the reasoner into
%% noun(casa), mean(casa, house). English is the pivot, so an English text
%% has no other language to cross to -- but its words must still be KNOWN
%% (tr_known(english, house), tr_class(english, house, noun)), and both are
%% asked of mean(_, house): some lesson word means it, and that word's
%% class is the English word's.
%%
%% The lesson here teaches every English word as the MEANING of a synthetic
%% word of its own, `x_house means house'. The synthetic word is what a
%% lesson word is; the English word stays English (it is no meaning of
%% itself, so the reader does not take it for a word of another language,
%% which a lesson that says `house means house' would).
%%
%% The words are the repository's: the noun, adjective, adverb and verb
%% lists under lexicon/, each line a word; a verb is taught in its third
%% person singular, the form a lesson states (`"mangia" means "eats"'),
%% which the inflector reasons from the base form the list carries. The
%% closed classes -- articles, prepositions, conjunctions, numbers,
%% determiners and adverbs -- are written below. A line with a space, a
%% hyphen or a character that is not a letter is skipped: a lesson word is
%% one token.
%%
%% The load is once per process: about a quarter of a second and 47 000
%% words on the machine this was measured on. It is called by the server's
%% main (httpd.pl) before the port is served, and by the endpoint test.

:- use_module(library(reasoning/translate)).

ep_english_lesson :-
    (   catch(nb_getval('$ep_english_lesson'), _, fail)
    ->  true
    ;   catch(ep_english_lesson_load, Ball,
              format(user_error, "warning: the English lesson did not load: ~q~n",
                     [Ball])),
        nb_setval('$ep_english_lesson', yes)
    ).

ep_english_lesson_load :-
    forall(member(File-Class,
                  ['lexicon/noun.txt'-noun,
                   'lexicon/known_noun.txt'-noun,
                   'lexicon/class.txt'-noun,
                   'lexicon/unit.txt'-noun,
                   'lexicon/adj.txt'-adjective,
                   'lexicon/known_adj.txt'-adjective,
                   'lexicon/adverb.txt'-adverb,
                   'lexicon/known_adverb.txt'-adverb]),
           ep_lesson_words(File, Class)),
    forall(member(File, ['lexicon/vt.txt', 'lexicon/vi.txt',
                         'lexicon/vpp.txt', 'lexicon/known_verb.txt']),
           ep_lesson_verbs(File)),
    ep_lesson_functions.

ep_lesson_words(File, Class) :-
    ep_lesson_lines(File, Lines),
    forall(( member(Line, Lines),
             ep_lesson_word(Line, W)
           ),
           (   atom_concat(x_, W, X),
               assertz(mean(X, W)),
               G =.. [Class, X],
               assertz(G)
           )).

ep_lesson_verbs(File) :-
    ep_lesson_lines(File, Lines),
    forall(( member(Line, Lines),
             ep_lesson_word(Line, W0)
           ),
           (   (   catch(reason_third(W0, W), _, fail)
               ->  true
               ;   W = W0
               ),
               atom_concat(x_, W, X),
               assertz(mean(X, W)),
               assertz(verb(X))
           )).

%% One word a line, one token a lesson word: letters only, and short
%% enough to be a word the lists meant.
ep_lesson_word(Line, W) :-
    atom_string(W, Line),
    W \== '',
    atom_codes(W, Codes),
    length(Codes, Length),
    Length =< 24,
    ep_lesson_letters(Codes).

ep_lesson_letters([]).
ep_lesson_letters([C|Codes]) :-
    C >= 0'a,
    C =< 0'z,
    ep_lesson_letters(Codes).

ep_lesson_lines(File, Lines) :-
    catch(read_file_to_codes(File, Codes), _, fail),
    atom_codes(Text, Codes),
    atomic_list_concat(Lines, '\n', Text).

ep_lesson_functions :-
    forall(member(Class-W,
                  [article-a, article-an, article-the,
                   preposition-of, preposition-in, preposition-on,
                   preposition-at, preposition-to, preposition-for,
                   preposition-with, preposition-by, preposition-from,
                   preposition-into, preposition-through,
                   preposition-between, preposition-under, preposition-over,
                   preposition-above, preposition-below, preposition-after,
                   preposition-before, preposition-about, preposition-as,
                   preposition-without, preposition-within,
                   preposition-during,
                   conjunction-and, conjunction-or, conjunction-but,
                   conjunction-nor, conjunction-yet,
                   number-one, number-two, number-three, number-four,
                   number-five, number-six, number-seven, number-eight,
                   number-nine, number-ten,
                   determiner-each, determiner-every, determiner-all,
                   determiner-some, determiner-any, determiner-no,
                   determiner-another, determiner-other, determiner-many,
                   determiner-much, determiner-more, determiner-most,
                   determiner-few, determiner-little, determiner-several,
                   determiner-both, determiner-either, determiner-neither,
                   determiner-such, determiner-this, determiner-that,
                   determiner-these, determiner-those,
                   adverb-not, adverb-very, adverb-only, adverb-also,
                   adverb-too, adverb-now, adverb-then, adverb-here,
                   adverb-there, adverb-when, adverb-where, adverb-why,
                   adverb-how, adverb-once, adverb-twice]),
           (   atom_concat(x_, W, X),
               assertz(mean(X, W)),
               G =.. [Class, X],
               assertz(G)
           )).
