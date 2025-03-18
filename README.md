# MMA Analyst App

An iOS application that provides MMA analysis, fighter statistics, and event information using AI-powered responses.

## Features

- Chat interface for asking questions about MMA fighters, events, and statistics
- AI-powered responses using OpenAI's GPT models
- Example questions to help users get started
- Real-time conversation history

## File Description

### App Structure
- **MMAApp.swift**: Entry point of the app, defines app structure and lifecycle.
- **ContentView.swift**: Main view container that coordinates between different views.

### Main Views
- **DashboardView.swift**: Home screen displaying an overview of MMA content.
- **ConversationHistoryView.swift**: Displays past conversations with the AI assistant.
- **SettingsView.swift**: Contains app configuration options for users.

### Components
- **ChatViewModel.swift**: Manages chat functionality and data, connects to the server API.
- **EventCard.swift**: UI component that displays MMA event information in card format.
- **FighterCard.swift**: UI component that displays fighter information in card format.

### Theme & UI
- **Theme.swift**: Defines basic theming elements like colors and fonts.
- **AppTheme.swift**: Implements the theme system for the app.

### Loading Screens
- **LaunchScreen.swift**: Initial screen users see when opening the app.
- **LoadingView.swift**: View shown during loading operations.

## Setup Instructions

### Prerequisites

- Xcode 15+ (for iOS app)
- Python 3.9+ (for backend API)
- OpenAI API key

### Backend Setup

1. Clone the repository
2. Navigate to the backend directory
3. Create and activate a virtual environment:
   ```
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```
4. Install dependencies:
   ```
   pip install flask flask-cors openai python-dotenv
   ```
5. Create a `.env` file in the root directory with your OpenAI API key:
   ```
   OPENAI_API_KEY=your_api_key_here
   ```
6. Run the Flask server:
   ```
   python app.py
   ```
   The server will run on `https://mma-ai.duckdns.org`

### Deployment to Raspberry Pi

For deploying the Flask API server to a Raspberry Pi:

1. Transfer the project files to your Raspberry Pi:
   ```
   rsync -av --exclude 'venv' --exclude 'MMAChat' --exclude '.DS_Store' /path/to/project/ trinity@mma-ai.duckdns.org:/home/trinity/mma-chat-api/
   ```

2. Set up the environment on your Raspberry Pi:
   ```
   ssh trinity@mma-ai.duckdns.org
   cd /home/trinity/mma-chat-api/
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

3. Configure your `.env` file with your OpenAI API key.

4. Run the server:
   ```
   python app.py
   ```
   
   Or set up a systemd service for automatic startup (see detailed instructions in the deployment guide).

5. Update the iOS app to use the new domain: `https://mma-ai.duckdns.org`

### iOS App Setup

1. Open the `MMAChat.xcodeproj` file in Xcode
2. Make sure the `ChatViewModel.swift` file has the correct IP address for your local machine
3. Build and run the app in the iOS simulator or on a physical device

## Usage

1. Launch the app
2. You'll see a welcome screen with example questions
3. Tap on an example question or "Start Chatting" to begin
4. Type your MMA-related questions in the text field and tap the send button
5. The AI will respond with relevant information

## Potential Improvements

### Content & Functionality Enhancements

- **Fighter Profiles**: Add a section to view detailed fighter stats, records, and career highlights
- **Upcoming Events Calendar**: Display a calendar of scheduled UFC/MMA events with fight cards
- **Fight Predictions**: Allow users to get AI-powered predictions for upcoming fights with probability percentages
- **News Feed**: Integrate latest MMA news from reliable sources
- **Video Analysis**: Add capability to analyze fight clips or link to YouTube highlights
- **Betting Odds Integration**: Show current betting odds for upcoming fights
- **Fight Notifications**: Send alerts for upcoming fights of favorite fighters

### UI/UX Improvements

- **Dark Mode**: Add a toggle for light/dark theme
- **Voice Input**: Allow users to ask questions via voice instead of typing
- **Custom Themes**: Let users choose UFC, Bellator, or other promotion-themed interfaces
- **Message Categories**: Add filters to sort conversations by topic (fighter info, event info, predictions)
- **Saved Conversations**: Allow users to bookmark important conversations

### Technical Enhancements

- **Offline Mode**: Cache recent conversations for offline viewing
- **Image Recognition**: Allow users to upload fighter images to get information
- **Export Functionality**: Let users export conversations as PDF or text
- **User Accounts**: Add login to sync conversations across devices
- **WebSocket Implementation**: Replace polling with WebSockets for more efficient real-time communication
- **Local Database**: Store fighter stats locally for faster responses on common queries

### Advanced Features

- **Fight Simulation**: Create a feature to simulate hypothetical matchups between any two fighters
- **Training Tracker**: Help users track their own MMA training progress
- **Community Integration**: Add a forum or comment section for users to discuss fights
- **Technique Library**: Create an illustrated guide to MMA techniques referenced in conversations
- **Fantasy MMA**: Integrate with or create a fantasy MMA league feature

## Troubleshooting

- If the app can't connect to the backend, make sure the Flask server is running and the IP address in `ChatViewModel.swift` is correct
- If you see "Thinking..." for too long, check the Flask server logs for any errors
- Make sure your OpenAI API key is valid and has sufficient credits

## License

[Your License Here]

## Acknowledgements

- OpenAI for providing the GPT models
- [Any other acknowledgements] 