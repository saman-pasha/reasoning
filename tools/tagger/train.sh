#!/bin/sh
# Writes model.rows -- the shipped tagger, the rows tagger_export/2 writes,
# which tagger_pretrained/1 loads when the knowledge base a program proves
# against holds no model of its own -- with a cocolog. generate.pl writes
# the training data first, as files under generated/ (committed, so the
# data the shipped model learned from is in the tree), and train.pl trains
# on training.txt and measures; this only arranges the stores: it trains
# into a scratch --embed store and exports from it. (A store was the
# shipped form once and is not: sixteen megabytes for three of live rows,
# never shrinking below its high-water mark, in one machine's byte order.)
#
# The module names are library(reasoning/...), so this repository's PARENT
# directory goes on the library path; the cocolog checkout beside it (or a
# running cocolog's own library/) supplies the other libraries.
#
#   sh tools/tagger/train.sh [FILE]     FILE defaults to model.rows
#
# STORE=DIR trains into that --embed store and KEEPS it (since reasoning
# 1.17.0): the knowledge base the model was trained in, which a program run
# over it reads the tagger from with no file -- the exported rows are the
# same model, for every other store, which consults them in at first use.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
[ -x "$COCOLOG" ] || COCOLOG=$(command -v cocolog) || {
    echo "tagger: no cocolog binary: set COCOLOG" >&2; exit 1; }
cd "$ROOT"
FILE=${1:-$ROOT/model.rows}
LIBS="$PARENT"
[ -d "$PARENT/cocolog/library" ] && LIBS="$LIBS:$PARENT/cocolog/library"
[ -n "${COCOLOG_LIBRARY:-}" ] && LIBS="$LIBS:$COCOLOG_LIBRARY"
export COCOLOG_LIBRARY="$LIBS"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
KB=${STORE:-$TMP/train}
"$COCOLOG" -s "$ROOT/generate.pl"
"$COCOLOG" --embed "$KB" -s "$ROOT/train.pl"
"$COCOLOG" --embed "$KB" query "use_module(library(reasoning/tagger)), tagger_export(tagger, '$FILE')" > /dev/null
echo "tagger: wrote $FILE ($(du -sh "$FILE" | cut -f1))"
