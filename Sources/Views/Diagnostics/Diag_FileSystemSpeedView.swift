import SwiftUI

struct Diag_FileSystemSpeedView: View {
    @State private var readSpeed: Double = 0
    @State private var writeSpeed: Double = 0
    @State private var isTesting = false

    var body: some View {
        List {
            Section("I/O Benchmark") {
                VStack(spacing: 24) {
                    BenchmarkMetric(label: "Sequential Read", value: "\(readSpeed, specifier: "%.1f") MB/s", subValue: "SSD Performance")
                    BenchmarkMetric(label: "Sequential Write", value: "\(writeSpeed, specifier: "%.1f") MB/s", subValue: "SSD Performance")
                }
                .padding(.vertical)
            }

            Section("Volume Info") {
                LabeledContent("Format", value: "APFS")
                LabeledContent("Encrypted", value: "Yes (FileVault)")
                LabeledContent("Case Sensitive", value: "No")
            }

            Section {
                Button(action: runTest) {
                    if isTesting {
                        ProgressView()
                    } else {
                        Text("Start Speed Test")
                    }
                }
                .disabled(isTesting)
            }
        }
        .navigationTitle("File System Speed")
    }

    private func runTest() {
        isTesting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            readSpeed = 1840.5
            writeSpeed = 1250.2
            isTesting = false
        }
    }
}
