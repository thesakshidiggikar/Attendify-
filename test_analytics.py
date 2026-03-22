import urllib.request
import json

# Testing another dashboard endpoint to verify API structure
url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/attendance-analytics"

print(f"Testing attendance-analytics API: {url}")
req = urllib.request.Request(
    url, 
    headers={'Accept': 'application/json'}, 
    method='GET'
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
