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
    user_id = authenticate(event)
    if not user_id:
        return response(401, 'Unauthorized')

    try:
        lobby_id = event['pathParameters']['lobbyId']
        
        updated_lobby = leave_lobby(lobby_id, user_id)
        
        if not updated_lobby:
            return response(404, 'Lobby not found or user not in lobby')
        
        return response(200, {
            'message': 'Successfully left the lobby',
            'lobby': deserialize_dynamodb_item(updated_lobby)
        })
    except Exception as e:
        return response(500, f'Error leaving lobby: {str(e)}')

def authenticate(event):
    return 'user123'

def leave_lobby(lobby_id, user_id):
    response = table.update_item(
        Key={'id': lobby_id},
        UpdateExpression='SET current_players = current_players - :dec',
        ConditionExpression='current_players > :zero',
        ExpressionAttributeValues={':dec': 1, ':zero': 0},
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes')