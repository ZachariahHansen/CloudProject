import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    
    # Store the connection ID
    connections_table.put_item(
        Item={
            'connectionId': connection_id
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Connected')
    }
