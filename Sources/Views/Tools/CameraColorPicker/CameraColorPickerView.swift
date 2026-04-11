import SwiftUI
import AVFoundation

struct CameraColorPickerView: View {
    @StateObject private var cameraService = CameraService()
    @StateObject private var colorPicker = RealTimeColorPicker()

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                CameraPreview(cameraService: cameraService)
                    .onAppear {
                        cameraService.delegate = colorPicker
                        cameraService.startSession()
                    }
                    .onDisappear {
                        cameraService.stopSession()
                    }

                // Center reticle
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 30, height: 30)
                    .shadow(radius: 3)

                Circle()
                    .fill(colorPicker.pickedColor)
                    .frame(width: 10, height: 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .cornerRadius(24)
            .padding()

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Point the camera at any object to identify its color in real-time. The center circle shows the currently detected color.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 16) {
                        Circle()
                            .fill(colorPicker.pickedColor)
                            .frame(width: 60, height: 60)
                            .shadow(radius: 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(colorPicker.hexCode)
                                .font(.system(.title2, design: .monospaced))
                                .bold()

                            Text("RGB: \(colorPicker.rgbString)")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: { UIPasteboard.general.string = colorPicker.hexCode }) {
                            Image(systemName: "doc.on.doc")
                                .font(.title3)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .clipShape(Circle())
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)

                if !colorPicker.recentColors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recently Captured")
                            .font(.headline)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(colorPicker.recentColors, id: \.self) { colorHex in
                                    VStack(spacing: 4) {
                                        Circle()
                                            .fill(Color(hex: colorHex) ?? .gray)
                                            .frame(width: 40, height: 40)
                                        Text(colorHex)
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary)
                                    }
                                    .onTapGesture {
                                        UIPasteboard.general.string = colorHex
                                    }
                                }
                            }
                        }
                    }
                }

                Button(action: colorPicker.capture) {
                    Label("Capture Color", systemImage: "paintbrush.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
            }
            .padding()
        }
        .navigationTitle("Camera Color Picker")
    }
}

class RealTimeColorPicker: NSObject, ObservableObject, CameraServiceDelegate {
    @Published var pickedColor = Color.white
    @Published var hexCode = "#FFFFFF"
    @Published var rgbString = "255, 255, 255"
    @Published var recentColors: [String] = []

    func didOutput(pixelBuffer: CVPixelBuffer) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)

        // Sample center pixel
        let centerX = width / 2
        let centerY = height / 2
        let pixelIndex = centerY * bytesPerRow + centerX * 4

        let b = buffer[pixelIndex]
        let g = buffer[pixelIndex + 1]
        let r = buffer[pixelIndex + 2]

        DispatchQueue.main.async {
            self.pickedColor = Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
            self.hexCode = String(format: "#%02X%02X%02X", r, g, b)
            self.rgbString = "\(r), \(g), \(b)"
        }
    }

    func capture() {
        if !recentColors.contains(hexCode) {
            recentColors.insert(hexCode, at: 0)
            if recentColors.count > 10 { recentColors.removeLast() }
        }
    }
}

struct CameraColorPickerTool: Tool {
    let name = "Cam Color Picker"
    let icon = "eyedropper.halfsquare"
    let category = ToolCategory.utility
    let complexity = ToolComplexity.basic
    let description = "Extract colors in real-time using your camera"
    let requiresAPI = false
    var view: AnyView { AnyView(CameraColorPickerView()) }
}
