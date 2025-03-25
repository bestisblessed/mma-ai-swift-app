import SwiftUI

struct FighterCard: View {
    let fighter: FighterStats
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(fighter.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                if let nickname = fighter.nickname {
                    Text("\"\(nickname)\"")
                        .font(.caption)
                        .italic()
                        .foregroundColor(AppTheme.accent)
                }
                
                Text(fighter.record)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(AppTheme.primary)
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    compactStatRow(label: "Weight", value: fighter.weightClass)
                    compactStatRow(label: "Age", value: "\(fighter.age)")
                    compactStatRow(label: "Height", value: fighter.height)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 6) {
                    compactStatRow(label: "Team", value: fighter.teamAffiliation)
                    compactStatRow(label: "Country", value: fighter.nationality ?? "N/A")
                    compactStatRow(label: "Hometown", value: fighter.hometown ?? "N/A")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppTheme.cardBackground)
            
            // Replace text stats with pie chart
            FighterChartView(
                winsByKO: fighter.winsByKO ?? 0,
                winsBySubmission: fighter.winsBySubmission ?? 0,
                winsByDecision: fighter.winsByDecision ?? 0,
                lossesByKO: fighter.lossesByKO ?? 0,
                lossesBySubmission: fighter.lossesBySubmission ?? 0,
                lossesByDecision: fighter.lossesByDecision ?? 0,
                chartSize: 100,
                showBothCharts: false // Only show wins on the card
            )
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground)
        }
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
    }
    
    private func compactStatRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(AppTheme.textPrimary)
        }
    }
}

#Preview {
    VStack {
        FighterCard(fighter: FighterStats(
            name: "Max Holloway",
            nickname: "Blessed",
            record: "25-7-0",
            weightClass: "Featherweight",
            age: 32,
            height: "5'11\"",
            reach: "69\"",
            stance: "Orthodox",
            teamAffiliation: "Hawaii Elite MMA",
            nationality: "American",
            hometown: "Waianae, Hawaii",
            birthDate: "Dec 4, 1991",
            fighterID: 12345, winsByKO: 12,
            winsBySubmission: 4,
            winsByDecision: 9,
            lossesByKO: 1,
            lossesBySubmission: 1,
            lossesByDecision: 5
        ))
        .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
}
