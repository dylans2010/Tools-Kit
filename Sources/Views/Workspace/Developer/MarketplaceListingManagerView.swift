import SwiftUI

struct MarketplaceListingManagerView: View {
    @ObservedObject var store = DeveloperPersistentStore.shared
    @State private var showingSubmissionSheet = false

    var body: some View {
        List {
            Section {
                if store.apps.isEmpty {
                    Text("You don't have any apps in the Marketplace yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    ForEach(store.apps) { listing in
                        NavigationLink(destination: AppDetailView(app: listing)) {
                            listingCard(listing)
                        }
                    }
                }
            } header: {
                Text("Your Live Listings")
            }
        }
        .navigationTitle("Marketplace Listings")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSubmissionSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingSubmissionSheet) {
            MarketplaceSubmissionView()
        }
    }

    private func listingCard(_ listing: DeveloperApp) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.1))
                    .frame(width: 48, height: 48)
                    .overlay(Image(systemName: listing.iconName).foregroundStyle(.secondary))

                VStack(alignment: .leading, spacing: 2) {
                    Text(listing.name).font(.headline)
                    Text("v\(listing.version) • \(listing.status.rawValue)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(listing.installCount)").font(.subheadline.bold())
                    Text("Installs").font(.system(size: 8)).foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 8) {
                actionButton(title: "Edit", icon: "pencil") {
                    // Navigate to edit
                }
                actionButton(title: "Version", icon: "arrow.up.circle") {
                    // Update version
                }
                actionButton(title: "Pause", icon: listing.status == .live ? "pause" : "play") {
                    toggleStatus(listing)
                }
                actionButton(title: "Analytics", icon: "chart.bar") {
                    // Navigate to analytics for this app
                }
            }

            Divider()

            HStack {
                Label("4.8 rating", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Spacer()
                Text("Revenue: $\(String(format: "%.2f", listing.revenue))").font(.caption.bold())
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }

    private func actionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                Text(title).font(.system(size: 9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func toggleStatus(_ app: DeveloperApp) {
        var updatedApp = app
        updatedApp.status = (app.status == .live) ? .suspended : .live
        var apps = store.apps
        if let index = apps.firstIndex(where: { $0.id == app.id }) {
            apps[index] = updatedApp
            store.saveApps(apps)
        }
    }
}
