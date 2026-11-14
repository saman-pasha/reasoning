#!/bin/sh
# coding/endpoint/run-httpd.sh -- the cocolog httpd endpoint.
#
#   export REASONING_API_KEY=...
#   export CODING_ENDPOINT_TOKEN=...
#   coding/endpoint/run-httpd.sh
#
# This version asks the backend for one whole reply: no SSE pass-through.
# It binds every interface (library(tcp) has no host argument), so the
# bearer token is the guard. Set CODING_ENDPOINT_PORT to move it.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
COCOLOG_LIBRARY="$PARENT:$PARENT/cocolog/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
cd "$ROOT"
exec "$COCOLOG" -s coding/endpoint/httpd.pl
