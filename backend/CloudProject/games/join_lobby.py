import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
lobbies_table = dynamodb.Table(os.environ['LOBBIES_TABLE'])
lambda_client = boto3.client('lambda')

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
    body = json.loads(event['body'])
    lobby_id = event['pathParameters']['lobbyId']
    player_name = body['player_name']
    connection_id = body['connection_id']  # Assuming this is passed from the client

    try:
        # Update Lobbies table
        lobbies_table.update_item(
            Key={'id': lobby_id},
            UpdateExpression='SET players = list_append(if_not_exists(players, :empty_list), :new_player)',
            ExpressionAttributeValues={
                ':empty_list': [],
                ':new_player': [{'connection_id': connection_id, 'name': player_name}]
            },
            ReturnValues="UPDATED_NEW"
        )

        # Trigger WebSocket broadcast
        lambda_client.invoke(
            FunctionName=os.environ['WEBSOCKET_DEFAULT_FUNCTION'],
            InvocationType='Event',
            Payload=json.dumps({
                'lobby_id': lobby_id,
                'message': {
                    'action': 'player_joined',
                    'player_name': player_name
                }
            })
        )

        return response(200, 'Joined lobby successfully')
    except Exception as e:
        return response(500, f'Error joining lobby: {str(e)}')