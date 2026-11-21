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


def run_tmux_width_comparison(cetta_bin: Path, repo_root: Path) -> None:
    """Compare real tmux 3.6 cell count and 64-column wrap boundaries against
    CeTTa's terminal:cells for ZWJ family, heart+VS16, keycap, and baseline
    clusters."""
    socket_name = f"cetta-width-test-{os.getpid()}"
    samples = [
        ("ascii_a", "a", 1),
        ("cjk_snow", "雪", 2),
        ("combining_e_acute", "e\u0301", 1),
        ("zwj_family", "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466", 2),
        ("heart_vs16", "\u2764\uFE0F", 2),
        ("heart_vs15", "\u2764\uFE0E", 1),
        ("heart_bare", "\u2764", 1),
        ("keycap_1", "1\uFE0F\u20E3", 2),
        ("keycap_hash_novs", "#\u20E3", 1),
        ("flag_cz", "\U0001F1E8\U0001F1FF", 2),
    ]

    # Measure CeTTa's terminal:cells for every sample.
    exprs = " ".join(
        f'({name} (terminal:cells "{s}"))' for name, s, _ in samples
    )
    cetta_out = subprocess.check_output(
        [str(cetta_bin), "--quiet", "--lang", "petta", "--profile", "extended",
         "-e", f"!(import! &self (library host_io)) !(println! ({exprs}))"],
        cwd=str(repo_root), text=True, timeout=30
    )
    cetta_widths = {}
    for name, _, _ in samples:
        marker = f"({name} "
        idx = cetta_out.find(marker)
        assert idx >= 0, f"missing {name} in CeTTa output: {cetta_out!r}"
        end = cetta_out.find(")", idx + len(marker))
        cetta_widths[name] = int(cetta_out[idx + len(marker):end])

    def tm(*args: str) -> str:
        return subprocess.check_output(["tmux", "-L", socket_name, *args], text=True)

    try:
        subprocess.run(
            ["tmux", "-L", socket_name, "-f", "/dev/null",
             "new-session", "-d", "-x", "64", "-y", "24", "sh", "-c", "sleep 60"],
            cwd=str(repo_root), check=True, capture_output=True, text=True
        )
        time.sleep(0.25)
        pw, ph, pty = tm("display-message", "-p", "#{pane_width} #{pane_height} #{pane_tty}").strip().split()
        assert pw == "64", f"expected 64-col pane, got {pw}x{ph}"

        # 1. Exact single-cluster cell width parity with tmux.
        for name, glyph, expected in samples:
            with open(pty, "wb", buffering=0) as f:
                f.write(b"\x1b[2J\x1b[H" + glyph.encode("utf-8"))
            time.sleep(0.06)
            cx, cy = (int(v) for v in tm("display-message", "-p", "#{cursor_x} #{cursor_y}").strip().split())
            assert cy == 0, f"{name}: unexpected row wrap cy={cy}"
            assert cx == expected, f"{name}: tmux cursor_x={cx}, expected {expected}"
            assert cetta_widths[name] == cx, (
                f"{name}: terminal:cells={cetta_widths[name]} disagrees with tmux cursor_x={cx}"
            )

        # 2. Exact 64-column wrap boundary for the three 2-cell sequences:
        #    - prefix 61 + 2-cell glyph + 'Z' = 64 cells -> fits on row 0 (cursor_x=64, cursor_y=0)
        #    - prefix 62 + 2-cell glyph + 'Z' = 65 cells -> glyph fills cols 62..63, 'Z' wraps to (1, 1)
        #    - prefix 63 + ZWJ family + 'Z' -> entire 2-cell ZWJ cluster wraps cleanly to row 1 (3, 1)
        for name, glyph in (
            ("zwj_family", "\U0001F468\u200D\U0001F469\u200D\U0001F467\u200D\U0001F466"),
            ("heart_vs16", "\u2764\uFE0F"),
            ("keycap_1", "1\uFE0F\u20E3"),
        ):
            for prefix_len, want_xy, want_row1 in (
                (61, (64, 0), ""),
                (62, (1, 1), "Z"),
            ):
                with open(pty, "wb", buffering=0) as f:
                    f.write(b"\x1b[2J\x1b[H" + (b"A" * prefix_len) + glyph.encode("utf-8") + b"Z")
                time.sleep(0.06)
                cx, cy = (int(v) for v in tm("display-message", "-p", "#{cursor_x} #{cursor_y}").strip().split())
                rows = tm("capture-pane", "-p", "-S", "0", "-E", "1").splitlines()
                r1 = rows[1].rstrip(" ") if len(rows) > 1 else ""
                assert (cx, cy) == want_xy and r1 == want_row1, (
                    f"{name} N={prefix_len}: got end=({cx},{cy}) row1={r1!r}, want {want_xy} {want_row1!r}"
                )
            if name == "zwj_family":
                with open(pty, "wb", buffering=0) as f:
                    f.write(b"\x1b[2J\x1b[H" + (b"A" * 63) + glyph.encode("utf-8") + b"Z")
                time.sleep(0.06)
                cx, cy = (int(v) for v in tm("display-message", "-p", "#{cursor_x} #{cursor_y}").strip().split())
                rows = tm("capture-pane", "-p", "-S", "0", "-E", "1").splitlines()
                r1 = rows[1].rstrip(" ") if len(rows) > 1 else ""
                assert (cx, cy) == (3, 1) and r1 == glyph + "Z", (
                    f"zwj_family N=63: got end=({cx},{cy}) row1={r1!r}"
                )
        print("PASS tmux 64-col width & wrap parity for ZWJ family, heart+VS16, keycap, and baseline clusters")
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
    run_tmux_width_comparison(cetta_bin, repo_root)
    print("TMUX_TERMINAL_COMMIT_AND_CPR_OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
