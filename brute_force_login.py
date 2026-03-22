import urllib.request
import json
import time

variants = [
    "/login",
    "/Login",
    "/login-student",
    "/student-login",
    "/auth/login",
    "/login-user",
    "/UserLogin",
    "/signin",
    "/SignIn",
    "/manual-attendance/login"
]

base = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default"
data = {"username": "STUD001", "password": "Diggikar@123"}

print(f"Brute-forcing API Variant endpoints for {base}...")

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
        # print(f"Body: {e.read().decode('utf-8')}")
    except Exception as e:
        print(f"ERROR: {str(e)}")
    time.sleep(0.5)
