import json
import jwt
import boto3
from os import getenv
from botocore.exceptions import ClientError

JWT_SECRET = getenv('JWT_SECRET')
JWT_ALGORITHM = 'HS256'

# Initialize the DynamoDB client
dynamodb = boto3.resource('dynamodb')
users_table = dynamodb.Table('Cloud_Users')

def lambda_handler(event, context):
    if 'authorizationToken' not in event:
        raise Exception('Unauthorized')
    
    auth_header = event['authorizationToken']
    
    # Extract the token from the Authorization header
    if auth_header.startswith('Bearer '):
        token = auth_header.split(' ')[1]
    else:
        token = auth_header  # Fallback in case 'Bearer ' prefix is missing
    
    try:
        decoded_token = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = decoded_token['user_id']
        
        # Fetch user information from DynamoDB
        user_info = get_user_info(user_id)
        
        if user_info is None:
            raise Exception('User not found')
        
        is_admin = user_info['is_admin']
        print(is_admin)
        
        policy = generate_policy(user_id, 'Allow', event['methodArn'], is_admin)
        return policy
    except jwt.ExpiredSignatureError:
        raise Exception('Token expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')
    except Exception as e:
        print(f"Error: {str(e)}")
        raise Exception('Unauthorized')

def get_user_info(user_id):
    try:
        response = users_table.get_item(Key={'id': user_id})
        return response.get('Item')
    except ClientError as e:
        print(f"Error fetching user info: {str(e)}")
        return None

def generate_policy(principal_id, effect, resource, is_admin):
    policy = {
        'principalId': principal_id,
        'policyDocument': {
            'Version': '2012-10-17',
            'Statement': [{
                'Action': 'execute-api:Invoke',
                'Effect': effect,
                'Resource': resource
            }]
        },
        'context': {
            'user_id': principal_id,
            'is_admin': json.dumps(is_admin)  # Ensure this is a JSON-serializable value
        }
    }
    return policy