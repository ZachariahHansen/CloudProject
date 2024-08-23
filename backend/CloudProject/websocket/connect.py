import os
import boto3
from botocore.exceptions import ClientError
import json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    user_id = event['queryStringParameters'].get('user_id')
    
    if not user_id:
        return {
            'statusCode': 400,
            'body': json.dumps('user_id is required')
        }
    
    try:
        table.put_item(Item={
            'connectionId': connection_id,
            'userId': user_id
        })
        return {'statusCode': 200, 'body': 'Connected'}
    except ClientError as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': 'Failed to connect'}