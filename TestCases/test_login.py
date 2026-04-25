import urllib.request
import json

# Using the same URL and payload as kiosk_app
url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/login"
data = {
    "username": "STUD001",
    "password": "Diggikar@123"
}

print(f"Testing Login API: {url}")
print(f"Payload: {data}")

req = urllib.request.Request(
    url, 
    data=json.dumps(data).encode('utf-8'), 
    headers={'Content-Type': 'application/json'}, 
    method='POST'
)

try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        body = response.read().decode('utf-8')
        print("Body:", body)
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Error:", str(e))
