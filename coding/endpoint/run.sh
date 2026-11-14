#!/bin/sh
# coding/endpoint/run.sh -- start the OpenCode coding endpoint.
#
#   export REASONING_API_KEY=...
#   coding/endpoint/run.sh
#
# The backend key is read from the environment by server.py at each call
# and never written here.  run.sh does NOT require it: a backend that needs
# no key works without it, and one that does says so at the first call.
#
# A TOKEN KEEPS THE LOOPBACK PORT PRIVATE.  Any process on this machine --
# a page in a browser included -- can reach 127.0.0.1, and the endpoint
# forwards the backend key on its own.  run.sh sets CODING_ENDPOINT_TOKEN to
# a fresh random value and prints it, and the opencode.json this repository
# installs carries the same value in its apiKey.  Set CODING_ENDPOINT_TOKEN
# yourself to keep the one you have.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
command -v python3 >/dev/null 2>&1 || {
    echo "run.sh: python3 is not on PATH" >&2
    exit 1
}
if [ -z "${CODING_ENDPOINT_TOKEN:-}" ]; then
    CODING_ENDPOINT_TOKEN=$(python3 -c 'import secrets; print(secrets.token_urlsafe(24))')
    export CODING_ENDPOINT_TOKEN
fi
echo "run.sh: token ${CODING_ENDPOINT_TOKEN}" >&2
echo "run.sh: put it in coding/endpoint/config/opencode.json as the provider's apiKey" >&2
exec python3 "$HERE/server.py" "$@"
