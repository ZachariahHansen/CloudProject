import os
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    
    try:
        table.put_item(Item={'connectionId': connection_id})
        return {'statusCode': 200, 'body': 'Connected'}
    except ClientError as e:
        print(f"Error: {e}")
        return {'statusCode': 500, 'body': 'Failed to connect'}