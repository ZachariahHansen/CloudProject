import json
import boto3
from boto3.dynamodb.conditions import Key
from botocore.exceptions import ClientError
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table('Games')

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

def lambda_handler(event, context):
    # Log the entire event for debugging
    print("Received event:", json.dumps(event))

    # Extract game_id from the path parameters
    game_id = event['pathParameters']['gameId']
    
    # Try to extract user_id from the authorizer context
    user_id = None
    if 'requestContext' in event and 'authorizer' in event['requestContext']:
        authorizer = event['requestContext']['authorizer']
        if isinstance(authorizer, dict):
            if 'lambda' in authorizer:
                user_id = authorizer['lambda'].get('user_id')
            else:
                user_id = authorizer.get('user_id')

    if not user_id:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Unable to retrieve user ID from authorizer', 'event': event})
        }

    try:
        # Retrieve the game from DynamoDB
        response = games_table.get_item(Key={'id': game_id})
        
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'message': 'Game not found'})
            }
        
        game = response['Item']
        
        # Check if the user is a participant in the game
        # Players list object: [{'id': '543e48a4-a04f-470d-a54f-cfa91433034c', 'prompt': '', 'response': '', 'status': 'alive'}, {'id': '91e6ffb9-b00c-4dc8-ae63-407d1ee11a98', 'prompt': '', 'response': '', 'status': 'alive'}]
        is_participant = False
        for player in game['players']:
            if player['id'] == user_id:
                is_participant = True
                break
        
        if not is_participant:
            return {
                'statusCode': 403,
                'body': json.dumps({'message': 'You are not a participant in this game'})
            }
            
        
        # Prepare the response
        game_state = {
            'id': game['id'],
            'status': game['status'],
            'current_round': game.get('current_round', 1),
            'total_rounds': game.get('total_rounds', 3),
            'players': game['players'],
            'current_prompt': game.get('current_prompt', None),
            'timer': game.get('timer', None)
        }
        
        return {
            'statusCode': 200,
            'body': json.dumps(game_state, cls=DecimalEncoder)
        }
    
    except ClientError as e:
        print(e.response['Error']['Message'])
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error'})
        }