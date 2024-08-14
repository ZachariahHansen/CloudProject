import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    
    # Store the connection ID in DynamoDB
    table.put_item(
        Item={
            'connectionId': connection_id
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Connected')
    }