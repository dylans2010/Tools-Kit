import SwiftUI
import Vision

struct ObjectDetectionView: View {
    @StateObject private var cameraService = CameraService()
    @State private var detections: [VNRecognizedObjectObservation] = []

    var body: some View {
        VStack {
            ZStack {
                CameraPreview(session: cameraService.session)

                // Overlay bounding boxes
                GeometryReader { geometry in
                    ForEach(detections, id: \.uuid) { detection in
                        BoundingBoxView(observation: detection, geometry: geometry)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(12)
            .padding()

            VStack(alignment: .leading) {
                Text("Detected Objects")
                    .font(.headline)

                if detections.isEmpty {
                    Text("Point camera at objects")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(detections, id: \.uuid) { detection in
                        if let label = detection.labels.first?.identifier {
                            Text("• \(label.capitalized) (\(Int(detection.confidence * 100))%)")
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("Object Detection")
        .onAppear {
            cameraService.start()
        }
        .onDisappear {
            cameraService.stop()
        }
        .onReceive(cameraService.$currentFrame) { frame in
            if let _ = frame {
                processFrame()
            }
        }
    }

    private func processFrame() {
        guard let pixelBuffer = cameraService.currentFrame else { return }

        Task {
            if let results = try? await VisionService.shared.detectObjects(in: pixelBuffer) {
                await MainActor.run {
                    self.detections = results
                }
            }
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.frame
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}

struct BoundingBoxView: View {
    let observation: VNRecognizedObjectObservation
    let geometry: GeometryProxy

    var body: some View {
        let box = observation.boundingBox
        let width = geometry.size.width
        let height = geometry.size.height

        // Vision coordinates are 0-1, with origin at bottom-left
        let rect = CGRect(
            x: box.origin.x * width,
            y: (1 - box.origin.y - box.size.height) * height,
            width: box.size.width * width,
            height: box.size.height * height
        )

        return ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.green, lineWidth: 2)
                .frame(width: rect.width, height: rect.height)

            if let label = observation.labels.first?.identifier {
                Text(label.capitalized)
                    .font(.caption2)
                    .padding(4)
                    .background(Color.green)
                    .foregroundColor(.white)
            }
        }
        .position(x: rect.midX, y: rect.midY)
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
