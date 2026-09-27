#!/usr/bin/env python3
"""Exercise the real MeTTa boundary in fresh, private local databases."""
import pathlib
import re
import subprocess
import sys
import tempfile


def run(binary, language, directory, source):
    program = directory / "probe.metta"
    program.write_text('!(import! &self durable)\n' + source)
    result = subprocess.run([binary, "--lang", language, str(program)],
                            capture_output=True, text=True, timeout=30)
    assert result.returncode == 0, (language, result.returncode, result.stderr, result.stdout)
    assert not result.stderr.strip(), result.stderr
    lines = result.stdout.strip().splitlines()
    if language == "he":
        assert all(line.startswith("[") and line.endswith("]") for line in lines), lines
        lines = [line[1:-1] for line in lines]
    assert lines.pop(0) in ("true", "()"), lines
    return [re.sub(r'"[0-9a-f]{32}"', '"EPOCH"', line) for line in lines]


def commit(operations, revision="$revision"):
    return '''!(case (durable:read "*")
      (((durable:snapshot $epoch $revision $records)
        (durable:commit $epoch ''' + revision + " (" + operations + ")))))\n"


def main():
    binary = str(pathlib.Path(sys.argv[1]).resolve())
    for language in ("petta", "he"):
        with tempfile.TemporaryDirectory(prefix="cetta-durable-library-") as temporary:
            directory = pathlib.Path(temporary)
            opening = '!(durable:open "' + str(directory / "coordination.db") + '")\n'
            source = opening
            source += commit('''(durable:insert "inbox" "one" (message "hello"))
              (durable:insert "state" "worker" (waiting 0))''')
            source += commit('''(durable:remove "inbox" "one")
              (durable:replace "state" "worker" (continuation 1))
              (durable:insert "outbox" "send:1" (send "test" "reply"))
              (durable:insert "data" "inert" (println! "DO_NOT_EXECUTE"))''')
            source += commit('(durable:insert "outbox" "stale" ignored)', "0")
            source += commit('''(durable:replace "state" "worker" wrong)
              (durable:remove "inbox" "missing")''')
            source += '!(durable:read "state")\n!(durable:checkpoint)\n!(durable:close)\n'
            assert run(binary, language, directory, source) == [
                '(durable:snapshot "EPOCH" 0 ())',
                '(durable:committed "EPOCH" 1)', '(durable:committed "EPOCH" 2)',
                '(durable:failure conflict)', '(durable:failure precondition)',
                '(durable:snapshot "EPOCH" 2 ((durable:record "state" "worker" (continuation 1))))',
                '(durable:checkpointed)', '(durable:closed)',
            ]
            # A new process recovers data without executing the saved expression.
            lines = run(binary, language, directory,
                        opening + '!(durable:read "data")\n!(durable:close)\n')
            assert len(lines) == 3, lines
            assert lines[0] == ('(durable:snapshot "EPOCH" 2 ('
                '(durable:record "state" "worker" (continuation 1)) '
                '(durable:record "outbox" "send:1" (send "test" "reply")) '
                '(durable:record "data" "inert" (println! "DO_NOT_EXECUTE"))))'), lines
            assert lines[1] == ('(durable:snapshot "EPOCH" 2 ('
                '(durable:record "data" "inert" (println! "DO_NOT_EXECUTE"))))'), lines
            assert lines[2] == '(durable:closed)', lines
    print("durable library: PeTTa and HE, atomic input/state/outbox, stale reads, rollback, inert data, process recovery passed")


if __name__ == "__main__":
    main()
