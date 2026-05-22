import SwiftUI

struct Diag_TrueToneCheckView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        Form {
            Section("True Tone Display") {
                VStack(alignment: .leading, spacing: 12) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)

                    Text("True Tone automatically adapts your display to match the ambient lighting conditions for a more natural viewing experience.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Display Properties") {
                LabeledContent("Screen Brightness") {
                    Text("\(Int(service.screenBrightness * 100))%")
                }
                LabeledContent("Display Scale") {
                    Text("\(service.screenScale, specifier: "%.0f")x Retina")
                }
                LabeledContent("Native Resolution") {
                    Text("\(Int(service.screenNativeBounds.width))×\(Int(service.screenNativeBounds.height))")
                }
                LabeledContent("Logical Resolution") {
                    Text("\(Int(service.screenBounds.width))×\(Int(service.screenBounds.height))")
                }
            }

            Section("Color Temperature Visualization") {
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        ForEach(0..<20, id: \.self) { i in
                            let warmth = Double(i) / 19.0
                            Color(
                                red: 1.0,
                                green: 0.85 + (0.15 * (1.0 - warmth)),
                                blue: 0.7 + (0.3 * (1.0 - warmth))
                            )
                            .frame(height: 50)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    HStack {
                        Text("Warm")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Cool")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section {
                Text("True Tone settings can be toggled in Settings > Display & Brightness. This test shows your current display properties and a color temperature reference.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("True Tone Check")
        .navigationBarTitleDisplayMode(.inline)
    }
}
