import json
import boto3

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table('Games')

def lambda_handler(event, context):
    game_id = event['pathParameters']['gameId']
    body = json.loads(event['body'])
    prompt_id = body['prompt_id']
    
    # Update the game with the selected prompt
    games_table.update_item(
        Key={'id': game_id},
        UpdateExpression='SET current_prompt = :prompt',
        ExpressionAttributeValues={':prompt': prompt_id}
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Prompt submitted successfully'})
    }