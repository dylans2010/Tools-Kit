import Foundation
class HTTPInspectorBackend: ObservableObject {
    @Published var headers = ""
    func inspect() { headers = "Headers" }
}
