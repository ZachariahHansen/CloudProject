import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    
    # Process the incoming message
    body = json.loads(event['body'])
    action = body.get('action')
    
    # Handle different actions
    if action == 'echo':
        message = body.get('message', '')
        send_message(connection_id, domain_name, stage, f"Echo: {message}")
    else:
        send_message(connection_id, domain_name, stage, "Unknown action")
    
    return {
        'statusCode': 200,
        'body': json.dumps('Message processed')
    }

def send_message(connection_id, domain_name, stage, message):
    gateway_api = boto3.client('apigatewaymanagementapi', 
                               endpoint_url=f"https://{domain_name}/{stage}")
    
    gateway_api.post_to_connection(
        ConnectionId=connection_id,
        Data=json.dumps(message).encode('utf-8')
    )