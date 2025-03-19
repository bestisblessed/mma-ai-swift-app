# from openai import OpenAI
# client = OpenAI()

# question = "Tell me about Max Holloway and all of his stats."
# # question = "Tell me about Paddy Pimblett and Michael Chandler and generate me a tale of the tape between them in a visualization."
# # question = "Who has the best win-loss record?"

# response = client.responses.create(
#     model="gpt-4o-mini",
#     # model="o3-mini",
#     input=question,
#     tools=[{
#         "type": "file_search",
#         "vector_store_ids": ["vs_67da64d9439c8191bdb5eb3a7f6e9a44"] # Fighter Info Vector Store
#     }],
#     include=["file_search_call.results"]
# )
# print(response)



from openai import OpenAI

client = OpenAI()

# question = "Tell me about Max Holloway and all of his stats."
# question = "Tell me about Conor McGregor and all of his stats."
question = "Tell me about Paddy Pimblett and Michael Chandler and generate me a tale of the tape between them in a visualization."
# question = "Who has the best win-loss record?"

response = client.responses.create(
    model="gpt-4o-mini",
    input=f"Extract the fighter name and weight class from this question: '{question}'",
)

# print(response)
extracted_text = response.output[0].content[0].text.strip()
print(f"Extracted: {extracted_text}")

filters = []
for line in extracted_text.split("\n"):
    if "Fighter:" in line:
        filters.append({"type": "eq", "key": "Fighter", "value": line.replace("Fighter:", "").strip()})
    elif "Weight Class:" in line:
        filters.append({"type": "eq", "key": "Weight Class", "value": line.replace("Weight Class:", "").strip()})

request_payload = {
    # "model": "gpt-4o-mini",
    "model": "o3-mini",
    "input": question,
    "instructions": """You are an MMA data assistant with access to a vector database of fighter information. 
                    Your goal is to help answer questions about MMA fighters, including their records, stats, and background. 
                    Use the vector store to retrieve the most relevant information before responding. 
                    Always provide accurate and concise answers based on the retrieved data.""",
    "tools": [{
        "type": "file_search",
        "vector_store_ids": ["vs_67da64d9439c8191bdb5eb3a7f6e9a44"],
    }],
    "include": ["file_search_call.results"]
}

if filters:
    request_payload["tools"][0]["filters"] = {"type": "and", "filters": filters}

response = client.responses.create(**request_payload)
for item in response.output:
    if hasattr(item, 'content') and item.content:
        print(item.content[0].text)
        break
