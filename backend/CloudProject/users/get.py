import json
import boto3
from boto3.dynamodb.conditions import Key
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USERS_TABLE'])

def lambda_handler(event, context):
    # Handle OPTIONS request
    if event['httpMethod'] == 'OPTIONS':
        return create_response(200, 'OK')

    # Extract user_id from the path parameters
    user_id = event['pathParameters']['userId']
    
    try:
        # Query the DynamoDB table
        response = table.get_item(Key={'id': user_id})
        
        # Check if the item was found
        if 'Item' in response:
            user = response['Item']
            # Remove sensitive information
            user.pop('password', None)
            return create_response(200, user)
        else:
            return create_response(404, {'message': 'User not found'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return create_response(500, {'message': 'Internal server error'})

def create_response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,GET'
        },
        'body': json.dumps(body)
    }