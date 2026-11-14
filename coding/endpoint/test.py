#!/usr/bin/env python3
"""Tests for coding/endpoint/server.py, with no model and no network.

The fake backend records the request the endpoint forwards, so the tests
can see the model mapping, the injected guide, the token cap and the
streamed bytes without asking a provider.
"""

import json
import os
import socket
import subprocess
import sys
import threading
import time
import unittest
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
SEEN = []


def free_port():
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        return sock.getsockname()[1]


class Backend(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt, *args):
        return

    def do_POST(self):
        length = int(self.headers.get("Content-Length", "0"))
        body = json.loads(self.rfile.read(length))
        SEEN.append(body)
        if body.get("stream"):
            self.send_response(200)
            self.send_header("Content-Type", "text/event-stream")
            self.send_header("Connection", "close")
            self.end_headers()
            self.wfile.write(
                b'data: {"choices":[{"delta":{"content":"ok"},"finish_reason":null}]}\n\n'
            )
            self.wfile.write(b"data: [DONE]\n\n")
            self.wfile.flush()
            self.close_connection = True
        else:
            data = json.dumps(
                {
                    "id": "test",
                    "object": "chat.completion",
                    "choices": [
                        {
                            "index": 0,
                            "message": {"role": "assistant", "content": "ok"},
                            "finish_reason": "stop",
                        }
                    ],
                }
            ).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)


def wait_for(url):
    for _ in range(100):
        try:
            with urllib.request.urlopen(url, timeout=1) as response:
                if response.status == 200:
                    return
        except Exception:
            time.sleep(0.05)
    raise RuntimeError(f"no answer at {url}")


def ask(url, payload):
    data = json.dumps(payload).encode()
    request = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=10) as response:
        return response.read()


class EndpointTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend_port = free_port()
        cls.backend = ThreadingHTTPServer(
            ("127.0.0.1", cls.backend_port), Backend
        )
        cls.backend_thread = threading.Thread(
            target=cls.backend.serve_forever, daemon=True
        )
        cls.backend_thread.start()
        cls.port = free_port()
        env = os.environ.copy()
        env.update(
            {
                "REASONING_API_KEY": "test-key",
                "CODING_ENDPOINT_PORT": str(cls.port),
                "CODING_ENDPOINT_BACKEND": (
                    f"http://127.0.0.1:{cls.backend_port}/v1/chat/completions"
                ),
                "CODING_ENDPOINT_MAX_TOKENS": "16",
            }
        )
        cls.server = subprocess.Popen(
            [sys.executable, str(HERE / "server.py")],
            env=env,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        cls.base = f"http://127.0.0.1:{cls.port}"
        wait_for(cls.base + "/health")

    @classmethod
    def tearDownClass(cls):
        cls.server.terminate()
        try:
            cls.server.wait(timeout=5)
        except subprocess.TimeoutExpired:
            cls.server.kill()
        cls.backend.shutdown()
        cls.backend.server_close()

    def setUp(self):
        SEEN.clear()

    def test_models(self):
        with urllib.request.urlopen(self.base + "/v1/models") as response:
            data = json.loads(response.read())
        self.assertEqual([m["id"] for m in data["data"]], ["c", "cocolog"])
        self.assertEqual(
            [m["context_length"] for m in data["data"]], [1000000, 1000000]
        )

    def test_c_request_maps_model_and_guide(self):
        ask(
            self.base + "/v1/chat/completions",
            {
                "model": "c",
                "messages": [{"role": "system", "content": "agent"},
                             {"role": "user", "content": "hello"}],
                "max_completion_tokens": 32000,
                "tools": [{"type": "function", "function": {"name": "read"}}],
            },
        )
        sent = SEEN[-1]
        self.assertEqual(sent["model"], "deepseek-chat")
        self.assertEqual(sent["max_tokens"], 16)
        self.assertIn("This session: C17", sent["messages"][0]["content"])
        self.assertEqual(len(sent["tools"]), 1)

    def test_effort_is_forwarded(self):
        ask(
            self.base + "/v1/chat/completions",
            {
                "model": "c",
                "messages": [{"role": "user", "content": "hello"}],
                "reasoning_effort": "low",
            },
        )
        self.assertEqual(SEEN[-1]["reasoning_effort"], "low")

    def test_title_request_gets_no_guide(self):
        ask(
            self.base + "/v1/chat/completions",
            {
                "model": "cocolog",
                "messages": [
                    {"role": "system", "content": "You name conversations."},
                    {"role": "user", "content": "a title"},
                ],
            },
        )
        sent = SEEN[-1]
        self.assertEqual(sent["model"], "deepseek-chat")
        self.assertNotIn("This session: C17", sent["messages"][0]["content"])
        self.assertNotIn("SKILL", sent["messages"][0]["content"])

    def test_cocolog_stream_passes_through(self):
        data = ask(
            self.base + "/v1/chat/completions",
            {
                "model": "cocolog",
                "stream": True,
                "messages": [{"role": "system", "content": "agent"},
                             {"role": "user", "content": "hello"}],
            },
        )
        sent = SEEN[-1]
        self.assertEqual(sent["model"], "deepseek-chat")
        self.assertIn("cocolog", sent["messages"][0]["content"])
        self.assertIn(b"data: ", data)
        self.assertIn(b"[DONE]", data)


if __name__ == "__main__":
    unittest.main()
