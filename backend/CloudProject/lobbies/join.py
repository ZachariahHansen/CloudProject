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
        
        updated_lobby = join_lobby(lobby_id, user_id)
        
        if not updated_lobby:
            return {
                'statusCode': 404,
                'body': json.dumps('Lobby not found or full')
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Successfully joined the lobby',
                'lobby': deserialize_dynamodb_item(updated_lobby)
            })
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error joining lobby: {str(e)}')
        }

def authenticate(event):
    return 'user123'

def join_lobby(lobby_id, user_id):
    response = table.update_item(
        Key={'id': lobby_id},
        UpdateExpression='SET current_players = current_players + :inc',
        ConditionExpression='current_players < max_players',
        ExpressionAttributeValues={':inc': 1},
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes')