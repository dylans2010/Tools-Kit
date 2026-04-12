import Foundation

final class PlaceholderGeneratorBackend: ObservableObject {
    @Published var text: String = ""

    func generate(paragraphs: Int) {
        let lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.\n\n"
        self.text = String(repeating: lorem, count: paragraphs)
    }
}
