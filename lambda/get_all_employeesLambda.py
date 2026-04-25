import json
import boto3

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("Users")

def lambda_handler(event, context):

    response = table.scan()

    users = response["Items"]

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        },
        "body": json.dumps({"users": users})
    }
