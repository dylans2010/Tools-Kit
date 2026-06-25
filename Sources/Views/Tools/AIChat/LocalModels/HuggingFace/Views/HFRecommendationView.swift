import SwiftUI

struct HFRecommendationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recommendations: [HFRecommendation] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Analyzing device and generating recommendations...")
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Retry") {
                            loadRecommendations()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List(recommendations) { rec in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(rec.model_title)
                                .font(.headline)
                            Text(rec.model_description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Why this model?")
                                    .font(.caption.bold())
                                    .foregroundColor(.blue)
                                Text(rec.model_why_recommendation)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(8)

                            Button {
                                downloadModel(rec)
                            } label: {
                                Label("Download GGUF", systemImage: "icloud.and.arrow.down")
                                    .font(.subheadline.bold())
                            }
                            .buttonStyle(.bordered)
                            .padding(.top, 4)
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                loadRecommendations()
            }
        }
    }

    private func loadRecommendations() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let recs = try await HuggingFaceRecommendationService.shared.getRecommendations()
                await MainActor.run {
                    self.recommendations = recs
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

    private func downloadModel(_ rec: HFRecommendation) {
        // Create a dummy HFModel to trigger download
        let model = HFModel(
            id: rec.model_link,
            author: rec.model_link.components(separatedBy: "/").first,
            lastModified: nil,
            likes: nil,
            downloads: nil,
            tags: ["gguf"],
            siblings: nil
        )
        HuggingFaceDownloadManager.shared.downloadModel(model)
        dismiss()
    }
}
