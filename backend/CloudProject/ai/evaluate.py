import json
import os
import urllib3
import boto3

# OpenAI API endpoint
OPENAI_API_ENDPOINT = "https://api.openai.com/v1/chat/completions"

dynamodb = boto3.resource('dynamodb')
games_table = dynamodb.Table(os.environ.get('GAMES_TABLE', 'Games'))
lambda_client = boto3.client('lambda')

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        # Parse the incoming event
        body = event if isinstance(event, dict) else json.loads(event)
        
        game_id = body['game_id']
        round_number = body['round_number']
        prompt = body['prompt']
        player_responses = body['player_responses']
        print("player_responses found: ", player_responses)

        # Get the API key from environment variable
        api_key = os.environ['OPENAI_API_KEY']

        # Prepare the results
        results = []

        # Initialize urllib3 PoolManager
        http = urllib3.PoolManager()

        # Process each player's response
        for player_response in player_responses:
            player_id = player_response['player_id']
            response_text = player_response['response']
            print("response_text found: ", response_text)
            print("prompt found: ", prompt)
            print("player_id found: ", player_id)

            # Prepare the messages for the ChatGPT API
            messages = [
                {"role": "system", "content": "You are the 'Arbiter of Fate,' a witty and slightly sarcastic AI tasked with determining the survival of players in ridiculous scenarios. Your job is to humorously explain why players live or die based on their choices."},
                {"role": "user", "content": f"""
Evaluate the player's response with humor and wit. Determine if they survive or perish based on their actions. Your explanation should be brief and amusing. Then provide a boolean indicating their survival.

Here's an example of the format I'm looking for:

{{
    "explanation": "Ah, using a banana as a boomerang to knock out the hungry tiger? Creative, but fruitless. The tiger, amused by your potassium-powered projectile, decides you're too entertaining to eat. You live to go bananas another day!",
    "status": "dead"
}}

Now, give me your evaluation for this player's response:
                 
Scenario: {prompt}

Player's response: {response_text}
"""}
            ]
            print("calling chatgpt api")
            # Call the ChatGPT API
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            data = {
                "model": "gpt-4o-mini",
                "messages": messages,
                "max_tokens": 200,
                "temperature": 0.7
            }
            print("going to call api now")
            try:
                response = http.request(
                    'POST',
                OPENAI_API_ENDPOINT,
                body=json.dumps(data).encode('utf-8'),
                    headers=headers
                )
            except Exception as e:
                print(f"Error calling ChatGPT API: {e}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': 'Failed to call ChatGPT API'})
                }

            try:
                print("response found: ", response)
                # Parse the API response
                api_response = json.loads(response.data.decode('utf-8'))
                print("api_response found: ", api_response)
                ai_evaluation = json.loads(api_response['choices'][0]['message']['content'])
                print("ai_evaluation found: ", ai_evaluation)
            except Exception as e:
                print(f"Error parsing ChatGPT API response: {e}")
                return {
                    'statusCode': 500,
                    'body': json.dumps({'error': 'Failed to parse ChatGPT API response'})
                }

            # Add the result to the list
            results.append({
                'player_id': player_id,
                'explanation': ai_evaluation['explanation'],
                'status': ai_evaluation['status']
            })
            print("results found: ", results)

        # Update the game state in DynamoDB
        game = games_table.get_item(Key={'id': game_id})['Item']
        game['status'] = 'round_complete'
        game['current_round_results'] = results
        game['rounds_completed'] = game.get('rounds_completed', 0) + 1

        for player in game['players']:
            player_result = next(r for r in results if r['player_id'] == player['id'])
            player['status'] = player_result['status']
            player['explanation'] = player_result['explanation']
            player['rounds_survived'] = player.get('rounds_survived', 0) + (1 if player_result['status'] else 0)

        if game['rounds_completed'] == 3:
            game['status'] = 'game_complete'
            game['winners'] = [
                player['id'] for player in game['players'] 
                if player['rounds_survived'] == max(p['rounds_survived'] for p in game['players'])
            ]

        games_table.put_item(Item=game)

        # Broadcast that AI evaluation is complete
        broadcast_evaluation_complete(game_id, results, game['status'])

        # Prepare the response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'game_id': game_id,
                'round_number': round_number,
                'results': results,
                'game_status': game['status']
            })
        }

        return response

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def broadcast_evaluation_complete(game_id, results, game_status):
    try:
        payload = {
            'body': json.dumps({
                'type': 'answers_evaluated',
                'game_id': game_id,
                'results': results,
                'game_status': game_status
            }),
            'requestContext': {
                'domainName': os.environ['WEBSOCKET_API_DOMAIN'],
                'stage': os.environ['WEBSOCKET_API_STAGE']
            }
        }
        
        lambda_client.invoke(
            FunctionName=os.environ['BROADCAST_FUNCTION_NAME'],
            InvocationType='Event',
            Payload=json.dumps(payload)
        )
    except Exception as e:
        print(f"Error broadcasting evaluation complete: {str(e)}")