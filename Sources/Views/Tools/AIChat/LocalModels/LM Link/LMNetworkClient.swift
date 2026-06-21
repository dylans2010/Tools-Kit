import Foundation

class LMNetworkClient {
    private let signer = LMRequestSigner()

    func request<T: Decodable>(_ url: URL, method: String = "GET", body: Data? = nil, timeout: TimeInterval = 10) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = body
            try signer.addSignatureHeaders(to: &request, payload: body)
        } else {
            // Sign empty payload for GET if required by protocol
            try signer.addSignatureHeaders(to: &request, payload: Data())
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "LMNetworkClient", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server returned \(httpResponse.statusCode)"])
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    func postRaw(_ url: URL, body: Data, timeout: TimeInterval = 30) async throws -> (Data, URLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = timeout
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = body
        try signer.addSignatureHeaders(to: &request, payload: body)

        return try await URLSession.shared.data(for: request)
    }
}
