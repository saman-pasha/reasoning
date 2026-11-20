#!/bin/sh
# coding/endpoint/run-httpd.sh -- the cocolog httpd endpoint.
#
#   export CODING_ENDPOINT_KEY_ENV=...
#   export CODING_ENDPOINT_TOKEN=...
#   coding/endpoint/run-httpd.sh
#
# This version asks the backend for one whole reply: no SSE pass-through.
# It binds every interface (library(tcp) has no host argument), so the
# bearer token is the guard. Set CODING_ENDPOINT_PORT to move it.
#
# The knowledge base is an embedded store, CODING_ENDPOINT_STORE
# (coding/endpoint/store unless set): the lessons, rewrites and verdicts
# the model gives the translator (ir_repair.pl) are kept there, and the
# next process reads them. coding/endpoint/store is COMMITTED, so what one
# machine learned is the next one's start: it holds the first sentences
# of every request this endpoint read, word for word, so a server whose
# requests are private names a store of its own. Commit it only while no
# endpoint runs on it. CODING_ENDPOINT_STORE=local keeps everything in the
# process alone.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$HERE/../.." && pwd)
PARENT=$(dirname "$ROOT")
COCOLOG=${COCOLOG:-$PARENT/cocolog/cocolog}
COCOLOG_LIBRARY="$PARENT:$PARENT/cocolog/library${COCOLOG_LIBRARY:+:$COCOLOG_LIBRARY}"
export COCOLOG_LIBRARY
cd "$ROOT"
STORE=${CODING_ENDPOINT_STORE:-$ROOT/coding/endpoint/store}
if [ "$STORE" = local ]; then
    exec "$COCOLOG" -s coding/endpoint/httpd.pl
fi
mkdir -p "$STORE"
exec "$COCOLOG" --embed "$STORE" -s coding/endpoint/httpd.pl
