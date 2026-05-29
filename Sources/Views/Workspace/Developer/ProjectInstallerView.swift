import SwiftUI
import UniformTypeIdentifiers

struct ProjectInstallerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingFilePicker = false
    @State private var error: String?
    @State private var success = false

    var body: some View {
        VStack(spacing: 24) {
            header

            if success {
                successView
            } else {
                installView
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.and.arrow.down.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
            Text("Project Installer")
                .font(.title2.bold())
            Text("Install .tkproj files instantly without authentication.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private var installView: some View {
        VStack(spacing: 20) {
            Button {
                showingFilePicker = true
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                    Text("Select .tkproj file")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6]))
                        .foregroundStyle(.secondary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button("Cancel") {
                dismiss()
            }
            .foregroundStyle(.secondary)
        }
        .sheet(isPresented: $showingFilePicker) {
            FileImporterView(
                allowedContentTypes: [UTType(filenameExtension: "tkproj") ?? .data],
                allowsMultipleSelection: false
            ) { urls in
                showingFilePicker = false
                if let url = urls.first {
                    guard url.startAccessingSecurityScopedResource() else {
                        self.error = "Failed to access the selected file."
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    do {
                        try ProjectInstallManager.shared.install(from: url)
                        success = true
                    } catch {
                        self.error = "Failed to install project: \(error.localizedDescription)"
                    }
                }
            }
        }
    }

    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Installation Complete")
                .font(.headline)
            Text("The project has been successfully imported and is ready to use.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
    }
}
