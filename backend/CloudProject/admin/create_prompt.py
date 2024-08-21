import json
import boto3
import uuid
from boto3.dynamodb.conditions import Attr

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')

def lambda_handler(event, context):
    # Extract user information from the authorizer context
    is_admin = event['requestContext']['authorizer']['is_admin']
    
    # Check if the user is an admin
    if not is_admin:
        return {
            'statusCode': 403,
            'body': json.dumps({'message': 'Access denied. Admin privileges required.'})
        }
    
    # If the user is an admin, proceed with creating the prompt
    try:
        body = json.loads(event['body'])
        prompt_text = body['text']
        
        # Create new prompt
        new_prompt = {
            'id': str(uuid.uuid4()),
            'text': prompt_text
        }
        
        prompts_table.put_item(Item=new_prompt)
        
        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'Prompt created successfully', 'prompt': new_prompt}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except KeyError:
        return {
            'statusCode': 400,
            'body': json.dumps({'message': 'Invalid request body. "text" field is required.'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'An error occurred: {str(e)}'}),
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            }
        }