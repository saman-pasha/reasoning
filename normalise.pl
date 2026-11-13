%% cocolog -- library(reasoning/normalise): the generator that teaches a text
%% normaliser, and the assembler that reads what it learns.
%%
%%     :- use_module(library(reasoning/normalise)).
%%
%% TIER 2, clauses only, and it needs nothing but library(reasoning/reason). The
%% network this feeds is NOT in here: this file is the part every later
%% number depends on, and the part that runs on a box with no torch.
%%
%% WHAT A NORMALISER IS, HERE. library(reasoning/reason) reads a controlled English
%% and refuses everything else, and the way to reach it from typed prose is
%% a network that says, for every token, WHAT IT IS -- the subject, the
%% relation, the object, or noise -- so that Prolog can rebuild the
%% sentence in the shapes the grammar reads. That network is a TAGGER, not
%% a writer: it never emits a word, it labels the ones it was given, so a
%% proper noun it has never seen is copied and never guessed, and a bad
%% label costs a refusal, never a malformed term.
%%
%% THE GRAMMAR IS THE DATA. No corpus of (prose, controlled English) exists,
%% and this file makes one from the grammar's own shapes: normalise_pair/2
%% builds a clean sentence WITH its gold tags -- the generator knows which
%% word is the subject as it puts it there -- and then applies NOISE
%% TRANSFORMS that carry the tags along: a filler phrase (tagged D, drop),
%% a hedge (`I think that', D), an adverb after the subject (D) or after an
%% intransitive verb (D), a prepositional adjunct (D), a relation written
%% as two words (R R, to be joined), an
%% emphatic `does' (D), two sentences joined by `and' (B, a boundary), and
%% a filler or a hedge right after that `and' (D) -- the position typed
%% prose puts them in and the generator did not, until `Priya is a baker
%% and, as far as I know, Priya is licensed' tagged the `and' as an object;
%% and a second fact about the SAME subject joined by `and', its subject
%% left out (`Priya is a baker and is licensed') or a pronoun (`and she is
%% licensed'). The assembler supplies the subject a break left out, and the
%% grammar resolves the pronoun: state carried from sentence to sentence.
%% Every transform is one the assembler can undo by dropping, joining or
%% splitting -- and none changes a word's FORM, because a tag cannot: a
%% plural, a passive, a pronoun are not in this set, and this header says
%% so rather than leaving it to be found.
%%
%% TWO KINDS OF NOISE ARE KEPT OUT ON PURPOSE, measured against the
%% grammar. A bare word after an indefinite object -- `owns a car too',
%% `owns a car now' -- is not refused but MISREAD, as the noun of the
%% phrase, so an adverb goes at the end only after an intransitive verb.
%% And a place is NEVER noise. After an intransitive verb -- `works in
%% Rome' -- it is the relation work_in, shape 9 with a phrasal verb, and
%% dropping it once taught the network to drop `lives in Lagos' too. After
%% an object -- `rents a flat in Rome' -- it is the third argument of
%% rent_in, shapes 23 to 26; while a transform dropped it there the network
%% dropped `rents a flat in Bristol' to `rents a flat'. So no transform
%% appends a preposition and a proper noun, and pp_extra's adjuncts are
%% lower-case throughout (`at home', never `on Monday'), because a
%% capitalised word after a preposition after an object is a place the
%% grammar reads.
%%
%% AND QUESTIONS ARE SHAPES TOO, twelve of the fifty-five: `Does Alice own
%% a car?', `Is Alice happy?', `May Alice use the server?', `Who owns a
%% car?', `What does Alice own?', `Where does Alice sleep?', `Does Alice pay
%% 500 euros?', `How much does Alice pay?', `How many euros does Alice
%% pay?', `How much is the rent?', `Why is Alice happy?', `Why does Alice
%% own a car?'. The tags are the statements' -- `who' is the
%% subject asked for, `what', `where', `how much' and `why' the object -- so the
%% assembler copies them where they stand, the text ends in `?', and the
%% grammar reads a goal with a variable there.
%%
%% AND QUANTITIES ARE EIGHT SHAPES: `Alice pays 500 euros', `Alice buys
%% two litres of milk', `Every tenant must pay 500 euros', `The rent is 500
%% euros' (the one definite subject the grammar reads), `Alice does not pay
%% 500 euros', and the three questions above. A number is a determiner to
%% the tagger -- T before the noun it counts, digits or the number words
%% (`twenty five', `a hundred'), the `of' of `two litres of milk' a K --
%% and the assembler copies it where it stands, so the grammar reads
%% quantity(500, euros). The nouns are units (lexicon/unit.txt, WordNet's
%% units of measurement and of time) and things, pluralised by the
%% inflector, because a plural is the form a number takes.
%%
%% AND A LESSON IS TEN SHAPES, WHOSE WORDS ARE A CORPUS. A language lesson
%% is written about WORDS -- `The feminine noun "casa" means "house"',
%% `"leche" is feminine', `"amigo" is a person', `"los" is the plural of
%% "el"', `Every noun that ends in "a" is feminine', `Every verb that ends
%% in "e" takes "n" in the plural', `The word "no" precedes the verb',
%% `Spanish is a language' -- and a word in quotation marks is MENTIONED:
%% it stands for itself, whatever it is. The tag for one is M, the
%% thirteenth, and it is the one tag that ADDS something when the
%% assembler undoes it: a token tagged M is written between quotation
%% marks, a run of them as one mention (`a el'), so `The noun casa means
%% house', typed as prose is typed, comes back as the lesson's own line.
%% No word of a lesson lives in this file: the mentioned words, the
%% classes said of them (noun, article, pronoun), the adjectives
%% (feminine), the forms (`the plural of', `the first person of'), the
%% relations (means, precedes, `takes ... in the plural') and the class
%% atoms (`the verb', `in the plural', `a vowel') are read out of the
%% lessons in library/reasoning/corpus/ -- one sentence a line, in the
%% controlled English itself -- by the shapes' own patterns
%% (normalise_lexicon/2 with mention, wclass, wadj, form, vq, vqin, vin,
%% vthe, wobj, wplace, wkind, wlang, ending, letter), and a lesson that
%% needs a word or a shape the corpus lacks gets a line there, not a word
%% here. The meanings and half the mentions are ordinary lexicon words
%% besides, because any English word can be mentioned. Two transforms
%% are theirs: `unquote', the marks taken off (at seven pairs in ten,
%% because that is how prose writes a word about a word, and the tagger
%% must read the quoted form too; at the HEAD of a sentence a bare word
%% is a name to the tagger and tagged S, because `Leche is feminine' and
%% `Mia is a nurse' are one shape and one term), and `in_language' -- `in Spanish' at
%% the end of a fact about a mention, or `In Spanish,' at the head, tagged
%% D, the grammar refusing the first because a sentence that mentions a
%% word names no place. Inside the apposition a language is an ADJECTIVE
%% kept (`The Spanish noun "casa"' is spanish(casa) besides, which is
%% true), because dropping it would have taught the network to drop an
%% adjective. What a tag still cannot do holds here too: `Nouns that end
%% in -a are feminine' changes three forms, and is not made.
%%
%% ---- THE SURFACE ------------------------------------------------------
%%
%%     normalise_pair(+Seed, -Pair)
%%     normalise_pair(+Seed, +Options, -Pair)
%%         Pair = pair(Noisy, Tokens, Tags, Clean, Applied): the noisy text;
%%         its tokens as reason_tokens/2 gives them, the final stop dropped;
%%         one tag a token; the controlled text the noise was made from; and
%%         the names of the transforms that applied. Deterministic in Seed.
%%         Options: transforms(Names) restricts the candidates, so
%%         transforms([]) is a clean pair; always(true) applies every
%%         candidate that fits, where the default is a coin a transform.
%%
%%     normalise_corpus(+N, -Pairs)
%%     normalise_corpus(+N, +Options, -Pairs)          seeds 1..N
%%
%%     normalise_save(+Pairs, +File)
%%     normalise_load(+File, -Pairs)
%%         The pairs as DATA: one canonical pair(...) term a line, written
%%         with writeq/1 and read back with term_to_atom/2, so what a
%%         tagger trained on is a file in the tree and not a seed somebody
%%         has to re-run the generator for. library/reasoning/generate.pl
%%         writes the shipped model's corpus to
%%         library/reasoning/generated/, and tagger_train/2's pairs_file(F)
%%         trains on it; the pair is the same term normalise_pair/2 gives.
%%     normalise_generated_dir(-Dir)
%%         Where generate.pl writes: $COCOLOG_GENERATED, or
%%         `reasoning/generated' under the first library directory that has
%%         a `reasoning', made when it is missing.
%%
%%     normalise_negatives(+From, +N, -Pairs)
%%         N real sentences from prose.txt beside the lexicon -- WordNet's own
%%         example sentences, in a fixed hash order -- from the From-th, as
%%         pairs whose every tag is X and whose Clean is `none': what a
%%         tagger must REFUSE, and what tagger_refused/4 measures it
%%         against. A seventh of them the grammar reads as they are, nearly
%%         all two words -- `Vulpine cunning.' as the Name-verb fact
%%         cunning(vulpine) -- which is why a tagging is judged by the
%%         lexicon and not by the grammar alone.
%%
%%     normalise_assemble(+Tokens, +Tags, -Text)
%%         The inverse: D dropped, a run of R joined with `_', B a sentence
%%         break -- and a sentence the break leaves with no subject (no S,
%%         and no M before its relation) takes the subject phrase of the
%%         one before it -- a run of M written as ONE mention between
%%         quotation marks, a quoted token as itself, everything else
%%         copied in its case; each sentence capitalised and stopped. What
%%         the tagger's output is handed to, and what the round trip below
%%         holds the tags to.
%%
%%     normalise_bare(+Text, -Bare)
%%         The text with its mentions written bare -- `The noun "casa" means
%%         "house".' as `The noun casa means house.' -- the way prose writes
%%         a word about a word, and what tagger_lessons/4 puts to the
%%         tagger; a mention that would not survive as words (`"¿"', a
%%         sign the tokeniser drops) keeps its marks, and so does one at
%%         the head of a sentence that could not stand as a subject: a
%%         closed word, or a word the lexicon knows as a common word.
%%
%%     normalise_head_bare(+Word)
%%         Whether a bare word can stand at the head of a sentence as its
%%         subject: one word, not closed, and a name or a word the lexicon
%%         does not know as a common word. The unquote transform writes a
%%         head mention bare and tagged S exactly when this holds, and
%%         library(reasoning/tagger) applies the same rule to what the
%%         network answers, so a head is never a coin.
%%
%%     normalise_lessons(-Lines)
%%         Every line of every .txt file in the corpus directory, in file
%%         and line order, comments and blank lines dropped: the lessons the
%%         shapes' words come from.
%%     normalise_corpus_dir(-Dir)                      where they were found
%%
%%     normalise_third(+Base, -ThirdPerson)             the inflector, which
%%                                                     library(reasoning/reason)'s stemmer must invert
%%     normalise_tags(-Tags)                           the alphabet, closed
%%     normalise_transforms(-Names)                    the transforms, by name
%%     normalise_lexicon(+Class, -Words)               proper, noun, class, adj, vt, vi, vpp,
%%                                                     adverb, place, unit, language -- the files
%%                                                     beside this one, filtered by the grammar;
%%                                                     modal, the grammar's own; and the corpus
%%                                                     classes read out of the lessons: mention,
%%                                                     wclass, wadj, form, vq, vqin, vin, vthe,
%%                                                     wobj, wplace, wkind, wlang, ending, letter
%%     normalise_lexicon_dir(-Dir)                     where the files were found
%%
%% ---- THE TAGS ---------------------------------------------------------
%%
%%     S  the subject head      Q  a quantifier (every)      C  the condition's adjective
%%     R  a relation word       K  a structural word kept as it is: `that', `does',
%%                                 the copula inside a relative clause
%%     N  not                   T  a determiner               A  an adjective -- and the class
%%                                                              noun of an apposition, `the NOUN "casa"'
%%     O  the object head       D  drop                       B  a sentence boundary
%%     M  a MENTIONED word, written between quotation marks: the subject or
%%        the object of a lesson's sentence, the letter a rule is over
%%     X  OUTSIDE: not a sentence of the grammar's at all -- the tag a tagger
%%        gives real prose it cannot normalise, and the assembler refuses
%%
%% Only D, R, B and M change what the assembler emits; the rest are copied,
%% and X is refused. The generator never emits X: a tagging comes back X
%% throughout when library(reasoning/tagger)'s lexicon rules contradict it,
%% and normalise_negatives/3 hands out real sentences tagged X throughout to
%% measure that against. Without a no the first tagger labelled `Boston,
%% Mass.' S R and the grammar read mass(boston); taught to the network as a
%% twelfth label it cost a tenth of what the tagger should read, so the no
%% is the lexicon's.
%% They are still worth teaching: a network told WHAT each kept word is
%% learns the sentence's shape, not only which words to lose, and an
%% assembler that one day reorders (a passive) will need them.
%%
%% ---- THE ROUND TRIP IS THE CONTRACT -----------------------------------
%%
%% For every pair: assemble the noisy tokens with their GOLD tags, parse
%% the result with reason_text/2, and it must give the same terms as the
%% clean text -- up to the names of a rule's variables. test/normalise.pl
%% holds 300 pairs to it. That is the proof that the tag scheme carries
%% enough to recover the sentence, which is the only thing that makes it a
%% possible target for a network; and the proof that every noisy text is
%% REFUSED by the grammar is what makes the noise noise.
%%
%% ---- WHAT THE NETWORK WILL AND WILL NOT LEARN ----------------------------
%%
%% It learns to undo the transforms written here. Prose has more, and the
%% grammar refuses what the tagger gets wrong -- so the cost of the gap is
%% refusals, measured by the acceptance rate on real text, and the next
%% transform to write is whichever refusal is commonest. And a well-formed
%% WRONG sentence is possible: swap S and O and `Rome owns a house' parses.
%% The grammar guarantees form; tag accuracy is the correctness number.
%%
%% THE NOISE IS DETERMINISTIC IN THE SEED, the way the tensor lessons draw
%% their data: a hash of the seed and a salt, not a random number, so a
%% corpus is reproducible and a failing pair can be named by its seed.

:- use_module(library(reasoning/reason)).

%% ---- the alphabet, the transforms, the lexicon ---------------------------

normalise_tags(['S', 'Q', 'C', 'N', 'R', 'K', 'T', 'A', 'O', 'D', 'B', 'X', 'M']).

%% in the order they are applied: the split before the emphatic (so a
%% split relation is not also a candidate for `does'), the join before the
%% fillers (so a filler or a hedge wraps the whole; filler_join conjoins
%% itself when nothing has, and puts its filler after the `and'), the tails
%% last -- an adverb after an intransitive verb, a prepositional adjunct
%% after anything, a language after a fact about a word -- and the
%% quotation marks taken off a mention after everything else, so a
%% conjoined lesson sentence loses its marks too
normalise_transforms([split_relation, emphatic_do, conjoin, conjoin_shared, filler_join, adverb, hedge_start, filler_start,
                      filler_end, adverb_end, pp_extra, in_language, unquote]).

%% ---- the lexicon: files beside this one, read when first asked for ---------
%%
%% library/reasoning/lexicon/<class>.txt, one word a line, commonest first:
%% `proper' is the US Census's first names; noun, class, adj, vt, vi, vpp,
%% adverb, place and unit are WordNet 3.0 ranked by its SemCor tag counts,
%% and prose is WordNet's example sentences, real English, for
%% normalise_negatives/3 --
%% written by library/reasoning/lexicon/build.pl (cocolog, not Python:
%% the parse of WordNet's files is a DCG's job). SOURCES.md beside them says where each
%% came from and under what licence. NO WORD LIVES IN THIS FILE.
%%
%% The files are read the first time a word is asked for, held as globals
%% of this machine -- never asserted, so a knowledge base is never written
%% -- and FILTERED BY THE GRAMMAR as they load: a word library(reasoning/reason)
%% treats as closed is dropped (`will' is a modal before it is a name), and
%% a verb whose third person does not come back to it through the stemmer
%% is dropped, so the inflection round trip holds by construction. Modals
%% are the grammar's own, asked of rl_modal/1. $COCOLOG_LEXICON names
%% another directory; otherwise it is `reasoning/lexicon' under the first
%% library directory that has one -- $COCOLOG_LIBRARY, ./library, the
%% binary's own.

normalise_lexicon_dir(Dir) :-
    getenv('COCOLOG_LEXICON', Dir), Dir \== '', exists_directory(Dir), !.
normalise_lexicon_dir(Dir) :-
    ng_library_dirs(Ds), member(D, Ds),
    atom_concat(D, '/reasoning/lexicon', Dir), exists_directory(Dir), !.

ng_library_dirs(Ds) :-
    (   getenv('COCOLOG_LIBRARY', Env), Env \== ''
    ->  atomic_list_concat(Env0, ':', Env)
    ;   Env0 = []
    ),
    (   current_prolog_flag(executable, Exe),
        atomic_list_concat(Parts, '/', Exe), append(DirParts, [_], Parts), DirParts \== []
    ->  atomic_list_concat(DirParts, '/', ExeDir), atom_concat(ExeDir, '/library', ExeLib), Extra = [ExeLib]
    ;   Extra = []
    ),
    append(Env0, [library|Extra], Ds1),
    findall(D, ( member(D, Ds1), D \== '' ), Ds).

ng_class(proper). ng_class(noun). ng_class(class). ng_class(adj). ng_class(vt).
ng_class(vi). ng_class(vpp). ng_class(adverb). ng_class(place). ng_class(unit). ng_class(language). ng_class(prose).
ng_class(known_noun). ng_class(known_verb). ng_class(known_adj). ng_class(known_adverb).   % the judge's, not the generator's

normalise_lexicon(modal, Ms) :- !, findall(M, rl_modal(M), Ms).
normalise_lexicon(Class, Words) :-
    ng_corpus_class(Class), !, ng_ensure_corpus, ng_key(list, Class, K), nb_getval(K, Words).
normalise_lexicon(Class, Words) :-
    ng_class(Class), ng_ensure_lexicon, ng_key(list, Class, K), nb_getval(K, Words).

ng_ensure_lexicon :- catch(nb_getval('$lx_ready', yes), _, fail), !.
ng_ensure_lexicon :-
    (   normalise_lexicon_dir(Dir)
    ->  true
    ;   throw(error(existence_error(directory, 'reasoning/lexicon'), normalise_lexicon/2))
    ),
    forall(ng_class(Class), ng_load_class(Dir, Class)),
    nb_setval('$lx_ready', yes).

ng_load_class(Dir, Class) :-
    atomic_list_concat([Dir, '/', Class, '.txt'], Path),
    (   exists_file(Path)
    ->  true
    ;   throw(error(existence_error(source_sink, Path), normalise_lexicon/2))
    ),
    read_file_to_codes(Path, Codes),
    split_string(Codes, [10], [32, 13, 9], Lines),
    findall(W, ( member(L, Lines), string_length(L, Len), Len > 0,
                 \+ sub_string(L, 0, 1, _, '#'),
                 atom_string(W, L), ng_keep(Class, W) ), Words),
    ng_store_class(Class, Words).

ng_store_class(Class, Words) :-
    length(Words, N),
    ng_key(size, Class, KS), nb_setval(KS, N),
    ng_key(list, Class, KL), nb_setval(KL, Words),
    ng_blocks(Words, Class, 0).

%% what the grammar will not read as an open word is not generated; a line
%% of prose is kept as it is
ng_keep(prose, _) :- !.
ng_keep(Class, W) :- ng_known(Class), !, downcase_atom(W, Lower), \+ rl_closed(Lower).   % known to the judge: no round trip asked
ng_keep(Class, W) :-
    downcase_atom(W, Lower), \+ rl_closed(Lower),
    (   memberchk(Class, [vt, vi, vpp])
    ->  normalise_third(W, Third), rs_base(Third, W)
    ;   true
    ).

%% blocks of a hundred, one global each, so a pick copies a hundred cells
%% and not the class
ng_blocks([], _, _) :- !.
ng_blocks(Words, Class, B) :-
    (   length(Chunk, 100), append(Chunk, Rest, Words) -> true ; Chunk = Words, Rest = [] ),
    T =.. [w|Chunk], ng_key(B, Class, K), nb_setval(K, T),
    B1 is B + 1, ng_blocks(Rest, Class, B1).

ng_key(Tag, Class, Key) :- atomic_list_concat(['$lx_', Tag, '_', Class], Key).

ng_size(Class, N) :-
    ( ng_corpus_class(Class) -> ng_ensure_corpus ; ng_ensure_lexicon ),
    ng_key(size, Class, K), nb_getval(K, N).

%% ---- the corpus: the lessons beside the lexicon, read when first asked for ---
%%
%% library/reasoning/corpus/*.txt, one sentence a line in the controlled
%% English, a line beginning # a comment (its README says what is there).
%% Read once a machine, like the lexicon, and held the same way; and the
%% words a lesson shape needs are taken out of the lines by PATTERN, over
%% the tokens: a quoted word is a mention; `the [ADJ..] CLASS "w"' and
%% `"w" is a [ADJ..] CLASS' give the classes and the adjectives said of a
%% word; `"w" is ADJ' an adjective; `the [ADJ..] FORM of "v"' a form (a
%% list, `[first, person]'); a third-person verb is a relation, kept by
%% what follows it -- a mention (means), a mention then `in the' (takes),
%% a preposition (ends), `the' (precedes) -- and the words after those
%% are the class atoms: `precedes the VERB', `in the PLURAL', `in a VOWEL',
%% `Spanish is a LANGUAGE'; the mention after `takes' is an ending and
%% the one after `in' a letter. $COCOLOG_CORPUS names another directory;
%% otherwise it is `reasoning/corpus' under the first library directory
%% that has one, as the lexicon is found.

normalise_corpus_dir(Dir) :-
    getenv('COCOLOG_CORPUS', Dir), Dir \== '', exists_directory(Dir), !.
normalise_corpus_dir(Dir) :-
    ng_library_dirs(Ds), member(D, Ds),
    atom_concat(D, '/reasoning/corpus', Dir), exists_directory(Dir), !.

normalise_lessons(Lines) :- ng_ensure_corpus, nb_getval('$lx_lessons', Lines).

ng_corpus_class(mention). ng_corpus_class(wclass). ng_corpus_class(wadj).  ng_corpus_class(form).
ng_corpus_class(vq).      ng_corpus_class(vqin).   ng_corpus_class(vin).   ng_corpus_class(vthe).
ng_corpus_class(wobj).    ng_corpus_class(wplace). ng_corpus_class(wkind). ng_corpus_class(wlang).
ng_corpus_class(ending).  ng_corpus_class(letter). ng_corpus_class(wverb).

ng_ensure_corpus :- catch(nb_getval('$lx_corpus', yes), _, fail), !.
ng_ensure_corpus :-
    (   normalise_corpus_dir(Dir)
    ->  true
    ;   throw(error(existence_error(directory, 'reasoning/corpus'), normalise_lessons/1))
    ),
    directory_files(Dir, Fs0), msort(Fs0, Fs),
    findall(Line, ( member(F, Fs), sub_atom(F, _, 4, 0, '.txt'),
                    atomic_list_concat([Dir, '/', F], Path),
                    read_file_to_codes(Path, Codes),
                    split_string(Codes, [10], [32, 13, 9], Ls),
                    member(L, Ls), string_length(L, Len), Len > 0,
                    \+ sub_string(L, 0, 1, _, '#'),
                    atom_string(Line, L) ),
            Lines),
    nb_setval('$lx_lessons', Lines),
    findall(Toks, ( member(L, Lines), reason_tokens(L, Toks0),
                    ( append(Toks, ['.'], Toks0) -> true ; Toks = Toks0 ) ),
            Sents),
    forall(ng_corpus_class(Class),
           ( findall(W, ( member(Ts, Sents), ng_corpus_word(Class, Ts, W) ), Ws0),
             ng_unique(Ws0, Ws), ng_store_class(Class, Ws) )),
    nb_setval('$lx_corpus', yes).

ng_unique([], []).
ng_unique([W|Ws], [W|Us]) :- \+ memberchk(W, Ws), !, ng_unique(Ws, Us).
ng_unique([_|Ws], Us) :- ng_unique(Ws, Us).

%% one word of a class, by pattern, from one sentence's tokens
ng_corpus_word(mention, Ts, W) :- member(quoted(W), Ts).
ng_corpus_word(wclass, Ts, C) :- ng_class_run(Ts, Run), last(Run, C).
ng_corpus_word(wadj, Ts, A) :- ng_class_run(Ts, Run), append(Adjs, [_], Run), member(A, Adjs).
ng_corpus_word(wadj, Ts, A) :- append(_, [quoted(_), word(C, _), word(A, _)], Ts), rl_copula(C), \+ rl_closed(A).
ng_corpus_word(form, Ts, Run) :- ng_det_run(Ts, def, Run, [word(of, _), quoted(_)|_]).
ng_corpus_word(vq, Ts, V) :- append(_, [word(V, _), quoted(_)], Ts), ng_third(V).
ng_corpus_word(vqin, Ts, V) :- append(_, [word(V, _), quoted(_), word(P, _), word(the, _)|_], Ts), rl_preposition(P), ng_third(V).
ng_corpus_word(vin, Ts, V-P) :- append(_, [word(V, _), word(P, _)|_], Ts), rl_preposition(P), ng_third(V).
ng_corpus_word(vthe, Ts, V) :- append(_, [word(V, _), word(the, _)|_], Ts), ng_third(V).
ng_corpus_word(wobj, Ts, N) :- append(_, [word(V, _), word(the, _), word(N, _)], Ts), ng_third(V), \+ rl_closed(N).
ng_corpus_word(wplace, Ts, P-N) :- append(_, [word(P, _), word(the, _), word(N, _)], Ts), rl_preposition(P), \+ rl_closed(N).
ng_corpus_word(wkind, Ts, N) :- append(_, [word(P, _), word(A, _), word(N, _)|_], Ts), rl_preposition(P), rl_det(A, indef), \+ rl_closed(N).
ng_corpus_word(wlang, Ts, N) :- Ts = [word(_, upper), word(C, _), word(A, _), word(N, _)], rl_copula(C), rl_det(A, indef), \+ rl_closed(N).
ng_corpus_word(ending, Ts, E) :- append(_, [quoted(E), word(P, _), word(the, _)|_], Ts), rl_preposition(P).
ng_corpus_word(letter, Ts, L) :-                                             % after a verb's preposition: `ends in "a"', not `of "el"'
    append(Pre, [word(P, _), quoted(L)|_], Ts), rl_preposition(P),
    ( append(_, [word(V, _)], Pre), ng_third(V) ; append(_, [word(not, _), word(_, _)], Pre) ).
ng_corpus_word(wverb, Ts, W) :- member(word(V, _), Ts), ng_third(V), ( W = V ; rs_base(V, W) ).   % the judge's: both forms

%% the words said OF a mention: `the [ADJ..] CLASS "w"', or `"w" is a
%% [ADJ..] CLASS' -- and not the class atom a relation ends in (`begins
%% the question'), because question/1 is the reader's own wrapper and a
%% class named `question' would read as one
ng_class_run(Ts, Run) :- ng_det_run(Ts, _, Run, [quoted(_)|_]).
ng_class_run([quoted(_), word(C, _), word(D, _)|Rest], Run) :- rl_copula(C), rl_det(D, indef), ng_open_run(Rest, Run, []), Run \== [].

%% `the [ADJ..] NOUN' not after a preposition: the run of open words after
%% the determiner, and what follows the run
ng_det_run(Ts, Kind, Run, After) :-
    append(Pre, [word(D, _)|Rest], Ts), rl_det(D, Kind),
    \+ ( last(Pre, word(P, _)), rl_preposition(P) ),
    ng_open_run(Rest, Run, After), Run \== [].
ng_open_run([word(W, _)|Ts], [W|Ws], After) :- \+ rl_closed(W), !, ng_open_run(Ts, Ws, After).
ng_open_run(Ts, [], Ts).

%% a third-person verb: not closed, and the stemmer takes it somewhere
ng_third(V) :- \+ rl_closed(V), rs_base(V, B), B \== V.
ng_nth(Class, K, W) :-
    B is K // 100, I is K mod 100 + 1,
    ng_key(B, Class, Key), nb_getval(Key, T), arg(I, T, W).

%% ---- the inflector ---------------------------------------------------------
%% Third person singular, library(reasoning/reason)'s reason_third/2: it
%% lives beside the stemmer it inverts, rs_base/2, and the two are changed
%% together -- -es after ss, sh, ch, x, z, o; -ies for a consonant and y;
%% -s otherwise; `has' by name. A
%% regular PLURAL is the same three rules (euro -> euros, inch -> inches,
%% penny -> pennies), so ng_plural/2 is this inflector; an irregular one
%% (foot, child) comes out wrong and does no harm, since the grammar takes
%% a noun as written and the tagger learns the shape, not the word.

normalise_third(B, T) :- reason_third(B, T).

ng_plural(N, P) :- normalise_third(N, P).

%% ---- deterministic noise -----------------------------------------------------

ng_noise(I, R) :- S is sin(I * 12.9898) * 43758.5453, R is S - truncate(S).
ng_pick(Seed, Salt, N, K) :- J is Seed * 7 + Salt, ng_noise(J, R), K is truncate(abs(R) * N).
ng_choose(Seed, Salt, List, X) :- length(List, N), ng_pick(Seed, Salt, N, K), nth0(K, List, X).
ng_coin(Seed, Salt, PercentYes) :- ng_pick(Seed, Salt, 100, K), K < PercentYes.

ng_word(vpp, Seed, Salt, V-Prep) :- !,
    ng_size(vpp, N), ng_pick(Seed, Salt, N, K), ng_nth(vpp, K, V),
    Salt2 is Salt + 70, ng_choose(Seed, Salt2, [in, at, to, with, for, from, on], Prep).
ng_word(modal, Seed, Salt, M) :- !, normalise_lexicon(modal, Ms), ng_choose(Seed, Salt, Ms, M).
ng_word(Class, Seed, Salt, W) :-
    ng_size(Class, N),
    (   N > 0 -> true
    ;   throw(error(existence_error(words, Class), context(normalise_pair/2, 'no line of the corpus gives one: see library/reasoning/corpus/README.md')))
    ),
    ng_pick(Seed, Salt, N, K), ng_nth(Class, K, W).
ng_word2(Class, Seed, Salt, W1, W2) :-
    ng_size(Class, N), ng_pick(Seed, Salt, N, K1),
    Salt2 is Salt + 50, ng_pick(Seed, Salt2, N, K2a),
    ( K2a =:= K1 -> K2 is (K1 + 1) mod N ; K2 = K2a ),
    ng_nth(Class, K1, W1), ng_nth(Class, K2, W2).

ng_art(W, an) :- atom_codes(W, [C|_]), memberchk(C, [0'a, 0'e, 0'i, 0'o, 0'u]), !.
ng_art(_, a).

%% the words of a lesson shape: a MENTION is a word of the corpus two
%% times in three and any lexicon word otherwise (a name lower-cased),
%% because any word can be mentioned; a MEANING is a lexicon word three
%% times in five; an adjective said of a word is the corpus's (feminine)
%% three times in five and the lexicon's otherwise; and the letter a rule
%% is over is a class atom (`a vowel') a third of the time, else one of
%% the corpus's letters or any of the alphabet
ng_mention(Seed, Salt, W) :-
    S1 is Salt + 60, S2 is Salt + 61,
    (   ng_coin(Seed, Salt, 65)
    ->  ng_word(mention, Seed, S1, W)
    ;   ng_choose(Seed, S1, [noun, adj, vt, proper], Class), ng_word(Class, Seed, S2, W0), downcase_atom(W0, W)
    ).
ng_mention2(Seed, Salt, W1, W2) :- ng_word2(mention, Seed, Salt, W1, W2).
ng_meaning(Seed, Salt, E) :-
    S1 is Salt + 62, S2 is Salt + 63,
    (   ng_coin(Seed, Salt, 60)
    ->  ng_choose(Seed, S1, [noun, adj, vt, vi, adverb], Class), ng_word(Class, Seed, S2, E0), downcase_atom(E0, E)
    ;   ng_word(mention, Seed, S1, E)
    ).
ng_wadj(Seed, Salt, A) :-
    S1 is Salt + 64,
    ( ng_coin(Seed, Salt, 60) -> ng_word(wadj, Seed, S1, A) ; ng_word(adj, Seed, S1, A) ).
ng_ending_phrase(Seed, Salt, End) :-
    S1 is Salt + 1, S2 is Salt + 2,
    (   ng_coin(Seed, Salt, 35) -> ng_word(wkind, Seed, S1, K), ng_art(K, Art), End = [Art-'T', K-'O']
    ;   ng_coin(Seed, S1, 50) -> ng_word(letter, Seed, S2, L), End = [q(L)-'M']
    ;   ng_pick(Seed, S2, 26, K0), C is 97 + K0, atom_codes(L, [C]), End = [q(L)-'M']
    ).
%% `the [LANGUAGE] [ADJ] CLASS "w"': the apposition, the language an
%% adjective one time in four and an adjective of the word's one in three
ng_apposition(Seed, Salt, [the-'T'|Rest]) :-
    S1 is Salt + 1, S2 is Salt + 2, S3 is Salt + 3, S4 is Salt + 4, S5 is Salt + 5,
    ng_word(wclass, Seed, Salt, C), ng_mention(Seed, S1, W),
    ( ng_coin(Seed, S2, 25) -> ng_word(language, Seed, S3, L), Lang = [L-'A'] ; Lang = [] ),
    ( ng_coin(Seed, S4, 30) -> ng_wadj(Seed, S5, A), Adj = [A-'A'] ; Adj = [] ),
    append([Lang, Adj, [C-'A', q(W)-'M']], Rest).
%% a form as pairs: `[first, person]' is first-A person-O
ng_form_pairs(Run, Pairs) :- append(Adjs, [N], Run), findall(A-'A', member(A, Adjs), As), append(As, [N-'O'], Pairs).

%% ---- the shapes: a clean sentence as Word-Tag pairs ----------------------------
%% Proper nouns are emitted capitalised, everything else lower; the text
%% builder capitalises a sentence's first word.

ng_sentence(Seed, Pairs) :- ng_pick(Seed, 1, 55, K), ng_shape(K, Seed, Pairs), !.

ng_known(known_noun). ng_known(known_verb). ng_known(known_adj). ng_known(known_adverb).

%% a statement: a question when the seed gives one is passed over, for the
%% second half of a conjunction
ng_statement(Seed, Qs) :- ng_statement(Seed, 0, Qs).
ng_statement(Seed, K, Qs) :-
    K < 8, S2 is Seed + K, ng_sentence(S2, Qs0),
    ( ng_question(Qs0) -> K1 is K + 1, ng_statement(Seed, K1, Qs) ; Qs = Qs0 ), !.
ng_statement(Seed, _, Qs) :- S2 is Seed + 8, ng_shape(5, S2, Qs).

%% a question is known by its first word, as the grammar knows it
ng_question([W-_|_]) :- ( W == does ; W == is ; rl_question(W) ; rl_modal(W) ), !.

ng_shape(0, Seed, [P-'S', V3-'R'|Obj]) :-                                  % Alice owns a red car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_object(Seed, 4, Obj).
ng_shape(1, Seed, [P-'S', is-'R', A-'A']) :-                               % Alice is happy
    ng_word(proper, Seed, 2, P), ng_word(adj, Seed, 3, A).
ng_shape(2, Seed, [P-'S', is-'R', Art-'T', N-'O']) :-                      % Alice is a tenant
    ng_word(proper, Seed, 2, P), ng_word(class, Seed, 3, N), ng_art(N, Art).
ng_shape(3, Seed, [P-'S', is-'R', not-'N', A-'A']) :-                      % Alice is not happy
    ng_word(proper, Seed, 2, P), ng_word(adj, Seed, 3, A).
ng_shape(4, Seed, [P-'S', does-'K', not-'N', V-'R'|Obj]) :-                % Alice does not own a red car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_word(noun, Seed, 4, N), ng_np(Seed, 12, N, Obj).
ng_shape(5, Seed, [P-'S', V3-'R']) :-                                      % Alice sleeps
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V), normalise_third(V, V3).
ng_shape(6, Seed, [P-'S', M-'R', V-'R'|Obj]) :-                            % Alice may use the old server
    ng_word(proper, Seed, 2, P), ng_word(modal, Seed, 3, M), ng_word(vt, Seed, 4, V), ng_word(noun, Seed, 5, N),
    ng_np_the(Seed, 12, N, Obj).
ng_shape(7, Seed, [every-'Q', C-'S', is-'R', Art-'T', N-'O']) :-           % Every tenant is a person
    ng_word2(class, Seed, 2, C, N), ng_art(N, Art).
ng_shape(8, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-            % Every tenant that is not exempt must pay the full rent
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(modal, Seed, 4, M),
    ng_word(vt, Seed, 5, V), ng_word(noun, Seed, 6, N), ng_np_the(Seed, 12, N, Obj),
    (   ng_coin(Seed, 7, 50)
    ->  Rest = [not-'N', A-'C', M-'R', V-'R'|Obj]
    ;   Rest = [A-'C', M-'R', V-'R'|Obj]
    ).
ng_shape(9, Seed, [P-'S', VJ-'R', Q-'O']) :-                               % Alice lives_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vpp, Seed, 3, V-Prep), normalise_third(V, V3),
    atomic_list_concat([V3, '_', Prep], VJ),
    ( ng_coin(Seed, 4, 50) -> ng_word(place, Seed, 5, Q) ; ng_word(proper, Seed, 5, Q) ).
ng_shape(10, Seed, [P-'S', V3-'R', Q-'O']) :-                              % Alice likes Bob
    ng_word2(proper, Seed, 2, P, Q), ng_word(vt, Seed, 3, V), normalise_third(V, V3).
ng_shape(11, Seed, [every-'Q', C-'S', is-'R', A-'A']) :-                   % Every tenant is exempt
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A).
ng_shape(12, Seed, [P-'S', is-'R', not-'N', Art-'T', N-'O']) :-            % Alice is not a tenant
    ng_word(proper, Seed, 2, P), ng_word(class, Seed, 3, N), ng_art(N, Art).
ng_shape(13, Seed, [P-'S', does-'K', not-'N', V-'R']) :-                   % Alice does not sleep
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V).
ng_shape(14, Seed, [every-'Q', C-'S', V3-'R'|Obj]) :-                      % Every employee has a blue badge
    ng_word(class, Seed, 2, C), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_np(Seed, 12, N, Obj).
ng_shape(15, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every tenant that is insured owns a red car
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(vt, Seed, 4, V), normalise_third(V, V3),
    ng_word(noun, Seed, 5, N), ng_np(Seed, 12, N, Obj),
    (   ng_coin(Seed, 6, 50)
    ->  Rest = [not-'N', A-'C', V3-'R'|Obj]
    ;   Rest = [A-'C', V3-'R'|Obj]
    ).
ng_shape(16, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every tenant that is not banned is a member
    ng_word2(class, Seed, 2, C, N), ng_word(adj, Seed, 3, A), ng_art(N, Art),
    (   ng_coin(Seed, 4, 50)
    ->  Rest = [not-'N', A-'C', is-'R', Art-'T', N-'O']
    ;   Rest = [A-'C', is-'R', Art-'T', N-'O']
    ).
ng_shape(17, Seed, [P-'S', does-'K', not-'N', VJ-'R', Q-'O']) :-           % Alice does not live_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vpp, Seed, 3, V-Prep),
    atomic_list_concat([V, '_', Prep], VJ),
    ( ng_coin(Seed, 4, 50) -> ng_word(place, Seed, 5, Q) ; ng_word(proper, Seed, 5, Q) ).
ng_shape(18, Seed, [P-'S', V3-'R', the-'T'|Obj]) :-                        % Alice owns the old car
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_adjectives(Seed, 4, As), ng_word(noun, Seed, 7, N), append(As, [N-'O'], Obj).
ng_shape(19, Seed, [P-'S', VJ-'R', Q-'O']) :-                              % Alice sleeps_in Rome
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V), normalise_third(V, V3),
    ng_choose(Seed, 4, [in, at, near], Prep), atomic_list_concat([V3, '_', Prep], VJ),
    ng_word(place, Seed, 5, Q).

ng_shape(20, Seed, [every-'Q', C-'S', V3-'R']) :-                          % Every baker works
    ng_word(class, Seed, 2, C), ng_word(vi, Seed, 3, V), normalise_third(V, V3).
ng_shape(21, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every baker that is not lazy works
    ng_word(class, Seed, 2, C), ng_word(adj, Seed, 3, A), ng_word(vi, Seed, 4, V), normalise_third(V, V3),
    (   ng_coin(Seed, 5, 50)
    ->  Rest = [not-'N', A-'C', V3-'R']
    ;   Rest = [A-'C', V3-'R']
    ).

ng_shape(22, Seed, [P-'S', does-'K', not-'N', V-'R', Q-'O']) :-           % Alice does not like Bob
    ng_word2(proper, Seed, 2, P, Q), ng_word(vt, Seed, 3, V).

%% a place after an object: the preposition is a relation word of its own
%% (a run of one, copied as it is) and the place an object, so the grammar
%% reads rent_in(alice, V, rome) -- the shape the network dropped `in
%% Bristol' for want of
ng_shape(23, Seed, [P-'S', V3-'R'|Rest]) :-                                % Alice rents a small flat in Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_object(Seed, 4, Obj), ng_place(Seed, 8, Pl), append(Obj, Pl, Rest).
ng_shape(24, Seed, [P-'S', V3-'R'|Rest]) :-                                % Alice keeps the old key at Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_np_the(Seed, 12, N, Obj), ng_place(Seed, 5, Pl), append(Obj, Pl, Rest).
ng_shape(25, Seed, [every-'Q', C-'S', V3-'R'|Rest]) :-                     % Every tenant rents a small flat in Rome
    ng_word(class, Seed, 2, C), ng_word(vt, Seed, 3, V), normalise_third(V, V3),
    ng_word(noun, Seed, 4, N), ng_np(Seed, 12, N, Obj), ng_place(Seed, 5, Pl), append(Obj, Pl, Rest).
ng_shape(26, Seed, [P-'S', does-'K', not-'N', V-'R'|Rest]) :-              % Alice does not rent a small flat in Rome
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_word(noun, Seed, 4, N), ng_np(Seed, 12, N, Obj),
    ng_place(Seed, 5, Pl), append(Obj, Pl, Rest).

%% questions, six shapes: the first word says so and the text ends in `?',
%% which the tokeniser makes a stop; `who' is the subject it asks for and
%% `what' or `where' the object, so the assembler copies them where they
%% stand and the grammar reads a goal with a variable there
ng_shape(27, Seed, [does-'K', P-'S', V-'R'|Obj]) :-                        % Does Alice own a red car?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_object(Seed, 4, Obj).
ng_shape(28, Seed, [is-'R', P-'S'|Rest]) :-                                 % Is Alice happy? Is Alice a tenant?
    ng_word(proper, Seed, 2, P),
    (   ng_coin(Seed, 3, 50)
    ->  ng_word(adj, Seed, 4, A), Rest = [A-'A']
    ;   ng_word(class, Seed, 4, N), ng_art(N, Art), Rest = [Art-'T', N-'O']
    ).
ng_shape(29, Seed, [M-'R', P-'S', V-'R'|Obj]) :-                            % May Alice use the old server?
    ng_word(modal, Seed, 2, M), ng_word(proper, Seed, 3, P), ng_word(vt, Seed, 4, V), ng_word(noun, Seed, 5, N),
    ng_np_the(Seed, 12, N, Obj).
ng_shape(30, Seed, [who-'S'|Rest]) :-                                        % Who owns a car? Who is happy?
    (   ng_coin(Seed, 2, 50)
    ->  ng_word(vt, Seed, 3, V), normalise_third(V, V3), ng_object(Seed, 4, Obj), Rest = [V3-'R'|Obj]
    ;   ng_word(adj, Seed, 3, A), Rest = [is-'R', A-'A']
    ).
ng_shape(31, Seed, [what-'O', does-'K', P-'S', V-'R'|Pl]) :-                 % What does Alice own? What does Alice keep in Rome?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    ( ng_coin(Seed, 4, 40) -> ng_place(Seed, 5, Pl) ; Pl = [] ).
ng_shape(32, Seed, [where-'O', does-'K', P-'S', V-'R']) :-                   % Where does Alice sleep?
    ng_word(proper, Seed, 2, P), ng_word(vi, Seed, 3, V).

%% quantities, eight shapes: a number tagged T before the noun it counts,
%% the `of' between a unit and its noun a K, the noun O -- the grammar
%% reads quantity(500, euros) and quantity(2, litres, milk) where the
%% assembler copies them; `the N is NUM UNIT' the amount sentence, the one
%% definite subject the grammar reads, and its yes-or-no question; and the
%% `how much' and `how many' questions, their question words O like `what'
%% and the noun of a `how many' with them
ng_shape(33, Seed, [P-'S', V3-'R'|Q]) :-                                   % Alice pays 500 euros / buys two litres of milk
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), normalise_third(V, V3), ng_quantity(Seed, 40, Q).
ng_shape(34, Seed, [every-'Q', C-'S', M-'R', V-'R'|Q]) :-                   % Every tenant must pay 500 euros
    ng_word(class, Seed, 2, C), ng_word(modal, Seed, 3, M), ng_word(vt, Seed, 4, V), ng_quantity(Seed, 40, Q).
ng_shape(35, Seed, Pairs) :-                                                % The rent is 500 euros / is 500 / Is the rent 500 euros?
    ng_word(noun, Seed, 2, N),
    (   ng_coin(Seed, 3, 25)
    ->  ng_number(Seed, 4, Num), findall(W-'O', member(W-_, Num), Q)       % a bare number is the object
    ;   ng_quantity(Seed, 40, Q)
    ),
    (   ng_coin(Seed, 8, 20) -> Pairs = [is-'R', the-'T', N-'S'|Q] ; Pairs = [the-'T', N-'S', is-'R'|Q] ).
ng_shape(36, Seed, [P-'S', does-'K', not-'N', V-'R'|Q]) :-                 % Alice does not pay 500 euros
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_quantity(Seed, 40, Q).
ng_shape(37, Seed, [does-'K', P-'S', V-'R'|Q]) :-                          % Does Alice pay 500 euros?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V), ng_quantity(Seed, 40, Q).
ng_shape(38, Seed, [how-'O', much-'O'|Rest]) :-                            % How much does Alice pay? How much must Alice pay?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    (   ng_coin(Seed, 4, 30)
    ->  ng_word(modal, Seed, 5, M), Rest = [M-'R', P-'S', V-'R']
    ;   Rest = [does-'K', P-'S', V-'R']
    ).
ng_shape(39, Seed, [how-'O', many-'O', Us-'O', does-'K', P-'S', V-'R']) :- % How many euros does Alice pay?
    ng_word(proper, Seed, 2, P), ng_word(vt, Seed, 3, V),
    ( ng_coin(Seed, 4, 70) -> ng_word(unit, Seed, 5, U) ; ng_word(noun, Seed, 5, U) ), ng_plural(U, Us).
ng_shape(40, Seed, [how-'O', much-'O', is-'R', the-'T', N-'S']) :-         % How much is the rent?
    ng_word(noun, Seed, 2, N).

%% `why' before a yes-or-no question, an O like `what': the grammar reads
%% question(why(Goal)) and answers with the whole proof
ng_shape(41, Seed, [why-'O'|Rest]) :- ng_shape(28, Seed, Rest).             % Why is Alice happy? Why is Alice a tenant?
ng_shape(42, Seed, [why-'O'|Rest]) :-                                        % Why does Alice own a car? Why may Alice use the server?
    ( ng_coin(Seed, 9, 50) -> ng_shape(27, Seed, Rest) ; ng_shape(29, Seed, Rest) ).

%% a rule whose head is an ADJECTIVE after a relative clause -- `Every
%% square that is attacked is unsafe' -- the shape the chess position was
%% written in and the tagger dropped the adjective of, having seen a head
%% after `that is' only as a class, a verb or a modal (shapes 8, 15, 16, 21)
ng_shape(43, Seed, [every-'Q', C-'S', that-'K', is-'K'|Rest]) :-           % Every square that is attacked is unsafe
    ng_word(class, Seed, 2, C), ng_word2(adj, Seed, 3, A, B),
    (   ng_coin(Seed, 6, 50)
    ->  Rest = [not-'N', A-'C', is-'R', B-'A']
    ;   Rest = [A-'C', is-'R', B-'A']
    ).

%% a modal before a phrasal verb -- `Kh8 may move to G8', which the chess
%% position wrote and the tagger read with `move' as the object: shape 6
%% puts a modal before a verb and a determined noun, shape 9 a phrasal
%% verb with no modal, and nothing put the two together. The clean text is
%% `may move_to G8'; split, tagged R R R, the assembler joins the run to
%% may_move_to, which the grammar reads as a modal and a base form
ng_shape(44, Seed, [P-'S', M-'R', VJ-'R', Q-'O']) :-                        % Alice may live_in Rome
    ng_word(proper, Seed, 2, P), ng_word(modal, Seed, 3, M), ng_word(vpp, Seed, 4, V-Prep),
    atomic_list_concat([V, '_', Prep], VJ),
    ( ng_coin(Seed, 5, 50) -> ng_word(place, Seed, 6, Q) ; ng_word(proper, Seed, 6, Q) ).

%% ---- lessons, ten shapes: a word said of a WORD ----------------------------
%% A mention is q(W) in the pairs and `"W"' in the text, tagged M; the
%% apposition's class is A (a fact about the word, as its adjectives are);
%% the relations, the class atoms, the forms and the adjectives are the
%% corpus's, so that no word of any lesson lives here
ng_shape(45, Seed, Pairs) :-                                                % The feminine noun "casa" means "house"
    ng_apposition(Seed, 2, Head), ng_word(vq, Seed, 8, V), ng_meaning(Seed, 9, E),
    append(Head, [V-'R', q(E)-'M'], Pairs).
ng_shape(46, Seed, [q(W)-'M', V-'R', q(E)-'M']) :-                         % "casa" means "house"
    ng_mention(Seed, 2, W), ng_word(vq, Seed, 3, V), ng_meaning(Seed, 4, E).
ng_shape(47, Seed, [q(W)-'M', is-'R'|Rest]) :-                              % "leche" is feminine / is not feminine
    ng_mention(Seed, 2, W), ng_wadj(Seed, 3, A),
    ( ng_coin(Seed, 4, 20) -> Rest = [not-'N', A-'A'] ; Rest = [A-'A'] ).
ng_shape(48, Seed, [q(W)-'M', is-'R', Art-'T'|Rest]) :-                     % "amigo" is a person / "casa" is a feminine noun
    ng_mention(Seed, 2, W), ng_word(wclass, Seed, 3, C),
    (   ng_coin(Seed, 4, 40) -> ng_wadj(Seed, 5, A), ng_art(A, Art), Rest = [A-'A', C-'O']
    ;   ng_art(C, Art), Rest = [C-'O']
    ).
ng_shape(49, Seed, [q(W)-'M', is-'R', the-'T'|Rest]) :-                     % "los" is the plural of "el" / "como" is the first person of "come"
    ng_mention2(Seed, 2, W, V), ng_word(form, Seed, 3, Form), ng_form_pairs(Form, FP),
    append(FP, [of-'K', q(V)-'M'], Rest).
ng_shape(50, Seed, [every-'Q', C-'S', that-'K'|Rest]) :-                    % Every noun that ends in "a" is feminine / that does not end in a vowel is masculine
    ng_word(wclass, Seed, 2, C), ng_wadj(Seed, 3, A), ng_word(vin, Seed, 4, V3-P), ng_ending_phrase(Seed, 5, End),
    (   ng_coin(Seed, 8, 30) -> rs_base(V3, V), Verb = [does-'K', not-'N', V-'R', P-'R']
    ;   Verb = [V3-'R', P-'R']
    ),
    append([Verb, End, [is-'R', A-'A']], Rest).
ng_shape(51, Seed, [every-'Q', C-'S'|Rest]) :-                              % Every verb that ends in "e" takes "n" in the plural / Every noun takes "s" in the plural
    ng_word(wclass, Seed, 2, C), ng_word(vqin, Seed, 3, V), ng_word(ending, Seed, 4, E), ng_word(wplace, Seed, 5, P-N),
    Tail = [V-'R', q(E)-'M', P-'R', the-'T', N-'O'],
    (   ng_coin(Seed, 6, 70)
    ->  ng_word(vin, Seed, 7, V3-P3), ng_ending_phrase(Seed, 8, End), append([[that-'K', V3-'R', P3-'R'], End, Tail], Rest)
    ;   Rest = Tail
    ).
ng_shape(52, Seed, Pairs) :-                                                % The word "no" precedes the verb / does not precede / Every adjective follows the noun / "y" precedes the verb
    ng_word(vthe, Seed, 2, V3), ng_word(wobj, Seed, 3, N), ng_pick(Seed, 4, 3, K),
    (   K =:= 0 -> ng_apposition(Seed, 5, Head)
    ;   K =:= 1 -> ng_mention(Seed, 5, W), Head = [q(W)-'M']
    ;   ng_word(wclass, Seed, 5, C), Head = [every-'Q', C-'S']
    ),
    (   K < 2, ng_coin(Seed, 12, 25) -> rs_base(V3, V), Tail = [does-'K', not-'N', V-'R', the-'T', N-'O']
    ;   Tail = [V3-'R', the-'T', N-'O']
    ),
    append(Head, Tail, Pairs).
ng_shape(53, Seed, [L-'S', is-'R', Art-'T', N-'O']) :-                      % Spanish is a language
    ng_word(language, Seed, 2, L), ng_word(wlang, Seed, 3, N), ng_art(N, Art).
ng_shape(54, Seed, Pairs) :-                                                % The noun "leche" is feminine / The noun "amigo" is a person / The article "los" is the plural of "el"
    ng_apposition(Seed, 2, Head), ng_pick(Seed, 9, 3, K),
    (   K =:= 0 -> ng_wadj(Seed, 10, A), Tail = [is-'R', A-'A']
    ;   K =:= 1 -> ng_word(wclass, Seed, 10, C), ng_art(C, Art), Tail = [is-'R', Art-'T', C-'O']
    ;   ng_mention(Seed, 10, V), ng_word(form, Seed, 11, Form), ng_form_pairs(Form, FP),
        append([[is-'R', the-'T'], FP, [of-'K', q(V)-'M']], Tail)
    ),
    append(Head, Tail, Pairs).

ng_place(Seed, Salt, [Prep-'R', Q-'O']) :-
    ng_choose(Seed, Salt, [in, at, near], Prep), Salt1 is Salt + 1, ng_word(place, Seed, Salt1, Q).

%% a quantity as an object: a number and its noun -- a unit pluralised
%% (`500 euros') or a thing pluralised (`three vineyards') -- and one time
%% in four with an `of' part, `two litres of milk' or `a litre of milk'
ng_quantity(Seed, Salt, Pairs) :-
    Salt1 is Salt + 1, Salt2 is Salt + 2, Salt3 is Salt + 3, Salt4 is Salt + 4,
    (   ng_coin(Seed, Salt, 25)
    ->  ng_word(unit, Seed, Salt1, U), ng_word(noun, Seed, Salt2, N),
        (   ng_coin(Seed, Salt3, 40)
        ->  ng_art(U, Art), Pairs = [Art-'T', U-'O', of-'K', N-'O']
        ;   ng_number(Seed, Salt4, Num), ng_plural(U, Us), append(Num, [Us-'O', of-'K', N-'O'], Pairs)
        )
    ;   ( ng_coin(Seed, Salt1, 70) -> ng_word(unit, Seed, Salt2, W) ; ng_word(noun, Seed, Salt2, W) ),
        ng_number(Seed, Salt4, Num), ng_plural(W, Ws), append(Num, [Ws-'O'], Pairs)
    ).

%% a number, each word of it tagged T: digits mostly (2 to 999, a decimal, a
%% round thousand), and the number words the grammar reads -- `five', `twenty
%% five', `two hundred', `a hundred', `three thousand'. Digits are an ATOM
%% here, because the text is joined with atomic_list_concat/3 and read back
%% by reason_tokens/2 as num(N); the pair's tokens carry the num.
ng_number(Seed, Salt, Pairs) :-
    Salt1 is Salt + 5, Salt2 is Salt + 6,
    ng_pick(Seed, Salt, 10, K),
    (   K < 5   -> ng_pick(Seed, Salt1, 998, N0), N is N0 + 2, format(atom(A), "~w", [N]), Pairs = [A-'T']
    ;   K =:= 5 -> ng_pick(Seed, Salt1, 99, N0), N is N0 + 1, ng_pick(Seed, Salt2, 9, D0), D is D0 + 1,
                   format(atom(A), "~w.~w", [N, D]), Pairs = [A-'T']
    ;   K =:= 6 -> ng_pick(Seed, Salt1, 20, N0), N is (N0 + 1) * 1000, format(atom(A), "~w", [N]), Pairs = [A-'T']
    ;   K =:= 7 -> findall(W, ( rl_number(W, V), V >= 2, V =< 19 ), Ws), ng_choose(Seed, Salt1, Ws, W1), Pairs = [W1-'T']
    ;   K =:= 8 -> findall(W, ( rl_number(W, V), V >= 20 ), Tens), ng_choose(Seed, Salt1, Tens, T1),
                   findall(W, ( rl_number(W, V), V >= 1, V =< 9 ), Units), ng_choose(Seed, Salt2, Units, U1),
                   Pairs = [T1-'T', U1-'T']
    ;   findall(W, ( rl_number(W, V), V >= 2, V =< 9 ), Small), ng_choose(Seed, Salt1, Small, S1),
        ng_choose(Seed, Salt2, [hundred, thousand, a], Scale),
        ( Scale == a -> Pairs = [a-'T', hundred-'T'] ; Pairs = [S1-'T', Scale-'T'] )
    ).

%% none, one or two adjectives -- the grammar takes every word between the
%% determiner and the noun as one, and a network shown only one dropped the
%% noun after two
ng_adjectives(Seed, Salt, As) :-
    ng_pick(Seed, Salt, 3, K), Salt1 is Salt + 1, Salt2 is Salt + 2,
    (   K =:= 0 -> As = []
    ;   K =:= 1 -> ng_word(adj, Seed, Salt1, A), As = [A-'A']
    ;   ng_word2(adj, Seed, Salt1, A, B), As = [A-'A', B-'A'], Salt2 > 0
    ).

ng_object(Seed, Salt, [Art-'T'|Obj]) :-
    ng_word(noun, Seed, Salt, N), Salt1 is Salt + 1,
    ng_adjectives(Seed, Salt1, As), append(As, [N-'O'], Obj),
    ( As = [A-_|_] -> ng_art(A, Art) ; ng_art(N, Art) ).

%% the noun phrase of an object in the nine verb-object shapes that used
%% to write `Art-'T', N-'O' themselves: the determiner, the adjectives,
%% the noun -- on a salt of the shape's own, so a shape that gains it
%% keeps every other word it drew. Until 1.2.42 only the four shapes that
%% call ng_object carried an adjective, so an adjective object followed
%% by a comma filler was made 352 times in 32768 pairs against 4120 bare
%% ones -- and the tagger read `Zed owns a red car, obviously' with `red'
%% as D: in 20 to 69 of 128 such sentences on 1.2.41's model, in 128 of
%% 128 on the first model trained after the Italian lesson grew. The
%% share the widened shapes give was MEASURED, 500 steps, over a grid of
%% 384 such sentences and the 300 evaluation pairs (CLAUDE.md, 1.2.42):
%%
%%   none / one / two          A-tokens   `T A O , D'   grid    sentences
%%   thirds, as ng_object      24 643     774           20      0.8300
%%   1/2 / 1/3 / 1/6           ~21 000    780           207     0.8867
%%   2/3 / 1/3 / never         18 619     791           0, 11   0.8600, 0.8567 (two seeds)
%%
%% -- the count of the shape is the same in all three and the outcome is
%% not, so the network learns it by the luck of the minimum and the share
%% that gave it is kept. A word's class as an input feature is the durable
%% fix, and it is proposed there, not done here.
ng_np(Seed, Salt, N, [Art-'T'|Obj]) :-
    ng_adjectives_some(Seed, Salt, As), append(As, [N-'O'], Obj),
    ( As = [A-_|_] -> ng_art(A, Art) ; ng_art(N, Art) ).
ng_np_the(Seed, Salt, N, [the-'T'|Obj]) :-
    ng_adjectives_some(Seed, Salt, As), append(As, [N-'O'], Obj).

%% the widened shapes' share: none in one object of two, one in one of
%% three, two in one of six -- lighter than shape 0's thirds, and the one
%% share of three measured that a training learns the shape from (the
%% table in ng_np's comment)
ng_adjectives_some(Seed, Salt, As) :-
    ng_pick(Seed, Salt, 6, K), Salt1 is Salt + 1,
    (   K < 3 -> As = []
    ;   K < 5 -> ng_word(adj, Seed, Salt1, A), As = [A-'A']
    ;   ng_word2(adj, Seed, Salt1, A, B), As = [A-'A', B-'A']
    ).

%% ---- the transforms -----------------------------------------------------------------
%% Each takes and gives st(Pairs, CleanSentences): the pairs with their
%% tags, and the list of clean pair-lists the pairs were made from, which
%% `conjoin' extends.

ng_applicable(split_relation, Ps) :- member(W-'R', Ps), sub_atom(W, _, _, _, '_'), !.
ng_applicable(emphatic_do, [S-'S', V3-'R'|Rest]) :-
    \+ rl_question(S), ng_base_of(V3, _), ( Rest = [] ; Rest = [_-'T'|_] ; Rest = [_-'O'|_] ), !.
ng_applicable(conjoin, Ps) :- \+ member(_-'B', Ps), \+ ng_question(Ps).
ng_applicable(conjoin_shared, [S-'S'|Ps]) :- \+ rl_question(S), \+ member(_-'B', Ps).   % a fact, not yet joined
ng_applicable(conjoin_shared, Ps) :- ng_mention_head(Ps, _, _), \+ member(_-'B', Ps).     % or a fact about a mention
ng_applicable(filler_join, Ps) :- \+ ng_question(Ps).
ng_applicable(adverb, Ps) :- member(_-'S', Ps), !.
ng_applicable(hedge_start, Ps) :- \+ ng_question(Ps).                  % `I think that does Alice...' is nobody's prose
ng_applicable(filler_start, _).
ng_applicable(filler_end, _).
ng_applicable(adverb_end, Ps) :- last(Ps, _-'R').           % only after an intransitive verb: a bare
                                                            % word after an object reads as its noun
ng_applicable(pp_extra, _).
ng_applicable(in_language, Ps) :- member(_-'M', Ps), !.
ng_applicable(unquote, Ps) :- member(q(_)-'M', Ps), !.

%% the base of an inflected verb, by the grammar's own stemmer -- which every
%% loaded verb round-trips through -- and only of a real inflection: `is'
%% stems to itself and takes no `does'; a joined `lives_in' stems to live_in
%% and would take one, but split_relation, first and always, has split it
%% by then. (The first
%% draft walked the whole vt and vi lists with the inflector for every pair,
%% which was nothing over twenty verbs and eighty milliseconds a pair over
%% four thousand.)
ng_base_of(V3, V) :- \+ rl_closed(V3), rs_base(V3, V), V \== V3.

ng_apply(split_relation, _, st(Ps, Cs), st(Qs, Cs)) :- ng_split_rel(Ps, Qs).
ng_apply(emphatic_do, _, st([S-'S', V3-'R'|Rest], Cs), st([S-'S', does-'D', V-'R'|Rest], Cs)) :- ng_base_of(V3, V).
ng_apply(conjoin, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    S2 is Seed * 31 + 7, ng_statement(S2, Qs),
    ( ng_coin(Seed, 25, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    append([Ps, Join, Qs], Out), append(Cs, [Qs], Cs2).
%% a second fact about the same subject, joined by `and' with its subject
%% left out (`Alice is a baker and is licensed') or as a pronoun (`and she
%% is licensed'); the clean text has both sentences whole
ng_apply(conjoin_shared, Seed, st([P-'S'|Ps], Cs), st(Out, Cs2)) :-
    ng_fact_rest(Seed, 0, Rest),
    ( ng_coin(Seed, 42, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    (   ng_coin(Seed, 43, 50)
    ->  Second = Rest
    ;   ng_choose(Seed, 44, [she, he], Pro), Second = [Pro-'S'|Rest]
    ),
    append([[P-'S'|Ps], Join, Second], Out), append(Cs, [[P-'S'|Rest]], Cs2).

%% the same about a MENTION: `"casa" means "house" and is feminine', `The
%% noun "casa" means "house" and is a person' -- the subject phrase is
%% everything before the relation (the apposition whole), never a pronoun,
%% because `it' is about nobody to the grammar
ng_apply(conjoin_shared, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    ng_mention_head(Ps, Head, _),
    ng_lesson_rest(Seed, Rest),
    ( ng_coin(Seed, 42, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] ),
    findall(P, ( member(P, Head), P \= _-'D', P \= _-'K', P \= _-'N' ), CleanHead),   % the phrase, never its `does not'
    append([Ps, Join, Rest], Out), append(CleanHead, Rest, Second), append(Cs, [Second], Cs2).

%% a filler or a hedge after the `and': joins a second sentence itself when
%% none has been joined, so the transform stands alone in a test
ng_apply(filler_join, Seed, st(Ps, Cs), st(Out, Cs2)) :-
    (   append(Before, [and-'B'|After], Ps)
    ->  Cs2 = Cs, Join = [and-'B']
    ;   S2 is Seed * 37 + 11, ng_statement(S2, After), Before = Ps, append(Cs, [After], Cs2),
        ( ng_coin(Seed, 33, 40) -> Join = [','-'D', and-'B'] ; Join = [and-'B'] )
    ),
    (   ng_coin(Seed, 30, 50)
    ->  ng_choose(Seed, 31, [[in, fact], [well], [actually], [of, course], [to, be, honest], [as, far, as, 'I', know],
                             [by, the, way], [anyway], [honestly], [frankly], [as, 'I', said], [after, all], [for, example],
                             [in, any, case], [as, usual], [no, doubt]], F),
        ng_dropped(F, Fs), append([','-'D'|Fs], [','-'D'], Filler)
    ;   ng_choose(Seed, 32, [['I', think, that], ['I', believe, that], [it, seems, that], [you, said, that],
                             ['I', heard, that], [we, know, that], [it, is, clear, that]], H),
        ng_dropped(H, Filler)
    ),
    append([Before, Join, Filler, After], Out).
ng_apply(adverb, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_word(adverb, Seed, 21, Adv),
    ng_after_subject(Ps, Adv-'D', Out).
ng_apply(hedge_start, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 26, [['I', think, that], ['I', believe, that], ['I', know, that], [it, seems, that],
                         [we, know, that], [you, said, that], [it, is, clear, that], ['I', heard, that]], F),
    ng_dropped(F, Fs), append(Fs, Ps, Out).
ng_apply(filler_start, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 22, [[in, fact], [well], [actually], [in, short], [of, course], [to, be, honest],
                         [as, far, as, 'I', know], [by, the, way], [anyway], [so], [also], [then],
                         [honestly], [frankly], [as, 'I', said], [after, all], [for, example], [in, any, case]], F),
    ng_dropped(F, Fs), append(Fs, [','-'D'|Ps], Out).
ng_apply(filler_end, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 23, [[obviously], [of, course], ['I', think], [apparently], [for, sure],
                         [as, far, as, 'I', know], [to, be, honest], ['I', believe], [no, doubt],
                         [as, usual], ['I', guess], [you, know], [it, seems], ['I', suppose], [clearly]], F),
    ng_dropped(F, Fs), append(Ps, [','-'D'|Fs], Out).
ng_apply(adverb_end, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_word(adverb, Seed, 27, Adv),
    append(Ps, [Adv-'D'], Out).
ng_apply(pp_extra, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_choose(Seed, 24, [[at, home], [on, weekdays], [in, the, morning], [for, now], [at, night],
                         [on, holiday], [in, the, evening], [at, work], [at, the, moment], [for, a, while],
                         [as, usual], [for, sure], [in, general], [at, first], [on, time], [by, now],
                         [in, the, end], [at, last], [on, the, whole], [in, practice]], F),
    ng_dropped(F, Fs), append(Ps, Fs, Out).

%% the language a lesson is about, as prose puts it: after a fact about a
%% mention when the fact ends in the mention or an adjective (where the
%% grammar refuses it: a sentence about a word names no place), and at the
%% head otherwise (`In Spanish, ...', refused by the closed word at the head)
ng_apply(in_language, Seed, st(Ps, Cs), st(Out, Cs)) :-
    ng_word(language, Seed, 28, L),
    (   ( last(Ps, q(_)-'M') ; last(Ps, _-'A') ), ng_coin(Seed, 29, 50)
    ->  append(Ps, [in-'D', L-'D'], Out)
    ;   Out = [in-'D', L-'D', ','-'D'|Ps]
    ).
%% the quotation marks taken off every mention that survives as words:
%% q('a el')-M becomes a-M el-M, and the assembler's M run puts the marks
%% back around both; a mention the tokeniser would drop bare (`¿') keeps
%% them. AT THE HEAD OF A SENTENCE a bare word cannot be told from a
%% name -- `Leche is feminine' and `Mia is a nurse' are one shape -- and
%% the name reading gives the SAME TERM (feminine(leche) either way, and
%% mean(casa, house) for `Casa means house'), so a head mention is
%% written bare and tagged S, the name reading: the network then never
%% has to guess, and a name typed after the lessons stays a name.
%% Measured before this rule: `Mia is a nurse and is careful' came back
%% as `"mia" is a nurse', the same facts about a word instead of a person.
%% A head word the lexicon knows as a COMMON word keeps its marks
%% (`"house" is feminine'), because the judge refuses a known common
%% word as a capitalised subject, as it refuses `Small business
%% management'; so does a closed word (`"the" is an article').
ng_apply(unquote, _, st(Ps, Cs), st(Qs, Cs)) :- ng_unquote(Ps, head, Qs).

%% a mention before the first relation and no S there: the head is the
%% subject phrase, `"casa"' or `the noun "casa"'
ng_mention_head(Ps, Head, Rest) :-
    append(Head, [R-'R'|Rest0], Ps), memberchk(_-'M', Head), \+ memberchk(_-'S', Head), !,
    Rest = [R-'R'|Rest0].

%% what else is said of a word: an adjective, a class, a meaning
ng_lesson_rest(Seed, Rest) :-
    ng_pick(Seed, 45, 3, K),
    (   K =:= 0 -> ng_wadj(Seed, 46, A), Rest = [is-'R', A-'A']
    ;   K =:= 1 -> ng_word(wclass, Seed, 46, C), ng_art(C, Art), Rest = [is-'R', Art-'T', C-'O']
    ;   ng_word(vq, Seed, 46, V), ng_meaning(Seed, 47, E), Rest = [V-'R', q(E)-'M']
    ).

%% a fact shape for it, its own subject taken off: a few seeds tried, and
%% `sleeps' when none of them is a fact
ng_fact_rest(Seed, K, Rest) :-
    K < 8, S2 is Seed * 41 + K,
    ng_sentence(S2, Qs),
    (   Qs = [_-'S'|Rest0], \+ ng_question(Qs) -> Rest = Rest0
    ;   K1 is K + 1, ng_fact_rest(Seed, K1, Rest)
    ), !.
ng_fact_rest(Seed, _, Rest) :- S2 is Seed * 41 + 8, ng_shape(5, S2, [_-'S'|Rest]).

ng_unquote([], _, []).
ng_unquote([q(W)-'M'|Ps], head, [W-'S'|Qs]) :- ng_head_bare(W), !, ng_unquote(Ps, rest, Qs).
ng_unquote([q(W)-'M'|Ps], head, [q(W)-'M'|Qs]) :- !, ng_unquote(Ps, rest, Qs).
ng_unquote([q(W)-'M'|Ps], rest, Out) :-
    ng_bare_words(W, Ws), !,
    findall(X-'M', member(X, Ws), Ms), append(Ms, Qs, Out), ng_unquote(Ps, rest, Qs).
ng_unquote([P|Ps], Pos, [P|Qs]) :-
    (   P = _-'B' -> Pos1 = head                       % the next sentence has a head of its own
    ;   P = _-'D' -> Pos1 = Pos                        % noise before the head is not the head
    ;   P = ','-_ -> Pos1 = Pos
    ;   Pos1 = rest
    ),
    ng_unquote(Ps, Pos1, Qs).

ng_bare_words(W, Ws) :-
    atomic_list_concat(Ws, ' ', W), Ws \== [],
    forall(member(X, Ws), ( X \== '', reason_tokens(X, [word(X, _)]) )).

%% one word, not closed, and either a name or a word the lexicon does not
%% know: what stands bare at the head as a subject
normalise_head_bare(W) :- ng_head_bare(W).
ng_head_bare(W) :-
    ng_bare_words(W, [W]),
    \+ rl_closed(W),
    ( ng_name_word(W) -> true ; \+ ng_known_word(W) ).

%% the lexicon's common words and its names, as two assocs made once a machine
ng_known_word(W) :- ng_word_table('$lx_known', [noun, class, adj, adverb, unit, vt, vi, vpp, known_noun, known_verb, known_adj, known_adverb], T), get_assoc(W, T, _).
ng_name_word(W) :- ng_word_table('$lx_names', [proper, place, language], T), get_assoc(W, T, _).
ng_word_table(Key, Classes, T) :-
    (   catch(nb_getval(Key, T0), _, fail)
    ->  T = T0
    ;   findall(W-yes, ( member(C, Classes), normalise_lexicon(C, Ws), member(W0, Ws),
                         ( W0 = V-_ -> true ; V = W0 ), downcase_atom(V, W) ), Ps0),
        keysort(Ps0, Ps1), ng_first_keys(Ps1, Ps), list_to_assoc(Ps, T0), nb_setval(Key, T0), T = T0
    ).
ng_first_keys([], []).
ng_first_keys([K-V|Rest], [K-V|Out]) :- ng_drop_key(K, Rest, Rest1), ng_first_keys(Rest1, Out).
ng_drop_key(K, [K-_|R], O) :- !, ng_drop_key(K, R, O).
ng_drop_key(_, R, R).

ng_dropped([], []).
ng_dropped([W|Ws], [W-'D'|Ds]) :- ng_dropped(Ws, Ds).

ng_split_rel([], []).
ng_split_rel([W-'R'|Ps], Out) :-
    sub_atom(W, _, _, _, '_'), !,
    atomic_list_concat(Parts, '_', W),
    findall(P-'R', member(P, Parts), Rs),
    append(Rs, Qs, Out), ng_split_rel(Ps, Qs).
ng_split_rel([P|Ps], [P|Qs]) :- ng_split_rel(Ps, Qs).

ng_after_subject([W-'S'|Ps], X, [W-'S', X|Ps]) :- !.
ng_after_subject([P|Ps], X, [P|Qs]) :- ng_after_subject(Ps, X, Qs).

%% ---- a pair, and a corpus ------------------------------------------------------------

normalise_pair(Seed, Pair) :- normalise_pair(Seed, [], Pair).

normalise_pair(Seed, Options, pair(Noisy, Tokens, Tags, Clean, Applied)) :-
    ng_sentence(Seed, Clean0),
    ( memberchk(transforms(Cands), Options) -> true ; normalise_transforms(Cands) ),
    ( memberchk(always(true), Options) -> Always = yes ; Always = no ),
    normalise_transforms(Order),
    ng_run(Order, Cands, Always, Seed, 100, st(Clean0, [Clean0]), st(Noisy0, Cleans), Applied),
    ng_text_of(Noisy0, Noisy),
    findall(T, member(_-T, Noisy0), Tags),
    findall(CT, ( member(CP, Cleans), ng_text_of(CP, CT) ), CTs),
    atomic_list_concat(CTs, ' ', Clean),
    reason_tokens(Noisy, Toks0), append(Tokens, ['.'], Toks0).

%% a transform's chance, per pair: a coin at 35 for noise, and the split
%% ALWAYS, because `lives_in' is the grammar's spelling and nobody types
%% it -- the two-word form is the only one a tagger will meet
ng_rate(split_relation, 100) :- !.
ng_rate(unquote, 70) :- !.           % prose writes a word about a word bare, mostly; the marks must be read too
ng_rate(_, 35).

ng_run([], _, _, _, _, S, S, []).
ng_run([T|Ts], Cands, Always, Seed, Salt, S0, S, Applied) :-
    S0 = st(Ps0, _),
    (   memberchk(T, Cands), ng_applicable(T, Ps0),
        ( Always == yes -> true ; ng_rate(T, Rate), ng_coin(Seed, Salt, Rate) )
    ->  ng_apply(T, Seed, S0, S1), Applied = [T|More]
    ;   S1 = S0, Applied = More
    ),
    Salt1 is Salt + 1,
    ng_run(Ts, Cands, Always, Seed, Salt1, S1, S, More).

%% real sentences, every tag X: a tagger's negatives
normalise_negatives(From, N, Pairs) :-
    To is From + N - 1, ng_size(prose, Size), To =< Size,
    findall(pair(Text, Toks, Tags, none, [outside]),
            ( between(From, To, I), K is I - 1, ng_nth(prose, K, Text),
              reason_tokens(Text, Toks0), ( append(Toks1, ['.'], Toks0) -> true ; Toks1 = Toks0 ),
              Toks1 \== [], Toks = Toks1,
              length(Toks, L), findall('X', between(1, L, _), Tags) ),
            Pairs).

normalise_corpus(N, Pairs) :- normalise_corpus(N, [], Pairs).
normalise_corpus(N, Options, Pairs) :-
    findall(P, ( between(1, N, I), normalise_pair(I, Options, P) ), Pairs).

%% ---- the pairs as a file ---------------------------------------------------------------
%% One term a line, quoted, so a text with `"' and a UTF-8 word in it
%% comes back as it was; a line beginning % is a comment and a blank line
%% is skipped. Written whole through a string, as tagger_export/2 writes
%% the model: no stream is opened.

normalise_save(Pairs, File) :-
    with_output_to(string(S), forall(member(P, Pairs), ( writeq(P), write('.'), nl ))),
    string_codes(S, Cs),
    write_file_from_codes(File, Cs).

normalise_load(File, Pairs) :-
    (   exists_file(File) -> true
    ;   throw(error(existence_error(source_sink, File), normalise_load/2))
    ),
    read_file_to_codes(File, Codes),
    split_string(Codes, [10], [32, 13, 9], Lines),
    findall(P, ( member(L, Lines), string_length(L, Len), Len > 0,
                 \+ sub_string(L, 0, 1, _, '%'),
                 atom_string(A, L), term_to_atom(P, A), P = pair(_, _, _, _, _) ),
            Pairs).

normalise_generated_dir(Dir) :-
    getenv('COCOLOG_GENERATED', Dir), Dir \== '', !,
    make_directory_path(Dir).
normalise_generated_dir(Dir) :-
    ng_library_dirs(Ds), member(D, Ds),
    atom_concat(D, '/reasoning', R), exists_directory(R), !,
    atom_concat(R, '/generated', Dir), make_directory_path(Dir).

%% ---- text from words ---------------------------------------------------------------------
%% The first word capitalised, a comma attached to the word before it, a
%% stop at the end.

ng_text_of(Pairs, Text) :- findall(W, member(W-_, Pairs), Ws), ng_stop(Pairs, Stop), ng_text(Ws, Stop, Text).

%% `?' after a question, `.' after anything else: the first word that is
%% not noise says which, in the generator's pairs and the assembler's alike
ng_stop(Pairs, Stop) :-
    (   member(P-T, Pairs), T \== 'D', P \== ',',
        ( P = word(W, _) -> true ; W = P )
    ->  ( ng_question([W-T]) -> Stop = '?' ; Stop = '.' )
    ;   Stop = '.'
    ).

ng_text(Words, Text) :- ng_text(Words, '.', Text).
ng_text(Words, Stop, Text) :-
    ng_text_(Words, first, Parts),
    atomic_list_concat(Parts, Body), atom_concat(Body, Stop, Text).

ng_text_([], _, []).
ng_text_([','|Ws], _, [','|Ps]) :- !, ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], first, [C|Ps]) :- !, ng_spell(W, A), ( W = q(_) -> C = A ; ng_cap(A, C) ), ng_text_(Ws, rest, Ps).
ng_text_([W|Ws], rest, [' ', A|Ps]) :- ng_spell(W, A), ng_text_(Ws, rest, Ps).

%% a mention q(W) is written between quotation marks, and never capitalised
ng_spell(q(W), A) :- !, atomic_list_concat(['"', W, '"'], A).
ng_spell(W, W).

%% ---- a text with its mentions bare ----------------------------------------------------------

normalise_bare(Text, Bare) :-
    reason_tokens(Text, Toks),
    nb_sentences(Toks, Sents),
    findall(T, ( member(S, Sents), nb_text(S, T) ), Ts),
    atomic_list_concat(Ts, ' ', Bare).

nb_sentences([], []) :- !.
nb_sentences(Toks, Sents) :-
    nb_upto(Toks, S, Rest),
    ( S == [] -> Sents = Sents1 ; Sents = [S|Sents1] ),
    nb_sentences(Rest, Sents1).
nb_upto([], [], []).
nb_upto(['.'|Ts], [], Ts) :- !.
nb_upto([T|Ts], [T|S], Rest) :- nb_upto(Ts, S, Rest).

nb_text(S, T) :-
    nb_words(S, head, Ws),
    findall(W-x, ( member(Tok, S), nb_plain(Tok, W) ), Pairs), ng_stop(Pairs, Stop),   % the stop from the lower-case words: `Is' asks
    ng_text(Ws, Stop, T).

nb_plain(word(W, _), W).
nb_plain(quoted(W), q(W)).
nb_plain(num(N), N).
nb_plain(',', ',').

%% as the unquote transform writes them: bare, and at the head only a
%% word that can stand as a subject
nb_words([], _, []).
nb_words([quoted(W)|Ts], head, [W|Ws]) :- ng_head_bare(W), !, nb_words(Ts, rest, Ws).
nb_words([quoted(W)|Ts], head, [q(W)|Ws]) :- !, nb_words(Ts, rest, Ws).
nb_words([quoted(W)|Ts], rest, Out) :- ng_bare_words(W, Bare), !, append(Bare, Ws, Out), nb_words(Ts, rest, Ws).
nb_words([quoted(W)|Ts], rest, [q(W)|Ws]) :- !, nb_words(Ts, rest, Ws).
nb_words([word(W, upper)|Ts], _, [C|Ws]) :- !, ng_cap(W, C), nb_words(Ts, rest, Ws).
nb_words([word(W, _)|Ts], _, [W|Ws]) :- !, nb_words(Ts, rest, Ws).
nb_words([num(N)|Ts], _, [A|Ws]) :- !, format(atom(A), "~w", [N]), nb_words(Ts, rest, Ws).
nb_words([T|Ts], Pos, [T|Ws]) :- nb_words(Ts, Pos, Ws).

%% AN ACCENTED FIRST LETTER IS A LETTER: the two bytes 195 and 160..190 in
%% UTF-8 (U+00E0..U+00FE), the division sign left out -- the same rule the
%% reader's tokeniser lower-cases by and the translator writes by.
%%
%% It was ASCII only, and a head MENTION is written bare (`"casa" means
%% "house"' is typed `Casa means house'), so a mentioned word beginning
%% with an accented letter came out lower-case -- neither a name, which is
%% capitalised, nor a mention, which carries its marks -- and the sentence
%% was refused. `è is the past of "tenemos"' is the shape, and it went
%% unseen because a seed has to draw such a word into the head of a lesson
%% sentence before anything types it.
ng_cap(W, C) :- atom_codes(W, [195, B|R]), B >= 160, B =< 190, B =\= 183, !, B1 is B - 32, atom_codes(C, [195, B1|R]).
ng_cap(W, C) :- atom_codes(W, [C0|R]), C0 >= 224, C0 =< 254, C0 =\= 247, rt_chars, !, C1 is C0 - 32, atom_codes(C, [C1|R]).
ng_cap(W, C) :-
    atom_codes(W, [F|R]),
    ( F >= 97, F =< 122 -> F1 is F - 32 ; F1 = F ),
    atom_codes(C, [F1|R]).

%% ---- the assembler -------------------------------------------------------------------------
%% D dropped, an R run joined with `_', B a break, X refused outright; a
%% word keeps the case its token carries, so a proper noun stays one, and
%% a number is written as its digits; an M run is ONE mention between
%% quotation marks and a quoted token is written as it was. A comma is
%% never emitted.

normalise_assemble(_, Tags, _) :- memberchk('X', Tags), !, fail.      % outside: refused
normalise_assemble(Tokens, Tags, Text) :-
    na_zip(Tokens, Tags, Zs),
    na_split(Zs, Sents),
    na_texts(Sents, [], Texts),
    atomic_list_concat(Texts, ' ', Text).

na_zip([], [], []).
na_zip([T|Ts], [G|Gs], [T-G|Zs]) :- na_zip(Ts, Gs, Zs).

na_split([], []) :- !.
na_split(Zs, [S|Ss]) :- na_upto_b(Zs, S, Rest), na_split(Rest, Ss).

na_upto_b([], [], []).
na_upto_b([_-'B'|Zs], [], Zs) :- !.
na_upto_b([Z|Zs], [Z|S], Rest) :- na_upto_b(Zs, S, Rest).

%% a sentence a break left with no subject -- `Priya is a baker and is
%% licensed' -- takes the subject phrase of the sentence before it: the
%% state the assembler carries, as the grammar carries the last subject
na_texts([], _, []).
na_texts([S0|Ss], Last, Ts) :-
    (   \+ na_has_subject(S0), Last \== [] -> append(Last, S0, S) ; S = S0 ),
    na_words(S, Ws),
    ( Ws == [] -> Ts = Ts1 ; ng_stop(S, Stop), ng_text(Ws, Stop, T), Ts = [T|Ts1] ),
    na_subject(S, Last, Last1),
    na_texts(Ss, Last1, Ts1).

%% a sentence has a subject when it has an S, or a mention before its
%% first relation: `"casa" means "house"' is about the word
na_has_subject(S) :- memberchk(_-'S', S), !.
na_has_subject(S) :- append(Pre, [_-'R'|_], S), memberchk(_-'M', Pre), !.

%% the subject phrase: what stands before the S (a quantifier), the S, and
%% a relative clause `that is [not] ADJ' when one follows -- D and commas
%% aside, and never the `does not' before a verb: `Priya', or `every baker
%% that is licensed'; for a mention, everything before the relation but
%% the noise and a `does not': `"casa"', or `the noun "casa"'
na_subject(S, Last, Sub) :-
    (   append(Pre, [Subj-'S'|After], S)
    ->  findall(Z, ( member(Z, Pre), Z \= _-'D', Z \= ','-_ ), Pre1),
        na_relative(After, Rel),
        append(Pre1, [Subj-'S'|Rel], Sub)
    ;   append(Pre, [_-'R'|_], S), memberchk(_-'M', Pre)
    ->  findall(Z, ( member(Z, Pre), Z \= _-'D', Z \= ','-_, Z \= _-'K', Z \= _-'N' ), Sub)
    ;   Sub = Last
    ).
na_relative(After, [word(that, lower)-'K'|Rel]) :-
    na_skip_d(After, [word(that, _)-'K'|Rest]), !,
    na_through_c(Rest, Rel).
na_relative(_, []).
na_skip_d([_-'D'|Zs], Out) :- !, na_skip_d(Zs, Out).
na_skip_d([','-_|Zs], Out) :- !, na_skip_d(Zs, Out).
na_skip_d(Zs, Zs).
na_through_c([Z-'C'|_], [Z-'C']) :- !.
na_through_c([Z|Zs], [Z|Rest]) :- na_through_c(Zs, Rest).
na_through_c([], []).

na_words([], []).
na_words([_-'D'|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([','-_|Zs], Ws) :- !, na_words(Zs, Ws).
na_words([num(N)-_|Zs], [A|Ws]) :- !, format(atom(A), "~w", [N]), na_words(Zs, Ws).   % a number as its digits
na_words([quoted(W)-_|Zs], [Q|Ws]) :- !, na_quote([W], Q), na_words(Zs, Ws).            % a mention as it was
na_words([word(W, _)-'M'|Zs], [Q|Ws]) :- !,                                            % an M run: one mention
    na_mrun(Zs, Ms, Rest), na_quote([W|Ms], Q), na_words(Rest, Ws).
na_words([word(W, _)-'R'|Zs], [J|Ws]) :- !,
    na_run(Zs, Rs, Rest), atomic_list_concat([W|Rs], '_', J), na_words(Rest, Ws).
na_words([word(W, upper)-_|Zs], [C|Ws]) :- !, ng_cap(W, C), na_words(Zs, Ws).
na_words([word(W, lower)-_|Zs], [W|Ws]) :- na_words(Zs, Ws).

na_run([word(W, _)-'R'|Zs], [W|Rs], Rest) :- !, na_run(Zs, Rs, Rest).
na_run(Zs, [], Zs).

na_mrun([word(W, _)-'M'|Zs], [W|Ms], Rest) :- !, na_mrun(Zs, Ms, Rest).
na_mrun(Zs, [], Zs).
na_quote(Ws, Q) :- atomic_list_concat(Ws, ' ', J), atomic_list_concat(['"', J, '"'], Q).
