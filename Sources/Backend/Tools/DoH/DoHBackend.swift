import Foundation

enum DoHProvider: String, CaseIterable, Identifiable, Sendable {
    case cloudflare = "Cloudflare"
    case google = "Google"

    var id: String { rawValue }

    var baseURL: String {
        switch self {
        case .cloudflare: return "https://cloudflare-dns.com/dns-query"
        case .google: return "https://dns.google/resolve"
        }
    }
}

enum DoHRecordType: String, CaseIterable, Identifiable, Sendable {
    case a = "A"
    case aaaa = "AAAA"
    case mx = "MX"
    case txt = "TXT"
    case cname = "CNAME"
    case ns = "NS"
    case soa = "SOA"

    var id: String { rawValue }

    var numericType: Int {
        switch self {
        case .a: return 1
        case .ns: return 2
        case .cname: return 5
        case .soa: return 6
        case .mx: return 15
        case .txt: return 16
        case .aaaa: return 28
        }
    }
}

struct DoHRecord: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let type: String
    let ttl: Int
    let data: String
}

struct DoHRawResponse: Codable, Sendable {
    let Status: Int?
    let Answer: [DoHRawRecord]?
    let Question: [DoHQuestion]?
}

struct DoHRawRecord: Codable, Sendable {
    let name: String
    let type: Int
    let TTL: Int
    let data: String
}

struct DoHQuestion: Codable, Sendable {
    let name: String
    let type: Int
}

@MainActor
final class DoHBackend: ObservableObject {
    @Published var domain = ""
    @Published var selectedProvider: DoHProvider = .cloudflare
    @Published var selectedRecordType: DoHRecordType = .a
    @Published var records: [DoHRecord] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var responseTimeMs: Int = 0

    func lookup() async {
        let trimmed = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        isLoading = true
        errorMessage = ""
        records = []

        var components = URLComponents(string: selectedProvider.baseURL)!
        components.queryItems = [
            URLQueryItem(name: "name", value: trimmed),
            URLQueryItem(name: "type", value: selectedRecordType.rawValue)
        ]

        guard let url = components.url else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        var request = URLRequest(url: url)
        request.setValue("application/dns-json", forHTTPHeaderField: "Accept")

        let start = Date()
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            responseTimeMs = Int(Date().timeIntervalSince(start) * 1000)
            let response = try JSONDecoder().decode(DoHRawResponse.self, from: data)
            if let status = response.Status, status != 0 {
                errorMessage = "DNS error – RCODE \(status)"
            } else {
                records = (response.Answer ?? []).map { raw in
                    DoHRecord(
                        name: raw.name,
                        type: recordTypeName(raw.type),
                        ttl: raw.TTL,
                        data: raw.data
                    )
                }
                if records.isEmpty {
                    errorMessage = "No records found"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func recordTypeName(_ type: Int) -> String {
        DoHRecordType.allCases.first { $0.numericType == type }?.rawValue ?? "\(type)"
    }
}
