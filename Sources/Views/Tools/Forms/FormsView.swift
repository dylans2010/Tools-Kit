import SwiftUI
import UniformTypeIdentifiers

struct FormsView: View {
    @StateObject private var backend = FormsBackend.shared
    @State private var showingCreate = false
    @State private var showingTemplates = false
    @State private var showingImport = false
    @State private var formToDelete: FormDocument?
    @State private var showDeleteConfirm = false
    @State private var searchText = ""

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    private var recentForms: [FormDocument] {
        Array(filteredForms.prefix(4))
    }

    private var filteredForms: [FormDocument] {
        guard !searchText.isEmpty else { return backend.forms }
        return backend.forms.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
            || $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                heroHeader

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
                .padding(.horizontal)

                if filteredForms.isEmpty {
                    EmptyStateView(
                        icon: "list.bullet.rectangle.portrait",
                        title: searchText.isEmpty ? "No Forms Yet" : "No Results",
                        message: searchText.isEmpty
                            ? "Create a form, pick a template, or import a .form file."
                            : "No forms match your search.",
                        action: searchText.isEmpty ? { showingCreate = true } : nil,
                        actionLabel: "Create Form"
                    )
                } else {
                    // When searching or when there are more forms than the 4-form recent cap, show a flat "All Forms" list.
                    let showFlatList = !searchText.isEmpty || filteredForms.count > recentForms.count
                    if showFlatList {
                        // Show all forms in one grid
                        sectionHeader("All Forms", count: filteredForms.count, icon: "list.bullet.rectangle.portrait")
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(filteredForms) { form in
                                formCard(for: form)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Recent forms
                        if !recentForms.isEmpty {
                            sectionHeader("Recent", count: recentForms.count, icon: "clock")
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(recentForms) { form in
                                    formCard(for: form)
                                }
                            }
                            .padding(.horizontal)
                        }

                        // All forms (if more than recent)
                        if filteredForms.count > recentForms.count {
                            sectionHeader("All Forms", count: filteredForms.count, icon: "list.bullet.rectangle.portrait")
                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(filteredForms) { form in
                                    formCard(for: form)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Forms")
        .searchable(text: $searchText, prompt: "Search forms…")
        .background(Color(.systemGroupedBackground))
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
                if let form = formToDelete { backend.remove(form) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Forms Studio")
                        .font(.title2.bold())
                    Text("Create, ship, import, review, and export secure `.form` workflows.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(backend.forms.count)")
                    .font(.headline.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Capsule())
            }
            HStack(spacing: 8) {
                quickTag("Owner-safe Imports", icon: "lock.shield", color: .indigo)
                quickTag("Manifest Metadata", icon: "doc.badge.gearshape", color: .orange)
                quickTag("Attachment Aware", icon: "paperclip", color: .purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func formCard(for form: FormDocument) -> some View {
        NavigationLink(destination: FormDetailView(form: form, backend: backend)) {
            FormCard(form: form) {
                formToDelete = form
                showDeleteConfirm = true
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                formToDelete = form
                showDeleteConfirm = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private func sectionHeader(_ title: String, count: Int, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .font(.caption)
            Text(title)
                .font(.headline)
            Text("(\(count))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 4)
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
            .padding(.vertical, 14)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
    }

    private func quickTag(_ title: String, icon: String, color: Color) -> some View {
        Label(title, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

// MARK: - Form Card

private struct FormCard: View {
    let form: FormDocument
    let onDelete: () -> Void

    private var accentColor: Color {
        Color(hex: form.accentHexColor)
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
