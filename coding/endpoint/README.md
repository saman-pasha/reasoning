# coding/endpoint

An OpenAI-compatible endpoint for [OpenCode](https://opencode.ai), written
in cocolog with `library(httpd)`. OpenCode sends its normal agent
conversation, tools and stream; the endpoint appends the language guide and
forwards the request to an OpenAI-compatible model.

Eight model names are exposed:

| model | guide and reasoning checks |
|---|---|
| `c` | `prompts/c.md`, C with clang and the sanitizers, C99 through C23; the endpoint's default two checks |
| `cocolog` | cocolog's own `SKILL.md`, `prompts/cocolog.md`; the default two checks |
| `c-r0`, `c-r2`, `c-r8` | the same C guide, with no checks, two checks or eight checks |
| `cocolog-r0`, `cocolog-r2`, `cocolog-r8` | the same cocolog guide, with no checks, two checks or eight checks |

The endpoint is not a second agent loop. OpenCode still owns the read, edit
and shell tools, the session and the permissions. Every model declares a
1,000,000-token context and a 32,768-token output limit.

Every model also defines the effort variants `none`, `low`, `medium` and
`high`, so the reasoning count and the effort are chosen independently:

```sh
reasoning/cocolog-r8#high     # eight checks and high model effort
reasoning/c-r0#none           # plain mode, no checks, no model effort
```

`settings.reasoningEffort` defaults to `none`, and OpenCode sends the chosen
level as `reasoning_effort`; the endpoint forwards it unchanged. `ctrl+t`
cycles effort variants on the selected model. A request that omits `stream`
is treated as `stream: true`.

The `-rN` suffix is read by the endpoint itself, and the model config also
carries `x-coding-reasoning: N`. A request header still overrides both for a
one-off: `0`/`off` is plain mode, and a number keeps that many checks.

## What it is not

The backend call is **non-streaming**: `library(curl)` returns one whole
reply, and the endpoint then synthesises the SSE stream OpenCode asked for
(one content or tool-call chunk, one finish chunk, `[DONE]`). The whole reply
arrives before OpenCode sees the first byte. The server also serves one
connection at a time, and `library(tcp)` binds every interface rather than
loopback.

## Start

```sh
export REASONING_API_KEY=...
export CODING_ENDPOINT_TOKEN=...
coding/endpoint/run-httpd.sh
```

It listens on port `8787` unless `CODING_ENDPOINT_PORT` names another. The
token is required when set; without it the server warns and the port is
open. Because the socket binds every interface, keep the token and the
port behind a firewall.

Check it:

```sh
curl -s http://127.0.0.1:8787/v1/models
curl -s http://127.0.0.1:8787/health
```

## Connect OpenCode

Copy `config/opencode.json` to `~/.config/opencode/opencode.json` for every
project, or to a project's `opencode.json` for one project. Its provider
`settings.apiKey` is `{env:CODING_ENDPOINT_TOKEN}` in the repository copy;
the installed copy carries the actual token, which must match the token the
running endpoint was given. The file uses OpenCode v2's
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

## The reasoning pre-pass

For every model, including the `-r0`, `-r2` and `-r8` names, the endpoint
reads the session's first user turn with `reasoning_core.pl`, which runs
locally and calls no model:

- `coding/obligations.pl` derives checks from the request's keywords.
- `coding/contract.pl` reads controlled-English sentences through
  `library(reasoning/reason)` and derives the contract's checks.
- `library(reasoning/reason)` parses the text into terms; their count is
  recorded in the trace.

The deduplicated checks are appended to the model's system prompt under a
"Reasoning pre-pass" heading. By default the pass keeps exactly two: the
task's first two, general checks when the task's wording gives fewer, and no
more when it gives more. That is the usual trace's `mode=reasoning` and
`reasoning=2`. The `-rN` model suffix and a request's `x-coding-reasoning`
header override both ends: `0` or `off` turns the pass off, and a number
keeps that many checks. `CODING_ENDPOINT_REASONING_MIN` and
`CODING_ENDPOINT_REASONING_MAX` change the two ends for requests with
neither. The model still writes and runs the code with OpenCode's tools, but
it is checked against this repository's own reading of the request.
`CODING_ENDPOINT_REASONING=off` disables the pass for every model.

## Trace

Set `CODING_ENDPOINT_TRACE=/path/to/trace.jsonl` to write one JSON line per
completion request. A line carries the time, OpenCode session and project
ids, model, backend model, effort, `mode` (`reasoning`, `title`, or `plain`
when the pre-pass is off),
the number of reasoning checks and parsed terms, message and tool counts,
the HTTP status and the seconds. The trace never includes prompts, replies
or the bearer token.

```sh
CODING_ENDPOINT_TRACE="$HOME/.local/state/opencode/reasoning-coding.jsonl" \
    coding/endpoint/run-httpd.sh
tail -f "$HOME/.local/state/opencode/reasoning-coding.jsonl"
```

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
| `CODING_ENDPOINT_TOKEN` | unset; a bearer token when set |
| `CODING_ENDPOINT_ALLOW_ORIGIN` | the local OpenCode web origins |
| `CODING_ENDPOINT_REASONING` | `on` for both models; `off` disables the pre-pass |
| `CODING_ENDPOINT_REASONING_MIN` | `2`, filled with general checks if needed |
| `CODING_ENDPOINT_REASONING_MAX` | `2`, the checks kept from a longer reading |
| `x-coding-reasoning` header | per request: `0`/`off`, `2`, `8`, … |
| `CODING_ENDPOINT_TRACE` | unset; a JSONL path turns tracing on |
| `CODING_ENDPOINT_HOST` | unused; `library(tcp)` binds every interface |
| `CODING_ENDPOINT_PORT` | `8787` |
| `CODING_ENDPOINT_MAX_TOKENS` | `32768` (0 leaves the client's limit) |
| `CODING_ENDPOINT_CONTEXT` | `1000000` |
| `CODING_ENDPOINT_TIMEOUT` | `600` seconds |
| `COCOLOG_LIBRARY` | set by `run-httpd.sh` |
| `COCOLOG_SKILL` | `../cocolog/SKILL.md` beside this repository |

The backend key is read from the environment at each call and never logged
or written to disk by the server. CORS headers go only to the allowlisted
origins, and a completion request needs `Authorization: Bearer TOKEN` when
`CODING_ENDPOINT_TOKEN` is set.

The request's `max_completion_tokens` is sent to the backend as
`max_tokens` and capped by `CODING_ENDPOINT_MAX_TOKENS`. `stream_options` is
removed because the backend call is not streamed. The OpenCode title request
is forwarded without a language guide or reasoning pass.

## Test

```sh
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog -s coding/endpoint/test.pl
```

The test checks the model and health replies, the bearer-token guard, the
guide merge, the SSE synthesis for text and tool calls, and the reasoning
reader. No model is called and no socket is opened.

## Files

| path | what |
|---|---|
| `httpd.pl` | the port, guards and `httpd_serve/2` |
| `httpd_core.pl` | pages, JSON, backend call, SSE synthesis, token/CORS, trace |
| `run-httpd.sh` | starts `httpd.pl` with the repository's library path |
| `reasoning_core.pl` | obligations, contract and reasoner reading |
| `reasoning.pl` | the command-line form of the pre-pass |
| `config/opencode.json` | the provider, the two models and their variants |
| `prompts/c.md` | the C guide, every edition from C99 to C23 |
| `prompts/cocolog.md` | the cocolog addendum to `SKILL.md` |
| `test.pl` | the local checks, no model and no socket |

## Limits

- No incremental streaming: the backend reply is buffered.
- One request at a time (`concurrency(none)`).
- Every interface is bound; the bearer token is the guard.
- A client that requests `stream: true` gets synthesized SSE, not live
  tokens.
