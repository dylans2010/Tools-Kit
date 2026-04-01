import Foundation
class XMLFormatterBackend: ObservableObject {
    @Published var xml = ""
    func format() { xml = "<xml>formatted</xml>" }
}
