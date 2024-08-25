import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('Lobbies')

def decimal_default(obj):
    if isinstance(obj, Decimal):
        return int(obj)
    raise TypeError

def deserialize_dynamodb_item(item):
    return json.loads(json.dumps(item, default=decimal_default))

def lambda_handler(event, context):
    # Handle OPTIONS request
    if event['httpMethod'] == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
                'Access-Control-Allow-Methods': 'OPTIONS,GET'
            },
            'body': json.dumps('OK')
        }

    user_id = authenticate(event)
    if not user_id:
        return response(401, 'Unauthorized')

    try:
        lobbies = scan_lobbies()
        return response(200, {'lobbies': lobbies})
    except Exception as e:
        return response(500, f'Error listing lobbies: {str(e)}')

def authenticate(event):
    # The authorizer adds the user information to the requestContext
    request_context = event.get('requestContext', {})
    authorizer = request_context.get('authorizer', {})
    return authorizer.get('user_id')

def scan_lobbies():
    response = table.scan()
    items = response.get('Items', [])
    return [deserialize_dynamodb_item(item) for item in items if item]

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