#!/usr/bin/env python3
"""An idle Telegram channel service costs little CPU, however long its history.

The service runs as an agent's channel does: commands, an operator socket, a
long poll that the local Bot API holds for its timeout, and an agent that keeps
a two-second WAIT open. Its journal holds HISTORY rows that no component reads,
as delivered conversations leave behind. Idle work that passes over every row
on each step shows up here as CPU time. Test token; 127.0.0.1 only.
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
WINDOW = float(os.environ.get('CETTA_TELEGRAM_IDLE_SECONDS', '8'))
LIMIT = float(os.environ.get('CETTA_TELEGRAM_IDLE_PERCENT', '3'))
COMMANDS = '''
(tg-cmd:command "/help" help "list these commands")
(tg-cmd:command "/stop" stop "stop the agent's sends")
(tg-cmd:command "/start" start "resume the agent's sends")
(tg-cmd:agent "Ada")
'''


class LongPoll(Peer):
    """getUpdates holds for its timeout, as Telegram does when nothing arrives."""
    def receipt(self, connection, method, path, body):
        name = path.rsplit('/', 1)[-1]
        if name == 'getUpdates':
            time.sleep(min(float(json.loads(body).get('timeout', 0)), 25))
            return 200, [], b'{"ok":true,"result":[]}'
        if name == 'getMe':
            return 200, [], b'{"ok":true,"result":{"id":1,"is_bot":true,"first_name":"Ada","username":"ada_bot"}}'
        return 200, [], b'{"ok":true,"result":true}'


def history(path, count):
    """A checkpoint-shaped CDR1 journal of COUNT rows in a space nothing reads."""
    base, row = struct.Struct('>4sB32sQQ'), struct.Struct('>BIIIQQ')

    def frame(payload):
        return b'CSL1' + struct.pack('>I', len(payload)) + hashlib.sha256(payload).hexdigest().encode() + payload
    epoch = os.urandom(16).hex().encode()
    parts = [frame(base.pack(b'CDR1', 0, epoch, 1, count))]
    name, value = b'test.history', b'x' * 64
    for position in range(count):
        key = b'row/%08d' % position
        parts.append(frame(base.pack(b'CDR1', 2, epoch, 1, 1) + row.pack(1, len(name), len(key), len(value), 1, position)
                           + name + key + value))
    path.write_bytes(b''.join(parts))


def cpu_seconds(pid):
    fields = pathlib.Path(f'/proc/{pid}/stat').read_text().rsplit(')', 1)[1].split()
    return (int(fields[11]) + int(fields[12])) / os.sysconf('SC_CLK_TCK')


def waiting_agent(path, stop, replies):
    """Keep one WAIT open, two seconds at a time, with the token of the last one."""
    token = ''
    while not stop.is_set():
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_SEQPACKET) as s:
                s.settimeout(5)
                s.connect(str(path))
                name = token.encode()
                s.sendall(b'CWP1' + bytes([5, len(name)]) + name + (b'2000' if token else b''))
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
    history(state / 'journal.db', HISTORY)
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
            deadline = time.monotonic() + 30
            while len(replies) < 2 and time.monotonic() < deadline:
                time.sleep(.05)
            assert len(replies) >= 2, 'the agent never held a WAIT'
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
        print('(TelegramIdleCpuV1 history %d seconds %.1f cpu-percent %.2f limit %.1f)' % (HISTORY, elapsed, percent, LIMIT))
        assert percent < LIMIT, 'an idle channel service with %d rows of history used %.2f%% CPU' % (HISTORY, percent)
