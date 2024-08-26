import boto3
from os import getenv
from uuid import uuid4
import json
import bcrypt
import jwt
from datetime import datetime, timedelta

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')
ses = boto3.client('ses', region_name=region_name)

# JWT configuration
JWT_SECRET = getenv('JWT_SECRET')
JWT_ALGORITHM = 'HS256'
JWT_EXP_DELTA_SECONDS = 3600  # Token expiration time (1 hour)

def lambda_handler(event, context):
    # Handle OPTIONS request
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,POST'
            },
            'body': json.dumps('OK')
        }

    body = event.get('body')

    if isinstance(body, str):
        try:
            body = json.loads(body)
        except json.JSONDecodeError:
            return response(400, "Invalid JSON in request body")
    elif not isinstance(body, dict):
        return response(400, "Body must be a JSON formatted string or a dict")

    # Extract user information
    Id = str(uuid4())
    username = body.get("username")
    email_address = body.get("email_address")
    password = body.get("password")
    is_admin = False

    # Validate required fields
    if not all([username, email_address, password]):
        return response(400, "Missing required fields")

    # Hash the password
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

    # Generate verification token
    verification_token = str(uuid4())

    # Insert the user data into DynamoDB
    try:
        db_insert(Id, username, email_address, hashed_password, is_admin, verification_token)
    except Exception as e:
        return response(500, f"Error inserting into DynamoDB: {str(e)}")

    # Send verification email
    # try:
    #     send_verification_email(email_address, verification_token)
    # except Exception as e:
    #     return response(500, f"Error sending verification email: {str(e)}")

    # Generate JWT token
    token = generate_jwt_token(Id)

    return response(200, {"message": "Registration successful. Please check your email to verify your account.", "Id": Id, "token": token})

def db_insert(Id, username, email_address, hashed_password, is_admin, verification_token):
    User_table.put_item(Item={
        'id': Id,
        'username': username,
        'email_address': email_address,
        'password': hashed_password,
        'is_admin': is_admin,
        'verified': False,
        'verification_token': verification_token
    })

def generate_jwt_token(user_id):
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(seconds=JWT_EXP_DELTA_SECONDS)
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def send_verification_email(email, token):
    SENDER = "zachariahjhansen@gmail.com"  # Replace with your SES verified email
    SUBJECT = "Verify your email for Dangerous Scenario Game"
    VERIFY_URL = f"https://your-api-gateway-url/users/verify?token={token}"  # Replace with your actual verification URL
    BODY_TEXT = f"Please click the following link to verify your email: {VERIFY_URL}"
    BODY_HTML = f"""
    <html>
    <head></head>
    <body>
        <h1>Verify your email for Dangerous Scenario Game</h1>
        <p>Please click the following link to verify your email:</p>
        <p><a href='{VERIFY_URL}'>Verify Email</a></p>
    </body>
    </html>
    """

    try:
        ses.send_email(
            Destination={'ToAddresses': [email]},
            Message={
                'Body': {
                    'Html': {'Data': BODY_HTML},
                    'Text': {'Data': BODY_TEXT},
                },
                'Subject': {'Data': SUBJECT},
            },
            Source=SENDER
        )
    except Exception as e:
        print(f"Error sending email: {str(e)}")
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