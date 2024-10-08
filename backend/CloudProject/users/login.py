import boto3
from os import getenv
import json
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
import jwt
from datetime import datetime, timedelta
import bcrypt

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

# JWT configuration
JWT_SECRET = getenv('JWT_SECRET')
JWT_ALGORITHM = 'HS256'
JWT_EXP_DELTA_SECONDS = 3600  # Token expiration time (1 hour)

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    # Handle OPTIONS request
    if event.get('httpMethod') == 'OPTIONS':
        print("Handling OPTIONS request")
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,POST'
            },
            'body': json.dumps('OK')
        }

    print(f"HTTP Method: {event.get('httpMethod')}")
    print(f"Event body: {event.get('body')}")

    try:
        if 'body' not in event:
            return response(400, "No body found in the request")

        body = json.loads(event['body']) if isinstance(event['body'], str) else event['body']

        username = body['username']
        password = body['password']
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error processing request: {str(e)}")
        return response(400, f"Error processing request: {str(e)}")

    if not all([username, password]):
        return response(400, "Username and password are required")

    try:
        user = get_user(username)
    except Exception as e:
        return response(500, f"Error querying DynamoDB: {str(e)}")

    if user and bcrypt.checkpw(password.encode('utf-8'), user['password'].encode('utf-8')):
        token = generate_jwt_token(user['id'], user['is_admin'])
        return response(200, {
            "message": "Login successful", 
            "token": token, 
            "user_id": user['id'],
            "is_admin": user['is_admin']
        })
    else:
        return response(401, "Invalid username or password")

def get_user(username):
    try:
        result = User_table.query(
            IndexName='username-index',
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

def generate_jwt_token(user_id, is_admin):
    payload = {
        'user_id': user_id,
        'is_admin': is_admin,
        'exp': datetime.utcnow() + timedelta(seconds=JWT_EXP_DELTA_SECONDS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

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