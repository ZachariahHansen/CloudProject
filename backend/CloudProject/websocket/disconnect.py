import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    
    # Remove the connection ID from DynamoDB
    table.delete_item(
        Key={
            'connectionId': connection_id
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Disconnected')
    }