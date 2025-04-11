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
    @State private var showAllFights = false
    @State private var showMainCard = true
    @State private var showPrelims = false
    @State private var selectedFighter: FighterStats? = nil
    
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
                    .foregroundColor(Color.yellow)
                
                Text(event.displayLocation)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(Color.red)
            
            // Fight Card
            VStack(spacing: 16) {
                Text("Fight Card")
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
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
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(8)
                    }
                    
                    if showMainCard {
                        Divider()
                            .background(AppTheme.accent.opacity(0.3))
                        
                        // Main Event is always shown
                        if event.fights.count > 0 {
                            fightRow(fight: event.fights[0])
                        }
                        
                        // Show remaining main card fights (1-5)
                        if event.fights.count > 1 {
                            ForEach(1..<min(6, event.fights.count), id: \.self) { index in
                                Divider()
                                    .background(AppTheme.accent.opacity(0.2))
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
                            .background(Color.gray.opacity(0.7))
                            .cornerRadius(8)
                        }
                        
                        if showPrelims {
                            Divider()
                                .background(AppTheme.accent.opacity(0.3))
                            
                            ForEach(6..<event.fights.count, id: \.self) { index in
                                if index > 6 {
                                    Divider()
                                        .background(AppTheme.accent.opacity(0.2))
                                }
                                fightRow(fight: event.fights[index])
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(red: 0.2, green: 0.2, blue: 0.25))
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
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    if fight.isTitleFight {
                        Text("Title Fight")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.yellow)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                    }
                    
                    Spacer()
                }
            }
            
            // Fighter names
            HStack {
                Button(action: {
                    loadFighterData(name: fight.redCorner, id: fight.redCornerID)
                }) {
                    Text(fight.redCorner)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                        .underline(FighterDataManager.shared.getFighterByID(fight.redCornerID) != nil || 
                                 FighterDataManager.shared.getFighter(fight.redCorner) != nil)
                }
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
                
                Button(action: {
                    loadFighterData(name: fight.blueCorner, id: fight.blueCornerID)
                }) {
                    Text(fight.blueCorner)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accent)
                        .underline(FighterDataManager.shared.getFighterByID(fight.blueCornerID) != nil || 
                                 FighterDataManager.shared.getFighter(fight.blueCorner) != nil)
                }
                
                Spacer()
                
                Text(fight.weightClass)
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
    }
}

#Preview {
    VStack {
        if let upcomingEvent = FighterDataManager.shared.getUpcomingEvents().first {
            EventCard(event: upcomingEvent)
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
            ))
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
