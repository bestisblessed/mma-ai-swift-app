import SwiftUI

// struct FighterStats: Identifiable {
//     var id: String { name }
//     let name: String
//     let nickname: String?
//     let record: String // e.g., "21-6-0"
//     let weightClass: String
//     let age: Int
//     let height: String
//     // let reach: String
//     // let stance: String
//     let teamAffiliation: String
// }
//struct FighterStats: Identifiable {
//    var id: String { name }
//    let name: String
//    let nickname: String?
//    let record: String // e.g., "21-6-0"
//    let weightClass: String
//    let age: Int
//    let height: String
//    let reach: String?
//    let stance: String?
//    let teamAffiliation: String
//    let nationality: String?
//    let hometown: String?
//    let birthDate: String
//    let winsByKO: Int?
//    let winsBySubmission: Int?
//    let winsByDecision: Int?
//} 

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
            
            VStack(spacing: 4) {
                Text("Win Methods")
                    .font(.caption)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 4)
                
                HStack(spacing: 20) {
                    statValue(value: "\(fighter.winsByKO ?? 0)", label: "KO/TKO")
                    statValue(value: "\(fighter.winsBySubmission ?? 0)", label: "SUB")
                    statValue(value: "\(fighter.winsByDecision ?? 0)", label: "DEC")
                }
                .padding(.bottom, 8)
            }
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
    
    private func statValue(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textPrimary)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
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
            // reach: "69\"",
            // stance: "Orthodox",
            teamAffiliation: "Hawaii Elite MMA",
            nationality: "American",
            hometown: "Waianae, Hawaii",
            birthDate: "Dec 4, 1991",
            winsByKO: 12,
            winsBySubmission: 4,
            winsByDecision: 9
        ))
        .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
} 
