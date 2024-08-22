import os
import json
import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])
games_table = dynamodb.Table(os.environ['GAMES_TABLE'])
lobbies_table = dynamodb.Table(os.environ['LOBBIES_TABLE'])

def lambda_handler(event, context):
    domain_name = event['requestContext']['domainName']
    stage = event['requestContext']['stage']
    api_client = boto3.client('apigatewaymanagementapi', endpoint_url=f'https://{domain_name}/{stage}')

    message_data = json.loads(event['body'])
    message_type = message_data['type']
    
    if message_type == 'lobby_update':
        broadcast_to_all(api_client, {'type': 'lobby_update', 'message': 'A lobby has been updated'})
    
    elif message_type == 'lobby_players_update':
        lobby_id = message_data['lobby_id']
        broadcast_to_lobby(api_client, lobby_id, {'type': 'lobby_update', 'message': 'The lobby has been updated'})
    
    elif message_type == 'game_start':
        lobby_id = message_data['lobby_id']
        game_id = message_data['game_id']
        players = get_lobby_players(lobby_id)
        prompt_selector = players[0]  # Assuming the first player selects the prompt
        
        for player in players:
            if player == prompt_selector:
                send_message(api_client, player, {'type': 'select_prompt', 'game_id': game_id})
            else:
                send_message(api_client, player, {'type': 'waiting_for_prompt', 'game_id': game_id})
    
    elif message_type == 'scenario_selected':
        game_id = message_data['game_id']
        broadcast_to_game(api_client, game_id, {'type': 'scenario_selected', 'message': 'The scenario has been selected'})
    
    elif message_type == 'all_answers_submitted':
        game_id = message_data['game_id']
        broadcast_to_game(api_client, game_id, {'type': 'advance_screen', 'message': 'All players have submitted answers'})
    
    elif message_type == 'answers_evaluated':
        game_id = message_data['game_id']
        broadcast_to_game(api_client, game_id, {'type': 'answers_evaluated', 'message': 'Answers have been evaluated'})
    
    return {'statusCode': 200, 'body': 'Messages sent successfully'}

def broadcast_to_all(api_client, message):
    connections = get_all_connections()
    for connection_id in connections:
        send_message(api_client, connection_id, message)

def broadcast_to_lobby(api_client, lobby_id, message):
    players = get_lobby_players(lobby_id)
    for player in players:
        send_message(api_client, player, message)

def broadcast_to_game(api_client, game_id, message):
    players = get_game_players(game_id)
    for player in players:
        send_message(api_client, player, message)

def send_message(api_client, connection_id, message):
    try:
        api_client.post_to_connection(
            ConnectionId=connection_id,
            Data=json.dumps(message).encode('utf-8')
        )
    except ClientError as e:
        if e.response['Error']['Code'] == 'GoneException':
            connections_table.delete_item(Key={'connectionId': connection_id})
        else:
            print(f"Error sending message to {connection_id}: {e}")

def get_all_connections():
    try:
        response = connections_table.scan(ProjectionExpression='connectionId')
        return [item['connectionId'] for item in response['Items']]
    except ClientError as e:
        print(f"Error retrieving connections: {e}")
        return []

def get_lobby_players(lobby_id):
    try:
        response = lobbies_table.get_item(Key={'id': lobby_id})
        return response['Item']['players']
    except ClientError as e:
        print(f"Error retrieving lobby players: {e}")
        return []

def get_game_players(game_id):
    try:
        response = games_table.get_item(Key={'id': game_id})
        return response['Item']['players']
    except ClientError as e:
        print(f"Error retrieving game players: {e}")
        return []