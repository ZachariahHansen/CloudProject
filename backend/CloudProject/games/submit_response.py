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

def lambda_handler(event, context):    
    try:
        game_id = event['pathParameters']['gameId']
        
        authorizer_context = event.get('requestContext', {}).get('authorizer', {})
        user_id = authorizer_context.get('user_id')

        if not user_id:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'User ID not found in request'})
            }

        body = json.loads(event['body'])
        response = body.get('response')

        if not response:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Response is required'})
            }

        game = games_table.get_item(Key={'id': game_id})['Item']

        player = next((p for p in game['players'] if p['id'] == user_id), None)
        if not player:
            return {
                'statusCode': 403,
                'body': json.dumps({'message': 'User is not a player in this game'})
            }

        if player['response']:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Player has already submitted a response'})
            }

        player['response'] = response
        game['responses_submitted'] += 1

        all_responses_submitted = game['responses_submitted'] == len(game['players'])

        if all_responses_submitted:
            # All players have submitted responses, trigger AI evaluation
            game['status'] = 'evaluating'
            
            # Prepare data for AI evaluation
            evaluation_data = {
                'game_id': game_id,
                'round_number': game['current_round'],
                'prompt': game['current_prompt'],
                'player_responses': [
                    {'player_id': p['id'], 'response': p['response']}
                    for p in game['players']
                ]
            }
            
            # Invoke AI evaluation Lambda function
            ai_function_name = os.environ.get('AI_EVALUATION_FUNCTION')
            lambda_client.invoke(
                FunctionName=ai_function_name,
                InvocationType='Event',
                Payload=json.dumps(evaluation_data, cls=DecimalEncoder)
            )
            
            # Broadcast that all responses have been submitted
            broadcast_all_responses_submitted(game_id)

        game['updated_at'] = datetime.utcnow().isoformat()
        games_table.put_item(Item=game)

        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Response submitted successfully',
                'game_status': game['status'],
                'all_responses_submitted': all_responses_submitted
            })
        }

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal server error'})
        }

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