#!/bin/sh
# coding/cocolog/bench/run.sh -- run the cocolog codegen benchmark.
#
#   export REASONING_API_KEY=...
#   coding/cocolog/bench/run.sh              all tasks
#   coding/cocolog/bench/run.sh -- json      one task
#
# COCOLOG_LIBRARY is a colon-separated list like PATH.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
COCOLOG_LIBRARY="$PARENT:$PARENT/cocolog/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
cd "$ROOT"
exec "$COCOLOG" -s coding/cocolog/bench/bench.pl "$@"
