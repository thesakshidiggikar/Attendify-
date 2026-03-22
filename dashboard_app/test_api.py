import urllib.request
import json

url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/manual-attendance"
data = {
    "username": "Rahul Gandhi",
    "date": "2026-03-19",
    "time": "1:11 PM",
    "status": "present",
    "entry_type": "manual"
}
req = urllib.request.Request(url, data=json.dumps(data).encode('utf-8'), headers={'Content-Type': 'application/json'}, method='POST')
try:
    with urllib.request.urlopen(req) as response:
        print("Status:", response.status)
        print("Body:", response.read().decode('utf-8'))
except urllib.error.HTTPError as e:
    print("HTTP Error:", e.code)
    print("Body:", e.read().decode('utf-8'))
except Exception as e:
    print("Error:", str(e))
