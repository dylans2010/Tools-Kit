import Foundation
import ZIPFoundation

class FinishedFetch {
    func createZip(from urls: [URL]) async throws -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let zipURL = documentsURL.appendingPathComponent("Songs.zip")

        if FileManager.default.fileExists(atPath: zipURL.path) {
            try FileManager.default.removeItem(at: zipURL)
        }

        guard let archive = Archive(url: zipURL, accessMode: .create) else {
            throw NSError(domain: "FinishedFetch", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create ZIP archive"])
        }

        for url in urls {
            try archive.addEntry(with: url.lastPathComponent, relativeTo: url.deletingLastPathComponent())
        }

        return zipURL
    }
}
