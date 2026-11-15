%% coding/python/names.pl -- the names a Python source defines and reads.
%%
%%     python_names_findings(+Code, -Findings)
%%         one atom a finding -- `possibly unbound NAME at line N' -- for
%%         each name the source reads and defines nowhere. [] when there
%%         is none. Code is an atom, a string or its codes.
%%
%% The name half of codegen's `guarded' reading and of
%% `coding/python/check.pl''s --strict, shared so the two cannot drift.
%%
%% IT IS A READING, NOT AN IMPORT. An import runs a file's top level, and
%% a checker has no right to run what a model wrote, so the names come
%% from the text:
%%
%%   -- a line is its indent and its words, with its strings and its
%%      comment taken out, so a name in a message is not a name in code,
%%      and its punctuation made words of its own, so `x=1' is `x', `=',
%%      `1';
%%   -- a DEFINITION is a name after `def', `class', `import', `for',
%%      `as', `global' or `nonlocal'; a name inside the parentheses of a
%%      line that opens a `def'; or a name left of an `='. The reading has
%%      no order for a block: a name assigned anywhere counts as bound,
%%      which keeps a function's own helpers and a branch's assignment
%%      from being findings and leaves the loud case -- a name the file
%%      never binds;
%%   -- a READ is a name followed by `(', `[' or an operator, and not
%%      after a `.` (an attribute is not a name Python resolves itself);
%%   -- the builtins, `self', `cls' and a name beginning with `__' are
%%      bound, and so is every name a `from X import *' could bring.
%%
%% A finding is `possibly', because the reading cannot see the last.

:- use_module(library(os)).

%% ---- the reading -------------------------------------------------------

%% The names the file defines, and the names it reads, each with its
%% line, then one finding a read name the file never defines.
%%
%% NOTHING HERE IS A findall OVER A LINE. Over this engine a search's goal
%% is walked twice and a cut or an if-then-else in it settles its own
%% branch, so every list below is walked by a recursion and every test is
%% a goal of its own. The reading of one line is a predicate of a line.
python_names_findings(Code, Findings) :-
    python_names_lines(Code, Lines),
    python_names_lines_defines(Lines, Names0),
    sort(Names0, Names),
    python_names_lines_reads(Lines, Reads0),
    sort(Reads0, Reads),
    python_names_findings_each(Reads, Names, Found),
    python_names_sorted_findings(Found, Findings).


python_names_sorted_findings(Found, Findings) :-
    sort(Found, Findings).


python_names_findings_find([], _, Findings, Tail) :-
    Findings = Tail.
python_names_findings_find([read(N, Name)|Reads], Defined, Findings, Tail) :-
    python_names_finding_for(N, Name, Defined, Here),
    append(Here, Tail, Tail1),
    python_names_findings_find(Reads, Defined, Findings, Tail1).

python_names_findings_each([], _, []).
python_names_findings_each([read(N, Name)|Reads], Defined, Findings) :-
    python_names_finding_for(N, Name, Defined, Here),
    python_names_findings_each(Reads, Defined, Tail),
    append(Here, Tail, Findings).

%% A name the file does not define, and that is not a builtin, is the one
%% that is kept. The guard is written out here, in its own clause, because
%% a call to a predicate whose body begins with a negation is a call this
%% engine does not come back from.
python_names_finding_for(N, Name, Defined, [Finding]) :-
    \+ python_names_name_defined(Name, Defined),
    format(atom(Finding),
           'possibly unbound ~w at line ~w: the file defines it nowhere',
           [Name, N]).
python_names_finding_for(_, _, _, []).

python_names_undefined(Name, Defined, no) :-
    \+ python_names_name_defined(Name, Defined),
    \+ python_names_builtin(Name).

%% A name the file defines is not a finding: the test is findall's, whose
%% one answer a matchchk reads and whose binding it never leaves behind.
python_names_name_defined(Name, Defined) :-
    findall(x, python_names_member_word(Defined, Name), [x]).

%% An answer, not a cut: a cut inside this asks the engine to commit the
%% search that owns it, and a caller's report after the negation is lost.
python_names_builtin_answer(Name, no) :-
    python_names_builtin(Name),
    !.
python_names_builtin_answer(_, yes).

%% ---- the words one line defines ----------------------------------------
%%
%% The reading has no order for a block, so a name a line defines is taken
%% as bound wherever it is read: the loud case it leaves is a name the file
%% never binds at all. Per word:
%%
%%   -- the word after `def', `class', `for' or `as';
%%   -- every word after `import', `global' or `nonlocal';
%%   -- every word between the parentheses of a line with a `def';
%%   -- a lettered word of any other line, since a name is bound by being
%%      written.

python_names_lines_defines(Lines, Names) :-
    python_names_lines_define_all(Lines, Names, []).

python_names_lines_define_all([], Names, Tail) :-
    Names = Tail.
python_names_lines_define_all([line(_, _, Words)|Lines], Names, Tail) :-
    python_names_defines_here(Words, Here),
    append(Here, Tail0, Names),
    python_names_lines_define_all(Lines, Tail0, Tail).

python_names_defines_here(Words, Here) :-
    python_names_line_defines(Words, Found0),
    sort(Found0, Here).

python_names_line_defines(Words, Found) :-
    findall(Word, python_names_defined_word_in(Words, Word), Found).

python_names_defined_word_in(Words, Word) :-
    python_names_member_word(Words, Word),
    python_names_defined_word(Word, Words).

python_names_member_word([Word|_], Word).
python_names_member_word([_|Words], Word) :-
    python_names_member_word(Words, Word).

python_names_defined_word(Word, Words) :-
    python_names_letter_name(Word),
    python_names_defined_where(Words, Word).

python_names_defined_where(Words, Word) :-
    python_names_after_keyword(Words, Word).
python_names_defined_where(Words, Word) :-
    python_names_after_open(Words, Word).
python_names_defined_where(Words, Word) :-
    python_names_member_word(Words, '='),
    python_names_left_of_eq(Words, Left),
    python_names_member_word(Left, Word).

python_names_after_keyword(Words, Word) :-
    python_names_after_a_keyword(Words, Word).

python_names_after_a_keyword([Keyword|Rest], Word) :-
    memberchk(Keyword, [def, class, for, as, import, global, nonlocal]),
    Rest = [Word|_],
    python_names_letter_name(Word).
python_names_after_a_keyword([_|Words], Word) :-
    python_names_after_a_keyword(Words, Word).

%% A `def' line's parameters: the words after its `('.
python_names_after_open(Words, Word) :-
    python_names_member_word(Words, def),
    python_names_after_open_scan(Words, Word).

python_names_after_open_scan(['('|Words], Word) :-
    python_names_after_open_rest(Words, Word).
python_names_after_open_scan([_|Words], Word) :-
    python_names_after_open_scan(Words, Word).

python_names_after_open_rest([Word|_], Word) :-
    python_names_letter_name(Word).
python_names_after_open_rest([_|Words], Word) :-
    python_names_after_open_rest(Words, Word).

%% ---- the names one line reads ------------------------------------------

python_names_lines_reads(Lines, Reads) :-
    python_names_reads_here_lines(Lines, Reads, []).

python_names_reads_here_lines([], ReadList, Tail) :-
    ReadList = Tail.
python_names_reads_here_lines([line(N, _, Words)|Lines], Reads, Tail) :-
    python_names_reads_of(Words, N, Here),
    append(Here, Tail0, Reads),
    python_names_reads_here_lines(Lines, Tail0, Tail).

python_names_reads_of(Words, N, Here) :-
    python_names_find_reads(Words, none, N, Found, []),
    sort(Found, Here).

%% A name is a read when the word after it is a `(', a `[' or an operator,
%% and the word before it is not a `.`: an attribute is not a name Python
%% resolves itself, and a builtin is bound before the file is read.
python_names_find_reads([], _, _, Reads, Reads).
python_names_find_reads([_], _, _, Reads, Reads).
python_names_find_reads([Word, Next|Words], Prev, N, Reads0, ReadsN) :-
    (   Prev \== '.',
        python_names_letter_name(Word),
        \+ python_names_keyword(Word),
        python_names_cue(Next)
    ->  (   python_names_builtin(Word)
        ->  python_names_find_reads([Next|Words], Word, N, Reads0, ReadsN)
        ;   Reads0 = [read(N, Word)|Reads1],
            python_names_find_reads([Next|Words], Word, N, Reads1, ReadsN)
        )
    ;   python_names_find_reads([Next|Words], Word, N, Reads0, ReadsN)
    ).

%% ---- the source as lines -----------------------------------------------

%% line(N, Indent, Words): the Nth line of the file, its indent, and the
%% words of its code. A line with no code is not a line of the reading.
python_names_lines(Text, Lines) :-
    python_names_codes(Text, Codes),
    python_names_split(Codes, Raw),
    python_names_number(Raw, 1, Numbered),
    python_names_each_line(Numbered, Lines).

python_names_each_line([], []).
python_names_each_line([raw(N, RawLine)|Numbered], Lines) :-
    python_names_numbered_line(N, RawLine, Here),
    python_names_each_line(Numbered, Rest),
    append(Here, Rest, Lines).

python_names_numbered_line(N, RawLine, [Line]) :-
    python_names_line(RawLine, Indent, Words),
    Words \== [],
    Line = line(N, Indent, Words).
python_names_numbered_line(_, _, []).

python_names_codes(Text, Codes) :-
    (   is_list(Text)
    ->  Codes = Text
    ;   atom(Text)
    ->  atom_codes(Text, Codes)
    ;   string(Text)
    ->  string_codes(Text, Codes)
    ;   Codes = []
    ).

python_names_split(Codes, Lines) :-
    python_names_split(Codes, [], Lines).

%% A line ends at a newline; the last line is the text after the last
%% newline, empty for a file that ends with one.
python_names_split([], Acc, [Line]) :-
    python_names_collect(Acc, Line).
python_names_split([10|Rest], Acc, [Line|Lines]) :-
    python_names_collect(Acc, Line),
    python_names_split(Rest, [], Lines).
python_names_split([C|Rest], Acc, Lines) :-
    \+ C =:= 10,
    python_names_split(Rest, [C|Acc], Lines).

python_names_collect(RevCodes, Line) :-
    reverse(RevCodes, Codes),
    atom_codes(Line, Codes).

python_names_number([], _, []).
python_names_number([RawLine|Raw], N, [raw(N, RawLine)|Numbered]) :-
    N1 is N + 1,
    python_names_number(Raw, N1, Numbered).

python_names_line(Line, Indent, Words) :-
    atom_codes(Line, Codes),
    python_names_indent(Codes, Indent, After),
    python_names_strip(After, Stripped),
    python_names_words(Stripped, Words0),
    exclude(python_names_blank_word, Words0, Words).

python_names_blank_word('').

python_names_indent([32|Cs], Indent, After) :-
    !,
    python_names_indent(Cs, N, After),
    Indent is N + 1.
python_names_indent(Cs, 0, Cs).

%% The line's code: a `#' ends it, a string becomes a space, and a
%% punctuation mark is separated from what stands beside it.
python_names_strip([], []).
python_names_strip([C|Cs], Out) :-
    (   C =:= 0'#
    ->  Out = []
    ;   python_names_quote_code(C)
    ->  python_names_until(Cs, C, Rest),
        Out = [32|More],
        python_names_strip(Rest, More)
    ;   python_names_punct(C)
    ->  Out = [32, C, 32|More],
        python_names_strip(Cs, More)
    ;   Out = [C|More],
        python_names_strip(Cs, More)
    ).

%% The words of a stripped line. Space ends a word; everything else is
%% part of one, the punctuation having been separated already.
python_names_words([], []).
python_names_words([C|Cs], Words) :-
    (   python_names_space(C)
    ->  python_names_words(Cs, Words)
    ;   python_names_word([C|Cs], Word, Rest),
        Words = [Word|More],
        python_names_words(Rest, More)
    ).

python_names_word([], '', []).
python_names_word([C|Cs], Word, Rest) :-
    (   python_names_space(C)
    ->  Word = '',
        Rest = [C|Cs]
    ;   python_names_word(Cs, Tail, Rest),
        atom_codes(Char, [C]),
        atom_concat(Char, Tail, Word)
    ).

python_names_space(C) :-
    python_names_space_code(C).

python_names_space_code(32).
python_names_space_code(9).
python_names_space_code(13).

%% ---- punctuation and quotes --------------------------------------------

python_names_punct(C) :-
    python_names_punct_code(C).

python_names_punct_code(0'().
python_names_punct_code(0')).
python_names_punct_code(0'[).
python_names_punct_code(0']).
python_names_punct_code(0'{).
python_names_punct_code(0'}).
python_names_punct_code(0'=).
python_names_punct_code(0'<).
python_names_punct_code(0'>).
python_names_punct_code(0'!).
python_names_punct_code(0'+).
python_names_punct_code(0'-).
python_names_punct_code(0'*).
python_names_punct_code(0'/).
python_names_punct_code(0'%).
python_names_punct_code(0'&).
python_names_punct_code(0'|).
python_names_punct_code(0'^).
python_names_punct_code(0'~).
python_names_punct_code(0'.).
python_names_punct_code(0',).
python_names_punct_code(0':).

python_names_quote_code(C) :-
    python_names_quote_fact(C).

python_names_quote_fact(0'\').
python_names_quote_fact(0'").

python_names_until([], _, []).
python_names_until([C|Cs], Q, Rest) :-
    (   C =:= Q
    ->  Rest = Cs
    ;   python_names_until(Cs, Q, Rest)
    ).

%% ---- the names a line defines ------------------------------------------

python_names_define_in(Words, Name) :-
    python_names_keyword_define(Words, Name).
python_names_define_in(Words, Name) :-
    python_names_left_of_eq(Words, Left),
    member(Name, Left),
    python_names_letter_name(Name).
python_names_define_in(Words, Name) :-
    append(_, ['('|Rest], Words),
    python_names_upto_close(Rest, Inside),
    member(Name, Inside),
    python_names_letter_name(Name).

%% The words before the first `=' on the line; the line's own words when
%% it has none.
python_names_left_of_eq([], []).
python_names_left_of_eq(['='|_], []) :-
    !.
python_names_left_of_eq([W|Ws], [W|Left]) :-
    python_names_left_of_eq(Ws, Left).

%% A keyword binds the words after it that are names: `import os, sys'
%% binds two, `for k in d' one, `def f(x)' f and x.
python_names_keyword_define(Words, Name) :-
    python_names_keyword_after(Words, Rest),
    python_names_take_names(Rest, Name).

python_names_keyword_after([Keyword|Rest], Rest) :-
    memberchk(Keyword, [def, class, import, for, as, global, nonlocal]),
    !.
python_names_keyword_after([_|Words], Rest) :-
    python_names_keyword_after(Words, Rest).

python_names_take_names([Word|Words], Name) :-
    (   python_names_letter_name(Word),
        \+ python_names_keyword(Word),
        \+ python_names_builtin(Word)
    ->  Name = Word
    ;   python_names_take_names(Words, Name)
    ).

python_names_upto_close([], []).
python_names_upto_close([')'|_], []) :-
    !.
python_names_upto_close([W|Ws], [W|Rest]) :-
    python_names_upto_close(Ws, Rest).

%% ---- the names a line reads --------------------------------------------
%%
%% A word is read when the word after it is a `(', a `[' or an operator,
%% and the word before it is not a `.`: an attribute is not a name Python
%% resolves itself.

python_names_read_in([This, Next|_], Name) :-
    python_names_letter_name(This),
    \+ python_names_keyword(This),
    python_names_cue(Next),
    Name = This.
python_names_read_in([Prev, This, Next|_], Name) :-
    Prev \== '.',
    python_names_letter_name(This),
    \+ python_names_keyword(This),
    python_names_cue(Next),
    Name = This.

python_names_keyword(Name) :-
    python_names_keyword_list(Keywords),
    memberchk(Name, Keywords).

python_names_keyword_list(['and', 'as', 'assert', 'async', 'await', 'break',
                           'class', 'continue', 'def', 'del', 'elif',
                           'else', 'except', 'finally', 'for', 'from',
                           'global', 'if', 'import', 'in', 'is', 'lambda',
                           'nonlocal', 'not', 'or', 'pass', 'raise',
                           'return', 'try', 'while', 'with', 'yield',
                           'None', 'True', 'False']).

python_names_cue('(').
python_names_cue('[').
python_names_cue('+').
python_names_cue('-').
python_names_cue('*').
python_names_cue('/').
python_names_cue('%').
python_names_cue('<').
python_names_cue('>').
python_names_cue('!').
python_names_cue('&').
python_names_cue('|').
python_names_cue('^').
python_names_cue('~').

python_names_letter_name(Name) :-
    atom(Name),
    atom_codes(Name, [C|_]),
    (   C >= 0'a, C =< 0'z
    ;   C >= 0'A, C =< 0'Z
    ;   C =:= 0'_
    ).

%% ---- the builtins and the words Python binds itself --------------------

python_names_builtin(Name) :-
    python_names_function(Name).
python_names_builtin(Name) :-
    python_names_exception(Name).
python_names_builtin(Name) :-
    atom(Name),
    sub_atom(Name, 0, 2, _, '__').

python_names_function(Name) :-
    memberchk(Name, [abs, aiter, all, anext, anext, any, ascii, bin, bool,
                     breakpoint, bytearray, bytes, callable, chr, classmethod,
                     compile, complex, delattr, dict, dir, divmod, enumerate,
                     eval, exec, filter, float, format, frozenset, getattr,
                     globals, hasattr, hash, help, hex, id, input, int,
                     isinstance, issubclass, iter, len, list, locals, map, max,
                     memoryview, min, next, object, oct, open, ord, pow,
                     readline, readlines, read, write, append, strip, split,
                     join, keys, values, items, get, setdefault, sort,
                     close, flush, endswith, startswith, lower, upper,
                     print, property, range, repr, reversed, round, set,
                     setattr, slice, sorted, staticmethod, str, sum, super,
                     tuple, type, vars, zip, self, cls, '__name__',
                     '__main__', '__file__', '__doc__', '__all__']).

python_names_exception(Name) :-
    memberchk(Name, ['Exception', 'ArithmeticError', 'AssertionError',
                     'AttributeError', 'BaseException', 'BufferError',
                     'EOFError', 'FloatingPointError', 'GeneratorExit',
                     'ImportError', 'IndentationError', 'IndexError',
                     'KeyError', 'KeyboardInterrupt', 'LookupError',
                     'MemoryError', 'NameError', 'NotImplementedError',
                     'OSError', 'OverflowError', 'RuntimeError',
                     'StopIteration', 'SyntaxError', 'SystemExit', 'TabError',
                     'TypeError', 'UnboundLocalError', 'UnicodeError',
                     'UnicodeDecodeError', 'UnicodeEncodeError',
                     'ValueError', 'ZeroDivisionError', 'IsADirectoryError',
                     'PermissionError', 'FileNotFoundError', 'FileExistsError',
                     'TimeoutError', 'ModuleNotFoundError', 'RecursionError',
                     'SystemError', 'Warning', 'UserWarning']).
