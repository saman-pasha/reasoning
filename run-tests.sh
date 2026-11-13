#!/bin/sh
# Runs the reasoning test cases from this repository's root.
#
#   sh run-tests.sh              all four: reason, normalise, tagger, translate
#   sh run-tests.sh reason       one of them
#
# The module names are library(reasoning/...), so the repository's PARENT
# directory goes on the library path; the cocolog checkout beside it (or a
# running cocolog's own library/) supplies the tier-2 libraries the cases
# use. COCOLOG names the binary to use, when it is not ../cocolog/cocolog.
set -e
ROOT=$(cd "$(dirname "$0")" && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
[ -x "$COCOLOG" ] || COCOLOG=$(command -v cocolog) || {
    echo "run-tests: no cocolog binary: set COCOLOG" >&2
    exit 1
}
LIBS="$PARENT"
[ -d "$PARENT/cocolog/library" ] && LIBS="$LIBS:$PARENT/cocolog/library"
[ -n "${COCOLOG_LIBRARY:-}" ] && LIBS="$LIBS:$COCOLOG_LIBRARY"
export COCOLOG_LIBRARY="$LIBS"
cd "$ROOT"
CASE=${1:-all}
case "$CASE" in
    all)      CASES="reason normalise tagger translate" ;;
    reason|normalise|tagger|translate) CASES=$CASE ;;
    *) echo "run-tests: no such case: $CASE" >&2; exit 1 ;;
esac
RED=0
for C in $CASES; do
    printf '%s\n' "===== $C ====="
    if "$COCOLOG" -s "test/$C.pl"; then :; else RED=$((RED + 1)); fi
done
exit "$RED"
