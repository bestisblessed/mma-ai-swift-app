import Foundation
import SwiftUI

// Make FighterDataManager conform to @unchecked Sendable to fix closure warnings
class FighterDataManager: ObservableObject, @unchecked Sendable {
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
    
    private init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshData() async throws {
        if loadingState == .loading { return }

        do {
            let needsUpdate = try await networkManager.checkForUpdates()
            if needsUpdate || upcomingEvents.isEmpty {
                await loadLatestData(force: true)
            }
        } catch {
            print("Update check failed: \(error)")
            if upcomingEvents.isEmpty {
                await loadLatestData(force: true)
            }
        }
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        if let fighter = fighters[name] {
            return fighter
        }
        let cleaned = networkManager.cleanName(name)
        return fighters.first { networkManager.cleanName($0.key) == cleaned }?.value
    }
    
    func getFighterByID(_ id: Int) -> FighterStats? {
        return fighters.values.first { $0.fighterID == id }
    }
    
    func getFightHistory(_ name: String) -> [FightResult]? {
        if let history = fightHistory[name] {
            return history
        }
        let cleaned = networkManager.cleanName(name)
        return fightHistory.first { networkManager.cleanName($0.key) == cleaned }?.value
    }
    
    // Convert FightResult to FightRecord for the profile view
    func getFightRecords(_ name: String) -> [FightRecord]? {
        guard let results = getFightHistory(name) else {
            return nil
        }
        
        return results.map { result in
            // Find the fight details to get round and time info
            var round: String? = nil
            var time: String? = nil
            
            // Try to find the fight in event details
            for (eventName, event) in eventDetails {
                if eventName == result.event {
                    // Find the specific fight
                    let fight = event.fights.first {
                        ($0.redCorner == name && $0.blueCorner == result.opponent) ||
                        ($0.redCorner == result.opponent && $0.blueCorner == name)
                    }
                    
                    if let fight = fight {
                        round = fight.round == "N/A" ? nil : fight.round
                        time = fight.time == "N/A" ? nil : fight.time
                    }
                }
            }
            
            return FightRecord(
                opponent: result.opponent,
                result: result.outcome == "Win" ? "W" : "L",
                method: result.method,
                date: result.date,
                event: result.event,
                round: round,
                time: time
            )
        }
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
        // Ensure news cache is up to date at startup
        networkManager.prefetchNewsIfNeeded()
        networkManager.prefetchOddsTimestampIfNeeded()
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
            let needsUpdate: Bool
            if force {
                needsUpdate = true
            } else {
                do {
                    needsUpdate = try await networkManager.checkForUpdates()
                } catch {
                    print("Update check failed: \(error)")
                    needsUpdate = false
                }
            }

            if !needsUpdate && !upcomingEvents.isEmpty {
                print("Data is up to date. Skipping refresh.")

                DispatchQueue.main.async {
                    self.loadingState = .success
                }
                return
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
            print("📊 Processing fighter: \(apiFighter.name), Wins: \(apiFighter.wins), Losses: \(apiFighter.losses), Win Methods: \(apiFighter.win_KO)/\(apiFighter.win_Sub)/\(apiFighter.win_Decision), Loss Methods: \(apiFighter.loss_KO)/\(apiFighter.loss_Sub)/\(apiFighter.loss_Decision)")
            
            newFighters[apiFighter.name] = FighterStats(
                name: apiFighter.name,
                nickname: apiFighter.nickname,
                record: record,
                weightClass: apiFighter.weightClass ?? "Unknown",
                age: calculateAge(from: apiFighter.birthDate ?? "Unknown"),
                height: apiFighter.height ?? "N/A",
                reach: apiFighter.reach ?? "N/A",
                stance: apiFighter.stance ?? "N/A",
                teamAffiliation: apiFighter.team ?? "Unknown",
                nationality: apiFighter.nationality,
                hometown: apiFighter.hometown,
                birthDate: apiFighter.birthDate ?? "",
                fighterID: apiFighter.fighterID,
                winsByKO: apiFighter.win_KO,
                winsBySubmission: apiFighter.win_Sub,
                winsByDecision: apiFighter.win_Decision,
                lossesByKO: apiFighter.loss_KO,
                lossesBySubmission: apiFighter.loss_Sub,
                lossesByDecision: apiFighter.loss_Decision
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
                opponentID: apiEvent.fighter2ID,
                outcome: outcome1,
                method: apiEvent.method ?? "Unknown",
                date: formattedDate,
                event: apiEvent.eventName
            )
            
            // Create fight results for fighter 2
            let outcome2 = apiEvent.fighter2 == apiEvent.winner ? "Win" : "Loss"
            let result2 = FightResult(
                opponent: apiEvent.fighter1,
                opponentID: apiEvent.fighter1ID,
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
                redCornerID: apiEvent.fighter1ID,
                blueCornerID: apiEvent.fighter2ID,
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
                        redCornerID: apiEvent.fighter1ID,
                        blueCornerID: apiEvent.fighter2ID,
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
                        redCornerID: apiEvent.fighter1ID,
                        blueCornerID: apiEvent.fighter2ID,
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
        
        // Keep only the most recent 10 events
        if newPastEvents.count > 10 {
            newPastEvents = Array(newPastEvents.prefix(10))
        }
        
        // Update on main thread
        DispatchQueue.main.async {
            self.pastEvents = newPastEvents
        }
        
        print("✅ Finished processing \(newPastEvents.count) past events")
    }
    
    // MARK: - Cache Management
    
    private func saveToCache() {
        // Persist data to JSON files for offline use
        FileCache.save(fighters, as: "fighters.json")
        FileCache.save(fightHistory, as: "fight_history.json")
        FileCache.save(eventDetails, as: "event_details.json")
        FileCache.save(upcomingEvents, as: "upcoming_events.json")
        FileCache.save(pastEvents, as: "past_events.json")

        cache.set(Date().timeIntervalSince1970, forKey: "lastUpdateTime")

        print("Data saved to cache")
    }

    private func loadFromCache() -> Bool {
        // Load data from JSON files
        if let cachedFighters = FileCache.load([String: FighterStats].self, from: "fighters.json"),
           let cachedHistory = FileCache.load([String: [FightResult]].self, from: "fight_history.json"),
           let cachedEvents = FileCache.load([String: EventInfo].self, from: "event_details.json"),
           let cachedUpcoming = FileCache.load([EventInfo].self, from: "upcoming_events.json") {

            // Perform state updates on main thread to avoid publish-from-background warnings
            DispatchQueue.main.async {
                self.fighters = cachedFighters
                self.fightHistory = cachedHistory
                self.eventDetails = cachedEvents
                self.upcomingEvents = cachedUpcoming
                self.pastEvents = FileCache.load([EventInfo].self, from: "past_events.json") ?? []
            }

            return true
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