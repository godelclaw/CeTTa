#!/usr/bin/env python3
"""HTTP bodies through files, in HE, PeTTa and Prime, against a local peer.

(http:save PATH) writes a 2xx body to a new file beside PATH that takes PATH
only when the transfer completes: a body holding NUL bytes arrives byte for
byte, an empty one as an empty file, a redirect's final response is the one
saved, and the answer carries the response's header fields.  A 404 answers
as an ordinary response and leaves PATH as it was; a transfer cut short, a
body past max-bytes and a body or header that reflects a credential leave no
file at all, and no temporary file stays behind.

(http:multipart PART ...) sends fields (text, empty, an integer) and files
holding any bytes (named and typed, or libcurl's defaults); the peer parses
the multipart/form-data body and finds every byte.  The Telegram shapes run end
to end: getFile, the file downloaded with http:save, then sent back with
sendDocument and sendPhoto, the peer receiving the same bytes.

Malformed requests are refused at submission, before any I/O."""
import hashlib
import http.server
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import threading
import urllib.parse

DIALECTS = ("he", "petta", "prime")
TOKEN = "123456:secret-token"
CREDENTIAL = "fixture-credential-7"
BINARY = bytes((i * 131 + (i >> 8) * 7) % 256 for i in range(300_000))  # holds NULs
DOCUMENT = bytes(range(256)) * 37 + b"\x00\x00tail\r\n--\r\n"


def parse_multipart(body, content_type):
    """RFC 7578 parts, read exactly: (headers, data) per part."""
    match = re.search(r'boundary=("?)([^";]+)\1', content_type)
    delimiter = b"--" + match.group(2).encode()
    parts = []
    sections = body.split(b"\r\n" + delimiter)
    first = sections[0]
    assert first.startswith(delimiter), first[:40]
    sections[0] = first[len(delimiter):]
    for section in sections:
        if section.startswith(b"--"):
            break
        assert section.startswith(b"\r\n"), section[:40]
        head, _, data = section[2:].partition(b"\r\n\r\n")
        headers = {}
        for line in head.split(b"\r\n"):
            name, _, value = line.decode("latin-1").partition(":")
            headers[name.strip().lower()] = value.strip()
        disposition = headers.get("content-disposition", "")
        name = re.search(r'\bname="([^"]*)"', disposition)
        filename = re.search(r'\bfilename="([^"]*)"', disposition)
        parts.append({"name": name.group(1) if name else None,
                      "filename": filename.group(1) if filename else None,
                      "type": headers.get("content-type"), "data": data})
    return parts


class Peer(http.server.BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def reply(self, status, body=b"", headers=()):
        self.send_response(status)
        for name, value in headers:
            self.send_header(name, value)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        path = urllib.parse.urlparse(self.path).path
        if path == "/bytes":
            self.reply(200, BINARY, [("Content-Type", "application/octet-stream"),
                                     ("X-Probe", "one")])
        elif path == "/empty":
            self.reply(204 if "204" in self.path else 200)
        elif path == "/redirect":
            self.reply(302, b"moved", [("Location", "/bytes")])
        elif path == "/missing":
            self.reply(404, b"not here", [("Content-Type", "text/plain")])
        elif path == "/cut":
            self.send_response(200)
            self.send_header("Content-Length", "100000")
            self.end_headers()
            self.wfile.write(BINARY[:1000])
            self.wfile.flush()
            self.close_connection = True
        elif path == "/big":
            self.reply(200, BINARY[:5000])
        elif path == "/v1/echo-body":
            self.reply(200, b"\x00reflected " + self.headers.get("Authorization", "").encode())
        elif path == "/v1/echo-header":
            self.reply(200, b"ok", [("X-Echo", self.headers.get("Authorization", ""))])
        elif path == "/v1/plain":
            self.server.authorized.append(self.headers.get("Authorization"))
            self.reply(200, BINARY[:777])
        elif path == f"/bot{TOKEN}/getFile":
            query = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)
            file_path = f"documents/file_{query['file_id'][0]}.bin"
            self.reply(200, json.dumps({"ok": True, "result": {
                "file_id": query["file_id"][0], "file_path": file_path}}).encode(),
                [("Content-Type", "application/json")])
        elif path.startswith(f"/file/bot{TOKEN}/documents/"):
            self.reply(200, DOCUMENT, [("Content-Type", "application/octet-stream")])
        else:
            self.reply(404, b"unknown")

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)
        content_type = self.headers.get("Content-Type", "")
        record = {"path": urllib.parse.urlparse(self.path).path, "content_type": content_type,
                  "parts": parse_multipart(body, content_type)
                  if content_type.startswith("multipart/form-data") else None}
        self.server.received.append(record)
        if record["path"].startswith(f"/bot{TOKEN}/send"):
            self.reply(200, json.dumps({"ok": True, "result": {"message_id": 42}}).encode(),
                       [("Content-Type", "application/json")])
        else:
            self.reply(200, b"ok")


def run(binary, dialect, work, statements, env, catch=False):
    library = "(library io)" if dialect == "petta" else "io"
    lines = [f"!(import! &self {library})"]
    for statement in statements:
        if catch and dialect == "petta" and statement.startswith("(io:submit"):
            statement = f"(catch {statement})"
        lines.append(f"!{statement}")
    source = Path(work) / "probe.metta"
    source.write_text("\n".join(lines) + "\n")
    proc = subprocess.run([binary, "--lang", dialect, str(source)], cwd=work, env=env,
                          capture_output=True, text=True, timeout=60)
    out = []
    for line in proc.stdout.splitlines()[1:]:
        if dialect != "petta" and line.startswith("[") and line.endswith("]"):
            line = line[1:-1]
        event = re.match(r"\(io:event \d+ (.*)\)$", line)
        out.append(event.group(1) if event else line)
    return out, proc


def leftovers(directory, name):
    return [entry for entry in os.listdir(directory) if entry.startswith("." + name + ".")]


def main():
    binary = os.path.abspath(sys.argv[1])
    probe = subprocess.run([binary, "--lang", "he", "-e", "!(import! &self io)",
                            "-e", "!(io:capabilities)"], capture_output=True, text=True, timeout=60)
    if "http" not in probe.stdout.replace("(", " ").replace(")", " ").split():
        print("SKIP: io-http-files needs the native HTTP provider")
        return 0
    peer = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Peer)
    peer.received, peer.authorized = [], []
    threading.Thread(target=peer.serve_forever, daemon=True).start()
    base = f"http://127.0.0.1:{peer.server_port}"
    env = {**os.environ, "CETTA_IO_AUTH_FIXTURE_URL_PREFIX": base + "/v1/",
           "CETTA_IO_AUTH_FIXTURE_HEADER": "Authorization",
           "CETTA_IO_AUTH_FIXTURE_ENV": "IO_FIXTURE_CREDENTIAL",
           "CETTA_IO_AUTH_FIXTURE_PREFIX": "Bearer ", "IO_FIXTURE_CREDENTIAL": CREDENTIAL}
    failures, checked = [], 0

    def check(dialect, name, ok, detail):
        nonlocal checked
        checked += 1
        if not ok:
            failures.append((dialect, name, detail))

    def get(url, target, extra="", follow="False", max_bytes=1000000, headers="()"):
        return (f'(io:submit (http:request "GET" "{url}" {headers} "" 10000 {max_bytes} '
                f'{follow} {extra}(http:save "{target}")))')

    try:
        for dialect in DIALECTS:
            with tempfile.TemporaryDirectory(prefix="io-http-files-") as work:
                downloads = Path(work) / "downloads"
                downloads.mkdir()
                fresh = lambda name: str(downloads / name)

                # A 2xx body with NUL bytes, byte for byte, with its headers.
                out, proc = run(binary, dialect, work, [get(base + "/bytes", fresh("a.bin")),
                                                        "(io:wait 10000)"], env)
                saved = re.match(r'\(http:saved 200 \((.*)\) "([^"]*)" (\d+)\)$', out[1]) \
                    if len(out) > 1 else None
                check(dialect, "binary saved", saved and saved.group(2) == fresh("a.bin") and
                      int(saved.group(3)) == len(BINARY) and
                      Path(fresh("a.bin")).read_bytes() == BINARY, (out, proc.stderr))
                fields = dict(re.findall(r'\(http:header "([^"]*)" "([^"]*)"\)',
                                         saved.group(1))) if saved else {}
                check(dialect, "response headers", fields.get("X-Probe") == "one" and
                      fields.get("Content-Type") == "application/octet-stream" and
                      fields.get("Content-Length") == str(len(BINARY)), fields)
                check(dialect, "no temporary file", not leftovers(downloads, "a.bin"),
                      os.listdir(downloads))

                # An existing file is replaced; an empty body is an empty file.
                Path(fresh("b.bin")).write_bytes(b"old")
                out, _ = run(binary, dialect, work, [get(base + "/empty", fresh("b.bin")),
                                                     "(io:wait 10000)"], env)
                check(dialect, "empty body saved", len(out) > 1 and
                      out[1].startswith("(http:saved 200 (") and out[1].endswith(f'"{fresh("b.bin")}" 0)') and
                      Path(fresh("b.bin")).read_bytes() == b"", out)

                # A followed redirect saves the final response, its headers.
                out, _ = run(binary, dialect, work, [get(base + "/redirect", fresh("c.bin"),
                                                         follow="True"), "(io:wait 10000)"], env)
                check(dialect, "redirect saves final body", len(out) > 1 and
                      out[1].startswith("(http:saved 200 (") and "Location" not in out[1] and
                      Path(fresh("c.bin")).read_bytes() == BINARY, out)

                # Another status answers as without the option; PATH stays.
                Path(fresh("d.bin")).write_bytes(b"kept")
                out, _ = run(binary, dialect, work, [get(base + "/missing", fresh("d.bin")),
                                                     "(io:wait 10000)"], env)
                check(dialect, "404 not saved", out[1:2] == ['(http:response 404 "not here")'] and
                      Path(fresh("d.bin")).read_bytes() == b"kept" and
                      not leftovers(downloads, "d.bin"), out)
                out, _ = run(binary, dialect, work, [get(base + "/redirect", fresh("e.bin")),
                                                     "(io:wait 10000)"], env)
                check(dialect, "unfollowed redirect not saved",
                      out[1:2] == ['(http:response 302 "moved")'] and
                      not os.path.exists(fresh("e.bin")), out)

                # A cut transfer, a body past max-bytes: no file, no temporary.
                out, _ = run(binary, dialect, work, [get(base + "/cut", fresh("f.bin")),
                                                     "(io:wait 10000)"], env)
                check(dialect, "cut transfer leaves nothing", len(out) > 1 and
                      "(http:error transport 18 " in out[1] and
                      not os.path.exists(fresh("f.bin")) and not leftovers(downloads, "f.bin"), out)
                out, _ = run(binary, dialect, work, [get(base + "/big", fresh("g.bin"), max_bytes=1000),
                                                     "(io:wait 10000)"], env)
                check(dialect, "too large leaves nothing", len(out) > 1 and
                      "(http:error response-too-large 1000)" in out[1] and
                      not os.path.exists(fresh("g.bin")) and not leftovers(downloads, "g.bin"), out)

                # A body or header reflecting the credential never lands.
                for tail, name in (("echo-body", "h.bin"), ("echo-header", "i.bin")):
                    out, proc = run(binary, dialect, work, [get(base + "/v1/" + tail, fresh(name),
                        headers='((http:credential "FIXTURE"))'), "(io:wait 10000)"], env)
                    check(dialect, f"credential in {tail} refused", len(out) > 1 and
                          "(http:error credential-in-response)" in out[1] and
                          CREDENTIAL not in proc.stdout + proc.stderr and
                          not os.path.exists(fresh(name)) and not leftovers(downloads, name), out)
                out, _ = run(binary, dialect, work, [get(base + "/v1/plain", fresh("j.bin"),
                    headers='((http:credential "FIXTURE"))'), "(io:wait 10000)"], env)
                check(dialect, "credentialed download saved", len(out) > 1 and
                      out[1].startswith("(http:saved 200 (") and
                      Path(fresh("j.bin")).read_bytes() == BINARY[:777] and
                      peer.authorized[-1:] == ["Bearer " + CREDENTIAL], out)

                # A relative path is the working directory's.
                out, _ = run(binary, dialect, work, [get(base + "/bytes", "downloads/k.bin"),
                                                     "(io:wait 10000)"], env)
                check(dialect, "relative path", len(out) > 1 and
                      out[1].endswith(f'"{fresh("k.bin")}" {len(BINARY)})') and
                      Path(fresh("k.bin")).read_bytes() == BINARY, out)

                # Multipart: fields and files, read exactly by the peer.
                upload = Path(work) / "upload.bin"
                upload.write_bytes(DOCUMENT)
                notes = Path(work) / "notes.txt"
                notes.write_bytes(b"plain notes\n")
                before = len(peer.received)
                out, proc = run(binary, dialect, work, [
                    f'(io:submit (http:request "POST" "{base}/upload" () '
                    f'(http:multipart (http:field "caption" "a caption") (http:field "chat_id" 123456789) '
                    f'(http:field "blank" "") '
                    f'(http:file "document" "{upload}" "report.pdf" "application/vnd.cetta-check") '
                    f'(http:file "notes" "{notes}")) 10000 100000))',
                    "(io:wait 10000)"], env)
                record = peer.received[before] if len(peer.received) > before else {}
                parts = record.get("parts") or []
                expected = [("caption", None, None, b"a caption"),
                            ("chat_id", None, None, b"123456789"),
                            ("blank", None, None, b""),
                            ("document", "report.pdf", "application/vnd.cetta-check", DOCUMENT),
                            ("notes", "notes.txt", "text/plain", b"plain notes\n")]
                got = [(p["name"], p["filename"], p["type"], p["data"]) for p in parts]
                check(dialect, "multipart round trip", out[1:2] == ['(http:response 200 "ok")'] and
                      got == expected, (out, [(n, f, t, len(d)) for n, f, t, d in got]))

                # The Telegram shapes, end to end.
                before = len(peer.received)
                out, proc = run(binary, dialect, work, [
                    f'(io:submit (http:request "GET" "{base}/bot{TOKEN}/getFile?file_id=7" () "" 10000 100000))',
                    "(io:wait 10000)",
                    get(f"{base}/file/bot{TOKEN}/documents/file_7.bin", fresh("7-file_7.bin")),
                    "(io:wait 10000)",
                    f'(io:submit (http:request "POST" "{base}/bot{TOKEN}/sendDocument" () '
                    f'(http:multipart (http:field "chat_id" "-1001") (http:field "caption" "back") '
                    f'(http:file "document" "{fresh("7-file_7.bin")}")) 10000 100000))',
                    "(io:wait 10000)",
                    f'(io:submit (http:request "POST" "{base}/bot{TOKEN}/sendPhoto" () '
                    f'(http:multipart (http:field "chat_id" "-1001") '
                    f'(http:file "photo" "{fresh("7-file_7.bin")}" "picture.png" "image/png")) 10000 100000))',
                    "(io:wait 10000)"], env)
                sent = peer.received[before:]
                documents = [p for r in sent for p in r["parts"] or [] if p["name"] in ("document", "photo")]
                check(dialect, "telegram flow", len(out) == 8 and
                      out[1].startswith('(http:response 200 "{') and "documents/file_7.bin" in out[1] and
                      out[3] == f'(http:saved 200 ' + out[3][len("(http:saved 200 "):] and
                      out[3].endswith(f'"{fresh("7-file_7.bin")}" {len(DOCUMENT)})') and
                      out[5].startswith('(http:response 200 "{') and out[7].startswith('(http:response 200 "{') and
                      [r["path"] for r in sent] == [f"/bot{TOKEN}/sendDocument", f"/bot{TOKEN}/sendPhoto"] and
                      [(p["filename"], p["type"], p["data"]) for p in documents] ==
                      [("7-file_7.bin", "application/octet-stream", DOCUMENT),
                       ("picture.png", "image/png", DOCUMENT)], (out, [(p["filename"], p["type"]) for p in documents]))

                # Refused at submission: nothing is sent, nothing is written.
                before = len(peer.received)
                for name, request, wanted in [
                    ("save into a missing directory", get(base + "/bytes", work + "/absent/x.bin"),
                     "a file in an existing directory"),
                    ("save to a directory path", get(base + "/bytes", str(downloads) + "/dir/"),
                     "a file in an existing directory"),
                    ("missing file part", f'(io:submit (http:request "POST" "{base}/upload" () '
                     f'(http:multipart (http:file "f" "{work}/absent.bin")) 10000 1000))',
                     "readable regular file"),
                    ("multipart GET", f'(io:submit (http:request "GET" "{base}/upload" () '
                     f'(http:multipart (http:field "a" "b")) 10000 1000))', "not GET or HEAD"),
                    ("multipart Content-Type", f'(io:submit (http:request "POST" "{base}/upload" '
                     f'((http:header "Content-Type" "text/plain")) '
                     f'(http:multipart (http:field "a" "b")) 10000 1000))', "sets its own Content-Type"),
                    ("quoted part name", f'(io:submit (http:request "POST" "{base}/upload" () '
                     f'(http:multipart (http:field "a\\"b" "c")) 10000 1000))', "without double quotes"),
                    ("two save options", f'(io:submit (http:request "GET" "{base}/bytes" () "" 10000 1000 '
                     f'False (http:save "{fresh("l.bin")}") (http:save "{fresh("m.bin")}")))', "each at most once")]:
                    out, proc = run(binary, dialect, work, [request], env, catch=True)
                    check(dialect, name, len(out) == 1 and out[0].startswith("(Error (io:submit)") and
                          wanted in out[0], (out, proc.stderr[-300:]))
                check(dialect, "refusals send nothing", len(peer.received) == before and
                      not os.path.exists(fresh("l.bin")), peer.received[before:])
    finally:
        peer.shutdown()
        peer.server_close()
    for dialect, name, detail in failures[:12]:
        print(f"MISMATCH {dialect} {name}\n  {str(detail)[:900]}")
    print(f"io-http-files: {checked} cases in {len(DIALECTS)} dialects, {len(failures)} mismatches")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
