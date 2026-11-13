#!/usr/bin/env python3
"""A child of proc:run or proc:request ends when the engine does, in HE, PeTTa and Prime.

The engine starts `sleep` and waits for it: proc:run blocks on it, and a
proc:request is waited for with io:wait. The check finds the child among the
engine's own, signals the engine alone with SIGTERM, or with SIGKILL, which
no handler sees, and requires the child to be gone within five seconds. A
surviving child is killed by the check."""
import json
import os
import signal
import subprocess
import sys
import tempfile
import time

DIALECTS = ("he", "petta", "prime")


def children(pid):
    found = []
    try:
        tasks = os.listdir(f"/proc/{pid}/task")
    except OSError:
        return found
    for task in tasks:
        try:
            with open(f"/proc/{pid}/task/{task}/children") as handle:
                found += [int(child) for child in handle.read().split()]
        except OSError:
            pass
    return found


def alive(pid):
    try:
        with open(f"/proc/{pid}/stat") as handle:
            return handle.read().rsplit(")", 1)[1].split()[0] != "Z"
    except OSError:
        return False


def command_name(pid):
    try:
        with open(f"/proc/{pid}/comm") as handle:
            return handle.read().strip()
    except OSError:
        return ""


def trial(binary, dialect, entry, number, work):
    proc_lib = "(library proc)" if dialect == "petta" else "proc"
    io_lib = "(library io)" if dialect == "petta" else "io"
    profile = [] if dialect == "prime" else ["--profile", "extended"]
    log = json.dumps(os.path.join(work, f"{dialect}-{entry}.log"))
    call = ('(proc:run ("sleep" "300") "." inherit 0 0)' if entry == "proc:run" else
            f'(case (io:submit (proc:request ("sleep" "300") "." inherit 0 {log} {log})) '
            '(((io:pending $id) (io:wait $id 600000)) ($other $other)))')
    engine = subprocess.Popen([binary, "--lang", dialect, *profile,
                               "-e", f"!(import! &self {proc_lib})", "-e", f"!(import! &self {io_lib})",
                               "-e", "!" + call], cwd=work, stdout=subprocess.DEVNULL,
                              stderr=subprocess.DEVNULL, start_new_session=True)
    child = None
    deadline = time.monotonic() + 20
    while child is None and time.monotonic() < deadline and engine.poll() is None:
        child = next((pid for pid in children(engine.pid) if command_name(pid) == "sleep"), None)
        time.sleep(0.02)
    if child is None:
        engine.kill()
        engine.wait()
        return "the engine started no child"
    os.kill(engine.pid, number)
    engine.wait(timeout=30)
    deadline = time.monotonic() + 5
    while alive(child) and time.monotonic() < deadline:
        time.sleep(0.02)
    if alive(child):
        os.kill(child, signal.SIGKILL)
        return "the child outlived the engine"
    return None


def main():
    binary = os.path.abspath(sys.argv[1])
    failures, checked = [], 0
    with tempfile.TemporaryDirectory(prefix="proc-parent-death-") as work:
        for dialect in DIALECTS:
            for entry in ("proc:run", "proc:request"):
                for number in (signal.SIGTERM, signal.SIGKILL):
                    checked += 1
                    problem = trial(binary, dialect, entry, number, work)
                    if problem:
                        failures.append(f"{dialect} {entry} {signal.Signals(number).name}: {problem}")
    for failure in failures[:12]:
        print("MISMATCH " + failure)
    print(f"proc-parent-death: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
