import json
import boto3
import os

# Initialize the Bedrock client
bedrock = boto3.client('bedrock-runtime')

def lambda_handler(event, context):
    try:
        # Parse the incoming event
        body = json.loads(event['body'])
        game_id = body['game_id']
        round_number = body['round_number']
        prompt = body['prompt']
        player_responses = body['player_responses']

        # Prepare the results
        results = []

        # Process each player's response
        for player_response in player_responses:
            player_id = player_response['player_id']
            response_text = player_response['response']

            # Prepare the prompt for the AI
            ai_prompt = f"""Scenario: {prompt}

Player's response: {response_text}

Based on the scenario and the player's response, provide a brief explanation of the outcome and determine if the player would survive or die. Your response should be in JSON format with the following structure:
{{
    "explanation": string,
    "survival": boolean
}}
"""

            # Call the AI service (Amazon Bedrock)
            ai_response = bedrock.invoke_model(
                modelId='anthropic.claude-v2',  # or whichever model you're using
                contentType='application/json',
                accept='application/json',
                body=json.dumps({
                    "prompt": ai_prompt,
                    "max_tokens_to_sample": 300,
                    "temperature": 0.7,
                    "top_p": 1,
                    "top_k": 250,
                    "stop_sequences": ["\n\nHuman:"],
                    "anthropic_version": "bedrock-2023-05-31"
                })
            )

            # Parse the AI response
            ai_result = json.loads(ai_response['body'].read().decode())
            ai_evaluation = json.loads(ai_result['completion'])

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
            'body': json.dumps({'error': 'Internal server error'})
        }