import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
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
    try:
        game_id = event['pathParameters']['gameId']
        body = json.loads(event['body'])
        prompt_text = body['prompt_text']
        
        # Update the game with the selected prompt
        updated_game = games_table.update_item(
            Key={'id': game_id},
            UpdateExpression='SET current_prompt = :prompt',
            ExpressionAttributeValues={':prompt': prompt_text},
            ReturnValues='ALL_NEW'
        )['Attributes']
        
        # Broadcast prompt selection to all players in the game
        broadcast_prompt_selection(game_id, prompt_text)
        
        return response(200, {'message': 'Prompt submitted successfully'})
    except Exception as e:
        print(f"Error: {str(e)}")
        return response(500, {'message': 'Internal server error'})

def broadcast_prompt_selection(game_id, prompt_text):
    try:
        payload = {
            'body': json.dumps({
                'type': 'scenario_selected',
                'game_id': game_id,
                'prompt': prompt_text
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
        print(f"Error broadcasting prompt selection: {str(e)}")