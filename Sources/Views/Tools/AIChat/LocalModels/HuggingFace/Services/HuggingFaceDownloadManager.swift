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
    let modelName: String
    let fileName: String
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
    private let hfRootFolder: URL

    override init() {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.hfRootFolder = paths[0].appendingPathComponent("Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: hfRootFolder, withIntermediateDirectories: true)

        super.init()

        let config = URLSessionConfiguration.background(withIdentifier: "com.tools-kit.hf-downloader")
        self.session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        loadSavedTasks()
    }

    func downloadModel(_ model: HFModel) {
        Task {
            do {
                // Fetch full model details to get siblings (files)
                let details = try await HuggingFaceAPIClient.shared.fetchModelDetails(id: model.id)
                guard let bestGGUF = selectBestGGUF(from: details.siblings ?? []) else {
                    SDKLogStore.shared.log("HFDownloadManager: No suitable GGUF found for \(model.id)", source: "HuggingFaceDownloadManager", level: .error)
                    return
                }

                let downloadURL = URL(string: "https://huggingface.co/\(model.id)/resolve/main/\(bestGGUF)")!

                let task = HFDownloadTask(
                    id: model.id,
                    modelName: model.name,
                    fileName: bestGGUF,
                    downloadURL: downloadURL,
                    progress: 0,
                    status: .queued,
                    totalBytes: 0,
                    bytesReceived: 0
                )

                await MainActor.run {
                    activeDownloads[model.id] = task
                    saveTasks()
                }

                let downloadTask = session.downloadTask(with: downloadURL)
                downloadTask.resume()

                await MainActor.run {
                    activeDownloads[model.id]?.status = .downloading
                }

                SDKLogStore.shared.log("HFDownloadManager: Started download for \(model.id) - \(bestGGUF)", source: "HuggingFaceDownloadManager", level: .info)
            } catch {
                SDKLogStore.shared.log("HFDownloadManager: Failed to start download: \(error.localizedDescription)", source: "HuggingFaceDownloadManager", level: .error)
            }
        }
    }

    private func selectBestGGUF(from siblings: [HFModel.HFSibling]) -> String? {
        let ggufFiles = siblings.map { $0.rfilename }.filter { $0.lowercased().hasSuffix(".gguf") }
        guard !ggufFiles.isEmpty else { return nil }

        let ram = DeviceProfile.current().ramGB

        // Strategy:
        // > 16GB RAM: Q8_0 or Q6_K
        // > 8GB RAM: Q5_K_M or Q4_K_M
        // <= 8GB RAM: Q4_K_S or Q3_K_M

        var targets: [String] = []
        if ram > 16 {
            targets = ["q8_0", "q6_k_m", "q6_k", "q5_k_m"]
        } else if ram > 8 {
            targets = ["q5_k_m", "q4_k_m", "q4_0"]
        } else {
            targets = ["q4_k_s", "q3_k_m", "q2_k"]
        }

        // Add some fallbacks
        targets.append(contentsOf: ["q4_k_m", "q4_0", "q3_k_m"])

        for target in targets {
            if let found = ggufFiles.first(where: { $0.lowercased().contains(target) }) {
                return found
            }
        }

        return ggufFiles.first // Just return any GGUF if none of the targets match
    }

    func pauseDownload(id: String) {
        activeDownloads[id]?.status = .paused
        saveTasks()
    }

    func cancelDownload(id: String) {
        activeDownloads.removeValue(forKey: id)
        saveTasks()
    }

    func deleteDownloadedModel(id: String) {
        let modelFolder = hfRootFolder.appendingPathComponent(id.replacingOccurrences(of: "/", with: "_"), isDirectory: true)
        try? FileManager.default.removeItem(at: modelFolder)
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
        let taskPair = activeDownloads.first(where: { $0.value.downloadURL == sourceURL })
        guard let id = taskPair?.key, let task = taskPair?.value else { return }

        let modelFolder = hfRootFolder.appendingPathComponent(task.modelName, isDirectory: true)
        try? FileManager.default.createDirectory(at: modelFolder, withIntermediateDirectories: true)

        let destinationURL = modelFolder.appendingPathComponent(task.fileName)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)

            Task { @MainActor in
                activeDownloads[id]?.status = .completed
                activeDownloads[id]?.progress = 1.0
                saveTasks()

                let model = AIModel(id: id, name: task.modelName)
                if !AIChatSettingsManager.shared.settings.favoriteModels.contains(where: { $0.id == id }) {
                    AIChatSettingsManager.shared.settings.favoriteModels.append(model)
                }

                SDKLogStore.shared.log("HFDownloadManager: Successfully downloaded \(id) to \(destinationURL.path)", source: "HuggingFaceDownloadManager", level: .info)
            }
        } catch {
            Task { @MainActor in
                activeDownloads[id]?.status = .failed
                activeDownloads[id]?.error = error.localizedDescription
                saveTasks()
                SDKLogStore.shared.log("HFDownloadManager: Error moving file for \(id): \(error.localizedDescription)", source: "HuggingFaceDownloadManager", level: .error)
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
                // If it was cancelled by user, it might not be a "failure" in UI
                if (error as NSError).code == NSURLErrorCancelled {
                    // Handled by cancelDownload
                } else {
                    activeDownloads[id]?.status = .failed
                    activeDownloads[id]?.error = error.localizedDescription
                    saveTasks()
                    SDKLogStore.shared.log("HFDownloadManager: Download failed for \(id): \(error.localizedDescription)", source: "HuggingFaceDownloadManager", level: .error)
                }
            }
        }
    }
}
