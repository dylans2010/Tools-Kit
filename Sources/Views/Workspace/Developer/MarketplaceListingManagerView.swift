import SwiftUI

struct MarketplaceListingManagerView: View {
    @State private var listings: [DeveloperApp] = [
        DeveloperApp(name: "GitHub Pro", type: .connector, status: .live, version: "2.1.0", installCount: 850),
        DeveloperApp(name: "Metal Shaders", type: .sdkExtension, status: .live, version: "1.2.0", installCount: 340)
    ]

    var body: some View {
        List {
            Section {
                ForEach(listings) { listing in
                    listingCard(listing)
                }
            } header: {
                Text("Your Live Listings")
            }
        }
        .navigationTitle("Marketplace Listings")
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
                actionButton(title: "Edit", icon: "pencil")
                actionButton(title: "Version", icon: "arrow.up.circle")
                actionButton(title: "Pause", icon: "pause")
                actionButton(title: "Analytics", icon: "chart.bar")
            }

            Divider()

            HStack {
                Label("4.8 rating", systemImage: "star.fill")
                    .foregroundStyle(.yellow)
                Spacer()
                Text("Revenue: $1,240.00").font(.caption.bold())
            }
            .font(.caption)
        }
        .padding(.vertical, 8)
    }

    private func actionButton(title: String, icon: String) -> some View {
        Button {} label: {
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
}
