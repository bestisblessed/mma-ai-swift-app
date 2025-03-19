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
            debugPrint("🔵 FighterProfileView appeared for: \(fighter.name)")
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
            VStack {
                // Fighter card
                FighterCard(fighter: fighter)
                
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
    }
}

@MainActor
class FighterProfileViewModel: ObservableObject {
    @Published private(set) var fighter: FighterStats?
    @Published private(set) var fightHistory: [FightResult] = []
    @Published private(set) var isLoading = true
    
    func loadFighter(fighter: FighterStats) {
        debugPrint("🔄 Loading fighter data for: \(fighter.name)")
        isLoading = true
        
        // Load fight history
        self.fighter = fighter
        self.fightHistory = FighterDataManager.shared.getFightHistory(fighter.name) ?? []
        self.isLoading = false
        debugPrint("✅ Loaded data for: \(fighter.name)")
    }
} 