#!/usr/bin/env python3
"""An idle Telegram channel service costs little CPU, however long its history.

The service runs as an agent's channel does: commands, an operator socket, a
long poll that the local Bot API answers every few seconds, and an agent that
keeps one WAIT open for its whole idle period. Its journal holds HISTORY rows
that no component reads, as delivered conversations leave behind, and TIMERS
finished timers in its outbox. Each poll publishes, so the journal moves while
the agent waits. Idle work that passes over every row on each step, or once
per finished timer, shows up here as CPU time. Test token; 127.0.0.1 only.
"""
import hashlib
import json
import os
import pathlib
import signal
import socket
import struct
import subprocess
import sys
import tempfile
import threading
import time

from test_telegram_transport import TOKEN, Peer, peer

BIN = str(pathlib.Path(sys.argv[1]).resolve())
ROOT = pathlib.Path(__file__).resolve().parents[1]
HISTORY = int(os.environ.get('CETTA_TELEGRAM_IDLE_HISTORY', '60000'))
TIMERS = int(os.environ.get('CETTA_TELEGRAM_IDLE_TIMERS', '128'))
WINDOW = float(os.environ.get('CETTA_TELEGRAM_IDLE_SECONDS', '8'))
LIMIT = float(os.environ.get('CETTA_TELEGRAM_IDLE_PERCENT', '3'))
POLL = float(os.environ.get('CETTA_TELEGRAM_IDLE_POLL_SECONDS', '3'))
WAIT_MS = int(os.environ.get('CETTA_TELEGRAM_IDLE_WAIT_MS', '10000'))
COMMANDS = '''
(tg-cmd:command "/help" help "list these commands")
(tg-cmd:command "/stop" stop "stop the agent's sends")
(tg-cmd:command "/start" start "resume the agent's sends")
(tg-cmd:agent "Ada")
'''


class LongPoll(Peer):
    """getUpdates holds for POLL seconds, at most its timeout, then answers empty."""
    def receipt(self, connection, method, path, body):
        name = path.rsplit('/', 1)[-1]
        if name == 'getUpdates':
            time.sleep(min(float(json.loads(body).get('timeout', 0)), POLL, 25))
            return 200, [], b'{"ok":true,"result":[]}'
        if name == 'getMe':
            return 200, [], b'{"ok":true,"result":{"id":1,"is_bot":true,"first_name":"Ada","username":"ada_bot"}}'
        return 200, [], b'{"ok":true,"result":true}'


class Symbol(str):
    pass


def value(atom):
    """CDV1: a tag, little-endian lengths and integers, expressions as tuples."""
    def encode(a):
        if isinstance(a, tuple):
            return b'E' + struct.pack('<I', len(a)) + b''.join(encode(x) for x in a)
        if isinstance(a, int):
            return b'I' + struct.pack('<q', a)
        data = a.encode()
        return (b'S' if isinstance(a, Symbol) else b'T') + struct.pack('<I', len(data)) + data
    return b'CDV1' + encode(atom)


def history(path, count, timers):
    """A checkpoint-shaped CDR1 journal: COUNT rows in a space nothing reads,
    and TIMERS one-shot timer intents in the outbox, each with its outcome."""
    base, row = struct.Struct('>4sB32sQQ'), struct.Struct('>BIIIQQ')

    def frame(payload):
        return b'CSL1' + struct.pack('>I', len(payload)) + hashlib.sha256(payload).hexdigest().encode() + payload
    epoch = os.urandom(16).hex().encode()
    rows = [(b'test.history', b'row/%08d' % position, b'x' * 64) for position in range(count)]
    for n in range(timers):
        key = b'timer-%04d' % n
        intent = (Symbol('host:intent'), 1, 'timer.after', '1',
                  (Symbol('timer:at'), 1, 1000, 0, Symbol('FireOnce'), 0, Symbol('wake')), ())
        outcome = (Symbol('host:timer-outcome'), 1, '%s/1/%d' % (epoch.decode(), n), Symbol('fired'), 1, 1000)
        rows += [(b'host.outbox', key, value(intent)), (b'host.outcomes', key, value(outcome))]
    parts = [frame(base.pack(b'CDR1', 0, epoch, 1, len(rows)))]
    for position, (name, key, data) in enumerate(rows):
        parts.append(frame(base.pack(b'CDR1', 2, epoch, 1, 1) + row.pack(1, len(name), len(key), len(data), 1, position)
                           + name + key + data))
    path.write_bytes(b''.join(parts))


def cpu_seconds(pid):
    fields = pathlib.Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')


def waiting_agent(path, stop, replies):
    """Keep one WAIT open, WAIT_MS at a time, with the token of the last one."""
    token = ''
    while not stop.is_set():
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET) as s:
                s.settimeout(WAIT_MS / 1000 + 5)
                s.connect(str(path))
                name = token.encode()
                s.sendall(b'CWP1' + bytes([5, len(name)]) + name + (str(WAIT_MS).encode() if token else b''))
                reply = s.recv(65606)
            # A service that is stopping closes the WAIT without a reply.
            if len(reply) > 5 and reply[4] in (64, 67):
                token = reply[6:6 + reply[5]].decode()
                replies.append(reply[4])
        except OSError:
            time.sleep(.2)


if not sys.platform.startswith('linux'):
    print('telegram idle cpu: skipped (reads /proc)')
    sys.exit(0)
with tempfile.TemporaryDirectory(prefix='cetta-telegram-idle-') as temp:
    root = pathlib.Path(temp)
    token = root / 'token'; token.write_text(TOKEN); token.chmod(0o600)
    commands = root / 'commands.metta'; commands.write_text(COMMANDS)
    state = root / 'state'; state.mkdir(mode=0o700)
    history(state / 'journal.db', HISTORY, TIMERS)
    with peer('http/1.1', None, None, LongPoll) as (server, origin):
        sockets = []
        for name in ('agent.sock', 'operator.sock'):
            listener = socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET)
            listener.bind(str(root / name)); listener.listen(16); (root / name).chmod(0o600)
            sockets.append(listener)
        proc = subprocess.Popen([BIN, '--run', '--root', str(ROOT), '--state-dir', str(state), '--worker', 'agent',
                                 '--program', 'channel', '--listener-fd', str(sockets[0].fileno()),
                                 '--operator-fd', str(sockets[1].fileno()), '--credential-file', str(token),
                                 '--commands', str(commands), '--command-deadline-ms', '3000',
                                 '--chat', '42', '--operator', '7', '--mock-origin', origin],
                                pass_fds=[s.fileno() for s in sockets], stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, text=True)
        stop, replies = threading.Event(), []
        try:
            ready = proc.stdout.readline()
            assert 'ready' in ready, (ready, proc.poll(), proc.stderr.read() if proc.poll() is not None else '')
            agent = threading.Thread(target=waiting_agent, args=(root / 'agent.sock', stop, replies), daemon=True)
            agent.start()
            # The first reply carries a token; the WAIT with it is held open.
            deadline = time.monotonic() + 30
            while len(replies) < 1 and time.monotonic() < deadline:
                time.sleep(.05)
            assert len(replies) >= 1, 'the agent never received a token'
            time.sleep(POLL + 1)
            before, started = cpu_seconds(proc.pid), time.monotonic()
            time.sleep(WINDOW)
            used, elapsed = cpu_seconds(proc.pid) - before, time.monotonic() - started
            assert proc.poll() is None, proc.communicate()
        finally:
            stop.set()
            if proc.poll() is None:
                proc.send_signal(signal.SIGTERM)
            try:
                out, err = proc.communicate(timeout=20)
            except subprocess.TimeoutExpired:
                proc.kill()
                out, err = proc.communicate()
            for listener in sockets:
                listener.close()
        assert TOKEN.split(':')[1] not in out + err
        percent = 100 * used / elapsed
        print('(TelegramIdleCpuV2 history %d timers %d poll %.1f wait-ms %d seconds %.1f cpu-percent %.2f limit %.1f)'
              % (HISTORY, TIMERS, POLL, WAIT_MS, elapsed, percent, LIMIT))
        assert percent < LIMIT, 'an idle channel service with %d rows of history and %d finished timers used %.2f%% CPU' % (
            HISTORY, TIMERS, percent)
