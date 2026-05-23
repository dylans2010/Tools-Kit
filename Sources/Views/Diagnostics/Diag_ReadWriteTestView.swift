import SwiftUI

struct Diag_ReadWriteTestView: View {
    @State private var isTesting = false
    @State private var writeSpeed: Double = 0
    @State private var readSpeed: Double = 0
    @State private var testComplete = false
    @State private var testSizeMB: Double = 10

    var body: some View {
        Form {
            Section("Read/Write Speed") {
                VStack(spacing: 16) {
                    HStack(spacing: 30) {
                        VStack {
                            Image(systemName: "arrow.down.doc.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                            Text("\(writeSpeed, specifier: "%.1f")")
                                .font(.title2.monospacedDigit().bold())
                            Text("MB/s Write")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        VStack {
                            Image(systemName: "arrow.up.doc.fill")
                                .font(.title)
                                .foregroundStyle(.green)
                            Text("\(readSpeed, specifier: "%.1f")")
                                .font(.title2.monospacedDigit().bold())
                            Text("MB/s Read")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Test Size") {
                VStack(alignment: .leading, spacing: 8) {
                    Slider(value: $testSizeMB, in: 1...50, step: 1)
                    Text("\(Int(testSizeMB)) MB")
                        .font(.subheadline.monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }

            Section {
                Button {
                    runTest()
                } label: {
                    HStack {
                        if isTesting { ProgressView().padding(.trailing, 4) }
                        Text(isTesting ? "Testing..." : "Run Speed Test")
                    }
                }
                .disabled(isTesting)
            }

            Section {
                Text("This test writes and reads a temporary file to measure storage I/O speed. The file is deleted after the test.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Read/Write Test")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func runTest() {
        isTesting = true
        writeSpeed = 0
        readSpeed = 0

        let requestedSizeMB = testSizeMB

        Task.detached(priority: .userInitiated) {
            let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("diag_rw_test.bin")
            let size = Int(requestedSizeMB * 1_000_000)
            let data = Data(repeating: 0xAA, count: size)

            // Write test
            let writeStart = Date()
            try? data.write(to: fileURL)
            let writeTime = Date().timeIntervalSince(writeStart)
            let wSpeed = Double(size) / writeTime / 1_000_000

            // Read test
            let readStart = Date()
            let _ = try? Data(contentsOf: fileURL)
            let readTime = Date().timeIntervalSince(readStart)
            let rSpeed = Double(size) / readTime / 1_000_000

            try? FileManager.default.removeItem(at: fileURL)

            await MainActor.run {
                writeSpeed = wSpeed
                readSpeed = rSpeed
                testComplete = true
                isTesting = false
            }
        }
    }
}
