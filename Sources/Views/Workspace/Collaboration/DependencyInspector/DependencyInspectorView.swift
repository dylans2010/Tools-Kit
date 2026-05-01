import SwiftUI

struct DependencyInspectorView: View {
    let space: CollaborationSpace
    @StateObject private var inspector = DependencyInspector.shared
    @State private var mappedDependencies: [ObjectDependency] = []

    var body: some View {
        List {
            Section(header: Text("Object Relationship Map")) {
                if mappedDependencies.isEmpty {
                    Text("No dependencies detected.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(mappedDependencies) { dep in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Source: \(dep.sourceID.uuidString.prefix(8))")
                                Text(dep.type.rawValue).font(.caption).foregroundColor(.blue)
                                Text("Target: \(dep.targetID.uuidString.prefix(8))")
                            }
                        }
                    }
                }
            }

            Section(header: Text("Analysis")) {
                Button("Run Orphan Detection") {
                    // Trigger detection
                }

                Button("Map Relationships") {
                    mappedDependencies = inspector.mapRelationships(in: space)
                }
            }
        }
        .navigationTitle("Dependency Inspector")
    }
}
