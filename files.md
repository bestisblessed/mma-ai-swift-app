
Let me examine your Swift project structure first.

Ran tool


Ran tool


Ran tool

# Swift App Files
- **MMAApp.swift**: 
  - Main app entry point and configuration
  - Sets up navigation and app structure

- **ContentView.swift**: 
  - Main container view with tab navigation
  - Manages primary user interface and flow

- **ChatViewModel.swift**: 
  - Handles AI chat conversation logic
  - Manages message state and API communication 

- **NetworkManager.swift**: 
  - Implements API requests to the Flask backend
  - Handles data fetching and error management

- **DashboardView.swift**: 
  - Displays main statistics and MMA information
  - Provides navigation to detailed content

- **EventCard.swift**: 
  - Renders MMA event cards with fight details
  - Manages event data visualization

- **FighterDashboardView.swift**: 
  - Fighter search and browse functionality
  - Displays fighter statistics and metrics

- **FighterProfileView.swift**: 
  - Shows detailed fighter information
  - Displays fight history and statistics

- **Message.swift**: 
  - Data model for chat messages
  - Handles different content types (text/images)

- **ConversationHistoryView.swift**: 
  - Displays chat history interface
  - Manages conversation state and navigation

# Flask Server (app.py)
- **API Endpoints**: 
  - Provides fighter and event data via JSON
  - Handles chat via OpenAI Assistant API

- **Data Management**: 
  - Reads and processes CSV data for fighters/events
  - Formats response data for Swift app consumption

- **Chat Functionality**: 
  - Manages conversation threads with OpenAI
  - Processes images and text responses
