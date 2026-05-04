import SwiftUI

struct SpatialWorkspaceHomeView: View {
    var body: some View {
        ZStack {
            InfiniteCanvasView()

            VStack {
                HStack {
                    Text("Spatial Workspace")
                        .font(.headline)
                        .padding()
                        .background(Material.thin)
                        .cornerRadius(12)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
        .navigationTitle("Spatial")
    }
}
