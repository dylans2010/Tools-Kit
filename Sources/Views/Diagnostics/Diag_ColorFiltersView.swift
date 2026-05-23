import SwiftUI

struct Diag_ColorFiltersView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var invertColors = UIAccessibility.isInvertColorsEnabled
    @State private var grayscaleEnabled = UIAccessibility.isGrayscaleEnabled
    @State private var reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
    @State private var increaseContrast = UIAccessibility.isDarkerSystemColorsEnabled

    var body: some View {
        Form {
            Section("Color Accessibility") {
                VStack(spacing: 12) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 48))
                        .foregroundStyle(.cyan)
                    Text("Color Filter Status")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Active Filters") {
                filterRow("Invert Colors", enabled: invertColors, icon: "circle.lefthalf.filled.inverse")
                filterRow("Grayscale", enabled: grayscaleEnabled, icon: "circle.lefthalf.striped.horizontal")
                filterRow("Reduce Transparency", enabled: reduceTransparency, icon: "square.on.square")
                filterRow("Increase Contrast", enabled: increaseContrast, icon: "circle.circle.fill")
            }

            Section("Display") {
                LabeledContent("Color Scheme") {
                    Text(colorScheme == .dark ? "Dark" : "Light")
                }
                LabeledContent("Interface Style") {
                    Text(colorScheme == .dark ? "Dark Mode" : "Light Mode")
                        .foregroundStyle(colorScheme == .dark ? .purple : .orange)
                }
            }

            Section("Color Test") {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        ForEach([Color.red, .orange, .yellow, .green, .blue, .purple], id: \.self) { color in
                            color.frame(height: 40)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    Text("If colors appear identical, a color filter may be active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Refresh") { checkFilters() }
            }
        }
        .navigationTitle("Color Filters")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { checkFilters() }
    }

    private func filterRow(_ title: String, enabled: Bool, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(enabled ? .blue : .secondary)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(enabled ? "Active" : "Inactive")
                .font(.caption)
                .foregroundStyle(enabled ? .orange : .green)
        }
    }

    private func checkFilters() {
        invertColors = UIAccessibility.isInvertColorsEnabled
        grayscaleEnabled = UIAccessibility.isGrayscaleEnabled
        reduceTransparency = UIAccessibility.isReduceTransparencyEnabled
        increaseContrast = UIAccessibility.isDarkerSystemColorsEnabled
    }
}
