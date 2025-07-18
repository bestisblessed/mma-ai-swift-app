import SwiftUI
import Charts

// Allowed sportsbooks for filtering everywhere in the odds dashboard
let allowedSportsbooks: Set<String> = [
    "betmgm", "betonline", "bookmaker", "bovada", "caesars-sportsbook", "circa-sports", "draftkings", "espn-bet", "fanduel", "mybookie", "pinnacle-sports"
]

struct OddsVisualizationView: View {
    let fighter: FighterStats
    @State private var oddsData: [OddsChartPoint] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var lastUpdated: String = ""
    
    // Sportsbook selector state
    @State private var sportsbooks: [String] = ["All"]
    @State private var selectedSportsbook: String = "All"
    
    // Filter helper
    private var filteredOddsData: [OddsChartPoint] {
        selectedSportsbook == "All"
        ? oddsData
        : oddsData.filter { $0.sportsbook == selectedSportsbook }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if !lastUpdated.isEmpty {
                    Text("Last updated: \(lastUpdated)")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 4)
                }
                if isLoading {
                    ProgressView("Loading odds data...")
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        
                        Text("Error loading odds data")
                            .font(.headline)
                        
                        Text(error)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else if filteredOddsData.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        
                        Text("No odds data available")
                            .font(.headline)
                        
                        Text("No odds movement data available for \(fighter.name) at this time.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("\(fighter.name) Betting Odds Movement")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if sportsbooks.count > 1 {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(sportsbooks, id: \.self) { book in
                                            Button(book) {
                                                selectedSportsbook = book
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 12)
                                            .background(
                                                selectedSportsbook == book
                                                ? AppTheme.accent
                                                : Color.clear
                                            )
                                            .foregroundColor(
                                                selectedSportsbook == book
                                                ? .black
                                                : .white
                                            )
                                            .cornerRadius(14)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .stroke(AppTheme.accent.opacity(0.6), lineWidth: 1)
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // American odds chart (filtered)
                            OddsLineChart(
                                chartTitle: "American Odds",
                                data: filteredOddsData,
                                isOddsChart: true
                            )
                            .frame(height: 250)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Implied probability chart (filtered)
                            OddsLineChart(
                                chartTitle: "Implied Win Probability",
                                data: filteredOddsData,
                                isOddsChart: false
                            )
                            .frame(height: 250)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            
                            // Bookmaker breakdown (filtered)
                            BookmakerBreakdownView(data: filteredOddsData)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .background(AppTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Odds Movement")
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
            .onAppear {
                loadOddsData()
                fetchLastUpdatedFromBackend()
            }
        }
    }
    
    private func loadOddsData() {
        // Try cached odds first for immediate display
        let safeName = fighter.name.replacingOccurrences(of: " ", with: "_").lowercased()
        if let cached = FileCache.load([OddsChartPoint].self, from: "odds_chart_\(safeName).json"), !cached.isEmpty {
            // Filter out unwanted sportsbooks and update UI synchronously
            let initial = cached.filter { allowedSportsbooks.contains($0.sportsbook) }
            oddsData = initial
            let books = Set(initial.map { $0.sportsbook }).sorted()
            sportsbooks = ["All"] + books
            selectedSportsbook = "All"
            isLoading = false
        }

        Task {
            do {
                let points = try await NetworkManager.shared.fetchOddsChart(for: fighter.name)
                DispatchQueue.main.async {
                    // Filter out unwanted sportsbooks from oddsData
                    oddsData = points.filter { allowedSportsbooks.contains($0.sportsbook) }
                    // Build selector list
                    let books = Set(oddsData.map { $0.sportsbook }).sorted()
                    sportsbooks = ["All"] + books
                    selectedSportsbook = "All"
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func fetchLastUpdatedFromBackend() {
        Task {
            if let epoch = await NetworkManager.shared.fetchOddsLastUpdated() {
                let date = Date(timeIntervalSince1970: epoch)
                let formatter = DateFormatter()
                formatter.timeZone = TimeZone(identifier: "America/New_York")
                //formatter.dateFormat = "MM/dd HH:mm a"
                formatter.dateFormat = "MMMM d HH:mm a"
                let formatted = formatter.string(from: date)
                // Calculate how long ago
                let now = Date()
                let interval = now.timeIntervalSince(date)
                let totalHours = Int(interval / 3600)
                let days = totalHours / 24
                let hours = totalHours % 24
                var agoString = ""
                if days > 0 {
                    agoString = "(\(days)d \(hours)h)"
                } else if totalHours > 0 {
                    agoString = "(\(totalHours)h)"
                } else {
                    let minutes = max(1, Int(interval / 60))
                    agoString = "(\(minutes)m)"
                }
                DispatchQueue.main.async {
                    lastUpdated = "\(formatted) \(agoString)"
                }
            } else {
                DispatchQueue.main.async {
                    lastUpdated = "Unknown"
                }
            }
        }
    }
}

// Helper extension for conditional modifier
extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

struct OddsLineChart: View {
    let chartTitle: String
    let data: [OddsChartPoint]
    let isOddsChart: Bool
    
    // Calculate expanded x-axis domain
    private var xDomain: ClosedRange<Date>? {
        let dates = data.compactMap { $0.date }
        guard let minDate = dates.min(), let maxDate = dates.max() else { return nil }
        // Add 1 hour to maxDate for padding
        let paddedMax = Calendar.current.date(byAdding: .hour, value: 1, to: maxDate) ?? maxDate
        return minDate...paddedMax
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Move title above the chart and change color
            Text(chartTitle)
                .font(.custom("Times New Roman", size: 20).weight(.bold))
                //.foregroundColor(.blue)
                .foregroundColor(AppTheme.accent)

                .padding(.bottom, 2)
            if let xDomain = xDomain {
                Chart {
                    ForEach(data) { point in
                        if let date = point.date {
                            if isOddsChart {
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Odds", point.odds)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Odds", point.odds)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(30)
                            } else {
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Probability", point.impliedProbability)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Probability", point.impliedProbability)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(30)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .chartXScale(domain: xDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(
                            value.as(Date.self).map {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM/dd"
                                return formatter.string(from: $0)
                            } ?? ""
                        )
                        .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if isOddsChart {
                                if let intVal = value.as(Int.self) {
                                    Text(intVal > 0 ? "+\(intVal)" : "\(intVal)")
                                        .font(.caption)
                                }
                            } else {
                                if let doubleVal = value.as(Double.self) {
                                    Text("\(Int(doubleVal * 100))%")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            } else {
                Chart {
                    ForEach(data) { point in
                        if let date = point.date {
                            if isOddsChart {
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Odds", point.odds)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Odds", point.odds)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(30)
                            } else {
                                LineMark(
                                    x: .value("Time", date),
                                    y: .value("Probability", point.impliedProbability)
                                )
                                .foregroundStyle(.green)
                                .lineStyle(StrokeStyle(lineWidth: 1))
                                
                                PointMark(
                                    x: .value("Time", date),
                                    y: .value("Probability", point.impliedProbability)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(30)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(
                            value.as(Date.self).map {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "MM/dd"
                                return formatter.string(from: $0)
                            } ?? ""
                        )
                        .font(.caption)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if isOddsChart {
                                if let intVal = value.as(Int.self) {
                                    Text(intVal > 0 ? "+\(intVal)" : "\(intVal)")
                                        .font(.caption)
                                }
                            } else {
                                if let doubleVal = value.as(Double.self) {
                                    Text("\(Int(doubleVal * 100))%")
                                        .font(.caption)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct BookmakerBreakdownView: View {
    let data: [OddsChartPoint]
    
    // Group data by sportsbook, but only allowed ones
    private var bookmakerData: [String: [OddsChartPoint]] {
        Dictionary(grouping: data.filter { allowedSportsbooks.contains($0.sportsbook) }, by: { $0.sportsbook })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bookmaker Breakdown")
                .font(.headline)
                .foregroundColor(.yellow)
            
            ForEach(bookmakerData.keys.sorted(), id: \.self) { bookmaker in
                if let points = bookmakerData[bookmaker] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(bookmaker)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        // Show the range of odds for this bookmaker
                        let minOdds = points.min(by: { $0.odds < $1.odds })?.odds ?? 0
                        let maxOdds = points.max(by: { $0.odds < $1.odds })?.odds ?? 0
                        
                        if minOdds != maxOdds {
                            Text("Range: \(minOdds) to \(maxOdds)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Stable at \(minOdds)")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        // Trend indicator
                        if points.count > 1 {
                            let sortedPoints = points.sorted(by: { $0.id < $1.id })
                            let firstOdds = sortedPoints.first?.odds ?? 0
                            let lastOdds = sortedPoints.last?.odds ?? 0
                            
                            HStack {
                                if lastOdds < firstOdds {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.red)
                                    Text("Odds shortened (favorite)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else if lastOdds > firstOdds {
                                    Image(systemName: "arrow.up")
                                        .foregroundColor(.green)
                                    Text("Odds lengthened (underdog)")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                } else {
                                    Image(systemName: "minus")
                                        .foregroundColor(.yellow)
                                    Text("No change")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(8)
                }
            }
        }
    }
}

#Preview {
    OddsVisualizationView(
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
        )
    )
    .preferredColorScheme(.dark)
}
