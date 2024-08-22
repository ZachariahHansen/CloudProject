import json
import boto3
from boto3.dynamodb.conditions import Attr
import logging

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
prompts_table = dynamodb.Table('Prompts')

def lambda_handler(event, context):
    logger.info(f"Received event: {json.dumps(event)}")

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

    try:
        # Check if the authorizer context exists
        if 'authorizer' not in event.get('requestContext', {}):
            logger.error("No authorizer context found in the event")
            return response(401, {'message': 'Unauthorized: No valid authentication provided'})

        # Check if the user is an admin
        is_admin = event['requestContext']['authorizer']['is_admin']
        if not is_admin:
            logger.warning("Non-admin user attempted to access prompts")
            return response(403, {'message': 'Access denied. Admin privileges required.'})

        # Scan the entire table to get all prompts
        scan_response = prompts_table.scan()
        
        # Extract the prompts from the response
        prompts = scan_response['Items']
        
        logger.info(f"Retrieved {len(prompts)} prompts successfully")
        return response(200, {
            'message': 'Prompts retrieved successfully',
            'prompts': prompts
        })
    except boto3.exceptions.Boto3Error as e:
        logger.error(f"Boto3 error occurred: {str(e)}")
        return response(500, {'message': 'An error occurred while accessing the database'})
    except json.JSONDecodeError as e:
        logger.error(f"JSON decode error: {str(e)}")
        return response(400, {'message': 'Invalid JSON in request body'})
    except Exception as e:
        logger.error(f"Unexpected error occurred: {str(e)}")
        return response(500, {'message': f'An unexpected error occurred: {str(e)}'})

def response(code, body):
    return {
        "statusCode": code,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,GET"
        },
        "body": json.dumps(body)
    }