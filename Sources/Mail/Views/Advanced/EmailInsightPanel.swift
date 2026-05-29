import SwiftUI

/// Contextual panel showing intent, entities, and extracted data for a specific email.
struct EmailInsightPanel: View {
    let thread: MailThread
    @StateObject private var viewModel = EmailInsightViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView("Extracting Insights...")
                    Spacer()
                }
            } else {
                intentSection
                entitiesSection
                actionsSection
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .onAppear { viewModel.loadInsights(for: thread) }
    }

    private var intentSection: some View {
        HStack {
            Label("Intent", systemImage: "target")
                .font(.headline)
            Spacer()
            Text(viewModel.intent?.rawValue.capitalized ?? "Analyzing...")
                .font(.subheadline.bold())
                .foregroundStyle(.purple)
        }
    }

    private var entitiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Extracted Entities")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            if let entities = viewModel.entities {
                FlowLayout(entities.people, spacing: 8) { EntityPill(text: $0, icon: "person.fill", color: .blue) }
                FlowLayout(entities.organizations, spacing: 8) { EntityPill(text: $0, icon: "building.2.fill", color: .orange) }
                FlowLayout(entities.deliverables, spacing: 8) { EntityPill(text: $0, icon: "cube.fill", color: .green) }
            }
        }
    }

    private var actionsSection: some View {
        HStack {
            Button(action: { viewModel.addToTasks(thread: thread) }) {
                Label("Add to Tasks", systemImage: "checklist")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button(action: { viewModel.addToCalendar(thread: thread) }) {
                Label("Calendar", systemImage: "calendar")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

struct EntityPill: View {
    let text: String
    let icon: String
    let color: Color
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2.bold())
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }
}

