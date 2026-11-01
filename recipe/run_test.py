import os
import shutil
import signal
import socket
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request

launcher = shutil.which("refine")
assert launcher, "refine launcher is missing"
flag = "/" if sys.platform == "win32" else "-"
help_result = subprocess.run([launcher, flag + "h"], capture_output=True, text=True, timeout=30)
assert "Usage:" in help_result.stdout, help_result.stdout + help_result.stderr

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    port = str(sock.getsockname()[1])

with tempfile.TemporaryDirectory() as directory, tempfile.TemporaryFile(mode="w+") as log:
    server = subprocess.Popen(
        [launcher, flag + "i", "127.0.0.1", flag + "p", port,
         flag + "d", directory, flag + "m", "256M"],
        env={**os.environ, "JAVA_OPTIONS": "-Drefine.headless=true"},
        stdout=log, stderr=subprocess.STDOUT,
        start_new_session=sys.platform != "win32",
    )
    try:
        deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if server.poll() is not None:
                raise RuntimeError("OpenRefine exited during startup")
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=3) as response:
                    assert b"OpenRefine" in response.read()
                break
            except (urllib.error.URLError, TimeoutError):
                time.sleep(0.5)
        else:
            raise TimeoutError("OpenRefine did not start")
    finally:
        if sys.platform == "win32":
            if server.poll() is None:
                subprocess.run(["taskkill", "/F", "/T", "/PID", str(server.pid)], check=True)
        else:
            try:
                os.killpg(server.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
        try:
            server.wait(timeout=10)
        except subprocess.TimeoutExpired:
            server.kill()
            server.wait()
        log.seek(0)
        print(log.read())
