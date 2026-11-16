#!/usr/bin/env bash
# Configure Codex's reasoning provider, model catalog and profile on Ubuntu.
#
#   REASONING_BASE_URL=http://127.0.0.1:8787/v1 \
#   CODING_ENDPOINT_TOKEN=... \
#       coding/install/codex-ubuntu.sh
#
# The backend must already be running at REASONING_BASE_URL (the default
# is the local endpoint). The script backs up ~/.codex/config.toml,
# merges the provider and defaults into it, and copies the model catalog
# and the reasoning profile beside it. Existing providers are kept.
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CODING_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
CATALOG_SOURCE="$CODING_DIR/endpoint/config/codex-model-catalog.json"
PROFILE_SOURCE="$CODING_DIR/endpoint/config/codex-reasoning.config.toml"

BASE_URL="${REASONING_BASE_URL:-${CODING_ENDPOINT_BASE_URL:-http://127.0.0.1:8787/v1}}"
BASE_URL="${BASE_URL%/}"
TOKEN="${CODING_ENDPOINT_TOKEN:-}"

[ -f "$CATALOG_SOURCE" ] || {
    echo "missing model catalog: $CATALOG_SOURCE" >&2
    exit 1
}
[ -f "$PROFILE_SOURCE" ] || {
    echo "missing Codex profile: $PROFILE_SOURCE" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required: sudo apt-get install -y python3" >&2
    exit 1
}

if [ -z "$TOKEN" ] && [ -t 0 ]; then
    printf 'Reasoning bearer token (blank keeps the existing token): '
    IFS= read -r -s TOKEN || true
    printf '\n'
fi

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="$CODEX_HOME/config.toml"
CATALOG_PATH="$CODEX_HOME/model-catalog.json"
PROFILE_PATH="$CODEX_HOME/reasoning.config.toml"
mkdir -p "$CODEX_HOME"

if [ -f "$CONFIG_PATH" ]; then
    cp -p "$CONFIG_PATH" "$CONFIG_PATH.bak.$(date +%Y%m%d%H%M%S)"
fi
if [ -f "$CATALOG_PATH" ]; then
    cp -p "$CATALOG_PATH" "$CATALOG_PATH.bak.$(date +%Y%m%d%H%M%S)"
fi
if [ -f "$PROFILE_PATH" ]; then
    cp -p "$PROFILE_PATH" "$PROFILE_PATH.bak.$(date +%Y%m%d%H%M%S)"
fi

cp "$CATALOG_SOURCE" "$CATALOG_PATH"
cp "$PROFILE_SOURCE" "$PROFILE_PATH"

python3 - "$CONFIG_PATH" "$CATALOG_PATH" "$BASE_URL" "$TOKEN" <<'PY'
import re
import sys

config_path, catalog_path, base_url, token = sys.argv[1:5]
try:
    with open(config_path, encoding="utf-8") as f:
        text = f.read()
except FileNotFoundError:
    text = ""

out = []
skip_reasoning = False
in_table = False
old_token = None

for line in text.splitlines():
    stripped = line.strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        name = stripped[1:-1].strip()
        if name == "model_providers.reasoning" or name.startswith(
            "model_providers.reasoning."
        ):
            skip_reasoning = True
            in_table = True
            continue
        skip_reasoning = False
        in_table = True
        out.append(line)
        continue
    if skip_reasoning:
        m = re.match(r'^\s*experimental_bearer_token\s*=\s*"(.*)"\s*$', line)
        if m:
            old_token = m.group(1)
        continue
    if not in_table and re.match(r"^\s*model_catalog_json\s*=", line):
        continue
    out.append(line)


def quote(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


token = token or old_token or ""
managed = [f"model_catalog_json = {quote(catalog_path)}"]
provider = [
    "",
    "[model_providers.reasoning]",
    'name = "Reasoning Coding Art"',
    f"base_url = {quote(base_url)}",
]
if token:
    provider.append(f"experimental_bearer_token = {quote(token)}")

final = managed + [""] + out + provider
merged = "\n".join(final).rstrip() + "\n"
with open(config_path, "w", encoding="utf-8") as f:
    f.write(merged)

try:
    import tomllib
except ImportError:
    tomllib = None
if tomllib is not None:
    try:
        tomllib.loads(merged)
    except Exception as exc:
        sys.exit(f"the merged Codex config is not valid TOML: {exc}")
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
        echo "warning: no healthy backend at $ROOT_URL/health; the Codex config is written anyway" >&2
    fi
else
    echo "warning: curl not found; skipped the health check" >&2
fi

if ! command -v codex >/dev/null 2>&1; then
    echo "Codex is not on PATH; install Codex 0.163 or later and rerun this script."
fi

echo "Codex reasoning provider configured in $CODEX_HOME"
echo "  model catalog: $CATALOG_PATH"
echo "  profile: $PROFILE_PATH"
echo "  base URL: $BASE_URL"
if [ -z "$TOKEN" ]; then
    echo "  bearer token: the existing one, if any; set CODING_ENDPOINT_TOKEN and rerun if the endpoint requires one"
fi
echo "No default model or provider was changed; select it with: codex -p reasoning"
echo "Restart Codex: codex app-server daemon restart"
echo "Try: codex -p reasoning -m c-r0 \"Reply with OK.\""
