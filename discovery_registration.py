import urllib.request
import json
import time

variants = [
    "/register",
    "/signup",
    "/create-user",
    "/add-user",
    "/add-student",
    "/register-student",
    "/student-register",
    "/user-service",
    "/registration",
    "/user"
]

base = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default"
# Dummy registration data
data = {
    "username": "DiscoveryTest",
    "email": "test@example.com",
    "password": "Password123!",
    "profile": "student"
}

print(f"Brute-forcing Registration Variant endpoints for {base}...")

for v in variants:
    url = base + v
    print(f"Testing {url}...", end=" ", flush=True)
    req = urllib.request.Request(
        url, 
        data=json.dumps(data).encode('utf-8'), 
        headers={'Content-Type': 'application/json'}, 
        method='POST'
    )
    try:
        with urllib.request.urlopen(req) as response:
            print(f"SUCCESS! Code: {response.status}")
            print(f"Body: {response.read().decode('utf-8')}")
            break
    except urllib.error.HTTPError as e:
        print(f"FAILED ({e.code})")
    except Exception as e:
        print(f"ERROR: {str(e)}")
    time.sleep(0.3)
