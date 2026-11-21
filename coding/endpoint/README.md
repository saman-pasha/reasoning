# coding/endpoint

An OpenAI-compatible endpoint for [OpenCode](https://opencode.ai), written
in cocolog with `library(httpd)`. OpenCode sends its normal agent
conversation, tools and stream; the endpoint appends the language guide to
the system prompt, puts the task said again in controlled English after the
task (C and Python), and forwards the request to an OpenAI-compatible model.

Twelve model names are exposed:

| model | guide and note |
|---|---|
| `c` | `prompts/c.md`, C with clang and the sanitizers, C99 through C23; the controlled English note |
| `cocolog` | this repository's `coding/cocolog/SKILL.md`, `prompts/cocolog.md`; no note unless `CODING_ENDPOINT_CONTROLLED_LANGS` names cocolog |
| `python` | `prompts/python.md`, Python 3 with `py_compile`, pytest or unittest; the controlled English note |
| `c-r0`, `c-r2`, `c-r8` | the same C guide; `-r0` with no note, `-r2` and `-r8` as `c` |
| `cocolog-r0`, `cocolog-r2`, `cocolog-r8` | the same cocolog guide; `-r0` with no note, `-r2` and `-r8` as `cocolog` |
| `python-r0`, `python-r2`, `python-r8` | the same Python guide; `-r0` with no note, `-r2` and `-r8` as `python` |

Through reasoning 1.17 the number after `-r` was the number of reasoning
checks sent. Since 1.18.0 the endpoint sends no checks (the next section),
and the names stay because clients name them: `-r0` turns the note off.

The endpoint is not a second agent loop. OpenCode still owns the read, edit
and shell tools, the session and the permissions. Every model declares a
1,000,000-token context and a 32,768-token output limit.

Every model also defines the effort variants `none`, `minimal`, `low`,
`medium`, `high`, `xhigh`, `ultra` and `max`, so the note and the effort
are chosen independently:

```sh
reasoning/python#max          # the note and max model effort
reasoning/c-r0#none           # plain mode, no note, no model effort
```

`settings.reasoningEffort` defaults to `none`, and OpenCode sends the chosen
level as `reasoning_effort`; the endpoint forwards an explicit level
unchanged. A request that omits the field, or sends it blank, is forwarded
as `none`; the provider default is never used by accident. `ctrl+t` cycles
effort variants on the selected model. A request that omits `stream` is
treated as `stream: true`.

The `-rN` suffix is read by the endpoint itself, and the model config also
carries `x-coding-reasoning: N`. A request header still overrides both for a
one-off: `0`/`off` is plain mode, and any other number sends the note.

## Codex

Codex speaks only the Responses API, and since 0.163 it refuses
`wire_api = "chat"`. The endpoint serves `/v1/responses` too: a Responses
request is translated to the same chat request -- developer messages become
system messages, a run of `function_call` items becomes one assistant
message with several tool calls, and `function_call_output` becomes the tool
message that answers it -- passed through the same guide, note
and loop guard, and the chat reply is written back as Responses SSE events
(or one Responses object). Codex's text and tool calls both round-trip.

Codex drops a reasoning item from its next input, but DeepSeek's thinking
mode wants the last reasoning back. The endpoint remembers the reasoning
per session (`session-id`) under the tool calls or the text it belonged to
and puts it on the rebuilt assistant messages; an assistant message always
carries the field, empty when there was no reasoning, because the backend
refuses one that omits it while thinking.

Codex ends its turn when a reply carries no function call, so a model that
writes "I’m running the gate now" and stops leaves the work undone. When a
reply with no tool call ends on an announcement of the next action, the
endpoint puts that reply in the history, adds a nudge and asks the backend
once more; the reply that carries the tool call is the one Codex sees. A
reply with a tool call, a truncated reply and a final answer are returned
unchanged. The extra calls are capped by
`CODING_ENDPOINT_CONTINUE_LIMIT` (default `2`), and
`CODING_ENDPOINT_CONTINUE=off` turns the guard off. The same guard applies
to OpenCode's chat route.

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
`[DONE]`). A preamble continuation is another whole backend call before
the stream is written. The whole reply arrives before OpenCode sees the
first byte, so
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

It listens on port `8787` unless `CODING_ENDPOINT_PORT` names another, and
keeps what the model taught the translator in the embedded store
`CODING_ENDPOINT_STORE` (`coding/endpoint/store`, committed: see "The
store" below; `CODING_ENDPOINT_STORE=local` keeps it in the process alone). The
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

## The controlled English note

The endpoint adds ONE note to a request, and only to C and Python: the
task -- the session's first user turn -- said again in the controlled
English this repository's reasoner reads, one sentence a line, after the
task in that same turn:

```text
<the task, as the client sent it>

# The request in controlled English

The same requirement, said again in the controlled English the repository's reasoner reads, one sentence a line:

Mvccs reads commands from the standard input.
...
```

That note, in that place, is what `coding/bench/v2` measured on
`mvccs_acid` (`coding/bench/v2/results/`: `controlled-english-python-3-20261121.md`
and `reason-python-20261121.md`):

| language | first program right, with the note | without | |
|---|---|---|---|
| Python | 104/180 | 79/180 | three runs, Cochran-Mantel-Haenszel one-sided p = 0.0058 |
| C | 15/20 | 14/20 | two-sided p = 1.0 |
| cocolog with its guide | 2/20 | 15/20 | two-sided p = 0.00007: the four input sentences are read as a code list to match (`controlled-ablation-20261121/`) |

So it is on for C and Python and off for cocolog:
`CODING_ENDPOINT_CONTROLLED_LANGS` (comma-separated, `c,python` unless set,
`none` for no language) chooses. In Python it cost 5 % more tokens over
the three runs and 8 % fewer calls. A task longer than
`CODING_ENDPOINT_CONTROLLED_MAX` characters (`12000`) gets no note.

The sentences are `reason_restate/3`'s (`library(reasoning/reason)`), in
live mode:

- a task the grammar reads already is its own sentences, and no model is
  asked;
- a task restated before is read from the knowledge base
  (`reason_live_restatement(Task, Sentences)`, kept in the embedded store),
  so the session's later turns, which send the same first turn, and the
  next process ask no model;
- any other task is said again by a model in the grammar's forms, and the
  sentences the grammar does not read go back to it, marked, with what the
  parser refuses and the form it reads instead
  (`REASON_LIVE_RESTATE_ROUNDS`, `3` calls at most); what reads is kept, in
  order, and what does not is left out. On `mvccs_acid`'s Python
  requirement (2 125 characters) `claude-sonnet-5-5` gave 56 sentences
  that read, 2 923 characters, in three calls: 9 336 prompt tokens and
  3 530 completion tokens, once for the task.

The model is `REASON_LIVE_*`'s (`library(reasoning/live)`). Where
`REASON_LIVE_KEY` is unset, the endpoint sets the four from the IR
repair's settings (`CODING_ENDPOINT_IR_API`, `_BACKEND`, `_KEY` and
`_MODEL`, each the endpoint's own unless set), so one key serves both. With
no key, or `CODING_ENDPOINT_RESTATE=off`, no model is asked: a task that
is neither controlled English nor restated before gets no note.
`REASON_LIVE_LOG=FILE` appends each round's prompt and reply to a file.

The system prompt is the language guide alone. Through reasoning 1.17 the
endpoint also sent, in the system prompt, the checks of a "Reasoning
pre-pass" (two by default), "What the request is about" and "The request in
the translator's IR", whose readings the model checked first
(`ir_repair.pl`). None of them is sent now: the controlled note is the one
the measurements back, and in Python the translator's IR and the readers'
own notes did no better than the requirement alone
(`reason-python-20261121.md`), and the complete IR did worse
(`complete-ir-20261121.md`).
`coding/bench/v2/ir_prep.pl` still writes them for a benchmark arm
(`ep_reasoning_notes/7`, `ep_ir_note/2`), `reasoning.pl` still prints the
checks, and `live_ir.pl` still grows the store's lessons; `ir_repair.pl`'s
header says how the repair works. `CODING_ENDPOINT_REASONING=off` sends no
note for any model.

### The store

`coding/endpoint/store` is committed (its `lock` is not), so what one machine
learned is the next machine's start, and every commit of it moves the
translator on. It was committed empty in reasoning 1.13.0, and 1.13.1 held
what `live_ir.pl` learned from three benchmark requirements. Since 1.13.2 it
holds what it learned from all twelve (`coding/bench/tasks.pl`), whose
sentences are in the tree already: 22 lessons, 20 rewrites, 65 verdicts (35
of them wrong readings) and 15 sentences unread -- most of them a table of
commands the splitter takes for one sentence, or a sentence with a list in
it, which the translator reads wrongly in every rewrite. Eight runs went to
it, rebuilt from 1.13.1's store; the first three found the faults 1.13.2
fixes, and the last two made no call. What a session needs to know before
committing it:

- **It holds every task the endpoint restated**, the whole first user turn
  word for word, as the key of its restatement (since 1.18.0), and the first
  sentences of every request `live_ir.pl` read, in its rewrites, verdicts
  and unread sentences; and the repository is public. An endpoint whose requests are private names a store
  of its own (`CODING_ENDPOINT_STORE=/path`), and a store is moved on into
  the tree only by a run whose sentences may be published (`live_ir.pl`).
- **It is one process's at a time**: stop the endpoint (`pgrep -x cocolog`
  prints nothing) before a query reads it and before `git add` takes it, or
  the commit may hold a store part way through a write.
- **It is in the writing machine's byte order** (`byteorder.bin`), which an
  open checks: x86-64 and Apple silicon are both little-endian, so it travels
  between them.

## Trace

Set `CODING_ENDPOINT_TRACE=/path/to/trace.jsonl` to write one JSON line per
completion request. A line carries the time, the session (`x-opencode-session`
or Codex's `session-id`) and project
ids, model, backend model, effort, `mode` (`reasoning`, `title`, or `plain`
when the note is off),
`reasoning`, the note's sentences (0 for no note; the number of checks
through 1.17), `terms` (0 since 1.18.0), message and tool counts,
`continued` (the extra backend calls made after a preamble), the HTTP
status and the seconds. It also carries the backend's usage, the
continuation's calls included, as
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
| `CODING_ENDPOINT_BACKEND` | `https://api.deepseek.com/v1/chat/completions` (`openai`); `https://api.deepseek.com/anthropic/v1/messages` (`anthropic`) |
| `CODING_ENDPOINT_MODEL` | `deepseek-chat` |
| `CODING_ENDPOINT_C_MODEL` | the backend model |
| `CODING_ENDPOINT_COCOLOG_MODEL` | the backend model |
| `CODING_ENDPOINT_PYTHON_MODEL` | the backend model |
| `CODING_ENDPOINT_KEY_ENV` | the backend key itself; required |
| `CODING_ENDPOINT_TOKEN` | unset; one or more bearer tokens, comma-separated |
| `CODING_ENDPOINT_ALLOW_ORIGIN` | the local OpenCode web origins |
| `CODING_ENDPOINT_REASONING` | `on` for every model; `off` sends no note |
| `CODING_ENDPOINT_CONTROLLED_LANGS` | `c,python`; the languages the note is sent for, `none` for none |
| `CODING_ENDPOINT_CONTROLLED_MAX` | `12000`; a longer task gets no note |
| `CODING_ENDPOINT_RESTATE` | `on`; `off` asks no model to restate a task |
| `REASON_LIVE_API`, `_URL`, `_KEY`, `_MODEL` | the restatement's model; the IR repair's settings where `REASON_LIVE_KEY` is unset |
| `REASON_LIVE_RESTATE_ROUNDS` | `3`; calls at most for one restatement |
| `CODING_ENDPOINT_REASONING_MIN` | `2`; `ir_prep.pl`'s checks only since 1.18.0 |
| `CODING_ENDPOINT_REASONING_MAX` | `2`; `ir_prep.pl`'s checks only since 1.18.0 |
| `x-coding-reasoning` header | per request: `0`/`off` for no note, a number for the note |
| `CODING_ENDPOINT_TRACE` | unset; a JSONL path turns tracing on |
| `CODING_ENDPOINT_CONTINUE` | `on`; `off` disables the preamble continuation |
| `CODING_ENDPOINT_CONTINUE_LIMIT` | `2`; extra backend calls after a preamble |
| `CODING_ENDPOINT_REPEAT_LIMIT` | `16`; `0` disables the repeated-tool-call guard |
| `CODING_ENDPOINT_HOST` | unused; `library(tcp)` binds every interface |
| `CODING_ENDPOINT_PORT` | `8787` |
| `CODING_ENDPOINT_MAX_TOKENS` | `32768` (0 leaves the client's limit) |
| `CODING_ENDPOINT_CONTEXT` | `1000000` |
| `CODING_ENDPOINT_TIMEOUT` | `600` seconds; the backend call's timeout |
| `CODING_ENDPOINT_STORE` | `coding/endpoint/store`; the embedded store `run-httpd.sh` runs on, `local` for none |
| `CODING_ENDPOINT_IR_REPAIR` | `on`; `off` asks no model about the translator's reading (`live_ir.pl` alone since 1.18.0, as are the IR rows below but the four the restatement takes) |
| `CODING_ENDPOINT_IR_CHECK` | `all`; every reading the model has not judged is checked, `always` every reading with every request, `failed` only what the translator could not read |
| `CODING_ENDPOINT_IR_API` | `CODING_ENDPOINT_API`; `openai` or `anthropic` for the repair's model |
| `CODING_ENDPOINT_IR_BACKEND` | the endpoint's backend, or the provider's own URL when `CODING_ENDPOINT_IR_API` is set |
| `CODING_ENDPOINT_IR_KEY` | `CODING_ENDPOINT_KEY_ENV`; the repair's key itself |
| `CODING_ENDPOINT_IR_MODEL` | `CODING_ENDPOINT_MODEL`; the repair's model |
| `CODING_ENDPOINT_IR_ROUNDS` | `3`; calls at most for one request |
| `CODING_ENDPOINT_IR_TRIES` | `2`; requests at most whose rounds end on a reading the model never saw |
| `CODING_ENDPOINT_IR_EFFORT` | `low` for `api.anthropic.com`, `none` elsewhere; `output_config.effort` |
| `CODING_ENDPOINT_IR_LOG` | none; a file each round's prompt and reply are appended to |
| `CODING_ENDPOINT_IR_SENTENCES` | `6`; the request's first sentences the translator reads |
| `CODING_ENDPOINT_IR_MAX_TOKENS` | `8000`; the repair reply's limit, thinking included |
| `COCOLOG_LIBRARY` | set by `run-httpd.sh` |
| `COCOLOG_SKILL` | `coding/cocolog/SKILL.md`, this repository's copy of the guide |

Despite its name, `CODING_ENDPOINT_KEY_ENV` holds the key itself; it is
not the name of another variable. The generators, the benchmarks and the
endpoint all read that one variable. The backend key is read from the
environment at each call and never logged or written to disk by the
server. CORS headers go only to the allowlisted
origins, and a completion request needs `Authorization: Bearer TOKEN` when
`CODING_ENDPOINT_TOKEN` is set. The variable is optional: unset or empty,
the port has no guard. When set, it may hold several comma-separated
tokens, and a request needs one of them; this is how a second client gets
its own token without sharing the first one. Generate one with
`openssl rand -hex 32`, or a 32-character base64url token with
`openssl rand -base64 24 | tr '+/' '-_' | tr -d '=\n'`; no further
encoding is needed. A token holds no whitespace and no comma, which
separates the list.

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
text and tool calls, the controlled English note, and the reasoning reader.
No model is called and no socket is opened: the restatement answers with a
stub model (`reason_live_stub/3`), and the IR repair's checks with another
(`ep_ir_model_stub/3`): a reading judged wrong and rewritten, a reading
confirmed, a rewrite read wrongly and caught, and a child process on an
embedded store that learns what a second child then reads with no call.

`live_ir.pl` runs the check and the repair against a real model on three
benchmark requirements, and costs money; it prints each reading in English
with its verdict. Run it twice on one store, and the second run makes no
call:

```sh
CODING_ENDPOINT_IR_API=anthropic CODING_ENDPOINT_IR_KEY="$TEST_API_KEY" \
CODING_ENDPOINT_IR_MODEL="$TEST_MODEL" \
COCOLOG_LIBRARY="$(dirname "$PWD"):$PWD/../cocolog/library" \
    ../cocolog/cocolog --embed coding/endpoint/store -s coding/endpoint/live_ir.pl
```

The trace line of a request carries the repair's counts: `ir_sentences`,
`ir_read`, `ir_lesson`, `ir_rewrite`, `ir_unread`, `ir_lessons`, `ir_calls`,
`ir_prompt_tokens`, `ir_completion_tokens`, and the verdicts the request
gave, `ir_checked` (right) and `ir_wrong`.

## Files

| path | what |
|---|---|
| `httpd.pl` | the port, guards and `httpd_serve/2` |
| `httpd_core.pl` | pages, JSON, backend call, the controlled English note, SSE synthesis, token/CORS, trace |
| `run-httpd.sh` | starts `httpd.pl` with the repository's library path |
| `reasoning_core.pl` | obligations, contract and reasoner reading |
| `english_lesson.pl` | the English lesson the translator reads a request by |
| `ir_repair.pl` | the model's check of each reading, its help with a sentence read wrongly or not read, and what it taught, kept |
| `live_ir.pl` | the check and the repair against a real model, on three benchmark requirements |
| `store/` | the embedded store the endpoint runs on: the restatements, and the lessons, rewrites and verdicts, committed |
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
- A preamble continuation costs one more whole backend call; two at most,
  unless `CODING_ENDPOINT_CONTINUE_LIMIT` says otherwise.
- One request at a time (`concurrency(none)`).
- Every interface is bound; the bearer token is the guard.
- A client that requests `stream: true` gets synthesized SSE, not live
  tokens.
