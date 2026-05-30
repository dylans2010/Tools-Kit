import SwiftUI

struct ColorConverterView: View {
    @State private var hex = "007AFF"
    @State private var r: Double = 0
    @State private var g: Double = 122
    @State private var b: Double = 255

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: r/255, green: g/255, blue: b/255))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 16) {
                    Text("HEX").font(.headline)
                    HStack {
                        Text("#").foregroundStyle(.secondary)
                        TextField("000000", text: $hex)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .autocapitalization(.allCharacters)
                            .onChange(of: hex) { _ in updateFromHex() }
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 16) {
                    Text("RGB").font(.headline)

                    rgbSlider(label: "Red", value: $r)
                    rgbSlider(label: "Green", value: $g)
                    rgbSlider(label: "Blue", value: $b)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 8) {
                    Text("SwiftUI Color").font(.caption.bold()).foregroundStyle(.secondary)
                    Text("Color(red: \(String(format: "%.2f", r/255)), green: \(String(format: "%.2f", g/255)), blue: \(String(format: "%.2f", b/255)))")
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
        }
        .navigationTitle("Color Converter")
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private func rgbSlider(label: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(label).font(.subheadline)
                Spacer()
                Text("\(Int(value.wrappedValue))").font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Slider(value: value, in: 0...255, step: 1)
                .onChange(of: value.wrappedValue) { _ in updateFromRGB() }
        }
    }

    private func updateFromHex() {
        let cleanHex = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleanHex.count == 6 else { return }

        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)

        r = Double((rgbValue & 0xFF0000) >> 16)
        g = Double((rgbValue & 0x00FF00) >> 8)
        b = Double(rgbValue & 0x0000FF)
    }

    private func updateFromRGB() {
        hex = String(format: "%02X%02X%02X", Int(r), Int(g), Int(b))
    }
}
