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
        
        // Preload the fighter data manager
        preloadFighterData()
    }
    
    // Preload all fighter data during app launch
    private func preloadFighterData() {
        debugPrint("Preloading fighter data...")
        
        // Initialize the shared instance to load all data
        _ = FighterDataManager.shared
        
        // Try accessing some fighters to ensure they're loaded
        let testFighters = ["Sean Brady", "Max Holloway", "Leon Edwards"]
        
        for fighter in testFighters {
            if let data = FighterDataManager.shared.getFighter(fighter) {
                debugPrint("✅ Fighter loaded: \(fighter) - \(data.record)")
                if let history = FighterDataManager.shared.getFightHistory(fighter) {
                    debugPrint("✅ History loaded: \(fighter) - \(history.count) fights")
                } else {
                    debugPrint("❌ No history for: \(fighter)")
                }
            } else {
                debugPrint("❌ Failed to load fighter: \(fighter)")
            }
        }
        
        // Force load all fighters in our predefined list
        let commonFighters = ["Leon Edwards", "Sean Brady", "Kevin Holland", "Gunnar Nelson", 
                             "Max Holloway", "Alexander Volkanovski", "Jon Jones", "Israel Adesanya",
                             "Conor McGregor", "Khabib Nurmagomedov", "Amanda Nunes", "Dustin Poirier"]
        
        let dispatchGroup = DispatchGroup()
        
        for fighter in commonFighters {
            dispatchGroup.enter()
            DispatchQueue.global().async {
                ensureFighterIsLoaded(fighter)
                dispatchGroup.leave()
            }
        }
        
        // Wait for all fighter data to be loaded
        dispatchGroup.notify(queue: .main) {
            debugPrint("All fighter data preloading complete")
            // Also load fight data into memory
            preloadFightData()
        }
    }
    
    private func preloadFightData() {
        debugPrint("Preloading fight data...")
        
        // Count the total number of fight records
        var totalFights = 0
        for (_, fights) in FighterDataManager.shared.fightHistory {
            totalFights += fights.count
        }
        
        debugPrint("✅ Found \(totalFights) total fight records across \(FighterDataManager.shared.fightHistory.count) fighters")
    }
    
    private func ensureFighterIsLoaded(_ name: String) {
        if let fighter = FighterDataManager.shared.getFighter(name) {
            debugPrint("Preloaded fighter: \(name) (\(fighter.record))")
            
            // Also preload fight history
            if let history = FighterDataManager.shared.getFightHistory(name) {
                debugPrint("Preloaded \(history.count) fights for \(name)")
            } else {
                debugPrint("No fight history found for \(name)")
            }
        } else {
            debugPrint("Failed to preload fighter: \(name)")
        }
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