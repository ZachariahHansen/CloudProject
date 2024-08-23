import json
import boto3
from decimal import Decimal
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Lobbies')
lambda_client = boto3.client('lambda')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def deserialize_dynamodb_item(item):
    return json.loads(json.dumps(item, default=decimal_default))

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['principalId']
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
        
        # Broadcast the lobby update to all players in the lobby
        broadcast_lobby_update(lobby_id, user_id)
        
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

def join_lobby(lobby_id, user_id):
    response = table.update_item(
        Key={'id': lobby_id},
        UpdateExpression='SET current_players = current_players + :inc, players = list_append(if_not_exists(players, :empty_list), :new_player)',
        ConditionExpression='current_players < max_players AND (NOT contains(players, :user_id))',
        ExpressionAttributeValues={
            ':inc': 1,
            ':empty_list': [],
            ':new_player': [user_id],
            ':user_id': user_id
        },
        ReturnValues='ALL_NEW'
    )
    return response.get('Attributes')

def broadcast_lobby_update(lobby_id, new_player_id):
    try:
        print("gonna try and broadcast lobby update now")
        payload = {
            'body': json.dumps({
                'type': 'lobby_players_update',
                'lobby_id': lobby_id,
                'new_player_id': new_player_id
            }),
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
    except Exception as e:
        print(f"Error broadcasting lobby update: {str(e)}")