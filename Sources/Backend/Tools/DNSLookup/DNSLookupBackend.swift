import Foundation
class DNSLookupBackend: ObservableObject {
    @Published var dns = ""
    func lookup() { dns = "DNS Records" }
}
