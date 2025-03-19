import SwiftUI

struct Conversation: Identifiable, Codable {
    var id: String
    var title: String
    var previewText: String
    var timestamp: Date
    var messages: [Message]?
}

class ConversationHistoryManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    private let storageKey = "savedConversations"
    
    init() {
        loadConversations()
    }
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decodedConversations = try? JSONDecoder().decode([Conversation].self, from: data) {
            conversations = decodedConversations
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addConversation(title: String, previewText: String, id: String, messages: [Message]? = nil) {
        // Check if conversation with this ID already exists
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            // Update existing conversation
            conversations[index].title = title
            conversations[index].previewText = previewText
            conversations[index].timestamp = Date()
            conversations[index].messages = messages
        } else {
            // Add new conversation
            let newConversation = Conversation(
                id: id,
                title: title,
                previewText: previewText,
                timestamp: Date(),
                messages: messages
            )
            conversations.insert(newConversation, at: 0)
        }

        // Sort by most recent
        conversations.sort { $0.timestamp > $1.timestamp }
        
        // Save to storage
        saveConversations()
    }
    
    func deleteConversation(at indexSet: IndexSet) {
        conversations.remove(atOffsets: indexSet)
        saveConversations()
    }
}

struct ConversationHistoryView: View {
    @ObservedObject var historyManager: ConversationHistoryManager
    @ObservedObject var chatViewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                if historyManager.conversations.isEmpty {
                    Text("No conversation history yet")
                        .foregroundColor(AppTheme.textSecondary)
                        .padding()
                } else {
                    ForEach(historyManager.conversations) { conversation in
                        Button(action: {
                            chatViewModel.loadConversation(id: conversation.id)
                            chatViewModel.isFirstLaunch = false
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(conversation.title)
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text(conversation.previewText)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textSecondary)
                                    .lineLimit(1)
                                
                                Text(formatDate(conversation.timestamp))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textMuted)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: historyManager.deleteConversation)
                }
            }
            .navigationTitle("Conversation History")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .listStyle(InsetGroupedListStyle())
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SaveConversationView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var historyManager: ConversationHistoryManager
    @Environment(\.presentationMode) var presentationMode
    @State private var title = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Save Conversation")
                    .font(.headline)
                
                TextField("Conversation Title", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                Button("Save") {
                    // Get first user message for the preview if available
                    let previewText = chatViewModel.messages.first(where: { $0.isUser })?.content ?? "Conversation"
                    
                    // Generate a unique ID if none exists
                    let id = chatViewModel.conversationId ?? UUID().uuidString
                    
                    // Save to history
                    historyManager.addConversation(
                        title: title.isEmpty ? String(previewText.prefix(30)) : title,
                        previewText: previewText,
                        id: id,
                        messages: chatViewModel.messages
                    )
                    
                    // Update the current conversation ID
                    chatViewModel.conversationId = id
                    
                    presentationMode.wrappedValue.dismiss()
                }
                .padding()
                .frame(width: 200)
                .background(AppTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(chatViewModel.messages.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

#Preview {
    ConversationHistoryView(
        historyManager: ConversationHistoryManager(),
        chatViewModel: ChatViewModel()
    )
}
