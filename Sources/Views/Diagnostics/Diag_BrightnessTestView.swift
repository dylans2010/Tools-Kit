import SwiftUI

struct Diag_BrightnessTestView: View {
    @StateObject private var service = DiagnosticsService.shared
    @State private var testBrightness: Double = 0.5
    @State private var originalBrightness: CGFloat = UIScreen.main.brightness

    var body: some View {
        Form {
            Section("Current Display") {
                LabeledContent("Screen Brightness") {
                    Text("\(Int(service.screenBrightness * 100))%")
                        .monospacedDigit()
                }
                LabeledContent("Screen Resolution") {
                    Text("\(Int(service.screenNativeBounds.width))×\(Int(service.screenNativeBounds.height))")
                }
                LabeledContent("Screen Scale") {
                    Text("\(service.screenScale, specifier: "%.0f")x")
                }
            }

            Section("Brightness Test") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Drag the slider to test brightness levels")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    HStack {
                        Image(systemName: "sun.min.fill")
                            .foregroundStyle(.secondary)
                        Slider(value: $testBrightness, in: 0...1) { editing in
                            if editing {
                                UIScreen.main.brightness = CGFloat(testBrightness)
                            }
                        }
                        .onChange(of: testBrightness) { _, newVal in
                            UIScreen.main.brightness = CGFloat(newVal)
                        }
                        Image(systemName: "sun.max.fill")
                            .foregroundStyle(.yellow)
                    }

                    Text("\(Int(testBrightness * 100))%")
                        .font(.title2.monospacedDigit().bold())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            Section("Gradient Test") {
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [.black, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                    Text("You should see a smooth gradient from black to white")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
            }

            Section {
                Button("Reset to Original Brightness") {
                    UIScreen.main.brightness = originalBrightness
                    testBrightness = Double(originalBrightness)
                }
            }
        }
        .navigationTitle("Brightness Test")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            originalBrightness = UIScreen.main.brightness
            testBrightness = Double(originalBrightness)
        }
        .onDisappear {
            UIScreen.main.brightness = originalBrightness
        }
    }
}
