import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Attendance")

def lambda_handler(event, context):
    try:
        response = table.scan()
        items = response.get("Items", [])

        # latest first
        items_sorted = sorted(
            items,
            key=lambda x: x.get("timestamp", ""),
            reverse=True
        )

        recent = items_sorted[:10]

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps(recent)
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"message": str(e)})
        }