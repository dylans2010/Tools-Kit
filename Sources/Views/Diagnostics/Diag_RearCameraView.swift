import SwiftUI
import AVFoundation

struct Diag_RearCameraView: View {
    @State private var isCameraAvailable = false

    var body: some View {
        VStack(spacing: 0) {
            if isCameraAvailable {
                CameraPreviewRepresentable(position: .back, isRunning: .constant(false))
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary)
                    Text("Rear camera not available")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.black)
        .navigationTitle("Rear Camera")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isCameraAvailable = UIImagePickerController.isCameraDeviceAvailable(.rear)
        }
    }
}
