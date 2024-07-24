#!/usr/bin/env python3

import os
import json
import base64
import hashlib
from http.server import SimpleHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse
import logging

AUTH_FILE = '/opt/wol/.htpasswd'
JSON_FILE = '/opt/wol/db/pcs.json'
STATIC_DIR = '/opt/wol'

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def check_password(username, hashed_password):
    """Check if the provided username and hashed password match the stored credentials."""
    try:
        with open(AUTH_FILE, 'r') as f:
            for line in f:
                stored_username, stored_hashed_password = line.strip().split(':')
                if stored_username == username and stored_hashed_password == hashed_password:
                    return True
    except FileNotFoundError:
        logging.error("Auth file not found.")
    return False

class WOLServerHandler(SimpleHTTPRequestHandler):

    def _set_headers(self, content_type='application/json'):
        self.send_response(200)
        self.send_header('Content-type', content_type)
        self.end_headers()

    def _send_json_response(self, response):
        self._set_headers()
        self.wfile.write(json.dumps(response).encode('utf-8'))

    def _authenticate(self):
        auth_header = self.headers.get('Authorization')
        if auth_header is None:
            return False

        auth_type, credentials = auth_header.split(' ', 1)
        if auth_type.lower() != 'basic':
            return False

        decoded_credentials = base64.b64decode(credentials).decode('utf-8')
        username, hashed_password = decoded_credentials.split(':', 1)

        return check_password(username, hashed_password)

    def do_GET(self):
        try:
            parsed_path = urlparse(self.path)
            if parsed_path.path.startswith('/api/'):
                if not self._authenticate():
                    self._send_json_response({'success': False, 'message': 'Authentication failed'})
                    return

                query_components = parse_qs(parsed_path.query)
                if 'load' in query_components:
                    with open(JSON_FILE, 'r') as file:
                        pcs = json.load(file)
                    self._send_json_response({'success': True, 'pcs_list': pcs})
                elif 'wake' in query_components:
                    mac = query_components['wake'][0]
                    os.system(f'etherwake -i eno1 -b {mac}')
                    self._send_json_response({'success': True, 'message': f'Wake-up signal sent to {mac}'})
                elif 'delete' in query_components:
                    mac = query_components['delete'][0]
                    with open(JSON_FILE, 'r') as file:
                        pcs = json.load(file)
                    pcs = [pc for pc in pcs if pc['mac'] != mac]
                    with open(JSON_FILE, 'w') as file:
                        json.dump(pcs, file)
                    self._send_json_response({'success': True, 'message': f'Deleted PC with MAC {mac}', 'pcs_list': pcs})
                else:
                    # If no specific query is detected, respond with a generic success message
                    self._send_json_response({'success': True, 'message': 'Authenticated successfully'})
            else:
                super().do_GET()
        except Exception as e:
            logging.error(f"Error handling GET request: {e}")
            self._send_json_response({'success': False, 'message': 'Internal server error'})

    def do_POST(self):
        try:
            if not self._authenticate():
                self._send_json_response({'success': False, 'message': 'Authentication failed'})
                return

            content_length = int(self.headers['Content-Length'])
            post_data = self.rfile.read(content_length).decode('utf-8')
            post_data = parse_qs(post_data)

            new_pc = {
                'mac': post_data['mac'][0],
                'ip': post_data['ip'][0],
                'hostname': post_data['hostname'][0]
            }

            with open(JSON_FILE, 'r') as file:
                pcs = json.load(file)

            pcs.append(new_pc)

            with open(JSON_FILE, 'w') as file:
                json.dump(pcs, file)

            self._send_json_response({'success': True, 'message': 'PC added successfully', 'pcs_list': pcs})
        except Exception as e:
            logging.error(f"Error handling POST request: {e}")
            self._send_json_response({'success': False, 'message': 'Internal server error'})

    def log_message(self, format, *args):
        logging.info("%s - - [%s] %s" % (self.client_address[0], self.log_date_time_string(), format % args))

def run(server_class=HTTPServer, handler_class=WOLServerHandler, port=9091):
    os.chdir(STATIC_DIR)  # Change to the directory with static files
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    logging.info('Starting server...')
    httpd.serve_forever()

if __name__ == '__main__':
    run()