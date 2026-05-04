import Foundation

class SpatialEngine: ObservableObject {
    static let shared = SpatialEngine()

    @Published var zoomLevel: CGFloat = 1.0
    @Published var offset: CGPoint = .zero

    private init() {}

    func pan(by delta: CGPoint) {
        offset.x += delta.x
        offset.y += delta.y
    }
}
