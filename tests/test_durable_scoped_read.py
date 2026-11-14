#!/usr/bin/env python3
"""Scoped durable administration in fresh, private local databases.

durable:attach opens and recovers a store but answers its coordinates and
row count, not every row; durable:read-key answers the row of one key (a1, not
a10) and durable:read-prefix the rows of the keys with a prefix, in one space.
Like the other administrative directives they run only under --durable-admin.
"""
import pathlib
import re
import subprocess
import sys
import tempfile


def run(binary, language, directory, source, admin=True, normalize=True):
    program = directory / "probe.metta"
    program.write_text('!(import! &self durable)\n' + source)
    arguments = [binary, "--lang", language] + (["--durable-admin"] if admin else [])
    result = subprocess.run(arguments + [str(program)], capture_output=True, text=True, timeout=60)
    assert result.returncode == 0, (language, result.returncode, result.stderr, result.stdout)
    lines = result.stdout.strip().splitlines()
    if language == "he":
        assert all(line.startswith("[") and line.endswith("]") for line in lines), lines
        lines = [line[1:-1] for line in lines]
    assert lines.pop(0) in ("true", "()"), lines
    return [re.sub(r'"[0-9a-f]{32}"', '"EPOCH"', line) for line in lines] if normalize else lines


def main():
    binary = str(pathlib.Path(sys.argv[1]).resolve())
    for language in ("petta", "he"):
        with tempfile.TemporaryDirectory(prefix="cetta-durable-scoped-") as temporary:
            directory = pathlib.Path(temporary)
            store = str(directory / "journal.db")
            opening = f'!(durable:open "{store}")\n'
            seed = run(binary, language, directory, opening + '!(durable:close)\n', normalize=False)
            epoch = re.search(r'"([0-9a-f]{32})"', seed[0]).group(1)
            rows = ' '.join(f'(durable:insert "history" "row/{n:05d}" (old {n}))' for n in range(2000))
            source = opening + f'!(durable:commit "{epoch}" 0 ({rows}))\n'
            source += f'''!(durable:commit "{epoch}" 1 ((durable:insert "inbox" "a1" (message 1))
                (durable:insert "inbox" "a2" (message 2)) (durable:insert "inbox" "b1" (message 3))
                (durable:insert "inbox" "a10" (message 4)) (durable:insert "state" "worker" (waiting 0))))
!(durable:close)
'''
            assert run(binary, language, directory, source) == [
                '(durable:snapshot "EPOCH" 0 ())', '(durable:committed "EPOCH" 1)',
                '(durable:committed "EPOCH" 2)', '(durable:closed)']
            attach = f'!(durable:attach "{store}")\n'
            reads = ('!(durable:read-key "inbox" "a1")\n!(durable:read-key "inbox" "zz")\n'
                     '!(durable:read-prefix "inbox" "a")\n!(durable:read-prefix "state" "")\n'
                     '!(durable:read-key "history" "row/01999")\n!(durable:close)\n')
            lines = run(binary, language, directory, attach + reads)
            assert lines == [
                '(durable:attached "EPOCH" 2 2005)',
                '(durable:snapshot "EPOCH" 2 ((durable:record "inbox" "a1" (message 1))))',
                '(durable:snapshot "EPOCH" 2 ())',
                '(durable:snapshot "EPOCH" 2 ((durable:record "inbox" "a1" (message 1)) '
                '(durable:record "inbox" "a2" (message 2)) (durable:record "inbox" "a10" (message 4))))',
                '(durable:snapshot "EPOCH" 2 ((durable:record "state" "worker" (waiting 0))))',
                '(durable:snapshot "EPOCH" 2 ((durable:record "history" "row/01999" (old 1999))))',
                '(durable:closed)',
            ], (language, lines)
            # A read before attaching has no store. While one store is
            # attached, attaching another is busy and the first stays attached.
            assert run(binary, language, directory, '!(durable:read-key "inbox" "a1")\n') == [
                '(durable:failure closed)']
            other = directory / "other.db"
            lines = run(binary, language, directory, attach + f'!(durable:attach "{other}")\n'
                        '!(durable:read-key "inbox" "a1")\n!(durable:close)\n')
            assert lines == ['(durable:attached "EPOCH" 2 2005)', '(durable:failure busy)',
                             '(durable:snapshot "EPOCH" 2 ((durable:record "inbox" "a1" (message 1))))',
                             '(durable:closed)'], (language, lines)
            assert not other.exists(), "a busy attach created a store"
            # Without --durable-admin the directives are refused like the others.
            denied = '(durable:failure commit-boundary-required)'
            assert run(binary, language, directory, attach + '!(durable:read-key "inbox" "a1")\n'
                       '!(durable:read-prefix "inbox" "a")\n', admin=False) == [denied] * 3, language
    print("durable scoped reads: attach answers coordinates, key and prefix reads answer their rows, "
          "refused without --durable-admin (petta, he)")


if __name__ == "__main__":
    main()
