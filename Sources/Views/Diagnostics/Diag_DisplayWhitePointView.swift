import SwiftUI

/// Display reference view. The previous version hardcoded
/// "Current White Point 6480K / Delta E 0.8 / Gamma 2.22" — iOS does not
/// expose a measured white point, Delta E, or gamma for the panel, so
/// those numbers were invented. This version shows only live traits
/// (brightness, scale, gamut, interface style) plus a D65 reference
/// swatch for a visual check, and says so plainly.
struct Diag_DisplayWhitePointView: View {
    @State private var brightness = UIScreen.main.brightness

    var body: some View {
        VStack {
            Text("D65 White Point Reference")
                .font(.headline)
                .padding()

            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 250)

                VStack {
                    Text("Reference White")
                        .foregroundStyle(.black)
                    Text("6504K (D65 reference, not a panel measurement)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            List {
                Section("Live Display Traits") {
                    LabeledContent("Brightness") { Text("\(Int(brightness * 100))%").monospacedDigit() }
                    LabeledContent("Display Scale") { Text("\(UIScreen.main.scale, specifier: "%.1f")x") }
                    LabeledContent("Native Scale") { Text("\(UIScreen.main.nativeScale, specifier: "%.2f")x") }
                    LabeledContent("Gamut") { Text(UIScreen.main.traitCollection.displayGamut == .P3 ? "Display P3" : "sRGB") }
                    LabeledContent("Max Refresh Rate") { Text("\(Int(UIScreen.main.maximumFramesPerSecond)) Hz") }
                }

                Section("Not Measured") {
                    Text("iOS does not expose a measured white point, Delta E, or gamma for this panel to apps. Any such number shown by an app would be invented, so this tool does not report one.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Environment") {
                    VStack(alignment: .leading) {
                        Text("Ambient Brightness Impact")
                        Slider(value: $brightness, in: 0...1)
                            .onChange(of: brightness) { _, newValue in
                                UIScreen.main.brightness = newValue
                            }
                    }
                }
            }
        }
        .navigationTitle("White Point Test")
    }
}
