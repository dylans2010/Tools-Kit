import SwiftUI

struct Diag_BoldTextCheckView: View {
    @Environment(\.legibilityWeight) private var legibilityWeight

    var body: some View {
        Form {
            Section("Bold Text") {
                VStack(spacing: 12) {
                    Image(systemName: "bold")
                        .font(.system(size: 48))
                        .foregroundStyle(isBoldEnabled ? .blue : .secondary)
                    Text(isBoldEnabled ? "Bold Text Enabled" : "Bold Text Disabled")
                        .font(.headline)
                    Text(isBoldEnabled ? "System-wide bold text is active" : "Standard font weight is used")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Text Samples") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Regular weight text sample")
                        .font(.body)
                    Text("This is how body text appears")
                        .font(.body)
                    Text("Caption text for smaller elements")
                        .font(.caption)
                    Text("Title text for headings")
                        .font(.title3)
                }
                .padding(.vertical, 4)
            }

            Section("Accessibility Settings") {
                LabeledContent("Bold Text") {
                    Text(isBoldEnabled ? "On" : "Off")
                        .foregroundStyle(isBoldEnabled ? .blue : .secondary)
                }
                LabeledContent("Legibility Weight") {
                    Text(legibilityWeight == .bold ? "Bold" : "Regular")
                }
            }

            Section("Impact") {
                Text("When Bold Text is enabled, all system fonts are rendered with a heavier weight for improved readability.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Bold Text Check")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var isBoldEnabled: Bool {
        legibilityWeight == .bold
    }
}
