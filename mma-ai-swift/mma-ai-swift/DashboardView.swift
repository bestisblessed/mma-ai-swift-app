import SwiftUI

struct DashboardView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab selector
            HStack(spacing: 0) {
                TabButton(title: "Upcoming", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                
                TabButton(title: "Rankings", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                
                TabButton(title: "News", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
            }
            .background(AppTheme.cardBackground)
            
            // Content
            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case 0:
                        UpcomingEventsView()
                    case 1:
                        RankingsView()
                    case 2:
                        NewsView()
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
        .background(AppTheme.background)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .foregroundColor(isSelected ? Color.yellow : AppTheme.textSecondary)
        }
        .background(
            ZStack {
                if isSelected {
                    Rectangle()
                        .fill(Color.yellow)
                        .frame(height: 3)
                        .offset(y: 15)
                }
            }
        )
    }
}

struct UpcomingEventsView: View {
    @ObservedObject private var dataManager = FighterDataManager.shared
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Upcoming Events")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
                .disabled(isRefreshing)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if dataManager.loadingState == .loading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .scaleEffect(1.5)
                    
                    Text("Loading upcoming events...")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            } else if case let .error(errorMessage) = dataManager.loadingState {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    
                    Text("Failed to load events")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        refreshData()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .padding(.top, 8)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            } else if dataManager.getUpcomingEvents().isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    
                    Text("No upcoming events found")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Check back later for upcoming UFC events")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            } else {
                ForEach(dataManager.getUpcomingEvents(), id: \.name) { event in
                    EventCard(event: event)
                }
                
                Text("Data source: upcoming_event_data_sherdog.csv")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
    }
    
    private func refreshData() {
        isRefreshing = true
        
        Task {
            do {
                try await dataManager.refreshData()
            } catch {
                print("Error refreshing data: \(error)")
            }
            
            DispatchQueue.main.async {
                isRefreshing = false
            }
        }
    }
}

struct RankingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("BETA")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("UFC Rankings")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                Text("Heavyweight Division")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RankingRow(position: "C", name: "Jon Jones", record: "27-1-0")
                RankingRow(position: "1", name: "Ciryl Gane", record: "11-2-0")
                RankingRow(position: "2", name: "Stipe Miocic", record: "20-4-0")
                RankingRow(position: "3", name: "Tom Aspinall", record: "13-3-0")
                RankingRow(position: "4", name: "Curtis Blaydes", record: "17-4-0")
                RankingRow(position: "5", name: "Sergei Pavlovich", record: "18-2-0")
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            
            VStack(spacing: 8) {
                Text("Lightweight Division")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                RankingRow(position: "C", name: "Islam Makhachev", record: "24-1-0")
                RankingRow(position: "1", name: "Charles Oliveira", record: "33-9-0")
                RankingRow(position: "2", name: "Dustin Poirier", record: "29-8-0")
                RankingRow(position: "3", name: "Justin Gaethje", record: "24-4-0")
                RankingRow(position: "4", name: "Arman Tsarukyan", record: "20-3-0")
                RankingRow(position: "5", name: "Michael Chandler", record: "23-8-0")
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}

struct RankingRow: View {
    let position: String
    let name: String
    let record: String
    
    var body: some View {
        HStack {
            Text(position)
                .font(.headline)
                .foregroundColor(position == "C" ? AppTheme.accent : AppTheme.textSecondary)
                .frame(width: 30)
            
            Text(name)
                .font(.body)
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Text(record)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct NewsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("BETA")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.top, 20)
            
            Text("Latest MMA News")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            NewsCard(
                title: "Jon Jones vs. Stipe Miocic Targeted for UFC 306",
                date: "February 28, 2025",
                summary: "The UFC is targeting a heavyweight title fight between champion Jon Jones and former champion Stipe Miocic for UFC 306 at the Sphere in Las Vegas.",
                source: "MMA Fighting"
            )
            
            NewsCard(
                title: "Islam Makhachev Defends Title Against Arman Tsarukyan",
                date: "February 25, 2025",
                summary: "Lightweight champion Islam Makhachev successfully defended his title against Arman Tsarukyan via unanimous decision in a closely contested rematch.",
                source: "ESPN MMA"
            )
            
            NewsCard(
                title: "UFC Announces Return to Australia for UFC 305",
                date: "February 20, 2025",
                summary: "The UFC has officially announced its return to Perth, Australia for UFC 305, featuring a middleweight title fight between Israel Adesanya and Dricus Du Plessis.",
                source: "UFC.com"
            )
        }
    }
}

struct NewsCard: View {
    let title: String
    let date: String
    let summary: String
    let source: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(summary)
                .font(.body)
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(3)
            
            HStack {
                Text(source)
                    .font(.caption)
                    .foregroundColor(AppTheme.accent)
                
                Spacer()
                
                Text(date)
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .preferredColorScheme(.dark)
} 
