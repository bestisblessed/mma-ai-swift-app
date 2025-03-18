import SwiftUI

struct LaunchScreen: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            Color(red: 0.05, green: 0.05, blue: 0.1) // Near Black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "figure.boxing")
                    .font(.system(size: 70))
                    .foregroundColor(AppTheme.accent)
                    .scaleEffect(isAnimating ? 1.0 : 0.6)
                    .opacity(isAnimating ? 1.0 : 0.5)
                
                // App name
                Text("MMA AI")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textPrimary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // Tagline
                Text("Your AI Fighting Expert")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textSecondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .padding(.top, 4)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    LaunchScreen()
} 