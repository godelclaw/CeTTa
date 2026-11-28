#!/usr/bin/env python3
"""A store's journal replays in time proportional to its records.

check_space_service_replay.py SPACE_SERVICE

A store gains N rows, then loses every other one, each removal its own
journal record; the service is restarted, opens the store and stops. Its
processor time for that run is the cost: unlike the time until it accepts,
it does not grow while the machine is loaded or swapping. Symbols decoded
from the journal are new to the service, as a real store's are, so with
managed symbols they stay spelled. Replaying four times the records must
cost less than eight times as much: linear replay costs about four, and a
replay that rebuilds the match index on every removal about sixteen.
"""
import importlib.util
from pathlib import Path
import resource
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("space_service_client", ROOT / "tools/space_service_client.py")
csp = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = csp
spec.loader.exec_module(csp)
Client, S, E = csp.Client, csp.S, csp.E

SERVICE = str(Path(sys.argv[1]).resolve())
SMALL, LARGE, LIMIT = 3000, 12000, 8.0


def start(socket, data):
    process = subprocess.Popen([SERVICE, "--socket", socket, "--data", data],
                               stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    began = time.monotonic()
    while time.monotonic() - began < 600:
        if process.poll() is not None:
            raise SystemExit("FAIL: the service exited: " + process.stderr.read().decode(errors="replace"))
        if Path(socket).exists():
            try:
                with Client(socket) as client:
                    client.hello()
                return process, time.monotonic() - began
            except OSError:
                pass
        time.sleep(0.005)
    process.kill()
    raise SystemExit("FAIL: the service did not accept within 600 s")


def stop(process):
    process.terminate()
    process.wait(timeout=30)


def children_cpu():
    """Processor time, user and system, of the children waited for so far."""
    usage = resource.getrusage(resource.RUSAGE_CHILDREN)
    return usage.ru_utime + usage.ru_stime


def row(i):
    return E("replay-row", S("row-%d" % i), "text %d" % i)


def replay_seconds(count):
    with tempfile.TemporaryDirectory(prefix="cetta-replay-") as directory:
        socket, data = str(Path(directory) / "s.sock"), str(Path(directory) / "data")
        process, _ = start(socket, data)
        with Client(socket) as client:
            space = client.open("replay", "native")
            for first in range(0, count, 250):
                space.batch(*(E("add", row(i)) for i in range(first, min(count, first + 250))))
            for i in range(0, count, 2):
                space.remove(row(i))
        stop(process)
        before = children_cpu()
        process, _ = start(socket, data)
        with Client(socket) as client:
            space = client.open("replay", "native")
            space.describe()
            kept = space.count
        stop(process)
        seconds = children_cpu() - before
    if kept != count // 2:
        raise SystemExit("FAIL: %d rows after replay, expected %d" % (kept, count // 2))
    return seconds


small = replay_seconds(SMALL)
large = replay_seconds(LARGE)
# Below a twentieth of a second the small run is mostly the service starting:
# it is read as 0.05 s, so a fast large replay always passes.
ratio = large / max(small, 0.05)
print("replay: %d rows and %d removals %.3f s, %d rows and %d removals %.3f s of processor time, ratio %.1f (limit %.1f)"
      % (SMALL, SMALL // 2, small, LARGE, LARGE // 2, large, ratio, LIMIT))
if ratio > LIMIT:
    raise SystemExit("FAIL: replay grows faster than its journal")
print("PASS: space service replay")
