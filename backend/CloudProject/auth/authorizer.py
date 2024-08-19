import json
import jwt
from os import getenv

JWT_SECRET = getenv('JWT_SECRET')
JWT_ALGORITHM = 'HS256'

def lambda_handler(event, context):
    token = event['authorizationToken']
    
    try:
        decoded_token = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        user_id = decoded_token['user_id']
        is_admin = decoded_token.get('is_admin', False)
        
        policy = generate_policy(user_id, 'Allow', event['methodArn'], is_admin)
        return policy
    except jwt.ExpiredSignatureError:
        raise Exception('Token expired')
    except jwt.InvalidTokenError:
        raise Exception('Invalid token')

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
            'is_admin': is_admin
        }
    }
    return policy