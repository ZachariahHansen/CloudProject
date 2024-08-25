import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
lobbies_table = dynamodb.Table(os.environ.get('LOBBIES_TABLE', 'Lobbies'))
lambda_client = boto3.client('lambda')

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
    print(f"Received event: {json.dumps(event)}")

    try:
        lobby_id = event['pathParameters']['lobbyId']
        
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = authorizer_context.get('user_id')

        if not user_id:
            print("Unable to find user_id in the authorizer context")
            return response(400, {'message': 'User ID not found in request'})

        print(f"User ID: {user_id}")

        lobby = lobbies_table.get_item(Key={'id': lobby_id})['Item']

        if lobby['creator_id'] != user_id:
            return response(403, {'message': 'Only the lobby creator can start the game'})

        if len(lobby['players']) < 2:
            return response(400, {'message': 'At least 2 players are required to start the game'})

        game_id = str(uuid.uuid4())
        current_time = datetime.utcnow().isoformat()
        
        game = {
            'id': game_id,
            'lobby_id': lobby_id,
            'players': [
                {
                    'id': player_id,
                    'prompt': '',
                    'response': '',
                    'status': 'alive'
                } for player_id in lobby['players']
            ],
            'current_round': 1,
            'total_rounds': 3,
            'status': 'in_progress',
            'responses_submitted': 0,
            'created_at': current_time,
            'updated_at': current_time
        }

        games_table.put_item(Item=game)

        lobbies_table.update_item(
            Key={'id': lobby_id},
            UpdateExpression='SET #status = :status, game_id = :game_id',
            ExpressionAttributeNames={'#status': 'status'},
            ExpressionAttributeValues={':status': 'in_game', ':game_id': game_id}
        )

        # Broadcast game start to all players in the lobby
        broadcast_game_start(lobby_id, game_id)

        return response(200, {
            'message': 'Game started successfully',
            'game_id': game_id,
            'status': 'in_progress'
        })

    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'message': 'Internal server error'})

def broadcast_game_start(lobby_id, game_id):
    try:
        payload = {
            'body': json.dumps({
                'type': 'game_start',
                'lobby_id': lobby_id,
                'game_id': game_id
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
        print(f"Error broadcasting game start: {str(e)}")