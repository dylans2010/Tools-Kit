import SwiftUI

struct GistDetailView: View {
    let gistId: String
    @State private var gist: GitHubGist?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isStarred = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading Gist...")
            } else if let gist = gist {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(gist.description ?? "No description")
                                .font(.headline)

                            HStack {
                                Label("Created \(gist.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                                Spacer()
                                if !gist.public {
                                    Label("Private", systemImage: "lock.fill")
                                } else {
                                    Label("Public", systemImage: "globe")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }

                    Section("Files") {
                        ForEach(Array(gist.files.values), id: \.filename) { file in
                            NavigationLink(destination: GistFileContentView(file: file)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(file.filename)
                                        .font(.system(.subheadline, design: .monospaced))
                                    HStack {
                                        if let lang = file.language {
                                            Text(lang)
                                        }
                                        Text("\(file.size) bytes")
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            deleteGist()
                        } label: {
                            Label("Delete Gist", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Gist Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    toggleStar()
                } label: {
                    Image(systemName: isStarred ? "star.fill" : "star")
                        .foregroundStyle(isStarred ? .yellow : .accentColor)
                }

                if let gist = gist {
                    NavigationLink(destination: GistEditorView(gist: gist)) {
                        Text("Edit")
                    }
                }
            }
        }
        .task {
            await fetchGist()
            await checkStarred()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
    }

    private func fetchGist() async {
        isLoading = true
        do {
            gist = try await GitHubAPIClient.shared.request(.gistDetails(id: gistId))
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func checkStarred() async {
        do {
            try await GitHubAPIClient.shared.requestEmpty(.checkGistStarred(id: gistId))
            isStarred = true
        } catch {
            isStarred = false
        }
    }

    private func toggleStar() {
        Task {
            do {
                if isStarred {
                    try await GitHubAPIClient.shared.requestEmpty(.unstarGist(id: gistId))
                    isStarred = false
                } else {
                    try await GitHubAPIClient.shared.requestEmpty(.starGist(id: gistId))
                    isStarred = true
                }
            } catch {
                errorMessage = "Failed to update star status"
            }
        }
    }

    private func deleteGist() {
        Task {
            do {
                try await GitHubAPIClient.shared.requestEmpty(.deleteGist(id: gistId))
                // Pop view
            } catch {
                errorMessage = "Failed to delete gist"
            }
        }
    }
}

struct GistFileContentView: View {
    let file: GitHubGistFile
    @State private var content: String = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            if isLoading {
                ProgressView().padding()
            } else {
                Text(content)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle(file.filename)
        .task {
            await fetchContent()
        }
    }

    private func fetchContent() async {
        if let existing = file.content {
            content = existing
            return
        }

        guard let urlString = file.rawUrl, let url = URL(string: urlString) else { return }
        isLoading = true
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            content = String(data: data, encoding: .utf8) ?? "Unable to load content"
            isLoading = false
        } catch {
            content = "Error loading content: \(error.localizedDescription)"
            isLoading = false
        }
    }
}
