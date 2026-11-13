#!/usr/bin/env python3
"""system:wall-time-ns and system:notify in HE, PeTTa and Prime.

system:wall-time-ns must be an integer within a second of time.time_ns().
system:notify sends its text as one datagram to $NOTIFY_SOCKET, the systemd
notify protocol: the text must arrive byte for byte at a path socket and at
an abstract one (@name). Unset or empty, the variable gives False and nothing
is sent. A missing socket, a path that is not a socket and an address too
long for a socket give (system:os-error errno message) with Python's errno
and strerror. A manager that never reads must not stall the caller: sending
past its queue gives EAGAIN, promptly. A text that is empty or not text is
refused as an argument error."""
import errno
import os
import socket
import subprocess
import sys
import tempfile
import time

DIALECTS = ("he", "petta", "prime")


def command(binary, dialect, lines):
    library = "(library system)" if dialect == "petta" else "system"
    profile = [] if dialect == "prime" else ["--profile", "extended"]
    args = [binary, "--lang", dialect, *profile, "-e", f"!(import! &self {library})"]
    for line in lines:
        args += ["-e", "!" + line]
    return args


def answers(binary, dialect, lines, environment, timeout=60):
    """One answer per line, written as PeTTa writes it."""
    env = {key: value for key, value in os.environ.items() if key != "NOTIFY_SOCKET"}
    env.update(environment)
    started = time.monotonic()
    proc = subprocess.run(command(binary, dialect, lines), capture_output=True, text=True,
                          env=env, timeout=timeout)
    elapsed = time.monotonic() - started
    if proc.returncode != 0:
        raise AssertionError(f"{dialect}: exited {proc.returncode}: {proc.stderr[-400:]}")
    out = []
    for text in proc.stdout.splitlines()[1:]:
        if text.startswith("[") and text.endswith("]"):
            text = text[1:-1]
        out.append({"True": "true", "False": "false"}.get(text, text))
    return out, elapsed


def os_error(code):
    return f'(system:os-error {code} "{os.strerror(code)}")'


def receiver(address):
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_DGRAM)
    sock.bind(address)
    sock.settimeout(5)
    return sock


def check(binary, dialect, work, failures):
    def expect(what, lines, environment, wanted):
        got, _ = answers(binary, dialect, lines, environment)
        if got != wanted:
            failures.append((dialect, what, got, wanted))

    before = time.time_ns()
    got, _ = answers(binary, dialect, ["(system:wall-time-ns)"], {})
    after = time.time_ns()
    if len(got) != 1 or not got[0].lstrip("-").isdigit() or \
            not before - 10 ** 9 <= int(got[0]) <= after + 10 ** 9:
        failures.append((dialect, "wall-time-ns", got, (before, after)))

    expect("unset", ['(system:notify "READY=1")'], {}, ["false"])
    expect("empty", ['(system:notify "READY=1")'], {"NOTIFY_SOCKET": ""}, ["false"])

    path = os.path.join(work, f"{dialect}.sock")
    text = "STATUS=Gödel ready\nREADY=1"
    literal = '"' + text.replace("\n", "\\n") + '"'
    with receiver(path) as sock:
        expect("path socket", [f"(system:notify {literal})"],
               {"NOTIFY_SOCKET": path}, ["true"])
        try:
            data = sock.recv(4096)
        except socket.timeout:
            data = None
        if data != text.encode():
            failures.append((dialect, "path datagram", data, text.encode()))
    os.unlink(path)

    name = f"cetta-notify-{os.getpid()}-{dialect}"
    with receiver("\0" + name) as sock:
        expect("abstract socket", ['(system:notify "WATCHDOG=1")'],
               {"NOTIFY_SOCKET": "@" + name}, ["true"])
        try:
            data = sock.recv(4096)
        except socket.timeout:
            data = None
        if data != b"WATCHDOG=1":
            failures.append((dialect, "abstract datagram", data, b"WATCHDOG=1"))

    missing = os.path.join(work, "missing", "notify.sock")
    expect("missing socket", ['(system:notify "READY=1")'], {"NOTIFY_SOCKET": missing},
           [os_error(errno.ENOENT)])
    plain = os.path.join(work, "plain-file")
    open(plain, "w").close()
    expect("not a socket", ['(system:notify "READY=1")'], {"NOTIFY_SOCKET": plain},
           [os_error(errno.ECONNREFUSED)])
    expect("address too long", ['(system:notify "READY=1")'],
           {"NOTIFY_SOCKET": "/" + "x" * 200}, [os_error(errno.ENAMETOOLONG)])

    path = os.path.join(work, f"{dialect}-full.sock")
    count = 4000
    with receiver(path):
        got, elapsed = answers(binary, dialect, ['(system:notify "WATCHDOG=1")'] * count,
                               {"NOTIFY_SOCKET": path})
    os.unlink(path)
    sent = got.count("true")
    full = got.count(os_error(errno.EAGAIN))
    if len(got) != count or sent == 0 or full == 0 or sent + full != count or \
            got[:sent] != ["true"] * sent:
        failures.append((dialect, "full queue", f"{sent} sent, {full} EAGAIN of {len(got)}",
                         "sends, then EAGAIN"))
    if elapsed > 30:
        failures.append((dialect, "full queue waits", elapsed, "under 30 s"))

    for what, argument in (("empty text", '""'), ("number", "5")):
        got, _ = answers(binary, dialect, [f"(system:notify {argument})"], {})
        if len(got) != 1 or "expected a nonempty notification text" not in got[0]:
            failures.append((dialect, what, got, "an argument error"))
    return 12


def main():
    binary = os.path.abspath(sys.argv[1])
    failures, checked = [], 0
    with tempfile.TemporaryDirectory(prefix="system-host-") as work:
        for dialect in DIALECTS:
            try:
                checked += check(binary, dialect, work, failures)
            except (AssertionError, subprocess.TimeoutExpired) as error:
                failures.append((dialect, "run", str(error)[:300], "an answer"))
    for dialect, what, got, wanted in failures[:20]:
        print(f"MISMATCH {dialect} {what}\n  got    {got!r}\n  wanted {wanted!r}")
    print(f"system-host: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
