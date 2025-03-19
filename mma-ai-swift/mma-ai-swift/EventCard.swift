import SwiftUI
import Foundation

struct Fight {
    let redCorner: String
    let blueCorner: String
    let weightClass: String
    let isMainEvent: Bool
    let isTitleFight: Bool
}

struct EventInfo {
    let name: String
    let date: String
    let location: String
    let venue: String
    let fights: [Fight]
}

struct FightResult {
    let opponent: String
    let outcome: String // Win or Loss
    let method: String  // e.g., "Decision (Unanimous)", "KO (Punch)"
    let date: String
    let event: String
}

// Data manager for fighters
class FighterDataManager {
    static let shared = FighterDataManager()
    
    var fighters: [String: FighterStats] = [:]
    var fightHistory: [String: [FightResult]] = [:]
    
    init() {
        verifyDataFiles()
        loadFighterData()
        loadFightHistory()
    }
    
    // Utility function to verify CSV file paths
    private func verifyDataFiles() {
        print("Verifying data files...")
        
        // Check bundle paths
        if let bundlePath = Bundle.main.resourcePath {
            print("Bundle resource path: \(bundlePath)")
        }
        
        // List contents of data directory if it exists
        if let dataPath = Bundle.main.path(forResource: "", ofType: "", inDirectory: "data") {
            print("Data directory found at: \(dataPath)")
            
            do {
                let fileManager = FileManager.default
                let items = try fileManager.contentsOfDirectory(atPath: dataPath)
                print("Data directory contents: \(items)")
            } catch {
                print("Failed to list data directory contents: \(error)")
            }
        } else {
            print("Data directory not found in bundle!")
            
            // Try to find CSV files directly
            let fighterCSVPath = Bundle.main.path(forResource: "fighter_info", ofType: "csv")
            let eventCSVPath = Bundle.main.path(forResource: "event_data_sherdog", ofType: "csv")
            
            print("Directly searching for CSV files:")
            print("fighter_info.csv path: \(fighterCSVPath ?? "Not found")")
            print("event_data_sherdog.csv path: \(eventCSVPath ?? "Not found")")
        }
    }
    
    func loadFighterData() {
        print("Loading fighter data from CSV...")
        
        // Try multiple paths to locate the CSV file
        var fighterCSVPath: String? = Bundle.main.path(forResource: "fighter_info", ofType: "csv", inDirectory: "data")
        
        // Fallback options if the file isn't found in the data directory
        if fighterCSVPath == nil {
            // Try without directory specification
            fighterCSVPath = Bundle.main.path(forResource: "fighter_info", ofType: "csv")
        }
        
        if fighterCSVPath == nil {
            // Try with documentation directory
            if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let potentialPath = docDir.appendingPathComponent("fighter_info.csv").path
                if FileManager.default.fileExists(atPath: potentialPath) {
                    fighterCSVPath = potentialPath
                }
            }
        }
        
        // Check if we found a valid path
        guard let finalPath = fighterCSVPath else {
            print("Error: fighter_info.csv not found in any expected location")
            loadSampleFighterData() // Fallback to sample data if file not found
            return
        }
        
        do {
            let csvString = try String(contentsOfFile: finalPath, encoding: .utf8)
            let rows = csvString.components(separatedBy: "\n")
            
            // Skip header row
            for i in 1..<rows.count {
                let row = rows[i]
                if row.isEmpty { continue }
                
                let columns = parseCSVRow(row)
                if columns.count >= 17 { // Ensure we have enough columns
                    let name = columns[0]
                    let nickname = columns[1].isEmpty || columns[1] == "-" ? nil : columns[1]
                    let birthDate = columns[2]
                    let _ = columns[3]  // nationality
                    let _ = columns[4]  // hometown
                    let team = columns[5]
                    let weightClass = columns[6]
                    let height = columns[7]
                    
                    // Parse record from wins and losses
                    let wins = Int(columns[8]) ?? 0
                    let losses = Int(columns[9]) ?? 0
                    let record = "\(wins)-\(losses)-0" // Simplifying for now, not including draws
                    
                    fighters[name] = FighterStats(
                        name: name,
                        nickname: nickname,
                        record: record,
                        weightClass: weightClass,
                        age: calculateAge(from: birthDate),
                        height: height,
                        reach: "N/A", // Not in our CSV data
                        stance: "N/A", // Not in our CSV data
                        teamAffiliation: team
                    )
                }
            }
            
            print("Successfully loaded \(fighters.count) fighters from CSV")
        } catch {
            print("Error loading fighter_info.csv: \(error)")
            loadSampleFighterData() // Fallback to sample data if file can't be read
        }
    }
    
    // Helper function to parse CSV row (handles quoted fields with commas)
    private func parseCSVRow(_ row: String) -> [String] {
        var columns: [String] = []
        var currentField = ""
        var inQuotes = false
        
        for char in row {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                columns.append(currentField)
                currentField = ""
            } else {
                currentField.append(char)
            }
        }
        columns.append(currentField) // Add the last field
        
        return columns
    }
    
    func loadFightHistory() {
        print("Loading fight history from CSV...")
        
        // Try multiple paths to locate the CSV file
        var eventCSVPath: String? = Bundle.main.path(forResource: "event_data_sherdog", ofType: "csv", inDirectory: "data")
        
        // Fallback options if the file isn't found in the data directory
        if eventCSVPath == nil {
            // Try without directory specification
            eventCSVPath = Bundle.main.path(forResource: "event_data_sherdog", ofType: "csv")
        }
        
        if eventCSVPath == nil {
            // Try with documentation directory
            if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let potentialPath = docDir.appendingPathComponent("event_data_sherdog.csv").path
                if FileManager.default.fileExists(atPath: potentialPath) {
                    eventCSVPath = potentialPath
                }
            }
        }
        
        // Check if we found a valid path
        guard let finalPath = eventCSVPath else {
            print("Error: event_data_sherdog.csv not found in any expected location")
            loadSampleFightHistory() // Fallback to sample data if file not found
            return
        }
        
        do {
            let csvString = try String(contentsOfFile: finalPath, encoding: .utf8)
            let rows = csvString.components(separatedBy: "\n")
            
            // Temporary dictionary to organize fights by fighter
            var tempFightHistory: [String: [FightResult]] = [:]
            
            // Skip header row
            for i in 1..<rows.count {
                let row = rows[i]
                if row.isEmpty { continue }
                
                let columns = parseCSVRow(row)
                if columns.count >= 14 { // Ensure we have enough columns
                    let eventName = columns[0]
                    let eventDate = formatDate(columns[2])
                    let fighter1 = columns[3]
                    let fighter2 = columns[4]
                    let _ = columns[7]  // weightClass
                    let winner = columns[8]
                    let method = columns[9]
                    
                    // Create fight results for fighter 1
                    let outcome1 = fighter1 == winner ? "Win" : "Loss"
                    let result1 = FightResult(
                        opponent: fighter2,
                        outcome: outcome1,
                        method: method,
                        date: eventDate,
                        event: eventName
                    )
                    
                    // Create fight results for fighter 2
                    let outcome2 = fighter2 == winner ? "Win" : "Loss"
                    let result2 = FightResult(
                        opponent: fighter1,
                        outcome: outcome2,
                        method: method,
                        date: eventDate,
                        event: eventName
                    )
                    
                    // Add to our temp dictionary
                    if tempFightHistory[fighter1] == nil {
                        tempFightHistory[fighter1] = []
                    }
                    tempFightHistory[fighter1]?.append(result1)
                    
                    if tempFightHistory[fighter2] == nil {
                        tempFightHistory[fighter2] = []
                    }
                    tempFightHistory[fighter2]?.append(result2)
                }
            }
            
            // Sort fights by date (newest first) and limit to 3 most recent
            for (fighter, fights) in tempFightHistory {
                // Sort by date (newest first)
                let sortedFights = fights.sorted { fight1, fight2 in
                    return compareDates(fight1.date, fight2.date)
                }
                
                // Keep only the 3 most recent fights
                fightHistory[fighter] = Array(sortedFights.prefix(3))
            }
            
            print("Successfully loaded fight history for \(fightHistory.count) fighters from CSV")
        } catch {
            print("Error loading event_data_sherdog.csv: \(error)")
            loadSampleFightHistory() // Fallback to sample data if file can't be read
        }
    }
    
    // Helper function to format ISO date to readable format
    private func formatDate(_ isoDateString: String) -> String {
        // Handle ISO date format (2024-11-09T00:00:00+00:00)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        
        if let date = dateFormatter.date(from: isoDateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateFormat = "MMM d, yyyy"
            return outputFormatter.string(from: date)
        }
        
        return isoDateString // Return original string if parsing fails
    }
    
    // Helper function to compare dates for sorting
    private func compareDates(_ date1: String, _ date2: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let d1 = dateFormatter.date(from: date1),
              let d2 = dateFormatter.date(from: date2) else {
            return false
        }
        
        return d1 > d2 // Return true if date1 is newer than date2
    }
    
    private func calculateAge(from birthDateString: String) -> Int {
        // Simple age calculation from birth date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let birthDate = dateFormatter.date(from: birthDateString) else {
            return 0
        }
        
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }
    
    // Fallback method if CSV loading fails
    private func loadSampleFighterData() {
        print("Loading sample fighter data as fallback...")
        
        fighters["Leon Edwards"] = FighterStats(
            name: "Leon Edwards",
            nickname: "Rocky",
            record: "22-4-0, 1NC",
            weightClass: "Welterweight",
            age: 33,
            height: "6'0\"",
            reach: "N/A",
            stance: "N/A",
            teamAffiliation: "Team Renegade"
        )
        
        fighters["Sean Brady"] = FighterStats(
            name: "Sean Brady",
            nickname: nil,
            record: "17-1-0",
            weightClass: "Welterweight",
            age: 31,
            height: "5'10\"",
            reach: "N/A",
            stance: "N/A",
            teamAffiliation: "Renzo Gracie Philly"
        )
        
        // Add a few more important fighters from our event
        fighters["Kevin Holland"] = FighterStats(
            name: "Kevin Holland",
            nickname: "Trailblazer",
            record: "26-13-0, 1NC",
            weightClass: "Welterweight",
            age: 32,
            height: "6'3\"",
            reach: "N/A",
            stance: "N/A",
            teamAffiliation: "Phalanx MMA Academy"
        )
        
        fighters["Gunnar Nelson"] = FighterStats(
            name: "Gunnar Nelson",
            nickname: "Gunni",
            record: "19-5-1",
            weightClass: "Welterweight",
            age: 36,
            height: "5'11\"",
            reach: "N/A",
            stance: "N/A",
            teamAffiliation: "Mjölnir MMA"
        )
        
        print("Loaded \(fighters.count) sample fighters")
    }
    
    // Fallback method if CSV loading fails
    private func loadSampleFightHistory() {
        print("Loading sample fight history as fallback...")
        
        fightHistory["Leon Edwards"] = [
            FightResult(
                opponent: "Colby Covington",
                outcome: "Win",
                method: "Decision (Unanimous)",
                date: "Dec 16, 2023",
                event: "UFC 296"
            ),
            FightResult(
                opponent: "Kamaru Usman",
                outcome: "Win",
                method: "Decision (Majority)",
                date: "Mar 18, 2023",
                event: "UFC 286"
            ),
            FightResult(
                opponent: "Kamaru Usman",
                outcome: "Win",
                method: "KO (Head Kick)",
                date: "Aug 20, 2022",
                event: "UFC 278"
            )
        ]
        
        fightHistory["Sean Brady"] = [
            FightResult(
                opponent: "Gilbert Burns",
                outcome: "Win",
                method: "Decision (Unanimous)",
                date: "Sep 7, 2024",
                event: "UFC Fight Night 242"
            ),
            FightResult(
                opponent: "Kelvin Gastelum",
                outcome: "Win",
                method: "Submission (Arm-Triangle Choke)",
                date: "Dec 2, 2023",
                event: "UFC Fight Night 233"
            ),
            FightResult(
                opponent: "Belal Muhammad",
                outcome: "Loss",
                method: "TKO (Punches)",
                date: "Oct 22, 2022",
                event: "UFC 280"
            )
        ]
        
        print("Loaded sample fight history for \(fightHistory.count) fighters")
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        return fighters[name]
    }
    
    func getFightHistory(_ name: String) -> [FightResult]? {
        return fightHistory[name]
    }
    
    // Preload fighter and history data, returning the fighter if loaded successfully
    func preloadFighterData(for name: String) -> FighterStats? {
        print("🔄 Pre-loading data for fighter: \(name)")
        
        // First check if fighter exists
        guard let fighter = getFighter(name) else {
            print("❌ Fighter not found: \(name)")
            return nil
        }
        
        // Ensure history is loaded too
        _ = getFightHistory(name)
        
        // Return the fighter data
        return fighter
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
                
                Text("\(event.venue) • \(event.location)")
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
    
    private func loadFighterData(name: String) {
        debugPrint("🔵 Selected fighter from event card: \(name)")
        
        // Pre-load data and show profile
        if let fighter = FighterDataManager.shared.getFighter(name) {
            debugPrint("✅ Successfully loaded data for: \(name)")
            selectedFighter = fighter
        } else {
            debugPrint("⚠️ Could not load fighter data for: \(name)")
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
                    loadFighterData(name: fight.redCorner)
                }) {
                    Text(fight.redCorner)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.red)
                        .underline(FighterDataManager.shared.getFighter(fight.redCorner) != nil)
                }
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 4)
                
                Button(action: {
                    loadFighterData(name: fight.blueCorner)
                }) {
                    Text(fight.blueCorner)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accent)
                        .underline(FighterDataManager.shared.getFighter(fight.blueCorner) != nil)
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
        EventCard(event: EventInfo(
            name: "UFC Fight Night 254 London",
            date: "March 22, 2025",
            location: "London, UK",
            venue: "O2 Arena",
            fights: [
                Fight(redCorner: "Leon Edwards", blueCorner: "Sean Brady", weightClass: "Welterweight", isMainEvent: true, isTitleFight: false),
                Fight(redCorner: "Jan Błachowicz", blueCorner: "Carlos Ulberg", weightClass: "Light Heavyweight", isMainEvent: false, isTitleFight: false),
                Fight(redCorner: "Gunnar Nelson", blueCorner: "Kevin Holland", weightClass: "Welterweight", isMainEvent: false, isTitleFight: false),
                Fight(redCorner: "Molly McCann", blueCorner: "Alexia Thainara", weightClass: "Women's Strawweight", isMainEvent: false, isTitleFight: false),
                Fight(redCorner: "Jordan Vucenic", blueCorner: "Chris Duncan", weightClass: "Lightweight", isMainEvent: false, isTitleFight: false),
                Fight(redCorner: "Nathaniel Wood", blueCorner: "Morgan Charriere", weightClass: "Featherweight", isMainEvent: false, isTitleFight: false)
            ]
        ))
        .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
    .onAppear {
        // Initialize fighter data in preview
        _ = FighterDataManager.shared
        
        // Debug check to see which fighters have data
        for fighter in ["Leon Edwards", "Sean Brady", "Kevin Holland", "Gunnar Nelson"] {
            if let fighterData = FighterDataManager.shared.getFighter(fighter) {
                print("✅ Found data for \(fighter): \(fighterData.record)")
            } else {
                print("❌ No data found for \(fighter)")
            }
            
            if let fightHistory = FighterDataManager.shared.getFightHistory(fighter) {
                print("✅ Found \(fightHistory.count) fight history records for \(fighter)")
            } else {
                print("❌ No fight history found for \(fighter)")
            }
        }
    }
} 