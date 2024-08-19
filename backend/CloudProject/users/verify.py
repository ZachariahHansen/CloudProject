import boto3
import json
from os import getenv

# Initialize the DynamoDB resource
region_name = getenv('APP_REGION')
User_table = boto3.resource('dynamodb', region_name=region_name).Table('Cloud_Users')

def lambda_handler(event, context):
    # Get the verification token from the query string parameters
    token = event['queryStringParameters'].get('token')
    
    if not token:
        return response(400, "Verification token is missing")

    # Find the user with this token
    try:
        result = User_table.scan(
            FilterExpression='verification_token = :token',
            ExpressionAttributeValues={':token': token}
        )
    except Exception as e:
        return response(500, f"Error querying DynamoDB: {str(e)}")

    items = result.get('Items', [])
    if not items:
        return response(400, "Invalid verification token")

    user = items[0]
    
    # Update user to verified status
    try:
        User_table.update_item(
            Key={'Id': user['Id']},
            UpdateExpression='SET verified = :val REMOVE verification_token',
            ExpressionAttributeValues={':val': True}
        )
    except Exception as e:
        return response(500, f"Error updating user in DynamoDB: {str(e)}")

    return response(200, "Email verified successfully. You can now log in to your account.")

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "GET,OPTIONS"
        },
        "body": json.dumps({"message": body})
    }