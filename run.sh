#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env file..."
    export $(grep -v '^#' .env | xargs)
else
    echo "Warning: .env file not found!"
fi

# Function to check if Flask server is running
check_flask_server() {
    if pgrep -f "python app.py" > /dev/null; then
        return 0  # Server is running
    else
        return 1  # Server is not running
    fi
}

# Function to stop any existing Flask server
stop_existing_server() {
    if check_flask_server; then
        echo "Stopping existing Flask server..."
        pkill -f "python app.py" || true
        sleep 1
        if ! check_flask_server; then
            echo "Flask server stopped successfully."
        else
            echo "Warning: Could not stop Flask server. You may need to kill it manually."
        fi
    fi
}

# Function to open Xcode
open_xcode() {
    echo "Opening Xcode project..."
    (cd MMAChat && open MMAChat.xcodeproj)
    echo "Xcode should be opening now."
    sleep 2  # Give Xcode a moment to open
}

# Main script
echo "MMA Analyst Development Environment"
echo "=================================="

# Check if user wants to stop existing server
if check_flask_server; then
    echo "A Flask server is already running."
    read -p "Do you want to stop it? (y/n): " stop_server
    if [[ $stop_server == "y" || $stop_server == "Y" ]]; then
        stop_existing_server
    else
        echo "Keeping existing Flask server running."
        echo "Opening Xcode only."
        open_xcode
        exit 0
    fi
fi

# Open Xcode first
open_xcode

# Now run the Flask server in the foreground
echo "Starting Flask server on https://mma-ai.duckdns.org..."
echo "Press Ctrl+C to stop the server when you're done."
echo "=================================="
python app.py  # Run in foreground 