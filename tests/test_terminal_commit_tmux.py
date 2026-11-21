#!/usr/bin/env python3
"""Real tmux PTY verification for Commit 1 terminal protocol primitives:
1. terminal:commit copy-safety via `tmux capture-pane -p -J -S -` at 40, 80,
   and 200 columns: even when the previous live region painted under autowrap-off
   (?7l), committed logical commands, heredocs, and OSC 8 paths copy back
   byte-for-byte intact with zero stale live-region copies in scrollback.
2. Live PTY CPR round-trip inside tmux: terminal:cpr-request (ESC[6n) ->
   buffer:input-event -> (HostInput "cursor-position" "7;13") ->
   terminal:cpr-parse -> (HostCursor 7 13).
"""
import os
import subprocess
import sys
import tempfile
import time
from pathlib import Path


def wait_for_file(path: Path, timeout: float = 10.0) -> str:
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if path.exists():
            txt = path.read_text(encoding="utf-8")
            if txt.strip():
                return txt
        time.sleep(0.05)
    raise AssertionError(f"timed out waiting for {path}")


def run_tmux_commit_check(cetta_bin: Path, repo_root: Path, cols: int) -> None:
    socket_name = f"cetta-commit-test-{os.getpid()}-{cols}"
    long_cmd = (
        "$ python3 -c 'print(\"exact-copy-marker-alpha-0123456789-"
        "beta-abcdefghijklmnopqrstuvwxyz-gamma-9876543210\")' --flag=value"
    )
    heredoc_open = "cat <<'EOF'"
    heredoc_body = "  indent_two && echo \"hello world\" | awk '{print $1}' --extra-long-argument-segment-for-wrapping-at-40-cols"
    heredoc_close = "EOF"
    long_path = "/home/agent/.local/state/runtime-x/artifacts/2026-11-21/very-long-session-directory-name/command-output-0001.log"

    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        done_file = td_path / "done.txt"
        script = td_path / "commit_demo.metta"
        # First draw a 3-row live region with autowrap OFF (?7l) and cursor on row 2
        # (2 rows below top of live region), then call terminal:commit 2 (...)!
        script.write_text(f'''
!(import! &self (library host_io))
!(import! &self (library system))
!(import! &self (library str))
!(import! &self (library fs))
!(let* (($tty (terminal:open "/dev/tty"))
        ($esc (str:byte-slice (terminal:cpr-request) 0 1))
        ;; Paint stale 3-row live region with autowrap OFF (?7l)
        ($stale (str:join "" ($esc "[?7lSTALE_LIVE_ROW_0\\r\\nSTALE_LIVE_ROW_1\\r\\nSTALE_LIVE_ROW_2")))
        ($_w1 (host:write $tty $stale 0))
        ($linked-path (terminal:hyperlink "file://{long_path}" "{long_path}"))
        ($lines ("{long_cmd.replace(chr(34), chr(92) + chr(34))}"
                 "{heredoc_open}"
                 "{heredoc_body.replace(chr(34), chr(92) + chr(34))}"
                 "{heredoc_close}"
                 $linked-path))
        ($redraw "FINAL_LIVE_STATUS\\r\\nFINAL_LIVE_PROMPT> ")
        ($frame (terminal:commit 2 $lines $redraw))
        ($_w2 (host:write $tty $frame 0))
        ($_c (host:close $tty))
        ($_d (fs:write "{done_file}" "DONE\\n")))
   True)
''', encoding="utf-8")

        cmd = (
            f"{cetta_bin} --quiet --lang petta --profile extended "
            f"--import-mode ancestor-walk {script}; sleep 30"
        )
        try:
            subprocess.run(
                ["tmux", "-L", socket_name, "-f", "/dev/null",
                 "new-session", "-d", "-x", str(cols), "-y", "24", cmd],
                cwd=str(repo_root), check=True, capture_output=True, text=True
            )
            wait_for_file(done_file, timeout=15.0)
            time.sleep(0.15)
            cap = subprocess.run(
                ["tmux", "-L", socket_name, "capture-pane", "-p", "-J", "-S", "-"],
                check=True, capture_output=True, text=True
            ).stdout
            lines = [ln.rstrip(" ") for ln in cap.splitlines()]
            joined = "\n".join(lines)
            assert "STALE_LIVE_ROW_0" not in joined, f"cols={cols}: stale live row leaked into scrollback:\n{joined}"
            assert "STALE_LIVE_ROW_1" not in joined, f"cols={cols}: stale live row 1 leaked:\n{joined}"
            assert "STALE_LIVE_ROW_2" not in joined, f"cols={cols}: stale live row 2 leaked:\n{joined}"
            for expected in (long_cmd, heredoc_open, heredoc_body, heredoc_close, long_path):
                assert expected in lines, (
                    f"cols={cols}: exact line missing from capture-pane -J!\n"
                    f"EXPECTED: {expected!r}\nCAPTURED LINES:\n" + "\n".join(repr(x) for x in lines)
                )
            assert "FINAL_LIVE_STATUS" in lines, f"cols={cols}: final live status missing"
            assert any("FINAL_LIVE_PROMPT>" in ln for ln in lines), f"cols={cols}: final live prompt missing"
            print(f"PASS tmux capture-pane -J copy-exact at cols={cols}")
        finally:
            subprocess.run(["tmux", "-L", socket_name, "kill-server"],
                           capture_output=True, text=True)


def run_tmux_cpr_check(cetta_bin: Path, repo_root: Path) -> None:
    socket_name = f"cetta-cpr-test-{os.getpid()}"
    with tempfile.TemporaryDirectory() as td:
        td_path = Path(td)
        out_file = td_path / "cpr_out.txt"
        script = td_path / "cpr_probe.metta"
        script.write_text(f'''
!(import! &self (library host_io))
!(import! &self (library system))
!(import! &self (library str))
!(import! &self (library fs))

(= (read-cpr $tty $buf $tries)
   (if (<= $tries 0) (HostFailure "cpr-timeout" 0 "timeout")
     (let $ev (buffer:input-event $buf "wait")
       (case $ev
         (((HostInput "cursor-position" $payload) (terminal:cpr-parse $payload))
          (HostPending
            (let $_w (host:wait (($tty read)) 200)
              (case (host:read $tty 64)
                (((HostBytes $chunk) (let $_a (buffer:append $buf $chunk) (read-cpr $tty $buf (- $tries 1))))
                 ($other (read-cpr $tty $buf (- $tries 1)))))))
          ($other (read-cpr $tty $buf (- $tries 1))))))))

!(let* (($tty (terminal:open "/dev/tty"))
        ($_raw (terminal:raw $tty "on"))
        ($esc (str:byte-slice (terminal:cpr-request) 0 1))
        ($move-and-ask (str:join "" ($esc "[7;13H" (terminal:cpr-request))))
        ($_w (host:write $tty $move-and-ask 0))
        ($buf (buffer:new 256 bytes))
        ($res (read-cpr $tty $buf 20))
        ($_off (terminal:raw $tty "off"))
        ($_c1 (host:close $buf))
        ($_c2 (host:close $tty))
        ($_out (fs:write "{out_file}" (repr $res))))
   True)
''', encoding="utf-8")

        cmd = (
            f"{cetta_bin} --quiet --lang petta --profile extended "
            f"--import-mode ancestor-walk {script}; sleep 5"
        )
        try:
            subprocess.run(
                ["tmux", "-L", socket_name, "-f", "/dev/null",
                 "new-session", "-d", "-x", "80", "-y", "24", cmd],
                cwd=str(repo_root), check=True, capture_output=True, text=True
            )
            got = wait_for_file(out_file, timeout=15.0).strip()
            assert got == "(HostCursor 7 13)", f"CPR mismatch: expected (HostCursor 7 13), got {got!r}"
            print(f"PASS tmux live PTY CPR round-trip: {got}")
        finally:
            subprocess.run(["tmux", "-L", socket_name, "kill-server"],
                           capture_output=True, text=True)


def main() -> int:
    repo_root = Path(__file__).resolve().parents[1]
    cetta_bin = (Path(sys.argv[1]) if len(sys.argv) > 1 else repo_root / "cetta").resolve()
    assert cetta_bin.exists(), f"missing cetta binary: {cetta_bin}"
    for cols in (40, 80, 200):
        run_tmux_commit_check(cetta_bin, repo_root, cols)
    run_tmux_cpr_check(cetta_bin, repo_root)
    print("TMUX_TERMINAL_COMMIT_AND_CPR_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
