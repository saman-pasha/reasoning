#!/usr/bin/env bash
# Change OpenCode's reasoning URL and token in an existing config on macOS.
#
#   coding/install/opencode-config-ubuntu.sh
#
# The full installer must have added providers.reasoning first. This script
# asks for the URL and token, updates those two settings, backs up the
# config, and changes nothing else. It starts no backend.
set -euo pipefail

CONFIG_PATH="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"
[ -f "$CONFIG_PATH" ] || {
    echo "no OpenCode config at $CONFIG_PATH; run coding/install/opencode-ubuntu.sh first" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required: xcode-select --install (or brew install python3)" >&2
    exit 1
}

DEFAULT_URL=$(python3 - "$CONFIG_PATH" <<'PY'
import json
import sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        d = json.load(f)
    print(d["providers"]["reasoning"]["settings"].get(
        "baseURL", "http://127.0.0.1:8787/v1"))
except Exception:
    print("http://127.0.0.1:8787/v1")
PY
)

URL="${REASONING_BASE_URL:-${CODING_ENDPOINT_BASE_URL:-}}"
if [ -z "$URL" ] && [ -t 0 ]; then
    printf 'Reasoning backend URL [%s]: ' "$DEFAULT_URL"
    IFS= read -r URL || true
fi
URL="${URL:-$DEFAULT_URL}"
URL="${URL%/}"

TOKEN="${CODING_ENDPOINT_TOKEN:-}"
if [ -z "$TOKEN" ] && [ -t 0 ]; then
    printf 'Bearer token (blank keeps the existing token): '
    IFS= read -r -s TOKEN || true
    printf '\n'
fi

cp -p "$CONFIG_PATH" "$CONFIG_PATH.bak.$(date +%Y%m%d%H%M%S)"

python3 - "$CONFIG_PATH" "$URL" "$TOKEN" <<'PY'
import json
import os
import sys

path, url, token = sys.argv[1:4]
with open(path, encoding="utf-8") as f:
    d = json.load(f)

providers = d.get("providers")
if not isinstance(providers, dict) or "reasoning" not in providers:
    sys.exit("no providers.reasoning in the config; run the full installer first")
settings = providers["reasoning"].get("settings")
if not isinstance(settings, dict):
    settings = {}
    providers["reasoning"]["settings"] = settings
settings["baseURL"] = url
if token:
    settings["apiKey"] = token

tmp = path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, path)
PY

chmod 600 "$CONFIG_PATH"
echo "OpenCode reasoning settings updated in $CONFIG_PATH"
echo "  base URL: $URL"
if [ -z "$TOKEN" ]; then
    echo "  bearer token: unchanged"
fi
