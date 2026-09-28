#!/usr/bin/env python3
"""Serve a reader-dict DictFile (.df) over HTTP for Lute.

GET /<word> returns the entry as HTML. Headwords and "&" variants
(plurals, conjugations) both resolve. In Lute, add a dictionary with
URI http://localhost:<port>/[LUTE] and type "Embedded".

Usage: dictserver.py FILE.df PORT
"""
import html
import os
import sys
from collections import defaultdict
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

DICT, PORT = sys.argv[1], int(sys.argv[2])

# ponytail: word -> byte offsets, entries read from disk per request; keeps RAM low for 200MB files.
index = defaultdict(list)


def load():
    if not os.path.exists(DICT):
        print(
            f"WARNING: dictionary not found at {DICT}\n"
            "  Download the DictFile (.df) format from https://www.reader-dict.com,\n"
            "  save it to that path (or edit the dictionary list in the `lute` script), then restart `lute`.",
            file=sys.stderr,
        )
        return
    with open(DICT, "rb") as f:
        start = None
        for line in iter(f.readline, b""):
            if line.startswith(b"@ "):
                start = f.tell() - len(line)
            if start is not None and line[:2] in (b"@ ", b"& "):
                word = line[2:].decode("utf-8", "replace").strip().lower()
                if start not in index[word]:
                    index[word].append(start)
    print(f"Loaded {len(index)} words from {DICT}", file=sys.stderr)


def entry(offset):
    """Render one entry starting at offset, up to the next blank line."""
    out = []
    with open(DICT, "rb") as f:
        f.seek(offset)
        for raw in iter(f.readline, b""):
            line = raw.decode("utf-8", "replace").rstrip("\n")
            if not line.strip():
                break
            if line.startswith("@ "):
                out.append(f"<h3>{html.escape(line[2:])}</h3>")
            elif line.startswith(": "):
                out.append(f"<p><i>{html.escape(line[2:])}</i></p>")
            elif line.startswith("<html>"):
                out.append(line[6:])
    return "".join(out)


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        word = unquote(self.path.lstrip("/")).strip()
        offsets = index.get(word.lower(), [])
        body = "<hr>".join(entry(o) for o in offsets) or f"<p>No entry for <b>{html.escape(word)}</b>.</p>"
        data = f"<!doctype html><meta charset=utf-8><body style='font-family:sans-serif'>{body}".encode()
        self.send_response(200 if offsets else 404)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


if __name__ == "__main__":
    load()
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
