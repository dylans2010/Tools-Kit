import SwiftUI

struct AutomationHomeView: View {
    @State private var showingWorkflowBuilder = false

    var body: some View {
        List {
            Section("Active Workflows") {
                Text("No active workflows.")
                    .foregroundColor(.secondary)
            }

            Section("Templates") {
                WorkflowTemplateRow(title: "Auto-task from Email", description: "Create a task when an email is marked as priority.", icon: "envelope.badge.shield.half.filled")
                WorkflowTemplateRow(title: "Commit to Note", description: "Summarize daily commits into a notebook page.", icon: "terminal.fill")
                WorkflowTemplateRow(title: "Meeting Summary", description: "Generate action items after a call ends.", icon: "video.fill")
            }
        }
        .navigationTitle("Automation")
        .toolbar {
            Button(action: { showingWorkflowBuilder = true }) {
                Image(systemName: "plus")
            }
        }
        .sheet(isPresented: $showingWorkflowBuilder) {
            WorkflowBuilderView()
        }
    }
}

struct WorkflowTemplateRow: View {
    let title: String
    let description: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}

