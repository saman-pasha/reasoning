# coding/endpoint

An OpenAI-compatible endpoint for [OpenCode](https://opencode.ai), written
in cocolog with `library(httpd)`. OpenCode sends its normal agent
conversation, tools and stream; the endpoint appends the language guide and
forwards the request to an OpenAI-compatible model.

Twelve model names are exposed:

| model | guide and reasoning checks |
|---|---|
| `c` | `prompts/c.md`, C with clang and the sanitizers, C99 through C23; the endpoint's default two checks |
| `cocolog` | cocolog's own `SKILL.md`, `prompts/cocolog.md`; the default two checks |
| `python` | `prompts/python.md`, Python 3 with `py_compile`, pytest or unittest; the default two checks |
| `c-r0`, `c-r2`, `c-r8` | the same C guide, with no checks, two checks or eight checks |
| `cocolog-r0`, `cocolog-r2`, `cocolog-r8` | the same cocolog guide, with no checks, two checks or eight checks |
| `python-r0`, `python-r2`, `python-r8` | the same Python guide, with no checks, two checks or eight checks |

The endpoint is not a second agent loop. OpenCode still owns the read, edit
and shell tools, the session and the permissions. Every model declares a
1,000,000-token context and a 32,768-token output limit.

Every model also defines the effort variants `none`, `minimal`, `low`,
`medium`, `high`, `xhigh`, `ultra` and `max`, so the reasoning count and
the effort are chosen independently:

```sh
reasoning/cocolog-r8#high     # eight checks and high model effort
reasoning/python#max          # two checks and max model effort
reasoning/c-r0#none           # plain mode, no checks, no model effort
```

`settings.reasoningEffort` defaults to `none`, and OpenCode sends the chosen
level as `reasoning_effort`; the endpoint forwards an explicit level
unchanged. A request that omits the field, or sends it blank, is forwarded
as `none`; the provider default is never used by accident. `ctrl+t` cycles
effort variants on the selected model. A request that omits `stream` is
treated as `stream: true`.

The `-rN` suffix is read by the endpoint itself, and the model config also
carries `x-coding-reasoning: N`. A request header still overrides both for a
one-off: `0`/`off` is plain mode, and a number keeps that many checks.

## Codex

Codex speaks only the Responses API, and since 0.163 it refuses
`wire_api = "chat"`. The endpoint serves `/v1/responses` too: a Responses
request is translated to the same chat request -- developer messages become
system messages, a run of `function_call` items becomes one assistant
message with several tool calls, and `function_call_output` becomes the tool
message that answers it -- passed through the same guide, reasoning checks
and loop guard, and the chat reply is written back as Responses SSE events
(or one Responses object). Codex's text and tool calls both round-trip.

Codex drops a reasoning item from its next input, but DeepSeek's thinking
mode wants the last reasoning back. The endpoint remembers the reasoning
per session (`session-id`) under the tool calls or the text it belonged to
and puts it on the rebuilt assistant messages; an assistant message always
carries the field, empty when there was no reasoning, because the backend
refuses one that omits it while thinking.

Copy `config/codex-model-catalog.json` to `~/.codex/model-catalog.json`.
The catalog is what puts the twelve names in Codex's `/model` picker;
without it Codex lists only the models it ships. Then add to the top of
`~/.codex/config.toml`, before any table:

```toml
model = "cocolog"
model_provider = "reasoning"
model_context_window = 1000000
model_auto_compact_token_limit = 900000
model_catalog_json = "~/.codex/model-catalog.json"

[model_providers.reasoning]
name = "Reasoning Coding Art"
base_url = "http://127.0.0.1:8787/v1"
experimental_bearer_token = "TOKEN"
```

`~/.codex/reasoning.config.toml`, selected with `codex -p reasoning`:

```toml
model = "cocolog"
model_provider = "reasoning"
model_reasoning_effort = "none"
model_context_window = 1000000
model_auto_compact_token_limit = 900000
```

`-m python-r8` picks another model, and `-c model_reasoning_effort=high`
picks the backend's effort. The base config names `cocolog` and
`reasoning` at the top level, so plain `codex` uses the same default
without `-p`; the catalog supplies the model metadata (1M context, 900k
auto-compaction) and the picker entries.

## What it is not

The backend call is **non-streaming**: `library(curl)` returns one whole
reply, and the endpoint then synthesises the SSE stream OpenCode asked for
(one content or tool-call chunk, one finish chunk, one usage chunk,
`[DONE]`). The whole reply arrives before OpenCode sees the first byte, so
the sidebar's token counts update once per model call rather than during
it; `library(httpd)` has no chunked encoding to carry a progress event.
The server also serves one connection at a time, and `library(tcp)` binds
every interface rather than loopback.

## Start

```sh
export CODING_ENDPOINT_KEY_ENV=...
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
completion request. A line carries the time, the session (`x-opencode-session`
or Codex's `session-id`) and project
ids, model, backend model, effort, `mode` (`reasoning`, `title`, or `plain`
when the pre-pass is off),
the number of reasoning checks and parsed terms, message and tool counts,
the HTTP status and the seconds. It also carries the backend's usage as
`prompt_tokens`, `completion_tokens`, `reasoning_tokens`, `total_tokens`
and `cache_hit_tokens`, all zero when the backend reports none. The
synthesized SSE stream ends with an OpenAI-shaped usage chunk carrying the
same counts, so OpenCode's sidebar shows the prompt, completion and
reasoning tokens after every model call. The trace never includes prompts,
replies or the bearer token.

```sh
CODING_ENDPOINT_TRACE="$HOME/.local/state/opencode/reasoning-coding.jsonl" \
    coding/endpoint/run-httpd.sh
tail -f "$HOME/.local/state/opencode/reasoning-coding.jsonl"
```

## Loop guard

Every request carries the session's tool history. The endpoint normalises a
shell command's digits (`names848.pl` and `names855.pl` are one signature)
and counts identical tool calls. A shell call is keyed by its command. A
tool whose arguments are a path alone is keyed by that path; an `edit` or a
`write` is keyed by its path and a digest of its other arguments, so
eighteen edits of one file with different hunks are eighteen signatures,
while the same edit twice is one. At 16 the request is refused with HTTP 409
and a message naming the repeated signature, before the backend is called.
`CODING_ENDPOINT_REPEAT_LIMIT` changes the limit; `0` disables the guard.

## Request bodies

The endpoint parses the whole request with cocolog's `json_parse/2`. That
parser refused a string holding `\u0000` -- "any character but a NUL" -- so
one tool that printed binary (`head -2 $(which timeout)`, say) put thousands
of NUL escapes into the next request and the endpoint answered HTTP 400
"the body is not JSON". The escape is now replaced with `�` before the
parse: the document stays valid and the tool's text keeps its place. A raw
NUL byte is still not JSON and is still refused.

## Backend

The endpoint forwards to an OpenAI-compatible chat endpoint or an
Anthropic-compatible Messages endpoint. The default is DeepSeek's OpenAI
endpoint with the backend key in `CODING_ENDPOINT_KEY_ENV`:

| variable | default |
|---|---|
| `CODING_ENDPOINT_API` | `openai`; `anthropic` speaks the Messages wire |
| `CODING_ENDPOINT_BACKEND` | `https://api.deepseek.com/v1/chat/completions`; the Anthropic default is `https://api.anthropic.com/v1/messages` |
| `CODING_ENDPOINT_MODEL` | `deepseek-chat` |
| `CODING_ENDPOINT_C_MODEL` | the backend model |
| `CODING_ENDPOINT_COCOLOG_MODEL` | the backend model |
| `CODING_ENDPOINT_PYTHON_MODEL` | the backend model |
| `CODING_ENDPOINT_KEY_ENV` | the backend key itself; required |
| `CODING_ENDPOINT_TOKEN` | unset; a bearer token when set |
| `CODING_ENDPOINT_ALLOW_ORIGIN` | the local OpenCode web origins |
| `CODING_ENDPOINT_REASONING` | `on` for every model; `off` disables the pre-pass |
| `CODING_ENDPOINT_REASONING_MIN` | `2`, filled with general checks if needed |
| `CODING_ENDPOINT_REASONING_MAX` | `2`, the checks kept from a longer reading |
| `x-coding-reasoning` header | per request: `0`/`off`, `2`, `8`, … |
| `CODING_ENDPOINT_TRACE` | unset; a JSONL path turns tracing on |
| `CODING_ENDPOINT_REPEAT_LIMIT` | `16`; `0` disables the repeated-tool-call guard |
| `CODING_ENDPOINT_HOST` | unused; `library(tcp)` binds every interface |
| `CODING_ENDPOINT_PORT` | `8787` |
| `CODING_ENDPOINT_MAX_TOKENS` | `32768` (0 leaves the client's limit) |
| `CODING_ENDPOINT_CONTEXT` | `1000000` |
| `CODING_ENDPOINT_TIMEOUT` | `600` seconds |
| `COCOLOG_LIBRARY` | set by `run-httpd.sh` |
| `COCOLOG_SKILL` | `../cocolog/SKILL.md` beside this repository |

Despite its name, `CODING_ENDPOINT_KEY_ENV` holds the key itself; it is
not the name of another variable. The generators, the benchmarks and the
endpoint all read that one variable. The backend key is read from the
environment at each call and never logged or written to disk by the
server. CORS headers go only to the allowlisted
origins, and a completion request needs `Authorization: Bearer TOKEN` when
`CODING_ENDPOINT_TOKEN` is set.

```sh
# OpenAI-compatible
export CODING_ENDPOINT_API=openai
export CODING_ENDPOINT_BACKEND=https://api.openai.com/v1/chat/completions
export CODING_ENDPOINT_KEY_ENV="$OPENAI_API_KEY"
export CODING_ENDPOINT_MODEL=gpt-5.1-codex

# Anthropic-compatible (api.anthropic.com or a gateway such as
# https://api.deepseek.com/anthropic/v1/messages)
export CODING_ENDPOINT_API=anthropic
export CODING_ENDPOINT_BACKEND=https://api.anthropic.com/v1/messages
export CODING_ENDPOINT_KEY_ENV="$ANTHROPIC_API_KEY"
export CODING_ENDPOINT_MODEL=claude-sonnet-4-5

coding/endpoint/run-httpd.sh
```

`CODING_ENDPOINT_C_MODEL`, `CODING_ENDPOINT_COCOLOG_MODEL` and
`CODING_ENDPOINT_PYTHON_MODEL` override the model per language; otherwise
all three use `CODING_ENDPOINT_MODEL`. The URL is the complete endpoint
(`/chat/completions` or `/messages`), not a base URL.

In `anthropic` mode the endpoint translates both ways: system messages
become the top-level `system` string, assistant tool calls become
`tool_use` blocks, tool results become `tool_result` blocks, and the reply's
text, tool calls, stop reason and usage (including cached input) become the
chat reply OpenCode and Codex read. `reasoning_effort` is not sent, because
the Messages API has no such field; the deterministic checks still follow
the model suffix (`-r0`, `-r2`, `-r8`).

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
guide merge, the usage reading and trace fields, the SSE synthesis for
text and tool calls, and the reasoning reader. No model is called and no
socket is opened.

## Files

| path | what |
|---|---|
| `httpd.pl` | the port, guards and `httpd_serve/2` |
| `httpd_core.pl` | pages, JSON, backend call, SSE synthesis, token/CORS, trace |
| `run-httpd.sh` | starts `httpd.pl` with the repository's library path |
| `reasoning_core.pl` | obligations, contract and reasoner reading |
| `reasoning.pl` | the command-line form of the pre-pass |
| `config/opencode.json` | the provider, the two models and their variants |
| `config/codex.toml` | Codex's top-level defaults and provider block, with a placeholder token |
| `config/codex-reasoning.config.toml` | Codex's `-p reasoning` profile |
| `config/codex-model-catalog.json` | the twelve models for Codex's `/model` picker |
| `prompts/c.md` | the C guide, every edition from C99 to C23 |
| `prompts/cocolog.md` | the cocolog addendum to `SKILL.md` |
| `test.pl` | the local checks, no model and no socket |

## Limits

- No incremental streaming: the backend reply is buffered.
- One request at a time (`concurrency(none)`).
- Every interface is bound; the bearer token is the guard.
- A client that requests `stream: true` gets synthesized SSE, not live
  tokens.
