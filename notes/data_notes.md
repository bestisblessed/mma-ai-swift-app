Let me analyze the pros and cons of bundling data with your app versus fetching it remotely, and what Apple recommends:

**Current Implementation (Bundled Data):**
Your app currently bundles CSV files (`fighter_info.csv` and `event_data_sherdog.csv`) directly in the app package.

**Apple's Recommendations:**
Apple doesn't have a strict preference, but they emphasize:
1. App responsiveness and offline functionality
2. Minimizing app size
3. Data privacy and security
4. Battery and network efficiency

Let's break down the pros and cons:

**Pros of Bundled Data:**
1. **Instant Access**
   - No loading/waiting time
   - Works offline immediately
   - Better user experience on first launch

2. **Reliability**
   - No network-related failures
   - Consistent performance
   - No API rate limits or server costs

3. **Simplicity**
   - No need for error handling of network requests
   - No need for API keys or authentication
   - Simpler code structure

4. **Privacy**
   - No network permissions needed
   - No data tracking concerns
   - Easier App Store approval

**Cons of Bundled Data:**
1. **App Size**
   - Larger initial download size
   - Your current CSV files are relatively small, but could grow
   - Might deter users with limited storage

2. **Update Limitations**
   - Requires app update for new data
   - Can't fix data errors quickly
   - Users need to download entire app update

3. **Scalability**
   - Limited by app size restrictions
   - Can't handle very large datasets
   - No real-time updates

**Alternative Approach - Hybrid Solution:**
Here's what I would recommend for your MMA app:

```swift:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/EventCard.swift
// ... existing code ...

class FighterDataManager {
    static let shared = FighterDataManager()
    
    var fighters: [String: FighterStats] = [:]
    var fightHistory: [String: [FightResult]] = [:]
    var eventDetails: [String: EventInfo] = [:]
    
    private let queue = DispatchQueue(label: "com.mmaai.datamanager", qos: .userInitiated)
    private let cache = UserDefaults.standard
    private let lastUpdateKey = "lastDataUpdate"
    private let cacheValidityDuration: TimeInterval = 24 * 60 * 60 // 24 hours
    
    init() {
        loadData()
    }
    
    private func loadData() {
        queue.async { [weak self] in
            // First load bundled data for instant access
            self?.loadBundledData()
            
            // Then check for updates if online
            self?.checkForUpdates()
        }
    }
    
    private func loadBundledData() {
        verifyDataFiles()
        loadFighterData()
        loadFightHistory()
        
        // Notify main thread that initial data is loaded
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .fighterDataDidLoad, object: nil)
        }
    }
    
    private func checkForUpdates() {
        // Check if we need to update cached data
        let lastUpdate = cache.double(forKey: lastUpdateKey)
        let now = Date().timeIntervalSince1970
        
        guard now - lastUpdate > cacheValidityDuration else {
            print("Cache is still valid, skipping update")
            return
        }
        
        // Here you could implement API calls to fetch updated data
        // For example:
        fetchUpdatedData { [weak self] result in
            switch result {
            case .success(let newData):
                self?.updateLocalData(with: newData)
                self?.cache.set(now, forKey: self?.lastUpdateKey ?? "")
                
                // Notify that updated data is available
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .fighterDataDidUpdate, object: nil)
                }
                
            case .failure(let error):
                print("Failed to fetch updates: \(error)")
            }
        }
    }
    
    private func fetchUpdatedData(completion: @escaping (Result<UpdatedData, Error>) -> Void) {
        // Example implementation:
        guard let url = URL(string: "https://api.yourbackend.com/fighter-updates") else {
            completion(.failure(DataError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(DataError.noData))
                return
            }
            
            do {
                let updatedData = try JSONDecoder().decode(UpdatedData.self, from: data)
                completion(.success(updatedData))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func updateLocalData(with newData: UpdatedData) {
        // Update local data structures with new data
        // This could include:
        // - New fighters
        // - Updated fight records
        // - New events
        // Then save to local storage for offline access
    }
}

// MARK: - Data Types
struct UpdatedData: Codable {
    let fighters: [Fighter]
    let events: [Event]
    let lastUpdate: Date
}

enum DataError: Error {
    case invalidURL
    case noData
    case decodingError
}

// MARK: - Notifications
extension Notification.Name {
    static let fighterDataDidLoad = Notification.Name("fighterDataDidLoad")
    static let fighterDataDidUpdate = Notification.Name("fighterDataDidUpdate")
}

// ... existing code ...
```
**Recommended Approach for Your App:**

1. **Keep the Current Bundled Data:**
   - Maintain base fighter/event data in the bundle
   - Ensures instant app usability
   - Perfect for historical/static data

2. **Add Incremental Updates:**
   - Implement the hybrid solution shown above
   - Only fetch new fights/events
   - Cache updates locally
   - Update every 24 hours or when needed

3. **Optimize Bundle Size:**
   - Keep core fighter profiles bundled
   - Move detailed historical data to API
   - Compress images and media

4. **User Experience:**
   - Show bundled data immediately
   - Load updates in background
   - Cache downloaded data
   - Show update status to users

To implement this in your Info.plist, add:

```plain text:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entries -->
    
    <!-- Add network permissions -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>yourbackend.com</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSTemporaryExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSTemporaryExceptionRequiresForwardSecrecy</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
    <!-- Add background fetch capability -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
    </array>
</dict>
</plist>
```
**Summary of Recommendations:**
1. Keep using bundled data for core content
2. Implement the hybrid solution for updates
3. Use background fetch for new data
4. Cache updates locally
5. Maintain offline functionality
6. Show loading states for updates

This approach gives you the best of both worlds:
- Fast initial load times
- Offline functionality
- Up-to-date content
- Efficient data usage
- Better user experience
- Smaller app updates

Would you like me to help you implement any specific part of this hybrid approach?





# NEW

Ah, in that case, with daily dataset updates, bundling the data with the app would NOT be the best approach. Let me explain why and suggest a better solution:

**Why Bundled Data Won't Work Well:**
1. Each data update would require a new app version
2. App Store review process takes 24-48 hours typically
3. Users would need to update the app daily
4. Very poor user experience
5. Risk of App Store rejection for too frequent updates

**Better Solution for Daily Updates:**
Let me propose a better architecture:

```swift:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/EventCard.swift
// ... existing code ...

class FighterDataManager {
    static let shared = FighterDataManager()
    
    private(set) var fighters: [String: FighterStats] = [:]
    private(set) var fightHistory: [String: [FightResult]] = [:]
    private(set) var eventDetails: [String: EventInfo] = [:]
    
    private let queue = DispatchQueue(label: "com.mmaai.datamanager", qos: .userInitiated)
    private let cache = UserDefaults.standard
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    // Configuration
    private struct Config {
        static let dataURL = "https://your-api.com/api/v1/mma-data"  // Replace with your API endpoint
        static let updateInterval: TimeInterval = 3600 // 1 hour
        static let maxRetries = 3
        static let cacheFileName = "fighter_data.json"
    }
    
    // Loading states
    @Published private(set) var loadingState: LoadingState = .idle
    @Published private(set) var lastUpdateTime: Date?
    
    init() {
        // Set up cache directory
        cacheDirectory = try! fileManager.url(for: .cachesDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: true)
        
        // Start loading sequence
        loadInitialData()
        setupAutoRefresh()
    }
    
    // MARK: - Public Methods
    
    func refreshData() async throws {
        guard loadingState != .loading else { return }
        await loadLatestData(force: true)
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        fighters[name]
    }
    
    func getFightHistory(_ fighter: String) -> [FightResult]? {
        fightHistory[fighter]
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() {
        Task {
            await loadLatestData(force: false)
        }
    }
    
    private func setupAutoRefresh() {
        // Set up timer for periodic updates
        Timer.scheduledTimer(withTimeInterval: Config.updateInterval, repeats: true) { [weak self] _ in
            Task {
                try? await self?.refreshData()
            }
        }
    }
    
    private func loadLatestData(force: Bool) async {
        do {
            // Update loading state
            await MainActor.run {
                loadingState = .loading
            }
            
            // Check if we need to update
            if !force {
                if let cached = try? loadFromCache(),
                   let lastUpdate = lastUpdateTime,
                   Date().timeIntervalSince(lastUpdate) < Config.updateInterval {
                    // Use cached data if it's recent enough
                    await updateDataModels(with: cached)
                    return
                }
            }
            
            // Fetch fresh data
            let data = try await fetchLatestData()
            
            // Save to cache
            try saveToCache(data)
            
            // Update models
            await updateDataModels(with: data)
            
            // Update state
            await MainActor.run {
                loadingState = .success
                lastUpdateTime = Date()
            }
            
        } catch {
            await MainActor.run {
                loadingState = .error(error)
            }
            
            // Try to load from cache as fallback
            if let cached = try? loadFromCache() {
                await updateDataModels(with: cached)
            }
        }
    }
    
    private func fetchLatestData() async throws -> Data {
        guard let url = URL(string: Config.dataURL) else {
            throw DataError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DataError.invalidResponse
        }
        
        return data
    }
    
    private func saveToCache(_ data: Data) throws {
        let cacheFile = cacheDirectory.appendingPathComponent(Config.cacheFileName)
        try data.write(to: cacheFile)
    }
    
    private func loadFromCache() throws -> Data {
        let cacheFile = cacheDirectory.appendingPathComponent(Config.cacheFileName)
        return try Data(contentsOf: cacheFile)
    }
    
    private func updateDataModels(with data: Data) async {
        do {
            let decoder = JSONDecoder()
            let apiData = try decoder.decode(APIResponse.self, from: data)
            
            // Update all models on main thread
            await MainActor.run {
                // Update fighters
                var newFighters: [String: FighterStats] = [:]
                for fighter in apiData.fighters {
                    newFighters[fighter.name] = FighterStats(
                        name: fighter.name,
                        nickname: fighter.nickname,
                        record: fighter.record,
                        weightClass: fighter.weightClass,
                        age: fighter.age,
                        height: fighter.height,
                        teamAffiliation: fighter.team,
                        nationality: fighter.nationality,
                        hometown: fighter.hometown,
                        birthDate: fighter.birthDate,
                        winsByKO: fighter.winsByKO,
                        winsBySubmission: fighter.winsBySub,
                        winsByDecision: fighter.winsByDec
                    )
                }
                self.fighters = newFighters
                
                // Update fight history
                self.fightHistory = apiData.fightHistory
                
                // Update event details
                self.eventDetails = apiData.events
                
                // Notify observers
                NotificationCenter.default.post(name: .fighterDataDidUpdate, object: nil)
            }
        } catch {
            print("Error decoding data: \(error)")
        }
    }
}

// MARK: - Types

enum LoadingState: Equatable {
    case idle
    case loading
    case success
    case error(Error)
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.success, .success):
            return true
        case (.error, .error):
            return true
        default:
            return false
        }
    }
}

struct APIResponse: Codable {
    let fighters: [APIFighter]
    let fightHistory: [String: [FightResult]]
    let events: [String: EventInfo]
    let lastUpdated: Date
}

struct APIFighter: Codable {
    let name: String
    let nickname: String?
    let record: String
    let weightClass: String
    let age: Int
    let height: String
    let team: String
    let nationality: String?
    let hometown: String?
    let birthDate: String
    let winsByKO: Int?
    let winsBySub: Int?
    let winsByDec: Int?
}

enum DataError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case networkError
    case cacheError
}

// MARK: - Notifications
extension Notification.Name {
    static let fighterDataDidUpdate = Notification.Name("fighterDataDidUpdate")
}

// ... existing code ...
```
This new implementation provides:

1. **Real-time Data Updates:**
   - Hourly automatic refresh (configurable)
   - Manual refresh capability
   - Background updates
   - Smart caching system

2. **Offline Support:**
   - Local caching of data
   - Fallback to cached data when offline
   - Automatic retry mechanism

3. **Better User Experience:**
   - No app updates needed for new data
   - Loading states for UI feedback
   - Smooth data transitions
   - Error handling with fallbacks

4. **Performance Optimizations:**
   - Async/await for modern concurrency
   - Background processing
   - Efficient memory usage
   - Minimal network usage

To complete the implementation, you'll need:

1. **Backend API:**
   - Set up an API endpoint that serves your data
   - Format: JSON matching the `APIResponse` structure
   - HTTPS required for App Store
   - Consider using CloudFlare or similar for caching

2. **Update Info.plist:**
   - Add network permissions
   - Add background fetch capability

```plain text:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entries -->
    
    <!-- Network permissions -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>your-api.com</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <false/>
                <key>NSTemporaryExceptionMinimumTLSVersion</key>
                <string>TLSv1.2</string>
                <key>NSTemporaryExceptionRequiresForwardSecrecy</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
    <!-- Background fetch -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
    </array>
    
    <!-- Privacy descriptions -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We use your location to show nearby MMA events.</string>
    
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>We use your location to notify you about nearby MMA events.</string>
</dict>
</plist>
```
3. **Add Loading UI:**
Let's add a loading indicator to your views:

```swift:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/FighterDashboardView.swift
struct FighterDashboardView: View {
    @StateObject private var viewModel = FighterDashboardViewModel()
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            Group {
                switch viewModel.loadingState {
                case .loading:
                    ProgressView("Loading fighters...")
                        .progressViewStyle(CircularProgressViewStyle())
                
                case .error(let error):
                    VStack {
                        Text("Error loading data")
                            .foregroundColor(.red)
                        Text(error.localizedDescription)
                            .font(.caption)
                        Button("Retry") {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    }
                
                case .success, .idle:
                    List {
                        ForEach(Array(viewModel.fighters.values), id: \.name) { fighter in
                            NavigationLink(destination: FighterProfileView(fighter: fighter)) {
                                FighterCard(fighter: fighter)
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("Fighters")
        }
    }
}

class FighterDashboardViewModel: ObservableObject {
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var loadingState: LoadingState = .idle
    
    private let dataManager = FighterDataManager.shared
    
    init() {
        // Subscribe to data updates
        NotificationCenter.default.addObserver(self,
            selector: #selector(handleDataUpdate),
            name: .fighterDataDidUpdate,
            object: nil)
        
        // Load initial data
        loadFighters()
    }
    
    func refresh() async {
        do {
            try await dataManager.refreshData()
        } catch {
            print("Error refreshing data: \(error)")
        }
    }
    
    @objc private func handleDataUpdate() {
        loadFighters()
    }
    
    private func loadFighters() {
        fighters = dataManager.fighters
        loadingState = .success
    }
}
```
This new architecture will:
1. Load data from API on app launch
2. Cache data locally
3. Update automatically every hour
4. Allow manual refresh (pull-to-refresh)
5. Show loading states
6. Handle errors gracefully
7. Work offline using cached data

**Benefits of this approach:**
1. No app updates needed for data changes
2. Better user experience
3. Lower App Store rejection risk
4. Efficient data usage
5. Better performance
6. Real-time updates
7. Offline support

Would you like me to help you set up the backend API for this system?




# NEW

I'll use sequential thinking to break down the best approach to integrate your Flask server with the iOS app for continuous data updates.

Ran tool

Ran tool
I'll proceed with implementing the solution based on the analysis. Let's break this down into steps:

1. First, let's add the necessary endpoints to your Flask server (app.py):

```python:/Users/td/Code/mma-ai-swift-app/app.py
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from openai import OpenAI
import json
import uuid
from dotenv import load_dotenv
import logging
import time
import base64
import pandas as pd
from datetime import datetime

# ... existing code ...

# New endpoints for fighter data
@app.route('/api/data/fighters', methods=['GET'])
def get_fighters():
    try:
        # Read the CSV file
        fighters_df = pd.read_csv('data/fighter_info.csv')
        
        # Convert to dictionary format
        fighters_data = fighters_df.to_dict('records')
        
        # Add timestamp for caching
        response = {
            'timestamp': datetime.now().isoformat(),
            'fighters': fighters_data
        }
        
        return jsonify(response)
    except Exception as e:
        logger.error(f"Error fetching fighter data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/events', methods=['GET'])
def get_events():
    try:
        # Read the CSV file
        events_df = pd.read_csv('data/event_data_sherdog.csv')
        
        # Convert to dictionary format
        events_data = events_df.to_dict('records')
        
        # Add timestamp for caching
        response = {
            'timestamp': datetime.now().isoformat(),
            'events': events_data
        }
        
        return jsonify(response)
    except Exception as e:
        logger.error(f"Error fetching event data: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/data/version', methods=['GET'])
def get_data_version():
    try:
        # Return the current version/timestamp of the data
        # This is used by the iOS app to check if it needs to update
        return jsonify({
            'fighter_data_version': os.path.getmtime('data/fighter_info.csv'),
            'event_data_version': os.path.getmtime('data/event_data_sherdog.csv'),
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Error fetching data version: {str(e)}")
        return jsonify({'error': str(e)}), 500

# ... rest of existing code ...
```
2. Now, let's create a new NetworkManager in the iOS app to handle API requests:

```swift:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/mma-ai-swift/NetworkManager.swift
import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = "http://localhost:5001/api"  // Update this with your server URL
    private let cache = UserDefaults.standard
    
    private init() {}
    
    // MARK: - Data Version Check
    
    func checkForUpdates() async throws -> Bool {
        let endpoint = "\(baseURL)/data/version"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let version = try JSONDecoder().decode(DataVersion.self, from: data)
        
        // Check if we need to update
        let lastFighterVersion = cache.double(forKey: "lastFighterVersion")
        let lastEventVersion = cache.double(forKey: "lastEventVersion")
        
        return version.fighter_data_version != lastFighterVersion ||
               version.event_data_version != lastEventVersion
    }
    
    // MARK: - Fetch Data
    
    func fetchFighters() async throws -> [APIFighter] {
        let endpoint = "\(baseURL)/data/fighters"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let fighterResponse = try JSONDecoder().decode(FighterResponse.self, from: data)
        
        // Update cache version
        if let version = try? await getDataVersion() {
            cache.set(version.fighter_data_version, forKey: "lastFighterVersion")
        }
        
        return fighterResponse.fighters
    }
    
    func fetchEvents() async throws -> [APIEvent] {
        let endpoint = "\(baseURL)/data/events"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        let eventResponse = try JSONDecoder().decode(EventResponse.self, from: data)
        
        // Update cache version
        if let version = try? await getDataVersion() {
            cache.set(version.event_data_version, forKey: "lastEventVersion")
        }
        
        return eventResponse.events
    }
    
    private func getDataVersion() async throws -> DataVersion {
        let endpoint = "\(baseURL)/data/version"
        
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        return try JSONDecoder().decode(DataVersion.self, from: data)
    }
}

// MARK: - Types

struct DataVersion: Codable {
    let fighter_data_version: Double
    let event_data_version: Double
    let timestamp: String
}

struct FighterResponse: Codable {
    let timestamp: String
    let fighters: [APIFighter]
}

struct EventResponse: Codable {
    let timestamp: String
    let events: [APIEvent]
}

struct APIFighter: Codable {
    let name: String
    let nickname: String?
    let record: String
    let weightClass: String
    let age: Int
    let height: String
    let team: String
    let nationality: String?
    let hometown: String?
    let birthDate: String
    let winsByKO: Int?
    let winsBySub: Int?
    let winsByDec: Int?
}

struct APIEvent: Codable {
    let name: String
    let date: String
    let location: String
    let fights: [APIFight]
}

struct APIFight: Codable {
    let redCorner: String
    let blueCorner: String
    let weightClass: String
    let isMainEvent: Bool
    let isTitleFight: Bool
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
    case serverError(String)
}
```
3. Now, let's update the FighterDataManager to use the NetworkManager:

```swift:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/mma-ai-swift/EventCard.swift
// ... existing code ...

class FighterDataManager {
    static let shared = FighterDataManager()
    
    @Published private(set) var fighters: [String: FighterStats] = [:]
    @Published private(set) var fightHistory: [String: [FightResult]] = [:]
    @Published private(set) var eventDetails: [String: EventInfo] = [:]
    @Published private(set) var loadingState: LoadingState = .idle
    
    private let queue = DispatchQueue(label: "com.mmaai.datamanager", qos: .userInitiated)
    private let cache = UserDefaults.standard
    private let networkManager = NetworkManager.shared
    
    init() {
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Public Methods
    
    func refreshData() async {
        await loadLatestData(force: true)
    }
    
    func getFighter(_ name: String) -> FighterStats? {
        fighters[name]
    }
    
    func getFightHistory(_ fighter: String) -> [FightResult]? {
        fightHistory[fighter]
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        // First try to load from cache
        if loadFromCache() {
            // Check for updates in background
            Task {
                await checkForUpdates()
            }
        } else {
            // If no cache, load from network
            await loadLatestData(force: true)
        }
    }
    
    private func loadLatestData(force: Bool) async {
        do {
            loadingState = .loading
            
            // Check if we need to update
            if !force {
                let needsUpdate = try await networkManager.checkForUpdates()
                if !needsUpdate {
                    loadingState = .success
                    return
                }
            }
            
            // Fetch new data
            async let fightersTask = networkManager.fetchFighters()
            async let eventsTask = networkManager.fetchEvents()
            
            let (fighters, events) = try await (fightersTask, eventsTask)
            
            // Process and store the data
            processNewData(fighters: fighters, events: events)
            
            // Save to cache
            saveToCache()
            
            loadingState = .success
            
        } catch {
            loadingState = .error(error)
            print("Error loading data: \(error)")
        }
    }
    
    private func processNewData(fighters: [APIFighter], events: [APIEvent]) {
        // Process fighters
        var newFighters: [String: FighterStats] = [:]
        var newFightHistory: [String: [FightResult]] = [:]
        var newEventDetails: [String: EventInfo] = [:]
        
        // Process fighters
        for fighter in fighters {
            newFighters[fighter.name] = FighterStats(
                name: fighter.name,
                nickname: fighter.nickname,
                record: fighter.record,
                weightClass: fighter.weightClass,
                age: fighter.age,
                height: fighter.height,
                teamAffiliation: fighter.team,
                nationality: fighter.nationality,
                hometown: fighter.hometown,
                birthDate: fighter.birthDate,
                winsByKO: fighter.winsByKO,
                winsBySubmission: fighter.winsBySub,
                winsByDecision: fighter.winsByDec
            )
        }
        
        // Process events
        for event in events {
            let fights = event.fights.map { fight in
                Fight(
                    redCorner: fight.redCorner,
                    blueCorner: fight.blueCorner,
                    weightClass: fight.weightClass,
                    isMainEvent: fight.isMainEvent,
                    isTitleFight: fight.isTitleFight,
                    round: "TBD",
                    time: "TBD"
                )
            }
            
            newEventDetails[event.name] = EventInfo(
                name: event.name,
                date: event.date,
                location: event.location,
                venue: "TBD",
                fights: fights
            )
        }
        
        // Update state
        self.fighters = newFighters
        self.fightHistory = newFightHistory
        self.eventDetails = newEventDetails
        
        // Notify observers
        NotificationCenter.default.post(name: .fighterDataDidUpdate, object: nil)
    }
    
    private func saveToCache() {
        let data = CacheData(
            fighters: fighters,
            fightHistory: fightHistory,
            eventDetails: eventDetails
        )
        
        if let encoded = try? JSONEncoder().encode(data) {
            cache.set(encoded, forKey: "fighterDataCache")
        }
    }
    
    private func loadFromCache() -> Bool {
        guard let data = cache.data(forKey: "fighterDataCache"),
              let cacheData = try? JSONDecoder().decode(CacheData.self, from: data) else {
            return false
        }
        
        self.fighters = cacheData.fighters
        self.fightHistory = cacheData.fightHistory
        self.eventDetails = cacheData.eventDetails
        
        return true
    }
    
    private func checkForUpdates() async {
        do {
            let needsUpdate = try await networkManager.checkForUpdates()
            if needsUpdate {
                await loadLatestData(force: true)
            }
        } catch {
            print("Error checking for updates: \(error)")
        }
    }
}

// MARK: - Types

struct CacheData: Codable {
    let fighters: [String: FighterStats]
    let fightHistory: [String: [FightResult]]
    let eventDetails: [String: EventInfo]
}

// ... existing code ...
```
4. Finally, let's update the Info.plist to allow network access:

```plain text:/Users/td/Code/mma-ai-swift-app/mma-ai-swift/Info.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing entries -->
    
    <!-- Network permissions -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
        <key>NSExceptionDomains</key>
        <dict>
            <key>localhost</key>
            <dict>
                <key>NSIncludesSubdomains</key>
                <true/>
                <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
                <true/>
            </dict>
        </dict>
    </dict>
    
    <!-- Background refresh -->
    <key>UIBackgroundModes</key>
    <array>
        <string>fetch</string>
    </array>
</dict>
</plist>
```
Now your app is set up to:

1. **Load Data Efficiently:**
   - First load from cache (instant)
   - Check for updates in background
   - Download new data if available
   - Save to cache for offline use

2. **Handle Updates:**
   - Automatic background updates
   - Manual refresh option
   - Version checking to minimize downloads
   - Smart caching system

3. **Provide Good UX:**
   - Loading states
   - Error handling
   - Offline support
   - Smooth data transitions

To use this system:

1. **Start your Flask server:**
```bash
python app.py
```

2. **Update the NetworkManager baseURL:**
- For development: `"http://localhost:5001/api"`
- For production: Your actual server URL

3. **Test the system:**
- Run the app
- Check initial load from cache
- Test manual refresh
- Test offline mode
- Monitor network requests

4. **Update your data:**
- Simply update the CSV files on your server
- The app will automatically fetch updates
- No app updates needed

This setup gives you:
- Real-time data updates
- Efficient network usage
- Good offline experience
- Easy server-side updates
- Clean architecture

Would you like me to help you test this setup or explain any part in more detail?

## File Cache
The app now saves fighter and event data to JSON files in the Application Support directory using `FileCache.swift`. This reduces launch time when the network is slow.

The previous four hour refresh window has been removed. The app now checks the
server's data version and only downloads new files when the version changes.
