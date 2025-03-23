import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import json
import uuid
from dotenv import load_dotenv
import logging
import time
import base64

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
            time.sleep(5)  # Poll every second
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
        response_data = []
        for msg in messages.data:
            if msg.role == "assistant":
                for content_item in msg.content:
                    if content_item.type == "text":
                        # Capture text annotations
                        text_content = content_item.text.value
                        annotations = [
                            {
                                "type": "file",
                                "text": annotation.text,
                                "file_id": annotation.file_path.file_id
                            } for annotation in content_item.text.annotations
                        ]
                        response_data.append({
                            "type": "text",
                            "content": text_content,
                            "annotations": annotations
                        })
                    elif content_item.type == "image_file":
                        # Retrieve and encode image
                        image_file = content_item.image_file.file_id
                        image_data = client.files.content(image_file)
                        encoded_image = base64.b64encode(image_data.content).decode('utf-8')
                        response_data.append({
                            "type": "image",
                            "format": "png",
                            "content": f"data:image/png;base64,{encoded_image}"
                        })
                if response_data:
                    break
        
        if not response_data:
            response_data = [{
                "type": "error",
                "content": "Sorry, I couldn't retrieve the information you requested."
            }]
        
        logger.info(f"Received response from Assistant: '{response_data[:50]}...'")
        
        # Return response with conversation ID
        return jsonify({
            "response": response_data,
            "conversation_id": conversation_id
        })
        
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": f"Server error: {str(e)}"}), 500

@app.route('/api/examples', methods=['GET'])
def get_examples():
    examples = [
        "Tell me about Jon Jones most recent 5 fights in detail",
        "Make me a pie chart visualization of Max Holloway's method of victories",
        "Analyze and research Paddy Pimblett and Michael Chandler in depth, then predict who would win in a potential fight. Include the method and time of victory.",
        "List me all the columns and summarize the data in all of your datasets",
        # "Tell me the most recent 3 events and the main event outcome of each one",
        # "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?",
    ]
    return jsonify({"examples": examples})

@app.route('/api/chat/history', methods=['POST'])
def get_chat_history():
    try:
        data = request.json
        thread_id = data.get('conversation_id')
        
        if not thread_id:
            return jsonify({"error": "No thread ID provided"}), 400
            
        # Fetch messages from the thread
        messages = client.beta.threads.messages.list(thread_id=thread_id)
        
        # Group and format messages for response
        user_messages = []
        assistant_messages = []
        formatted_messages = []
        
        # First, separate user and assistant messages
        for msg in messages.data:
            if msg.role == "user":
                response_data = []
                for content_item in msg.content:
                    if content_item.type == "text":
                        response_data.append({
                            "type": "text",
                            "content": content_item.text.value
                        })
                if response_data:
                    user_messages.append({
                        "role": "user",
                        "content": response_data,
                        "created_at": msg.created_at  # We'll use this to match with assistant responses
                    })
            elif msg.role == "assistant":
                response_data = []
                for content_item in msg.content:
                    if content_item.type == "text":
                        response_data.append({
                            "type": "text",
                            "content": content_item.text.value
                        })
                    elif content_item.type == "image_file":
                        image_file = content_item.image_file.file_id
                        image_data = client.files.content(image_file)
                        encoded_image = base64.b64encode(image_data.content).decode('utf-8')
                        response_data.append({
                            "type": "image",
                            "content": f"data:image/png;base64,{encoded_image}"
                        })
                if response_data:
                    assistant_messages.append({
                        "role": "assistant",
                        "content": response_data,
                        "created_at": msg.created_at
                    })
        
        # Sort messages by creation time (oldest first)
        user_messages.sort(key=lambda x: x["created_at"])
        assistant_messages.sort(key=lambda x: x["created_at"])
        
        # For each user message, find the most recent assistant message that follows it
        for i, user_msg in enumerate(user_messages):
            # Add user message
            formatted_messages.append({
                "role": user_msg["role"],
                "content": user_msg["content"]
            })
            
            # Find the most recent assistant message created after this user message
            next_user_time = user_messages[i+1]["created_at"] if i+1 < len(user_messages) else float('inf')
            relevant_assistant_msgs = [
                a for a in assistant_messages 
                if a["created_at"] > user_msg["created_at"] and a["created_at"] < next_user_time
            ]
            
            # If there are assistant messages, add only the most recent one
            if relevant_assistant_msgs:
                # Sort by creation time (newest first) and take the first one
                relevant_assistant_msgs.sort(key=lambda x: x["created_at"], reverse=True)
                formatted_messages.append({
                    "role": "assistant",
                    "content": relevant_assistant_msgs[0]["content"]
                })
            
        return jsonify({
            "messages": formatted_messages,
            "conversation_id": thread_id
        })
        
    except Exception as e:
        logger.error(f"Chat history error: {str(e)}")
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
   app.run(debug=True, host='0.0.0.0', port=5001)
# if __name__ == "__main__":
#     app.run(host="127.0.0.1", port=5001)
