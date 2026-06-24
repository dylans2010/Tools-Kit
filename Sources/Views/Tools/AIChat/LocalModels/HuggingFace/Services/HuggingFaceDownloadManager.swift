import Foundation
import Combine

enum DownloadState: String, Codable {
    case queued
    case downloading
    case paused
    case completed
    case failed
}

struct HFDownloadTask: Identifiable, Codable {
    let id: String // Model ID
    let downloadURL: URL
    var progress: Double
    var status: DownloadState
    var totalBytes: Int64
    var bytesReceived: Int64
    var error: String?
}

@MainActor
class HuggingFaceDownloadManager: NSObject, ObservableObject {
    static let shared = HuggingFaceDownloadManager()

    @Published var activeDownloads: [String: HFDownloadTask] = [:]
    private var session: URLSession!
    private let downloadFolder: URL

    override init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.downloadFolder = paths[0].appendingPathComponent("HFModels", isDirectory: true)
        try? FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "com.tools-kit.hf-downloader")
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        loadSavedTasks()
    }

    func downloadModel(_ model: HFModel) {
        Task {
            var modelWithDetails = model
            if model.siblings == nil || model.siblings?.isEmpty == true {
                do {
                    modelWithDetails = try await HuggingFaceAPIClient.shared.fetchModelDetails(id: model.id)
                } catch {
                    SDKLogStore.shared.log("Failed to fetch model details for download: \(error)", source: "HFDownloadManager", level: .error)
                    return
                }
            }

            guard let fileName = selectBestGGUF(model: modelWithDetails) else {
                SDKLogStore.shared.log("No suitable GGUF found for \(model.id)", source: "HFDownloadManager", level: .error)
                return
            }

            guard let url = URL(string: "https://huggingface.co/\(model.id)/resolve/main/\(fileName)") else { return }

            let task = HFDownloadTask(
                id: model.id,
                downloadURL: url,
                progress: 0,
                status: .queued,
                totalBytes: 0,
                bytesReceived: 0
            )

            activeDownloads[model.id] = task
            saveTasks()

            let downloadTask = session.downloadTask(with: url)
            downloadTask.resume()

            activeDownloads[model.id]?.status = .downloading
        }
    }

    private func selectBestGGUF(model: HFModel) -> String? {
        guard let siblings = model.siblings else { return nil }
        let ggufFiles = siblings.map { $0.rfilename }.filter { $0.lowercased().hasSuffix(".gguf") }
        guard !ggufFiles.isEmpty else { return nil }

        let profile = DeviceProfile.current()
        let ram = profile.ramGB

        // Preference order based on RAM
        let preferredQuants: [String]
        if ram >= 16 {
            preferredQuants = ["Q8_0", "Q6_K", "Q5_K_M", "Q4_K_M"]
        } else if ram >= 12 {
            preferredQuants = ["Q6_K", "Q5_K_M", "Q4_K_M", "Q3_K_M"]
        } else if ram >= 8 {
            preferredQuants = ["Q5_K_M", "Q4_K_M", "Q3_K_M"]
        } else {
            preferredQuants = ["Q4_K_M", "Q3_K_M", "Q2_K"]
        }

        for quant in preferredQuants {
            if let found = ggufFiles.first(where: { $0.contains(quant) }) {
                return found
            }
        }

        // If no preferred quant matches, try to find any "Q4" or "Q5" as they are usually good balances
        if let found = ggufFiles.first(where: { $0.contains("Q4") }) { return found }
        if let found = ggufFiles.first(where: { $0.contains("Q5") }) { return found }

        // Fallback to the first GGUF found if no preferred quant matches
        return ggufFiles.first
    }

    func pauseDownload(id: String) {
        // Implementation for pausing would go here
        activeDownloads[id]?.status = .paused
        saveTasks()
    }

    func cancelDownload(id: String) {
        activeDownloads.removeValue(forKey: id)
        saveTasks()
    }

    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(activeDownloads) {
            UserDefaults.standard.set(encoded, forKey: "HFActiveDownloads")
        }
    }

    private func loadSavedTasks() {
        if let data = UserDefaults.standard.data(forKey: "HFActiveDownloads"),
           let decoded = try? JSONDecoder().decode([String: HFDownloadTask].self, from: data) {
            self.activeDownloads = decoded
        }
    }
}

extension HuggingFaceDownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }

        // Find the task matching this URL
        let taskId = activeDownloads.values.first(where: { $0.downloadURL == sourceURL })?.id

        guard let id = taskId else { return }

        let destinationURL = downloadFolder.appendingPathComponent("\(id.replacingOccurrences(of: "/", with: "_")).gguf")

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)

            Task { @MainActor in
                activeDownloads[id]?.status = .completed
                activeDownloads[id]?.progress = 1.0
                saveTasks()

                // Add to favorite models/local configs automatically?
                // For now just keep it in completed state.
                let model = AIModel(id: id, name: id.components(separatedBy: "/").last ?? id)
                AIChatSettingsManager.shared.settings.favoriteModels.append(model)
            }
        } catch {
            Task { @MainActor in
                activeDownloads[id]?.status = .failed
                activeDownloads[id]?.error = error.localizedDescription
                saveTasks()
            }
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let sourceURL = downloadTask.originalRequest?.url else { return }
        let taskId = activeDownloads.values.first(where: { $0.downloadURL == sourceURL })?.id
        guard let id = taskId else { return }

        Task { @MainActor in
            activeDownloads[id]?.bytesReceived = totalBytesWritten
            activeDownloads[id]?.totalBytes = totalBytesExpectedToWrite
            activeDownloads[id]?.progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            activeDownloads[id]?.status = .downloading
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            guard let sourceURL = task.originalRequest?.url else { return }
            let taskId = activeDownloads.values.first(where: { $0.downloadURL == sourceURL })?.id
            guard let id = taskId else { return }

            Task { @MainActor in
                activeDownloads[id]?.status = .failed
                activeDownloads[id]?.error = error.localizedDescription
                saveTasks()
            }
        }
    }
}
