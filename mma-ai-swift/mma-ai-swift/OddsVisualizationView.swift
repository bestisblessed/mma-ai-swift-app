import SwiftUI
import Charts

// Allowed sportsbooks for filtering everywhere in the odds dashboard
let allowedSportsbooks: Set<String> = [
    "betmgm", "betonline", "bookmaker", "bovada", "caesars-sportsbook", "circa-sports", "draftkings", "espn-bet", "fanduel", "mybookie", "pinnacle-sports"
]

struct OddsVisualizationView: View {
    let fight: Fight
    @State private var oddsData1: [OddsChartPoint] = []
    @State private var oddsData2: [OddsChartPoint] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    
    // Sportsbook selector state
    @State private var sportsbooks: [String] = ["All"]
    @State private var selectedSportsbook: String = "All"
    @State private var selectedTab: Int = 0
    
    // Filter helper for current fighter tab
    private var filteredOddsData: [OddsChartPoint] {
        let base = (selectedTab == 0 ? oddsData1 : oddsData2)
        return selectedSportsbook == "All"
            ? base
            : base.filter { $0.sportsbook == selectedSportsbook }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
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
                        
                        Text("No odds movement data available for \(selectedTab == 0 ? fight.redCorner : fight.blueCorner) at this time.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("\(selectedTab == 0 ? fight.redCorner : fight.blueCorner) Betting Odds Movement")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                        // 🔽 NEW – sportsbook selector + fighter tabs
                            Picker(selection: $selectedTab, label: EmptyView()) {
                                Text(fight.redCorner).tag(0)
                                Text(fight.blueCorner).tag(1)
                            }
                            .pickerStyle(SegmentedPickerStyle())
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
        }
        }
    }
    
    private func loadOddsData() {
        Task {
            do {
                let points1 = try await NetworkManager.shared.fetchOddsChart(for: fight.redCorner)
                let points2 = try await NetworkManager.shared.fetchOddsChart(for: fight.blueCorner)
                DispatchQueue.main.async {
                    let filtered1 = points1.filter { allowedSportsbooks.contains($0.sportsbook) }
                    let filtered2 = points2.filter { allowedSportsbooks.contains($0.sportsbook) }
                    oddsData1 = filtered1
                    oddsData2 = filtered2
                    FighterDataManager.shared.storeOddsChart(fight.redCorner, data: filtered1)
                    FighterDataManager.shared.storeOddsChart(fight.blueCorner, data: filtered2)
                    let books = Set((filtered1 + filtered2).map { $0.sportsbook }).sorted()
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
        fight: Fight(
            redCorner: "Jon Jones",
            blueCorner: "Stipe Miocic",
            redCornerID: 123456,
            blueCornerID: 654321,
            weightClass: "Heavyweight",
            isMainEvent: false,
            isTitleFight: false,
            round: "",
            time: ""
        )
    )
    .preferredColorScheme(.dark)
}
