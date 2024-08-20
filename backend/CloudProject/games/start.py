import json
import boto3
import os
import uuid
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
lobbies_table = dynamodb.Table(os.environ.get('LOBBIES_TABLE', 'Lobbies'))

def lambda_handler(event, context):
    try:
        lobby_id = event['pathParameters']['lobbyId']
        user_id = event['requestContext']['authorizer']['lambda']['user_id']

        # Get the lobby
        lobby = lobbies_table.get_item(Key={'id': lobby_id})['Item']

        # Check if the user is the creator of the lobby
        if lobby['creator_id'] != user_id:
            return {
                'statusCode': 403,
                'body': json.dumps({'message': 'Only the lobby creator can start the game'})
            }

        # Check if there are at least 2 players
        if len(lobby['players']) < 2:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'At least 2 players are required to start the game'})
            }

        # Create a new game
        game_id = str(uuid.uuid4())
        current_time = datetime.utcnow().isoformat()
        
        game = {
            'id': game_id,
            'lobby_id': lobby_id,
            'players': lobby['players'],
            'current_round': 1,
            'total_rounds': 3,
            'status': 'in_progress',
            'created_at': current_time,
            'updated_at': current_time
        }

        # Save the game to the database
        games_table.put_item(Item=game)

        # Update the lobby status
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