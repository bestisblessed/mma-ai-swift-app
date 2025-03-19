import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var historyManager = ConversationHistoryManager()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab (now first)
            NavigationView {
                DashboardView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Dashboard")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 17))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar")
            }
            .tag(0)
            
            // Chat Tab (in the middle)
            NavigationView {
                VStack {
                    if chatViewModel.isFirstLaunch {
                        WelcomeView(chatViewModel: chatViewModel)
                    } else {
                        ChatView(chatViewModel: chatViewModel, settingsManager: settingsManager)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(chatViewModel.isFirstLaunch ? "" : "MMA AI")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 17))
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        // Show different buttons based on whether we're in chat or welcome screen
                        Group {
                            if chatViewModel.isFirstLaunch {
                                // Settings button when on welcome screen
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 17))
                                }
                            } else {
                                // Only home button when in chat mode, no settings
                                Button(action: {
                                    chatViewModel.goToWelcomeScreen()
                                }) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 17))
                                }
                            }
                        }
                    }
                }
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
                if chatViewModel.isFirstLaunch {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right")
                } else {
                    Label("Home", systemImage: "house.fill")
                }
            }
            .tag(1)
            
            // Fighters Tab (remains third)
            NavigationView {
                FighterDashboardView()
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .principal) {
                            Text("Database")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 17))
                            }
                        }
                    }
            }
            .tabItem {
                Label("Database", systemImage: "figure.boxing")
            }
            .tag(2)
        }
        .accentColor(AppTheme.accent)
        .font(.system(size: 14, weight: .medium))
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
                
                Text("Ask a question about fights, fighters, predictions, trends, or anything..")
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
                        // Check if there's a saved conversation
                        if chatViewModel.restoreConversation() {
                            // If there's a saved conversation, just send the message
                            chatViewModel.sendMessage(chatViewModel.exampleQuestions[index])
                        } else {
                            // Otherwise create a new conversation with this question
                            chatViewModel.sendMessage(chatViewModel.exampleQuestions[index])
                        }
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
                    // Check if there's a saved conversation to restore
                    chatViewModel.restoreConversation()
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
                            MessageBubble(message: message)
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
            
            // Action buttons row (NEW)
            HStack(spacing: 16) {
                Spacer()
                
                Button(action: {
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("New Chat")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.cardBackground)
                    .foregroundColor(AppTheme.accent)
                    .cornerRadius(18)
                }
                
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(AppTheme.cardBackground)
                    .foregroundColor(AppTheme.accent)
                    .cornerRadius(18)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .background(AppTheme.cardBackground)
            
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
        .navigationTitle("MMA AI Chatbot")
        .sheet(isPresented: $showingExportSheet) {
            let export = chatViewModel.exportConversation()
            ExportView(text: export.text, images: export.images)
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
                if message.isLoading {
                    // Display a loading spinner in a bubble
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
                        
                        Text("Thinking...")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.botBubbleText)
                            .padding(.leading, 8)
                    }
                    .padding(16)
                    .background(AppTheme.botBubble)
                    .cornerRadius(18)
                    .offset(x: isAnimated ? 0 : -50)
                    .opacity(isAnimated ? 1.0 : 0.0)
                } else if message.content == "Thinking..." && !message.isUser {
                    ThinkingView()
                        .opacity(isAnimated ? 1.0 : 0.0)
                } else if let imageData = message.imageData, !message.isUser {
                    // Display image if we have image data
                    if let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 280, maxHeight: 280)
                            .cornerRadius(16)
                            .padding(8)
                            .background(AppTheme.botBubble)
                            .cornerRadius(18)
                            .offset(x: isAnimated ? 0 : -50)
                            .opacity(isAnimated ? 1.0 : 0.0)
                    } else {
                        // Fallback if image data is invalid
                        Text("Unable to display image")
                            .font(.system(size: 16))
                            .padding(16)
                            .background(AppTheme.botBubble)
                            .foregroundColor(AppTheme.botBubbleText)
                            .cornerRadius(18)
                            .offset(x: isAnimated ? 0 : -50)
                            .opacity(isAnimated ? 1.0 : 0.0)
                    }
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


