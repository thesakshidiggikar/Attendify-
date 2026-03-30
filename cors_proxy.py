import http.server
import http.client
import urllib.parse
import json

class ProxyHTTPRequestHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = 'HTTP/1.1'

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)

        # Target AWS Endpoint
        target_host = "s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com"
        target_path = "/default" + self.path

        print(f"Forwarding POST request to: https://{target_host}{target_path}")

        conn = http.client.HTTPSConnection(target_host)
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        
        try:
            conn.request("POST", target_path, body, headers)
            response = conn.getresponse()
            resp_data = response.read()

            self.send_response(response.status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(resp_data)
        except Exception as e:
            print(f"Error: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())
        finally:
            conn.close()

    def do_GET(self):
        # Target AWS Endpoint
        target_host = "s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com"
        target_path = "/default" + self.path

        print(f"Forwarding GET request to: https://{target_host}{target_path}")

        conn = http.client.HTTPSConnection(target_host)
        try:
            conn.request("GET", target_path)
            response = conn.getresponse()
            resp_data = response.read()

            self.send_response(response.status)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(resp_data)
        except Exception as e:
            print(f"Error: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(str(e).encode())
        finally:
            conn.close()

def run(server_class=http.server.HTTPServer, handler_class=ProxyHTTPRequestHandler, port=8000):
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    print(f"CORS Proxy running on http://localhost:{port}")
    httpd.serve_forever()

if __name__ == "__main__":
    run()
