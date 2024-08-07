import json
import os
import urllib3

# OpenAI API endpoint
OPENAI_API_ENDPOINT = "https://api.openai.com/v1/chat/completions"

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    try:
        # Parse the incoming event
        if isinstance(event['body'], str):
            body = json.loads(event['body'])
        else:
            body = event['body']
        
        game_id = body['game_id']
        round_number = body['round_number']
        prompt = body['prompt']
        player_responses = body['player_responses']

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

            # Prepare the messages for the ChatGPT API
            messages = [
                {"role": "system", "content": "You are an AI evaluating survival scenarios in a game."},
                {"role": "user", "content": f"""Scenario: {prompt}

Player's response: {response_text}

Based on the scenario and the player's response, provide a brief explanation of the outcome and determine if the player would survive or die. Your response should be in JSON format with the following structure:
{{
    "explanation": string,
    "survival": boolean
}}
"""}
            ]

            # Call the ChatGPT API
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json"
            }
            data = {
                "model": "gpt-3.5-turbo",  # or "gpt-4" if you have access
                "messages": messages,
                "max_tokens": 150,
                "temperature": 0.7
            }
            response = http.request(
                'POST',
                OPENAI_API_ENDPOINT,
                body=json.dumps(data).encode('utf-8'),
                headers=headers
            )

            # Parse the API response
            api_response = json.loads(response.data.decode('utf-8'))
            ai_evaluation = json.loads(api_response['choices'][0]['message']['content'])

            # Add the result to the list
            results.append({
                'player_id': player_id,
                'explanation': ai_evaluation['explanation'],
                'survival': ai_evaluation['survival']
            })

        # Prepare the response
        response = {
            'statusCode': 200,
            'body': json.dumps({
                'game_id': game_id,
                'round_number': round_number,
                'results': results
            })
        }

        return response

    except Exception as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }