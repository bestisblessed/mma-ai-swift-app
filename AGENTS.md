# AGENTS.md – MMA Analyst App
This document provides guidance for OpenAI Codex and other AI agents working with the MMA Analyst Swift application. It outlines project structure, coding conventions, testing protocols, and how agents should interact with the codebase to ensure consistency and quality.

## 📁 Project Structure
- **mma-ai-swift/** – Main SwiftUI app
  - `MMAApp.swift` – App entry point, handles launch, preloads fighter data, and manages launch screen.
  - `ContentView.swift` – Main tabbed UI: dashboard, chat, and fighter database.
  - `DashboardView.swift` – Dashboard with tabs for upcoming/past events, rankings, news, and odds.
  - `Models.swift` – Core data models for fighters, fights, events, and API responses.
  - `OddsMonitoringView.swift` – UI for monitoring and selecting fight odds.
  - `EventCard.swift` – UI card for displaying event details and fight cards.
  - `FightOddsChart.swift` – Chart view for visualizing odds movement for a fight.
  - `OddsModels.swift` – Data models for odds movement and odds API responses.
  - `NetworkManager.swift` – Handles all network/API requests and caching.
  - `OddsHistoryView.swift` – UI for searching and displaying historical odds for fighters.
  - `DataManager.swift` – Singleton for managing fighter/event/odds data and caching.
  - `ChatViewModel.swift` – View model for chat logic, API calls, and conversation state.
  - `Message.swift` – Data model for chat messages (user/assistant, text, images, etc).
  - `FighterCard.swift` – UI card for displaying a fighter's summary and stats.
  - `FighterProfileView.swift` – Detailed fighter profile with stats, charts, and fight history.
  - `SettingsView.swift` – App settings UI (dark mode, version, links).
  - `FighterDashboardView.swift` – Fighter and fight database browser with search and filters.
  - `SharedComponents.swift` – Reusable UI components (loading dots, image viewer, etc).
  - `AppTheme.swift` – Centralized color, font, and style definitions for the app.
  - `ExportView.swift` – UI for exporting and sharing conversation text/images.
  - `ConversationHistoryView.swift` – UI and logic for managing and restoring chat history.
  - `LaunchScreen.swift` – Animated launch/splash screen for the app.
- **app.py** – Python Flask backend API (avoid modifying unless necessary)
- **Assets.xcassets** – Images, colors (do not modify without approval)
- **notes/** – Developer notes and architecture decisions
- **Info.plist**, `.env` – App configuration and environment


## ✅ Testing Protocols
- Build with Xcode (v15+): open `mma-ai-swift/MMAChat.xcodeproj`, run with Cmd+R
- Backend API: run `python app.py` with `.env` set for local testing
- Manual testing required – simulate chat, fighter search, event display, etc.
- No XCTest yet – optional to add for new logic
- No SwiftLint yet – self-enforce consistent formatting
- Test edge cases (offline, empty history, slow response, etc.)


## 🔀 Pull Request Guidelines
- **Title**: Format them all lowercase and with dashes between words like 'added-feature-odds-dashboard'
- **Description**: Include:
  - What was changed and why
  - How it was implemented
  - How it was tested
  - Screenshots (if UI changes)
  - Dependencies added (if any)
- All code must compile with no warnings before review


## 🤖 Agent Behavior
- Read and follow context from existing files before editing
- Match code style exactly (spacing, logging, naming, architecture)
- Only touch what is needed for the task – no drive-by refactors
- Document new features in README and `notes/` if applicable
- Validate all changes – test manually and ensure nothing breaks
- Fix any test or type errors until the whole suite is green
- PRs must be review-ready: tested, clean, and documented