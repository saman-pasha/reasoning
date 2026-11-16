# Install the reasoning backend in a client

These scripts configure **OpenCode** or **Codex** to use a running
reasoning endpoint. They merge the provider into the client's config,
copy Codex's model catalog and profile, back up what they replace, and
check the backend's `/health`.

| client | Ubuntu | macOS | Windows |
|---|---|---|---|
| OpenCode | `opencode-ubuntu.sh` | `opencode-macos.sh` | `opencode-windows.ps1` |
| Codex | `codex-ubuntu.sh` | `codex-macos.sh` | `codex-windows.ps1` |

The backend itself is not started by these scripts. Run it first:

```sh
coding/endpoint/run-httpd.sh
```

or use an already deployed endpoint.

## Before installing

- The client must be installed:
  - OpenCode: an `opencode` command on `PATH`.
  - Codex: Codex 0.163 or later; `codex` on `PATH`. Codex uses the
    Responses API, which the endpoint serves at `/v1/responses`.
- Ubuntu and macOS need `python3`; the scripts use it to merge JSON and
  TOML safely.
- The scripts expect the repository layout: `coding/install/` beside
  `coding/endpoint/config/`.

## Run the installer

### Ubuntu or macOS

OpenCode:

```sh
REASONING_BASE_URL=http://127.0.0.1:8787/v1 \
CODING_ENDPOINT_TOKEN='your-token' \
    coding/install/opencode-ubuntu.sh      # or opencode-macos.sh
```

Codex:

```sh
REASONING_BASE_URL=http://127.0.0.1:8787/v1 \
CODING_ENDPOINT_TOKEN='your-token' \
    coding/install/codex-ubuntu.sh         # or codex-macos.sh
```

### Windows

Run PowerShell, set the same two variables, and run the script:

```powershell
$env:REASONING_BASE_URL = "http://127.0.0.1:8787/v1"
$env:CODING_ENDPOINT_TOKEN = "your-token"

powershell -ExecutionPolicy Bypass -File coding\install\opencode-windows.ps1
powershell -ExecutionPolicy Bypass -File coding\install\codex-windows.ps1
```

`-ExecutionPolicy Bypass` is needed on a default Windows installation
that blocks local `.ps1` files.

## Set the backend URL

The default is:

```text
http://127.0.0.1:8787/v1
```

Set `REASONING_BASE_URL` before the install (or `CODING_ENDPOINT_BASE_URL`
as a fallback) to use another endpoint. Include the `/v1` part:

```sh
REASONING_BASE_URL=https://example.test/reasoning/v1 \
    coding/install/codex-macos.sh
```

The health check removes the trailing `/v1` and asks for
`.../health`; the model list is `.../v1/models`.

## Set the bearer token

Set `CODING_ENDPOINT_TOKEN` during installation. If it is unset and the
installer is interactive, it asks for the token; the input is hidden.

If no token is entered:

- **OpenCode** keeps an existing `settings.apiKey`, or writes
  `{env:CODING_ENDPOINT_TOKEN}`. Export the variable before running
  OpenCode:
  ```sh
  export CODING_ENDPOINT_TOKEN='your-token'
  ```
- **Codex** keeps an existing `experimental_bearer_token`; if there is
  none, the line is omitted. Rerun the installer with the token if the
  endpoint requires one.

Generate a token with either form:

```sh
openssl rand -hex 32
openssl rand -base64 24 | tr '+/' '-_' | tr -d '=\n'
```

No further encoding is needed. A token must contain no whitespace and no
comma; commas separate several tokens in the endpoint's
`CODING_ENDPOINT_TOKEN`.

## Where the settings go

OpenCode (the first existing path is used, unless `OPENCODE_CONFIG`
names another file):

- `~/.config/opencode/opencode.json` (Ubuntu/macOS)
- `%USERPROFILE%\.config\opencode\opencode.json` (Windows)
- `%APPDATA%\opencode\opencode.json` (Windows, when that file exists)

The script replaces only `providers.reasoning`; other providers stay.
The provider is written at `settings.baseURL` and `settings.apiKey`.
It does not change OpenCode's default model; choose
`reasoning/c-r0` (or another name) when you want it.

Codex (or `CODEX_HOME` when set):

- `~/.codex/config.toml`
- `~/.codex/model-catalog.json`
- `~/.codex/reasoning.config.toml`

The script sets only `model_catalog_json` in `config.toml`:

```toml
model_catalog_json = "/home/you/.codex/model-catalog.json"
```

and replaces the `[model_providers.reasoning]` table:

```toml
[model_providers.reasoning]
name = "Reasoning Coding Art"
base_url = "http://127.0.0.1:8787/v1"
experimental_bearer_token = "your-token"
```

Other tables, providers and top-level defaults are kept. **The installer
does not make reasoning the default.** Plain `codex` keeps its existing
`model` and `model_provider`. To use the reasoning provider, select the
profile:

```sh
codex -p reasoning
```

That profile, copied to `reasoning.config.toml`, carries the model and
context settings:

```toml
model = "cocolog"
model_provider = "reasoning"
model_reasoning_effort = "none"
model_context_window = 1000000
model_auto_compact_token_limit = 900000
```

The model catalog is what makes the twelve names (`c`, `c-r0`,
`cocolog-r2`, `python-r8`, …) appear in Codex's `/model` picker. Selecting
one without the profile still uses your default provider, so use
`codex -p reasoning` (or set `model_provider = "reasoning"` yourself if
you want it as the default).

Every replaced file is backed up beside itself with a timestamp:

```text
config.toml.bak.20261116120000
```

## After installation

To change the URL or token later, either rerun the installer with new
environment values, or edit the client config:

- OpenCode: `providers.reasoning.settings.baseURL` and
  `providers.reasoning.settings.apiKey`.
- Codex: `[model_providers.reasoning]`'s `base_url` and
  `experimental_bearer_token`. The installer never changes your default
  model or provider; to make reasoning the default, add `model` and
  `model_provider` to the top level of `config.toml` yourself.

After editing Codex, restart its daemon so the new provider is used:

```sh
codex app-server daemon restart
```

Restart an open OpenCode or Codex TUI as well.

## Check

```sh
curl -s http://127.0.0.1:8787/health
curl -s -H "Authorization: Bearer $CODING_ENDPOINT_TOKEN" \
     http://127.0.0.1:8787/v1/models

opencode -m reasoning/c-r0 "Reply with OK."
codex -p reasoning -m c-r0 "Reply with OK."
```

If `/model` shows only the built-in models, the catalog path is wrong,
the catalog JSON is invalid, or Codex's daemon was not restarted.
