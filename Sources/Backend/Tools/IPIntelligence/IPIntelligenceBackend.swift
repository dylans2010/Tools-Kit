import Foundation

struct IPIntelligenceData: Sendable {
    let ip: String
    let country: String
    let region: String
    let city: String
    let zip: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    let isp: String
    let org: String
    let asNumber: String
    let isProxy: Bool
    let isHosting: Bool
    let isMobile: Bool
}

private struct FreeIPAPIResponse: Codable, Sendable {
    let ipVersion: Int?
    let ipAddress: String?
    let latitude: Double?
    let longitude: Double?
    let countryName: String?
    let countryCode: String?
    let timeZone: String?
    let zipCode: String?
    let cityName: String?
    let regionName: String?
    let isProxy: Bool?
    let isCrawler: Bool?
    let isAnycast: Bool?
    let continent: String?
    let continentCode: String?
    let isMobile: Bool?
    let isHosting: Bool?
    let message: String?
}

@MainActor
final class IPIntelligenceBackend: ObservableObject {
    @Published var data: IPIntelligenceData?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var lookupIP = ""
    @Published var cachedIPs: [String: IPIntelligenceData] = [:]

    func lookup(ip: String? = nil) async {
        let target = (ip ?? lookupIP).trimmingCharacters(in: .whitespacesAndNewlines)

        if let cached = cachedIPs[target.isEmpty ? "self" : target] {
            data = cached
            return
        }

        isLoading = true
        errorMessage = ""
        data = nil

        let path = target.isEmpty ? "" : "/\(target)"
        guard let url = URL(string: "https://freeipapi.com/api/json\(path)") else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            let (responseData, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(FreeIPAPIResponse.self, from: responseData)

            if let msg = response.message, !msg.isEmpty {
                errorMessage = msg
            } else {
                let result = IPIntelligenceData(
                    ip: response.ipAddress ?? target,
                    country: response.countryName ?? "Unknown",
                    region: response.regionName ?? "Unknown",
                    city: response.cityName ?? "Unknown",
                    zip: response.zipCode ?? "",
                    latitude: response.latitude ?? 0,
                    longitude: response.longitude ?? 0,
                    timezone: response.timeZone ?? "Unknown",
                    isp: response.continent ?? "Unknown",
                    org: response.continentCode ?? "Unknown",
                    asNumber: response.countryCode ?? "Unknown",
                    isProxy: response.isProxy ?? false,
                    isHosting: response.isHosting ?? false,
                    isMobile: response.isMobile ?? false
                )
                self.data = result
                let cacheKey = target.isEmpty ? "self" : target
                cachedIPs[cacheKey] = result
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func clearCache() {
        cachedIPs.removeAll()
    }
}
