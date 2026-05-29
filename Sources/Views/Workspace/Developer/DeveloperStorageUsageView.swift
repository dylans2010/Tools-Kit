import SwiftUI

struct DeveloperStorageUsageView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Total Storage").font(.headline)
                    HStack {
                        VStack(alignment: .leading) {
                            Text("1.2 GB / 5.0 GB").font(.title3.bold())
                            ProgressView(value: 0.24).tint(.blue)
                        }
                        Spacer()
                        Text("24%").font(.headline).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 12) {
                    Text("Usage by Category").font(.headline)
                    usageRow(label: "Database", value: "450 MB", icon: "cylinder.split.1x2.fill", color: .blue)
                    usageRow(label: "Assets", value: "680 MB", icon: "photo.on.rectangle.angled", color: .green)
                    usageRow(label: "Logs", value: "90 MB", icon: "list.bullet.rectangle", color: .purple)
                }
                .padding()
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Section {
                    Button(role: .destructive) {
                        // Clear logs
                    } label: {
                        Label("Clear Cached Logs", systemImage: "trash")
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
