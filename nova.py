import boto3
import json

# Create the Bedrock Runtime client with your AWS profile and region
session = boto3.Session(profile_name="ainativeops-bedrock")
client = session.client("bedrock-runtime", region_name="us-east-1")


#client = boto3.client(service_name="bedrock-runtime")

messages = [
    {
        "role": "user",
        "content": [{"text": "Write a short poem about nature."}]
    }
]

response = client.converse(
    modelId="amazon.nova-lite-v1:0",
    messages=messages,
    inferenceConfig={
        "maxTokens": 512,
        "temperature": 0.7,
        "topP": 0.9
    }
)

print(response["output"]["message"]["content"][0]["text"])