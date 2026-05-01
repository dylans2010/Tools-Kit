import SwiftUI

/// Attention-based inbox view that replaces standard chronological order with AI scoring.
struct PriorityQueueView: View {
    @StateObject private var viewModel = PriorityQueueViewModel()

    var body: some View {
        List {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Analyzing Priority...")
                    Spacer()
                }
                .listRowBackground(Color.clear)
            } else if viewModel.prioritizedThreads.isEmpty {
                Text("Your priority queue is clear.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.prioritizedThreads) { thread in
                    WorkspaceSurfaceCard {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(thread.subject)
                                    .font(.headline)
                                Spacer()
                                scoreBadge(for: thread)
                            }

                            Text(thread.snippet)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)

                            HStack {
                                Label("Urgent", systemImage: "exclamationmark.circle")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                Spacer()
                                Text(thread.lastMessageDate, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Priority Queue")
        .onAppear { viewModel.loadPriorityQueue() }
    }

    private func scoreBadge(for thread: MailThread) -> some View {
        Text("\(Int((thread.priorityScore ?? 0.8) * 100))")
            .font(.caption2.bold())
            .padding(6)
            .background(Color.purple.opacity(0.2))
            .foregroundStyle(.purple)
            .clipShape(Circle())
    }
}
