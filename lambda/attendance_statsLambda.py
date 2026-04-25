import json
import boto3
from datetime import datetime

dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table("Users")
attendance_table = dynamodb.Table("Attendance")

def lambda_handler(event, context):

    try:
        if event.get("httpMethod") == "OPTIONS":
            return response(200, {})

        today = datetime.utcnow().date().isoformat()

        # Fetch all users (handle pagination)
        users = []
        response_users = users_table.scan()
        users.extend(response_users.get("Items", []))

        while "LastEvaluatedKey" in response_users:
            response_users = users_table.scan(ExclusiveStartKey=response_users["LastEvaluatedKey"])
            users.extend(response_users.get("Items", []))

        total_students = len(users)

        # Edge case: no users
        if total_students == 0:
            return response(200, {
                "total_students": 0,
                "present_today": 0,
                "absent_today": 0,
                "attendance_percentage": 0
            })

        # Create valid user set
        valid_users = set(user["user_id"] for user in users)

        # Fetch all attendance (handle pagination)
        attendance_items = []
        response_att = attendance_table.scan()
        attendance_items.extend(response_att.get("Items", []))

        while "LastEvaluatedKey" in response_att:
            response_att = attendance_table.scan(ExclusiveStartKey=response_att["LastEvaluatedKey"])
            attendance_items.extend(response_att.get("Items", []))

        # Track unique उपस्थित users
        present_users = set()

        for item in attendance_items:
            timestamp = item.get("timestamp", "")
            user_id = item.get("user_id")

            if not timestamp or not user_id:
                continue

            # Ignore unknown users
            if user_id not in valid_users:
                continue

            if timestamp.startswith(today):
                present_users.add(user_id)

        present_today = len(present_users)
        absent_today = max(0, total_students - present_today)

        percentage = (present_today / total_students) * 100

        return response(200, {
            "total_students": total_students,
            "present_today": present_today,
            "absent_today": absent_today,
            "attendance_percentage": round(percentage, 2)
        })

    except Exception as e:
        print("Error:", str(e))
        return response(500, {"error": "Internal server error"})


def response(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, OPTIONS",
            "Access-Control-Allow-Headers": "*"
        },
        "body": json.dumps(body)
    }