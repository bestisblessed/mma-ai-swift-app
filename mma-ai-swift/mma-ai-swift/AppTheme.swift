import SwiftUI

// Color extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

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
    static let botBubble = secondary
    static let userBubbleText = Color.white
    static let botBubbleText = Color.white
    
    // Input field
    static let inputBackground = Color(red: 0.2, green: 0.2, blue: 0.25)
    static let inputText = Color.white
    static let inputPlaceholder = Color(white: 0.6)
    
    // Button states
    static let buttonDisabled = Color(white: 0.4)
    
    // Chart colors
    static let koColor = Color.green // green ko
    static let submissionColor = Color(red: 0.3, green: 0.6, blue: 0.9) // blue submission
    static let decisionColor = Color(red: 0.5, green: 0.4, blue: 0.8) // purple decision
    
    // Status colors
    static let success = Color.green
    static let error = Color.red
    static let warning = Color(red: 0.9, green: 0.7, blue: 0.0)  // Gold
    
    // Shadows
    static let shadowColor = Color.black.opacity(0.3)
    static let shadowRadius: CGFloat = 5
    static let shadowX: CGFloat = 0
    static let shadowY: CGFloat = 2
    
    // Gradients
    static let headerGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primary.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundGradient = LinearGradient(
        gradient: Gradient(colors: [background, background.opacity(0.9)]),
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

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(AppTheme.primary, lineWidth: 2)
            )
            .foregroundColor(AppTheme.primary)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
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
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating && index == 0 ? 1.0 : 0.7)
                    .animation(
                        Animation.easeInOut(duration: 0.5)
                            .repeatForever()
                            .delay(0.2 * Double(index)),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}