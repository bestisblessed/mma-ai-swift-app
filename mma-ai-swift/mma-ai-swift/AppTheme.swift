import SwiftUI

struct AppTheme {
    // Main colors
    static let primary = Color(red: 0.8, green: 0.0, blue: 0.0)  // UFC Red
    static let secondary = Color(red: 0.1, green: 0.1, blue: 0.2)  // Dark Blue/Black
    static let accent = Color(red: 0.9, green: 0.7, blue: 0.0)  // Gold
    
    // Background colors
    static let background = Color(red: 0.05, green: 0.05, blue: 0.1)  // Near Black
    static let cardBackground = Color(red: 0.15, green: 0.15, blue: 0.2)  // Dark Gray
    
    // Text colors
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.8)
    static let textMuted = Color(white: 0.6)
    
    // Message bubbles
    static let userBubble = primary
    static let botBubble = cardBackground
    static let userBubbleText = Color.white
    static let botBubbleText = Color.white
    
    // Input field
    static let inputBackground = Color(red: 0.2, green: 0.2, blue: 0.25)
    static let inputText = Color.white
    static let inputPlaceholder = Color(white: 0.6)
    
    // Button states
    static let buttonDisabled = Color(white: 0.4)
    
    // Gradients
    static let headerGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primary.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [background, secondary]),
        startPoint: .top,
        endPoint: .bottom
    )
}

// Custom button style
struct PrimaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(isDisabled ? AppTheme.buttonDisabled : AppTheme.primary)
            .foregroundColor(AppTheme.textPrimary)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// Custom text field style
struct AppTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(AppTheme.inputBackground)
            .cornerRadius(20)
            .foregroundColor(AppTheme.inputText)
            .accentColor(AppTheme.accent)
    }
}

// Extension for custom modifiers
extension View {
    func cardStyle() -> some View {
        self
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
    }
    
    func appTitle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func appHeadline() -> some View {
        self
            .font(.headline)
            .foregroundColor(AppTheme.textSecondary)
    }
}

struct ThinkingView: View {
    @State private var animationOffset = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 8, height: 8)
                    .offset(y: animationOffset.isNaN ? 0 : sin(animationOffset + Double(index) * 0.5) * 5)
            }
        }
        .padding(12)
        .background(AppTheme.botBubble)
        .cornerRadius(18)
        .onAppear {
            withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationOffset = animationOffset.isNaN ? 0 : 2 * .pi
            }
        }
    }
} 