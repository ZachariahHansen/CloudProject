import json
import os
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])
api_gateway = boto3.client('apigatewaymanagementapi')

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    
    api_gateway.apigatewaymanagementapi = boto3.client(
        'apigatewaymanagementapi',
        endpoint_url=f"https://{domain_name}/{stage}"
    )
    
    # Parse the incoming message
    body = json.loads(event.get('body', '{}'))
    message_type = body.get('type')
    message_data = body.get('data', {})
    
    # Handle different message types
    if message_type == 'broadcast':
        broadcast_message(message_data)
    elif message_type == 'lobby_update':
        broadcast_lobby_update(message_data)
    elif message_type == 'game_start':
        handle_game_start(message_data)
    elif message_type == 'scenario_selected':
        broadcast_scenario_selected(message_data)
    elif message_type == 'all_answers_submitted':
        broadcast_all_answers_submitted(message_data)
    elif message_type == 'answers_evaluated':
        broadcast_answers_evaluated(message_data)
    else:
        return {
            'statusCode': 400,
            'body': json.dumps('Invalid message type')
        }
    
    return {
        'statusCode': 200,
        'body': json.dumps('Message sent')
    }

def broadcast_message(message):
    connections = table.scan()['Items']
    for connection in connections:
        send_message(connection['connectionId'], message)

def broadcast_lobby_update(data):
    # Implement lobby update logic
    pass

def handle_game_start(data):
    # Implement game start logic
    pass

def broadcast_scenario_selected(data):
    # Implement scenario selected logic
    pass

def broadcast_all_answers_submitted(data):
    # Implement all answers submitted logic
    pass

def broadcast_answers_evaluated(data):
    # Implement answers evaluated logic
    pass

def send_message(connection_id, message):
    try:
        api_gateway.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(message).encode('utf-8')
        )
    except api_gateway.exceptions.GoneException:
        # Connection no longer exists, remove it from the table
        table.delete_item(Key={'connectionId': connection_id})