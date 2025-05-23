import SwiftUI

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    @ObservedObject var settingsManager: SettingsManager
    @StateObject private var historyManager = ConversationHistoryManager()
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showSaveDialog = false
    @State private var selectedTab = 1
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab (now first)
            NavigationView {
                DashboardView()
                    .navigationBarTitleDisplayMode(.inline)
                    .modifier(
                        ToolbarModifier(
                            title: "Dashboard",
                            trailingButton: AnyView(Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 17))
                            })
                        )
                    )
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
                        ChatView(
                            chatViewModel: chatViewModel, 
                            settingsManager: settingsManager,
                            historyManager: historyManager,
                            showSaveDialog: $showSaveDialog
                        )
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .modifier(
                    ToolbarModifier(
                        title: chatViewModel.isFirstLaunch ? "" : "MMA AI",
                        leadingButton: AnyView(Button(action: {
                            showHistory = true
                        }) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 17))
                        }),
                        trailingButton: AnyView(Group {
                            if chatViewModel.isFirstLaunch {
                                // Settings button when on welcome screen
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Image(systemName: "gear")
                                        .font(.system(size: 17))
                                }
                            } else {
                                // Home button when in chat mode
                                Button(action: {
                                    // Navigate back to the welcome screen
                                    chatViewModel.goToWelcomeScreen() // Call the method to go to the welcome screen
                                }) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 17))
                                }
                            }
                        })
                    )
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
                .sheet(isPresented: $showSaveDialog) {
                    SaveConversationView(
                        chatViewModel: chatViewModel,
                        historyManager: historyManager
                    )
                }
                .onAppear {
                    // Just set up the notification observer when the view appears
                    setupPredictionObserver()
                }
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(1)
            .onChange(of: selectedTab) { oldValue, newValue in
                if newValue == 1 && !chatViewModel.isFirstLaunch {
                    // If the user selects the Chat tab and there's an ongoing conversation, show the chat
                    chatViewModel.isFirstLaunch = false
                }
            }
            
            // Fighters Tab (remains third)
            NavigationView {
                FighterDashboardView()
                    .navigationBarTitleDisplayMode(.inline)
                    .modifier(
                        ToolbarModifier(
                            title: "Database",
                            trailingButton: AnyView(Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 17))
                            })
                        )
                    )
            }
            .tabItem {
                Label("Database", systemImage: "figure.boxing")
            }
            .tag(2)
        }
        .accentColor(AppTheme.accent)
        .font(.system(size: 14, weight: .medium))
    }
    
    // Move the notification observer setup to a separate function
    private func setupPredictionObserver() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RequestFightPrediction"),
            object: nil,
            queue: .main
        ) { [weak chatViewModel] notification in
            guard let chatViewModel = chatViewModel else { return }
            
            if let prompt = notification.userInfo?["prompt"] as? String {
                // Switch to the chat tab
                selectedTab = 1
                
                // Always create a new chat for each prediction
                chatViewModel.startNewChat()
                chatViewModel.isFirstLaunch = false
                
                // Instead of using standard sendMessage, we'll use a special version
                // that doesn't show the user input in the chat UI
                chatViewModel.sendPredictionRequest(
                    prompt: prompt,
                    assistantId: "asst_n6LeaUZ7n2zYwMeGzIon47B5"
                )
            }
        }
    }
}

// Custom view modifier to handle the toolbar to avoid ambiguity
struct ToolbarModifier: ViewModifier {
    let title: String
    var leadingButton: AnyView? = nil
    var trailingButton: AnyView? = nil
    
    init(title: String, leadingButton: AnyView? = nil, trailingButton: AnyView? = nil) {
        self.title = title
        self.leadingButton = leadingButton
        self.trailingButton = trailingButton
    }
    
    func body(content: Content) -> some View {
        content
            .navigationBarItems(
                leading: leadingButton ?? AnyView(EmptyView()),
                trailing: trailingButton ?? AnyView(EmptyView())
            )
            .navigationTitle(title)
    }
}

struct WelcomeView: View {
    @ObservedObject var chatViewModel: ChatViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Logo/Header
                Image(systemName: "figure.boxing")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.accent)
//                    .padding(.top, 10)
                    .padding(.top, 4)
                
                Text("Welcome to\nMMA AI")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Ask questions about historical fights & fighters, to generate predictions, create visualizations, find trends, or anything...")
                    // .font(.footnote)
                    .font(.system(size: 14))
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.bottom, 2)
                
                Text("Example Questions:")
//                    .font(.headline)
                    .font(.footnote)
                    // .fontWeight(.semibold)
//                    .padding(.top, 10)
                    .padding(.top, 5)
                    .padding(.bottom, 5)
                
                // Generate buttons for example questions
                ForEach(0..<chatViewModel.exampleQuestions.count, id: \.self) { index in
                    Button(action: {
                        if chatViewModel.restoreConversation() {
                            chatViewModel.sendMessage(chatViewModel.exampleQuestions[index])
                        } else {
                            chatViewModel.sendMessage(chatViewModel.exampleQuestions[index])
                        }
                        chatViewModel.isFirstLaunch = false
                    }) {
                        Text(chatViewModel.exampleQuestions[index])
                            .font(.footnote)
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
                    _ = chatViewModel.restoreConversation()
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
    @ObservedObject var historyManager: ConversationHistoryManager
    @Binding var showSaveDialog: Bool
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
            
            // Action buttons row (MODIFIED)
            HStack(spacing: 16) {
                Spacer()
                
                Button(action: {
                    showingAlert = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("New Chat")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(AppTheme.cardBackground)
                    .foregroundColor(AppTheme.accent)
                    .cornerRadius(12)
                }
                
                // Added Save button
                Button(action: {
                    showSaveDialog = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(AppTheme.cardBackground)
                    .foregroundColor(AppTheme.accent)
                    .cornerRadius(12)
                }
                .disabled(chatViewModel.messages.isEmpty)
                
                Button(action: {
                    showingExportSheet = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(AppTheme.cardBackground)
                    .foregroundColor(AppTheme.accent)
                    .cornerRadius(12)
                }
                
                Spacer()
            }
            .padding(.vertical, 4)
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
                    // Display a loading spinner with appropriate text
                    HStack {
                        // Use the custom message content if provided, otherwise default to "Thinking..."
                        Text(message.content.isEmpty ? "Thinking..." : message.content)
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.botBubbleText)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.8)
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
                        NavigationLink(destination: FullScreenImageView(image: uiImage)) {
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
                        }
                        .contextMenu {
                            Button(action: {
                                shareImage(uiImage)
                            }) {
                                Text("Share")
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
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

func shareImage(_ image: UIImage) {
    let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
    
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {
        
        // Find the topmost view controller
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        
        // Present the activity view controller
        topController.present(activityVC, animated: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(settingsManager: SettingsManager()) // Pass necessary dependencies
    }
}
