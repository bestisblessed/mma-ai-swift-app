import Foundation

struct FightResult {
    let opponent: String
    let opponentID: Int
    let event: String
    let outcome: String // "Win" or "Loss"
    let method: String
    let date: String
}

class FighterDataManager: ObservableObject {
    static let shared = FighterDataManager()
    
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var fightHistory: [String: [FightResult]] = [:]
    @Published private(set) var eventDetails: [String: EventInfo] = [:]
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
    
    func refreshData() async {
        if loadingState == .loading { return }
        await loadLatestData(force: true)
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        fighters[name]
    }
    
    func getFightHistory(_ name: String) -> [FightResult]? {
        fightHistory[name]
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        // First try to load from cache
        if loadFromCache() {
            // Check for updates in background
            Task {
                await checkForUpdates()
            }
        } else {
            // If no cache, load from network
            await loadLatestData(force: true)
        }
    }
    
    private func loadFromCache() -> Bool {
        // Load cached data if available
        if let fightersData = cache.data(forKey: "fighters"),
           let historyData = cache.data(forKey: "fightHistory"),
           let eventsData = cache.data(forKey: "eventDetails") {
            
            do {
                let decoder = JSONDecoder()
                self.fighters = try decoder.decode([String: FighterStats].self, from: fightersData)
                self.fightHistory = try decoder.decode([String: [FightResult]].self, from: historyData)
                self.eventDetails = try decoder.decode([String: EventInfo].self, from: eventsData)
                return true
            } catch {
                print("Error decoding cache: \(error)")
                return false
            }
        }
        return false
    }
    
    private func saveToCache() {
        do {
            let encoder = JSONEncoder()
            let fightersData = try encoder.encode(fighters)
            let historyData = try encoder.encode(fightHistory)
            let eventsData = try encoder.encode(eventDetails)
            
            cache.set(fightersData, forKey: "fighters")
            cache.set(historyData, forKey: "fightHistory")
            cache.set(eventsData, forKey: "eventDetails")
        } catch {
            print("Error saving to cache: \(error)")
        }
    }
    
    private func checkForUpdates() async {
        do {
            if try await networkManager.checkForUpdates() {
                await loadLatestData(force: true)
            }
        } catch {
            print("Error checking for updates: \(error)")
        }
    }
    
    private func loadLatestData(force: Bool) async {
        loadingState = .loading
        
        do {
            // Fetch fighters and events from API
            let apiFighters = try await networkManager.fetchFighters()
            let apiEvents = try await networkManager.fetchEvents()
            
            // Process the data
            processNewData(fighters: apiFighters, events: apiEvents)
            
            // Save to cache
            saveToCache()
            
            loadingState = .success
        } catch {
            print("Failed to fetch data: \(error)")
            loadingState = .error(error.localizedDescription)
            
            // Load sample data as fallback if needed
            if force {
                loadSampleFighterData()
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
            
            newFighters[apiFighter.name] = FighterStats(
                name: apiFighter.name,
                nickname: apiFighter.nickname,
                record: record,
                weightClass: apiFighter.weightClass ?? "Unknown",
                age: calculateAge(from: apiFighter.birthDate ?? "Unknown"),
                height: apiFighter.height ?? "N/A",
                teamAffiliation: apiFighter.team ?? "Unknown",
                nationality: apiFighter.nationality,
                hometown: apiFighter.hometown,
                birthDate: apiFighter.birthDate ?? "Unknown",
                winsByKO: apiFighter.win_KO,
                winsBySubmission: apiFighter.win_Sub,
                winsByDecision: apiFighter.win_Decision,
                lossesByKO: apiFighter.loss_KO,
                lossesBySubmission: apiFighter.loss_Sub,
                lossesByDecision: apiFighter.loss_Decision,
                fighterID: apiFighter.fighterID
            )
        }
        
        // Process events and create fight history
        for event in apiEvents {
            let eventInfo = EventInfo(
                name: event.name,
                date: event.date,
                location: event.location,
                venue: event.venue ?? "TBD",
                fights: event.fights
            )
            newEventDetails[event.name] = eventInfo
            
            // Create fight history entries for both fighters
            for fight in event.fights {
                // Create fight result for red corner
                let redCornerResult = FightResult(
                    opponent: fight.blueCorner,
                    opponentID: fight.blueCornerID,
                    event: event.name,
                    outcome: fight.winner == fight.redCorner ? "Win" : "Loss",
                    method: fight.method ?? "TBD",
                    date: event.date
                )
                
                // Create fight result for blue corner
                let blueCornerResult = FightResult(
                    opponent: fight.redCorner,
                    opponentID: fight.redCornerID,
                    event: event.name,
                    outcome: fight.winner == fight.blueCorner ? "Win" : "Loss",
                    method: fight.method ?? "TBD",
                    date: event.date
                )
                
                // Add to fight history
                if newFightHistory[fight.redCorner] == nil {
                    newFightHistory[fight.redCorner] = []
                }
                if newFightHistory[fight.blueCorner] == nil {
                    newFightHistory[fight.blueCorner] = []
                }
                
                newFightHistory[fight.redCorner]?.append(redCornerResult)
                newFightHistory[fight.blueCorner]?.append(blueCornerResult)
            }
        }
        
        // Update state
        self.fighters = newFighters
        self.fightHistory = newFightHistory
        self.eventDetails = newEventDetails
    }
    
    private func calculateAge(from birthDateString: String) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        
        guard let birthDate = dateFormatter.date(from: birthDateString) else {
            return 0
        }
        
        let calendar = Calendar.current
        let now = Date()
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: now)
        return ageComponents.year ?? 0
    }
    
    // Sample data for fallback
    private func loadSampleFighterData() {
        print("Loading sample fighter data as fallback...")
        
        fighters["Max Holloway"] = FighterStats(
            name: "Max Holloway",
            nickname: "Blessed",
            record: "25-7-0",
            weightClass: "Featherweight",
            age: 32,
            height: "5'11\"",
            teamAffiliation: "Hawaii Elite MMA",
            nationality: "American",
            hometown: "Waianae, Hawaii",
            birthDate: "Dec 4, 1991",
            winsByKO: 12,
            winsBySubmission: 4,
            winsByDecision: 9,
            lossesByKO: 1,
            lossesBySubmission: 1,
            lossesByDecision: 5,
            fighterID: 12345
        )
        
        print("Loaded \(fighters.count) sample fighters")
    }
}
