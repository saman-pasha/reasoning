%% templates/persian.pl -- the template of Persian, for
%% library(reasoning/typology). Facts only; typology_load(persian) reads it.

%% The orders: subject, object, verb; the article, the noun, the
%% adjectives.
ty_order(persian, clause, [s, o, v]).
ty_order(persian, np, [d, n, a]).

%% The nouns: Meaning, Gender (Persian has none), Animacy (person, animate, inanimate; a person is animate too), Singular, Plural.
ty_noun(persian, dog, none, animate, 'سگ', 'سگ‌ها').
ty_noun(persian, mouse, none, animate, 'موش', 'موش‌ها').
ty_noun(persian, cat, none, animate, 'گربه', 'گربه‌ها').
ty_noun(persian, house, none, inanimate, 'خانه', 'خانه‌ها').
ty_noun(persian, animal, none, animate, 'حیوان', 'حیوان‌ها').
ty_noun(persian, boy, none, person, 'پسر', 'پسرها').
ty_noun(persian, girl, none, person, 'دختر', 'دخترها').
ty_noun(persian, book, none, inanimate, 'کتاب', 'کتاب‌ها').

%% The adjectives do not change.
ty_adjective(persian, big, any, any, 'بزرگ').
ty_adjective(persian, small, any, any, 'کوچک').
ty_adjective(persian, black, any, any, 'سیاه').
ty_adjective(persian, red, any, any, 'قرمز').

%% The verbs agree with the subject in number. The negative is a prefix,
%% so each form is one word.
ty_verb(persian, see, present, sg, pos, ['می‌بیند']).
ty_verb(persian, see, present, pl, pos, ['می‌بینند']).
ty_verb(persian, see, present, sg, neg, ['نمی‌بیند']).
ty_verb(persian, see, present, pl, neg, ['نمی‌بینند']).
ty_verb(persian, see, past, sg, pos, ['دید']).
ty_verb(persian, see, past, pl, pos, ['دیدند']).
ty_verb(persian, see, past, sg, neg, ['ندید']).
ty_verb(persian, see, past, pl, neg, ['ندیدند']).
ty_verb(persian, sleep, present, sg, pos, ['می‌خوابد']).
ty_verb(persian, sleep, present, pl, pos, ['می‌خوابند']).
ty_verb(persian, sleep, present, sg, neg, ['نمی‌خوابد']).
ty_verb(persian, sleep, present, pl, neg, ['نمی‌خوابند']).
ty_verb(persian, sleep, past, sg, pos, ['خوابید']).
ty_verb(persian, sleep, past, pl, pos, ['خوابیدند']).
ty_verb(persian, sleep, past, sg, neg, ['نخوابید']).
ty_verb(persian, sleep, past, pl, neg, ['نخوابیدند']).
ty_verb(persian, think, present, sg, pos, ['فکر', 'می‌کند']).
ty_verb(persian, think, present, pl, pos, ['فکر', 'می‌کنند']).
ty_verb(persian, think, present, sg, neg, ['فکر', 'نمی‌کند']).
ty_verb(persian, think, present, pl, neg, ['فکر', 'نمی‌کنند']).
ty_verb(persian, think, past, sg, pos, ['فکر', 'کرد']).
ty_verb(persian, think, past, pl, pos, ['فکر', 'کردند']).
ty_verb(persian, think, past, sg, neg, ['فکر', 'نکرد']).
ty_verb(persian, think, past, pl, neg, ['فکر', 'نکردند']).
ty_verb(persian, look, present, sg, pos, ['نگاه', 'می‌کند']).
ty_verb(persian, look, present, pl, pos, ['نگاه', 'می‌کنند']).
ty_verb(persian, look, present, sg, neg, ['نگاه', 'نمی‌کند']).
ty_verb(persian, look, present, pl, neg, ['نگاه', 'نمی‌کنند']).
ty_verb(persian, look, past, sg, pos, ['نگاه', 'کرد']).
ty_verb(persian, look, past, pl, pos, ['نگاه', 'کردند']).
ty_verb(persian, look, past, sg, neg, ['نگاه', 'نکرد']).
ty_verb(persian, look, past, pl, neg, ['نگاه', 'نکردند']).

%% The future: `خواستن' before the past stem (`خواهد دید', `نخواهد دید'),
%% each person its own word; a compound verb puts it before the light
%% verb (`فکر خواهد کرد'), rows of their own. The perfect: the participle
%% and `است' (`دیده است'), the person's ending joined to the participle
%% (`دیده‌اند', and by the persons' rule below `دیده‌ام').
ty_tense_form(persian, future, sg, pos, ['خواهد', form(past, sg)]).
ty_tense_form(persian, future, pl, pos, ['خواهند', form(past, sg)]).
ty_tense_form(persian, future, sg(1), pos, ['خواهم', form(past, sg)]).
ty_tense_form(persian, future, sg(2), pos, ['خواهی', form(past, sg)]).
ty_tense_form(persian, future, pl(1), pos, ['خواهیم', form(past, sg)]).
ty_tense_form(persian, future, pl(2), pos, ['خواهید', form(past, sg)]).
ty_tense_form(persian, future, sg, neg, ['نخواهد', form(past, sg)]).
ty_tense_form(persian, future, pl, neg, ['نخواهند', form(past, sg)]).
ty_tense_form(persian, future, sg(1), neg, ['نخواهم', form(past, sg)]).
ty_tense_form(persian, future, sg(2), neg, ['نخواهی', form(past, sg)]).
ty_tense_form(persian, future, pl(1), neg, ['نخواهیم', form(past, sg)]).
ty_tense_form(persian, future, pl(2), neg, ['نخواهید', form(past, sg)]).
ty_verb(persian, see, perfect, sg, pos, ['دیده', 'است']).
ty_verb(persian, see, perfect, pl, pos, ['دیده‌اند']).
ty_verb(persian, see, perfect, sg, neg, ['ندیده', 'است']).
ty_verb(persian, see, perfect, pl, neg, ['ندیده‌اند']).
ty_verb(persian, sleep, perfect, sg, pos, ['خوابیده', 'است']).
ty_verb(persian, sleep, perfect, pl, pos, ['خوابیده‌اند']).
ty_verb(persian, sleep, perfect, sg, neg, ['نخوابیده', 'است']).
ty_verb(persian, sleep, perfect, pl, neg, ['نخوابیده‌اند']).
ty_verb(persian, think, perfect, sg, pos, ['فکر', 'کرده', 'است']).
ty_verb(persian, think, perfect, pl, pos, ['فکر', 'کرده‌اند']).
ty_verb(persian, think, perfect, sg, neg, ['فکر', 'نکرده', 'است']).
ty_verb(persian, think, perfect, pl, neg, ['فکر', 'نکرده‌اند']).
ty_verb(persian, think, future, sg, pos, ['فکر', 'خواهد', 'کرد']).
ty_verb(persian, think, future, sg, neg, ['فکر', 'نخواهد', 'کرد']).
ty_verb(persian, think, future, pl, pos, ['فکر', 'خواهند', 'کرد']).
ty_verb(persian, think, future, pl, neg, ['فکر', 'نخواهند', 'کرد']).
ty_verb(persian, think, future, sg(1), pos, ['فکر', 'خواهم', 'کرد']).
ty_verb(persian, think, future, sg(1), neg, ['فکر', 'نخواهم', 'کرد']).
ty_verb(persian, think, future, sg(2), pos, ['فکر', 'خواهی', 'کرد']).
ty_verb(persian, think, future, sg(2), neg, ['فکر', 'نخواهی', 'کرد']).
ty_verb(persian, think, future, pl(1), pos, ['فکر', 'خواهیم', 'کرد']).
ty_verb(persian, think, future, pl(1), neg, ['فکر', 'نخواهیم', 'کرد']).
ty_verb(persian, think, future, pl(2), pos, ['فکر', 'خواهید', 'کرد']).
ty_verb(persian, think, future, pl(2), neg, ['فکر', 'نخواهید', 'کرد']).
ty_verb(persian, look, perfect, sg, pos, ['نگاه', 'کرده', 'است']).
ty_verb(persian, look, perfect, pl, pos, ['نگاه', 'کرده‌اند']).
ty_verb(persian, look, perfect, sg, neg, ['نگاه', 'نکرده', 'است']).
ty_verb(persian, look, perfect, pl, neg, ['نگاه', 'نکرده‌اند']).
ty_verb(persian, look, future, sg, pos, ['نگاه', 'خواهد', 'کرد']).
ty_verb(persian, look, future, sg, neg, ['نگاه', 'نخواهد', 'کرد']).
ty_verb(persian, look, future, pl, pos, ['نگاه', 'خواهند', 'کرد']).
ty_verb(persian, look, future, pl, neg, ['نگاه', 'نخواهند', 'کرد']).
ty_verb(persian, look, future, sg(1), pos, ['نگاه', 'خواهم', 'کرد']).
ty_verb(persian, look, future, sg(1), neg, ['نگاه', 'نخواهم', 'کرد']).
ty_verb(persian, look, future, sg(2), pos, ['نگاه', 'خواهی', 'کرد']).
ty_verb(persian, look, future, sg(2), neg, ['نگاه', 'نخواهی', 'کرد']).
ty_verb(persian, look, future, pl(1), pos, ['نگاه', 'خواهیم', 'کرد']).
ty_verb(persian, look, future, pl(1), neg, ['نگاه', 'نخواهیم', 'کرد']).
ty_verb(persian, look, future, pl(2), pos, ['نگاه', 'خواهید', 'کرد']).
ty_verb(persian, look, future, pl(2), neg, ['نگاه', 'نخواهید', 'کرد']).

%% No definite article; `یک' before a singular indefinite noun.
ty_article(persian, indef, any, sg, 'یک').
%% The article of a question (`پسر کدام سگ را می‌بیند؟'): a noun phrase
%% of کدام is definite to را.
ty_article(persian, which, any, any, 'کدام').

%% `را' after a definite object.
ty_mark(persian, o, after, 'را', [[def]]).

%% The ezafe: a noun before its adjective, and an adjective before another,
%% is linked to it. After a consonant the link is a vowel not written;
%% after a silent `ه' it is `‌ی' (`گربه‌ی سیاه'), after `ا' and `و' it is `ی'
%% (`سگ‌های سیاه'). `سیاه' ends in a spoken h, so it is named, unchanged.
ty_linked(persian, n, a, 'ه', 'ه‌ی').
ty_linked(persian, n, a, 'ا', 'ای').
ty_linked(persian, n, a, 'و', 'وی').
ty_linked(persian, a, a, 'ه', 'ه‌ی').
ty_linked(persian, a, a, 'سیاه', 'سیاه').
ty_linked(persian, a, a, 'ا', 'ای').
ty_linked(persian, a, a, 'و', 'وی').

%% The copula clause: subject, predicate, copula, the copula last.
ty_order(persian, copula, [s, p, c]).
ty_copula(persian, any, present, sg, pos, ['است']).
ty_copula(persian, any, present, pl, pos, ['هستند']).
ty_copula(persian, any, present, sg, neg, ['نیست']).
ty_copula(persian, any, present, pl, neg, ['نیستند']).
ty_copula(persian, any, past, sg, pos, ['بود']).
ty_copula(persian, any, past, pl, pos, ['بودند']).
ty_copula(persian, any, past, sg, neg, ['نبود']).
ty_copula(persian, any, past, pl, neg, ['نبودند']).

%% Prepositions before their noun phrase; the adjuncts before the verb.
ty_order(persian, pp, [p, x]).
ty_adjunct(persian, before(v)).
ty_adposition(persian, in, ['در']).
ty_adposition(persian, on, ['روی']).
ty_adposition(persian, with, ['با']).
ty_adposition(persian, to, ['به']).
ty_adposition(persian, from, ['از']).
ty_adverb(persian, quickly, 'تند').
ty_adverb(persian, slowly, 'آهسته').
ty_adverb(persian, today, 'امروز').
ty_adverb(persian, here, 'اینجا').

%% Questions: `؟'; a yes or no question in the statement's order, or with
%% `آیا' first; a question word in place (`پسر چه چیزی می‌بیند؟'),
%% `کجا است' written `کجاست'.
ty_question_mark(persian, '', '؟').
ty_question(persian, yes_no, clause, unchanged).
ty_question(persian, yes_no, clause, particle('آیا', start)).
ty_question(persian, yes_no, copula, unchanged).
ty_question(persian, yes_no, copula, particle('آیا', start)).
ty_question(persian, wh, clause, unchanged).
ty_question(persian, wh, copula, unchanged).
ty_wh(persian, in_place).
ty_wh_word(persian, who, ['چه', 'کسی']).
ty_wh_word(persian, what, ['چه', 'چیزی']).
ty_wh_word(persian, where, ['کجا']).
ty_wh_word(persian, when, ['کی']).
ty_contraction(persian, ['کجا', 'است'], 'کجاست').

%% Relative clauses: the head, the marker, the clause (`سگی که پسر
%% می‌بیند', the dog that the boy sees). The head's last word takes ی
%% (after ه ‌ای, after ا and و یی), and a mark stays with the head: `سگی را
%% که پسر دید'.
ty_order(persian, rel, [h, m, c]).
ty_relative(persian, any, ['که'], [[]]).
ty_linked(persian, n, r, '', 'ی').
ty_linked(persian, n, r, 'ه', 'ه‌ای').
ty_linked(persian, n, r, 'ا', 'ایی').
ty_linked(persian, n, r, 'و', 'ویی').
ty_linked(persian, a, r, '', 'ی').
ty_linked(persian, a, r, 'ه', 'ه‌ای').
ty_linked(persian, a, r, 'سیاه', 'سیاهی').
ty_linked(persian, a, r, 'ا', 'ایی').
ty_linked(persian, a, r, 'و', 'ویی').

%% The relative clause of an object or a predicate stands after the verb
%% (`دختر سگ سیاهی را می‌بیند که می‌خوابد', `سگ حیوانی است که می‌خوابد'),
%% and is read in place too; an indefinite head takes no یک before it
%% (`حیوانی که'). A subject's relative clause after the verb is read
%% (`سگی می‌خوابد که پسر می‌بیند'), and written in place. The gap of an
%% object is no word, or read as a pronoun
%% with its mark (`سگی که پسر آن را می‌بیند'); in an adposition phrase it
%% is a pronoun (`خانه‌ای که سگ در آن می‌خوابد', `دختری که پسر به او فکر
%% می‌کند'): `او' for a person, `آن' for an animal or a thing, `آنها' for
%% several.
ty_relative_after(persian, o, first).
ty_relative_after(persian, p, first).
ty_relative_after(persian, s, second).
ty_relative_bare(persian, indef).
ty_gap(persian, o, gap).
ty_gap(persian, o, resumptive).
ty_gap(persian, pp, resumptive).
ty_resumptive(persian, ['او'], [[person, sg]]).
ty_resumptive(persian, ['آنها'], [[pl]]).
ty_resumptive(persian, ['آن'], [[sg]]).

%% The complement of two verbs of two words (above) with به (`پسر به دختر فکر
%% می‌کند.'): the object takes no را then.
ty_complement(persian, think, ['به']).
ty_complement(persian, look, ['به']).
ty_complement_wh(persian, moves).

%% The answer to a yes or no question, with the Persian comma (`بله، پسر سگ
%% را می‌بیند.'); a positive answer to a negative question is چرا, as
%% French `si' and German `doch'.
ty_answer(persian, yes, ['بله']).
ty_answer(persian, no, ['نه']).
ty_answer(persian, contradict, ['چرا']).
ty_answer_mark(persian, '،').

%% A possessor (`سگ پسر', the boy's dog): the possessed, its last word
%% taking the ezafe as before an adjective (`خانه‌ی پسر'), then the
%% possessor. `whose' is a clitic on the possessed, which stays: ش for one
%% possessor, شان for several (`پسری که سگش می‌خوابد', `خانه‌اش').
ty_possessive(persian, [h, p, g], [], keep).
ty_linked(persian, n, g, 'ه', 'ه‌ی').
ty_linked(persian, n, g, 'ا', 'ای').
ty_linked(persian, n, g, 'و', 'وی').
ty_linked(persian, a, g, 'ه', 'ه‌ی').
ty_linked(persian, a, g, 'سیاه', 'سیاه').
ty_linked(persian, a, g, 'ا', 'ای').
ty_linked(persian, a, g, 'و', 'وی').
ty_gap(persian, poss, resumptive).
ty_linked(persian, n, clitic(sg), '', 'ش').
ty_linked(persian, n, clitic(sg), 'ه', 'ه‌اش').
ty_linked(persian, n, clitic(sg), 'ا', 'ایش').
ty_linked(persian, n, clitic(sg), 'و', 'ویش').
ty_linked(persian, a, clitic(sg), '', 'ش').
ty_linked(persian, a, clitic(sg), 'ه', 'ه‌اش').
ty_linked(persian, a, clitic(sg), 'سیاه', 'سیاهش').
ty_linked(persian, n, clitic(pl), '', 'شان').
ty_linked(persian, n, clitic(pl), 'ه', 'ه‌شان').
ty_linked(persian, n, clitic(pl), 'ا', 'ایشان').
ty_linked(persian, a, clitic(pl), '', 'شان').
ty_linked(persian, a, clitic(pl), 'ه', 'ه‌شان').
ty_linked(persian, a, clitic(pl), 'سیاه', 'سیاهشان').

%% A possessive pronoun is the clitic on the possessed (`سگش', his, her or
%% its dog; `سگشان', their dog), the clitic(N) rows above.
ty_possessive_clitic(persian).

%% Personal pronouns, one form in every role (an object's takes را as a
%% noun phrase does: `او را می‌بینم'); a subject of the first or the second
%% person is no word, the verb's ending telling it (`سگ را می‌بینم', I see
%% the dog), and one of the third may be none. The verb of the first and
%% the second persons is the plural's with ند made م, ی, یم, ید
%% (`می‌بینم', `می‌بینی', `می‌بینیم', `می‌بینید'; `دیدم'; `هستم', `نیستیم').
ty_pronoun(persian, s, ['من'], [[1, sg]]).
ty_pronoun(persian, s, ['تو'], [[2, sg]]).
ty_pronoun(persian, s, ['او'], [[3, sg, m], [3, sg, f]]).
ty_pronoun(persian, s, ['آن'], [[3, sg, n]]).
ty_pronoun(persian, s, ['ما'], [[1, pl]]).
ty_pronoun(persian, s, ['شما'], [[2, pl], [polite]]).
ty_pronoun(persian, s, ['آنها'], [[3, pl]]).
ty_pro_drop(persian, [1, 2]).
%% The polite `you' is `شما' with the second plural's form and clitic
%% (`شما سگ را می‌بینید', `سگتان'); it is never dropped.
ty_polite(persian, sg, pl(2)).
ty_polite(persian, pl, pl(2)).
ty_verb_person(persian, any, sg(1), pl, 'ند', 'م').
ty_verb_person(persian, any, sg(2), pl, 'ند', 'ی').
ty_verb_person(persian, any, pl(1), pl, 'ند', 'یم').
ty_verb_person(persian, any, pl(2), pl, 'ند', 'ید').

%% A possessive pronoun of the first and the second persons is a clitic as
%% the third's is: م, ت, مان, تان (`سگم', my dog; `خانه‌ات', your house;
%% `کتاب‌هایمان', our books).
ty_linked(persian, n, clitic(sg(1)), '', 'م').
ty_linked(persian, n, clitic(sg(1)), 'ه', 'ه‌ام').
ty_linked(persian, n, clitic(sg(1)), 'ا', 'ایم').
ty_linked(persian, n, clitic(sg(1)), 'و', 'ویم').
ty_linked(persian, a, clitic(sg(1)), '', 'م').
ty_linked(persian, a, clitic(sg(1)), 'ه', 'ه‌ام').
ty_linked(persian, a, clitic(sg(1)), 'سیاه', 'سیاهم').
ty_linked(persian, n, clitic(sg(2)), '', 'ت').
ty_linked(persian, n, clitic(sg(2)), 'ه', 'ه‌ات').
ty_linked(persian, n, clitic(sg(2)), 'ا', 'ایت').
ty_linked(persian, n, clitic(sg(2)), 'و', 'ویت').
ty_linked(persian, a, clitic(sg(2)), '', 'ت').
ty_linked(persian, a, clitic(sg(2)), 'ه', 'ه‌ات').
ty_linked(persian, a, clitic(sg(2)), 'سیاه', 'سیاهت').
ty_linked(persian, n, clitic(pl(1)), '', 'مان').
ty_linked(persian, n, clitic(pl(1)), 'ه', 'ه‌مان').
ty_linked(persian, n, clitic(pl(1)), 'ا', 'ایمان').
ty_linked(persian, a, clitic(pl(1)), '', 'مان').
ty_linked(persian, a, clitic(pl(1)), 'ه', 'ه‌مان').
ty_linked(persian, a, clitic(pl(1)), 'سیاه', 'سیاهمان').
ty_linked(persian, n, clitic(pl(2)), '', 'تان').
ty_linked(persian, n, clitic(pl(2)), 'ه', 'ه‌تان').
ty_linked(persian, n, clitic(pl(2)), 'ا', 'ایتان').
ty_linked(persian, a, clitic(pl(2)), '', 'تان').
ty_linked(persian, a, clitic(pl(2)), 'ه', 'ه‌تان').
ty_linked(persian, a, clitic(pl(2)), 'سیاه', 'سیاهتان').

%% The short answer that repeats the clause: the yes or no word and the
%% verb with no object (`بله، می‌بینم.', yes, I see; `چرا، می‌بینم.' to a
%% negative question).
ty_answer_echo(persian, verb, keep).

%% The copula's future and perfect (`خواهد بود', `بوده است').
ty_copula(persian, any, future, sg, pos, ['خواهد', 'بود']).
ty_copula(persian, any, future, pl, pos, ['خواهند', 'بود']).
ty_copula(persian, any, future, sg(1), pos, ['خواهم', 'بود']).
ty_copula(persian, any, future, sg(2), pos, ['خواهی', 'بود']).
ty_copula(persian, any, future, pl(1), pos, ['خواهیم', 'بود']).
ty_copula(persian, any, future, pl(2), pos, ['خواهید', 'بود']).
ty_copula(persian, any, future, sg, neg, ['نخواهد', 'بود']).
ty_copula(persian, any, future, pl, neg, ['نخواهند', 'بود']).
ty_copula(persian, any, future, sg(1), neg, ['نخواهم', 'بود']).
ty_copula(persian, any, future, sg(2), neg, ['نخواهی', 'بود']).
ty_copula(persian, any, future, pl(1), neg, ['نخواهیم', 'بود']).
ty_copula(persian, any, future, pl(2), neg, ['نخواهید', 'بود']).
ty_copula(persian, any, perfect, sg, pos, ['بوده', 'است']).
ty_copula(persian, any, perfect, pl, pos, ['بوده‌اند']).
ty_copula(persian, any, perfect, sg(1), pos, ['بوده‌ام']).
ty_copula(persian, any, perfect, sg(2), pos, ['بوده‌ای']).
ty_copula(persian, any, perfect, pl(1), pos, ['بوده‌ایم']).
ty_copula(persian, any, perfect, pl(2), pos, ['بوده‌اید']).
ty_copula(persian, any, perfect, sg, neg, ['نبوده', 'است']).
ty_copula(persian, any, perfect, pl, neg, ['نبوده‌اند']).
ty_copula(persian, any, perfect, sg(1), neg, ['نبوده‌ام']).
ty_copula(persian, any, perfect, sg(2), neg, ['نبوده‌ای']).
ty_copula(persian, any, perfect, pl(1), neg, ['نبوده‌ایم']).
ty_copula(persian, any, perfect, pl(2), neg, ['نبوده‌اید']).

%% The imperfect: `می' before the past (`می‌دید', `نمی‌دید'), before the
%% light verb of a compound verb (`فکر می‌کرد'); the conditional is
%% written as the imperfect (ty_tense_like/4). The pluperfect: the
%% participle and `بود' (`دیده بود'). The first and second persons by the
%% persons' rule (`می‌دیدم', `دیده بودم'). The copula's imperfect and
%% conditional are written as its past (`بود'); its pluperfect `بوده بود'.
ty_tense_like(persian, clause, conditional, imperfect).
ty_tense_like(persian, copula, imperfect, past).
ty_tense_like(persian, copula, conditional, past).
ty_verb(persian, see, imperfect, sg, pos, ['می‌دید']).
ty_verb(persian, see, imperfect, pl, pos, ['می‌دیدند']).
ty_verb(persian, see, imperfect, sg, neg, ['نمی‌دید']).
ty_verb(persian, see, imperfect, pl, neg, ['نمی‌دیدند']).
ty_verb(persian, sleep, imperfect, sg, pos, ['می‌خوابید']).
ty_verb(persian, sleep, imperfect, pl, pos, ['می‌خوابیدند']).
ty_verb(persian, sleep, imperfect, sg, neg, ['نمی‌خوابید']).
ty_verb(persian, sleep, imperfect, pl, neg, ['نمی‌خوابیدند']).
ty_verb(persian, think, imperfect, sg, pos, ['فکر', 'می‌کرد']).
ty_verb(persian, think, imperfect, pl, pos, ['فکر', 'می‌کردند']).
ty_verb(persian, think, imperfect, sg, neg, ['فکر', 'نمی‌کرد']).
ty_verb(persian, think, imperfect, pl, neg, ['فکر', 'نمی‌کردند']).
ty_verb(persian, look, imperfect, sg, pos, ['نگاه', 'می‌کرد']).
ty_verb(persian, look, imperfect, pl, pos, ['نگاه', 'می‌کردند']).
ty_verb(persian, look, imperfect, sg, neg, ['نگاه', 'نمی‌کرد']).
ty_verb(persian, look, imperfect, pl, neg, ['نگاه', 'نمی‌کردند']).
ty_verb(persian, see, pluperfect, sg, pos, ['دیده', 'بود']).
ty_verb(persian, see, pluperfect, pl, pos, ['دیده', 'بودند']).
ty_verb(persian, see, pluperfect, sg, neg, ['ندیده', 'بود']).
ty_verb(persian, see, pluperfect, pl, neg, ['ندیده', 'بودند']).
ty_verb(persian, sleep, pluperfect, sg, pos, ['خوابیده', 'بود']).
ty_verb(persian, sleep, pluperfect, pl, pos, ['خوابیده', 'بودند']).
ty_verb(persian, sleep, pluperfect, sg, neg, ['نخوابیده', 'بود']).
ty_verb(persian, sleep, pluperfect, pl, neg, ['نخوابیده', 'بودند']).
ty_verb(persian, think, pluperfect, sg, pos, ['فکر', 'کرده', 'بود']).
ty_verb(persian, think, pluperfect, pl, pos, ['فکر', 'کرده', 'بودند']).
ty_verb(persian, think, pluperfect, sg, neg, ['فکر', 'نکرده', 'بود']).
ty_verb(persian, think, pluperfect, pl, neg, ['فکر', 'نکرده', 'بودند']).
ty_verb(persian, look, pluperfect, sg, pos, ['نگاه', 'کرده', 'بود']).
ty_verb(persian, look, pluperfect, pl, pos, ['نگاه', 'کرده', 'بودند']).
ty_verb(persian, look, pluperfect, sg, neg, ['نگاه', 'نکرده', 'بود']).
ty_verb(persian, look, pluperfect, pl, neg, ['نگاه', 'نکرده', 'بودند']).
ty_copula(persian, any, pluperfect, sg, pos, ['بوده', 'بود']).
ty_copula(persian, any, pluperfect, pl, pos, ['بوده', 'بودند']).
ty_copula(persian, any, pluperfect, sg, neg, ['نبوده', 'بود']).
ty_copula(persian, any, pluperfect, pl, neg, ['نبوده', 'بودند']).

%% The word before the last item of a list: a predicate's adjectives
%% (`small and black'), noun phrases (`the boy and the girl'), clauses.
ty_and(persian, ['و']).
%% The other conjunctions (since 1.59.0): `or', `but'.
ty_conjunction(persian, or, ['یا']).
ty_conjunction(persian, but, ['اما']).
%% The comma: `،' (`سگ کوچک، سیاه و بزرگ است.').
ty_comma(persian, '،').

%% March, the month (`در مارس').
ty_noun(persian, march_month, none, unknown, 'مارس', 'مارس‌ها').
