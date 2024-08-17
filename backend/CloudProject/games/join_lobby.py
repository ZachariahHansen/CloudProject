import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
lobbies_table = dynamodb.Table(os.environ['LOBBIES_TABLE'])
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    lobby_id = event['pathParameters']['lobbyId']
    player_name = body['player_name']
    connection_id = body['connection_id']  # Assuming this is passed from the client

    try:
        # Update Lobbies table
        response = lobbies_table.update_item(
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

        return {
            'statusCode': 200,
            'body': json.dumps('Joined lobby successfully')
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error joining lobby: {str(e)}')
        }