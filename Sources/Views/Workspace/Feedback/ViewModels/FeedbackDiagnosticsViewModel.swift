import Foundation
import Combine

@MainActor
public final class FeedbackDiagnosticsViewModel: ObservableObject {
    @Published public var diagnostics: DiagnosticsData?
    @Published public var isCapturing = false

    public init() {}

    public func capture() async {
        isCapturing = true
        diagnostics = await DiagnosticsManager.shared.captureDiagnostics()
        isCapturing = false
    }
}
