#!/usr/bin/env python3
"""(fs:changed DIR NAMES [modified]) through io:submit and io:wait, in HE, PeTTa and Prime.

The engine submits a watch, prints a marker and waits; the check then
changes the directory. (except NAME ...) ignores those names: a write to an
ignored file leaves the watch waiting, a write to another completes it.
With modified, a write to a file its writer still holds open completes the
watch with IN_MODIFY in the mask; without it, the same write waits for the
close. A list of names still selects them, and an unknown fourth element is
refused."""
import os
import select
import subprocess
import sys
import tempfile
import time

DIALECTS = ("he", "petta", "prime")
IN_MODIFY = 0x2


def watch(binary, dialect, directory, names, extra, wait_ms, act):
    library = "(library io)" if dialect == "petta" else "io"
    profile = [] if dialect == "prime" else ["--profile", "extended"]
    request = f'(fs:changed "{directory}" {names}{" " + extra if extra else ""})'
    program = (f'(case (io:submit {request}) (((io:pending $w) (let $ready (println! e1-watching) '
               f'(io:wait $w {wait_ms}))) ($other $other)))')
    engine = subprocess.Popen([binary, "--lang", dialect, *profile, "-e", f"!(import! &self {library})",
                               "-e", "!" + program], stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                              text=True)
    lines, started = [], time.monotonic()
    while time.monotonic() - started < 20:
        ready, _, _ = select.select([engine.stdout], [], [], 0.5)
        if ready:
            line = engine.stdout.readline()
            if not line:
                break
            lines.append(line.strip())
            if "e1-watching" in line:
                act()
                break
    out, _ = engine.communicate(timeout=30)
    lines += [line.strip() for line in out.splitlines() if line.strip()]
    answer = lines[-1] if lines else ""
    return answer[1:-1] if answer.startswith("[") and answer.endswith("]") else answer


def mask_of(answer):
    try:
        return int(answer.rstrip(")").split()[-1])
    except (ValueError, IndexError):
        return None


def main():
    if not sys.platform.startswith("linux"):
        print("SKIP: fs:changed watches are Linux inotify subscriptions")
        return 0
    binary = os.path.abspath(sys.argv[1])
    failures, checked = [], 0
    for dialect in DIALECTS:
        with tempfile.TemporaryDirectory(prefix="fs-changed-") as directory:
            data = os.path.join(directory, "data")
            open(data, "w").close()

            def held_write():
                handle = open(data, "a")
                handle.write("x")
                handle.flush()
                time.sleep(2.5)
                handle.close()

            def ignored_then_data():
                with open(os.path.join(directory, "pump.lock"), "w") as handle:
                    handle.write("ignored")
                time.sleep(0.4)
                held_write()

            cases = [
                ("except, modified: an ignored name waits, a held write completes",
                 '(except "pump.lock" "sequence")', "modified", 5000, ignored_then_data,
                 lambda a: '"data"' in a and (mask_of(a) or 0) & IN_MODIFY),
                ("without modified, a held write waits for its close",
                 "()", "", 1200, held_write, lambda a: "fs:changed" not in a),
                ("selected names: another name waits, a selected one completes",
                 '("chosen")', "", 5000,
                 lambda: (open(os.path.join(directory, "other"), "w").close(), time.sleep(0.4),
                          open(os.path.join(directory, "chosen"), "w").close()),
                 lambda a: '"chosen"' in a),
                ("an unknown fourth element is refused", "()", "always", 1000, lambda: None,
                 lambda a: "expected (fs:changed directory [names [modified]])" in a),
            ]
            for what, names, extra, wait_ms, act, accept in cases:
                checked += 1
                answer = watch(binary, dialect, directory, names, extra, wait_ms, act)
                if not accept(answer):
                    failures.append((dialect, what, answer))
    for dialect, what, answer in failures[:12]:
        print(f"MISMATCH {dialect} {what}\n  got {answer!r}")
    print(f"fs-changed: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
