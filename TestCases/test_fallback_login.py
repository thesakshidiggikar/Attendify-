import urllib.request
import json

# Testing the FALLBACK URL found in the code
url = "https://wny1io6xre.execute-api.ap-south-1.amazonaws.com/dev/login"
data = {
    "username": "STUD001",
    "password": "Diggikar@123"
}

print(f"Testing Fallback Login API: {url}")
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
