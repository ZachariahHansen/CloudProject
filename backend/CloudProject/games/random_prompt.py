import json
import boto3
import random
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')
games_table = dynamodb.Table('Games')

def lambda_handler(event, context):
    game_id = event['pathParameters']['gameId']
    
    # Get all prompts
    response = prompts_table.scan()
    prompts = response['Items']
    
    if not prompts:
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'No prompts available'})
        }
    
    # Select a random prompt
    random_prompt = random.choice(prompts)
    
    # Update the game with the selected prompt
    games_table.update_item(
        Key={'id': game_id},
        UpdateExpression='SET current_prompt = :prompt',
        ExpressionAttributeValues={':prompt': random_prompt['id']}
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'prompt': random_prompt['text'],
            'prompt_id': random_prompt['id']
        })
    }