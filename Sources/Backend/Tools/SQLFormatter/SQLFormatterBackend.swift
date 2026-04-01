import Foundation
class SQLFormatterBackend: ObservableObject {
    @Published var sql = ""
    func format() { sql = "SELECT * FROM table" }
}
