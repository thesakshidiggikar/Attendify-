import urllib.request
import json

# Testing if manual-attendance acts as a login proxy when provided with user_id
url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/manual-attendance"
data = {
    "user_id": "STUD001",
    "password": "Diggikar@123"
}

print(f"Testing manual-attendance with user_id: {url}")
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
