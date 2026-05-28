import SwiftUI

struct AppDetailView: View {
    let app: DeveloperApp
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            header

            Picker("Tab", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("History").tag(1)
                Text("Scopes").tag(2)
                Text("Auth").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()

            ScrollView {
                VStack(spacing: 20) {
                    if selectedTab == 0 {
                        overviewTab
                    } else if selectedTab == 1 {
                        versionHistoryTab
                    } else if selectedTab == 2 {
                        scopesTab
                    } else {
                        authConfigTab
                    }
                }
                .padding()
            }
        }
        .navigationTitle(app.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1))
                .frame(width: 64, height: 64)
                .overlay(Image(systemName: app.iconName).font(.title).foregroundStyle(.secondary))

            VStack(alignment: .leading, spacing: 4) {
                Text(app.name).font(.title3.bold())
                Text("\(app.type.rawValue) • \(app.status.rawValue)").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }

    private var overviewTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailGroup(title: "App Information") {
                detailRow(label: "Bundle ID", value: app.bundleId.isEmpty ? "com.developer.\(app.name.lowercased().replacingOccurrences(of: " ", with: "."))" : app.bundleId)
                detailRow(label: "Current Version", value: app.version)
                detailRow(label: "Pricing", value: app.pricingModel)
                detailRow(label: "Revenue", value: "$\(String(format: "%.2f", app.revenue))")
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description").font(.headline)
                Text(app.description.isEmpty ? "No description provided." : app.description)
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            Section {
                Button(role: .destructive) {} label: {
                    Label("Delete App", systemImage: "trash")
                }
            } header: {
                Text("Danger Zone").font(.headline).foregroundStyle(.red)
            }
        }
    }

    private var versionHistoryTab: some View {
        VStack(spacing: 0) {
            ForEach(0..<3) { i in
                HStack {
                    VStack(alignment: .leading) {
                        Text("v1.\(3-i).0").font(.subheadline.bold())
                        Text("Released \(Date().addingTimeInterval(Double(-i * 86400 * 7)).formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(i == 0 ? "Active" : "Archived")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(i == 0 ? Color.green.opacity(0.1) : Color.secondary.opacity(0.1))
                        .foregroundStyle(i == 0 ? .green : .secondary)
                        .clipShape(Capsule())
                }
                .padding()
                if i < 2 { Divider() }
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scopesTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Currently Granted Scopes", systemImage: "lock.shield")
                .font(.headline)

            ForEach(["read:user", "read:data"], id: \.self) { scope in
                HStack {
                    Text(scope).font(.caption.monospaced())
                    Spacer()
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                }
                .padding()
                .background(Color.secondary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var authConfigTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Authentication Setup").font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text("Primary Auth").font(.subheadline.bold())
                    Text("Google OAuth 2.0").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Configure") {}.font(.caption.bold())
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(spacing: 0) {
                content()
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            Spacer()
            Text(value).font(.subheadline.bold())
        }
        .padding()
    }
}
