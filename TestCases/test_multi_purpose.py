import urllib.request
import json

# Testing if manual-attendance is a multi-purpose endpoint
url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/manual-attendance"
data = {
    "username": "STUD001",
    "password": "Diggikar@123",
    "action": "login" # Guessing an action field
}

print(f"Testing manual-attendance as login: {url}")
req = urllib.request.Request(
    url, 
    data=json.dumps(data).encode('utf-8'), 
    headers={'Content-Type': 'application/json'}, 
    method='POST'
)

try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Error:", str(e))
