#!/usr/bin/env python3
"""Store services under injected write faults (ENOSPC and EIO).

A served store whose write certainly published nothing answers an explicit
error and keeps serving. A write whose publication is uncertain, in a request
or in a maintenance step, is answered as uncertain and then ends the service
(exit 75); the store reopened by its restart answers the retried request
exactly once. A parent-owned worker that keeps such an owner ends the same
way. A torn segment tail and a torn space journal reopen to their last
publication.

Each case has its own store and process; the check starts an ended process
again, as systemd's Restart= would.
"""
import argparse
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile
import time
import traceback

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / 'tools'))
from check_native_kb_service import Client, E, S  # noqa: E402
import space_service_client  # noqa: E402
from space_service_client import decode, encode  # noqa: E402

UNCERTAIN_EXIT = 75
IO_ERROR = (S('Error'), S('db:transaction'), (S('StoreRefused'), S('io')))


class Service:
    def __init__(self, command, environment, path, ready):
        self.command, self.environment, self.path, self.ready = command, environment, path, ready
        self.process = None
        self.logs = []

    def start(self):
        if self.path.exists():
            self.path.unlink()
        self.process = subprocess.Popen(self.command, env=self.environment,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        deadline = time.monotonic() + 30
        while time.monotonic() < deadline:
            if self.process.poll() is not None:
                raise AssertionError(('service ended at start', self.process.returncode, self.process.communicate()))
            try:
                self.ready(self.path)
                return
            except OSError:
                time.sleep(.01)
        raise AssertionError('service did not start')

    def running(self):
        return self.process is not None and self.process.poll() is None

    def ended(self, timeout):
        """The exit status if the service ends within TIMEOUT seconds, else None."""
        try:
            self.process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            return None
        self.logs.append(self.process.communicate(timeout=10))
        code, self.process = self.process.returncode, None
        return code

    def stop(self):
        if not self.process:
            return None
        if self.process.poll() is None:
            self.process.terminate()
        self.logs.append(self.process.communicate(timeout=20))
        code, self.process = self.process.returncode, None
        return code

    def remove(self):
        for path in (self.path, self.path.with_name(self.path.name + '.lock')):
            if path.exists():
                path.unlink()


class Fault:
    def __init__(self, directory):
        self.arm, self.marker = directory / 'armed', directory / 'injected'

    def environment(self, library):
        return dict(LD_PRELOAD=str(library), CETTA_STORE_FAULT_ARM=str(self.arm),
                    CETTA_STORE_FAULT_MARKER=str(self.marker))

    def set(self, mode):
        if self.marker.exists():
            self.marker.unlink()
        self.arm.write_text(mode + '\n')

    def clear(self):
        if self.arm.exists():
            self.arm.unlink()

    def injected(self):
        return self.marker.read_text().splitlines() if self.marker.exists() else []

    def wait(self, mark, timeout=10):
        deadline = time.monotonic() + timeout
        while mark not in self.injected() and time.monotonic() < deadline:
            time.sleep(.01)
        assert mark in self.injected(), (mark, self.injected())


def connect(path):
    Client(path).socket.close()


def outcome(client, route, request, key):
    answer = client.route(route, E(route + 'V1', request, key))
    assert answer[0] == S('FaultOutcomeV1'), answer
    return answer[1]


def put(client, request, key):
    return outcome(client, 'FaultPut', request, key)


def committed(request, key):
    return (S('db:committed'), request, ((S('stored'), key),))


def replayed(request, key):
    return (S('db:replayed'), request, ((S('stored'), key),))


def rows(client):
    answer = client.route('FaultRows')
    assert answer[0] == S('FaultRowsV1'), answer
    return sorted(answer[1])


class Store:
    """A ledger-shaped value service over one store, with the fault library."""
    def __init__(self, args, root, library, name, number):
        self.directory = root / name
        self.directory.mkdir(mode=0o700)
        self.fault = Fault(self.directory)
        path = Path(tempfile.gettempdir()) / ('cetta-fault-%d-%d.sock' % (number, os.getpid()))
        command = [str(args.worker.resolve()), '--serve', '--lang', 'petta',
                   str(HERE / 'store_fault_server.metta'), 'fault-server:configuration']
        environment = dict(os.environ, CETTA_DB_SOURCE=str(self.directory / 'store'), CETTA_DB_SOCKET=str(path),
                           **self.fault.environment(library))
        self.service = Service(command, environment, path, connect)

    def client(self):
        if not self.service.running():
            self.service.start()
        return Client(self.service.path)

    def close(self):
        if self.service.running():
            self.service.stop()
        self.service.remove()


def certain(store, mode, mark):
    """A failure that publishes nothing is an explicit error; the service keeps
    serving and the same request commits once the fault is gone."""
    client = store.client()
    assert put(client, 'r1', 'k1') == committed('r1', 'k1')
    store.fault.set(mode)
    failed = put(client, 'r2', 'k2')
    store.fault.clear()
    assert mark in store.fault.injected(), store.fault.injected()
    assert failed == IO_ERROR, failed
    assert store.service.running(), 'service ended after a certain failure'
    again = put(client, 'r2', 'k2')
    assert again == committed('r2', 'k2'), ('the store stayed unwritable', again)
    assert rows(client) == ['k1', 'k2']
    client.socket.close()
    assert store.service.stop() == 0


def torn(store):
    """A torn segment tail past the last publication reopens to that publication."""
    client = store.client()
    assert put(client, 'r1', 'k1') == committed('r1', 'k1')
    store.fault.set('torn')
    failed = put(client, 'r2', 'k2')
    store.fault.clear()
    assert 'torn segment write' in store.fault.injected(), store.fault.injected()
    assert failed == IO_ERROR, failed
    client.socket.close()
    assert store.service.stop() == 0
    client = store.client()
    assert rows(client) == ['k1']
    assert put(client, 'r2', 'k2') == committed('r2', 'k2')
    client.socket.close()
    assert store.service.stop() == 0
    client = store.client()
    assert rows(client) == ['k1', 'k2']
    client.socket.close()
    assert store.service.stop() == 0


def uncertain(store, mode, mark, route, landed):
    """An uncertain publication is answered as uncertain and ends the service;
    its restart reopens the store, and the retried request is replayed if it
    landed or applied once if it did not."""
    client = store.client()
    assert put(client, 'r1', 'k1') == committed('r1', 'k1')
    store.fault.set(mode)
    try:
        reply = client.route(route, E(route + 'V1', 'r2', 'k2'))
    except (AssertionError, OSError) as lost:
        store.fault.clear()
        raise AssertionError(('the request had no reply', lost))
    expected = (S('FaultOutcomeV1'), (S('db:uncertain'), 'r2', S('data'), S('put'))) \
        if route == 'FaultPut' else (S('FaultLaterV1'), 'r2')
    if reply != expected:
        store.fault.clear()
        raise AssertionError(('reply', reply, 'expected', expected))
    store.fault.wait(mark)
    code = store.service.ended(10)
    store.fault.clear()
    client.socket.close()
    if code is None:
        follow = Client(store.service.path)
        later = put(follow, 'r3', 'k3')
        follow.socket.close()
        raise AssertionError(('the service kept serving after an uncertain publication',
                              'its reply', reply, 'a later write', later))
    assert code == UNCERTAIN_EXIT, (code, store.service.logs[-1])
    assert b'uncertain' in store.service.logs[-1][1], store.service.logs[-1]
    client = store.client()
    retried = put(client, 'r2', 'k2')
    assert retried == (replayed if landed else committed)('r2', 'k2'), retried
    assert put(client, 'r3', 'k3') == committed('r3', 'k3')
    assert rows(client) == ['k1', 'k2', 'k3']
    client.socket.close()
    assert store.service.stop() == 0


def closing(store):
    """Once a publication is uncertain the service evaluates nothing more: of
    two writes that arrive together, one is answered and the other never runs;
    the restarted service replays the first and applies the second once."""
    client = store.client()
    assert put(client, 'r1', 'k1') == committed('r1', 'k1')
    client.socket.close()
    gate = store.directory / 'gate'
    os.mkfifo(gate)
    slow = Client(store.service.path)
    waiting = slow.send(E('CallV1', S('FaultWait'), E('FaultWaitV1', str(gate))))
    time.sleep(.2)
    writers = [(Client(store.service.path), request, key) for request, key in (('r2', 'k2'), ('r3', 'k3'))]
    store.fault.set('dirsync')
    sent = [(client, client.send(E('CallV1', S('FaultPut'), E('FaultPutV1', request, key))), request, key)
            for client, request, key in writers]
    time.sleep(.2)
    descriptor = os.open(gate, os.O_WRONLY | os.O_NONBLOCK)
    os.write(descriptor, b'go')
    os.close(descriptor)
    assert slow.receive(waiting) == (S('FaultWaitedV1'), 'go')
    answered = []
    for client, identifier, request, key in sent:
        try:
            answered.append((request, key, client.receive(identifier)))
        except (AssertionError, OSError):
            pass
    store.fault.wait('directory fsync EIO')
    code = store.service.ended(10)
    store.fault.clear()
    for client, _, _, _ in sent:
        client.socket.close()
    slow.socket.close()
    if code is None:
        raise AssertionError(('the service kept serving after an uncertain publication', answered))
    assert code == UNCERTAIN_EXIT, code
    assert len(answered) == 1, ('requests evaluated after an uncertain publication', answered)
    request, key, reply = answered[0]
    assert reply == (S('FaultOutcomeV1'), (S('db:uncertain'), request, S('data'), S('put'))), reply
    client = store.client()
    for other, other_key in (('r2', 'k2'), ('r3', 'k3')):
        expected = replayed if other == request else committed
        assert put(client, other, other_key) == expected(other, other_key), other
    assert rows(client) == ['k1', 'k2', 'k3']
    client.socket.close()
    assert store.service.stop() == 0


class ParentWorker:
    """cetta-value-worker without --serve, spoken to over its pipes."""
    def __init__(self, args, directory, environment):
        self.command = [str(args.worker.resolve()), '--lang', 'petta',
                        str(HERE / 'store_fault_server.metta'), 'fault-worker:run']
        self.environment, self.store = environment, str(directory / 'store')
        self.process = None

    def start(self):
        self.process = subprocess.Popen(self.command, env=self.environment, stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        assert self.call(E('FaultOpenV1', self.store)) == S('FaultOpenedV1')

    def call(self, value):
        identifier = os.urandom(8).hex()
        data = encode(E('work', identifier, value))
        self.process.stdin.write(b'CSP1' + len(data).to_bytes(4, 'big') + data)
        self.process.stdin.flush()
        header = self.process.stdout.read(8)
        assert len(header) == 8 and header[:4] == b'CSP1', ('worker reply', header)
        reply = decode(self.process.stdout.read(int.from_bytes(header[4:], 'big')))
        assert reply[:3] == (S('reply'), identifier, S('ok')), reply
        return reply[3]

    def put(self, request, key):
        answer = self.call(E('FaultPutV1', request, key))
        assert answer[0] == S('FaultOutcomeV1'), answer
        return answer[1]

    def ended(self, timeout):
        try:
            self.process.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            return None
        self.process.stdin.close()
        self.stderr = self.process.stderr.read()
        code, self.process = self.process.returncode, None
        return code

    def stop(self):
        if self.process:
            self.process.stdin.close()
            self.process.wait(timeout=20)
            code, self.process = self.process.returncode, None
            return code
        return None


def parent_worker(args, root, library):
    """A parent-owned worker answers an uncertain publication as uncertain,
    then ends; restarted, it replays the request whose rename landed."""
    directory = root / 'worker'
    directory.mkdir(mode=0o700)
    fault = Fault(directory)
    worker = ParentWorker(args, directory, dict(os.environ, **fault.environment(library)))
    try:
        worker.start()
        assert worker.put('r1', 'k1') == committed('r1', 'k1')
        fault.set('dirsync')
        reply = worker.put('r2', 'k2')
        fault.wait('directory fsync EIO')
        assert reply == (S('db:uncertain'), 'r2', S('data'), S('put')), reply
        code = worker.ended(10)
        fault.clear()
        if code is None:
            later = worker.put('r3', 'k3')
            raise AssertionError(('the worker kept serving after an uncertain publication', later))
        assert code == UNCERTAIN_EXIT and b'uncertain' in worker.stderr, (code, worker.stderr)
        worker.start()
        assert worker.put('r2', 'k2') == replayed('r2', 'k2')
        assert worker.put('r3', 'k3') == committed('r3', 'k3')
        assert worker.stop() == 0
    finally:
        fault.clear()
        if worker.process:
            worker.process.kill()
            worker.process.wait()


def space_journal(args, root, library):
    """The space service ends on a failed journal append; its restart discards
    the torn tail and keeps every acknowledged row."""
    directory = root / 'space'
    directory.mkdir(mode=0o700)
    (directory / 'data').mkdir(mode=0o700)
    fault = Fault(directory)
    path = Path(tempfile.gettempdir()) / ('cetta-fault-space-%d.sock' % os.getpid())
    command = [str(args.space_service.resolve()), '--socket', str(path), '--data', str(directory / 'data')]

    def ready(socket_path):
        with space_service_client.Client(str(socket_path), timeout=5) as client:
            client.hello()
    service = Service(command, dict(os.environ, **fault.environment(library)), path, ready)
    try:
        service.start()
        with space_service_client.Client(str(path), timeout=10) as client:
            space = client.open('faults')
            space.add(E('row', 'kept'))
            fault.set('journal')
            try:
                space.add(E('row', 'torn'))
                raise AssertionError('a failed journal append was acknowledged')
            except (space_service_client.Uncertain, space_service_client.ServiceError, OSError):
                pass
        assert 'torn journal write' in fault.injected(), fault.injected()
        code = service.ended(10)
        fault.clear()
        assert code is not None and code != 0, ('the space service kept serving after a failed append', code)
        service.start()
        with space_service_client.Client(str(path), timeout=10) as client:
            space = client.open('faults')
            found = space.match(E('row', space_service_client.Var(0)), space_service_client.Var(0))
            assert found == ['kept'], found
            space.add(E('row', 'after'))
        assert service.stop() == 0
        assert b'discarding incomplete journal tail' in service.logs[-1][1], service.logs[-1]
    finally:
        if service.running():
            service.stop()
        service.remove()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('worker', type=Path)
    parser.add_argument('space_service', type=Path)
    args = parser.parse_args()
    if not sys.platform.startswith('linux'):
        print('(StoreWriteFaultsV1Summary skipped Linux-loader-injection)')
        return
    failed = 0
    with tempfile.TemporaryDirectory(prefix='cetta-store-faults-') as temporary:
        root = Path(temporary)
        library = root / 'store_write_fault.so'
        subprocess.run(shlex.split(os.environ.get('CC', 'cc')) + ['-shared', '-fPIC', '-O2',
                       str(HERE / 'store_write_fault.c'), '-ldl', '-o', str(library)], check=True)
        cases = [
            ('segment_enospc_is_an_error', lambda s: certain(s, 'segment', 'segment write ENOSPC')),
            ('rename_enospc_is_an_error', lambda s: certain(s, 'rename', 'rename ENOSPC')),
            ('torn_segment_tail_reopens', torn),
            ('uncertain_request_ends_service_and_replays',
             lambda s: uncertain(s, 'dirsync', 'directory fsync EIO', 'FaultPut', True)),
            ('uncertain_rename_ends_service_and_applies_once',
             lambda s: uncertain(s, 'rename-eio', 'rename EIO', 'FaultPut', False)),
            ('uncertain_maintenance_ends_service_and_replays',
             lambda s: uncertain(s, 'dirsync', 'directory fsync EIO', 'FaultLater', True)),
            ('closing_service_evaluates_nothing_more', closing),
        ]
        for number, (name, case) in enumerate(cases):
            store = Store(args, root, library, name, number)
            try:
                case(store)
                print('PASS', name)
            except Exception:
                failed += 1
                print('FAIL', name)
                traceback.print_exc(file=sys.stdout)
            finally:
                store.close()
        for name, case in (('uncertain_worker_ends_and_replays', parent_worker),
                           ('space_journal_failure_ends_service_and_reopens', space_journal)):
            try:
                case(args, root, library)
                print('PASS', name)
            except Exception:
                failed += 1
                print('FAIL', name)
                traceback.print_exc(file=sys.stdout)
    print('(StoreWriteFaultsV1Summary %d %d)' % (len(cases) + 2 - failed, failed))
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main()
