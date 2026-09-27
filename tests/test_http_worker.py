#!/usr/bin/env python3
"""Private loopback fixture and journal; no production credentials or endpoints."""
import pathlib
import selectors
import subprocess
import sys
import tempfile

fixture, test = (str(pathlib.Path(x).resolve()) for x in sys.argv[1:])
with tempfile.TemporaryDirectory(prefix="cetta-http-worker-") as directory:
    server = subprocess.Popen([fixture], stdout=subprocess.PIPE, text=True)
    try:
        with selectors.DefaultSelector() as ready:
            ready.register(server.stdout, selectors.EVENT_READ)
            assert ready.select(timeout=5), "fixture did not start"
        port = int(server.stdout.readline().strip())
        subprocess.run([test, f"http://127.0.0.1:{port}", str(pathlib.Path(directory) / "journal.db")],
                       check=True, timeout=40)
    finally:
        server.terminate()
        server.wait(timeout=5)
