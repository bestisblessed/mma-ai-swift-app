import SwiftUI

// Global debug helper
func debugPrint(_ message: String, function: String = #function, line: Int = #line) {
    print("🔍 [\(function):\(line)] \(message)")
}

@main
struct MMAApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @State private var isShowingLaunchScreen = true
    
    init() {
        // Initialize any app-wide settings here
        
        // App-wide settings initialized
    }
    
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView(settingsManager: settingsManager)
                    .preferredColorScheme(settingsManager.useDarkMode ? .dark : .light)
                    .accentColor(AppTheme.accent)
                    .opacity(isShowingLaunchScreen ? 0 : 1)
                
                if isShowingLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                }
            }
            .onAppear {
                // Show launch screen for 2.5 seconds, which gives time for data preloading
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isShowingLaunchScreen = false
                    }
                }
            }
        }
    }
} 