import Foundation

extension String {
    func decodedSlideJSON<T: Decodable>(_ type: T.Type) throws -> T {
        let data = Data(utf8)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
