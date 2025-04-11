import SwiftUI
import Charts

struct FighterProfileView: View {
    let fighter: FighterStats
    let onDismiss: () -> Void
    
    @State private var selectedTab = 0
    @State private var showingFightHistory = false
    @State private var fightHistory: [FightRecord]?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text(fighter.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(fighter.nickname ?? "")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .opacity(fighter.nickname == nil ? 0 : 1)
                        
                        Text(fighter.weightClass)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            
                        if !fighter.teamAffiliation.isEmpty {
                            Text(fighter.teamAffiliation)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top)
                    
                    // Stats Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 20) {
                        StatBox(title: "Record", value: fighter.record)
                        StatBox(title: "Age", value: "\(fighter.age)")
                        
                        // Origin/Location Box
                        VStack(spacing: 4) {
                            Text("Nationality")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            Text(fighter.nationality ?? "N/A")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(8)
                        
                        StatBox(title: "Height", value: fighter.height)
                        StatBox(title: "Reach", value: fighter.reach ?? "N/A")
                        StatBox(title: "Stance", value: fighter.stance ?? "N/A")
                    }
                    .padding(.horizontal)
                    
                    // Stats Charts
                    VStack(alignment: .leading, spacing: 16) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 30) {
                                Spacer(minLength: 0)
                                
                                // Win Method Distribution
                                VStack {
                                    Chart {
                                        SectorMark(
                                            angle: .value("KO/TKO", fighter.winsByKO ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.red)
                                        
                                        SectorMark(
                                            angle: .value("Submission", fighter.winsBySubmission ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.purple)
                                        
                                        SectorMark(
                                            angle: .value("Decision", fighter.winsByDecision ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.orange)
                                    }
                                    .frame(width: 120, height: 120)
                                    
                                    Text("Win Methods")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 8) {
                                        Text("KO: \(fighter.winsByKO ?? 0)")
                                            .foregroundColor(.red)
                                        Text("SUB: \(fighter.winsBySubmission ?? 0)")
                                            .foregroundColor(.purple)
                                        Text("DEC: \(fighter.winsByDecision ?? 0)")
                                            .foregroundColor(.orange)
                                    }
                                    .font(.caption)
                                }
                                
                                // Loss Method Distribution
                                VStack {
                                    Chart {
                                        SectorMark(
                                            angle: .value("KO/TKO", fighter.lossesByKO ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.red.opacity(0.7))
                                        
                                        SectorMark(
                                            angle: .value("Submission", fighter.lossesBySubmission ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.purple.opacity(0.7))
                                        
                                        SectorMark(
                                            angle: .value("Decision", fighter.lossesByDecision ?? 0),
                                            innerRadius: .ratio(0.8),
                                            angularInset: 2.0
                                        )
                                        .foregroundStyle(.orange.opacity(0.7))
                                    }
                                    .frame(width: 120, height: 120)
                                    
                                    Text("Loss Methods")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    HStack(spacing: 8) {
                                        Text("KO: \(fighter.lossesByKO ?? 0)")
                                            .foregroundColor(.red.opacity(0.7))
                                        Text("SUB: \(fighter.lossesBySubmission ?? 0)")
                                            .foregroundColor(.purple.opacity(0.7))
                                        Text("DEC: \(fighter.lossesByDecision ?? 0)")
                                            .foregroundColor(.orange.opacity(0.7))
                                    }
                                    .font(.caption)
                                }
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Fight History Button
                    Button(action: {
                        loadFightHistory()
                        showingFightHistory = true
                    }) {
                        Text("View Fight History")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                        onDismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingFightHistory) {
                if let history = fightHistory {
                    FightHistoryView(fights: history, fighterName: fighter.name)
                } else {
                    ProgressView("Loading fight history...")
                }
            }
        }
    }
    
    private func loadFightHistory() {
        fightHistory = FighterDataManager.shared.getFightRecords(fighter.name)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

// Helper extension for clamping values
extension Double {
    func clamped(to limits: ClosedRange<Double>) -> Double {
        return min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct FightHistoryView: View {
    let fights: [FightRecord]
    let fighterName: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(fights) { fight in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(fight.event)
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(fight.date)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Text(fight.opponent)
                            .font(.subheadline)
                            .foregroundColor(fight.result == "W" ? .green : (fight.result == "L" ? .red : .gray))
                        
                        Spacer()
                        
                        Text(fight.method)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                    
                    if let round = fight.round, let time = fight.time {
                        Text("Round \(round) - \(time)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(Color.black.opacity(0.3))
            }
            .listStyle(.plain)
            .background(AppTheme.background)
            .navigationTitle("\(fighterName)'s Fight History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FighterProfileView(
        fighter: FighterStats(
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
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
