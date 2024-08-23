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
    
    try:
        if message_type == 'lobby_update':
            print("got a lobby update message")
            broadcast_to_all(api_client, {
                'type': 'lobby_update',
                'message': 'A lobby has been updated'
            })
        
        elif message_type == 'lobby_players_update':
            print("got a lobby message update thing")
            lobby_id = message_data['lobby_id']
            broadcast_to_lobby(api_client, lobby_id, {
                'type': 'lobby_update',
                'message': 'The lobby has been updated',
                'lobby_id': lobby_id
            })
        
        elif message_type == 'game_start':
            lobby_id = message_data['lobby_id']
            game_id = message_data['game_id']
            lobby = get_lobby(lobby_id)
            if lobby:
                players = lobby['players']
                prompt_selector = players[0]  # Assuming the first player selects the prompt
                
                for player in players:
                    if player == prompt_selector:
                        send_message_to_user(api_client, player, {
                            'type': 'select_prompt',
                            'game_id': game_id
                        })
                    else:
                        send_message_to_user(api_client, player, {
                            'type': 'waiting_for_prompt',
                            'game_id': game_id
                        })
        
        elif message_type == 'scenario_selected':
            game_id = message_data['game_id']
            broadcast_to_game(api_client, game_id, {
                'type': 'scenario_selected',
                'message': 'The scenario has been selected',
                'game_id': game_id
            })
        
        elif message_type == 'all_answers_submitted':
            game_id = message_data['game_id']
            broadcast_to_game(api_client, game_id, {
                'type': 'advance_screen',
                'message': 'All players have submitted answers',
                'game_id': game_id
            })
        
        elif message_type == 'answers_evaluated':
            game_id = message_data['game_id']
            broadcast_to_game(api_client, game_id, {
                'type': 'answers_evaluated',
                'message': 'Answers have been evaluated',
                'game_id': game_id
            })
        
        elif message_type == 'game_update':
            game_id = message_data['game_id']
            broadcast_to_game(api_client, game_id, {
                'type': 'game_update',
                'message': 'The game has been updated',
                'game_id': game_id
            })
        
        else:
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid message type'})
            }
        
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Messages sent successfully'})
        }
    
    except Exception as e:
        print(f"Error in broadcast: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'message': f'Error in broadcast: {str(e)}'})
        }

def broadcast_to_all(api_client, message):
    connections = get_all_connections()
    for connection in connections:
        send_message(api_client, connection['connectionId'], message)

def broadcast_to_lobby(api_client, lobby_id, message):
    lobby = get_lobby(lobby_id)
    if lobby:
        player_ids = lobby['players']
        connections = get_connections_for_users(player_ids)
        for connection in connections:
            send_message(api_client, connection['connectionId'], message)

def broadcast_to_game(api_client, game_id, message):
    game = get_game(game_id)
    if game:
        player_ids = [player['id'] for player in game['players']]
        connections = get_connections_for_users(player_ids)
        for connection in connections:
            send_message(api_client, connection['connectionId'], message)

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
        response = connections_table.scan()
        return response['Items']
    except ClientError as e:
        print(f"Error retrieving connections: {e}")
        return []

def get_lobby(lobby_id):
    try:
        response = lobbies_table.get_item(Key={'id': lobby_id})
        return response.get('Item')
    except ClientError as e:
        print(f"Error retrieving lobby {lobby_id}: {e}")
        return None

def get_game(game_id):
    try:
        response = games_table.get_item(Key={'id': game_id})
        return response.get('Item')
    except ClientError as e:
        print(f"Error retrieving game {game_id}: {e}")
        return None

def get_connections_for_users(user_ids):
    connections = []
    for user_id in user_ids:
        try:
            # Try to use the UserIdIndex
            response = connections_table.query(
                IndexName='UserIdIndex',
                KeyConditionExpression='userId = :userId',
                ExpressionAttributeValues={':userId': user_id}
            )
            connections.extend(response['Items'])
        except ClientError as e:
            if e.response['Error']['Code'] == 'ValidationException' and 'UserIdIndex' in str(e):
                # If the index is not available, fall back to scanning the table
                print(f"UserIdIndex not available, falling back to scan for user {user_id}")
                response = connections_table.scan(
                    FilterExpression='userId = :userId',
                    ExpressionAttributeValues={':userId': user_id}
                )
                print("hi response is as follows: ", str(response))
                connections.extend(response['Items'])
            else:
                print(f"Error retrieving connection for user {user_id}: {e}")
    return connections

def send_message_to_user(api_client, user_id, message):
    connections = get_connections_for_users([user_id])
    for connection in connections:
        send_message(api_client, connection['connectionId'], message)