import Foundation

// MARK: - Core Models

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

// MARK: - API Models

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
    let reach: String?
    let stance: String?
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
        case reach = "Reach"
        case stance = "Stance"
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
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        birthDate = try container.decodeIfPresent(String.self, forKey: .birthDate)
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality)
        hometown = try container.decodeIfPresent(String.self, forKey: .hometown)
        team = try container.decodeIfPresent(String.self, forKey: .team)
        weightClass = try container.decodeIfPresent(String.self, forKey: .weightClass)
        height = try container.decodeIfPresent(String.self, forKey: .height)
        reach = try container.decodeIfPresent(String.self, forKey: .reach)
        stance = try container.decodeIfPresent(String.self, forKey: .stance)
        
        // Integer fields with proper error handling
        wins = (try? container.decode(Int.self, forKey: .wins)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .wins) ?? "") ?? 0)
        
        losses = (try? container.decode(Int.self, forKey: .losses)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .losses) ?? "") ?? 0)
        
        win_Decision = (try? container.decode(Int.self, forKey: .win_Decision)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .win_Decision) ?? "") ?? 0)
        
        win_KO = (try? container.decode(Int.self, forKey: .win_KO)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .win_KO) ?? "") ?? 0)
        
        win_Sub = (try? container.decode(Int.self, forKey: .win_Sub)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .win_Sub) ?? "") ?? 0)
        
        loss_Decision = (try? container.decode(Int.self, forKey: .loss_Decision)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .loss_Decision) ?? "") ?? 0)
        
        loss_KO = (try? container.decode(Int.self, forKey: .loss_KO)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .loss_KO) ?? "") ?? 0)
        
        loss_Sub = (try? container.decode(Int.self, forKey: .loss_Sub)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .loss_Sub) ?? "") ?? 0)
        
        fighterID = (try? container.decode(Int.self, forKey: .fighterID)) ?? 
        (Int(try! container.decodeIfPresent(String.self, forKey: .fighterID) ?? "") ?? 0)
    }
}

struct APIEvent: Codable {
    let eventID: Int
    let eventName: String
    let location: String?
    let date: String?
    let venue: String?
    let fighter1: String
    let fighter2: String
    var fighter1ID: Int
    var fighter2ID: Int
    let weightClass: String?
    let winner: String?
    let method: String?
    let round: Int?
    let time: String?
    let referee: String?
    let fightType: String?

    enum CodingKeys: String, CodingKey {
        case eventID = "Event ID"
        case eventName = "Event Name"
        case location = "Event Location"
        case date = "Event Date"
        case venue = "Venue"
        case fighter1 = "Fighter 1"
        case fighter2 = "Fighter 2"
        case fighter1ID = "Fighter 1 ID"
        case fighter2ID = "Fighter 2 ID"
        case weightClass = "Weight Class"
        case winner = "Winning Fighter"
        case method = "Winning Method"
        case round = "Winning Round"
        case time = "Winning Time"
        case referee = "Referee"
        case fightType = "Fight Type"
    }
} 
