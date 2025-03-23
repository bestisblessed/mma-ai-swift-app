import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = "https://mma-ai.duckdns.org/api"
    private let cache = UserDefaults.standard
    var isServerAvailable = false
    
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
                
                return eventResponse.events
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
                        
                        events.append(APIEvent(
                            eventName: event.eventName,
                            location: event.location,
                            date: event.date,
                            fighter1: formattedFighter1,
                            fighter2: formattedFighter2,
                            fighter1ID: 0,
                            fighter2ID: 0,
                            weightClass: fight.weightClass,
                            winner: fight.winner,
                            method: fight.method,
                            round: fight.round,
                            time: fight.time,
                            referee: nil,
                            fightType: fightType
                        ))
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
}

// MARK: - Data Models

struct DataVersion: Codable {
    let fighter_data_version: Double
    let event_data_version: Double
    let timestamp: String
}

struct FighterResponse: Codable {
    let timestamp: String
    let fighters: [APIFighter]
}

struct EventResponse: Codable {
    let timestamp: String
    let events: [APIEvent]
}

struct APIFighter: Codable {
    let name: String
    let nickname: String?
    let birthDate: String?
    let nationality: String?
    let hometown: String?
    let team: String?
    let weightClass: String?
    let height: String?
    let wins: Int
    let losses: Int
    let win_Decision: Int
    let win_KO: Int
    let win_Sub: Int
    let loss_Decision: Int
    let loss_KO: Int
    let loss_Sub: Int
    let fighterID: Int

    enum CodingKeys: String, CodingKey {
        case name = "Fighter"
        case nickname = "Nickname"
        case birthDate = "Birth Date"
        case nationality = "Nationality"
        case hometown = "Hometown"
        case team = "Association"
        case weightClass = "Weight Class"
        case height = "Height"
        case wins = "Wins"
        case losses = "Losses"
        case win_Decision = "Win_Decision"
        case win_KO = "Win_KO"
        case win_Sub = "Win_Sub"
        case loss_Decision = "Loss_Decision"
        case loss_KO = "Loss_KO"
        case loss_Sub = "Loss_Sub"
        case fighterID = "Fighter_ID"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required field - we know this is always present based on CSV analysis
        name = try container.decode(String.self, forKey: .name)
        
        // Optional string fields
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
        hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        team = try container.decodeIfPresent(String.self, forKey: .team)
        weightClass = try container.decodeIfPresent(String.self, forKey: .weightClass) // Has nulls in CSV
        height = try container.decodeIfPresent(String.self, forKey: .height)
        
        // Integer fields with fallbacks for different formats
        if let winsInt = try? container.decode(Int.self, forKey: .wins) {
            wins = winsInt
        } else if let winsString = try? container.decode(String.self, forKey: .wins),
                  let winsInt = Int(winsString) {
            wins = winsInt
        } else {
            wins = 0
        }
        
        if let lossesInt = try? container.decode(Int.self, forKey: .losses) {
            losses = lossesInt
        } else if let lossesString = try? container.decode(String.self, forKey: .losses),
                  let lossesInt = Int(lossesString) {
            losses = lossesInt
        } else {
            losses = 0
        }
        
        // Win stats
        if let winDecInt = try? container.decode(Int.self, forKey: .win_Decision) {
            win_Decision = winDecInt
        } else if let winDecString = try? container.decode(String.self, forKey: .win_Decision),
                  let winDecInt = Int(winDecString) {
            win_Decision = winDecInt
        } else {
            win_Decision = 0
        }
        
        if let winKOInt = try? container.decode(Int.self, forKey: .win_KO) {
            win_KO = winKOInt
        } else if let winKOString = try? container.decode(String.self, forKey: .win_KO),
                  let winKOInt = Int(winKOString) {
            win_KO = winKOInt
        } else {
            win_KO = 0
        }
        
        if let winSubInt = try? container.decode(Int.self, forKey: .win_Sub) {
            win_Sub = winSubInt
        } else if let winSubString = try? container.decode(String.self, forKey: .win_Sub),
                  let winSubInt = Int(winSubString) {
            win_Sub = winSubInt
        } else {
            win_Sub = 0
        }
        
        // Loss stats
        if let lossDecInt = try? container.decode(Int.self, forKey: .loss_Decision) {
            loss_Decision = lossDecInt
        } else if let lossDecString = try? container.decode(String.self, forKey: .loss_Decision),
                  let lossDecInt = Int(lossDecString) {
            loss_Decision = lossDecInt
        } else {
            loss_Decision = 0
        }
        
        if let lossKOInt = try? container.decode(Int.self, forKey: .loss_KO) {
            loss_KO = lossKOInt
        } else if let lossKOString = try? container.decode(String.self, forKey: .loss_KO),
                  let lossKOInt = Int(lossKOString) {
            loss_KO = lossKOInt
        } else {
            loss_KO = 0
        }
        
        if let lossSubInt = try? container.decode(Int.self, forKey: .loss_Sub) {
            loss_Sub = lossSubInt
        } else if let lossSubString = try? container.decode(String.self, forKey: .loss_Sub),
                  let lossSubInt = Int(lossSubString) {
            loss_Sub = lossSubInt
        } else {
            loss_Sub = 0
        }
        
        // Fighter ID
        if let fighterIDInt = try? container.decode(Int.self, forKey: .fighterID) {
            fighterID = fighterIDInt
        } else if let fighterIDString = try? container.decode(String.self, forKey: .fighterID),
                  let fighterIDInt = Int(fighterIDString) {
            fighterID = fighterIDInt
        } else {
            fighterID = 0
        }
    }
}

struct APIEvent: Codable {
    let eventName: String
    let location: String?
    let date: String?
    let fighter1: String
    let fighter2: String
    let fighter1ID: Int
    let fighter2ID: Int
    let weightClass: String?
    let winner: String?
    let method: String?
    let round: Int?
    let time: String?
    let referee: String?
    let fightType: String?

    enum CodingKeys: String, CodingKey {
        case eventName = "Event Name"
        case location = "Event Location"
        case date = "Event Date"
        case fighter1 = "Fighter 1"
        case fighter2 = "Fighter 2"
        case fighter1ID = "Fighter 1 ID"
        case fighter2ID = "Fighter 2 ID"
        case weightClass = "Weight Class" // Has 1651 nulls in CSV
        case winner = "Winning Fighter"
        case method = "Winning Method"
        case round = "Winning Round"
        case time = "Winning Time"
        case referee = "Referee"
        case fightType = "Fight Type"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields - these are always present in the CSV
        eventName = try container.decode(String.self, forKey: .eventName)
        fighter1 = try container.decode(String.self, forKey: .fighter1)
        fighter2 = try container.decode(String.self, forKey: .fighter2)
        
        // Optional string fields
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        weightClass = try container.decodeIfPresent(String.self, forKey: .weightClass)
        winner = try container.decodeIfPresent(String.self, forKey: .winner)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        referee = try container.decodeIfPresent(String.self, forKey: .referee)
        fightType = try container.decodeIfPresent(String.self, forKey: .fightType)
        
        // Handle integers with potential type variation
        if let id1Int = try? container.decode(Int.self, forKey: .fighter1ID) {
            fighter1ID = id1Int
        } else if let id1Str = try? container.decode(String.self, forKey: .fighter1ID),
                  let id1Int = Int(id1Str) {
            fighter1ID = id1Int
        } else {
            fighter1ID = 0
        }
        
        if let id2Int = try? container.decode(Int.self, forKey: .fighter2ID) {
            fighter2ID = id2Int
        } else if let id2Str = try? container.decode(String.self, forKey: .fighter2ID),
                  let id2Int = Int(id2Str) {
            fighter2ID = id2Int
        } else {
            fighter2ID = 0
        }
        
        // Winning Round is an integer in the CSV but handle variations
        if let roundInt = try? container.decode(Int.self, forKey: .round) {
            round = roundInt
        } else if let roundStr = try? container.decode(String.self, forKey: .round),
                  let roundInt = Int(roundStr) {
            round = roundInt
        } else {
            round = nil
        }
    }

    init(eventName: String, location: String?, date: String?, fighter1: String, fighter2: String, 
         fighter1ID: Int, fighter2ID: Int, weightClass: String?, winner: String?, method: String?, 
         round: Int?, time: String?, referee: String?, fightType: String?) {
        self.eventName = eventName
        self.location = location
        self.date = date
        self.fighter1 = fighter1
        self.fighter2 = fighter2
        self.fighter1ID = fighter1ID
        self.fighter2ID = fighter2ID
        self.weightClass = weightClass
        self.winner = winner
        self.method = method
        self.round = round
        self.time = time
        self.referee = referee
        self.fightType = fightType
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case serverUnavailable
    case decodingError
    case serverError(String)
}

extension UserDefaults {
    func set(_ value: Double, forKey key: String) {
        set(NSNumber(value: value), forKey: key)
    }
} 
