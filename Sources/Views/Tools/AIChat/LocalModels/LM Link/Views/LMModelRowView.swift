import SwiftUI

struct LMModelRowView: View {
    let model: LMModel

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cpu")
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.subheadline.bold())
                if let arch = model.architecture {
                    Text(arch)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if let ctx = model.contextLength {
                Text("\(ctx/1024)k")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}
