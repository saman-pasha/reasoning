# coding/endpoint

An OpenAI-compatible endpoint for [OpenCode](https://opencode.ai). OpenCode
sends its normal agent conversation, tools and stream; the endpoint appends
the language guide and forwards the request to an OpenAI-compatible model.

Two model names are exposed:

| model | guide |
|---|---|
| `c` | `prompts/c.md`, C with clang and the sanitizers, C99 through C23 (C17 unless the task names another) |
| `cocolog` | cocolog's own `SKILL.md`, `prompts/cocolog.md`, and the endpoint's reasoning pre-pass |

The endpoint is not a second agent loop. OpenCode still owns the read, edit
and shell tools, the session and the permissions. The guides tell the model
how to use those tools for C or cocolog. Both models declare a 1,000,000-token
context and an 8,192-token output limit; `/v1/models` reports the same limits.

`settings.reasoningEffort` defaults to `high`, and the models define the
variants `none`, `low`, `medium` and `high`. OpenCode sends the chosen level
as `reasoning_effort`, and the endpoint forwards it unchanged. `none` turns
the backend's thinking off; a higher level asks for more thinking, tokens and
latency. In the TUI, `ctrl+t` cycles the variants; on the command line name
one as `reasoning/c#none` or `reasoning/cocolog#high`.

## The reasoning pre-pass

For `reasoning/cocolog`, the endpoint reads the latest user turn with
`reasoning.pl`, which runs locally and calls no model:

- `coding/obligations.pl` derives checks from the request's keywords.
- `coding/contract.pl` reads controlled-English sentences through
  `library(reasoning/reason)` and derives the contract's checks.
- `library(reasoning/reason)` parses the text into terms; their count is
  recorded in the trace.

The deduplicated checks are appended to the cocolog system prompt under a
"Reasoning pre-pass" heading. The model still writes and runs the code with
OpenCode's tools, but it is checked against this repository's own reading of
the request. `CODING_ENDPOINT_REASONING=off` disables the pass. The `c` model
does not use it.

## The non-streaming cocolog httpd version

`httpd.pl` is the same endpoint written in cocolog, for a box that wants
the server in this repository's language. It asks the backend for one whole
reply — `library(curl)` has no streaming — and, when the client asked for
`stream: true` as OpenCode does, synthesises the reply as SSE: one content
(or tool-call) chunk, one finish chunk, then `[DONE]`.

```sh
export REASONING_API_KEY=...
export CODING_ENDPOINT_TOKEN=...
CODING_ENDPOINT_PORT=8790 coding/endpoint/run-httpd.sh
```

It uses the same guides, reasoning pre-pass, environment variables and
trace format as `server.py`. Its limits are the tradeoff: the whole reply
arrives before the first byte reaches OpenCode, and `library(tcp)` binds
every interface rather than loopback, so the bearer token is the guard.
Run one endpoint or the other on a port, not both.

OpenCode was checked against it with `reasoning/c` writing and compiling a
C file through `write`/`shell` tool calls, and with
`reasoning/cocolog#none` answering a cocolog prompt.

## Trace

Set `CODING_ENDPOINT_TRACE=/path/to/trace.jsonl` to write one JSON line per
completion request. A line carries the time, OpenCode session and project
ids, model, backend model, effort, `mode` (`reasoning`, `plain` or `title`),
the number of reasoning checks and parsed terms, message and tool counts,
the HTTP status and the seconds. The trace never includes prompts, replies
or the bearer token.

```sh
CODING_ENDPOINT_TRACE="$HOME/.local/state/opencode/reasoning-coding.jsonl" \
    coding/endpoint/run.sh
tail -f "$HOME/.local/state/opencode/reasoning-coding.jsonl"
```

## Start

```sh
export REASONING_API_KEY=...
coding/endpoint/run.sh
```

`run.sh` makes a random `CODING_ENDPOINT_TOKEN` when that variable is unset
and prints it. Every completion request must then carry
`Authorization: Bearer TOKEN`, and the `apiKey` in the installed OpenCode
config must be the same value. To keep a token across restarts, export
`CODING_ENDPOINT_TOKEN` yourself before `run.sh`. The model list and the
health page are open.

It listens on `http://127.0.0.1:8787/v1` by default. Check it:

```sh
curl -s http://127.0.0.1:8787/v1/models
curl -s http://127.0.0.1:8787/health
```

## Connect OpenCode

Copy `config/opencode.json` to `~/.config/opencode/opencode.json` for every
project, or to a project's `opencode.json` for one project. Its provider
`settings.apiKey` is `{env:CODING_ENDPOINT_TOKEN}` in the repository copy;
the installed copy carries the actual token, which must match the token
the running endpoint was given. The file uses OpenCode v2's
`providers`/`package`/`settings` shape.

Then either choose the model in the TUI, or name it on the command line:

```sh
opencode -m reasoning/c
opencode -m reasoning/cocolog
opencode run --standalone --auto -m reasoning/c \
    "Write hello.c, compile it with clang, and run it."
```

`--auto` auto-approves OpenCode's shell and edit permissions; without it,
OpenCode asks as usual.

## Backend

The endpoint forwards to an OpenAI-compatible chat endpoint. The default is
DeepSeek's OpenAI endpoint with `REASONING_API_KEY`:

| variable | default |
|---|---|
| `CODING_ENDPOINT_BACKEND` | `https://api.deepseek.com/v1/chat/completions` |
| `CODING_ENDPOINT_MODEL` | `deepseek-chat` |
| `CODING_ENDPOINT_C_MODEL` | the backend model |
| `CODING_ENDPOINT_COCOLOG_MODEL` | the backend model |
| `CODING_ENDPOINT_KEY_ENV` | `REASONING_API_KEY` |
| `CODING_ENDPOINT_TOKEN` | a fresh random token when `run.sh` starts |
| `CODING_ENDPOINT_ALLOW_ORIGIN` | the local OpenCode web origins |
| `CODING_ENDPOINT_REASONING` | `on` for `cocolog`; `off` disables the pre-pass |
| `CODING_ENDPOINT_TRACE` | unset; a JSONL path turns tracing on |
| `CODING_ENDPOINT_REASONING_BIN` | `../../cocolog/cocolog` beside this repository |
| `CODING_ENDPOINT_HOST` | `127.0.0.1` |
| `CODING_ENDPOINT_PORT` | `8787` |
| `CODING_ENDPOINT_MAX_TOKENS` | `8192` (0 leaves the client's limit) |
| `CODING_ENDPOINT_TIMEOUT` | `600` seconds |
| `COCOLOG_LIBRARY` | the repository's parent and cocolog's library |
| `COCOLOG_SKILL` | `../../cocolog/SKILL.md` beside this repository |

The backend key is read from the environment at each call and never logged
or written to disk by the server. The endpoint binds to loopback by
default, requires the bearer token when `CODING_ENDPOINT_TOKEN` is set, and
sends CORS headers only to the allowlisted origins. Do not expose it on a
public interface.

The request's `max_completion_tokens` is sent to the backend as
`max_tokens` and capped by `CODING_ENDPOINT_MAX_TOKENS`, because OpenCode
asks for 32 000 output tokens where the configured backend may allow fewer.
The OpenCode title-generation request is forwarded without a language guide.

## Test

```sh
python3 coding/endpoint/test.py -v
python3 coding/endpoint/test_httpd.py -v
```

The first test starts a fake backend and `server.py`; the second starts
`httpd.pl` against the same kind of fake backend. They check the model
list, the model mapping and token cap, the injected C guide, the title
request without a guide, the bearer-token guard, the forwarded effort,
the non-stream JSON, the synthesised SSE and the trace. No model is
called.

## Files

| path | what |
|---|---|
| `server.py` | the streaming endpoint, standard library only |
| `run.sh` | starts `server.py` and makes or accepts the bearer token |
| `httpd.pl` | the non-streaming endpoint in cocolog |
| `run-httpd.sh` | starts `httpd.pl` with the repository's library path |
| `reasoning_core.pl` | the shared obligations, contract and term reader |
| `config/opencode.json` | the provider, the two models and their variants |
| `reasoning.pl` | the command-line form of the pre-pass |
| `prompts/c.md` | the C guide, every edition from C99 to C23 |
| `prompts/cocolog.md` | the cocolog addendum to `SKILL.md` |
| `test.py` | the local checks for `server.py`, no model |
| `test_httpd.py` | the local checks for `httpd.pl`, no model |
