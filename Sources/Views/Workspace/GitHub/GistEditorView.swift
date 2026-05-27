import SwiftUI

struct GistEditorView: View {
    @Environment(\.dismiss) var dismiss

    var gist: GitHubGist? // nil if creating new

    @State private var description: String = ""
    @State private var files: [GistFileEdit] = [GistFileEdit()]
    @State private var isPublic: Bool = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    struct GistFileEdit: Identifiable {
        let id = UUID()
        var filename: String = ""
        var content: String = ""
    }

    init(gist: GitHubGist? = nil) {
        self.gist = gist
        if let gist = gist {
            _description = State(initialValue: gist.description ?? "")
            _isPublic = State(initialValue: gist.public)
            let edits = gist.files.values.map { GistFileEdit(filename: $0.filename, content: $0.content ?? "") }
            _files = State(initialValue: edits.isEmpty ? [GistFileEdit()] : edits)
        }
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Description", text: $description)
                Toggle("Public", isOn: $isPublic)
                    .disabled(gist != nil) // GitHub doesn't allow changing visibility after creation
            }

            ForEach($files) { $file in
                Section {
                    TextField("Filename (e.g. script.swift)", text: $file.filename)
                        .font(.system(.subheadline, design: .monospaced))
                    TextEditor(text: $file.content)
                        .font(.system(.caption, design: .monospaced))
                        .frame(minHeight: 200)
                } header: {
                    HStack {
                        Text("File")
                        Spacer()
                        if files.count > 1 {
                            Button(role: .destructive) {
                                files.removeAll { $0.id == file.id }
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    files.append(GistFileEdit())
                } label: {
                    Label("Add File", systemImage: "plus")
                }
            }
        }
        .navigationTitle(gist == nil ? "New Gist" : "Edit Gist")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    saveGist()
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
                .disabled(isSaving || files.first?.filename.isEmpty ?? true)
            }

            if gist == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
        .task {
            if let gist = gist {
                await loadFileContents(gist: gist)
            }
        }
    }

    private func loadFileContents(gist: GitHubGist) async {
        var updatedFiles: [GistFileEdit] = []
        for file in gist.files.values {
            var content = file.content ?? ""
            if content.isEmpty, let rawUrl = file.rawUrl, let url = URL(string: rawUrl) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    content = String(data: data, encoding: .utf8) ?? ""
                } catch {}
            }
            updatedFiles.append(GistFileEdit(filename: file.filename, content: content))
        }
        if !updatedFiles.isEmpty {
            self.files = updatedFiles
        }
    }

    private func saveGist() {
        isSaving = true

        struct GistPayload: Encodable {
            let description: String
            let `public`: Bool
            let files: [String: [String: String]]
        }

        var filesPayload: [String: [String: String]] = [:]
        for file in files {
            if !file.filename.isEmpty {
                filesPayload[file.filename] = ["content": file.content]
            }
        }

        let payload = GistPayload(description: description, public: isPublic, files: filesPayload)

        Task {
            do {
                if let gist = gist {
                    let _: GitHubGist = try await GitHubAPIClient.shared.request(.updateGist(id: gist.id), body: payload)
                } else {
                    let _: GitHubGist = try await GitHubAPIClient.shared.request(.createGist, body: payload)
                }
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
