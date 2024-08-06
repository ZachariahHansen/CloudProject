import boto3
from os import getenv
import json
import hashlib

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Extract login information
    username = event.get("username")
    password = event.get("password")

    # Validate required fields
    if not all([username, password]):
        return response(400, "Missing username or password")

    # Attempt to authenticate user
    try:
        user = authenticate_user(username, password)
        if user:
            return response(200, {"message": "Login successful", "user": user})
        else:
            return response(401, "Invalid username or password")
    except Exception as e:
        return response(500, f"Error during authentication: {str(e)}")

def authenticate_user(username, password):
    # Hash the password
    hashed_password = hashlib.sha256(password.encode()).hexdigest()

    # Query DynamoDB for the user
    result = User_table.get_item(
        Key={'username': username},
        ProjectionExpression='Id, username, email_address, password, is_admin'
    )

    # Check if user exists and password matches
    if 'Item' in result:
        user = result['Item']
        if user['password'] == hashed_password:
            # Don't return the password in the response
            del user['password']
            return user
    
    return None

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }