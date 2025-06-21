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
                TabButton(title: "News", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "Past", isSelected: selectedTab == 2) {
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
                        NewsView()
                    case 2:
                        PastEventsView()
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
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 16) {
            // Removed refresh button (moved to main tab bar)
            
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
                
//                Text("Data source: upcoming_event_data_sherdog.csv")
//                    .font(.caption)
//                    .foregroundColor(AppTheme.textSecondary)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .padding(.top, 8)
            }
        }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    refreshData()
                }
            }
        // .onAppear {
        //     refreshData()
        // }
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

struct PastEventsView: View {
    @ObservedObject private var dataManager = FighterDataManager.shared
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        VStack(spacing: 16) {
            
            if dataManager.loadingState == .loading {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                        .scaleEffect(1.5)
                    
                    Text("Loading past events...")
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
            } else if dataManager.getPastEvents().isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.yellow)
                    
                    Text("No past events found")
                        .font(.headline)
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Text("Check back later for past UFC events")
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
                ForEach(dataManager.getPastEvents(), id: \.name) { event in
                    EventCard(event: event, isPastEvent: true)
                }
                
                Text("Data source: event_data_sherdog.csv")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                refreshData()
            }
        }
        // .onAppear {
        //     refreshData()
        // }
    }
    
    private func refreshData() {
        Task {
            do {
                try await dataManager.refreshData()
            } catch {
                print("Error refreshing data: \(error)")
            }
        }
    }
}

struct NewsStory: Identifiable, Decodable {
    let id = UUID()
    let title: String
    let summary: String
    let url: String
}

//struct NewsResponse: Decodable {
//    let news: [NewsStory]
//}

struct NewsView: View {
    @State private var news: [NewsStory] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView("Loading news...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .yellow))
                    .scaleEffect(1.2)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if news.isEmpty {
                Text("No news stories found.")
                    .foregroundColor(AppTheme.textSecondary)
            } else {
                ForEach(news) { story in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(story.title)
                            .font(.headline)
                            .foregroundColor(AppTheme.textPrimary)
                        Text(story.summary)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                        if !story.url.isEmpty {
                            Link("Read more", destination: URL(string: story.url)!)
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                }
            }
        }
        .onAppear(perform: fetchNews)
    }

    func fetchNews() {
        guard let url = URL(string: "https://mma-ai.duckdns.org/api/news") else {
            self.errorMessage = "Invalid news API URL."
            self.isLoading = false
            return
        }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                do {
                    self.news = try JSONDecoder().decode([NewsStory].self, from: data)
                } catch {
                    self.errorMessage = "Failed to parse news: \(error.localizedDescription)"
                }
            }
        }
        task.resume()
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
