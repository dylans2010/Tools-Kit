import Foundation

protocol OpenClawPairingStrategy {
    var name: String { get }
    func pair() async throws -> OpenClawDevice
}
