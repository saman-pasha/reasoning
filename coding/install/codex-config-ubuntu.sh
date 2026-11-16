#!/usr/bin/env bash
# Change Codex's reasoning URL and token in an existing config on Ubuntu.
#
#   coding/install/codex-config-ubuntu.sh
#
# The full installer must have added [model_providers.reasoning] first.
# This script asks for the URL and token, updates those two settings, backs
# up config.toml, and changes nothing else. It starts no backend.
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_PATH="$CODEX_HOME/config.toml"
[ -f "$CONFIG_PATH" ] || {
    echo "no Codex config at $CONFIG_PATH; run coding/install/codex-ubuntu.sh first" >&2
    exit 1
}

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required: sudo apt-get install -y python3" >&2
    exit 1
}

DEFAULT_URL=$(python3 - "$CONFIG_PATH" <<'PY'
import re
import sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
start = None
for i, line in enumerate(lines):
    if line.strip() == "[model_providers.reasoning]":
        start = i
        break
if start is None:
    sys.exit(2)

url = "http://127.0.0.1:8787/v1"
for line in lines[start + 1:]:
    if line.strip().startswith("["):
        break
    m = re.match(r'^\s*base_url\s*=\s*"(.*)"\s*$', line)
    if m:
        url = m.group(1)
        break
print(url)
PY
) || {
    echo "no [model_providers.reasoning] in $CONFIG_PATH; run coding/install/codex-ubuntu.sh first" >&2
    exit 1
}

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
import re
import sys

path, url, token = sys.argv[1:4]
lines = open(path, encoding="utf-8").read().splitlines()

start = None
for i, line in enumerate(lines):
    if line.strip() == "[model_providers.reasoning]":
        start = i
        break
if start is None:
    sys.exit("no [model_providers.reasoning] in the config; run the full installer first")

end = len(lines)
for j in range(start + 1, len(lines)):
    stripped = lines[j].strip()
    if stripped.startswith("[") and stripped.endswith("]"):
        end = j
        break


def quote(value):
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


block = []
found_url = False
found_token = False
for line in lines[start + 1:end]:
    if re.match(r"^\s*base_url\s*=", line):
        block.append(f"base_url = {quote(url)}")
        found_url = True
    elif token and re.match(r"^\s*experimental_bearer_token\s*=", line):
        block.append(f"experimental_bearer_token = {quote(token)}")
        found_token = True
    else:
        block.append(line)

if not found_url:
    block.insert(0, f"base_url = {quote(url)}")
if token and not found_token:
    at = 0
    for i, line in enumerate(block):
        if re.match(r"^\s*base_url\s*=", line):
            at = i + 1
            break
    block.insert(at, f"experimental_bearer_token = {quote(token)}")

merged = "\n".join(lines[:start + 1] + block + lines[end:]).rstrip() + "\n"
with open(path, "w", encoding="utf-8") as f:
    f.write(merged)

try:
    import tomllib
except ImportError:
    tomllib = None
if tomllib is not None:
    try:
        tomllib.loads(merged)
    except Exception as exc:
        sys.exit(f"the updated Codex config is not valid TOML: {exc}")
PY

chmod 600 "$CONFIG_PATH"
echo "Codex reasoning settings updated in $CONFIG_PATH"
echo "  base URL: $URL"
if [ -z "$TOKEN" ]; then
    echo "  bearer token: unchanged"
fi
echo "Restart Codex: codex app-server daemon restart"
