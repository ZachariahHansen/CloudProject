import json
import boto3
import uuid
import os
from decimal import Decimal
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ.get('LOBBIES_TABLE', 'Lobbies'))
lambda_client = boto3.client('lambda')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def deserialize_dynamodb_item(item):
    return json.loads(json.dumps(item, default=decimal_default))

def invoke_broadcast(message_data):
    payload = {
        'body': json.dumps(message_data),
        'requestContext': {
            'domainName': os.environ['WEBSOCKET_API_DOMAIN'],
            'stage': os.environ['WEBSOCKET_API_STAGE']
        }
    }
    
    lambda_client.invoke(
        FunctionName=os.environ['BROADCAST_FUNCTION_NAME'],
        InvocationType='Event',
        Payload=json.dumps(payload)
    )

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['user_id']
    if not user_id:
        print("user_id not found, hit create lobby")
        return {
            'statusCode': 401,
            'body': json.dumps({'message': 'Unauthorized'})
        }

    try:
        body = json.loads(event['body'])
        lobby_id = str(uuid.uuid4())
        
        item = {
            'id': lobby_id,
            'name': body['name'],
            'creator_id': user_id,
            'max_players': body.get('max_players', 8),
            'current_players': 1,
            'status': 'waiting',
            'players': [user_id],
            'created_at': datetime.utcnow().isoformat()
        }
        
        put_item(item)
        
        response_body = deserialize_dynamodb_item(item)
        
        # Broadcast the lobby creation to all connected clients
        invoke_broadcast({
            'type': 'lobby_update',
            'action': 'created',
            'lobby_id': lobby_id,
            'lobby_name': body['name']
        })
        
        return {
            'statusCode': 201,
            'body': json.dumps(response_body)
        }
    except KeyError:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid request body'})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Error creating lobby: {str(e)}'})
        }

def put_item(item):
    table.put_item(Item=item)