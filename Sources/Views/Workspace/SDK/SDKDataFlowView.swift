import SwiftUI

struct SDKDataFlowView: View {
    var body: some View {
        VStack {
            Image(systemName: "tray.2.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
                .padding()
            Text("Data Flow Visualizer").font(.title2).bold()
            Text("Real-time pipeline monitoring").foregroundStyle(.secondary)

            List {
                HStack {
                    Text("Workspace API")
                    Image(systemName: "arrow.right")
                    Text("SDK Pipeline")
                    Image(systemName: "arrow.right")
                    Text("App UI")
                }
                .font(.caption)
            }
        }
        .navigationTitle("Data Flow")
    }
}
