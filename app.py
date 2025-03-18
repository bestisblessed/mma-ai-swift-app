import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import json
import uuid
from dotenv import load_dotenv
import logging
import time

# Configure logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

# Initialize OpenAI client with API key from environment variable
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    logger.error("No OpenAI API key found in environment variables")
else:
    logger.info(f"API key loaded (starts with: {api_key[:5]}...)")

client = OpenAI(api_key=api_key)

# Store conversation threads
threads = {}

# Assistant ID from your assistants.py script
ASSISTANT_ID = "asst_QIEMCdBCqsX4al7O4Jg2Jjpx"

@app.route('/')
def home():
    return "Flask App is Running! API is available at /api/chat and /api/examples"

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_input = data.get('message', '')
        conversation_id = data.get('conversation_id')
        
        logger.info(f"Received message: '{user_input}'")
        logger.info(f"Conversation ID: {conversation_id}")
        
        # Create new thread if none exists
        if not conversation_id or conversation_id not in threads:
            # Create a new thread in the Assistants API
            thread = client.beta.threads.create()
            thread_id = thread.id
            conversation_id = thread_id  # Use thread_id as conversation_id
            threads[conversation_id] = thread_id
            logger.info(f"Created new thread with ID: {thread_id}")
        else:
            thread_id = threads[conversation_id]
        
        # Add user message to thread
        client.beta.threads.messages.create(
            thread_id=thread_id,
            role="user",
            content=user_input
        )
        
        run = client.beta.threads.runs.create(
            thread_id=thread_id,
            assistant_id=ASSISTANT_ID
        ) 

        # Wait for completion
        while run.status not in ["completed", "failed", "cancelled", "expired"]:
            time.sleep(10)  # Poll every second
            run = client.beta.threads.runs.retrieve(
                thread_id=thread_id, 
                run_id=run.id
            )
            logger.info(f"Run status: {run.status}")
        
        if run.status != "completed":
            logger.error(f"Run failed with status: {run.status}")
            return jsonify({
                "error": f"Assistant run failed with status: {run.status}",
                "conversation_id": conversation_id
            }), 500
        
        # Get the assistant's response
        messages = client.beta.threads.messages.list(thread_id=thread_id)
        
        # Get the most recent assistant message
        content = ""
        for msg in messages.data:
            if msg.role == "assistant":
                for content_item in msg.content:
                    if content_item.type == "text":
                        content = content_item.text.value
                        break
                if content:  # If we found content, break out of the loop
                    break
        
        if not content:
            content = "Sorry, I couldn't retrieve the information you requested."
        
        logger.info(f"Received response from Assistant: '{content[:50]}...'")
        
        # Return response with conversation ID
        return jsonify({
            "response": content,
            "conversation_id": conversation_id
        })
        
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": f"Server error: {str(e)}"}), 500

@app.route('/api/examples', methods=['GET'])
def get_examples():
    examples = [
        "Tell me about Max Holloway's most recent 5 fights and details of the outcomes",
        "Analyze and research Paddy Pimblett and Michael Chandler, then predict who would win in a fight and why.",
        "List me all the columns in your datasets",
        "Tell me the most recent 3 events and the main event outcome of each one",
        "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?",
        "What is the current weather forecast for Miami, Florida?"
    ]
    return jsonify({"examples": examples})

#if __name__ == '__main__':
#    app.run(debug=True, host='0.0.0.0', port=5001)
if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5001)
