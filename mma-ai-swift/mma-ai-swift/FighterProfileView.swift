import SwiftUI
import Charts

struct FighterProfileView: View {
    let fighter: FighterStats
    let onDismiss: () -> Void
    
    @State private var selectedTab = 0
    @State private var fightHistory: [FightRecord]?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            mainContent
        }
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                fighterHeader
                statsGrid
                chartsSection
                fightHistorySection
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
        .onAppear {
            loadFightHistory()
        }
    }
    
    private var fighterHeader: some View {
        VStack(spacing: 8) {
            Text(fighter.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(fighter.nickname ?? "")
                .font(.headline)
                .foregroundColor(.yellow)
                .opacity((fighter.nickname == nil || fighter.nickname == "-") ? 0 : 1)
            
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
    }
    
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            StatBox(title: "Record", value: fighter.record)
            StatBox(title: "Age", value: "\(fighter.age)")
            nationalityBox
            StatBox(title: "Height", value: fighter.height)
            StatBox(title: "Reach", value: fighter.reach ?? "N/A")
            StatBox(title: "Stance", value: fighter.stance ?? "N/A")
        }
        .padding(.horizontal)
    }
    
    private var nationalityBox: some View {
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
    }
    
    private var chartsSection: some View {
        VStack(alignment: .center, spacing: 16) {
            HStack(spacing: 30) {
                Spacer(minLength: 0)
                winMethodsChart
                lossMethodsChart
                Spacer(minLength: 0)
            }
            .padding(.horizontal)
        }
    }
    
    private var winMethodsChart: some View {
        VStack {
            AnimatedVictoryChart(
                koValue: fighter.winsByKO ?? 0,
                subValue: fighter.winsBySubmission ?? 0,
                decValue: fighter.winsByDecision ?? 0,
                title: "Win Methods",
                koColor: .red,
                subColor: .purple,
                decColor: .orange
            )
        }
    }
    
    private var lossMethodsChart: some View {
        VStack {
            AnimatedVictoryChart(
                koValue: fighter.lossesByKO ?? 0,
                subValue: fighter.lossesBySubmission ?? 0,
                decValue: fighter.lossesByDecision ?? 0,
                title: "Loss Methods",
                koColor: .red.opacity(0.7),
                subColor: .purple.opacity(0.7),
                decColor: .orange.opacity(0.7)
            )
        }
    }
    
    private var fightHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fight History")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if let fights = fightHistory, !fights.isEmpty {
                fightHistoryList(fights: fights)
            } else {
                Text("No fight history available")
                    .foregroundColor(.gray)
                    .italic()
                    .padding()
            }
        }
        .padding(.top, 20)
    }
    
    private func fightHistoryList(fights: [FightRecord]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(fights) { fight in
                fightRecordView(fight: fight)
            }
        }
    }
    
    private func fightRecordView(fight: FightRecord) -> some View {
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
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

// Existing chart-related views and animated chart components