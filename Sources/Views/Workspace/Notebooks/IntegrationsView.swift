import SwiftUI

struct IntegrationsView: View {
    @StateObject private var manager = NotebooksManager.shared
    @State private var showingCreate = false
    @State private var editingTool: IntegrationTool? = nil
    @State private var selectedCategory: ToolCategory = .all

    enum ToolCategory: String, CaseIterable {
        case all = "All"
        case writing = "Writing"
        case analysis = "Analysis"
        case research = "Research"
        case custom = "Custom"
    }

    private var filteredTools: [IntegrationTool] {
        manager.integrations
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ToolCategory.allCases, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                Text(cat.rawValue)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(selectedCategory == cat ? Color.purple : Color(.secondarySystemBackground))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // AI gradient header
                HStack(spacing: 12) {
                    ZStack {
                        LinearGradient(
                            colors: [.purple, .blue, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: 56, height: 56)
                        .cornerRadius(16)
                        Image(systemName: "puzzlepiece.extension.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Writing Tools")
                            .font(.headline)
                        Text("Build custom AI-powered tools to enhance your writing workflow.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.05)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .padding(.horizontal)

                if filteredTools.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "puzzlepiece.extension")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                        VStack(spacing: 8) {
                            Text("No Integrations Yet")
                                .font(.title3.bold())
                            Text("Create custom AI tools to enhance your writing with smart prompts, tone adjusters, and more.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        Button {
                            showingCreate = true
                        } label: {
                            Label("Create Integration", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach($manager.integrations) { $tool in
                            IntegrationCard(tool: $tool, manager: manager) {
                                editingTool = tool
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Integrations")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showingCreate = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            IntegrationEditorView(tool: nil)
        }
        .sheet(item: $editingTool) { tool in
            IntegrationEditorView(tool: tool)
        }
    }
}

private struct IntegrationCard: View {
    @Binding var tool: IntegrationTool
    @ObservedObject var manager: NotebooksManager
    let onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    LinearGradient(
                        colors: tool.isEnabled ? [.purple, .blue] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 44, height: 44)
                    .cornerRadius(12)
                    Image(systemName: "sparkles")
                        .font(.body)
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.name)
                        .font(.headline)
                    Text(tool.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: $tool.isEnabled)
                    .labelsHidden()
                    .onChange(of: tool.isEnabled) { _ in manager.saveIntegration(tool) }
            }

            HStack {
                Label("Custom Prompt", systemImage: "text.quote")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    onEdit()
                } label: {
                    Label("Edit", systemImage: "pencil")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(tool.isEnabled ? Color.purple.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
}

