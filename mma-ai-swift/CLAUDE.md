# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Workflow

### Build and Test
- Build the project: `xcodebuild clean build`
  - Ensures no compilation errors
  - Catches Swift syntax issues early
  - Verifies project-wide compatibility

### Project Architecture
- **Primary Architecture**: SwiftUI MVVM (Model-View-ViewModel)
- **Key Architectural Components**:
  1. Views: Responsible for UI rendering
  2. ViewModels: Manage UI state and business logic
  3. Managers: Handle data persistence and app-wide state
  4. Models: Define data structures

### Key Frameworks and Dependencies
- SwiftUI for UI
- Combine for reactive programming
- UIKit for some native iOS integrations

### State Management Patterns
- `@StateObject`: For long-lived view models
- `@ObservedObject`: For shared, externally managed objects
- `@Published`: For reactive property updates
- UserDefaults for lightweight persistent storage

### Core Design Principles
- Reactive UI updates
- Dependency injection
- Centralized theming (`AppTheme`)
- Consistent error and loading state handling

### Data Flow
- ChatViewModel manages conversation state
- ConversationHistoryManager handles saved conversations
- SettingsManager manages app-wide settings
- FighterDataManager handles event and fighter data retrieval

### Important Conventions
- Use `AppTheme` for consistent styling
- Implement loading and error states in data-fetching views
- Use native iOS sharing and activity view controllers
- Leverage SwiftUI's built-in animation and state management

### Performance Considerations
- Lazy loading of views
- Efficient state management
- Minimal use of persistent storage
- Asynchronous data fetching with `async/await`

### Debugging and Development
- Use Xcode's built-in SwiftUI preview functionality
- Leverage Swift's type safety and compile-time checks
- Use `print()` statements sparingly for debugging

### Key Customization Points
- Modify `AppTheme` for global styling changes
- Extend `SettingsManager` for new app-wide settings
- Update `ChatViewModel` for AI interaction modifications