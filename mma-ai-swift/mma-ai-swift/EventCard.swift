import SwiftUI
import Foundation

struct Fight {
    let redCorner: String
    let blueCorner: String
    let weightClass: String
    let isMainEvent: Bool
    let isTitleFight: Bool
    let round: String
    let time: String
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
class FighterDataManager: ObservableObject {
    static let shared = FighterDataManager()
    
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var fightHistory: [String: [FightResult]] = [:]
    @Published private(set) var eventDetails: [String: EventInfo] = [:]
    @Published private(set) var upcomingEvents: [EventInfo] = []
    @Published private(set) var pastEvents: [EventInfo] = []
    @Published private(set) var loadingState: LoadingState = .idle
    
    private let networkManager = NetworkManager.shared
    private let cache = UserDefaults.standard
    
    enum LoadingState: Equatable {
        case idle
        case loading
        case success
        case error(String)
        
        static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.success, .success):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshData() async throws {
        if loadingState == .loading {
            return
        }
        await loadLatestData(force: true)
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        fighters[name]
    }
    
    func getFightHistory(_ name: String) -> [FightResult]? {
        fightHistory[name]
    }
    
    func getUpcomingEvents() -> [EventInfo] {
        return upcomingEvents
    }
    
    func getPastEvents() -> [EventInfo] {
        return pastEvents
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        // First try to load from cache
        if loadFromCache() {
            print("Data loaded from cache")
            
            // Check for updates in background
            Task {
                await loadLatestData(force: false)
            }
        } else {
            // No cache, load from network
            await loadLatestData(force: true)
        }
    }
    
    private func loadLatestData(force: Bool) async {
        DispatchQueue.main.async {
            self.loadingState = .loading
        }
        
        // Debug CSV columns
        Task {
            await networkManager.debugCSVColumns()
        }
        
        do {
            // Skip network requests if not forced and within update time window
            if !force {
                if let needsUpdate = try? await networkManager.checkForUpdates(), !needsUpdate {
                    print("No update needed, data is current")
                    
                    DispatchQueue.main.async {
                        self.loadingState = .success
                    }
                    return
                }
            }
            
            print("Fetching latest data from server...")
            
            // Fetch updated fighter and event data
            async let fightersTask = networkManager.fetchFighters()
            async let eventsTask = networkManager.fetchEvents()
            async let upcomingEventsTask = networkManager.fetchUpcomingEvents()
            
            let (apiFighters, apiEvents, upcomingApiEvents) = try await (fightersTask, eventsTask, upcomingEventsTask)
            
            print("✅ Successfully fetched data - \(apiFighters.count) fighters, \(apiEvents.count) events, and upcoming events")
            
            // Process data
            processNewData(fighters: apiFighters, events: apiEvents)
            
            // Process upcoming events
            processUpcomingEvents(events: upcomingApiEvents)
            
            // Process past events
            processPastEvents(events: apiEvents)
            
            // Save to cache
            saveToCache()
            
            DispatchQueue.main.async {
                self.loadingState = .success
            }
        } catch {
            print("Failed to fetch data: \(error.localizedDescription)")
            
            DispatchQueue.main.async {
                self.loadingState = .error(error.localizedDescription)
            }
        }
    }
    
    private func processNewData(fighters apiFighters: [APIFighter], events apiEvents: [APIEvent]) {
        var newFighters: [String: FighterStats] = [:]
        var newFightHistory: [String: [FightResult]] = [:]
        var newEventDetails: [String: EventInfo] = [:]
        
        // Process fighters
        for apiFighter in apiFighters {
            let record = "\(apiFighter.wins)-\(apiFighter.losses)-0"
            
            // Print fighter details for debugging
            print("📊 Processing fighter: \(apiFighter.name), Wins: \(apiFighter.wins), Losses: \(apiFighter.losses), Win Methods: \(apiFighter.win_KO)/\(apiFighter.win_Sub)/\(apiFighter.win_Decision)")
            
            newFighters[apiFighter.name] = FighterStats(
                name: apiFighter.name,
                nickname: apiFighter.nickname,
                record: record,
                weightClass: apiFighter.weightClass ?? "Unknown",
                age: calculateAge(from: apiFighter.birthDate!),
                height: apiFighter.height ?? "N/A",
                teamAffiliation: apiFighter.team!,
                nationality: apiFighter.nationality,
                hometown: apiFighter.hometown,
                birthDate: apiFighter.birthDate ?? "Unknown",
                winsByKO: apiFighter.win_KO,
                winsBySubmission: apiFighter.win_Sub,
                winsByDecision: apiFighter.win_Decision
            )
        }
        
        print("📊 Successfully processed \(newFighters.count) fighters")
        
        // Process events and fight history
        var tempEventMap: [String: [Fight]] = [:]
        
        for apiEvent in apiEvents {
            let formattedDate = formatDate(apiEvent.date ?? "Unknown")
            
            // Create fight results for fighter 1
            let outcome1 = apiEvent.fighter1 == apiEvent.winner ? "Win" : "Loss"
            let result1 = FightResult(
                opponent: apiEvent.fighter2,
                outcome: outcome1,
                method: apiEvent.method ?? "Unknown",
                date: formattedDate,
                event: apiEvent.eventName
            )
            
            // Create fight results for fighter 2
            let outcome2 = apiEvent.fighter2 == apiEvent.winner ? "Win" : "Loss"
            let result2 = FightResult(
                opponent: apiEvent.fighter1,
                outcome: outcome2,
                method: apiEvent.method ?? "Unknown",
                date: formattedDate,
                event: apiEvent.eventName
            )
            
            // Add to fight history
            if newFightHistory[apiEvent.fighter1] == nil {
                newFightHistory[apiEvent.fighter1] = []
            }
            newFightHistory[apiEvent.fighter1]?.append(result1)
            
            if newFightHistory[apiEvent.fighter2] == nil {
                newFightHistory[apiEvent.fighter2] = []
            }
            newFightHistory[apiEvent.fighter2]?.append(result2)
            
            // Create or update event
            if tempEventMap[apiEvent.eventName] == nil {
                tempEventMap[apiEvent.eventName] = []
            }
            
            // Add the fight to the event
            let fight = Fight(
                redCorner: apiEvent.fighter1,
                blueCorner: apiEvent.fighter2,
                weightClass: apiEvent.weightClass ?? "Unknown",
                isMainEvent: false, // Could be determined by event order
                isTitleFight: apiEvent.method?.lowercased().contains("title") ?? false,
                round: apiEvent.round != nil ? String(apiEvent.round!) : "N/A",
                time: apiEvent.time ?? "N/A"
            )
            
            tempEventMap[apiEvent.eventName]?.append(fight)
        }
        
        // Create final event details
        for (eventName, fights) in tempEventMap {
            // Find a sample event to get location and date
            if let sampleEvent = apiEvents.first(where: { $0.eventName == eventName }) {
                newEventDetails[eventName] = EventInfo(
                    name: eventName,
                    date: formatDate(sampleEvent.date ?? "Unknown"),
                    location: sampleEvent.location ?? "Unknown",
                    venue: "N/A", // Not available in our CSV
                    fights: fights
                )
            }
        }
        
        // Sort fights by date (newest first)
        for (fighter, fights) in newFightHistory {
            newFightHistory[fighter] = fights.sorted { fight1, fight2 in
                return compareDates(fight1.date, fight2.date)
            }
        }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.fighters = newFighters
            self.fightHistory = newFightHistory
            self.eventDetails = newEventDetails
        }
    }
    
    // Process upcoming events data
    private func processUpcomingEvents(events apiEvents: [APIEvent]) {
        print("🔄 Processing \(apiEvents.count) upcoming events...")
        
        // Group events by event name to organize fights under each event
        let eventsByName = Dictionary(grouping: apiEvents) { $0.eventName }
        var newUpcomingEvents: [EventInfo] = []
        
        // Process each event
        for (eventName, eventFights) in eventsByName {
            // Get the first event to extract common data
            if let firstEvent = eventFights.first {
                // Convert fights to our app's format
                var fights: [Fight] = []
                
                for apiEvent in eventFights {
                    // Determine if this is a main event or title fight
                    let isMainEvent = apiEvent.fightType?.lowercased().contains("main event") ?? false
                    let isTitleFight = apiEvent.fightType?.lowercased().contains("title") ?? false
                    
                    let fight = Fight(
                        redCorner: apiEvent.fighter1,
                        blueCorner: apiEvent.fighter2,
                        weightClass: apiEvent.weightClass ?? "Unknown",
                        isMainEvent: isMainEvent,
                        isTitleFight: isTitleFight,
                        round: "N/A", // Upcoming fights don't have results
                        time: "N/A"   // Upcoming fights don't have times
                    )
                    
                    fights.append(fight)
                }
                
                // Create the event info
                let eventInfo = EventInfo(
                    name: eventName,
                    date: formatDate(firstEvent.date ?? "Unknown"),
                    location: firstEvent.location ?? "Unknown",
                    venue: "N/A", // Venue not available in CSV
                    fights: fights
                )
                
                newUpcomingEvents.append(eventInfo)
                print("✅ Processed upcoming event: \(eventName) with \(fights.count) fights")
            }
        }
        
        // Sort events by date (soonest first)
        newUpcomingEvents.sort { event1, event2 in
            // Later date should come first in the list
            let result = compareDates(event1.date, event2.date)
            // If compareDates returns true, event1 is more recent than event2,
            // but for upcoming events, we want earlier dates first
            return !result
        }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.upcomingEvents = newUpcomingEvents
        }
        
        print("✅ Finished processing \(newUpcomingEvents.count) upcoming events")
    }
    
    // Process past events data
    private func processPastEvents(events apiEvents: [APIEvent]) {
        print("🔄 Processing past events...")
        
        // Group events by event name
        let eventsByName = Dictionary(grouping: apiEvents) { $0.eventName }
        var newPastEvents: [EventInfo] = []
        
        // Process each event
        for (eventName, eventFights) in eventsByName {
            // Skip if there are no fights with winners (incomplete data)
            if eventFights.allSatisfy({ $0.winner == nil || $0.winner == "TBD" }) {
                continue
            }
            
            // Get the first event to extract common data
            if let firstEvent = eventFights.first {
                // Convert fights to our app's format
                var fights: [Fight] = []
                
                for apiEvent in eventFights {
                    let isMainEvent = apiEvent.fightType?.lowercased().contains("main event") ?? false
                    let isTitleFight = apiEvent.method?.lowercased().contains("title") ?? false
                    
                    let fight = Fight(
                        redCorner: apiEvent.fighter1,
                        blueCorner: apiEvent.fighter2,
                        weightClass: apiEvent.weightClass ?? "Unknown",
                        isMainEvent: isMainEvent,
                        isTitleFight: isTitleFight,
                        round: apiEvent.round != nil ? String(apiEvent.round!) : "N/A",
                        time: apiEvent.time ?? "N/A"
                    )
                    
                    fights.append(fight)
                }
                
                // Create the event info
                let eventInfo = EventInfo(
                    name: eventName,
                    date: formatDate(firstEvent.date ?? "Unknown"),
                    location: firstEvent.location ?? "Unknown",
                    venue: "N/A", // Venue not available in CSV
                    fights: fights
                )
                
                newPastEvents.append(eventInfo)
                print("✅ Processed past event: \(eventName) with \(fights.count) fights")
            }
        }
        
        // Sort events by date (most recent first)
        newPastEvents.sort { event1, event2 in
            // Later date should come first in the list
            compareDates(event1.date, event2.date)
        }
        
        // Keep only the most recent event
        if !newPastEvents.isEmpty {
            newPastEvents = [newPastEvents[0]]
        }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.pastEvents = newPastEvents
        }
        
        print("✅ Finished processing \(newPastEvents.count) past events")
    }
    
    // MARK: - Cache Management
    
    private func saveToCache() {
        // Convert data to JSON and save to UserDefaults
        do {
            let fightersData = try JSONEncoder().encode(fighters)
            let fightHistoryData = try JSONEncoder().encode(fightHistory)
            let eventDetailsData = try JSONEncoder().encode(eventDetails)
            let upcomingEventsData = try JSONEncoder().encode(upcomingEvents)
            let pastEventsData = try JSONEncoder().encode(pastEvents)
            
            cache.set(fightersData, forKey: "cachedFighters")
            cache.set(fightHistoryData, forKey: "cachedFightHistory")
            cache.set(eventDetailsData, forKey: "cachedEventDetails")
            cache.set(upcomingEventsData, forKey: "cachedUpcomingEvents")
            cache.set(pastEventsData, forKey: "cachedPastEvents")
            cache.set(Date().timeIntervalSince1970, forKey: "lastUpdateTime")
            
            print("Data saved to cache")
        } catch {
            print("Failed to save data to cache: \(error)")
        }
    }
    
    private func loadFromCache() -> Bool {
        // Try to load data from UserDefaults
        if let fightersData = cache.data(forKey: "cachedFighters"),
           let fightHistoryData = cache.data(forKey: "cachedFightHistory"),
           let eventDetailsData = cache.data(forKey: "cachedEventDetails"),
           let upcomingEventsData = cache.data(forKey: "cachedUpcomingEvents") {
            
            do {
                fighters = try JSONDecoder().decode([String: FighterStats].self, from: fightersData)
                fightHistory = try JSONDecoder().decode([String: [FightResult]].self, from: fightHistoryData)
                eventDetails = try JSONDecoder().decode([String: EventInfo].self, from: eventDetailsData)
                upcomingEvents = try JSONDecoder().decode([EventInfo].self, from: upcomingEventsData)
                
                // Load past events if available, otherwise use empty array
                if let pastEventsData = cache.data(forKey: "cachedPastEvents") {
                    pastEvents = try JSONDecoder().decode([EventInfo].self, from: pastEventsData)
                }
                
                return true
            } catch {
                print("Failed to decode cached data: \(error)")
                return false
            }
        }
        
        return false
    }
    
    // MARK: - Helper Methods
    
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
            teamAffiliation: "N/A",
            nationality: nil,
            hometown: nil,
            birthDate: "",
            winsByKO: nil,
            winsBySubmission: nil,
            winsByDecision: nil
        )
        
        
//        fighters["Sean Brady"] = FighterStats(
//            name: "Sean Brady",
//            nickname: nil,
//            record: "17-1-0",
//            weightClass: "Welterweight",
//            age: 31,
//            height: "5'10\"",
////            reach: "N/A",
////            stance: "N/A",
//            teamAffiliation: "Renzo Gracie Philly"
//        )
//        
//        // Add a few more important fighters from our event
//        fighters["Kevin Holland"] = FighterStats(
//            name: "Kevin Holland",
//            nickname: "Trailblazer",
//            record: "26-13-0, 1NC",
//            weightClass: "Welterweight",
//            age: 32,
//            height: "6'3\"",
////            reach: "N/A",
////            stance: "N/A",
//            teamAffiliation: "Phalanx MMA Academy"
//        )
//        
//        fighters["Gunnar Nelson"] = FighterStats(
//            name: "Gunnar Nelson",
//            nickname: "Gunni",
//            record: "19-5-1",
//            weightClass: "Welterweight",
//            age: 36,
//            height: "5'11\"",
////            reach: "N/A",
////            stance: "N/A",
//            teamAffiliation: "Mjölnir MMA"
//        )
        
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
    
    private func loadSampleUpcomingEvents() {
        print("Loading sample upcoming events as fallback...")
        
        let sampleEvent = EventInfo(
            name: "UFC Fight Night 254 London",
            date: "March 22, 2025",
            location: "London, UK",
            venue: "O2 Arena",
            fights: [
                Fight(redCorner: "Leon Edwards", blueCorner: "Sean Brady", weightClass: "Welterweight", isMainEvent: true, isTitleFight: false, round: "N/A", time: "N/A"),
                Fight(redCorner: "Jan Błachowicz", blueCorner: "Carlos Ulberg", weightClass: "Light Heavyweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                Fight(redCorner: "Gunnar Nelson", blueCorner: "Kevin Holland", weightClass: "Welterweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A")
            ]
        )
        
        DispatchQueue.main.async {
            self.upcomingEvents = [sampleEvent]
        }
        
        print("Loaded 1 sample upcoming event")
    }
    
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
    
    private func compareDates(_ date1: String, _ date2: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let d1 = dateFormatter.date(from: date1),
              let d2 = dateFormatter.date(from: date2) else {
            return false
        }
        
        return d1 > d2 // Return true if date1 is newer than date2
    }
}

// Make models Codable for caching
extension FighterStats: Codable {
    enum CodingKeys: String, CodingKey {
        case name, nickname, record, weightClass, age, height
        case teamAffiliation, nationality, hometown, birthDate
        case winsByKO, winsBySubmission, winsByDecision
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        record = try container.decode(String.self, forKey: .record)
        weightClass = try container.decode(String.self, forKey: .weightClass)
        age = try container.decode(Int.self, forKey: .age)
        height = try container.decode(String.self, forKey: .height)
        teamAffiliation = try container.decode(String.self, forKey: .teamAffiliation)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
        hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        birthDate = try container.decode(String.self, forKey: .birthDate)
        winsByKO = try container.decodeIfPresent(Int.self, forKey: .winsByKO)
        winsBySubmission = try container.decodeIfPresent(Int.self, forKey: .winsBySubmission)
        winsByDecision = try container.decodeIfPresent(Int.self, forKey: .winsByDecision)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(nickname, forKey: .nickname)
        try container.encode(record, forKey: .record)
        try container.encode(weightClass, forKey: .weightClass)
        try container.encode(age, forKey: .age)
        try container.encode(height, forKey: .height)
        try container.encode(teamAffiliation, forKey: .teamAffiliation)
        try container.encodeIfPresent(nationality, forKey: .nationality)
        try container.encodeIfPresent(hometown, forKey: .hometown)
        try container.encode(birthDate, forKey: .birthDate)
        try container.encodeIfPresent(winsByKO, forKey: .winsByKO)
        try container.encodeIfPresent(winsBySubmission, forKey: .winsBySubmission)
        try container.encodeIfPresent(winsByDecision, forKey: .winsByDecision)
    }
}
extension FightResult: Codable {}
extension EventInfo: Codable {}
extension Fight: Codable {}

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
                    Fight(redCorner: "Leon Edwards", blueCorner: "Sean Brady", weightClass: "Welterweight", isMainEvent: true, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Jan Błachowicz", blueCorner: "Carlos Ulberg", weightClass: "Light Heavyweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Gunnar Nelson", blueCorner: "Kevin Holland", weightClass: "Welterweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Molly McCann", blueCorner: "Alexia Thainara", weightClass: "Women's Strawweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Jordan Vucenic", blueCorner: "Chris Duncan", weightClass: "Lightweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A"),
                    Fight(redCorner: "Nathaniel Wood", blueCorner: "Morgan Charriere", weightClass: "Featherweight", isMainEvent: false, isTitleFight: false, round: "N/A", time: "N/A")
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
