import SwiftUI

struct ConversationSummary: Identifiable {
    let id: String
    let title: String
    let date: Date
    let previewText: String
}

class ConversationHistoryManager: ObservableObject {
    @Published var conversations: [ConversationSummary] = []
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        // In a real app, this would load from UserDefaults or a database
        conversations = [
            ConversationSummary(
                id: "1",
                title: "UFC 300 Discussion",
                date: Date().addingTimeInterval(-86400), // Yesterday
                previewText: "Tell me about UFC 300"
            ),
            ConversationSummary(
                id: "2",
                title: "Max Holloway Stats",
                date: Date().addingTimeInterval(-172800), // 2 days ago
                previewText: "What are Max Holloway's recent stats?"
            ),
            ConversationSummary(
                id: "3",
                title: "Upcoming Events",
                date: Date().addingTimeInterval(-259200), // 3 days ago
                previewText: "What UFC events are coming up?"
            )
        ]
    }
    
    func addConversation(title: String, previewText: String, id: String) {
        let newConversation = ConversationSummary(
            id: id,
            title: title,
            date: Date(),
            previewText: previewText
        )
        conversations.insert(newConversation, at: 0)
    }
    
    func deleteConversation(at indexSet: IndexSet) {
        conversations.remove(atOffsets: indexSet)
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