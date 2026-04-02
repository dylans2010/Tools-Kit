import Foundation
import LinkPresentation
import SwiftUI

struct LinkMetadata: Identifiable {
    let id = UUID()
    let title: String?
    let icon: UIImage?
    let url: URL
}

class LinkPreviewBackend: ObservableObject {
    @Published var urlString = ""
    @Published var metadata: LinkMetadata? = nil
    @Published var isLoading = false
    @Published var error: String? = nil

    func fetch() {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        let formatted = trimmed.hasPrefix("http") ? trimmed : "https://\(trimmed)"

        guard let url = URL(string: formatted) else {
            error = "Invalid URL"
            return
        }

        isLoading = true
        error = nil
        metadata = nil

        let provider = LPMetadataProvider()
        provider.startFetchingMetadata(for: url) { metadata, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.error = error.localizedDescription
                }
                return
            }

            if let metadata = metadata {
                if let iconProvider = metadata.iconProvider {
                    iconProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        DispatchQueue.main.async {
                            self.metadata = LinkMetadata(
                                title: metadata.title,
                                icon: image as? UIImage,
                                url: url
                            )
                            self.isLoading = false
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.metadata = LinkMetadata(
                            title: metadata.title,
                            icon: nil,
                            url: url
                        )
                        self.isLoading = false
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}
