#!/usr/bin/env python3
"""(inherit (("NAME" "value") ...)) as a child's environment, in HE, PeTTa and Prime.

The child of proc:run, of proc:request and of an owned job gets the caller's
environment with each NAME set: a variable the caller has is replaced in its
place (getenv, which takes the first entry, reads the new value), one it
lacks is added, and every other variable is inherited. A program named without a / is found on the PATH of
that environment. (inherit ()) is the caller's environment. A name given
twice, a name holding =, a pair that is not two texts and a list that is not
one are refused as argument errors, by all three entries."""
import json
import os
import subprocess
import sys
import tempfile

DIALECTS = ("he", "petta", "prime")
SHOW = '(printf %s "$E1_A|$E1_B|$E1_KEEP")'


def run(binary, dialect, line, work):
    proc_lib = "(library proc)" if dialect == "petta" else "proc"
    io_lib = "(library io)" if dialect == "petta" else "io"
    profile = [] if dialect == "prime" else ["--profile", "extended"]
    env = dict(os.environ, E1_KEEP="kept", E1_R="parent")
    env.pop("E1_A", None)
    env.pop("E1_B", None)
    proc = subprocess.run([binary, "--lang", dialect, *profile,
                           "-e", f"!(import! &self {proc_lib})", "-e", f"!(import! &self {io_lib})",
                           "-e", "!" + line], capture_output=True, text=True, env=env,
                          cwd=work, timeout=60)
    lines = proc.stdout.splitlines()[2:]
    text = lines[-1] if lines else proc.stderr.strip()[-200:]
    return text[1:-1] if text.startswith("[") and text.endswith("]") else text


def stdout_of(call):
    return f"(case {call} (((proc:exited 0 $out $err) $out) ($other $other)))"


def main():
    binary = os.path.abspath(sys.argv[1])
    overrides = '(inherit (("E1_A" "one") ("E1_B" "two words") ("E1_R" "child")))'
    shown = '"one|two words|kept"'
    failures, checked = [], 0
    with tempfile.TemporaryDirectory(prefix="proc-env-") as work:
        log = json.dumps(os.path.join(work, "request.log"))
        request = (f'(proc:request ("sh" "-c" {json.dumps(SHOW[1:-1])}) "." {overrides} 5000 {log} {log})')
        cases = [
            ("proc:run", stdout_of(f'(proc:run ("sh" "-c" {json.dumps(SHOW[1:-1])}) "." {overrides} 5000 0)'),
             shown),
            ("owned job", f'(case (proc:run ("sh" "-c" {json.dumps(SHOW[1:-1])}) ((env {overrides}))) '
             '(((proc:result $end $mode $out $err $capture) $out) ($other $other)))', shown),
            ("proc:request", f'(case (io:submit {request}) (((io:pending $id) (case (io:wait $id 5000) '
             '(((io:event $id (proc:finished $pid exited 0 $o $e)) done) ($w $w)))) ($s $s)))', "done"),
            ("proc:run replaces in place", '(case (proc:run ("printenv" "E1_R") "." ' + overrides + ' 5000 0) '
             '(((proc:exited 0 "child\\n" $err) replaced) ($other $other)))', "replaced"),
            ("owned job replaces in place", '(case (proc:run ("printenv" "E1_R") ((env ' + overrides + '))) '
             '(((proc:result $end $mode "child\\n" $err $capture) replaced) ($other $other)))', "replaced"),
            ("empty overrides", stdout_of('(proc:run ("sh" "-c" "printf %s $E1_R") "." (inherit ()) 5000 0)'),
             '"parent"'),
            ("PATH from the overrides", '(proc:run ("sh" "-c" "true") "." (inherit (("PATH" "/nonexistent"))) 5000 0)',
             '(proc:failed "program not found")'),
            ("PATH set", stdout_of('(proc:run ("/bin/sh" "-c" "printf %s $PATH") "." (inherit (("PATH" "/nonexistent"))) 5000 0)'),
             '"/nonexistent"'),
        ]
        refusals = {
            "a name given twice": '(inherit (("E1_A" "1") ("E1_A" "2")))',
            "a name holding =": '(inherit (("E1_A=B" "1")))',
            "a pair of one text": '(inherit (("E1_A")))',
            "a value that is not text": '(inherit (("E1_A" 5)))',
            "overrides that are not a list": '(inherit "E1_A")',
        }
        for what, env in refusals.items():
            cases.append((f"proc:run refuses {what}", f'(proc:run ("true") "." {env} 5000 0)', "inherit takes"))
        cases.append(("owned job refuses a name given twice",
                      f'(proc:run ("true") ((env {refusals["a name given twice"]})))', "inherit takes"))
        cases.append(("proc:request refuses a name given twice",
                      f'(io:submit (proc:request ("true") "." {refusals["a name given twice"]} 5000 {log} {log}))',
                      "inherit takes"))
        for dialect in DIALECTS:
            for what, line, want in cases:
                if os.path.exists(json.loads(log)):
                    os.unlink(json.loads(log))
                got = run(binary, dialect, line, work)
                ok = want in got if want == "inherit takes" else got == want
                if ok and what == "proc:request":
                    with open(json.loads(log)) as handle:
                        got = handle.read()
                    ok = got == shown[1:-1]
                checked += 1
                if not ok:
                    failures.append((dialect, what, got, want))
    for dialect, what, got, want in failures[:20]:
        print(f"MISMATCH {dialect} {what}\n  got    {got!r}\n  wanted {want!r}")
    print(f"proc-env: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
