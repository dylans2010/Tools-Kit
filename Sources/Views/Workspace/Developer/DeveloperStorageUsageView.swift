import SwiftUI

struct DeveloperStorageUsageView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @ObservedObject var logService = DeveloperLogService.shared
    @State private var selectedAppID: UUID?
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                appPickerSection
                storageUsageSection
                categoryUsageSection
                clearCacheSection
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Storage Usage")
        .confirmationDialog("Clear Cached Data?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
            Button("Clear All Logs", role: .destructive) {
                Task {
                    // Logic to clear logs
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete local logs and cached app data. This action cannot be undone.")
        }
    }

    @ViewBuilder
    private var appPickerSection: some View {
        Section {
            Picker("App", selection: $selectedAppID) {
                Text("All Apps").tag(Optional<UUID>.none)
                ForEach(appService.apps) { app in
                    Text(app.name).tag(Optional(app.id))
                }
            }
            .pickerStyle(.menu)
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private var storageUsageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Usage").font(.headline)
            HStack {
                VStack(alignment: .leading) {
                    Text("\(currentUsageGB, specifier: "%.2f") GB / 5.0 GB").font(.title3.bold())
                    ProgressView(value: currentUsageGB, total: 5.0).tint(.blue)
                }
                Spacer()
                Text("\(Int(currentUsageGB / 5.0 * 100))%").font(.headline).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private var categoryUsageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Usage by Category").font(.headline)
            usageRow(label: "Database", value: "0 MB", icon: "cylinder.split.1x2.fill", color: .blue)
            usageRow(label: "Assets", value: "0 MB", icon: "photo.on.rectangle.angled", color: .green)
            usageRow(label: "Logs", value: "\(String(format: "%.1f", logUsageMB)) MB", icon: "list.bullet.rectangle", color: .purple)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var clearCacheSection: some View {
        Section {
            Button(role: .destructive) {
                showingClearConfirmation = true
            } label: {
                Label("Clear Cached Data", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var currentUsageGB: Double {
        logUsageMB / 1024.0
    }

    private var logUsageMB: Double {
        // Calculate real usage from log entries payload size
        let totalBytes = logService.logEntries.reduce(0) { $0 + $1.payload.utf8.count + $1.message.utf8.count }
        return Double(totalBytes) / (1024.0 * 1024.0)
    }

    private func usageRow(label: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(color).frame(width: 24)
            Text(label).font(.subheadline)
            Spacer()
            Text(value).font(.subheadline.bold()).foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }
}
