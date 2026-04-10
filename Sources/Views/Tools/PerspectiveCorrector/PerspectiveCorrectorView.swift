import SwiftUI

struct PerspectiveCorrectorView: View {
    @State private var selectedImage: UIImage?
    @State private var showingPicker = false

    var body: some View {
        VStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .overlay(
                        Rectangle()
                            .stroke(Color.blue, lineWidth: 2)
                            .opacity(0.5)
                    )
            } else {
                Button(action: { showingPicker = true }) {
                    VStack {
                        Image(systemName: "skew")
                            .font(.system(size: 48))
                        Text("Select Image for Correction")
                    }
                }
            }

            Spacer()

            Button("Correct Perspective") {
                // Apply CIDetector and perspective transform
            }
            .buttonStyle(.borderedProminent)
            .disabled(selectedImage == nil)
            .padding()
        }
        .navigationTitle("Perspective Corrector")
        .sheet(isPresented: $showingPicker) {
            FileImporterRepresentableView(allowedContentTypes: [.image]) { urls in
                if let url = urls.first, let data = try? Data(contentsOf: url) {
                    selectedImage = UIImage(data: data)
                }
            }
        }
    }
}

struct PerspectiveCorrectorTool: Tool {
    let name = "Perspective"
    let icon = "skew"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.advanced
    let description = "Fix skewed document photos and architectural shots"
    let requiresAPI = false
    var view: AnyView { AnyView(PerspectiveCorrectorView()) }
}
