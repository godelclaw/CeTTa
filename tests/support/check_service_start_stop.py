#!/usr/bin/env python3
"""A service stopped while it is still starting ends cleanly.

The space service is stopped while it replays its journal, and a value
service while its configuration is evaluated. Each must take the stop
request, finish what it was doing, exit 0 without binding its socket, and
start normally afterwards with its data intact. Before, both installed their
stop handler only after binding: the stop killed them by signal.
"""
import argparse
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'tools'))
import space_service_client as space  # noqa: E402
from space_service_client import E, S  # noqa: E402

ROWS, BATCH = int(os.environ.get('CETTA_START_STOP_ROWS', '120000')), 2000


def holds(pid, target):
    """Whether process PID has TARGET open."""
    try:
        return any(os.readlink(entry) == str(target) for entry in Path(f'/proc/{pid}/fd').iterdir())
    except OSError:
        return False


def stopped_while(process, starting, socket_path, label):
    deadline = time.monotonic() + 30
    while not starting() and process.poll() is None and time.monotonic() < deadline:
        time.sleep(.001)
    assert process.poll() is None and starting(), (label, 'start-up was not observed', process.poll())
    assert not socket_path.exists(), (label, 'start-up already bound its socket; nothing to check')
    process.send_signal(signal.SIGTERM)
    return process


def finish(process, label):
    out, err = process.communicate(timeout=120)
    assert process.returncode == 0, (label, 'a stop during start-up ended it with', process.returncode, err[-400:])
    assert b'stopped during start-up' in err, (label, err[-400:])
    return out, err


def space_service(binary, root):
    data, path = root / 'data', Path(tempfile.gettempdir()) / ('cetta-start-stop-%d.sock' % os.getpid())
    data.mkdir(mode=0o700)
    command = [str(binary), '--socket', str(path), '--data', str(data),
               '--max-facts', str(ROWS * 2), '--max-live-bytes', str(1 << 30),
               '--max-journal-bytes', str(1 << 30)]

    def start():
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        deadline = time.monotonic() + 120
        while time.monotonic() < deadline:
            assert process.poll() is None, process.communicate()
            try:
                with space.Client(str(path), timeout=10) as client:
                    client.hello()
                return process
            except OSError:
                time.sleep(.01)
        raise AssertionError('space service did not start')

    def stop(process):
        process.send_signal(signal.SIGTERM)
        out, err = process.communicate(timeout=60)
        assert process.returncode == 0, (process.returncode, err[-400:])

    try:
        process = start()
        with space.Client(str(path), timeout=60) as client:
            rows = client.open('start-stop')
            for first in range(0, ROWS, BATCH):
                rows.batch(*[E('add', E('row', n)) for n in range(first, first + BATCH)])
        stop(process)
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stopped_while(process, lambda: holds(process.pid, data / 'journal.csl'), path, 'space service')
        finish(process, 'space service')
        assert not path.exists(), 'a space service stopped during start-up left its socket'
        process = start()
        with space.Client(str(path), timeout=60) as client:
            assert client.open('start-stop').match_count(E('row', space.Var(0))) == ROWS
        stop(process)
    finally:
        if path.exists():
            path.unlink()


def value_service(worker, root):
    gate, path = root / 'gate', Path(tempfile.gettempdir()) / ('cetta-start-gate-%d.sock' % os.getpid())
    os.mkfifo(gate)
    environment = dict(os.environ, CETTA_START_GATE=str(gate), CETTA_START_SOCKET=str(path))
    command = [str(worker), '--serve', '--lang', 'petta', str(HERE / 'service_start_gate.metta'),
               'start-gate:configuration']
    try:
        writer = os.open(gate, os.O_RDWR)
        process = subprocess.Popen(command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        stopped_while(process, lambda: holds(process.pid, gate), path, 'value service')
        time.sleep(.1)
        os.write(writer, b'opened')
        os.close(writer)
        finish(process, 'value service')
        assert not path.exists(), 'a value service stopped during start-up left its socket'
        writer = os.open(gate, os.O_RDWR)
        process = subprocess.Popen(command, env=environment, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        deadline = time.monotonic() + 30
        while not holds(process.pid, gate) and process.poll() is None and time.monotonic() < deadline:
            time.sleep(.001)
        os.write(writer, b'opened')
        os.close(writer)
        deadline = time.monotonic() + 30
        while not path.exists() and process.poll() is None and time.monotonic() < deadline:
            time.sleep(.01)
        assert path.exists(), ('value service did not start', process.poll())
        process.send_signal(signal.SIGTERM)
        process.communicate(timeout=30)
        assert process.returncode == 0, process.returncode
    finally:
        for leftover in (path, path.with_name(path.name + '.lock')):
            if leftover.exists():
                leftover.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('space_service', type=Path)
    parser.add_argument('worker', type=Path)
    args = parser.parse_args()
    if not sys.platform.startswith('linux'):
        print('(ServiceStartStopV1 skipped reads-proc)')
        return
    with tempfile.TemporaryDirectory(prefix='cetta-start-stop-') as temporary:
        root = Path(temporary)
        (root / 'space').mkdir()
        space_service(args.space_service.resolve(), root / 'space')
        print('PASS space service stopped during replay')
        (root / 'value').mkdir()
        value_service(args.worker.resolve(), root / 'value')
        print('PASS value service stopped during configuration')
    print('(ServiceStartStopV1Summary 2)')


if __name__ == '__main__':
    main()
