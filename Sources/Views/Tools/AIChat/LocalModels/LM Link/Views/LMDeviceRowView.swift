import SwiftUI

struct LMDeviceRowView: View {
    let device: LMDevice

    var body: some View {
        HStack(spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "desktopcomputer")
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(device.name)
                    .font(.headline)
                Text("\(device.ipAddress):\(device.port)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(device.status.rawValue.capitalized)
                    .font(.caption.bold())
                    .foregroundColor(device.status == .online ? .green : .red)

                Text(device.models.count == 1 ? "1 Model" : "\(device.models.count) Models")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
