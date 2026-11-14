# coding/endpoint

An OpenAI-compatible endpoint for [OpenCode](https://opencode.ai). OpenCode
sends its normal agent conversation, tools and stream; the endpoint appends
the language guide and forwards the request to an OpenAI-compatible model.

Two model names are exposed:

| model | guide |
|---|---|
| `c` | `prompts/c.md`, C17 with clang and the sanitizers |
| `cocolog` | cocolog's own `SKILL.md` plus `prompts/cocolog.md` |

The endpoint is not a second agent loop. OpenCode still owns the read, edit
and shell tools, the session and the permissions. The guides tell the model
how to use those tools for C or cocolog.

## Start

```sh
export REASONING_API_KEY=...
coding/endpoint/run.sh
```

It listens on `http://127.0.0.1:8787/v1` by default. Check it:

```sh
curl -s http://127.0.0.1:8787/v1/models
curl -s http://127.0.0.1:8787/health
```

## Connect OpenCode

Copy `opencode.json` to `~/.config/opencode/opencode.json` for every
project, or to a project's `opencode.json` for one project. The installed
copy is kept at `config/opencode.json`. The file uses OpenCode v2's
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
| `CODING_ENDPOINT_HOST` | `127.0.0.1` |
| `CODING_ENDPOINT_PORT` | `8787` |
| `CODING_ENDPOINT_MAX_TOKENS` | `8192` (0 leaves the client's limit) |
| `CODING_ENDPOINT_TIMEOUT` | `600` seconds |
| `COCOLOG_SKILL` | `../../cocolog/SKILL.md` beside this repository |

The key is read from the environment at each call and never logged or
written to disk. The endpoint binds to loopback by default and has no
authentication of its own: do not expose it on a public interface.

The request's `max_completion_tokens` is sent to the backend as
`max_tokens` and capped by `CODING_ENDPOINT_MAX_TOKENS`, because OpenCode
asks for 32 000 output tokens where the configured backend may allow fewer.
The OpenCode title-generation request is forwarded without a language guide.

## Test

```sh
python3 coding/endpoint/test.py -v
```

The test starts a fake backend and the endpoint, then checks the model
list, the model mapping and token cap, the injected C guide, the title
request without a guide, and a streamed cocolog reply. No model is called.

## Files

| path | what |
|---|---|
| `server.py` | the endpoint, standard library only |
| `run.sh` | starts it with `REASONING_API_KEY` checked |
| `opencode.json` | the provider and the two models |
| `config/opencode.json` | the copy installed at `~/.config/opencode/` |
| `prompts/c.md` | the C17 guide |
| `prompts/cocolog.md` | the cocolog addendum to `SKILL.md` |
| `test.py` | the local checks, no model |
