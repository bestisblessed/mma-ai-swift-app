import Foundation

// Simple fighter model with no redundant declarations
struct FighterStats: Codable, Identifiable {
    // Properties
    let name: String
    let nickname: String?
    let record: String
    let weightClass: String
    let age: Int
    let height: String
    let reach: String?
    let stance: String?
    let teamAffiliation: String
    let nationality: String?
    let hometown: String?
    let birthDate: String
    let fighterID: Int
    
    // Win/loss stats
    let winsByKO: Int?
    let winsBySubmission: Int?
    let winsByDecision: Int?
    let lossesByKO: Int?
    let lossesBySubmission: Int?
    let lossesByDecision: Int?
    
    // Identifiable conformance
    var id: String { name }
}

// Fight-related models
struct Fight: Codable {
    let redCorner: String
    let blueCorner: String
    let redCornerID: Int
    let blueCornerID: Int
    let weightClass: String
    let isMainEvent: Bool
    let isTitleFight: Bool
    let round: String
    let time: String
}

struct FightResult: Codable {
    let opponent: String
    let opponentID: Int
    let outcome: String // "Win" or "Loss"
    let method: String
    let date: String
    let event: String
}

struct EventInfo: Codable {
    let name: String
    let date: String
    let location: String
    let venue: String
    let fights: [Fight]
    
    var displayLocation: String {
        if venue.isEmpty || venue == "N/A" {
            return location
        } else {
            return "\(venue) • \(location)"
        }
    }
}

// Simple fight record struct
struct FightRecord: Codable, Identifiable {
    let opponent: String
    let result: String // "W" for win, "L" for loss
    let method: String
    let date: String
    let event: String
    let round: String?
    let time: String?
    
    // Identifiable conformance
    var id: String { opponent + date }
} 