import SwiftUI
import Charts

struct OddsHistoryView: View {
    @ObservedObject private var dataManager = FighterDataManager.shared
    @State private var searchText: String = ""

    private var filteredFighters: [String] {
        let names = Array(Set(dataManager.oddsMovements.map { $0.fighter }))
        if searchText.isEmpty { return names.sorted() }
        return names.filter { $0.localizedCaseInsensitiveContains(searchText) }.sorted()
    }

    var body: some View {
        VStack {
            TextField("Search Fighter", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            ScrollView {
                ForEach(filteredFighters, id: \.self) { fighter in
                    VStack(alignment: .leading) {
                        Text(fighter)
                            .font(.headline)
                            .foregroundColor(.white)
                        OddsLineChart(fighter: fighter, movements: dataManager.oddsMovements)
                            .frame(height: 200)
                    }
                    .padding()
                }
            }
        }
        .background(AppTheme.background)
    }
}
