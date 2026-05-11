import SwiftUI

struct GitHubCodeEditorWorkspaceView: View {
    let filePath: String
    @State private var content: String = ""
    @State private var originalContent: String = ""
    @State private var hasUnsavedChanges = false
    @State private var showingDiff = false
    @State private var errorMessage: String?

    @ObservedObject private var gitEngine = GitEngineService.shared

    var body: some View {
        VStack(spacing: 0) {
            editorToolbar

            TextEditor(text: $content)
                .font(.system(.body, design: .monospaced))
                .padding(4)
                .onChange(of: content) { _, newValue in
                    hasUnsavedChanges = newValue != originalContent
                }
        }
        .navigationTitle(URL(fileURLWithPath: filePath).lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Stage") {
                    showingDiff = true
                }
                .disabled(!hasUnsavedChanges)
            }
        }
        .sheet(isPresented: $showingDiff) {
            diffPreview
        }
        .alert("File Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            loadRealContent()
        }
    }

    private var editorToolbar: some View {
        HStack {
            Text(filePath)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            if hasUnsavedChanges {
                Text("Unsaved Changes")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
    }

    private var diffPreview: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Proposed Changes").font(.headline).padding(.horizontal)

                    DiffView(original: originalContent, modified: content)
                        .padding()
                }
            }
            .navigationTitle("Structured Diff")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingDiff = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Staging") {
                        saveAndStage()
                    }
                }
            }
        }
    }

    private func loadRealContent() {
        let fm = FileManager.default
        // In this environment, we check if the file exists in the sandbox
        if fm.fileExists(atPath: filePath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
                if let str = String(data: data, encoding: .utf8) {
                    self.content = str
                    self.originalContent = str
                }
            } catch {
                self.errorMessage = "Failed to read file: \(error.localizedDescription)"
            }
        } else {
            self.errorMessage = "File not found at path: \(filePath)"
            self.content = ""
            self.originalContent = ""
        }
    }

    private func saveAndStage() {
        gitEngine.stageChange(filePath: filePath, original: originalContent, modified: content)
        originalContent = content
        hasUnsavedChanges = false
        showingDiff = false
    }
}
