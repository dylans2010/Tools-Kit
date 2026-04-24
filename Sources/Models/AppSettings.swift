import Foundation
import Combine

final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var selectedModel: String = "gpt-4"
    @Published var coreMLSelectedModel: String? = nil
    @Published var coreMLEnabled: Bool = false
    @Published var julesEnabled: Bool = true

    private init() {}
}
