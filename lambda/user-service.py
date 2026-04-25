import json
import boto3
import uuid
import base64
from datetime import datetime

rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")

users_table = dynamodb.Table("Users")

COLLECTION_ID = "faceattend-collection"


def lambda_handler(event, context):

    print("Incoming event:", event)

    # ---------- Step 1: Parse request body ----------
    try:
        if "body" in event:
            body = json.loads(event["body"])
        else:
            body = event
    except Exception:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid JSON body"})
        }

    # ---------- Step 2: Validate required fields ----------
    name = body.get("name")
    department = body.get("department")
    image_base64 = body.get("image")

    if not name or not image_base64:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Missing required fields"})
        }

    # ---------- Step 3: Clean Base64 string ----------
    try:
        if "," in image_base64:
            image_base64 = image_base64.split(",")[1]

        image_bytes = base64.b64decode(image_base64)

    except Exception:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid image format"})
        }

    # ---------- Step 4: Validate image size ----------
    if len(image_bytes) > 5 * 1024 * 1024:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Image size exceeds limit"})
        }

    # ---------- Step 5: Detect faces ----------
    detect_response = rekognition.detect_faces(
        Image={"Bytes": image_bytes}
    )

    face_details = detect_response.get("FaceDetails", [])

    if len(face_details) == 0:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "No face detected"})
        }

    if len(face_details) > 1:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Multiple faces detected"})
        }

    # ---------- Step 6: Check duplicate face ----------
    search_response = rekognition.search_faces_by_image(
        CollectionId=COLLECTION_ID,
        Image={"Bytes": image_bytes},
        MaxFaces=1,
        FaceMatchThreshold=95
    )

    if len(search_response["FaceMatches"]) > 0:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Face already registered"})
        }

    # ---------- Step 7: Generate user id ----------
    user_id = str(uuid.uuid4())

    # ---------- Step 8: Index face ----------
    try:
        response = rekognition.index_faces(
            CollectionId=COLLECTION_ID,
            Image={"Bytes": image_bytes},
            ExternalImageId=user_id,
            MaxFaces=1
        )

    except Exception as e:
        print("Rekognition error:", e)

        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Face indexing failed"})
        }

    if len(response["FaceRecords"]) == 0:
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Face indexing failed"})
        }

    face_id = response["FaceRecords"][0]["Face"]["FaceId"]

    # ---------- Step 9: Store user in DynamoDB ----------
    try:
        users_table.put_item(
            Item={
                "user_id": user_id,
                "name": name,
                "department": department,
                "face_id": face_id,
                "created_at": datetime.utcnow().isoformat()
            }
        )

    except Exception as e:
        print("DB error:", e)

        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Failed to store user"})
        }

    # ---------- Step 10: Success response ----------
    return {
        "statusCode": 200,
        "body": json.dumps({
            "message": "User registered successfully",
            "user_id": user_id
        })
    }