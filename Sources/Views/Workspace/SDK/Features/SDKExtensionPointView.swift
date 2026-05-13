
import SwiftUI

struct SDKExtensionPointView: View {
    @State private var extensionPoints: [ExtPoint] = []

    struct ExtPoint: Identifiable {
        let id = UUID()
        var name: String
        var description: String
    }

    var body: some View {
        List {
            Section("Defined Extension Points") {
                if extensionPoints.isEmpty {
                    Text("No extension points defined.").font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(extensionPoints) { pt in
                        VStack(alignment: .leading) {
                            Text(pt.name).bold()
                            Text(pt.description).font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Button("Define New Extension Point", systemImage: "puzzlepiece.extension") { }
        }
        .navigationTitle("Extension Points")
    }
}
