import Foundation
class EmailGeneratorBackend: ObservableObject {
    @Published var email = ""
    func generate() { email = "Email" }
}
