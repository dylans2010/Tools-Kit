import SwiftUI

struct ColorGradingView: View {
    @StateObject private var manager = ColorGradingManager.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Color Grading Suite").font(.headline)

            VStack(spacing: 16) {
                AdjustmentSlider(label: "Exposure", value: $manager.activeProfile.exposure, range: -2...2)
                AdjustmentSlider(label: "Contrast", value: $manager.activeProfile.contrast, range: 0.5...2)
                AdjustmentSlider(label: "Saturation", value: $manager.activeProfile.saturation, range: 0...2)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("LUT Library").font(.caption.bold())
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        LUTThumbnail(name: "Cinematic")
                        LUTThumbnail(name: "Vintage")
                        LUTThumbnail(name: "Noir")
                        LUTThumbnail(name: "Vivid")
                    }
                }
            }

            Button("Auto Match Colors") {
                // Trigger match
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

struct AdjustmentSlider: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.caption)
                Spacer()
                Text(String(format: "%.2f", value)).font(.caption.monospaced())
            }
            Slider(value: $value, in: range)
        }
    }
}

struct LUTThumbnail: View {
    let name: String

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 60, height: 40)
            Text(name).font(.system(size: 10))
        }
    }
}
