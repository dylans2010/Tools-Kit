import SwiftUI

struct NodeInspectorView: View {
    let node: SpatialNode

    var body: some View {
        Form {
            Section("Entity Info") {
                Text(node.entity.title)
                Text(node.entity.type.rawValue)
            }
            Section("Spatial Props") {
                Text("X: \(node.position.x)")
                Text("Y: \(node.position.y)")
            }
        }
        .navigationTitle("Inspector")
    }
}
