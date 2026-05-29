import SwiftUI

struct DeveloperStorageUsageView: View {
    @ObservedObject var appService = DeveloperAppService.shared
    @State private var selectedAppID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
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

                VStack(alignment: .leading, spacing: 16) {
                    Text("Storage Usage").font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("0.0 GB / 5.0 GB").font(.title3.bold())
                            ProgressView(value: 0.0).tint(.blue)
                        }
                        Spacer()
                        Text("0%").font(.headline).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage by Category").font(.headline)
                    usageRow(label: "Database", value: "0 MB", icon: "cylinder.split.1x2.fill", color: .blue)
                    usageRow(label: "Assets", value: "0 MB", icon: "photo.on.rectangle.angled", color: .green)
                    usageRow(label: "Logs", value: "0 MB", icon: "list.bullet.rectangle", color: .purple)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Section {
                    Button(role: .destructive) {
                        // Awaiting backend integration
                    } label: {
                        Label("Clear Cached Data", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Storage Usage")
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
