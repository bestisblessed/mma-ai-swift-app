import Foundation

struct FighterStats: Identifiable {
    var id: String { name }
    let name: String
    let nickname: String?
    let record: String // e.g., "21-6-0"
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
    
    // Win methods
    let winsByKO: Int?
    let winsBySubmission: Int?
    let winsByDecision: Int?
    
    // Loss methods (added)
    let lossesByKO: Int?
    let lossesBySubmission: Int?
    let lossesByDecision: Int?
    
    // Initialize with all parameters
    init(name: String, nickname: String?, record: String, weightClass: String, 
         age: Int, height: String, reach: String? = nil, stance: String? = nil, 
         teamAffiliation: String, nationality: String? = nil, hometown: String? = nil,
         birthDate: String, winsByKO: Int? = nil, winsBySubmission: Int? = nil, 
         winsByDecision: Int? = nil, lossesByKO: Int? = nil, 
         lossesBySubmission: Int? = nil, lossesByDecision: Int? = nil,
         fighterID: Int = 0) {
        
        self.name = name
        self.nickname = nickname
        self.record = record
        self.weightClass = weightClass
        self.age = age
        self.height = height
        self.reach = reach
        self.stance = stance
        self.teamAffiliation = teamAffiliation
        self.nationality = nationality
        self.hometown = hometown
        self.birthDate = birthDate
        self.winsByKO = winsByKO
        self.winsBySubmission = winsBySubmission
        self.winsByDecision = winsByDecision
        self.lossesByKO = lossesByKO
        self.lossesBySubmission = lossesBySubmission
        self.lossesByDecision = lossesByDecision
        self.fighterID = fighterID
    }
}
