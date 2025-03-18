import Foundation
import Combine

// Custom URLSession delegate to handle SSL certificate validation
class SSLCertificateHandler: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        // Accept all certificates
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

struct Message: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isFirstLaunch = true
    @Published var exampleQuestions: [String] = []
    @Published var conversationId: String?
    
    private var apiUrl = "https://mma-ai.duckdns.org/api"
    
    init() {
        // Initialize with default example questions
        exampleQuestions = [
            "Where is the upcoming UFC card/event this weekend and what are all of the fights on it with a short overview of each fight?",
            "Tell me about Max Holloway's most recent 5 fights chronologically",
            "Compare Paddy Pimblett and Michael Chandler's fighting styles and predict who would win in a fight.",
            "What is the current weather forecast for Miami, Florida?"
        ]
        // Load from API if available
        loadExampleQuestions()
    }
    
    func updateApiEndpoint(_ endpoint: String) {
        apiUrl = endpoint
        print("API endpoint updated to: \(apiUrl)")
    }
    
    func loadConversation(id: String) {
        isLoading = true
        conversationId = id
        
        let url = URL(string: "\(apiUrl)/conversation/\(id)")!
        print("Loading conversation from: \(url.absoluteString)")
        
        let sessionConfig = URLSessionConfiguration.default
        let sslHandler = SSLCertificateHandler()
        let session = URLSession(configuration: sessionConfig, delegate: sslHandler, delegateQueue: nil)
        
        session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    print("Error loading conversation: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Print the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Conversation API Response: \(responseString)")
                }
                
                do {
                    let decodedResponse = try JSONDecoder().decode(ConversationResponse.self, from: data)
                    self?.messages = decodedResponse.messages.map { msg in
                        Message(
                            content: msg.content,
                            isUser: msg.role == "user",
                            timestamp: ISO8601DateFormatter().date(from: msg.timestamp) ?? Date()
                        )
                    }
                    self?.isFirstLaunch = false
                } catch {
                    print("Error decoding conversation: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func loadExampleQuestions() {
        // Don't reload if we're already loading
        if isLoading { return }
        
        print("Loading example questions from API at \(apiUrl)/examples...")
        isLoading = true
        
        let url = URL(string: "\(apiUrl)/examples")!
        print("URL: \(url.absoluteString)")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 300  // 5 minutes
        sessionConfig.timeoutIntervalForResource = 600 // 10 minutes
        let sslHandler = SSLCertificateHandler()
        let session = URLSession(configuration: sessionConfig, delegate: sslHandler, delegateQueue: nil)
        
        session.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                }
                
                guard let data = data, error == nil else {
                    print("Error loading example questions: \(error?.localizedDescription ?? "Unknown error")")
                    print("Using default example questions (count: \(self?.exampleQuestions.count ?? 0))")
                    return
                }
                
                // Print the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Examples API Response: \(responseString)")
                }
                
                if let decodedResponse = try? JSONDecoder().decode(ExamplesResponse.self, from: data),
                   !decodedResponse.examples.isEmpty {
                    print("Successfully loaded \(decodedResponse.examples.count) example questions from API")
                    self?.exampleQuestions = decodedResponse.examples
                } else {
                    print("Failed to decode API response or empty examples array")
                    print("Keeping default example questions (count: \(self?.exampleQuestions.count ?? 0))")
                }
            }
        }.resume()
    }
    
    func sendMessage(_ content: String) {
        // Create and add the user message
        let userMessage = Message(content: content, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        isLoading = true
        
        // Create a placeholder for the assistant's response
        let loadingMessage = Message(content: "Working...", isUser: false, timestamp: Date())
        messages.append(loadingMessage)
        let loadingIndex = messages.count - 1
        
        // Prepare the request
        let url = URL(string: "\(apiUrl)/chat")!
        print("Sending request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "message": content,
            "conversation_id": conversationId as Any
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            print("Request body: \(requestBody)")
            
            // Create a URLSession configuration that allows self-signed certificates
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 180
            let sslHandler = SSLCertificateHandler()
            let session = URLSession(configuration: sessionConfig, delegate: sslHandler, delegateQueue: nil)
            
            session.dataTask(with: request) { [weak self] data, response, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    // Remove only the loading message
                    if let self = self, self.messages.count > loadingIndex {
                        self.messages.remove(at: loadingIndex)
                    }
                    
                    if let error = error {
                        print("Network error: \(error.localizedDescription)")
                        let errorMessage = Message(
                            content: "Network error: \(error.localizedDescription)",
                            isUser: false,
                            timestamp: Date()
                        )
                        self?.messages.append(errorMessage)
                        return
                    }
                    
                    if let httpResponse = response as? HTTPURLResponse {
                        print("HTTP Status Code: \(httpResponse.statusCode)")
                        print("HTTP Headers: \(httpResponse.allHeaderFields)")
                    }
                    
                    guard let data = data else {
                        let errorMessage = Message(
                            content: "No data received from server",
                            isUser: false,
                            timestamp: Date()
                        )
                        self?.messages.append(errorMessage)
                        return
                    }
                    
                    // Print the raw response for debugging
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("API Response: \(responseString)")
                    }
                    
                    do {
                        let decodedResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                        
                        if let errorMsg = decodedResponse.error {
                            print("Server error: \(errorMsg)")
                            let errorMessage = Message(
                                content: "Server error: \(errorMsg)",
                                isUser: false,
                                timestamp: Date()
                            )
                            self?.messages.append(errorMessage)
                            return
                        }
                        
                        let responseContent = decodedResponse.response ?? ""
                        print("Response content: '\(responseContent)'")
                        
                        if responseContent.isEmpty {
                            print("Empty response received from server")
                            let errorMessage = Message(
                                content: "The server returned an empty response. This might be due to an issue with the OpenAI API key or rate limiting.",
                                isUser: false,
                                timestamp: Date()
                            )
                            self?.messages.append(errorMessage)
                        } else {
                            let assistantMessage = Message(
                                content: responseContent,
                                isUser: false,
                                timestamp: Date()
                            )
                            self?.messages.append(assistantMessage)
                        }
                        
                        if let newConversationId = decodedResponse.conversation_id {
                            self?.conversationId = newConversationId
                        }
                    } catch {
                        print("Decoding error: \(error.localizedDescription)")
                        let errorMessage = Message(
                            content: "Error parsing response: \(error.localizedDescription)",
                            isUser: false,
                            timestamp: Date()
                        )
                        self?.messages.append(errorMessage)
                    }
                }
            }.resume()
        } catch {
            DispatchQueue.main.async {
                self.isLoading = false
                
                // Remove only the loading message
                if self.messages.count > loadingIndex {
                    self.messages.remove(at: loadingIndex)
                }
                
                let errorMessage = Message(
                    content: "Error preparing request: \(error.localizedDescription)",
                    isUser: false,
                    timestamp: Date()
                )
                self.messages.append(errorMessage)
            }
        }
    }
}

struct ChatResponse: Codable {
    let response: String?
    let conversation_id: String?
    let error: String?
}

struct ExamplesResponse: Codable {
    let examples: [String]
}

struct ConversationResponse: Codable {
    let conversation_id: String
    let messages: [ConversationMessage]
}

struct ConversationMessage: Codable {
    let role: String
    let content: String
    let timestamp: String
} 