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
