import SwiftUI

struct BackupTimelineView: View {
    @StateObject private var manager = BackupManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if manager.availableBackups.isEmpty {
                    ContentUnavailableView("Empty Timeline", systemImage: "calendar.badge.exclamationmark")
                        .padding(.top, 100)
                } else {
                    ForEach(manager.availableBackups) { backup in
                        HStack(alignment: .top, spacing: 16) {
                            // Timeline stem
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(backup.mode == .full ? .blue : .secondary)
                                    .frame(width: 12, height: 12)
                                Rectangle()
                                    .fill(Color(.separator))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(backup.timestamp.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.name)
                                        .font(.headline)
                                    Text("\(backup.restoreScope.count) modules • \(ByteCountFormatter.string(fromByteCount: backup.totalSizeCompressed, countStyle: .file))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.bottom, 24)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.top)
        }
        .navigationTitle("Timeline")
    }
}
