import SwiftUI

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var showWelcome = false
    @State private var showTuning = false
    @State private var shuffledPrompts: [String] = []

    // Preset Prompts (100+)
    private let allPrompts = [
        "Summarize my recent meetings", "What are my top priorities today?", "Draft an email to my team about the project",
        "How many habits have I completed this week?", "Show me my upcoming deadlines", "Analyze my latest spreadsheet",
        "Create a slide deck outline for a sales pitch", "What did we decide in the last collaboration session?",
        "Find knowledge gaps in my notebooks", "How is my streak for 'Morning Run'?", "Review my recent mail for urgent tasks",
        "Suggest a better schedule for tomorrow", "What are the key points from my latest article?",
        "Compare my tasks from last week vs this week", "Draft a project proposal based on my notes",
        "Explain the current status of the 'Marketing' space", "Summarize all unread emails",
        "What are my habits for today?", "How many slides are in my 'Product Launch' deck?",
        "Give me a briefing for my 2 PM meeting", "What tasks are overdue?", "List all notebooks related to 'AI'",
        "Help me brainstorm ideas for a new blog post", "Summarize the 'Research' folder in my notebook",
        "Who are the members of the 'Design' collaboration space?", "Calculate the average value in my 'Budget' sheet",
        "Suggest 3 new habits based on my goals", "Create a task for 'Follow up with Client'",
        "Show me my activity feed for the 'Development' space", "What articles did I read yesterday?",
        "Draft a summary of my weekly accomplishments", "Find all tasks with high priority",
        "What is the description of the 'Alpha' collaboration space?", "How many mail accounts are connected?",
        "Show me the content of my 'Ideas' page", "What is my longest habit streak?",
        "Create a meeting agenda for tomorrow's sync", "Summarize the recent changes in 'Source Code' space",
        "What are the tags in my 'Project X' notebook?", "How many tasks are completed today?",
        "Draft a reply to the last email from 'John'", "What are the upcoming events for this weekend?",
        "List all slide decks I modified this week", "Analyze the trends in my 'Sales' spreadsheet",
        "Give me a summary of the 'Habit Coaching' insights", "What is the status of my 'Fitness' goal?",
        "Show me the most recent collaboration messages", "Draft an article based on my 'Brainstorm' notes",
        "What are the key takeaways from the 'Vision' meeting?", "How many spreadsheets do I have?",
        "Summarize the 'Meeting Notes' folder", "What tasks are assigned to me in 'Team Alpha'?",
        "List all articles in the 'Tech' collection", "How many habits have a 100% completion rate?",
        "Show me my schedule for next Monday", "Draft a welcome message for new space members",
        "What is the total row count of my 'Inventory' sheet?", "Create a 'Weekly Review' task",
        "Summarize the 'Competitor Analysis' slide deck", "What are the recent interactions with Persona?",
        "Help me organize my 'Drafts' folder", "What is the theme of my 'Presentation 1'?",
        "Draft a follow-up email for the 'Partnership' meeting", "How many tasks are due in the next 3 days?",
        "Summarize the 'Project Requirements' document", "What are my most active habits?",
        "List all members in the 'Workspace Admins' space", "Calculate the sum of 'Expenses' in my sheet",
        "Suggest a topic for my next presentation", "Show me my top 5 most used notebook tags",
        "What is the description of the 'Personal' notebook?", "How many unread messages in collaboration spaces?",
        "Draft a summary of the 'User Feedback' articles", "What are my commitments for this week?",
        "Summarize the 'Onboarding' slide deck", "How many habits did I miss yesterday?",
        "List all calendar events at 'Office'", "Draft a response to the 'Budget Approval' request",
        "What are the main goals of the 'Expansion' space?", "How many columns in the 'Performance' sheet?",
        "Create a task list for 'Event Planning'", "Summarize the 'Marketing Strategy' notes",
        "What is my current completion rate for 'Reading'?", "List all tasks with 'Urgent' tag",
        "Show me the latest commit in 'Main Project'", "Draft an intro for the 'Annual Report'",
        "What are the action items from 'Sync #4'?", "How many articles are in my 'Reference' library?",
        "Summarize the 'Q3 Goals' notebook page", "What is the start time of my next event?",
        "List all spreadsheets related to 'Finance'", "Draft a project update for 'Stakeholders'",
        "What are my habits for the 'Health' category?", "How many slides have images in my deck?",
        "Summarize the 'Product Roadmap' space", "What is the due date of 'Finalize Design'?",
        "List all notebook folders in 'Workspace'", "Draft a 'Thank You' note for the team",
        "What are the highlights from the 'Innovation' workshop?", "How many collaboration spaces am I in?"
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Chat History
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if manager.chatHistory.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 100)
                                Text("Ask Persona anything about your workspace.")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(manager.chatHistory) { message in
                                PersonaChatBubble(message: message)
                                    .id(message.id)
                            }
                        }

                        if manager.isThinking {
                            ThinkingIndicator()
                                .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: manager.chatHistory.count) { _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: manager.isThinking) { thinking in
                    if thinking {
                        scrollToBottom(proxy)
                    }
                }
            }

            // Presets and Input
            VStack(spacing: 12) {
                // Preset Prompts
                HStack(spacing: 8) {
                    ForEach(shuffledPrompts, id: \.self) { prompt in
                        Button(action: {
                            query = prompt
                            sendMessage()
                        }) {
                            Text(prompt)
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(12)
                                .lineLimit(1)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }

                    Button(action: {
                        withAnimation {
                            shufflePrompts()
                        }
                    }) {
                        Image(systemName: "shuffle")
                            .font(.caption2)
                            .padding(6)
                            .background(Color.accentColor.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)

                // Input Area
                HStack(spacing: 12) {
                    TextField("Message Persona...", text: $query, axis: .vertical)
                        .padding(10)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(20)
                        .lineLimit(1...5)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(query.isEmpty || manager.isThinking ? AnyShapeStyle(.secondary) : AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)))
                    }
                    .disabled(query.isEmpty || manager.isThinking)
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(.ultraThinMaterial)
        }
        .navigationTitle("AI Persona")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showTuning = true } label: {
                    Image(systemName: "slider.horizontal.3")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { showWelcome = true } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .onAppear {
            if manager.chatHistory.isEmpty && !hasShownWelcome {
                showWelcome = true
                hasShownWelcome = true
            }
            shufflePrompts()
        }
        .sheet(isPresented: $showWelcome) {
            WelcomePersonaView()
        }
        .sheet(isPresented: $showTuning) {
            TuningSheetView(manager: manager)
                .presentationDetents([.medium])
        }
    }

    private func sendMessage() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        query = ""

        Task {
            await manager.queryPersonaSafely(query: trimmed)
        }
    }

    private func shufflePrompts() {
        shuffledPrompts = Array(allPrompts.shuffled().prefix(3))
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        withAnimation {
            if manager.isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let lastId = manager.chatHistory.last?.id {
                proxy.scrollTo(lastId, anchor: .bottom)
            }
        }
    }
}

private struct PersonaChatBubble: View {
    let message: PersonaMessage

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                PersonaMarkdownBubbleText(markdown: message.content, isUser: message.role == "user")
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(message.role == "user" ?
                                  AnyShapeStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                                  AnyShapeStyle(Color.secondary.opacity(0.15)))
                    )
                    .foregroundStyle(message.role == "user" ? .white : .primary)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.role == "assistant" { Spacer() }
        }
        .transition(.asymmetric(insertion: .move(edge: message.role == "user" ? .trailing : .leading).combined(with: .opacity), removal: .opacity))
    }
}

private struct PersonaMarkdownBubbleText: View {
    let markdown: String
    let isUser: Bool

    var body: some View {
        if let parsed = try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(parsed)
        } else {
            Text(markdown)
        }
    }
}

struct ThinkingIndicator: View {
    @State private var animStep = 0
    let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 7, height: 7)
                            .scaleEffect(animStep == index ? 1.2 : 0.8)
                            .opacity(animStep == index ? 1.0 : 0.4)
                    }
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 18).fill(Color.secondary.opacity(0.15)))
            }
            Spacer()
        }
        .onReceive(timer) { _ in
            withAnimation(.easeInOut(duration: 0.4)) {
                animStep = (animStep + 1) % 3
            }
        }
    }
}

struct WelcomePersonaView: View {
    @State private var gradientStart = UnitPoint.topLeading
    @State private var gradientEnd = UnitPoint.bottomTrailing
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple, .mint, .indigo, .cyan],
                                startPoint: gradientStart,
                                endPoint: gradientEnd
                            )
                        )
                        .symbolEffect(.pulse.byLayer, options: .nonRepeating)
                        .onAppear {
                            withAnimation(.linear(duration: 3).repeatForever(autoreverses: true)) {
                                gradientStart = .bottomTrailing
                                gradientEnd = .topLeading
                            }
                        }
                        .padding(.top, 40)

                    VStack(spacing: 8) {
                        Text("Welcome to Persona")
                            .font(.system(size: 34, weight: .bold))
                        Text("Your Personal Workspace AI")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 25) {
                        PersonaInfoRow(icon: "brain.head.profile", title: "Intelligent Analysis", detail: "Persona analyzes your Mail, Calendar, Tasks, and more to provide context-aware insights.")
                        PersonaInfoRow(icon: "bubble.left.and.bubble.right", title: "Natural Chat", detail: "Talk to your data naturally. Ask questions, draft replies, or plan your week effortlessly.")
                        PersonaInfoRow(icon: "lock.shield", title: "Secure & Private", detail: "All data processing happens within your workspace. We prioritize your privacy and data sovereignty.")
                    }
                    .padding(.horizontal, 30)

                    Spacer(minLength: 40)

                    Button {
                        dismiss()
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct TuningSheetView: View {
    @ObservedObject var manager: PersonaManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Persona Identity")) {
                    TextField("Name", text: $manager.config.name)
                    VStack(alignment: .leading) {
                        Text("Instructions").font(.caption).foregroundStyle(.secondary)
                        TextEditor(text: $manager.config.instructions)
                            .frame(height: 80)
                    }
                }

                Section(header: Text("Training & Data")) {
                    Toggle("Train Persona With My Data", isOn: $manager.config.isTrainingEnabled)
                    Text("Interaction pairs are used to improve the Persona's future responses. This can be disabled at any time.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        manager.clearHistory()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear Chat History")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Tuning")
            .navigationBarItems(trailing: Button("Done") {
                manager.saveConfig()
                dismiss()
            })
        }
    }
}

private struct PersonaInfoRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 35)

            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
