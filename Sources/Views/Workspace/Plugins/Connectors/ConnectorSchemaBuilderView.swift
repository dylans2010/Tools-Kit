import SwiftUI

struct ConnectorSchemaBuilderView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.left.arrow.right.square")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("Data Mapping Engine")
                .font(.title2.bold())

            Text("Map external API responses to Workspace models.")
                .font(.subheadline)
                .secondary()
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            List {
                Section("Field Mappings") {
                    Text("external_id → workspace.id").font(.caption.monospaced())
                    Text("user.email → workspace.author").font(.caption.monospaced())
                }
            }
        }
        .navigationTitle("Schema Builder")
    }
}
