#!/usr/bin/env python3

import os
from http.server import BaseHTTPRequestHandler, HTTPServer

NOTES_FILE = os.environ.get("NOTES_FILE", "/home/vovan/devops_workout/notesApp/notes.txt")
PORT = int(os.environ.get("PORT", "8080"))

REQUESTS = {}

class Handler(BaseHTTPRequestHandler):
    def read_notes(self):
        if not os.path.exists(NOTES_FILE):
            return "cant find notes.txt file\ndont forget to create it!\n"
        with open(NOTES_FILE, encoding="utf-8") as f:
            return f.read()

    def respond(self, code, body):
        REQUESTS[code] = REQUESTS.get(code, 0) + 1
        data = body.encode("utf-8")

        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        if self.path == "/healthz":
            self.respond(200, "ok\n")
        elif self.path == "/":
            self.respond(200, self.read_notes())
        elif self.path == "/metrics":
            lines = [
                "# HELP notes_requests_total Total number of HTTP-requests",
                "# TYPE notes_requests_total counter",
            ]
            for status, count in sorted(REQUESTS.items()):
                lines.append(f'notes_requests_total{{status="{status}"}} {count}')

            lines.extend([
                "# HELP notes_up App is alive",
                "# TYPE notes_up gauge",
                "notes_up 1"
            ])

            self.respond(200, "\n".join(lines) + "\n")
        else:
            self.respond(404, "not found\n")

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"notesApp listen for {PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()