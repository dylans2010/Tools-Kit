import SwiftUI
import Combine

@MainActor
final class AIInboxDashboardViewModel: ObservableObject {
    @Published var insights: [String] = []
    @Published var isTriageActive = false
    @Published var priorityThreads: [MailThread] = []

    private var triageTask: Task<Void, Never>?

    func performTriage() {
        isTriageActive = true
        triageTask = Task {
            let threads = MailStorageService.shared.loadThreads(for: "all")
            let results = try? await InboxOperatorEngine.shared.performTriage(on: threads)

            if !Task.isCancelled {
                self.insights = results?.values.map { String($0.prefix(60)) + "..." } ?? []
                self.priorityThreads = threads.filter { ($0.priorityScore ?? 0) > 0.7 }
                isTriageActive = false
            }
        }
    }

    func clearNoise() {
        Task {
            let threads = MailStorageService.shared.loadThreads(for: "all").filter { ($0.priorityScore ?? 0) < 0.2 }
            let actions = threads.map { InboxOperatorEngine.BatchAction(threadID: $0.id, type: .archive) }
            // For production, we'd need the actual account here
            if let account = MailStore.shared.activeAccount {
                try? await InboxOperatorEngine.shared.executeBatchActions(actions: actions, account: account)
            }
        }
    }

    func cancelTasks() {
        triageTask?.cancel()
    }
}

@MainActor
final class AutomationBuilderViewModel: ObservableObject {
    @Published var workflowName: String = ""
    @Published var steps: [WorkflowStep] = []
    @Published var isCompiling = false

    func addStep() {
        let newStep = WorkflowStep(id: UUID(), title: "New Step", description: "Define action details...", actionType: "manual", isCompleted: false)
        steps.append(newStep)
    }

    func deleteStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }

    func compileWorkflow() {
        isCompiling = true
        Task {
            let allThreads = MailStorageService.shared.loadThreads(for: "all")
            let thread = allThreads.first { $0.subject.contains(workflowName) }
                ?? MailThread(id: "manual", subject: workflowName, messages: [MailMessage(id: "manual", threadId: "manual", from: "User", to: [], cc: [], bcc: [], subject: workflowName, body: "Manual workflow trigger.", htmlBody: nil, date: Date(), isRead: true, isStarred: false, attachments: [])], lastMessageDate: Date())

            _ = try? await WorkflowAutomationEngine.shared.compileThreadToWorkflow(thread: thread)
            isCompiling = false
        }
    }
}

@MainActor
final class PriorityQueueViewModel: ObservableObject {
    @Published var prioritizedThreads: [MailThread] = []
    @Published var isLoading = false

    func loadPriorityQueue() {
        isLoading = true
        Task {
            let threads = MailStorageService.shared.loadThreads(for: "all")
            prioritizedThreads = await PriorityAttentionEngine.shared.rankThreadsByAttention(threads)
            isLoading = false
        }
    }
}

@MainActor
final class RelationshipInsightsViewModel: ObservableObject {
    @Published var profile: RelationshipProfile?
    @Published var isLoading = false

    func loadProfile(for email: String) {
        isLoading = true
        Task {
            let history = MailStorageService.shared.loadThreads(for: "all")
                .filter { $0.participants.contains(email) }
                .map { "Subject: \($0.subject), Last: \($0.lastMessageDate)" }
                .joined(separator: "\n")

            profile = try? await RelationshipIntelligenceEngine.shared.buildProfile(for: email, interactionHistory: history.isEmpty ? "No prior history." : history)
            isLoading = false
        }
    }
}

@MainActor
final class EmailInsightViewModel: ObservableObject {
    @Published var intent: MailIntent?
    @Published var entities: ExtractedEntities?
    @Published var isLoading = false

    func loadInsights(for thread: MailThread) {
        isLoading = true
        Task {
            intent = try? await CommunicationIntelligenceEngine.shared.classifyIntent(for: thread)
            entities = try? await CommunicationIntelligenceEngine.shared.extractEntities(for: thread)
            isLoading = false
        }
    }

    func addToTasks(thread: MailThread) {
        Task {
            let entities = try? await CommunicationIntelligenceEngine.shared.extractEntities(for: thread)
            let deadline = entities?.deadlines.first
            _ = try? await ExecutionBridge.shared.createTask(
                title: "Follow up: \(thread.subject)",
                description: "AI-extracted follow-up from thread \(thread.id). Deliverables: \(entities?.deliverables.joined(separator: ", ") ?? "None")"
            )
        }
    }

    func addToCalendar(thread: MailThread) {
        Task {
            _ = try? await ExecutionBridge.shared.convertThreadToCalendarEvent(thread: thread)
        }
    }
}
