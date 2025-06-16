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
import pandas as pd
from datetime import datetime
import re

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

def clean_markdown_simple(text):
    """Remove basic markdown symbols (# and *) from text."""
    if not text:
        return text
    
    # Remove heading symbols
    text = re.sub(r'^#+\s+', '', text, flags=re.MULTILINE)
    
    # Remove bold/italic asterisks
    text = re.sub(r'\*+', '', text)
    
    return text

@app.route('/')
def home():
    return "Flask App is Running! API is available at /api/chat and /api/examples"

# New endpoints for fighter and event data
@app.route('/api/data/fighters', methods=['GET'])
def get_fighters():
    try:
        # Read the CSV file
        fighters_df = pd.read_csv('data/fighter_info.csv')
        
        # Replace string "None" or "NULL" values with proper None/null
        fighters_df = fighters_df.replace(["None", "NULL", "NaN"], None)
        
        # Fill nullable columns that should never be null with appropriate values
        fighters_df["Wins"] = fighters_df["Wins"].fillna(0)
        fighters_df["Losses"] = fighters_df["Losses"].fillna(0)
        fighters_df["Win_Decision"] = fighters_df["Win_Decision"].fillna(0)
        fighters_df["Win_KO"] = fighters_df["Win_KO"].fillna(0)
        fighters_df["Win_Sub"] = fighters_df["Win_Sub"].fillna(0)
        fighters_df["Loss_Decision"] = fighters_df["Loss_Decision"].fillna(0)
        fighters_df["Loss_KO"] = fighters_df["Loss_KO"].fillna(0)
        fighters_df["Loss_Sub"] = fighters_df["Loss_Sub"].fillna(0)
        fighters_df["Fighter_ID"] = fighters_df["Fighter_ID"].fillna(0)
        
        # For Reach, replace '-' with empty string to keep it as a string
        fighters_df["Reach"] = fighters_df["Reach"].replace('-', '')
        # For Stance, replace '-' with empty string
        fighters_df["Stance"] = fighters_df["Stance"].replace('-', '')
        # Fill any remaining nulls with empty strings for string columns
        fighters_df["Reach"] = fighters_df["Reach"].fillna('')
        fighters_df["Stance"] = fighters_df["Stance"].fillna('')
        
        # Ensure integer fields are properly formatted as integers
        int_columns = ["Wins", "Losses", "Win_Decision", "Win_KO", "Win_Sub", 
                       "Loss_Decision", "Loss_KO", "Loss_Sub", "Fighter_ID"]
        for col in int_columns:
            fighters_df[col] = fighters_df[col].astype(int)
        
        # Make sure Reach is treated as a string to match Swift's expectation
        # Convert any numeric values to strings with one decimal place if needed
        fighters_df["Reach"] = fighters_df["Reach"].apply(
            lambda x: f"{float(x):.1f}" if isinstance(x, (int, float)) and x != '' else str(x)
        )
        
        # Convert to dictionary format with appropriate handling of null values
        fighters_data = json.loads(fighters_df.to_json(orient='records', date_format='iso'))
        
        # Add timestamp for caching
        response = {
            'timestamp': datetime.now().isoformat(),
            'fighters': fighters_data
        }
        
        return jsonify(response)
    except Exception as e:
        logger.error(f"Error fetching fighter data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/events', methods=['GET'])
def get_events():
    try:
        # Read the CSV file
        events_df = pd.read_csv('data/event_data_sherdog.csv')
        
        # Replace string "None" or "NULL" values with proper None/null
        events_df = events_df.replace(["None", "NULL", "NaN"], None)
        
        # Fill nullable columns that should never be null with appropriate values
        events_df["Fighter 1 ID"] = events_df["Fighter 1 ID"].fillna(0)
        events_df["Fighter 2 ID"] = events_df["Fighter 2 ID"].fillna(0)
        events_df["Winning Round"] = events_df["Winning Round"].fillna(0)
        
        # Ensure integer fields are properly formatted as integers
        int_columns = ["Fighter 1 ID", "Fighter 2 ID", "Winning Round"]
        for col in int_columns:
            events_df[col] = events_df[col].astype(int)
        
        # Convert to dictionary format with appropriate handling of null values
        events_data = json.loads(events_df.to_json(orient='records', date_format='iso'))
        
        # Add timestamp for caching
        response = {
            'timestamp': datetime.now().isoformat(),
            'events': events_data
        }
        
        return jsonify(response)
    except Exception as e:
        logger.error(f"Error fetching event data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/version', methods=['GET'])
def get_data_version():
    try:
        # Return the current version based on file modification times
        fighter_data_path = 'data/fighter_info.csv'
        event_data_path = 'data/event_data_sherdog.csv'
        
        fighter_timestamp = os.path.getmtime(fighter_data_path) if os.path.exists(fighter_data_path) else 0
        event_timestamp = os.path.getmtime(event_data_path) if os.path.exists(event_data_path) else 0
        
        return jsonify({
            'fighter_data_version': fighter_timestamp,
            'event_data_version': event_timestamp,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Error fetching data version: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_input = data.get('message', '')
        conversation_id = data.get('conversation_id')
        custom_assistant_id = data.get('assistant_id')  # Get custom assistant ID if provided
        
        # Log information about the request
        logger.info(f"Received message: '{user_input}'")
        logger.info(f"Conversation ID: {conversation_id}")
        if custom_assistant_id:
            logger.info(f"Using custom assistant ID: {custom_assistant_id}")
        
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
        
        # Use custom assistant ID if provided, otherwise use default
        assistant_id = custom_assistant_id if custom_assistant_id else ASSISTANT_ID
        logger.info(f"Running assistant with ID: {assistant_id}")
        
        # Create run with text response format
        run = client.beta.threads.runs.create(
            thread_id=thread_id,
            assistant_id=assistant_id
            # response_format={"type": "text"},
            # instructions="Please provide responses in plain text only. Avoid using markdown formatting symbols like asterisks and hash symbols."
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
                        # Clean markdown symbols
                        text_content = clean_markdown_simple(text_content)
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

@app.route('/api/debug/fighter_csv_columns', methods=['GET'])
def get_fighter_csv_columns():
    try:
        fighters_df = pd.read_csv('data/fighter_info.csv')
        column_info = {
            'columns': list(fighters_df.columns),
            'dtypes': {col: str(fighters_df[col].dtype) for col in fighters_df.columns},
            'null_counts': {col: int(fighters_df[col].isnull().sum()) for col in fighters_df.columns}
        }
        return jsonify(column_info)
    except Exception as e:
        logger.error(f"Error reading fighter CSV columns: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/debug/event_csv_columns', methods=['GET'])
def get_event_csv_columns():
    try:
        events_df = pd.read_csv('data/event_data_sherdog.csv')
        column_info = {
            'columns': list(events_df.columns),
            'dtypes': {col: str(events_df[col].dtype) for col in events_df.columns},
            'null_counts': {col: int(events_df[col].isnull().sum()) for col in events_df.columns}
        }
        return jsonify(column_info)
    except Exception as e:
        logger.error(f"Error reading event CSV columns: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/upcoming', methods=['GET'])
def get_upcoming_events():
    try:
        # Load the upcoming events CSV file
        upcoming_df = pd.read_csv('data/upcoming_event_data_sherdog.csv')
        
        # Group by event name to organize fights under each event
        events = []
        for event_name, group in upcoming_df.groupby('Event Name'):
            first_row = group.iloc[0]
            
            # Get all fights for this event and convert to list
            fights = []
            for _, row in group.iterrows():
                fight = {
                    'fighter1': row['Fighter 1'],
                    'fighter2': row['Fighter 2'],
                    'weightClass': row['Weight Class'],
                    'fightType': row['Fight Type'],
                    'round': None,  # These are upcoming so no result yet
                    'time': None,
                    'winner': None,
                    'method': None
                }
                fights.append(fight)
            
            # Split fights into main card and prelims
            # Main card is last 5 fights (or all if less than 5)
            total_fights = len(fights)
            main_card_size = min(5, total_fights)
            
            # Create the event object with sections for main card and prelims
            event = {
                'eventName': event_name,
                'location': first_row['Event Location'],
                'date': first_row['Event Date'],
                'mainCard': fights[-main_card_size:] if main_card_size > 0 else [],
                'prelims': fights[:-main_card_size] if total_fights > main_card_size else [],
                'allFights': fights  # Keep the full list as well
            }
            
            events.append(event)
            
        return jsonify(events)
    except Exception as e:
        logger.error(f"Error fetching upcoming event data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/odds', methods=['GET'])
def get_odds_chart():
    """Return betting odds movement data for the requested fighter as a list of chart points."""
    fighter_name = request.args.get('fighter', default='', type=str).strip().lower()
    csv_path = 'data/ufc_odds_movements_fightoddsio.csv'

    if not os.path.exists(csv_path):
        return jsonify({'error': f'CSV file not found at {csv_path}'}), 500

    try:
        # Read only needed columns for efficiency
        cols = ['file1', 'file2', 'fighter', 'sportsbook', 'odds_before', 'odds_after']
        df = pd.read_csv(csv_path, usecols=cols)

        # Optionally filter by fighter (case-insensitive exact match)
        if fighter_name:
            df = df[df['fighter'].str.lower() == fighter_name]

        # If nothing to return, send empty list so client can show graceful message
        if df.empty:
            return jsonify({'fighter': fighter_name, 'data': []})

        chart_points = []
        for _, row in df.iterrows():
            # Derive a timestamp from the two filenames: 20250511_1646 etc.
            time_stamp = f"{row['file1']}_{row['file2']}"

            def to_int(odds_str):
                try:
                    return int(str(odds_str).replace('+', '').strip())
                except ValueError:
                    return 0

            before = to_int(row['odds_before'])
            after = to_int(row['odds_after'])

            sportsbook = row['sportsbook']

            # Create two points per row to match the iOS chart logic (before and after)
            if before != 0:
                chart_points.append({
                    'timestamp': time_stamp,
                    'odds': before,
                    'sportsbook': sportsbook
                })
            if after != 0:
                chart_points.append({
                    'timestamp': f"{time_stamp}+",  # trailing + indicates post-movement
                    'odds': after,
                    'sportsbook': sportsbook
                })

        # Sort by timestamp for consistency
        chart_points.sort(key=lambda p: p['timestamp'])

        return jsonify({'fighter': fighter_name, 'data': chart_points})
    except Exception as e:
        logger.error(f"Error processing odds data: {str(e)}")
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
   app.run(debug=True, host='0.0.0.0', port=5001)
# if __name__ == "__main__":
#     app.run(host="127.0.0.1", port=5001)
