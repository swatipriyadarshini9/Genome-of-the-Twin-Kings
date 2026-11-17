#!/usr/bin/env python3
"""Serve a Godot Web export locally, with browser cache revalidation.

Run from the export directory: python3 serve.py
For another directory: python3 serve_web.py --directory ../twin-kings-preview
"""

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class RevalidatingHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # A fresh export at the same origin should replace cached .html/.pck files
        # without changing the origin where Godot keeps the player's saves.
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--directory", default=".", help="directory containing index.html")
    parser.add_argument("--host", default="127.0.0.1", help="listen address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=8000, help="listen port (default: 8000)")
    args = parser.parse_args()
    directory = Path(args.directory).resolve()
    if not (directory / "index.html").is_file():
        parser.error(f"no index.html found in {directory}")
    handler = partial(RevalidatingHandler, directory=str(directory))
    with ThreadingHTTPServer((args.host, args.port), handler) as server:
        print(f"Serving {directory} at http://{args.host}:{args.port}/", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            print("\nServer stopped.")


if __name__ == "__main__":
    main()
