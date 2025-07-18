import Foundation
import SwiftUI
import Charts

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

// MARK: - Odds Models

struct OddsMovement: Codable, Identifiable {
    let matchup: String
    let gameDate: String
    let sportsbook: String
    let oddsBeforeRaw: String
    let oddsAfterRaw: String
    let timeStamp: String
    
    var id: String { "\(matchup)-\(timeStamp)" }
    
    var fighter1: String {
        matchup.components(separatedBy: " vs ").first?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    var fighter2: String {
        matchup.components(separatedBy: " vs ").last?.trimmingCharacters(in: .whitespaces) ?? ""
    }
    
    var oddsBeforeFighter1: Int {
        parseOdds(oddsBeforeRaw, fighter: 1)
    }
    
    var oddsBeforeFighter2: Int {
        parseOdds(oddsBeforeRaw, fighter: 2)
    }
    
    var oddsAfterFighter1: Int {
        parseOdds(oddsAfterRaw, fighter: 1)
    }
    
    var oddsAfterFighter2: Int {
        parseOdds(oddsAfterRaw, fighter: 2)
    }
    
    var displayTimeStamp: String {
        let components = timeStamp.components(separatedBy: "_")
        guard components.count >= 2 else { return timeStamp }
        return components[1]
    }
    
    private func parseOdds(_ oddsString: String, fighter: Int) -> Int {
        let components = oddsString.components(separatedBy: "|")
        guard components.count >= 2 else { return 0 }
        
        let targetComponent = fighter == 1 ? components[0] : components[1]
        let trimmed = targetComponent.trimmingCharacters(in: .whitespaces)
        
        if trimmed == "-" { return 0 }
        
        // Remove any + sign before converting to integer
        let cleanedValue = trimmed.replacingOccurrences(of: "+", with: "")
        return Int(cleanedValue) ?? 0
    }
}

// Helper class to manage and process odds data
class OddsProcessor {
    static func processOddsData(from csvData: [[String: String]]) -> [OddsMovement] {
        var oddsMovements: [OddsMovement] = []
        
        for row in csvData {
            guard let matchup = row["matchup"],
                  let gameDate = row["game_date"],
                  let sportsbook = row["sportsbook"],
                  let oddsBeforeRaw = row["odds_before"],
                  let oddsAfterRaw = row["odds_after"],
                  let file1 = row["file1"],
                  let file2 = row["file2"] else {
                continue
            }
            
            // Create a timestamp from the filename (format: ufc_odds_vsin_YYYYMMDD_HHMM.json)
            let timeStamp = "\(file1)_\(file2)"
            
            let movement = OddsMovement(
                matchup: matchup,
                gameDate: gameDate,
                sportsbook: sportsbook,
                oddsBeforeRaw: oddsBeforeRaw,
                oddsAfterRaw: oddsAfterRaw,
                timeStamp: timeStamp
            )
            
            oddsMovements.append(movement)
        }
        
        return oddsMovements
    }
    
    static func getOddsChartData(for fighter: String, from movements: [OddsMovement]) -> [OddsChartPoint] {
        var chartData: [OddsChartPoint] = []
        let relevantMovements = movements.filter { 
            $0.fighter1.lowercased() == fighter.lowercased() || 
            $0.fighter2.lowercased() == fighter.lowercased() 
        }
        
        for movement in relevantMovements {
            let isFighter1 = movement.fighter1.lowercased() == fighter.lowercased()
            let beforeOdds = isFighter1 ? movement.oddsBeforeFighter1 : movement.oddsBeforeFighter2
            let afterOdds = isFighter1 ? movement.oddsAfterFighter1 : movement.oddsAfterFighter2
            
            // Only add points where odds changed
            if beforeOdds != 0 {
                chartData.append(OddsChartPoint(
                    timestamp: movement.displayTimeStamp,
                    odds: beforeOdds,
                    sportsbook: movement.sportsbook
                ))
            }
            
            if afterOdds != 0 {
                chartData.append(OddsChartPoint(
                    timestamp: movement.displayTimeStamp + "+",
                    odds: afterOdds,
                    sportsbook: movement.sportsbook
                ))
            }
        }
        
        // Sort by timestamp
        return chartData.sorted { $0.timestamp < $1.timestamp }
    }
}

struct OddsChartPoint: Identifiable, Codable {
    let timestamp: String
    let odds: Int
    let sportsbook: String
    
    // New: parsed date from timestamp
    let date: Date?
    
    // New: formatted date string for axis labels
    var formattedDate: String {
        guard let date = date else { return timestamp }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, h:mma"
        formatter.amSymbol = "am"
        formatter.pmSymbol = "pm"
        return formatter.string(from: date)
    }
    
    var id: String { "\(timestamp)-\(sportsbook)" }
    
    // Convert American odds to probability
    var impliedProbability: Double {
        if odds > 0 {
            return 100.0 / Double(odds + 100)
        } else if odds < 0 {
            return Double(abs(odds)) / Double(abs(odds) + 100)
        }
        return 0.5 // Even odds
    }
    
    // Custom decoding to parse date from timestamp
    enum CodingKeys: String, CodingKey {
        case timestamp, odds, sportsbook
    }
    
    init(timestamp: String, odds: Int, sportsbook: String) {
        self.timestamp = timestamp
        self.odds = odds
        self.sportsbook = sportsbook
        self.date = OddsChartPoint.parseDate(from: timestamp)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(String.self, forKey: .timestamp)
        self.odds = try container.decode(Int.self, forKey: .odds)
        self.sportsbook = try container.decode(String.self, forKey: .sportsbook)
        self.date = OddsChartPoint.parseDate(from: self.timestamp)
    }
    
    // Helper to parse date from timestamp string (e.g., ufc_odds_fightoddsio_20250616_0452.csv)
    static func parseDate(from timestamp: String) -> Date? {
        // Try to extract YYYYMMDD_HHMM from the string
        let regex = try? NSRegularExpression(pattern: "(\\d{8})_(\\d{4})")
        let range = NSRange(location: 0, length: timestamp.utf16.count)
        guard let match = regex?.firstMatch(in: timestamp, options: [], range: range),
              match.numberOfRanges == 3,
              let dateRange = Range(match.range(at: 1), in: timestamp),
              let timeRange = Range(match.range(at: 2), in: timestamp) else {
            return nil
        }
        let dateStr = String(timestamp[dateRange]) // e.g., 20250616
        let timeStr = String(timestamp[timeRange]) // e.g., 0452
        let fullStr = dateStr + timeStr // 202506160452
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmm"
        formatter.timeZone = TimeZone.current
        return formatter.date(from: fullStr)
    }
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
    let eventID: Int?
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
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        eventID = try container.decodeIfPresent(Int.self, forKey: .eventID) ?? 0
        
        eventName = try container.decode(String.self, forKey: .eventName)
        fighter1 = try container.decode(String.self, forKey: .fighter1)
        fighter2 = try container.decode(String.self, forKey: .fighter2)
        
        fighter1ID = (try? container.decode(Int.self, forKey: .fighter1ID)) ??
            (Int(try container.decodeIfPresent(String.self, forKey: .fighter1ID) ?? "") ?? 0)
        fighter2ID = (try? container.decode(Int.self, forKey: .fighter2ID)) ??
            (Int(try container.decodeIfPresent(String.self, forKey: .fighter2ID) ?? "") ?? 0)
        
        location = try container.decodeIfPresent(String.self, forKey: .location)
        date = try container.decodeIfPresent(String.self, forKey: .date)
        venue = try container.decodeIfPresent(String.self, forKey: .venue)
        weightClass = try container.decodeIfPresent(String.self, forKey: .weightClass)
        winner = try container.decodeIfPresent(String.self, forKey: .winner)
        method = try container.decodeIfPresent(String.self, forKey: .method)
        round = try container.decodeIfPresent(Int.self, forKey: .round)
        time = try container.decodeIfPresent(String.self, forKey: .time)
        referee = try container.decodeIfPresent(String.self, forKey: .referee)
        fightType = try container.decodeIfPresent(String.self, forKey: .fightType)
    }
} 
