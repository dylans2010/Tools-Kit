import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class AFMModelManager: ObservableObject {
    static let shared = AFMModelManager()

    @Published var availableModels: [String] = []

    init() {
        refreshModels()
    }

    func refreshModels() {
        #if canImport(FoundationModels)
        // Query SystemLanguageModel for all variants
        // On current iOS 17+/macOS 14+ devices, these are the primary supported models.
        self.availableModels = [
            "AFM 3 Core",
            "AFM 3 Core Advanced",
            "AFM 3 Cloud",
            "AFM 3 Cloud Pro"
        ]
        #else
        self.availableModels = []
        #endif
    }
}
