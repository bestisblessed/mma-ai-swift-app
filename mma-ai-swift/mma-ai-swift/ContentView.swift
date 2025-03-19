import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var historyManager = ConversationHistoryManager()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Chat Tab
            NavigationView {
                VStack {
                    if chatViewModel.isFirstLaunch {
                        WelcomeView(chatViewModel: chatViewModel)
                    } else {
                        ChatView(chatViewModel: chatViewModel, settingsManager: settingsManager)
                    }
                }
                .navigationTitle(chatViewModel.isFirstLaunch ? "" : "MMA AI")
                .navigationBarItems(
                    leading: Button(action: {
                        showHistory = true
                    }) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                    },
                    trailing: Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                    }
                )
                .sheet(isPresented: $showSettings) {
                    SettingsView(settingsManager: settingsManager)
                }
                .sheet(isPresented: $showHistory) {
                    ConversationHistoryView(
                        historyManager: historyManager,
                        chatViewModel: chatViewModel
                    )
                }
                .onAppear {
                    // Update ChatViewModel with settings
                    chatViewModel.updateApiEndpoint(settingsManager.apiEndpoint)
                }
                .onChange(of: settingsManager.apiEndpoint) { _, newValue in
                    chatViewModel.updateApiEndpoint(newValue)
                }
                .onChange(of: chatViewModel.conversationId) { _, newId in
                    if let id = newId, let firstMessage = chatViewModel.messages.first(where: { $0.isUser }) {
                        historyManager.addConversation(
                            title: firstMessage.content.prefix(30).appending(firstMessage.content.count > 30 ? "..." : "").description,
                            previewText: firstMessage.content,
                            id: id
                        )
                    }
                }
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(0)
            
            // Dashboard Tab
            NavigationView {
                DashboardView()
                    .navigationTitle("Dashboard")
                    .navigationBarItems(trailing: Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gear")
                            .font(.system(size: 20))
                    })
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar")
            }
            .tag(1)
        }
        .accentColor(AppTheme.accent)
    }
}

struct WelcomeView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Logo/Header
                Image(systemName: "figure.boxing")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.accent)
                    .padding(.top, 10)
                
                Text("Welcome to\nMMA AI")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Ask questions about fighters, events, and statistics")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 5)
                
                Text("Example Questions:")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .padding(.top, 10)
                    .padding(.bottom, 5)
                
                // Generate buttons for example questions
                ForEach(0..<chatViewModel.exampleQuestions.count, id: \.self) { index in
                    Button(action: {
                        chatViewModel.sendMessage(chatViewModel.exampleQuestions[index])
                        chatViewModel.isFirstLaunch = false
                    }) {
                        Text(chatViewModel.exampleQuestions[index])
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.cardBackground)
                            .foregroundColor(AppTheme.textPrimary)
                            .cornerRadius(10)
                    }
                    .padding(.vertical, 2)
                }
                
                Button("Start Chatting") {
                    chatViewModel.isFirstLaunch = false
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .onAppear {
            print("WelcomeView appeared with \(chatViewModel.exampleQuestions.count) example questions")
            for (index, question) in chatViewModel.exampleQuestions.enumerated() {
                print("Question \(index + 1): \(question)")
            }
            chatViewModel.loadExampleQuestions()
        }
    }
}

struct ChatView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    @ObservedObject var settingsManager: SettingsManager
    @State private var newMessage = ""
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var showingAlert = false
    @State private var showingExportSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat area
            ScrollView {
                ScrollViewReader { proxy in
                    LazyVStack(spacing: 8) {
                        ForEach(chatViewModel.messages) { message in
                            VStack(alignment: .leading) {
                                if message.imageData != nil {
                                    Image(uiImage: UIImage(data: message.imageData!) ?? UIImage())
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 300)
                                        .cornerRadius(10)
                                } else {
                                    Text(message.content)
                                        .padding(10)
                                        .background(message.isUser ? AppTheme.accent : AppTheme.cardBackground)
                                        .foregroundColor(message.isUser ? .white : AppTheme.textPrimary)
                                        .cornerRadius(15)
                                }
                                Text(message.formattedTime)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .onChange(of: chatViewModel.messages.count) { oldCount, newCount in
                        if let lastMessage = chatViewModel.messages.last {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                    .background(AppTheme.accent.opacity(0.3))
                
                HStack {
                    // Text input field
                    TextField("Type a message...", text: $newMessage)
                        .textFieldStyle(AppTextFieldStyle())
                        .disabled(chatViewModel.isLoading)
                    
                    // Send button
                    Button(action: {
                        if !newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            let messageToSend = newMessage
                            newMessage = ""
                            
                            // Use slight delay to ensure text field is cleared before sending
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                chatViewModel.sendMessage(messageToSend)
                            }
                        }
                    }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.accent)
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatViewModel.isLoading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(AppTheme.cardBackground)
            .overlay(
                Divider().background(AppTheme.accent.opacity(0.3)),
                alignment: .top
            )
        }
        .navigationTitle("MMA AI")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    showingAlert = true
                }) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(AppTheme.accent)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingExportSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Start New Chat"),
                message: Text("Are you sure you want to start a new conversation? This will clear the current chat."),
                primaryButton: .default(Text("Yes")) {
                    chatViewModel.startNewChat()
                },
                secondaryButton: .cancel()
            )
        }
        .sheet(isPresented: $showingExportSheet) {
            let export = chatViewModel.exportConversation()
            ExportView(text: export.text, images: export.images)
        }
    }
}

struct MessageBubble: View {
    let message: Message
    @State private var isAnimated = false
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
            } else {
                // Bot avatar
                Image(systemName: "figure.boxing")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.cardBackground)
                    .clipShape(Circle())
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .opacity(isAnimated ? 1.0 : 0.0)
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                if message.content == "Thinking..." && !message.isUser {
                    ThinkingView()
                        .opacity(isAnimated ? 1.0 : 0.0)
                } else {
                    Text(message.content)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(message.isUser ? AppTheme.userBubble : AppTheme.botBubble)
                        .foregroundColor(message.isUser ? AppTheme.userBubbleText : AppTheme.botBubbleText)
                        .cornerRadius(18)
                        .offset(x: isAnimated ? 0 : (message.isUser ? 50 : -50))
                        .opacity(isAnimated ? 1.0 : 0.0)
                }
                
                Text(message.formattedTime)
                    .font(.caption2)
                    .foregroundColor(AppTheme.textMuted)
                    .padding(.horizontal, 4)
                    .opacity(isAnimated ? 0.8 : 0.0)
            }
            
            if !message.isUser {
                Spacer()
            } else {
                // User avatar
                Image(systemName: "person.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .scaleEffect(isAnimated ? 1.0 : 0.8)
                    .opacity(isAnimated ? 1.0 : 0.0)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}

/* Removed duplicate Message struct declaration */ 
