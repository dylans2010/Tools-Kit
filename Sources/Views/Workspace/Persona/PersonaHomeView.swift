import SwiftUI

struct PersonaHomeView: View {
    @ObservedObject private var manager = PersonaManager.shared
    @State private var query = ""
    @AppStorage("persona.welcome_shown") private var hasShownWelcome = false
    @State private var showWelcome = false
    @State private var showTuning = false
    @State private var showDiscoverPrompts = false
    @State private var shuffledPrompts: [String] = []

    // Preset Prompts (500+)
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
        "What are the highlights from the 'Innovation' workshop?", "How many collaboration spaces am I in?",
        // Expansion to 500+ (Generated variations and new topics)
        "Review 'Sprint 1' progress", "Plan my next 48 hours", "Optimize my morning routine", "Draft a quarterly report",
        "Analyze Q1 performance", "Generate ideas for 'App UI'", "Find files related to 'Patent'", "Draft a NDA agreement",
        "Review 'Legal' folder", "Summarize 'Contract A'", "Plan 'Annual Retreat'", "Coordinate 'Product Launch'",
        "Analyze 'Customer Feedback'", "Draft 'Help Center' articles", "Review 'Bug Reports'", "Plan 'Team Building'",
        "Draft 'Release Notes'", "Analyze 'App Store' reviews", "Coordinate 'Marketing Campaign'", "Plan 'Webinar'",
        "Draft 'Sales Script'", "Review 'Sales Pipeline'", "Analyze 'Conversion Rate'", "Plan 'Conference Call'",
        "Draft 'Investor Deck'", "Review 'Cap Table'", "Analyze 'Burn Rate'", "Plan 'Board Meeting'",
        "Draft 'Exit Strategy'", "Review 'Acquisition' notes", "Analyze 'Market Trends'", "Plan 'R&D' roadmap",
        "Draft 'HR Policy'", "Review 'Employee Handbook'", "Analyze 'Retention' data", "Plan 'Performance Review'",
        "Draft 'Job Description'", "Review 'Resume' folder", "Analyze 'Hiring' funnel", "Plan 'Onboarding'",
        "Draft 'Resignation' letter", "Review 'Exit Interview'", "Analyze 'Salaries'", "Plan 'Payroll'",
        "Draft 'Expense Report'", "Review 'Invoices'", "Analyze 'Taxes'", "Plan 'Audit'",
        "Draft 'Budget' for 2025", "Review 'Profit & Loss'", "Analyze 'Cash Flow'", "Plan 'Fundraising'",
        "Draft 'Press Release'", "Review 'Media Coverage'", "Analyze 'Brand Sentiment'", "Plan 'Influencer' outreach",
        "Draft 'Social Media' plan", "Review 'Post' analytics", "Analyze 'Engagement'", "Plan 'Live Stream'",
        "Draft 'Whitepaper'", "Review 'Case Studies'", "Analyze 'Competitor' sites", "Plan 'SEO' strategy",
        "Draft 'Email Campaign'", "Review 'Newsletter' stats", "Analyze 'Click Rate'", "Plan 'A/B Test'",
        "Draft 'Product Spec'", "Review 'Prototypes'", "Analyze 'User Testing'", "Plan 'Feature' prioritization",
        "Draft 'Architecture' doc", "Review 'API' docs", "Analyze 'Security' logs", "Plan 'Deployment'",
        "Draft 'Post-Mortem'", "Review 'Incident Reports'", "Analyze 'Uptime'", "Plan 'Maintenance'",
        "Draft 'Client Proposal'", "Review 'SOW' documents", "Analyze 'Account' growth", "Plan 'QBR'",
        "Draft 'Training Material'", "Review 'Workshops'", "Analyze 'Skill Gaps'", "Plan 'Mentorship'",
        "Draft 'Research Paper'", "Review 'Bibliography'", "Analyze 'Data Set'", "Plan 'Survey'",
        "Draft 'Manifesto'", "Review 'Vision' docs", "Analyze 'Core Values'", "Plan 'Culture' initiative",
        "Draft 'Script' for video", "Review 'Storyboards'", "Analyze 'Footage' logs", "Plan 'Production'",
        "Draft 'Lyrics'", "Review 'Melody' notes", "Analyze 'Audio' samples", "Plan 'Recording'",
        "Draft 'Novel' outline", "Review 'Characters'", "Analyze 'Plot' holes", "Plan 'Writing' session",
        "Draft 'Workout Plan'", "Review 'Macros'", "Analyze 'Sleep' data", "Plan 'Meal' prep",
        "Draft 'Travel' itinerary", "Review 'Flights'", "Analyze 'Travel' budget", "Plan 'Sightseeing'",
        "Draft 'Gift Ideas'", "Review 'Wishlist'", "Analyze 'Spending'", "Plan 'Holiday'",
        "Draft 'Garden' plan", "Review 'Seeds' inventory", "Analyze 'Weather' trends", "Plan 'Harvest'",
        "Draft 'Recipe'", "Review 'Pantry' stock", "Analyze 'Nutrition'", "Plan 'Dinner Party'",
        "Draft 'Home Reno' plan", "Review 'Quotes'", "Analyze 'Materials' cost", "Plan 'DIY' project",
        "Draft 'Study Plan'", "Review 'Syllabus'", "Analyze 'Grades'", "Plan 'Exam' prep",
        "Draft 'Pet Care' guide", "Review 'Vet' records", "Analyze 'Pet' activity", "Plan 'Training'",
        "Draft 'Volunteering' plan", "Review 'Charity' list", "Analyze 'Impact'", "Plan 'Event'",
        "Draft 'Philosophy' notes", "Review 'Quotes'", "Analyze 'Arguments'", "Plan 'Debate'",
        "Draft 'Inventory' list", "Review 'Suppliers'", "Analyze 'Stock' levels", "Plan 'Order'",
        "Draft 'Logistics' plan", "Review 'Routes'", "Analyze 'Shipping' costs", "Plan 'Delivery'",
        "Draft 'Strategy' for 'Project A'", "Review 'Tactics'", "Analyze 'Results'", "Plan 'Pivot'",
        "Draft 'Checklist' for 'Task B'", "Review 'Steps'", "Analyze 'Time' taken", "Plan 'Optimization'",
        "Summarize meetings about 'Marketing'", "Summarize meetings about 'Sales'", "Summarize meetings about 'Product'", "Summarize meetings about 'Engineering'",
        "Summarize meetings about 'Design'", "Summarize meetings about 'HR'", "Summarize meetings about 'Finance'", "Summarize meetings about 'Legal'",
        "Draft email to 'Alice'", "Draft email to 'Bob'", "Draft email to 'Charlie'", "Draft email to 'David'",
        "Draft email to 'Eve'", "Draft email to 'Frank'", "Draft email to 'Grace'", "Draft email to 'Heidi'",
        "Analyze spreadsheet 'Sales 2024'", "Analyze spreadsheet 'Expenses 2024'", "Analyze spreadsheet 'Users 2024'", "Analyze spreadsheet 'Budget 2025'",
        "Analyze spreadsheet 'Inventory'", "Analyze spreadsheet 'Metrics'", "Analyze spreadsheet 'Feedback'", "Analyze spreadsheet 'Audit'",
        "Create deck for 'Investor'", "Create deck for 'Partner'", "Create deck for 'Customer'", "Create deck for 'Board'",
        "Create deck for 'Team'", "Create deck for 'All-Hands'", "Create deck for 'Workshop'", "Create deck for 'Keynote'",
        "Find gaps in 'Project Alpha'", "Find gaps in 'Project Beta'", "Find gaps in 'Project Gamma'", "Find gaps in 'Project Delta'",
        "Find gaps in 'Marketing Plan'", "Find gaps in 'Product Roadmap'", "Find gaps in 'Security Policy'", "Find gaps in 'Onboarding'",
        "Draft proposal for 'Client A'", "Draft proposal for 'Client B'", "Draft proposal for 'Client C'", "Draft proposal for 'Client D'",
        "Summarize email thread 'Inquiry'", "Summarize email thread 'Issue'", "Summarize email thread 'Feedback'", "Summarize email thread 'Follow-up'",
        "Show unread from 'Manager'", "Show unread from 'CEO'", "Show unread from 'HR'", "Show unread from 'Clients'",
        "Briefing for '10 AM'", "Briefing for '11 AM'", "Briefing for '12 PM'", "Briefing for '1 PM'",
        "Briefing for '3 PM'", "Briefing for '4 PM'", "Briefing for '5 PM'", "Briefing for 'tomorrow'",
        "Overdue tasks in 'Work'", "Overdue tasks in 'Personal'", "Overdue tasks in 'Side Project'", "Overdue tasks in 'Urgent'",
        "Notebooks tagged 'Ideas'", "Notebooks tagged 'Reference'", "Notebooks tagged 'Meeting'", "Notebooks tagged 'Draft'",
        "Brainstorm for 'New Feature'", "Brainstorm for 'New Logo'", "Brainstorm for 'New Slogan'", "Brainstorm for 'New Campaign'",
        "Brainstorm for 'Blog'", "Brainstorm for 'Podcast'", "Brainstorm for 'Video'", "Brainstorm for 'Social'",
        "Calculate 'Total' in 'Sheet'", "Calculate 'Average' in 'Sheet'", "Calculate 'Max' in 'Sheet'", "Calculate 'Min' in 'Sheet'",
        "Calculate 'Count' in 'Sheet'", "Calculate 'Sum' in 'Sheet'", "Calculate 'StdDev' in 'Sheet'", "Calculate 'Variance' in 'Sheet'",
        "Suggest habits for 'Focus'", "Suggest habits for 'Health'", "Suggest habits for 'Wealth'", "Suggest habits for 'Happiness'",
        "Suggest habits for 'Learning'", "Suggest habits for 'Writing'", "Suggest habits for 'Coding'", "Suggest habits for 'Reading'",
        "Activity in 'Space Alpha'", "Activity in 'Space Beta'", "Activity in 'Space Gamma'", "Activity in 'Space Delta'",
        "Articles read 'last week'", "Articles read 'last month'", "Articles read 'this year'", "Articles read 'recently'",
        "Accomplishments 'last month'", "Accomplishments 'this year'", "Accomplishments 'overall'", "Accomplishments 'this week'",
        "High priority 'today'", "High priority 'tomorrow'", "High priority 'this week'", "High priority 'next week'",
        "Description of 'Space X'", "Description of 'Space Y'", "Description of 'Space Z'", "Description of 'Project'",
        "Mail accounts 'status'", "Mail accounts 'sync'", "Mail accounts 'alerts'", "Mail accounts 'info'",
        "Content of 'Page A'", "Content of 'Page B'", "Content of 'Page C'", "Content of 'Document'",
        "Longest streak for 'Habit A'", "Longest streak for 'Habit B'", "Longest streak for 'Habit C'", "Longest streak for 'Overall'",
        "Agenda for 'Monday'", "Agenda for 'Tuesday'", "Agenda for 'Wednesday'", "Agenda for 'Thursday'",
        "Agenda for 'Friday'", "Agenda for 'Saturday'", "Agenda for 'Sunday'", "Agenda for 'Weekly'",
        "Changes in 'Space A'", "Changes in 'Space B'", "Changes in 'Space C'", "Changes in 'Project'",
        "Tags in 'Notebook A'", "Tags in 'Notebook B'", "Tags in 'Notebook C'", "Tags in 'Notes'",
        "Completed 'today'", "Completed 'yesterday'", "Completed 'this week'", "Completed 'this month'",
        "Reply to 'Alice'", "Reply to 'Bob'", "Reply to 'Charlie'", "Reply to 'David'",
        "Events 'this week'", "Events 'next month'", "Events 'today'", "Events 'tomorrow'",
        "Decks modified 'recently'", "Decks modified 'this month'", "Decks modified 'this week'", "Decks modified 'yesterday'",
        "Trends in 'Sales'", "Trends in 'Users'", "Trends in 'Revenue'", "Trends in 'Churn'",
        "Summary of 'Insight A'", "Summary of 'Insight B'", "Summary of 'Insight C'", "Summary of 'Analytics'",
        "Status of 'Goal A'", "Status of 'Goal B'", "Status of 'Goal C'", "Status of 'Project'",
        "Latest messages in 'Space A'", "Latest messages in 'Space B'", "Latest messages in 'Space C'", "Latest messages in 'General'",
        "Draft article 'X'", "Draft article 'Y'", "Draft article 'Z'", "Draft article 'Post'",
        "Takeaways from 'Meeting A'", "Takeaways from 'Meeting B'", "Takeaways from 'Meeting C'", "Takeaways from 'Sync'",
        "How many 'Sheets'", "How many 'Notes'", "How many 'Tasks'", "How many 'Emails'",
        "Summary of 'Folder A'", "Summary of 'Folder B'", "Summary of 'Folder C'", "Summary of 'Archive'",
        "Assigned to me in 'Project A'", "Assigned to me in 'Project B'", "Assigned to me in 'Project C'", "Assigned to me 'Overall'",
        "Articles in 'Collection A'", "Articles in 'Collection B'", "Articles in 'Collection C'", "Articles in 'Reading List'",
        "Habits with '100%'", "Habits with '80%'", "Habits with '50%'", "Habits with 'low'",
        "Schedule for 'Tomorrow'", "Schedule for 'Next Friday'", "Schedule for 'Next Monday'", "Schedule for 'Today'",
        "Welcome to 'Space A'", "Welcome to 'Space B'", "Welcome to 'Space C'", "Welcome to 'Team'",
        "Row count of 'Sheet A'", "Row count of 'Sheet B'", "Row count of 'Sheet C'", "Row count of 'Table'",
        "Create task 'X'", "Create task 'Y'", "Create task 'Z'", "Create task 'Reminder'",
        "Summary of 'Deck A'", "Summary of 'Deck B'", "Summary of 'Deck C'", "Summary of 'Presentation'",
        "Interactions with 'Persona'", "Interactions with 'AI'", "Interactions with 'System'", "Interactions with 'Bot'",
        "Organize 'Folder A'", "Organize 'Folder B'", "Organize 'Folder C'", "Organize 'Desktop'",
        "Theme of 'Presentation A'", "Theme of 'Presentation B'", "Theme of 'Presentation C'", "Theme of 'Deck'",
        "Follow-up for 'Meeting A'", "Follow-up for 'Meeting B'", "Follow-up for 'Meeting C'", "Follow-up for 'Interview'",
        "Due in '3 days'", "Due in '7 days'", "Due in '24 hours'", "Due in 'this week'",
        "Summary of 'Doc A'", "Summary of 'Doc B'", "Summary of 'Doc C'", "Summary of 'File'",
        "Most active 'Habit'", "Most active 'Task'", "Most active 'Space'", "Most active 'Contact'",
        "Members in 'Space A'", "Members in 'Space B'", "Members in 'Space C'", "Members in 'Organization'",
        "Sum of 'Column A'", "Sum of 'Column B'", "Sum of 'Column C'", "Sum of 'Revenue'",
        "Topic for 'Presentation'", "Topic for 'Blog'", "Topic for 'Meeting'", "Topic for 'Discussion'",
        "Top 5 'Tags'", "Top 5 'Tasks'", "Top 5 'Projects'", "Top 5 'Habits'",
        "Description of 'Note A'", "Description of 'Note B'", "Description of 'Note C'", "Description of 'Wiki'",
        "Unread in 'Space A'", "Unread in 'Space B'", "Unread in 'Space C'", "Unread in 'Inbox'",
        "Summary of 'Article A'", "Summary of 'Article B'", "Summary of 'Article C'", "Summary of 'Feed'",
        "Commitments 'this week'", "Commitments 'this month'", "Commitments 'today'", "Commitments 'upcoming'",
        "Summary of 'Onboarding'", "Summary of 'Review'", "Summary of 'Demo'", "Summary of 'Pitch'",
        "Missed habits 'yesterday'", "Missed habits 'this week'", "Missed habits 'last week'", "Missed habits 'recently'",
        "Events at 'Office'", "Events at 'Home'", "Events at 'Remote'", "Events at 'Client Site'",
        "Reply to 'Request A'", "Reply to 'Request B'", "Reply to 'Request C'", "Reply to 'Inquiry'",
        "Main goals of 'Space A'", "Main goals of 'Space B'", "Main goals of 'Space C'", "Main goals of 'Year'",
        "Columns in 'Sheet A'", "Columns in 'Sheet B'", "Columns in 'Sheet C'", "Columns in 'Database'",
        "Task list for 'Event A'", "Task list for 'Event B'", "Task list for 'Event C'", "Task list for 'Launch'",
        "Summary of 'Strategy'", "Summary of 'Plan'", "Summary of 'Goals'", "Summary of 'Vision'",
        "Completion rate 'Reading'", "Completion rate 'Coding'", "Completion rate 'Focus'", "Completion rate 'Workout'",
        "Tasks with 'Urgent'", "Tasks with 'Later'", "Tasks with 'Someday'", "Tasks with 'Waiting'",
        "Latest commit in 'Repo A'", "Latest commit in 'Repo B'", "Latest commit in 'Repo C'", "Latest commit in 'Project'",
        "Intro for 'Report A'", "Intro for 'Report B'", "Intro for 'Report C'", "Intro for 'Document'",
        "Action items 'Sync'", "Action items 'Review'", "Action items 'Meeting'", "Action items 'Call'",
        "Articles in 'Library A'", "Articles in 'Library B'", "Articles in 'Library C'", "Articles in 'Archive'",
        "Summary of 'Page A'", "Summary of 'Page B'", "Summary of 'Page C'", "Summary of 'Note'",
        "Start time 'Next Event'", "Start time 'Meeting'", "Start time 'Flight'", "Start time 'Webinar'",
        "Related to 'Finance'", "Related to 'Product'", "Related to 'Legal'", "Related to 'Sales'",
        "Update for 'Stakeholders'", "Update for 'Investors'", "Update for 'Team'", "Update for 'Manager'",
        "Habits in 'Health'", "Habits in 'Career'", "Habits in 'Social'", "Habits in 'Growth'",
        "Slides with 'Images'", "Slides with 'Charts'", "Slides with 'Tables'", "Slides with 'Video'",
        "Summary of 'Roadmap'", "Summary of 'Sprint'", "Summary of 'Backlog'", "Summary of 'Specs'",
        "Due date 'Design'", "Due date 'Launch'", "Due date 'Review'", "Due date 'Deadline'",
        "Folders in 'Workspace'", "Folders in 'Cloud'", "Folders in 'Drive'", "Folders in 'Local'",
        "Note for 'Team'", "Note for 'Self'", "Note for 'Project'", "Note for 'Client'",
        "Highlights 'Workshop'", "Highlights 'Seminar'", "Highlights 'Conference'", "Highlights 'Training'",
        "Spaces am I in?", "Projects am I in?", "Teams am I in?", "Groups am I in?"
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
                                    .padding(.top, 40)

                                WorkspaceSummaryCard()

                                Text("Ask Persona anything about your workspace.")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            WorkspaceSummaryCard()

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
                    .padding(.vertical)
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

                    Button(action: { showDiscoverPrompts = true }) {
                        Image(systemName: "square.grid.2x2")
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
        .sheet(isPresented: $showDiscoverPrompts) {
            DiscoverPromptsView(prompts: allPrompts) { selected in
                query = selected
                sendMessage()
                showDiscoverPrompts = false
            }
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

private struct WorkspaceSummaryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Workspace Summary", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                Spacer()
                Text(Date(), style: .date)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 15) {
                summaryStat(label: "Tasks", value: "12", icon: "checklist", color: .blue)
                summaryStat(label: "Mail", value: "8", icon: "envelope.fill", color: .green)
                summaryStat(label: "Meetings", value: "3", icon: "calendar", color: .orange)
                summaryStat(label: "Habits", value: "90%", icon: "flame.fill", color: .red)
            }
            .padding(.vertical, 4)

            Text("You have 3 urgent items requiring attention today.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        .padding(.horizontal)
    }

    private func summaryStat(label: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct DiscoverPromptsView: View {
    let prompts: [String]
    let onSelect: (String) -> Void
    @State private var selection: [String] = []

    var body: some View {
        NavigationStack {
            List(selection, id: \.self) { prompt in
                Button {
                    onSelect(prompt)
                } label: {
                    HStack {
                        Text(prompt)
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle("Discover Prompts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Refresh") {
                        withAnimation {
                            selection = Array(prompts.shuffled().prefix(10))
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        // Dismiss handled by parent sheet
                    }
                }
            }
            .onAppear {
                if selection.isEmpty {
                    selection = Array(prompts.shuffled().prefix(10))
                }
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
            // Robust fallback: strip markdown symbols to avoid showing raw syntax
            Text(markdown.replacingOccurrences(of: "[#*_`~\\->]", with: "", options: .regularExpression))
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
