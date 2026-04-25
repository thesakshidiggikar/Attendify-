import urllib.request
import json
import time

variants = [
    "/login",
    "/Login",
    "/student-login",
    "/login-student",
    "/login-user",
    "/UserLogin",
    "/manual-attendance", # testing if same endpoint
    "/mark-attendance",
    "/auth",
    "/signin"
]

base = "https://s3c1f3w0jg.execute-api.ap-south-1.amazonaws.com/default"
data = {"user_id": "STUD001", "Password": "Diggikar@123"} # Using uppercase Password as in DynamoDB

print(f"Brute-forcing API Variant endpoints with user_id/Password for {base}...")

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
            body = response.read().decode('utf-8')
            print(f"Body: {body}")
            if "token" in body.lower() or "success" in body.lower():
                print("FOUND POTENTIAL LOGIN ENDPOINT!")
                break
    except urllib.error.HTTPError as e:
        print(f"FAILED ({e.code})")
    except Exception as e:
        print(f"ERROR: {str(e)}")
    time.sleep(0.3)
