import SwiftUI

struct Diag_NetInterfaceCountView: View {
    @State private var total = 0
    @State private var up = 0

    var body: some View {
        Form {
            Section("Interfaces") {
                LabeledContent("Total Addresses") { Text("\(total)").monospacedDigit() }
                LabeledContent("Up") { Text("\(up)").monospacedDigit() }
                LabeledContent("Down") { Text("\(total - up)").monospacedDigit() }
            }
            Section { Button("Refresh") { load() } }
        }
        .navigationTitle("Network Interface Count")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { load() }
    }

    private func load() {
        var totalCount = 0
        var upCount = 0
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let first = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }
        var ptr: UnsafeMutablePointer<ifaddrs>? = first
        while let addr = ptr {
            if addr.pointee.ifa_addr != nil {
                totalCount += 1
                if (addr.pointee.ifa_flags & UInt32(IFF_UP)) != 0 { upCount += 1 }
            }
            ptr = addr.pointee.ifa_next
        }
        total = totalCount
        up = upCount
    }
}
