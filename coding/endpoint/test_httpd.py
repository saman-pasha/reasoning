#!/usr/bin/env python3
"""Tests for coding/endpoint/httpd.pl, with no model and no network.

The fake backend is the same shape test.py uses. This file checks the
cocolog server's model mapping, guide, token guard, non-stream JSON and
synthesised SSE; the reasoning pre-pass is off so the test needs no
reasoner subprocess.
"""

import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
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
        data = json.dumps(
            {
                "id": "test",
                "object": "chat.completion",
                "created": 1,
                "model": body.get("model"),
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
    for _ in range(200):
        try:
            with urllib.request.urlopen(url, timeout=1) as response:
                if response.status == 200:
                    return
        except Exception:
            time.sleep(0.05)
    raise RuntimeError(f"no answer at {url}")


def post(url, payload, token="test-token"):
    headers = {"Content-Type": "application/json"}
    if token is not None:
        headers["Authorization"] = f"Bearer {token}"
    request = urllib.request.Request(
        url, data=json.dumps(payload).encode(), headers=headers, method="POST"
    )
    with urllib.request.urlopen(request, timeout=20) as response:
        return response.read(), response.headers.get("Content-Type", "")


class HttpdTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend_port = free_port()
        cls.backend = ThreadingHTTPServer(("127.0.0.1", cls.backend_port), Backend)
        threading.Thread(target=cls.backend.serve_forever, daemon=True).start()
        cls.port = free_port()
        cls.tmp = tempfile.mkdtemp(prefix="coding-httpd-test-")
        cls.trace = os.path.join(cls.tmp, "trace.jsonl")
        env = os.environ.copy()
        env.update(
            {
                "REASONING_API_KEY": "test-key",
                "CODING_ENDPOINT_TOKEN": "test-token",
                "CODING_ENDPOINT_PORT": str(cls.port),
                "CODING_ENDPOINT_BACKEND": (
                    f"http://127.0.0.1:{cls.backend_port}/v1/chat/completions"
                ),
                "CODING_ENDPOINT_REASONING": "off",
                "CODING_ENDPOINT_TRACE": cls.trace,
            }
        )
        cls.server = subprocess.Popen(
            [str(HERE / "run-httpd.sh")],
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
        shutil.rmtree(cls.tmp, ignore_errors=True)

    def setUp(self):
        SEEN.clear()

    def test_models_and_limits(self):
        with urllib.request.urlopen(self.base + "/v1/models") as response:
            data = json.loads(response.read())
        self.assertEqual([m["id"] for m in data["data"]], ["c", "cocolog"])
        self.assertEqual([m["context_length"] for m in data["data"]],
                         [1000000, 1000000])

    def test_non_stream_maps_model_and_guide(self):
        data, ctype = post(
            self.base + "/v1/chat/completions",
            {
                "model": "c",
                "messages": [{"role": "system", "content": "agent"},
                             {"role": "user", "content": "hello"}],
                "stream": False,
            },
        )
        self.assertIn("application/json", ctype)
        reply = json.loads(data)
        self.assertEqual(reply["choices"][0]["message"]["content"], "ok")
        sent = SEEN[-1]
        self.assertEqual(sent["model"], "deepseek-chat")
        self.assertIn("This session: C", sent["messages"][0]["content"])

    def test_stream_is_synthesised(self):
        data, ctype = post(
            self.base + "/v1/chat/completions",
            {
                "model": "cocolog",
                "messages": [{"role": "user", "content": "hello"}],
                "stream": True,
            },
        )
        self.assertIn("text/event-stream", ctype)
        self.assertIn(b'"content":"ok"', data)
        self.assertIn(b'"finish_reason":"stop"', data)
        self.assertTrue(data.endswith(b"data: [DONE]\n\n"))
        self.assertFalse(SEEN[-1].get("stream"))
        self.assertNotIn("stream_options", SEEN[-1])

    def test_token_is_required(self):
        with self.assertRaises(urllib.error.HTTPError) as caught:
            post(
                self.base + "/v1/chat/completions",
                {
                    "model": "c",
                    "messages": [{"role": "user", "content": "hello"}],
                },
                token=None,
            )
        self.assertEqual(caught.exception.code, 401)

    def test_trace(self):
        post(
            self.base + "/v1/chat/completions",
            {
                "model": "c",
                "messages": [{"role": "user", "content": "hello"}],
                "stream": True,
            },
        )
        for _ in range(100):
            if os.path.exists(self.trace):
                with open(self.trace, encoding="utf-8") as handle:
                    lines = [json.loads(line) for line in handle if line.strip()]
                if lines:
                    record = lines[-1]
                    self.assertEqual(record["model"], "c")
                    self.assertEqual(record["mode"], "plain")
                    self.assertEqual(record["status"], 200)
                    return
            time.sleep(0.02)
        self.fail("no trace line")


if __name__ == "__main__":
    unittest.main()
