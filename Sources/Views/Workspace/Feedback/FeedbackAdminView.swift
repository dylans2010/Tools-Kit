import SwiftUI

struct FeedbackAdminView: View {
    let allowDeveloperToolsAccess: Bool

    @State private var feedbackItems: [Feedback] = []
    @State private var selectedCategoryFilter = "all"
    @State private var selectedStatusFilter = "all"
    @State private var selectedPriorityFilter = "all"
    @State private var selectedSort: SortOption = .newest

    @State private var isLoading = false
    @State private var errorMessage: String?

    init(allowDeveloperToolsAccess: Bool = false) {
        self.allowDeveloperToolsAccess = allowDeveloperToolsAccess
    }

    private enum SortOption: String, CaseIterable, Identifiable {
        case newest
        case priority

        var id: String { rawValue }
    }

    private var hasAccess: Bool {
        #if DEBUG
        true
        #else
        allowDeveloperToolsAccess
        #endif
    }

    var body: some View {
        Group {
            if hasAccess {
                content
            } else {
                ContentUnavailableView(
                    "Admin Access Required",
                    systemImage: "lock.fill",
                    description: Text("Feedback moderation is available only in debug or developer tools mode.")
                )
            }
        }
        .navigationTitle("Feedback Admin")
        .task {
            guard hasAccess else { return }
            await loadFeedback()
        }
    }

    private var content: some View {
        List {
            filterSection

            if isLoading {
                ProgressView("Loading feedback...")
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if filteredAndSortedFeedback.isEmpty {
                ContentUnavailableView(
                    "No Feedback",
                    systemImage: "tray",
                    description: Text("No feedback entries available.")
                )
            } else {
                ForEach(filteredAndSortedFeedback) { feedback in
                    NavigationLink {
                        FeedbackDetailView(feedback: feedback) { updated in
                            if let index = feedbackItems.firstIndex(where: { $0.id == updated.id }) {
                                feedbackItems[index] = updated
                            }
                        }
                    } label: {
                        FeedbackRowView(feedback: feedback)
                    }
                }
            }
        }
        .refreshable {
            await loadFeedback()
        }
    }

    private var filterSection: some View {
        Section("Filters & Sort") {
            Picker("Category", selection: $selectedCategoryFilter) {
                Text("All").tag("all")
                ForEach(FeedbackCategory.allCases) { category in
                    Text(category.displayName).tag(category.rawValue)
                }
            }

            Picker("Status", selection: $selectedStatusFilter) {
                Text("All").tag("all")
                ForEach(FeedbackStatus.allCases) { status in
                    Text(status.displayName).tag(status.rawValue)
                }
            }

            Picker("Priority", selection: $selectedPriorityFilter) {
                Text("All").tag("all")
                ForEach(FeedbackPriority.allCases) { priority in
                    Text(priority.displayName).tag(priority.rawValue)
                }
            }

            Picker("Sort", selection: $selectedSort) {
                Text("Newest").tag(SortOption.newest)
                Text("Priority").tag(SortOption.priority)
            }
            .pickerStyle(.segmented)
        }
    }

    private var filteredAndSortedFeedback: [Feedback] {
        var result = feedbackItems

        if selectedCategoryFilter != "all" {
            result = result.filter { $0.category == selectedCategoryFilter }
        }

        if selectedStatusFilter != "all" {
            result = result.filter { $0.status == selectedStatusFilter }
        }

        if selectedPriorityFilter != "all" {
            result = result.filter { $0.priority == selectedPriorityFilter }
        }

        switch selectedSort {
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .priority:
            result.sort { priorityRank($0.priorityValue) < priorityRank($1.priorityValue) }
        }

        return result
    }

    private func priorityRank(_ priority: FeedbackPriority) -> Int {
        switch priority {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }

    @MainActor
    private func loadFeedback() async {
        isLoading = true
        errorMessage = nil

        do {
            feedbackItems = try await FeedbackService.shared.fetchAllFeedback()
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
        }
    }
}
