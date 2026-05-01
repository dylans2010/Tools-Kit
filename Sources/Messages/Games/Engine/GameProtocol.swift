import Foundation

protocol GameProtocol {
    associatedtype StateType: Codable

    var state: StateType { get set }

    func makeMove(action: String) -> StateType
    func encodeState() -> Data?
    static func decodeState(from data: Data) -> StateType?
}
