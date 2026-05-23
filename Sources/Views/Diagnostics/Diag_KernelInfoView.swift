import SwiftUI

struct Diag_KernelInfoView: View {
    @StateObject private var service = DiagnosticsService.shared

    var body: some View {
        List {
            Section("Kernel Details") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("XNU Kernel Version")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(service.kernelVersion)
                        .font(.system(.body, design: .monospaced))
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
            }

            Section("Boot Parameters") {
                LabeledContent("Boot Args", value: "None")
                LabeledContent("Secure Boot", value: "Enabled")
                LabeledContent("Page Size", value: "\(vm_kernel_page_size) bytes")
            }

            Section("Memory Management") {
                LabeledContent("Max Tasks", value: "2048")
                LabeledContent("Max Threads", value: "4096")
            }
        }
        .navigationTitle("Kernel Info")
    }
}
