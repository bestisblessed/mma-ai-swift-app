import SwiftUI
import Charts

struct FighterComparisonView: View {
    let fighter1: FighterStats
    let fighter2: FighterStats?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with fighter names
                    HStack {
                        FighterHeaderView(fighter: fighter1)
                        Spacer()
                        Text("VS")
                            .font(.headline)
                            .foregroundColor(.yellow)
                        Spacer()
                        if let fighter2 = fighter2 {
                            FighterHeaderView(fighter: fighter2)
                        } else {
                            VStack(spacing: 4) {
                                Text("No opponent")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                Text("")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Basic stats comparison
                    ComparisonSection(title: "Basic Stats") {
                        ComparisonRow(title: "Record", value1: fighter1.record, value2: fighter2?.record ?? "-")
                        ComparisonRow(title: "Age", value1: "\(fighter1.age)", value2: fighter2 != nil ? "\(fighter2!.age)" : "-")
                        ComparisonRow(title: "Height", value1: fighter1.height, value2: fighter2?.height ?? "-")
                        ComparisonRow(title: "Reach", value1: fighter1.reach ?? "N/A", value2: fighter2?.reach ?? "-")
                        ComparisonRow(title: "Stance", value1: fighter1.stance ?? "N/A", value2: fighter2?.stance ?? "-")
                    }
                    
                    // Win method comparison charts
                    ComparisonSection(title: "Win Methods") {
                        HStack {
                            VictoryMethodChart(
                                fighter: fighter1,
                                totalWins: (fighter1.winsByKO ?? 0) + (fighter1.winsBySubmission ?? 0) + (fighter1.winsByDecision ?? 0)
                            )
                            if let fighter2 = fighter2 {
                                VictoryMethodChart(
                                    fighter: fighter2,
                                    totalWins: (fighter2.winsByKO ?? 0) + (fighter2.winsBySubmission ?? 0) + (fighter2.winsByDecision ?? 0)
                                )
                            } else {
                                Spacer()
                            }
                        }
                    }
                    
                    // Win percentages comparison
                    if let fighter2 = fighter2 {
                        ComparisonSection(title: "Win Percentages") {
                            WinPercentagesChart(fighter1: fighter1, fighter2: fighter2)
                        }
                        // Advanced matchup analysis
                        ComparisonSection(title: "Matchup Analysis") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Stylistic Matchup")
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                
                                let analysis = generateMatchupAnalysis(fighter1: fighter1, fighter2: fighter2)
                                Text(analysis)
                                    .font(.body)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding()
                                    .background(Color.black.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Fighter Comparison")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
    }
    
    private func generateMatchupAnalysis(fighter1: FighterStats, fighter2: FighterStats) -> String {
        // This is a simplified analysis - in a real app, you would use more sophisticated
        // analysis based on complete fighter data and statistics
        
        let ageAdvantage: String
        if fighter1.age < fighter2.age - 5 {
            ageAdvantage = "\(fighter1.name) has a significant youth advantage, being \(fighter2.age - fighter1.age) years younger."
        } else if fighter2.age < fighter1.age - 5 {
            ageAdvantage = "\(fighter2.name) has a significant youth advantage, being \(fighter1.age - fighter2.age) years younger."
        } else {
            ageAdvantage = "Both fighters are in a similar age range."
        }
        
        let winMethodAnalysis: String
        let fighter1KOPercentage = calculatePercentage(fighter1.winsByKO ?? 0, total: getTotalWins(fighter1))
        let fighter2KOPercentage = calculatePercentage(fighter2.winsByKO ?? 0, total: getTotalWins(fighter2))
        let fighter1SubPercentage = calculatePercentage(fighter1.winsBySubmission ?? 0, total: getTotalWins(fighter1))
        let fighter2SubPercentage = calculatePercentage(fighter2.winsBySubmission ?? 0, total: getTotalWins(fighter2))
        
        if fighter1KOPercentage > 60 && fighter2SubPercentage > 60 {
            winMethodAnalysis = "Classic striker vs grappler matchup: \(fighter1.name) has a striking advantage with \(fighter1KOPercentage)% KO wins, while \(fighter2.name) will look to take the fight to the ground with \(fighter2SubPercentage)% submission victories."
        } else if fighter2KOPercentage > 60 && fighter1SubPercentage > 60 {
            winMethodAnalysis = "Classic striker vs grappler matchup: \(fighter2.name) has a striking advantage with \(fighter2KOPercentage)% KO wins, while \(fighter1.name) will look to take the fight to the ground with \(fighter1SubPercentage)% submission victories."
        } else if fighter1KOPercentage > 60 && fighter2KOPercentage > 60 {
            winMethodAnalysis = "Potential firefight between two strikers: both \(fighter1.name) (\(fighter1KOPercentage)% KOs) and \(fighter2.name) (\(fighter2KOPercentage)% KOs) prefer to keep the fight standing."
        } else if fighter1SubPercentage > 60 && fighter2SubPercentage > 60 {
            winMethodAnalysis = "Grappling-heavy matchup: both \(fighter1.name) (\(fighter1SubPercentage)% submissions) and \(fighter2.name) (\(fighter2SubPercentage)% submissions) excel on the ground."
        } else {
            winMethodAnalysis = "Both fighters have shown well-rounded skill sets with wins across different methods."
        }
        
        return "\(ageAdvantage)\n\n\(winMethodAnalysis)"
    }
    
    private func getTotalWins(_ fighter: FighterStats) -> Int {
        return (fighter.winsByKO ?? 0) + (fighter.winsBySubmission ?? 0) + (fighter.winsByDecision ?? 0)
    }
    
    private func calculatePercentage(_ value: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(value) / Double(total)) * 100)
    }
}

struct FighterHeaderView: View {
    let fighter: FighterStats
    
    var body: some View {
        VStack(spacing: 4) {
            Text(fighter.name)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            if let nickname = fighter.nickname, !nickname.isEmpty {
                Text("\"\(nickname)\"")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .multilineTextAlignment(.center)
            }
            
            Text(fighter.weightClass)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ComparisonSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .padding(.horizontal)
            
            content
        }
        .padding(.vertical, 10)
    }
}

struct ComparisonRow: View {
    let title: String
    let value1: String
    let value2: String
    
    var body: some View {
        HStack(alignment: .center) {
            Text(value1)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .trailing)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .center)
            
            Text(value2)
                .font(.subheadline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct VictoryMethodChart: View {
    let fighter: FighterStats
    let totalWins: Int
    
    private var koPercentage: Double {
        totalWins > 0 ? Double(fighter.winsByKO ?? 0) / Double(totalWins) : 0
    }
    
    private var submissionPercentage: Double {
        totalWins > 0 ? Double(fighter.winsBySubmission ?? 0) / Double(totalWins) : 0
    }
    
    private var decisionPercentage: Double {
        totalWins > 0 ? Double(fighter.winsByDecision ?? 0) / Double(totalWins) : 0
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text(fighter.name)
                .font(.caption)
                .foregroundColor(.gray)
            
            if totalWins > 0 {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: koPercentage)
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: koPercentage, to: koPercentage + submissionPercentage)
                        .stroke(Color.purple, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Circle()
                        .trim(from: koPercentage + submissionPercentage, to: 1)
                        .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(totalWins)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Legend
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("KO: \(fighter.winsByKO ?? 0)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                        Text("SUB: \(fighter.winsBySubmission ?? 0)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                        Text("DEC: \(fighter.winsByDecision ?? 0)")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            } else {
                Text("No win data")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .frame(height: 140)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(10)
    }
}

struct WinPercentagesChart: View {
    let fighter1: FighterStats
    let fighter2: FighterStats
    
    private var data: [(String, Double, Double)] {
        let f1Total = getTotalWins(fighter1)
        let f2Total = getTotalWins(fighter2)
        
        return [
            ("KO", f1Total > 0 ? Double(fighter1.winsByKO ?? 0) / Double(f1Total) : 0,
             f2Total > 0 ? Double(fighter2.winsByKO ?? 0) / Double(f2Total) : 0),
            
            ("SUB", f1Total > 0 ? Double(fighter1.winsBySubmission ?? 0) / Double(f1Total) : 0,
             f2Total > 0 ? Double(fighter2.winsBySubmission ?? 0) / Double(f2Total) : 0),
            
            ("DEC", f1Total > 0 ? Double(fighter1.winsByDecision ?? 0) / Double(f1Total) : 0,
             f2Total > 0 ? Double(fighter2.winsByDecision ?? 0) / Double(f2Total) : 0)
        ]
    }
    
    private func getTotalWins(_ fighter: FighterStats) -> Int {
        return (fighter.winsByKO ?? 0) + (fighter.winsBySubmission ?? 0) + (fighter.winsByDecision ?? 0)
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(fighter1.name)
                    .font(.caption)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(fighter2.name)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            Chart {
                ForEach(data, id: \.0) { item in
                    BarMark(
                        x: .value("Category", item.0),
                        y: .value("Percentage", item.1 * 100)
                    )
                    .foregroundStyle(Color.blue)
                    .position(by: .value("Fighter", fighter1.name))
                    
                    BarMark(
                        x: .value("Category", item.0),
                        y: .value("Percentage", item.2 * 100)
                    )
                    .foregroundStyle(Color.red)
                    .position(by: .value("Fighter", fighter2.name))
                }
            }
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine()
                    AxisTick()
                    if let val = value.as(Double.self) {
                        AxisValueLabel {
                            Text("\(Int(val))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }
}

#Preview {
    FighterComparisonView(
        fighter1: FighterStats(
            name: "Jon Jones",
            nickname: "Bones",
            record: "27-1-0",
            weightClass: "Heavyweight",
            age: 36,
            height: "6'4\"",
            reach: "84.5\"",
            stance: "Orthodox",
            teamAffiliation: "Jackson-Wink MMA",
            nationality: "American",
            hometown: "Rochester, NY",
            birthDate: "July 19, 1987",
            fighterID: 123456,
            winsByKO: 10,
            winsBySubmission: 7,
            winsByDecision: 10,
            lossesByKO: 0,
            lossesBySubmission: 0,
            lossesByDecision: 1
        ),
        fighter2: FighterStats(
            name: "Alexander Gustafsson",
            nickname: "The Mauler",
            record: "18-8-0",
            weightClass: "Light Heavyweight",
            age: 37,
            height: "6'5\"",
            reach: "79.0\"",
            stance: "Orthodox",
            teamAffiliation: "Allstars Training Center",
            nationality: "Swedish",
            hometown: "Stockholm, Sweden",
            birthDate: "January 15, 1987",
            fighterID: 234567,
            winsByKO: 11,
            winsBySubmission: 3,
            winsByDecision: 4,
            lossesByKO: 5,
            lossesBySubmission: 2,
            lossesByDecision: 1
        )
    )
    .preferredColorScheme(.dark)
}
