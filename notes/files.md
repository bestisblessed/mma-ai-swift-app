
# MMA AI Swift App Components

## Swift Files:

### ContentView.swift
- Main interface controller showing chat, dashboard, and settings
- Manages navigation and tab selection between different views
- Handles authentication state and user session

### DashboardView.swift
- Displays fighter and event statistics in a dashboard format
- Shows visualization of fighter data and upcoming events
- Allows filtering and search of fighter/event information

### ChatViewModel.swift
- Manages chat interactions using the OpenAI API via a Swift package
- Handles message processing, streaming responses, and storage
- Manages conversation history and message threading

- Handles all data API requests to the Flask backend
- Processes fighter and event data from CSV files
- Manages caching of data and API responses

### EventCard.swift
- Displays detailed information about MMA events
- Shows fight cards with matchups and results
- Visualizes event statistics and fight outcomes

### FighterProfileView.swift
- Shows detailed fighter statistics and information
- Displays win/loss record and fight history
- Visualizes fighter performance metrics

### FighterDashboardView.swift
- Comprehensive dashboard for fighter statistics
- Generates visualizations of fighter performance
- Allows comparison between different fighters

### Message.swift
- Defines data structures for chat messages
- Handles different message types (text, images)
- Manages message metadata and formatting

### ConversationHistoryView.swift
- Displays history of chat conversations
- Allows navigation through past interactions
- Manages conversation deletion and persistence

### SettingsView.swift
- Provides app configuration options
- Manages user preferences and appearance settings
- Controls API connection settings

### ExportView.swift
- Handles exporting of data and conversations
- Provides sharing options for statistics and insights
- Manages file format selection for exports

### MMAApp.swift
- Main app entry point and lifecycle controller
- Initializes core services and view hierarchy
- Manages global app state and dependencies

### FighterCard.swift
- Displays condensed fighter information in card format
- Shows key stats and record information
- Provides navigation to detailed fighter profile

### AppTheme.swift
- Defines app-wide styling and theming
- Manages color schemes and visual appearance
- Provides consistent UI elements across the app

### LoadingView.swift
- Shows loading indicators during async operations
- Provides feedback during data retrieval
- Handles loading state transitions

## Flask Server (app.py):

### Server Components:
- Provides RESTful API endpoints for fighter and event data from CSV files
- Manages chat functionality using OpenAI Assistant API for MMA analysis
- Handles conversation history, threading, and image generation
- Serves upcoming event data and statistics for the Swift app
