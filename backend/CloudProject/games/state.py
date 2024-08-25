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

def response(status_code, body):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Access-Control-Allow-Methods': 'OPTIONS,GET'
        },
        'body': json.dumps(body, cls=DecimalEncoder)
    }

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    game_id = event['pathParameters']['gameId']
    
    user_id = None
    if 'requestContext' in event and 'authorizer' in event['requestContext']:
        authorizer = event['requestContext']['authorizer']
        if isinstance(authorizer, dict):
            if 'lambda' in authorizer:
                user_id = authorizer['lambda'].get('user_id')
            else:
                user_id = authorizer.get('user_id')

    if not user_id:
        return response(400, {'message': 'Unable to retrieve user ID from authorizer', 'event': event})

    try:
        game_response = games_table.get_item(Key={'id': game_id})
        
        if 'Item' not in game_response:
            return response(404, {'message': 'Game not found'})
        
        game = game_response['Item']
        
        is_participant = any(player['id'] == user_id for player in game['players'])
        
        if not is_participant:
            return response(403, {'message': 'You are not a participant in this game'})
        
        game_state = {
            'id': game['id'],
            'status': game['status'],
            'current_round': game.get('current_round', 1),
            'total_rounds': game.get('total_rounds', 3),
            'players': game['players'],
            'current_prompt': game.get('current_prompt', None),
            'timer': game.get('timer', None)
        }
        
        return response(200, game_state)
    
    except ClientError as e:
        print(e.response['Error']['Message'])
        return response(500, {'message': 'Internal server error'})