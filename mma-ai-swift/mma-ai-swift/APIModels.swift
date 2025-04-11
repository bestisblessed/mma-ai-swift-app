import Foundation

// API response models
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
        reach = try container.decodeIfPresent(String.self, forKey: .reach)
        stance = try container.decodeIfPresent(String.self, forKey: .stance)
        
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
        case weightClass = "Weight Class" // Has nulls in CSV
        case winner = "Winning Fighter"
        case method = "Winning Method"
        case round = "Winning Round"
        case time = "Winning Time"
        case referee = "Referee"
        case fightType = "Fight Type"
    }
    
    // Custom initializer for creating an APIEvent from parsed data
    init(eventID: Int = 0, eventName: String, location: String?, date: String?, venue: String? = nil,
         fighter1: String, fighter2: String, fighter1ID: Int, fighter2ID: Int,
         weightClass: String?, winner: String?, method: String?, round: Int?, time: String?,
         referee: String? = nil, fightType: String? = nil) {
        self.eventID = eventID
        self.eventName = eventName
        self.location = location
        self.date = date
        self.venue = venue
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required fields - these are always present in the CSV
        eventName = try container.decode(String.self, forKey: .eventName)
        fighter1 = try container.decode(String.self, forKey: .fighter1)
        fighter2 = try container.decode(String.self, forKey: .fighter2)
        
        // Event ID
        if let eventIDInt = try? container.decode(Int.self, forKey: .eventID) {
            eventID = eventIDInt
        } else if let eventIDString = try? container.decode(String.self, forKey: .eventID),
                  let eventIDInt = Int(eventIDString) {
            eventID = eventIDInt
        } else {
            eventID = 0
        }
        
        // Optional string fields
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        venue = try container.decodeIfPresent(String.self, forKey: .venue)
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
} 