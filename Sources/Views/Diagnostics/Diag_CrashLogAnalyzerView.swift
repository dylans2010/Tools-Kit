import SwiftUI

struct Diag_CrashLogAnalyzerView: View {
    @State private var crashLogs: [CrashLogEntry] = []
    @State private var isScanning = false
    @State private var stats: [(String, String)] = []

    struct CrashLogEntry: Identifiable {
        let id = UUID()
        let filename: String
        let date: Date?
        let size: UInt64
        let type: String
    }

    var body: some View {
        Form {
            Section("Crash Log Analyzer") {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text("Crash & Diagnostic Logs")
                        .font(.headline)
                    Text("Scan for system and app crash reports")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Section("Summary") {
                ForEach(stats, id: \.0) { s in
                    LabeledContent(s.0) { Text(s.1).font(.caption) }
                }
            }

            if !crashLogs.isEmpty {
                Section("Found Logs (\(crashLogs.count))") {
                    ForEach(crashLogs.prefix(50), id: \.id) { log in
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Image(systemName: log.type == "crash" ? "exclamationmark.circle.fill" : "doc.text.fill")
                                    .foregroundStyle(log.type == "crash" ? .red : .orange)
                                Text(log.filename)
                                    .font(.subheadline.weight(.medium))
                                    .lineLimit(1)
                            }
                            HStack {
                                if let date = log.date {
                                    Text(date, style: .date).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(log.size), countStyle: .file))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section("Diagnostic Data Locations") {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Settings → Privacy & Security → Analytics & Improvements → Analytics Data", systemImage: "gearshape.fill").font(.caption)
                    Label("Crash reports are also sent to Apple if opted in", systemImage: "apple.logo").font(.caption)
                    Label("Developers can view crash reports in Xcode Organizer", systemImage: "hammer.fill").font(.caption)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button { scanCrashLogs() } label: {
                    HStack {
                        if isScanning { ProgressView().scaleEffect(0.8) }
                        else { Image(systemName: "magnifyingglass") }
                        Text(isScanning ? "Scanning..." : "Scan for Crash Logs")
                    }
                }
                .disabled(isScanning)
            }
        }
        .navigationTitle("Crash Log Analyzer")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { scanCrashLogs() }
    }

    private func scanCrashLogs() {
        isScanning = true
        crashLogs = []
        let fm = FileManager.default

        let logDirs = [
            "/var/mobile/Library/Logs/CrashReporter/",
            "/var/mobile/Library/Logs/DiagnosticReports/",
            "/var/logs/CrashReporter/",
            NSHomeDirectory() + "/Library/Caches/",
            NSHomeDirectory() + "/tmp/"
        ]

        var logs: [CrashLogEntry] = []
        let crashExtensions = ["ips", "crash", "log", "synced", "plist"]

        for dir in logDirs {
            guard let files = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for file in files {
                let ext = (file as NSString).pathExtension.lowercased()
                if crashExtensions.contains(ext) || file.contains("crash") || file.contains("panic") {
                    let fullPath = (dir as NSString).appendingPathComponent(file)
                    let attrs = try? fm.attributesOfItem(atPath: fullPath)
                    let date = attrs?[.modificationDate] as? Date
                    let size = attrs?[.size] as? UInt64 ?? 0
                    let type = ext == "crash" || ext == "ips" ? "crash" : "diagnostic"
                    logs.append(CrashLogEntry(filename: file, date: date, size: size, type: type))
                }
            }
        }

        logs.sort { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
        crashLogs = logs

        let crashCount = logs.filter { $0.type == "crash" }.count
        let diagCount = logs.filter { $0.type == "diagnostic" }.count
        let totalSize = logs.reduce(UInt64(0)) { $0 + $1.size }

        stats = [
            ("Total Logs Found", "\(logs.count)"),
            ("Crash Reports", "\(crashCount)"),
            ("Diagnostic Reports", "\(diagCount)"),
            ("Total Size", ByteCountFormatter.string(fromByteCount: Int64(totalSize), countStyle: .file))
        ]

        isScanning = false
    }
}
