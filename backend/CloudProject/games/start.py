import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
lobbies_table = dynamodb.Table(os.environ.get('LOBBIES_TABLE', 'Lobbies'))

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")

    try:
        lobby_id = event['pathParameters']['lobbyId']
        
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = authorizer_context.get('user_id')

        if not user_id:
            print("Unable to find user_id in the authorizer context")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'User ID not found in request'})
            }

        print(f"User ID: {user_id}")

        lobby = lobbies_table.get_item(Key={'id': lobby_id})['Item']

        if lobby['creator_id'] != user_id:
            return {
                'statusCode': 403,
                'body': json.dumps({'message': 'Only the lobby creator can start the game'})
            }

        if len(lobby['players']) < 2:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'At least 2 players are required to start the game'})
            }

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
            #dont think we need this'current_prompt': None,
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

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Game started successfully',
                'game_id': game_id,
                'status': 'in_progress'
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error'})
        }
