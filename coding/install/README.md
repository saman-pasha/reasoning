# Configure a reasoning client

These six scripts change **only the backend URL and token** of an
existing reasoning provider in OpenCode or Codex. They start no backend,
copy no model catalog or profile, and do not change the default model or
provider.

| client | Ubuntu | macOS | Windows |
|---|---|---|---|
| OpenCode | `opencode-config-ubuntu.sh` | `opencode-config-macos.sh` | `opencode-config-windows.ps1` |
| Codex | `codex-config-ubuntu.sh` | `codex-config-macos.sh` | `codex-config-windows.ps1` |

## Before running

The full installer must already have added the provider entry:

- OpenCode: `providers.reasoning` in
  `~/.config/opencode/opencode.json` (or `OPENCODE_CONFIG`).
- Codex: `[model_providers.reasoning]` in
  `~/.codex/config.toml` (or `CODEX_HOME`).

If it is missing, run the full installer first; the full install section
is in `coding/README.md`. The config scripts exit with a message rather
than writing a half provider.

Ubuntu and macOS need `python3`. The scripts use it to update JSON and
TOML without disturbing the rest of the file.

## Run

Interactively, the script asks for the URL and then the token. The URL
prompt shows the current URL as its default; pressing Enter keeps it. The
token prompt is hidden; pressing Enter keeps the existing token.

```sh
coding/install/opencode-config-macos.sh
coding/install/codex-config-macos.sh
```

Set the values to skip the prompts:

```sh
REASONING_BASE_URL=http://127.0.0.1:8787/v1 \
CODING_ENDPOINT_TOKEN='your-token' \
    coding/install/opencode-config-ubuntu.sh
```

`CODING_ENDPOINT_BASE_URL` is accepted as a fallback for the URL.

Windows (PowerShell):

```powershell
powershell -ExecutionPolicy Bypass -File coding\install\opencode-config-windows.ps1
powershell -ExecutionPolicy Bypass -File coding\install\codex-config-windows.ps1
```

or set the variables first to skip the prompts:

```powershell
$env:REASONING_BASE_URL = "http://127.0.0.1:8787/v1"
$env:CODING_ENDPOINT_TOKEN = "your-token"
powershell -ExecutionPolicy Bypass -File coding\install\codex-config-windows.ps1
```

## What is changed

OpenCode:

- `providers.reasoning.settings.baseURL`
- `providers.reasoning.settings.apiKey` when a token is entered

Codex:

- `[model_providers.reasoning]`'s `base_url`
- `experimental_bearer_token` when a token is entered

Everything else stays as it was: other providers, models, variants,
top-level defaults, profiles and comments. The old file is backed up
beside itself:

```text
config.toml.bak.20261116120000
```

The scripts do not set reasoning as the default. OpenCode still uses its
chosen default model; Codex still uses its existing `model` and
`model_provider`. Select reasoning explicitly with:

```sh
opencode -m reasoning/c-r0
codex -p reasoning
```

## URL

The default prompt value is the URL already in the config, or
`http://127.0.0.1:8787/v1` when there is none. Include the `/v1` part:

```text
http://127.0.0.1:8787/v1
```

## Token

Generate one with either form:

```sh
openssl rand -hex 32
openssl rand -base64 24 | tr '+/' '-_' | tr -d '=\n'
```

No further encoding is needed. A token must contain no whitespace and no
comma; commas separate multiple tokens in the endpoint's
`CODING_ENDPOINT_TOKEN`.

A blank token prompt keeps the token already in the client config. If
there is no existing token and none is entered, the token field is left
unchanged (OpenCode may still hold `{env:CODING_ENDPOINT_TOKEN}`; export
that variable before starting the client).

## After changing

Restart an open OpenCode or Codex TUI. After changing Codex, also restart
its daemon:

```sh
codex app-server daemon restart
```

Check the endpoint directly:

```sh
curl -s http://127.0.0.1:8787/health
curl -s -H "Authorization: Bearer $CODING_ENDPOINT_TOKEN" \
     http://127.0.0.1:8787/v1/models
```

and the client:

```sh
opencode -m reasoning/c-r0 "Reply with OK."
codex -p reasoning -m c-r0 "Reply with OK."
```
