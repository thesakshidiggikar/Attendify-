import json
import boto3

dynamodb = boto3.resource("dynamodb")
rekognition = boto3.client("rekognition")
users_table = dynamodb.Table("Users")
COLLECTION_ID = "faceattend-collection"

def lambda_handler(event, context):
    try:
        body = json.loads(event["body"]) if "body" in event else event
        user_id = body.get("user_id") or body.get("username")

        # Get face_id first
        response = users_table.get_item(Key={"user_id": user_id})
        if "Item" not in response:
            return response_json(404, {"message": "User not found"})

        face_id = response["Item"].get("face_id")

        # 1. Delete from Rekognition
        if face_id:
            try:
                rekognition.delete_faces(CollectionId=COLLECTION_ID, FaceIds=[face_id])
            except: pass

        # 2. Delete from DynamoDB
        users_table.delete_item(Key={"user_id": user_id})

        return response_json(200, {"message": "User deleted successfully"})
    except Exception as e:
        return response_json(500, {"message": str(e)})

def response_json(status, body):
    return {
        "statusCode": status,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,POST"
        },
        "body": json.dumps(body)
    }
