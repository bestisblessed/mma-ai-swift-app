import SwiftUI

class SettingsManager: ObservableObject {
    @Published var useDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(useDarkMode, forKey: "useDarkMode")
        }
    }
    // Add published property for last data refresh timestamp
    @Published var lastDataRefresh: String = "Never"

    init() {
        self.useDarkMode = UserDefaults.standard.object(forKey: "useDarkMode") as? Bool ?? true
        // Initialize last data refresh value
        updateLastDataRefresh()
        // Observe changes to UserDefaults to keep timestamp up-to-date
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsChanged),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Helpers
    @objc private func userDefaultsChanged() {
        updateLastDataRefresh()
    }

    private func updateLastDataRefresh() {
        let epoch = UserDefaults.standard.double(forKey: "lastUpdateTime")
        let formatted: String
        if epoch > 0 {
            let date = Date(timeIntervalSince1970: epoch)
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            formatted = formatter.string(from: date)
        } else {
            formatted = "Never"
        }
        // Ensure state update happens on the next run-loop cycle to avoid SwiftUI warnings
        DispatchQueue.main.async {
            self.lastDataRefresh = formatted
        }
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
                
                // New section displaying last data refresh time
                Section(header: Text("Data")) {
                    HStack {
                        Text("Last Refresh")
                        Spacer()
                        Text(settingsManager.lastDataRefresh)
                            .foregroundColor(.gray)
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.3.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/bestisblessed")!)
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