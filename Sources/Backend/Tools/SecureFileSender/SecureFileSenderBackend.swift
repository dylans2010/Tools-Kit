import Foundation

struct UploadResult: Identifiable {
    let id = UUID()
    let filename: String
    let link: String
    let expiry: String
    let size: Int
    let uploadedAt: Date
}

private struct FileIOResponse: Codable {
    let success: Bool?
    let key: String?
    let link: String?
    let expiry: String?
    let size: Int?
}

@MainActor
final class SecureFileSenderBackend: ObservableObject {
    @Published var selectedFileURL: URL?
    @Published var selectedFileName = ""
    @Published var selectedFileSize: Int = 0
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var uploadResult: UploadResult?
    @Published var errorMessage = ""
    @Published var history: [UploadResult] = []
    @Published var expiryOption = "1d"

    let expiryOptions = ["1h", "6h", "12h", "1d", "3d", "7d", "14d"]

    init() {
        loadHistory()
    }

    func selectFile(url: URL) {
        selectedFileURL = url
        selectedFileName = url.lastPathComponent
        selectedFileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    func upload() async {
        guard let fileURL = selectedFileURL else {
            errorMessage = "No file selected"
            return
        }

        isUploading = true
        uploadProgress = 0
        errorMessage = ""
        uploadResult = nil

        guard let uploadURL = URL(string: "https://file.io/?expires=\(expiryOption)") else {
            errorMessage = "Upload service unavailable"
            isUploading = false
            return
        }

        do {
            let fileData = try Data(contentsOf: fileURL)
            let boundary = "Boundary-\(UUID().uuidString)"
            var body = Data()

            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(selectedFileName)\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
            body.append(fileData)
            body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

            var request = URLRequest(url: uploadURL)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = body

            uploadProgress = 0.5
            let (data, response) = try await URLSession.shared.data(for: request)
            uploadProgress = 0.9

            let httpResponse = response as? HTTPURLResponse
            guard let statusCode = httpResponse?.statusCode, (200...299).contains(statusCode) else {
                errorMessage = "Upload failed – HTTP \(httpResponse?.statusCode ?? 0)"
                isUploading = false
                return
            }

            let decoded = try JSONDecoder().decode(FileIOResponse.self, from: data)
            guard let link = decoded.link else {
                errorMessage = "No link in response"
                isUploading = false
                return
            }

            let result = UploadResult(
                filename: selectedFileName,
                link: link,
                expiry: expiryOption,
                size: fileData.count,
                uploadedAt: Date()
            )
            uploadResult = result
            history.insert(result, at: 0)
            if history.count > 20 { history.removeLast() }
            saveHistory()
            uploadProgress = 1.0

        } catch {
            errorMessage = error.localizedDescription
        }
        isUploading = false
    }

    private func saveHistory() {
        let encoded = history.map { r in
            ["filename": r.filename, "link": r.link, "expiry": r.expiry,
             "size": "\(r.size)", "date": "\(r.uploadedAt.timeIntervalSince1970)"]
        }
        UserDefaults.standard.set(encoded, forKey: "secureFileSenderHistory")
    }

    private func loadHistory() {
        guard let raw = UserDefaults.standard.array(forKey: "secureFileSenderHistory") as? [[String: String]] else { return }
        history = raw.compactMap { dict in
            guard let filename = dict["filename"], let link = dict["link"],
                  let expiry = dict["expiry"], let sizeStr = dict["size"],
                  let size = Int(sizeStr), let dateStr = dict["date"],
                  let ts = Double(dateStr) else { return nil }
            return UploadResult(filename: filename, link: link, expiry: expiry, size: size, uploadedAt: Date(timeIntervalSince1970: ts))
        }
    }
}
