import Foundation
import Combine

final class WorkspaceModeManager: ObservableObject {
    static let shared = WorkspaceModeManager()

    private let key = "workspaceModeEnabled"

    @Published var isWorkspaceModeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isWorkspaceModeEnabled, forKey: key)
        }
    }

    private init() {
        isWorkspaceModeEnabled = UserDefaults.standard.bool(forKey: key)
    }
}
