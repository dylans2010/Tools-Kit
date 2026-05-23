import SwiftUI

struct Diag_HDRDisplayView: View {
    @State private var brightness: CGFloat = 0
    @State private var supportsWideColor = false

    var body: some View {
        Form {
            Section("HDR Capabilities") {
                LabeledContent("Wide Color (P3)") {
                    Label(supportsWideColor ? "Supported" : "Not Available",
                          systemImage: supportsWideColor ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(supportsWideColor ? .green : .red)
                }
                LabeledContent("Current Brightness") {
                    Text("\(Int(brightness * 100))%").monospacedDigit()
                }
                LabeledContent("Max EDR Headroom") {
                    Text(edrHeadroom).monospacedDigit()
                }
            }

            Section("Color Space Test") {
                VStack(spacing: 8) {
                    HStack(spacing: 0) {
                        Color.red.frame(height: 60)
                        Color.green.frame(height: 60)
                        Color.blue.frame(height: 60)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("Standard RGB Bars")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)

                VStack(spacing: 8) {
                    LinearGradient(colors: [.black, .white], startPoint: .leading, endPoint: .trailing)
                        .frame(height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("Luminance Gradient")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section("Display Info") {
                LabeledContent("Screen Scale") {
                    Text("\(Int(UIScreen.main.scale))x")
                }
                LabeledContent("Native Bounds") {
                    let b = UIScreen.main.nativeBounds
                    Text("\(Int(b.width))×\(Int(b.height))")
                }
            }
        }
        .navigationTitle("HDR Display")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            brightness = UIScreen.main.brightness
            supportsWideColor = UIScreen.main.traitCollection.displayGamut == .P3
        }
    }

    private var edrHeadroom: String {
        if #available(iOS 16.0, *) {
            let headroom = UIScreen.main.currentEDRHeadroom
            return String(format: "%.2fx", headroom)
        }
        return "N/A"
    }
}
