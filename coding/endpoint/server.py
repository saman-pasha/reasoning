#!/usr/bin/env python3
"""An OpenAI-compatible coding endpoint for OpenCode.

OpenCode connects to ``http://127.0.0.1:8787/v1`` and chooses the model
``c`` or ``cocolog``.  This server appends the language's guide to the
system prompt, keeps the conversation, tools and stream the client sent,
and forwards the request to an OpenAI-compatible backend.

The server is deliberately local: it binds 127.0.0.1 by default, keeps no
state between requests, and reads the backend key from the environment at
each call.  It is not a second agent loop; OpenCode's tools are the loop.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]

HOST = os.environ.get("CODING_ENDPOINT_HOST", "127.0.0.1")
PORT = int(os.environ.get("CODING_ENDPOINT_PORT", "8787"))
BACKEND = os.environ.get(
    "CODING_ENDPOINT_BACKEND", "https://api.deepseek.com/v1/chat/completions"
)
BACKEND_MODEL = os.environ.get("CODING_ENDPOINT_MODEL", "deepseek-chat")
C_MODEL = os.environ.get("CODING_ENDPOINT_C_MODEL", BACKEND_MODEL)
COCOLOG_MODEL = os.environ.get("CODING_ENDPOINT_COCOLOG_MODEL", BACKEND_MODEL)
KEY_ENV = os.environ.get("CODING_ENDPOINT_KEY_ENV", "REASONING_API_KEY")
REQUEST_TIMEOUT = int(os.environ.get("CODING_ENDPOINT_TIMEOUT", "600"))
MAX_OUTPUT_TOKENS = int(os.environ.get("CODING_ENDPOINT_MAX_TOKENS", "8192"))
CONTEXT_WINDOW = int(os.environ.get("CODING_ENDPOINT_CONTEXT", "1000000"))
MAX_BODY = int(os.environ.get("CODING_ENDPOINT_MAX_BODY", str(8 * 1024 * 1024)))
COCOLOG_SKILL = Path(
    os.environ.get("COCOLOG_SKILL", str(ROOT.parent / "cocolog" / "SKILL.md"))
)

SERVICE = "reasoning-coding/1.0"
MODELS = ("c", "cocolog")
ALIASES = {
    "c": "c",
    "c17": "c",
    "cocolog": "cocolog",
    "cocolog-card": "cocolog",
}


def read_text(path):
    return path.read_text(encoding="utf-8")


def load_guides():
    c_guide = read_text(HERE / "prompts" / "c.md")
    cocolog_addendum = read_text(HERE / "prompts" / "cocolog.md")
    try:
        skill = read_text(COCOLOG_SKILL)
    except OSError as error:
        print(f"coding endpoint: no cocolog guide at {COCOLOG_SKILL}: {error}",
              file=sys.stderr, flush=True)
        skill = None
    guides = {"c": c_guide}
    if skill is not None:
        guides["cocolog"] = skill.rstrip() + "\n\n" + cocolog_addendum
    return guides


GUIDES = load_guides()


def alias_of(model):
    if not isinstance(model, str) or not model:
        return None
    return ALIASES.get(model.rsplit("/", 1)[-1].lower())


def backend_model(alias):
    return C_MODEL if alias == "c" else COCOLOG_MODEL


def is_title_request(messages):
    if not messages or not isinstance(messages, list):
        return False
    first = messages[0]
    if not isinstance(first, dict) or first.get("role") != "system":
        return False
    content = first.get("content")
    return isinstance(content, str) and content.startswith("You name conversations")


def add_guide(messages, guide):
    if not guide:
        return messages
    if messages and isinstance(messages[0], dict) and messages[0].get("role") == "system":
        content = messages[0].get("content")
        if isinstance(content, str):
            messages[0]["content"] = content.rstrip() + "\n\n" + guide
        elif isinstance(content, list):
            content.append({"type": "text", "text": guide})
        else:
            messages[0]["content"] = guide
    else:
        messages.insert(0, {"role": "system", "content": guide})
    return messages


def backend_key():
    key = os.environ.get(KEY_ENV, "")
    if not key:
        raise RuntimeError(f"{KEY_ENV} is not set")
    return key


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    server_version = SERVICE

    def log_message(self, fmt, *args):
        return

    def send_json(self, status, payload):
        body = json.dumps(payload, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body)

    def send_cors(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Authorization, Content-Type")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_OPTIONS(self):
        self.send_cors()

    def do_GET(self):
        path = urlsplit(self.path).path.rstrip("/") or "/"
        if path == "/v1/models":
            now = 0
            data = [
                {
                    "id": model,
                    "object": "model",
                    "created": now,
                    "owned_by": "reasoning-coding",
                    "name": "C17" if model == "c" else "cocolog",
                    "context_length": CONTEXT_WINDOW,
                    "max_output_tokens": MAX_OUTPUT_TOKENS,
                }
                for model in MODELS
            ]
            self.send_json(200, {"object": "list", "data": data})
            return
        if path in ("/health", "/"):
            self.send_json(
                200,
                {
                    "ok": True,
                    "service": SERVICE,
                    "models": list(MODELS),
                    "backend": BACKEND,
                    "backend_models": {"c": C_MODEL, "cocolog": COCOLOG_MODEL},
                    "guides": sorted(GUIDES),
                },
            )
            return
        self.send_json(404, {"error": {"message": f"no route {path}"}})

    def do_POST(self):
        path = urlsplit(self.path).path.rstrip("/")
        if path != "/v1/chat/completions":
            self.send_json(404, {"error": {"message": f"no route {path}"}})
            return
        length_text = self.headers.get("Content-Length", "0")
        try:
            length = int(length_text)
        except ValueError:
            self.send_json(400, {"error": {"message": "bad Content-Length"}})
            return
        if length <= 0 or length > MAX_BODY:
            self.send_json(413, {"error": {"message": "request body too large"}})
            return
        raw = self.rfile.read(length)
        try:
            body = json.loads(raw)
        except (ValueError, UnicodeDecodeError) as error:
            self.send_json(400, {"error": {"message": f"bad JSON: {error}"}})
            return
        if not isinstance(body, dict):
            self.send_json(400, {"error": {"message": "the body is not an object"}})
            return
        alias = alias_of(body.get("model"))
        if alias is None:
            self.send_json(
                400,
                {
                    "error": {
                        "message": "unknown model; use one of: " + ", ".join(MODELS)
                    }
                },
            )
            return
        guide = GUIDES.get(alias)
        if guide is None:
            self.send_json(
                500,
                {
                    "error": {
                        "message": f"the {alias} guide is not available; "
                        f"set COCOLOG_SKILL to the cocolog checkout's SKILL.md"
                    }
                },
            )
            return
        messages = body.get("messages")
        if not isinstance(messages, list) or not messages:
            self.send_json(400, {"error": {"message": "messages must be a non-empty list"}})
            return
        title = is_title_request(messages)
        if not title:
            add_guide(messages, guide)
        body["model"] = backend_model(alias)
        if "max_completion_tokens" in body:
            wanted = body.pop("max_completion_tokens")
            if isinstance(wanted, int) and wanted > 0:
                body["max_tokens"] = wanted
        if MAX_OUTPUT_TOKENS > 0:
            wanted = body.get("max_tokens")
            if not isinstance(wanted, int) or wanted <= 0 or wanted > MAX_OUTPUT_TOKENS:
                body["max_tokens"] = MAX_OUTPUT_TOKENS
        stream = bool(body.get("stream"))
        tools = body.get("tools")
        tool_count = len(tools) if isinstance(tools, list) else 0
        effort = body.get("reasoning_effort", "-")
        print(
            f"{alias} -> {body['model']} stream={str(stream).lower()} "
            f"messages={len(messages)} tools={tool_count} "
            f"effort={effort} guide={'no' if title else 'yes'}",
            file=sys.stderr,
            flush=True,
        )
        try:
            key = backend_key()
        except RuntimeError as error:
            self.send_json(500, {"error": {"message": str(error)}})
            return
        request = urllib.request.Request(
            BACKEND,
            data=json.dumps(body, ensure_ascii=False, separators=(",", ":")).encode(
                "utf-8"
            ),
            headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json",
                "Accept": "text/event-stream" if stream else "application/json",
                "Accept-Encoding": "identity",
                "User-Agent": SERVICE,
            },
            method="POST",
        )
        try:
            response = urllib.request.urlopen(request, timeout=REQUEST_TIMEOUT)
        except urllib.error.HTTPError as error:
            data = error.read()
            ctype = error.headers.get("Content-Type", "application/json")
            self.send_response(error.code)
            self.send_header("Content-Type", ctype)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)
            return
        except Exception as error:
            self.send_json(502, {"error": {"message": f"backend failed: {error}"}})
            return
        try:
            if stream:
                self.send_response(response.status)
                self.send_header(
                    "Content-Type",
                    response.headers.get("Content-Type", "text/event-stream"),
                )
                self.send_header("Cache-Control", "no-cache")
                self.send_header("X-Accel-Buffering", "no")
                self.end_headers()
                while True:
                    chunk = response.read1(8192) if hasattr(response, "read1") else response.read(8192)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    self.wfile.flush()
            else:
                data = response.read()
                self.send_response(response.status)
                self.send_header(
                    "Content-Type",
                    response.headers.get("Content-Type", "application/json"),
                )
                self.send_header("Content-Length", str(len(data)))
                self.send_header("Access-Control-Allow-Origin", "*")
                self.end_headers()
                self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            pass
        finally:
            response.close()


class Server(ThreadingHTTPServer):
    daemon_threads = True
    allow_reuse_address = True


def main():
    server = Server((HOST, PORT), Handler)
    print(
        f"coding endpoint {SERVICE} on http://{HOST}:{PORT}/v1 "
        f"(models: {', '.join(MODELS)}; backend: {BACKEND})",
        file=sys.stderr,
        flush=True,
    )
    if "cocolog" not in GUIDES:
        print(f"coding endpoint: cocolog is unavailable until {COCOLOG_SKILL} exists",
              file=sys.stderr, flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
