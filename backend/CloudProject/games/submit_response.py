import json
import boto3
import os
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
lambda_client = boto3.client('lambda')

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
        'body': json.dumps(body)
    }

def lambda_handler(event, context):    
    try:
        game_id = event['pathParameters']['gameId']
        
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = authorizer_context.get('user_id')

        if not user_id:
            return response(400, {'message': 'User ID not found in request'})

        body = json.loads(event['body'])
        player_response = body.get('response')

        if not player_response:
            return response(400, {'message': 'Response is required'})

        game = games_table.get_item(Key={'id': game_id})['Item']

        player = next((p for p in game['players'] if p['id'] == user_id), None)
        if not player:
            return response(403, {'message': 'User is not a player in this game'})

        if player['response']:
            return response(400, {'message': 'Player has already submitted a response'})

        player['response'] = player_response
        game['responses_submitted'] += 1

        all_responses_submitted = game['responses_submitted'] == len(game['players'])

        if all_responses_submitted:
            game['status'] = 'evaluating'
            
            evaluation_data = {
                'game_id': game_id,
                'round_number': game['current_round'],
                'prompt': game['current_prompt'],
                'player_responses': [
                    {'player_id': p['id'], 'response': p['response']}
                    for p in game['players']
                ]
            }
            
            ai_function_name = os.environ.get('AI_EVALUATION_FUNCTION')
            lambda_client.invoke(
                FunctionName=ai_function_name,
                InvocationType='Event',
                Payload=json.dumps(evaluation_data, cls=DecimalEncoder)
            )
            
            broadcast_all_responses_submitted(game_id)

        game['updated_at'] = datetime.utcnow().isoformat()
        games_table.put_item(Item=game)

        return response(200, {
            'message': 'Response submitted successfully',
            'game_status': game['status'],
            'all_responses_submitted': all_responses_submitted
        })

    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'message': 'Internal server error'})

def broadcast_all_responses_submitted(game_id):
    try:
        payload = {
            'body': json.dumps({
                'type': 'all_answers_submitted',
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
        print(f"Error broadcasting all responses submitted: {str(e)}")