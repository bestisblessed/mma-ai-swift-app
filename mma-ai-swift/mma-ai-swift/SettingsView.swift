import SwiftUI

class SettingsManager: ObservableObject {
    @Published var useDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(useDarkMode, forKey: "useDarkMode")
        }
    }
    
    init() {
        self.useDarkMode = UserDefaults.standard.object(forKey: "useDarkMode") as? Bool ?? true
    }
}

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $settingsManager.useDarkMode)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.3.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/yourusername/mma-ai")!)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                // toolbar items
            }
        }
        .preferredColorScheme(settingsManager.useDarkMode ? .dark : .light)
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
} 