import SwiftUI

struct DeviceScreenSizeRefDevTool: DevTool {
    let id = "device-screen-size-ref"
    let name = "Device Screen Size Reference"
    let category: DevToolCategory = .uiDesign
    let icon = "iphone"
    let description = "Reference for screen resolutions and safe areas"

    func render() -> some View {
        List {
            deviceRow("iPhone 15 Pro Max", "430 x 932", "3x")
            deviceRow("iPhone 15 / Pro", "393 x 852", "3x")
            deviceRow("iPhone 14 Plus", "428 x 926", "3x")
            deviceRow("iPhone 14 / 13 Pro", "390 x 844", "3x")
            deviceRow("iPhone 13 mini / 12 mini", "375 x 812", "3x")
            deviceRow("iPhone SE (3rd gen)", "375 x 667", "2x")
            deviceRow("iPad Pro 12.9\"", "1024 x 1366", "2x")
            deviceRow("iPad Pro 11\"", "834 x 1194", "2x")
        }
    }

    private func deviceRow(_ name: String, _ points: String, _ scale: String) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.headline)
                Text(points).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(scale).font(.system(.body, design: .monospaced)).foregroundStyle(.tertiary)
        }
    }
}
