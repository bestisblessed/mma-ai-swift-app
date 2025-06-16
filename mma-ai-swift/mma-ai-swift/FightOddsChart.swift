import SwiftUI
import Charts

/// Line chart comparing odds movement for both fighters in a matchup.
struct OddsFightChart: View {
    let fight: Fight
    let movements: [OddsMovement]

    private func points(for fighter: String) -> [OddsPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var buckets: [Date: [Double]] = [:]
        for move in movements where move.fighter == fighter {
            if let ts = move.time_after, let date = formatter.date(from: ts) {
                buckets[date, default: []].append(move.odds_after)
            }
        }
        return buckets.map { date, values in
            let avg = values.reduce(0, +) / Double(values.count)
            return OddsPoint(date: date, value: avg)
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart {
            ForEach(points(for: fight.redCorner)) { point in
                LineMark(x: .value("Time", point.date),
                         y: .value("Odds", point.value))
                    .foregroundStyle(.red)
            }
            ForEach(points(for: fight.blueCorner)) { point in
                LineMark(x: .value("Time", point.date),
                         y: .value("Odds", point.value))
                    .foregroundStyle(.blue)
            }
        }
    }
}

/// Simple wrapper used when presenting the chart in a sheet
struct FightOddsView: View {
    let fight: Fight
    @ObservedObject private var dataManager = FighterDataManager.shared

    var body: some View {
        VStack {
            Text("\(fight.redCorner) vs \(fight.blueCorner)")
                .font(.headline)
                .foregroundColor(.white)
            OddsFightChart(fight: fight, movements: dataManager.oddsMovements)
                .frame(height: 250)
        }
        .padding()
        .background(AppTheme.background)
    }
}
