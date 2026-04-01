import Foundation
class PortCheckerBackend: ObservableObject {
    @Published var status = ""
    func check() { status = "Port open" }
}
