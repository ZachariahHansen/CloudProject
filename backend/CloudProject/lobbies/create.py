import json
import boto3
import uuid
from decimal import Decimal
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Lobbies')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def deserialize_dynamodb_item(item):
    return json.loads(json.dumps(item, default=decimal_default))

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['user_id']
    if not user_id:
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