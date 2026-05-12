import Foundation
import Combine

struct RouterRegion: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let endpoint: String
    let flag: String
}

@MainActor
final class SecureRouterBackend: ObservableObject {
    @Published var customEndpoint = ""
    @Published var selectedRegion: RouterRegion?
    @Published var retryCount: Int = 3
    @Published var isEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "secureRouterEnabled")
            applyToNetworkClient()
        }
    }
    @Published var testResult = ""
    @Published var isTesting = false
    @Published var lastPingMs: Int = 0

    let regions: [RouterRegion] = [
        RouterRegion(id: "cloudflare", name: "Cloudflare", endpoint: "https://1.1.1.1", flag: "🌐"),
        RouterRegion(id: "google",    name: "Google",     endpoint: "https://8.8.8.8",  flag: "🔵"),
        RouterRegion(id: "quad9",     name: "Quad9",      endpoint: "https://9.9.9.9",  flag: "🟣"),
        RouterRegion(id: "custom",    name: "Custom",     endpoint: "",                 flag: "⚙️")
    ]

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "secureRouterEnabled")
        self.selectedRegion = regions.first
    }

    var activeEndpoint: String {
        if selectedRegion?.id == "custom" { return customEndpoint }
        return selectedRegion?.endpoint ?? ""
    }

    func testConnectivity() async {
        guard !activeEndpoint.isEmpty, let url = URL(string: activeEndpoint) else {
            testResult = "Invalid endpoint URL"
            return
        }
        isTesting = true
        testResult = ""
        let start = Date()
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 10
            _ = try await URLSession.shared.data(for: request)
            lastPingMs = Int(Date().timeIntervalSince(start) * 1000)
            testResult = "✅ Reachable – \(lastPingMs)ms"
        } catch {
            testResult = "❌ Unreachable – \(error.localizedDescription)"
        }
        isTesting = false
    }

    func sendTestRequest(through endpoint: String, target: String) async throws -> String {
        guard let targetURL = URL(string: target) else { throw URLError(.badURL) }
        var request = URLRequest(url: targetURL)
        request.timeoutInterval = 30
        var attempts = 0
        var lastError: Error?
        while attempts <= retryCount {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                let status = (response as? HTTPURLResponse)?.statusCode ?? 0
                return "Status \(status) – \(data.count) bytes"
            } catch {
                lastError = error
                attempts += 1
                if attempts <= retryCount {
                    try await Task.sleep(nanoseconds: 500_000_000)
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    private func applyToNetworkClient() {
        // Integration point: in a full implementation the NetworkClient's
        // RoutingMiddleware would be toggled here.
    }
}
