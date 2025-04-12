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
                                
                                // Win Methods Chart
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
                                
                                // Loss Methods Chart
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
                                
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Fight History Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fight History")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        if let fights = fightHistory, !fights.isEmpty {
                            LazyVStack(spacing: 8) {
                                ForEach(fights) { fight in
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
                            }
                        } else {
                            Text("No fight history available")
                                .foregroundColor(.gray)
                                .italic()
                                .padding()
                        }
                    }
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
            .onAppear {
                loadFightHistory()
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

// Chart Components
struct WinLossSlice: Identifiable {
    var id = UUID()
    var type: String
    var count: Int
    var color: Color
}

struct FighterChartView: View {
    let winsByKO: Int
    let winsBySubmission: Int
    let winsByDecision: Int
    let lossesByKO: Int
    let lossesBySubmission: Int
    let lossesByDecision: Int
    let chartSize: CGFloat
    let showBothCharts: Bool
    
    init(winsByKO: Int, winsBySubmission: Int, winsByDecision: Int,
         lossesByKO: Int, lossesBySubmission: Int, lossesByDecision: Int, 
         chartSize: CGFloat = 100, showBothCharts: Bool = false) {
        self.winsByKO = winsByKO
        self.winsBySubmission = winsBySubmission
        self.winsByDecision = winsByDecision
        self.lossesByKO = lossesByKO
        self.lossesBySubmission = lossesBySubmission
        self.lossesByDecision = lossesByDecision
        self.chartSize = chartSize
        self.showBothCharts = showBothCharts
    }
    
    init(winsByKO: Int, winsBySubmission: Int, winsByDecision: Int, chartSize: CGFloat = 100) {
        self.init(winsByKO: winsByKO, winsBySubmission: winsBySubmission, winsByDecision: winsByDecision,
                  lossesByKO: 0, lossesBySubmission: 0, lossesByDecision: 0, chartSize: chartSize)
    }
    
    private var winsData: [WinLossSlice] {
        [
            WinLossSlice(type: "KO/TKO", count: winsByKO, color: AppTheme.koColor),
            WinLossSlice(type: "SUB", count: winsBySubmission, color: AppTheme.submissionColor),
            WinLossSlice(type: "DEC", count: winsByDecision, color: AppTheme.decisionColor)
        ].filter { $0.count > 0 }
    }
    
    private var lossesData: [WinLossSlice] {
        [
            WinLossSlice(type: "KO/TKO", count: lossesByKO, color: AppTheme.koColor),
            WinLossSlice(type: "SUB", count: lossesBySubmission, color: AppTheme.submissionColor),
            WinLossSlice(type: "DEC", count: lossesByDecision, color: AppTheme.decisionColor)
        ].filter { $0.count > 0 }
    }
    
    private var totalWins: Int { winsByKO + winsBySubmission + winsByDecision }
    private var totalLosses: Int { lossesByKO + lossesBySubmission + lossesByDecision }
    
    var body: some View {
        Group {
            if showBothCharts {
                HStack(alignment: .top, spacing: 0) {
                    chartView(title: "Win Methods", data: winsData, total: totalWins)
                    chartView(title: "Loss Methods", data: lossesData, total: totalLosses)
                }
            } else {
                chartView(title: "Win Methods", data: winsData, total: totalWins)
            }
        }
    }
    
    private func chartView(title: String, data: [WinLossSlice], total: Int) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textSecondary)
            
            if total > 0 {
                ZStack {
                    PieChartView(data: data, chartSize: chartSize)
                    Text("\(total)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textPrimary)
                }
                
                HStack(spacing: 10) {
                    ForEach(data) { slice in
                        statBadge(value: "\(slice.count)", 
                                  label: slice.type, 
                                  color: slice.color,
                                  percent: Float(slice.count) / Float(total))
                    }
                }
            } else {
                Text("No data")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(height: chartSize)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func statBadge(value: String, label: String, color: Color, percent: Float) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.system(size: 10))
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textSecondary)
            }
            Text(value)
                .font(.system(size: 14))
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            Text(String(format: "%.1f%%", percent * 100))
                .font(.system(size: 10))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(6)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

private struct PieChartView: View {
    let data: [WinLossSlice]
    let chartSize: CGFloat
    
    var totalValue: Int {
        data.reduce(0) { $0 + $1.count }
    }
    
    var body: some View {
        ZStack {
            ForEach(data) { slice in
                if slice.count > 0 {
                    PieSliceView(
                        startAngle: startAngleForSlice(slice),
                        endAngle: endAngleForSlice(slice),
                        color: slice.color
                    )
                }
            }
        }
        .frame(width: chartSize, height: chartSize)
    }
    
    private func startAngleForSlice(_ slice: WinLossSlice) -> Double {
        let index = data.firstIndex(where: { $0.id == slice.id }) ?? 0
        let precedingTotal = data.prefix(index).reduce(0) { $0 + $1.count }
        return Double(precedingTotal) / Double(totalValue) * 360
    }
    
    private func endAngleForSlice(_ slice: WinLossSlice) -> Double {
        startAngleForSlice(slice) + (Double(slice.count) / Double(totalValue) * 360)
    }
}

private struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                path.move(to: center)
                path.addArc(center: center,
                           radius: radius,
                           startAngle: .degrees(startAngle - 90),
                           endAngle: .degrees(endAngle - 90),
                           clockwise: false)
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

// Custom animated circular chart for victory methods
struct AnimatedVictoryChart: View {
    let koValue: Int
    let subValue: Int
    let decValue: Int
    let title: String
    let koColor: Color
    let subColor: Color
    let decColor: Color
    
    @State private var animationProgress: Double = 0
    
    var totalValue: Int {
        koValue + subValue + decValue
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Chart
            ZStack(alignment: .center) {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                    .frame(width: 120, height: 120)
                
                // Segments
                if totalValue > 0 {
                    // Calculate fractions for segments
                    let koFraction = CGFloat(koValue) / CGFloat(totalValue)
                    let subFraction = CGFloat(subValue) / CGFloat(totalValue)
                    let decFraction = CGFloat(decValue) / CGFloat(totalValue)
                    
                    // Always display all three segments to ensure proper spacing
                    // KO segment
                    Circle()
                        .trim(from: 0, to: koFraction * animationProgress)
                        .stroke(koValue > 0 ? koColor : Color.clear, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    
                    // Submission segment
                    Circle()
                        .trim(from: koFraction, to: koFraction + subFraction * animationProgress)
                        .stroke(subValue > 0 ? subColor : Color.clear, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                    
                    // Decision segment
                    Circle()
                        .trim(from: koFraction + subFraction, to: koFraction + subFraction + decFraction * animationProgress)
                        .stroke(decValue > 0 ? decColor : Color.clear, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                }
                
                // Center text
                VStack(spacing: 2) {
                    Text("\(totalValue)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Total")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 130, height: 130)
            .padding(.top, 5)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            // Legend
            VStack(spacing: 6) {
                // Always show all methods in legend, even if zero
                LegendItem(label: "KO", value: koValue, color: koColor, total: totalValue > 0 ? totalValue : 1)
                LegendItem(label: "SUB", value: subValue, color: subColor, total: totalValue > 0 ? totalValue : 1)
                LegendItem(label: "DEC", value: decValue, color: decColor, total: totalValue > 0 ? totalValue : 1)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animationProgress = 1.0
            }
        }
    }
}

struct LegendItem: View {
    let label: String
    let value: Int
    let color: Color
    let total: Int
    
    var percentage: String {
        let percent = Double(value) / Double(total) * 100
        return String(format: "%.1f%%", percent)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text("\(label): \(value)")
                .font(.caption)
                .foregroundColor(.white)
            
            Text(percentage)
                .font(.caption)
                .foregroundColor(.gray)
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
