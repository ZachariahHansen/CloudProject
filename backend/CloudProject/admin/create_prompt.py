import json
import boto3
import uuid
import logging
from botocore.exceptions import ClientError

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')

def lambda_handler(event, context):
    # Log the incoming event
    logger.info(f"Received event: {json.dumps(event)}")

    # Handle OPTIONS request
    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,GET',
                'Access-Control-Max-Age': '3600',
            },
            'body': json.dumps('OK')
        }

    # Extract user information from the authorizer context
    try:
        is_admin = event['requestContext']['authorizer']['is_admin']
        logger.info(f"User is_admin: {is_admin}")
    except KeyError:
        logger.error("Failed to extract is_admin from authorizer context")
        return response(500, {'message': 'Internal server error: Failed to validate admin status'})

    # Check if the user is an admin
    if not is_admin:
        logger.warning("Non-admin user attempted to create a prompt")
        return response(403, {'message': 'Access denied. Admin privileges required.'})

    # If the user is an admin, proceed with creating the prompt
    try:
        body = json.loads(event['body'])
        prompt_text = body['text']
        
        # Validate prompt text
        if not prompt_text or not isinstance(prompt_text, str):
            logger.error("Invalid prompt text")
            return response(400, {'message': 'Invalid prompt text. Must be a non-empty string.'})
        
        # Create new prompt
        new_prompt = {
            'id': str(uuid.uuid4()),
            'text': prompt_text
        }
        
        logger.info(f"Attempting to create new prompt: {new_prompt}")
        
        prompts_table.put_item(Item=new_prompt)
        
        logger.info("Prompt created successfully")
        
        return response(201, {'message': 'Prompt created successfully', 'prompt': new_prompt})
    except KeyError as e:
        logger.error(f"KeyError: {str(e)}")
        return response(400, {'message': 'Invalid request body. "text" field is required.'})
    except ClientError as e:
        logger.error(f"DynamoDB ClientError: {str(e)}")
        return response(500, {'message': 'Failed to create prompt in database'})
    except json.JSONDecodeError as e:
        logger.error(f"JSON Decode Error: {str(e)}")
        return response(400, {'message': 'Invalid JSON in request body'})
    except Exception as e:
        logger.error(f"Unexpected error: {str(e)}")
        return response(500, {'message': 'An unexpected error occurred'})

def response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"
        },
        "body": json.dumps(body)
    }