%% lexicon/build.pl -- WordNet 3.0 to lexicon/*.txt.
%%
%%     ./cocolog -s lexicon/build.pl -- --wordnet DIR [--out DIR] [--cap CLASS=N]...
%%     ./cocolog -s lexicon/build.pl -- --capitals --wordnet DIR [--out DIR]
%%     ./cocolog -s lexicon/build.pl -- --every --wordnet DIR [--out DIR]
%%     ./cocolog -s lexicon/build.pl -- --phrasal --wordnet DIR [--out DIR]
%%     ./cocolog -s lexicon/build.pl -- --infinitive --wordnet DIR [--out DIR]
%%     sh tools/lexicon/build.sh                         the same, from this repository's root
%%
%% THE LEXICON IS DATA, NOT SOURCE. library(reasoning/normalise) generates
%% its sentences from files beside it, one class a file, and this writes
%% those files from Princeton WordNet's database, thousands of words wide,
%% the commonest first -- so that nobody adds a noun by hand, and so that
%% a network trained on the generator meets the words English uses.
%%
%% WHAT COMES FROM WHERE. Three of WordNet's files carry what a class needs:
%%
%%   cntlist.rev   every sense SemCor tagged, as `lemma%T:LF:..  sense  count':
%%                 T the part of speech (1 noun, 2 verb, 3 adjective, 4
%%                 adverb, 5 adjective satellite), LF the LEXICOGRAPHER FILE
%%                 the sense sits in (18 noun.person, 15 noun.location, ...),
%%                 and the count, which ranks a word by use. A word's class
%%                 follows its most-tagged sense: `hand' is a body part before
%%                 it is a worker.
%%   index.noun    every noun, with the synset of its FIRST sense -- WordNet
%%                 orders a word's senses by how often each is meant.
%%   data.noun     every noun synset, with its lexicographer file, whether
%%                 it is an INSTANCE (`@i' among its pointers): a named place
%%                 rather than a kind of place -- and its HYPONYMS (`~'),
%%                 which is how a unit is found: a noun whose first sense
%%                 descends from unit_of_measurement or time_unit (euro,
%%                 gram, mile, hour), where the file noun.quantity alone
%%                 would give `nothing', `much' and `half' -- and how a
%%                 LANGUAGE is: a noun whose first or second sense descends
%%                 from natural_language (English first, Italian second,
%%                 because WordNet names the people before the tongue).
%%   data.verb     the SENTENCE FRAMES each synset takes, which is what says a
%%                 verb takes an object (frames 8-11), none (1, 2) or a phrase
%%                 (22, 4).
%%   the glosses   every data.* gloss quotes EXAMPLE SENTENCES -- "She froze
%%                 when she saw her ex-husband" -- which are real English and
%%                 not the grammar's: prose.txt, the NEGATIVES a tagger learns
%%                 to refuse, in a fixed hash order so a slice is a sample.
%%
%% Then: noun = a word whose first sense is a thing (animal, artifact, food,
%% object, plant, possession) and no instance; class = noun.person; place =
%% noun.location and an instance, capitalised -- every noun WordNet has,
%% the SemCor-counted ones first and the rest in a fixed hash order, never
%% alphabetical, so a cap is a sample and not the letter A; adj = adj.all
%% or adj.pert; adverb = adv.all; vt, vi, vpp by frame; unit = a hyponym
%% of unit_of_measurement or time_unit, first sense; language = a hyponym of
%% natural_language in a word's first or second sense, capitalised, for the
%% lesson shapes (`Spanish is a language', `The Spanish word "casa"'); and known_noun,
%% known_verb, known_adverb = EVERY counted lemma of that part of
%% speech whatever its sense, for the tagger's judge rather than the
%% generator (`death' is no thing to own, and still a noun); known_adj =
%% every adjective index.adj names, counted or not, because `registered'
%% is one and SemCor never tagged it. Only single, alphabetic,
%% three-to-twelve-letter words; the grammar's own filters -- a closed word,
%% a verb the stemmer cannot invert -- are applied where the files are READ,
%% in normalise.pl, not here, so this tool knows nothing of the grammar.
%%
%% IN COCOLOG, NOT PYTHON: read_file_to_codes/2 takes data.noun's fifteen
%% megabytes in half a second and split_string/4 cuts a megabyte into lines
%% in ten milliseconds, and a parse over fields is what a Prolog is for.

%% --capitals writes capital.txt alone (since reasoning 1.92.0): the
%% adjectives WordNet writes ONLY with a capital, from the four data files
%% (no cntlist.rev, so WordNet 3.1's files serve as well as 3.0's).
main :-
    current_prolog_flag(argv, [_|Args0]),
    select('--capitals', Args0, Args), !,
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], _),
    lx_capitals(WN, Caps),
    lx_write(Out, capital, Caps),
    length(Caps, N), lx_take(6, Caps, First),
    format("   capital ~w  ~w~nwrote ~w/capital.txt~n", [N, First, Out]).
%% --phrasal writes phrasal.txt alone (since reasoning 1.94.0): WordNet's
%% verbs of a verb and a particle, from data.verb (either version's).
main :-
    current_prolog_flag(argv, [_|Args0]),
    select('--phrasal', Args0, Args), !,
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], _),
    lx_phrasals(WN, Rows),
    lx_write(Out, phrasal, Rows),
    length(Rows, N), lx_take(6, Rows, First),
    format("   phrasal ~w  ~w~nwrote ~w/phrasal.txt~n", [N, First, Out]).
%% --infinitive writes vinf.txt and vtinf.txt alone (since reasoning 1.95.0
%% and 1.96.0): the verbs WordNet gives the frame `Somebody ----s to
%% INFINITIVE' (28), and `Somebody ----s somebody to INFINITIVE' (24), from
%% data.verb.
main :-
    current_prolog_flag(argv, [_|Args0]),
    select('--infinitive', Args0, Args), !,
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], _),
    lx_verb_frames(WN, Frames),
    assoc_to_keys(Frames, Verbs),
    forall(member(Name-F, [vinf-28, vtinf-24]),
           ( findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), memberchk(F, Fs) ), Vs),
             lx_write(Out, Name, Vs),
             length(Vs, N), lx_take(6, Vs, First),
             format("   ~w ~w  ~w~nwrote ~w/~w.txt~n", [Name, N, First, Out, Name]) )).
%% --clause writes vthat.txt alone (since reasoning 1.144.0): the verbs
%% WordNet gives the frame `Somebody ----s that CLAUSE' (26), from
%% data.verb.
main :-
    current_prolog_flag(argv, [_|Args0]),
    select('--clause', Args0, Args), !,
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], _),
    lx_verb_frames(WN, Frames),
    assoc_to_keys(Frames, Verbs),
    findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), memberchk(26, Fs) ), Vs),
    lx_write(Out, vthat, Vs),
    length(Vs, N), lx_take(6, Vs, First),
    format("   vthat ~w  ~w~nwrote ~w/vthat.txt~n", [N, First, Out]).
%% --every writes every_noun.txt, every_verb.txt, every_adverb.txt and
%% every_vi.txt alone (since reasoning 1.123.0), and every_adjective.txt
%% (since 1.124.0): every lemma index.noun, index.verb, index.adv and
%% index.adj name, of letters a to z (and since 1.128.0 a hyphen between
%% two letters: low-level) and three letters or more, of any
%% length since 1.124.0 (unsympathetic, uncompromising; this file's word
%% filter stops at twelve), the SemCor-counted ones first (known_noun's,
%% known_verb's, known_adj's and known_adverb's order) and the rest in
%% hash order, and every verb with
%% the frame "Something ----s" or "Somebody ----s" (1, 2), vi.txt's
%% order uncapped. They are the typology's words, never the judge's: the
%% known_* files stay SemCor's (lx_classes/7 says why). An uncounted lemma
%% that is a form of another word, or that the data files write only with
%% a capital (a name: socrates, paris), is left out (lx_every_keep/5).
main :-
    current_prolog_flag(argv, [_|Args0]),
    select('--every', Args0, Args), !,
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], _),
    lx_senses(WN, Groups),
    lx_verb_frames(WN, Frames),
    lx_inflected(WN, Forms, All),
    findall(W, ( member(F, ['data.adj', 'data.noun', 'data.verb', 'data.adv']),
                 lx_data_word(WN, F, W), \+ lx_capital_form(W) ), Low0),
    sort(Low0, Low1), findall(W-1, member(W, Low1), LowPairs), list_to_assoc(LowPairs, Low),
    forall(member(Name-Ts-File-P, [every_noun-[1]-'index.noun'-noun, every_verb-[2]-'index.verb'-verb,
                                   every_adjective-[3, 5]-'index.adj'-adj, every_adverb-[4]-'index.adv'-adverb]),
           ( findall(NC-W, ( member(g(W, T, _, C), Groups), memberchk(T, Ts), NC is -C ), K0), lx_rank_unique(K0, Counted),
             lx_index_words(WN, File, Lemmas0),
             include(lx_every_word, Lemmas0, Lemmas),
             lx_uncounted(Lemmas, Counted, Rest0),
             include(lx_every_keep(Forms, All, Low, P), Rest0, Rest),
             append(Counted, Rest, Words),
             lx_every_write(Out, Name, Words) )),
    findall(NC-W, ( member(g(W, 2, _, C), Groups), NC is -C ), Verb0),
    lx_rank(Verb0, VCounted),
    assoc_to_keys(Frames, AllVerbs),
    findall(V, ( member(V, AllVerbs), \+ memberchk(V, VCounted) ), Uncounted),
    append(VCounted, Uncounted, Verbs),
    findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), lx_meets(Fs, [1, 2]) ), VI),
    lx_every_write(Out, every_vi, VI).
main :-
    current_prolog_flag(argv, [_|Args]),
    lx_options(Args, '/usr/share/wordnet', WN, 'lexicon', Out, [], Caps),
    atom_concat(WN, '/cntlist.rev', Cnt),
    (   exists_file(Cnt)
    ->  true
    ;   throw(error(existence_error(wordnet, WN), 'apt install wordnet-base, or --wordnet DIR'))
    ),
    format("lexicon: reading WordNet at ~w~n", [WN]),
    lx_senses(WN, Groups),
    lx_noun_kinds(WN, Kinds, Synsets),
    lx_units(Synsets, Units),
    lx_languages(Synsets, Languages),
    lx_verb_frames(WN, Frames),
    lx_index_lemmas(WN, 'index.adj', AdjLemmas),
    lx_classes(Groups, Kinds, Units, Languages, Frames, AdjLemmas, Classes0),
    lx_prose(WN, Prose),
    append(Classes0, [prose-Prose], Classes),
    forall(member(Class-Words, Classes),
           ( lx_cap(Class, Caps, Cap), lx_take(Cap, Words, Kept),
             lx_write(Out, Class, Kept),
             length(Kept, N), lx_take(6, Kept, First),
             format("   ~w ~w  ~w~n", [Class, N, First]) )),
    format("wrote ~w/{noun,class,adj,vt,vi,vpp,adverb,place,unit,language,prose,known_noun,known_verb,known_adj,known_adverb}.txt~n", [Out]).

%% THE FORMS OF WORDS the reader makes itself (since reasoning 1.123.0):
%% Forms maps a form to the lemmas it is a form of -- a noun's plural, a
%% verb's -s, -ed and -ing, each rule made generous (an e dropped, a y made
%% i, the last letter doubled), and every line of the four exception files
%% (better, worse) -- and All holds every lemma of the four indexes, each
%% of any length here (does is a form of do).
%% Generous on purpose: a form too many leaves a rare lemma out, a form too
%% few lets one in that reads wrong. An adjective's -er is no rule: it left
%% out the agent nouns (spreader, of the adjective spread).
lx_inflected(WN, Forms, All) :-
    findall(F-B, ( member(P-File, [noun-'index.noun', verb-'index.verb']),
                   lx_index_words(WN, File, Ls), member(B, Ls), lx_form(P, B, F), F \== B ), Regular),
    findall(F-B, ( member(E, ['noun.exc', 'verb.exc', 'adj.exc', 'adv.exc']),
                   lx_lines(WN, E, Lines), member(L, Lines),
                   split_string(L, " ", " ", [FS, BS|_]), FS \== "", BS \== "",
                   atom_string(F, FS), atom_string(B, BS), F \== B ), Irregular),
    append(Regular, Irregular, Pairs0), msort(Pairs0, Pairs),
    lx_group_pairs(Pairs, Grouped), list_to_assoc(Grouped, Forms),
    findall(W-1, ( member(File2, ['index.noun', 'index.verb', 'index.adj', 'index.adv']),
                   lx_index_words(WN, File2, Ls2), member(W, Ls2) ), Ws0),
    sort(Ws0, Ws), list_to_assoc(Ws, All).

%% every lemma of an index of letters a to z alone, whatever its length,
%% and since reasoning 1.128.0 a hyphen between two letters (low-level,
%% self-conscious, tongue-in-cheek: 7 028 lemmas of the four indexes).
lx_index_words(WN, File, Words) :-
    lx_lines(WN, File, Lines),
    findall(W, ( member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
                 split_string(L, [32], [32], [LemS|_]), LemS \== "",
                 atom_string(W, LemS), atom_codes(W, Cs),
                 lx_index_codes(Cs) ), Ws),
    sort(Ws, Words).

lx_index_codes([C|Cs]) :- lx_az(C), lx_index_rest(Cs).
lx_index_rest([]).
lx_index_rest([C|Cs]) :- lx_az(C), !, lx_index_rest(Cs).
lx_index_rest([0'-, C|Cs]) :- lx_az(C), lx_index_rest(Cs).

lx_az(C) :- C >= 0'a, C =< 0'z.

%% a word of an every_* file: three letters or more (since 1.124.0 of any
%% length).
lx_every_word(W) :- atom_length(W, N), N >= 3.

lx_group_pairs([], []).
lx_group_pairs([F-B|Ps], [F-[B|Bs]|Gs]) :- lx_same_form(F, Ps, Bs, Rest), lx_group_pairs(Rest, Gs).
lx_same_form(F, [F-B|Ps], [B|Bs], Rest) :- !, lx_same_form(F, Ps, Bs, Rest).
lx_same_form(_, Rest, [], Rest).

lx_form(noun, B, F) :- lx_plural(B, F).
lx_form(verb, B, F) :- lx_plural(B, F).
lx_form(verb, B, F) :- member(S, [ed, ing]), lx_suffixed(B, S, F).

lx_plural(B, F) :- atom_concat(B, s, F).
lx_plural(B, F) :- atom_concat(B, es, F).
lx_plural(B, F) :- atom_concat(B0, y, B), atom_concat(B0, ies, F).

lx_suffixed(B, S, F) :- atom_concat(B, S, F).
lx_suffixed(B, S, F) :- atom_concat(B0, e, B), atom_concat(B0, S, F).
lx_suffixed(B, ed, F) :- atom_concat(B0, y, B), atom_concat(B0, ied, F).
lx_suffixed(B, S, F) :- sub_atom(B, _, 1, 0, C), atomic_list_concat([B, C, S], F).

%% An uncounted lemma is kept where the data files write it in small
%% letters, and unless it is a form of another lemma (fields, teeth,
%% twitching, drew, heaps), or, a noun, its plural is a lemma or another
%% lemma's form (physic: physics; sens: senses).
lx_every_keep(Forms, All, Low, P, W) :-
    get_assoc(W, Low, _),
    \+ lx_form_of_other(Forms, W, W),
    \+ ( P == noun, lx_plural(W, Pl),
         ( get_assoc(Pl, All, _) ; lx_form_of_other(Forms, Pl, W) ) ).

lx_form_of_other(Forms, F, W) :- get_assoc(F, Forms, Bs), member(B, Bs), B \== W, !.

lx_every_write(Out, Name, Words) :-
    lx_write(Out, Name, Words),
    length(Words, N), lx_take(6, Words, First),
    format("   ~w ~w  ~w~nwrote ~w/~w.txt~n", [Name, N, First, Out, Name]).

%% ---- options ----------------------------------------------------------------

lx_options([], WN, WN, Out, Out, Caps, Caps).
lx_options(['--wordnet', D|As], _, WN, O0, Out, C0, Caps) :- !, lx_options(As, D, WN, O0, Out, C0, Caps).
lx_options(['--out', D|As], W0, WN, _, Out, C0, Caps) :- !, lx_options(As, W0, WN, D, Out, C0, Caps).
lx_options(['--cap', Spec|As], W0, WN, O0, Out, C0, Caps) :- !,
    atomic_list_concat([C, NA], '=', Spec), atom_number(NA, N),
    lx_options(As, W0, WN, O0, Out, [C-N|C0], Caps).
lx_options([A|_], _, _, _, _, _, _) :-
    throw(error(domain_error(argument, A), '--wordnet DIR, --out DIR, --cap CLASS=N')).

lx_cap(Class, Caps, Cap) :- memberchk(Class-Cap, Caps), !.
lx_cap(noun, _, 6000).
lx_cap(class, _, 2000).
lx_cap(adj, _, 3000).
lx_cap(vt, _, 2500).
lx_cap(vi, _, 1200).
lx_cap(vpp, _, 1000).
lx_cap(adverb, _, 500).
lx_cap(place, _, 800).
lx_cap(unit, _, 400).
lx_cap(language, _, 150).
lx_cap(prose, _, 8000).
lx_cap(known_noun, _, 20000).
lx_cap(known_verb, _, 8000).
lx_cap(known_adj, _, 20000).
lx_cap(known_adverb, _, 3000).

%% ---- capital.txt: the adjectives written only with a capital ----------------------
%% A one-word adjective lemma of data.adj that is a capital and then small
%% letters (`American', `Guyanese', `Gallic') where no lemma of any part
%% of speech has the word in small letters: `Polish' is a verb's polish,
%% and `Victorian' an adjective's victorian too (prim), so neither is
%% one. Alphabetical: the file is a set, never capped.
lx_capitals(WN, Caps) :-
    findall(W, ( member(F, ['data.adj', 'data.noun', 'data.verb', 'data.adv']),
                 lx_data_word(WN, F, W), \+ lx_capital_form(W) ), Low0),
    sort(Low0, Low),
    findall(W, ( lx_data_word(WN, 'data.adj', W), lx_capital_form(W),
                 downcase_atom(W, L), lx_word(L), \+ ord_memberchk(L, Low) ), Caps0),
    sort(Caps0, Caps).

%% ---- phrasal.txt: the verbs of a verb and a particle ------------------------------
%% A lemma of data.verb that is a verb's word, `_' and a particle
%% (`throw_out', `set_up', `come_up'), and what its synsets' frames let it
%% take: `object' where every frame has an object (8 `Somebody ----s
%% something' and the like), `none' where none has (1 `Something ----s', 22
%% `Somebody ----s PP'), `any' where both stand; a lemma of neither kind of
%% frame (`It ----s that CLAUSE' alone) is left out. A line is the lemma
%% and that word, `throw_out object'. Alphabetical: the file is a set,
%% never capped.
lx_phrasals(WN, Rows) :-
    lx_lines(WN, 'data.verb', Lines),
    findall(V-F,
            ( member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
              lx_synset(L, Words, Fs),
              member(W0, Words), downcase_atom(W0, V), lx_phrasal_lemma(V),
              member(F, Fs) ),
            Pairs),
    msort(Pairs, Sorted),
    lx_group_frames(Sorted, [], Grouped),
    findall(Row, ( member(V-Fs, Grouped), lx_phrasal_takes(Fs, K),
                   atomic_list_concat([V, K], ' ', Row) ), Rows).

lx_phrasal_lemma(V) :-
    atomic_list_concat([B, P], '_', V),
    memberchk(P, [about, along, apart, around, aside, away, back, down, forward,
                  in, off, on, out, over, through, together, up]),
    atom_codes(B, Cs), length(Cs, N), N >= 2, N =< 12,
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z )).

lx_phrasal_takes(Fs, K) :-
    ( lx_meets(Fs, [5, 8, 9, 10, 11, 14, 15, 16, 17, 18, 19, 20, 21, 24, 25, 30, 31]) -> O = yes ; O = no ),
    ( lx_meets(Fs, [1, 2, 3, 4, 6, 7, 12, 13, 22, 23, 27]) -> I = yes ; I = no ),
    lx_takes(O, I, K).

lx_takes(yes, no, object).
lx_takes(no, yes, none).
lx_takes(yes, yes, any).

%% each lemma of a data file, its adjective marker ((a), (p), (ip)) off
lx_data_word(WN, F, W) :-
    lx_lines(WN, F, Lines),
    member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
    split_string(L, [32], [32], [_, _, _, WcntS|R]),
    lx_hex(WcntS, N), lx_take_words(N, R, Ws, _),
    member(W0, Ws),
    ( sub_atom(W0, B, _, _, '(') -> sub_atom(W0, 0, B, _, W) ; W = W0 ).

%% a capital and then small letters, nothing else
lx_capital_form(W) :-
    atom_codes(W, [C|Cs]), C >= 0'A, C =< 0'Z, Cs \== [],
    forall(member(X, Cs), ( X >= 0'a, X =< 0'z )).

%% ---- the files, as lines --------------------------------------------------------

lx_lines(WN, Name, Lines) :-
    atomic_list_concat([WN, '/', Name], Path),
    read_file_to_codes(Path, Codes),
    split_string(Codes, [10], [13], Lines).

%% a single, alphabetic, three-to-twelve-letter word
lx_word(W) :-
    atom_codes(W, Cs), length(Cs, N), N >= 3, N =< 12,
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z )).

%% ---- cntlist.rev: every tagged sense, grouped by word and part of speech --------

lx_senses(WN, Groups) :-
    lx_lines(WN, 'cntlist.rev', Lines),
    findall(k(Lemma, Type, NegCount, LF),
            ( member(L, Lines),
              split_string(L, [32], [32], [KeyS, _, CountS]),
              catch(number_string(Count, CountS), _, fail),
              split_string(KeyS, [37], [], [LemS, RestS]),
              split_string(RestS, [58], [], [TypeS, LFS|_]),
              catch(number_string(Type, TypeS), _, fail), catch(number_string(LF, LFS), _, fail),
              atom_string(Lemma, LemS), lx_word(Lemma),
              NegCount is -Count ),
            Keys),
    msort(Keys, Sorted),
    lx_group(Sorted, [], Groups).

%% a word's most-tagged sense gives its class, and the sum of its senses its rank
lx_group([], Acc, Groups) :- reverse(Acc, Groups).
lx_group([k(L, T, NC, LF)|Rest], Acc, Groups) :-
    lx_same(L, T, Rest, Same, Others),
    findall(C, ( member(k(_, _, NC1, _), [k(L, T, NC, LF)|Same]), C is -NC1 ), Cs), sum_list(Cs, Total),
    lx_group(Others, [g(L, T, LF, Total)|Acc], Groups).
lx_same(L, T, [k(L, T, NC, LF)|R], [k(L, T, NC, LF)|S], O) :- !, lx_same(L, T, R, S, O).
lx_same(_, _, R, [], R).

%% ---- index.noun and data.noun: every noun's first sense, its file and instance-hood ----
%% Kinds: lemma -> k(LexFile, Instance, FirstOffset, SecondOffset) -- the
%% second `none' for a word of one sense; Synsets: offset -> s(LexFile,
%% Instance, Words, Hyponyms), the tree lx_units/2 and lx_languages/2 walk.

lx_noun_kinds(WN, Kinds, ByOffset) :-
    lx_lines(WN, 'data.noun', DLines),
    findall(Offset-s(LF, Inst, Words, Hypos),
            ( member(L, DLines), \+ sub_string(L, 0, 1, _, ' '), lx_noun_synset(L, Offset, LF, Inst, Words, Hypos) ),
            Synsets),
    list_to_assoc(Synsets, ByOffset),
    lx_lines(WN, 'index.noun', ILines),
    findall(Lemma-K,
            ( member(L, ILines), \+ sub_string(L, 0, 1, _, ' '),
              split_string(L, [32], [32], [LemS, _, _, PS|Rest]),
              catch(number_string(P, PS), _, fail),
              length(Syms, P), append(Syms, [_, _, FirstS|More], Rest),
              atom_string(Lemma, LemS), lx_word(Lemma),
              atom_string(First, FirstS), get_assoc(First, ByOffset, s(LF, Inst, _, _)),
              ( More = [SecondS|_] -> atom_string(Second, SecondS) ; Second = none ),
              K = k(LF, Inst, First, Second) ),
            Pairs),
    list_to_assoc(Pairs, Kinds).

%% a data.noun line: offset lexfile n w_cnt(hex) word lexid ... p_cnt (sym offset pos st)... | gloss
lx_noun_synset(L, Offset, LF, Inst, Words, Hypos) :-
    split_string(L, [124], [], [BodyS|_]),
    split_string(BodyS, [32], [32], [OffS, LFS, _, WcntS|R1]),
    atom_string(Offset, OffS), catch(number_string(LF, LFS), _, fail),
    lx_hex(WcntS, Wcnt),
    lx_take_words(Wcnt, R1, Words, [PcntS|R3]),
    catch(number_string(Pcnt, PcntS), _, fail),
    lx_pointers(Pcnt, R3, Ptrs),
    ( memberchk('@i'-_, Ptrs) -> Inst = yes ; Inst = no ),
    findall(H, member('~'-H, Ptrs), Hypos).

lx_pointers(0, _, []) :- !.
lx_pointers(N, [SymS, OffS, _, _|R], [Sym-Off|Ps]) :-
    atom_string(Sym, SymS), atom_string(Off, OffS), N1 is N - 1, lx_pointers(N1, R, Ps).

%% ---- the units: everything under unit_of_measurement and time_unit ---------------------------
%% The synsets that carry those names are the roots, and every hyponym
%% below them (`~', never an instance) is a unit: euro under monetary_unit,
%% gram under metric_weight_unit, hour under time_unit. An assoc of the
%% offsets, so a lemma's first sense is looked up in it.

lx_units(Synsets, Units) :-
    assoc_to_list(Synsets, Pairs),
    findall(Off, ( member(Off-s(_, _, Ws, _), Pairs), ( memberchk(unit_of_measurement, Ws) ; memberchk(time_unit, Ws) ) ), Roots),
    empty_assoc(Seen0),
    lx_descend(Roots, Synsets, Seen0, Units).

lx_descend([], _, Seen, Seen).
lx_descend([Off|Offs], Synsets, Seen0, Seen) :-
    (   get_assoc(Off, Seen0, _)
    ->  lx_descend(Offs, Synsets, Seen0, Seen)
    ;   put_assoc(Off, Seen0, yes, Seen1),
        ( get_assoc(Off, Synsets, s(_, _, _, Hypos)) -> true ; Hypos = [] ),
        append(Hypos, Offs, Queue),
        lx_descend(Queue, Synsets, Seen1, Seen)
    ).

%% ---- the languages: everything under natural_language --------------------------------------
%% The synset named natural_language is the root and every hyponym below it
%% is a language or a family of them: English, Spanish, Romance, Germanic.
%% An assoc of the offsets, so a lemma's first TWO senses are looked up in
%% it -- Italian, German and Japanese name the people first and the
%% language second, English and Spanish the language first; a word whose
%% language sense is third (creole) is not a language's name, nor one
%% whose first sense is a thing (tongue, chin).

lx_languages(Synsets, Languages) :-
    assoc_to_list(Synsets, Pairs),
    findall(Off, ( member(Off-s(_, _, Ws, _), Pairs), memberchk(natural_language, Ws) ), Roots),
    empty_assoc(Seen0),
    lx_descend(Roots, Synsets, Seen0, Languages).

%% ---- data.verb: the frames each verb takes, over all its synsets -------------------------

lx_verb_frames(WN, Frames) :-
    lx_lines(WN, 'data.verb', Lines),
    findall(V-F,
            ( member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
              lx_synset(L, Words, Fs),
              member(W0, Words), downcase_atom(W0, V), lx_word(V),
              member(F, Fs) ),
            Pairs),
    msort(Pairs, Sorted),
    lx_group_frames(Sorted, [], Grouped),
    list_to_assoc(Grouped, Frames).

lx_group_frames([], Acc, Out) :- reverse(Acc, Out).
lx_group_frames([V-F|Rest], Acc, Out) :-
    lx_same_verb(V, Rest, Fs, Others),
    lx_group_frames(Others, [V-[F|Fs]|Acc], Out).
lx_same_verb(V, [V-F|R], [F|Fs], O) :- !, lx_same_verb(V, R, Fs, O).
lx_same_verb(_, R, [], R).

%% a data.verb line: offset lexfile v w_cnt(hex) word lexid ... p_cnt pointers... f_cnt (+ f_num w_num)... | gloss
lx_synset(L, Words, Frames) :-
    split_string(L, [124], [], [BodyS|_]),
    split_string(BodyS, [32], [32], Fields),
    Fields = [_, _, _, WcntS|R1],
    lx_hex(WcntS, Wcnt),
    lx_take_words(Wcnt, R1, Words, R2),
    R2 = [PcntS|R3], catch(number_string(Pcnt, PcntS), _, fail),
    Skip is 4 * Pcnt, length(Ptrs, Skip), append(Ptrs, R4, R3),
    R4 = [FcntS|R5], catch(number_string(Fcnt, FcntS), _, fail),
    lx_take_frames(Fcnt, R5, Frames).

lx_take_words(0, R, [], R) :- !.
lx_take_words(N, [WS, _|R], [W|Ws], Rest) :- atom_string(W, WS), N1 is N - 1, lx_take_words(N1, R, Ws, Rest).

lx_take_frames(0, _, []) :- !.
lx_take_frames(N, [_, FS, _|R], [F|Fs]) :- catch(number_string(F, FS), _, fail), N1 is N - 1, lx_take_frames(N1, R, Fs).

lx_hex(S, N) :- string_codes(S, Cs), lx_hex_codes(Cs, 0, N).
lx_hex_codes([], N, N).
lx_hex_codes([C|Cs], Acc, N) :-
    (   C >= 0'0, C =< 0'9 -> D is C - 0'0
    ;   C >= 0'a, C =< 0'f -> D is C - 0'a + 10
    ;   C >= 0'A, C =< 0'F -> D is C - 0'A + 10
    ),
    Acc1 is Acc * 16 + D, lx_hex_codes(Cs, Acc1, N).

%% ---- the classes, ranked --------------------------------------------------------------------

lx_classes(Groups, Kinds, Units, Languages, Frames, AdjLemmas, Classes) :-
    findall(W-C, member(g(W, 1, _, C), Groups), NounCounts0), list_to_assoc(NounCounts0, NounCounts),
    lx_ranked(Kinds, NounCounts, [5, 6, 13, 17, 20, 21], no, Nouns),
    lx_ranked(Kinds, NounCounts, [18], no, Kinds1),
    lx_ranked(Kinds, NounCounts, [15], yes, Places0),
    findall(P, ( member(W, Places0), lx_capitalised(W, P) ), Places),
    lx_ranked_under(Kinds, NounCounts, Units, UnitWords),
    lx_ranked_under2(Kinds, NounCounts, Languages, Languages0),
    findall(P, ( member(W, Languages0), lx_capitalised(W, P) ), LanguageWords),
    findall(NC-W, ( member(g(W, T, LF, C), Groups), memberchk(T, [3, 5]), memberchk(LF, [0, 1]), NC is -C ), Adj0),
    lx_rank(Adj0, Adjs),
    findall(NC-W, ( member(g(W, 4, _, C), Groups), NC is -C ), Adv0),
    lx_rank(Adv0, Advs),
    findall(NC-W, ( member(g(W, 2, _, C), Groups), NC is -C ), Verb0),
    lx_rank(Verb0, Counted),
    assoc_to_keys(Frames, AllVerbs),
    findall(V, ( member(V, AllVerbs), \+ memberchk(V, Counted) ), Uncounted),
    append(Counted, Uncounted, Verbs),
    findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), lx_meets(Fs, [8, 9, 10, 11]) ), VT),
    findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), lx_meets(Fs, [1, 2]) ), VI),
    findall(V, ( member(V, Verbs), lx_frames(V, Frames, Fs), lx_meets(Fs, [22, 4]) ), VPP),
    findall(NC-W, ( member(g(W, 1, _, C), Groups), NC is -C ), KN0), lx_rank_unique(KN0, KnownNouns),
    findall(NC-W, ( member(g(W, 2, _, C), Groups), NC is -C ), KV0), lx_rank_unique(KV0, KnownVerbs),
    findall(NC-W, ( member(g(W, T, _, C), Groups), memberchk(T, [3, 5]), NC is -C ), KA0), lx_rank_unique(KA0, KA1),
    lx_uncounted(AdjLemmas, KA1, KA2), append(KA1, KA2, KnownAdjs),
    findall(NC-W, ( member(g(W, 4, _, C), Groups), NC is -C ), KR0), lx_rank_unique(KR0, KnownAdvs),
    Classes = [noun-Nouns, class-Kinds1, adj-Adjs, vt-VT, vi-VI, vpp-VPP, adverb-Advs, place-Places, unit-UnitWords,
               language-LanguageWords,
               known_noun-KnownNouns, known_verb-KnownVerbs, known_adj-KnownAdjs, known_adverb-KnownAdvs].

%% the known_* classes: every SemCor-counted lemma of a part of speech,
%% whatever its sense or file, commonest first and each word once. Not the
%% generator's words -- the JUDGE's: library(reasoning/tagger) refuses a
%% tagging these contradict, and `death' put as a subject slipped through
%% while only the generator's concrete nouns were known.
%%
%% AND known_adj CARRIES EVERY ADJECTIVE THE DICTIONARY KNOWS, not only the
%% counted ones, which is lx_uncounted/3 below. cntlist.rev says how OFTEN a
%% corpus used a word; index.adj says whether WordNet knows it at all, and
%% for a table whose question is `is this word an adjective' the second is
%% the question. It cost a sentence: `registered' has three adjective senses
%% and no SemCor count, so it reached library(reasoning/tagger) at class
%% mask 0 -- the same code a word that is NOT an adjective gets -- and `She
%% is registered' came back tagged D and refused. 5 102 counted adjectives
%% become 16 352. The counted ones keep their order at the front, so nothing
%% a cap used to keep has moved.
%%
%% THE SAME GAP IS IN known_noun AND known_verb and is NOT closed here: the
%% indexes hold 50 436 nouns and 8 293 verbs past this file's word filter,
%% against 8 915 and 3 616 counted, and widening either moves what the JUDGE
%% refuses -- its rules are written in terms of what a word is known ONLY as.
%% The typology takes the rest from the every_* files instead (--every,
%% since reasoning 1.123.0), which the judge never reads.
%% One table at a time, each measured.
lx_rank_unique(NCWs, Words) :-
    findall(W-NC, member(NC-W, NCWs), WNCs), keysort(WNCs, ByWord),
    lx_best(ByWord, Best), keysort(Best, Ranked),
    findall(W, member(_-W, Ranked), Words).
lx_best([], []).
lx_best([W-NC|Rest], [NCb-W|Out]) :- lx_best_same(W, Rest, NC, NCb, Others), lx_best(Others, Out).
lx_best_same(W, [W-NC2|R], NC, NCb, O) :- !, ( NC2 < NC -> NC1 = NC2 ; NC1 = NC ), lx_best_same(W, R, NC1, NCb, O).
lx_best_same(_, R, NC, NC, R).

%% every lemma an index file names, under this file's word filter: the
%% first field of every line that does not begin with a space (the licence
%% header does).
lx_index_lemmas(WN, File, Lemmas) :-
    lx_lines(WN, File, Lines),
    findall(W, ( member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
                 split_string(L, [32], [32], [LemS|_]),
                 atom_string(W, LemS), lx_word(W) ), Ws),
    sort(Ws, Lemmas).

%% the lemmas of a list that the counted ranking does not already hold, in
%% hash order -- the order lx_ranked/5 puts uncounted nouns in, so a cap
%% takes a stable sample rather than an alphabetical one.
lx_uncounted(Lemmas, Counted, Rest) :-
    list_to_assoc([], E), lx_seen(Counted, E, Seen),
    findall(H-W, ( member(W, Lemmas), \+ get_assoc(W, Seen, _), lx_hash(W, H) ), Keyed),
    lx_rank(Keyed, Rest).
lx_seen([], A, A).
lx_seen([W|Ws], A0, A) :- ( get_assoc(W, A0, _) -> A1 = A0 ; put_assoc(W, A0, 1, A1) ), lx_seen(Ws, A1, A).

%% the nouns whose first sense sits in one of the files, instances wanted or
%% not: the SemCor-counted ones first, then the rest in hash order
lx_ranked(Kinds, Counts, Files, WantInstance, Words) :-
    assoc_to_list(Kinds, Pairs),
    findall(Key-W,
            ( member(W-k(LF, Inst, _, _), Pairs), memberchk(LF, Files), Inst == WantInstance,
              ( get_assoc(W, Counts, C) -> true ; C = 0 ),
              NC is -C, lx_hash(W, H), Key = NC-H ),
            Keyed),
    lx_rank(Keyed, Words).

%% the nouns whose first sense is one of the synsets given, no instance,
%% ranked the same way
lx_ranked_under(Kinds, Counts, Synsets, Words) :-
    assoc_to_list(Kinds, Pairs),
    findall(Key-W,
            ( member(W-k(_, no, First, _), Pairs), get_assoc(First, Synsets, _),
              ( get_assoc(W, Counts, C) -> true ; C = 0 ),
              NC is -C, lx_hash(W, H), Key = NC-H ),
            Keyed),
    lx_rank(Keyed, Words).

%% the same over a word's first OR second sense, instance or not: the
%% languages, whose names WordNet often gives to the people first -- so a
%% second sense counts only when the first is a person or a group
%% (noun.person 18, noun.group 14), which keeps Italian and German and
%% drops `tongue' and `chin', whose second senses are languages too
lx_ranked_under2(Kinds, Counts, Synsets, Words) :-
    assoc_to_list(Kinds, Pairs),
    findall(Key-W,
            ( member(W-k(LF, _, First, Second), Pairs),
              (   get_assoc(First, Synsets, _) -> true
              ;   get_assoc(Second, Synsets, _), memberchk(LF, [14, 18])      % the people first: not a chin, not a tongue
              ),
              ( get_assoc(W, Counts, C) -> true ; C = 0 ),
              NC is -C, lx_hash(W, H), Key = NC-H ),
            Keyed),
    lx_rank(Keyed, Words).

lx_rank(Keyed, Words) :- keysort(Keyed, Sorted), findall(W, member(_-W, Sorted), Words).

%% a fixed order for the words no corpus counted: not the alphabet
lx_hash(W, H) :- atom_codes(W, Cs), lx_hash_codes(Cs, 7, H).
lx_hash_codes([], H, H).
lx_hash_codes([C|Cs], Acc, H) :- Acc1 is (Acc * 131 + C) mod 1000003, lx_hash_codes(Cs, Acc1, H).

lx_frames(V, Frames, Fs) :- get_assoc(V, Frames, Fs).
lx_meets(Fs, Wanted) :- member(F, Fs), memberchk(F, Wanted), !.

lx_capitalised(W, P) :- atom_codes(W, [C|Cs]), U is C - 32, atom_codes(P, [U|Cs]).

lx_take(N, Xs, Taken) :- ( length(Taken, N), append(Taken, _, Xs) -> true ; Taken = Xs ).

%% ---- the example sentences: real prose, the grammar's opposite --------------------------------
%% Two to twenty words of letters, spaces, commas, apostrophes and hyphens,
%% capitalised and stopped, in hash order -- two, because a tagger never shown
%% a fragment reads `Boston, Mass.' as a fact.

lx_prose(WN, Prose) :-
    findall(S,
            ( member(F, ['data.noun', 'data.verb', 'data.adj', 'data.adv']),
              lx_lines(WN, F, Lines), member(L, Lines), \+ sub_string(L, 0, 1, _, ' '),
              split_string(L, [124], [], [_, GlossS|_]),
              split_string(GlossS, [34], [], Parts), lx_odd(Parts, Quoted),
              member(Q, Quoted), lx_sentence(Q, S) ),
            Prose0),
    sort(Prose0, Unique),
    findall(H-S, ( member(S, Unique), lx_hash(S, H) ), Keyed),
    keysort(Keyed, Sorted),
    findall(S, member(_-S, Sorted), Prose).

lx_odd([], []).
lx_odd([_], []) :- !.
lx_odd([_, Q|Rest], [Q|Qs]) :- lx_odd(Rest, Qs).

lx_sentence(QS, Sentence) :-
    split_string(QS, "", " ", [TS]), string_codes(TS, Cs),
    Cs = [C0|_], C0 >= 0'a, C0 =< 0'z,
    forall(member(C, Cs), ( C >= 0'a, C =< 0'z ; C >= 0'A, C =< 0'Z ; memberchk(C, [32, 44, 39, 45]) )),
    last(Cs, Last), Last >= 0'a, Last =< 0'z,
    findall(x, member(32, Cs), Spaces), length(Spaces, NSp), NSp >= 1, NSp =< 19,
    U0 is C0 - 32, Cs = [_|Rest], append([U0|Rest], [0'.], SCs),
    atom_codes(Sentence, SCs).

%% ---- the files ----------------------------------------------------------------------------------

lx_write(Out, Class, Words) :-
    atomic_list_concat([Out, '/', Class, '.txt'], Path),
    findall(Line, ( member(W, Words), atom_codes(W, Cs), append(Cs, [10], Line) ), Lines),
    append(Lines, Codes),
    write_file_from_codes(Path, Codes).
