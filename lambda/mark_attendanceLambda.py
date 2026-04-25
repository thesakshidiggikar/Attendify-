import json
import boto3
import base64
from datetime import datetime
from boto3.dynamodb.conditions import Key

rekognition = boto3.client("rekognition")
dynamodb = boto3.resource("dynamodb")
users_table = dynamodb.Table("Users")
attendance_table = dynamodb.Table("Attendance")
COLLECTION_ID = "faceattend-collection"

def lambda_handler(event, context):
    try:
        body = json.loads(event["body"]) if "body" in event else event
        image_base64 = body.get("image")
        
        if "," in image_base64:
            image_base64 = image_base64.split(",")[1]
        image_bytes = base64.b64decode(image_base64)

        # 1. Search for a matching face
        search_resp = rekognition.search_faces_by_image(
            CollectionId=COLLECTION_ID,
            Image={"Bytes": image_bytes},
            FaceMatchThreshold=90,
            MaxFaces=1
        )

        if not search_resp["FaceMatches"]:
            return response_json(404, {"message": "Face not recognized"})

        user_id = search_resp["FaceMatches"][0]["Face"]["ExternalImageId"]
        
        # 2. Fetch User Name to fix the "Random string on right" Kiosk bug 
        user_resp = users_table.get_item(Key={"user_id": user_id})
        student_name = user_resp.get("Item", {}).get("name", "Unknown Student")
        
        # 3. Prevent duplicate attendance today
        today_date = datetime.utcnow().strftime("%Y-%m-%d")
        
        # FIX: Move timestamp check into KeyConditionExpression since it is a Sort Key
        existing_attendance = attendance_table.query(
            KeyConditionExpression=Key("user_id").eq(user_id) & Key("timestamp").begins_with(today_date)
        )
        
        # If they already scanned in today, return immediately without re-saving
        if existing_attendance.get("Items"):
            return response_json(200, {
                "message": f"Already marked for {student_name} today!", 
                "user_id": user_id,
                "name": student_name
            })
        
        # 4. Mark attendance (Save 'name' too)
        attendance_table.put_item(
            Item={
                "user_id": user_id,
                "name": student_name,
                "timestamp": datetime.utcnow().isoformat(),
                "device": "kiosk-scan",
                "status": "present"
            }
        )

        return response_json(200, {
            "message": f"Attendance marked for {student_name}!", 
            "user_id": user_id,
            "name": student_name
        })
        
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


# import json
# import boto3
# import base64
# from datetime import datetime
# from boto3.dynamodb.conditions import Key, Attr

# rekognition = boto3.client("rekognition")
# dynamodb = boto3.resource("dynamodb")
# users_table = dynamodb.Table("Users")
# attendance_table = dynamodb.Table("Attendance")
# COLLECTION_ID = "faceattend-collection"

# def lambda_handler(event, context):
#     try:
#         body = json.loads(event["body"]) if "body" in event else event
#         image_base64 = body.get("image")
        
#         if "," in image_base64:
#             image_base64 = image_base64.split(",")[1]
#         image_bytes = base64.b64decode(image_base64)

#         # 1. Search for a matching face
#         search_resp = rekognition.search_faces_by_image(
#             CollectionId=COLLECTION_ID,
#             Image={"Bytes": image_bytes},
#             FaceMatchThreshold=90,
#             MaxFaces=1
#         )

#         if not search_resp["FaceMatches"]:
#             return response_json(404, {"message": "Face not recognized"})

#         user_id = search_resp["FaceMatches"][0]["Face"]["ExternalImageId"]
        
#         # 2. Fetch User Name to fix the "Random string on right" Kiosk bug 
#         user_resp = users_table.get_item(Key={"user_id": user_id})
#         student_name = user_resp.get("Item", {}).get("name", "Unknown Student")
        
#         # 3. Prevent duplicate attendance today
#         today_date = datetime.utcnow().strftime("%Y-%m-%d")
        
#         existing_attendance = attendance_table.query(
#             KeyConditionExpression=Key("user_id").eq(user_id),
#             FilterExpression=Attr("timestamp").begins_with(today_date)
#         )
        
#         # If they already scanned in today, return immediately without re-saving
#         if existing_attendance.get("Items"):
#             return response_json(200, {
#                 "message": f"{student_name} already marked present!", 
#                 "user_id": user_id,
#                 "name": student_name
#             })
        
#         # 4. Mark attendance (Save 'name' too, so recent-attendance doesn't show UUIDs!)
#         attendance_table.put_item(
#             Item={
#                 "user_id": user_id,
#                 "name": student_name,
#                 "timestamp": datetime.utcnow().isoformat(),
#                 "device": "kiosk-scan",
#                 "status": "present"
#             }
#         )

#         return response_json(200, {
#             "message": f"Attendance marked for {student_name}!", 
#             "user_id": user_id,
#             "name": student_name
#         })
        
#     except Exception as e:
#         return response_json(500, {"message": str(e)})

# def response_json(status, body):
#     return {
#         "statusCode": status,
#         "headers": {
#             "Content-Type": "application/json",
#             "Access-Control-Allow-Origin": "*",
#             "Access-Control-Allow-Methods": "OPTIONS,POST"
#         },
#         "body": json.dumps(body)
#     }

