import Foundation
class JWTDecoderBackend: ObservableObject {
    @Published var token = ""
    @Published var decoded = ""
    func decode() { decoded = "Decoded JWT Payload" }
}
