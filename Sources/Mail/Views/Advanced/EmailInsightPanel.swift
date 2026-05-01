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

/// Production-grade FlowLayout implementation using the SwiftUI Layout protocol.
struct FlowLayout: View {
    var spacing: CGFloat
    var content: [AnyView]

    init<Data: Collection, Content: View>(
        _ data: Data,
        spacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.spacing = spacing
        self.content = data.map { AnyView(content($0)) }
    }

    var body: some View {
        FlowStack(spacing: spacing) {
            ForEach(0..<content.count, id: \.self) { index in
                content[index]
            }
        }
    }
}

/// Helper Layout for flowing elements.
struct FlowStack: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxX = max(maxX, currentX)
        }

        return CGSize(width: maxX, height: currentY + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
