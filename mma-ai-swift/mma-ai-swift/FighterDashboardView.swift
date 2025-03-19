import SwiftUI

struct FighterDashboardView: View {
    @State private var selectedDivision = "All"
    @State private var searchText = ""
    @State private var selectedFighter: FighterStats? = nil
    @StateObject private var viewModel = FighterDashboardViewModel()
    
    private let divisions = ["All", "Heavyweight", "Light Heavyweight", "Middleweight", "Welterweight", "Lightweight", "Featherweight", "Bantamweight", "Flyweight", "Women's"]
    
    var body: some View {
        VStack {
            // Division selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(divisions, id: \.self) { division in
                        Button(action: {
                            selectedDivision = division
                        }) {
                            Text(division)
                                .fontWeight(selectedDivision == division ? .bold : .medium)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedDivision == division ? AppTheme.accent : Color.clear)
                                .foregroundColor(selectedDivision == division ? .white : AppTheme.textPrimary)
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search fighters", text: $searchText)
                    .foregroundColor(AppTheme.textPrimary)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(AppTheme.cardBackground)
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading fighters...")
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                // Fighter grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(filteredFighters, id: \.name) { fighter in
                            FighterTileView(fighter: fighter) {
                                debugPrint("🔵 Selected fighter: \(fighter.name)")
                                selectedFighter = fighter
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            viewModel.loadFighters()
        }
        .fullScreenCover(item: $selectedFighter) { fighter in
            FighterProfileView(
                fighter: fighter,
                onDismiss: {
                    debugPrint("🔵 Fighter profile dismissed for: \(fighter.name)")
                    selectedFighter = nil
                }
            )
        }
    }
    
    private var filteredFighters: [FighterStats] {
        viewModel.getFilteredFighters(division: selectedDivision, searchText: searchText)
    }
}

@MainActor
class FighterDashboardViewModel: ObservableObject {
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var isLoading = true
    
    func loadFighters() {
        debugPrint("🔵 Loading fighters in dashboard")
        isLoading = true
        
        // Load fighters from FighterDataManager
        DispatchQueue.global().async { [weak self] in
            let loadedFighters = FighterDataManager.shared.fighters
            
            DispatchQueue.main.async {
                self?.fighters = loadedFighters
                self?.isLoading = false
                debugPrint("✅ Loaded \(loadedFighters.count) fighters in dashboard")
            }
        }
    }
    
    func getFilteredFighters(division: String, searchText: String) -> [FighterStats] {
        var result = fighters.values.map { $0 }
        
        // Filter by division
        if division != "All" {
            if division == "Women's" {
                result = result.filter { $0.weightClass.contains("Women") }
            } else {
                result = result.filter { $0.weightClass == division }
            }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { 
                $0.name.lowercased().contains(searchText.lowercased()) ||
                ($0.nickname?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
        
        // Sort alphabetically
        return result.sorted { $0.name < $1.name }
    }
}

struct FighterTileView: View {
    let fighter: FighterStats
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                Text(fighter.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
                
                if let nickname = fighter.nickname {
                    Text("'\(nickname)'")
                        .font(.caption)
                        .foregroundColor(AppTheme.accent)
                        .lineLimit(1)
                }
                
                Text(fighter.record)
                    .font(.callout)
                    .foregroundColor(.secondary)
                
                Text(fighter.weightClass)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(10)
        }
    }
}

#Preview {
    FighterDashboardView()
        .preferredColorScheme(.dark)
} 