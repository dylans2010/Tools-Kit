import SwiftUI

/// Exports a FormDocument as a `.form` file and presents a system share sheet.
struct ExportFormView: View {
    let form: FormDocument
    @Environment(\.dismiss) private var dismiss

    @State private var exportURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                VStack(spacing: 8) {
                    Text("Export Form")
                        .font(.title2.bold())
                    Text("Save "\(form.name)" as a `.form` file you can share or import later.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let exportURL {
                    ShareLink(item: exportURL) {
                        Label("Share "\(form.name).form"", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .padding(.horizontal, 24)
                    }
                } else {
                    Button {
                        generateExport()
                    } label: {
                        Label("Prepare Export", systemImage: "gearshape.2")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .padding(.horizontal, 24)
                    }
                }

                Spacer()
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { generateExport() }
        }
    }

    private func generateExport() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(form.name).form")
        do {
            try FormFileManager.exportForm(form, to: url)
            exportURL = url
            errorMessage = nil
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
