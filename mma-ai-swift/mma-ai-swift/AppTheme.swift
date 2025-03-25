import SwiftUI

class AppTheme {
    // Main colors
    static let primary = Color("PrimaryColor", default: Color.red)
    static let accent = Color("AccentColor", default: Color.yellow)
    static let background = Color("BackgroundColor", default: Color.black)
    static let cardBackground = Color("CardBackgroundColor", default: Color(UIColor.systemGray6))
    
    // Text colors
    static let textPrimary = Color("TextPrimaryColor", default: Color.white)
    static let textSecondary = Color("TextSecondaryColor", default: Color.gray)
    static let textMuted = Color.gray // Add the missing text muted color
    
    // Chart colors
    static let koColor = Color("KOColor", default: Color.red)
    static let submissionColor = Color("SubmissionColor", default: Color.blue)
    static let decisionColor = Color("DecisionColor", default: Color.green)
    
    // Background colors
    static let secondary = Color(red: 0.1, green: 0.1, blue: 0.2)  // Dark Blue/Black
    
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
    
    // Static accessor for ColorScheme
    static var colorScheme: ColorScheme? = nil // Initialize with nil to avoid binding issue
}

extension Color {
    init(_ name: String, default defaultColor: Color) {
        self = Color(UIColor(named: name) ?? UIColor(defaultColor))
    }
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

// Extension to handle ColorScheme for preview providers
extension AppTheme {
    static func preview(_ colorScheme: ColorScheme? = nil) -> some View {
        EmptyView().onAppear {
            AppTheme.colorScheme = colorScheme
        }
    }
} 