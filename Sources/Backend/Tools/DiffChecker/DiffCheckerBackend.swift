import Foundation
class DiffCheckerBackend: ObservableObject {
    @Published var diff = ""
    func check() { diff = "No differences found" }
}
