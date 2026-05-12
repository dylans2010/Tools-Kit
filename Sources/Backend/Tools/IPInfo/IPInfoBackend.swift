import Foundation

struct IPInfoData: Codable, Sendable {
    let ip: String?
    let city: String?
    let region: String?
    let country_name: String?
    let org: String?
    let latitude: Double?
    let longitude: Double?
    let timezone: String?
}

class IPInfoBackend: ObservableObject {
    @Published var info: IPInfoData?
    @Published var isLoading = false
    @Published var error = ""

    func fetch() {
        isLoading = true
        error = ""

        guard let url = URL(string: "https://ipapi.co/json/") else { return }

        URLSession.shared.dataTask(with: url) { data, response, urlError in
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
                    self.info = try JSONDecoder().decode(IPInfoData.self, from: data)
                } catch {
                    self.error = "Failed to parse IP data"
                }
            }
        }.resume()
    }
}
