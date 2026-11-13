%% cocolog -- library/reasoning/corpus/build.pl: a language's vocabulary as a lesson,
%% written in the controlled English library(reasoning/reason) reads, out of
%% Apertium's dictionaries.
%%
%%     sh tools/corpus/fetch.sh                                  # the raw dictionaries into corpus/raw/
%%     cocolog -s library/reasoning/corpus/build.pl -- spanish   # writes corpus/vocabulary/spanish.txt
%%     cocolog -s library/reasoning/corpus/build.pl -- italian   # writes corpus/vocabulary/italian.txt
%%
%% WHAT IT READS. corpus/raw/apertium-eng-LANG.eng-LANG.dix is Apertium's
%% bilingual dictionary, one entry a line: the English word and its part of
%% speech on the left, the lesson's word on the right --
%%
%%     <e><p><l>house<s n="n"/></l><r>casa<s n="n"/><s n="f"/></r></p></e>
%%
%% -- an entry marked r="LR" is read only from English, r="RL" only into it.
%% corpus/raw/apertium-LANG.LANG.dix is the monolingual one: every lemma with
%% a stem and the PARADIGM that inflects it, and every paradigm as the endings
%% it adds with the tags each ending means --
%%
%%     <e lm="casa"><i>cas</i><par n="cas/a__n"/></e>
%%     <pardef n="cas/a__n"> <e><p><l>e</l><r>a<s n="n"/><s n="f"/><s n="pl"/></r></p></e> ... </pardef>
%%
%% -- so a noun's gender and plural, an adjective's four forms and a verb's
%% every person and tense are the stem with an ending, read off the paradigm.
%% corpus/raw/en-verbs.txt is pattern's table of English verbs, for the pasts
%% and participles English does not make by -ed (`ate', `eaten'), and
%% lexicon/class.txt -- WordNet's noun.person -- says which nouns are persons.
%%
%% WHAT IT WRITES, one lesson line each, in the shapes corpus/spanish.txt
%% already uses, so that the same reader and the same translator serve:
%%
%%     The feminine noun "casa" means "house".     "casas" is the plural of "casa".
%%     The masculine noun "problema" means "problem".   "problema" is not feminine.
%%     "amigo" is a person.
%%     The masculine adjective "rojo" means "red".  The feminine adjective "roja" means "red".
%%     The verb "come" means "eats".                "comen" is the plural of "come".
%%     "como" is the first person of "come".        "comió" is the past of "come".
%%     "comerá" is the future of "come".            "comido" is the participle of "come".
%%     "comería" is the conditional of "come".      "comerían" is the plural of "comería".
%%     "coma" is the subjunctive of "come".         "comiera" is the past subjunctive of "come".
%%     "comer" is the infinitive of "come".         "comiendo" is the gerund of "come".
%%     "come" is the imperative of "come".          "comas" is the negative imperative of "come".
%%     "comed" is the imperative of "comen".        "comáis" is the negative imperative of "comen".
%%     "pesadísimas" is the superlative of "pesadas".
%%     "ate" is the past of "eats".                 "eaten" is the participle of "eats".
%%     "running" is the gerund of "runs".           The adverb "rápidamente" means "quickly".
%%     The modal "puede" means "can".               "podría" is the conditional of "puede".
%%     The verb "hay" means "there is".             The number "cuatro" means "four".
%%     The masculine demonstrative "este" means "this".   "estos" is the plural of "este".
%%     The masculine determiner "otro" means "another".   The determiner "cada" means "each".
%%     The pronoun "esto" means "this".             The pronoun "esto" does not precede the verb.
%%
%% A gender is stated of every noun and a plural of every noun, adjective and
%% verb, so that no rule of the grammar lesson is relied on for a word whose
%% paradigm says otherwise: `"problema" is not feminine' is the denial that
%% lets the masculine fact win over `Every noun that ends in "a" is
%% feminine' (tr_gender/2 asks tr_holds/1). The words are ordered so that
%% the first meaning the translator finds is the canonical one: the
%% entries read both ways first, then those read only from the lesson's
%% language, then those read only from English. Multi-word entries, proper
%% nouns and English's own function words are left out -- a word is one
%% lower-case word of letters, and an English noun or adjective the
%% dictionary capitalises is lowered where the lesson's word is lower case
%% (a month, a day, a nationality: cb_common_words/2) -- except for the closed words the translator
%% has a slot for: a modal (`can', `may', `must', `should'), a demonstrative
%% or another determiner (`this', `another', `each', `much'), a pronoun that
%% stands alone (`this', `somebody', `nobody', `everything'), and `there is',
%% the one entry of more than a word, which is the verb `hay'. A pronoun the
%% dictionary gives that way is a tonic one, so it never precedes the verb.
%%
%% THE FILES ARE DATA AND THE PROGRAM IS THIS ONE FILE, the rule every
%% generator in the reasoning library follows: nothing of a lesson lives in
%% the code, and what is written is committed beside the lessons that were
%% written by hand.

:- use_module(library(reasoning/reason)).
:- use_module(library(reasoning/normalise)).
:- use_module(library(reasoning/translate)).     % tr_english_ing/2: the gerund rule the line must not repeat

%% split_string/4 answers STRINGS, and a "..." literal is codes unless the flag
%% says otherwise: a token compared with a literal never matched until it did
:- set_prolog_flag(double_quotes, string).

:- dynamic cb_par/3, cb_lemma/3, cb_en_verb/4, cb_person/1, cb_seen_f/2, cb_seen_e/2, cb_seen_pair/3, cb_formed/2, cb_en_done/1, cb_lang/1,
           cb_plain/2.

%% EVERY TEST OF A LINE IS A C BUILTIN. sub_string/5 is clauses here, and a
%% search with it walks the line a position at a time converting it to codes
%% each step: the first draft of this file did not finish the Spanish
%% dictionary in ten minutes. split_string/4, atom_string/2 and atom_concat/3
%% (in the modes that take the line apart) are C, and every test below is
%% one of those: a line is cut at `<' and `>' once, and a prefix is checked
%% with atom_concat(Prefix, _, Atom).
cb_prefix(Prefix, S) :- atom_string(A, S), atom_concat(Prefix, _, A).
cb_suffix(Suffix, S) :- atom_string(A, S), atom_concat(_, Suffix, A).


main :-
    current_prolog_flag(argv, [_|Args]),
    ( Args = [Lang|_] -> true ; Lang = spanish ),
    build(Lang).

cb_source(spanish, 'apertium-eng-spa.eng-spa.dix', 'apertium-spa.spa.dix', 'apertium/apertium-eng-spa and apertium/apertium-spa (GPL-2)').
cb_source(italian, 'apertium-eng-ita.eng-ita.dix', 'apertium-ita.ita.dix', 'apertium/apertium-eng-ita and apertium/apertium-ita (GPL-2)').

build(Lang) :-
    cb_source(Lang, BiFile, MonoFile, Credit),
    assertz(cb_lang(Lang)),
    normalise_corpus_dir(Dir),
    atomic_list_concat([Dir, '/raw/', BiFile], Bi),
    atomic_list_concat([Dir, '/raw/', MonoFile], Mono),
    atomic_list_concat([Dir, '/raw/en-verbs.txt'], EnVerbs),
    atomic_list_concat([Dir, '/vocabulary/', Lang, '.txt'], Out),
    format("reading ~w~n", [Mono]), cb_read_mono(Mono),
    aggregate_all(count, cb_lemma(_, _, _), NL), aggregate_all(count, cb_par(_, _, _), NP),
    format("   ~d lemmas, ~d paradigm endings~n", [NL, NP]),
    format("reading ~w~n", [EnVerbs]), cb_read_en_verbs(EnVerbs),
    cb_read_persons,
    format("reading ~w~n", [Bi]), cb_read_bilingual(Bi, Entries),
    length(Entries, NE), format("   ~d entries~n", [NE]),
    cb_order(Entries, Ordered),
    with_output_to(string(S), cb_write(Lang, Credit, Ordered)),
    string_codes(S, Codes), write_file_from_codes(Out, Codes),
    split_string(S, "\n", "", Ls), length(Ls, NLines0), NLines is NLines0 - 1,
    format("wrote ~w: ~d lines~n", [Out, NLines]).

%% ---- the monolingual dictionary: lemmas and paradigms ---------------------------

cb_read_mono(Path) :-
    read_file_to_codes(Path, Codes), split_string(Codes, "\n", " \t\r", Lines),
    cb_mono_lines(Lines, none).

cb_mono_lines([], _).
cb_mono_lines([L|Ls], P0) :-
    atom_string(A, L),
    (   atom_concat('<pardef ', _, A)
    ->  cb_attr(L, "n", Name), atom_string(P1, Name)
    ;   A == '</pardef>'
    ->  P1 = none
    ;   P0 \== none, atom_concat('<e', _, A)
    ->  cb_par_line(P0, L), P1 = P0
    ;   atom_concat('<e lm=', _, A)
    ->  cb_lemma_line(L), P1 = P0
    ;   P1 = P0
    ),
    cb_mono_lines(Ls, P1).

%% an ending of a paradigm: <e><p><l>SUFFIX</l><r>...<s n="tag"/>...</r></p></e>;
%% a joined form (clitics, <j/> or a nested <par>) and an analysis-only
%% variant (r="LR") are not forms the lesson would state
cb_par_line(P, L) :-
    split_string(L, "<>", "", Toks),
    \+ memberchk("j/", Toks), \+ memberchk("j /", Toks),
    \+ ( member(T, Toks), cb_prefix('par ', T) ),
    Toks = [_, ETok|_], \+ cb_lr(ETok),
    cb_l_text(Toks, Suffix),
    cb_tags(Toks, Tags), Tags \== [],
    !, assertz(cb_par(P, Suffix, Tags)).
cb_par_line(_, _).

%% the text between <l> and </l>: <l>s</l>, <l></l>, <l />, and <l><a/>questo</l>
%% -- the Italian demonstratives' generated forms carry an <a/> before the
%% word, and without it `questo' has no singular
cb_l_text(Toks, Suf) :- append(_, ["l", S, "/l"|_], Toks), !, atom_string(Suf, S).
cb_l_text(Toks, Suf) :- append(_, ["l", "", "a/", S, "/l"|_], Toks), !, atom_string(Suf, S).
cb_l_text(Toks, '') :- memberchk("l /", Toks), !.
cb_l_text(Toks, '') :- memberchk("l/", Toks), !.

%% every <s n="X"/> on the line, as atoms, in order (`s n="n" /' after the
%% metadix converter, `s n="n"/' as Apertium writes it)
cb_tags(Toks, Tags) :- findall(T, ( member(Tok, Toks), cb_tag_tok(Tok, T) ), Tags).
cb_tag_tok(Tok, T) :- cb_prefix('s n="', Tok), split_string(Tok, "\"", "", [_, V|_]), atom_string(T, V).

%% the entry's own token, `e r="LR"': read only from the left
cb_lr(ETok) :- split_string(ETok, "\"", "", Ps), memberchk("LR", Ps).
cb_rl(ETok) :- split_string(ETok, "\"", "", Ps), memberchk("RL", Ps).

%% a lemma entry: <e lm="casa"> [<par n="prefixes_n"/>] <i>STEM</i><par n="PARADIGM"/></e>;
%% the paradigm is the LAST par named, the stem the one <i> text, one word
cb_lemma_line(L) :-
    cb_attr(L, "lm", LmS), atom_string(Lemma, LmS),
    split_string(L, "<>", "", Toks),
    cb_i_text(Toks, Stem),
    findall(P, cb_par_ref(Toks, P), Ps), Ps \== [], last(Ps, Par),
    !, assertz(cb_lemma(Lemma, Stem, Par)).
cb_lemma_line(_).

%% the stem between <i> and </i>; the <l> text of an entry written as a
%% pair instead; and EMPTY for a verb whose paradigm carries the whole word
%% -- `ser' and `essere' are `<e lm="ser"><par n="/ser__vbser"/></e>', no
%% stem at all, and were the two verbs a lesson cannot do without
cb_i_text(Toks, Stem) :- append(_, ["i", S, "/i"|_], Toks), !, atom_string(Stem, S).
cb_i_text(Toks, Stem) :- append(_, ["l", S, "/l"|_], Toks), !, atom_string(Stem, S).
cb_i_text(_, '').

cb_par_ref(Toks, P) :- member(Tok, Toks), cb_prefix('par n="', Tok), split_string(Tok, "\"", "", [_, V|_]), atom_string(P, V).

%% the value of an attribute on the line: the part after `NAME="' up to the next quote
cb_attr(L, Name, Value) :-
    string_concat(Name, "=", Key), string_length(Key, KL), split_string(L, "\"", "", Parts),
    cb_attr_parts(Parts, Key, KL, Value).
%% the value follows a part that ends in `NAME=' (the quote was the cut)
cb_attr_parts([Before, V|_], Key, _, V) :- atom_string(KeyA, Key), cb_suffix(KeyA, Before), !.
cb_attr_parts([_, _|Rest], Key, KL, V) :- cb_attr_parts(Rest, Key, KL, V).

%% the forms of a lemma with their tags: the stem and each ending of its paradigm
cb_forms(Lemma, Forms) :-
    findall(F-Tags, ( cb_lemma(Lemma, Stem, Par), cb_stem_fits(Lemma, Stem, Par),
                      cb_par(Par, Suf, Tags), \+ memberchk(sup, Tags), \+ memberchk(comp, Tags),
                      atom_concat(Stem, Suf, F) ),
            Forms).                                   % a superlative (grandissimo) is not the adjective

%% A LEMMA WITH TWO STEMS UNDER ONE PARADIGM: apertium-ita gives `sottoporre'
%% as `sottop' and as `sottopo', both with antepo/rre__vblex, and the forms of
%% the first came first -- `"sottopne" means "subjects"', and `sottopongano'
%% was a word no lesson knew. The stem that fits is the one the paradigm's own
%% lemma ending completes to the lemma -- `antepo/rre' ends in `rre', and
%% `sottopo' and `rre' are `sottoporre' -- and where one fits, a stem under
%% the same paradigm that does not is left out; a stem alone under its
%% paradigm is kept, fitting or not, as it always was
cb_stem_fits(Lemma, Stem, Par) :-
    (   cb_par_ending(Par, E), atom_concat(Stem, E, Lemma) -> true
    ;   \+ ( cb_lemma(Lemma, S2, Par), S2 \== Stem, cb_par_ending(Par, E2), atom_concat(S2, E2, Lemma) )
    ).
%% the lemma ending a paradigm's name gives: after the `/' and before the
%% `__', a `(2)' of a second paradigm of one name left off -- `cas/a__n' is
%% `a'; a name with no `/' gives the whole word to the stem
cb_par_ending(Par, E) :-
    atomic_list_concat([Name|_], '__', Par),
    (   atomic_list_concat([_, E0], '/', Name) -> atomic_list_concat([E|_], '(', E0)
    ;   E = ''
    ).

%% the singular: tagged sg, or sp where one form is both numbers (città)
cb_sg(Forms, Tags, F) :- ( append(Tags, [sg], T1), cb_form(Forms, T1, F) -> true ; append(Tags, [sp], T2), cb_form(Forms, T2, F) ).

cb_form(Forms, Tags, F) :- member(F-Ts, Forms), cb_has_tags(Tags, Ts), !.

%% a verb's form: Apertium tags `ser' and `essere' vbser, `haber' and
%% `avere' vbhaver and the modals (`poder', `dovere') vbmod, where every
%% other verb is vblex
cb_verb_form(Forms, Tags, F) :- member(V, [vblex, vbser, vbhaver, vbmod]), cb_form(Forms, [V|Tags], F), !.

%% WHAT A LANGUAGE BUILDS ITS NEGATIVE IMPERATIVE ON: Spanish takes the
%% second person of the present subjunctive (`no comas'), Italian the
%% infinitive (`non mangiare'). It is a fact about the LANGUAGE and about
%% the tags its own dictionary uses, and this file is what reads a
%% language's dictionary, so it belongs here -- the translator asks the
%% lesson for `the negative imperative' and never learns which is which.
cb_negative_imperative(spanish, [prs, p2, sg]).
cb_negative_imperative(italian, [inf]).
%% ... and its PLURAL: Spanish takes the second person plural of the
%% present subjunctive (`no comáis'); Italian denies the plural with the
%% plural itself (`non mangiate'), so it states none and the translator
%% writes the affirmative form after the denial
cb_negative_imperative_plural(spanish, [prs, p2, pl]).
%% ... AND ITS COMMAND OF THE FIRST PERSON PLURAL, `let us': Italian's is
%% what its dictionary tags `imp p1 pl', the indicative's own form
%% (`finiamo'), and Spanish's is the first person plural of the present
%% subjunctive (`dejemos'), which its dictionary tags no imperative at all
cb_hortative(italian, [imp, p1, pl]).
cb_hortative(spanish, [prs, p1, pl]).
%% a form the language commands with: the plural imperative, and the negative one where it has a plural of its own --
%% and Italian's present subjunctive, which is the imperative of `essere' and `avere' (`siate', `abbiate') where its
%% dictionary tags the indicative's `siete' with the tag
cb_command_plural(Forms, _, F) :- cb_verb_form(Forms, [imp, p2, pl], I), I == F, !.
cb_command_plural(Forms, _, F) :- cb_lang(Lg), cb_negative_imperative_plural(Lg, Tags), cb_verb_form(Forms, Tags, N), N == F, !.
cb_command_plural(_, prs, _) :- cb_lang(italian).
cb_has_tags([], _).
cb_has_tags([T|Ts], Have) :- memberchk(T, Have), cb_has_tags(Ts, Have).

%% ---- English's irregular verbs, and the persons ------------------------------------

%% pattern's en-verbs.txt: base,,,3sg,,gerund,,,,,past,participle,...
cb_read_en_verbs(Path) :-
    read_file_to_codes(Path, Codes), split_string(Codes, "\n", " \t\r", Lines),
    forall(( member(L, Lines), L \== "", \+ cb_prefix(';', L) ), cb_en_verb_line(L)).
cb_en_verb_line(L) :-
    split_string(L, ",", "", Fs),
    (   Fs = [B, _, _, _, _, Ger, _, _, _, _, Past, Pp|_], B \== "", Past \== ""
    ->  atom_string(Base, B), atom_string(PastA, Past), ( Pp == "" -> PpA = PastA ; atom_string(PpA, Pp) ),
        ( Ger == "" -> GerA = none ; atom_string(GerA, Ger) ),
        assertz(cb_en_verb(Base, PastA, PpA, GerA))
    ;   true
    ).

%% a past English makes on its own: -ed, -d after e, -ied for a consonant and y
cb_en_regular_past(Base, Past) :-
    (   atom_concat(Base, ed, Past) -> true
    ;   atom_concat(Base, d, Past), sub_atom(Base, _, 1, 0, e) -> true
    ;   atom_concat(Stem, y, Base), atom_concat(Stem, ied, Past) -> true
    ).

cb_read_persons :-
    normalise_lexicon(class, Words),
    forall(member(W, Words), assertz(cb_person(W))).

%% ---- the bilingual dictionary ----------------------------------------------------

%% THE BILINGUAL DICTIONARY IS THE SHORT ONE, and a word it lacks is a word
%% with NO FORM AT ALL, though the monolingual has its every form: Italian's
%% `muovere', `rendere', `spegnere', `sparire', `riprendere' are all there
%% with their paradigms and none of them has an English entry. What a hand
%% has to add is therefore only the MEANING, and it is added in the
%% dictionary's own shape -- corpus/extra/eng-LANG.dix, one entry a line,
%% read BEFORE the raw one so that its entries come first in their class,
%% as corpus/extra/LANG.txt's lines do -- and every form then comes out of
%% the paradigm exactly as a dictionary word's does. A line that is not an
%% entry is a comment.
cb_read_bilingual(Path, Entries) :-
    cb_supplement(Path, Supp),
    ( catch(read_file_to_codes(Supp, SCodes), _, fail) -> true ; SCodes = [] ),
    read_file_to_codes(Path, Codes), split_string(Codes, "\n", " \t\r", Lines),
    split_string(SCodes, "\n", " \t\r", SLines),
    findall(E, ( member(L, SLines), cb_bi_line(L, E) ), E1),
    findall(E, ( member(L, Lines), cb_bi_line(L, E) ), E2),
    length(E1, N1), format("   ~d supplement entries from ~w~n", [N1, Supp]),
    append(E1, E2, Entries0),
    cb_common_words(Entries0, Entries).

%% A MONTH, A DAY AND A NATIONALITY ARE COMMON WORDS IN ITALIAN AND SPANISH
%% and capitalised ones in English, so the dictionary writes `January'
%% against `gennaio' -- and an English word of lower-case letters was the
%% test, so none of them had a meaning: `il 20 gennaio 2014' was refused for
%% a word every dictionary has. A noun or an adjective whose English is
%% capitalised, and whose own word is not, is read with the English
%% lowered, which is how every English word of a lesson is written; a proper
%% noun is tagged np and never reaches cb_pos/2. BUT ONLY WHERE THE ENGLISH
%% WORD HAS NO LOWER-CASE ENTRY OF ITS OWN IN THAT CLASS: `March' is `marzo'
%% and `march' is `marcia', and the IR carries the English word and not its
%% capital, so a march read as a month would be a wrong translation where
%% no month at all is only a refusal.
cb_common_words(Es0, Es) :-
    retractall(cb_plain(_, _)),
    forall(( member(e(_, P, En, _, _), Es0), atom(En) ), ( cb_plain(En, P) -> true ; assertz(cb_plain(En, P)) )),
    findall(E, ( member(E0, Es0), cb_common_word(E0, E) ), Es).
cb_common_word(e(D, P, lowered(En), Fo, T), e(D, P, En, Fo, T)) :- !, \+ cb_plain(En, P).
cb_common_word(E, E).

%% corpus/raw/apertium-eng-ita.eng-ita.dix -> corpus/extra/eng-ita.dix
cb_supplement(Path, Supp) :-
    file_base_name(Path, Base), atom_concat('apertium-', Rest, Base), atomic_list_concat([Pair|_], '.', Rest),
    normalise_corpus_dir(Dir), atomic_list_concat([Dir, '/extra/', Pair, '.dix'], Supp).

%% e(Direction, Pos, English, Foreign, ForeignTags): one line, one word a side
cb_bi_line(L, E) :-
    cb_prefix('<e', L),
    split_string(L, "<>", "", Toks),
    \+ memberchk("g", Toks),
    Toks = [_, ETok|_],
    (   cb_lr(ETok) -> Dir = lr
    ;   cb_rl(ETok) -> Dir = rl
    ;   Dir = both
    ),
    cb_bi_entry(Toks, Dir, E), !.

%% the ordinary entry: no <par>, the class from the English side's tags, the
%% word admitted by its class -- or the one paradigm that adds nothing to the
%% word, SP: the Italian noun is the same in both numbers (`serenità',
%% `durabilità'), 428 nouns of eng-ita that this rule dropped whole, and
%% their forms come from the monolingual paradigm as every noun's do
cb_bi_entry(Toks, Dir, e(Dir, Pos, En, Fo, RTags)) :-
    \+ ( member(T, Toks), cb_prefix('par ', T), \+ cb_prefix('par n="SP"', T) ),
    cb_side(Toks, "l", "/l", EnS, LTags), cb_side(Toks, "r", "/r", FoS, RTags),
    cb_pos(LTags, Pos),
    atom_string(En0, EnS), atom_string(Fo, FoS),
    cb_english_side(Pos, En0, En, W),
    cb_admits(Pos, W), cb_foreign_word(Fo).
%% a number: the dictionary writes the cardinals as a bare pair with the
%% paradigm named beside it -- <l>four</l><r>cuatro</r><par n="three__num"/>
%% -- and the two paradigms that add nothing to the word are the numbers
cb_bi_entry(Toks, Dir, e(Dir, number, En, Fo, [])) :-
    member(T, Toks), cb_prefix('par n="', T), split_string(T, "\"", "", [_, P|_]), memberchk(P, ["three__num", "twenty__num"]),
    cb_side(Toks, "l", "/l", EnS, []), cb_side(Toks, "r", "/r", FoS, []),
    atom_string(En, EnS), atom_string(Fo, FoS),
    cb_english_word(En), cb_foreign_word(Fo).
%% `there is': the one entry of more than a word a lesson states, because
%% its word is a verb of its own -- <l>there<b/>is<s n="vblex"/></l><r>hay...
%% (the cut at `<' and `>' leaves an empty field between `/>' and `</l>')
cb_bi_entry(Toks, Dir, e(Dir, existential, 'there is', Fo, RTags)) :-
    \+ ( member(T, Toks), cb_prefix('par ', T) ),
    append(_, ["l", "there", B, "is", VT, "", "/l"|_], Toks), memberchk(B, ["b/", "b /"]), cb_prefix('s n="vblex"', VT),
    cb_side(Toks, "r", "/r", FoS, RTags), atom_string(Fo, FoS), cb_foreign_word(Fo).

%% a capitalised noun or adjective as lowered(Word), which cb_common_words/2
%% keeps or drops once every entry has been read; any other word as itself
cb_english_side(Pos, En0, lowered(W), W) :-
    memberchk(Pos, [noun, adjective]),
    atom_codes(En0, [C|Cs]), C >= 0'A, C =< 0'Z, !,
    L is C + 32, atom_codes(W, [L|Cs]).
cb_english_side(_, En, En, En).

%% the word and the tags between an opening and a closing token; a <b/>
%% between them is a blank, so the entry is more than one word
cb_side(Toks, Open, Close, Word, Tags) :-
    append(_, [Open|After], Toks), append(Inside, [Close|_], After), !,
    \+ memberchk("b/", Inside), \+ memberchk("b /", Inside),
    Inside = [Word|Rest], \+ cb_prefix('s n=', Word),              % the word comes first, or the side is bare
    cb_tags(Rest, Tags).

%% the class, from the English side's tags: the first tag for an open
%% class; a determiner's kind (dem, ind, qnt) is settled by its forms, and
%% a pronoun is one of the English words that stand alone (`nobody', `this'),
%% which the dictionary tags tn (tonic) on most entries and not on all
%% (`nobody<prn>'), so the English word decides and a clitic never passes
cb_pos([n|_], noun).       cb_pos([adj|_], adjective). cb_pos([vblex|_], verb).  cb_pos([vbser|_], verb).
cb_pos([vaux|_], modal).   cb_pos([det|_], det).       cb_pos([prn|_], pronoun).
cb_pos([adv|_], adverb).   cb_pos([preadv|_], adverb). cb_pos([pr|_], preposition). cb_pos([num|_], number).
cb_pos([cnjcoo|_], conjunction).

%% what a class admits: an open class any word of letters that is not one
%% of English's own, and a closed class exactly the words the translator
%% has a slot for -- a modal it writes in the past and the conditional
%% (`could', `might'), a determiner it puts in the number of its noun
%% (`this' and `these', `much' and `many', `another' and `other'), a
%% pronoun it takes for a subject or an object of the third person
cb_admits(modal, W) :- !, cb_letters(W), memberchk(W, [can, may, might, must, should, could]).
cb_admits(det, W) :- !, cb_letters(W), memberchk(W, [this, that, another, other, each, every, much, many, several, both, some, such, few, little]).
cb_admits(pronoun, W) :- !, cb_letters(W),
    memberchk(W, [this, that, something, anything, everything, nothing, somebody, anybody, nobody, everybody,
                  someone, anyone, everyone, all, another, both, many, few, several, none, others]).
cb_admits(_, W) :- cb_english_word(W).

%% an English word: lower-case letters, and not one of the words the
%% translator knows on its own, nor a modal it cannot conjugate
cb_english_word(W) :- cb_letters(W), \+ cb_english_own(W).
cb_letters(W) :- atom_codes(W, Cs), Cs \== [], forall(member(C, Cs), ( C >= 0'a, C =< 0'z )).
%% `be' and `have' are kept: the lesson gives them as `is' and `has', which is
%% what the translator's English knows them as, and `ser', `estar' and
%% `tener' hang on them. `do' is not: `does' is the word that fronts a question
cb_english_own(be) :- !, fail.
cb_english_own(have) :- !, fail.
cb_english_own(W) :-
    memberchk(W, [a, an, the, and, or, not, no, yes, is, are, am, was, were, been, being,
                  do, does, did, has, had, will, would, shall, should, can, could, may, might, must, ought,
                  i, you, he, she, it, we, they, me, him, her, us, them, my, your, his, its, our, their,
                  what, who, whom, where, when, which, why, how, this, that, these, those,
                  in, on, at, to, of, with, from, for, by, about, into, under, over]).

%% a word of the lesson's language: lower-case letters, accented ones
%% included (UTF-8 bytes past 127), and no capital -- a Latin-1 capital is
%% the byte 195 followed by 128..158
cb_foreign_word(W) :-
    atom_codes(W, Cs), Cs \== [], cb_lower_codes(Cs).
cb_lower_codes([]).
cb_lower_codes([C|Cs]) :- C >= 0'a, C =< 0'z, !, cb_lower_codes(Cs).
cb_lower_codes([195, C|Cs]) :- !, ( C >= 128, C =< 158 -> fail ; true ), cb_lower_codes(Cs).
cb_lower_codes([C|_]) :- C >= 192, C =< 222, current_prolog_flag(text_units, characters), !, fail.    % a capital, as a code point
cb_lower_codes([C|Cs]) :- C >= 128, !, cb_lower_codes(Cs).

%% ---- the order, so the first meaning is the canonical one ------------------------

%% both ways first; then a lesson word read only into English that no
%% entry gave yet; then an English word read only into the lesson that
%% no entry gave yet. The dictionary's own order within each. And the
%% NOUNS FIRST, then the verbs, the adjectives, the adverbs and the closed
%% classes: the translator takes the first meaning it finds, and a word
%% that is a noun and something else -- `periódico', a newspaper and
%% periodic; `médica', a doctor and medical -- is more often the noun
%% where a sentence puts it.
cb_order(Entries, Ordered) :-
    findall(E, ( member(E, Entries), E = e(both, _, _, _, _) ), Both),
    forall(member(e(_, P, En, Fo, _), Both), cb_note(P, En, Fo)),
    findall(E, ( member(E, Entries), E = e(rl, P, _, Fo, _), \+ cb_seen_f(Fo, P) ), Rl0),
    forall(member(e(_, P, En, Fo, _), Rl0), cb_note(P, En, Fo)),
    findall(E, ( member(E, Entries), E = e(lr, P, En, Fo, _), ( \+ cb_seen_e(En, P) ; \+ cb_seen_f(Fo, P) ) ), Lr0),
    append([Both, Rl0, Lr0], ByDirection),
    findall(E, ( member(Class, [noun, verb, modal, existential, adjective, adverb, preposition, number, det, pronoun, conjunction]),
                 member(E, ByDirection), E = e(_, Class, _, _, _) ),
            Ordered0),
    cb_dedupe(Ordered0, Ordered1),
    findall(E, ( member(E, Ordered1), \+ cb_stray_adverb(E, Ordered1) ), Ordered).

%% AN ADVERB THAT MEANS ITSELF, FOR A WORD THAT IS AN ADJECTIVE, is a musical term the English dictionary
%% carries (`largo', `allegro') and no adverb of the lesson's language: `un periodo largo para Moratti'
%% read `largo' as that adverb, which the writer gave back untranslated (`a period for Moratti largo')
cb_stray_adverb(e(_, adverb, W, W, _), Es) :- memberchk(e(_, adjective, _, W, _), Es).

%% one entry per class, English word and lesson word: the dictionary gives
%% `another' and `otro' three times, once a direction and gender, and the
%% lines say the same each time. Keyed on the WORD, as cb_note/3 is: a
%% first draft keyed it on the class and took five minutes over what the
%% word makes an indexed lookup
cb_dedupe([], []).
cb_dedupe([E|Es], Out) :-
    E = e(_, Class, En, Fo, _),
    (   cb_seen_pair(Fo, Class, En) -> Out = Out1
    ;   assertz(cb_seen_pair(Fo, Class, En)), Out = [E|Out1]
    ),
    cb_dedupe(Es, Out1).
cb_note(P, En, Fo) :-                                            % indexed on the WORD, the selective argument
    ( cb_seen_f(Fo, P) -> true ; assertz(cb_seen_f(Fo, P)) ),
    ( cb_seen_e(En, P) -> true ; assertz(cb_seen_e(En, P)) ).

%% ---- the lines ----------------------------------------------------------------------

cb_write(Lang, Credit, Entries) :-
    length(Entries, N),
    format("# library/reasoning/corpus/vocabulary/~w.txt -- the vocabulary of the lesson, as lesson lines~n", [Lang]),
    format("# WRITTEN BY library/reasoning/corpus/build.pl and never by hand: ~d dictionary entries from~n", [N]),
    format("# ~w, the English pasts from clips/pattern (BSD),~n", [Credit]),
    format("# the persons from WordNet's noun.person. Learn it after corpus/~w.txt, which holds the~n", [Lang]),
    format("# grammar: cocolog -s library/reasoning/teach.pl -- ~w. A line beginning # is a comment.~n", [Lang]),
    cb_extra(Lang),
    forall(member(E, Entries), cb_entry(E)).

%% THE WORDS APERTIUM DOES NOT CARRY GO HERE AND NOT IN THE HAND LESSON, and
%% the reason is the TAGGER. `corpus/<language>.txt' is the generator's
%% corpus -- it draws its lesson shapes from those lines -- so a word added
%% there changes the training pairs, and `generated/' and `model.rows' must
%% be regenerated with it, which re-rolls every minority shape the network
%% learned by the luck of its minimum. Measured: FOUR lines (`perche',
%% `porque' and the two prepositions meaning `by') took the adjective grid
%% from 0.60 to 0.25 and put test/tagger.pl RED -- the fifth firing of that
%% coin toss.
%%
%% The VOCABULARY directory is not read by the generator, so a line put here
%% reaches the translator and the tagger never sees it.
%%
%% AND IT IS WRITTEN FIRST, because a lesson says what a word MEANS and what
%% classes it has and never which meaning belongs to which class, so the
%% FIRST meaning wins wherever one has to be chosen. Every line here is here
%% because the dictionary's meaning is wrong or missing, so the hand-written
%% one belongs in front of it -- and the layering that gives is the one the
%% project already has: corpus/<language>.txt, then these, then Apertium.
%% Appended, `The masculine noun "sabato" means "saturday".' lost to the
%% dictionary's `sabbath' and could not be corrected at all.
cb_extra(Lang) :-
    normalise_corpus_dir(Dir),
    atomic_list_concat([Dir, '/extra/', Lang, '.txt'], File),
    (   catch(read_file_to_codes(File, Codes), _, fail)
    ->  atom_codes(A, Codes), split_string(A, "\n", " \t\r", Lines),
        forall( ( member(L, Lines), L \== "", \+ sub_string(L, 0, 1, _, "#") ),
                format("~w~n", [L]) )
    ;   true
    ).

cb_entry(e(_, noun, En, Fo, RTags)) :- !,
    cb_forms(Fo, Forms),
    (   cb_sg(Forms, [n, m], M), cb_sg(Forms, [n, f], F), M \== F
    ->  (   memberchk(f, RTags) -> cb_noun(F, feminine, En, Forms, f)          % `daughter' is hijo<f>: hija
        ;   memberchk(m, RTags) -> cb_noun(M, masculine, En, Forms, m)
        ;   cb_noun(M, masculine, En, Forms, m), cb_noun(F, feminine, En, Forms, f)
        )
    %% ONE SINGULAR FOR BOTH GENDERS AND A PLURAL FOR EACH: `socialista',
    %% `solista', `collega' -- `i socialisti' and `le socialiste'. Stated as
    %% the feminine noun it had only the feminine plural, and `los socialistas
    %% vascos' came out `le socialiste basche'. It is a noun of no gender,
    %% masculine where nothing says which, the masculine plural first; an
    %% entry that names the gender still takes it. Only where the PLURALS
    %% differ: Spanish's `capital', `cometa', `orden' are two nouns of one
    %% spelling, the gender with the sense, and they keep what they had
    ;   cb_sg(Forms, [n, m], W), cb_sg(Forms, [n, f], W),
        cb_form(Forms, [n, m, pl], PM), cb_form(Forms, [n, f, pl], PF), PM \== PF,
        \+ memberchk(f, RTags)
    ->  cb_noun_common(W, En, Forms)
    ;   cb_sg(Forms, [n, f], F) -> cb_noun(F, feminine, En, Forms, f)
    %% ONE FORM FOR BOTH GENDERS COMES BEFORE A DIFFERENT MASCULINE ONE: a
    %% paradigm that has both names the masculine for an APOCOPE. `generale'
    %% is `generali' in the plural for either gender and `general' only
    %% before a name, and read masculine first the noun was stated as
    %% `general', with no plural -- so `I generali' had no noun in it and read
    %% as an article, an adjective and a noun left out. One paradigm in
    %% either dictionary has the pair, general/e__n; where the two forms are
    %% the same word (`presente', `custode') the masculine stays stated.
    ;   cb_sg(Forms, [n, mf], W), cb_sg(Forms, [n, m], M0), M0 \== W -> cb_noun(W, none, En, Forms, mf)
    ;   cb_sg(Forms, [n, m], M) -> cb_noun(M, masculine, En, Forms, m)
    ;   cb_sg(Forms, [n, mf], W) -> cb_noun(W, none, En, Forms, mf)
    ;   cb_noun(Fo, none, En, [], none)
    ).
cb_entry(e(_, adjective, En, Fo, _)) :- !,
    cb_forms(Fo, Forms),
    (   cb_sg(Forms, [adj, m], M), cb_sg(Forms, [adj, f], F), M \== F
    ->  cb_adjective(M, masculine, En, Forms, m), cb_adjective(F, feminine, En, Forms, f)
    ;   cb_sg(Forms, [adj, mf], W) -> cb_adjective(W, none, En, Forms, mf)
    ;   cb_sg(Forms, [adj, m], W), cb_sg(Forms, [adj, f], W),
        cb_form(Forms, [adj, m, pl], PM), cb_form(Forms, [adj, f, pl], PF), PM \== PF
    ->  cb_adjective_common(W, En, PM, PF)
    ;   cb_sg(Forms, [adj, m], M) -> cb_adjective(M, none, En, Forms, m)
    ;   cb_adjective(Fo, none, En, [], none)
    ),
    cb_superlatives(Fo, Forms).
cb_entry(e(_, verb, En, Fo, _)) :- !,
    cb_forms(Fo, Forms),
    (   cb_verb_form(Forms, [pri, p3, sg], L)
    ->  cb_third(En, En3), cb_line('The verb "~w" means "~w".', [L, En3]),
        cb_verb_forms(L, Forms), cb_english_verb(En, En3)
    ;   true                                                        % no paradigm: no lexeme to state
    ).
%% a modal: its third person as the lexeme and every form a verb has; its
%% English past and conditional are the translator's own (`could', `might')
cb_entry(e(_, modal, En, Fo, _)) :- !,
    cb_forms(Fo, Forms),
    (   cb_verb_form(Forms, [pri, p3, sg], L)
    ->  cb_line('The modal "~w" means "~w".', [L, En]), cb_verb_forms(L, Forms)
    ;   true
    ).
cb_entry(e(_, existential, En, Fo, _)) :- !, cb_line('The verb "~w" means "~w".', [Fo, En]).
%% a determiner: a demonstrative when the dictionary tags it so on either
%% side, in its genders with their plurals; a pronoun the same way, and
%% since it is one that stands alone it never precedes the verb
cb_entry(e(_, det, En, Fo, RTags)) :- !,
    cb_forms(Fo, Forms),
    ( ( memberchk(dem, RTags) ; cb_form(Forms, [det, dem], _) ) -> Kind = demonstrative ; Kind = determiner ),
    cb_closed(Kind, det, En, Fo, Forms).
cb_entry(e(_, pronoun, En, Fo, _)) :- !,
    cb_forms(Fo, Forms), cb_closed(pronoun, prn, En, Fo, Forms).
cb_entry(e(_, adverb, En, Fo, _)) :- !, cb_line('The adverb "~w" means "~w".', [Fo, En]).
cb_entry(e(_, preposition, En, Fo, _)) :- !, cb_line('The preposition "~w" means "~w".', [Fo, En]).
cb_entry(e(_, number, En, Fo, _)) :- !, cb_line('The number "~w" means "~w".', [Fo, En]).
cb_entry(e(_, conjunction, En, Fo, _)) :- !, cb_line('The conjunction "~w" means "~w".', [Fo, En]).
cb_entry(_).
%% THE ABSOLUTE SUPERLATIVE, `le pesantissime accuse': every form the
%% paradigm tags sup, stated of the plain form in its own gender and number
%% -- `"pesantissime" is the superlative of "pesanti".' -- which the reader
%% takes as the lesson's word for `very' before that form. Once a form, as
%% a verb's forms are once a lexeme.
cb_superlatives(Fo, Forms) :-
    forall(( cb_lemma(Fo, Stem, Par), cb_par(Par, Suf, Tags), memberchk(sup, Tags),
             atom_concat(Stem, Suf, S), \+ cb_formed(S, superlative), cb_sup_base(Forms, Tags, B) ),
           ( assertz(cb_formed(S, superlative)), cb_line('"~w" is the superlative of "~w".', [S, B]) )).
cb_sup_base(Forms, Tags, B) :-
    ( memberchk(pl, Tags) -> N = pl ; N = sg ),
    ( memberchk(f, Tags) -> G = f ; G = m ),
    ( cb_form(Forms, [adj, G, N], B) -> true ; cb_form(Forms, [adj, mf, N], B) ).

cb_line(Fmt, Args) :- format(Fmt, Args), nl.

%% a closed word in its genders: the masculine and the feminine singular
%% when the paradigm has both, the one form for both genders, or the word
%% as the dictionary wrote it when it has no paradigm of that class
cb_closed(Kind, Tag, En, Fo, Forms) :-
    (   cb_sg(Forms, [Tag, m], M), cb_sg(Forms, [Tag, f], F), M \== F
    ->  cb_closed_word(Kind, Tag, M, masculine, En, Forms, m), cb_closed_word(Kind, Tag, F, feminine, En, Forms, f)
    ;   cb_sg(Forms, [Tag, mf], W) -> cb_closed_word(Kind, Tag, W, none, En, Forms, mf)
    ;   cb_sg(Forms, [Tag, m], M) -> cb_closed_word(Kind, Tag, M, masculine, En, Forms, m)
    ;   cb_sg(Forms, [Tag, f], F) -> cb_closed_word(Kind, Tag, F, feminine, En, Forms, f)
    ;   cb_closed_word(Kind, Tag, Fo, none, En, [], none)
    ).

%% its line, its plural once whatever classes the word has (`estos' is the
%% plural of the demonstrative and of the pronoun alike), and for a pronoun
%% that it stands after the verb
cb_closed_word(Kind, Tag, W, G, En, Forms, GT) :-
    (   G == none -> cb_line('The ~w "~w" means "~w".', [Kind, W, En])
    ;   cb_line('The ~w ~w "~w" means "~w".', [G, Kind, W, En])
    ),
    (   cb_formed(W, Kind) -> true
    ;   assertz(cb_formed(W, Kind)),
        (   GT \== none, cb_form(Forms, [Tag, GT, pl], P), P \== W, \+ cb_formed(W, plural)
        ->  assertz(cb_formed(W, plural)), cb_line('"~w" is the plural of "~w".', [P, W])
        ;   true
        ),
        ( Kind == pronoun -> cb_line('The pronoun "~w" does not precede the verb.', [W]) ; true )
    ).

%% a noun: its gender stated, a denial where the grammar's rule would say
%% otherwise, its plural, and whether it is a person
cb_noun(W, G, En, Forms, Tag) :-
    (   G == feminine -> cb_line('The feminine noun "~w" means "~w".', [W, En])
    ;   G == masculine -> cb_line('The masculine noun "~w" means "~w".', [W, En]),
        ( sub_atom(W, _, 1, 0, a) -> cb_line('"~w" is not feminine.', [W]) ; true )
    ;   cb_line('The noun "~w" means "~w".', [W, En]),
        %% ONE FORM FOR BOTH GENDERS TAKES THE MASCULINE ARTICLE when nothing
        %% says which: `un soccorritore' is `socorrista' in Spanish, and with
        %% the grammar's rule that a noun ending in `a' is feminine it came
        %% out `una socorrista'
        ( G == none, Tag == mf, sub_atom(W, _, 1, 0, a) -> cb_line('"~w" is not feminine.', [W]) ; true )
    ),
    (   cb_formed(W, noun) -> true
    ;   assertz(cb_formed(W, noun)),
        (   Tag \== none, cb_form(Forms, [n, Tag, pl], P), P \== W
        ->  cb_line('"~w" is the plural of "~w".', [P, W])
        %% ONE FORM FOR BOTH NUMBERS IS ITS OWN PLURAL: `città', `crisis'.
        %% Italian states no plural rule, so a noun with no plural line
        %% could not be written in the plural at all -- `de las ciudades'
        %% refused into Italian for want of `delle città'
        ;   Tag \== none, cb_form(Forms, [n, Tag, sp], W)
        ->  cb_line('"~w" is the plural of "~w".', [W, W])
        ;   true
        ),
        ( cb_person(En) -> cb_line('"~w" is a person.', [W]) ; true )
    ).

%% a noun with one singular for both genders: no gender, the masculine
%% article where nothing says which, and each plural, the masculine first
%% and the feminine one said to be, so that an adjective of the same shape
%% agrees (below)
cb_noun_common(W, En, Forms) :-
    cb_line('The noun "~w" means "~w".', [W, En]),
    ( sub_atom(W, _, 1, 0, a) -> cb_line('"~w" is not feminine.', [W]) ; true ),
    (   cb_formed(W, noun) -> true
    ;   assertz(cb_formed(W, noun)),
        cb_form(Forms, [n, m, pl], PM), cb_form(Forms, [n, f, pl], PF),
        cb_line('"~w" is the plural of "~w".', [PM, W]),
        cb_line('"~w" is the plural of "~w".', [PF, W]),
        cb_line('"~w" is feminine.', [PF]),
        ( cb_person(En) -> cb_line('"~w" is a person.', [W]) ; true )
    ).

%% AN ADJECTIVE WITH ONE SINGULAR FOR BOTH GENDERS AND A PLURAL FOR EACH:
%% `ottimista' is `ottimisti' and `ottimiste'. Stated with the masculine
%% plural alone it wrote `le previsioni ... non sono ottimisti' once the noun
%% of the same spelling stopped stating the feminine one first, and the
%% feminine one said to be is what the writer asks for a feminine noun
%% (tr_adjective_plural/5)
cb_adjective_common(W, En, PM, PF) :-
    cb_line('The adjective "~w" means "~w".', [W, En]),
    (   cb_formed(W, adjective) -> true
    ;   assertz(cb_formed(W, adjective)),
        cb_line('"~w" is the plural of "~w".', [PM, W]),
        cb_line('"~w" is the plural of "~w".', [PF, W]),
        cb_line('"~w" is feminine.', [PF])
    ).

cb_adjective(W, G, En, Forms, Tag) :-
    (   G == feminine -> cb_line('The feminine adjective "~w" means "~w".', [W, En])
    ;   G == masculine -> cb_line('The masculine adjective "~w" means "~w".', [W, En])
    ;   cb_line('The adjective "~w" means "~w".', [W, En])
    ),
    (   cb_formed(W, adjective) -> true
    ;   assertz(cb_formed(W, adjective)),
        (   Tag \== none, cb_form(Forms, [adj, Tag, pl], P), P \== W
        ->  cb_line('"~w" is the plural of "~w".', [P, W])
        ;   true
        )
    ).

cb_past_spelling(W, S) :-
    cb_lang(italian), atom_concat(Stem, 'è', W), Stem \== '', !, atom_concat(Stem, ette, S).
cb_past_spelling(W, W).

%% a verb's forms, once per lexeme: the plural, the persons, the past, the
%% future and the conditional with theirs, the participle, the infinitive
%% and the gerund
cb_verb_forms(L, _) :- cb_formed(L, verb), !.
cb_verb_forms(L, Forms) :-
    assertz(cb_formed(L, verb)),
    cb_tense(Forms, pri, L, plural_of),
    %% ITALIAN'S `-ere' VERBS OF ONE PARADIGM HAVE THEIR PRETERITE IN `-è' (`insistè',
    %% `esistè', `credè'), a spelling no Italian page prints; the same verb's
    %% plural is `-erono' and the page says `insistette', `esistette', `credette'
    %% (and `insistettero'). The third person is stated with `-ette' -- the form
    %% a page has and the one a writer should write -- and its plural in `-ettero'
    %% before the dictionary's own, which is then only read
    ( cb_verb_form(Forms, [ifi, p3, sg], Past0), cb_past_spelling(Past0, Past)
    ->  cb_line('"~w" is the past of "~w".', [Past, L]),
        (   Past \== Past0, cb_verb_form(Forms, [pri, p3, pl], PresPl0), cb_verb_form(Forms, [ifi, p3, pl], PastPl0),
            atom_concat(PlStem, erono, PastPl0), atom_concat(PlStem, ettero, PastPl)
        ->  cb_line('"~w" is the past of "~w".', [PastPl, PresPl0])
        ;   true
        ),
        cb_tense(Forms, ifi, Past, past_of)
    ;   true
    ),
    %% the imperfect is a tense of its own -- `estaba', `tenía', `era' -- stated
    %% as the imperfect, after the preterite's past: a page is read in either,
    %% and each is written back as it was read (the past, which English has
    %% only the one of, is the preterite)
    ( cb_verb_form(Forms, [pii, p3, sg], Imp), Imp \== Past -> cb_line('"~w" is the imperfect of "~w".', [Imp, L]), cb_tense(Forms, pii, Imp, imperfect_of) ; true ),
    ( cb_verb_form(Forms, [fti, p3, sg], Fut) -> cb_line('"~w" is the future of "~w".', [Fut, L]), cb_tense(Forms, fti, Fut, plural_of) ; true ),
    ( cb_verb_form(Forms, [cni, p3, sg], Cond) -> cb_line('"~w" is the conditional of "~w".', [Cond, L]), cb_tense(Forms, cni, Cond, plural_of) ; true ),
    %% THE SUBJUNCTIVE IS A FORM THE READER NEEDS AND ENGLISH DOES NOT MARK.
    %% `che il militare volesse' wants one where `that the soldier wanted'
    %% has none, so the translator reads a subjunctive as the TENSE it
    %% stands for and writes the indicative back -- which it can only do if
    %% the forms are stated. The present one is stated bare and the past one
    %% as `the past subjunctive', the `is the ADJ NOUN of X' shape, so the
    %% reader knows which tense each stands for; a plural takes its tense
    %% from the singular it is the plural of, so cb_tense/4 needs nothing new.
    ( cb_verb_form(Forms, [prs, p3, sg], Subj) -> cb_line('"~w" is the subjunctive of "~w".', [Subj, L]), cb_tense(Forms, prs, Subj, plural_of) ; true ),
    ( cb_verb_form(Forms, [pis, p3, sg], PSubj) -> cb_line('"~w" is the past subjunctive of "~w".', [PSubj, L]), cb_tense(Forms, pis, PSubj, plural_of) ; true ),
    %% THE IMPERATIVE IS THE FORM APERTIUM TAGS `imp', and the NEGATIVE one
    %% is a different form in every language that has both -- which is why
    %% the translator asks for it by name rather than making it. About half
    %% of the Tatoeba sentences refused with every word known are
    %% imperatives (`Dame eso.', `No te rias.'), so this is the largest
    %% single row of that table.
    ( cb_verb_form(Forms, [imp, p2, sg], Imper) -> cb_line('"~w" is the imperative of "~w".', [Imper, L]) ; true ),
    ( cb_lang(Lg), cb_negative_imperative(Lg, NTags), cb_verb_form(Forms, NTags, NImper)
    ->  cb_line('"~w" is the negative imperative of "~w".', [NImper, L]) ; true ),
    %% THE PLURAL IMPERATIVE IS STATED OF THE PLURAL FORM, as the past of a
    %% plural is (`"comieron" is the past of "comen"'): `"processate" is the
    %% imperative of "processano".', `"comed" is the imperative of "comen".'
    %% A headline's `"processate il vescovo"' is one, and with no plural
    %% stated it read as a passive whose participle agreed with nothing.
    (   cb_verb_form(Forms, [imp, p2, pl], PImper), cb_verb_form(Forms, [pri, p3, pl], Pl)
    ->  cb_line('"~w" is the imperative of "~w".', [PImper, Pl]),
        (   cb_lang(Lg2), cb_negative_imperative_plural(Lg2, NPTags), cb_verb_form(Forms, NPTags, NPImper)
        ->  cb_line('"~w" is the negative imperative of "~w".', [NPImper, Pl]) ; true )
    ;   true
    ),
    %% THE COMMAND OF THE FIRST PERSON PLURAL, stated of the verb as the
    %% singular imperative is: `Finiamola di considerare i parchi un freno'
    %% is let us stop, and `finiamo' is also what we do, so only the lesson
    %% can say it is a command too -- `"finiamo" is the hortative of
    %% "finisce".', `"dejemos" is the hortative of "deja".'
    (   cb_lang(Lg3), cb_hortative(Lg3, HTags), cb_verb_form(Forms, HTags, Hort)
    ->  cb_line('"~w" is the hortative of "~w".', [Hort, L]) ; true ),
    cb_participles(Forms, L),
    ( cb_verb_form(Forms, [inf], Inf) -> cb_line('"~w" is the infinitive of "~w".', [Inf, L]) ; true ),
    ( cb_verb_form(Forms, [ger], Ger) -> cb_line('"~w" is the gerund of "~w".', [Ger, L]) ; true ).

%% A PARTICIPLE AGREES, AND ALL FOUR FORMS ARE THE PARTICIPLE. Only the
%% masculine singular was written, so `considerata', `conclusa', `attaccata',
%% `appellati', `accertate' and `costituite' were unknown words although
%% their verbs were all in the vocabulary -- seven of the refusals in the
%% newspaper sample, over six sentences, for a form the dictionary already
%% carries. The masculine singular is stated FIRST so that a writer taking
%% the first meaning writes what it wrote before; the other three are read.
%%
%% Agreement on the way OUT is a different question and is not answered
%% here: a participle after `ser' agrees with its subject, and writing the
%% masculine form of a feminine subject is wrong. Reading is what the
%% sample needs and what this gives.
cb_participles(Forms, L) :-
    forall( ( member(G-N, [m-sg, f-sg, m-pl, f-pl]),
              cb_verb_form(Forms, [pp, G, N], Pp) ),
            cb_participle(Forms, L, G, N, Pp) ).

%% EACH FORM SAYS WHAT IT IS, or nothing could pick among the four. The
%% gender is stated of the feminine ones (the rule of gender would get
%% `considerate' wrong -- it does not end in `a' and is feminine plural),
%% and the number by stating a plural as the plural of its own singular,
%% which is the relation a noun and an adjective already use.
cb_participle(Forms, L, G, N, Pp) :-
    cb_line('"~w" is the participle of "~w".', [Pp, L]),
    ( G == f -> cb_line('"~w" is feminine.', [Pp]) ; true ),
    (   N == pl, cb_verb_form(Forms, [pp, G, sg], Sg), Sg \== Pp
    ->  cb_line('"~w" is the plural of "~w".', [Pp, Sg])
    ;   true
    ).

%% the plural and the persons of one tense's third person singular. The
%% plural of a past is stated as the past of the plural (`"comieron" is the
%% past of "comen"'), of a present or a future as the plural of the form
cb_tense(Forms, Tense, Sg, How) :-
    (   cb_verb_form(Forms, [Tense, p3, pl], Pl)
    ->  (   How == past_of, cb_verb_form(Forms, [pri, p3, pl], PresPl)
        ->  cb_line('"~w" is the past of "~w".', [Pl, PresPl])
        ;   How == imperfect_of, cb_verb_form(Forms, [pri, p3, pl], PresPl)
        ->  cb_line('"~w" is the imperfect of "~w".', [Pl, PresPl])
        ;   cb_line('"~w" is the plural of "~w".', [Pl, Sg])
        ),
        ( cb_verb_form(Forms, [Tense, p1, pl], P1pl) -> cb_line('"~w" is the first person of "~w".', [P1pl, Pl]) ; true ),
        %% (the second person plural the same way, `"direte" is the second person of "diranno".': `voi direte
        %% elezioni', `aprirete questo tavolo' -- Italian's was an imperative only, and the future, the
        %% imperfect and the rest were unknown words. NOT A FORM THE LANGUAGE COMMANDS WITH: Italian's
        %% present indicative is its imperative (`aprite', `guardate che ...', `non pensate che ...') and
        %% Spanish's present subjunctive its negative one (`no miréis'), and stated as a person too they
        %% read as the statement before the command that is tried last -- five commands of the controls
        %% became `abrís', `miráis', `sois' -- and, spelled like the participle's feminine plural
        %% (`proibite', `studiate', `annegate'), they made a headline a clause)
        ( cb_verb_form(Forms, [Tense, p2, pl], P2pl), P2pl \== Pl, \+ cb_command_plural(Forms, Tense, P2pl)
        ->  cb_line('"~w" is the second person of "~w".', [P2pl, Pl]) ; true )
    ;   true
    ),
    ( cb_verb_form(Forms, [Tense, p1, sg], P1), P1 \== Sg -> cb_line('"~w" is the first person of "~w".', [P1, Sg]) ; true ),
    ( cb_verb_form(Forms, [Tense, p2, sg], P2), P2 \== Sg -> cb_line('"~w" is the second person of "~w".', [P2, Sg]) ; true ).

%% the third person the lesson gives a verb as: the inflector's, and
%% English's own for `be' and `have'
cb_third(be, is) :- !.
cb_third(have, has) :- !.
cb_third(En, En3) :- reason_third(En, En3).

%% the English verb's past and participle, when -ed does not make them,
%% and its gerund when the translator's -ing rule does not (`running')
cb_english_verb(En, _) :- cb_en_done(En), !.
cb_english_verb(En, En3) :-
    assertz(cb_en_done(En)),
    (   cb_en_verb(En, Past, Pp, Ger)
    ->  ( cb_en_regular_past(En, Past) -> true ; cb_line('"~w" is the past of "~w".', [Past, En3]) ),
        ( Pp == Past -> true ; cb_line('"~w" is the participle of "~w".', [Pp, En3]) ),
        ( ( Ger == none ; tr_english_ing(En, Ger) ) -> true ; cb_line('"~w" is the gerund of "~w".', [Ger, En3]) )
    ;   true
    ).
