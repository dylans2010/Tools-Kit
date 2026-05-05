import SwiftUI

struct WhiteboardsHomeView: View {
    @StateObject private var dataStore = UnifiedDataStore.shared
    @State private var showingCreate = false
    @State private var newCanvasName = ""

    var body: some View {
        List {
            Section("My Whiteboards") {
                if dataStore.spatialCanvases.isEmpty {
                    Text("No whiteboards yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(dataStore.spatialCanvases) { canvas in
                        NavigationLink(destination: WhiteboardCanvasView(canvas: canvas)) {
                            Label(canvas.name, systemImage: "square.3.layers.3d")
                        }
                    }
                }

                Button("Create New Whiteboard") {
                    showingCreate = true
                }
            }
        }
        .navigationTitle("Spatial Whiteboards")
        .alert("New Whiteboard", isPresented: $showingCreate) {
            TextField("Canvas Name", text: $newCanvasName)
            Button("Cancel", role: .cancel) { newCanvasName = "" }
            Button("Create") {
                if !newCanvasName.isEmpty {
                    _ = WhiteboardService.shared.createNewCanvas(name: newCanvasName)
                    newCanvasName = ""
                }
            }
        }
    }
}
