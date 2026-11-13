#!/bin/sh
# Writes lexicon/{noun,class,adj,vt,vi,vpp,adverb,place,unit,language,prose,known_*}.txt
# from WordNet 3.0, with a cocolog -- lexicon/build.pl is the program, this
# only sets the library path. proper.txt is not touched.
#
# The module names are library(reasoning/...), so this repository's PARENT
# directory goes on the library path; the cocolog checkout beside it (or a
# running cocolog's own library/) supplies the other libraries.
#
#   WORDNET   WordNet 3.0's dict directory (default /usr/share/wordnet;
#             apt install wordnet-base; Homebrew: /usr/local/share/wordnet or /opt/homebrew/share/wordnet)
#   COCOLOG   the binary to use (default ../cocolog/cocolog, else PATH)
#   any further arguments go to build.pl: --cap CLASS=N, --out DIR
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
[ -x "$COCOLOG" ] || COCOLOG=$(command -v cocolog) || {
    echo "lexicon: no cocolog binary: set COCOLOG" >&2; exit 1; }
cd "$ROOT"
LIBS="$PARENT"
[ -d "$PARENT/cocolog/library" ] && LIBS="$LIBS:$PARENT/cocolog/library"
[ -n "${COCOLOG_LIBRARY:-}" ] && LIBS="$LIBS:$COCOLOG_LIBRARY"
COCOLOG_LIBRARY="$LIBS" \
  exec "$COCOLOG" -s "$ROOT/lexicon/build.pl" -- --wordnet "${WORDNET:-/usr/share/wordnet}" "$@"
