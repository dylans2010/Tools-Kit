import SwiftUI

struct Diag_DynamicTypeView: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    var body: some View {
        Form {
            Section("Current Dynamic Type") {
                VStack(spacing: 12) {
                    Text("Aa")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)

                    Text("\(dynamicTypeSize.description)")
                        .font(.title2.bold())

                    Text("This is the text size currently configured in your system settings")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Text Size Preview") {
                Group {
                    Text("Extra Small")
                        .dynamicTypeSize(.xSmall)
                    Text("Small")
                        .dynamicTypeSize(.small)
                    Text("Medium (Default)")
                        .dynamicTypeSize(.medium)
                    Text("Large")
                        .dynamicTypeSize(.large)
                    Text("Extra Large")
                        .dynamicTypeSize(.xLarge)
                    Text("XXL")
                        .dynamicTypeSize(.xxLarge)
                    Text("XXXL")
                        .dynamicTypeSize(.xxxLarge)
                    Text("Accessibility Medium")
                        .dynamicTypeSize(.accessibility1)
                    Text("Accessibility Large")
                        .dynamicTypeSize(.accessibility3)
                    Text("Accessibility XXL")
                        .dynamicTypeSize(.accessibility5)
                }
            }

            Section("UI Impact") {
                Text("Dynamic Type affects the readability and layout of all text-based UI elements. Larger sizes may cause text to wrap or truncate in fixed-width layouts.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Dynamic Type")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension DynamicTypeSize {
    var description: String {
        switch self {
        case .xSmall: return "Extra Small"
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        case .xLarge: return "Extra Large"
        case .xxLarge: return "XX Large"
        case .xxxLarge: return "XXX Large"
        case .accessibility1: return "Accessibility 1"
        case .accessibility2: return "Accessibility 2"
        case .accessibility3: return "Accessibility 3"
        case .accessibility4: return "Accessibility 4"
        case .accessibility5: return "Accessibility 5"
        @unknown default: return "Unknown"
        }
    }
}
