import Foundation
class LinkPreviewBackend: ObservableObject {
    @Published var title = ""
    func fetch() { title = "Link Title" }
}
