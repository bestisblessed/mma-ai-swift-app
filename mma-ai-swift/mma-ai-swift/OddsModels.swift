import Foundation

struct OddsMovement: Codable, Identifiable {
    let id = UUID()
    let file1: String
    let file2: String
    let fighter: String
    let sportsbook: String
    let odds_before: Double
    let odds_after: Double
    let time_before: String?
    let time_after: String?
}

struct OddsResponse: Codable {
    let timestamp: String
    let odds: [OddsMovement]
}

struct OddsPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
