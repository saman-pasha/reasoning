# library/reasoning/generated

What the shipped tagger was trained and measured on, written down.
`library/reasoning/generate.pl` writes these files from
`library(reasoning/normalise)` -- one canonical `pair(Noisy, Tokens, Tags,
Clean, Applied)` term a line, `normalise_save/2`'s form, read back by
`normalise_load/2` -- and `tools/tagger/train.sh` runs it before
`library/reasoning/train.pl` trains on `training.txt`.

| file | what |
|---|---|
| `training.txt` | seeds 1 to 32768 of the generator: the pairs `tagger_train/2` fitted the shipped `model.rows` to |
| `evaluation.txt` | seeds 30001 to 30300: the pairs `tagger_evaluate/4` measures a model on, which no training saw |

The generator is deterministic in its seed, so these files can be made
again from the code, the lexicon and the lessons -- and they are committed
anyway, because a shape, a lexicon file or a lesson line changed under a
seed makes a different pair, and the data a model was trained on would
otherwise be gone with it. The rule for everything under
`library/reasoning`: nothing trains on data the tree does not hold, and a
generator is a `.pl` file beside the data it writes.
