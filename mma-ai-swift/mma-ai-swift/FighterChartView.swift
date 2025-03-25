import SwiftUI

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
    
    // Default initializer with all data
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
    
    // Convenience initializer for just wins data
    init(winsByKO: Int, winsBySubmission: Int, winsByDecision: Int, chartSize: CGFloat = 100) {
        self.init(winsByKO: winsByKO, winsBySubmission: winsBySubmission, winsByDecision: winsByDecision,
                  lossesByKO: 0, lossesBySubmission: 0, lossesByDecision: 0, chartSize: chartSize)
    }
    
    private var winsData: [WinLossSlice] {
        [
            WinLossSlice(type: "KO/TKO", count: winsByKO, color: AppTheme.koColor),
            WinLossSlice(type: "SUB", count: winsBySubmission, color: AppTheme.submissionColor),
            WinLossSlice(type: "DEC", count: winsByDecision, color: AppTheme.decisionColor)
        ].filter { $0.count > 0 } // Only include slices with non-zero values
    }
    
    private var lossesData: [WinLossSlice] {
        [
            WinLossSlice(type: "KO/TKO", count: lossesByKO, color: AppTheme.koColor),
            WinLossSlice(type: "SUB", count: lossesBySubmission, color: AppTheme.submissionColor),
            WinLossSlice(type: "DEC", count: lossesByDecision, color: AppTheme.decisionColor)
        ].filter { $0.count > 0 } // Only include slices with non-zero values
    }
    
    private var totalWins: Int {
        winsByKO + winsBySubmission + winsByDecision
    }
    
    private var totalLosses: Int {
        lossesByKO + lossesBySubmission + lossesByDecision
    }
    
    var body: some View {
        Group {
            if showBothCharts {
                HStack(alignment: .top, spacing: 0) {
                    // Win methods chart
                    chartView(
                        title: "Win Methods",
                        data: winsData,
                        total: totalWins
                    )
                    
                    // Loss methods chart
                    chartView(
                        title: "Loss Methods",
                        data: lossesData,
                        total: totalLosses
                    )
                }
            } else {
                // Just wins chart
                chartView(
                    title: "Win Methods",
                    data: winsData,
                    total: totalWins
                )
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

struct PieChartView: View {
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
        let startAngle = Double(precedingTotal) / Double(totalValue) * 360
        return startAngle
    }
    
    private func endAngleForSlice(_ slice: WinLossSlice) -> Double {
        startAngleForSlice(slice) + (Double(slice.count) / Double(totalValue) * 360)
    }
}

struct PieSliceView: View {
    var startAngle: Double
    var endAngle: Double
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let radius = min(geometry.size.width, geometry.size.height) / 2
                
                path.move(to: center)
                
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: Angle(degrees: startAngle - 90),
                    endAngle: Angle(degrees: endAngle - 90),
                    clockwise: false
                )
                
                path.closeSubpath()
            }
            .fill(color)
        }
    }
}

#Preview {
    VStack {
        FighterChartView(
            winsByKO: 12,
            winsBySubmission: 2,
            winsByDecision: 12,
            lossesByKO: 1,
            lossesBySubmission: 1,
            lossesByDecision: 6,
            chartSize: 150,
            showBothCharts: true
        )
        .padding()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
