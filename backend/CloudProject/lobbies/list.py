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
    user_id = authenticate(event)
    if not user_id:
        return {
            'statusCode': 401,
            'body': json.dumps('Unauthorized')
        }
    try:
        lobbies = scan_lobbies()
        
        return {
            'statusCode': 200,
            'body': json.dumps({'lobbies': lobbies})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error listing lobbies: {str(e)}')
        }

def authenticate(event):
    # The authorizer adds the user information to the requestContext
    request_context = event.get('requestContext', {})
    authorizer = request_context.get('authorizer', {})
    return authorizer.get('user_id')

def scan_lobbies():
    response = table.scan()
    items = response.get('Items', [])
    
    return [deserialize_dynamodb_item(item) for item in items if item]