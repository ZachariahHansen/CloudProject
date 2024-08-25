import json
import boto3
import random
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')
games_table = dynamodb.Table('Games')

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
    # Get all prompts
    prompts_response = prompts_table.scan()
    prompts = prompts_response['Items']
    
    if not prompts:
        return response(404, {'message': 'No prompts available'})
    
    # Select a random prompt
    random_prompt = random.choice(prompts)
    
    return response(200, {'prompt_text': random_prompt['text']})