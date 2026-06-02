import SwiftUI

struct PlaceholderDataDevTool: DevTool {
    let id = "placeholder-data"
    let name = "Placeholder Data Generator"
    let category: DevToolCategory = .data
    let icon = "text.badge.plus"
    let description = "Generate realistic random names, emails, and addresses"

    private let firstNames = ["James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael", "Linda", "William", "Elizabeth"]
    private let lastNames = ["Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez"]
    private let domains = ["gmail.com", "outlook.com", "icloud.com", "example.com", "enterprise.org"]
    private let streets = ["Main St", "Oak Ave", "Washington Blvd", "Lakeview Dr", "Park St"]

    func render() -> some View {
        SimpleDevToolView(title: name, placeholder: "Enter count (default: 5)") { input in
            let count = Int(input) ?? 5
            return (1...min(count, 100)).map { i in
                let fn = firstNames.randomElement()!
                let ln = lastNames.randomElement()!
                let email = "\(fn.lowercased()).\(ln.lowercased())@\(domains.randomElement()!)"
                let addr = "\(Int.random(in: 100...999)) \(streets.randomElement()!), Suite \(i)"
                return "{\"id\": \(i), \"name\": \"\(fn) \(ln)\", \"email\": \"\(email)\", \"address\": \"\(addr)\"}"
            }.joined(separator: "\n")
        }
    }
}
