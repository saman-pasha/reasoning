#!/bin/sh
# coding/bench/paired.sh -- the paired repair comparison.
#
#   export REASONING_API_KEY=...
#   coding/bench/paired.sh              all tasks
#   coding/bench/paired.sh -- lcs       one task
#
# COCOLOG_LIBRARY is a colon-separated list like PATH. This script puts
# the repository's parent and the cocolog checkout beside it on the list,
# and keeps any paths already there.
set -e
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
COCOLOG_LIBRARY="$PARENT:$PARENT/cocolog/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
cd "$ROOT"
exec "$COCOLOG" query "use_module('coding/bench/paired.pl'), run" "$@"
