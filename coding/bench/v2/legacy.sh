#!/bin/sh
# coding/bench/v2/legacy.sh -- run the frozen legacy benchmark.
#
#     ./coding/bench/v2/legacy.sh -- [task ...]
#
# This is the Phase 0 selector: it runs the unchanged
# coding/bench/bench.pl under the unchanged verification, for historical
# comparison only. v2 never calls it. With no task names it runs every
# legacy task and mode and spends model tokens.
#
# The baseline it reproduces is v2/results/baseline.md.

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
exec "$COCOLOG" -s coding/bench/bench.pl -- "$@"
