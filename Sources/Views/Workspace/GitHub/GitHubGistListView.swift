import SwiftUI

struct GitHubGistListView: View {
    @State private var gists: [GitHubGist] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading && gists.isEmpty {
                ProgressView("Fetching Gists...")
            } else if gists.isEmpty {
                ContentUnavailableView(
                    "No Gists Found",
                    systemImage: "doc.plaintext",
                    description: Text("Create your first Gist on GitHub to see it here.")
                )
            } else {
                List(gists) { gist in
                    NavigationLink(destination: GistDetailView(gistId: gist.id)) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(.secondary)
                            Text(gist.description ?? "No description")
                                .font(.subheadline.bold())
                                .lineLimit(1)
                            Spacer()
                            if !gist.public {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        let files = Array(gist.files.values)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(files, id: \.filename) { file in
                                    HStack(spacing: 4) {
                                        Image(systemName: "doc.append")
                                        Text(file.filename)
                                    }
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                }
                            }
                        }

                        HStack {
                            Text("Created \(gist.createdAt.formatted(date: .abbreviated, time: .omitted))")
                            Spacer()
                            Text("\(gist.files.count) files")
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 6)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await fetchGists()
                }
            }
        }
        .navigationTitle("Your Gists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: GistEditorView()) {
                    Image(systemName: "plus")
                }
            }
        }
        .task {
            await fetchGists()
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Unknown Error")
        }
    }

    private func fetchGists() async {
        isLoading = true
        do {
            let fetched: [GitHubGist] = try await GitHubAPIClient.shared.request(.gists)
            await MainActor.run {
                self.gists = fetched
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
