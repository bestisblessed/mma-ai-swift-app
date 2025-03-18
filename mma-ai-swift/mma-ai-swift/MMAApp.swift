import SwiftUI

@main
struct MMAApp: App {
    @StateObject private var settingsManager = SettingsManager()
    @State private var isShowingLaunchScreen = true
    
    init() {
        // Initialize any app-wide settings here
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
                // Show launch screen for 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        isShowingLaunchScreen = false
                    }
                }
            }
        }
    }
} 