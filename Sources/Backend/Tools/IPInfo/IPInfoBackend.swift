import Foundation
class IPInfoBackend: ObservableObject {
    @Published var info = ""
    func fetch() { info = "IP Info" }
}
