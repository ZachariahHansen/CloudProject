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

def response(status_code, body):
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

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['user_id']
    if not user_id:
        print("user_id not found, hit create lobby")
        return response(401, {'message': 'Unauthorized'})

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
        
        return response(201, response_body)
    except KeyError:
        return response(400, {'message': 'Invalid request body'})
    except Exception as e:
        return response(500, {'message': f'Error creating lobby: {str(e)}'})

def put_item(item):
    table.put_item(Item=item)