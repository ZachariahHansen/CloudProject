import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Lobbies')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def deserialize_dynamodb_item(item):
    return json.loads(json.dumps(item, default=decimal_default))

def lambda_handler(event, context):
    user_id = authenticate(event)
    if not user_id:
        return {
            'statusCode': 401,
            'body': json.dumps('Unauthorized')
        }

    try:
        lobby_id = event['pathParameters']['lobbyId']
        
        lobby = get_lobby(lobby_id)
        
        if not lobby:
            return {
                'statusCode': 404,
                'body': json.dumps('Lobby not found')
            }
        
        if lobby['creator_id'] != user_id:
            return {
                'statusCode': 403,
                'body': json.dumps('Only the creator can delete the lobby')
            }
        
        delete_lobby(lobby_id)
        
        return {
            'statusCode': 200,
            'body': json.dumps('Lobby successfully deleted')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error deleting lobby: {str(e)}')
        }

def authenticate(event):
    return 'user123'

def get_lobby(lobby_id):
    response = table.get_item(Key={'id': lobby_id})
    return response.get('Item')

def delete_lobby(lobby_id):
    table.delete_item(Key={'id': lobby_id})