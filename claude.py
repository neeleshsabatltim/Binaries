import boto3
import json
import os
from dotenv import load_dotenv
# Load environment variables from .env file
load_dotenv()
# Create Bedrock client using credentials from environment
client = boto3.client(
    "bedrock-runtime",
    region_name="us-east-1",
    aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY")
)
# Define payload for Claude Sonnet 4
payload = {
    "anthropic_version": "bedrock-2023-05-31",
    "messages": [
        {
            "role": "user",
            "content": "What is Amazon Bedrock and how to deploy it?"
        }
    ],
    "max_tokens": 500
}
# Invoke the model
response = client.invoke_model(
    modelId="us.anthropic.claude-sonnet-4-20250514-v1:0",
    contentType="application/json",
    accept="application/json",
    body=json.dumps(payload)
)
# Parse and print the result
result = json.loads(response["body"].read())
print(result["content"][0]["text"])
 
 