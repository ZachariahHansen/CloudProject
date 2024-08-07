import boto3
from os import getenv
import json

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
Performer_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Extract the user Id
    user_id = event.get("Id")

    # Validate required fields
    if not user_id:
        return response(400, "Missing user Id")

    # Attempt to delete the user
    try:
        db_delete(user_id)
        return response(200, {"message": "User successfully deleted"})
    except Exception as e:
        return response(500, f"Error deleting user from DynamoDB: {str(e)}")

def db_delete(user_id):
    # Delete the user from DynamoDB
    Performer_table.delete_item(
        Key={'Id': user_id}
    )

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
