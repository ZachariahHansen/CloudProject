import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
connections_table = dynamodb.Table(os.environ['CONNECTIONS_TABLE'])
lobbies_table = dynamodb.Table(os.environ['LOBBIES_TABLE'])

def lambda_handler(event, context):
    connection_id = event['requestContext']['connectionId']
    
    # Remove the connection ID from the connections table
    connections_table.delete_item(
        Key={
            'connectionId': connection_id
        }
    )
    
    # Remove the player from any lobby they might be in
    # This is a simplified version; you might want to add more logic here
    lobbies_table.update_item(
        UpdateExpression="SET players = list_remove(players, :player)",
        ExpressionAttributeValues={
            ':player': {'connection_id': connection_id}
        }
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Disconnected')
    }