import json
import boto3
import random
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')
games_table = dynamodb.Table('Games')

def lambda_handler(event, context):    
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
    
    return {
        'statusCode': 200,
        'body': json.dumps({
            'prompt_text': random_prompt['text']
        })
    }