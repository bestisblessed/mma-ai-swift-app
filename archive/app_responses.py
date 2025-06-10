import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import json
import uuid
from dotenv import load_dotenv
import logging
import re
from pathlib import Path

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

# Store conversation history
conversations = {}

# Function to extract potential fighter names from user input
def extract_fighter_names(user_input):
    """Extract potential fighter names from user input by checking against our database"""
    try:
        # Load fighter names from final.json (only do this once and cache it in production)
        fighter_names = []
        with open('data/final.json', 'r') as f:
            fighters_data = json.load(f)
            for fighter in fighters_data:
                if 'name' in fighter and fighter['name']:
                    fighter_names.append(fighter['name'])
        
        # Sort by length (descending) to match longer names first
        fighter_names = sorted(fighter_names, key=len, reverse=True)
        
        # Find all matches in the user input
        found_fighters = []
        user_input_lower = user_input.lower()
        
        for name in fighter_names:
            if name.lower() in user_input_lower:
                found_fighters.append(name)
                # Remove this name from the input to avoid double-matching
                user_input_lower = user_input_lower.replace(name.lower(), "")
                
                # Limit to 3 fighters to avoid too many filters
                if len(found_fighters) >= 3:
                    break
        
        return found_fighters
    except Exception as e:
        logger.error(f"Error extracting fighter names: {str(e)}")
        return []

# Function to create vector store filters based on fighter names
def create_fighter_filters(fighter_names):
    """Create vector store filters for the specified fighter names"""
    if not fighter_names:
        return None
    
    # Create metadata filter conditions for each fighter name
    metadata_filters = []
    for name in fighter_names:
        # Add condition to match fighter name
        metadata_filters.append({
            "key": "name",
            "value": name,
            "operator": "contains"
        })
        
        # Add condition to match opponent name
        metadata_filters.append({
            "key": "opponent",
            "value": name,
            "operator": "contains"
        })
    
    # Return the properly formatted filter structure for Responses API
    return {
        "metadata_filter": {
            "operator": "or",
            "filters": metadata_filters
        }
    }

@app.route('/api/chat', methods=['POST'])
def chat():
    try:
        data = request.json
        user_input = data.get('message', '')
        conversation_id = data.get('conversation_id')
        
        logger.info(f"Received message: '{user_input}'")
        logger.info(f"Conversation ID: {conversation_id}")
        
        # Create new conversation if none exists
        if not conversation_id or conversation_id not in conversations:
            conversation_id = str(uuid.uuid4())
            conversations[conversation_id] = []
            logger.info(f"Created new conversation with ID: {conversation_id}")
        
        # Add user message to history
        conversations[conversation_id].append({"role": "user", "content": user_input})
        
        # Prepare messages for OpenAI
        messages = [
            {"role": "system", "content": "You are an expert data analyst and MMA handicapper with extensive knowledge of fighter statistics, fight history, and analytical techniques."}
        ]
        
        # Filter out any messages with null content
        for msg in conversations[conversation_id]:
            if msg.get("content") is not None:
                messages.append(msg)
        
        logger.info(f"Sending {len(messages)} messages to OpenAI")
        
        try:
            # Extract fighter names from the user input
            fighter_names = extract_fighter_names(user_input)
            logger.info(f"Extracted fighter names: {fighter_names}")
            
            # Create filters based on fighter names
            filters = create_fighter_filters(fighter_names)
            logger.info(f"Created filters: {filters}")
            
            # Configure the file_search tool with filters if available
            file_search_tool = {
                "type": "file_search",
                "vector_store_ids": ["vs_67d35d0e2f608191b6398703dc71a931"]
            }
            
            if filters:
                file_search_tool.update(filters)
            
            # Always use the Responses API with both file_search and web_search tools
            logger.info("Using Responses API with knowledge base and web search")
            response = client.responses.create(
                model="gpt-4o-mini",
                # model="gpt-4o",
                input=user_input,
                temperature=0.2,  # Add a lower temperature for more factual responses
                instructions="""
                You are an expert data analyst and MMA handicapper with extensive knowledge of fighter statistics, 
                fight history, and analytical techniques.

                CRITICAL RULES FOR AI TO ALWAYS FOLLOW NO MATTER WHAT:

                1. For fighter data and statistics:
                - You MUST ONLY use the EXACT numbers from the retrieved file_search data
                - When reporting win methods (KO, submissions, decisions), ONLY use the numbers from the "stats" section
                - ALWAYS check the "stats" section of the fighter data for the official record
                    ex) Jon Jones
                        "stats": {
                            "record": "28-1-0",
                            "total_wins": 28,
                            "total_losses": 1,
                            "total_draws": 0,
                            "win_methods": {
                                "decision": 10,
                                "knockout": 11,
                                "submission": 7
                            },
                            "loss_methods": {
                                "decision": 0,
                                "knockout": 0,
                                "submission": 0
                            }
                        },
                - NEVER rely on your pre-trained knowledge for any numerical statistics
                - Your file_search data contains comprehensive historical fight information - USE THIS as your primary and authoritative source for ALL past fights and career statistics

                2. CRITICAL ABOUT FIGHT HISTORY:
                - When listing a fighter's recent fights, you MUST check the ENTIRE "fights" array in the data
                - ALWAYS sort by date in DESCENDING order (newest first) when reporting
                - VERIFY you have included the MOST RECENT fight by checking the latest date
                - For Max Holloway specifically, ensure you include his fight with Ilia Topuria
                - If asked for the 5 most recent fights, you MUST check ALL fights and sort by date before selecting the 5 newest

                3. Web search should ONLY be used for things like:
                - Current news like injuries, weight cuts, or training camp updates
                - Last-minute changes to fight cards
                - Current rankings or championship status changes
                - Weather forecasting
                
                4. When analyzing data and providing insights, you should:
                - Utilize the `file_search` tool FIRST to locate comprehensive data on fighters
                - Use the `web_search` tool ONLY for time-sensitive or future information
                - Present your results in a clear, concise, and professional manner
                
                IMPORTANT ABOUT FIGHT HISTORY:
                - When listing a fighter's recent fights, ALWAYS check their ENTIRE fight list in the data
                - Sort fights by date in DESCENDING order (newest first) when reporting
                
                """,
                tools=[
                    file_search_tool,
                    {
                        "type": "web_search_preview",
                        "search_context_size": "low",
                    }
                ]
            )
            
            # Process the response similar to responses.py
            content = ""
            for item in response.output:
                if hasattr(item, 'content'):
                    for content_item in item.content:
                        if hasattr(content_item, 'text'):
                            content += content_item.text
            
            if not content:
                content = "Sorry, I couldn't retrieve the information you requested."
            
            logger.info(f"Received response from Responses API: '{content[:50]}...'")
            
            # Add assistant response to history
            conversations[conversation_id].append({
                "role": "assistant", 
                "content": content
            })
            
            # Return response with conversation ID
            return jsonify({
                "response": content,
                "conversation_id": conversation_id
            })
        except Exception as e:
            logger.error(f"OpenAI API error: {str(e)}")
            return jsonify({
                "error": f"OpenAI API error: {str(e)}",
                "conversation_id": conversation_id
            }), 500
        
    except Exception as e:
        logger.error(f"Server error: {str(e)}")
        return jsonify({"error": str(e)}), 500

@app.route('/api/examples', methods=['GET'])
def get_examples():
    examples = [
        "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?",
        "Tell me about Max Holloway's most recent 5 fights chronologically",
        "What is the current weather forecast for Miami, Florida?"
    ]
    return jsonify({"examples": examples})

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5001)