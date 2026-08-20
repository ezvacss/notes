import os
from http.server import BaseHTTPRequestHandler, HTTPServer

NOTES_FILE = os.environ.get("NOTES_FILE", "/home/vovan/devops_workout/notesApp/notes.txt")
PORT = int(os.environ.get("PORT", "8080"))

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/healthz":
            self.respond(200, "ok\n")
        elif self.path == "/":
            self.respond(200, self.read_notes())
        else:
            self.respond(404, "page not found\n")

    def read_notes(self):
        if not os.path.exists(NOTES_FILE):
            return "cant find notes.txt file\n"
        with open (NOTES_FILE, encoding="utf=8") as f:
            return f.read()

    def respond(self, code, body):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        print(f"{self.address_string()} {fmt % args}", flush=True)


if __name__ == "__main__":
    print(f"notesApp listen for {PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
