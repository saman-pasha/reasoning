#!/bin/sh
# coding/endpoint/run.sh -- start the OpenCode coding endpoint.
#
#   export REASONING_API_KEY=...
#   coding/endpoint/run.sh
#
# The key is read from the environment by server.py and never written here.
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
command -v python3 >/dev/null 2>&1 || {
    echo "run.sh: python3 is not on PATH" >&2
    exit 1
}
if [ -z "${REASONING_API_KEY:-}" ]; then
    echo "run.sh: REASONING_API_KEY is not set" >&2
    exit 1
fi
exec python3 "$HERE/server.py" "$@"
