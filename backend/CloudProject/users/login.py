import boto3
from os import getenv
import json
from boto3.dynamodb.conditions import Key

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Print the entire event for debugging
    print(f"Received event: {json.dumps(event)}")

    # Extract username and password from the event body
    try:
        # Check if body exists in the event
        #  if isinstance(event['body'], str):
        #     body = json.loads(event['body'])
        # else:
        #     body = event['body']
        
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
        password = body['password']
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

    # Check if user exists and password matches
    if user and user['password'] == password:
        # Remove sensitive information before returning
        del user['password']
        return response(200, {"message": "Authentication successful", "user": user})
    else:
        return response(401, "Invalid username or password")

def get_user(username):
    # Query item from DynamoDB
    result = User_table.query(
        KeyConditionExpression=Key('username').eq(username)
    )
    items = result.get('Items', [])
    return items[0] if items else None

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }