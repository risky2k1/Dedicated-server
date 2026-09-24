#!/usr/bin/env python3
"""Tiny localhost JSON API for Valheim process/port status (nginx proxies /api/status)."""

from __future__ import annotations

import json
import subprocess
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

SERVICE = "valheim"
HOST = "127.0.0.1"
PORT = 18765
GAME_PORTS = (2456, 2457)


def run(cmd: list[str]) -> tuple[int, str]:
    try:
        p = subprocess.run(
            cmd,
            check=False,
            capture_output=True,
            text=True,
            timeout=5,
        )
        return p.returncode, (p.stdout or "").strip()
    except (OSError, subprocess.TimeoutExpired) as exc:
        return 1, str(exc)


def collect() -> dict:
    code, state = run(["systemctl", "is-active", SERVICE])
    active = code == 0 and state == "active"
    _, ss_out = run(["ss", "-ulnp"])
    ports_listening = {
        str(p): (f":{p}" in ss_out and "valheim" in ss_out.lower())
        or (f":{p}" in ss_out)
        for p in GAME_PORTS
    }
    # Prefer matching valheim process when possible
    ports_ok = any(ports_listening.values())
    pid = None
    _, main_pid = run(["systemctl", "show", "-p", "MainPID", "--value", SERVICE])
    if main_pid.isdigit() and int(main_pid) > 0:
        pid = int(main_pid)

    return {
        "ok": True,
        "checked_at": int(time.time()),
        "service": SERVICE,
        "active": active,
        "state": state or "unknown",
        "pid": pid,
        "ports": ports_listening,
        "listening": ports_ok,
        "process_online": active and ports_ok,
    }


class Handler(BaseHTTPRequestHandler):
    def do_GET(self) -> None:  # noqa: N802
        if self.path.split("?", 1)[0] not in ("/status", "/api/status", "/status.json"):
            self.send_error(404)
            return
        body = json.dumps(collect(), separators=(",", ":")).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt: str, *args) -> None:  # noqa: A003
        return


def main() -> None:
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
