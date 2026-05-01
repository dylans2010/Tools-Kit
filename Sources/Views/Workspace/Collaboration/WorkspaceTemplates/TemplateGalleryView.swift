import SwiftUI

struct TemplateGalleryView: View {
    @StateObject private var templateManager = TemplateManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: SpaceTemplate.TemplateCategory = .project

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(SpaceTemplate.TemplateCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(templateManager.templates.filter { $0.category == selectedCategory }) { template in
                            TemplateCard(template: template) {
                                _ = templateManager.createSpaceFromTemplate(template)
                                dismiss()
                            }
                        }

                        // Mock template if list is empty for demo
                        if templateManager.templates.isEmpty {
                            TemplateCard(template: SpaceTemplate(id: UUID(), name: "Startup Launch", description: "Standard workspace for new ventures.", icon: "rocket.fill", category: .startup, snapshotData: Data())) { }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Space Templates")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct TemplateCard: View {
    let template: SpaceTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: template.icon)
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
