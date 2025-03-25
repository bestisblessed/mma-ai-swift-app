import SwiftUI

class SettingsManager: ObservableObject {
    @Published var useDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(useDarkMode, forKey: "useDarkMode")
        }
    }
    
    @Published var apiEndpoint: String {
        didSet {
            UserDefaults.standard.set(apiEndpoint, forKey: "apiEndpoint")
        }
    }
    
    init() {
        self.useDarkMode = UserDefaults.standard.object(forKey: "useDarkMode") as? Bool ?? true
        self.apiEndpoint = UserDefaults.standard.string(forKey: "apiEndpoint") ?? "https://mma-ai.duckdns.org/api"
    }
}

struct SettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @Environment(\.presentationMode) var presentationMode
    @State private var tempApiEndpoint: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Toggle("Dark Mode", isOn: $settingsManager.useDarkMode)
                }
                
                Section(header: Text("API Settings")) {
                    TextField("API Endpoint", text: $tempApiEndpoint)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onAppear {
                            tempApiEndpoint = settingsManager.apiEndpoint
                        }
                    
                    Button("Save Endpoint") {
                        settingsManager.apiEndpoint = tempApiEndpoint
                    }
                    .disabled(tempApiEndpoint == settingsManager.apiEndpoint)
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    Link("GitHub Repository", destination: URL(string: "https://github.com/yourusername/mma-ai")!)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .preferredColorScheme(settingsManager.useDarkMode ? .dark : .light)
    }
}

#Preview {
    SettingsView(settingsManager: SettingsManager())
} 