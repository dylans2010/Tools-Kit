import SwiftUI
import UniformTypeIdentifiers

struct FormsView: View {
    @StateObject private var backend = FormsBackend()
    @State private var showingCreate = false
    @State private var showingTemplates = false
    @State private var showingImport = false
    @State private var formToDelete: FormDocument?
    @State private var showDeleteConfirm = false

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    var body: some View {
        ToolDetailView(tool: FormsTool()) {
            VStack(spacing: 20) {
                // Action bar
                HStack(spacing: 10) {
                    actionButton("Create", icon: "plus.circle.fill", color: .blue) {
                        showingCreate = true
                    }
                    actionButton("Templates", icon: "doc.on.doc", color: .purple) {
                        showingTemplates = true
                    }
                    actionButton("Import", icon: "tray.and.arrow.down", color: .green) {
                        showingImport = true
                    }
                }

                // Forms grid
                if backend.forms.isEmpty {
                    ContentUnavailableView(
                        "No Forms Yet",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Create a new form, pick a template, or import a .form file.")
                    )
                    .padding(.vertical, 24)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(
                            title: "Your Forms",
                            subtitle: "\(backend.forms.count)",
                            icon: "list.bullet.rectangle.portrait"
                        )

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(backend.forms) { form in
                                NavigationLink(destination: FormDetailView(form: form, backend: backend)) {
                                    FormCard(form: form) {
                                        formToDelete = form
                                        showDeleteConfirm = true
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingCreate) {
            NavigationStack { CreateFormView(backend: backend) }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingTemplates) {
            NavigationStack { FormTemplatesView(backend: backend) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingImport) {
            NavigationStack { ImportFormView(backend: backend) }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Delete \(formToDelete?.name ?? "")?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let form = formToDelete {
                    backend.remove(form)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }

    private func actionButton(_ title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Form Card

private struct FormCard: View {
    let form: FormDocument
    let onDelete: () -> Void

    private var accentColor: Color {
        Color(hex: form.accentHexColor) ?? .blue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.title2)
                    .foregroundColor(accentColor)
                Spacer()
                Button {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            Text(form.name.isEmpty ? "Untitled" : form.name)
                .font(.subheadline.bold())
                .lineLimit(2)

            if !form.description.isEmpty {
                Text(form.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Label("\(form.questions.count)", systemImage: "questionmark.circle")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text(form.manifest.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(minHeight: 120)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }
}

struct FormsTool: Tool {
    let name = "Forms"
    let icon = "list.bullet.rectangle.portrait"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Build, style, import/export, and review secure .form files"
    let requiresAPI = false
    var view: AnyView { AnyView(FormsView()) }
}
