import SwiftUI

struct Diag_CacheSizeView: View {
    @State private var cacheSize: Int64 = 0
    @State private var tempSize: Int64 = 0
    @State private var documentsSize: Int64 = 0
    @State private var isCalculating = false
    @State private var cacheItemCount: Int = 0

    var body: some View {
        Form {
            Section("Cache Storage") {
                VStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.teal)
                    Text(formattedBytes(cacheSize))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Total Cache Size")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }

            Section("Breakdown") {
                LabeledContent("Cache Directory") {
                    Text(formattedBytes(cacheSize)).monospacedDigit()
                }
                LabeledContent("Temp Directory") {
                    Text(formattedBytes(tempSize)).monospacedDigit()
                }
                LabeledContent("Documents") {
                    Text(formattedBytes(documentsSize)).monospacedDigit()
                }
                LabeledContent("Cache Items") {
                    Text("\(cacheItemCount)").monospacedDigit()
                }
            }

            Section("URL Cache") {
                let urlCache = URLCache.shared
                LabeledContent("Memory Capacity") {
                    Text(formattedBytes(Int64(urlCache.memoryCapacity))).monospacedDigit()
                }
                LabeledContent("Disk Capacity") {
                    Text(formattedBytes(Int64(urlCache.diskCapacity))).monospacedDigit()
                }
                LabeledContent("Current Memory Usage") {
                    Text(formattedBytes(Int64(urlCache.currentMemoryUsage))).monospacedDigit()
                }
                LabeledContent("Current Disk Usage") {
                    Text(formattedBytes(Int64(urlCache.currentDiskUsage))).monospacedDigit()
                }
            }

            Section {
                Button {
                    calculateSizes()
                } label: {
                    HStack {
                        Image(systemName: isCalculating ? "hourglass" : "arrow.clockwise")
                        Text(isCalculating ? "Calculating..." : "Refresh")
                    }
                }
                .disabled(isCalculating)
            }
        }
        .navigationTitle("Cache Size")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { calculateSizes() }
    }

    private func calculateSizes() {
        isCalculating = true
        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            let cachePath = fm.urls(for: .cachesDirectory, in: .userDomainMask).first
            let tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let docsPath = fm.urls(for: .documentDirectory, in: .userDomainMask).first

            let cSize = directorySize(url: cachePath)
            let tSize = directorySize(url: tempPath)
            let dSize = directorySize(url: docsPath)
            let itemCount = (try? fm.contentsOfDirectory(atPath: cachePath?.path ?? "").count) ?? 0

            DispatchQueue.main.async {
                cacheSize = cSize
                tempSize = tSize
                documentsSize = dSize
                cacheItemCount = itemCount
                isCalculating = false
            }
        }
    }

    private func directorySize(url: URL?) -> Int64 {
        guard let url = url else { return 0 }
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
