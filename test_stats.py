import urllib.request
import json

# Testing the analytics/stats endpoint
url = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default/attendance-stats"

print(f"Testing attendance-stats API: {url}")
req = urllib.request.Request(
    url, 
    headers={'Accept': 'application/json'}, 
    method='GET'
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
