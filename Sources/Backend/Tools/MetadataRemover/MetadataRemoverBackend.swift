import Foundation
class MetadataRemoverBackend: ObservableObject {
    @Published var done = false
    func clean() { done = true }
}
