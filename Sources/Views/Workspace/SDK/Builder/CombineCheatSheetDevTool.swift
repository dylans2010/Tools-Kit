import SwiftUI

struct CombineCheatSheetDevTool: DevTool {
    let id = "combine-cheat"
    let name = "Combine Cheat Sheet"
    let category: DevToolCategory = .utilities
    let icon = "app.connected.to.app.below.fill"
    let description = "Cheat sheet for Combine operators and publishers"

    func render() -> some View {
        List {
            Section("Publishers") {
                Text("Just(value)")
                Text("Future { promise in ... }")
                Text("PassthroughSubject<T, E>")
                Text("CurrentValueSubject<T, E>")
            }
            Section("Operators") {
                Text(".map { ... }")
                Text(".filter { ... }")
                Text(".flatMap { ... }")
                Text(".sink { ... }")
            }
        }
    }
}
