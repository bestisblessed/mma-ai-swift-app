import Foundation
import UIKit
import Combine
import OpenAI

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

    private let openAI: OpenAI
    
    // Track current network tasks to allow cancellation
    private var currentChatTask: URLSessionDataTask?
    private var currentPredictionTask: URLSessionDataTask?

    init() {
        let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        self.openAI = OpenAI(apiToken: apiKey)
        // Register for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppStateChange),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Load example questions from API
        loadExampleQuestions()
    }
    
    @objc private func handleAppStateChange() {
        // Cancel ongoing tasks when app goes to background
        currentChatTask?.cancel()
        currentPredictionTask?.cancel()
        
        // Reset loading state
        DispatchQueue.main.async {
            self.isLoading = false
        }
    }
    
    deinit {
        // Remove observer to prevent memory leaks
        NotificationCenter.default.removeObserver(self)
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
        guard !isLoading, let url = URL(string: "\(apiUrl)/examples") else { return }
        isLoading = true
        let sessionConfig = URLSessionConfiguration.default
        let sslHandler = SSLCertificateHandler()
        let session = URLSession(configuration: sessionConfig, delegate: sslHandler, delegateQueue: nil)
        session.dataTask(with: url) { [weak self] data, _, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data, error == nil,
                      let decoded = try? JSONDecoder().decode(ExamplesResponse.self, from: data) else {
                    return
                }
                self?.exampleQuestions = decoded.examples
            }
        }.resume()
    }

    func sendMessage(_ content: String, assistantId: String? = nil) {
        currentChatTask?.cancel()

        let userMessage = Message(content: content, isUser: true, timestamp: Date())
        messages.append(userMessage)

        isLoading = true

        let loadingMessage = Message(content: "", isUser: false, timestamp: Date(), isLoading: true)
        messages.append(loadingMessage)
        let loadingIndex = messages.count - 1

        var chatMessages: [ChatQuery.ChatCompletionMessageParam] = messages.compactMap {
            guard !$0.isLoading else { return nil }
            let role: ChatQuery.ChatCompletionMessageParam.Role = $0.isUser ? .user : .assistant
            return .init(role: role, content: .string($0.content))
        }
        chatMessages.append(.user(.init(content: .string(content))))

        let query = ChatQuery(messages: chatMessages, model: .gpt4_o)

        Task { [weak self] in
            var accumulated = ""
            do {
                for try await result in openAI.chatsStream(query: query) {
                    if let delta = result.choices.first?.delta.content?.string {
                        accumulated += delta
                        await MainActor.run {
                            if let self = self, self.messages.indices.contains(loadingIndex) {
                                self.messages[loadingIndex].content = accumulated
                            }
                        }
                    }
                }
                await MainActor.run {
                    if let self = self, self.messages.indices.contains(loadingIndex) {
                        self.messages[loadingIndex].isLoading = false
                    }
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self?.isLoading = false
                    if let self = self, self.messages.indices.contains(loadingIndex) {
                        self.messages.remove(at: loadingIndex)
                    }
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isUser: false, timestamp: Date())
                    self?.messages.append(errorMessage)
                }
            }
        }
    }
    
    // Function for fight predictions that doesn't show the fighter ID input in the chat
    func sendPredictionRequest(prompt: String, assistantId: String) {
        currentPredictionTask?.cancel()

        isLoading = true

        let loadingMessage = Message(content: "Generating prediction...", isUser: false, timestamp: Date(), isLoading: true)
        messages.append(loadingMessage)
        let loadingIndex = messages.count - 1

        let systemMsg = ChatQuery.ChatCompletionMessageParam(role: .system, content: .string("You are an MMA fight prediction assistant."))
        let userMsg = ChatQuery.ChatCompletionMessageParam(role: .user, content: .string(prompt))
        let query = ChatQuery(messages: [systemMsg, userMsg], model: .gpt4_o)

        Task { [weak self] in
            var accumulated = ""
            do {
                for try await result in openAI.chatsStream(query: query) {
                    if let delta = result.choices.first?.delta.content?.string {
                        accumulated += delta
                        await MainActor.run {
                            if let self = self, self.messages.indices.contains(loadingIndex) {
                                self.messages[loadingIndex].content = accumulated
                            }
                        }
                    }
                }
                await MainActor.run {
                    if let self = self, self.messages.indices.contains(loadingIndex) {
                        self.messages[loadingIndex].isLoading = false
                    }
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self?.isLoading = false
                    if let self = self, self.messages.indices.contains(loadingIndex) {
                        self.messages.remove(at: loadingIndex)
                    }
                    let errorMessage = Message(content: "Error: \(error.localizedDescription)", isUser: false, timestamp: Date())
                    self?.messages.append(errorMessage)
                }
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
