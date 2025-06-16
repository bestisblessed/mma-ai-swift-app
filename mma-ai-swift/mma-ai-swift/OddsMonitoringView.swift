import SwiftUI
import Charts

struct OddsMonitoringView: View {
    @ObservedObject private var dataManager = FighterDataManager.shared
    @State private var selectedFight: Fight?

    private var fights: [Fight] {
        dataManager.upcomingEvents.flatMap { $0.fights }
    }

    var body: some View {
        VStack {
            if dataManager.oddsMovements.isEmpty {
                ProgressView("Loading odds...")
            } else {
                Picker("Matchup", selection: $selectedFight) {
                    ForEach(fights) { fight in
                        Text("\(fight.redCorner) vs \(fight.blueCorner)").tag(Optional(fight))
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .onAppear {
                    if selectedFight == nil { selectedFight = fights.first }
                }

                if let fight = selectedFight {
                    OddsFightChart(fight: fight, movements: dataManager.oddsMovements)
                        .frame(height: 250)
                        .padding()
                }
            }
        }
        .background(AppTheme.background)
    }
}

struct OddsLineChart: View {
    let fighter: String
    let movements: [OddsMovement]

    private var points: [OddsPoint] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return movements.filter { $0.fighter == fighter }.compactMap { move in
            if let ts = move.time_after, let date = formatter.date(from: ts) {
                return OddsPoint(date: date, value: move.odds_after)
            }
            return nil
        }.sorted { $0.date < $1.date }
    }

    var body: some View {
        Chart(points) { point in
            LineMark(x: .value("Time", point.date),
                     y: .value("Odds", point.value))
                .foregroundStyle(.yellow)
        }
    }
}
