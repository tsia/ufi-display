#!/usr/bin/env python3
import sys
import re
import os
from http.server import BaseHTTPRequestHandler, HTTPServer
from subprocess import Popen, PIPE
from threading import Timer

SCRIPTDIR = os.getcwd() + '/scripts'
HBTIMEOUT = 30
HBTIMER = None

class Server(BaseHTTPRequestHandler):
    def do_GET(self):
        self._sendResponse(400, b'Bad Request')

    def do_POST(self):
        if self.path == '/heartbeat':
            if HBTIMER is not None:
                HBTIMER.cancel()
            heartbeat()
            self._sendResponse(200, b'OK')
            return

        if self.path == '/exit':
            sys.exit()
            self._sendResponse(200, b'OK')
            return

        if not re.match(r"/[a-zA-Z0-9\._-]", self.path):
            self._sendResponse(400, b'Bad Request')
            return
        if not os.path.isfile(SCRIPTDIR + self.path + '.sh'):
            self._sendResponse(404, b'Not Found')
            return
        args = [SCRIPTDIR + self.path + '.sh']
        Popen(args, cwd=SCRIPTDIR)
        self._sendResponse(200, b'OK')

    def _sendResponse(self, code, body, contenttype = 'text/plain'):
        self.send_response(code)
        self.send_header('Content-type', contenttype)
        self.end_headers()
        self.wfile.write(body)

def timeout():
    print('heartbeat timeout')
    args = [SCRIPTDIR + '/heartbeat.sh']
    Popen(args, cwd=SCRIPTDIR)
    heartbeat()

def heartbeat():
    global HBTIMER
    print('Starting heartbeat with timeout=%d' % (HBTIMEOUT))
    HBTIMER = Timer(HBTIMEOUT, timeout)
    HBTIMER.start()

def run(server_class=HTTPServer, handler_class=Server, port=80):
    print('Running setup script')
    if not os.path.isfile(SCRIPTDIR + '/setup.sh'):
        print('not found. skipping')
    else:
        args = [SCRIPTDIR + '/setup.sh']
        Popen(args, cwd=SCRIPTDIR)
    print('Starting httpd on port %d...' % (port))
    server_address = ('localhost', port)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()

if __name__ == "__main__":
    try:
        if len(sys.argv) == 2:
            run(port=int(sys.argv[1]))
        else:
            run()
    except KeyboardInterrupt as e:
        if HBTIMER:
            HBTIMER.cancel()
        print(e)
