import json
import boto3
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')

def lambda_handler(event, context):
    try:
        # Scan the entire table to get all prompts
        response = prompts_table.scan()
        
        # Extract the prompts from the response
        prompts = response['Items']
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'Prompts retrieved successfully',
                'prompts': prompts
            }),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({
                'message': f'An error occurred: {str(e)}'
            }),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }