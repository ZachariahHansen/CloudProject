import boto3
from os import getenv
from uuid import uuid4
import json

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
Performer_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Extract performer information
    Id = str(uuid4())
    username = event["username"]
    email_address = event["email_address"]
    password = event["password"]
    is_admin = event["is_admin"]

    # Validate required fields
    if not all([username, email_address, password, is_admin]):
        return response(400, "Missing required fields")

    # Insert the performer data into DynamoDB
    try:
        db_insert(Id, username, email_address, password, is_admin)
    except Exception as e:
        return response(500, f"Error inserting into DynamoDB: {str(e)}")

    return response(200, {"Id": Id})

def db_insert(Id, username, email_address, password, is_admin):
    # Put item into DynamoDB
    Performer_table.put_item(Item={
        'Id': Id,
        'username': username,
        'email_address': email_address,
        'password': password,
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
