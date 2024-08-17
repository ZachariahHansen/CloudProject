import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])
lobbies_table = dynamodb.Table(os.environ['LOBBIES_TABLE'])
games_table = dynamodb.Table(os.environ['GAMES_TABLE'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    body = json.loads(event['body'])
    action = body.get('action')
    
    if action == 'ping':
        return handle_ping(connection_id)
    elif action == 'join_lobby':
        return handle_join_lobby(connection_id, body)
    # Add more action handlers as needed
    
    return {
        'statusCode': 400,
        'body': json.dumps('Unknown action')
    }

def handle_ping(connection_id):
    return {
        'statusCode': 200,
        'body': json.dumps('pong')
    }

def handle_join_lobby(connection_id, body):
    lobby_id = body['lobby_id']
    player_name = body['player_name']
    
    # Add player to lobby
    lobbies_table.update_item(
        Key={'id': lobby_id},
        UpdateExpression='SET players = list_append(if_not_exists(players, :empty_list), :new_player)',
        ExpressionAttributeValues={
            ':empty_list': [],
            ':new_player': [{'connection_id': connection_id, 'name': player_name}]
        }
    )
    
    # Broadcast to all players in the lobby
    broadcast_to_lobby(lobby_id, {
        'action': 'player_joined',
        'player_name': player_name
    })
    
    return {
        'statusCode': 200,
        'body': json.dumps('Joined lobby successfully')
    }

def broadcast_to_lobby(lobby_id, message):
    lobby = lobbies_table.get_item(Key={'id': lobby_id})['Item']
    api_client = boto3.client('apigatewaymanagementapi', endpoint_url=os.environ['WEBSOCKET_API_ENDPOINT'])
    
    for player in lobby['players']:
        try:
            api_client.post_to_connection(
                ConnectionId=player['connection_id'],
                Data=json.dumps(message)
            )
        except api_client.exceptions.GoneException:
            print(f"Connection {player['connection_id']} is gone, removing from lobby")
            # Handle disconnected player
