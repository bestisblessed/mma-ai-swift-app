import SwiftUI

struct FighterProfileView: View {
    let fighter: FighterStats
    let onDismiss: () -> Void
    @StateObject private var viewModel = FighterProfileViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let fighterData = viewModel.fighter {
                    fighterContentView(fighter: fighterData)
                } else {
                    errorView
                }
            }
            .navigationTitle(fighter.name)
            .navigationBarItems(trailing: Button("Close") {
                onDismiss()
            })
        }
        .onAppear {
            debugPrint("🔵 FighterProfileView appeared for: \(fighter.name) (ID: \(fighter.fighterID))")
            viewModel.loadFighter(fighter: fighter)
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView("Loading fighter data...")
                .progressViewStyle(CircularProgressViewStyle())
            Text(fighter.name)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .padding(.vertical, 50)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.yellow)
            Text("Could not load fighter data")
                .font(.headline)
            Button("Retry") {
                viewModel.loadFighter(fighter: fighter)
            }
        }
        .padding()
    }
    
    private func fighterContentView(fighter: FighterStats) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Basic fighter info
                VStack(spacing: 4) {
                    Text(fighter.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    if let nickname = fighter.nickname {
                        Text("\"\(nickname)\"")
                            .font(.caption)
                            .italic()
                            .foregroundColor(AppTheme.accent)
                    }
                    
                    Text(fighter.record)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(AppTheme.primary)
                
                // Fighter stats
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        statRow(label: "Weight", value: fighter.weightClass)
                        statRow(label: "Age", value: "\(fighter.age)")
                        statRow(label: "Height", value: fighter.height)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        statRow(label: "Team", value: fighter.teamAffiliation)
                        statRow(label: "Country", value: fighter.nationality ?? "N/A")
                        statRow(label: "Hometown", value: fighter.hometown ?? "N/A")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Performance Analysis with Win/Loss Charts
                VStack {
                    Text("Performance Analysis")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                        .padding(.top, 8)

                    // Win/Loss charts
                    FighterChartView(
                        winsByKO: fighter.winsByKO ?? 0,
                        winsBySubmission: fighter.winsBySubmission ?? 0,
                        winsByDecision: fighter.winsByDecision ?? 0,
                        lossesByKO: fighter.lossesByKO ?? 0,
                        lossesBySubmission: fighter.lossesBySubmission ?? 0,
                        lossesByDecision: fighter.lossesByDecision ?? 0,
                        chartSize: 120,
                        showBothCharts: true
                    )
                    .padding(.vertical, 8)
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Fight history
                if !viewModel.fightHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recent Fights")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top, 10)
                        
                        ForEach(viewModel.fightHistory, id: \.opponent) { fight in
                            FightHistoryRow(fight: fight)
                        }
                    }
                    .padding(.bottom)
                } else {
                    Text("No recent fights found")
                        .foregroundColor(.secondary)
                        .padding(.vertical, 30)
                }
            }
        }
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

struct FightHistoryRow: View {
    let fight: FightResult
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading) {
                    Text(fight.opponent)
                        .fontWeight(.semibold)
                    Text(fight.event)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(fight.outcome)
                        .fontWeight(.bold)
                        .foregroundColor(fight.outcome == "Win" ? .green : .red)
                    Text(fight.method)
                        .font(.caption)
                    Text(fight.date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(10)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture {
            // Future enhancement: navigate to opponent profile using opponentID
            debugPrint("🔵 Tapped on opponent: \(fight.opponent) (ID: \(fight.opponentID))")
        }
    }
}

@MainActor
class FighterProfileViewModel: ObservableObject {
    @Published private(set) var fighter: FighterStats?
    @Published private(set) var fightHistory: [FightResult] = []
    @Published private(set) var isLoading = true
    
    func loadFighter(fighter: FighterStats) {
        isLoading = true
        
        // Get the latest fighter data from the shared manager
        let enhancedFighter = FighterDataManager.shared.getFighter(fighter.name)
        
        // Get fight history from the shared manager
        let history = FighterDataManager.shared.getFightHistory(fighter.name) ?? []
        
        DispatchQueue.main.async {
            self.fighter = enhancedFighter ?? fighter // Fall back to original fighter if not found
            self.fightHistory = history
            self.isLoading = false
            
            // Log the ID for debugging
            debugPrint("✅ Loaded fighter profile with ID: \(enhancedFighter?.fighterID ?? 0)")
        }
    }
}
