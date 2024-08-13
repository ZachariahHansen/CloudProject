import boto3
from os import getenv
import json
from boto3.dynamodb.conditions import Attr
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
from uuid import uuid4

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Print the entire event for debugging
    print(f"Received event: {json.dumps(event)}")

    # Extract username and password from the event body
    try:
        if 'body' not in event:
            return response(400, "No body found in the request")

        # Parse the body
        if isinstance(event['body'], str):
            body = json.loads(event['body'])
        elif isinstance(event['body'], dict):
            body = event['body']
        else:
            return response(400, f"Unexpected body type: {type(event['body'])}")

        # Extract username and password
        username = body['username']
        password = body['password']  # This is the plain text password for now
    except json.JSONDecodeError:
        return response(400, "Invalid JSON in request body")
    except KeyError as e:
        return response(400, f"Missing required field: {str(e)}")
    except Exception as e:
        return response(400, f"Error processing request: {str(e)}")

    # Validate required fields
    if not all([username, password]):
        return response(400, "Username and password are required")

    # Retrieve user data from DynamoDB
    try:
        user = get_user(username)
    except Exception as e:
        return response(500, f"Error querying DynamoDB: {str(e)}")

    # Check if user exists and password matches (simple string match, insecure)
    if user and password == user['password']:  # Simple password comparison
        # Generate a session ID
        session_id = str(uuid4())
        
        # Here you might want to store the session ID in a database or cache
        # For simplicity, we're just returning it
        
        return response(200, {"message": "Login successful", "session_id": session_id, "user_id": user['Id']})
    else:
        return response(401, "Invalid username or password")

def get_user(username):
    try:
        # Query items from DynamoDB
        result = User_table.query(
            IndexName='username-index',  # Assuming you've created a GSI on the username field
            KeyConditionExpression=Key('username').eq(username)
        )
        items = result.get('Items', [])
        return items[0] if items else None
    except ClientError as e:
        print(f"An error occurred: {e.response['Error']['Message']}")
        raise
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        raise


def response(code, body):
    return {
        "statusCode": code,
        "headers": {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
    "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"
},
        "body": json.dumps(body)
    }
