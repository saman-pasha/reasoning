#!/bin/sh
# coding/bench/v2/run.sh -- the v2 runner from any directory.
#
#     ./coding/bench/v2/run.sh --plan
#     ./coding/bench/v2/run.sh --run --tasks lcs --modes plain --trials 1
#
# COCOLOG names the binary (default: the cocolog checkout beside this
# repository). COCOLOG_LIBRARY is set for the checkout, not inherited.

set -eu

HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROOT=$(CDPATH= cd -- "$HERE/../../.." && pwd)
COCOLOG=${COCOLOG:-"$ROOT/../cocolog/cocolog"}

if [ ! -x "$COCOLOG" ]; then
    echo "no cocolog binary at $COCOLOG; set COCOLOG" >&2
    exit 2
fi

COCOLOG_LIBRARY=$(dirname "$ROOT"):"$ROOT/../cocolog/library"
export COCOLOG_LIBRARY
cd "$ROOT"
exec "$COCOLOG" -s coding/bench/v2/run.pl -- "$@"
