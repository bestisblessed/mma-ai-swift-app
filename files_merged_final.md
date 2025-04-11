Let me analyze the key files in your project to provide a comprehensive list of what each one does:

Ran tool
Now let me examine key files to understand their specific functionality:

Read file: mma-ai-swift/mma-ai-swift/ChatViewModel.swift

Read file: mma-ai-swift/mma-ai-swift/FighterProfileView.swift

Read file: mma-ai-swift/mma-ai-swift/EventCard.swift
Based on the updated files in your Swift MMA app, here's a detailed breakdown of what each file does:

1. **ChatViewModel.swift (25KB):**
   - Powers the AI chat interface for fighter analysis
   - Handles sending fighter comparison requests to backend API
   - Manages conversation threads and message history
   - Formats fight analysis responses with fighter names
   - Supports image display for visualization of fighter stats

2. **FighterProfileView.swift (20KB):**
   - Displays comprehensive fighter information in a full-screen interface
   - Shows fighter stats including record, age, nationality, height, reach
   - Features pie charts for win/loss method distribution (KO, submission, decision)
   - Includes scrollable view of fight history with results
   - Uses SwiftUI Charts for data visualization

3. **EventCard.swift (16KB):**
   - Displays MMA event information in a card format
   - Shows event name, date, and venue location
   - Organizes fights into main card and preliminary card sections
   - Collapsible sections for both main card and prelims
   - Links fighters to their profile views

4. **FighterDashboardView.swift (33KB):**
   - Main database interface for exploring fighters and fights
   - Features division filters and search functionality
   - Displays fighters in a grid layout with basic info
   - Shows fight matchups with fighter records
   - Includes detailed fight profile view with winner highlight

5. **Models.swift (6.8KB):**
   - Combined data models for both core app and API
   - Defines structures for fighters, events, and fights
   - Handles JSON decoding for API responses
   - Supports data conversion between different formats
   - Provides identifiable conformance for SwiftUI lists

6. **DataManager.swift (21KB):**
   - Manages the loading and caching of fighter/event data
   - Handles data persistence between app sessions
   - Provides methods to access fighter information
   - Maintains fight history and event details
   - Synchronizes with backend API

7. **NetworkManager.swift (25KB):**
   - Handles all API communication with the backend
   - Fetches fighter and event data
   - Manages authentication and API keys
   - Implements error handling and retry logic
   - Parses API responses into app models

8. **AppTheme.swift (5.7KB):**
   - Defines app-wide styling and theme elements
   - Provides consistent colors for different fight outcomes (KO, SUB, DEC)
   - Sets up text styles, card backgrounds, and accent colors
   - Ensures visual consistency across all app screens

9. **SharedComponents.swift (1.6KB):**
   - Contains reusable UI components like loading indicators
   - Includes FullScreenImageView for viewing images
   - Provides animation effects for loading states
   - Supports sharing functionality for images

10. **ContentView.swift (23KB):**
    - Main view controller coordinating app navigation
    - Implements tab-based navigation
    - Connects all major views (Chat, Dashboard, Fighter Database)
    - Manages state transitions between views

11. **DashboardView.swift (17KB):**
    - Displays overview of MMA data and statistics
    - Shows upcoming events and recent fight results
    - Provides quick access to popular fighters
    - Features cards for different data categories

12. **FighterCard.swift (3.8KB):**
    - Displays fighter information in compact card format
    - Shows name, nickname, record, and weight class
    - Used throughout the app for fighter selection
    - Consistent styling with app theme

13. **ConversationHistoryView.swift (6.6KB):**
    - Displays history of AI chat conversations
    - Shows message threads with timestamps
    - Supports viewing and continuing past conversations
    - Handles displaying both text and image content

14. **MMAApp.swift (4.2KB):**
    - Entry point for the application
    - Sets up the environment and initial state
    - Configures app appearance and navigation
    - Initializes data managers and services

15. **SettingsView.swift (2.4KB):**
    - Provides user preference options
    - Controls app behavior settings
    - Includes data management options
    - Shows app information and credits

This updated organization makes your codebase more maintainable by consolidating related functionality and removing redundancy, particularly with the merging of chart components, shared UI elements, and data models.
