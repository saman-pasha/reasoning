#!/usr/bin/env bash
# Configure OpenCode's reasoning provider on macOS.
#
#   REASONING_BASE_URL=http://127.0.0.1:8787/v1 \
#   CODING_ENDPOINT_TOKEN=... \
#       coding/install/opencode-ubuntu.sh
#
# The backend must already be running at REASONING_BASE_URL (the default
# is the local endpoint). The provider is merged into
# ~/.config/opencode/opencode.json, or OPENCODE_CONFIG when set; other
# providers are left alone and the old file is backed up.
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODING_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SOURCE_CONFIG="$CODING_DIR/endpoint/config/opencode.json"

BASE_URL="${REASONING_BASE_URL:-${CODING_ENDPOINT_BASE_URL:-http://127.0.0.1:8787/v1}}"
BASE_URL="${BASE_URL%/}"
TOKEN="${CODING_ENDPOINT_TOKEN:-}"

[ -f "$SOURCE_CONFIG" ] || {
    echo "missing provider template: $SOURCE_CONFIG" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required: xcode-select --install (or brew install python3)" >&2
    exit 1
}

if [ -z "$TOKEN" ] && [ -t 0 ]; then
    printf 'Reasoning bearer token (blank uses {env:CODING_ENDPOINT_TOKEN}): '
    IFS= read -r -s TOKEN || true
    printf '\n'
fi

CONFIG_PATH="${OPENCODE_CONFIG:-$HOME/.config/opencode/opencode.json}"
mkdir -p "$(dirname -- "$CONFIG_PATH")"
if [ -f "$CONFIG_PATH" ]; then
    cp -p "$CONFIG_PATH" "$CONFIG_PATH.bak.$(date +%Y%m%d%H%M%S)"
fi

python3 - "$SOURCE_CONFIG" "$CONFIG_PATH" "$BASE_URL" "$TOKEN" <<'PY'
import json
import os
import sys

src_path, dst_path, base_url, token = sys.argv[1:5]
with open(src_path, encoding="utf-8") as f:
    src = json.load(f)
try:
    with open(dst_path, encoding="utf-8") as f:
        dst = json.load(f)
except FileNotFoundError:
    dst = {}
except json.JSONDecodeError as exc:
    sys.exit(f"{dst_path} is not valid JSON: {exc}")

providers = dst.setdefault("providers", {})
if not isinstance(providers, dict):
    sys.exit(f"{dst_path}: providers is not an object")

old = providers.get("reasoning", {})
old_settings = old.get("settings", {}) if isinstance(old, dict) else {}
old_key = old_settings.get("apiKey") if isinstance(old_settings, dict) else None

reasoning = src["providers"]["reasoning"]
settings = reasoning.setdefault("settings", {})
settings["baseURL"] = base_url
settings["apiKey"] = token or (old_key if isinstance(old_key, str) and old_key
                               else "{env:CODING_ENDPOINT_TOKEN}")
providers["reasoning"] = reasoning

if "$schema" in src and "$schema" not in dst:
    dst["$schema"] = src["$schema"]

tmp = dst_path + ".tmp"
with open(tmp, "w", encoding="utf-8") as f:
    json.dump(dst, f, indent=2, ensure_ascii=False)
    f.write("\n")
os.replace(tmp, dst_path)
PY

chmod 600 "$CONFIG_PATH"

ROOT_URL="${BASE_URL%/v1}"
if [ "$ROOT_URL" = "$BASE_URL" ]; then
    ROOT_URL="${BASE_URL%/}"
fi
if command -v curl >/dev/null 2>&1; then
    if curl -fsS --max-time 3 "$ROOT_URL/health" >/dev/null 2>&1; then
        echo "backend: healthy at $ROOT_URL/health"
    else
        echo "warning: no healthy backend at $ROOT_URL/health; the client config is written anyway" >&2
    fi
else
    echo "warning: curl not found; skipped the health check" >&2
fi

if ! command -v opencode >/dev/null 2>&1; then
    echo "OpenCode is not on PATH; install it and rerun this script."
fi

echo "OpenCode reasoning provider configured at $CONFIG_PATH"
echo "  base URL: $BASE_URL"
if [ -z "$TOKEN" ]; then
    echo "  apiKey: the existing one, or {env:CODING_ENDPOINT_TOKEN}; export it before running OpenCode"
fi
echo "Try: opencode -m reasoning/c-r0"
