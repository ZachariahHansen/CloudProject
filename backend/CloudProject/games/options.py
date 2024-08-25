import json

def lambda_handler(event, context):
    # Define the allowed origins, methods, and headers
    allowed_origins = "*"  # Allow all origins. In production, you might want to restrict this.
    allowed_methods = "GET,POST,PUT,DELETE,OPTIONS"
    allowed_headers = "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token"

    # Create the response
    response = {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": allowed_origins,
            "Access-Control-Allow-Methods": allowed_methods,
            "Access-Control-Allow-Headers": allowed_headers,
            "Access-Control-Allow-Credentials": "true"
        },
        'body': json.dumps('OK')
    }

    return response