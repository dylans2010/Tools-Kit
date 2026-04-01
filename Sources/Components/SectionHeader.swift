import SwiftUI

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                }
                Text(title)
                    .font(.title2.bold())
            }
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }
}
