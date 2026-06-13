import SwiftUI

struct BridgePlatformSelectorView: View {
    @Binding var selectedPlatform: BridgePlatform

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Host OS")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(BridgePlatform.allCases) { platform in
                    PlatformCard(
                        platform: platform,
                        isSelected: selectedPlatform == platform,
                        action: { selectedPlatform = platform }
                    )
                }
            }

            Text("This will adjust default ports and supported command sets for the bridge connection.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct PlatformCard: View {
    let platform: BridgePlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: platform.iconName)
                    .font(.largeTitle)
                Text(platform.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
