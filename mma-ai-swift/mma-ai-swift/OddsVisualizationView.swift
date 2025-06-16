import SwiftUI
import Charts

struct OddsVisualizationView: View {
    let fighter: FighterStats
    @State private var oddsData: [OddsChartPoint] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
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
                } else if oddsData.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                        
                        Text("No odds data available")
                            .font(.headline)
                        
                        Text("There is no betting odds movement data available for \(fighter.name) at this time.")
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
                            
                            // American odds chart
                            OddsLineChart(chartTitle: "American Odds", data: oddsData, isOddsChart: true)
                                .frame(height: 250)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            // Implied probability chart
                            OddsLineChart(chartTitle: "Implied Win Probability", data: oddsData, isOddsChart: false)
                                .frame(height: 250)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            // Bookmaker breakdown
                            BookmakerBreakdownView(data: oddsData)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            
                            // Data sources and explanation
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About Betting Odds")
                                    .font(.headline)
                                    .foregroundColor(.yellow)
                                
                                Text("American odds show the amount you would win on a $100 bet (if positive) or how much you need to bet to win $100 (if negative). Implied probability is the conversion of odds to a percentage chance of winning.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                                
                                Text("Data source: ufc_odds_movements.csv")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
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
        // Simulate loading from odds data source
        // In a real app, this would fetch from a local database or API
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // Create some sample data for demonstration
            // In a real implementation, you would parse the CSV data
            let sampleData: [OddsChartPoint] = [
                OddsChartPoint(timestamp: "0313_1821", odds: -150, sportsbook: "Circa"),
                OddsChartPoint(timestamp: "0313_2057", odds: -145, sportsbook: "Wynn"),
                OddsChartPoint(timestamp: "0314_0951", odds: -155, sportsbook: "Westgate"),
                OddsChartPoint(timestamp: "0314_0957", odds: -160, sportsbook: "Circa"),
                OddsChartPoint(timestamp: "0317_1731", odds: -170, sportsbook: "BetMGM"),
                OddsChartPoint(timestamp: "0317_1807", odds: -165, sportsbook: "Circa"),
                OddsChartPoint(timestamp: "0317_2019", odds: -180, sportsbook: "Westgate"),
                OddsChartPoint(timestamp: "0317_2143", odds: -185, sportsbook: "Circa"),
                OddsChartPoint(timestamp: "0318_0043", odds: -170, sportsbook: "Circa"),
                OddsChartPoint(timestamp: "0318_0331", odds: -175, sportsbook: "Circa")
            ]
            
            self.oddsData = sampleData
            self.isLoading = false
        }
    }
}

struct OddsLineChart: View {
    let chartTitle: String
    let data: [OddsChartPoint]
    let isOddsChart: Bool
    
    // Helper function to format timestamp
    private func formatTimestamp(_ timestamp: String) -> String {
        guard timestamp.count == 9,
              let month = Int(timestamp.prefix(2)),
              let day = Int(timestamp.dropFirst(2).prefix(2)) else {
            return timestamp
        }
        return String(format: "%02d/%02d", month, day)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(chartTitle)
                .font(.headline)
                .foregroundColor(.yellow)
            
            Chart {
                ForEach(data) { point in
                    if isOddsChart {
                        LineMark(
                            x: .value("Time", formatTimestamp(point.timestamp)),
                            y: .value("Odds", point.odds)
                        )
                        .foregroundStyle(.green)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Time", formatTimestamp(point.timestamp)),
                            y: .value("Odds", point.odds)
                        )
                        .foregroundStyle(.green)
                        .symbolSize(30)
                    } else {
                        LineMark(
                            x: .value("Time", formatTimestamp(point.timestamp)),
                            y: .value("Probability", point.impliedProbability)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        
                        PointMark(
                            x: .value("Time", formatTimestamp(point.timestamp)),
                            y: .value("Probability", point.impliedProbability)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
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
                                Text("\(intVal)")
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

struct BookmakerBreakdownView: View {
    let data: [OddsChartPoint]
    
    // Group data by sportsbook
    private var bookmakerData: [String: [OddsChartPoint]] {
        Dictionary(grouping: data, by: { $0.sportsbook })
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
                            let sortedPoints = points.sorted(by: { $0.timestamp < $1.timestamp })
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
