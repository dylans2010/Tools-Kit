import Foundation

struct DNSRecord: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: Int
    let data: String
    let TTL: Int
}

struct DNSResponse: Codable {
    let Answer: [DNSRecord]?
}

class DNSLookupBackend: ObservableObject {
    @Published var domain = ""
    @Published var records: [DNSRecord] = []
    @Published var isLoading = false
    @Published var error = ""

    func lookup() {
        let trimmedDomain = domain.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedDomain.isEmpty else { return }

        isLoading = true
        error = ""
        records = []

        // Using Cloudflare DNS-over-HTTPS API
        guard let url = URL(string: "https://cloudflare-dns.com/dns-query?name=\(trimmedDomain)&type=A") else { return }

        var request = URLRequest(url: url)
        request.addValue("application/dns-json", forHTTPHeaderField: "Accept")

        URLSession.shared.dataTask(with: request) { data, response, urlError in
            DispatchQueue.main.async {
                self.isLoading = false
                if let urlError = urlError {
                    self.error = urlError.localizedDescription
                    return
                }

                guard let data = data else {
                    self.error = "No data received"
                    return
                }

                do {
                    let response = try JSONDecoder().decode(DNSResponse.self, from: data)
                    self.records = response.Answer ?? []
                    if self.records.isEmpty {
                        self.error = "No records found"
                    }
                } catch {
                    self.error = "Failed to parse DNS response"
                }
            }
        }.resume()
    }
}
