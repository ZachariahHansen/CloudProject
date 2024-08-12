import boto3
from os import getenv
from uuid import uuid4
import json

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Extract the body from the event. Check if it's already a dictionary.
    body = event.get('body')

    # If the body is a string (i.e., JSON string), parse it into a dictionary.
    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            return response(400, "Invalid JSON in request body")

    # If body is not a string and not a dictionary, return an error.
    elif not isinstance(body, dict):
        return response(400, "Body must be a JSON formatted string or a dict")

    # Proceed with processing the body now that it's a dictionary.
    # Extract user information
    Id = str(uuid4())
    username = body.get("username")
    email_address = body.get("email_address")
    password = body.get("password")  # This is the plain text password for now
    is_admin = body.get("is_admin", False)

    # Validate required fields
    if not all([username, email_address, password]):
        return response(400, "Missing required fields")

    # Insert the user data into DynamoDB
    try:
        db_insert(Id, username, email_address, password, is_admin)  # Passing plain text password
    except Exception as e:
        return response(500, f"Error inserting into DynamoDB: {str(e)}")

    return response(200, {"Id": Id})


def db_insert(Id, username, email_address, password, is_admin):
    User_table.put_item(Item={
        'Id': Id,
        'username': username,
        'email_address': email_address,
        'password': password,  # Storing the plain text password
        'is_admin': is_admin
    })

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }
