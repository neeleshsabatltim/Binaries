import boto3
import json

# Create the Bedrock Runtime client
session = boto3.Session(profile_name="ainativeops-bedrock")
client = session.client("bedrock-runtime", region_name="us-east-1")

# Titan Text Embeddings V2 model ID
model_id = "amazon.titan-embed-text-v2:0"

# Input text to embed
input_text = "DevOps engineers bridge the gap between development and operations teams."



# Construct the payload
payload = {
    "inputText": input_text
}

# Invoke the model
response = client.invoke_model(
    modelId=model_id,
    body=json.dumps(payload),
    contentType="application/json",
    accept="application/json"
)

# Parse and print the embedding
response_body = json.loads(response["body"].read())
embedding = response_body["embedding"]

print("\nTitan Text Embeddings V2 Output:\n")
print(embedding)
 