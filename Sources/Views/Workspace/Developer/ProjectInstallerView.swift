import SwiftUI
import UniformTypeIdentifiers

public class ProjectInstallManager: ObservableObject {
    public static let shared = ProjectInstallManager()

    private init() {}

    public func install(from url: URL) throws {
        // Awaiting backend integration for project installation logic
    }
}

struct ProjectInstallerView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingFilePicker = false
    @State private var error: String?
    @State private var success = false

    var body: some View {
        VStack(spacing: 24) {
            if success {
                successView
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.accent)

                    Text("Install Project")
                        .font(.title2.bold())

                    Text("Select a .tkproj file to import an existing project into your workspace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        showingFilePicker = true
                    } label: {
                        Label("Select Project File", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.top, 8)
                }
            }

            if let error = error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .navigationTitle("Installer")
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
