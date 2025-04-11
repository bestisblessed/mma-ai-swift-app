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

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isFirstLaunch = true
    @Published var exampleQuestions: [String] = []
    @Published var threadId: String?
    
    // Store saved conversation when going to welcome screen
    private var savedMessages: [Message] = []
    private var savedThreadId: String?
    
    private var apiUrl = "https://mma-ai.duckdns.org/api"
    
    init() {
        // Initialize with default example questions
        exampleQuestions = [
            "Tell me about Max Holloway's most recent 5 fights chronologically",
            "Generate me a visualization of Max Holloway's method of victories"
        ]
        // Load from API if available
        loadExampleQuestions()
    }
    
    func updateApiEndpoint(_ endpoint: String) {
        apiUrl = endpoint
        print("API endpoint updated to: \(apiUrl)")
    }
    
    func loadConversation(threadId: String) {
        print("Loading conversation with thread ID: \(threadId)")
        
        isLoading = true
        self.threadId = threadId
        
        let url = URL(string: "\(apiUrl)/chat/history")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["conversation_id": threadId]
        request.httpBody = try? JSONEncoder().encode(body)
        
        let sessionConfig = URLSessionConfiguration.default
        let sslHandler = SSLCertificateHandler()
        let session = URLSession(configuration: sessionConfig, delegate: sslHandler, delegateQueue: nil)
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Error loading conversation: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    print("No data received")
                    return
                }
                
                // Print the raw response for debugging
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Conversation API Response: \(responseString)")
                }
                
                do {
                    let response = try JSONDecoder().decode(ChatHistoryResponse.self, from: data)
                    var loadedMessages: [Message] = []
                    
                    // Convert all messages in the conversation
                    for msg in response.messages {
                        var content = ""
                        var imageData: Data? = nil
                        
                        // Handle different content types
                        for contentItem in msg.content {
                            switch contentItem.type {
                            case "text":
                                content = contentItem.content
                            case "image":
                                if let base64String = contentItem.content.components(separatedBy: ",").last,
                                   let data = Data(base64Encoded: base64String) {
                                    imageData = data
                                }
                            default:
                                break
                            }
                        }
                        
                        // Skip empty messages
                        if content.isEmpty && imageData == nil {
                            continue
                        }
                        
                        // Create message object
                        let message = Message(
                            content: content,
                            isUser: msg.role == "user",
                            timestamp: Date(),
                            imageData: imageData
                        )
                        
                        // Add to our collection
                        loadedMessages.append(message)
                    }
                    
                    // Update the messages array - the backend already returns in chronological order now
                    self?.messages = loadedMessages
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
    
    func sendMessage(_ content: String, assistantId: String? = nil) {
        // Create and add the user message
        let userMessage = Message(content: content, isUser: true, timestamp: Date())
        messages.append(userMessage)
        
        isLoading = true
        
        // Create a placeholder for the assistant's response that shows it's loading
        let loadingMessage = Message(content: "", isUser: false, timestamp: Date(), isLoading: true)
        messages.append(loadingMessage)
        let loadingIndex = messages.count - 1
        
        // Prepare the request
        let url = URL(string: "\(apiUrl)/chat")!
        print("Sending request to: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var requestBody: [String: Any] = [
            "message": content,
            "conversation_id": threadId as Any
        ]
        
        // Add custom assistant ID if provided (for fight predictions)
        if let assistantId = assistantId {
            requestBody["assistant_id"] = assistantId
            print("Using custom assistant ID: \(assistantId)")
        } else {
            // Use default chat assistant ID
            requestBody["assistant_id"] = "asst_QIEMCdBCqsX4al7O4Jg2Jjpx"
            print("Using default chat assistant ID: asst_QIEMCdBCqsX4al7O4Jg2Jjpx")
        }
        
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
                        
                        let responseItems = decodedResponse.response
                        for item in responseItems {
                            var messageContent = item.content
                            if let annotations = item.annotations, !annotations.isEmpty {
                                messageContent += "\n\nReferences:\n" + annotations.map { $0.text }.joined(separator: "\n")
                            }
                            
                            let newMessage = Message(
                                content: messageContent,
                                isUser: false,
                                timestamp: Date(),
                                imageData: item.type == "image" ? self?.extractImageData(from: item.content) : nil
                            )
                            self?.messages.append(newMessage)
                        }
                        
                        self?.threadId = decodedResponse.conversation_id
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
    
    func startNewChat() {
        self.messages = []
        self.threadId = nil
        self.isFirstLaunch = false
        
        // Clear saved conversation
        self.savedMessages = []
        self.savedThreadId = nil
        
        print("Started new chat")
    }
    
    func goToWelcomeScreen() {
        // Save the current conversation
        if !messages.isEmpty {
            self.savedMessages = self.messages
            self.savedThreadId = self.threadId
        }
        
        // Clear the current view but don't delete the conversation
        self.messages = []
        self.threadId = nil
        self.isFirstLaunch = true
        
        print("Returned to welcome screen (conversation saved)")
        loadExampleQuestions() // Refresh example questions
    }
    
    // New function to restore conversation when coming back from welcome screen
    func restoreConversation() -> Bool {
        if !savedMessages.isEmpty {
            self.messages = self.savedMessages
            if let threadId = self.savedThreadId {
                self.threadId = threadId
                print("Restored conversation with \(savedMessages.count) messages, thread ID: \(threadId)")
            }
            return true
        } else {
            print("No saved conversation to restore")
            return false
        }
    }
    
    func exportConversation() -> (text: String, images: [Data]) {
        var exportText = "MMA AI Conversation Export\n"
        exportText += "Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .medium))\n\n"
        
        var images: [Data] = []
        
        for message in messages {
            let sender = message.isUser ? "You" : "MMA AI"
            exportText += "[\(sender)]: \(message.content)\n\n"
            
            if let imageData = message.imageData {
                images.append(imageData)
            }
        }
        
        return (text: exportText, images: images)
    }
    
    private func extractImageData(from dataUrl: String) -> Data? {
        // Check if it's a data URL format
        guard dataUrl.hasPrefix("data:image/") else {
            print("Not a valid data URL: \(dataUrl.prefix(30))...")
            return nil
        }
        
        // Extract the base64 part after the comma
        guard let commaIndex = dataUrl.firstIndex(of: ",") else {
            print("No comma found in data URL")
            return nil
        }
        
        let base64String = String(dataUrl[dataUrl.index(after: commaIndex)...])
        print("Extracted base64 string of length: \(base64String.count)")
        return Data(base64Encoded: base64String)
    }
}

struct ChatResponse: Decodable {
    let response: [ResponseItem]
    let conversation_id: String
    let error: String?
}

struct ResponseItem: Decodable {
    let type: String
    let content: String
    let format: String?  // For images
    let annotations: [Annotation]?
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

struct Annotation: Decodable {
    let type: String
    let text: String
    let file_id: String
}

// Response types for chat history
struct ChatHistoryResponse: Codable {
    let messages: [ChatMessage]
    let conversation_id: String
}

struct ChatMessage: Codable {
    let role: String
    let content: [ContentItem]
}

struct ContentItem: Codable {
    let type: String
    let content: String
}
