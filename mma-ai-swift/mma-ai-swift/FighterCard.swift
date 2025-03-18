import SwiftUI

struct FighterStats {
    let name: String
    let nickname: String?
    let record: String // e.g., "21-6-0"
    let weightClass: String
    let age: Int
    let height: String
    let reach: String
    let stance: String
    let teamAffiliation: String
}

struct FighterCard: View {
    let fighter: FighterStats
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                Text(fighter.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                
                if let nickname = fighter.nickname {
                    Text("\"" + nickname + "\"")
                        .font(.subheadline)
                        .italic()
                        .foregroundColor(AppTheme.accent)
                }
                
                Text(fighter.record)
                    .font(.headline)
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.top, 2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(AppTheme.primary)
            
            // Stats
            VStack(spacing: 12) {
                statRow(label: "Weight Class", value: fighter.weightClass)
                statRow(label: "Age", value: "\(fighter.age)")
                statRow(label: "Height", value: fighter.height)
                statRow(label: "Reach", value: fighter.reach)
                statRow(label: "Stance", value: fighter.stance)
                statRow(label: "Team", value: fighter.teamAffiliation)
            }
            .padding()
            .background(AppTheme.cardBackground)
        }
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 100, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
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
            teamAffiliation: "Hawaii Elite MMA"
        ))
        .padding()
    }
    .background(AppTheme.background)
    .preferredColorScheme(.dark)
} 