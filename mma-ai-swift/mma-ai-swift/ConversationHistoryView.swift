import SwiftUI

struct ConversationSummary: Identifiable, Codable {
    let id: String
    let title: String
    let date: Date
    let previewText: String
}

class ConversationHistoryManager: ObservableObject {
    @Published var conversations: [ConversationSummary] = []
    private let storageKey = "savedConversations"
    
    init() {
        loadConversations()
    }
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decodedConversations = try? JSONDecoder().decode([ConversationSummary].self, from: data) {
            conversations = decodedConversations
        }
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    func addConversation(title: String, previewText: String, id: String) {
        let newConversation = ConversationSummary(
            id: id,
            title: title,
            date: Date(),
            previewText: previewText
        )
        conversations.insert(newConversation, at: 0)
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
                                
                                Text(formatDate(conversation.date))
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

#Preview {
    ConversationHistoryView(
        historyManager: ConversationHistoryManager(),
        chatViewModel: ChatViewModel()
    )
} 