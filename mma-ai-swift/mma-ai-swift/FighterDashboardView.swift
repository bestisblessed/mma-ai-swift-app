import SwiftUI

struct FighterDashboardView: View {
    @State private var selectedDivision = "All"
    @State private var searchText = ""
    @State private var selectedFighter: FighterStats? = nil
    @State private var selectedFight: FightDetails? = nil
    @StateObject private var viewModel = FighterDashboardViewModel()
    @State private var selectedTab = 0 // 0 for Fighters, 1 for Fights
    
    private let divisions = ["All", "Heavyweight", "Light Heavyweight", "Middleweight", "Welterweight", "Lightweight", "Featherweight", "Bantamweight", "Flyweight"]
    
    var body: some View {
        VStack {
            // Section selector
            Picker("Database Section", selection: $selectedTab) {
                Text("Fighters").tag(0)
                Text("Fights").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.top, 8)
            
            if selectedTab == 0 {
                // FIGHTERS TAB
                // Division selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(divisions, id: \.self) { division in
                            Button(action: {
                                selectedDivision = division
                            }) {
                                Text(division)
                                    .fontWeight(selectedDivision == division ? .bold : .medium)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedDivision == division ? AppTheme.accent : Color.clear)
                                    .foregroundColor(selectedDivision == division ? .white : AppTheme.textPrimary)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search fighters", text: $searchText)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading fighters...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    // Fighter grid
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            ForEach(filteredFighters, id: \.name) { fighter in
                                FighterTileView(fighter: fighter) {
                                    debugPrint("🔵 Selected fighter: \(fighter.name)")
                                    selectedFighter = fighter
                                }
                            }
                        }
                        .padding()
                    }
                }
            } else {
                // FIGHTS TAB
                // Search bar for fights
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search fights", text: $searchText)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(10)
                .background(AppTheme.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 8)
                
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading fights...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else {
                    // Fights list
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.getFilteredFights(searchText: searchText), id: \.id) { fight in
                                FightTileView(fight: fight) {
                                    debugPrint("🔵 Selected fight: \(fight.redCorner) vs \(fight.blueCorner)")
                                    selectedFight = viewModel.getFightDetails(for: fight)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadFighters()
            viewModel.loadFights()
        }
        .fullScreenCover(item: $selectedFighter) { fighter in
            FighterProfileView(
                fighter: fighter,
                onDismiss: {
                    debugPrint("🔵 Fighter profile dismissed for: \(fighter.name)")
                    selectedFighter = nil
                }
            )
        }
        .fullScreenCover(item: $selectedFight) { fightDetails in
            FightProfileView(
                fightDetails: fightDetails,
                onDismiss: {
                    debugPrint("🔵 Fight profile dismissed for: \(fightDetails.redCorner) vs \(fightDetails.blueCorner)")
                    selectedFight = nil
                }
            )
        }
    }
    
    private var filteredFighters: [FighterStats] {
        viewModel.getFilteredFighters(division: selectedDivision, searchText: searchText)
    }
}

// Fight details struct with all data from the event CSV
struct FightDetails: Identifiable {
    var id: String { "\(redCorner)-\(blueCorner)-\(date)" }
    let eventName: String
    let date: String
    let redCorner: String
    let blueCorner: String
    let weightClass: String
    let winner: String
    let method: String
    let round: String
    let time: String
    let isMainEvent: Bool
    let isTitleFight: Bool
    
    // Add references to fighter stats for easy access
    var redCornerStats: FighterStats?
    var blueCornerStats: FighterStats?
}

@MainActor
class FighterDashboardViewModel: ObservableObject {
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var fights: [Fight] = []
    @Published private(set) var fightDetails: [String: FightDetails] = [:]
    @Published private(set) var isLoading = true
    
    func loadFighters() {
        debugPrint("🔵 Loading fighters in dashboard")
        isLoading = true
        
        // Load fighters from FighterDataManager
        DispatchQueue.global().async { [weak self] in
            let loadedFighters = FighterDataManager.shared.fighters
            
            DispatchQueue.main.async {
                self?.fighters = loadedFighters
                self?.isLoading = false
                debugPrint("✅ Loaded \(loadedFighters.count) fighters in dashboard")
            }
        }
    }
    
    func loadFights() {
        debugPrint("🔵 Loading fights in dashboard")
        
        // Extract fights from fighter history to create a unified fight list
        DispatchQueue.global().async { [weak self] in
            var allFights: [Fight] = []
            var allFightDetails: [String: FightDetails] = [:]
            let fightHistory = FighterDataManager.shared.fightHistory
            let eventDetails = FighterDataManager.shared.eventDetails
            
            // Process each fighter's history
            for (fighter, results) in fightHistory {
                for result in results {
                    // Only add each fight once by checking if red corner is the current fighter
                    let isRedCorner = fighter < result.opponent
                    
                    if isRedCorner {
                        let fight = Fight(
                            redCorner: fighter,
                            blueCorner: result.opponent,
                            weightClass: FighterDataManager.shared.fighters[fighter]?.weightClass ?? "Unknown",
                            isMainEvent: false,
                            isTitleFight: false,
                            round: "N/A",
                            time: "N/A"
                        )
                        allFights.append(fight)
                        
                        // Create fight details for this fight
                        let fightId = "\(fighter)-\(result.opponent)-\(result.date)"
                        let details = self?.createFightDetails(
                            fighter: fighter,
                            result: result,
                            eventDetails: eventDetails
                        )
                        
                        if let details = details {
                            allFightDetails[fightId] = details
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self?.fights = allFights
                self?.fightDetails = allFightDetails
                debugPrint("✅ Loaded \(allFights.count) fights with \(allFightDetails.count) detailed records in dashboard")
            }
        }
    }
    
    private func createFightDetails(fighter: String, result: FightResult, eventDetails: [String: EventInfo]) -> FightDetails {
        // Try to find the event
        if let eventDetail = eventDetails[result.event] {
            // Find the specific fight in the event
            let fightDetail = eventDetail.fights.first { 
                ($0.redCorner == fighter && $0.blueCorner == result.opponent) ||
                ($0.redCorner == result.opponent && $0.blueCorner == fighter)
            }
            
            // If we found the specific fight
            if let fightDetail = fightDetail {
                // Create detailed fight record
                return FightDetails(
                    eventName: result.event,
                    date: result.date,
                    redCorner: fighter,
                    blueCorner: result.opponent,
                    weightClass: FighterDataManager.shared.fighters[fighter]?.weightClass ?? "Unknown",
                    winner: result.outcome == "Win" ? fighter : result.opponent,
                    method: result.method,
                    round: eventDetail.fights.first?.round ?? "N/A",
                    time: eventDetail.fights.first?.time ?? "N/A",
                    isMainEvent: fightDetail.isMainEvent,
                    isTitleFight: fightDetail.isTitleFight,
                    redCornerStats: FighterDataManager.shared.fighters[fighter],
                    blueCornerStats: FighterDataManager.shared.fighters[result.opponent]
                )
            } else {
                // Fallback if no specific fight details found
                return createBasicFightDetails(fighter: fighter, result: result, isTitleFight: result.method.lowercased().contains("title"))
            }
        } else {
            // Create basic fight details if event not found
            return createBasicFightDetails(fighter: fighter, result: result, isTitleFight: result.method.lowercased().contains("title"))
        }
    }
    
    private func createBasicFightDetails(fighter: String, result: FightResult, isTitleFight: Bool) -> FightDetails {
        return FightDetails(
            eventName: result.event,
            date: result.date,
            redCorner: fighter,
            blueCorner: result.opponent,
            weightClass: FighterDataManager.shared.fighters[fighter]?.weightClass ?? "Unknown",
            winner: result.outcome == "Win" ? fighter : result.opponent,
            method: result.method,
            round: "N/A",
            time: "N/A",
            isMainEvent: false,
            isTitleFight: isTitleFight,
            redCornerStats: FighterDataManager.shared.fighters[fighter],
            blueCornerStats: FighterDataManager.shared.fighters[result.opponent]
        )
    }
    
    func getFilteredFighters(division: String, searchText: String) -> [FighterStats] {
        var result = fighters.values.map { $0 }
        
        // Filter by division
        if division != "All" {
            if division == "Women's" {
                result = result.filter { $0.weightClass.contains("Women") }
            } else {
                result = result.filter { $0.weightClass == division }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.nickname?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
        
        // Sort alphabetically
        return result.sorted { $0.name < $1.name }
    }
    
    func getFilteredFights(searchText: String) -> [FightWithId] {
        // Convert Fight to FightWithId for easy identification
        let fightsWithId = fights.enumerated().map { index, fight in
            FightWithId(
                id: String(index),
                redCorner: fight.redCorner,
                blueCorner: fight.blueCorner,
                weightClass: fight.weightClass,
                isMainEvent: fight.isMainEvent,
                isTitleFight: fight.isTitleFight,
                round: fight.round,
                time: fight.time
            )
        }
        
        // Filter by search text
        if searchText.isEmpty {
            return fightsWithId
        } else {
            return fightsWithId.filter {
                $0.redCorner.lowercased().contains(searchText.lowercased()) ||
                $0.blueCorner.lowercased().contains(searchText.lowercased()) ||
                $0.weightClass.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
    func getFightDetails(for fight: FightWithId) -> FightDetails? {
        // Create an ID to look up the fight details
        let redCorner = fight.redCorner < fight.blueCorner ? fight.redCorner : fight.blueCorner
        let blueCorner = fight.redCorner < fight.blueCorner ? fight.blueCorner : fight.redCorner
        
        // Try to find the fight details
        for (_, detail) in fightDetails {
            if (detail.redCorner == redCorner && detail.blueCorner == blueCorner) ||
               (detail.redCorner == blueCorner && detail.blueCorner == redCorner) {
                return detail
            }
        }
        
        // Fallback: create a basic FightDetails object if we can't find the detailed record
        return FightDetails(
            eventName: "UFC Event",
            date: "N/A",
            redCorner: fight.redCorner,
            blueCorner: fight.blueCorner,
            weightClass: fight.weightClass,
            winner: "Unknown",
            method: "N/A",
            round: "N/A",
            time: "N/A",
            isMainEvent: fight.isMainEvent,
            isTitleFight: fight.isTitleFight,
            redCornerStats: fighters[fight.redCorner],
            blueCornerStats: fighters[fight.blueCorner]
        )
    }
}

// Add an ID field to Fight for ForEach usage
struct FightWithId: Identifiable {
    let id: String
    let redCorner: String
    let blueCorner: String
    let weightClass: String
    let isMainEvent: Bool
    let isTitleFight: Bool
    let round: String
    let time: String
}
//
//struct FighterTileView: View {
//    let fighter: FighterStats
//    let onTap: () -> Void
//    
//    var body: some View {
//        Button(action: onTap) {
//            VStack(alignment: .leading, spacing: 6) {
//                Text(fighter.name)
//                    .font(.headline)
//                    .foregroundColor(AppTheme.textPrimary)
//                    .lineLimit(1)
//                
//                if let nickname = fighter.nickname {
//                    Text("'\(nickname)'")
//                        .font(.caption)
//                        .foregroundColor(AppTheme.accent)
//                        .lineLimit(1)
//                }
//                
//                Text(fighter.record)
//                    .font(.callout)
//                    .foregroundColor(.secondary)
//                
//                Text(fighter.weightClass)
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.top, 2)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            .padding()
//            .background(AppTheme.cardBackground)
//            .cornerRadius(10)
//        }
//    }
//}
struct FighterTileView: View {
    let fighter: FighterStats
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) { // Reduce spacing
                Text(fighter.name)
                    .font(.subheadline) // Smaller font
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                if let nickname = fighter.nickname {
                    Text("'\(nickname)'")
                        .font(.caption2) // Smaller font
                        .foregroundColor(AppTheme.accent)
                        .lineLimit(1)
                }
                
                Text(fighter.record)
                    .font(.caption2) // Smaller font
                    .foregroundColor(.secondary)

                Text(fighter.weightClass)
                    .font(.caption2) // Smaller font
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8) // Decrease padding
            .background(AppTheme.cardBackground)
            .cornerRadius(8) // Smaller corners
        }
    }
}

struct FightTileView: View {
    let fight: FightWithId
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text(fight.redCorner)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if let record = FighterDataManager.shared.getFighter(fight.redCorner)?.record {
                            Text(record)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Text("vs")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accent)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(fight.blueCorner)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        if let record = FighterDataManager.shared.getFighter(fight.blueCorner)?.record {
                            Text(record)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack {
                    Text(fight.weightClass)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if fight.isTitleFight {
                        Text("Title Fight")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent.opacity(0.2))
                            .cornerRadius(4)
                    }
                    
                    if fight.isMainEvent {
                        Text("Main Event")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.accent.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(10)
        }
    }
}

struct FightProfileView: View {
    let fightDetails: FightDetails
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Main fight card header
                    VStack(spacing: 6) {
                        Text(fightDetails.eventName)
                            .font(.headline)
                            .foregroundColor(AppTheme.accent)
                            .multilineTextAlignment(.center)
                        
                        Text(fightDetails.date)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        
                        if fightDetails.isMainEvent {
                            Text("Main Event")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.accent)
                                .cornerRadius(8)
                                .padding(.top, 5)
                        }
                        
                        if fightDetails.isTitleFight {
                            Text("Title Fight")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.accent)
                                .cornerRadius(8)
                                .padding(.top, 5)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    
                    // Fighters vs section
                    HStack(alignment: .top, spacing: 20) {
                        // Red corner
                        VStack(spacing: 8) {
                            Text(fightDetails.redCorner)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            if let stats = fightDetails.redCornerStats {
                                Text(stats.record)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                if let nickname = stats.nickname {
                                    Text("'\(nickname)'")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.accent)
                                        .italic()
                                }
                            }
                            
                            // Highlight the winner
                            if fightDetails.winner == fightDetails.redCorner {
                                Text("Winner")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                    .padding(.top, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(10)
                        
                        Text("vs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accent)
                            .padding(.top, 20)
                        
                        // Blue corner
                        VStack(spacing: 8) {
                            Text(fightDetails.blueCorner)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            if let stats = fightDetails.blueCornerStats {
                                Text(stats.record)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                
                                if let nickname = stats.nickname {
                                    Text("'\(nickname)'")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.accent)
                                        .italic()
                                }
                            }
                            
                            // Highlight the winner
                            if fightDetails.winner == fightDetails.blueCorner {
                                Text("Winner")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.green)
                                    .cornerRadius(8)
                                    .padding(.top, 5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(10)
                    }
                    
                    // Fight details section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fight Details")
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Group {
                            detailRow(label: "Weight Class", value: fightDetails.weightClass)
                            detailRow(label: "Method", value: fightDetails.method)
                            if fightDetails.round != "N/A" {
                                detailRow(label: "Round", value: fightDetails.round)
                            }
                            if fightDetails.time != "N/A" {
                                detailRow(label: "Time", value: fightDetails.time)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Fight Details")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .background(AppTheme.background.ignoresSafeArea())
        }
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    FighterDashboardView()
        .preferredColorScheme(.dark)
} 
