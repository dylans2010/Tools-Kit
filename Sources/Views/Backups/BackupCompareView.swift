import SwiftUI

struct BackupCompareView: View {
    @StateObject private var manager = BackupManager.shared
    @State private var backupA: BackupMetadata?
    @State private var backupB: BackupMetadata?
    @State private var showingPicker = false
    @State private var pickingFor: PickingTarget?

    enum PickingTarget {
        case a, b
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                compareCard(target: .a, backup: backupA)
                compareCard(target: .b, backup: backupB)
            }
            .padding()

            if let a = backupA, let b = backupB {
                List {
                    Section("Module Size Differences") {
                        let allModules = Set(a.moduleSizes.keys).union(b.moduleSizes.keys)
                        ForEach(Array(allModules).sorted(), id: \.self) { module in
                            let sizeA = a.moduleSizes[module] ?? 0
                            let sizeB = b.moduleSizes[module] ?? 0
                            let diff = sizeB - sizeA

                            HStack {
                                Text(module.capitalized)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: diff, countStyle: .file))
                                    .foregroundStyle(diff > 0 ? .green : (diff < 0 ? .red : .secondary))
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }

                    Section("Metadata Comparison") {
                        compareRow(label: "App Version", valA: a.appVersion, valB: b.appVersion)
                        compareRow(label: "Date", valA: a.timestamp.formatted(date: .abbreviated, time: .omitted), valB: b.timestamp.formatted(date: .abbreviated, time: .omitted))
                        compareRow(label: "Mode", valA: a.mode.rawValue, valB: b.mode.rawValue)
                    }
                }
            } else {
                ContentUnavailableView("Compare Backups", systemImage: "arrow.left.and.right.circle", description: Text("Select two backups to see what changed between them."))
            }
        }
        .navigationTitle("Comparison")
        .sheet(item: $pickingFor) { target in
            NavigationStack {
                List(manager.availableBackups) { backup in
                    Button {
                        if target == .a { backupA = backup }
                        else { backupB = backup }
                        pickingFor = nil
                    } label: {
                        VStack(alignment: .leading) {
                            Text(backup.name).bold()
                            Text(backup.timestamp.formatted()).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }
                .navigationTitle("Select Backup")
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { pickingFor = nil }
                    }
                }
            }
        }
    }

    private func compareCard(target: PickingTarget, backup: BackupMetadata?) -> some View {
        Button {
            pickingFor = target
        } label: {
            VStack {
                Text(target == .a ? "Backup A" : "Backup B")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                if let backup = backup {
                    Text(backup.name)
                        .font(.headline)
                        .lineLimit(1)
                    Text(backup.timestamp.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.largeTitle)
                        .padding(.vertical, 4)
                    Text("Select")
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func compareRow(label: String, valA: String, valB: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(valA).font(.caption).foregroundStyle(.secondary)
            Image(systemName: "arrow.right").font(.caption2).foregroundStyle(.tertiary)
            Text(valB).font(.caption).foregroundStyle(valA == valB ? .secondary : .blue)
        }
    }
}

extension BackupCompareView.PickingTarget: Identifiable {
    var id: Self { self }
}
