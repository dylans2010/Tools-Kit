import SwiftUI
import Vision

struct ObjectDetectionView: View {
    @State private var detectedObjects: [String] = []

    var body: some View {
        VStack {
            ZStack {
                Color.black
                Text("Vision Object Detection Feed")
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()

            VStack(alignment: .leading) {
                Text("Detected Objects")
                    .font(.headline)

                if detectedObjects.isEmpty {
                    Text("No objects detected")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(detectedObjects, id: \.self) { obj in
                        Text("• \(obj)")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()

            Button("Detect Objects") {
                detectedObjects = ["Bottle", "Laptop", "Keyboard"]
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .navigationTitle("Object Detection")
    }
}

struct ObjectDetectionTool: Tool {
    let name = "Object Detection"
    let icon = "viewfinder.circle"
    let category = ToolCategory.ai
    let complexity = ToolComplexity.advanced
    let description = "Identify and label objects in real-time"
    let requiresAPI = false
    var view: AnyView { AnyView(ObjectDetectionView()) }
}
