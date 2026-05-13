
import SwiftUI

struct ConnectorPaginationView: View {
    @State private var strategy: PaginationStrategy = .offset
    @State private var pageSize = 20
    @State private var paramName = "page"

    enum PaginationStrategy: String, CaseIterable {
        case offset, cursor, pageNumber = "Page Number"
    }

    var body: some View {
        Form {
            Section("Strategy") {
                Picker("Type", selection: $strategy) {
                    ForEach(PaginationStrategy.allCases, id: \.self) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
            }

            Section("Parameters") {
                TextField("Page Parameter Name", text: $paramName)
                Stepper("Default Page Size: \(pageSize)", value: $pageSize, in: 1...100)
            }

            Section {
                Text("Automatic pagination will be handled by the execution coordinator.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Pagination")
    }
}
