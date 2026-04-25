import json
import boto3
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
attendance_table = dynamodb.Table("Attendance")
users_table = dynamodb.Table("Users")

VALID_STATUSES = ["present", "absent", "late", "excused"]

def lambda_handler(event, context):

    print("Event:", event)

    # Handle CORS preflight
    if event.get("httpMethod") == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": ""
        }

    # Parse request body safely
    try:
        body = json.loads(event.get("body", "{}"))
    except Exception:
        return response(400, {"error": "Invalid JSON body"})

    user_id = body.get("user_id")
    status = body.get("status", "present").lower()
    date = body.get("date")   # format: YYYY-MM-DD
    time = body.get("time")   # format: HH:MM

    # Validate user_id
    if not user_id:
        return response(400, {"error": "user_id is required"})

    # Validate status
    if status not in VALID_STATUSES:
        return response(400, {"error": "Invalid status value"})

    # Check if user exists
    user = users_table.get_item(Key={"user_id": user_id})
    if "Item" not in user:
        return response(400, {"error": "User does not exist"})

    # Generate timestamp
    try:
        if date and time:
            timestamp = f"{date}T{time}"
        else:
            timestamp = datetime.utcnow().isoformat()
    except Exception:
        return response(400, {"error": "Invalid date/time format"})

    # Check duplicate attendance (same day)
    today = date if date else datetime.utcnow().date().isoformat()

    existing = attendance_table.scan(
        FilterExpression="user_id = :uid AND begins_with(#ts, :today)",
        ExpressionAttributeNames={"#ts": "timestamp"},
        ExpressionAttributeValues={
            ":uid": user_id,
            ":today": today
        }
    )

    if existing.get("Items"):
        return response(400, {"error": "Attendance already marked for this day"})

    # Insert attendance
    try:
        attendance_table.put_item(
            Item={
                "user_id": user_id,
                "timestamp": timestamp,
                "device": "admin",
                "status": status,
                "type": "manual"
            }
        )
    except Exception as e:
        print("DB Error:", str(e))
        return response(500, {"error": "Database error"})

    return response(200, {"message": "Manual attendance marked"})


def cors_headers():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "*"
    }


def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": cors_headers(),
        "body": json.dumps(body)
    }