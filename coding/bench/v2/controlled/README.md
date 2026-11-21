# Controlled restatements

A requirement as a benchmark gives it is prose, and the reasoner's readers
read controlled English. Read as it is, `mvccs_acid`'s requirement gives
`reason_text/2` nothing: 0 of its 14 sentences with the grammar, 0 with the
tagger (reasoning 1.17.0), and one in live mode, read wrongly ("Write a
complete Python 3 program." rewritten as "Alice writes a program."). So
`reason_concepts/2`, `reason_topics/2` and `reason_outline/2` have nothing
either.

`TASK.txt` here is the requirement said again in sentences the grammar
reads, one a line. `coding/bench/v2/reason_prep.pl` reads it whole, with the
grammar alone, and writes the notes the runner's `controlled`, `terms`,
`concepts` and `outline` arms put after the requirement.

## The rule

**A restatement says what the requirement says, and nothing more.** It was
written by hand from the requirement's text alone, sentence by sentence,
never from the cases or their expected output: the requirement says "error
if T is not active" and never what an error prints, so the restatement says
`Every transaction that is not active causes an error.` and not that it
prints the word `error`, which the cases expect. What the grammar cannot
say is said more coarsely or left out, never filled in:

| the requirement | the restatement |
|---|---|
| a multi-version B-tree of minimum degree 2, integer keys, possibly negative | `Mvccs simulates a tree.` `Every tree is a b_tree.` `The minimum_degree is 2.` `Every key is an integer.` `Every negative_integer may be a key.` |
| one command per line; blank lines are ignored | `Every line holds a command.` `Every line that is blank is ignored.` |
| `b T` begins T at the latest committed version; error if T is active | `Every transaction begins at the latest_version.` `Every repeated_begin begins an active_transaction.` `Every repeated_begin causes an error.` |
| `i`, `d`, `c`, `a`, `r`, `p`: error if T is not active | `Every transaction that is active may stage an insertion.` (and the others) `Every transaction that is not active causes an error.` |
| `r T KEY` prints yes if KEY is visible in T's view, otherwise no | `Every key that is visible reads as "yes".` `Every key that is not visible reads as "no".` |
| `g KEY` prints yes if KEY is in the latest committed version, otherwise no | `Every key that is committed gets "yes".` `Every key that is not committed gets "no".` |
| a deletion of a key T cannot see is still staged | `Every blind_deletion deletes an invisible_key.` `Every blind_deletion is staged.` |
| inserting a key already there, or deleting one not there, changes nothing | `Every redundant_insertion inserts a present_key.` `Every present_key is a committed_key.` `Every redundant_insertion is ignored.` (and the deletion's three) |
| one command's output on its own line, keys one per line | left out: the grammar has no shape for it |

Where a reading is the grammar's and not the sentence's meaning, it stays:
`Every transaction that is active may commit.` is `may_commit/1`, and the
outline then says "is may_commit". The notes are the readers' output as it
is.

## The complete IR (reasoning 1.17.3)

The coding endpoint's IR note of `mvccs_acid` read 5 of the requirement's
14 sentences, and the command table was not among them. The restatement
is read whole by the grammar, so its IR can be whole too, but the
translator's lexicon is not the grammar's: it reads no compound joined
by `_`, and `commit` and `abort` only as verbs. With no model it read 29
of the 64 sentences.

`TASK.translator.txt` is the restatement in a form the translator reads,
line N for line N, and `ir_complete.pl` reads it with the translator
alone and writes `TASK.ir`: every sentence of the restatement, its
translator form where that differs, and the IR of each sentence of that
form. For `mvccs_acid`: 64 sentences, 68 IR terms, 20 039 characters,
no model call, the same note at every run.

| the translator form | lines |
|---|---|
| the restatement's sentence as it stands, read right | 15 |
| the model's rewrite from the endpoint's repair (6 calls, $0.11, in a copy of the store), read right | 33 |
| by hand, after the model's rewrites were not read or were read wrong | 16 |

The hand lines (by the assistant that ran the benchmark) say the same
rule in words the translator reads right, each checked by its IR:
`Every commit is atomic.` is `A transaction commits atomically.`, the
commit id is `the counter` (`the version number` was read as the
comparative of `numb`), `Mvccs does not print a prompt.` is `The program
does not ask for input.` (the lexicon knows `prompt` as an adjective
alone), and a reading of `can`, `causes` or `present` as a noun was
replaced. Every one of the 68 readings was read back by hand for such a
misreading; the model's check was not used, because its verdicts moved
between runs (a second repair run judged 23 readings wrong and read 52
sentences where the first read 54).
