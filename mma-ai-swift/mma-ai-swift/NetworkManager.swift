import Foundation
// API models are defined in APIModels.swift in the same target

// Define network-specific error enum
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverUnavailable
    case unexpectedError(String)
}

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = "https://mma-ai.duckdns.org/api"
    private let cache = UserDefaults.standard
    var isServerAvailable = false
    private var fighterIdLookup: [String: Int] = [:]
    private var fighterNameLookup: [Int: String] = [:]
    
    private init() {
        print("🌐 NetworkManager initialized with base URL: \(baseURL)")
        // Check server availability on initialization
        Task {
            isServerAvailable = await checkServerAvailability()
            print("Server availability check: \(isServerAvailable ? "✅ Available" : "❌ Unavailable")")
        }
    }
    
    // MARK: - Server Availability
    
    func checkServerAvailability() async -> Bool {
        // Check if the examples endpoint is available, which we know works
        let endpoint = "\(baseURL)/examples"
        print("🔍 Checking server availability at: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            print("⚠️ Invalid URL: \(endpoint)")
            return false
        }
        
        // Create a URLRequest with a short timeout
        var request = URLRequest(url: url)
        request.timeoutInterval = 10 // 10 seconds timeout
        
        do {
            print("📡 Sending request to \(endpoint)...")
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("⚠️ Unexpected response type: \(response)")
                return false
            }
            
            print("📥 Response status code: \(httpResponse.statusCode)")
            
            if httpResponse.statusCode == 200 {
                // Try to print the response to verify we're getting the expected data
                if let responseString = String(data: data, encoding: .utf8) {
                    print("📄 Response preview: \(responseString.prefix(100))...")
                }
                
                print("✅ Server is available at \(baseURL)")
                return true
            } else {
                print("⚠️ Server returned non-200 status code: \(httpResponse.statusCode)")
                return false
            }
        } catch {
            print("⚠️ Server connection error: \(error.localizedDescription)")
            
            // Try alternate endpoints to see if any part of the API is working
            print("🔄 Trying alternate endpoint: \(baseURL)/data/version")
            if let versionURL = URL(string: "\(baseURL)/data/version") {
                do {
                    let (_, versionResponse) = try await URLSession.shared.data(from: versionURL)
                    if let httpResponse = versionResponse as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        print("✅ Version endpoint is available, using this as confirmation")
                        return true
                    }
                } catch {
                    print("⚠️ Version endpoint also failed: \(error.localizedDescription)")
                }
            }
            
            print("❌ Server appears to be completely unavailable")
            return false
        }
    }
    
    // MARK: - Data Version Check
    
    func checkForUpdates() async throws -> Bool {
        // Check server availability first
        if !isServerAvailable {
            isServerAvailable = await checkServerAvailability()
            if !isServerAvailable {
                print("⚠️ Server not available for version check")
                throw NetworkError.serverUnavailable
            }
        }
        
        let endpoint = "\(baseURL)/data/version"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            let version = try JSONDecoder().decode(DataVersion.self, from: data)
            
            // Check if we need to update
            let lastFighterVersion = cache.double(forKey: "lastFighterVersion")
            let lastEventVersion = cache.double(forKey: "lastEventVersion")
            
            print("💾 Version check - Server: \(version.fighter_data_version), Local: \(lastFighterVersion)")
            
            return version.fighter_data_version != lastFighterVersion ||
                   version.event_data_version != lastEventVersion
        } catch {
            print("⚠️ Version check error: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Fetch Data
    
    func fetchFighters() async throws -> [APIFighter] {
        // Check server availability first
        if !isServerAvailable {
            isServerAvailable = await checkServerAvailability()
            if !isServerAvailable {
                print("⚠️ Server not available for fetching fighters")
                throw NetworkError.serverUnavailable
            }
        }
        
        let endpoint = "\(baseURL)/data/fighters"
        print("🔄 Fetching fighters from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            // Debug: Print the raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 Raw JSON response received:")
                let firstPart = String(jsonString.prefix(500))
                print(firstPart)
                print("...")
                
                // Look for specific fields to verify structure
                print("🔍 Checking for expected fields:")
                print("Contains 'fighters': \(jsonString.contains("fighters"))")
                print("Contains 'Fighter': \(jsonString.contains("Fighter"))")
                print("Contains 'Win_Decision': \(jsonString.contains("Win_Decision"))")
                print("Contains 'Loss_Decision': \(jsonString.contains("Loss_Decision"))")
            }
            
            // Try to parse with more detailed error handling
            do {
                let decoder = JSONDecoder()
                let fighterResponse = try decoder.decode(FighterResponse.self, from: data)
                print("✅ Successfully fetched \(fighterResponse.fighters.count) fighters")
                
                // Update cache version
                if let version = try? await getDataVersion() {
                    cache.set(version.fighter_data_version, forKey: "lastFighterVersion")
                }
                
                // Build lookup tables for fighter IDs
                buildFighterLookups(fighters: fighterResponse.fighters)
                
                return fighterResponse.fighters
            } catch {
                print("⚠️ JSON decoding error details: \(error)")
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 Key not found: \(key), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("📊 Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("🚫 Value not found: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("🔥 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("⚠️ Unknown decoding error: \(decodingError)")
                    }
                }
                
                // Try parsing with a more flexible approach
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let fightersArray = json["fighters"] as? [[String: Any]] {
                    print("📊 Manual parsing found \(fightersArray.count) fighters")
                    
                    // Create fighter objects manually
                    var fighters: [APIFighter] = []
                    let decoder = JSONDecoder()
                    
                    for fighterDict in fightersArray {
                        do {
                            let fighterData = try JSONSerialization.data(withJSONObject: fighterDict)
                            let fighter = try decoder.decode(APIFighter.self, from: fighterData)
                            fighters.append(fighter)
                        } catch {
                            print("⚠️ Failed to parse a fighter: \(error)")
                            // Continue with next fighter
                        }
                    }
                    
                    if !fighters.isEmpty {
                        print("✅ Successfully parsed \(fighters.count) fighters manually")
                        return fighters
                    }
                }
                
                // If all else fails, throw the original error
                throw error
            }
        } catch {
            print("⚠️ Fighter fetch error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchEvents() async throws -> [APIEvent] {
        // Check server availability first
        if !isServerAvailable {
            isServerAvailable = await checkServerAvailability()
            if !isServerAvailable {
                print("⚠️ Server not available for fetching events")
                throw NetworkError.serverUnavailable
            }
        }
        
        let endpoint = "\(baseURL)/data/events"
        print("🔄 Fetching events from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            // Debug: Print the raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 Raw events JSON response received:")
                let firstPart = String(jsonString.prefix(500))
                print(firstPart)
                print("...")
                
                // Look for specific fields to verify structure
                print("🔍 Checking for expected event fields:")
                print("Contains 'events': \(jsonString.contains("events"))")
                print("Contains 'EventName': \(jsonString.contains("EventName"))")
                print("Contains 'Fighter1': \(jsonString.contains("Fighter1"))")
                print("Contains 'Fighter2': \(jsonString.contains("Fighter2"))")
            }
            
            do {
                let decoder = JSONDecoder()
                let eventResponse = try decoder.decode(EventResponse.self, from: data)
                print("✅ Successfully fetched event data with \(eventResponse.events.count) events")
                
                // Update cache version
                if let version = try? await getDataVersion() {
                    cache.set(version.event_data_version, forKey: "lastEventVersion")
                }
                
                // Enrich events with fighter IDs
                let enrichedEvents = enrichEventsWithFighterIds(events: eventResponse.events)
                
                return enrichedEvents
            } catch {
                print("⚠️ Event JSON decoding error details: \(error)")
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 Key not found: \(key), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("📊 Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("🚫 Value not found: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("🔥 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("⚠️ Unknown decoding error: \(decodingError)")
                    }
                }
                
                // Try parsing with a more flexible approach
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let eventsArray = json["events"] as? [[String: Any]] {
                    print("📊 Manual parsing found \(eventsArray.count) events")
                    
                    // Create event objects manually
                    var events: [APIEvent] = []
                    let decoder = JSONDecoder()
                    
                    for eventDict in eventsArray {
                        do {
                            let eventData = try JSONSerialization.data(withJSONObject: eventDict)
                            let event = try decoder.decode(APIEvent.self, from: eventData)
                            events.append(event)
                        } catch {
                            print("⚠️ Failed to parse an event: \(error)")
                            // Continue with next event
                        }
                    }
                    
                    if !events.isEmpty {
                        print("✅ Successfully parsed \(events.count) events manually")
                        return events
                    }
                }
                
                throw error
            }
        } catch {
            print("⚠️ Event fetch error: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUpcomingEvents() async throws -> [APIEvent] {
        // Check server availability first
        if !isServerAvailable {
            isServerAvailable = await checkServerAvailability()
            if !isServerAvailable {
                print("⚠️ Server not available for fetching upcoming events")
                throw NetworkError.serverUnavailable
            }
        }
        
        let endpoint = "\(baseURL)/data/upcoming"
        print("🔄 Fetching upcoming events from: \(endpoint)")
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw NetworkError.invalidResponse
            }
            
            // Debug: Print the raw JSON response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 Raw upcoming events JSON response preview:")
                let firstPart = String(jsonString.prefix(500))
                print(firstPart)
                print("...")
            }
            
            do {
                let decoder = JSONDecoder()
                struct UpcomingEvent: Codable {
                    let eventName: String
                    let location: String?
                    let date: String?
                    let mainCard: [UpcomingFight]
                    let prelims: [UpcomingFight]
                    let allFights: [UpcomingFight]
                    
                    struct UpcomingFight: Codable {
                        let fighter1: String
                        let fighter2: String
                        let weightClass: String?
                        let fightType: String?
                        let round: Int?
                        let time: String?
                        let winner: String?
                        let method: String?
                    }
                }
                
                // Decode to custom structure first
                let upcomingEvents = try decoder.decode([UpcomingEvent].self, from: data)
                
                // Map to APIEvent format
                let apiEvents = upcomingEvents.flatMap { event -> [APIEvent] in
                    var events: [APIEvent] = []
                    
                    // Process all fights in order
                    for fight in event.allFights {
                        // Format fighter names with spaces
                        let formattedFighter1 = formatFighterName(fight.fighter1)
                        let formattedFighter2 = formatFighterName(fight.fighter2)
                        
                        // Determine fight type from the CSV data
                        let fightType = if fight.fightType?.contains("Main Event") == true {
                            "Main Event"
                        } else {
                            "Main Card"  // All other fights go to main card
                        }
                        
                        // Create a new APIEvent using decoder initializer pattern
//                        let encoder = JSONEncoder()
                        _ = JSONEncoder()
                        let decoder = JSONDecoder()
                        
                        // Create a dictionary with the event data
                        let eventDict: [String: Any] = [
                            "Event Name": event.eventName,
                            "Event Location": event.location as Any,
                            "Event Date": event.date as Any,
                            "Fighter 1": formattedFighter1,
                            "Fighter 2": formattedFighter2,
                            "Weight Class": fight.weightClass as Any,
                            "Winning Fighter": fight.winner as Any,
                            "Winning Method": fight.method as Any,
                            "Winning Round": fight.round as Any,
                            "Winning Time": fight.time as Any,
                            "Fight Type": fightType
                        ]
                        
                        do {
                            // Convert dictionary to JSON
                            let eventData = try JSONSerialization.data(withJSONObject: eventDict)
                            
                            // Decode JSON to APIEvent
                            let apiEvent = try decoder.decode(APIEvent.self, from: eventData)
                            events.append(apiEvent)
                        } catch {
                            print("⚠️ Error creating upcoming event: \(error)")
                        }
                    }
                    
                    return events
                }
                
                print("✅ Successfully fetched \(apiEvents.count) upcoming events")
                return apiEvents
            } catch {
                print("⚠️ Upcoming events JSON decoding error: \(error)")
                
                if let decodingError = error as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("🔑 Key not found: \(key), context: \(context.debugDescription)")
                    case .typeMismatch(let type, let context):
                        print("📊 Type mismatch: expected \(type), context: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("🚫 Value not found: expected \(type), context: \(context.debugDescription)")
                    case .dataCorrupted(let context):
                        print("🔥 Data corrupted: \(context.debugDescription)")
                    @unknown default:
                        print("⚠️ Unknown decoding error: \(decodingError)")
                    }
                }
                
                throw error
            }
        } catch {
            print("⚠️ Upcoming events fetch error: \(error.localizedDescription)")
            throw error
        }
    }

    private func getDataVersion() async throws -> DataVersion {
        let endpoint = "\(baseURL)/data/version"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(DataVersion.self, from: data)
    }
    
    // MARK: - CSV Column Debugging
    
    func debugCSVColumns() async {
        print("🔍 Debugging CSV columns on server...")
        
        // Try to access the raw fighter CSV data first
        if let url = URL(string: "\(baseURL)/debug/fighter_csv_columns") {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("📋 Fighter CSV columns: \(responseString)")
                } else {
                    print("⚠️ Error getting fighter CSV columns")
                }
            } catch {
                print("⚠️ Error fetching fighter CSV columns: \(error.localizedDescription)")
            }
        }
        
        // Try to access the raw events CSV data
        if let url = URL(string: "\(baseURL)/debug/event_csv_columns") {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let responseString = String(data: data, encoding: .utf8) {
                    print("📋 Event CSV columns: \(responseString)")
                } else {
                    print("⚠️ Error getting event CSV columns")
                }
            } catch {
                print("⚠️ Error fetching event CSV columns: \(error.localizedDescription)")
            }
        }
        
        // If the debug endpoints don't exist, try directly parsing sample data
        Task {
            do {
                let fighters = try await fetchFighters()
                if let firstFighter = fighters.first {
                    print("📊 Sample fighter: \(firstFighter)")
                }
            } catch {
                print("⚠️ Could not fetch sample fighter: \(error.localizedDescription)")
            }
            
            do {
                let events = try await fetchEvents()
                if let firstEvent = events.first {
                    print("📊 Sample event: \(firstEvent)")
                }
            } catch {
                print("⚠️ Could not fetch sample event: \(error.localizedDescription)")
            }
        }
    }
    
    // Helper function to add spaces to fighter names
    private func formatFighterName(_ name: String) -> String {
        // Use regular expression to insert spaces before uppercase letters
        // that are not at the beginning of the name and not after a space or period
        let pattern = "(?<=[a-z])(?=[A-Z])"
        return name.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
    }
    
    // MARK: - Fighter ID Utilities
    
    // Get fighter ID from name
    func getFighterId(name: String) -> Int? {
        return fighterIdLookup[name]
    }
    
    // Get fighter name from ID
    func getFighterName(id: Int) -> String? {
        return fighterNameLookup[id]
    }
    
    // Build lookup tables after fetching fighter data
    func buildFighterLookups(fighters: [APIFighter]) {
        var idLookup: [String: Int] = [:]
        var nameLookup: [Int: String] = [:]
        
        for fighter in fighters {
            idLookup[fighter.name] = fighter.fighterID
            nameLookup[fighter.fighterID] = fighter.name
        }
        
        self.fighterIdLookup = idLookup
        self.fighterNameLookup = nameLookup
        
        print("📊 Built fighter ID lookup tables with \(idLookup.count) entries")
    }
    
    // Helper to map fighter names to IDs in events
    func enrichEventsWithFighterIds(events: [APIEvent]) -> [APIEvent] {
        return events.map { event in
            var updatedEvent = event
            
            // Update fighter IDs if they're not already set
            if event.fighter1ID == 0, let id = getFighterId(name: event.fighter1) {
                updatedEvent.fighter1ID = id
            }
            
            if event.fighter2ID == 0, let id = getFighterId(name: event.fighter2) {
                updatedEvent.fighter2ID = id
            }
            
            return updatedEvent
        }
    }
}

// MARK: - Data Models should be in Models.swift

extension UserDefaults {
    func set(_ value: Double, forKey key: String) {
        set(NSNumber(value: value), forKey: key)
    }
} 
