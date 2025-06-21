import SwiftUI
import Foundation
// Import required model files

// Add necessary imports to use models
// No need to specify 'class' or 'struct' when importing

// Remove all duplicate model declarations and keep only the UI components

// Define LoadingState enum here if needed
enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case error(String)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            return true
        case (.error(let lhsMsg), .error(let rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

struct EventCard: View {
    let event: EventInfo
    let isPastEvent: Bool
    let defaultPrelimsExpanded: Bool
    @State private var showAllFights = false
    @State private var showMainCard = true
    @State private var showPrelims: Bool
    @State private var selectedFighter: FighterStats? = nil
    
    // Prediction & analysis sheet state
    @State private var showComparison = false
    @State private var comparisonFighters: (FighterStats, FighterStats)? = nil
    @State private var showOdds = false
    @State private var oddsFight: Fight? = nil
    
    init(event: EventInfo, isPastEvent: Bool = false, defaultPrelimsExpanded: Bool = false) {
        self.event = event
        self.isPastEvent = isPastEvent
        self.defaultPrelimsExpanded = defaultPrelimsExpanded
        _showPrelims = State(initialValue: defaultPrelimsExpanded)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(event.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(event.date)
                    .font(.headline)
                    .foregroundColor(Color(hex: "#BDBDBD")) // Light gray for date
                
                Text(event.displayLocation)
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#BDBDBD")) // Light gray for location
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color(hex: "#1C1C23")) // Dark background
            
            // Fight Card Section (removed "Fight Card" text)
            VStack(spacing: 16) {
                // Main Card Section
                VStack(spacing: 8) {
                    Button(action: {
                        withAnimation {
                            showMainCard.toggle()
                        }
                    }) {
                        HStack {
                            Text("Main Card")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(Color.white)
                            
                            Spacer()
                            
                            Image(systemName: showMainCard ? "chevron.up" : "chevron.down")
                                .foregroundColor(Color.white)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(hex: "#1C1C23").opacity(0.7)) // Dark background instead of red
                        .cornerRadius(8)
                    }
                    
                    if showMainCard {
                        Divider()
                            .background(Color(hex: "#9E9E9E").opacity(0.3)) // Gray for dividers
                        
                        // Main Event is always shown
                        if event.fights.count > 0 {
                            fightRow(fight: event.fights[0])
                        }
                        
                        // Show remaining main card fights (1-5)
                        if event.fights.count > 1 {
                            ForEach(1..<min(6, event.fights.count), id: \.self) { index in
                                Divider()
                                    .background(Color(hex: "#9E9E9E").opacity(0.2)) // Gray for dividers
                                fightRow(fight: event.fights[index])
                            }
                        }
                    }
                }
                
                // Preliminary Card Section
                if event.fights.count > 6 {
                    VStack(spacing: 8) {
                        Button(action: {
                            withAnimation {
                                showPrelims.toggle()
                            }
                        }) {
                            HStack {
                                Text("Preliminary Card")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.white)
                                
                                Spacer()
                                
                                Image(systemName: showPrelims ? "chevron.up" : "chevron.down")
                                    .foregroundColor(Color.white)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(hex: "#1C1C23").opacity(0.7)) // Dark background instead of gray
                            .cornerRadius(8)
                        }
                        
                        if showPrelims {
                            Divider()
                                .background(Color(hex: "#9E9E9E").opacity(0.3)) // Gray for dividers
                            
                            ForEach(6..<event.fights.count, id: \.self) { index in
                                if index > 6 {
                                    Divider()
                                        .background(Color(hex: "#9E9E9E").opacity(0.2)) // Gray for dividers
                                }
                                fightRow(fight: event.fights[index])
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(hex: "#1C1C23")) // Dark background for fight card
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
        .fullScreenCover(item: $selectedFighter) { fighter in
            FighterProfileView(
                fighter: fighter,
                onDismiss: {
                    debugPrint("🔵 Fighter profile dismissed for: \(fighter.name)")
                    selectedFighter = nil
                }
            )
        }
    }
    
    private func loadFighterData(name: String, id: Int) {
        debugPrint("🔵 Selected fighter from event card: \(name) (ID: \(id))")
        
        // Try to load by ID first, then fall back to name
        var fighter = FighterDataManager.shared.getFighterByID(id)
        
        // Fall back to name lookup if ID lookup fails
        if fighter == nil {
            fighter = FighterDataManager.shared.getFighter(name)
        }
        
        if let fighter = fighter {
            debugPrint("✅ Successfully loaded data for: \(name)")
            selectedFighter = fighter
        } else {
            debugPrint("⚠️ Could not load fighter data for: \(name) (ID: \(id))")
        }
    }
    
    private func fightRow(fight: Fight) -> some View {
        VStack(spacing: 8) {
            // Fight type label
            if fight.isMainEvent || fight.isTitleFight {
                HStack(spacing: 8) {
                    if fight.isMainEvent {
                        Text("Main Event")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(hex: "#333333").opacity(0.6)) // Darker, more subtle background
                            .foregroundColor(Color(hex: "#BDBDBD").opacity(0.8)) // Lighter gray text with some opacity
                            .cornerRadius(3)
                    }
                    
                    if fight.isTitleFight {
                        Text("Title Fight")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "#FFD700")) // Gold
                            .foregroundColor(Color(hex: "#1C1C23")) // Dark text
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // All in one row: fighters, weight class, and prediction button
            HStack(spacing: 4) {
                // Red corner with abbreviated name
                Button(action: {
                    loadFighterData(name: fight.redCorner, id: fight.redCornerID)
                }) {
                    Text(abbreviateName(fight.redCorner))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#FFD700")) // Gold color for left fighter
                        .lineLimit(1)
                        .underline(FighterDataManager.shared.getFighter(fight.redCorner) != nil)
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("vs")
                    .font(.caption2)
                    .foregroundColor(Color.gray)
                    .padding(.horizontal, 2)
                
                // Blue corner with abbreviated name
                Button(action: {
                    loadFighterData(name: fight.blueCorner, id: fight.blueCornerID)
                }) {
                    Text(abbreviateName(fight.blueCorner))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(hex: "#FF9800")) // Orange color for right fighter
                        .lineLimit(1)
                        .underline(FighterDataManager.shared.getFighter(fight.blueCorner) != nil)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Weight class
                Text(fight.weightClass)
                    .font(.caption2)
                    .foregroundColor(Color(hex: "#9E9E9E")) // Gray for weight class
                    .lineLimit(1)
                
                // Only show prediction button if not a past event
                if !isPastEvent {
                    // Prediction button
                    Button(action: {
                        requestFightPrediction(fight: fight)
                    }) {
                        Text("🔮")
                            .font(.caption)
                            .padding(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                    .padding(.leading, 4)
                    .buttonStyle(BorderlessButtonStyle())
                    .hoverEffect(.highlight)
                    .help("Generate AI fight prediction")
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Helper function to abbreviate first names
    private func abbreviateName(_ fullName: String) -> String {
        let components = fullName.components(separatedBy: " ")
        if components.count > 1 {
            // Get first letter of first name and add period
            let firstInitial = String(components[0].prefix(1))
            
            // Join with the rest of the name components
            let lastName = components.dropFirst().joined(separator: " ")
            return "\(firstInitial). \(lastName)"
        }
        return fullName // Return original if can't split
    }
    
    private func requestFightPrediction(fight: Fight) {
        // Get the fighter IDs directly from the data manager
        let redFighter = FighterDataManager.shared.getFighter(fight.redCorner)
        let blueFighter = FighterDataManager.shared.getFighter(fight.blueCorner)
        
        // Use the IDs from the fighter objects, not from the Fight model
        let redID = redFighter?.fighterID ?? 0
        let blueID = blueFighter?.fighterID ?? 0
        
        // Create ID-based matchup string in format "ID1 vs ID2"
        let idMatchup = "\(redID) vs \(blueID)"
        
        // Add "(5 rounder)" to the prompt if this is a main event
        let predictionPrompt = fight.isMainEvent ? "\(idMatchup) (5 rounder)" : idMatchup
        
        // Log the IDs to debug
        debugPrint("🔵 Requesting prediction for fighters - red: \(fight.redCorner) (ID: \(redID)), blue: \(fight.blueCorner) (ID: \(blueID))")
        
        // Create notification to show prediction is being processed
        NotificationCenter.default.post(
            name: NSNotification.Name("RequestFightPrediction"),
            object: nil,
            userInfo: [
                "prompt": predictionPrompt,
                "redCornerID": redID,
                "blueCornerID": blueID,
                "isMainEvent": fight.isMainEvent,
                "weightClass": fight.weightClass
            ]
        )
    }
}

#Preview {
    VStack {
        if let upcomingEvent = FighterDataManager.shared.getUpcomingEvents().first {
            EventCard(event: upcomingEvent, defaultPrelimsExpanded: true)
                .padding()
        } else {
            // Fallback to sample data if no dynamic data is available
            EventCard(event: EventInfo(
                name: "UFC Fight Night 254 London",
                date: "March 22, 2025",
                location: "London, UK",
                venue: "O2 Arena",
                fights: [
                    Fight(redCorner: "Leon Edwards", blueCorner: "Sean Brady", redCornerID: 1, blueCornerID: 2, weightClass: "Welterweight", isMainEvent: true, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Jan Błachowicz", blueCorner: "Carlos Ulberg", redCornerID: 6, blueCornerID: 7, weightClass: "Light Heavyweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Gunnar Nelson", blueCorner: "Kevin Holland", redCornerID: 8, blueCornerID: 9, weightClass: "Welterweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Molly McCann", blueCorner: "Alexia Thainara", redCornerID: 10, blueCornerID: 11, weightClass: "Women's Strawweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Jordan Vucenic", blueCorner: "Chris Duncan", redCornerID: 12, blueCornerID: 13, weightClass: "Lightweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Nathaniel Wood", blueCorner: "Morgan Charriere", redCornerID: 14, blueCornerID: 15, weightClass: "Featherweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A")
                ]
            ), defaultPrelimsExpanded: true)
                .padding()
        }
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
    .onAppear {
        // Initialize fighter data in preview
        let dataManager = FighterDataManager.shared
        
        // Manually trigger data loading for preview
        Task {
            do {
                try await dataManager.refreshData()
            } catch {
                print("⚠️ Error loading data in preview: \(error)")
            }
        }
        
        // Debug check to see which fighters have data
        for fighter in ["Leon Edwards", "Sean Brady", "Kevin Holland", "Gunnar Nelson"] {
            if let fighterData = dataManager.getFighter(fighter) {
                print("✅ Found data for \(fighter): \(fighterData.record)")
            } else {
                print("❌ No data found for \(fighter)")
            }
            
            if let fightHistory = dataManager.getFightHistory(fighter) {
                print("✅ Found \(fightHistory.count) fight history records for \(fighter)")
            } else {
                print("❌ No fight history found for \(fighter)")
            }
        }
    }
}

// AppTheme and FighterProfileView should be imported from their respective files
// Don't define them here
