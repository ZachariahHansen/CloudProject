import boto3
from os import getenv
import json
import hashlib

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Extract user information
    if isinstance(event['body'], str):
        body = json.loads(event['body'])
    else:
        body = event['body']

    username = body.get("username")
    password = body.get("password")
    email_address = body.get("email_address")
    is_admin = body.get("is_admin", False)

    # Validate required fields
    if not all([username, password, email_address]):
        return response(400, "Missing required user information")

    # Attempt to add or update user
    try:
        put_user(username, password, email_address, is_admin)
        return response(200, {"message": "User successfully added or updated"})
    except Exception as e:
        return response(500, f"Error adding or updating user: {str(e)}")

def put_user(username, password, email_address, is_admin):
    # Hash the password
    hashed_password = hashlib.sha256(password.encode()).hexdigest()

    # Put user information in DynamoDB
    User_table.put_item(
        Item={
            'username': username,
            'password': hashed_password,
            'email_address': email_address,
            'is_admin': is_admin
        }
    )

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
